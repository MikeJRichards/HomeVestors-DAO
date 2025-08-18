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


    public func updateLaunchedFixedPrice(arg: FixedPriceUArg, property: Property, caller: Principal): async MarketplaceIntentResult {
        switch(await updateFixedListing(arg: FixedPriceUArg, property: Property, caller: Principal)){
            case(#Ok( #Update( #LiveFixedPrice(arg), id))) #Ok(#Update(#LaunchFixedPrice(arg), id));
            case(#Err(e)) return #Err(e);
            case(_) return #Err(#InvalidType);
        }
    };

    func createCancelledLaunch(property: Property, arg: CancelArg, fixedPrice: FixedPrice, caller: Principal): async MarketplaceIntentResult{
        switch(await createCancelledFixedPrice(property, arg, fixedPrice, caller)){
            case(#Ok(#Update(#CancelledFixedPrice(arg), id))) #Ok(#Update(#CancelledLaunch(arg), id));
            case(#Err(e)) #Err(e);
            case(_) return #Err(#InvalidType);
        }
    };

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