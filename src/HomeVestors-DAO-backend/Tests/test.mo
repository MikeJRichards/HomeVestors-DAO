import Types "../types";
import TestTypes "testTypes";
import TProp "createProperty";
import Buffer "mo:base/Buffer";
import Prop "../property";
import Debug "mo:base/Debug";
import Stables "stables";
import TestCases "testCases";
import Caller "caller";

module Test {
    type What = Types.What;
    type Arg = Types.Arg;
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


      func createTestOptions(): TestOptions {
        {
            auctionCreate = [];
            auctionUpdate = [];
            fixedPriceCreate = [];
            fixedPriceUpdate = [];
            launchCreate = [];
            launchUpdate = [];

            noteCreate = [#EmptyTitle, #EmptyContent, #FutureDate,#Valid, #Valid, #AnonymousAuthor];
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


    public func runTests(arg: TestOption, handlePropertyUpdate: (Types.WhatWithPropertyId, Principal) -> async Types.UpdateResult): async () {
        let testCases = createTestCases(arg);

        var property = TProp.createBlankProperty();
        for(test in testCases.vals()){
            Debug.print("NEW TEST STARTED");
           // Debug.print("Notes Id"#debug_show(property.administrative.notesId));
            let stableProperty = Stables.toStableProperty(property);
            let testType = TestCases.createTestCase(test, property);
            let arg: Types.Arg = {
                what = testType.arg; 
                caller = Caller.getCaller(test); 
                property = stableProperty; 
                handlePropertyUpdate; 
                testing = true;
            };
            let result = await Prop.updateProperty(arg);
     
            if(testType.expectedOutcome == result){
                Debug.print("✅ results match on "#debug_show(testType.name))
            }
            else {
                let mismatchExplanation : Text = switch (result, testType.expectedOutcome) {
                  case (#Ok(actual), #Ok(expected)) {
                    Debug.print("🧪 Entered Ok/Ok comparison");
                    formatMismatchedSectionsExpected(actual, expected, stableProperty);
                  };
                  case (#Ok(actual), #Err(expected)) {
                    Debug.print("🧪 Entered Ok/Err comparison");
                    let safeExpected = debug_show(expected);
                    let safeActual = formatMismatchedSections(actual, Stables.toStableProperty(property));
                    "expected: " # safeExpected # "\n Actual result: " # safeActual;
                  };
                  case (_) {
                    Debug.print("🧪 Entered fallback case");
                    "expected: " # debug_show(testType.expectedOutcome) # "\n actual result: " # debug_show(result);
                  };
                };
                Debug.print(
                  "❌ results didn't match on " # debug_show(testType.name) # "\n" #
                  "args were: " # debug_show(testType.arg) # "\n" #
                  mismatchExplanation
                );
                switch(result){
                    case(#Ok(updatedProperty)) property := Stables.fromStableProperty(updatedProperty);
                    case(_){};
                };
                //Debug.print(
                //    "❌ results didn't match on " # debug_show(testType.name) # "\n" #
                //    "args were: " # debug_show(testType.arg) # "\n" #
                //    (switch (result, testType.expectedOutcome) {
                //        case (#Ok(actual), #Ok(expected)) formatMismatchedSectionsExpected(actual, expected);
                //        case (#Ok(actual), _) "expected:  " # debug_show(testType.expectedOutcome) # " actual result: " # formatMismatchedSections(actual, Stables.toStableProperty(property));
                //        case (_) "expected:  " # debug_show(testType.expectedOutcome) # " actual result: " # debug_show(result);
                //    })
                //);
            }
        };
    };

    func formatMismatchedSectionsExpected(actual: Types.Property, expected: Types.Property, previously: Types.Property): Text {
        var output = "";
        if(actual.details.location != expected.details.location) output #= "🔸 MISMATCH in details location:\n  previous:" #debug_show(previously.details.location) #"\n Expected: " # debug_show(expected.details.location) # "\n  actual: " # debug_show(actual.details.location) # "\n";
        if(actual.details.physical != expected.details.physical) output #= "🔸 MISMATCH in details physical:\n  previous:" #debug_show(previously.details.physical) # "\n Expected:" # debug_show(expected.details.physical) # "\n  actual: " # debug_show(actual.details.physical) # "\n";
        if(actual.details.additional != expected.details.additional) output #= "🔸 MISMATCH in details additional:\n  previous:" #debug_show(previously.details.additional) # "\n  expected: " # debug_show(expected.details.additional) # "\n  actual: " # debug_show(actual.details.additional) # "\n";
        if(actual.details.misc != expected.details.misc) output #= "🔸 MISMATCH in details misc:\n  previous:" #debug_show(previously.details.misc) # "\n  expected: " # debug_show(expected.details.misc) # "\n  actual: " # debug_show(actual.details.misc) # "\n";
        if(actual.financials.account != expected.financials.account) output #= "🔸 MISMATCH in financials account:\n  previous:" #debug_show(previously.financials.account) # "\n  expected: " # debug_show(expected.financials.account) # "\n  actual: " # debug_show(actual.financials.account) # "\n";
        if(actual.financials.investment != expected.financials.investment) output #= "🔸 MISMATCH in financials investment:\n  previous:" #debug_show(previously.financials.investment) # "\n  expected: " # debug_show(expected.financials.investment) # "\n  actual: " # debug_show(actual.financials.investment) # "\n";
        if(actual.financials.pricePerSqFoot != expected.financials.pricePerSqFoot) output #= "🔸 MISMATCH in financials pricePerSqFoot:\n  previous:" #debug_show(previously.financials.pricePerSqFoot) # "\n  expected: " # debug_show(expected.financials.pricePerSqFoot) # "\n  actual: " # debug_show(actual.financials.pricePerSqFoot) # "\n";
        if(actual.financials.valuationId != expected.financials.valuationId) output #= "🔸 MISMATCH in financials valuationId:\n  previous:" #debug_show(previously.financials.valuationId) # "\n  expected: " # debug_show(expected.financials.valuationId) # "\n  actual: " # debug_show(actual.financials.valuationId) # "\n";
        if(actual.financials.valuations != expected.financials.valuations) output #= "🔸 MISMATCH in financials valuations:\n  previous:" #debug_show(previously.financials.valuations) # "\n  expected: " # debug_show(expected.financials.valuations) # "\n  actual: " # debug_show(actual.financials.valuations) # "\n";
        if(actual.financials.invoiceId != expected.financials.invoiceId) output #= "🔸 MISMATCH in financials invoiceId:\n  previous:" #debug_show(previously.financials.invoiceId) # "\n  expected: " # debug_show(expected.financials.invoiceId) # "\n  actual: " # debug_show(actual.financials.invoiceId) # "\n";
        if(actual.financials.invoices != expected.financials.invoices) output #= "🔸 MISMATCH in financials invoices:\n  previous:" #debug_show(previously.financials.invoices) # "\n  expected: " # debug_show(expected.financials.invoices) # "\n  actual: " # debug_show(actual.financials.invoices) # "\n";
        if(actual.financials.monthlyRent != expected.financials.monthlyRent) output #= "🔸 MISMATCH in financials monthlyRent:\n  previous:" #debug_show(previously.financials.monthlyRent) # "\n  expected: " # debug_show(expected.financials.monthlyRent) # "\n  actual: " # debug_show(actual.financials.monthlyRent) # "\n";
        if(actual.financials.yield != expected.financials.yield) output #= "🔸 MISMATCH in financials yield:\n  previous:" #debug_show(previously.financials.yield) # "\n  expected: " # debug_show(expected.financials.yield) # "\n  actual: " # debug_show(actual.financials.yield) # "\n";
        if(actual.financials.currentValue != expected.financials.currentValue) output #= "🔸 MISMATCH in financials currentValue:\n  previous:" #debug_show(previously.financials.currentValue) # "\n  expected: " # debug_show(expected.financials.currentValue) # "\n  actual: " # debug_show(actual.financials.currentValue) # "\n";
        if(actual.administrative.documentId != expected.administrative.documentId) output #= "🔸 MISMATCH in administrative documentId:\n  previous:" #debug_show(previously.administrative.documentId) # "\n  expected: " # debug_show(expected.administrative.documentId) # "\n  actual: " # debug_show(actual.administrative.documentId) # "\n";
        if(actual.administrative.insuranceId != expected.administrative.insuranceId) output #= "🔸 MISMATCH in administrative insuranceId:\n  previous:" #debug_show(previously.administrative.insuranceId) # "\n  expected: " # debug_show(expected.administrative.insuranceId) # "\n  actual: " # debug_show(actual.administrative.insuranceId) # "\n";
        if(actual.administrative.notesId != expected.administrative.notesId) output #= "🔸 MISMATCH in administrative notesId:\n  previous:" #debug_show(previously.administrative.notesId) # "\n  expected: " # debug_show(expected.administrative.notesId) # "\n  actual: " # debug_show(actual.administrative.notesId) # "\n";
        if(actual.administrative.insurance != expected.administrative.insurance) output #= "🔸 MISMATCH in administrative insurance:\n  previous:" #debug_show(previously.administrative.insurance) # "\n  expected: " # debug_show(expected.administrative.insurance) # "\n  actual: " # debug_show(actual.administrative.insurance) # "\n";
        if(actual.administrative.documents != expected.administrative.documents) output #= "🔸 MISMATCH in administrative documents:\n  previous:" #debug_show(previously.administrative.documents) # "\n  expected: " # debug_show(expected.administrative.documents) # "\n  actual: " # debug_show(actual.administrative.documents) # "\n";
        if(actual.administrative.notes != expected.administrative.notes) output #= "🔸 MISMATCH in administrative notes:\n  previous:" #debug_show(previously.administrative.notes) # "\n  expected: " # debug_show(expected.administrative.notes) # "\n  actual: " # debug_show(actual.administrative.notes) # "\n";
        if(actual.operational.tenantId != expected.operational.tenantId) output #= "🔸 MISMATCH in operational tenantId:\n  previous:" #debug_show(previously.operational.tenantId) # "\n  expected: " # debug_show(expected.operational.tenantId) # "\n  actual: " # debug_show(actual.operational.tenantId) # "\n";
        if(actual.operational.maintenanceId != expected.operational.maintenanceId) output #= "🔸 MISMATCH in operational maintenanceId:\n  previous:" #debug_show(previously.operational.maintenanceId) # "\n  expected: " # debug_show(expected.operational.maintenanceId) # "\n  actual: " # debug_show(actual.operational.maintenanceId) # "\n";
        if(actual.operational.inspectionsId != expected.operational.inspectionsId) output #= "🔸 MISMATCH in operational inspectionsId:\n  previous:" #debug_show(previously.operational.inspectionsId) # "\n  expected: " # debug_show(expected.operational.inspectionsId) # "\n  actual: " # debug_show(actual.operational.inspectionsId) # "\n";
        if(actual.operational.tenants != expected.operational.tenants) output #= "🔸 MISMATCH in operational tenants:\n  previous:" #debug_show(previously.operational.tenants) # "\n  expected: " # debug_show(expected.operational.tenants) # "\n  actual: " # debug_show(actual.operational.tenants) # "\n";
        if(actual.operational.maintenance != expected.operational.maintenance) output #= "🔸 MISMATCH in operational maintenance:\n  previous:" #debug_show(previously.operational.maintenance) # "\n  expected: " # debug_show(expected.operational.maintenance) # "\n  actual: " # debug_show(actual.operational.maintenance) # "\n";
        if(actual.nftMarketplace.collectionId != expected.nftMarketplace.collectionId) output #= "🔸 MISMATCH in nftMarketplace collectionId:\n  previous:" #debug_show(previously.nftMarketplace.collectionId) # "\n  expected: " # debug_show(expected.nftMarketplace.collectionId) # "\n  actual: " # debug_show(actual.nftMarketplace.collectionId) # "\n";
        if(actual.nftMarketplace.listId != expected.nftMarketplace.listId) output #= "🔸 MISMATCH in nftMarketplace listId:\n  previous:" #debug_show(previously.nftMarketplace.listId) # "\n  expected: " # debug_show(expected.nftMarketplace.listId) # "\n  actual: " # debug_show(actual.nftMarketplace.listId) # "\n";
        if(actual.nftMarketplace.listings != expected.nftMarketplace.listings) output #= "🔸 MISMATCH in nftMarketplace listings:\n  previous:" #debug_show(previously.nftMarketplace.listings) # "\n  expected: " # debug_show(expected.nftMarketplace.listings) # "\n  actual: " # debug_show(actual.nftMarketplace.listings) # "\n";
        if(actual.nftMarketplace.timerIds != expected.nftMarketplace.timerIds) output #= "🔸 MISMATCH in nftMarketplace timerIds:\n  previous:" #debug_show(previously.nftMarketplace.timerIds) # "\n  expected: " # debug_show(expected.nftMarketplace.timerIds) # "\n  actual: " # debug_show(actual.nftMarketplace.timerIds) # "\n";
        if(actual.nftMarketplace.royalty != expected.nftMarketplace.royalty) output #= "🔸 MISMATCH in nftMarketplace royalty:\n  previous:" #debug_show(previously.nftMarketplace.royalty) # "\n  expected: " # debug_show(expected.nftMarketplace.royalty) # "\n  actual: " # debug_show(actual.nftMarketplace.royalty) # "\n";
        if(actual.governance.proposalId != expected.governance.proposalId) output #= "🔸 MISMATCH in governance proposalId:\n  previous:" #debug_show(previously.governance.proposalId) # "\n  expected: " # debug_show(expected.governance.proposalId) # "\n  actual: " # debug_show(actual.governance.proposalId) # "\n";
        if(actual.governance.proposals != expected.governance.proposals) output #= "🔸 MISMATCH in governance proposals:\n  previous:" #debug_show(previously.governance.proposals) # "\n  expected: " # debug_show(expected.governance.proposals) # "\n  actual: " # debug_show(actual.governance.proposals) # "\n";
        if(actual.governance.assetCost != expected.governance.assetCost) output #= "🔸 MISMATCH in governance assetCost:\n  previous:" #debug_show(previously.governance.assetCost) # "\n  expected: " # debug_show(expected.governance.assetCost) # "\n  actual: " # debug_show(actual.governance.assetCost) # "\n";
        if(actual.governance.proposalCost != expected.governance.proposalCost) output #= "🔸 MISMATCH in governance proposalCost:\n  previous:" #debug_show(previously.governance.proposalCost) # "\n  expected: " # debug_show(expected.governance.proposalCost) # "\n  actual: " # debug_show(actual.governance.proposalCost) # "\n";
        if(actual.governance.requireNftToPropose != expected.governance.requireNftToPropose) output #= "🔸 MISMATCH in governance requireNftToPropose:\n  previous:" #debug_show(previously.governance.requireNftToPropose) # "\n  expected: " # debug_show(expected.governance.requireNftToPropose) # "\n  actual: " # debug_show(actual.governance.requireNftToPropose) # "\n";
        if(actual.governance.minYesVotes != expected.governance.minYesVotes) output #= "🔸 MISMATCH in governance minYesVotes:\n  previous:" #debug_show(previously.governance.minYesVotes) # "\n  expected: " # debug_show(expected.governance.minYesVotes) # "\n  actual: " # debug_show(actual.governance.minYesVotes) # "\n";
        if(actual.governance.minTurnout != expected.governance.minTurnout) output #= "🔸 MISMATCH in governance minTurnout:\n  previous:" #debug_show(previously.governance.minTurnout) # "\n  expected: " # debug_show(expected.governance.minTurnout) # "\n  actual: " # debug_show(actual.governance.minTurnout) # "\n";
        if(actual.governance.quorumPercentage != expected.governance.quorumPercentage) output #= "🔸 MISMATCH in governance quorumPercentage:\n  previous:" #debug_show(previously.governance.quorumPercentage) # "\n  expected: " # debug_show(expected.governance.quorumPercentage) # "\n  actual: " # debug_show(actual.governance.quorumPercentage) # "\n";
        if(actual.updates != expected.updates) output #= "🔸 MISMATCH in updates:\n  previous:" #debug_show(expected.updates) # "\n  expected: " # debug_show(previously.updates) # "\n  actual: " # debug_show(actual.updates) # "\n";
 
        //if (actual.details != expected.details) output #= "🔸 MISMATCH in details:\n  expected: " # debug_show(expected.details) # "\n  actual: " # debug_show(actual.details) # "\n";
//
        //if (actual.administrative != expected.administrative)
        //    output #= "🔸 MISMATCH in administrative:\n  expected: " # debug_show(expected.administrative) # "\n  actual: " # debug_show(actual.administrative) # "\n";
//
        //if (actual.financials != expected.financials)
        //    output #= "🔸 MISMATCH in financials:\n  expected: " # debug_show(expected.financials) # "\n  actual: " # debug_show(actual.financials) # "\n";
//
        //if (actual.operational != expected.operational)
        //    output #= "🔸 MISMATCH in operational:\n  expected: " # debug_show(expected.operational) # "\n  actual: " # debug_show(actual.operational) # "\n";
//
        //if (actual.nftMarketplace != expected.nftMarketplace)
        //    output #= "🔸 MISMATCH in nftMarketplace:\n  expected: " # debug_show(expected.nftMarketplace) # "\n  actual: " # debug_show(actual.nftMarketplace) # "\n";
        //
        //if(output.size() == 0) return debug_show(actual);
        output;
    };

    func formatMismatchedSections(actual: Types.Property, expected: Types.Property): Text {
        var output = "";
        if(actual.details.location != expected.details.location) output #= "🔸 MISMATCH in details location:\n  expected: " # debug_show(expected.details.location) # "\n  actual: " # debug_show(actual.details.location) # "\n";
        if(actual.details.physical != expected.details.physical) output #= "🔸 MISMATCH in details physical:\n  expected: " # debug_show(expected.details.physical) # "\n  actual: " # debug_show(actual.details.physical) # "\n";
        if(actual.details.additional != expected.details.additional) output #= "🔸 MISMATCH in details additional:\n  expected: " # debug_show(expected.details.additional) # "\n  actual: " # debug_show(actual.details.additional) # "\n";
        if(actual.details.misc != expected.details.misc) output #= "🔸 MISMATCH in details misc:\n  expected: " # debug_show(expected.details.misc) # "\n  actual: " # debug_show(actual.details.misc) # "\n";
        if(actual.financials.account != expected.financials.account) output #= "🔸 MISMATCH in financials account:\n  expected: " # debug_show(expected.financials.account) # "\n  actual: " # debug_show(actual.financials.account) # "\n";
        if(actual.financials.investment != expected.financials.investment) output #= "🔸 MISMATCH in financials investment:\n  expected: " # debug_show(expected.financials.investment) # "\n  actual: " # debug_show(actual.financials.investment) # "\n";
        if(actual.financials.pricePerSqFoot != expected.financials.pricePerSqFoot) output #= "🔸 MISMATCH in financials pricePerSqFoot:\n  expected: " # debug_show(expected.financials.pricePerSqFoot) # "\n  actual: " # debug_show(actual.financials.pricePerSqFoot) # "\n";
        if(actual.financials.valuationId != expected.financials.valuationId) output #= "🔸 MISMATCH in financials valuationId:\n  expected: " # debug_show(expected.financials.valuationId) # "\n  actual: " # debug_show(actual.financials.valuationId) # "\n";
        if(actual.financials.valuations != expected.financials.valuations) output #= "🔸 MISMATCH in financials valuations:\n  expected: " # debug_show(expected.financials.valuations) # "\n  actual: " # debug_show(actual.financials.valuations) # "\n";
        if(actual.financials.invoiceId != expected.financials.invoiceId) output #= "🔸 MISMATCH in financials invoiceId:\n  expected: " # debug_show(expected.financials.invoiceId) # "\n  actual: " # debug_show(actual.financials.invoiceId) # "\n";
        if(actual.financials.invoices != expected.financials.invoices) output #= "🔸 MISMATCH in financials invoices:\n  expected: " # debug_show(expected.financials.invoices) # "\n  actual: " # debug_show(actual.financials.invoices) # "\n";
        if(actual.financials.monthlyRent != expected.financials.monthlyRent) output #= "🔸 MISMATCH in financials monthlyRent:\n  expected: " # debug_show(expected.financials.monthlyRent) # "\n  actual: " # debug_show(actual.financials.monthlyRent) # "\n";
        if(actual.financials.yield != expected.financials.yield) output #= "🔸 MISMATCH in financials yield:\n  expected: " # debug_show(expected.financials.yield) # "\n  actual: " # debug_show(actual.financials.yield) # "\n";
        if(actual.financials.currentValue != expected.financials.currentValue) output #= "🔸 MISMATCH in financials currentValue:\n  expected: " # debug_show(expected.financials.currentValue) # "\n  actual: " # debug_show(actual.financials.currentValue) # "\n";
        if(actual.administrative.documentId != expected.administrative.documentId) output #= "🔸 MISMATCH in administrative documentId:\n  expected: " # debug_show(expected.administrative.documentId) # "\n  actual: " # debug_show(actual.administrative.documentId) # "\n";
        if(actual.administrative.insuranceId != expected.administrative.insuranceId) output #= "🔸 MISMATCH in administrative insuranceId:\n  expected: " # debug_show(expected.administrative.insuranceId) # "\n  actual: " # debug_show(actual.administrative.insuranceId) # "\n";
        if(actual.administrative.notesId != expected.administrative.notesId) output #= "🔸 MISMATCH in administrative notesId:\n  expected: " # debug_show(expected.administrative.notesId) # "\n  actual: " # debug_show(actual.administrative.notesId) # "\n";
        if(actual.administrative.insurance != expected.administrative.insurance) output #= "🔸 MISMATCH in administrative insurance:\n  expected: " # debug_show(expected.administrative.insurance) # "\n  actual: " # debug_show(actual.administrative.insurance) # "\n";
        if(actual.administrative.documents != expected.administrative.documents) output #= "🔸 MISMATCH in administrative documents:\n  expected: " # debug_show(expected.administrative.documents) # "\n  actual: " # debug_show(actual.administrative.documents) # "\n";
        if(actual.administrative.notes != expected.administrative.notes) output #= "🔸 MISMATCH in administrative notes:\n  expected: " # debug_show(expected.administrative.notes) # "\n  actual: " # debug_show(actual.administrative.notes) # "\n";
        if(actual.operational.tenantId != expected.operational.tenantId) output #= "🔸 MISMATCH in operational tenantId:\n  expected: " # debug_show(expected.operational.tenantId) # "\n  actual: " # debug_show(actual.operational.tenantId) # "\n";
        if(actual.operational.maintenanceId != expected.operational.maintenanceId) output #= "🔸 MISMATCH in operational maintenanceId:\n  expected: " # debug_show(expected.operational.maintenanceId) # "\n  actual: " # debug_show(actual.operational.maintenanceId) # "\n";
        if(actual.operational.inspectionsId != expected.operational.inspectionsId) output #= "🔸 MISMATCH in operational inspectionsId:\n  expected: " # debug_show(expected.operational.inspectionsId) # "\n  actual: " # debug_show(actual.operational.inspectionsId) # "\n";
        if(actual.operational.tenants != expected.operational.tenants) output #= "🔸 MISMATCH in operational tenants:\n  expected: " # debug_show(expected.operational.tenants) # "\n  actual: " # debug_show(actual.operational.tenants) # "\n";
        if(actual.operational.maintenance != expected.operational.maintenance) output #= "🔸 MISMATCH in operational maintenance:\n  expected: " # debug_show(expected.operational.maintenance) # "\n  actual: " # debug_show(actual.operational.maintenance) # "\n";
        if(actual.nftMarketplace.collectionId != expected.nftMarketplace.collectionId) output #= "🔸 MISMATCH in nftMarketplace collectionId:\n  expected: " # debug_show(expected.nftMarketplace.collectionId) # "\n  actual: " # debug_show(actual.nftMarketplace.collectionId) # "\n";
        if(actual.nftMarketplace.listId != expected.nftMarketplace.listId) output #= "🔸 MISMATCH in nftMarketplace listId:\n  expected: " # debug_show(expected.nftMarketplace.listId) # "\n  actual: " # debug_show(actual.nftMarketplace.listId) # "\n";
        if(actual.nftMarketplace.listings != expected.nftMarketplace.listings) output #= "🔸 MISMATCH in nftMarketplace listings:\n  expected: " # debug_show(expected.nftMarketplace.listings) # "\n  actual: " # debug_show(actual.nftMarketplace.listings) # "\n";
        if(actual.nftMarketplace.timerIds != expected.nftMarketplace.timerIds) output #= "🔸 MISMATCH in nftMarketplace timerIds:\n  expected: " # debug_show(expected.nftMarketplace.timerIds) # "\n  actual: " # debug_show(actual.nftMarketplace.timerIds) # "\n";
        if(actual.nftMarketplace.royalty != expected.nftMarketplace.royalty) output #= "🔸 MISMATCH in nftMarketplace royalty:\n  expected: " # debug_show(expected.nftMarketplace.royalty) # "\n  actual: " # debug_show(actual.nftMarketplace.royalty) # "\n";
        if(actual.governance.proposalId != expected.governance.proposalId) output #= "🔸 MISMATCH in governance proposalId:\n  expected: " # debug_show(expected.governance.proposalId) # "\n  actual: " # debug_show(actual.governance.proposalId) # "\n";
        if(actual.governance.proposals != expected.governance.proposals) output #= "🔸 MISMATCH in governance proposals:\n  expected: " # debug_show(expected.governance.proposals) # "\n  actual: " # debug_show(actual.governance.proposals) # "\n";
        if(actual.governance.assetCost != expected.governance.assetCost) output #= "🔸 MISMATCH in governance assetCost:\n  expected: " # debug_show(expected.governance.assetCost) # "\n  actual: " # debug_show(actual.governance.assetCost) # "\n";
        if(actual.governance.proposalCost != expected.governance.proposalCost) output #= "🔸 MISMATCH in governance proposalCost:\n  expected: " # debug_show(expected.governance.proposalCost) # "\n  actual: " # debug_show(actual.governance.proposalCost) # "\n";
        if(actual.governance.requireNftToPropose != expected.governance.requireNftToPropose) output #= "🔸 MISMATCH in governance requireNftToPropose:\n  expected: " # debug_show(expected.governance.requireNftToPropose) # "\n  actual: " # debug_show(actual.governance.requireNftToPropose) # "\n";
        if(actual.governance.minYesVotes != expected.governance.minYesVotes) output #= "🔸 MISMATCH in governance minYesVotes:\n  expected: " # debug_show(expected.governance.minYesVotes) # "\n  actual: " # debug_show(actual.governance.minYesVotes) # "\n";
        if(actual.governance.minTurnout != expected.governance.minTurnout) output #= "🔸 MISMATCH in governance minTurnout:\n  expected: " # debug_show(expected.governance.minTurnout) # "\n  actual: " # debug_show(actual.governance.minTurnout) # "\n";
        if(actual.governance.quorumPercentage != expected.governance.quorumPercentage) output #= "🔸 MISMATCH in governance quorumPercentage:\n  expected: " # debug_show(expected.governance.quorumPercentage) # "\n  actual: " # debug_show(actual.governance.quorumPercentage) # "\n";
        if(actual.updates != expected.updates) output #= "🔸 MISMATCH in updates:\n  expected: " # debug_show(expected.updates) # "\n  actual: " # debug_show(actual.updates) # "\n";
 //
 //       if (actual.details != expected.details)
 //           output #= "🔸 MISMATCH in details:\n  actual: " # debug_show(actual.details) # "\n";
//
 //       if (actual.administrative != expected.administrative)
 //           output #= "🔸 MISMATCH in administrative:\n  actual: " # debug_show(actual.administrative) # "\n";
//
 //       if (actual.financials != expected.financials)
 //           output #= "🔸 MISMATCH in financials:\n  actual: " # debug_show(actual.financials) # "\n";
//
 //       if (actual.operational != expected.operational)
 //           output #= "🔸 MISMATCH in operational:\n  actual: " # debug_show(actual.operational) # "\n";
//
 //       if (actual.nftMarketplace != expected.nftMarketplace)
 //           output #= "🔸 MISMATCH in nftMarketplace:\n  actual: " # debug_show(actual.nftMarketplace) # "\n";

        output;
    };




}