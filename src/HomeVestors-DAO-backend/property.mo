import Types "types";
import NFT "nft";
import Administrative "administrative";
import Details "details";
import Financials "financials";
import Operational "operational";
import Result "mo:base/Result";
import NFTMarketplace "nftMarketplace";

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

    
    public func addProperty(id: Nat, nftCollection: Principal, quantity: Nat): async (Property, [?MintResult]) {
        let (mintResult, (financials, details)) = await NFT.initiateNFT(nftCollection, quantity, id);
        let property = createProperty(id, details, financials, nftCollection);
        return (property, mintResult);
    };

    func createProperty(id: Nat, details : PropertyDetails, financials: CreateFinancialsArg, nftCollection: Principal): Property{
        {
            id;
            details;
            financials = Financials.createFinancials(financials);
            administrative = Administrative.createAdministrativeInfo();
            operational = Operational.createOperationalInfo();
            nftMarketplace = NFTMarketplace.createNFTMarketplace(nftCollection);
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


    public func updateProperty(what: What, caller: Principal, property: Property): async UpdateResult {
        switch(what){
            case(#Insurance(action)){
                Administrative.writeInsurance(action, property);
            };
            case(#Document(action)){
                Administrative.writeDocument(action, property);
            };
            case(#Note(action)){
                Administrative.writeNote(action, property, caller);
            };
            case(#Maintenance(action)){
                Operational.writeMaintenance(action, property);
            };
            case(#Inspection(action)){
                Operational.writeInspection(action, property, caller);
            };
            case(#Tenant(action)){
                Operational.writeTenant(action, property);
            };
            case(#Valuations(action)){
                Financials.writeValuation(action, property, caller);
            };
            case(#Financials(arg)){
                Financials.applyFinancialUpdate(#Ok(#Financials(arg)), property, #Financials(arg));
            };
            case(#MonthlyRent(n)){
                Financials.applyFinancialUpdate(#Ok(#MonthlyRent(n)), property, #MonthlyRent(n));
            };
            case(#PhysicalDetails(arg)){
                Details.mutatePhysicalDetails(property, arg, what);
            };
            case(#AdditionalDetails(arg)){
                Details.mutateAdditionalDetails(property, arg, what);
            };
            case(#NFTMarketplace(arg)){
                await NFTMarketplace.writeListings(arg, property, caller);
            }
        }
    };

 

}