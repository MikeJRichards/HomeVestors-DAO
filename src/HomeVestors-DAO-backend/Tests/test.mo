import Types "../types";
import TestTypes "testTypes";
import UnstableTypes "unstableTypes";
import TProp "createProperty";
import Buffer "mo:base/Buffer";
import Prop "../property";
import Debug "mo:base/Debug";
import Stables "stables";
import TestCases "testCases";
import ExpectedOutcomes "expectedOutcomes";
import Caller "caller";

module Test {
    type What = Types.What;
    type Callers = TestTypes.Callers;
    type TestCase = TestTypes.TestCase;
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
    type TestOptions = TestTypes.TestOptions;
    type TestOption = TestTypes.TestOption;
    type TestType = TestTypes.TestType;

    public func createTestType(tcases: TestCase): TestType {
        {
            name = tcases;
            arg = TestCases.createWhat(tcases);
            expectedOutcome = ExpectedOutcomes.createExpectedOutcome(tcases);
        }
    };

      func createTestOptions(): TestOptions {
        {
            noteCreate = [#Valid, #EmptyTitle, #EmptyContent, #FutureDate, #AnonymousAuthor];
            noteUpdate = [#Valid, #NonExistentId, #EmptyTitle, #NullTitle, #EmptyContent, #NullContent, #FutureDate];
            insuranceCreate = [#Valid, #EmptyPolicyNumber, #EmptyProvider, #EndDateInPast, #PremiumZero, #NextPaymentInPast, #EmptyContactInfo];
            insuranceUpdate = [#Valid, #NonExistentId, #EmptyProvider, #PremiumZero];
            documentCreate = [#Valid, #EmptyTitle, #EmptyDescription, #EmptyURL];
            documentUpdate = [#Valid, #NonExistentId, #EmptyTitle, #EmptyDescription];
            tenantCreate = [#Valid, #EmptyLeadTenant, #ZeroMonthlyRent, #ZeroDeposit, #StartDateInPast];
            tenantUpdate = [#Valid, #NonExistentId, #EmptyLeadTenant, #ZeroMonthlyRent, #ZeroDeposit, #StartDateInPast];
            maintenanceCreate = [#Valid, #EmptyDescription, #DateCompletedInFuture, #DateReportedInFuture];
            maintenanceUpdate = [#Valid, #NonExistentId, #EmptyDescription, #DateCompletedInFuture, #DateReportedInFuture];
            inspectionCreate = [#Valid, #EmptyInspectorName, #EmptyFindings, #DateInFuture];
            inspectionUpdate = [#Valid, #NonExistentId, #EmptyInspectorName, #EmptyFindings, #DateInFuture];
            valuationCreate = [#Valid, #ZeroValue];
            valuationUpdate = [#Valid, #NonExistentId, #ZeroValue];
            financialsCreate = [#Valid, #ZeroCurrentValue];
            monthlyRentCreate = [#Valid, #ZeroRent];
            physicalDetailsUpdate = [#Valid, #RenovationTooOld, #TooManyBeds, #TooManyBaths];
            additionalDetailsUpdate = [#Valid, #LowCrimeScore, #HighSchoolScore];
            imagesCreate = [#Valid, #EmptyURL];
            imagesUpdate = [#Valid, #EmptyURL];
            descriptionUpdate = [#Valid, #Empty];
            delete = [#Valid, #NonExistentId];
        }
    };

    func createTestCases(arg: TestOption): [TestCase] {
        let testOptions = createTestOptions();
        let testCases = Buffer.Buffer<TestCase>(0);

        switch (arg) {
            case (#NoteCreate) for (c in testOptions.noteCreate.vals()) { testCases.add(#Note(#Create(c))) };
            case (#NoteUpdate) for (u in testOptions.noteUpdate.vals()) { testCases.add(#Note(#Update(u))) };
            case (#NoteDelete) for (d in testOptions.delete.vals()) { testCases.add(#Note(#Delete(d))) };

            case (#InsuranceCreate) for (c in testOptions.insuranceCreate.vals()) { testCases.add(#Insurance(#Create(c))) };
            case (#InsuranceUpdate) for (u in testOptions.insuranceUpdate.vals()) { testCases.add(#Insurance(#Update(u))) };
            case (#InsuranceDelete) for (d in testOptions.delete.vals()) { testCases.add(#Insurance(#Delete(d))) };

            case (#DocumentCreate) for (c in testOptions.documentCreate.vals()) { testCases.add(#Documents(#Create(c))) };
            case (#DocumentUpdate) for (u in testOptions.documentUpdate.vals()) { testCases.add(#Documents(#Update(u))) };
            case (#DocumentDelete) for (d in testOptions.delete.vals()) { testCases.add(#Documents(#Delete(d))) };

            case (#TenantCreate) for (c in testOptions.tenantCreate.vals()) { testCases.add(#Tenant(#Create(c))) };
            case (#TenantUpdate) for (u in testOptions.tenantUpdate.vals()) { testCases.add(#Tenant(#Update(u))) };
            case (#TenantDelete) for (d in testOptions.delete.vals()) { testCases.add(#Tenant(#Delete(d))) };

            case (#MaintenanceCreate) for (c in testOptions.maintenanceCreate.vals()) { testCases.add(#Maintenance(#Create(c))) };
            case (#MaintenanceUpdate) for (u in testOptions.maintenanceUpdate.vals()) { testCases.add(#Maintenance(#Update(u))) };
            case (#MaintenanceDelete) for (d in testOptions.delete.vals()) { testCases.add(#Maintenance(#Delete(d))) };

            case (#InspectionCreate) for (c in testOptions.inspectionCreate.vals()) { testCases.add(#Inspection(#Create(c))) };
            case (#InspectionUpdate) for (u in testOptions.inspectionUpdate.vals()) { testCases.add(#Inspection(#Update(u))) };
            case (#InspectionDelete) for (d in testOptions.delete.vals()) { testCases.add(#Inspection(#Delete(d))) };

            case (#ValuationCreate) for (c in testOptions.valuationCreate.vals()) { testCases.add(#Valuation(#Create(c))) };
            case (#ValuationUpdate) for (u in testOptions.valuationUpdate.vals()) { testCases.add(#Valuation(#Update(u))) };
            case (#ValuationDelete) for (d in testOptions.delete.vals()) { testCases.add(#Valuation(#Delete(d))) };

            case (#ImagesCreate) for (c in testOptions.imagesCreate.vals()) { testCases.add(#Images(#Create(c))) };
            case (#ImagesUpdate) for (u in testOptions.imagesUpdate.vals()) { testCases.add(#Images(#Update(u))) };
            case (#ImagesDelete) for (d in testOptions.delete.vals()) { testCases.add(#Images(#Delete(d))) };
            
            case (#DescriptionUpdate) for (u in testOptions.descriptionUpdate.vals()) { testCases.add(#Description(u)) };
            
            case (#FinancialsCreate) for (c in testOptions.financialsCreate.vals()) { testCases.add(#Financials(c)) };

            case (#MonthlyRentCreate) for (c in testOptions.monthlyRentCreate.vals()) { testCases.add(#MonthlyRent(c)) };
            case (#PhysicalDetailsUpdate) for (u in testOptions.physicalDetailsUpdate.vals()) {     testCases.add(#PhysicalDetails(u)); };

            case (#AdditionalDetailsUpdate) for (u in testOptions.additionalDetailsUpdate.vals()) {testCases.add(#AdditionalDetails(u)); };
            case (#All) {
                for (c in testOptions.noteCreate.vals()) testCases.add(#Note(#Create(c)));
                for (u in testOptions.noteUpdate.vals()) testCases.add(#Note(#Update(u)));
                for (d in testOptions.delete.vals()) testCases.add(#Note(#Delete(d)));

                for (c in testOptions.insuranceCreate.vals()) testCases.add(#Insurance(#Create(c)));
                for (u in testOptions.insuranceUpdate.vals()) testCases.add(#Insurance(#Update(u)));
                for (d in testOptions.delete.vals()) testCases.add(#Insurance(#Delete(d)));

                for (c in testOptions.documentCreate.vals()) testCases.add(#Documents(#Create(c)));
                for (u in testOptions.documentUpdate.vals()) testCases.add(#Documents(#Update(u)));
                for (d in testOptions.delete.vals()) testCases.add(#Documents(#Delete(d)));

                for (c in testOptions.tenantCreate.vals()) testCases.add(#Tenant(#Create(c)));
                for (u in testOptions.tenantUpdate.vals()) testCases.add(#Tenant(#Update(u)));
                for (d in testOptions.delete.vals()) testCases.add(#Tenant(#Delete(d)));

                for (c in testOptions.maintenanceCreate.vals()) testCases.add(#Maintenance(#Create(c)));
                for (u in testOptions.maintenanceUpdate.vals()) testCases.add(#Maintenance(#Update(u)));
                for (d in testOptions.delete.vals()) testCases.add(#Maintenance(#Delete(d)));

                for (c in testOptions.inspectionCreate.vals()) testCases.add(#Inspection(#Create(c)));
                for (u in testOptions.inspectionUpdate.vals()) testCases.add(#Inspection(#Update(u)));
                for (d in testOptions.delete.vals()) testCases.add(#Inspection(#Delete(d)));

                for (c in testOptions.valuationCreate.vals()) testCases.add(#Valuation(#Create(c)));
                for (u in testOptions.valuationUpdate.vals()) testCases.add(#Valuation(#Update(u)));
                for (d in testOptions.delete.vals()) testCases.add(#Valuation(#Delete(d)));

                for (c in testOptions.financialsCreate.vals()) testCases.add(#Financials(c));
                for (c in testOptions.monthlyRentCreate.vals()) testCases.add(#MonthlyRent(c));
                for (u in testOptions.physicalDetailsUpdate.vals()) testCases.add(#PhysicalDetails(u));
                for (u in testOptions.additionalDetailsUpdate.vals()) testCases.add(#AdditionalDetails(u));
                
                for (c in testOptions.imagesCreate.vals()) { testCases.add(#Images(#Create(c))) };
                for (u in testOptions.imagesUpdate.vals()) { testCases.add(#Images(#Update(u))) };
                for (d in testOptions.delete.vals()) { testCases.add(#Images(#Delete(d))) };

                for (u in testOptions.descriptionUpdate.vals()) { testCases.add(#Description(u)) };
            
            };
        };
        Buffer.toArray(testCases);
    };


type Arg = UnstableTypes.Arg;
    public func runTests(arg: TestOption): async () {
        let testCases = createTestCases(arg);
        for(test in testCases.vals()){
            let testType = createTestType(test);
            let property = TProp.createBlankProperty();
            let result = await Prop.updateProperty(testType.arg, Caller.getCaller(test), Stables.toStableProperty(property));
            if(testType.expectedOutcome == result){
                Debug.print("✅ results match on "#debug_show(testType.name))
            }
            else {
                Debug.print("❌ results didn't match on "#debug_show(testType.name)#" args were "#debug_show(testType.arg)#" expected result was "#debug_show(testType.expectedOutcome)#" Actual result was "#debug_show(result));
            }
        };
    };





}