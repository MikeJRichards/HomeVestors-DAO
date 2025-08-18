import Types "types";
import UnstableTypes "Tests/unstableTypes";
import CreateProperty "Tests/createProperty";
import NFT "nft";
import Administrative "administrative";
import Details "details";
import Financials "financials";
import Operational "operational";
import Result "mo:base/Result";
import NFTMarketplace "nftMarketplace";
import Invoices "invoices";
import Governance "proposals";
import Buffer "mo:base/Buffer";
import PropHelper "propHelper";
import Iter "mo:base/Iter";
import Array "mo:base/Array";
import Nat "mo:base/Nat";
import Int "mo:base/Int";
import Text "mo:base/Text";
import Option "mo:base/Option";
import HashMap "mo:base/HashMap";

module Property {
    type Property = Types.Property;
    type Properties = Types.Properties;
    type PropertyDetails = Types.PropertyDetails;
    type CreateFinancialsArg = Types.CreateFinancialsArg;
    type UpdateResult = Types.UpdateResult;
    type What = Types.What;
    type MintResult = Types.MintResult;
    type Error = Types.Error;
    type ValuationRecordCArg = Types.ValuationRecordCArg;
    type InsurancePolicy = Types.InsurancePolicy;
    type Document = Types.Document;
    type Note = Types.Note;
    type ValuationRecord = Types.ValuationRecord;
    type Tenant = Types.Tenant;
    type MaintenanceRecord = Types.MaintenanceRecord;
    type InspectionRecord = Types.InspectionRecord;
    type Miscellaneous = Types.Miscellaneous;
    type SimpleHandler<T> = UnstableTypes.SimpleHandler<T>;
    type Arg = Types.Arg;
    type Actions<C,U> = Types.Actions<C,U>;
    type Handler<C,U> = UnstableTypes.Handler<C,U>;
    type InsurancePolicyCArg = Types.InsurancePolicyCArg;
    type InsurancePolicyUArg = Types.InsurancePolicyUArg;
    type InsurancePolicyUnstable = UnstableTypes.InsurancePolicyUnstable;
    type DocumentCArg = Types.DocumentCArg;
    type DocumentUArg = Types.DocumentUArg;
    type DocumentUnstable = UnstableTypes.DocumentUnstable;
    type NoteCArg = Types.NoteCArg;
    type NoteUArg = Types.NoteUArg;
    type NoteUnstable = UnstableTypes.NoteUnstable;
    type MaintenanceRecordCArg = Types.MaintenanceRecordCArg;
    type MaintenanceRecordUArg = Types.MaintenanceRecordUArg;
    type MaintenanceRecordUnstable = UnstableTypes.MaintenanceRecordUnstable;
    type InspectionRecordCArg = Types.InspectionRecordCArg;
    type InspectionRecordUArg = Types.InspectionRecordUArg;
    type InspectionRecordUnstable = UnstableTypes.InspectionRecordUnstable;
    type TenantCArg = Types.TenantCArg;
    type TenantUArg = Types.TenantUArg;
    type TenantUnstable = UnstableTypes.TenantUnstable;
    type ValuationRecordUArg = Types.ValuationRecordUArg;
    type ValuationRecordUnstable = UnstableTypes.ValuationRecordUnstable;
    type FinancialsArg = Types.FinancialsArg;
    type PhysicalDetails = Types.PhysicalDetails;
    type AdditionalDetails = Types.AdditionalDetails;
    type Ref = Types.Ref;
    type ReadResult = Types.ReadResult;
    type LocationDetails = Types.LocationDetails;
    type Financials = Types.Financials;
    type NestedRead = Types.NestedRead;
    type ReadOutcome<T> = Types.ReadOutcome<T>;
    type PropertyResult<T> = Types.PropertyResult<T>;
    type Result = Types.Result;
    type Read2 = Types.Read2;
    type ReadHandler<T> = Types.ReadHandler<T>;
    type SimpleReadHandler<T> = Types.SimpleReadHandler<T>;
    type UpdateError = Types.UpdateError;
    type ListingConditionals = Types.ListingConditionals;
    type Listing = Types.Listing;
    type Account = Types.Account;
    type Payment = Types.Payment;
    type Refund = Types.Refund;
    type ElementResult<T> = Types.ElementResult<T>;
    type FilterProperties = Types.FilterProperties;
    type ReadArg = Types.ReadArg;
    type Proposal = Types.Proposal;
    type Invoice = Types.Invoice;
    
