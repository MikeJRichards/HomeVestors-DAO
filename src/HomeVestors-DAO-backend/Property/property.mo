import Types "../Utils/types";
import CreateProperty "Tests/createProperty";
import NFT "../Marketplace/nft";
import Administrative "administrative";
import Details "details";
import Financials "financials";
import Operational "operational";
import Result "mo:base/Result";
import NFTMarketplace "../Marketplace/nftMarketplace";
import Invoices "invoices";
import Governance "proposals";

module Property {
    type Property = Types.Property;
    type Properties = Types.Properties;
    type PropertyDetails = Types.PropertyDetails;
    type CreateFinancialsArg = Types.CreateFinancialsArg;
    type UpdateResult = Types.UpdateResult;
    type MintResult = Types.MintResult;
    type UpdateError = Types.UpdateError;
    type Arg = Types.Arg<Property, Types.PropertyWhats>;

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

    public func removeProperty(id: Nat, properties: Properties): Result.Result<Property, UpdateError> {
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
            case(#None) return #Err([(null, #InvalidParent)]);
        }
    };


//    ///////////////////////////////////////////////////
 


    

    


 

}

