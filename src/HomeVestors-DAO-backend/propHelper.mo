import Types "types";
import Array "mo:base/Array";
import Hash "mo:base/Hash";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Blob "mo:base/Blob";

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

    public func getElementByKey<T>(arr: [(Nat, T)], key: Nat) : ?T {
        for ((k, v) in arr.vals()) {
            if (k == key) {
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

    
    public func addPropertyEvent(action: What, property: Property):  Property{
        {property with updates = Array.append(property.updates, [#Ok(action)])};
    };

    public func getAdmin(): Principal {
        Principal.fromText("b7qdj-qbquz-a4rzw-dl5y6-a6gun-mi7yk-tnlxd-jjwom-fqqry-2jpr2-xqe");
    };

    public func updateProperty(update: Update, property: Property, action: What): UpdateResult {
        var updatedProperty = switch(update){
            case(#Details(d)){{property with details = d;}};
            case(#Financials(f)){{property with financials = f}};
            case(#Administrative(a)){{property with administrative = a}};
            case(#Operational(o)){{property with operational = o}};
            case(#NFTMarketplace(m)){{property with nftMarketplace = m}}
        };
        updatedProperty := addPropertyEvent(action, updatedProperty);
        return #Ok(updatedProperty);
    };

    public func updateId<T>(action: Intent<T>, currentId: Nat): Nat{
        switch(action){
            case(#Create(_)) return currentId + 1;
            case(_) return currentId;
        };
    };

    public func performAction<T>(action: Intent<T>, arr: [(Nat, T)]): [(Nat, T)]{
        switch(action){
            case(#Create(el, id)){
                return addElement<T>(arr, id, el);
            };
            case(#Update(el, id)){
                return updateElementByKey<T>(arr, id, el)
            };
            case(#Delete(id)){
                return removeElementByKey<T>(arr, id);
            }
        };
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
    
     
}