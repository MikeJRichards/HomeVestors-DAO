import TestTypes "testTypes";
import Types "../types";
import Prop "createProperty";
import Utils "utils";
import Arg "createArgs";
import Time "mo:base/Time";

module {
    type TestCase = TestTypes.TestCase;
    type TestType = TestTypes.TestType;
    type NoteCreateCase = TestTypes.NoteCreateCase;
    type NoteUpdateCase = TestTypes.NoteUpdateCase;
    type InsuranceCreateCase = TestTypes.InsuranceCreateCase;
    type InsuranceUpdateCase = TestTypes.InsuranceUpdateCase;
    type DocumentCreateCase = TestTypes.DocumentCreateCase;
    type DocumentUpdateCase = TestTypes.DocumentUpdateCase;
    type TenantCreateCase = TestTypes.TenantCreateCase;
    type TenantUpdateCase = TestTypes.TenantUpdateCase;
    type MaintenanceCreateCase = TestTypes.MaintenanceCreateCase;
    type MaintenanceUpdateCase = TestTypes.MaintenanceUpdateCase;
    type InspectionCreateCase = TestTypes.InspectionCreateCase;
    type InspectionUpdateCase = TestTypes.InspectionUpdateCase;
    type ValuationCreateCase = TestTypes.ValuationCreateCase;
    type ValuationUpdateCase = TestTypes.ValuationUpdateCase;
    type FinancialsCreateCase = TestTypes.FinancialsCreateCase;
    type MonthlyRentCreateCase = TestTypes.MonthlyRentCreateCase;
    type PhysicalDetailsUpdateCase = TestTypes.PhysicalDetailsTestCase;
    type AdditionalDetailsUpdateCase = TestTypes.AdditionalDetailsTestCase;
    type InsurancePolicyCArg = Types.InsurancePolicyCArg;
    type InsurancePolicyUArg = Types.InsurancePolicyUArg;
    type DocumentCArg = Types.DocumentCArg;
    type DocumentUArg = Types.DocumentUArg;
    type NoteCArg = Types.NoteCArg;
    type NoteUArg = Types.NoteUArg;
    type MaintenanceRecordCArg = Types.MaintenanceRecordCArg;
    type MaintenanceRecordUArg = Types.MaintenanceRecordUArg;
    type InspectionRecordCArg = Types.InspectionRecordCArg;
    type InspectionRecordUArg = Types.InspectionRecordUArg;
    type TenantCArg = Types.TenantCArg;
    type TenantUArg = Types.TenantUArg;
    type ValuationRecordCArg = Types.ValuationRecordCArg;
    type ValuationRecordUArg = Types.ValuationRecordUArg;
    type FixedPriceCArg = Types.FixedPriceCArg;
    type FixedPriceUArg = Types.FixedPriceUArg;
    type AuctionCArg = Types.AuctionCArg;
    type AuctionUArg = Types.AuctionUArg;
    type BidArg = Types.BidArg;
    type CancelArg = Types.CancelArg;
    type FinancialsArg = Types.FinancialsArg;
    type PhysicalDetails = Types.PhysicalDetails;
    type AdditionalDetails = Types.AdditionalDetails;
    type What = Types.What;



    type DeleteCase = TestTypes.DeleteCase;

    public func createNoteTestCaseArg(tcase: NoteCreateCase): NoteCArg {
        let arg = Arg.createNoteCArg();
        switch(tcase){
            case(#Valid or #AnonymousAuthor) arg;
            case(#EmptyTitle) return {arg with title = ""};
            case(#EmptyContent) return {arg with content = ""};
            case(#FutureDate) return {arg with date = ?Utils.daysInFuture(7)};
        };
    };

    public func updateNoteTestCaseArg(tcase: NoteUpdateCase): (NoteUArg, Nat) {
        let arg = Arg.createNoteUArg();
        switch(tcase){
            case(#Valid) (arg, 0);
            case(#NonExistentId) (arg, 10);
            case(#EmptyTitle) ({arg with title = ?""}, 0);
            case(#NullTitle) ({arg with title = null}, 0);
            case(#EmptyContent) ({arg with content = ?""}, 0);
            case(#NullContent) ({arg with content = null}, 0);
            case(#FutureDate) ({arg with date = ?Utils.daysInFuture(7)}, 0);
        }
    };

    public func createInsuranceTestCaseArg(tcase: InsuranceCreateCase): InsurancePolicyCArg {
        let arg = Arg.createInsurancePolicyCArg();
        switch(tcase){
            case(#Valid) arg;
            case(#EmptyPolicyNumber) return { arg with policyNumber = "" };
            case(#EmptyProvider) return { arg with provider = "" };
            case(#EndDateInPast) return { arg with endDate = ?(Time.now() - 1_000_000) };
            case(#PremiumZero) return { arg with premium = 0 };
            case(#NextPaymentInPast) return { arg with nextPaymentDate = Time.now() - 1_000_000 };
            case(#EmptyContactInfo) return { arg with contactInfo = "" };
        };
    };

    public func updateInsuranceTestCaseArg(tcase: InsuranceUpdateCase): (InsurancePolicyUArg, Nat) {
        let arg = Arg.createInsurancePolicyUArg();
        switch(tcase){
            case(#Valid) (arg, 0);
            case(#NonExistentId) (arg, 10);
            case(#EmptyProvider) return ({ arg with provider = ?"" }, 0);
            case(#PremiumZero) return ({ arg with premium = ?0 }, 0);
        };
    };

    public func createDocumentTestCaseArg(tcase: DocumentCreateCase): DocumentCArg {
        let arg = Arg.createDocumentCArg();
        switch(tcase){
            case(#Valid) arg;
            case(#EmptyTitle) return { arg with title = "" };
            case(#EmptyDescription) return { arg with description = "" };
            case(#EmptyURL) return { arg with url = "" };
        };
    };
    
    public func updateDocumentTestCaseArg(tcase: DocumentUpdateCase): (DocumentUArg, Nat) {
        let arg = Arg.createDocumentUArg();
        switch(tcase){
            case(#Valid) (arg, 0);
            case(#NonExistentId) (arg, 10);
            case(#EmptyTitle) ({ arg with title = ?"" }, 0);
            case(#EmptyDescription) ({ arg with description = ?"" }, 0);
        };
    };


    // Tenant
    public func createTenantTestCaseArg(tcase: TenantCreateCase): TenantCArg {
        let arg = Arg.createTenantCArg();
        switch (tcase) {
            case (#Valid) arg;
            case (#EmptyLeadTenant) return { arg with leadTenant = "" };
            case (#ZeroMonthlyRent) return { arg with monthlyRent = 0 };
            case (#ZeroDeposit) return { arg with deposit = 0 };
            case (#StartDateInPast) return { arg with leaseStartDate = Time.now() - 1 };
        };
    };

    public func updateTenantTestCaseArg(tcase: TenantUpdateCase): (TenantUArg, Nat) {
        let arg = Arg.createTenantUArg();
        switch (tcase) {
            case (#Valid) (arg, 0);
            case (#NonExistentId) (arg, 10);
            case (#EmptyLeadTenant) ({ arg with leadTenant = ?"" }, 0);
            case (#ZeroMonthlyRent) ({ arg with monthlyRent = ?0 }, 0);
            case (#ZeroDeposit) ({ arg with deposit = ?0 }, 0);
            case (#StartDateInPast) ({ arg with leaseStartDate = ?(Time.now() - 1) }, 0);
        };
    };

    // Maintenance
    public func createMaintenanceTestCaseArg(tcase: MaintenanceCreateCase): MaintenanceRecordCArg {
        let arg = Arg.createMaintenanceRecordCArg();
        switch (tcase) {
            case (#Valid) arg;
            case (#EmptyDescription) return { arg with description = "" };
            case (#DateCompletedInFuture) return { arg with dateCompleted = ?(Time.now() + 1) };
            case (#DateReportedInFuture) return { arg with dateReported = ?(Time.now() + 1) };
        };
    };

    public func updateMaintenanceTestCaseArg(tcase: MaintenanceUpdateCase): (MaintenanceRecordUArg, Nat) {
        let arg = Arg.createMaintenanceRecordUArg();
        switch (tcase) {
            case (#Valid) (arg, 0);
            case (#NonExistentId) (arg, 10);
            case (#EmptyDescription) ({ arg with description = ?"" }, 0);
            case (#DateCompletedInFuture) ({ arg with dateCompleted = ?(Time.now() + 1) }, 0);
            case (#DateReportedInFuture) ({ arg with dateReported = ?(Time.now() + 1) }, 0);
        };
    };

    // Inspection
    public func createInspectionTestCaseArg(tcase: InspectionCreateCase): InspectionRecordCArg {
        let arg = Arg.createInspectionRecordCArg();
        switch (tcase) {
            case (#Valid) arg;
            case (#EmptyInspectorName) return { arg with inspectorName = "" };
            case (#EmptyFindings) return { arg with findings = "" };
            case (#DateInFuture) return { arg with date = ?(Time.now() + 1) };
        };
    };

    public func updateInspectionTestCaseArg(tcase: InspectionUpdateCase): (InspectionRecordUArg, Nat) {
        let arg = Arg.createInspectionRecordUArg();
        switch (tcase) {
            case (#Valid) (arg, 0);
            case (#NonExistentId) (arg, 10);
            case (#EmptyInspectorName) ({ arg with inspectorName = ?"" }, 0);
            case (#EmptyFindings) ({ arg with findings = ?"" }, 0);
            case (#DateInFuture) ({ arg with date = ?(Time.now() + 1) }, 0);
        };
    };

    public func createMonthlyRentTestCaseArg(tcase: MonthlyRentCreateCase): Nat {
        switch (tcase) {
            case (#Valid) 1000;
            case (#ZeroRent) 0;
        };
    };

    public func createFinancialsTestCaseArg(tcase: FinancialsCreateCase): FinancialsArg {
        let arg = Arg.createFinancialsArg();
        switch (tcase) {
            case (#Valid) arg;
            case (#ZeroCurrentValue) return { arg with currentValue = 0 };
        };
    };

    public func createValuationTestCaseArg(tcase: ValuationCreateCase): ValuationRecordCArg {
        let arg = Arg.createValuationRecordCArg();
        switch (tcase) {
            case (#Valid) arg;
            case (#ZeroValue) return { arg with value = 0 };
        };
    };

    public func updateValuationTestCaseArg(tcase: ValuationUpdateCase): (ValuationRecordUArg, Nat) {
        let arg = Arg.createValuationRecordUArg();
        switch (tcase) {
            case (#Valid) (arg, 0);
            case (#NonExistentId) (arg, 10);
            case (#ZeroValue) ({ arg with value = ?0 }, 0);
        };
    };

    public func createPhysicalDetailsTestCaseArg(tcase: PhysicalDetailsUpdateCase): PhysicalDetails {
        let arg = Prop.createPhysicalDetails();
        switch (tcase) {
            case (#Valid) arg;
            case (#RenovationTooOld) return { arg with lastRenovation = 1890 };
            case (#TooManyBeds) return { arg with beds = 11 };
            case (#TooManyBaths) return { arg with baths = 11 };
        };
    };

    public func createAdditionalDetailsTestCaseArg(tcase: AdditionalDetailsUpdateCase): AdditionalDetails {
        let arg = Prop.createAdditionalDetails();
        switch (tcase) {
            case (#Valid) arg;
            case (#LowCrimeScore) return { arg with crimeScore = 10 };
            case (#HighSchoolScore) return { arg with schoolScore = 11 };
        };
    };

    type ImageCreateCase = TestTypes.ImageCreateCase;
    type ImageUpdateCase = TestTypes.ImageUpdateCase;
    type DescriptionCase = TestTypes.DescriptionCase;
    public func createImageTestCaseArg(tcase: ImageCreateCase): Text {
        switch (tcase) {
            case (#Valid) "initial url to image";
            case (#EmptyURL) "";
        };
    };

    public func updateImageTestCaseArg(tcase: ImageUpdateCase): (Text, Nat) {
        switch (tcase) {
            case (#Valid) ("updated url to image",0);
            case (#EmptyURL) ("",0);
        };
    };

    public func descriptionTestCaseArg(tcase: DescriptionCase): Text {
        switch (tcase) {
            case (#Valid) "updated description of property";
            case (#Empty) "";
        };
    };




    public func createDeleteCase(tcase: DeleteCase): Nat {
        switch(tcase){
            case(#Valid) 0;
            case(#NonExistentId) 10;
        }
    };

    public func createWhat(tcases: TestCase): What {
        switch (tcases) {
            // NOTE
            case (#Note(#Create(arg))) {
                #Note(#Create(createNoteTestCaseArg(arg)));
            };
            case (#Note(#Update(arg))) {
                #Note(#Update(updateNoteTestCaseArg(arg)));
            };
            case (#Note(#Delete(arg))) {
                #Note(#Delete(createDeleteCase(arg)));
            };

            // INSURANCE
            case (#Insurance(#Create(arg))) {
                #Insurance(#Create(createInsuranceTestCaseArg(arg)));
            };
            case (#Insurance(#Update(arg))) {
                #Insurance(#Update(updateInsuranceTestCaseArg(arg)));
            };
            case (#Insurance(#Delete(arg))) {
                #Insurance(#Delete(createDeleteCase(arg)));
            };

            // DOCUMENTS
            case (#Documents(#Create(arg))) {
                #Document(#Create(createDocumentTestCaseArg(arg)));
            };
            case (#Documents(#Update(arg))) {
                #Document(#Update(updateDocumentTestCaseArg(arg)));
            };
            case (#Documents(#Delete(arg))) {
                #Document(#Delete(createDeleteCase(arg)));
            };

            // TENANT
            case (#Tenant(#Create(arg))) {
                #Tenant(#Create(createTenantTestCaseArg(arg)));
            };
            case (#Tenant(#Update(arg))) {
                #Tenant(#Update(updateTenantTestCaseArg(arg)));
            };
            case (#Tenant(#Delete(arg))) {
                #Tenant(#Delete(createDeleteCase(arg)));
            };

            // MAINTENANCE
            case (#Maintenance(#Create(arg))) {
                #Maintenance(#Create(createMaintenanceTestCaseArg(arg)));
            };
            case (#Maintenance(#Update(arg))) {
                #Maintenance(#Update(updateMaintenanceTestCaseArg(arg)));
            };
            case (#Maintenance(#Delete(arg))) {
                #Maintenance(#Delete(createDeleteCase(arg)));
            };

            // INSPECTION
            case (#Inspection(#Create(arg))) {
                #Inspection(#Create(createInspectionTestCaseArg(arg)));
            };
            case (#Inspection(#Update(arg))) {
                #Inspection(#Update(updateInspectionTestCaseArg(arg)));
            };
            case (#Inspection(#Delete(arg))) {
                #Inspection(#Delete(createDeleteCase(arg)));
            };

             case (#Financials(arg)) {
                #Financials(createFinancialsTestCaseArg(arg));
            };

            // MONTHLY RENT
            case (#MonthlyRent(arg)) {
                #MonthlyRent(createMonthlyRentTestCaseArg(arg));
            };

            // VALUATION
            case (#Valuation(#Create(arg))) {
                #Valuations(#Create(createValuationTestCaseArg(arg)));
            };
            case (#Valuation(#Update(arg))) {
                #Valuations(#Update(updateValuationTestCaseArg(arg)));
            };
            case (#Valuation(#Delete(arg))) {
                #Valuations(#Delete(createDeleteCase(arg)));
            };

            case(#Images(#Create(arg))){
                #Images(#Create(createImageTestCaseArg(arg)));
            };
            case(#Images(#Update(arg))){
                #Images(#Update(updateImageTestCaseArg(arg)));
            };
            case(#Images(#Delete(arg))){
                #Images(#Delete(createDeleteCase(arg)));
            };

            case(#Description(arg)){
                #Description(descriptionTestCaseArg(arg));
            };

            case (#PhysicalDetails(arg)) {
                #PhysicalDetails(createPhysicalDetailsTestCaseArg(arg));
            };

            // ADDITIONAL DETAILS
            case (#AdditionalDetails(arg)) {
                #AdditionalDetails(createAdditionalDetailsTestCaseArg(arg));
            };
        };
    };

}