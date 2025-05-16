import Types "types";
import PropHelper "propHelper";
import Time "mo:base/Time";

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

    public func createNFTMarketplace(collectionId: Principal): NFTMarketplace {
        {
            collectionId;
            listId = 0;
            listings = [];
            royalty = 0;
        }
    };

    public func createFixedListing(arg: FixedPriceCArg, property: Property, caller: Principal): async MarketplaceIntentResult {
        //validate that they've transfered us the NFT, or that we're approved to transfer their nft to use first
        //validate the actual args as well
        let newId = property.nftMarketplace.listId + 1;
        let newListing = #LiveFixedPrice({
            tokenId = arg.tokenId;
            listedAt = Time.now();
            seller = {owner = caller; subaccount = arg.seller_subaccount};
            quoteAsset = PropHelper.get(arg.quoteAsset, #ICP);
            price = arg.price;
            expiresAt = arg.expiresAt;
        });
        return #Ok( #Create( newListing, newId));
    };

    public func createAuctionListing(arg: AuctionCArg, property: Property, caller: Principal): async MarketplaceIntentResult {
        //validate that they've transfered us the NFT, or that we're approved to transfer their nft to use first
        //validate the actual args as well
        let newId = property.nftMarketplace.listId + 1;
        let newListing : Listing = #LiveAuction({
            tokenId = arg.tokenId;
            listedAt = Time.now();
            seller = {owner = caller; subaccount = arg.seller_subaccount};
            quoteAsset = PropHelper.get(arg.quoteAsset, #ICP);
            startingPrice = arg.startingPrice;
            buyNowPrice = arg.buyNowPrice;
            bidIncrement = 1;
            reservePrice = arg.reservePrice;
            startTime = arg.startTime;
            endsAt = arg.endsAt;
            highestBid = null;
            previousBids = [];
        });
        return #Ok(#Create(newListing, newId));
    };

    func mutateFixedListing(arg: FixedPriceUArg, fixedPrice: FixedPrice): FixedPrice {
        {
            fixedPrice with
            price           = PropHelper.get(arg.price, fixedPrice.price);
            quoteAsset      = PropHelper.get(arg.quoteAsset, fixedPrice.quoteAsset);
            expiresAt       = PropHelper.getNullable(arg.expiresAt, fixedPrice.expiresAt);
        }
    };

    public func updateFixedListing(arg: FixedPriceUArg, property: Property): MarketplaceIntentResult {
        switch(PropHelper.getElementByKey(property.nftMarketplace.listings, arg.listingId)){
            case(?listing){
                let fixedPrice = switch(listing){case(#LiveFixedPrice(arg)) arg; case(_)return #Err(#InvalidType)};
                let updatedFixedPrice = mutateFixedListing(arg, fixedPrice);
                //validation step
                return #Ok( #Update( #LiveFixedPrice(updatedFixedPrice), arg.listingId));
            };
            case(null){
                return #Err(#InvalidElementId);
            }
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
    
    public func updateAuctionListing(arg: AuctionUArg, property: Property): MarketplaceIntentResult {
        switch(PropHelper.getElementByKey(property.nftMarketplace.listings, arg.listingId)){
            case(?listing){
                let auction = switch(listing){case(#LiveAuction(arg)) arg; case(_)return #Err(#InvalidType)};
                let updatedAuction= mutateAuction(arg, auction);
                //validation step
                return #Ok( #Update( #LiveAuction(updatedAuction), arg.listingId));
            };
            case(null){
                return #Err(#InvalidElementId);
            }
        }
    };

    func createSoldFixedPrice(arg: BidArg, fixedPrice: FixedPrice, caller: Principal, royalty: Nat): async SoldFixedPrice {
        //transfer tokens to seller
        {
            fixedPrice with
            soldAt = Time.now();
            buyer = {owner = caller; subaccount = arg.buyer_subaccount};
            royaltyBps = ?(arg.bidAmount * royalty / 100000);
        }
    };

    func createSoldAuction(arg: BidArg, auction: Auction, caller: Principal, royalty: Nat): async SoldAuction {
       //validate and complete transfer - probs make allowance first - and check an allowance exists
        {
            auction with
            auctionEndTime = Time.now();
            soldFor = arg.bidAmount;
            boughtNow = switch(auction.buyNowPrice){case(?p) if(p == arg.bidAmount) true else false; case(null)false};
            buyer = {owner = caller; subaccount = arg.buyer_subaccount};
            royaltyBps = ?(arg.bidAmount * royalty / 100_000);
        }
    };

    public func placeBid(arg: BidArg, property: Property, caller: Principal): async MarketplaceIntentResult {
        switch(PropHelper.getElementByKey(property.nftMarketplace.listings, arg.listingId)){
            case(?listing){
                //Validate the bid - ensure they have enough to purchase - perhaps we either call validateTransfer or attach a transferResult or create an approval, then immediately transfer the tokens
                switch(listing){
                    case(#LiveAuction(auction)){
                        let soldAuction = await createSoldAuction(arg, auction, caller, property.nftMarketplace.royalty);
                        return #Ok(#Update (#SoldAuction(soldAuction), arg.listingId))

                    }; 
                    case(#LiveFixedPrice(fixedPrice)){
                        let soldfixedPrice = await createSoldFixedPrice(arg, fixedPrice, caller, property.nftMarketplace.royalty);
                        return #Ok(#Update (#SoldFixedPrice(soldfixedPrice), arg.listingId))
                    };
                    case(_)return #Err(#InvalidType)
                };
            };
            case(null){
                return #Err(#InvalidElementId);
            }
        }
    };

    func createCancelledFixedPrice(arg: CancelArg, fixedPrice: FixedPrice, caller: Principal): async CancelledFixedPrice {
        //validate and transfer nft back to them
        {
            fixedPrice with
            cancelledBy = {owner = caller; subaccount = arg.cancelledBy_subaccount};
            cancelledAt = Time.now();
            reason = arg.reason;
        }
    };

    func createCancelledAuction(arg: CancelArg, auction: Auction, caller: Principal): async CancelledAuction {
        //validate and transfer nft back to them
        {
            auction with
            cancelledBy = {owner = caller; subaccount = arg.cancelledBy_subaccount};
            cancelledAt = Time.now();
            reason = arg.reason;
        }
    };

    public func cancelListing(arg: CancelArg, property: Property, caller: Principal): async MarketplaceIntentResult {
        switch(PropHelper.getElementByKey(property.nftMarketplace.listings, arg.listingId)){
            case(?listing){
                //Validate the bid - ensure they have enough to purchase - perhaps we either call validateTransfer or attach a transferResult or create an approval, then immediately transfer the tokens
                switch(listing){
                    case(#LiveAuction(auction)){
                        let cancelledAuction = await createCancelledAuction(arg, auction, caller);
                        return #Ok(#Update (#CancelledAuction(cancelledAuction), arg.listingId))

                    }; 
                    case(#LiveFixedPrice(fixedPrice)){
                        let cancelledFixedPrice = await createCancelledFixedPrice(arg, fixedPrice, caller);
                        return #Ok(#Update (#CancelledFixedPrice(cancelledFixedPrice), arg.listingId))
                    };
                    case(_)return #Err(#InvalidType)
                };
            };
            case(null){
                return #Err(#InvalidElementId);
            }
        }
    };


    public func writeListings(action: MarketplaceAction, property: Property, caller: Principal): async UpdateResult {
        let result : MarketplaceIntentResult = switch(action){
            case(#CreateFixedListing(arg)){
                await createFixedListing(arg, property, caller);
            };
            case(#CreateAuctionListing(arg)){
                await createAuctionListing(arg, property, caller);
            };
            case(#UpdateFixedListing(arg)){
                updateFixedListing(arg, property);
            };
            case(#UpdateAuctionListing(arg)){
                updateAuctionListing(arg, property);
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
        let updatedNftMarketplace = switch(result){
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
}