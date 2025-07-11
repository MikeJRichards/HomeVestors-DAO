import Types "types";
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
import { setTimer } = "mo:base/Timer";
import Nat "mo:base/Nat";

module {
    type MarketplaceAction = Types.MarketplaceAction;
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


    public func createNFTMarketplace(collectionId: Principal): NFTMarketplace {
        {
            collectionId;
            listId = 0;
            listings = [];
            royalty = 0;
        }
    };

    type GenericTransferResult = Types.GenericTransferResult;
    type Refund = Types.Refund;
    func createRefund(id: Nat, from: Account, to: Account, amount: Nat, result: GenericTransferResult): Refund {
        let refund = {
            id;
            from;
            to;
            amount;
            attempted_at = Time.now();
            result;
        };
        switch(result){
            case(#Err(_)) #Err(refund);
            case(#Ok(_)) #Ok(refund)
        };
    };

    public func validateFixedListing(arg: FixedPrice, caller: Principal): Result.Result<FixedPrice, UpdateError>{
        let time = Time.now();
        //if(Principal.notEqual(caller, arg.seller.owner)) return #err(#Unauthorized);
        if(arg.price == 0) return #err(#InvalidData{field = "price"; reason = #CannotBeZero});
        if(Option.get(arg.expiresAt, time) < time) return #err(#InvalidData{field= "expires at"; reason = #CannotBeSetInThePast});
        return #ok(arg);
    };

    public func validateAuctionListing(arg: Auction, caller: Principal): Result.Result<Auction, UpdateError>{
        if(Principal.notEqual(caller, arg.seller.owner)) return #err(#Unauthorized);
        if(Option.get(arg.buyNowPrice, arg.startingPrice) < arg.startingPrice) return #err(#InvalidData{field= "buy now price"; reason = #InvalidInput});
        if(arg.bidIncrement < 1) return #err(#InvalidData{field= "bid increment"; reason = #InvalidInput});
        if(Option.get(arg.reservePrice, arg.startingPrice) > Option.get(arg.buyNowPrice, arg.startingPrice)) return #err(#InvalidData{field= "reserve price"; reason = #InvalidInput});
        if(arg.startTime > arg.endsAt) return #err(#InvalidData{field= "start time"; reason = #OutOfRange});
        if(arg.highestBid != null) return #err(#ImmutableLiveAuction);
        if(arg.endsAt < Time.now()) return #err(#InvalidData{field= "end time"; reason = #CannotBeSetInThePast});
        return #ok(arg)
    };

    func verifyBid(arg: BidArg, bidMin: Nat, seller: Account, caller: Principal, endsAt: ?Int): Result.Result<Bid, UpdateError> {
        let bid = {buyer = {owner = caller; subaccount = null}; bidAmount = arg.bidAmount; bidTime = Time.now()};
        let time = Time.now();
        if(bid.buyer == seller) return #err(#InvalidData{field = "buyer"; reason = #BuyerAndSellerCannotMatch});
        if(bid.bidAmount < bidMin) return #err(#InsufficientBid{minimum_bid = bidMin});
        if(Option.get(endsAt, time) < time) return #err(#ListingExpired);
        #ok(bid)
    };

    public func createFixedListing(arg: FixedPriceCArg, property: Property, caller: Principal): async MarketplaceIntentResult {
        //need the validate args as well
        let fixedPrice : FixedPrice = {
            arg with 
            id = property.nftMarketplace.listId + 1;
            listedAt = Time.now();
            seller = {owner = caller; subaccount = null};
            quoteAsset = PropHelper.get(arg.quoteAsset, #ICP);
        };
        switch(validateFixedListing(fixedPrice, caller)){case(#ok(_)){}; case(#err(e)) return #Err(e)};
        
        switch(await NFT.transferFrom(property.nftMarketplace.collectionId, {owner= caller; subaccount = null}, {owner = Principal.fromText("vq2za-kqaaa-aaaas-amlvq-cai"); subaccount = null}, arg.tokenId)){
            case(?#Ok(_)) {
                switch(fixedPrice.expiresAt){case(null){}; case(?expiresAt) await setUpEndsAtTimer(property, property.nftMarketplace.listId + 1, Int.abs(expiresAt - Time.now()))};
                return #Ok( #Create( #LiveFixedPrice(fixedPrice), property.nftMarketplace.listId + 1));
            };
            case(?#Err(e)) return #Err(#Transfer(?e));
            case(_) return #Err(#Transfer(null));
        };
    };

    public func createAuctionListing(arg: AuctionCArg, property: Property, caller: Principal): async MarketplaceIntentResult {
       let auction : Auction = {
            arg with 
            id = property.nftMarketplace.listId + 1;
            listedAt = Time.now();
            seller = {owner = caller; subaccount = null};
            quoteAsset = PropHelper.get(arg.quoteAsset, #ICP);
            bidIncrement = 1;
            highestBid = null;
            previousBids = [];
            refunds = [];
       };
       switch(validateAuctionListing(auction, caller)){case(#ok(_)){}; case(#err(e)) return #Err(e)};

        switch(await NFT.transferFrom(property.nftMarketplace.collectionId, {owner= caller; subaccount = null}, {owner = Principal.fromText("vq2za-kqaaa-aaaas-amlvq-cai"); subaccount = null}, arg.tokenId)){
            case(?#Ok(_)) {
                await setUpEndsAtTimer(property, property.nftMarketplace.listId + 1, Int.abs(auction.endsAt - Time.now()));
                return #Ok(#Create( #LiveAuction(auction), property.nftMarketplace.listId + 1));
            };
            case(?#Err(e)) return #Err(#Transfer(?e));
            case(_) return #Err(#Transfer(null));
        };
    };

    func mutateFixedListing(arg: FixedPriceUArg, fixedPrice: FixedPrice): FixedPrice {
        {
            fixedPrice with
            price           = PropHelper.get(arg.price, fixedPrice.price);
            quoteAsset      = PropHelper.get(arg.quoteAsset, fixedPrice.quoteAsset);
            expiresAt       = PropHelper.getNullable(arg.expiresAt, fixedPrice.expiresAt);
        }
    };

    public func updateFixedListing(arg: FixedPriceUArg, property: Property, caller: Principal): async MarketplaceIntentResult {
        switch(PropHelper.getElementByKey(property.nftMarketplace.listings, arg.listingId)){
            case(?#LiveFixedPrice(fixedPrice)){
                let updatedFixedPrice = mutateFixedListing(arg, fixedPrice);
                switch(validateFixedListing(updatedFixedPrice, caller)){case(#ok(_)){}; case(#err(e)) return #Err(e)};
                if(arg.expiresAt != null) await setUpEndsAtTimer(property, arg.listingId, Int.abs(Option.get(updatedFixedPrice.expiresAt, Time.now()) - Time.now()));
                return #Ok( #Update( #LiveFixedPrice(updatedFixedPrice), arg.listingId));
            };
            case(?#LaunchFixedPrice(fixedPrice)){
                let updatedFixedPrice = mutateFixedListing(arg, fixedPrice);
                switch(validateFixedListing(updatedFixedPrice, caller)){case(#ok(_)){}; case(#err(e)) return #Err(e)};
                if(arg.expiresAt != null) await setUpEndsAtTimer(property, arg.listingId, Int.abs(Option.get(updatedFixedPrice.expiresAt, Time.now()) - Time.now()));
                return #Ok( #Update( #LaunchFixedPrice(updatedFixedPrice), arg.listingId));
            };
            case(?_) return #Err(#InvalidType);
            case(null) return #Err(#InvalidElementId);
        }
    };

    public func updateLaunchedFixedPrice(arg: FixedPriceUArg, property: Property, caller: Principal): async MarketplaceIntentResult {
        switch(await updateFixedListing(arg: FixedPriceUArg, property: Property, caller: Principal)){
            case(#Ok( #Update( #LiveFixedPrice(arg), id))) #Ok(#Update(#LaunchFixedPrice(arg), id));
            case(#Err(e)) return #Err(e);
            case(_) return #Err(#InvalidType);
        }
    };

    public func mutateAuction(arg: AuctionUArg, auction: Auction): Auction {
        {
            auction with 
            startingPrice   = PropHelper.get(arg.startingPrice, auction.startingPrice);
            startTime       = PropHelper.get(arg.startTime, auction.startTime);
            endsAt          = PropHelper.get(arg.endsAt, auction.endsAt);
            quoteAsset      = PropHelper.get(arg.quoteAsset, auction.quoteAsset);
            buyNowPrice     = PropHelper.getNullable(arg.buyNowPrice, auction.buyNowPrice);
            reservePrice    = PropHelper.getNullable(arg.reservePrice, auction.reservePrice);
        }
    };
    
    public func updateAuctionListing(arg: AuctionUArg, property: Property, caller: Principal): async MarketplaceIntentResult {
        switch(PropHelper.getElementByKey(property.nftMarketplace.listings, arg.listingId)){
            case(?#LiveAuction(auction)){
                let updatedAuction = mutateAuction(arg, auction);
                switch(validateAuctionListing(updatedAuction, caller)){case(#ok(_)){}; case(#err(e)) return #Err(e)};
                return #Ok( #Update( #LiveAuction(updatedAuction), arg.listingId));
            };
            case(?_) return #Err(#InvalidType);
            case(null) return #Err(#InvalidElementId);
        }
    };

  

    func createSoldFixedPrice(property: Property, arg: BidArg, fixedPrice: FixedPrice, caller: Principal): async MarketplaceIntentResult {
        let bid = switch(verifyBid(arg, fixedPrice.price, fixedPrice.seller, caller, fixedPrice.expiresAt)){case(#ok(bid)) bid; case(#err(e)) return #Err(e)};
        let royalty = (bid.bidAmount * property.nftMarketplace.royalty / 100000);
        let nftTransferArgs = (property.nftMarketplace.collectionId, null, bid.buyer, fixedPrice.tokenId);
        switch(await NFT.verifyTransfer(nftTransferArgs)){case(?#Ok(_)) {}; case(?#Err(e)) return #Err(#Transfer(?e)); case(null) return #Err(#Transfer(null))};
        switch(await Tokens.transferFrom(fixedPrice.quoteAsset, bid.bidAmount - royalty, {owner = fixedPrice.seller.owner; subaccount = null}, bid.buyer)){case(#Ok(_)) {}; case(#Err(e)) return #Err(#Transfer(?e))};
        switch(await NFT.transfer(nftTransferArgs)){case(?#Ok(_)) {}; case(?#Err(e)) return #Err(#Transfer(?e)); case(null) return #Err(#Transfer(null))};
        let soldFixedPrice = {
            fixedPrice with
            bid;
            royaltyBps = ?royalty;
        };
        return #Ok(#Update (#SoldFixedPrice(soldFixedPrice), arg.listingId))
    };

    func createSoldLaunched(property: Property, arg: BidArg, fixedPrice: FixedPrice, caller: Principal): async MarketplaceIntentResult {
        switch(await createSoldFixedPrice(property, arg, fixedPrice, caller)){
            case(#Ok(#Update(#SoldFixedPrice(arg), id))) #Ok(#Update(#SoldLaunchFixedPrice(arg), id));
            case(#Err(e)) #Err(e);
            case(_) #Err(#InvalidType);
        }
    };

    func createSoldAuction(property: Property, arg: Bid, auction: Auction, listingId: Nat): async MarketplaceIntentResult {
       //validate and complete transfer - probs make allowance first - and check an allowance exists
        //need to change the args for transferFrom
        let royalty = arg.bidAmount * property.nftMarketplace.royalty / 100_000;
        let nftTransferArgs = (property.nftMarketplace.collectionId, null, arg.buyer, auction.tokenId);
        switch(await NFT.verifyTransfer(nftTransferArgs)){case(?#Ok(_)) {}; case(?#Err(e)) return #Err(#Transfer(?e)); case(null) return #Err(#Transfer(null))};
        switch(await Tokens.transferFromBackend(auction.quoteAsset, arg.bidAmount - royalty, auction.seller, null)){case(#Ok(_)) {}; case(#Err(e)) return #Err(#Transfer(?e))};
        switch(await NFT.transfer(nftTransferArgs)){case(?#Ok(_)) {}; case(?#Err(e)) return #Err(#Transfer(?e)); case(null) return #Err(#Transfer(null))};

        let soldAuction: SoldAuction =  {
            auction with
            auctionEndTime = Time.now();
            soldFor = arg.bidAmount;
            boughtNow = true;
            buyer = arg.buyer;
            royaltyBps = ?royalty;
        };
        return #Ok(#Update(#SoldAuction(soldAuction), listingId));
    };

    public func endAuction(property: Property, auction : Auction, listingId: Nat): async () {
        let outcome : {#Purchase: Bid; #Cancel} = switch(auction.highestBid, auction.reservePrice){
            case(?bid, ?reserve) if(bid.bidAmount > reserve) #Purchase(bid) else #Cancel;
            case(?bid, null) #Purchase(bid);
            case(_) #Cancel;
        };
        let (action, intent) : (MarketplaceAction, MarketplaceIntentResult) = switch(outcome){
            case(#Purchase(bid)){
                let arg : AuctionUArg = {
                    listingId;
                    startingPrice = null;
                    buyNowPrice = null;
                    reservePrice = null;
                    startTime = null;
                    endsAt = null;
                    quoteAsset = null;
                };
                let intent = await createSoldAuction(property, bid, auction, listingId);
                (#UpdateAuctionListing(arg), intent);
            };
            case(#Cancel){
                let arg = {
                        cancelledBy_subaccount = null; 
                        listingId; 
                        reason = #Expired;
                };
                let intent = await createCancelledAuction(property, arg, auction, auction.seller.owner);
                (#CancelListing(arg), intent);
            };
        };
        let _ = applyMarketplaceIntentResult(intent, property, action);
    };

    public func setUpEndsAtTimer(property : Property, listingId: Nat, delaySeconds : Nat) : async () {
        ignore setTimer<system>(
          #seconds delaySeconds,
          func () : async () {
            switch(PropHelper.getElementByKey(property.nftMarketplace.listings, listingId)){
                case(?#LiveAuction(auction)) if(auction.endsAt > Time.now()) await endAuction(property, auction, listingId) else await setUpEndsAtTimer(property, listingId, Int.abs(auction.endsAt - Time.now()));
                case(?#LiveFixedPrice(fixedPrice)) await endFixedPrice(property, fixedPrice, listingId);
                case(_) return;
            };
          }
        );
    };
    
    func endFixedPrice(property: Property, fixedPrice: FixedPrice, listingId: Nat): async (){
        switch(fixedPrice.expiresAt){
            case(?expiresAt) if(Time.now() > expiresAt) return await setUpEndsAtTimer(property, listingId, Int.abs(expiresAt - Time.now()));
            case(null) return; 
        };
        
        let arg = {
            cancelledBy_subaccount = null; 
            listingId; 
            reason = #Expired;
        };
        let intent = await createCancelledFixedPrice(property, arg, fixedPrice, fixedPrice.seller.owner);
        let _ = applyMarketplaceIntentResult(intent, property, #CancelListing(arg));
    };

    
    public func addBidToAuction(auction: Auction, arg: BidArg, property: Property, caller: Principal, listingId: Nat): async  MarketplaceIntentResult {
        //verify bid
        let minBidAmount = switch(auction.highestBid){case(?bid) bid.bidAmount + auction.bidIncrement; case(null) auction.startingPrice};
        let bid = switch(verifyBid(arg, minBidAmount, auction.seller, caller, ?auction.endsAt)){case(#ok(bid)) bid; case(#err(e)) return #Err(e)};
        switch(await Tokens.transferFrom(auction.quoteAsset, bid.bidAmount, {owner = Principal.fromText("vq2za-kqaaa-aaaas-amlvq-cai"); subaccount = null}, bid.buyer)){
            case(#Ok(_)){
                if(Option.get(auction.buyNowPrice, 0) == bid.bidAmount) return await createSoldAuction(property, bid, auction, listingId);
                var updatedAuction : Auction = {
                    auction with
                    highestBid = ?bid;
                    previousBids = Array.append(auction.previousBids, [bid]);
                }; 
                updatedAuction := switch(auction.highestBid){
                    case(?previousBid) {
                        let result = await Tokens.transferFromBackend(auction.quoteAsset, previousBid.bidAmount, previousBid.buyer, null);
                        let refund = createRefund(auction.refunds.size(), {owner = Principal.fromText("vq2za-kqaaa-aaaas-amlvq-cai"); subaccount = null}, previousBid.buyer, previousBid.bidAmount, result);
                        {updatedAuction with refunds = Array.append(updatedAuction.refunds, [refund])};
                    }; 
                    case(null){
                        updatedAuction;
                    };                    
                };
                return #Ok( #Update( #LiveAuction(updatedAuction), arg.listingId));
            };
            case(#Err(e)){
                return #Err(#Transfer(?e));
            }
        };



    };

    public func placeBid(arg: BidArg, property: Property, caller: Principal): async MarketplaceIntentResult {
        switch(PropHelper.getElementByKey(property.nftMarketplace.listings, arg.listingId)){
            case(?listing){
                switch(listing){
                    case(#LaunchFixedPrice(fixedPrice)){
                        await createSoldLaunched(property, arg, fixedPrice, caller);
                    };
                    case(#LiveAuction(auction)){
                        await addBidToAuction(auction, arg, property, caller, arg.listingId);
                    }; 
                    case(#LiveFixedPrice(fixedPrice)){
                        await createSoldFixedPrice(property, arg, fixedPrice, caller);
                    };
                    case(_)return #Err(#InvalidType)
                };
            };
            case(null){
                return #Err(#InvalidElementId);
            }
        }
    };

    func verifyCancelArgs(arg: CancelArg, seller: Account, caller: Principal, bid: ?Bid): Result.Result<CancelArg, UpdateError>{
        if(seller != {owner = caller; subaccount = null}) return #err(#Unauthorized);
        if(bid != null) return #err(#ImmutableLiveAuction);
        return #ok(arg);
    };

    func createCancelledFixedPrice(property: Property, arg: CancelArg, fixedPrice: FixedPrice, caller: Principal): async MarketplaceIntentResult {
        //validate and transfer nft back to them
        switch(verifyCancelArgs(arg, fixedPrice.seller, caller, null)){case(#ok(_)){}; case(#err(e)) return #Err(e)};
        switch(await NFT.transfer(property.nftMarketplace.collectionId, null, fixedPrice.seller, fixedPrice.tokenId)){
            case(?#Ok(_)){
                let cancelledFixedPrice = {
                    fixedPrice with
                    cancelledBy = {owner = caller; subaccount = null};
                    cancelledAt = Time.now();
                    reason = arg.reason;
                };
                return #Ok(#Update (#CancelledFixedPrice(cancelledFixedPrice), arg.listingId))
            };
            case(?#Err(e)) return #Err(#Transfer(?e));
            case(_) return #Err(#Transfer(null));
        };
    };

    func createCancelledLaunch(property: Property, arg: CancelArg, fixedPrice: FixedPrice, caller: Principal): async MarketplaceIntentResult{
        switch(await createCancelledFixedPrice(property, arg, fixedPrice, caller)){
            case(#Ok(#Update(#CancelledFixedPrice(arg), id))) #Ok(#Update(#CancelledLaunch(arg), id));
            case(#Err(e)) #Err(e);
            case(_) return #Err(#InvalidType);
        }
    };

    func createCancelledAuction(property: Property, arg: CancelArg, auction: Auction, caller: Principal): async  MarketplaceIntentResult {
        //validate and transfer nft back to them
        switch(verifyCancelArgs(arg, auction.seller, caller, auction.highestBid)){case(#ok(_)){}; case(#err(e)) return #Err(e)};
        switch(await NFT.transfer(property.nftMarketplace.collectionId, null, auction.seller, auction.tokenId)){
            case(?#Ok(_)){
                let refund = switch(auction.highestBid){
                    case(null){[]}; 
                    case(?bid){
                        let result = await Tokens.transferFromBackend(auction.quoteAsset, bid.bidAmount, bid.buyer, null);
                        [createRefund(auction.refunds.size(), {owner = Principal.fromText("vq2za-kqaaa-aaaas-amlvq-cai"); subaccount = null}, bid.buyer, bid.bidAmount, result)]
                    };
                };
                let cancelledAuction = {
                    auction with
                    cancelledBy = {owner = caller; subaccount = null};
                    cancelledAt = Time.now();
                    reason = arg.reason;
                    refunds = Array.append(auction.refunds, refund);
                };
                return #Ok(#Update (#CancelledAuction(cancelledAuction), arg.listingId))

            };
            case(?#Err(e)) return #Err(#Transfer(?e));
            case(_) return #Err(#Transfer(null));
        };
        
    
    };

    public func cancelListing(arg: CancelArg, property: Property, caller: Principal): async MarketplaceIntentResult {
        switch(PropHelper.getElementByKey(property.nftMarketplace.listings, arg.listingId)){
            case(?listing){
                //Validate the bid - ensure they have enough to purchase - perhaps we either call validateTransfer or attach a transferResult or create an approval, then immediately transfer the tokens
                switch(listing){
                    case(#LiveAuction(auction)){
                        await createCancelledAuction(property, arg, auction, caller);

                    }; 
                    case(#LiveFixedPrice(fixedPrice)){
                        await createCancelledFixedPrice(property, arg, fixedPrice, caller);
                    };
                    case(#LaunchFixedPrice(fixedPrice)){
                        await createCancelledLaunch(property, arg, fixedPrice, caller);
                    };
                    case(_)return #Err(#InvalidType)
                };
            };
            case(null){
                return #Err(#InvalidElementId);
            }
        }
    };

    type Launch = Types.Launch;
    type LaunchArg = Types.LaunchArg;
    type TransferArg = Types.TransferArg;
    func validateLaunchArg(caller: Principal, arg: LaunchArg, tokenIds: [Nat]): Result.Result<(), UpdateError>{
        let time = Time.now();
       // if(Principal.notEqual(caller, PropHelper.getAdmin())) return #err(#Unauthorized);
        if(time > Option.get(arg.endsAt, time)) return #err(#InvalidData{field = "ends at"; reason = #CannotBeSetInThePast});
        if(arg.price == 0) return #err(#InvalidData{field = "price"; reason = #CannotBeZero});
        if(10 > Option.get(arg.maxListed, 11)) return #err(#InvalidData{field = "max listed"; reason = #OutOfRange});
        if(Principal.equal(caller, Principal.fromText("vq2za-kqaaa-aaaas-amlvq-cai")) and arg.transferType != #Transfer) return #err(#InvalidData{field = "transfer type"; reason = #BuyerAndSellerCannotMatch});
        if(10 > tokenIds.size()) return #err(#InvalidData{field = "insufficient tokens"; reason = #DataMismatch});
        #ok();
    };

    func createLaunch(property: Property, caller: Principal, arg: LaunchArg): async  MarketplaceIntentResult {
        //let from = {owner = if(arg.transferType == #Transfer) Principal.fromText("vq2za-kqaaa-aaaas-amlvq-cai") else caller; subaccount = arg.from_subaccount};
        let from = {owner = Principal.fromText("vq2za-kqaaa-aaaas-amlvq-cai"); subaccount = null};
        let seller = {owner = Principal.fromText("vq2za-kqaaa-aaaas-amlvq-cai"); subaccount = null};
        let tokenIds = await NFT.tokensOf(property.nftMarketplace.collectionId, from, null, arg.maxListed);
        switch(validateLaunchArg(caller, arg, tokenIds)){case(#err(e)) return #Err(e); case(#ok()) {}};
        
        let transferFromArgs = Buffer.Buffer<TransferFromArg>(tokenIds.size());
        let transferArgs = Buffer.Buffer<TransferArg>(tokenIds.size());
        for(token in tokenIds.vals()){
            if(arg.transferType == #TransferFrom)  transferFromArgs.add(NFT.createTransferFromArg(from, seller, token)) 
            else transferArgs.add(NFT.createTransferArg(token, null, seller));
        };

        let results = await if(arg.transferType == #TransferFrom) NFT.transferFromBulk(property.nftMarketplace.collectionId, Buffer.toArray(transferFromArgs)) else NFT.transferBulk(property.nftMarketplace.collectionId, Buffer.toArray(transferArgs));
        let verifiedTokenIds = Buffer.Buffer<Nat>(0);
        let listings = Buffer.Buffer<(Nat, Listing)>(0);
        for(i in results.keys()){
            switch(results[i]){
                case(?#Ok(_)){
                    verifiedTokenIds.add(tokenIds[i]);
                    listings.add(property.nftMarketplace.listId + i + 2, #LaunchFixedPrice{
                        id = property.nftMarketplace.listId + i + 2;
                        price = arg.price;
                        expiresAt = arg.endsAt;
                        tokenId = tokenIds[i];
                        quoteAsset = Option.get(arg.quoteAsset, #HGB);
                        listedAt = Time.now();
                        seller;
                    });
                };
                case(_){};
            };
        };
        let launch : Listing = #LaunchedProperty{
            id = property.nftMarketplace.listId + 1;
            seller;
            caller;
            tokenIds = Buffer.toArray(verifiedTokenIds);
            args = Buffer.toArray(listings);
            maxListed = Option.get(arg.maxListed, verifiedTokenIds.size());
            listedAt = Time.now();
            price = arg.price;
            quoteAsset = Option.get(arg.quoteAsset, #HGB);
        };
        #Ok(#Create(launch, property.nftMarketplace.listId + 1));
    };


    public func writeListings(action: MarketplaceAction, property: Property, caller: Principal): async UpdateResult {
        let result : MarketplaceIntentResult = switch(action){
            case(#LaunchProperty(arg)){
                await createLaunch(property, caller, arg);
            };
            case(#CreateFixedListing(arg)){
                await createFixedListing(arg, property, caller);
            };
            case(#CreateAuctionListing(arg)){
                await createAuctionListing(arg, property, caller);
            };
            case(#UpdateFixedListing(arg)){
                await updateFixedListing(arg, property, caller);
            };
            case(#UpdateLaunch(arg)){
                await updateLaunchedFixedPrice(arg, property, caller);
            };
            case(#UpdateAuctionListing(arg)){
                await updateAuctionListing(arg, property, caller);
            };
            case(#Bid(arg)){
                await placeBid(arg, property, caller);
            };
            case(#CancelListing(arg)){
                await cancelListing(arg, property, caller);
            };
        };  
        applyMarketplaceIntentResult(result, property, action);
    };

    func applyMarketplaceIntentResult(result: MarketplaceIntentResult, property: Property, action: MarketplaceAction): UpdateResult {
        let updatedNftMarketplace :NFTMarketplace = switch(result){
            case(#Ok(#Create(#LaunchedProperty(arg), id))){
                {
                    property.nftMarketplace with
                    listId = property.nftMarketplace.listId + arg.args.size();
                    listings = Array.append(property.nftMarketplace.listings, Array.append([(id, #LaunchedProperty(arg))], arg.args));
                }
            };
            case(#Ok(act)){
                {
                    property.nftMarketplace with
                    listId = PropHelper.updateId(act, property.nftMarketplace.listId);
                    listings = PropHelper.performAction(act, property.nftMarketplace.listings);
                };
            };
            case(#Err(e)){
                return #Err(e)
            }
        };
       PropHelper.updateProperty(#NFTMarketplace(updatedNftMarketplace), property, #NFTMarketplace(action));
    };



    public func tagMatching(listing: Listing, optTag: ?[MarketplaceOptions]): Bool {
        let opts = switch(optTag){case(null) return true; case(?opt) opt};
        let tag: MarketplaceOptions = switch listing {
            case (#LaunchedProperty(_)) #PropertyLaunch;
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

    //public func getListings(properties: ReadTypeArray<Property>, acc: ?Account, marketplaceOption: ?[MarketplaceOptions], getAcc: Listing -> [Account]): ReadUnsanitized {
    //    let result = Buffer.Buffer<ReadType<[(Nat, Listing)]>>(properties.size());
    //    for (res in properties.vals()) {
    //        switch(res.value){
    //            case(#Err(e)) result.add({propertyId = res.propertyId; value = #Err(e)});
    //            case(#Ok(property)){
    //                let listings = Buffer.Buffer<(Nat, Listing)>(0);
    //                for((id, listing) in property.nftMarketplace.listings.vals()){
    //                    if(PropHelper.matchNullableAccountArr(acc, getAcc(listing)) and tagMatching(listing, marketplaceOption)) listings.add((id, listing));
    //                };
    //                let res : ReadType<[(Nat, Listing)]> = {
    //                    propertyId = property.id;
    //                    value = switch(listings.size()){case(0) #Err(#EmptyArray); case(_)#Ok(Buffer.toArray(listings))}
    //                };
    //                result.add(res);
    //            } 
    //        }
    //    };
    //    #Listings(Buffer.toArray(result));
    //};

    


    type What = Types.What;
    type TransferFromArg = Types.TransferFromArg;
    type WhatWithPropertyId = Types.WhatWithPropertyId;
    type LaunchProperty = Types.LaunchProperty;
    type UpdateResultNat = Types.UpdateResultNat;
    public func createLaunchArgs(arg: LaunchProperty, property: Property): async [WhatWithPropertyId]{
        let tokenIds = await NFT.tokensOf(property.nftMarketplace.collectionId, {owner = Principal.fromText("vq2za-kqaaa-aaaas-amlvq-cai"); subaccount = null}, null, null);
        let args = Buffer.Buffer<WhatWithPropertyId>(tokenIds.size());
        for(tokenId in tokenIds.vals()){
            args.add({what = #NFTMarketplace(#CreateFixedListing{
                tokenId;
                seller_subaccount = null;
                price = arg.price;
                expiresAt = arg.endsAt;
                quoteAsset = arg.quoteAsset
            }); propertyId = arg.propertyId});
        };
        Buffer.toArray(args);
    };
//        if(tokenIds.size() > 0){
//            var fixedPrice : FixedPrice = {
//                tokenId = tokenIds[0];
//                listedAt = Time.now();
//                seller = {owner = Principal.fromText("vq2za-kqaaa-aaaas-amlvq-cai"); subaccount = null};
//                price = arg.price;
//                expiresAt = arg.endsAt;
//                quoteAsset = Option.get(arg.quoteAsset, #HGB);
//            };
//            let transferResults = switch(validateFixedListing(fixedPrice, caller)){
//                case(#err(e)) return #Err(e);
//                case(#ok(_))  await NFT.transferFromBulk(property.nftMarketplace.collectionId, tokenIds, fixedPrice.seller, {owner = fixedPrice.seller.owner; subaccount = ?Principal.toBlob(fixedPrice.seller.owner)});
//            };
//            for(result in transferResults.vals()){
//                switch(result){
//                    case(?#Ok(id)){
//                        fixedPrice := {fixedPrice with tokenId = id};
//                        {
//
//                        }
//                        args.add(fixedPrice);
//                    };
//                    case(?#Err(e)){}
//                }
//            };
//
//
//
//        };
//        //reality is that if one passes then they'd all pass
//        //so why not just feed in the first id in the array - if fails - return from this functon
//        //if succeeds - create transfer from args for all in a array
//        //Then call transfer from on entire array
//        //if that succeeds - create individual fixed price
//        for(i in tokenIds.keys()){
//            
//
//        };
//
//            
//            args.add({what = #NFTMarketplace(#CreateFixedListing(fixedPrice)); propertyId = arg.propertyId});
//        };
   
}