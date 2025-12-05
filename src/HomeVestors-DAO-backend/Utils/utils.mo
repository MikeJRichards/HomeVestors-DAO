import Types "types";
import UnstableTypes "unstableTypes";
import Array "mo:base/Array";
import Hash "mo:base/Hash";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Blob "mo:base/Blob";
import HashMap "mo:base/HashMap";
import Int "mo:base/Int";
import Result "mo:base/Result";
import Buffer "mo:base/Buffer";
//import Debug "mo:base/Debug";

module PropertiesHelper {
   type Property = Types.Property;
   type Properties = Types.Properties;
   type Update = Types.Update;
   type PropertyResult<T> = Types.PropertyResult<T>;
   type Result = Types.Result;
   type GetPropertyResult = Types.GetPropertyResult;
   type UpdateResult = Types.UpdateResult;
   type Account = Types.Account;
   type Intent<T> = Types.Intent<T>;
   type What = Types.What;
   type CrudHandler<K, C,U, T, StableT> = UnstableTypes.CrudHandler<K, C,U,T ,StableT>;
   type BeforeVsAfter<K> = Types.BeforeVsAfter<K>;
   type ToStruct<K> = Types.ToStruct<K>;
   type BeforeOrAfter = UnstableTypes.BeforeOrAfter;

    public func accountEqual(a : Account, b : Account) : Bool {
         Principal.equal(a.owner, b.owner) and
         blobEqual(a.subaccount, b.subaccount)
    };
  
    public func blobEqual(a : ?Blob, b : ?Blob) : Bool {
        switch (a, b) {
          case (null, null) true;
          case (?a, ?b) Blob.equal(a, b);
          case _ false;
        }
    };

    public func accountHash(account: Account): Hash.Hash {
        let ownerBlob = Principal.hash(account.owner);
        let subaccountBlob = switch (account.subaccount) {
            case null { Blob.hash(Blob.fromArray([])) };
            case (?sub) { Blob.hash(sub)};
        };
        return ownerBlob ^ subaccountBlob;
    };

    public func natToHash(n: Nat): Hash.Hash {
       Text.hash(Nat.toText(n));  
    };

    public func getNullable<T>(test: ?T, alternative: ?T): ?T {
        switch(test){
            case(?t) ?t;
            case(null) alternative;
        }
    };

     public func get<T>(test: ?T, alternative: T): T {
        switch(test){
            case(?t) t;
            case(null) alternative;
        }
    };

    public func getPropertyFromId(id: Nat, properties: Properties): GetPropertyResult {
        switch(properties.get(id)){
            case(null){
                return #Err();
            };
            case(?property){
                return #Ok(property);
            }
        }
    };

    public func isInList<T>(target: T, list: [T], equal: (T, T) -> Bool) : Bool {
      switch (Array.find<T>(list, func (item) { equal(item, target) })) {
        case (?_) true;
        case null false;
      }
    };

    public func getElementByKey<K, T>(arr: [(K, T)], key: K, equal: (K, K) -> Bool) : ?T {
        for ((k, v) in arr.vals()) {
            if (equal(k,key)) {
                return ?v;
            }
        };
        return null;
    };

    public func updateElementByKey<T>(arr: [(Nat, T)], key: Nat, newValue: T) : [(Nat, T)] {
        return Array.map<(Nat, T), (Nat, T)>(arr, func((k, v)) {
            if (k == key) {
                return (k, newValue);
            } else {
                return (k, v);
            }
        });
    };

    public func removeElementByKey<T>(arr: [(Nat, T)], key: Nat) : [(Nat, T)] {
        return Array.filter<(Nat, T)>(arr, func((k, v)) {
            k != key
        });
    };

    public func addElement<T>(arr: [(Nat, T)], key: Nat, value: T) : [(Nat, T)] {
        for ((k, v) in arr.vals()) {
            if (k == key) {
                return arr;
            }
        };
        return Array.append(arr, [(key, value)]);
    };

    public func getAdmin(): Principal {
        Principal.fromText("b7qdj-qbquz-a4rzw-dl5y6-a6gun-mi7yk-tnlxd-jjwom-fqqry-2jpr2-xqe");
    };

