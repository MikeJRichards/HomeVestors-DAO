import Nat "mo:core/Nat";
import Result "mo:core/Result";
import Time "mo:core/Time";
import Principal "mo:core/Principal";
import Array "mo:base/Array"; 
import Timer "mo:base/Timer";
import Int "mo:base/Int";
import Types "./types";

persistent actor {
    type Listing = Types.Listing;

    var marketplace : Types.NFTMarketplace = {
        listings = [];
        royalty = 0;
        launchId = 0;
        launches = [];
        failedTimers = [];
        stateChanges = [];
    };
    let marketplaceVault: Types.MarketplaceVault = actor("vq2za-kqaaa-aaaas-amlvq-cai");
    
    func cancelTimer(listing : Listing) {
        switch(listing.timerId) {
            case(null) {};
            case(?tid) Timer.cancelTimer(tid);
        };
    };

    func updateListingInternal(listingId : Nat, getStatus : Listing -> Result.Result<Types.ListingStatus, ()>, runAsync: ?((Listing, Types.ListingStatus) -> async Result.Result<Listing,()>)) : async Result.Result<(), ()> {
        // Load listing
        let map = Types.createMapHandler<Nat, Listing>(Nat.compare, marketplace.listings);
        let listing = switch(map.get(listingId)) {case(null) return #err(); case(?l) l;};
        // Compute updated status (domain logic)
        let newStatus = switch(getStatus(listing)) {case(#err()) return #err();case(#ok(s)) s;};
        let updatedListing = switch(runAsync){
            case(null){{listing with status = newStatus}};
            case(?runAsync) switch(await runAsync(listing, newStatus)){case(#err()) return #err(); case(#ok(fn)) fn};
        };
        map.put(listingId, updatedListing);
        marketplace := {
            marketplace with
            listings = map.toArray()
        };
        // Auto-cancel timer when leaving any "Live" state
        #ok();
    };

    func updateListing(listingId : Nat, arg: Types.Action, getStatus : Listing -> Result.Result<Types.ListingStatus, ()>, runAsync: ?((Listing, Types.ListingStatus) -> async Result.Result<Listing,()>)) : async Result.Result<(), ()> {
        let listingsBefore = Types.createMapHandler<Nat, Listing>(Nat.compare, marketplace.listings);
        let result = await updateListingInternal(listingId, getStatus, runAsync);
        let listingsAfter = Types.createMapHandler<Nat, Listing>(Nat.compare, marketplace.listings);
        createResultDif(?listingId, #Listing(listingsBefore.get(listingId)), #Listing(listingsAfter.get(listingId)),arg, result);
        result
    };






    public shared ({caller}) func createFixedPriceListing(arg: Types.FixedPriceCArg): async Result.Result<[Result.Result<Types.ParseListing, Types.NFTTransferFromError>], ()>{
        switch(arg.expiresAt){case(?time) if(time < Time.now()) return #err(); case(_){}};
        if(arg.price <= 0) return #err();
        let seller: Types.Account = {owner = caller; subaccount = arg.seller_subaccount};
        let status = #LiveFixedPrice({
            price = arg.price;
            expiresAt = arg.expiresAt;
        });
        #ok(await createListing(#FixedPrice(#Create(arg)), seller, arg.collectionId, arg.tokenIds, status, arg.expiresAt));
    };

    public shared ({caller}) func createAuctionListing(arg: Types.AuctionCArg): async Result.Result<[Result.Result<Types.ParseListing, Types.NFTTransferFromError>], ()> {
        //validation function 
        let time = Time.now();
        if(time > arg.endsAt) return #err();
        if(time > arg.startTime) return #err();
        if(arg.startingPrice == 0) return #err();
        switch(arg.reservePrice){case(null){}; case(?x) if(arg.startingPrice > x) return #err()};
        switch(arg.buyNowPrice){case(null){}; case(?x) if(arg.startingPrice > x) return #err()};
        let seller: Types.Account = {owner = caller; subaccount = arg.seller_subaccount};
        let status = #LiveAuction({
            startingPrice = arg.startingPrice;
            buyNowPrice = arg.buyNowPrice;
            bidIncrement = 100;
            reservePrice = arg.reservePrice;
            startTime = arg.startTime;
            endsAt = arg.endsAt;
            highestBid = null;
            previousBids = [];
            refunds = [];
        });
        
        #ok(await createListing(#Auction(#Create(arg)), seller, arg.collectionId, arg.tokenId, status, ?arg.endsAt));
    };

    public shared ({caller}) func launchProperty(arg: Types.LaunchCArg): async Result.Result<(), ()> {
        if(Principal.notEqual(caller, Principal.fromText("vq2za-kqaaa-aaaas-amlvq-cai"))) return #err();//backend account
        if(arg.price == 0) return #err();
        switch(arg.endsAt){case(null) {}; case(?x) if(Time.now() >= x) return #err()};
        switch(arg.maxListed){case(null){}; case(?x) if (x == 0) return #err()};
        let seller: Types.Account = {owner = caller; subaccount = arg.seller_subaccount};
        let nftActor : Types.NFTActor = actor(Principal.toText(arg.collectionId));
        let nftTokenIds : [Nat] = await nftActor.icrc7_tokens_of(seller, null, null);
        if(nftTokenIds.size() == 0) return #err();
        let status = #LiveFixedPrice({
            price = arg.price;
            expiresAt = arg.endsAt;
        });
        let results = await createListing(#Launch(#Create(arg)),seller, arg.collectionId, nftTokenIds, status, arg.endsAt);
        let listingIds = Types.createListHandler<Nat>([]);
        let tokenIds = Types.createListHandler<Nat>([]);
        for(res in results.vals()){
            switch(res){
                case(#ok(parseListing)){
                    tokenIds.add(parseListing.tokenId);
                    listingIds.add(parseListing.listingId);
                };
                case(#err(_)){};
            }
        };

        if(listingIds.size() == 0) return #err();
        let launch : Types.LaunchTypes = #Live{
            id = marketplace.launchId;
            seller;
            caller;
            tokenIds = tokenIds.toArray();
            listIds = listingIds.toArray();
            maxListed = arg.maxListed;
            listedAt = Time.now();
            endsAt = arg.endsAt;
            price = arg.price;
            quoteAsset = #HUSD;
        };

        marketplace := {
            marketplace with
            launchId = marketplace.launchId + 1;
            launches = Array.append(marketplace.launches, [(marketplace.launchId, launch)]);
        };
        return #ok();
    };

    func cancelLaunchInternal(id: Nat, caller: Principal): async Result.Result<(),()>{
        if(Principal.notEqual(caller, Principal.fromText("vq2za-kqaaa-aaaas-amlvq-cai"))) return #err();//backend account
        let launches = Types.createMapHandler<Nat, Types.LaunchTypes>(Nat.compare, marketplace.launches);
        let launch = switch(launches.get(id)){case(?#Live(launch)) launch; case(_) return #err()};
        let results = Types.createListHandler<async Result.Result<(),()>>([]);
        for(id in launch.listIds.vals()){
            let arg = {
                cancelledBy_subaccount = null;
                listingId = id;
                reason = #CalledByAdmin;
            };
            results.add(cancelListing(arg));  
        };
        let awaitedResults = Types.createListHandler<Result.Result<(),()>>([]);
        for(result in results.entries()) awaitedResults.add(await result);
        let updatedLaunch : Types.LaunchTypes = #Cancelled{
            launch with
            cancelledBy = {owner = caller; subaccount = null};
            cancelledAt = Time.now();
            reason = #CalledByAdmin;
            cancelledResults = awaitedResults.toArray();
        };
        launches.put(id, updatedLaunch);
        marketplace := {
            marketplace with
            launches = launches.toArray();
        };
        #ok();
    };

    public shared ({caller}) func cancelLaunch(id: Nat): async Result.Result<(),()>{
        let launchesBefore = Types.createMapHandler<Nat, Types.LaunchTypes>(Nat.compare, marketplace.launches);
        let results = await cancelLaunchInternal(id, caller);
        let launchesAfter = Types.createMapHandler<Nat, Types.LaunchTypes>(Nat.compare, marketplace.launches);
        createResultDif(?id, #Launch(launchesBefore.get(id)), #Launch(launchesAfter.get(id)), #CancelLaunch(id), results);
        results;
    };


    func updateLaunchInternal(arg: Types.LaunchUArg, caller: Principal): async Result.Result<(),()>{
        if(Principal.notEqual(caller, Principal.fromText("vq2za-kqaaa-aaaas-amlvq-cai"))) return #err();//backend account
        if(arg.price == null and arg.endsAt == null) return #err();
        let launches = Types.createMapHandler<Nat, Types.LaunchTypes>(Nat.compare, marketplace.launches);
        let launch = switch(launches.get(arg.launchId)){case(?#Live(launch)) launch; case(_) return #err()};
        let updatedLaunch : Types.LaunchTypes = #Live{
            launch with
            price = switch(arg.price){case(null) launch.price; case(?price) if(price == 0) return #err() else price};
            endsAt = switch(arg.endsAt){case(null) launch.endsAt; case(?time) if(Time.now() >= time) return #err() else ?time};
        };
        let results = Types.createListHandler<async Result.Result<(),()>>([]);
        for(id in launch.listIds.vals()){
            let args = {
                listingId = id;
                price = arg.price;
                expiresAt = arg.endsAt;
            };
            results.add(updateFixedPriceListing(args));  
        };
        //let awaitedResults = Types.createListHandler<Result.Result<(),()>>([]);
        //for(result in results.entries()) awaitedResults.add(await result);
        launches.put(arg.launchId, updatedLaunch);
        marketplace := {
            marketplace with
            launches = launches.toArray();
        };
        #ok();
    };

    public shared ({caller}) func updateLaunch(arg: Types.LaunchUArg): async Result.Result<(),()>{
        let launchesBefore = Types.createMapHandler<Nat, Types.LaunchTypes>(Nat.compare, marketplace.launches);
        let results = await updateLaunchInternal(arg, caller);
        let launchesAfter = Types.createMapHandler<Nat, Types.LaunchTypes>(Nat.compare, marketplace.launches);
        createResultDif(?arg.launchId, #Launch(launchesBefore.get(arg.launchId)), #Launch(launchesAfter.get(arg.launchId)), #Launch(#Update(arg)), results);
        results;
    };
    
    func createListingInternal(seller : Types.Account, collectionId : Principal, tokenId : [Nat], status : Types.ListingStatus, endsAt: ?Nat): async [Result.Result<Types.ParseListing, Types.NFTTransferFromError>] {
        let results = await marketplaceVault.createListing(seller, collectionId, tokenId);
        let handler = Types.createListHandler<Result.Result<Types.ParseListing, Types.NFTTransferFromError>>(results);
        let listings = Types.createMapHandler<Nat, Listing>(Nat.compare, marketplace.listings);
        for(res in handler.entries()){
            switch(res){
                case(#ok(parseListing)){
                    let listing : Listing = {
                        timerId = await createTimer(endsAt, parseListing.listingId);
                        id = parseListing.listingId;
                        collectionId;
                        tokenId = parseListing.tokenId;
                        listedAt = Time.now();
                        seller;
                        quoteAsset = #HUSD;
                        status;
                    };
                    listings.put(parseListing.listingId, listing);
                };
                case(#err(_)){};
            };
        };
        marketplace := {
            marketplace with
            listings = listings.toArray();
        };

        results;
    };

    func createListing(arg: Types.Action, seller : Types.Account, collectionId : Principal, tokenId : [Nat], status : Types.ListingStatus, endsAt: ?Nat): async [Result.Result<Types.ParseListing, Types.NFTTransferFromError>] {
        let listingsBefore = Types.createMapHandler<Nat, Listing>(Nat.compare, marketplace.listings);
        let results = await createListingInternal(seller, collectionId, tokenId, status, endsAt);
        for(res in results.vals()){
            switch(res){
                case(#ok(parse)){
                    let listingsAfter = Types.createMapHandler<Nat, Listing>(Nat.compare, marketplace.listings);
                    createResultDif(?parse.listingId, #Listing(listingsBefore.get(parse.listingId)), #Listing(listingsAfter.get(parse.listingId)),arg, #ok());
                };
                case(#err(e)){
                    createResultDif(null, #Listing(null), #Listing(null),arg, #err());
                };
            };
        };
        results;
    };

    func createTimer<system>(endsAt: ?Nat, listingId: Nat): async ?Nat{
        switch(endsAt){
            case(null) null;
            case(?endsAt){
            let nowSec : Nat = Int.abs(Time.now() / 1_000_000_000);

            if (endsAt <= nowSec) {
                // Already expired – run immediately or return null
                ignore await endListing(listingId);
                return null;
            };

            let delay : Nat = endsAt - nowSec;
            ?Timer.setTimer<system>(#seconds(delay), func () : async () {
                    switch(await endListing(listingId)){
                        case(#ok()){};
                        case(#err()){
                            marketplace := {
                                marketplace with 
                                failedTimers = Array.append(marketplace.failedTimers, [(listingId, #err())]);
                            };
                        }
                    };
                });
            }; 
        };
    };

    func endListing(listingId: Nat): async Result.Result<(),()>{
        let time = Time.now();
        let updateStatusFn = func(listing: Listing): Result.Result<Types.ListingStatus, ()>{
            switch(listing.status){
                case(#LiveFixedPrice(fixed)){
                    switch(fixed.expiresAt){case(null) return #err(); case(?x) if(time > x) return #err()};
                    return #ok(#CancelledFixedPrice{
                        fixed with
                        cancelledBy = listing.seller;
                        cancelledAt = time;
                        reason = #Expired;
                    });
                };
                case(#LiveAuction(auction)){
                    if(auction.endsAt > time) return #err();
                    let sale : Result.Result<Types.Bid,()> = switch(auction.highestBid, auction.reservePrice){
                        case(?bid, null) #ok(bid);
                        case(?bid, ?reserve) if(bid.bidAmount > reserve) #ok(bid) else #err();
                        case(_) #err();
                    };
                    switch(sale){
                        case(#ok(bid)){
                            return #ok(#SoldAuction{
                                auction with 
                                auctionEndTime = time;
                                soldFor = bid.bidAmount;
                                buyer = bid.buyer;
                                boughtNow = false;
                                royaltyBps = null;
                            });
                        };
                        case(#err()){
                            return #ok(#CancelledAuction{
                                auction with
                                cancelledBy = listing.seller;
                                cancelledAt = time;
                                reason = #Expired;
                            });
                        };
                    }
                };
                case(_) #err();
            }
        };
        
        let runAsync = func(listing: Listing, newStatus: Types.ListingStatus): async Result.Result<Listing, ()>{
            let result = switch(listing.status, newStatus){
                case(#LiveFixedPrice(_), #CancelledFixedPrice(_)) await marketplaceVault.cancelListing(listingId);
                case(#LiveAuction(_), #SoldAuction(_)) await marketplaceVault.completeListing(listingId);
                case(#LiveAuction(_), #CancelledAuction(_)) await marketplaceVault.cancelListing(listingId);
                case(_) return #err();
            };
            switch(result){
                case(#ok()) #ok({listing with status = newStatus});
                case(#err()) #err();
            }
        };
        
        await updateListing(listingId, #EndListing(listingId), updateStatusFn, ?runAsync);
    };

    public shared ({caller}) func cancelListing(arg: Types.CancelArg): async Result.Result<(), ()>{
        let updateStatusFn = func(listing: Listing): Result.Result<Types.ListingStatus, ()>{
            if(not Principal.equal(listing.seller.owner, caller)) return #err();
            let updatedStatus = switch(listing.status){
                case(#LiveFixedPrice(fixed)){
                    #CancelledFixedPrice{
                            fixed with
                            cancelledBy = {owner = caller; subaccount = arg.cancelledBy_subaccount};
                            cancelledAt = Time.now();
                            reason = arg.reason;
                    }
                };
                case(#LiveAuction(auction)){
                    if(auction.highestBid != null) return #err();  
                    #CancelledAuction({
                            auction with
                            cancelledBy = {owner = caller; subaccount = arg.cancelledBy_subaccount};
                            cancelledAt = Time.now();
                            reason = arg.reason;
                    })
                };
                case(_) return #err();
            };
            #ok(updatedStatus);
        };

        let runAsync = func(listing: Listing, newStatus: Types.ListingStatus): async Result.Result<Listing, ()>{
            switch(await marketplaceVault.cancelListing(arg.listingId)){
                case(#ok()) #ok({listing with status = newStatus});
                case(#err()) #err();
            };
        };
        
        await updateListing(arg.listingId, #CancelListing(arg), updateStatusFn, ?runAsync);
    };

    public shared ({caller}) func placeBid(arg: Types.BidArg): async Result.Result<(),()>{
        let updateStatusFn = func(listing: Listing): Result.Result<Types.ListingStatus, ()>{
            let updatedStatus = switch(listing.status){
                case(#LiveFixedPrice(fixed)){
                    if(fixed.price >= arg.bidAmount) return #err();
                    #SoldFixedPrice({
                        fixed with
                        bid = {bidAmount = arg.bidAmount; buyer = {owner = caller; subaccount = arg.buyer_subaccount}; bidTime = Time.now()};
                        royaltyBps = ?0;
                    });
                };
                case(#LiveAuction(auction)){
                    switch(auction.highestBid){
                        case(?bid){
                            if(bid.bidAmount + auction.bidIncrement > arg.bidAmount) return #err(); 
                            if(bid.buyer.owner == caller) return #err();
                        }; 
                        case(null){}
                    };
                    let buyNow = switch(auction.buyNowPrice){case(null)false; case(?x) arg.bidAmount >= x};
                    if(buyNow){
                        #SoldAuction{
                            auction with 
                            auctionEndTime = Time.now();
                            soldFor = arg.bidAmount;
                            buyer = {owner = caller; subaccount = arg.buyer_subaccount};
                            boughtNow = true;
                            royaltyBps = null;
                        }
                    }
                    else {
                        #LiveAuction({
                                auction with
                                highestBid = ?{bidAmount = arg.bidAmount; buyer = {owner = caller; subaccount = arg.buyer_subaccount}; bidTime = Time.now()};
                                previousBids = switch(auction.highestBid){case(?bid) Array.append(auction.previousBids, [bid]); case(null) auction.previousBids};
                        });
                    };
                };
                case(_) return #err();
            };
            return #ok(updatedStatus);
        };

        let runAsync = func(listing: Listing, newStatus: Types.ListingStatus): async Result.Result<Listing, ()>{
            let result = switch(listing.status, newStatus){
                case(#LiveFixedPrice(_), #SoldFixedPrice(_)){
                    switch(await marketplaceVault.placeBid(arg.listingId, {owner = caller; subaccount = arg.buyer_subaccount}, arg.bidAmount)){case(#ok()){}; case(#err()) return #err()};
                    switch(await marketplaceVault.completeListing(arg.listingId)){case(#ok()){}; case(#err()) return #err()};
                    cancelTimer(listing);
                    return #ok({listing with status = newStatus; timerId = null});
                };
                case(#LiveAuction(_), #SoldAuction(_)){
                    switch(await marketplaceVault.placeBid(arg.listingId, {owner = caller; subaccount = arg.buyer_subaccount}, arg.bidAmount)){case(#ok()){}; case(#err()) return #err()};
                    switch(await marketplaceVault.completeListing(arg.listingId)){case(#err()) return #err(); case(#ok()){}};
                    cancelTimer(listing);
                    return #ok({listing with status = newStatus; timerId = null});
                };
                case(#LiveAuction(_), #LiveAuction(_)) await marketplaceVault.placeBid(arg.listingId, {owner = caller; subaccount = arg.buyer_subaccount}, arg.bidAmount);
                case(_) #err();
            };
            switch(result){
                case(#ok()) #ok({listing with status = newStatus});
                case(#err()) #err();
            }
        };  
        await updateListing(arg.listingId, #Bid(arg), updateStatusFn, ?runAsync);
    };

    public shared ({caller}) func updateFixedPriceListing(arg: Types.FixedPriceUArg): async Result.Result<(),()>{
        let updateStatusFn = func(listing: Listing): Result.Result<Types.ListingStatus, ()>{
            if(arg.price == null and arg.expiresAt == null) return #err();
            if(Principal.notEqual(caller, listing.seller.owner)) return #err();
            switch(listing.status){
                case(#LiveFixedPrice(fixed)){
                    #ok(#LiveFixedPrice{
                        price = switch(arg.price){case(null) fixed.price; case(?price) if(price == 0) return #err() else price};
                        expiresAt = switch(arg.expiresAt){case(null) fixed.expiresAt; case(?expiry) if(Time.now() >= expiry) return #err() else ?expiry};
                    })
                };
                case(_)#err();
            }
        };

        let runAsync = func(listing: Listing, newStatus: Types.ListingStatus): async Result.Result<Listing, ()>{
            switch(arg.expiresAt){
                case(null) #ok({listing with status = newStatus});
                case(?_){
                    cancelTimer(listing);
                    let timerId = await createTimer(arg.expiresAt, arg.listingId);
                    #ok({listing with status = newStatus; timerId = timerId});
                }
            }
        };

        await updateListing(arg.listingId, #FixedPrice(#Update(arg)), updateStatusFn, ?runAsync);
    };

    public shared ({caller}) func updateAuctionListing(arg: Types.AuctionUArg): async Result.Result<(),()>{
        let updateStatusFn = func(listing: Listing): Result.Result<Types.ListingStatus, ()>{
            if(arg.startingPrice == null and arg.buyNowPrice == null and arg.reservePrice == null and arg.startTime == null and arg.endsAt == null) return #err();
            if(Principal.notEqual(caller, listing.seller.owner)) return #err();
            switch(listing.status){
                case(#LiveAuction(auction)){
                    switch(auction.highestBid){case(null){}; case(?bid) return #err()};
                    if(Time.now() > auction.startTime) return #err();
                    let startingPrice = switch(arg.startingPrice){case(null) auction.startingPrice; case(?price) if(price == 0) return #err() else price};
                    let (startTime, endsAt) = switch(arg.startTime, arg.endsAt){
                        case(null, null) (auction.startTime, auction.endsAt); 
                        case(?start, null) if(Time.now() > start) return #err() else (start, auction.endsAt);
                        case(?start, ?ends) if(Time.now() > start or start > ends) return #err() else (start, ends);
                        case(null, ?ends) if(Time.now() > ends or auction.startTime > ends) return #err() else (auction.startTime, ends);
                    };

                    #ok(#LiveAuction{
                        auction with
                        startingPrice;
                        buyNowPrice = switch(arg.buyNowPrice){case(null) auction.buyNowPrice; case(?price) if(startingPrice > price) return #err() else ?price};
                        reservePrice = switch(arg.reservePrice){case(null) auction.reservePrice; case(?price) if(startingPrice > price) return #err() else ?price};
                        startTime; 
                        endsAt;
                    })
                };
                case(_)#err();
            }
        };

        let runAsync = func(listing: Listing, newStatus: Types.ListingStatus): async Result.Result<Listing, ()>{
            switch(arg.endsAt){
                case(null) #ok({listing with status = newStatus});
                case(?_){
                    cancelTimer(listing);
                    let timerId = await createTimer(arg.endsAt, arg.listingId);
                    #ok({listing with status = newStatus; timerId = timerId});
                }
            }
        };

        await updateListing(arg.listingId, #Auction(#Update(arg)), updateStatusFn, ?runAsync);
    };

    func createResultDif(id: ?Nat, before: Types.State, after: Types.State, arg: Types.Action, result: Result.Result<(), ()>): () {
        let stateChanges = Types.createListHandler<Types.ResultDiff>(marketplace.stateChanges);
        let dif = {
            id; 
            before;
            after;
            arg;
            result;
        };
        stateChanges.add(dif);
        marketplace:= {
            marketplace with stateChanges = stateChanges.toArray();
        }
    };




}