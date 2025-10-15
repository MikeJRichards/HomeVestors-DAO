import UnstableTypes "./../unstableTypes";
import Types "./../../types";
import TestTypes "./../testTypes";
import Utils "./../utils";

import HashMap "mo:base/HashMap";
import Time "mo:base/Time";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Iter "mo:base/Iter";
import Option "mo:base/Option";

module{
    type Actions<C,U> = Types.Actions<C,U>;
    type PropertyUnstable = UnstableTypes.PropertyUnstable;
    type WhatWithPropertyId = Types.WhatWithPropertyId;
    type UpdateResult = Types.UpdateResult;
    type  PreTestHandler<C, U, T> = TestTypes. PreTestHandler<C, U, T>;
    type FlatPreTestHandler<U,T> = TestTypes.FlatPreTestHandler<U,T>;
    type SingleActionPreTestHandler<U, T> = TestTypes.SingleActionPreTestHandler<U, T>;

    // ====================== FIXED PRICE ======================
public func createFixedPriceTestType2(property: PropertyUnstable, handlePropertyUpdate: (Types.WhatWithPropertyId, Principal) -> async Types.UpdateResultBeforeVsAfter): async [Text] {
    type C = Types.FixedPriceCArg;
    type U = Types.FixedPriceUArg;
    type T = Types.Listing;

    func createFixedPriceCArg(): C {
        {
            tokenId = 123;
            seller_subaccount = null;
            price = 100;
            expiresAt = ?(Time.now() + 604800000); // +1 week
            quoteAsset = ?#ICP;
        };
    };

    func createFixedPriceUArg(): U {
        {
            listingId = 123;
            price = ?110000;
            expiresAt = ?(Time.now() + 1209600000); // +2 weeks
            quoteAsset = ?#ICP;
        };
    };

    let cArg : C = createFixedPriceCArg();
    let uArg : U = createFixedPriceUArg();

    let fixedPriceCases : [(Text, Actions<C,U>, Bool)] = [
        // CREATE
        Utils.ok("FixedPrice: create valid", #Create([cArg])),

        // UPDATE
        Utils.ok("FixedPrice: update valid",     #Update((uArg, [0]))),
        Utils.err("FixedPrice: update non-exist",#Update((uArg, [9999]))),

        // DELETE
        Utils.ok("FixedPrice: delete valid",     #Delete([0])),
        Utils.err("FixedPrice: delete non-exist",#Delete([9999]))
    ];

    let handler : PreTestHandler<C,U,T> = {
        testing = true;
        handlePropertyUpdate;
        toHashMap   = func(p: PropertyUnstable) = p.nftMarketplace.listings;
        showMap     = func(map: HashMap.HashMap<Nat,T>) = debug_show(Iter.toArray(map.entries()));
        toId        = func(p: PropertyUnstable) = p.nftMarketplace.listId;
        toWhat      = func(action: Actions<C,U>) = #NftMarketplace(#FixedPrice(action));

        checkUpdate = func(before: T, after: T, arg: U): Text {
            var s = "";
            switch(before, after){
                case(#LiveFixedPrice(before), #LiveFixedPrice(after)){
                    s #= Utils.assertUpdate2("price",     #OptNat(?before.price),    #OptNat(?after.price),    #OptNat(arg.price));
                    s #= Utils.assertUpdate2("expiresAt", #OptInt(before.expiresAt), #OptInt(after.expiresAt), #OptInt(arg.expiresAt));
                };
                case(#LiveFixedPrice(_), _) s #="listing type changed from auction, due to update and became "#debug_show(after);
                case(_) s #= "invalid listing type"
            };
            s;
        };

        checkCreate = Utils.createDefaultCheckCreate();
        checkDelete = func(before: T, after: ?T, id: Nat, propBefore: PropertyUnstable, propAfter: PropertyUnstable, handler: PreTestHandler<C,U,T>): Text {
            switch(after){
                case(null) "\n element with id "#debug_show(id) # " was not archived";
                case(?#CancelledFixedPrice(_)) "";
                case(_) "\n after deletion it became the incorrect type";
            };
        };
        seedCreate = Utils.createDefaultSeedCreate(cArg);
        validForTest = func(labels: Text, el: T): ?Bool {
            switch(labels, el){
                case("FixedPrice: delete non-exist" or "FixedPrice: update non-exist", _) return null;
                case(_, #LiveFixedPrice(_)) ?true;
                case(_)?false;
            }
        };
    };

    await Utils.runGenericCases<C,U,T>(property, handler, fixedPriceCases)
};


// ====================== AUCTION ======================
public func createAuctionTestType2(property: PropertyUnstable, handlePropertyUpdate: (Types.WhatWithPropertyId, Principal) -> async Types.UpdateResultBeforeVsAfter): async [Text] {
    type C = Types.AuctionCArg;
    type U = Types.AuctionUArg;
    type T = Types.Listing;

    func createAuctionCArg(): C {
        {
            tokenId = 999;
            seller_subaccount = null;
            startingPrice = 75000;
            buyNowPrice = ?95000;
            reservePrice = ?80000;
            startTime = Time.now();
            endsAt = Time.now() + 7 * 24 * 60 * 60 * 1_000_000_000; // +1 week
            quoteAsset = ?#ICP;
        };
    };

    func createAuctionUArg(): U {
        {
            listingId = 999;
            startingPrice = ?80000;
            buyNowPrice = ?100000;
            reservePrice = ?85000;
            startTime = ?Time.now();
            endsAt = ?(Time.now() + 7 * 24 * 60 * 60 * 1_000_000_000);
            quoteAsset = ?#ICP;
        };
    };
    let cArg : C = createAuctionCArg();
    let uArg : U = createAuctionUArg();

    let auctionCases : [(Text, Actions<C,U>, Bool)] = [
        // CREATE
        Utils.ok("Auction: create valid", #Create([cArg])),

        // UPDATE
        Utils.ok("Auction: update valid",     #Update((uArg, [0]))),
        Utils.err("Auction: update non-exist",#Update((uArg, [9999]))),

        // DELETE
        Utils.ok("Auction: delete valid",     #Delete([0])),
        Utils.err("Auction: delete non-exist",#Delete([9999]))
    ];

    let handler : PreTestHandler<C,U,T> = {
        testing = true;
        handlePropertyUpdate;
        toHashMap   = func(p: PropertyUnstable) = p.nftMarketplace.listings;
        showMap     = func(map: HashMap.HashMap<Nat,T>) = debug_show(Iter.toArray(map.entries()));
        toId        = func(p: PropertyUnstable) = p.nftMarketplace.listId;
        toWhat      = func(action: Actions<C,U>) = #NftMarketplace(#Auction(action));

        checkUpdate = func(before: T, after: T, arg: U): Text {
            var s = "";
            switch(before, after){
                case(#LiveAuction(before), #LiveAuction(after)){
                    s #= Utils.assertUpdate2("startingPrice", #OptNat(?before.startingPrice), #OptNat(?after.startingPrice), #OptNat(arg.startingPrice));
                    s #= Utils.assertUpdate2("startTime",     #OptInt(?before.startTime),     #OptInt(?after.startTime),     #OptInt(arg.startTime));
                    s #= Utils.assertUpdate2("endsAt",        #OptInt(?before.endsAt),        #OptInt(?after.endsAt),        #OptInt(arg.endsAt));
                    s #= Utils.assertUpdate2("buyNowPrice",   #OptNat(before.buyNowPrice),#OptNat(after.buyNowPrice),#OptNat(arg.buyNowPrice));
                    s #= Utils.assertUpdate2("reservePrice",  #OptNat(before.reservePrice),#OptNat(after.reservePrice),#OptNat(arg.reservePrice));
                };
                case(#LiveAuction(_), _) s #="listing type changed from auction, due to update and became "#debug_show(after);
                case(_) s #= "invalid listing type"
            };
            s;
        };

        checkCreate = Utils.createDefaultCheckCreate();
        checkDelete = func(before: T, after: ?T, id: Nat, propBefore: PropertyUnstable, propAfter: PropertyUnstable, handler: PreTestHandler<C,U,T>): Text {
            switch(after){
                case(null) "\n element with id "#debug_show(id) # " was not archived";
                case(?#CancelledAuction(_)) "";
                case(_) "\n after deletion it became the incorrect type";
            };
        };
        seedCreate = Utils.createDefaultSeedCreate(cArg);
        validForTest = func(labels: Text, el: T): ?Bool {
            switch(labels, el){
                case("Auction: update non-exist" or "Auction: delete non-exist", _) return null;
                case(_, #LiveAuction(_)) ?true;
                case(_)?false;
            }
        };
    };

    await Utils.runGenericCases<C,U,T>(property, handler, auctionCases)
};

public func createBidHandlersTest(property: PropertyUnstable, handleUpdate: (Types.WhatWithPropertyId, Principal) -> async Types.UpdateResultBeforeVsAfter): async [Text] {
    type C = Types.BidArg;
    type T = Types.Listing;
    func createBidArg(): C {
        {
            listingId = 999;
            bidAmount = 100;
            buyer_subaccount = ?Text.encodeUtf8("buyer");
        };
    };

    func createFixedPriceCArg(): Types.FixedPriceCArg {
        {
            tokenId = 123;
            seller_subaccount = ?Text.encodeUtf8("seller");
            price = 100;
            expiresAt = ?(Time.now() + 604800000); // +1 week
            quoteAsset = ?#ICP;
        };
    };

        func createAuctionCArg(): Types.AuctionCArg {
        {
            tokenId = 999;
            seller_subaccount = ?Text.encodeUtf8("seller");
            startingPrice = 100;
            buyNowPrice = null;
            reservePrice = null;
            startTime = Time.now();
            endsAt = Time.now() + 7 * 24 * 60 * 60 * 1_000_000_000; // +1 week
            quoteAsset = ?#ICP;
        };
    };

    let fixed = createFixedPriceCArg();
    let auction = createAuctionCArg();
    let baseArg : C = createBidArg();

    let cases : [(Text, C, Bool)] = [
        //Minimal 
        Utils.ok1("Bid Fixed: Valid", baseArg),
        Utils.ok1("Bid Auction: Valid", baseArg),
        Utils.ok1("Bid Auction: Bid higher on auction with bid", {baseArg with bidAmount = 110}),
        Utils.err1("Bid Auction: Bid lower on auction with bid", {baseArg with bidAmount = 90}),
        Utils.err1("Bid - invalid listing type", baseArg),
        Utils.err1("Bid = non existent listing", baseArg),
       
       // Utils.err1("Bid: Fixed: buyer == seller", { baseArg with bidAmount = 1000 }), 
       // Utils.err1("Bid: Fixed: bid too low", { baseArg with bidAmount = 500 }), 
       // Utils.err1("Bid: Fixed: listing expired", { baseArg with bidAmount = 1000 }),
//
       // // AUCTION
       // Utils.ok1("Bid: Auction: first valid bid above start", { baseArg with bidAmount = 200 }),
       // Utils.err1("Bid: Auction: below starting price", { baseArg with bidAmount = 50 }),
       // Utils.err1("Bid: Auction: buyer == seller", { baseArg with bidAmount = 200 }),
       // Utils.ok1("Bid: Auction: meets buy-now price", { baseArg with bidAmount = 5000 }),
       // Utils.err1("Bid: Auction: expired", { baseArg with bidAmount = 200 }),
//
       // // PREVIOUS BIDS + REFUNDS
       // Utils.ok1("Bid: Auction: outbids previous bid", { baseArg with bidAmount = 300 }),
       // Utils.err1("Bid: Auction: bid below increment", { baseArg with bidAmount = 201 }),
//
       // // INVALIDS
       // Utils.err1("Bid: Invalid: no listing found", { baseArg with listingId = 999 }),
       // Utils.err1("Bid: Invalid: wrong listing type", { baseArg with listingId = 123 })
    ];

    let handler : SingleActionPreTestHandler<C,T> = {
        testing = true;
        toHashMap = func(p: PropertyUnstable) = p.nftMarketplace.listings;
        showMap = func(map: HashMap.HashMap<Nat,T>) = debug_show(Iter.toArray(map.entries()));
        toWhat = func(arg: C) = #NftMarketplace(#Bid(arg));
        checkUpdate = func(before: T, after: T, arg: C): Text {
            var s = "";
            switch(before, after){
                case(#LiveFixedPrice(_), #SoldFixedPrice(_)){};
                case(#LiveAuction(auctionBefore), #LiveAuction(auctionAfter)){
                    if (Option.isNull(auctionAfter.highestBid)) s #= "\n Highest bidder not set";
                    if (auctionAfter.previousBids.size() <= auctionBefore.previousBids.size()) s #= "\n bid array did not increase in size";
                };
                case(_) s #= "\n invalid type, before: " # debug_show(before) # " after: " # debug_show(after);
            };
            s;
        };
        handlePropertyUpdate = handleUpdate;
        seedCreate = func(labels: Text, p: PropertyUnstable): [Types.What] {
            switch(labels){
                case("Bid Fixed: Valid") return [#NftMarketplace(#FixedPrice(#Create([fixed])))];
                case("Bid Auction: Valid") return [#NftMarketplace(#Auction(#Create([auction])))];
                case("Bid Auction: Bid higher on auction with bid" or "Bid Auction: Bid lower on auction with bid") [#NftMarketplace(#Auction(#Create([auction]))), #NftMarketplace(#Bid({baseArg with listingId = p.nftMarketplace.listId + 1}))];
                case(_)[];
            };
        };
        toCaller = func(labels: Text, _: Nat, _: PropertyUnstable): Principal {
            Utils.getCallers().buyer;
        };
        validForTest = func(labels: Text, el: T): ?Bool {
            switch(labels, el){
                case("Bid Fixed: Valid", #LiveFixedPrice(_)) ?true;
                case("Bid Auction: Valid", #LiveAuction(_)) ?true;
                case("Bid Auction: Bid higher on auction with bid" or "Bid Auction: Bid lower on auction with bid", #LiveAuction(auction)) if(auction.highestBid != null) ?true else ?false;
                case("Bid - invalid listing type", _) ?true;
                case("Bid = non existent listing", _) null;
                case(_) ?false;
            }
        };
        setId = func(id: Nat, arg: C) = {arg with listingId = id};
  
    };

    await Utils.runSingleActionGenericCases<C,T>(property, handler, cases);
};

//public func createBidHandlersTest(
//    property: PropertyUnstable,
//    handleUpdate: (Types.WhatWithPropertyId, Principal) -> async Types.UpdateResult
//): async [Text] {
//    type U = Types.BidArg;
//    type T = HashMap.HashMap<Nat, Types.Listing>;
//    type D = Types.Listing;
//
//    func createBidArg(): U {
//        {
//            listingId = 0; // Will be updated by getValidDependentId
//            bidAmount = 85000;
//            buyer_subaccount = null;
//        };
//    };
//
//    func createFixedPriceListing(id: Nat): Types.WhatWithPropertyId {
//        #NftMarketplace(#FixedPrice({
//            tokenId = id;
//            seller_subaccount = null;
//            price = 1000;
//            expiresAt = ?(Time.now() + 7 * 24 * 60 * 60 * 1_000_000_000); // +1 week
//            quoteAsset = #ICP;
//            seller = { owner = Principal.fromText("aaaaa-aa"); subaccount = null };
//        }));
//    };
//
//    func createAuctionListing(id: Nat): Types.WhatWithPropertyId {
//        #NftMarketplace(#Auction({
//            tokenId = id;
//            seller_subaccount = null;
//            startingPrice = 100;
//            buyNowPrice = ?5000;
//            reservePrice = ?150;
//            startTime = Time.now();
//            endsAt = Time.now() + 7 * 24 * 60 * 60 * 1_000_000_000; // +1 week
//            quoteAsset = #ICP;
//            seller = { owner = Principal.fromText("aaaaa-aa"); subaccount = null };
//            highestBid = null;
//            previousBids = [];
//            refunds = [];
//        }));
//    };
//
//    let baseArg: U = createBidArg();
//
//    let cases: [(Text, U, Bool)] = [
//        // FIXED PRICE
//        Utils.ok1("Bid: Fixed: valid bid meets price", { baseArg with bidAmount = 1000 }),
//        Utils.err1("Bid: Fixed: buyer == seller", { baseArg with bidAmount = 1000 }),
//        Utils.err1("Bid: Fixed: bid too low", { baseArg with bidAmount = 500 }),
//        Utils.err1("Bid: Fixed: listing expired", { baseArg with bidAmount = 1000 }),
//
//        // AUCTION
//        Utils.ok1("Bid: Auction: first valid bid above start", { baseArg with bidAmount = 200 }),
//        Utils.err1("Bid: Auction: below starting price", { baseArg with bidAmount = 50 }),
//        Utils.err1("Bid: Auction: buyer == seller", { baseArg with bidAmount = 200 }),
//        Utils.ok1("Bid: Auction: meets buy-now price", { baseArg with bidAmount = 5000 }),
//        Utils.err1("Bid: Auction: expired", { baseArg with bidAmount = 200 }),
//
//        // PREVIOUS BIDS + REFUNDS
//        Utils.ok1("Bid: Auction: outbids previous bid", { baseArg with bidAmount = 300 }),
//        Utils.err1("Bid: Auction: bid below increment", { baseArg with bidAmount = 201 }),
//
//        // INVALIDS
//        Utils.err1("Bid: Invalid: no listing found", { baseArg with listingId = 999 }),
//        Utils.err1("Bid: Invalid: wrong listing type", { baseArg with listingId = 123 })
//    ];
//
//    let handler: DependentPreTestHandler<U, T, D> = {
//        handlePropertyUpdate = handleUpdate;
//        toStruct = func(p: PropertyUnstable) = p.nftMarketplace.listings;
//        toWhat = func(arg: U) = #NftMarketplace(#Bid(arg));
//        checkUpdate = func(before: PropertyUnstable, after: PropertyUnstable, arg: U): Text {
//            var s = "";
//            let caller = getCaller("");
//            let beforeListing = before.nftMarketplace.listings.get(arg.listingId);
//            let afterListing = after.nftMarketplace.listings.get(arg.listingId);
//            switch (beforeListing, afterListing) {
//                case (?#LiveFixedPrice(_), ?#SoldFixedPrice(sold)) {
//                    s #= Utils.assertUpdate2("soldFor", #OptNat(null), #OptNat(?sold.bid.bidAmount), #OptNat(?arg.bidAmount));
//                    s #= Utils.assertEqual<Text>("buyer", Principal.toText(sold.bid.buyer.owner), Principal.toText(caller), Text.equal, func(x) = x);
//                };
//                case (?#LaunchFixedPrice(_), ?#SoldLaunchFixedPrice(sold)) {
//                    s #= Utils.assertUpdate2("soldFor", #OptNat(null), #OptNat(?sold.bid.bidAmount), #OptNat(?arg.bidAmount));
//                    s #= Utils.assertEqual<Text>("buyer", Principal.toText(sold.bid.buyer.owner), Principal.toText(caller), Text.equal, func(x) = x);
//                };
//                case (?#LiveAuction(_), ?#LiveAuction(afterAuc)) {
//                    switch (afterAuc.highestBid) {
//                        case (?bid) {
//                            s #= Utils.assertUpdate2("highestBid", #OptNat(null), #OptNat(?bid.bidAmount), #OptNat(?arg.bidAmount));
//                            s #= Utils.assertEqual<Text>("buyer", Principal.toText(bid.buyer.owner), Principal.toText(caller), Text.equal, func(x) = x);
//                        };
//                        case (null) { s #= "expected highestBid but none\n" };
//                    }
//                };
//                case (?#LiveAuction(_), ?#SoldAuction(sold)) {
//                    s #= Utils.assertUpdate2("soldFor", #OptNat(null), #OptNat(?sold.soldFor), #OptNat(?arg.bidAmount));
//                    s #= Utils.assertEqual<Text>("buyer", Principal.toText(sold.buyer.owner), Principal.toText(caller), Text.equal, func(x) = x);
//                };
//                case (_, afterOpt) {
//                    s #= Utils.assertUnchanged<?Types.Listing>("listing", beforeListing, afterOpt, func(a: ?Types.Listing, b: ?Types.Listing) = a == b, func(x: ?Types.Listing) = debug_show(x));
//                };
//            };
//            s;
//        };
//        validForTest = func(labels: Text, el: D, id: Nat): ?Bool {
//            switch (labels, el) {
//                case ("Bid: Fixed: valid bid meets price", #LiveFixedPrice(fixed)) ?(fixed.price == 1000);
//                case ("Bid: Fixed: buyer == seller", #LiveFixedPrice(fixed)) ?(fixed.price == 1000);
//                case ("Bid: Fixed: bid too low", #LiveFixedPrice(fixed)) ?(fixed.price == 1000);
//                case ("Bid: Fixed: listing expired", #LiveFixedPrice(fixed)) ?(fixed.expiresAt < ?Time.now());
//                case ("Bid: Auction: first valid bid above start", #LiveAuction(auc)) ?(auc.startingPrice == 100 and auc.highestBid == null);
//                case ("Bid: Auction: below starting price", #LiveAuction(auc)) ?(auc.startingPrice == 100);
//                case ("Bid: Auction: buyer == seller", #LiveAuction(auc)) ?(auc.startingPrice == 100);
//                case ("Bid: Auction: meets buy-now price", #LiveAuction(auc)) ?(auc.buyNowPrice == ?5000);
//                case ("Bid: Auction: expired", #LiveAuction(auc)) ?(auc.endsAt < Time.now());
//                case ("Bid: Auction: outbids previous bid", #LiveAuction(auc)) ?(switch (auc.highestBid) { case (?bid) bid.bidAmount == 200; case (null) false });
//                case ("Bid: Auction: bid below increment", #LiveAuction(auc)) ?(switch (auc.highestBid) { case (?bid) bid.bidAmount == 200; case (null) false });
//                case ("Bid: Invalid: no listing found", _) ?false;
//                case ("Bid: Invalid: wrong listing type", #LiveFixedPrice(_)) ?true; // Test expects a fixed-price listing to fail as wrong type
//                case (_, _) null;
//            };
//        };
//        seedCreate = func(labels: Text, id: Nat): [Types.WhatWithPropertyId] {
//            switch (labels) {
//                case ("Bid: Fixed: valid bid meets price") [createFixedPriceListing(id)];
//                case ("Bid: Fixed: buyer == seller") [createFixedPriceListing(id)];
//                case ("Bid: Fixed: bid too low") [createFixedPriceListing(id)];
//                case ("Bid: Fixed: listing expired") [
//                    #NftMarketplace(#FixedPrice({
//                        tokenId = id;
//                        seller_subaccount = null;
//                        price = 1000;
//                        expiresAt = ?(Time.now() - 1_000_000_000); // Expired
//                        quoteAsset = #ICP;
//                        seller = { owner = Principal.fromText("aaaaa-aa"); subaccount = null };
//                    }))
//                ];
//                case ("Bid: Auction: first valid bid above start") [createAuctionListing(id)];
//                case ("Bid: Auction: below starting price") [createAuctionListing(id)];
//                case ("Bid: Auction: buyer == seller") [createAuctionListing(id)];
//                case ("Bid: Auction: meets buy-now price") [createAuctionListing(id)];
//                case ("Bid: Auction: expired") [
//                    #NftMarketplace(#Auction({
//                        tokenId = id;
//                        seller_subaccount = null;
//                        startingPrice = 100;
//                        buyNowPrice = ?5000;
//                        reservePrice = ?150;
//                        startTime = Time.now() - 8 * 24 * 60 * 60 * 1_000_000_000;
//                        endsAt = Time.now() - 1_000_000_000; // Expired
//                        quoteAsset = #ICP;
//                        seller = { owner = Principal.fromText("aaaaa-aa"); subaccount = null };
//                        highestBid = null;
//                        previousBids = [];
//                        refunds = [];
//                    }))
//                ];
//                case ("Bid: Auction: outbids previous bid") [
//                    #NftMarketplace(#Auction({
//                        tokenId = id;
//                        seller_subaccount = null;
//                        startingPrice = 100;
//                        buyNowPrice = ?5000;
//                        reservePrice = ?150;
//                        startTime = Time.now();
//                        endsAt = Time.now() + 7 * 24 * 60 * 60 * 1_000_000_000;
//                        quoteAsset = #ICP;
//                        seller = { owner = Principal.fromText("aaaaa-aa"); subaccount = null };
//                        highestBid = ?{ buyer = { owner = Principal.fromText("bbbbb-bb"); subaccount = null }; bidAmount = 200; bidTime = Time.now() };
//                        previousBids = [];
//                        refunds = [];
//                    }))
//                ];
//                case ("Bid: Auction: bid below increment") [
//                    #NftMarketplace(#Auction({
//                        tokenId = id;
//                        seller_subaccount = null;
//                        startingPrice = 100;
//                        buyNowPrice = ?5000;
//                        reservePrice = ?150;
//                        startTime = Time.now();
//                        endsAt = Time.now() + 7 * 24 * 60 * 60 * 1_000_000_000;
//                        quoteAsset = #ICP;
//                        seller = { owner = Principal.fromText("aaaaa-aa"); subaccount = null };
//                        highestBid = ?{ buyer = { owner = Principal.fromText("bbbbb-bb"); subaccount = null }; bidAmount = 200; bidTime = Time.now() };
//                        previousBids = [];
//                        refunds = [];
//                    }))
//                ];
//                case ("Bid: Invalid: no listing found") [];
//                case ("Bid: Invalid: wrong listing type") [createFixedPriceListing(id)];
//                case (_) [];
//            };
//        };
//    };
//
//    await runDependentGenericCases<U, T, D>(property, handler, cases);
//};
//

}