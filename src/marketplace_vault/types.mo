import Iter "mo:core/Iter";
import Order "mo:core/Order";
import Map "mo:core/Map";
import List "mo:core/List";
import Nat "mo:core/Nat";

module {
    public type MapHandler<K,V> = {
        put: (K, V) -> ();
        get: K -> ?V;
        remove: K -> ();
        entries: () -> Iter.Iter<(K, V)>;
    };
    public func createMapHandler<K,V>(compare: (K, K) -> Order.Order, map: Map.Map<K,V>): MapHandler<K,V>{
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
        }
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
        toArray : () -> [T];                        // snapshot as array
        find : (T -> Bool) -> ?T;                   // first matching element
        zip : <A, B>(List.List<A>, List.List<B>) -> ListHandler<(A, B)>; //create a tuple list from two lists
    };

    public func createListHandler<T>(list : List.List<T>) : ListHandler<T> {
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

                createListHandler(out)
            };
        };
    };
  
    public type TokenActor = actor {
      //fee and balance
      icrc1_balance_of: query (Account) -> async Nat;
      icrc1_fee: query() -> async Nat;
      icrc1_transfer: shared (TokenTransferArg) -> async TokenTransferResult;
      icrc2_transfer_from: shared (TokenTransferFromArgs) -> async TokenTransferFromResult;
    };

    public type TokenTransferResult = {
      #Ok : Nat;
      #Err : TokenTransferError;
    };

    public type TokenTransferFromResult = {
        #Ok : Nat;
        #Err : TokenTransferFromError;
    };

    public type TokenBaseError = {
        #Unauthorized;
      #BadFee : { expected_fee : Nat };
        #InsufficientFunds : { balance : Nat };
        #TooOld;
        #CreatedInFuture : { ledger_time : Nat64 };
        #Duplicate : { duplicate_of : Nat };
        #TemporarilyUnavailable;
        #GenericError : { error_code : Nat; message : Text };
    };

    public type TokenTransferError = TokenBaseError or {
      #BadBurn : { min_burn_amount : Nat };
    };

    public type TokenTransferFromError = TokenTransferError or {
      #InsufficientAllowance : { allowance : Nat };
    };

    public type TokenGenericTransferArg = {
      amount : Nat;
      fee : ?Nat;
      memo : ?Blob;
      created_at_time : ?Nat64;
    };

    public type TokenTransferArg = TokenGenericTransferArg and {
      to : Account;
      from_subaccount : ?Blob;
    };

    public type TokenTransferFromArgs = TokenGenericTransferArg and {
      to : Account;
      spender_subaccount : ?Blob;
      from : Account;
    };


    public type NFTActor = actor {
        icrc37_transfer_from: shared ([NFTTransferFromArg]) -> async [ ?NFTTransferFromResult ];
        icrc7_transfer: shared ([NFTTransferArg]) -> async [ ?NFTTransferResult ];
    };

    public type NFTTransferFromResult = {
        #Ok : Nat; // Transaction index for successful transfer
        #Err : NFTTransferFromError;
    };

    public type NFTBaseError = {
        #TooOld;
        #CreatedInFuture : {ledger_time: Nat64};
        #GenericError : {error_code : Nat; message : Text};
        #GenericBatchError : {error_code : Nat; message : Text};
    };

    public type NFTStandardError = NFTBaseError or {
        #Unauthorized;
        #NonExistingTokenId;
    };

    public type NFTTransferError = NFTStandardError or {
        #InvalidRecipient;
        #Duplicate : {duplicate_of : Nat};
    };

    public type NFTTransferFromError = NFTTransferError;

    public type Account = {
        owner: Principal;
        subaccount: ?Blob;
    };

    public type NFTTransferFromArg = {
        spender_subaccount: ?Blob; // The subaccount of the caller (used to identify the spender) - essentially equivalent to from_subaccount
        from : Account;
        to : Account;
        token_id : Nat;
        memo : ?Blob;
        created_at_time : ?Nat64;
    };

    public type NFTTransferArg = {
        token_id : Nat;
        from_subaccount : ?Blob;
        memo: ?Blob;
        created_at_time: ?Nat64;
        to: Account;
    };

    public type NFTTransferResult = {
        #Ok : Nat; // Transaction index for successful transfer
        #Err : NFTTransferError;
    };

    public type Bid = {
        bidder: Account;
        amount: Nat; //e8
    };

    public type Listing = {
        seller: Account;
        nftId: Nat;
        collection: Principal;
        bid: ?Bid;
    };
}