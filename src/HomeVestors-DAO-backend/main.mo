import Types "types";
import Prop "property";
import Financial "financials";
import NFT "nft";
import UserNotifications "userNotifications";
import PropHelper "propHelper";
import HashMap "mo:base/HashMap";
import Result "mo:base/Result";
import Nat "mo:base/Nat";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import Array "mo:base/Array";
import Blob "mo:base/Blob";
import IC "ic:aaaaa-aa";
import Buffer "mo:base/Buffer";

actor {
  type Property = Types.Property;
  type Properties = Types.Properties;
  type Error = Types.Error;
  type GetPropertyResult = Types.GetPropertyResult;
  type UpdateResult = Types.UpdateResult;
  type WhatWithPropertyId = Types.WhatWithPropertyId;
  type ReadResult = Types.ReadResult;
  type Read = Types.Read;
  type MintResult = Types.MintResult;
  type Account = Types.Account;
  type User = Types.User;
  type Notification = Types.Notification;
  type NotificationType =  Types.NotificationType;
  type NotificationResult = Types.NotificationResult;

  var properties : Properties = HashMap.HashMap<Nat, Property>(0, Nat.equal, PropHelper.natToHash);
  var userNotifications = HashMap.HashMap<Account, User>(0, NFT.accountEqual, NFT.accountHash);
  stable var stableProperties : [(Nat, Property)] = [];
  stable var stableUserNotifications : [(Account, User)] = [];
  var id = 0;

  public func createProperty(nftCollection: Principal, nftQuantity: Nat): async [?MintResult] {
    let (property, mintResult) = await Prop.addProperty(id, nftCollection, nftQuantity);
    properties.put(id, property);
    id += 1;
    return mintResult;
  };

  public func getProperty(id: Nat): async GetPropertyResult {
    return PropHelper.getPropertyFromId(id, properties);
  };

  public func getAllProperties(): async [Property]{
    Iter.toArray(properties.vals());
  };

  public func removeProperty(id: Nat): async Result.Result<Property, Error>{
    Prop.removeProperty(id, properties);
  };

  func handlePropertyUpdate(action: WhatWithPropertyId, caller: Principal): async UpdateResult {
    let property = switch(properties.get(action.propertyId)){case(?p)p; case(null) return #Err(#InvalidPropertyId)};
    switch(await Prop.updateProperty(action.what, caller, property)){
      case(#Ok(updatedProperty)){
        properties.put(action.propertyId, updatedProperty);
        let updatedNotifications = await UserNotifications.addUserNotification(action, userNotifications, updatedProperty.nftMarketplace.collectionId);
        userNotifications := HashMap.fromIter(updatedNotifications.vals(), 0, NFT.accountEqual, NFT.accountHash);
        ignore NFT.handleNFTMetadataUpdate(action.what, updatedProperty);
        return #Ok(updatedProperty);
      };
      case(#Err(e)){
        properties.put(action.propertyId, {property with updates = Array.append(property.updates, [#Err(e)])});
        return #Err(e);
      }
    };
  };

  public shared ({caller}) func updateProperty(action: WhatWithPropertyId): async UpdateResult {
    await handlePropertyUpdate(action, caller)
  };

  public shared ({caller}) func bulkPropertyUpdate(args: [WhatWithPropertyId]): async [UpdateResult]{
    var results : [UpdateResult] = [];
    for(arg in args.vals()){
      let updateResult = await handlePropertyUpdate(arg, caller);
      results := Array.append(results, [updateResult]);
    };
    return results;
  };

  public query func readProperty(read: Read, propertyId: Nat): async ReadResult {
    let property = switch(properties.get(propertyId)){case(?p)p; case(null) return #Err(#InvalidPropertyId)};
    PropHelper.readPropertyData(property, read);
  };



  /////////////////////////
  ////HTTP Outcall
  //////////////////////
  // Required for consensus — strips response headers
   public query func transform({context : Blob; response : IC.http_request_result;}) : async IC.http_request_result {
    {
        status = response.status;
        body = response.body;
        headers = []; // 🔥 Strip all response headers
    };
  };

  public shared ({caller}) func updatePropertyValuations(): async [UpdateResult]{
    let results = Buffer.Buffer<UpdateResult>(properties.size());
    for(property in properties.vals()){
      switch(await Financial.fetchValuation(property.details.location.postcode, transform)){
        case(#ok(what)){
            results.add(await handlePropertyUpdate({what = what; propertyId = property.id}, caller));
        };
        case(#err(e)){
          results.add(#Err(e))
        };
      }
    };
    return Iter.toArray(results.vals());
  };

  /////////////////////////////////////////
  //////User Notifications 
  //////////////////////////////////////////
  public func getUserNotification(account: Account): async [Notification]{
    UserNotifications.getUserNotifications(account, userNotifications);
  };

  public func getUserNotificationResults(account: Account): async [NotificationResult]{
    UserNotifications.getUserNotificationsResults(account, userNotifications);
  };

  public func getUserNotificationsOfType(account: Account, ntype: NotificationType): async [Notification]{
    UserNotifications.getUserNotificationType(account, userNotifications, ntype);
  };

  public func updateNotificationType(account: Account, ntype: NotificationType, id: Nat): async NotificationResult {
    let (result, updatedUserNotifications) = UserNotifications.changeNotificationType(id, ntype, account, userNotifications);
    userNotifications := updatedUserNotifications;
    return result;
  };
     
  system func preupgrade(){
    stableProperties := Iter.toArray(properties.entries());
    stableUserNotifications := Iter.toArray(userNotifications.entries());
  };

  system func postupgrade(){
    properties := HashMap.fromIter(stableProperties.vals(), 0, Nat.equal, PropHelper.natToHash);
    userNotifications := HashMap.fromIter(stableUserNotifications.vals(), 0, NFT.accountEqual, NFT.accountHash);
  }

};
