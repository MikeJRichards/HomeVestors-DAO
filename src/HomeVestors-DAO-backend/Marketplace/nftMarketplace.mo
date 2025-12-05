import Types "../Utils/types";
import Stables "../Utils/stables";
import UnstableTypes "../Utils/unstableTypes";
import NFT "nft";
import Tokens "token";
import Time "mo:base/Time";
import Principal "mo:base/Principal";
import Array "mo:base/Array";
import Result "mo:base/Result";
import Option "mo:base/Option";
import Int "mo:base/Int";
import Buffer "mo:base/Buffer";
import Nat "mo:base/Nat";
import HashMap "mo:base/HashMap";
import { setTimer; cancelTimer } = "mo:base/Timer";
import Handler "../Utils/applyHandler";
import CrudHandler "../Utils/crudHandler";
import Utils "../Utils/utils";



module {
   // type TransferFromArg = Types.TransferFromArg;
    type NFTMarketplace = Types.NFTMarketplace;
    type Listing = Types.Listing;
    type Account = Types.Account;
    type AcceptedCryptos = Types.AcceptedCryptos;
    type FixedPrice = Types.FixedPrice;
    type Auction = Types.Auction;
    type SoldAuction = Types.SoldAuction;
    type Bid = Types.Bid;
    type FixedPriceCArg = Types.FixedPriceCArg;
    type FixedPriceUArg = Types.FixedPriceUArg;
    type AuctionCArg = Types.AuctionCArg;
    type AuctionUArg = Types.AuctionUArg;
    type SoldFixedPrice = Types.SoldFixedPrice;
    type BidArg = Types.BidArg;
    type Property = Types.Property;
    type UpdateResult = Types.UpdateResult;
    type MarketplaceIntent = Types.MarketplaceIntent;
    type MarketplaceIntentResult = Types.MarketplaceIntentResult;
    type CancelArg = Types.CancelArg;
    type CancelledFixedPrice = Types.CancelledFixedPrice;
    type CancelledAuction = Types.CancelledAuction;
    type UpdateError = Types.UpdateError;
    type MarketplaceOptions = Types.MarketplaceOptions;
    type NftMarketplacePartialUnstable = UnstableTypes.NftMarketplacePartialUnstable;
    type Arg = Types.Arg<Property, Types.PropertyWhats>;
    type ListingUnstable = UnstableTypes.ListingUnstable;
    type Actions<C, U> = Types.Actions<C, U>;
    type What = Types.What;
    type TransferFromArg = Types.TransferFromArg;
    type CrudHandler<K, C, U, T, StableT> = UnstableTypes.CrudHandler<K, C, U, T, StableT>;
    type Handler<P, K, A, T, StableT> = UnstableTypes.Handler<P, K, A, T, StableT>;

    public func createTimers<system>(arg: Arg, m: NftMarketplacePartialUnstable, arr: [Result.Result<?Nat, (?Nat, UpdateError)>], create: Bool): async (){
        let addTimer = func<system>(id: Nat, delay: Nat, what: What):(){
            let timerId = setTimer<system>(#nanoseconds delay, func () : async () {
                let whatWithPropertyId: Types.WhatWithPropertyId = {
                   propertyId = arg.parent.id;
                   what; 
                };
                ignore arg.handlePropertyUpdate(whatWithPropertyId, arg.caller);
            }); 
            m.timerIds.put(id, timerId);
        };
        
        for(res in arr.vals()){
            switch(res){
                case(#ok(?id)){
                    switch(m.listings.get(id)){
                        case(?#LiveFixedPrice(fixedPrice)){
                            switch(fixedPrice.expiresAt){
                                case(null) cancelListingTimer(m, id);
                                case(?expiresAt){
                                    cancelListingTimer(m, id);
                                    if(create) addTimer<system>(id, Int.abs(expiresAt - Time.now()), #NftMarketplace(#FixedPrice(#Delete([id]))));
                                }
                            };
                        };
                        case(?#LiveAuction(auction)){
                            cancelListingTimer(m, id);
                            if(create) addTimer<system>(id, Int.abs(auction.endsAt - Time.now()), #NftMarketplace(#Auction(#Delete([id]))));
                        };
                        case(?#LaunchedProperty(launch)){
                            cancelListingTimer(m, id);
                            switch(launch.endsAt){case(null){}; case(?endsAt) if(create) addTimer<system>(id, Int.abs(endsAt - Time.now()), #NftMarketplace(#Launch(#Delete([id]))))};
                        };
                        case(_){};
                    }
                };
                case(_){};
            }
        };
    };

    public func cancelListingTimer(m: NftMarketplacePartialUnstable, listId: Nat): (){
        switch(m.timerIds.get(listId)){
            case(null){}; 
            case(?id) cancelTimer(id)
        };
    };

    public func bulkTransferToLaunch<A>(canisterId: Principal, arr: [(?Nat, A, Result.Result<ListingUnstable, UpdateError>)], stageTokens: (Nat, [(Nat, Result.Result<(), UpdateError>)]) -> ()): async [Result.Result<(), UpdateError>]{
        let results = Buffer.Buffer<Result.Result<(), UpdateError>>(0);
        for((idOpt, arg, res) in arr.vals()){
            switch(idOpt, res){
                case(null, _) results.add(#err(#InvalidElementId));
                case(?_, #err(e)) results.add(#err(e));
                case(?id, #ok(el)){
                    switch(el){
                        case(#LaunchedProperty(launch)){
                            let args = Buffer.Buffer<Types.TransferArg>(0);
                            let tokenIds = await NFT.tokensOf(canisterId, {owner = Principal.fromText("vq2za-kqaaa-aaaas-amlvq-cai"); subaccount = null}, null, ?launch.maxListed);
                            if(tokenIds.size() == 0) results.add(#err(#GenericError))
                            else{
                                for(tokenId in tokenIds.vals()){
                                    args.add(NFT.createTransferArg(tokenId, null, {owner= Principal.fromText("vq2za-kqaaa-aaaas-amlvq-cai"); subaccount = null}));
                                };
                                let transferResults = await NFT.transferBulk(canisterId, Buffer.toArray(args));
                                let okCount = Array.filter<?Types.TransferResult>(transferResults, func(res) {
                                    switch (res) {
                                        case (?#Ok(_)) true;
                                        case (_) false;
                                    }
                                }).size();
                                if(okCount > 0){
                                    let tokenTransferResults = Buffer.Buffer<(Nat, Result.Result<(), UpdateError>)>(tokenIds.size());
                                    for(i in transferResults.keys()){
                                        let result : Result.Result<(), UpdateError> = switch(transferResults[i]){
                                            case(null) #err(#Transfer(null));
                                            case(?#Err(e)) #err(#Transfer(?e));
                                            case(?#Ok(_)) #ok();
                                        };
                                        tokenTransferResults.add((tokenIds[i], result));
                                    };
                                    results.add(#ok());
                                    stageTokens(id, Buffer.toArray(tokenTransferResults));
                                }
                                else {
                                    let result : Result.Result<(), UpdateError> = switch(transferResults[0]){
                                        case(null) #err(#Transfer(null));
                                        case(?#Err(e)) #err(#Transfer(?e));
                                        case(?#Ok(_)) #ok();
                                    };
                                    results.add(result);
                                };
                            };
                        };
                        case(_){};
                    }
                }
            }
        }; 
        Buffer.toArray(results);
    };

    public func bulkTransferFromSeller<A>(canisterId: Principal, arr: [(?Nat, A, Result.Result<ListingUnstable, UpdateError>)]): async [Result.Result<(), UpdateError>] {
        let args = Buffer.Buffer<TransferFromArg>(0);
        let results = Buffer.Buffer<Result.Result<(), UpdateError>>(0);
        let acc = { 
            owner = Principal.fromText("vq2za-kqaaa-aaaas-amlvq-cai"); 
            subaccount = null 
        };
        for ((_, arg, res) in arr.vals()) {
            switch res {
                case (#err(e)) results.add(#err(e));
                case (#ok(el)) {
                    switch (el) {
                        case (#LiveFixedPrice(fixedPrice)) args.add(NFT.createTransferFromArg(fixedPrice.seller, acc, fixedPrice.tokenId));
                        case (#LiveAuction(auction)) args.add(NFT.createTransferFromArg(auction.seller, acc, auction.tokenId));
                        case (_) {};
                    };
                };
            };
        };

        let transferResults = await NFT.transferFromBulk(canisterId, Buffer.toArray(args));

        for (r in transferResults.vals()) {
            let result: Result.Result<(), UpdateError> = switch (r) {
                case (null) #err(#Transfer(null));
                case (?#Err(e)) #err(#Transfer(?e));
                case (?#Ok(_)) #ok();
            };
            results.add(result);
        };

        Buffer.toArray(results);
    };

    public func bulkTransferToSeller<A>(canisterId: Principal, arr: [(?Nat, A, Result.Result<ListingUnstable, UpdateError>)]): async [Result.Result<(), UpdateError>] {
        let args = Buffer.Buffer<Types.TransferArg>(0);
        let results = Buffer.Buffer<Result.Result<(), UpdateError>>(0);

        for ((_, _, res) in arr.vals()) {
            switch res {
                case (#err(e)) results.add(#err(e));
                case (#ok(el)) {
                    switch (el) {
                        case (#LiveFixedPrice(fixedPrice)) args.add(NFT.createTransferArg(fixedPrice.tokenId, null, fixedPrice.seller));
                        case (#LiveAuction(auction)) args.add(NFT.createTransferArg(auction.tokenId, null, auction.seller));
                        case (_) {};
                    };
                };
            };
        };

        let transferResults = await NFT.transferBulk(canisterId, Buffer.toArray(args));

        for (r in transferResults.vals()) {
            let result: Result.Result<(), UpdateError> = switch (r) {
                case (null) #err(#Transfer(null));
                case (?#Err(e)) #err(#Transfer(?e));
                case (?#Ok(_)) #ok();
            };
            results.add(result);
        };

        Buffer.toArray(results);
    };



    public func createFixedPriceHandlers(arg: Arg, action: Actions<FixedPriceCArg, FixedPriceUArg>):async UpdateResult {
        type P = Property;
        type K = Nat;
        type C = FixedPriceCArg;
        type U = FixedPriceUArg;
        type A = Types.AtomicAction<K, C, U>;
        type T = ListingUnstable;
        type StableT = Listing;
        type S = UnstableTypes.NftMarketplacePartialUnstable;
        let marketplace = Stables.toPartialStableNftMarketplace(arg.parent.nftMarketplace);
        let map = marketplace.listings;
        var tempId = marketplace.listId + 1;
        let crudHandler : CrudHandler<K, C, U, T, StableT> = {
            map = marketplace.listings;
            getId = func() = marketplace.listId;
            createTempId = func(){
              tempId += 1;
              tempId;
            };
            incrementId = func(){marketplace.listId += 1;};
            assignId = func(id: Nat, el: StableT): (Nat, StableT){
                switch(el){
                    case(#LiveFixedPrice(element)) return (id, #LiveFixedPrice({element with id = id}));
                    case(_) (id, el);
                };
            };

            delete =  func(id: Nat, el: StableT): (){
                let determineCancelledReason = func(fixedPrice: FixedPrice, caller: ?Principal): ?Types.CancelledReason {
                    let cancelledBySeller = caller == ?fixedPrice.seller.owner;
                    let cancelledByAdmin = caller == ?Utils.getAdmin(); 
                    let expired = switch(fixedPrice.expiresAt){case(null) false; case(?e) Time.now() > e ;};
                    return if(expired) ?#Expired else if (cancelledBySeller) ?#CancelledBySeller else if (cancelledByAdmin) ?#CalledByAdmin else null;
                };
                switch(el){
                    case(#LiveFixedPrice(fixedPrice)){
                        let resolvedCaller = switch(fixedPrice.expiresAt){case(null) ?arg.caller; case(?e) if(Time.now() > e) null else ?arg.caller};
                        let cancelledReason = determineCancelledReason(fixedPrice, resolvedCaller);
                        switch(cancelledReason){
                            case(null) marketplace.listings.put(id, el);
                            case(?reason){
                                cancelListingTimer(marketplace, id);
                                let cancelled = #CancelledFixedPrice({
                                    fixedPrice with
                                    cancelledBy = {owner = arg.caller; subaccount = null};
                                    cancelledAt = Time.now();
                                    reason = reason;
                                });
                                marketplace.listings.put(id, cancelled);
                            };
                        };
                    };
                    case(_){};
                };
            };
            fromStable = Stables.fromStableListing;
            create = func(args: C, id: Nat): T {
                #LiveFixedPrice({
                    var tokenId = args.tokenId;
                    var price = args.price;
                    var expiresAt = args.expiresAt;
                    var id = id;
                    var listedAt = Time.now();
                    var seller = {owner = arg.caller; subaccount = args.seller_subaccount};
                    var quoteAsset = Utils.get(args.quoteAsset, #ICP); 
                });
            };
            mutate = func(arg: U, el: T): T {
                switch(el){
                    case(#LiveFixedPrice(fixedPrice)){
                        fixedPrice.price := Utils.get(arg.price, fixedPrice.price);
                        fixedPrice.quoteAsset := Utils.get(arg.quoteAsset, fixedPrice.quoteAsset);
                        fixedPrice.expiresAt := Utils.getNullable(arg.expiresAt, fixedPrice.expiresAt);
                        #LiveFixedPrice(fixedPrice);
                    };
                    case(_) el;
                };
            };
            validate = func(el: ?T): Result.Result<T, UpdateError>{
                switch(el){
                    case(?#LiveFixedPrice(fixedPrice)){
                        let time = Time.now();
                        //if(Principal.notEqual(caller, arg.seller.owner)) return #err(#Unauthorized);
                        if(fixedPrice.price == 0) return #err(#InvalidData{field = "price"; reason = #CannotBeZero});
                        if(Option.get(fixedPrice.expiresAt, time) < time) return #err(#InvalidData{field= "expires at"; reason = #CannotBeSetInThePast});
                        return #ok(#LiveFixedPrice(fixedPrice));
                    };
                    case(null) return #err(#InvalidElementId);
                    case(_) return #err(#InvalidType);
                }

            };
        };

        let handler: Handler<P, K, A, T, StableT> = {
            isConflict =  CrudHandler.isConflictOnNatId();
            validateAndPrepare = func(parent: P, arg: Types.AtomicAction<K, C, U>) = CrudHandler.getValid<K, C, U, T, StableT>(arg, crudHandler);
            asyncEffect = func(arr: [(?K, A, Result.Result<T, UpdateError>)]): async [Result.Result<(), UpdateError>] {
                if(arg.testing) return Handler.runNoAsync<K, A, T>(arr);
                switch(action){
                    case(#Create(_)) await bulkTransferFromSeller(marketplace.collectionId, arr);
                    case(#Update(_)) Handler.runNoAsync(arr);//Call no async effect here
                    case(#Delete(_)) await bulkTransferToSeller(marketplace.collectionId, arr);
                };
            };

            applyAsyncEffects = func(idOpt: ?K, res: Result.Result<T, Types.UpdateError>): [(?K, Result.Result<StableT, UpdateError>)]{
                switch(idOpt, res){
                    case(null, _) return [(null, #err(#InvalidElementId))];
                    case(?id, #ok(el)) return [(idOpt, #ok(Stables.toStableListing(el)))];
                    case(?id, #err(e)) return [(idOpt, #err(e))];
                };
            };

            applyUpdate = func(id: ?K, arg:A, el: StableT) = CrudHandler.applyUpdate<K, C, U, T, StableT>(arg, id, el, crudHandler);

            finalAsync = func(arr: [(A, [Result.Result<?Nat, (?Nat, UpdateError)>])]): async (){
                if(arg.testing) return;
                for((args, res) in arr.vals()){
                    switch(args){
                        case(#Create(_) or #Update(_)) ignore createTimers(arg, marketplace, res, true);
                        case(#Delete(_)) ignore createTimers(arg, marketplace, res, false);
                    }
                }
            };
            toStruct = CrudHandler.toStruct<P, K, C, U, T, StableT>(func(stableT: ?StableT) = #NftMarketplace(stableT), func(property: Property) = property.nftMarketplace.listings, Nat.equal);
            applyParentUpdate = func(property: P): P {{property with nftMarketplace = Stables.fromPartialStableNftMarketplace(marketplace)}};
            updateParentEventLog = Handler.updatePropertyEventLog;
            toArgDomain = CrudHandler.atomicActionToWhat(func(a: Types.Actions<C,U>): Types.What = #NftMarketplace(#FixedPrice(a)));
        };
        await Handler.applyHandler<P, K, A, T, StableT>(arg, CrudHandler.makeAutomicAction(action, map.size()), handler);
    };

    public func createAuctionHandlers(arg: Arg, action: Actions<AuctionCArg, AuctionUArg>): async UpdateResult {
        type P = Property;
        type K = Nat;
        type C = AuctionCArg;
        type U = AuctionUArg;
        type A = Types.AtomicAction<K, C, U>;
        type T = ListingUnstable;
        type StableT = Listing;
        type S = UnstableTypes.NftMarketplacePartialUnstable;
        let marketplace = Stables.toPartialStableNftMarketplace(arg.parent.nftMarketplace);
        let map =  marketplace.listings;
        var tempId = marketplace.listId + 1;
        let crudHandler : CrudHandler<K, C, U, T, StableT> = {
            map;
            getId = func() = marketplace.listId;
            createTempId = func(){
              tempId += 1;
              tempId;
            };
            incrementId = func(){marketplace.listId += 1;};
            assignId = func(id: Nat, el: StableT): (Nat, StableT){
                switch(el){
                    case(#LiveAuction(element)){
                        switch(mockTimerIds.get(element.id)){
                            case(null){};
                            case(?timerId) marketplace.timerIds.put(id, timerId); 
                        };
                        return (id, #LiveAuction({element with id = id}));
                    };
                    case(_) (id, el);
                };
            };

            delete =  func(id: Nat, el: StableT): (){
                let determineCancelledReason = func(auction: Auction, caller: ?Principal): ?Types.CancelledReason {
                    let cancelledBySeller = caller == ?auction.seller.owner;
                    let cancelledByAdmin = caller == ?Utils.getAdmin(); 
                    let expired = Time.now() > auction.endsAt;
                    switch(auction.highestBid, auction.reservePrice){
                        case(?bid, ?reservePrice) if(reservePrice > bid.bidAmount and expired) ?#ReserveNotMet else if(cancelledByAdmin) ?#CalledByAdmin else null;
                        case(?_, null) if(cancelledByAdmin) ?#CalledByAdmin else null;
                        case(null, _) if(expired) ?#Expired else if(cancelledBySeller) ?#CancelledBySeller else if(cancelledByAdmin) ?#CalledByAdmin else null;
                    }
                };
                switch(el){
                    case(#LiveAuction(auction)){
                        let cancelledReason = determineCancelledReason(auction, ?arg.caller);
                        switch(cancelledReason){
                            case(null) marketplace.listings.put(id, el);
                            case(?reason){
                                cancelListingTimer(marketplace, id);
                                let cancelled = #CancelledAuction({
                                    auction with
                                    cancelledBy = {owner = arg.caller; subaccount = null};
                                    cancelledAt = Time.now();
                                    reason = reason;
                                });
                                marketplace.listings.put(id, cancelled);
                            };
                        };
                    };
                    case(_){};
                };
            };

            fromStable = Stables.fromStableListing;
            
            create = func(args: C, id: Nat): T {
               let auction = #LiveAuction({
                    args with 
                    id;
                    listedAt = Time.now();
                    seller = {owner = arg.caller; subaccount = null};
                    quoteAsset = Utils.get(args.quoteAsset, #ICP);
                    bidIncrement = 1;
                    highestBid = null;
                    previousBids = [];
                    refunds = [];
                });
                Stables.fromStableListing(auction);
            };

            mutate = func(arg: U, el: T): T {
                switch(el){
                    case(#LiveAuction(auction)){
                        auction.startingPrice   := Utils.get(arg.startingPrice, auction.startingPrice);
                        auction.startTime       := Utils.get(arg.startTime, auction.startTime);
                        auction.endsAt          := Utils.get(arg.endsAt, auction.endsAt);
                        auction.quoteAsset      := Utils.get(arg.quoteAsset, auction.quoteAsset);
                        auction.buyNowPrice     := Utils.getNullable(arg.buyNowPrice, auction.buyNowPrice);
                        auction.reservePrice    := Utils.getNullable(arg.reservePrice, auction.reservePrice);
                        
                        #LiveAuction(auction);
                    };
                    case(_) el;
                };
            };

            validate = func(el: ?T): Result.Result<T, UpdateError>{
                switch(el){
                    case(?#LiveAuction(args)){
                        if(Principal.notEqual(arg.caller, args.seller.owner)) return #err(#Unauthorized);
                        if(Option.get(args.buyNowPrice, args.startingPrice) < args.startingPrice) return #err(#InvalidData{field= "buy now price"; reason = #InvalidInput});
                        if(args.bidIncrement < 1) return #err(#InvalidData{field= "bid increment"; reason = #InvalidInput});
                        if(Option.get(args.reservePrice, args.startingPrice) > Option.get(args.buyNowPrice, args.startingPrice)) return #err(#InvalidData{field= "reserve price"; reason = #InvalidInput});
                        if(args.startTime > args.endsAt) return #err(#InvalidData{field= "start time"; reason = #OutOfRange});
                        if(args.highestBid != null) return #err(#ImmutableLiveAuction);
                        if(args.endsAt < Time.now()) return #err(#InvalidData{field= "end time"; reason = #CannotBeSetInThePast});
                        return #ok(#LiveAuction(args))
                    };
                    case(null) return #err(#InvalidElementId);
                    case(_) return #err(#InvalidType);
                };    
               
            };
        };

        let mockTimerIds = HashMap.HashMap<Nat, Nat>(0, Nat.equal, Utils.natToHash);


        let handler: Handler<P, K, A, T, StableT> = {
            isConflict =  CrudHandler.isConflictOnNatId();
            validateAndPrepare = func(parent: P, arg: Types.AtomicAction<K, C, U>) = CrudHandler.getValid<K, C, U, T, StableT>(arg, crudHandler);

            
            asyncEffect = func(arr: [(?K, A, Result.Result<T, UpdateError>)]): async [Result.Result<(), UpdateError>] {
                if(arg.testing) return Handler.runNoAsync<K, A, T>(arr);
                switch(action){
                    case(#Create(_)) await bulkTransferFromSeller(marketplace.collectionId, arr);
                    case(#Update(_)) Handler.runNoAsync(arr);//Call no async effect here
                    case(#Delete(_)) await bulkTransferToSeller(marketplace.collectionId, arr);
                };
            };

            applyAsyncEffects = func(id: ?K, res: Result.Result<T, Types.UpdateError>): [(?K, Result.Result<StableT, UpdateError>)]{
                switch(id, res){
                    case(null, _) return [(null, #err(#InvalidElementId))];
                    case(?id, #ok(el)) return [(?id, #ok(Stables.toStableListing(el)))];
                    case(?id, #err(e)) return [(?id, #err(e))];
                };
            };
            applyUpdate = func(id: ?K, arg:A, el: StableT) = CrudHandler.applyUpdate<K, C, U, T, StableT>(arg, id, el, crudHandler);

            finalAsync = func(arr: [(A, [Result.Result<?Nat, (?Nat, UpdateError)>])]): async (){
                if(arg.testing) return;
                for((args, res) in arr.vals()){
                    switch(args){
                        case(#Create(_) or #Update(_)) ignore createTimers(arg, marketplace, res, true);
                        case(#Delete(_)) ignore createTimers(arg, marketplace, res, false);
                    }
                }
            };
            toStruct = CrudHandler.toStruct<P, K, C, U, T, StableT>(func(stableT: ?StableT) = #NftMarketplace(stableT), func(property: Property) = property.nftMarketplace.listings, Nat.equal);
            applyParentUpdate = func(property: P): P {{property with nftMarketplace = Stables.fromPartialStableNftMarketplace(marketplace)}};
            updateParentEventLog = Handler.updatePropertyEventLog;
            toArgDomain = CrudHandler.atomicActionToWhat(func(a: Types.Actions<C,U>): Types.What = #NftMarketplace(#Auction(a)));
        };
        await Handler.applyHandler<P, K, A, T, StableT>(arg, CrudHandler.makeAutomicAction(action, map.size()), handler);
    };

    public func createLaunchHandlers(arg: Arg, action: Actions<Types.LaunchCArg, Types.LaunchUArg>): async UpdateResult {
        type P = Property;
        type K = Nat;
        type C = Types.LaunchCArg;
        type U = Types.LaunchUArg;
        type A = Types.AtomicAction<K, C, U>;
        type T = ListingUnstable;
        type StableT = Listing;
        type S = UnstableTypes.NftMarketplacePartialUnstable;
        let marketplace = Stables.toPartialStableNftMarketplace(arg.parent.nftMarketplace);
        let parentChildId = HashMap.HashMap<Nat, Buffer.Buffer<Nat>>(0, Nat.equal, Utils.natToHash);
        let map = marketplace.listings;
        var tempId = marketplace.listId + 1;

        let crudHandler : CrudHandler<K, C, U, T, StableT> = {
            map;
            getId = func() = marketplace.listId;
            createTempId = func(){
              tempId += 1;
              tempId;
            };
            incrementId = func(){marketplace.listId += 1;};
            
            assignId = func(id: Nat, el: StableT): (Nat, StableT){
                switch(el){
                    case(#LaunchedProperty(element)){
                        parentChildId.put(id, Buffer.Buffer<Nat>(0));
                        return (id, #LaunchedProperty({element with id = id}));
                    };
                    case(#LaunchFixedPrice(element)){
                        switch(parentChildId.get(element.id)){
                            case(?buf){
                                buf.add(id);
                                parentChildId.put(element.id, buf);
                            };
                            case(null){
                                let buf = Buffer.Buffer<Nat>(0);
                                buf.add(id);                                
                                parentChildId.put(element.id, buf);
                            }
                        };
                        return (id, #LaunchFixedPrice({element with id = id}));
                    }; 
                    case(_) (id, el);
                };
            };

            delete =  func(id: Nat, el: StableT): (){
                switch(el){
                    case(#LaunchedProperty(launch)){
                        cancelListingTimer(marketplace, id);
                        let cancelled = #CancelledLaunchedProperty({
                            launch with
                            cancelledBy = {owner = arg.caller; subaccount = null};
                            cancelledAt = Time.now();
                            reason = #CalledByAdmin;
                        });
                        marketplace.listings.put(id, cancelled);
                    };
                    case(#LaunchFixedPrice(fixed)){
                        cancelListingTimer(marketplace, id);
                        let cancelled = #CancelledLaunch({
                            fixed with
                            cancelledBy = {owner = arg.caller; subaccount = null};
                            cancelledAt = Time.now();
                            reason = #CalledByAdmin;
                        });
                        marketplace.listings.put(id, cancelled);
                    };
                    case(_){};
                };
            };

            fromStable = Stables.fromStableListing;
            
            create = func(args: C, id: Nat): T {
                let listing = #LaunchedProperty{
                    id = marketplace.listId + 1;
                    seller = {owner = Principal.fromText("vq2za-kqaaa-aaaas-amlvq-cai"); subaccount = null};
                    caller = arg.caller;
                    tokenIds = [];
                    listIds = [];
                    maxListed = Option.get(args.maxListed, 1000);
                    listedAt = Time.now();
                    endsAt = args.endsAt;
                    price = args.price;
                    quoteAsset = Option.get(args.quoteAsset, #HGB);
                };
                Stables.fromStableListing(listing);
            };

            mutate = func(arg: U, el: T): T {
                switch(el){
                    case(#LaunchedProperty(launch)){
                        launch.price          := Utils.get(arg.price, launch.price);
                        launch.endsAt         := switch(arg.endsAt){case(?endAt) ?endAt; case(null) launch.endsAt};
                        launch.quoteAsset     := Utils.get(arg.quoteAsset, launch.quoteAsset);
                        #LaunchedProperty(launch);
                    };
                    case(#LaunchFixedPrice(fixedPrice)){
                        fixedPrice.price      := Utils.get(arg.price, fixedPrice.price);
                        fixedPrice.quoteAsset := Utils.get(arg.quoteAsset, fixedPrice.quoteAsset);
                        fixedPrice.expiresAt  := Utils.getNullable(arg.endsAt, fixedPrice.expiresAt);
                        #LaunchFixedPrice(fixedPrice)
                    };
                    case(_) el;
                };
            };

            validate = func(el: ?T): Result.Result<T, UpdateError>{
                switch(el){
                    case(?#LaunchFixedPrice(arg)){
                        let time = Time.now();
                        //if(Principal.notEqual(caller, arg.seller.owner)) return #err(#Unauthorized);
                        if(arg.price == 0) return #err(#InvalidData{field = "price"; reason = #CannotBeZero});
                        if(Option.get(arg.expiresAt, time) < time) return #err(#InvalidData{field= "expires at"; reason = #CannotBeSetInThePast});
                        return #ok(#LiveFixedPrice(arg));
                    };
                    case(?#LaunchedProperty(arg)){
                        let time = Time.now();
                        if(arg.maxListed == 0) return #err(#InvalidData{field = "max listed"; reason = #CannotBeZero});
                        if(Option.get(arg.endsAt, time) < time) return #err(#InvalidData{field= "expires at"; reason = #CannotBeSetInThePast});
                        if(arg.price == 0) return #err(#InvalidData{field = "price"; reason = #CannotBeZero});
                        return #ok(#LaunchedProperty(arg));
                    };
                    case(null) return #err(#InvalidElementId);
                    case(_) return #err(#InvalidType);
                };    
               
            };
        };

        type LaunchListingChildren = {
            id: Nat;
            transferResults: [(Nat, Result.Result<(), UpdateError>)]
        };

        let launchChildren = HashMap.HashMap<Nat, LaunchListingChildren>(0, Nat.equal, Utils.natToHash);
        let addChildren = func(id: Nat, transferResults: [(Nat, Result.Result<(), UpdateError>)]): (){
            launchChildren.put(id, {id; transferResults;})
        };


        let handler: Handler<P, K, A, T, StableT> = {
            isConflict =  CrudHandler.isConflictOnNatId();
            validateAndPrepare = func(parent: P, arg: Types.AtomicAction<K, C, U>) = CrudHandler.getValid<K, C, U, T, StableT>(arg, crudHandler);
            
            asyncEffect = func(arr: [(?K, A, Result.Result<T, UpdateError>)]): async [Result.Result<(), UpdateError>] {
                if(arg.testing) return Handler.runNoAsync<K, A, T>(arr);
                switch(action){
                    case(#Create(_)) await bulkTransferToLaunch<A>(marketplace.collectionId, arr, addChildren);
                    case(#Update(_)) Handler.runNoAsync(arr);//Call no async effect here
                    case(#Delete(_)) Handler.runNoAsync(arr);
                };
            };

            applyAsyncEffects = func(id: ?K, res: Result.Result<T, Types.UpdateError>): [(?K, Result.Result<StableT, UpdateError>)]{
                let elements = Buffer.Buffer<(?K, Result.Result<StableT, UpdateError>)>(0);
                switch(id, res, action){
                    case(null, _, _) elements.add((null, #err(#InvalidElementId)));
                    case(?parentId, #ok(#LaunchedProperty(launch)), #Create(_)){
                        switch(launchChildren.get(parentId)){
                            case(null) return [(?parentId, #ok(Stables.toStableListing(#LaunchedProperty(launch))))];
                            case(?children){
                                let tokenIds = Buffer.Buffer<Nat>(0);
                                for((tokenId, res) in children.transferResults.vals()){
                                    let fixedPrice = #LaunchFixedPrice({
                                        id = parentId;
                                        tokenId = tokenId;
                                        listedAt = Time.now();
                                        seller = launch.seller;
                                        quoteAsset = launch.quoteAsset;
                                        price = launch.price;
                                        expiresAt = launch.endsAt;
                                    });
                                    elements.add((id, #ok(fixedPrice)));
                                    tokenIds.add(tokenId);
                                };
                                launch.tokenIds := tokenIds;
                                elements.add((?parentId, #ok(Stables.toStableListing(#LaunchedProperty(launch)))));
                                
                            }
                        };
                    };
                    case(?_, #ok(#LaunchedProperty(launch)), #Update(_)){
                        for(id in launch.listIds.vals()){
                            switch(marketplace.listings.get(id)){
                                case(null){};
                                case(?#LaunchFixedPrice(fixed)){
                                    let fixedPrice = #LaunchFixedPrice({
                                        fixed with
                                        price = launch.price;
                                        endsAt = launch.endsAt;
                                        quoteAsset = launch.quoteAsset;
                                    });
                                    elements.add((?id, #ok(fixedPrice)));
                                };
                                case(_){};
                            };
                        }
                    };
                    case(?_, #ok(#CancelledLaunchedProperty(launch)), #Delete(_)){
                        for(id in launch.listIds.vals()){
                            switch(marketplace.listings.get(id)){
                                case(null){};
                                case(?#LaunchFixedPrice(fixedPrice)){
                                    let cancelled = #CancelledLaunch({
                                        fixedPrice with
                                        cancelledBy = launch.cancelledBy;
                                        cancelledAt = launch.cancelledAt;
                                        reason = launch.reason;
                                    });
                                    elements.add((?id, #ok(cancelled)));
                                };
                                case(_){};
                            };
                        }
                    };
                    case(_, #ok(listing), _) elements.add((id, #ok(Stables.toStableListing(listing))));
                    case(_, #err(e), _) elements.add((id, #err(e)));
                };
                Buffer.toArray(elements);
            };

            applyUpdate = func(id: ?K, arg:A, el: StableT) = CrudHandler.applyUpdate<K, C, U, T, StableT>(arg, id, el, crudHandler);

            finalAsync = func(arr: [(A, [Result.Result<?K, (?K, UpdateError)>])]): async (){
                if(arg.testing) return;
                for((args, res) in arr.vals()){
                    switch(args){
                        case(#Create(_)){
                            await createTimers(arg, marketplace, res, true);
                            var launched :?Types.Launch = null;
                            let buffer = Buffer.Buffer<Nat>(0);
                            for(result in res.vals()){
                                switch(result){
                                    case(#ok(?id)){
                                        switch(marketplace.listings.get(id)){
                                            case(?#LaunchedProperty(launch)) launched := ?launch;
                                            case(_) buffer.add(id);
                                        };
                                    };
                                    case(_){};
                                };
                            };
                            switch(launched){
                                case(?launch) marketplace.listings.put(launch.id, #LaunchedProperty({launch with listIds = Buffer.toArray(buffer)}));
                                case(null){};
                            };

                        }; 
                        case(#Update(_)) await createTimers(arg, marketplace, res, true);
                        case(#Delete(_)) await createTimers(arg, marketplace, res, false);
                    }
                }
            };
            toStruct = CrudHandler.toStruct<P, K, C, U, T, StableT>(func(stableT: ?StableT) = #NftMarketplace(stableT), func(property: Property) = property.nftMarketplace.listings, Nat.equal);
            applyParentUpdate = func(property: P): P {{property with nftMarketplace = Stables.fromPartialStableNftMarketplace(marketplace)}};
            updateParentEventLog = Handler.updatePropertyEventLog;
            toArgDomain = CrudHandler.atomicActionToWhat(func(a: Types.Actions<C,U>): Types.What = #NftMarketplace(#Launch(a)));
        };

        await Handler.applyHandler<P, K, A, T, StableT>(arg, CrudHandler.makeAutomicAction(action, map.size()), handler);
    };

    public func createBidHandlers(arg: Arg, args: BidArg): async UpdateResult {
        type P = Property;
        type K = Nat;
        type A = BidArg;
        type T = ListingUnstable;
        type StableT = Listing;
        let marketplace = Stables.toPartialStableNftMarketplace(arg.parent.nftMarketplace);
        let previousHighestBidder = HashMap.HashMap<Nat, Bid>(0, Nat.equal, Utils.natToHash);

        func verifyBid(arg: BidArg, bidMin: Nat, seller: Account, caller: Principal, endsAt: ?Int): Result.Result<Bid, UpdateError> {
            let bid = {buyer = {owner = caller; subaccount = null}; bidAmount = arg.bidAmount; bidTime = Time.now()};
            let time = Time.now();
            if(bid.buyer == seller) return #err(#InvalidData{field = "buyer"; reason = #BuyerAndSellerCannotMatch});
            if(bid.bidAmount < bidMin) return #err(#InsufficientBid{minimum_bid = bidMin});
            if(Option.get(endsAt, time) < time) return #err(#ListingExpired);
            #ok(bid)
        };

        let handler: Handler<P, K, A, T, StableT> = {
            isConflict =  func(arg1: A, arg2: A):Bool = arg1.listingId == arg2.listingId;
            
            validateAndPrepare = func(parent: P, args: A): (?K, A, Result.Result<T, Types.UpdateError>){
                let createSoldFixedPrice = func(fixed: FixedPrice): Result.Result<SoldFixedPrice, (?K, A, Result.Result<T, Types.UpdateError>)> {
                    switch(verifyBid(args, fixed.price, fixed.seller, arg.caller, fixed.expiresAt)){
                        case(#err(e)) return #err(?args.listingId, args, #err(e));
                        case(#ok(bid)){
                            return #ok({
                                fixed with
                                bid;
                                royaltyBps = ?(bid.bidAmount * marketplace.royalty / 100000);
                            });
                        }
                    };
                };
                
                let listing : Listing = switch(marketplace.listings.get(args.listingId)){
                    case(?#LaunchFixedPrice(fixed)) switch(createSoldFixedPrice(fixed)){case(#ok(el)) #SoldLaunchFixedPrice(el); case(#err(e)) return e};
                    case(?#LiveFixedPrice(fixed)) switch(createSoldFixedPrice(fixed)){case(#ok(el)) #SoldFixedPrice(el); case(#err(e)) return e};
                    case(?#LiveAuction(auction)){
                        switch(auction.highestBid){case(null){}; case(?bid)previousHighestBidder.put(args.listingId, bid)};
                        let minBidAmount = switch(auction.highestBid){case(?bid) bid.bidAmount + auction.bidIncrement; case(null) auction.startingPrice};
                        switch(verifyBid(args, minBidAmount, auction.seller, arg.caller, ?auction.endsAt)){
                            case(#err(e)) return (?args.listingId,args, #err(e));
                            case(#ok(bid)){
                                if(auction.buyNowPrice == ?bid.bidAmount){
                                    #SoldAuction({
                                        auction with
                                        auctionEndTime = Time.now();
                                        soldFor = args.bidAmount;
                                        boughtNow = true;
                                        buyer = {owner = arg.caller; subaccount = args.buyer_subaccount};
                                        royaltyBps = ?(args.bidAmount * marketplace.royalty / 100_000);
                                    });
                                } 
                                else{
                                    #LiveAuction({
                                        auction with
                                        highestBid = ?bid;
                                        previousBids = Array.append(auction.previousBids, [bid]);
                                    }); 
                                };
                            }
                        }
                    };
                    case(null) return (?args.listingId, args, #err(#InvalidElementId));
                    case(_) return (?args.listingId, args, #err(#InvalidType));
                };
                (?args.listingId, args, #ok(Stables.fromStableListing(listing)));
            };
            
            asyncEffect = func(arr: [(?K, A, Result.Result<T, UpdateError>)]): async [Result.Result<(), UpdateError>] {
                if(arg.testing) return Handler.runNoAsync<K, A, T>(arr);
                let calculateAmount = func(amount: Nat, royalty: ?Nat): Nat {
                    switch(royalty){
                        case(?royalty) if(amount > royalty) Nat.sub(amount, royalty) else 0;
                        case(null) amount;
                    }
                };
                
                let soldTransfers = func(buyer: Account, tokenId: Nat, asset: AcceptedCryptos, amount: Nat, seller: Account): async Result.Result<(), UpdateError>{
                    switch(await NFT.verifyTransfer(marketplace.collectionId, null, buyer, tokenId)){case(?#Ok(_)) {}; case(?#Err(e)) return #err(#Transfer(?e)); case(null) return #err(#Transfer(null))};
                    switch(await Tokens.transferFrom(asset, amount, seller, buyer)){case(#Ok(_)) {}; case(#Err(e)) return #err(#Transfer(?e))};
                    switch(await NFT.transfer(marketplace.collectionId, null, buyer, tokenId)){case(?#Ok(_)) return #ok(); case(?#Err(e)) return #err(#Transfer(?e)); case(null) return #err(#Transfer(null))};
                };
                let buffer = Buffer.Buffer<Result.Result<(), UpdateError>>(0);
                label processing for((id, args, res) in arr.vals()){
                    let result = switch(res){
                        case(#ok(#SoldLaunchFixedPrice(sold))) await soldTransfers(sold.bid.buyer, sold.tokenId, sold.quoteAsset, calculateAmount(sold.bid.bidAmount, sold.royaltyBps), sold.seller);
                        case(#ok(#SoldFixedPrice(sold))) await soldTransfers(sold.bid.buyer, sold.tokenId, sold.quoteAsset, calculateAmount(sold.bid.bidAmount, sold.royaltyBps), sold.seller);
                        case(#ok(#SoldAuction(sold))) await soldTransfers(sold.buyer, sold.tokenId, sold.quoteAsset, sold.soldFor, sold.seller); 
                        case(#ok(#LiveAuction(auction))){
                            switch(auction.highestBid){
                                case(?bid) await soldTransfers(bid.buyer, auction.tokenId, auction.quoteAsset, bid.bidAmount, auction.seller);
                                case(null) #ok();
                            }
                        };
                        case(#ok(_)) #err(#InvalidType);
                        case(#err(e)) #err(e);
                    };
                    buffer.add(result);
                };
                Buffer.toArray(buffer);
            };

            applyAsyncEffects = func(id: ?K, res: Result.Result<T, Types.UpdateError>): [(?K, Result.Result<StableT, UpdateError>)]{
                switch(res){
                    case(#err(e)) [(id, #err(e))];
                    case(#ok(el)) [(id, #ok(Stables.toStableListing(el)))];
                };
            };

            applyUpdate = func(idOpt: ?K, args: A, el: StableT) : ?K {
                switch(idOpt){
                    case(?id) {
                        marketplace.listings.put(args.listingId, el);
                        ?args.listingId;
                    };
                    case(null) ?args.listingId;
                }
            };


            finalAsync = func(arr: [(A, [Result.Result<?Nat, (?Nat, UpdateError)>])]): async (){
                if(arg.testing) return;
                func createRefund(id: Nat, asset: AcceptedCryptos, to: Account, amount: Nat): async Types.Refund {
                    let result = await Tokens.transferFromBackend(asset, amount, to, null);
            
                    let refund : Types.Ref = {
                        id;
                        from = {owner = Principal.fromText("vq2za-kqaaa-aaaas-amlvq-cai"); subaccount = null};
                        to;
                        amount;
                        asset;
                        attempted_at = Time.now();
                        result;
                    };
                    switch(result){
                        case(#Err(_)) #Err(refund);
                        case(#Ok(_)) #Ok(refund)
                    };
                };

                for((args, res) in arr.vals()){
                    for(result in res.vals()){
                        switch(result){
                            case(#ok(?id)){
                                switch(previousHighestBidder.get(id), marketplace.listings.get(id)){
                                    case(?previousBid, ?#LiveAuction(auction)){
                                        let refund = await createRefund(auction.refunds.size(), auction.quoteAsset, previousBid.buyer, previousBid.bidAmount);
                                        let updatedAuction = #LiveAuction({
                                            auction with 
                                            refunds = Array.append(auction.refunds, [refund]);
                                        });
                                        marketplace.listings.put(id, updatedAuction);
                                    };
                                    case(?previousBid, ?#SoldAuction(auction)){
                                        let refund = await createRefund(auction.refunds.size(), auction.quoteAsset, previousBid.buyer, previousBid.bidAmount);
                                        let updatedAuction = #SoldAuction({
                                            auction with 
                                            refunds = Array.append(auction.refunds, [refund]);
                                        });
                                        marketplace.listings.put(id, updatedAuction);
                                    };
                                    case(_){};
                                };
                            };
                            case(_){};
                        }
                    }
                }
            };
            toStruct = func(property: Property, idOpt: ?K, beforeOrAfter: UnstableTypes.BeforeOrAfter): Types.ToStruct<K> {
                switch(idOpt){
                    case(?id) #NftMarketplace(Utils.getElementByKey(property.nftMarketplace.listings, id, Nat.equal));
                    case(null) #Err(idOpt, #NullId);
                }
            };
            applyParentUpdate = func(property: P): P {{property with nftMarketplace = Stables.fromPartialStableNftMarketplace(marketplace)}};
            updateParentEventLog = Handler.updatePropertyEventLog;
            toArgDomain = func(a:A): Types.What = #NftMarketplace(#Bid(a));
        };
        await Handler.applyHandler<P, K, A, T, StableT>(arg, [args], handler);
    };





    public func createNFTMarketplace(collectionId: Principal): NFTMarketplace {
        {
            collectionId;
            listId = 0;
            listings = [];
            timerIds = [];
            royalty = 0;
        }
    };

    public func tagMatching(listing: Listing, optTag: ?[MarketplaceOptions]): Bool {
        let opts = switch(optTag){case(null) return true; case(?opt) opt};
        let tag: MarketplaceOptions = switch listing {
            case (#LaunchedProperty(_)) #PropertyLaunch;
            case (#CancelledLaunchedProperty(_)) #CancelledPropertyLaunch;
            case( #SoldLaunchFixedPrice(_)) #SoldLaunchFixedPrice;
            case (#LaunchFixedPrice(_)) #LaunchFixedPrice;
            case (#CancelledLaunch(_)) #CancelledLaunch;
            case (#LiveFixedPrice(_)) #LiveFixedPrice;
            case (#SoldFixedPrice(_)) #SoldFixedPrice;
            case (#CancelledFixedPrice(_)) #CancelledFixedPrice;
            case (#LiveAuction(_)) #LiveAuction;
            case (#SoldAuction(_)) #SoldAuction;
            case (#CancelledAuction(_)) #CancelledAuction;
        };
        for(opt in opts.vals()){
            if(opt == tag) return true;
        };
        return false;
    };

    public func getSeller(listing: Listing): [Account] {
        [switch(listing){
            case (#LaunchedProperty(arg)) arg.seller;
            case (#CancelledLaunchedProperty(arg)) arg.seller;
            case (#LaunchFixedPrice(arg)) arg.seller;
            case (#SoldLaunchFixedPrice(arg)) arg.seller;
            case (#CancelledLaunch(arg)) arg.seller;
            case (#LiveFixedPrice(arg)) arg.seller;
            case (#SoldFixedPrice(arg)) arg.seller;
            case (#CancelledFixedPrice(arg)) arg.seller;
            case (#LiveAuction(arg)) arg.seller;
            case (#SoldAuction(arg)) arg.seller;
            case (#CancelledAuction(arg)) arg.seller;
        }];
    };

    func getBiddersFromAuction(highestBid: ?Bid, arr: [Bid], allBidders: Bool): [Account]{
        let buffer = Buffer.Buffer<Account>(0);
        switch(highestBid){case(null){}; case(?bid) buffer.add(bid.buyer)};
        if(allBidders){
            for(bid in arr.vals()){
                buffer.add(bid.buyer);
            };
        };
        Buffer.toArray(buffer);
    };

    public func getBuyingAccounts(listing: Listing, allBidders: Bool): [Account] {
        switch(listing){
            case (#SoldLaunchFixedPrice(arg)) [arg.bid.buyer];
            case (#SoldFixedPrice(arg)) [arg.bid.buyer];
            case (#LiveAuction(arg)) getBiddersFromAuction(arg.highestBid, arg.previousBids, allBidders);
            case (#SoldAuction(arg)) getBiddersFromAuction(arg.highestBid, arg.previousBids, allBidders);
            case (#CancelledAuction(arg)) getBiddersFromAuction(arg.highestBid, arg.previousBids, allBidders);
            case(_) [];
        };
    };

    public func getAllBidders(listing:Listing): [Account] = getBuyingAccounts(listing, true);
    public func getBuyer(listing:Listing): [Account] = getBuyingAccounts(listing, false);
   
}