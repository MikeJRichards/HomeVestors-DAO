import Iter "mo:core/Iter";
import Order "mo:core/Order";
import Map "mo:core/Map";
import List "mo:core/List";
import Nat "mo:core/Nat";
import Blob "mo:base/Blob";
import Text "mo:base/Text";
import Principal "mo:base/Principal";

module {
    public type MapHandler<K,V> = {
        put: (K, V) -> ();
        get: K -> ?V;
        remove: K -> ();
        entries: () -> Iter.Iter<(K, V)>;
        toArray: () -> [(K, V)];
    };

    public type ListHandler<T> = {
        list: List.List<T>;
        add : (T) -> ();                            // push to end
        addAll : (Iter.Iter<T>) -> ();              // push many
        removeLast : () -> ?T;                      // pop from end
        clear : () -> ();                           // wipe list
        get : (Nat) -> ?T;                          // safe index
        put : (Nat, T) -> ();                       // overwrite index (trap if OOB)
        size : () -> Nat;                           // current length
        entries : () -> Iter.Iter<T>;                // iterator over values
        filter: (T, T->Bool)->ListHandler<T>;
        toArray : () -> [T];                        // snapshot as array
        find : (T -> Bool) -> ?T;                   // first matching element
        zip : <A, B>(List.List<A>, List.List<B>) -> ListHandler<(A, B)>; //create a tuple list from two lists
    };

    public type VersionKey = {
        struct: Nat;
        actions: Nat;
        logic: Nat;
    };

    public type Wasm = {
        wasm_module: [Nat8];
        installArg: [Nat8];
        upgradeArg: [Nat8];
    };

    public func versionCompare(a : VersionKey, b : VersionKey) : Order.Order {
        if (a.struct < b.struct) return #less;
        if (a.struct > b.struct) return #greater;

        // struct equal → compare actions
        if (a.actions < b.actions) return #less;
        if (a.actions > b.actions) return #greater;

        // struct & actions equal → compare logic
        if (a.logic < b.logic) return #less;
        if (a.logic > b.logic) return #greater;

        // all equal
        return #equal;
    };

    public func createMapHandler<K,V>(compare: (K, K) -> Order.Order, arr: [(K, V)]): MapHandler<K,V>{
        let map = Map.fromIter(arr.vals(), compare);

        {
            put = func(key : K, value : V) {
                Map.add(map, compare, key, value);
            };

            get = func (key : K) : ?V {
                Map.get(map, compare, key);
            };

            remove = func(key : K) {
                Map.remove(map, compare, key);
            };

            entries = func(): Iter.Iter<(K, V)> {                
                Map.entries(map)
            };

            toArray = func(): [(K, V)]{
                Iter.toArray(Map.entries(map));
            };
        }
    };

    public func createListHandler<T>(arr : [T]) : ListHandler<T> {
        let list = List.fromArray(arr);
        {
            list;
            // add element to the end
            add = func (value : T) {
                List.add<T>(list, value);
            };

            // add all elements from an iterator
            addAll = func (it : Iter.Iter<T>) {
                List.addAll<T>(list, it);
            };

            // remove and return last element, or null if empty
            removeLast = func () : ?T {
                List.removeLast<T>(list);
            };

            // clear the list in-place
            clear = func () {
                List.clear<T>(list);
            };

            // safe get: returns ?T instead of trapping
            get = func (index : Nat) : ?T {
               let sz = List.size<T>(list);
                if (index >= sz) {
                    null
                } else {
                    List.get<T>(list, index)
                }
            };

            // overwrite element at index (traps if index >= size)
            put = func (index : Nat, value : T) {
                List.put<T>(list, index, value);
            };

            filter = func(el: T, match: T -> Bool): ListHandler<T>{
                createListHandler(List.toArray<T>(List.filter<T>(list, match)));
            };

            // current size
            size = func () : Nat {
                List.size<T>(list);
            };

            // iterator over current values
            entries = func () : Iter.Iter<T> {
                List.values<T>(list);
            };

            // snapshot to array
            toArray = func () : [T] {
                List.toArray<T>(list);
            };

            // first element matching predicate
            find = func (pred : T -> Bool) : ?T {
                List.find<T>(list, pred);
            };

            zip = func <A, B>(list: List.List<A>, other : List.List<B>) : ListHandler<(A, B)> {
                let out = List.empty<(A, B)>();
                let len = Nat.min(List.size(list), List.size(other));

                var i : Nat = 0;
                while (i < len) {
                    switch(List.get<A>(list, i), List.get<B>(other, i)){
                        case(?a, ?b) List.add(out, (a, b));
                        case(_){};
                    };
                    i += 1;
                };
                createListHandler(List.toArray<(A,B)>(out));
            };
        };
    };


    public type CanisterSettings = {
        controllers : ?[Principal];
        compute_allocation : ?Nat;
        memory_allocation : ?Nat;
        freezing_threshold : ?Nat;
    };

    public type InstallCodeMode = {
        #reinstall;
        #upgrade;
        #install;
    };

  // Management canister interface subset: create_canister + install_code
  public type IC = actor {
    create_canister : shared { settings : ?CanisterSettings } -> async { canister_id : Principal };

    install_code : shared { arg : [Nat8]; wasm_module : [Nat8]; mode : { #reinstall; #upgrade; #install }; canister_id : Principal; } -> async ();
  };

  public type PropertyDAO = actor{
    getProperty: () -> async Property;
    setPropertyModule: Principal -> async ();
  };

  public type CanisterIds = {
    propertyDao: Principal;
    nft: Principal;
    propertyModule: Principal;
  };

    
    public type PropertyIdentity = {
        propertyId    : Nat;
        addressLine1  : Text;
        addressLine2  : Text;
        addressLine3  : Text;
        addressLine4  : Text;
        postcode      : Text;
        purchasePrice    : Nat;


        // permanent canister relationships
        companyNumber: Text;
        collectionId  : Principal; // NFT collection canister
    };

    public type PropertyDisplay = {
        // headline visuals
        mainImage: Text;
        images: [Text];
        shortDescription : Text;

        // key numbers for systems + frontend
        valuation        : Nat;  // current market value
        mortgageBalance  : Nat;  // outstanding mortgage
        monthlyRent      : Nat;

        // key property characteristics (used everywhere)
        beds             : Nat;
        baths            : Nat;
        squareFootage    : Nat;
        propertyType     : PropertyType;

        // financial fundamentals

        // metadata syncing / migrations
        version          : VersionKey;
        propertyModule: Principal;
    };

    type PropertyType = { 
        #Terraced; 
        #Semi; 
        #Detached; 
        #Flat; 
        #Other: Text 
    };

    public type Value = {
        #Text : Text;
        #Nat  : Nat;
        #Int  : Int;
        #Float: Float;
        #Principal: Principal;
        #Blob : Blob;
        #Array : [Value];
        #Map : [(Text, Value)];
    };

    public type Field = {
        key   : Text;    // "amount", "status", "description"
        labels : Text;    // display label
        types  : Text;    // "text", "currency", "date", "status", "image", etc.
        value : Value;   // actual content
    };

    public type Item = {
        id     : Text;   // unique identifier per item/row
        labels  : Text;   // optional item title/subtitle
        fields : [Field];// key-value pairs describing the item
    };

    public type Section = {
        id      : Text;  // "invoices", "financials", "tenants", "maintenance"
        title   : Text;  // display title
        kind    : Text;  // "list", "table", "timeline", "cards", "images", etc.
        items   : [Item];
    };

    public type Property = {
        identity: PropertyIdentity;
        display: PropertyDisplay;
        view: [Section];
        governance: [Section];
    };

}