import Types "../types";
import { setTimer; cancelTimer } = "mo:base/Timer";
import UnstableTypes "./../Tests/unstableTypes";
import PropHelper "../propHelper";
import Time "mo:base/Time";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
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
    type PropertyUnstable = UnstableTypes.PropertyUnstable;

    public func determineCancelledReason(fixedPrice: FixedPrice, caller: ?Principal): ?Types.CancelledReason {
        let cancelledBySeller = caller == ?fixedPrice.seller.owner;
        let cancelledByAdmin = caller == ?PropHelper.getAdmin(); 
        let expired = switch(fixedPrice.expiresAt){case(null) false; case(?e) Time.now() > e ;};
        return if(expired) ?#Expired else if (cancelledBySeller) ?#CancelledBySeller else if (cancelledByAdmin) ?#CalledByAdmin else null;
    };

    public func mutate(fixedPrice: FixedPrice, arg: FixedPriceUArg): Listing {
        #LiveFixedPrice({
            fixedPrice with 
            price      = PropHelper.get(arg.price, fixedPrice.price);
            quoteAsset = PropHelper.get(arg.quoteAsset, fixedPrice.quoteAsset);
            expiresAt  = PropHelper.getNullable(arg.expiresAt, fixedPrice.expiresAt);
        })
    };

    public func validate (arg: FixedPrice): Result.Result<Listing, UpdateError>{
        let time = Time.now();
        //if(Principal.notEqual(caller, arg.seller.owner)) return #err(#Unauthorized);
        if(arg.price == 0) return #err(#InvalidData{field = "price"; reason = #CannotBeZero});
        if(Option.get(arg.expiresAt, time) < time) return #err(#InvalidData{field= "expires at"; reason = #CannotBeSetInThePast});
        return #ok(#LiveFixedPrice(arg));
    };

    public func create(arg: FixedPriceCArg, id: Nat, caller: Principal): Listing {
        #LiveFixedPrice({
            tokenId = arg.tokenId;
            price = arg.price;
            expiresAt = arg.expiresAt;
            id = id;
            listedAt = Time.now();
            seller = {owner = caller; subaccount = arg.seller_subaccount};
            quoteAsset = PropHelper.get(arg.quoteAsset, #ICP); 
        });
    };
}