    public func addProperty(id: Nat, nftCollection: Principal, quantity: Nat): async (Property, [?MintResult]) {
        let (mintResult, (financials, details)) = await NFT.initiateNFT(nftCollection, quantity, id);
        let property = createProperty(id, details, financials, nftCollection);
        return (property, mintResult);
    };

    func createProperty(id: Nat, details : PropertyDetails, financials: CreateFinancialsArg, nftCollection: Principal): Property{
        {
            id;
            details;
            financials = Financials.createFinancials(financials, id);
            administrative = Administrative.createAdministrativeInfo();
            operational = Operational.createOperationalInfo();
            nftMarketplace = NFTMarketplace.createNFTMarketplace(nftCollection);
            governance = CreateProperty.createGovernance();
            updates = [];
        }
    };

    public func removeProperty(id: Nat, properties: Properties): Result.Result<Property, Error> {
        switch(properties.remove(id)){
            case(null){
                return #err(#InvalidPropertyId);
            };
            case(?p){
                return #ok(p);
            }
        }
    };

    public func updateProperty(arg: Arg): async UpdateResult {
        switch(arg.what){
            case(#Insurance(action)) await Administrative.createInsuranceHandler(arg, action);
            case(#Document(action)) await Administrative.createDocumentHandler(arg, action);
            case(#Note(action)) await Administrative.createNoteHandler(arg, action);
            case(#Maintenance(action)) await Operational.createMaintenanceHandler(arg, action);
            case(#Inspection(action)) await Operational.createInspectionHandler(arg, action);
            case(#Tenant(action)) await Operational.createTenantHandler(arg, action);
            case(#Valuations(action)) await Financials.createValuationHandler(arg, action);
            case(#Images(action)) await Details.createImageHandler(arg, action);
            case(#Financials(val)) await Financials.currentValueHandler(arg, val);
            case(#MonthlyRent(val)) await Financials.monthlyRentHandler(arg, val);
            case(#PhysicalDetails(val)) await Details.physicalDetailsHandler(arg, val);
            case(#AdditionalDetails(val)) await Details.additionalDetailsHandler(arg, val);
            case(#Description(val)) await Details.descriptionHandler(arg, val);
            case(#NftMarketplace(#FixedPrice(action))) await NFTMarketplace.createFixedPriceHandlers(arg, action);
            case(#NftMarketplace(#Auction(action))) await NFTMarketplace.createAuctionHandlers(arg, action);
            case(#NftMarketplace(#Launch(action))) await NFTMarketplace.createLaunchHandlers(arg, action);
            case(#NftMarketplace(#Bid(action))) await NFTMarketplace.createBidHandlers(arg, action);
            case(#Governance(#Vote(action))) await Governance.voteHandler(arg, action);
            case(#Governance(#Proposal(action))) await Governance.createProposalHandlers(arg, action);
            case(#Invoice(action)) await Invoices.createInvoiceHandler(arg, action);
        }
    };


//    ///////////////////////////////////////////////////
 


    func rentFilter(rent: ?Float, property: Property): Bool {
        switch(rent){
            case(null) true;
            case(?rent) rent < property.financials.yield;
        }
    };



    func bedsFilter(beds: ?[Nat], property: Property): Bool {
        switch(beds){
            case(null) true;
            case(?beds){
                for(bed in beds.vals()){
                    if(bed == property.details.physical.beds) return true;
                };
                false;
            }
        }
    };



    func houseValueWithinRanges(min: ?Nat, max: ?Nat, property: Property): Bool {
        let map = HashMap.fromIter<Nat, ValuationRecord>(property.financials.valuations.vals(), property.financials.valuations.size(), Nat.equal, PropHelper.natToHash);
        let value = switch(map.get(property.financials.valuationId)){
            case(null) property.financials.investment.purchasePrice;
            case(?valuation) valuation.value;
        };
        switch(min, max){
            case(null, ?max) max > value;
            case(?min, null) min < value;
            case(?min, ?max) max > value and min < value;
            case(null, null) true;
        }
    };

    func matchNFTPriceMin(min: ?Nat, property: Property): Bool {
        switch(min){
            case(null) true;
            case(?min){
                for((id, listing) in property.nftMarketplace.listings.vals()){
                    switch(listing){
                        case(#LaunchFixedPrice(arg)) return min < arg.price;
                        case(#LiveFixedPrice(arg)) return min < arg.price;
                        case(#LiveAuction(arg)){
                            let nextMinBid = switch(arg.highestBid){case(null) arg.startingPrice; case(?bid) bid.bidAmount + arg.bidIncrement};
                            return min < nextMinBid and min < Option.get(arg.reservePrice, min);
                        }; 
                        case(_) {};
                    }
                };
                false;
            }
        }
    };

    func matchNFTPriceMax(max: ?Nat, property: Property): Bool {
        switch(max){
            case(null) true;
            case(?max){
                for((id, listing) in property.nftMarketplace.listings.vals()){
                    switch(listing){
                        case(#LaunchFixedPrice(arg)) return max > arg.price;
                        case(#LiveFixedPrice(arg)) return max > arg.price;
                        case(#LiveAuction(arg)){
                            let nextMinBid = switch(arg.highestBid){case(null) arg.startingPrice; case(?bid) bid.bidAmount + arg.bidIncrement};
                            return max > nextMinBid and max > Option.get(arg.reservePrice, max);
                        }; 
                        case(_) {};
                    }
                };
                false;
            }
        }
    };



    func matchLocation(property: Property, location: ?Text): Bool {
        switch(location){
            case(null) true;
            case(?location) Text.equal(property.details.location.location, location);
        };
    };

    func filterProperty(property: Property, arg: ?FilterProperties): Bool {
        switch(arg){
            case(null) true;
            case(?arg){
                matchLocation(property, arg.location) and matchNFTPriceMax(arg.nftPriceMax, property) and matchNFTPriceMin(arg.nftPriceMin, property) and  houseValueWithinRanges(arg.houseValueMin, arg.houseValueMax, property) and bedsFilter(arg.beds, property) and rentFilter(arg.monthlyRentMin, property);
            }
        }
    };

    func returnElById<T>(property: Property, ids: [Result.Result<Nat, Nat>], elementIds: ?[Int], handler: ReadHandler<T>): [ElementResult<T>]{
        let buff = Buffer.Buffer<ElementResult<T>>(ids.size());
        let arr = handler.toEl(property);
        for(id in ids.vals()){
            switch(id){
                case(#err(id)) buff.add({id; value = #Err(#ArrayIndexOutOfBounds)});
                case(#ok(id)){
                    let value = switch(handler.filter, PropHelper.getElementByKey(arr, id)){
                        case(_, null) #Err(#InvalidElementId); 
                        case(null, ?val) handler.cond(val);
                        case(?filter, ?val){
                            let requestedElements = filter((id, val), elementIds);
                            handler.cond(requestedElements.1);
                        } 
                    };
                    buff.add({id; value;});
                }
            };
            
        };
        Buffer.toArray(buff);
    };

    func returnPropertyElement<T>(arg: ReadArg, ids: ?[Int], handler: SimpleReadHandler<T>): [ElementResult<T>]{
        let buf = Buffer.Buffer<ElementResult<T>>(0);
        let configuredIds = convertIds(Iter.toArray(arg.properties.entries()), ids);
        for(res in configuredIds.vals()){
            switch(res){
                case(#err(id)){buf.add({id; value = #Err(#ArrayIndexOutOfBounds)})};
                case(#ok(id)){
                    let value = switch(arg.properties.get(id)){
                        case(null) #Err(#InvalidPropertyId);
                        case(?property){
                            if(filterProperty(property, arg.filterProperties)) handler.cond(handler.toEl(property)) else #Err(#Filtered);
                        };
                    };
                    buf.add({id; value;});
                };
            }
        };
        Buffer.toArray(buf);
    };
    
    
    func getImages(p: Property): [(Nat, Text)] = p.details.misc.images;
    func getInsurance(p: Property): [(Nat, InsurancePolicy)] = p.administrative.insurance;
    func getNotes(p: Property): [(Nat, Note)] = p.administrative.notes;
    func getDocuments(p: Property): [(Nat, Document)] = p.administrative.documents;
    func getValuations(p: Property): [(Nat, ValuationRecord)] = p.financials.valuations;
    func getTenants(p: Property): [(Nat, Tenant)] = p.operational.tenants;
    func getMaintenance(p: Property): [(Nat, MaintenanceRecord)] = p.operational.maintenance;
    func getInspections(p: Property): [(Nat, InspectionRecord)] = p.operational.inspections;  
    func getCollection(p: Property): Principal = p.nftMarketplace.collectionId;

    func getTenantPayments(p: Property): [(Nat, [Payment])] {
        let buff = Buffer.Buffer<(Nat, [Payment])>(p.operational.tenants.size());
        for((id, tenant) in p.operational.tenants.vals()){
            buff.add(id, tenant.paymentHistory)
        };
        Buffer.toArray(buff);
    };

    func paymentFilter(el: (Nat, [Payment]), ids: ?[Int]) : (Nat, [Payment]) {
       filter<Payment>(el, ids);
    };



    func filter<T <: { id : Nat }>(el : (Nat, [T]), ids: ?[Int]): (Nat, [T]) {
        let (id, arr) = el;
        switch(ids){
            case(null) el;
            case(?ids){
                let buff = Buffer.Buffer<T>(0);
                for(id in ids.vals()){
                    let idx = if(id > 0) id else arr.size() + id;
                    for(element in arr.vals()) if(idx == element.id) buff.add(element);
                };
                (id, Buffer.toArray(buff));
            }
        }
    };


    func _filterNatArray<T>(el : (Nat, [(Nat, T)]), ids: ?[Int]): (Nat, [(Nat, T)]) {
        let (id, arr) = el;
        switch(ids){
            case(null) el;
            case(?ids){
                let buff = Buffer.Buffer<(Nat, T)>(ids.size());
                for(id in ids.vals()){
                    let idx = if(id > 0) id else arr.size() + id;
                    switch(PropHelper.getElementByKey(arr, Int.abs(idx))){
                        case(null){}; 
                        case(?el) buff.add((Int.abs(idx), el))
                    };
                };
                (id, Buffer.toArray(buff));
            }
        }
    };

    func simpleReadHandler<T>(toEl: Property -> T): SimpleReadHandler<T>{
        {
            toEl;
            cond = func(el) = #Ok(el);
        }
    };

    func updatesReadHandler(arg: {#All; #Err; #Ok}): SimpleReadHandler<[Result]>{
        {
            toEl = func(p: Property) : [Result] = p.updates;
            cond = func(arr) = resultCond<Types.OkUpdateResult,UpdateError>(arr, arg);
        }
    };



    func resultCond<Ok, Err>(arr: [{#Ok: Ok; #Err: Err}], arg: {#All; #Err; #Ok}): ReadOutcome<[{#Ok: Ok; #Err: Err}]>{
        let buff = Buffer.Buffer<{#Ok: Ok; #Err: Err}>(0);
        for(element in arr.vals()){
            let flag = switch(element){
                case(#Err(_)) #Err;
                case(#Ok(_)) #Ok;
            };
            if(arg == #All or flag == arg) buff.add(element);
        };
        if(buff.size() > 0) #Ok(Buffer.toArray(buff)) else #Err(#EmptyArray);
               
    };

    func readHandler<T>(toEl: Property -> [(Nat, T)]): ReadHandler<T>{
        {
            toEl;
            filter = null;
            cond = func(el) = #Ok(el);
        }
    };

    func nestedReadHandler<T>(toEl: Property -> [(Nat, T)], filter: ?( ((Nat, T), ?[Int]) -> (Nat, T) ) ): ReadHandler<T>{
        {
            toEl;
            filter;
            cond = func(el) = #Ok(el);
        }
    };


    func listingsReadHandler(arg: ListingConditionals): ReadHandler<Listing>{
        {
            toEl = func(p) = p.nftMarketplace.listings;
            filter = null; 
            cond = func(el: Listing): ReadOutcome<Listing> {
                if(matchAcc(el, arg.account, arg.ltype) and NFTMarketplace.tagMatching(el, arg.listingType)) #Ok(el) else #Err(#DidNotMatchConditions);
            };
        }
    };

    
    func proposalReadHandler(arg: Types.ProposalConditionals): ReadHandler<Types.Proposal>{
        {
            toEl = func(p) = p.governance.proposals;
            filter = null; 
            cond = func(el: Proposal): ReadOutcome<Proposal> {
                Governance.matchProposalConditions(el, arg);
            };
        }
    };

    func invoiceReadHandler(arg: Types.InvoiceConditionals): ReadHandler<Invoice>{
        {
            toEl = func(p) = p.financials.invoices;
            filter = null; 
            cond = func(el: Invoice): ReadOutcome<Invoice> {
                Invoices.filterInvoices(el, arg);
            };
        }
    };

    func refundsReadHandler(arg: {#All; #Err; #Ok}): ReadHandler<[Refund]>{
        {
            toEl =  func(p: Property): [(Nat, [Refund])] {
                            let buff = Buffer.Buffer<(Nat, [Refund])>(0);
                            for((id, listing) in p.nftMarketplace.listings.vals()){
                                switch(listing){
                                    case(#LiveAuction(arg)) buff.add((id, arg.refunds));
                                    case(#SoldAuction(arg)) buff.add((id, arg.refunds));
                                    case(#CancelledAuction(arg)) buff.add((id, arg.refunds));
                                    case(_){};
                                }
                            };
                            Buffer.toArray(buff);
                        };
            filter = ?(func(refunds: (Nat, [Refund]), ids: ?[Int]) : (Nat, [Refund]) {
                let (id, arr) = refunds;
                switch(ids){
                    case(null) refunds;
                    case(?ids){
                        let buff = Buffer.Buffer<Refund>(0);
                        for (id in ids.vals()) {
                            let idx = if(id > 0) id else arr.size() + id;
                            for (refund in arr.vals()) {
                                let refundId = switch(refund) {
                                    case (#Err(ref)) ref.id;
                                    case (#Ok(ref))  ref.id;
                                };
                                if (idx == refundId) buff.add(refund);
                            }
                        };
                        (id, Buffer.toArray(buff));
                    }
                }
            }); 
            cond = func(arr) = resultCond<Ref, Ref>(arr, arg);
        }
    };


  
    public func read2<T>(args: ReadArg, reads: [Read2]): [ReadResult] {
        let buff = Buffer.Buffer<ReadResult>(reads.size());
        for(read in reads.vals()){
            let result = switch(read){
                case(#CollectionIds(arg)) #CollectionIds(returnPropertyElement<Principal>(args, arg, simpleReadHandler(getCollection)));
                case(#Images(arg)) #Image(applyReadArgs<Text>(args, arg, readHandler(getImages)));
                case(#Document(arg)) #Document(applyReadArgs<Document>(args, arg, readHandler(getDocuments)));
                case(#Note(arg)) #Note(applyReadArgs<Note>(args, arg, readHandler(getNotes)));
                case(#Insurance(arg)) #Insurance(applyReadArgs<InsurancePolicy>(args, arg, readHandler(getInsurance)));
                case(#PaymentHistory(arg)) #PaymentHistory(applyReadArgs<[Payment]>(args, arg, nestedReadHandler(getTenantPayments, ?paymentFilter)));
                case(#Valuation(arg)) #Valuation(applyReadArgs<ValuationRecord>(args, arg, readHandler(getValuations)));
                case(#Tenants(arg)) #Tenants(applyReadArgs<Tenant>(args, arg, readHandler(getTenants)));
                case(#Maintenance(arg)) #Maintenance(applyReadArgs<MaintenanceRecord>(args, arg, readHandler(getMaintenance)));
                case(#Inspection(arg)) #Inspection(applyReadArgs<InspectionRecord>(args, arg, readHandler(getInspections)));
                case(#Physical(arg)) #Physical(returnPropertyElement<PhysicalDetails>(args, arg, simpleReadHandler(getPhysical)));
                case(#Additional(arg)) #Additional(returnPropertyElement<AdditionalDetails>(args, arg, simpleReadHandler(getAdditional)));
                case(#Location(arg)) #Location(returnPropertyElement<LocationDetails>(args, arg, simpleReadHandler(getLocation)));
                case(#Misc(arg)) #Misc(returnPropertyElement<Miscellaneous>(args, arg, simpleReadHandler(getMisc)));
                case(#Financials(arg)) #Financials(returnPropertyElement<Financials>(args, arg, simpleReadHandler(getFinancials)));
                case(#MonthlyRent(arg)) #MonthlyRent(returnPropertyElement<Nat>(args, arg, simpleReadHandler(getRent)));
                case(#Listings(arg)) #Listings(applyReadArgs<Listing>(args, arg.base, listingsReadHandler(arg.conditionals))); 
                case(#UpdateResults(arg)) #UpdateResults(returnPropertyElement<[Result]>(args, arg.selected, updatesReadHandler(arg.conditional))); 
                case(#Refunds(arg)) #Refunds(applyReadArgs<[Refund]>(args, arg.nested, refundsReadHandler(arg.conditionals))); 
                case(#Proposals(arg)) #Proposals(applyReadArgs<Proposal>(args, arg.base, proposalReadHandler(arg.conditionals))); 
                case(#Invoices(arg)) #Invoices(applyReadArgs<Invoice>(args, arg.base, invoiceReadHandler(arg.conditionals))); 
            };
            buff.add(result);
        };
        Buffer.toArray(buff);
    };

    let getPhysical = func(p: Property): PhysicalDetails = p.details.physical;
    let getAdditional = func(p: Property): AdditionalDetails = p.details.additional;
    let getLocation = func(p: Property): LocationDetails = p.details.location;
    let getMisc = func(p: Property): Miscellaneous = p.details.misc;
    let getFinancials = func(p: Property): Financials = p.financials;
    let getRent = func(p: Property): Nat = p.financials.monthlyRent;


    func applyReadArgs<T>(read: ReadArg, readArg: NestedRead, handler: ReadHandler<T>): [PropertyResult<T>]{
        switch(readArg){
            //All properties these ids, if null all, if negative last indexes
            case(#Ids(ids)) getSpecificElements(read, null, ids, null, handler);
            //These properties, all elements, if null all
            case(#Properties(propertyIds)) getSpecificElements(read, propertyIds, null, null, handler);
            //This property, these ids, if null all elements for this property, if negative, then last
            case(#Scoped(args)){
                let buf = Buffer.Buffer<PropertyResult<T>>(args.size());
                for(arg in args.vals()) buf.add(getSpecificElements(read, ?[Int.abs(arg.propertyId)], arg.ids, null, handler)[0]);
                Buffer.toArray(buf);
            }; 
            case(#NestedScoped(args)){
                let buf = Buffer.Buffer<PropertyResult<T>>(args.size());
                for(arg in args.vals()) buf.add(getSpecificElements(read, ?[Int.abs(arg.propertyId)], arg.ids, arg.elements, handler)[0]);
                Buffer.toArray(buf);
            }
        };
    };

    type ReadErrors = Types.ReadErrors;
    public func convertIds<T>(arr: [(Nat, T)], ids: ?[Int]): [Result.Result<Nat, Nat>]{
        let idsArr = Array.map<(Nat, T), Nat>(arr, func ((n, _)) = n);
        let sortedArr = Array.sort<Nat>(idsArr, Nat.compare);
        let buff = Buffer.Buffer<Result.Result<Nat, Nat>>(0);
        switch(ids){
            case(null) for(id in sortedArr.vals()) buff.add(#ok(id));
            case(?ids){
                for(id in ids.vals()){
                    let idx = Int.abs( if(id < 0) sortedArr.size() + id else id);
                    let res = if (idx < 0 or idx >= sortedArr.size()) #err(idx) else #ok(sortedArr[idx]);
                    buff.add(res);
                };
            };
        };
        Buffer.toArray(buff);
    };

    func getSpecificElements<T>(arg: ReadArg, propertyIds: ?[Int], ids: ?[Int], elementIds: ?[Int], handler: ReadHandler<T>): [PropertyResult<T>]{
        let buf = Buffer.Buffer<PropertyResult<T>>(arg.properties.size());
        let results = convertIds<Property>(Iter.toArray(arg.properties.entries()), propertyIds);
        for(res in results.vals()){
            switch(res){
                case(#err(propertyId)) buf.add({propertyId; result = #Err(#ArrayIndexOutOfBounds)});
                case(#ok(propertyId)){
                    switch(arg.properties.get(propertyId)){
                        case(null){
                            buf.add({
                                propertyId;
                                result = #Err(#InvalidPropertyId);
                            })
                        };
                        case(?property){
                            if(filterProperty(property, arg.filterProperties)){
                                let convertedIds = convertIds(handler.toEl(property), ids);

                                let arr : [ElementResult<T>] = if(convertedIds.size() > 0 or elementIds != null) returnElById<T>(property, convertedIds, elementIds, handler) else [];
                                buf.add({
                                    propertyId = property.id;
                                    result = if(hasOk(arr)) #Ok(arr) else if(arr.size() > 0) #Err(#DidNotMatchConditions) else #Err(#EmptyArray);
                                });
                            }
                            else {
                                buf.add({
                                    propertyId = property.id;
                                    result = #Err(#Filtered);
                                })
                            }
                        };
                    };
                };
            };
            
        };
        Buffer.toArray(buf);
    };

    func hasOk<T>(arr: [ElementResult<T>]): Bool {
        for(el in arr.vals()){
            switch(el.value){
                case(#Ok(_)) return true;
                case(_){};
            };
        };
        false;
    };

    
    func matchAcc(listing: Listing, acc: ?Account, ltype: {#Seller; #Winning; #Purchased; #PreviousBids;}): Bool {
        let accounts = switch(ltype){
            case(#Seller) NFTMarketplace.getSeller(listing);
            case(#Winning or #Purchased) NFTMarketplace.getBuyer(listing);
            case(#PreviousBids) NFTMarketplace.getAllBidders(listing)
        };
        PropHelper.matchNullableAccountArr(acc, accounts);
    };

    


 

}

