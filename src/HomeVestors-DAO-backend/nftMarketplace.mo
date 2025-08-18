import Types "types";
import Stables "./Tests/stables";
import { setTimer } = "mo:base/Timer";
import UnstableTypes "./Tests/unstableTypes";
import FixedPrice "./marketplace/fixedPrice";
import Auction "./marketplace/auction";
import Utils "./marketplace/utils";
import NFT "nft";
import Tokens "token";
import PropHelper "propHelper";
import Time "mo:base/Time";
import Principal "mo:base/Principal";
import Array "mo:base/Array";
import Result "mo:base/Result";
import Option "mo:base/Option";
import Int "mo:base/Int";
import Buffer "mo:base/Buffer";
import Nat "mo:base/Nat";
import HashMap "mo:base/HashMap";

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
    type Arg = Types.Arg;
    type ListingUnstable = UnstableTypes.ListingUnstable;
    type Actions<C, U> = Types.Actions<C, U>;
    type What = Types.What;
    type TransferFromArg = Types.TransferFromArg;
    type CrudHandler<C, U, T, StableT> = UnstableTypes.CrudHandler<C, U, T, StableT>;
    type Handler<T, StableT> = UnstableTypes.Handler<T, StableT>;

    public func createTimers<system>(arg: Arg, m: NftMarketplacePartialUnstable, arr: [Result.Result<?Nat, (?Nat, UpdateError)>], create: Bool): async (){
        let addTimer = func<system>(id: Nat, delay: Nat, what: What):(){
            let timerId = setTimer<system>(#nanoseconds delay, func () : async () {
                let whatWithPropertyId: Types.WhatWithPropertyId = {
                   propertyId = arg.property.id;
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
                                case(null) Utils.cancelListingTimer(m, id);
                                case(?expiresAt){
                                    Utils.cancelListingTimer(m, id);
                                    if(create) addTimer<system>(id, Int.abs(expiresAt - Time.now()), #NftMarketplace(#FixedPrice(#Delete([id]))));
                                }
                            };
                        };
                        case(?#LiveAuction(auction)){
                            Utils.cancelListingTimer(m, id);
                            if(create) addTimer<system>(id, Int.abs(auction.endsAt - Time.now()), #NftMarketplace(#Auction(#Delete([id]))));
                        };
                        case(?#LaunchedProperty(launch)){
                            Utils.cancelListingTimer(m, id);
                            switch(launch.endsAt){case(null){}; case(?endsAt) if(create) addTimer<system>(id, Int.abs(endsAt - Time.now()), #NftMarketplace(#Launch(#Delete([id]))))};
                        };
                        case(_){};
                    }
                };
                case(_){};
            }
        };
    };

    public func bulkTransferToLaunch(canisterId: Principal, arr: [(?Nat, Result.Result<ListingUnstable, UpdateError>)], stageTokens: (Nat, [(Nat, Result.Result<(), UpdateError>)]) -> ()): async [(?Nat, Result.Result<(), UpdateError>)]{
        let results = Buffer.Buffer<(?Nat, Result.Result<(), UpdateError>)>(0);
        for((idOpt, res) in arr.vals()){
            switch(idOpt, res){
                case(null, _) results.add((null, #err(#InvalidElementId)));
                case(?_, #err(e)) results.add((idOpt, #err(e)));
                case(?id, #ok(el)){
                    switch(el){
                        case(#LaunchedProperty(launch)){
                            let args = Buffer.Buffer<Types.TransferArg>(0);
                            let tokenIds = await NFT.tokensOf(canisterId, {owner = Principal.fromText("vq2za-kqaaa-aaaas-amlvq-cai"); subaccount = null}, null, ?launch.maxListed);
                            if(tokenIds.size() == 0) results.add(idOpt, #err(#GenericError))
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
                                    results.add(idOpt, #ok());
                                    stageTokens(id, Buffer.toArray(tokenTransferResults));
                                }
                                else {
                                    let result : Result.Result<(), UpdateError> = switch(transferResults[0]){
                                        case(null) #err(#Transfer(null));
                                        case(?#Err(e)) #err(#Transfer(?e));
                                        case(?#Ok(_)) #ok();
                                    };
                                    results.add(idOpt, result);
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

    public func bulkTransferFromSeller(canisterId: Principal, arr: [(?Nat, Result.Result<ListingUnstable, UpdateError>)]): async [(?Nat, Result.Result<(), UpdateError>)]{
        let args = Buffer.Buffer<TransferFromArg>(0);
        let results = Buffer.Buffer<(?Nat, Result.Result<(), UpdateError>)>(0);
        let ids = Buffer.Buffer<Nat>(0);
        for((id, res) in arr.vals()){
            switch(id, res){
                case(null, _) results.add((null, #err(#InvalidElementId)));
                case(?id, #err(e)) results.add((null, #err(e)));
                case(?id, #ok(el)){
                    ids.add(id);
                    switch(el){
                        case(#LiveFixedPrice(fixedPrice)) args.add(NFT.createTransferFromArg(fixedPrice.seller, {owner = Principal.fromText("vq2za-kqaaa-aaaas-amlvq-cai"); subaccount = null}, fixedPrice.tokenId));
                        case(#LiveAuction(auction)) args.add(NFT.createTransferFromArg(auction.seller, {owner = Principal.fromText("vq2za-kqaaa-aaaas-amlvq-cai"); subaccount = null}, auction.tokenId));
                        case(_){};
                    }
                }
            }
        };

        let transferResults = await NFT.transferFromBulk(canisterId, Buffer.toArray(args));
        assert(ids.size() == transferResults.size()); // Sanity check
        for(i in transferResults.keys()){
            let result : Result.Result<(), UpdateError> = switch(transferResults.get(i)){
                case(null) #err(#Transfer(null));
                case(?#Err(e)) #err(#Transfer(?e));
                case(?#Ok(_)) #ok();
            };
            results.add((?ids.get(i), result));
        };
        Buffer.toArray(results);
    };

    public func bulkTransferToSeller(canisterId: Principal, arr: [(?Nat, Result.Result<ListingUnstable, UpdateError>)]): async [(?Nat, Result.Result<(), UpdateError>)]{
        let args = Buffer.Buffer<Types.TransferArg>(0);
        let results = Buffer.Buffer<(?Nat, Result.Result<(), UpdateError>)>(0);
        let ids = Buffer.Buffer<Nat>(0);
        for((id, res) in arr.vals()){
            switch(id, res){
                case(null, _) results.add((null, #err(#InvalidElementId)));
                case(?id, #err(e)) results.add((null, #err(e)));
                case(?id, #ok(el)){
                    ids.add(id);
                    switch(el){
                        case(#LiveFixedPrice(fixedPrice)) args.add(NFT.createTransferArg(fixedPrice.tokenId, null, fixedPrice.seller));
                        case(#LiveAuction(auction)) args.add(NFT.createTransferArg(auction.tokenId, null, auction.seller));
                        case(_){};
                    };
                }
            }
        };

        let transferResults = await NFT.transferBulk(canisterId, Buffer.toArray(args));
        assert(ids.size() == transferResults.size()); // Sanity check
        for(i in transferResults.keys()){
            let result : Result.Result<(), UpdateError> = switch(transferResults[i]){
                case(null) #err(#Transfer(null));
                case(?#Err(e)) #err(#Transfer(?e));
                case(?#Ok(_)) #ok();
            };
            results.add((?ids.get(i), result));
        };
        Buffer.toArray(results);
    };


    public func createFixedPriceHandlers(arg: Arg, action: Actions<FixedPriceCArg, FixedPriceUArg>):async UpdateResult {
        type C = FixedPriceCArg;
        type U = FixedPriceUArg;
        type T = ListingUnstable;
        type StableT = Listing;
        let marketplace = Stables.toPartialStableNftMarketplace(arg.property.nftMarketplace);
        
        let crudHandler : CrudHandler<C, U, T, StableT> = {
            map = marketplace.listings;
            var id = marketplace.listId;
            setId = func(id: Nat) = marketplace.listId := id;
            
            assignId = func(id: Nat, el: StableT): (Nat, StableT){
                switch(el){
                    case(#LiveFixedPrice(element)) return (id, #LiveFixedPrice({element with id = id}));
                    case(_) (id, el);
                };
            };

            delete =  func(id: Nat, el: StableT): (){
                switch(el){
                    case(#LiveFixedPrice(fixedPrice)){
                        let resolvedCaller = switch(fixedPrice.expiresAt){case(null) ?arg.caller; case(?e) if(Time.now() > e) null else ?arg.caller};
                        let cancelledReason = FixedPrice.determineCancelledReason(fixedPrice, resolvedCaller);
                        switch(cancelledReason){
                            case(null) marketplace.listings.put(id, el);
                            case(?reason){
                                Utils.cancelListingTimer(marketplace, id);
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
                    var quoteAsset = PropHelper.get(args.quoteAsset, #ICP); 
                });
            };
            mutate = func(arg: U, el: T): T {
                switch(el){
                    case(#LiveFixedPrice(fixedPrice)){
                        fixedPrice.price := PropHelper.get(arg.price, fixedPrice.price);
                        fixedPrice.quoteAsset := PropHelper.get(arg.quoteAsset, fixedPrice.quoteAsset);
                        fixedPrice.expiresAt := PropHelper.getNullable(arg.expiresAt, fixedPrice.expiresAt);
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

        let handler: Handler<T, StableT> = {
            validateAndPrepare = func () = PropHelper.getValid<C, U, T, StableT>(action, crudHandler);
            
            asyncEffect = func(arr: [(?Nat, Result.Result<T, UpdateError>)]): async [(?Nat, Result.Result<(), UpdateError>)] {
                if(arg.testing) return PropHelper.runNoAsync<T>(arr);
                switch(action){
                    case(#Create(_)) await bulkTransferFromSeller(marketplace.collectionId, arr);
                    case(#Update(_)) PropHelper.runNoAsync(arr);//Call no async effect here
                    case(#Delete(_)) await bulkTransferToSeller(marketplace.collectionId, arr);
                };
            };

            applyAsyncEffects = func(idOpt: ?Nat, res: Result.Result<T, Types.UpdateError>): [(?Nat, Result.Result<StableT, UpdateError>)]{
                switch(idOpt, res){
                    case(null, _) return [(null, #err(#InvalidElementId))];
                    case(?id, #ok(el)) return [(idOpt, #ok(Stables.toStableListing(el)))];
                    case(?id, #err(e)) return [(idOpt, #err(e))];
                };
            };

            applyUpdate = func(id: ?Nat, el: StableT) = PropHelper.applyUpdate<C, U, T, StableT>(action, id, el, crudHandler);

            getUpdate = func() = #NFTMarketplace(Stables.fromPartialStableNftMarketplace(marketplace));

            finalAsync = func(arr: [Result.Result<?Nat, (?Nat, UpdateError)>]): async (){
                if(arg.testing) return;
                switch(action){
                    case(#Create(_) or #Update(_)) ignore createTimers(arg, marketplace, arr, true);
                    case(#Delete(_)) ignore createTimers(arg, marketplace, arr, false);
                }
            };
        };

        await PropHelper.applyHandler<T, StableT>(arg, handler);
    };

    public func createAuctionHandlers(arg: Arg, action: Actions<AuctionCArg, AuctionUArg>): async UpdateResult {
        type C = AuctionCArg;
        type U = AuctionUArg;
        type T = ListingUnstable;
        type StableT = Listing;
        let marketplace = Stables.toPartialStableNftMarketplace(arg.property.nftMarketplace);
        
        let crudHandler : CrudHandler<C, U, T, StableT> = {
            map = marketplace.listings;
            var id = marketplace.listId;
            setId = func(id: Nat) = marketplace.listId := id;
            
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
                switch(el){
                    case(#LiveAuction(auction)){
                        let cancelledReason = Auction.determineCancelledReason(auction, ?arg.caller);
                        switch(cancelledReason){
                            case(null) marketplace.listings.put(id, el);
                            case(?reason){
                                Utils.cancelListingTimer(marketplace, id);
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
                    quoteAsset = PropHelper.get(args.quoteAsset, #ICP);
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
                        auction.startingPrice   := PropHelper.get(arg.startingPrice, auction.startingPrice);
                        auction.startTime       := PropHelper.get(arg.startTime, auction.startTime);
                        auction.endsAt          := PropHelper.get(arg.endsAt, auction.endsAt);
                        auction.quoteAsset      := PropHelper.get(arg.quoteAsset, auction.quoteAsset);
                        auction.buyNowPrice     := PropHelper.getNullable(arg.buyNowPrice, auction.buyNowPrice);
                        auction.reservePrice    := PropHelper.getNullable(arg.reservePrice, auction.reservePrice);
                        
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

        let mockTimerIds = HashMap.HashMap<Nat, Nat>(0, Nat.equal, PropHelper.natToHash);


        let handler: Handler<T, StableT> = {
            validateAndPrepare = func() = PropHelper.getValid<C, U, T, StableT>(action, crudHandler);
            
            asyncEffect = func(arr: [(?Nat, Result.Result<T, UpdateError>)]): async [(?Nat, Result.Result<(), UpdateError>)] {
                if(arg.testing) return PropHelper.runNoAsync<T>(arr);
                switch(action){
                    case(#Create(_)) await bulkTransferFromSeller(marketplace.collectionId, arr);
                    case(#Update(_)) PropHelper.runNoAsync(arr);//Call no async effect here
                    case(#Delete(_)) await bulkTransferToSeller(marketplace.collectionId, arr);
                };
            };

            applyAsyncEffects = func(id: ?Nat, res: Result.Result<T, Types.UpdateError>): [(?Nat, Result.Result<StableT, UpdateError>)]{
                switch(id, res){
                    case(null, _) return [(null, #err(#InvalidElementId))];
                    case(?id, #ok(el)) return [(?id, #ok(Stables.toStableListing(el)))];
                    case(?id, #err(e)) return [(?id, #err(e))];
                };
            };

            applyUpdate = func(id: ?Nat, el: StableT) = PropHelper.applyUpdate(action, id, el, crudHandler);

            getUpdate = func() = #NFTMarketplace(Stables.fromPartialStableNftMarketplace(marketplace));

            finalAsync = func(arr: [Result.Result<?Nat, (?Nat, UpdateError)>]): async (){
                if(arg.testing) return;
                switch(action){
                    case(#Create(_) or #Update(_)) await createTimers(arg, marketplace, arr, true);
                    case(#Delete(_)) await createTimers(arg, marketplace, arr, false);
                }
            };
        };

        await PropHelper.applyHandler<T, StableT>(arg, handler);
    };

    public func createLaunchHandlers(arg: Arg, action: Actions<Types.LaunchCArg, Types.LaunchUArg>): async UpdateResult {
        type C = Types.LaunchCArg;
        type U = Types.LaunchUArg;
        type T = ListingUnstable;
        type StableT = Listing;
        let marketplace = Stables.toPartialStableNftMarketplace(arg.property.nftMarketplace);
        let parentChildId = HashMap.HashMap<Nat, Buffer.Buffer<Nat>>(0, Nat.equal, PropHelper.natToHash);


        let crudHandler : CrudHandler<C, U, T, StableT> = {
            map = marketplace.listings;
            var id = marketplace.listId;
            setId = func(id: Nat) = marketplace.listId := id;
            
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
                        Utils.cancelListingTimer(marketplace, id);
                        let cancelled = #CancelledLaunchedProperty({
                            launch with
                            cancelledBy = {owner = arg.caller; subaccount = null};
                            cancelledAt = Time.now();
                            reason = #CalledByAdmin;
                        });
                        marketplace.listings.put(id, cancelled);
                    };
                    case(#LaunchFixedPrice(fixed)){
                        Utils.cancelListingTimer(marketplace, id);
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
                        launch.price          := PropHelper.get(arg.price, launch.price);
                        launch.endsAt         := switch(arg.endsAt){case(?endAt) ?endAt; case(null) launch.endsAt};
                        launch.quoteAsset     := PropHelper.get(arg.quoteAsset, launch.quoteAsset);
                        #LaunchedProperty(launch);
                    };
                    case(#LaunchFixedPrice(fixedPrice)){
                        fixedPrice.price      := PropHelper.get(arg.price, fixedPrice.price);
                        fixedPrice.quoteAsset := PropHelper.get(arg.quoteAsset, fixedPrice.quoteAsset);
                        fixedPrice.expiresAt  := PropHelper.getNullable(arg.endsAt, fixedPrice.expiresAt);
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

        let launchChildren = HashMap.HashMap<Nat, LaunchListingChildren>(0, Nat.equal, PropHelper.natToHash);
        let addChildren = func(id: Nat, transferResults: [(Nat, Result.Result<(), UpdateError>)]): (){
            launchChildren.put(id, {id; transferResults;})
        };


        let handler: Handler<T, StableT> = {
            validateAndPrepare = func() = PropHelper.getValid(action, crudHandler);
            
            asyncEffect = func(arr: [(?Nat, Result.Result<T, UpdateError>)]): async [(?Nat, Result.Result<(), UpdateError>)] {
                if(arg.testing) return PropHelper.runNoAsync<T>(arr);
                switch(action){
                    case(#Create(_)) await bulkTransferToLaunch(marketplace.collectionId, arr, addChildren);
                    case(#Update(_)) PropHelper.runNoAsync(arr);//Call no async effect here
                    case(#Delete(_)) PropHelper.runNoAsync(arr);
                };
            };

            applyAsyncEffects = func(id: ?Nat, res: Result.Result<T, Types.UpdateError>): [(?Nat, Result.Result<StableT, UpdateError>)]{
                let elements = Buffer.Buffer<(?Nat, Result.Result<StableT, UpdateError>)>(0);
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

            applyUpdate = func(id: ?Nat, el: StableT) = PropHelper.applyUpdate(action, id, el, crudHandler);

            getUpdate = func() = #NFTMarketplace(Stables.fromPartialStableNftMarketplace(marketplace));

            finalAsync = func(arr: [Result.Result<?Nat, (?Nat, UpdateError)>]): async (){
                if(arg.testing) return;
                switch(action){
                    case(#Create(_)){
                        await createTimers(arg, marketplace, arr, true);
                        var launched :?Types.Launch = null;
                        let buffer = Buffer.Buffer<Nat>(0);
                        for(res in arr.vals()){
                            switch(res){
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
                    case(#Update(_)) await createTimers(arg, marketplace, arr, true);
                    case(#Delete(_)) await createTimers(arg, marketplace, arr, false);
                }
            };
        };

        await PropHelper.applyHandler<T, StableT>(arg, handler);
    };

    public func createBidHandlers(arg: Arg, args: BidArg): async UpdateResult {
        type C = BidArg;
        type T = ListingUnstable;
        type StableT = Listing;
        let marketplace = Stables.toPartialStableNftMarketplace(arg.property.nftMarketplace);
        let previousHighestBidder = HashMap.HashMap<Nat, Bid>(0, Nat.equal, PropHelper.natToHash);

        func verifyBid(arg: BidArg, bidMin: Nat, seller: Account, caller: Principal, endsAt: ?Int): Result.Result<Bid, UpdateError> {
            let bid = {buyer = {owner = caller; subaccount = null}; bidAmount = arg.bidAmount; bidTime = Time.now()};
            let time = Time.now();
            if(bid.buyer == seller) return #err(#InvalidData{field = "buyer"; reason = #BuyerAndSellerCannotMatch});
            if(bid.bidAmount < bidMin) return #err(#InsufficientBid{minimum_bid = bidMin});
            if(Option.get(endsAt, time) < time) return #err(#ListingExpired);
            #ok(bid)
        };

        let handler: Handler<T, StableT> = {
            validateAndPrepare = func(): [(?Nat, Result.Result<T, Types.UpdateError>)]{
                let createSoldFixedPrice = func(fixed: FixedPrice): Result.Result<SoldFixedPrice, [(?Nat, Result.Result<T, Types.UpdateError>)]> {
                    switch(verifyBid(args, fixed.price, fixed.seller, arg.caller, fixed.expiresAt)){
                        case(#err(e)) return #err([(?args.listingId, #err(e))]);
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
                            case(#err(e)) return [(?args.listingId, #err(e))];
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
                    case(null) return [(?args.listingId, #err(#InvalidElementId))];
                    case(_) return [(?args.listingId, #err(#InvalidType))];
                };
                [(?args.listingId, #ok(Stables.fromStableListing(listing)))];
            };
            
            asyncEffect = func(arr: [(?Nat, Result.Result<T, UpdateError>)]): async [(?Nat, Result.Result<(), UpdateError>)] {
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
                let buffer = Buffer.Buffer<(?Nat, Result.Result<(), UpdateError>)>(0);
                label processing for((id, res) in arr.vals()){
                    let result = switch(res){
                        case(#ok(#SoldLaunchFixedPrice(sold))) await soldTransfers(sold.bid.buyer, sold.tokenId, sold.quoteAsset, calculateAmount(sold.bid.bidAmount, sold.royaltyBps), sold.seller);
                        case(#ok(#SoldFixedPrice(sold))) await soldTransfers(sold.bid.buyer, sold.tokenId, sold.quoteAsset, calculateAmount(sold.bid.bidAmount, sold.royaltyBps), sold.seller);
                        case(#ok(#SoldAuction(sold))) await soldTransfers(sold.buyer, sold.tokenId, sold.quoteAsset, sold.soldFor, sold.seller); 
                        case(#ok(#LiveAuction(auction))){
                            switch(auction.highestBid){
                                case(?bid) await soldTransfers(bid.buyer, auction.tokenId, auction.quoteAsset, bid.bidAmount, auction.seller);
                                case(null) continue processing;
                            }
                        };
                        case(_) continue processing;
                    };
                    buffer.add((id, result));
                };
                Buffer.toArray(buffer);
            };

            applyAsyncEffects = func(id: ?Nat, res: Result.Result<T, Types.UpdateError>): [(?Nat, Result.Result<StableT, UpdateError>)]{
                switch(res){
                    case(#err(e)) [(id, #err(e))];
                    case(#ok(el)) [(id, #ok(Stables.toStableListing(el)))];
                };
            };

            applyUpdate = func(idOpt: ?Nat, el: StableT) : ?Nat {
                switch(idOpt){
                    case(?id) {
                        marketplace.listings.put(id, el);
                        idOpt;
                    };
                    case(null) idOpt;
                }
            };

            getUpdate = func() = #NFTMarketplace(Stables.fromPartialStableNftMarketplace(marketplace));

            finalAsync = func(arr: [Result.Result<?Nat, (?Nat, UpdateError)>]): async (){
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

                for(res in arr.vals()){
                    switch(res){
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
            };
        };

        await PropHelper.applyHandler<T, StableT>(arg, handler);
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
//
//    type GenericTransferResult = Types.GenericTransferResult;
//    type Refund = Types.Refund;
//
//
//    ///Okay, so why can't we treat it like any other crud.
//    //With create - it's just createFixedPrice, createAuction, createLaunch
//    //Update - very similar - custom logic
//    //delete - just create a custom delete function, that changes and puts it in as cancelled rather than simply just deleting
//    //These functions just need to be async - since they have side effects
//    //Then bidding does the more complicated logic - with placeholders for delete and update
//
//    
//    func createAsync(arr :[(Nat, Listing)]): async [(Nat, Result.Result<(), UpdateError>)]{
//        let buff = Buffer.Buffer<(Nat, Result.Result<(), UpdateError>)>(arr.size());
//        for((id, listing) in arr.vals()){
//            switch(listing){
//                case(#LaunchedProperty(launch)){
//                    //call nfts backend owns
//                    //create transfer args for each
//                    //build the array and send it off in one go
//                    //Then for every one we create - we then need to create a fixed price arg
//                    //And somehow insert each of these
//                };
//                case(#LaunchFixedPrice(fixedPrice)){};
//                case(#LiveFixedPrice(fixedPrice)){};
//                case(#LiveAuction(auction)){};
//                case(_) buff.add((id, #err(#InvalidType)));
//            }
//        };
//        Buffer.toArray(buff);
//    };
//
//
//
//    type PropertyUnstable = UnstableTypes.PropertyUnstable;
//
//
//
//    type CreateListing = Types.CreateListing;
//    type UpdateListing = Types.UpdateListing;
//    type Handler<T, StableT> = UnstableTypes.Handler<T, StableT>;
//    type ListingUnstable = UnstableTypes.ListingUnstable;
//    type Actions<C, U> = Types.Actions<C,U>;
//    type Arg = Types.Arg;
//    public func createMarketplaceHandler(args: Arg, action: Actions<CreateListing, (UpdateListing, Nat)>): (){
//        type C = CreateListing;
//        type U = Types.UpdateListing;
//        type T = ListingUnstable;
//        type StableT = Listing;
//        let marketplace = Stables.toPartialStableNftMarketplace(args.property.nftMarketplace);
//
//        
//        var hashmap = HashMap.HashMap<Nat, T>(0, Nat.equal, PropHelper.natToHash);
//
//        let updateAsync = func(fixedPrice: FixedPrice): async Result.Result<(), UpdateError> {
//            switch(fixedPrice.expiresAt){
//                case(null) return #ok();
//                case(?expiresAt){
//                    Utils.resetTimer<system, FixedListings>(
//                        p, fixedPrice.id, Int.abs(expiresAt - Time.now()),
//                        func () : async () {
//                            delete(fixedPrice, {cancelledBy_subaccount = null; listingId = fixedPrice.id; reason = #Expired;});
//                            ignore deleteAsync(fixedPrice);
//                        }
//                    );
//                    return #ok();
//                } 
//            }
//        };
//
//        let assignListingId = func(id: Nat, el: Listing): (Nat, Listing) {
//            switch(el){
//                case(#CancelledAuction(element)) (id, #CancelledAuction({element with id = id}));
//                case(#CancelledFixedPrice(element)) (id, #CancelledFixedPrice({element with id = id}));
//                case(#CancelledLaunch(element)) (id, #CancelledLaunch({element with id = id}));
//                case(#LaunchFixedPrice(element)) (id, #LaunchFixedPrice({element with id = id}));
//                case(#LaunchedProperty(element)) (id, #LaunchedProperty({element with id = id}));
//                case(#LiveAuction(element)) (id, #LiveAuction({element with id = id}));
//                case(#LiveFixedPrice(element)) (id, #LiveFixedPrice({element with id = id}));
//                case(#SoldAuction(element)) (id, #SoldAuction({element with id = id}));
//                case(#SoldFixedPrice(element)) (id, #SoldFixedPrice({element with id = id}));
//                case(#SoldLaunchFixedPrice(element)) (id, #SoldLaunchFixedPrice({element with id = id}));
//            };
//        };
//        
//        let deleteAsync = func(fixedPrice: FixedPrice): async Result.Result<(), UpdateError> {
//            Utils.cancelListingTimer(p, fixedPrice.id);
//            await Utils.transferBackToSeller(p, fixedPrice.tokenId, fixedPrice.seller);
//        };
//        
//        let createAsync = func(fixedPrice: FixedPrice): async Result.Result<(), UpdateError> {
//            switch(await Utils.transferFromSeller(p, fixedPrice.tokenId, {owner= caller; subaccount = null})){
//                case(#ok(_)) return await updateAsync(fixedPrice);
//                case(#err(e)) return #err(e);
//            };
//        };
//
//        var returnResult : ?GenericTransferResult = null;
//        
//        let updateReturnResult = func(res: GenericTransferResult):(){
//            returnResult := ?res;
//        };
//
//
//        let handler : Handler<CreateListing, UpdateListing, ListingUnstable, Listing> = {
//
//            map = marketplace.listings;
//
//            id = {var value = marketplace.listId};
//
//            assignId = assignListingId;
//
//            delete = func(id: Nat, el: StableT):(){
//                let listing = switch(el){
//                    case(#LiveAuction(auction)) Auction.delete(auction, caller, returnResult);
//                    case(#LiveFixedPrice(fixedPrice)) FixedPrice.delete(fixedPrice, caller);
//                    case(#LaunchFixedPrice(fixedPrice)) FixedPrice.delete(fixedPrice, caller);
//                    case(_) el;
//                };
//                marketplace.listings.put(id, listing);
//            };
//
//            asyncEffect = func(arr: [(Nat, Result.Result<T, Types.UpdateError>)]): async [(Nat, Result.Result<(), UpdateError>)] {
//                let buffer = Buffer.Buffer<(Nat, Result.Result<(), UpdateError>)>(arr.size());
//                let okays = Buffer.Buffer<(Nat, Result.Result<T, UpdateError>)>(0);
//                for((id, res) in arr.vals()){
//                    switch(res){
//                        case(#err(e)) buffer.add((id, #err(e))); 
//                        case(#ok(listing)) okays.add((id, #ok(listing)));
//                    };
//                };
//                switch(action){
//                    case(#Create(_)){};
//                    case(#Update(#Bid(_), _)){};
//                    case(#Update(_)){};
//                    case(#Delete(_)){}
//                }  
//            };
//
//            mutate = func(arg: FixedPriceUArg, el: FixedListings) : FixedListings= withLive<FixedListings>(?el, func (fixedPrice) = mutate(fixedPrice, arg), func () = el, func () = el);
//
//            validate = func(el: ?FixedListings) : Result.Result<FixedListings, UpdateError> = withLive<Result.Result<FixedListings, UpdateError>>(el, validate, func () = #err(#InvalidType), func () = #err(#InvalidElementId));
//
//            delete = func(id: Nat, arg: CancelArg) : ()= withLive<()>(hashmap.get(id), func (fixedPrice) = delete(fixedPrice, arg), func () = (), func () = ());
//
//            createAsync = func(el: FixedListings): async Result.Result<(), UpdateError>{await withLiveAsyncDefault(?el, createAsync)};
//
//            updateAsync = func(el: FixedListings): async Result.Result<(), UpdateError> {await withLiveAsyncDefault(?el, updateAsync)};
//            deleteAsync = func(el: FixedListings): async Result.Result<(), UpdateError>{await withLiveAsyncDefault(?el, deleteAsync)};
//        };
//    };
//
//    //async functionality:
//    //Transfer NFT when listing
//    //Set up Timer for when listing ends
//    //Transfer NFT back to owner - when cancelling the listing
//    //validate nft transfer, transfer tokens from buyer, transfer nft - fixed price place bid (i.e. purchase) or auction purchase
//    //place bid on auction - transfer tokens from bidder, refund previous token bid if present 
//
//
//    ////////////////////////////////////
//    ////Fixed Price Logic
//    //////////////////////////////////
//    public func validateFixedListing(arg: FixedPrice, caller: Principal): Result.Result<FixedPrice, UpdateError>{
//        let time = Time.now();
//        //if(Principal.notEqual(caller, arg.seller.owner)) return #err(#Unauthorized);
//        if(arg.price == 0) return #err(#InvalidData{field = "price"; reason = #CannotBeZero});
//        if(Option.get(arg.expiresAt, time) < time) return #err(#InvalidData{field= "expires at"; reason = #CannotBeSetInThePast});
//        return #ok(arg);
//    };
//
//    public func createFixedListing(arg: FixedPriceCArg, property: Property, caller: Principal): async MarketplaceIntentResult {
//        //need the validate args as well
//        let fixedPrice : FixedPrice = {
//            arg with 
//            id = property.nftMarketplace.listId + 1;
//            listedAt = Time.now();
//            seller = {owner = caller; subaccount = null};
//            quoteAsset = PropHelper.get(arg.quoteAsset, #ICP);
//        };
//        switch(validateFixedListing(fixedPrice, caller)){case(#ok(_)){}; case(#err(e)) return #Err(e)};
//        
//        switch(await NFT.transferFrom(property.nftMarketplace.collectionId, {owner= caller; subaccount = null}, {owner = Principal.fromText("vq2za-kqaaa-aaaas-amlvq-cai"); subaccount = null}, arg.tokenId)){
//            case(?#Ok(_)) {
//                switch(fixedPrice.expiresAt){case(null){}; case(?expiresAt) await setUpEndsAtTimer(property, property.nftMarketplace.listId + 1, Int.abs(expiresAt - Time.now()))};
//                return #Ok( #Create( #LiveFixedPrice(fixedPrice), property.nftMarketplace.listId + 1));
//            };
//            case(?#Err(e)) return #Err(#Transfer(?e));
//            case(_) return #Err(#Transfer(null));
//        };
//    };
//
//    func mutateFixedListing(arg: FixedPriceUArg, fixedPrice: FixedPrice): FixedPrice {
//        {
//            fixedPrice with
//            price           = PropHelper.get(arg.price, fixedPrice.price);
//            quoteAsset      = PropHelper.get(arg.quoteAsset, fixedPrice.quoteAsset);
//            expiresAt       = PropHelper.getNullable(arg.expiresAt, fixedPrice.expiresAt);
//        }
//    };
//
//    public func updateFixedListing(arg: FixedPriceUArg, property: Property, caller: Principal): async MarketplaceIntentResult {
//        switch(PropHelper.getElementByKey(property.nftMarketplace.listings, arg.listingId)){
//            case(?#LiveFixedPrice(fixedPrice)){
//                let updatedFixedPrice = mutateFixedListing(arg, fixedPrice);
//                switch(validateFixedListing(updatedFixedPrice, caller)){case(#ok(_)){}; case(#err(e)) return #Err(e)};
//                if(arg.expiresAt != null) await setUpEndsAtTimer(property, arg.listingId, Int.abs(Option.get(updatedFixedPrice.expiresAt, Time.now()) - Time.now()));
//                return #Ok( #Update( #LiveFixedPrice(updatedFixedPrice), arg.listingId));
//            };
//            case(?#LaunchFixedPrice(fixedPrice)){
//                let updatedFixedPrice = mutateFixedListing(arg, fixedPrice);
//                switch(validateFixedListing(updatedFixedPrice, caller)){case(#ok(_)){}; case(#err(e)) return #Err(e)};
//                if(arg.expiresAt != null) await setUpEndsAtTimer(property, arg.listingId, Int.abs(Option.get(updatedFixedPrice.expiresAt, Time.now()) - Time.now()));
//                return #Ok( #Update( #LaunchFixedPrice(updatedFixedPrice), arg.listingId));
//            };
//            case(?_) return #Err(#InvalidType);
//            case(null) return #Err(#InvalidElementId);
//        }
//    };
//
//    func endFixedPrice(property: Property, fixedPrice: FixedPrice, listingId: Nat): async (){
//        switch(fixedPrice.expiresAt){
//            case(?expiresAt) if(Time.now() > expiresAt) return await setUpEndsAtTimer(property, listingId, Int.abs(expiresAt - Time.now()));
//            case(null) return; 
//        };
//        
//        let arg = {
//            cancelledBy_subaccount = null; 
//            listingId; 
//            reason = #Expired;
//        };
//        let intent = await createCancelledFixedPrice(property, arg, fixedPrice, fixedPrice.seller.owner);
//        let _ = applyMarketplaceIntentResult(intent, property, #CancelListing(arg));
//    };
//
//    func createCancelledFixedPrice(property: Property, arg: CancelArg, fixedPrice: FixedPrice, caller: Principal): async MarketplaceIntentResult {
//        //validate and transfer nft back to them
//        switch(verifyCancelArgs(arg, fixedPrice.seller, caller, null)){case(#ok(_)){}; case(#err(e)) return #Err(e)};
//        switch(await NFT.transfer(property.nftMarketplace.collectionId, null, fixedPrice.seller, fixedPrice.tokenId)){
//            case(?#Ok(_)){
//                let cancelledFixedPrice = {
//                    fixedPrice with
//                    cancelledBy = {owner = caller; subaccount = null};
//                    cancelledAt = Time.now();
//                    reason = arg.reason;
//                };
//                return #Ok(#Update (#CancelledFixedPrice(cancelledFixedPrice), arg.listingId))
//            };
//            case(?#Err(e)) return #Err(#Transfer(?e));
//            case(_) return #Err(#Transfer(null));
//        };
//    };
//
//    
//
//
//
//    
//
//
//
//
//
//
//
//    //////////////////////////////////////
//    //////////Auction Logic
//    /////////////////////////////////////
//    public func validateAuctionListing(arg: Auction, caller: Principal): Result.Result<Auction, UpdateError>{
//        if(Principal.notEqual(caller, arg.seller.owner)) return #err(#Unauthorized);
//        if(Option.get(arg.buyNowPrice, arg.startingPrice) < arg.startingPrice) return #err(#InvalidData{field= "buy now price"; reason = #InvalidInput});
//        if(arg.bidIncrement < 1) return #err(#InvalidData{field= "bid increment"; reason = #InvalidInput});
//        if(Option.get(arg.reservePrice, arg.startingPrice) > Option.get(arg.buyNowPrice, arg.startingPrice)) return #err(#InvalidData{field= "reserve price"; reason = #InvalidInput});
//        if(arg.startTime > arg.endsAt) return #err(#InvalidData{field= "start time"; reason = #OutOfRange});
//        if(arg.highestBid != null) return #err(#ImmutableLiveAuction);
//        if(arg.endsAt < Time.now()) return #err(#InvalidData{field= "end time"; reason = #CannotBeSetInThePast});
//        return #ok(arg)
//    };
//
//    public func createAuctionListing(arg: AuctionCArg, property: Property, caller: Principal): async MarketplaceIntentResult {
//       let auction : Auction = {
//            arg with 
//            id = property.nftMarketplace.listId + 1;
//            listedAt = Time.now();
//            seller = {owner = caller; subaccount = null};
//            quoteAsset = PropHelper.get(arg.quoteAsset, #ICP);
//            bidIncrement = 1;
//            highestBid = null;
//            previousBids = [];
//            refunds = [];
//       };
//       switch(validateAuctionListing(auction, caller)){case(#ok(_)){}; case(#err(e)) return #Err(e)};
//
//        switch(await NFT.transferFrom(property.nftMarketplace.collectionId, {owner= caller; subaccount = null}, {owner = Principal.fromText("vq2za-kqaaa-aaaas-amlvq-cai"); subaccount = null}, arg.tokenId)){
//            case(?#Ok(_)) {
//                await setUpEndsAtTimer(property, property.nftMarketplace.listId + 1, Int.abs(auction.endsAt - Time.now()));
//                return #Ok(#Create( #LiveAuction(auction), property.nftMarketplace.listId + 1));
//            };
//            case(?#Err(e)) return #Err(#Transfer(?e));
//            case(_) return #Err(#Transfer(null));
//        };
//    };
//
//     public func mutateAuction(arg: AuctionUArg, auction: Auction): Auction {
//        {
//            auction with 
//            startingPrice   = PropHelper.get(arg.startingPrice, auction.startingPrice);
//            startTime       = PropHelper.get(arg.startTime, auction.startTime);
//            endsAt          = PropHelper.get(arg.endsAt, auction.endsAt);
//            quoteAsset      = PropHelper.get(arg.quoteAsset, auction.quoteAsset);
//            buyNowPrice     = PropHelper.getNullable(arg.buyNowPrice, auction.buyNowPrice);
//            reservePrice    = PropHelper.getNullable(arg.reservePrice, auction.reservePrice);
//        }
//    };
//    
//    public func updateAuctionListing(arg: AuctionUArg, property: Property, caller: Principal): async MarketplaceIntentResult {
//        switch(PropHelper.getElementByKey(property.nftMarketplace.listings, arg.listingId)){
//            case(?#LiveAuction(auction)){
//                let updatedAuction = mutateAuction(arg, auction);
//                switch(validateAuctionListing(updatedAuction, caller)){case(#ok(_)){}; case(#err(e)) return #Err(e)};
//                return #Ok( #Update( #LiveAuction(updatedAuction), arg.listingId));
//            };
//            case(?_) return #Err(#InvalidType);
//            case(null) return #Err(#InvalidElementId);
//        }
//    };
//
//    public func endAuction(property: Property, auction : Auction, listingId: Nat): async () {
//        let outcome : {#Purchase: Bid; #Cancel} = switch(auction.highestBid, auction.reservePrice){
//            case(?bid, ?reserve) if(bid.bidAmount > reserve) #Purchase(bid) else #Cancel;
//            case(?bid, null) #Purchase(bid);
//            case(_) #Cancel;
//        };
//        let (action, intent) : (MarketplaceAction, MarketplaceIntentResult) = switch(outcome){
//            case(#Purchase(bid)){
//                let arg : AuctionUArg = {
//                    listingId;
//                    startingPrice = null;
//                    buyNowPrice = null;
//                    reservePrice = null;
//                    startTime = null;
//                    endsAt = null;
//                    quoteAsset = null;
//                };
//                let intent = await createSoldAuction(property, bid, auction, listingId);
//                (#UpdateAuctionListing(arg), intent);
//            };
//            case(#Cancel){
//                let arg = {
//                        cancelledBy_subaccount = null; 
//                        listingId; 
//                        reason = #Expired;
//                };
//                let intent = await createCancelledAuction(property, arg, auction, auction.seller.owner);
//                (#CancelListing(arg), intent);
//            };
//        };
//        let _ = applyMarketplaceIntentResult(intent, property, action);
//    };
//
//    public func setUpEndsAtTimer(property : Property, listingId: Nat, delaySeconds : Nat) : async () {
//        ignore setTimer<system>(
//          #seconds delaySeconds,
//          func () : async () {
//            switch(PropHelper.getElementByKey(property.nftMarketplace.listings, listingId)){
//                case(?#LiveAuction(auction)) if(auction.endsAt > Time.now()) await endAuction(property, auction, listingId) else await setUpEndsAtTimer(property, listingId, Int.abs(auction.endsAt - Time.now()));
//                case(?#LiveFixedPrice(fixedPrice)) await endFixedPrice(property, fixedPrice, listingId);
//                case(_) return;
//            };
//          }
//        );
//    };
//
//    func createCancelledAuction(property: Property, arg: CancelArg, auction: Auction, caller: Principal): async  MarketplaceIntentResult {
//        //validate and transfer nft back to them
//        switch(verifyCancelArgs(arg, auction.seller, caller, auction.highestBid)){case(#ok(_)){}; case(#err(e)) return #Err(e)};
//        switch(await NFT.transfer(property.nftMarketplace.collectionId, null, auction.seller, auction.tokenId)){
//            case(?#Ok(_)){
//                let refund = switch(auction.highestBid){
//                    case(null){[]}; 
//                    case(?bid){
//                        let result = await Tokens.transferFromBackend(auction.quoteAsset, bid.bidAmount, bid.buyer, null);
//                        [createRefund(auction.refunds.size(), {owner = Principal.fromText("vq2za-kqaaa-aaaas-amlvq-cai"); subaccount = null}, bid.buyer, bid.bidAmount, result)]
//                    };
//                };
//                let cancelledAuction = {
//                    auction with
//                    cancelledBy = {owner = caller; subaccount = null};
//                    cancelledAt = Time.now();
//                    reason = arg.reason;
//                    refunds = Array.append(auction.refunds, refund);
//                };
//                return #Ok(#Update (#CancelledAuction(cancelledAuction), arg.listingId))
//
//            };
//            case(?#Err(e)) return #Err(#Transfer(?e));
//            case(_) return #Err(#Transfer(null));
//        };    
//    };
//
//
//
//
//
//
//
//    //////////////////////////////////////
//    ////////Launch
//    //////////////////////////////////////
//    
//
//    
//
//
//
//
//
//
//
//
//    ///////////////////////////////////////
//    ///////Bid 
//    ///////////////////////////////////////
//    func createRefund(id: Nat, asset: AcceptedCryptos, to: Account, amount: Nat, result: GenericTransferResult): async Refund {
//        let result = await Tokens.transferFromBackend(asset, amount, to, null);
//
//        let refund = {
//            id;
//            from;
//            to;
//            amount;
//            attempted_at = Time.now();
//            result;
//        };
//        switch(result){
//            case(#Err(_)) #Err(refund);
//            case(#Ok(_)) #Ok(refund)
//        };
//    };
//
//      func verifyBid(arg: BidArg, bidMin: Nat, seller: Account, caller: Principal, endsAt: ?Int): Result.Result<Bid, UpdateError> {
//        let bid = {buyer = {owner = caller; subaccount = null}; bidAmount = arg.bidAmount; bidTime = Time.now()};
//        let time = Time.now();
//        if(bid.buyer == seller) return #err(#InvalidData{field = "buyer"; reason = #BuyerAndSellerCannotMatch});
//        if(bid.bidAmount < bidMin) return #err(#InsufficientBid{minimum_bid = bidMin});
//        if(Option.get(endsAt, time) < time) return #err(#ListingExpired);
//        #ok(bid)
//    };
//
//    func createSoldFixedPrice(property: Property, arg: BidArg, fixedPrice: FixedPrice, caller: Principal): async MarketplaceIntentResult {
//        let bid = switch(verifyBid(arg, fixedPrice.price, fixedPrice.seller, caller, fixedPrice.expiresAt)){case(#ok(bid)) bid; case(#err(e)) return #Err(e)};
//        let royalty = (bid.bidAmount * property.nftMarketplace.royalty / 100000);
//        let nftTransferArgs = (property.nftMarketplace.collectionId, null, bid.buyer, fixedPrice.tokenId);
//        switch(await NFT.verifyTransfer(nftTransferArgs)){case(?#Ok(_)) {}; case(?#Err(e)) return #Err(#Transfer(?e)); case(null) return #Err(#Transfer(null))};
//        switch(await Tokens.transferFrom(fixedPrice.quoteAsset, bid.bidAmount - royalty, {owner = fixedPrice.seller.owner; subaccount = null}, bid.buyer)){case(#Ok(_)) {}; case(#Err(e)) return #Err(#Transfer(?e))};
//        switch(await NFT.transfer(nftTransferArgs)){case(?#Ok(_)) {}; case(?#Err(e)) return #Err(#Transfer(?e)); case(null) return #Err(#Transfer(null))};
//        let soldFixedPrice = {
//            fixedPrice with
//            bid;
//            royaltyBps = ?royalty;
//        };
//        return #Ok(#Update (#SoldFixedPrice(soldFixedPrice), arg.listingId))
//    };
//
//    func createSoldLaunched(property: Property, arg: BidArg, fixedPrice: FixedPrice, caller: Principal): async MarketplaceIntentResult {
//        switch(await createSoldFixedPrice(property, arg, fixedPrice, caller)){
//            case(#Ok(#Update(#SoldFixedPrice(arg), id))) #Ok(#Update(#SoldLaunchFixedPrice(arg), id));
//            case(#Err(e)) #Err(e);
//            case(_) #Err(#InvalidType);
//        }
//    };
//
//    func createSoldAuction(property: Property, arg: Bid, auction: Auction, listingId: Nat): async MarketplaceIntentResult {
//       //validate and complete transfer - probs make allowance first - and check an allowance exists
//        //need to change the args for transferFrom
//        let royalty = arg.bidAmount * property.nftMarketplace.royalty / 100_000;
//        let nftTransferArgs = (property.nftMarketplace.collectionId, null, arg.buyer, auction.tokenId);
//        switch(await NFT.verifyTransfer(nftTransferArgs)){case(?#Ok(_)) {}; case(?#Err(e)) return #Err(#Transfer(?e)); case(null) return #Err(#Transfer(null))};
//        switch(await Tokens.transferFromBackend(auction.quoteAsset, arg.bidAmount - royalty, auction.seller, null)){case(#Ok(_)) {}; case(#Err(e)) return #Err(#Transfer(?e))};
//        switch(await NFT.transfer(nftTransferArgs)){case(?#Ok(_)) {}; case(?#Err(e)) return #Err(#Transfer(?e)); case(null) return #Err(#Transfer(null))};
//
//        let soldAuction: SoldAuction =  {
//            auction with
//            auctionEndTime = Time.now();
//            soldFor = arg.bidAmount;
//            boughtNow = true;
//            buyer = arg.buyer;
//            royaltyBps = ?royalty;
//        };
//        return #Ok(#Update(#SoldAuction(soldAuction), listingId));
//    };
//
//    public func addBidToAuction(auction: Auction, arg: BidArg, property: Property, caller: Principal, listingId: Nat): async  MarketplaceIntentResult {
//        //verify bid
//        let minBidAmount = switch(auction.highestBid){case(?bid) bid.bidAmount + auction.bidIncrement; case(null) auction.startingPrice};
//        let bid = switch(verifyBid(arg, minBidAmount, auction.seller, caller, ?auction.endsAt)){case(#ok(bid)) bid; case(#err(e)) return #Err(e)};
//        switch(await Tokens.transferFrom(auction.quoteAsset, bid.bidAmount, {owner = Principal.fromText("vq2za-kqaaa-aaaas-amlvq-cai"); subaccount = null}, bid.buyer)){
//            case(#Ok(_)){
//                if(Option.get(auction.buyNowPrice, 0) == bid.bidAmount) return await createSoldAuction(property, bid, auction, listingId);
//                var updatedAuction : Auction = {
//                    auction with
//                    highestBid = ?bid;
//                    previousBids = Array.append(auction.previousBids, [bid]);
//                }; 
//                updatedAuction := switch(auction.highestBid){
//                    case(?previousBid) {
//                        let result = await Tokens.transferFromBackend(auction.quoteAsset, previousBid.bidAmount, previousBid.buyer, null);
//                        let refund = createRefund(auction.refunds.size(), {owner = Principal.fromText("vq2za-kqaaa-aaaas-amlvq-cai"); subaccount = null}, previousBid.buyer, previousBid.bidAmount, result);
//                        {updatedAuction with refunds = Array.append(updatedAuction.refunds, [refund])};
//                    }; 
//                    case(null){
//                        updatedAuction;
//                    };                    
//                };
//                return #Ok( #Update( #LiveAuction(updatedAuction), arg.listingId));
//            };
//            case(#Err(e)){
//                return #Err(#Transfer(?e));
//            }
//        };
//    };
//
//    public func placeBid(arg: BidArg, property: Property, caller: Principal): async MarketplaceIntentResult {
//        switch(PropHelper.getElementByKey(property.nftMarketplace.listings, arg.listingId)){
//            case(?listing){
//                switch(listing){
//                    case(#LaunchFixedPrice(fixedPrice)){
//                        await createSoldLaunched(property, arg, fixedPrice, caller);
//                    };
//                    case(#LiveAuction(auction)){
//                        await addBidToAuction(auction, arg, property, caller, arg.listingId);
//                    }; 
//                    case(#LiveFixedPrice(fixedPrice)){
//                        await createSoldFixedPrice(property, arg, fixedPrice, caller);
//                    };
//                    case(_)return #Err(#InvalidType)
//                };
//            };
//            case(null){
//                return #Err(#InvalidElementId);
//            }
//        }
//    };
//
//
//
//
//
//
//
//
//   
//    
//  
//
//    
//    
//    
//    
//   
//  
//
//    
//    
//    
//    
//    
//    
//    
//    func verifyCancelArgs(arg: CancelArg, seller: Account, caller: Principal, bid: ?Bid): Result.Result<CancelArg, UpdateError>{
//        if(seller != {owner = caller; subaccount = null}) return #err(#Unauthorized);
//        if(bid != null) return #err(#ImmutableLiveAuction);
//        return #ok(arg);
//    };
//
//    
//    
//    public func cancelListing(arg: CancelArg, property: Property, caller: Principal): async MarketplaceIntentResult {
//        switch(PropHelper.getElementByKey(property.nftMarketplace.listings, arg.listingId)){
//            case(?listing){
//                //Validate the bid - ensure they have enough to purchase - perhaps we either call validateTransfer or attach a transferResult or create an approval, then immediately transfer the tokens
//                switch(listing){
//                    case(#LiveAuction(auction)){
//                        await createCancelledAuction(property, arg, auction, caller);
//
//                    }; 
//                    case(#LiveFixedPrice(fixedPrice)){
//                        await createCancelledFixedPrice(property, arg, fixedPrice, caller);
//                    };
//                    case(#LaunchFixedPrice(fixedPrice)){
//                        await createCancelledLaunch(property, arg, fixedPrice, caller);
//                    };
//                    case(_)return #Err(#InvalidType)
//                };
//            };
//            case(null){
//                return #Err(#InvalidElementId);
//            }
//        }
//    };
//
//    type Launch = Types.Launch;
//    type LaunchCArg = Types.LaunchCArg;
//    type LaunchUArg = Types.LaunchUArg;
//    type TransferArg = Types.TransferArg;
//    
//
//    public func writeListings(action: MarketplaceAction, property: Property, caller: Principal): async UpdateResult {
//        let result : MarketplaceIntentResult = switch(action){
//            case(#LaunchProperty(arg)){
//                await createLaunch(property, caller, arg);
//            };
//            case(#CreateFixedListing(arg)){
//                await createFixedListing(arg, property, caller);
//            };
//            case(#CreateAuctionListing(arg)){
//                await createAuctionListing(arg, property, caller);
//            };
//            case(#UpdateFixedListing(arg)){
//                await updateFixedListing(arg, property, caller);
//            };
//            case(#UpdateLaunch(arg)){
//                await updateLaunchedFixedPrice(arg, property, caller);
//            };
//            case(#UpdateAuctionListing(arg)){
//                await updateAuctionListing(arg, property, caller);
//            };
//            case(#Bid(arg)){
//                await placeBid(arg, property, caller);
//            };
//            case(#CancelListing(arg)){
//                await cancelListing(arg, property, caller);
//            };
//        };  
//        applyMarketplaceIntentResult(result, property, action);
//    };
//
//    func applyMarketplaceIntentResult(result: MarketplaceIntentResult, property: Property, action: MarketplaceAction): UpdateResult {
//        let updatedNftMarketplace :NFTMarketplace = switch(result){
//            case(#Ok(#Create(#LaunchedProperty(arg), id))){
//                {
//                    property.nftMarketplace with
//                    listId = property.nftMarketplace.listId + arg.args.size();
//                    listings = Array.append(property.nftMarketplace.listings, Array.append([(id, #LaunchedProperty(arg))], arg.args));
//                }
//            };
//            case(#Ok(act)){
//                {
//                    property.nftMarketplace with
//                    listId = PropHelper.updateId(act, property.nftMarketplace.listId);
//                    listings = PropHelper.performAction(act, property.nftMarketplace.listings);
//                };
//            };
//            case(#Err(e)){
//                return #Err(e)
//            }
//        };
//       PropHelper.updateProperty(#NFTMarketplace(updatedNftMarketplace), property, #NFTMarketplace(action));
//    };
//
//
//
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
//
//    //public func getListings(properties: ReadTypeArray<Property>, acc: ?Account, marketplaceOption: ?[MarketplaceOptions], getAcc: Listing -> [Account]): ReadUnsanitized {
//    //    let result = Buffer.Buffer<ReadType<[(Nat, Listing)]>>(properties.size());
//    //    for (res in properties.vals()) {
//    //        switch(res.value){
//    //            case(#Err(e)) result.add({propertyId = res.propertyId; value = #Err(e)});
//    //            case(#Ok(property)){
//    //                let listings = Buffer.Buffer<(Nat, Listing)>(0);
//    //                for((id, listing) in property.nftMarketplace.listings.vals()){
//    //                    if(PropHelper.matchNullableAccountArr(acc, getAcc(listing)) and tagMatching(listing, marketplaceOption)) listings.add((id, listing));
//    //                };
//    //                let res : ReadType<[(Nat, Listing)]> = {
//    //                    propertyId = property.id;
//    //                    value = switch(listings.size()){case(0) #Err(#EmptyArray); case(_)#Ok(Buffer.toArray(listings))}
//    //                };
//    //                result.add(res);
//    //            } 
//    //        }
//    //    };
//    //    #Listings(Buffer.toArray(result));
//    //};
//
//    
//
//
//    type What = Types.What;
//    type TransferFromArg = Types.TransferFromArg;
//    type WhatWithPropertyId = Types.WhatWithPropertyId;
//    type LaunchProperty = Types.LaunchProperty;
//    type UpdateResultNat = Types.UpdateResultNat;
//    
////        if(tokenIds.size() > 0){
////            var fixedPrice : FixedPrice = {
////                tokenId = tokenIds[0];
////                listedAt = Time.now();
////                seller = {owner = Principal.fromText("vq2za-kqaaa-aaaas-amlvq-cai"); subaccount = null};
////                price = arg.price;
////                expiresAt = arg.endsAt;
////                quoteAsset = Option.get(arg.quoteAsset, #HGB);
////            };
////            let transferResults = switch(validateFixedListing(fixedPrice, caller)){
////                case(#err(e)) return #Err(e);
////                case(#ok(_))  await NFT.transferFromBulk(property.nftMarketplace.collectionId, tokenIds, fixedPrice.seller, {owner = fixedPrice.seller.owner; subaccount = ?Principal.toBlob(fixedPrice.seller.owner)});
////            };
////            for(result in transferResults.vals()){
////                switch(result){
////                    case(?#Ok(id)){
////                        fixedPrice := {fixedPrice with tokenId = id};
////                        {
////
////                        }
////                        args.add(fixedPrice);
////                    };
////                    case(?#Err(e)){}
////                }
////            };
////
////
////
////        };
////        //reality is that if one passes then they'd all pass
////        //so why not just feed in the first id in the array - if fails - return from this functon
////        //if succeeds - create transfer from args for all in a array
////        //Then call transfer from on entire array
////        //if that succeeds - create individual fixed price
////        for(i in tokenIds.keys()){
////            
////
////        };
////
////            
////            args.add({what = #NFTMarketplace(#CreateFixedListing(fixedPrice)); propertyId = arg.propertyId});
////        };
//   
}