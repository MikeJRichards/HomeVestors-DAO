import Types "../types";
import UnstableTypes "unstableTypes";
import Stables "stables";
import Principal "mo:base/Principal";

module {
    type Property = Types.Property;
    type PropertyDetails = Types.PropertyDetails;
    type Financials = Types.Financials;
    type AdministrativeInfo = Types.AdministrativeInfo;
    type OperationalInfo = Types.OperationalInfo;
    type NFTMarketplace = Types.NFTMarketplace;
    type Result = Types.Result;
    type LocationDetails = Types.LocationDetails;
    type PhysicalDetails = Types.PhysicalDetails;
    type AdditionalDetails = Types.AdditionalDetails;
    type InvestmentDetails = Types.InvestmentDetails;
    type Note = Types.Note;
    type NoteCArg = Types.NoteCArg;
    type Document = Types.Document;
    type NoteUArg = Types.NoteUArg;
    type DocumentCArg = Types.DocumentCArg;
    type DocumentUArg = Types.DocumentUArg;
    type InsurancePolicyCArg = Types.InsurancePolicyCArg;
    type InsurancePolicyUArg = Types.InsurancePolicyUArg;
    type InsurancePolicy = Types.InsurancePolicy;
    type MaintenanceRecord = Types.MaintenanceRecord;
    type InspectionRecord = Types.InspectionRecord;
    type ValuationRecord = Types.ValuationRecord;
    type Tenant = Types.Tenant;
    type Miscellaneous = Types.Miscellaneous;
    
    public func createLocationDetails(): LocationDetails {
        {
            name = "";
            addressLine1 = "";
            addressLine2 = "";
            addressLine3 = null;
            addressLine4 = null;
            location = "";
            postcode = "";
        }
    };

    public func createPhysicalDetails(): PhysicalDetails{
       {
            lastRenovation = 2000;
            yearBuilt = 0;
            squareFootage = 100;
            beds = 0;
            baths = 0;
       } 
    };

    public func createAdditionalDetails(): AdditionalDetails {
        {
            crimeScore = 150;
            schoolScore = 5;
            affordability = 0;
            floodZone = false;
        }
    };

    public func createPropertyDetails(): PropertyDetails {
        {
            location = createLocationDetails();
            physical = createPhysicalDetails();
            additional = createAdditionalDetails();
            misc = createMisc();
        };
    };

    public func createMisc(): Miscellaneous {
      {
        description = "updated description of property";
        imageId = 0;
        images = [];
      }
    };

    public func createInvestmentDetails(): InvestmentDetails {
        {
            totalInvestmentValue = 0;
            platformFee = 0;
            initialMaintenanceReserve = 0;
            purchasePrice = 0;
        }
    };

    public func createFinancials(): Financials {
        {
            account = {owner = Principal.fromText("vq2za-kqaaa-aaaas-amlvq-cai"); subaccount = null};
            currentValue = 0;
            investment = createInvestmentDetails();
            pricePerSqFoot =0;
            valuationId = 0;
            valuations = [];
            invoiceId = 0;
            invoices = [];
            monthlyRent = 0;
            yield = 0.0;
        }
    };

    public func createAdministrativeInfo(): AdministrativeInfo {
        {
            documentId = 0;
            insuranceId = 0;
            notesId = 0;
            insurance = [];
            documents = [];
            notes = [];
        }
    };

    public func createOperationalInfo(): OperationalInfo {
        {
            tenantId = 0;
            maintenanceId = 0;
            inspectionsId = 0;
            tenants = [];
            maintenance = [];
            inspections = [];
        }
    };

    public func createNFTMarketplace(): NFTMarketplace {
        {
            collectionId = Principal.fromText("wvocl-xyaaa-aaaas-aml6a-cai");
            listId = 0;
            listings = [];
            timerIds = [];
            royalty = 0;
        }
    };

    public func createGovernance(): Types.Governance {
      {
        proposalId = 0;
        proposals = [];
        assetCost = #HGB;
        proposalCost = 0;
        requireNftToPropose = true;      // must own an NFT from this property to propose
        minYesVotes = 0;           // Absolute vote count threshold
        minTurnout = 0;               // % turnout requirement
        quorumPercentage = 51;         // e.g. 51
      };
    };

    public func createBlankProperty(): UnstableTypes.PropertyUnstable {
        Stables.fromStableProperty({
            id = 0;
            details = createPropertyDetails();
            financials = createFinancials();
            administrative = createAdministrativeInfo();
            operational = createOperationalInfo();
            nftMarketplace = createNFTMarketplace();
            governance = createGovernance();
            updates = [];
        })
    };



}