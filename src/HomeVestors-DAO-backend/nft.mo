import Types "types";
import PropHelper "propHelper";
import Principal "mo:base/Principal";
import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";
import Hash "mo:base/Hash";
import Blob "mo:base/Blob";
import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";
import Time "mo:base/Time";
import HashMap "mo:base/HashMap";

module NFTCollections {
    type CreateFinancialsArg = Types.CreateFinancialsArg;
    type PropertyDetails = Types.PropertyDetails;
    type Account = Types.Account;
    type TokenRecord = Types.TokenRecord;
    type Value = Types.Value;
    type PhysicalDetails = Types.PhysicalDetails;
    type AdditionalDetails = Types.AdditionalDetails;
    type Property = Types.Property;
    type What = Types.What;
    type Properties = Types.Properties;
    type MintArg = Types.MintArg;
    type MintResult = Types.MintResult;
    type TransferFromArg = Types.TransferFromArg;
    type TransferArg = Types.TransferArg;
    type TransferResult = Types.TransferResult;
    type TransferFromResult = Types.TransferFromResult;

    public type NFTActor = actor {
        // INITIATION
        initiateMetadata: shared (Nat) -> async ();
        mintNFT: shared ([MintArg]) -> async [?MintResult];
        initiateProperty: shared query () -> async (CreateFinancialsArg, PropertyDetails);

        // COLLECTION METADATA
        updateCollectionMetadata: shared ([(Text, Value)]) -> async ();
        icrc7_collection_metadata: shared query () -> async [(Text, Value)];
        icrc7_symbol: shared query () -> async Text;
        icrc7_name: shared query () -> async Text;
        icrc7_description: shared query () -> async ?Text;
        icrc7_logo: shared query () -> async ?Text;

        // SUPPLY
        icrc7_total_supply: query () -> async Nat;

        // TOKEN DATA
        get_all_tokens: shared query () -> async [(Nat, TokenRecord)];
        icrc7_token_metadata: shared query ([Nat]) -> async [?[ (Text, Value) ]];

        // ACCOUNT DATA
        icrc7_balance_of: query ([Account]) -> async [Nat];
        icrc7_owner_of: query ([Nat]) -> async [ ?Account ];
        icrc7_tokens_of: query (Account, ?Nat, ?Nat) -> async [Nat];

        icrc37_transfer_from: shared ([TransferFromArg]) -> async [ ?TransferFromResult ];
        icrc7_transfer: shared ([TransferArg]) -> async [ ?TransferResult ];
        verify_icrc7_transfer: shared ([TransferArg]) -> async [?TransferResult]; 
        verifyTransferFrom: shared ([TransferFromArg]) -> async [ ?TransferFromResult ];

        clearState: shared () -> async ();
    };

    public func clearNFTState(canisterId: Principal): async (){
        let nftActor : NFTActor = actor(Principal.toText(canisterId));
        return await nftActor.clearState();
    };

    public func createTransferFromArg(from:Account, to:Account, token_id: Nat): TransferFromArg {
        {
            spender_subaccount = null;
            from;
            to;
            token_id;
            memo = null;
            created_at_time = ?Nat64.fromIntWrap(Time.now());
        };
    };

    public func tokensOf(canisterId: Principal, acc: Account, prev: ?Nat, take: ?Nat): async [Nat]{
        let nftActor : NFTActor = actor(Principal.toText(canisterId));
        return await nftActor.icrc7_tokens_of(acc, prev, take);
    };

    type ReadOutcome<T> = Types.ReadOutcome<T>;
    public func tokensOfToValue(canisterId: Principal, acc: Account, prev: ?Nat, take: ?Nat): async ReadOutcome<[Nat]>{
        let nftActor : NFTActor = actor(Principal.toText(canisterId));
        let arr = await nftActor.icrc7_tokens_of(acc, prev, take);
        if(arr.size() == 0) #Err(#EmptyArray) else #Ok(arr);
    };

    public func transferFrom(canisterId: Principal, from: Account, to: Account, token_id: Nat): async ?TransferFromResult {
        let arg = createTransferFromArg(from, to, token_id);
        let nftActor : NFTActor = actor(Principal.toText(canisterId));
        let results = await nftActor.icrc37_transfer_from([arg]);
        results[0];
    };

    public func transferFromBulk(canisterId: Principal, transferFromArgs: [TransferFromArg]): async [?TransferFromResult] {
        let nftActor : NFTActor = actor(Principal.toText(canisterId));
        await nftActor.icrc37_transfer_from(transferFromArgs);
    };

    public func transferBulk(canisterId: Principal, transferArg: [TransferArg]): async [?TransferFromResult] {
        let nftActor : NFTActor = actor(Principal.toText(canisterId));
        await nftActor.icrc7_transfer(transferArg);
    };

