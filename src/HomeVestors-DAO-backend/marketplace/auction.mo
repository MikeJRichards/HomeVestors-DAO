import Types "../types";
import { setTimer; cancelTimer } = "mo:base/Timer";
import UnstableTypes "./../Tests/unstableTypes";
import PropHelper "../propHelper";
import Time "mo:base/Time";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Array "mo:base/Array";
import Option "mo:base/Option";
import Nat "mo:base/Nat";

module {
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
    type GenericTransferResult = Types.GenericTransferResult;
    type Refund = Types.Refund;
    type PropertyUnstable = UnstableTypes.PropertyUnstable;

    public func createRefund(auction: Auction, res: ?GenericTransferResult): [Refund] {
        let (bid, result) = switch(auction.highestBid, res){case(?bid, ?result) (bid, result); case(_) return []};
        let refund = {
            id = auction.id;
            asset = auction.quoteAsset;
            from = {owner = Principal.fromText("vq2za-kqaaa-aaaas-amlvq-cai"); subaccount = null};
            to = bid.buyer;
            amount = bid.bidAmount;
            attempted_at = Time.now();
            result;
        };
        switch(result){
            case(#Err(_)) [#Err(refund)];
            case(#Ok(_)) [#Ok(refund)]
        };
    };

    public func determineCancelledReason(auction: Auction, caller: ?Principal): ?Types.CancelledReason {
        let cancelledBySeller = caller == ?auction.seller.owner;
        let cancelledByAdmin = caller == ?PropHelper.getAdmin(); 
        let expired = Time.now() > auction.endsAt;
        switch(auction.highestBid, auction.reservePrice){
            case(?bid, ?reservePrice) if(reservePrice > bid.bidAmount and expired) ?#ReserveNotMet else if(cancelledByAdmin) ?#CalledByAdmin else null;
            case(?_, null) if(cancelledByAdmin) ?#CalledByAdmin else null;
            case(null, _) if(expired) ?#Expired else if(cancelledBySeller) ?#CancelledBySeller else if(cancelledByAdmin) ?#CalledByAdmin else null;
        }
    };

    public func delete (auction: Auction, caller: Principal, result: ?GenericTransferResult): Listing {
        let resolvedCaller = if(Time.now() > auction.endsAt) null else ?caller;
        let cancelledReason = determineCancelledReason(auction, resolvedCaller);
        
        switch(cancelledReason){
            case(null) #LiveAuction(auction);
            case(?reason){
                #CancelledAuction({
                    auction with
                    cancelledBy = {owner = caller; subaccount = null};
                    cancelledAt = Time.now();
                    refunds = Array.append(auction.refunds, createRefund(auction, result));
                    reason;
                });
            }
        };
    };

    public func mutate(auction: Auction, arg: AuctionUArg): Listing {
        #LiveAuction({
            auction with 
            startingPrice   = PropHelper.get(arg.startingPrice, auction.startingPrice);
            startTime       = PropHelper.get(arg.startTime, auction.startTime);
            endsAt          = PropHelper.get(arg.endsAt, auction.endsAt);
            quoteAsset      = PropHelper.get(arg.quoteAsset, auction.quoteAsset);
            buyNowPrice     = PropHelper.getNullable(arg.buyNowPrice, auction.buyNowPrice);
            reservePrice    = PropHelper.getNullable(arg.reservePrice, auction.reservePrice);
        })
    };

    public func validate (arg: Auction, caller: Principal): Result.Result<Listing, UpdateError>{
     if(Principal.notEqual(caller, arg.seller.owner)) return #err(#Unauthorized);
        if(Option.get(arg.buyNowPrice, arg.startingPrice) < arg.startingPrice) return #err(#InvalidData{field= "buy now price"; reason = #InvalidInput});
        if(arg.bidIncrement < 1) return #err(#InvalidData{field= "bid increment"; reason = #InvalidInput});
        if(Option.get(arg.reservePrice, arg.startingPrice) > Option.get(arg.buyNowPrice, arg.startingPrice)) return #err(#InvalidData{field= "reserve price"; reason = #InvalidInput});
        if(arg.startTime > arg.endsAt) return #err(#InvalidData{field= "start time"; reason = #OutOfRange});
        if(arg.highestBid != null) return #err(#ImmutableLiveAuction);
        if(arg.endsAt < Time.now()) return #err(#InvalidData{field= "end time"; reason = #CannotBeSetInThePast});
        return #ok(#LiveAuction(arg))
    };

    public func create(arg: AuctionCArg, id: Nat, caller: Principal): Listing {
        #LiveAuction({
            arg with 
            id;
            listedAt = Time.now();
            seller = {owner = caller; subaccount = null};
            quoteAsset = PropHelper.get(arg.quoteAsset, #ICP);
            bidIncrement = 1;
            highestBid = null;
            previousBids = [];
            refunds = [];
       });
    };
}