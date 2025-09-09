import Types "types";
import Prop "property";
import Financial "financials";
import NFT "nft";
import Tokens "token";
import UserNotifications "userNotifications";
import PropHelper "propHelper";
import TestRouter "Tests/testRouter";
import TestTypes "Tests/testTypes";
import HashMap "mo:base/HashMap";
import Result "mo:base/Result";
import Nat "mo:base/Nat";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Time "mo:base/Time";
import Nat64 "mo:base/Nat64";
import IC "ic:aaaaa-aa";
import Buffer "mo:base/Buffer";

persistent actor {
  type Property = Types.Property;
  type Properties = Types.Properties;
  type Error = Types.Error;
  type GetPropertyResult = Types.GetPropertyResult;
  type UpdateResult = Types.UpdateResult;
  type WhatWithPropertyId = Types.WhatWithPropertyId;
  type ReadResult = Types.ReadResult;
  type MintResult = Types.MintResult;
  type Account = Types.Account;
  type User = Types.User;
  type Notification = Types.Notification;
  type NotificationType =  Types.NotificationType;
  type NotificationResult = Types.NotificationResult;
  type TestOption = TestTypes.TestOption;
  type LaunchProperty = Types.LaunchProperty;
  type MintError = Types.MintError;

  transient var properties : Properties = HashMap.HashMap<Nat, Property>(0, Nat.equal, PropHelper.natToHash);
  transient var userNotifications = HashMap.HashMap<Account, User>(0, NFT.accountEqual, NFT.accountHash);
  var stableProperties : [(Nat, Property)] = [];
  var stableUserNotifications : [(Account, User)] = [];
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
    let property = switch(properties.get(action.propertyId)){case(?p) p; case(null) return #Err([(?action.propertyId, #InvalidPropertyId)])};
    switch(await Prop.updateProperty({what = action.what; caller; property; handlePropertyUpdate; testing = false})){
      case(#Ok(updatedProperty)){
        properties.put(action.propertyId, updatedProperty);
        let updatedNotifications = await UserNotifications.addUserNotification(action, userNotifications, updatedProperty.nftMarketplace.collectionId);
        userNotifications := HashMap.fromIter(updatedNotifications.vals(), 0, NFT.accountEqual, NFT.accountHash);
        ignore NFT.handleNFTMetadataUpdate(action.what, updatedProperty);
        return #Ok(updatedProperty);
      };
      case(#Err(e)) return #Err(e);
    };
  };

  public shared ({caller}) func updateProperty(action: WhatWithPropertyId): async UpdateResult {
    await handlePropertyUpdate(action, caller);
  };

  type UpdateResultNat = Types.UpdateResultNat;
  public shared ({caller}) func bulkPropertyUpdate(args: [WhatWithPropertyId]): async [UpdateResultNat]{
    var results = Buffer.Buffer<UpdateResultNat>(args.size());
    for(i in args.keys()){
      switch(await handlePropertyUpdate(args[i], caller)){
        case(#Err(e)) results.add(#Err(e));
        case(#Ok(_)) results.add(#Ok(i));
      };
    };
    return Buffer.toArray(results);
  };

  public query func getTime(): async Nat64{
    let buffer = 2_000_000_000;
    Nat64.fromIntWrap(Time.now()+buffer);
  };


  type Read2 = Types.Read2;
  type FilterProperties = Types.FilterProperties;
  public query func readProperties(read: [Read2], filterProperties: ?FilterProperties): async [ReadResult] {
    Prop.read2({properties; filterProperties}, read);
  };

  type NFTActor = NFT.NFTActor;
  type ElementResult<T> = Types.ElementResult<T>;

  public func getNFTs(ids: ?[Int], acc: Account): async ReadResult {
        let propertyIds = Prop.convertIds(Iter.toArray(properties.entries()), ids);
        let futures = Buffer.Buffer<(Nat, async [Nat])>(0);
        let resultType = Buffer.Buffer<ElementResult<[Nat]>>(propertyIds.size());
        for(id in propertyIds.vals()){
          switch(id){
            case(#err(id)){};
            case(#ok(id)){
              switch(properties.get(id)){
                case(null) resultType.add({id; value = #Err(#InvalidPropertyId)});
                case(?property){
                  let nftActor : NFTActor = actor(Principal.toText(property.nftMarketplace.collectionId));
                  futures.add((property.id, nftActor.icrc7_tokens_of(acc, null, null)));
                }
              }
            };
          };
        };
        for ((id, future) in futures.vals()){
          let arr = await future;
          resultType.add({id; value = if(arr.size() == 0) #Err(#EmptyArray) else #Ok(arr)});
        };
        #NFTs(Array.sort<ElementResult<[Nat]>>(Buffer.toArray(resultType), func(a, b){Nat.compare(a.id, b.id)}));
    };

    ///////////////////////////////////////
    ///Temporary NFT Marketplace functions
    ///////////////////////////////////////

  func countResult (arr: [?MintResult]): {nullRes: Nat; ok: Nat; err: [MintError]}{
    var okCount = 0;
    var errCount = Buffer.Buffer<MintError>(0);
    var nullCount = 0;

    for (res in arr.vals()) {
        switch res {
            case null { nullCount += 1; };
            case (?result) {
                switch result {
                    case (#Ok(_)) { okCount += 1; };
                    case (#Err(e)) errCount.add(e);
                }
            };
        }
    };
    return {nullRes = nullCount; ok = okCount; err = Buffer.toArray(errCount)};
  };

  public func emptyState(quantity: Nat): async [{nullRes: Nat; ok: Nat; err: [MintError]}]{
    let array = Iter.toArray(properties.entries());
    let results = Buffer.Buffer<{nullRes: Nat; ok: Nat; err: [MintError]}>(properties.size());
    properties := HashMap.HashMap<Nat, Property>(0, Nat.equal, PropHelper.natToHash);
    id := 0;      
    for((_, property) in array.vals()){
      await NFT.clearNFTState(property.nftMarketplace.collectionId);
      let (newProperty, mintResult) = await Prop.addProperty(id, property.nftMarketplace.collectionId, quantity);
      let result = countResult(mintResult);
      if(result.ok > 0){
        properties.put(id, newProperty);
        id += 1;
      };
      results.add(result);
    };
    Buffer.toArray(results);
  };

public func verifyNFTTransfer(propertyId: Nat, to: Account, token_id: Nat): async ?TransferResult {
    let property = switch(properties.get(propertyId)){case(null)return null; case(?p)p};
    await NFT.verifyTransfer(property.nftMarketplace.collectionId, ?Principal.toBlob(PropHelper.getAdmin()), to, token_id);
  };
 
  type AcceptedCryptos = Types.AcceptedCryptos;
  type TransferFromResult = Tokens.TransferFromResult;
  public func verifyTokenTransferFrom(propertyId: Nat, listingId: Nat, from: Account): async ?TransferFromResult {
    let property = switch(properties.get(propertyId)){case(null)return null; case(?property)property};
    switch(PropHelper.getElementByKey(property.nftMarketplace.listings, listingId)){
      case(null)return null;
      case(?#LaunchFixedPrice(arg)){
        let result = await Tokens.transferFrom(arg.quoteAsset, arg.price, {owner = arg.seller.owner; subaccount = ?Principal.toBlob(Principal.fromText("vq2za-kqaaa-aaaas-amlvq-cai"))}, from);
        ?result
      };
      case(_){return null};
    };
  };


  type TransferResult = Types.TransferResult;
  public func transferNFT(to: Account, listId: Nat, propertyId: Nat, tokenId:Nat): async ?TransferResult {
    let property = switch(properties.get(propertyId)){case(?prop) prop; case(null){return ?#Err(#InvalidRecipient)}};
    switch(PropHelper.getElementByKey(property.nftMarketplace.listings, listId)){
      case(null) return null;
      case(?#LaunchFixedPrice(arg)){
        await NFT.transfer(property.nftMarketplace.collectionId, arg.seller.subaccount, to, tokenId);

      };
      case(_){return null};
    };
  };

type TransferArg = Types.TransferArg;
public func transferNFTBulk(): async [?TransferResult] {
    let property = switch(properties.get(0)){case(?prop) prop; case(null){return [?#Err(#InvalidRecipient)]}};
    let buffer = Buffer.Buffer<TransferArg>(0);
    buffer.add(NFT.createTransferArg(2, null, {owner = PropHelper.getAdmin(); subaccount = ?Principal.toBlob(PropHelper.getAdmin())}));
    buffer.add(NFT.createTransferArg(3, null, {owner = PropHelper.getAdmin(); subaccount = ?Principal.toBlob(PropHelper.getAdmin())}));
    await NFT.transferBulk(property.nftMarketplace.collectionId, Buffer.toArray(buffer));
  };

  public func getBackendsNFTs(): async [Nat] {
    let property = switch(properties.get(0)){case(?prop) prop; case(null){return []}};
    await NFT.tokensOf(property.nftMarketplace.collectionId, {owner = Principal.fromText("vq2za-kqaaa-aaaas-amlvq-cai"); subaccount = null},null, null);
  };

  public func transferAllNFTs(): async [?TransferResult] {
    let property = switch(properties.get(0)){case(?prop) prop; case(null){return [?#Err(#InvalidRecipient)]}};
    let tokens = await NFT.tokensOf(property.nftMarketplace.collectionId, {owner = Principal.fromText("vq2za-kqaaa-aaaas-amlvq-cai"); subaccount = null},null, null);
    let buffer = Buffer.Buffer<TransferArg>(0);
    for(token in tokens.vals()){
      buffer.add(NFT.createTransferArg(token, null, {owner = PropHelper.getAdmin(); subaccount = ?Principal.toBlob(PropHelper.getAdmin())}));
    };
    await NFT.transferBulk(property.nftMarketplace.collectionId, Buffer.toArray(buffer));
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
      switch(await Financial.fetchValuation(property, transform)){
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

  public func getURLs():async [Text]{
    let buff = Buffer.Buffer<Text>(properties.size());
    for(property in properties.vals()){
      buff.add(Financial.createURL(property));
    };
    Buffer.toArray(buff);
  };

  /////////////////////////////////////////
  //////User Notifications 
  //////////////////////////////////////////
  public func getUserNotification(account: Account): async [Notification]{
    UserNotifications.getUserNotifications(account, userNotifications);
  };

  public shared ({caller}) func updateSavedListings(propertyId: Nat, listId: Nat):(){
    UserNotifications.updateSaved({owner=caller; subaccount = null}, propertyId, listId, userNotifications);
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

  public shared ({caller}) func verifyKYC(result: Bool): async (){
    UserNotifications.verifyKYC(result, caller, userNotifications);
  };

  public query func userVerified(user: Account): async Bool {
    switch(userNotifications.get(user)){
      case(null) false;
      case(?user) user.kyc;
    }
  };

  public func runTests(arg: TestOption): async [[Text]]{
    await TestRouter.runTestsForOption(arg, handlePropertyUpdate);
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
