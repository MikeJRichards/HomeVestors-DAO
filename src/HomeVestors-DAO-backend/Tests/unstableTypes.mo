import HashMap "mo:base/HashMap";
import Buffer "mo:base/Buffer";
import Nat "mo:base/Nat";
import Types "../types";
import Result "mo:base/Result";

module {
    type Result = Types.Result;
    type What = Types.What;
    type UpdateError = Types.UpdateError;

    public type Handler<C,U,T> = {
        map: PropertyUnstable -> HashMap.HashMap<Nat, T>;
        getId : PropertyUnstable -> Nat;
        incrementId : PropertyUnstable -> ();
        create: (C, Nat, Principal) -> T;
        mutate: (U, T) -> T;
        validate: ?T -> Result.Result<T, UpdateError>;
    };

    public type SimpleHandler<T> = {
      validate: (val: T) -> Result.Result<T, UpdateError>;
      apply: (val: T, p: PropertyUnstable) -> ();
    };

    public type Arg = {
        what: What;
        caller: Principal;
        property: PropertyUnstable;
    };

    public type PropertyUnstable = {
        var id: Nat;
        var details: PropertyDetailsUnstable;
        var financials: FinancialsUnstable;
        var administrative: AdministrativeInfoUnstable;
        var operational: OperationalInfoUnstable;
        var nftMarketplace: NFTMarketplaceUnstable;
        var updates: Buffer.Buffer<Result>;
    };

    public type PropertyDetailsUnstable = {
        var location: LocationDetailsUnstable;
        var physical: PhysicalDetailsUnstable;
        var additional: AdditionalDetailsUnstable;
        var misc: MiscellaneousUnstable;
    };

    public type MiscellaneousUnstable = {
        var description : Text;
        var imageId: Nat;
        images: HashMap.HashMap<Nat, Text>;
    };

    public type LocationDetailsUnstable = {
        var name: Text;
        var addressLine1: Text;
        var addressLine2: Text;
        var addressLine3: ?Text;
        var addressLine4: ?Text;
        var location: Text;
        var postcode: Text;
    };

    public type PhysicalDetailsUnstable = {
        var lastRenovation: Nat;
        var yearBuilt: Nat;
        var squareFootage: Nat;
        var beds: Nat;
        var baths: Nat;
    };

    public type AdditionalDetailsUnstable = {
        var crimeScore: Nat;
        var schoolScore: Nat;
        var affordability: Nat;
        var floodZone: Bool;
    };

    public type AdministrativeInfoUnstable = {
        var documentId: Nat;
        var insuranceId: Nat;
        var notesId: Nat;
        var insurance: HashMap.HashMap<Nat, InsurancePolicyUnstable>;
        var documents: HashMap.HashMap<Nat, DocumentUnstable>;
        var notes: HashMap.HashMap<Nat, NoteUnstable>;
    };

    public type OperationalInfoUnstable = {
        var tenantId: Nat;
        var maintenanceId: Nat;
        var inspectionsId: Nat;
        var tenants: HashMap.HashMap<Nat, TenantUnstable>;
        var maintenance: HashMap.HashMap<Nat, MaintenanceRecordUnstable>;
        var inspections: HashMap.HashMap<Nat, InspectionRecordUnstable>;
    };

    public type FinancialsUnstable = {
        var investment: InvestmentDetailsUnstable;
        var pricePerSqFoot: Nat;
        var valuationId: Nat;
        var valuations: HashMap.HashMap<Nat, ValuationRecordUnstable>;
        var monthlyRent: Nat;
        var yield: Float;
        var currentValue: Nat;
    };

    public type InvestmentDetailsUnstable = {
        var totalInvestmentValue: Nat;
        var platformFee: Nat;
        var initialMaintenanceReserve: Nat;
        var purchasePrice: Nat;
    };

    public type ValuationRecordUnstable = {
        var id: Nat;
        var value: Nat;
        var method: ValuationMethodUnstable;
        var date: Int;
        var appraiser: Principal;
    };

    public type ValuationMethodUnstable = {
        #Appraisal;
        #MarketComparison;
        #Online;
    };

    public type InsurancePolicyUnstable = {
        var id: Nat;
        var policyNumber: Text;
        var provider: Text;
        var startDate: Int;
        var endDate: ?Int;
        var premium: Nat;
        var paymentFrequency: PaymentFrequencyUnstable;
        var nextPaymentDate: Int;
        var contactInfo: Text;
    };

    public type PaymentFrequencyUnstable = {
        #Weekly;
        #Monthly;
        #Annually;
    };

    public type DocumentUnstable = {
        var id: Nat;
        var uploadDate: Int;
        var title: Text;
        var description: Text;
        var documentType: DocumentTypeUnstable;
        var url: Text;
    };

    public type DocumentTypeUnstable = {
        #AST;
        #EPC;
        #EICR;
        #Other: Text;
    };

    public type NoteUnstable = {
        var id: Nat;
        var date: ?Int;
        var title: Text;
        var content: Text;
        var author: Principal;
    };

    public type TenantUnstable = {
        var id: Nat;
        var leadTenant: Text;
        var otherTenants: Buffer.Buffer<Text>;
        var principal: ?Principal;
        var monthlyRent: Nat;
        var deposit: Nat;
        var leaseStartDate: Int;
        var contractLength: ContractLengthUnstable;
        var paymentHistory: Buffer.Buffer<PaymentUnstable>;
    };

    public type ContractLengthUnstable = {
        #SixMonths;
        #Rolling;
        #Annual;
    };

    public type PaymentUnstable = {
        var id: Nat;
        var amount: Nat;
        var date: Int;
        var method: PaymentMethod;
    };

    public type PaymentMethod = {
        #Crypto: {cryptoType: AcceptedCryptos};
        #BankTransfer;
        #Cash;
        #Other: {description: ?Text};
    };

    public type AcceptedCryptos = {
        #CKUSDC;
        #ICP;
        #HGB;
    };

    public type MaintenanceRecordUnstable = {
        var id: Nat;
        var description: Text;
        var dateCompleted: ?Int;
        var cost: ?Float;
        var contractor: ?Text;
        var status: MaintenanceStatusUnstable;
        var paymentMethod: ?PaymentMethod;
        var dateReported: ?Int;
    };

    public type MaintenanceStatusUnstable = {
        #Pending;
        #InProgress;
        #Completed;
    };

    public type InspectionRecordUnstable = {
        var id: Nat;
        var inspectorName: Text;
        var date: ?Int;
        var findings: Text;
        var actionRequired: ?Text;
        var followUpDate: ?Int;
        var appraiser: Principal;
    };

    public type NFTMarketplaceUnstable = {
        var collectionId: Principal;
        var listId: Nat;
        var listings: HashMap.HashMap<Nat, Listing>;
        var royalty : Nat;
    };

    type Listing = Types.Listing;
}