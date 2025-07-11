import HashMap "mo:base/HashMap";

module {
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
        kyc: Bool;
        notifications : [Notification];
        results : [NotificationResult];
        saved: [(Nat, [Nat])];
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

    public type Property = {
        id: Nat;  // Unique identifier for the property
        details: PropertyDetails;  // Grouped details about the property, including description
        financials: Financials;  // Financial details, including investment, valuation, and income
        administrative: AdministrativeInfo;  // Grouped administrative information
        operational: OperationalInfo;  // Grouped operational information
        nftMarketplace: NFTMarketplace;
        updates : [Result];
    };

   public type PropertyDetails = {
       location: LocationDetails;  // Location-specific details, including property name
       physical: PhysicalDetails;  // Physical characteristics of the property
       additional: AdditionalDetails;  // Additional property-related details
       misc: Miscellaneous;
   };

   public type Miscellaneous = {
        description: Text;
        imageId: Nat;
        images: [(Nat, Text)];
   };

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

    public type StandardError = BaseError or {
        #Unauthorized;
        #NonExistingTokenId;
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

    // AdministrativeInfo Structure
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
//    // InspectionRecord Structure
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

//    // ValuationRecord Structure
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
    
//    // Account Structure
    public type Account = {
        owner: Principal;
        subaccount: ?Blob;
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
        #ListingExpired;
        #InvalidType;
        #ImmutableLiveAuction;
        #Transfer: ?GenericTransferError;
        #Unauthorized;
        #InsufficientBid : {minimum_bid: Nat}
    };

    public type GenericTransferError = TransferFromError or {
        #BadFee : {expected_fee: Nat};
        #InsufficientFunds: {balance: Nat};
        #TemporarilyUnavailable;
        #BadBurn  : { min_burn_amount : Nat };
        #InsufficientAllowance  : { allowance : Nat };
        #GenericBatchError : { error_code : Nat; message : Text };
        #InvalidRecipient;                                        // ← Missing
        #NonExistingTokenId; 
    };

    public type GenericTransferResult = {
        #Ok: Nat;
        #Err: GenericTransferError;
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
        #BuyerAndSellerCannotMatch;
    };

    public type ReadErrors = {
        #InvalidPropertyId;
        #InvalidElementId;
        #Filtered;
        #ArrayIndexOutOfBounds;
        #DidNotMatchConditions;
        #EmptyArray;
        #Vacant
    };

    type Selected = ?[Int]; //if null = all, if negative - taken from end, if positive = these specific ids
    type ScopedProperties = {propertyId: Nat; ids: Selected};
    type ScopedNestedProperties = {propertyId: Nat; ids: Selected; elements: Selected};
    public type ListingConditionals = {account: ?Account; listingType: ?[MarketplaceOptions]; ltype: {#Seller; #Winning; #Purchased; #PreviousBids;}};

    public type BaseRead = {
        #Ids: Selected; //These ids from all properties, 
        #Properties: Selected; //All ids from these properties
        #Scoped: [ScopedProperties]; //These ids for this property
    };

    public type ConditionalBaseRead<T> = {
        base: BaseRead;
        conditionals: T;
    };

    public type NestedRead = BaseRead or {
        #NestedScoped: [ScopedNestedProperties];
    };

    public type NestedConditionalRead<T> = {
        nested: NestedRead;
        conditionals: T;
    };

    public type Read2 = {
        #Images: BaseRead;
        #Document: BaseRead;
        #Note: BaseRead;
        #Insurance: BaseRead;
        #Valuation: BaseRead;
        #Tenants: BaseRead;
        #Maintenance: BaseRead;
        #Inspection: BaseRead;
        #PaymentHistory: NestedRead;
        #Physical: Selected; 
        #Additional: Selected; 
        #Location: Selected; 
        #Misc: Selected; 
        #Financials: Selected; 
        #MonthlyRent: Selected;
        #UpdateResults : {selected: Selected; conditional: {#All; #Err; #Ok}};
        #Listings: ConditionalBaseRead<ListingConditionals>;
        #Refunds: NestedConditionalRead<{#All; #Ok; #Err}>;
        #CollectionIds: Selected;
    };

    public type ReadArg = {
        properties: Properties;
        filterProperties: ?FilterProperties;
    };

    public type FilterProperties = {
        location: ?Text;
        nftPriceMin: ?Nat;
        nftPriceMax: ?Nat;
        houseValueMin: ?Nat;
        houseValueMax: ?Nat;
        typeOfProperty: ?{#Terraced; #Semi; #Detached};
        beds: ?[Nat];
        saved: ?Account;
        monthlyRentMin: ?Float;
    };

    public type PropertyResult<T> = {
      propertyId: Nat;
      result: {
        #Ok: [ElementResult<T>];
        #Err: ReadErrors; //invalid property etc
      };
    };

    public type ReadOutcome<T> = {
        #Ok: T; 
        #Err: ReadErrors;
    };

    public type ElementResult<T> = {
      id: Nat; //element id
      value: {
        #Ok: T; //in the case of nested element - they contain their own id - therefore id above is always of parent
        #Err: ReadErrors; // e.g. #EmptyArray, #InvalidElementId, etc.
      };
    };

    public type ReadHandler<T> = {
        toEl: Property -> [(Nat, T)]; //if elements are nested this returns top elements id, then array of nested elements either in form [(Nat, NestedType)] or [NestType] - if later struct includes id 
        filter: ?(((Nat, T), ?[Int]) -> (Nat, T)); //for filtering nested elements
        cond: T -> ReadOutcome<T>; //for filtering top level elements
    };

    public type SimpleReadHandler<T> = {
        toEl: Property -> T;
        cond: T -> ReadOutcome<T>;
    };


    public type ReadResult = {
        #Image: [PropertyResult<Text>];
        #Document: [PropertyResult<Document>];
        #Note: [PropertyResult<Note>];
        #Insurance: [PropertyResult<InsurancePolicy>];
        #Valuation: [PropertyResult<ValuationRecord>];
        #Tenants: [PropertyResult<Tenant>];
        #Maintenance: [PropertyResult<MaintenanceRecord>];
        #Inspection: [PropertyResult<InspectionRecord>];
        #PaymentHistory: [PropertyResult<[Payment]>];
        #Physical: [ElementResult<PhysicalDetails>]; 
        #Additional: [ElementResult<AdditionalDetails>]; 
        #Location: [ElementResult<LocationDetails>]; 
        #Misc: [ElementResult<Miscellaneous>]; 
        #Financials: [ElementResult<Financials>]; 
        #MonthlyRent: [ElementResult<Nat>];
        #UpdateResults: [ElementResult<[Result]>];
        #Listings : [PropertyResult<Listing>];
        #Refunds: [PropertyResult<[Refund]>];
        #NFTs: [ElementResult<[Nat]>];
        #CollectionIds : [ElementResult<Principal>];
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
        #Images: Actions<Text, (Text, Nat)>;
        #Description : Text;
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

    public type FinancialIntentResult = IntentResult<FinancialIntentAction>;

    public type UpdateResult = {
        #Ok: Property; 
        #Err : UpdateError;
    };

    public type UpdateResultNat = {
        #Ok: Nat; 
        #Err : UpdateError;
    };

    //Marketplace structs
    public type NFTMarketplace = {
        collectionId: Principal;
        listId: Nat;
        listings: [(Nat, Listing)];
        royalty : Nat;
    };

    public type Ref = {
        id: Nat;
        from: Account;
        to: Account;
        amount: Nat;
        attempted_at: Int;
        result: GenericTransferResult;
    };

    public type Listing = {
        #LaunchedProperty: Launch;
        #LaunchFixedPrice: FixedPrice;
        #CancelledLaunch: CancelledFixedPrice;
        #SoldLaunchFixedPrice: SoldFixedPrice;
        #LiveFixedPrice: FixedPrice;
        #SoldFixedPrice: SoldFixedPrice;
        #CancelledFixedPrice: CancelledFixedPrice;
        #LiveAuction: Auction;
        #SoldAuction: SoldAuction;
        #CancelledAuction: CancelledAuction;
    };

    public type Launch = {
        id: Nat;
        seller: Account;
        caller: Principal;
        tokenIds: [Nat];
        args: [(Nat, Listing)];
        maxListed: Nat;
        listedAt: Int;
        price: Nat;
        quoteAsset: AcceptedCryptos;
    };

    public type LaunchArg = {
        transferType: {#TransferFrom; #Transfer};
        maxListed: ?Nat;
        price: Nat;
        endsAt: ?Int;
        from_subaccount: ?Blob;
        seller_subaccount: ?Blob;
        quoteAsset: ?AcceptedCryptos;
    };

    public type MarketplaceOptions = {
        #PropertyLaunch;
        #SoldLaunchFixedPrice;
        #LaunchFixedPrice;
        #CancelledLaunch;
        #LiveFixedPrice;
        #SoldFixedPrice;
        #CancelledFixedPrice;
        #LiveAuction;
        #SoldAuction;
        #CancelledAuction;
    };

    public type BaseListing = {
        id: Nat;
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
        bid: Bid;
        royaltyBps: ?Nat; // Basis points, e.g. 250 = 2.5%
    };

    public type CancelledFixedPrice = FixedPrice and {
        cancelledBy: Account;
        cancelledAt: Int;
        reason: CancelledReason;
    };

    public type Refund = {
        #Err: Ref;
        #Ok: Ref;
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
        refunds: [Refund];
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
        #ReserveNotMet;
        #NoBids;
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
        #LaunchProperty: LaunchArg;
        #UpdateLaunch: FixedPriceUArg;
        #CreateFixedListing : FixedPriceCArg;
        #UpdateFixedListing: FixedPriceUArg;
        #CreateAuctionListing : AuctionCArg;
        #UpdateAuctionListing: AuctionUArg;
        #Bid: BidArg;
        #CancelListing: CancelArg;
    };

    public type LaunchProperty = {
        propertyId: Nat;
        price: Nat;
        endsAt: ?Int;
        quoteAsset: ?AcceptedCryptos;
    };

    public type MarketplaceIntent = Intent<Listing>;
    public type MarketplaceIntentResult = IntentResult<MarketplaceIntent>;

//    //////Transfering NFTs
    public type TransferFromResult = {
        #Ok : Nat; // Transaction index for successful transfer
        #Err : TransferFromError;
    };

    public type TransferFromArg = {
        spender_subaccount: ?Blob; // The subaccount of the caller (used to identify the spender) - essentially equivalent to from_subaccount
        from : Account;
        to : Account;
        token_id : Nat;
        memo : ?Blob;
        created_at_time : ?Nat64;
    };

    public type TransferArg = {
        token_id : Nat;
        from_subaccount : ?Blob;
        memo: ?Blob;
        created_at_time: ?Nat64;
        to: Account;
    };

    public type TransferResult = {
        #Ok : Nat; // Transaction index for successful transfer
        #Err : TransferError;
    };
}