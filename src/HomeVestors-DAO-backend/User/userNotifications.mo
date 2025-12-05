//import Types "../Utils/types";
//import NFT "../Marketplace/nft";
//import Array "mo:base/Array";
//import Iter "mo:base/Iter";
//import Buffer "mo:base/Buffer";
//import Option "mo:base/Option";
//import HashMap "mo:base/HashMap";
//import Nat "mo:base/Nat";
//import Utils "../Utils/utils";
//
//module UserNotifications {
//  
//    type UsersNotifications = Types.UsersNotifications;
//    type WhatWithPropertyId = Types.WhatWithPropertyId;
//    type User = Types.User;
//    type Account = Types.Account;
//    type NotificationType = Types.NotificationType;
//    type What = Types.What;
//    type Notification = Types.Notification;
//    type NotificationResult = Types.NotificationResult;
//
//    public func createNewUser(p: Principal): User {
//      {
//        id = p;
//        vault = createVault();
//        stabilityPosition = createStabilityPosition();
//        transactionHistory = [];
//        kyc = false;
//        notifications = [];
//        results = [];
//        saved = [];
//      }
//    };
//
//    func createVault(): Types.Vault {
//      {
//        nftCollateral = [];
//        hvrCollateral = 0;
//        husdDebt = 0;
//      }
//    };
//
//    func createStabilityPosition(): Types.StabilityPosition {
//      {
//        depositedHUSD = 0;
//        pendingHVRRewards = 0;
//        pendingNFTRewards = [];
//        lastReward = 0;
//      }
//    };
//
//  public func verifyKYC(result: Bool, caller: Principal, userNotifications: HashMap.HashMap<Account, User>): (){
//    let account = {owner = caller; subaccount = null};
//    switch(userNotifications.get(account)){
//      case(?user){
//        if(not user.kyc){
//          let updatedUser = {user with kyc = result};
//          userNotifications.put(account, updatedUser);
//        }
//      };
//      case(null){
//        let newUser = {createNewUser(caller) with kyc = result};
//        userNotifications.put(account, newUser)
//      };  
//    }
//  };
//
//
//    func toggleNat(arr: [Nat], target: Nat): [Nat] {
//      if (Array.indexOf<Nat>(target, arr, func(a, b) = a == b) != null) {
//          Array.filter<Nat>(arr, func(x) = x != target)
//      } else {
//          Array.append(arr, [target])
//      }
//    };
//
//    public func updateSaved(account: Account, propertyId: Nat, listId: Nat, userNotifications: UsersNotifications): (){
//      var user = getUser(account, userNotifications);
//      let saved = HashMap.fromIter<Nat, [Nat]>(user.saved.vals(), user.saved.size(), Nat.equal, Utils.natToHash);
//      switch(saved.get(propertyId)){
//        case(null) saved.put(propertyId, [listId]);
//        case(?listIds) saved.put(propertyId, toggleNat(listIds, listId));
//      };
//      user := {user with saved = Iter.toArray(saved.entries());};
//      userNotifications.put(account, user);
//    };
//
//    public func getUser(account: Account, userNotifications: UsersNotifications): User{
//      switch(userNotifications.get(account)){
//        case(null) createNewUser(account.owner);
//        case(?user) user;
//      }
//    };
//
//    public func getUserNotifications(account: Account, usersNotifications: UsersNotifications): [Notification]{
//      let user = getUser(account, usersNotifications);
//      return user.notifications;
//    };
//
//     public func getUserNotificationsResults(account: Account, usersNotifications: UsersNotifications): [NotificationResult]{
//      let user = getUser(account, usersNotifications);
//      return user.results;
//    };
//
//    public func addUserNotification(_action: Types.AllWhatsWithPropertyId, userNotifications : UsersNotifications, nftCollection: Principal): async [(Account, User)] {
//        let users = await NFT.getAllAccountBalances(nftCollection);
//        for(account in users.vals()){
//          let user = getUser(account, userNotifications);
//          userNotifications.put(account, user);
//        };
//        return Iter.toArray(userNotifications.entries());
//    };
//
//    
//
//    public func getUserNotificationType(account: Account, usersNotifications: UsersNotifications, notificationType: NotificationType): [Notification] {
//      let user = getUser(account, usersNotifications);
//      let notificationsOfType = Buffer.Buffer<Notification>(0);
//      for(notification in user.notifications.vals()){
//        if(notification.ntype == notificationType) notificationsOfType.add(notification);
//      };
//      return Iter.toArray(notificationsOfType.vals());
//    };
//
//    public func changeNotificationType(notificationId: Nat, newNType: NotificationType, account: Account, usersNotifications: UsersNotifications): (NotificationResult, UsersNotifications) {
//      let user = getUser(account, usersNotifications);
//      let updatedNotifications = Buffer.Buffer<Notification>(user.notifications.size());
//      var result : ?NotificationResult = null;
//      for(notification in user.notifications.vals()){
//        if(notification.id == notificationId){
//          updatedNotifications.add({notification with ntype = newNType;});
//          result := ?#Ok({notification with ntype = newNType});
//        }
//        else {
//          updatedNotifications.add(notification);
//        };
//      };
//      let updateResult = Option.get(result, #Err(notificationId, #InvalidElementId));
//      let updatedUser : User = {
//        user with 
//        notifications = Iter.toArray(updatedNotifications.vals());
//        results = Array.append(user.results, [updateResult]);
//      };
//      usersNotifications.put(account, updatedUser);
//      (updateResult, usersNotifications);
//    };
//}