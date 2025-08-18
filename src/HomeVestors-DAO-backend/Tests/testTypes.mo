import Types "../types";
import UnstableTypes "unstableTypes";
module TestTypes {
    type What = Types.What;
    type Property = Types.Property;
    type PropertyUnstable = UnstableTypes.PropertyUnstable;
    type UpdateResult = Types.UpdateResult;

    public type TestHandler<CT, UT, DT, C, U> = {
      tcase: Cases<CT, UT, DT>;
      wrapAction: Types.Actions<C , U> -> What;
      createArg: CT -> C;
      createExpected: (C, CT) -> Types.UpdateResult;
      updateArg: UT -> (U, [Int]);
      updateExpected: (UT, (U, [Int])) -> Types.UpdateResult;
      deleteArg: DT -> Nat;
      deleteExpected: (DT, What) -> Types.UpdateResult;
    };

    public type Callers = {
        anon: Principal;
        tenant1: Principal;
        tenant2: Principal;
        admin: Principal;
    };
    public type Cases<C, U, DT> = {
        #Create: C;
        #Update: U;
        #Delete: DT;
    };

    public type LaunchTestCase = Cases<LaunchCreateCase, LaunchUpdateCase, DeleteCase>;
    public type FixedPriceTestCase = Cases<FixedPriceCreateCase, FixedPriceUpdateCase, DeleteCase>;
    public type AuctionTestCase = Cases<AuctionCreateCase, AuctionUpdateCase, DeleteCase>;
    public type ProposalTestCase = Cases<ProposalCreateCase, ProposalUpdateCase, DeleteCase>;
    public type InvoiceTestCase = Cases<InvoiceCreateCase, InvoiceUpdateCase, DeleteCase>;
    public type NoteTestCase = Cases<NoteCreateCase, NoteUpdateCase, DeleteCase>;
    public type InsuranceTestCase = Cases<InsuranceCreateCase, InsuranceUpdateCase, DeleteCase>;
    public type DocumentsTestCase = Cases<DocumentCreateCase, DocumentUpdateCase, DeleteCase>;
    public type TenantTestCase = Cases<TenantCreateCase, TenantUpdateCase, DeleteCase>;
    public type MaintenanceTestCase = Cases<MaintenanceCreateCase, MaintenanceUpdateCase, DeleteCase>;
    public type InspectionTestCase = Cases<InspectionCreateCase, InspectionUpdateCase, DeleteCase>;
    public type ValuationTestCase = Cases<ValuationCreateCase, ValuationUpdateCase, DeleteCase>;
    public type ImagesTestCase = Cases<ImageCreateCase, ImageUpdateCase, DeleteCase>;

    public type TestCase = {
      //#NFTMarketplace: {
      //  #Launch: LaunchTestCase;
      //  #FixedPrice: FixedPriceTestCase;
      //  #Auction: AuctionTestCase;
      //};
      //#Proposal: ProposalTestCase;
      //#Invoice: InvoiceTestCase;
      #Note: NoteTestCase;
      #Insurance: InsuranceTestCase;
      #Documents: DocumentsTestCase;
      #Tenant: TenantTestCase;
      #Maintenance: MaintenanceTestCase;
      #Inspection: InspectionTestCase;
      #Valuation: ValuationTestCase;
      #Images: ImagesTestCase;
      #Description: DescriptionCase;
      #Financials: FinancialsCreateCase;
      #MonthlyRent: MonthlyRentCreateCase;
      #PhysicalDetails : PhysicalDetailsTestCase;
      #AdditionalDetails : AdditionalDetailsTestCase;
    };

    public type TestOptions = {
      fixedPriceCreate: [FixedPriceCreateCase];
      fixedPriceUpdate: [FixedPriceUpdateCase];
      auctionCreate: [AuctionCreateCase];
      auctionUpdate: [AuctionUpdateCase];
      launchCreate: [LaunchCreateCase];
      launchUpdate: [LaunchUpdateCase];
      noteCreate: [NoteCreateCase];
      noteUpdate: [NoteUpdateCase];
      insuranceCreate: [InsuranceCreateCase];
      insuranceUpdate: [InsuranceUpdateCase];
      documentCreate: [DocumentCreateCase];
      documentUpdate: [DocumentUpdateCase];
      tenantCreate: [TenantCreateCase];
      tenantUpdate: [TenantUpdateCase];
      maintenanceCreate: [MaintenanceCreateCase];
      maintenanceUpdate: [MaintenanceUpdateCase];
      inspectionCreate: [InspectionCreateCase];
      inspectionUpdate: [InspectionUpdateCase];
      valuationCreate: [ValuationCreateCase];
      valuationUpdate: [ValuationUpdateCase];
      financialsCreate: [FinancialsCreateCase];
      monthlyRentCreate: [MonthlyRentCreateCase];
      physicalDetailsUpdate: [PhysicalDetailsTestCase];
      additionalDetailsUpdate: [AdditionalDetailsTestCase];
      imagesCreate: [ImageCreateCase];
      imagesUpdate: [ImageUpdateCase];
      descriptionUpdate: [DescriptionCase];
      delete: [DeleteCase];
    };