    public func verifyTransferFrom(canisterId: Principal, from: Account, to: Account, token_id: Nat): async ?TransferFromResult {
        let arg = createTransferFromArg(from, to, token_id);
        let nftActor : NFTActor = actor(Principal.toText(canisterId));
        let results = await nftActor.verifyTransferFrom([arg]);
        results[0];
    };

    public func createTransferArg(token_id:Nat, from_subaccount: ?Blob, to: Account): TransferArg {
        {
            token_id;
            from_subaccount;
            memo = null;
            created_at_time = null;
            to;
        };
    };

    public func transfer(canisterId: Principal, from_subaccount: ?Blob, to: Account, token_id: Nat): async ?TransferResult {
        let arg : TransferArg = createTransferArg(token_id, from_subaccount, to);
        let nftActor : NFTActor = actor(Principal.toText(canisterId));
        let results = await nftActor.icrc7_transfer([arg]);
        results[0];
    };

    public func verifyTransfer(canisterId: Principal, from_subaccount: ?Blob, to: Account, token_id: Nat): async ?TransferResult {
        let arg : TransferArg = createTransferArg(token_id, from_subaccount, to);
        let nftActor : NFTActor = actor(Principal.toText(canisterId));
        let results = await nftActor.verify_icrc7_transfer([arg]);
        results[0];
    };

     public func accountEqual(a : Account, b : Account) : Bool {
         Principal.equal(a.owner, b.owner) and
         blobEqual(a.subaccount, b.subaccount)
     };

       // Helper function to compare optional Blobs
    public func blobEqual(a : ?Blob, b : ?Blob) : Bool {
        switch (a, b) {
          case (null, null) true;
          case (?a, ?b) Blob.equal(a, b);
          case _ false;
        }
    };

    public func accountHash(account: Account): Hash.Hash {
        let ownerBlob = Principal.hash(account.owner);
        let subaccountBlob = switch (account.subaccount) {
            case null { Blob.hash(Blob.fromArray([])) };
            case (?sub) { Blob.hash(sub)};
        };
        return ownerBlob ^ subaccountBlob;
    };


    public func icrc7_owner_of(tokenIds: [Nat], canisterId: Principal): async [?Account]{
        let NFT : NFTActor = actor(Principal.toText(canisterId));
        await NFT.icrc7_owner_of(tokenIds);
    };

    public func getAllAccounts(canisterId: Principal): async ([(Account, Nat)], Nat){
        let NFT: NFTActor = actor(Principal.toText(canisterId));
        let tokenIds = Buffer.Buffer<Nat>(0);
        let totalSupply = await NFT.icrc7_total_supply();
        for(tokenId in Iter.range(0, totalSupply)){
            tokenIds.add(tokenId);
        };
        let allAccounts = await NFT.icrc7_owner_of(Buffer.toArray(tokenIds));
        let map = HashMap.HashMap<Account, Nat>(0, PropHelper.accountEqual, PropHelper.accountHash);
        let addAccountToMap = func(acc: Account):(){
            switch(map.get(acc)){
                case(null) map.put(acc, 1);
                case(?count) map.put(acc, count + 1);
            };
        };
        for(account in allAccounts.vals()){
            switch(account){
                case(null){};
                case(?account) addAccountToMap(account);
            };
        };
        return (Iter.toArray(map.entries()), totalSupply);
    };

    public func getCollectionMetadata(nftCollection: Principal): async [(Text, Value)] {
        let NFT : NFTActor = actor(Principal.toText(nftCollection));
        await NFT.icrc7_collection_metadata();
    };

    public func getNftSymbol(nftCollection: Principal): async Text {
        let NFT : NFTActor = actor(Principal.toText(nftCollection));
        await NFT.icrc7_symbol();
    };

    public func getNftName(nftCollection: Principal): async Text {
        let NFT : NFTActor = actor(Principal.toText(nftCollection));
        await NFT.icrc7_name();
    };

    public func getNftDescription(nftCollection: Principal): async ?Text {
        let NFT : NFTActor = actor(Principal.toText(nftCollection));
        await NFT.icrc7_description();
    };

    public func getNftLogo(nftCollection: Principal): async ?Text {
       let NFT : NFTActor = actor(Principal.toText(nftCollection));
        await NFT.icrc7_logo();
    };

    public func getTokenMetadata(nftCollection: Principal, tokenIds: [Nat]): async [?[ (Text, Value) ]] {
        let NFT : NFTActor = actor(Principal.toText(nftCollection));
        await NFT.icrc7_token_metadata(tokenIds);
    };

