import Types "types";
import NFT "nft";
import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Buffer "mo:base/Buffer";
import Option "mo:base/Option";

module UserNotifications {
    type UsersNotifications = Types.UsersNotifications;
    type WhatWithPropertyId = Types.WhatWithPropertyId;
    type User = Types.User;
    type Account = Types.Account;
    type NotificationType = Types.NotificationType;
    type What = Types.What;
    type UpdateError = Types.UpdateError;
    type Notification = Types.Notification;
    type NotificationResult = Types.NotificationResult;

    func createNewUser(): User {
      {
        id = 0;
        notifications = [];
        results = [];
      }
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
        results = Array.append(user.results, [#Ok(newNotification)])
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