    public type TestOption = {
      //#NFTMarketplaceFixedPriceCreate;
      //#NFTMarketplaceFixedPriceUpdate;
      //#NFTMarketplaceFixedPriceDelete;
      //#NFTMarketplaceAuctionCreate;
      //#NFTMarketplaceAuctionUpdate;
      //#NFTMarketplaceAuctionDelete;
      //#NFTMarketplaceLaunchCreate;
      //#NFTMarketplaceLaunchUpdate;
      //#NFTMarketplaceLaunchDelete;
      //#Bid;
      
      #NoteCreate;
      #NoteUpdate;
      #NoteDelete;
      #InsuranceCreate;
      #InsuranceUpdate;
      #InsuranceDelete;
      #DocumentCreate;
      #DocumentUpdate;
      #DocumentDelete;
      #TenantCreate;
      #TenantUpdate;
      #TenantDelete;
      #MaintenanceCreate;
      #MaintenanceUpdate;
      #MaintenanceDelete;
      #InspectionCreate;
      #InspectionUpdate;
      #InspectionDelete;
      #ValuationCreate;
      #ValuationUpdate;
      #ValuationDelete;
      #FinancialsCreate;
      #MonthlyRentCreate;
      #PhysicalDetailsUpdate;
      #AdditionalDetailsUpdate;
      #ImagesCreate;
      #ImagesUpdate;
      #ImagesDelete;
      #DescriptionUpdate;
      #All;
    };

    public type TestType = {
        name: TestCase;
        arg: What;
        expectedOutcome: UpdateResult;
    };

    public type FixedPriceCreateCase = {
      #Valid;
    };

    public type FixedPriceUpdateCase = {
      #Valid;
    };

    public type AuctionCreateCase = {
      #Valid;
    };

    public type AuctionUpdateCase = {
      #Valid;
    };
    
    public type LaunchCreateCase = {
      #Valid;
    };

    public type LaunchUpdateCase = {
      #Valid;
    };

    public type ProposalCreateCase = {
      #Valid;
    };

    public type ProposalUpdateCase = {
      #Valid;
    };

    public type InvoiceCreateCase = {
      #Valid;
    };

    public type InvoiceUpdateCase = {
      #Valid;
    };


    public type NoteCreateCase = {
      #Valid;
      #EmptyTitle;
      #EmptyContent;
      #FutureDate;
      #AnonymousAuthor;
    };

    public type ImageCreateCase = {
      #Valid;
      #EmptyURL;
    };

    public type ImageUpdateCase = {
      #Valid;
      #EmptyURL;
    };

    public type DescriptionCase = {
      #Valid;
      #Empty;
    };

    public type NoteUpdateCase = {
      #Valid;
      #NonExistentId;
      #EmptyTitle;
      #NullTitle;
      #EmptyContent;
      #NullContent;
      #FutureDate;
    };

    public type InsuranceCreateCase = {
      #Valid;
      #EmptyPolicyNumber;
      #EmptyProvider;
      #EndDateInPast;
      #PremiumZero;
      #NextPaymentInPast;
      #EmptyContactInfo;
    };

    public type InsuranceUpdateCase = {
      #Valid;
      #NonExistentId;
      #EmptyProvider;
      #PremiumZero;
    };

    public type DocumentCreateCase = {
      #Valid;
      #EmptyTitle;
      #EmptyDescription;
      #EmptyURL;
    };

    public type DocumentUpdateCase = {
      #Valid;
      #NonExistentId;
      #EmptyTitle;
      #EmptyDescription;
    };

    public type TenantCreateCase = {
      #Valid;
      #EmptyLeadTenant;
      #ZeroMonthlyRent;
      #ZeroDeposit;
      #StartDateInPast;
    };

    public type MaintenanceCreateCase = {
      #Valid;
      #EmptyDescription;
      #DateCompletedInFuture;
      #DateReportedInFuture;
    };

    public type InspectionCreateCase = {
      #Valid;
      #EmptyInspectorName;
      #EmptyFindings;
      #DateInFuture;
    };

    // Update Case Types
    public type TenantUpdateCase = {
      #Valid;
      #NonExistentId;
      #EmptyLeadTenant;
      #ZeroMonthlyRent;
      #ZeroDeposit;
      #StartDateInPast;
    };

    public type MaintenanceUpdateCase = {
      #Valid;
      #NonExistentId;
      #EmptyDescription;
      #DateCompletedInFuture;
      #DateReportedInFuture;
    };

    public type InspectionUpdateCase = {
      #Valid;
      #NonExistentId;
      #EmptyInspectorName;
      #EmptyFindings;
      #DateInFuture;
    };

    public type ValuationCreateCase = {
      #Valid;
      #ZeroValue;
    };

    public type ValuationUpdateCase = {
      #Valid;
      #NonExistentId;
      #ZeroValue;
    };

    // === Financials Test Cases (Create only) ===
    public type FinancialsCreateCase = {
      #Valid;
      #ZeroCurrentValue;
    };

    // === Monthly Rent Test Cases (Create only) ===
    public type MonthlyRentCreateCase = {
      #Valid;
      #ZeroRent;
    };

    public type PhysicalDetailsTestCase = {
        #Valid;
        #RenovationTooOld;
        #TooManyBeds;
        #TooManyBaths;
    };

    public type AdditionalDetailsTestCase = {
        #Valid;
        #LowCrimeScore;
        #HighSchoolScore;
    };

    public type DeleteCase = {
      #Valid;
      #NonExistentId;
    };

    


}