    public func lastEntry<T,V>(arr: [(T, V)]): ?V {
        if(arr.size() == 0) {
            return null
        } 
        else {
            let (_, v) = arr[arr.size() - 1];
            return ?v
        };
    };

    public func matchNullableAccounts(acc1: ?Account, acc2: ?Account): Bool {
        switch(acc1, acc2){
            case(?account1, ?account2) account1 == account2;
            case(_) true; 
        }
    };

    public func matchNullableAccountArr(account: ?Account, accounts: [Account]): Bool {
        switch(account){
            case(?acc1){
                for(acc2 in accounts.vals()){
                    if(acc1 == acc2) return true;
                };
                return false;
            };
            case(_) true; 
        }
    };    

    public func makeDelete<T>(map: HashMap.HashMap<Nat, T>): (Nat, T) -> () {
      func(id: Nat, _el: T): () = map.delete(id);
    };

    public func makeIdVar(initial: Nat): { var value: Nat } {
      { var value = initial };
    };

    public func matchEqualityFlag(int: Int, eq: ?Types.EqualityFlag): Bool {
        switch(eq){
            case(null) true;
            case(?#LessThan(cond)) int < cond; 
            case(?#MoreThan(cond)) int > cond;
        };
    };

    public func matchNullablePrincipals(p1: ?Principal, p2: ?Principal): Bool{
        //function used for reads / conditionals so defaults to true if either are null
        switch(p1, p2){
            case(?p1, ?p2) Principal.equal(p1, p2);
            case(_) true;
        }
    };

    public func convertIds<T>(arr: [(Nat, T)], ids: ?[Int]): [Result.Result<Nat, Nat>]{
        let idsArr = Array.map<(Nat, T), Nat>(arr, func ((n, _)) = n);
        let sortedArr = Array.sort<Nat>(idsArr, Nat.compare);
        let buff = Buffer.Buffer<Result.Result<Nat, Nat>>(0);
        switch(ids){
            case(null) for(id in sortedArr.vals()) buff.add(#ok(id));
            case(?ids){
                for(id in ids.vals()){
                    let idx = Int.abs( if(id < 0) sortedArr.size() + id else id);
                    let res = if (idx < 0 or idx >= sortedArr.size()) #err(idx) else #ok(sortedArr[idx]);
                    buff.add(res);
                };
            };
        };
        Buffer.toArray(buff);
    };

    public func matchWhat(what: [What], whatFlag: ?Types.WhatFlag): Bool {
    switch (whatFlag) {
        case (null) { 
            return true;  // Always match if flag is null, even for empty actions
        };
        case (?flag) {
            for (w in what.vals()) {
                switch (w, flag) {
                    case (#Insurance(_), #Insurance) return true;
                    case (#Document(_), #Document) return true;
                    case (#Note(_), #Note) return true;
                    case (#Maintenance(_), #Maintenance) return true;
                    case (#Inspection(_), #Inspection) return true;
                    case (#Tenant(_), #Tenant) return true;
                    case (#Valuations(_), #Valuations) return true;
                    case (#Financials(_), #Financials) return true;
                    case (#MonthlyRent(_), #MonthlyRent) return true;
                    case (#PhysicalDetails(_), #PhysicalDetails) return true;
                    case (#AdditionalDetails(_), #AdditionalDetails) return true;
                    case (#NftMarketplace(#FixedPrice(_)), #NftMarketplace(#FixedPrice)) return true;
                    case (#NftMarketplace(#Auction(_)), #NftMarketplace(#Auction)) return true;
                    case (#NftMarketplace(#Launch(_)), #NftMarketplace(#Launch)) return true;
                    case (#NftMarketplace(#Bid(_)), #NftMarketplace(#Bid)) return true;
                    case (#Images(_), #Images) return true;
                    case (#Invoice(_), #Invoice) return true;
                    case (#Description(_), #Description) return true;
                    case (#Governance(#Vote(_)), #Governance(#Vote)) return true;
                    case (#Governance(#Proposal(_)), #Governance(#Proposal)) return true;
                    case (_) {};  // No match for this action/flag combo
                };
            };
            return false;  // No matching actions found for non-null flag
        };
    };
};
}
