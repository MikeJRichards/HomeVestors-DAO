import Types "../types";
module TestTypes {
    type What = Types.What;
    type Property = Types.Property;
    type UpdateResult = Types.UpdateResult;

    public type Callers = {
        anon: Principal;
        tenant1: Principal;
        tenant2: Principal;
        admin: Principal;
    };
    type Cases<C, U> = {
        #Create: C;
        #Update: U;
        #Delete: DeleteCase;
    };

    public type TestCase = {
        #Note: Cases<NoteCreateCase, NoteUpdateCase>;
        #Insurance: Cases<InsuranceCreateCase, InsuranceUpdateCase>;
        #Documents: Cases<DocumentCreateCase, DocumentUpdateCase>;
        #Tenant: Cases<TenantCreateCase, TenantUpdateCase>;
        #Maintenance: Cases<MaintenanceCreateCase, MaintenanceUpdateCase>;
        #Inspection: Cases<InspectionCreateCase, InspectionUpdateCase>;
        #Valuation: Cases<ValuationCreateCase, ValuationUpdateCase>;
        #Images: Cases<ImageCreateCase, ImageUpdateCase>;
        #Description: DescriptionCase;
        #Financials: FinancialsCreateCase;
        #MonthlyRent: MonthlyRentCreateCase;
        #PhysicalDetails : PhysicalDetailsTestCase;
        #AdditionalDetails : AdditionalDetailsTestCase;
    };

    public type TestOptions = {
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