import Iter "mo:core/Iter";
import Order "mo:core/Order";
import Map "mo:core/Map";
import List "mo:core/List";
import Nat "mo:core/Nat";
import Result "mo:core/Result";

module {
    public type MapHandler<K,V> = {
        put: (K, V) -> ();
        get: K -> ?V;
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

    public type ParseListing = {
        tokenId: Nat;
        listingId: Nat;
    };

    public type MarketplaceVault = actor {
        createListing: (Account, Principal, [Nat]) -> async [Result.Result<ParseListing, NFTTransferFromError>];
        placeBid: (Nat, Account, Nat) -> async Result.Result<(),()>;
        completeListing: Nat -> async Result.Result<(),()>;
        cancelListing: Nat -> async Result.Result<(),()>;
    };

    public type NFTActor = actor {
        icrc7_tokens_of: query (Account, ?Nat, ?Nat) -> async [Nat];
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

    
    public type NFTMarketplace = {
        listings: [(Nat, Listing)];
        royalty : Nat;
        launchId: Nat;
        launches: [(Nat, LaunchTypes)];
        failedTimers: [(Nat, Result.Result<(),()>)];
        stateChanges: [ResultDiff];
    };

    public type LaunchTypes = {
        #Live: Launch; 
        #Cancelled: CancelledLaunch;
    };

    public type Launch = {
        id: Nat;
        seller: Account;
        caller: Principal;
        tokenIds: [Nat];
        listIds: [Nat];
        maxListed: ?Nat;
        listedAt: Int;
        endsAt: ?Int;
        price: Nat;
        quoteAsset: AcceptedCryptos;
    };

    public type CancelledLaunch = Launch and {
        cancelledBy: Account;
        cancelledAt: Int;
        reason: CancelledReason;
        cancelledResults: [Result.Result<(),()>];
    };

    public type Listing = {
        id: Nat;
        collectionId: Principal;
        tokenId: Nat;
        listedAt: Int;
        seller: Account;
        quoteAsset: AcceptedCryptos;
        timerId: ?Nat;
        status: ListingStatus;
    };

    public type AcceptedCryptos = {
        #HUSD;
    };

    public type Account = {
        owner: Principal;
        subaccount: ?Blob;
    };

    public type ListingStatus = {
        #LiveFixedPrice: FixedPrice;
        #CancelledFixedPrice: CancelledFixedPrice;
        #SoldFixedPrice: SoldFixedPrice;
        #LiveAuction: Auction;
        #SoldAuction: SoldAuction;
        #CancelledAuction: CancelledAuction;
    };

    public type FixedPrice = {
        price : Nat;
        expiresAt: ?Int;
    };

    public type FixedPriceCArg = {
        tokenIds: [Nat];
        seller_subaccount: ?Blob;
        price: Nat;
        expiresAt: ?Nat;
        quoteAsset: ?AcceptedCryptos;
        collectionId: Principal;
    };

    public type FixedPriceUArg = {
        listingId: Nat;
        price: ?Nat;
        expiresAt: ?Nat;
    };

    public type CancelledFixedPrice = FixedPrice and {
        cancelledBy: Account;
        cancelledAt: Int;
        reason: CancelledReason;
    };

    public type SoldFixedPrice = FixedPrice and {
        bid: Bid;
        royaltyBps: ?Nat; // Basis points, e.g. 250 = 2.5%
    };

    public type Auction = {
        startingPrice: Nat;
        buyNowPrice: ?Nat;
        bidIncrement: Nat;
        reservePrice: ?Nat;
        startTime: Int;
        endsAt: Nat;
        highestBid: ?Bid;
        previousBids: [Bid];
        refunds: [Refund];
    };

    public type AuctionCArg = {
        collectionId: Principal;
        tokenId: [Nat];
        seller_subaccount: ?Blob;
        startingPrice: Nat;
        buyNowPrice: ?Nat;
        reservePrice: ?Nat;
        startTime: Int;
        endsAt: Nat;
    };

    public type AuctionUArg = {
        listingId: Nat;
        startingPrice: ?Nat;
        buyNowPrice: ?Nat;
        reservePrice: ?Nat;
        startTime: ?Nat;
        endsAt: ?Nat;
    };

    public type SoldAuction = Auction and {
        auctionEndTime: Int;
        soldFor: Nat;
        boughtNow: Bool;
        buyer: Account;
        royaltyBps: ?Nat;
    };

    public type CancelledAuction = Auction and {
        cancelledBy: Account;
        cancelledAt: Int;
        reason: CancelledReason;
    };



    public type CancelledReason = {
        #CancelledBySeller;
        #Expired;
        #CalledByAdmin;
        #ReserveNotMet;
        #NoBids;
    };

    public type LaunchCArg = {
        collectionId: Principal;
        maxListed: ?Nat;
        price: Nat;
        endsAt: ?Nat;
        seller_subaccount: ?Blob;
        quoteAsset: ?AcceptedCryptos;
    };

    public type LaunchUArg = {
        launchId: Nat;
        price: ?Nat;
        endsAt: ?Nat;
    };

    public type BidArg = {
        listingId: Nat;
        bidAmount: Nat;
        buyer_subaccount: ?Blob;
    };

    public type Bid = {
        bidAmount: Nat;
        buyer: Account;
        bidTime: Int;
    };

    public type Refund = {
        #Err: Ref;
        #Ok: Ref;
    };

    public type Ref = {
        id: Nat;
        asset: AcceptedCryptos;
        from: Account;
        to: Account;
        amount: Nat;
        attempted_at: Int;
    };

    public type CancelArg = {
        cancelledBy_subaccount: ?Blob;
        listingId: Nat;
        reason: CancelledReason;
    };

    public type ResultDiff = {
        id: ?Nat;
        before: State;
        after: State;
        arg: Action;
        result: Result.Result<(),()>;
    };

    public type State = {
        #Launch: ?LaunchTypes;
        #Listing: ?Listing;
    };  

    public type Action = {
        #FixedPrice: ActionEnum<FixedPriceCArg, FixedPriceUArg>;
        #Auction: ActionEnum<AuctionCArg, AuctionUArg>;
        #Launch: ActionEnum<LaunchCArg, LaunchUArg>;
        #Bid: BidArg;
        #EndListing: Nat;
        #CancelListing: CancelArg;
        #CancelLaunch: Nat;
    };

    public type ActionEnum<C, U> = {
        #Create: C;
        #Update: U;
    };



}