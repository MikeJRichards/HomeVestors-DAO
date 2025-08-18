import Types "../types";
import { setTimer; cancelTimer } = "mo:base/Timer";
import UnstableTypes "./../Tests/unstableTypes";
import NFT "../nft";
import Result "mo:base/Result";
import Principal "mo:base/Principal";

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
    type NftMarketplacePartialUnstable = UnstableTypes.NftMarketplacePartialUnstable;

    public func withLive<R>(listing: ?Listing, onLive: FixedPrice -> R, onAuction: Auction -> R, onInvalid: () -> R, onNull: () -> R): R {
        switch (listing) {
            case (?#LiveFixedPrice(liveVal)) onLive(liveVal);
            case (?#LiveAuction(liveVal)) onAuction(liveVal);
            case (null) onNull();
            case(_) onInvalid();
        }
    };

    public func withLiveAsyncDefault(listing: ?Listing, onFixed: FixedPrice -> async Result.Result<(), UpdateError>, onAuction: Auction -> async Result.Result<(), UpdateError>): async Result.Result<(), UpdateError> {
        switch (listing) {
            case (?#LiveFixedPrice(liveVal)) await onFixed(liveVal);
            case (?#LiveAuction(liveVal)) await onAuction(liveVal);
            case (null) return #err(#InvalidElementId);
            case (_) return #err(#InvalidType);
        }
    };

    public func resetTimer<system>(m: UnstableTypes.NftMarketplacePartialUnstable, listId: Nat, delay: Nat, onExpire: () -> async ()): () {
        // Cancel old timer if it exists
        cancelListingTimer(m, listId);

        let timerId = setTimer<system>(#nanoseconds delay, func () : async () {await onExpire()}); 

        m.timerIds.put(listId, timerId);
    };

    public func transferFromSeller(m: NftMarketplacePartialUnstable, tokenId: Nat, seller: Account): async Result.Result<(), UpdateError> {
        switch (await NFT.transferFrom(m.collectionId, seller, {owner = Principal.fromText("vq2za-kqaaa-aaaas-amlvq-cai"); subaccount = null}, tokenId)) {
            case (?#Ok(_)) return #ok();
            case (?#Err(e)) return #err(#Transfer(?e));
            case (_) return #err(#Transfer(null));
        };
    };

    public func transferBackToSeller(m: NftMarketplacePartialUnstable, tokenId: Nat, seller: Account): async Result.Result<(), UpdateError> {
        switch (await NFT.transfer(m.collectionId, null, seller, tokenId)) {
            case (?#Ok(_)) return #ok();
            case (?#Err(e)) return #err(#Transfer(?e));
            case (_) return #err(#Transfer(null));
        };
    };
    
    //let getTimerId = func(p: PropertyUnstable, listId: Nat): ?Nat = p.nftMarketplace.timerIds.get(listId); 
    public func cancelListingTimer(m: NftMarketplacePartialUnstable, listId: Nat): (){
        switch(m.timerIds.get(listId)){
            case(null){}; 
            case(?id) cancelTimer(id)
        };
    };
    
    
}