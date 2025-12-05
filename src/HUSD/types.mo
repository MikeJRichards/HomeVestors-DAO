import Iter "mo:core/Iter";
import Order "mo:core/Order";
import Map "mo:core/Map";
import List "mo:core/List";
import Nat "mo:core/Nat";
import Blob "mo:base/Blob";
import Text "mo:base/Text";
import Principal "mo:base/Principal";

import CertTree "mo:ic-certification/CertTree";

module {
    public type LedgerState = {
        blocks : [Blocks];
        balances : [(Account, Nat)];
        allowances: [(AllowanceArgs, Allowance)];
        metadata: [(Text, Value)];
        //transactions
        totalSupply: Nat;
        mintingAccount: Account;
        fee : Nat;
        txIndex : Nat;
        decimals: Nat8;
        symbol: Text;
        name: Text;
        tx_window: Nat;
        permitted_drift: Nat;
        cert: CertTree.Store;
        phash: Blob;
    };
    func compareAccount(a : Account, b : Account) : Order.Order {
            let ownerOrder = Blob.compare(Principal.toBlob(a.owner), Principal.toBlob(b.owner));
            if (ownerOrder != #equal) return ownerOrder;

            // Principals equal → compare subaccounts
            switch (a.subaccount, b.subaccount) {
                case (null, null)          #equal;
                case (null, ?_)            #less;
                case (?_, null)            #greater;
                case (?sa, ?sb)            Blob.compare(sa, sb);
            };
        };

        func compareAllowanceKey(a : AllowanceArgs, b : AllowanceArgs) : Order.Order {
            let callerOrder = compareAccount(a.account, b.account);
            if (callerOrder != #equal) return callerOrder;
            return compareAccount(a.spender, b.spender);
        };

    public type MapHandler<K,V> = {
        put: (K, V) -> ();
        get: K -> ?V;
        remove: K -> ();
        entries: () -> Iter.Iter<(K, V)>;
        toArray: () -> [(K, V)];
    };

    public type BalanceMapHandler<K, V> = {
        get: K -> V;
        put: (K, V) -> ();
        remove: K -> ();
        entries: () -> Iter.Iter<(K, V)>;
        toArray: () -> [(K, V)];
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

    public func createBalanceMapHandler<K, V>(compare: (K, K) ->Order.Order, arr: [(K, V)], nullValue: V): BalanceMapHandler<K, V>{
        let mapHandler = createMapHandler<K, V>(compare, arr);
        {
            mapHandler with 
            get = func(key: K): V {
                switch(mapHandler.get(key)){
                    case(null) nullValue;
                    case(?amount) amount;
                }
            }
        }
    };



    public class Ledger(state : LedgerState) {

        // -------------------------
        // Internal state
        // -------------------------
        public let balances : BalanceMapHandler<Account, Nat> = createBalanceMapHandler<Account, Nat>(compareAccount, state.balances, 0);
        public let allowances : BalanceMapHandler<AllowanceArgs, Allowance> = createBalanceMapHandler<AllowanceArgs, Allowance>(compareAllowanceKey, state.allowances, {allowance = 0; expires_at = null});
        public let metadata : MapHandler<Text, Value> = createMapHandler<Text, Value>(Text.compare, state.metadata);
        public let blocks : ListHandler<Blocks> = createListHandler<Blocks>(state.blocks);
        
        public var totalSupply : Nat = state.totalSupply;
        public var mintingAccount : Account = state.mintingAccount;
        public var fee : Nat = state.fee;
        public var txIndex : Nat = state.txIndex;
        public var decimals : Nat8 = state.decimals;
        public let symbol: Text = state.symbol;
        public let name: Text = state.name;
        public let permitted_drift = state.permitted_drift;
        public let tx_window = state.tx_window;
        public let cert = state.cert;
        public var phash = state.phash; 

        // -------------------------
        // PUBLIC METHODS
        // -------------------------
        public func transfer(from : Account, to : Account, amount : Nat, op: Text) : Text {
            let fb = balances.get(from);
            let tb = balances.get(to);

            switch(from == mintingAccount, to == mintingAccount){
                case(true, _){
                    //mint
                    balances.put(to, tb + amount);
                    totalSupply += amount;
                    "mint";
                };
                case(_, true){
                    //burn
                    balances.put(from, fb - amount);
                    totalSupply -= amount;
                    "burn";
                };
                case(_){
                    //either transfer or transfer from
                    balances.put(from, fb - amount - fee);
                    balances.put(to, tb + amount);
                    op;
                }
            };          
        };

        // -------------------------
        // SNAPSHOT FOR UPGRADE
        // -------------------------
        public func stateSnapshot() : LedgerState {
          {
            balances = balances.toArray();
            allowances = allowances.toArray();
            metadata = metadata.toArray();
            blocks = blocks.toArray();
            totalSupply;
            mintingAccount;
            fee;
            txIndex;
            decimals;
            symbol;
            name;
            permitted_drift;
            tx_window;
            cert;
            phash;
          }
        };

    };

    public type Operation = {
        #Mint;
        #Burn;
        #Transfer;
        #TransferFrom;
        #Approve;
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

    // Number of nanoseconds since the UNIX epoch in UTC timezone.
    public type Timestamp = Nat64;

    // Number of nanoseconds between two [Timestamp]s.
    public type Duration = Nat64;

    public type Subaccount = Blob;

    public type Account = {
        owner : Principal;
        subaccount : ?Subaccount;
    };

    public type TransferArgs = {
        from_subaccount : ?Subaccount;
        to : Account;
        amount : Nat;
        fee : ?Nat;
        memo : ?Blob;
        created_at_time : ?Timestamp;
    };

    

    public type TransferResult = {
        #Ok: Nat;
        #Err: TransferError;
    };

    public type Value = {
        #Nat : Nat;
        #Int : Int;
        #Text : Text;
        #Blob : Blob;
        #Array : [Value];
        #Map : [(Text, Value)];
    };

    //ICRC2

    public type ApproveArgs = {
        from_subaccount : ?Subaccount;
        spender : Account;
        amount : Nat;
        expected_allowance : ?Nat;
        expires_at : ?Nat64;
        fee : ?Nat;
        memo : ?Blob;
        created_at_time : ?Nat64;
    };

    public type ApproveResult = {
        #Ok: Nat;
        #Err: ApproveError;
    };

    public type TransferFromArgs = {
        spender_subaccount : ?Blob;
        from : Account;
        to : Account;
        amount : Nat;
        fee :  ?Nat;
        memo : ?Blob;
        created_at_time : ?Nat64;
    };

    public type TransferFromResult = {
        #Ok: Nat;
        #Err: TransferFromError;
    };

    public type AllowanceArgs = {
        account : Account;
        spender : Account;
    };

    public type Allowance = {
        allowance: Nat; 
        expires_at: ?Nat64
    };

    public type BaseError = {
        #BadFee : { expected_fee : Nat };
        #TooOld;
        #CreatedInFuture: { ledger_time : Timestamp };
        #Duplicate : { duplicate_of : Nat };
        #GenericError : { error_code : Nat; message : Text };
        #TemporarilyUnavailable;
        #InsufficientFunds :  { balance : Nat };

    };

    public type TransferError = BaseError or {
        #BadBurn : { min_burn_amount : Nat };
    };

    public type TransferFromError = TransferError or {
        #InsufficientAllowance : { allowance : Nat };
    };

    public type ApproveError = BaseError or {
        #AllowanceChanged : { current_allowance : Nat };
        #Expired : { ledger_time : Nat64 };
    };

    //ICRC3

    public type GetArchivesArgs = {
        // The last archive seen by the client.
        // The Ledger will return archives coming
        // after this one if set, otherwise it
        // will return the first archives.
        from : ?Principal;
    };

    public type GetArchivesResult = [{
        // The id of the archive
        canister_id : Principal;

        // The first block in the archive
        start : Nat;

        // The last block in the archive
        end : Nat;
    }];

    public type GetBlocksArgs = [{ start : Nat; length : Nat }];

    public type GetBlocksResult = {
        // Total number of blocks in the
        // block log
        log_length : Nat;

        blocks : [Blocks];

        archived_blocks : [{
            args : GetBlocksArgs;
            callback : query (GetBlocksArgs) -> async (GetBlocksResult);
        }];
    };

    public type Blocks = { 
        id : Nat; 
        block: Value 
    };



    public type DataCertificate = {
      // See https://internetcomputer.org/docs/current/references/ic-interface-spec#certification
      certificate : Blob;

      // CBOR encoded hash_tree
      hash_tree : Blob;
    };

}