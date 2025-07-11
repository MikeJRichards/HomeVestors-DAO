import Types "types";
import NFT "nft";
import PropHelper "propHelper";
import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Buffer "mo:base/Buffer";
import Option "mo:base/Option";
import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";

module UserNotifications {
    type UsersNotifications = Types.UsersNotifications;
    type WhatWithPropertyId = Types.WhatWithPropertyId;
    type User = Types.User;
    type Account = Types.Account;
    type NotificationType = Types.NotificationType;
    type What = Types.What;
    type Notification = Types.Notification;
    type NotificationResult = Types.NotificationResult;

    func createNewUser(): User {
      {
        id = 0;
        kyc = false;
        notifications = [];
        results = [];
        saved = [];
      }
    };

  public func verifyKYC(result: Bool, caller: Principal, userNotifications: HashMap.HashMap<Account, User>): (){
    let account = {owner = caller; subaccount = null};
    switch(userNotifications.get(account)){
      case(?user){
        if(not user.kyc){
          let updatedUser = {user with kyc = result};
          userNotifications.put(account, updatedUser);
        }
      };
      case(null){
        let newUser = {createNewUser() with kyc = result};
        userNotifications.put(account, newUser)
      };  
    }
  };


    func toggleNat(arr: [Nat], target: Nat): [Nat] {
      if (Array.indexOf<Nat>(target, arr, func(a, b) = a == b) != null) {
          Array.filter<Nat>(arr, func(x) = x != target)
      } else {
          Array.append(arr, [target])
      }
    };

    public func updateSaved(account: Account, propertyId: Nat, listId: Nat, userNotifications: UsersNotifications): (){
      var user = getUser(account, userNotifications);
      let saved = HashMap.fromIter<Nat, [Nat]>(user.saved.vals(), user.saved.size(), Nat.equal, PropHelper.natToHash);
      switch(saved.get(propertyId)){
        case(null) saved.put(propertyId, [listId]);
        case(?listIds) saved.put(propertyId, toggleNat(listIds, listId));
      };
      user := {user with saved = Iter.toArray(saved.entries());};
      userNotifications.put(account, user);
    };

    public func getUser(account: Account, userNotifications: UsersNotifications): User{
      switch(userNotifications.get(account)){
        case(null) createNewUser();
        case(?user) user;
      }
    };

    public func getUserNotifications(account: Account, usersNotifications: UsersNotifications): [Notification]{
      let user = getUser(account, usersNotifications);
      return user.notifications;
    };

     public func getUserNotificationsResults(account: Account, usersNotifications: UsersNotifications): [NotificationResult]{
      let user = getUser(account, usersNotifications);
      return user.results;
    };

    func createNotification(user: User, content: WhatWithPropertyId): User {
      let newNotification : Notification = {
        id = user.id + 1;
        propertyId = content.propertyId;
        ntype = #New;
        content = content.what;
      };

      {
        id = user.id + 1;
        notifications = Array.append(user.notifications, [newNotification]);
        results = Array.append(user.results, [#Ok(newNotification)]);
        saved = user.saved;
        kyc = user.kyc;
      };
    };

 

    public func addUserNotification(action: WhatWithPropertyId, userNotifications : UsersNotifications, nftCollection: Principal): async [(Account, User)] {
        let users = await NFT.getAllAccountBalances(nftCollection);
        for(account in users.vals()){
          let user = getUser(account, userNotifications);
          userNotifications.put(account, createNotification(user, action));
        };
        return Iter.toArray(userNotifications.entries());
    };

    

    public func getUserNotificationType(account: Account, usersNotifications: UsersNotifications, notificationType: NotificationType): [Notification] {
      let user = getUser(account, usersNotifications);
      let notificationsOfType = Buffer.Buffer<Notification>(0);
      for(notification in user.notifications.vals()){
        if(notification.ntype == notificationType) notificationsOfType.add(notification);
      };
      return Iter.toArray(notificationsOfType.vals());
    };

    public func changeNotificationType(notificationId: Nat, newNType: NotificationType, account: Account, usersNotifications: UsersNotifications): (NotificationResult, UsersNotifications) {
      let user = getUser(account, usersNotifications);
      let updatedNotifications = Buffer.Buffer<Notification>(user.notifications.size());
      var result : ?NotificationResult = null;
      for(notification in user.notifications.vals()){
        if(notification.id == notificationId){
          updatedNotifications.add({notification with ntype = newNType;});
          result := ?#Ok({notification with ntype = newNType});
        }
        else {
          updatedNotifications.add(notification);
        };
      };
      let updateResult = Option.get(result, #Err(notificationId, #InvalidElementId));
      let updatedUser : User = {
        user with 
        notifications = Iter.toArray(updatedNotifications.vals());
        results = Array.append(user.results, [updateResult]);
      };
      usersNotifications.put(account, updatedUser);
      (updateResult, usersNotifications);
    };
}