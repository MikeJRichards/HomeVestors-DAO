import HashMap "mo:base/HashMap";

module {
    //public type HashMap.HashMap<A,B> = HashMap.HashMap<A,B>;
    // Main Property Structure
    public type Property = {
        id: Nat;  // Unique identifier for the property
        details: PropertyDetails;  // Grouped details about the property, including description
        financials: Financials;  // Financial details, including investment, valuation, and income
        administrative: AdministrativeInfo;  // Grouped administrative information
        operational: OperationalInfo;  // Grouped operational information
        nftMarketplace: NFTMarketplace;
        updates : [Result];
    };

    public type Result = {
        #Ok: What;
        #Err: UpdateError;
    };

    public type Update = {
        #Details : PropertyDetails;
        #Financials : Financials;
        #Administrative : AdministrativeInfo;
        #Operational : OperationalInfo;
        #NFTMarketplace: NFTMarketplace;
    };

    public type Error = {
        #InvalidPropertyId;
    };

    public type Properties = HashMap.HashMap<Nat, Property>;
    public type UsersNotifications = HashMap.HashMap<Account, User>;
    public type User = {
        id: Nat;
        notifications : [Notification];
        results : [NotificationResult];
    };

    public type NotificationResult = {
        #Ok : Notification;
        #Err: (Nat, UpdateError);
    };

    public type Notification = {
        id: Nat;
        propertyId: Nat;
        ntype : NotificationType;
        content: What;
    };

    public type NotificationType = {
        #New;
        #Read;
        #Deleted;
    };

 //   // PropertyDetails Structure
   public type PropertyDetails = {
       location: LocationDetails;  // Location-specific details, including property name
       physical: PhysicalDetails;  // Physical characteristics of the property
       additional: AdditionalDetails;  // Additional property-related details
       description: Text;  // General description of the property
   };
//
    public type LocationDetails = {
        name: Text;  // Name of the property
        addressLine1: Text;  // Street address
        addressLine2: Text;  // Street address
        addressLine3: ?Text;  // Street address
        addressLine4: ?Text;  // Street address
        location: Text;  // City, state, or other location information
        postcode: Text;  // Postal code
    };

    public type PhysicalDetails = {
        lastRenovation: Nat;
        yearBuilt: Nat;
        squareFootage: Nat;
        beds: Nat;
        baths: Nat;
    };

   public type AdditionalDetails = {
       crimeScore: Nat;
       schoolScore: Nat;
       affordability: Nat;
       floodZone: Bool;
   };

    // Financials Structure
    public type FinancialsArg = {
        currentValue: Nat;  // Current market value of the property
    };

    public type Financials = FinancialsArg and {
        investment: InvestmentDetails;  // Separate structure for investment-related details
        pricePerSqFoot: Nat;  // Price per square foot of the property
        valuationId: Nat; //Id of the valuations
        valuations: [(Nat, ValuationRecord)];  // Array of property valuation records
        monthlyRent: Nat;  // Monthly rent collected from the property
        yield: Float;  // Yield based on rental income
    };

    public type CreateFinancialsArg = {
        reserve: Nat;
        purchasePrice: Nat;
        platformFee: Nat;
        currentValue: Nat;
        sqrFoot: Nat;
        monthlyRent: Nat;
    };

     public type AccountRecord = {
       balance: Nat;
       owned_tokens: [Nat];
       transfers: [TransactionEvent]; // 👈 New field
     };
 
    public type TokenRecord = {
      owner: Account;
      metadata: [(Text, Value)];
      history: [(Principal, Int, TransactionType)]; // (owner, timestamp)
    };

    public type MintArg = {
      meta: [(Text, Value)];
      from_subaccount: ?Blob;
      to: Account;
      memo: ?Blob;
      created_at_time: ?Nat64;
    };  

    public type MintResult = {
      #Ok: Nat;
      #Err: MintError;
    };

    public type BaseError = {
        #TooOld;
        #CreatedInFuture : {ledger_time: Nat64};
        #GenericError : {error_code : Nat; message : Text};
        #GenericBatchError : {error_code : Nat; message : Text};
    };
    
    public type RevokeCollectionApprovalError = BaseError or {
        #ApprovalDoesNotExist;
    };

    public type ApproveCollectionError = BaseError or  {
        #InvalidSpender;
    };

    public type StandardError = BaseError or {
        #Unauthorized;
        #NonExistingTokenId;
    };

    public type RevokeTokenApprovalError = StandardError or  {
        #ApprovalDoesNotExist;
    };

    public type ApproveTokenError = StandardError or {
        #InvalidSpender;
    };

    public type TransferError = StandardError or {
        #InvalidRecipient;
        #Duplicate : {duplicate_of : Nat};
    };

    public type TransferFromError = TransferError;

    public type MintError = TransferError or {
        #ExceedsMaxSupply;
    };

    public type TransactionType = {
       #Burn;
       #Transfer;
       #Send;
       #Receive;
       #Mint;
       #TransferFrom;
    };
//
     public type TransactionEvent = {
       token_id: Nat;
       counterparty: ?Account;
       transaction: TransactionType;
       timestamp: Int;
     };

    public type Value = {
        #Blob : Blob; 
        #Text : Text; 
        #Nat : Nat;
        #Int : Int;
        #Array : [Value]; 
        #Map : [(Text, Value)];
    };

   public type InvestmentDetails = {
       totalInvestmentValue: Nat;
       platformFee: Nat;
       initialMaintenanceReserve: Nat;
       purchasePrice: Nat;
   };
//
 //   public type PropertyStatus = {
 //       #PreCompletion;
 //       #Active;
 //       #Frozen;
 //       #Selling;
 //       #Other;  // Add any other relevant statuses as needed
 //   };
//
 //   // AdministrativeInfo Structure
    public type AdministrativeInfo = {
        documentId: Nat;
        insuranceId: Nat;
        notesId: Nat;
        insurance: [(Nat, InsurancePolicy)];  // Insurance policies
        documents: [(Nat, Document)];  // Property-related documents
        notes: [(Nat, Note)];  // General notes related to the property
    };

    // OperationalInfo Structure
    public type OperationalInfo = {
        tenantId: Nat;
        maintenanceId: Nat;
        inspectionsId: Nat;
        tenants: [(Nat, Tenant)];  // Tenants in the property
        maintenance: [(Nat, MaintenanceRecord)];  // Maintenance tasks
        inspections: [(Nat, InspectionRecord)];  // Inspection records
    };

    // Supporting Structures
    public type InsurancePolicyUArg = {
        policyNumber: ?Text;  // Unique policy number
        provider: ?Text;  // Insurance provider
        startDate: ?Int;  // Start date of the policy
        endDate: ?Int;  // End date of the policy (None if active)
        premium: ?Nat;  // Premium cost
        paymentFrequency: ?PaymentFrequency;  // Whether paid weekly, monthly, or annually
        nextPaymentDate: ?Int;  // Date of the next payment
        contactInfo: ?Text;  // Contact information for the insurance provider
    };

    public type InsurancePolicyCArg = {
        policyNumber: Text;  // Unique policy number
        provider: Text;  // Insurance provider
        startDate: Int;  // Start date of the policy
        endDate: ?Int;  // End date of the policy (None if active)
        premium: Nat;  // Premium cost
        paymentFrequency: PaymentFrequency;  // Whether paid weekly, monthly, or annually
        nextPaymentDate: Int;  // Date of the next payment
        contactInfo: Text;  // Contact information for the insurance provider
    };

    // InsurancePolicy Structure
    public type InsurancePolicy = InsurancePolicyCArg and {
        id: Nat;  // Unique identifier for the insurance policy
    };

   public type PaymentFrequency = {
       #Weekly;
       #Monthly;
       #Annually;
   };
   
   public type DocumentUArg = {
        title: ?Text;  // Title of the document
        description: ?Text;  // Description or purpose of the document
        documentType: ?DocumentType;  // Type of document, e.g., "Lease", "Inspection Report"
        url: ?Text;  // URL or file location where the document is stored
    };

    public type DocumentCArg = {
        title: Text;  // Title of the document
        description: Text;  // Description or purpose of the document
        documentType: DocumentType;  // Type of document, e.g., "Lease", "Inspection Report"
        url: Text;  // URL or file location where the document is stored
    };

    // Document Structure
    public type Document = {
        id: Nat;  // Unique identifier for the document
        uploadDate: Int;  // Date the document was uploaded or created
        title: Text;  // Title of the document
        description: Text;  // Description or purpose of the document
        documentType: DocumentType;  // Type of document, e.g., "Lease", "Inspection Report"
        url: Text;  // URL or file location where the document is stored
    };

   //Document type 
   public type DocumentType = {
       #AST;
       #EPC;
       #EICR;
       //etc
       #Other : Text;
   };
    // InspectionRecord Structure
    public type InspectionRecordUArg = {
        inspectorName: ?Text;  // Name of the inspector or inspection company
        date: ?Int;  // Date of the inspection
        findings: ?Text;  // Findings from the inspection
        actionRequired: ?Text;  // Description of any required follow-up actions
        followUpDate: ?Int;  // Date for a follow-up inspection, if needed
    };

    public type InspectionRecordCArg = {
        inspectorName: Text;  // Name of the inspector or inspection company
        date: ?Int;  // Date of the inspection
        findings: Text;  // Findings from the inspection
        actionRequired: ?Text;  // Description of any required follow-up actions
        followUpDate: ?Int;  // Date for a follow-up inspection, if needed
    };

    public type InspectionRecord =InspectionRecordCArg and {
        id: Nat;  // Unique identifier for the inspection record
        appraiser: Principal;  // Name of the appraiser or firm that conducted the valuation
    };

    // ValuationRecord Structure
    public type ValuationRecordUArg = {
        value: ?Nat;  // Assessed value of the property
        method: ?ValuationMethod;  // Method used for the valuation
    };

    public type ValuationRecordCArg = {
        value: Nat;  // Assessed value of the property
        method: ValuationMethod;  // Method used for the valuation
    };

    public type ValuationRecord = ValuationRecordCArg and {
        id: Nat;  // Unique identifier for the valuation record
        date: Int;  // Date of the valuation
        appraiser: Principal;
    };

    public type ValuationMethod = {
        #Appraisal;
        #MarketComparison;
        #Online;
    };

    // Note Structure
    public type NoteUArg = {
        date: ?Int;  // Date the note was made
        title : ?Text;
        content: ?Text;  // Content of the note
    };

    public type NoteCArg = {
        date: ?Int;
        title: Text;
        content: Text;
    };

    public type Note = NoteCArg and {
        id: Nat;  // Unique identifier for the note
        author: Principal;  // Name of the person who made the note
    };

    public type TenantUArg = {
        leadTenant: ?Text;  // Name of the lead tenant
        otherTenants: ?[Text];  // Array of names of other tenants
        principal: ?Principal;  // Lead tenant's Principal (for interactions/payments), nullable
        monthlyRent: ?Nat;  // Amount of rent the tenant pays monthly
        deposit: ?Nat;  // Security deposit amount
        leaseStartDate: ?Int;  // Start date of the lease
        contractLength: ?ContractLength; // End date of the lease (None if currently active)
        paymentHistory : ?[Payment];
    };

    public type TenantCArg = {
        leadTenant: Text;  // Name of the lead tenant
        otherTenants: [Text];  // Array of names of other tenants
        principal: ?Principal;  // Lead tenant's Principal (for interactions/payments), nullable
        monthlyRent: Nat;  // Amount of rent the tenant pays monthly
        deposit: Nat;  // Security deposit amount
        leaseStartDate: Int;  // Start date of the lease
        contractLength: ContractLength; // End date of the lease (None if currently active)
    };

    // Tenant Structure
    public type Tenant = TenantCArg and {
        id: Nat;  // Unique identifier for the tenant
        paymentHistory: [Payment];  // Array of payments made by the tenant
    };

    public type ContractLength = {
        #SixMonths;
        #Rolling;
        #Annual;
    };

   public type Payment = {
       id: Nat;  // Unique identifier for the payment
       amount: Nat;  // Amount paid
       date: Int;  // Date of the payment
       method: PaymentMethod;  // Method used for the payment
   };

    public type PaymentMethod = {
        #Crypto: {cryptoType: AcceptedCryptos};
        #BankTransfer;
        #Cash;
        #Other: { description: ?Text};// Option to define other payment methods
    };

    public type AcceptedCryptos = {
        #CKUSDC;
        #ICP;
        #HGB;
    };

    public type MaintenanceRecordUArg = {
        description: ?Text;  // Description of the maintenance task or issue
        dateCompleted: ?Int;  // The date the task was completed (None if still ongoing)
        cost: ?Float;  // The cost of the maintenance, if applicable
        contractor: ?Text;  // The name of the contractor or company responsible, if applicable
        status: ?MaintenanceStatus;  // Status of the maintenance task (e.g., Pending, In Progress, Completed)
        paymentMethod: ?PaymentMethod;  // Method used to pay for the maintenance
        dateReported: ?Int;  // The date the issue was reported or the task was created
    };

    public type MaintenanceRecordCArg = {
        description: Text;  // Description of the maintenance task or issue
        dateCompleted: ?Int;  // The date the task was completed (None if still ongoing)
        cost: ?Float;  // The cost of the maintenance, if applicable
        contractor: ?Text;  // The name of the contractor or company responsible, if applicable
        status: MaintenanceStatus;  // Status of the maintenance task (e.g., Pending, In Progress, Completed)
        paymentMethod: ?PaymentMethod;  // Method used to pay for the maintenance
        dateReported: ?Int;  // The date the issue was reported or the task was created
    };

    // MaintenanceRecord Structure
    public type MaintenanceRecord = MaintenanceRecordCArg and {
        id: Nat;  // Unique identifier for the maintenance record
    };

    public type MaintenanceStatus = {
        #Pending;
        #InProgress;
        #Completed;
    };
    
    // Account Structure
    public type Account = {
        owner: Principal;
        subaccount: ?Blob;
    };

    public type Read = {
        #AllInsurance;
        #InsuranceById : Nat;
        #AllDocuments;
        #DocumentById: Nat;
        #AllNotes;
        #NoteById: Nat;
        #LastNote;
        #AllValuations;
        #ValuationById : Nat;
        #LastValuation;
        #AllTenants;
        #CurrentTenant;
        #TenantById: Nat;
        #TenantPaymentHistory: Nat;
        #AllMaintenance;
        #MaintenanceById: Nat;
        #LastMaintenance;
        #AllInspections;
        #InspectionById: Nat;
        #LastInspection;
        #PhysicalDetails;
        #AdditionalDetails;
        #LocationDetails;
        #Financials;
        #MonthlyRent;
        #UpdateResults;
        #UpdatedState;
        #UpdateErrors;
    };

    public type ReadResult = {
        #Ok: ReadUnsanitized;
        #Err: ReadErrors;
    };

    public type GetPropertyResult = {
        #Ok : Property;
        #Err;
    };

    public type UpdateError = {
        #InvalidPropertyId;
        #InvalidElementId;
        #OverWritingData;
        #InvalidData : {field: Text; reason: Reason};
        #GenericError;
        #InvalidType;
        #CannotUpdateLiveAuction;
    };

    public type Reason = {
        #EmptyString;
        #CannotBeSetInThePast;
        #CannotBeSetInTheFuture;
        #CannotBeZero;
        #InaccurateData;
        #OutOfRange;
        #InvalidInput;
        #DataMismatch;
        #CannotBeNull;
        #Anonymous;
        #FailedToDecodeResponseBody;
        #JSONParseError;
    };

    public type ReadErrors = {
        #InvalidPropertyId;
        #InvalidElementId;
        #EmptyArray;
        #Vacant
    };

    public type ReadUnsanitized = {
        #AllInsurance: [(Nat, InsurancePolicy)];
        #Insurance : ?InsurancePolicy;
        #AllDocuments: [(Nat, Document)];
        #Document : ?Document;
        #AllNotes: [(Nat, Note)];
        #Note : ?Note;
        #LastNote: ?Note;
        #AllValuations: [(Nat, ValuationRecord)];
        #Valuation : ?ValuationRecord;
        #LastValuation: ?ValuationRecord;
        #AllTenants: [(Nat, Tenant)];
        #Tenant : ?Tenant;
        #CurrentTenant: ?Tenant;
        #TenantPaymentHistory: ?[Payment];
        #AllMaintenance: [(Nat, MaintenanceRecord)];
        #Maintenance: ?MaintenanceRecord;
        #LastMaintenance :?MaintenanceRecord;
        #AllInspections: [(Nat, InspectionRecord)];
        #Inspection: ?InspectionRecord;
        #LastInspection: ?InspectionRecord;
        #PhysicalDetails: PhysicalDetails;
        #AdditionalDetails: AdditionalDetails;
        #LocationDetails: LocationDetails;
        #Financials: Financials;
        #MonthlyRent: Nat;
        #UpdateResults : [Result];
    };
    
    public type Intent<T> = {
        #Create: (T, Nat);
        #Update: (T, Nat);
        #Delete: Nat;
    };

    public type Actions<C, U> = {
        #Create: C;
        #Update: U;
        #Delete: Nat;
    };

    public type WhatWithPropertyId = {
        propertyId: Nat;
        what: What;
    };

    public type What = {
        #Insurance: Actions<InsurancePolicyCArg, (InsurancePolicyUArg, Nat)>;
        #Document: Actions<DocumentCArg, (DocumentUArg, Nat)>;
        #Note: Actions<NoteCArg, (NoteUArg, Nat)>;
        #Maintenance: Actions<MaintenanceRecordCArg, (MaintenanceRecordUArg, Nat)>;
        #Inspection: Actions<InspectionRecordCArg, (InspectionRecordUArg, Nat)>;
        #Tenant: Actions<TenantCArg, (TenantUArg, Nat)>;
        #Valuations: Actions<ValuationRecordCArg, (ValuationRecordUArg, Nat)>;
        #Financials: FinancialsArg;
        #MonthlyRent: Nat;
        #PhysicalDetails : PhysicalDetails;
        #AdditionalDetails : AdditionalDetails;
        #NFTMarketplace: MarketplaceAction;
    };

    public type OperationalIntentAction = {
        #Maintenance: Intent<MaintenanceRecord>;
        #Tenant: Intent<Tenant>;
        #Inspection: Intent<InspectionRecord>;
    };

    public type AdministrativeIntentAction = {
        #Insurance: Intent<InsurancePolicy>;
        #Documents: Intent<Document>;
        #Notes: Intent<Note>;
    };

    public type FinancialIntentAction = {
        #Valuation: Intent<ValuationRecord>;
        #Financials: FinancialsArg;
        #MonthlyRent: Nat;
    };

    public type IntentResult<T> = {
        #Ok: T;
        #Err: UpdateError;
    };

    public type AdministrativeIntentResult = IntentResult<AdministrativeIntentAction>;
    public type OperationalIntentResult = IntentResult<OperationalIntentAction>;
    public type FinancialIntentResult = IntentResult<FinancialIntentAction>;

    public type UpdateResult = {
        #Ok: Property; 
        #Err : UpdateError;
    };

    /////////////////////////////////
    //Marketplace structs
    public type NFTMarketplace = {
        collectionId: Principal;
        listId: Nat;
        listings: [(Nat, Listing)];
        royalty : Nat;
    };

    public type Listing = {
        #LiveFixedPrice: FixedPrice;
        #SoldFixedPrice: SoldFixedPrice;
        #CancelledFixedPrice: CancelledFixedPrice;
        #LiveAuction: Auction;
        #SoldAuction: SoldAuction;
        #CancelledAuction: CancelledAuction;
    };

    public type BaseListing = {
        tokenId: Nat;
        listedAt: Int;
        seller: Account;
        quoteAsset: AcceptedCryptos;
    };

    public type FixedPrice = BaseListing and {
        price: Nat;
        expiresAt: ?Int;
    };

    public type FixedPriceCArg = {
        tokenId: Nat;
        seller_subaccount: ?Blob;
        price: Nat;
        expiresAt: ?Int;
        quoteAsset: ?AcceptedCryptos;
    };

    public type FixedPriceUArg = {
        listingId: Nat;
        price: ?Nat;
        expiresAt: ?Int;
        quoteAsset: ?AcceptedCryptos;
    };

    public type SoldFixedPrice = FixedPrice and {
        soldAt: Int;
        buyer: Account;
        royaltyBps: ?Nat; // Basis points, e.g. 250 = 2.5%
    };

    public type CancelledFixedPrice = FixedPrice and {
        cancelledBy: Account;
        cancelledAt: Int;
        reason: CancelledReason;
    };

    

    public type Auction = BaseListing and {
        startingPrice: Nat;
        buyNowPrice: ?Nat;
        bidIncrement: Nat;
        reservePrice: ?Nat;
        startTime: Int;
        endsAt: Int;
        highestBid: ?Bid;
        previousBids: [Bid];
    };

    public type AuctionCArg = {
        tokenId: Nat;
        seller_subaccount: ?Blob;
        startingPrice: Nat;
        buyNowPrice: ?Nat;
        reservePrice: ?Nat;
        startTime: Int;
        endsAt: Int;
        quoteAsset: ?AcceptedCryptos;
    };

    public type AuctionUArg = {
        listingId: Nat;
        startingPrice: ?Nat;
        buyNowPrice: ?Nat;
        reservePrice: ?Nat;
        startTime: ?Int;
        endsAt: ?Int;
        quoteAsset: ?AcceptedCryptos;
    };

    public type SoldAuction = Auction and {
        auctionEndTime: Int;
        soldFor: Nat;
        boughtNow: Bool;
        buyer: Account;
        royaltyBps: ?Nat;
    };

    public type CancelledAuction = Auction and {
        cancelledBy: Account;
        cancelledAt: Int;
        reason: CancelledReason;
    };

    public type CancelledReason = {
        #CancelledBySeller;
        #Expired;
        #CalledByAdmin;
    };

    public type BidArg = {
        listingId: Nat;
        bidAmount: Nat;
        buyer_subaccount: ?Blob;
    };

    public type Bid = {
        bidAmount: Nat;
        buyer: Account;
        bidTime: Int;
    };

    public type CancelArg = {
        cancelledBy_subaccount: ?Blob;
        listingId: Nat;
        reason: CancelledReason;
    };


    public type MarketplaceAction = {
        #CreateFixedListing : FixedPriceCArg;
        #UpdateFixedListing: FixedPriceUArg;
        #CreateAuctionListing : AuctionCArg;
        #UpdateAuctionListing: AuctionUArg;
        #Bid: BidArg;
        #CancelListing: CancelArg;
    };

    public type MarketplaceIntent = Intent<Listing>;
    public type MarketplaceIntentResult = IntentResult<MarketplaceIntent>;

    

}