import Types "types";
import NFT "nft";
import Array "mo:base/Array";
import Iter "mo:base/Iter";

module UserNotifications {
    type UserNotifications = Types.UserNotifications;
    type WhatWithPropertyId = Types.WhatWithPropertyId;

    public func addUserNotification(action: WhatWithPropertyId, userNotifications : UserNotifications, nftCollection: Principal): async [(Principal, [WhatWithPropertyId])] {
        let users = await NFT.getAllAccountBalances(nftCollection);
        for(account in users.vals()){
          let previousNotifications = switch(userNotifications.get(account.owner)){case(null)[]; case(?n)n};
          let allNotifications = Array.append(previousNotifications, [action]);
          userNotifications.put(account.owner, allNotifications);
        };
        return Iter.toArray(userNotifications.entries());
    };
}