    public func initiateNFT(nftCollection : Principal, quantity: Nat, propertyId: Nat): async ([?MintResult], (CreateFinancialsArg, PropertyDetails)){
        let NFT : NFTActor = actor(Principal.toText(nftCollection));
        await NFT.initiateMetadata(propertyId);
        let mintArgs = Buffer.Buffer<MintArg>(quantity);
        for(i in Iter.range(0, quantity - 1)){
            let mintArg : MintArg = {
                meta = [];
                from_subaccount = null;
                to = {owner = Principal.fromText("vq2za-kqaaa-aaaas-amlvq-cai"); subaccount = null};
                memo = null;
                created_at_time = null;
            };
            mintArgs.add(mintArg);
        };
        let mintResult = await NFT.mintNFT(Iter.toArray(mintArgs.vals()));
        let propStructs = await NFT.initiateProperty();
        return (mintResult, propStructs)
    };

    public func getAllAccountBalances(nftCollection: Principal): async [Account] {
        let NFT : NFTActor = actor(Principal.toText(nftCollection));
        let totalSupply = await NFT.icrc7_total_supply();
        let tokenIds = Buffer.Buffer<Nat>(totalSupply);
        for(i in Iter.range(0, totalSupply)){
            tokenIds.add(i);
        };
        let possibleAccounts = await NFT.icrc7_owner_of(Iter.toArray(tokenIds.vals()));
        let accounts = Buffer.Buffer<Account>(totalSupply);
        for(account in possibleAccounts.vals()){
            switch(account){
                case(null){};
                case(?account) accounts.add(account);
            };
        };
        return Iter.toArray(accounts.vals());
    };

    public func getAllTokens(nftCollection: Principal): async [(Nat, TokenRecord)] {
        let NFT : NFTActor = actor(Principal.toText(nftCollection));
        await NFT.get_all_tokens();
    };

    public func getAllTokensOfHolder(properties: Properties, account: Account): async [(Principal, [Nat])] {
        var result : [(Principal, [Nat])] = [];
        for(property in properties.vals()){
            let NFT : NFTActor = actor(Principal.toText(property.nftMarketplace.collectionId));
            let tokenIds = await NFT.icrc7_balance_of([account]);
            if(tokenIds.size() > 0){
                result := Array.append(result, [(property.nftMarketplace.collectionId, tokenIds)]);
            };
        };
        return result;
    };

    public func getTotalSupply(nftCollection: Principal): async Nat {
        let NFT : NFTActor = actor(Principal.toText(nftCollection));
        await NFT.icrc7_total_supply();
    };

    func createPhysicalDetailsMetadata(p :PhysicalDetails): [(Text, Value)]{
        [
            ("last_renovation", #Nat(p.lastRenovation)),
            ("year_built", #Nat(p.yearBuilt)),
            ("square_footage(sqft)", #Nat(p.squareFootage)),
            ("beds", #Nat(p.beds)),
            ("baths", #Nat(p.baths))
        ];
    };

    func createAdditionalDetailsMetadata(a: AdditionalDetails): [(Text, Value)]{
        [
            ("crime_score(out_of_100)", #Nat(a.crimeScore)),
            ("school_score(out_of_100)", #Nat(a.schoolScore)),
            ("affordability(out_of_100)", #Nat(a.affordability)),
            ("flood_zone", #Text(if(a.floodZone) "true" else "false"))
        ];
    };

    func createFinancialMetadata(value: ?Nat, rent: ?Nat): [(Text, Value)]{
        let valueArray = switch(value){case(?v)[("current_value", #Nat(v))]; case(null) []};
        let rentArray = switch(rent){case(?r)[("monthly_rent", #Nat(r))]; case(null) []};
        Array.append(valueArray, rentArray);
    };

    public func handleNFTMetadataUpdate(what: What, property: Property): async () {
        let updates = switch (what) {
            case (#PhysicalDetails(_)) {
                createPhysicalDetailsMetadata(property.details.physical);
            };
            case (#AdditionalDetails(_)) {
                createAdditionalDetailsMetadata(property.details.additional);
            };
            case (#Financials(_)) {
                createFinancialMetadata(?property.financials.currentValue, ?property.financials.monthlyRent);
            };
            case (#MonthlyRent(_)) {
                createFinancialMetadata(null, ?property.financials.monthlyRent);
            };
            case (#Description(_)) {
                [("description", #Text(property.details.misc.description))]
            };
            case (#Valuations(_)) {
                switch(PropHelper.getElementByKey<Nat, Types.ValuationRecord>(property.financials.valuations, property.financials.valuationId, Nat.equal)){
                    case(null){return};
                    case(?v){
                        createFinancialMetadata(?v.value, null);
                    }
                };
            };
            case (_) [];
        };

        if (updates.size() > 0) {
            let NFT : NFTActor = actor(Principal.toText(property.nftMarketplace.collectionId));
            await NFT.updateCollectionMetadata(updates);
        };
    };
}