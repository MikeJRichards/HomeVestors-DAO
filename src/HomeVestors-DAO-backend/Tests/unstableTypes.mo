import HashMap "mo:base/HashMap";
import Buffer "mo:base/Buffer";
import Nat "mo:base/Nat";
import Types "../types";
import Result "mo:base/Result";

module {
    type Result = Types.Result;
    type What = Types.What;
    type UpdateError = Types.UpdateError;
    type Update = Types.Update;

    public type Handler<T, StableT> = {
        validateAndPrepare: () -> [(?Nat, Result.Result<T, Types.UpdateError>)];
        asyncEffect:  [(?Nat, Result.Result<T, UpdateError>)] -> async [(?Nat, Result.Result<(), UpdateError>)];
        applyAsyncEffects: (?Nat, Result.Result<T, Types.UpdateError>) -> [(?Nat, Result.Result<StableT, Types.UpdateError>)];
        applyUpdate: (?Nat, StableT) -> ?Nat;
        getUpdate: () -> Update;
        finalAsync: [Result.Result<?Nat, (?Nat, UpdateError)>] -> async ();
    };

    public type CrudHandler<C, U, T, StableT> = {
        map: HashMap.HashMap<Nat, StableT>;
        var id: Nat;
        setId: Nat -> ();
        assignId: (Nat, StableT) -> (Nat, StableT); //increment property id, assign id to el, return (id, el)
        delete: (Nat, StableT) -> ();
        fromStable: StableT -> T;
        create: (C, Nat) -> T;
        mutate: (U, T) -> T;
        validate: ?T -> Result.Result<T, UpdateError>;
    };


    public type SimpleHandler<T> = {
      validate: (val: T) -> Result.Result<T, UpdateError>;
      apply: (val: T, p: PropertyUnstable) -> ();
    };


    public type PropertyUnstable = {
        var id: Nat;
        var details: PropertyDetailsUnstable;
        var financials: FinancialsUnstable;
        var administrative: AdministrativeInfoUnstable;
        var operational: OperationalInfoUnstable;
        var nftMarketplace: NFTMarketplaceUnstable;
        var governance: GovernanceUnstable;
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
        var account: Account;
        var investment: InvestmentDetailsUnstable;
        var pricePerSqFoot: Nat;
        var valuationId: Nat;
        var valuations: HashMap.HashMap<Nat, ValuationRecordUnstable>;
        var invoiceId: Nat;
        var invoices: HashMap.HashMap<Nat, InvoiceUnstable>;
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
        var timerIds: HashMap.HashMap<Nat, Nat>; //listId, timerIds
        var royalty : Nat;
    };

    public type InvoiceUnstable = {
      var id: Nat;
      var status: Types.InvoiceStatus;
      var direction: Types.InvoiceDirection;       // includes category + counterparty
      var title: Text;
      var description: Text;
      var amount: Nat;
      var due: Int;
      var paymentStatus: Types.PaymentStatus;
      var paymentMethod: Types.AcceptedCryptos;
      var recurrence: Types.RecurrenceType;
      var logs: [Types.InvoiceLog];
    };

    type Listing = Types.Listing;
    type InvestmentDetails = Types.InvestmentDetails;
    type ValuationRecord = Types.ValuationRecord;

    public type MiscellaneousPartialUnstable = {
        var description: Text;
        var imageId: Nat;
        var images: HashMap.HashMap<Nat, Text>;
    };

    public type FinancialsPartialUnstable = {
        var account : Account;
        var currentValue: Nat;
        var investment: InvestmentDetails;
        var pricePerSqFoot: Nat;
        var valuationId: Nat;
        var valuations : HashMap.HashMap<Nat, ValuationRecord>;
        var invoiceId: Nat;
        var invoices : HashMap.HashMap<Nat, Types.Invoice>;
        var monthlyRent: Nat;
        var yield: Float;
    };
    type InsurancePolicy = Types.InsurancePolicy;
    type Document = Types.Document;
    type Note = Types.Note;

    public type AdministrativeInfoPartialUnstable = {
        var documentId: Nat;
        var insuranceId: Nat;
        var notesId: Nat;
        var insurance: HashMap.HashMap<Nat, InsurancePolicy>;
        var documents: HashMap.HashMap<Nat, Document>;
        var notes: HashMap.HashMap<Nat, Note>;
    };

    type Tenant = Types.Tenant;
    type MaintenanceRecord = Types.MaintenanceRecord;
    type InspectionRecord = Types.InspectionRecord;

    public type OperationalInfoPartialUnstable = {
        var tenantId: Nat;
        var maintenanceId: Nat;
        var inspectionsId: Nat;
        var tenants: HashMap.HashMap<Nat, Tenant>;
        var maintenance: HashMap.HashMap<Nat, MaintenanceRecord>;
        var inspections: HashMap.HashMap<Nat, InspectionRecord>;
    };

    public type GovernanceUnstable = {
        var proposalId: Nat;
        var proposals: HashMap.HashMap<Nat, Types.Proposal>;
        var assetCost: AcceptedCryptos;
        var proposalCost: Nat;              // in e8s or base units
        var requireNftToPropose: Bool;      // must own an NFT from this property to propose
        var minYesVotes: Nat;           // Absolute vote count threshold
        var minTurnout: Nat;               // % turnout requirement
        var quorumPercentage: Nat;         // e.g. 51
    };

    public type ProposalUnstable = {
      var id: Nat;
      var title: Text;
      var description: Text;
      var creator: Principal;
      var createdAt: Int;
      var startAt: Int;
      var eligibleVoters: [Principal];
      var totalEligibleVoters: Nat;            // ← stored for convenience
      var votes: [(Principal, Bool)];          // One vote per principal
      var status: Types.ProposalStatus;               // Draft | Live | Executed | Rejected
      var category: Types.ProposalCategory;
      var implementation: Types.ImplementationCategory;
      var actions: [What];
    };



    public type NftMarketplacePartialUnstable = {
        var collectionId: Principal;
        var listId: Nat;
        var listings: HashMap.HashMap<Nat, Listing>;
        var timerIds: HashMap.HashMap<Nat, Nat>;
        var royalty: Nat;
    };

    type Account = Types.Account;
    public type BaseListingUnstable = {
        var id: Nat;
        var tokenId: Nat;
        var listedAt: Int;
        var seller: Account;
        var quoteAsset: AcceptedCryptos;
    };
  
    public type FixedPriceUnstable = BaseListingUnstable and {
        var price: Nat;
        var expiresAt: ?Int;
    };

    type Bid = Types.Bid;
    public type SoldFixedPriceUnstable = FixedPriceUnstable and {
        var bid: Bid;
        var royaltyBps: ?Nat;
    };

    type CancelledReason = Types.CancelledReason;
    public type CancelledFixedPriceUnstable = FixedPriceUnstable and {
        var cancelledBy: Account;
        var cancelledAt: Int;
        var reason: CancelledReason;
    };

    type Refund = Types.Refund;
    public type AuctionUnstable = BaseListingUnstable and {
        var startingPrice: Nat;
        var buyNowPrice: ?Nat;
        var bidIncrement: Nat;
        var reservePrice: ?Nat;
        var startTime: Int;
        var endsAt: Int;
        var highestBid: ?Bid;
        var previousBids: Buffer.Buffer<Bid>;
        var refunds: Buffer.Buffer<Refund>;
    };

    public type SoldAuctionUnstable = AuctionUnstable and {
        var auctionEndTime: Int;
        var soldFor: Nat;
        var boughtNow: Bool;
        var buyer: Account;
        var royaltyBps: ?Nat;
    };

    public type CancelledAuctionUnstable = AuctionUnstable and {
        var cancelledBy: Account;
        var cancelledAt: Int;
        var reason: CancelledReason;
    };

    public type LaunchUnstable = {
        var id: Nat;
        var seller: Account;
        var caller: Principal;
        var tokenIds: Buffer.Buffer<Nat>;
        var listIds: Buffer.Buffer<Nat>;
        var maxListed: Nat;
        var listedAt: Int;
        var price: Nat;
        var quoteAsset: AcceptedCryptos;
        var endsAt: ?Int;
    };

    public type CancelledLaunchUnstable = LaunchUnstable and {
        var cancelledBy: Account;
        var cancelledAt: Int;
        var reason: CancelledReason;
    };

    public type ListingUnstable = {
        #LaunchedProperty: LaunchUnstable;
        #LaunchFixedPrice: FixedPriceUnstable;
        #CancelledLaunch: CancelledFixedPriceUnstable;
        #CancelledLaunchedProperty: CancelledLaunchUnstable;
        #SoldLaunchFixedPrice: SoldFixedPriceUnstable;
        #LiveFixedPrice: FixedPriceUnstable;
        #SoldFixedPrice: SoldFixedPriceUnstable;
        #CancelledFixedPrice: CancelledFixedPriceUnstable;
        #LiveAuction: AuctionUnstable;
        #SoldAuction: SoldAuctionUnstable;
        #CancelledAuction: CancelledAuctionUnstable;
    };





}