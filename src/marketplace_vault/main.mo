import Map "mo:core/Map";
import Nat "mo:core/Nat";
import Iter "mo:core/Iter";
import Types "./types";
import Principal "mo:core/Principal";
import Result "mo:base/Result";
import List "mo:core/List";

persistent actor MarketplaceVault {
    type Listing = Types.Listing;
    type Bid = Types.Bid;
    type Account = Types.Account;
    // 1. The MAP is stable
    let listingMap = Map.empty<Nat, Types.Listing>();
    let refundMap = Map.empty<Principal, Nat>();
    // 2. The HANDLER is NOT stable — it wraps the stable variable
    transient var listings = Types.createMapHandler<Nat, Types.Listing>(Nat.compare, listingMap);
    transient var refunds = Types.createMapHandler<Principal, Nat>(Principal.compare, refundMap);
    var listingId = 0;

    func assertBackend(caller: Principal):(){
        assert(Principal.equal(caller, Principal.fromText("vq2za-kqaaa-aaaas-amlvq-cai")));
    };

    func addRefundAmount(bid: ?Bid): (){
        switch(bid){
            case(?bid){
                let previousRefundAmount = switch(refunds.get(bid.bidder.owner)){case(?amount) amount; case(null) 0};
                refunds.put(bid.bidder.owner, previousRefundAmount + bid.amount);
            };
            case(null){};
        };
    };

    public shared ({caller}) func createListing(seller: Account, nftCanisterId: Principal, tokenIds: [Nat]): async [Result.Result<(),Types.NFTTransferFromError>]{
        assertBackend(caller);
        let nftActor: Types.NFTActor = actor(Principal.toText(nftCanisterId));
        let argList = Types.createListHandler(List.empty<Types.NFTTransferFromArg>());
        for(tokenId in tokenIds.vals()){
            let arg : Types.NFTTransferFromArg = {
                spender_subaccount = null;
                from = seller;
                to = seller; //should be vault
                token_id = tokenId;
                memo = null;
                created_at_time = null;
            };
            argList.add(arg);
        };
        let transferResults = await nftActor.icrc37_transfer_from(argList.toArray());
        let results = Types.createListHandler(List.empty<Result.Result<(),Types.NFTTransferFromError>>());
        let combinedList = argList.zip<Types.NFTTransferFromArg, ?Types.NFTTransferFromResult>(argList.list, List.fromArray<?Types.NFTTransferFromResult>(transferResults));
        for((arg, result) in combinedList.entries()){
            switch(result){
                case(?#Err(e)) results.add(#err(e));
                case(?#Ok(_)){
                    let listing : Listing = {
                        seller;
                        nftId = arg.token_id;
                        collection = nftCanisterId;
                        bid = null;
                    };
                    listingId += 1;
                    listings.put(listingId, listing);
                    results.add(#ok());
                };
                case(null) results.add(#err(#GenericError({error_code = 500; message= "null transfer attempt"})));
            };
        };
        return results.toArray();
    };

    public shared ({caller}) func placeBid(listingId: Nat, bidder: Account, amount: Nat): async Result.Result<(),()> {
        assertBackend(caller);
        let listing = switch(listings.get(listingId)){case(null) return #err(); case(?listing) listing}; //Error: No Listing
        switch(listing.bid){case(null){}; case(?bid) if(bid.amount > amount) return #err()}; //Error: Insufficient Amount
        let husd: Types.TokenActor = actor("vq2za-kqaaa-aaaas-amlvq-cai");
        let arg : Types.TokenTransferFromArgs = {
            amount;
            fee = null;
            memo = null;
            created_at_time = null;
            to = bidder; //should be vault
            spender_subaccount = null;
            from = bidder;
        };
        let _transactionId = switch(await husd.icrc2_transfer_from(arg)){case(#Ok(transactionId)) transactionId; case(#Err(_e)) return #err();}; //Error: Failed Transaction
        addRefundAmount(listing.bid);
        let updatedListing : Listing = {
            listing with
            bid = ?{
                bidder;
                amount;
            }
        };
        listings.put(listingId, updatedListing);
        return #ok()
    };

    public shared ({caller}) func withdrawRefund(): async Result.Result<(), ()>{
        let husd: Types.TokenActor = actor("vq2za-kqaaa-aaaas-amlvq-cai");
        let arg: Types.TokenTransferArg = {
            amount = switch(refunds.get(caller)){case(null) return #err(); case(?amount) amount;}; //error zero amount
            fee = null;
            memo = null;
            created_at_time = null;
            to = {owner = caller; subaccount = null};
            from_subaccount = null;
        };
        switch(await husd.icrc1_transfer(arg)){
            case(#Ok(_transactionId)){
                refunds.put(caller, 0);
                return #ok();
            };
            case(#Err(_)) return #err();
        };
    };

    public shared ({caller}) func completeListing(listingId: Nat): async Result.Result<(),()>{
        assertBackend(caller);
        let (listing, bid, buyer) = switch(listings.get(listingId)){
            case(null) return #err();
            case(?listing){
                switch(listing.bid){
                    case(?bid) (listing, bid, bid.bidder);
                    case(null) return #err();
                }
            }
        };
        let newRefundAmountInFailure = switch(refunds.get(buyer.owner)){case(?amount) amount + bid.amount; case(null) bid.amount};
        let husd: Types.TokenActor = actor("vq2za-kqaaa-aaaas-amlvq-cai");
        let nftActor: Types.NFTActor = actor(Principal.toText(listing.collection));
        let tokenTransferArg: Types.TokenTransferArg = {
            amount = bid.amount; //error zero amount
            fee = null;
            memo = null;
            created_at_time = null;
            to = listing.seller;
            from_subaccount = null;
        };
        let arg : Types.NFTTransferArg = {
            token_id = listing.nftId;
            from_subaccount = null;
            memo = null;
            created_at_time = null;
            to = buyer;
        };
        let nftTransferResult = await nftActor.icrc7_transfer([arg]);
        switch(nftTransferResult[0]){
            case(?#Ok(_)) listings.remove(listingId);
            case(_) return #err();
        };
        switch(await husd.icrc1_transfer(tokenTransferArg)){
            case(#Ok(_)) return #ok();
            case(#Err(_)){
                refunds.put(buyer.owner, newRefundAmountInFailure);
                return #err();
            }
        };
    };

    public shared ({caller}) func cancelListing(listingId: Nat): async Result.Result<(),()>{
        assertBackend(caller);
        let listing = switch(listings.get(listingId)){case(null) return #err(); case(?listing) listing};
        addRefundAmount(listing.bid);
        let nftActor: Types.NFTActor = actor(Principal.toText(listing.collection));
        let arg : Types.NFTTransferArg = {
            token_id = listing.nftId;
            from_subaccount = null;
            memo = null;
            created_at_time = null;
            to = listing.seller;
        };
        let nftTransferResults = await nftActor.icrc7_transfer([arg]); 
        switch(nftTransferResults[0]){
            case(?#Ok(_)){
                listings.remove(listingId);
                return #ok();
            };
            case(_) return #err();
        };
    };

    public shared ({caller}) func refundBalance(): async Nat {
        switch(refunds.get(caller)){
            case(?amount) amount;
            case(null) 0
        }
    };



    //storage:
    //auctionId, seller, canisterId, nftId, [bidder, husd amount]
    //refunds - bidder, amount

    //actor types:
    //HUSD, transfer, transferFrom, hasApproval
    //NFT, transfer, transferFrom

    //main functionality:
    //create listing - transfer nft from seller
    //place bid - transfer husd from bidder, associate with correct listing, if an existing bid exists of lower value add this amount to refund map otherwise error
    //withdraw refund - find caller balance in refunds, transfer that to caller from backend
    //cancel listing - send nft back to seller, add bid to refund list if present
    //complete sale - send nft to bidder, send husd amount to seller
    

    //helpers
    //mark bid for refund - move bid to refunds map
    //assert backend
    
    public query func hello() : async Text {
        "MarketplaceVault online"
    };
}