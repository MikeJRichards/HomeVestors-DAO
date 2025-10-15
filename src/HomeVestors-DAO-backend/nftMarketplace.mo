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
            toStruct = PropHelper.toStruct<C, U, T, StableT>(action, crudHandler, func(stableT: ?StableT) = #NftMarketplace(stableT), func(property: Property) = property.nftMarketplace.listings);
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
            toStruct = PropHelper.toStruct<C, U, T, StableT>(action, crudHandler, func(stableT: ?StableT) = #NftMarketplace(stableT), func(property: Property) = property.nftMarketplace.listings);
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
            toStruct = PropHelper.toStruct<C, U, T, StableT>(action, crudHandler, func(stableT: ?StableT) = #NftMarketplace(stableT), func(property: Property) = property.nftMarketplace.listings);
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
            toStruct = func(property: Property, idOpt: ?Nat, beforeOrAfter: UnstableTypes.BeforeOrAfter): Types.ToStruct {
                let id = switch(idOpt){case(null) return #Err(idOpt, #NullId); case(?id) id;};
                switch(marketplace.listings.get(id)){
                    case(null) return #Err(idOpt, #InvalidElementId);
                    case(?listing) return #NftMarketplace(?listing)
                }
            };
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
                if(arg.testing) return PropHelper.runNoAsync<T>(arr);
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
                                case(null) #ok();
                            }
                        };
                        case(#ok(_)) #err(#InvalidType);
                        case(#err(e)) #err(e);
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