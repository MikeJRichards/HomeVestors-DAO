import Types "../types";
import TestTypes "testTypes";
import TestCases "testCases";
import UnstableTypes "unstableTypes";
import Prop "createProperty";
import Stables "stables";
import Float "mo:base/Float";
import Arg "createArgs";
import Utils "utils";

module {
     type UpdateResult = Types.UpdateResult;
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
    type DeleteCase = TestTypes.DeleteCase;
    type PropertyUnstable  = UnstableTypes.PropertyUnstable ;
    type ImageCreateCase = TestTypes.ImageCreateCase;
    type ImageUpdateCase = TestTypes.ImageUpdateCase;
    type DescriptionCase = TestTypes.DescriptionCase;


    func createNoteExpectedOutcome(tcase: NoteCreateCase): UpdateResult {
        let prop = Prop.createBlankProperty();
        switch(tcase){
            case (#AnonymousAuthor) return #Err(#InvalidData{field= "author"; reason = #Anonymous;});
            case(#EmptyTitle) return #Err(#InvalidData{field = "title"; reason = #EmptyString;});
            case(#EmptyContent) return #Err(#InvalidData{field = "content"; reason = #EmptyString;});
            case(#FutureDate) return #Err(#InvalidData({ field = "Upload Date"; reason = #CannotBeSetInTheFuture }));
            case(_) {
                let arg = TestCases.createNoteTestCaseArg(tcase);
                let note = Prop.validNote(1, arg);
                prop.administrative.notesId += 1;
                prop.administrative.notes.put(1, Stables.fromStableNote(note));
                prop.updates.add(#Ok(#Note(#Create(arg))));
            };
        };
        #Ok(Stables.toStableProperty(prop));
    };

    func updateNoteExpectedOutcome(tcase: NoteUpdateCase): UpdateResult {
        let prop = Prop.createBlankProperty();
        let arg = switch(tcase){
            case(#NonExistentId) return #Err(#InvalidElementId);
            case(#EmptyTitle) return #Err(#InvalidData{field = "title"; reason = #EmptyString;});
            case(#EmptyContent)  return #Err(#InvalidData{field = "content"; reason = #EmptyString;});
            case(#FutureDate) return #Err(#InvalidData({ field = "Upload Date"; reason = #CannotBeSetInTheFuture }));
            case(#NullContent)({Arg.createNoteUArg() with content = ?"This is a useful note about the property."}, 0); 
            case(#NullTitle) ({Arg.createNoteUArg() with title = ?"Initial Note"}, 0);
            case(_){
                TestCases.updateNoteTestCaseArg(tcase);
            };
        };
        let note = Prop.updatedNote(arg);
        prop.administrative.notes.put(0, Stables.fromStableNote(note));
        prop.updates.add(#Ok(#Note(#Update(TestCases.updateNoteTestCaseArg(tcase)))));  
        #Ok(Stables.toStableProperty(prop));
    };

    func createInsuranceExpectedOutcome(tcase: InsuranceCreateCase): UpdateResult {
        let prop = Prop.createBlankProperty();
        switch(tcase){
            case(#EmptyPolicyNumber) return #Err(#InvalidData{field = "policy Number"; reason = #EmptyString;});
            case(#EmptyProvider) return #Err(#InvalidData{field = "policy Provider"; reason = #EmptyString;});
            case(#EndDateInPast) return #Err(#InvalidData{field = "Insurance End Date"; reason = #CannotBeSetInThePast;});
            case(#PremiumZero) return #Err(#InvalidData{field = "Insurance Premium"; reason = #CannotBeZero});
            case(#NextPaymentInPast) return #Err(#InvalidData{field = "Next Payment Date"; reason = #CannotBeSetInThePast;});
            case(#EmptyContactInfo) return #Err(#InvalidData{field = "Contact Info"; reason = #EmptyString;});
            case(_){
                let arg = TestCases.createInsuranceTestCaseArg(tcase);
                let insurance = Prop.validInsurancePolicy(1, arg);
                prop.administrative.insuranceId += 1;
                prop.administrative.insurance.put(1, Stables.fromStableInsurancePolicy(insurance));
                prop.updates.add(#Ok(#Insurance(#Create(arg))));  
            }
        };
        #Ok(Stables.toStableProperty(prop));
    };

    func updateInsuranceExpectedOutcome(tcase: InsuranceUpdateCase): UpdateResult {
        let prop = Prop.createBlankProperty();
        switch(tcase){
            case(#NonExistentId) return #Err(#InvalidElementId);
            case(#EmptyProvider) return #Err(#InvalidData{field = "policy Provider"; reason = #EmptyString;});
            case(#PremiumZero) return #Err(#InvalidData{field = "Insurance Premium"; reason = #CannotBeZero});
            case(_) {
                let arg = TestCases.updateInsuranceTestCaseArg(tcase);
                let insurance = Prop.updateValidInsurancePolicy(arg);
                prop.administrative.insurance.put(0, Stables.fromStableInsurancePolicy(insurance));
                prop.updates.add(#Ok(#Insurance(#Update(arg)))); 
            }
        };
        #Ok(Stables.toStableProperty(prop));
    };

    func createDocumentExpectedOutcome(tcase: DocumentCreateCase): UpdateResult {
        let prop = Prop.createBlankProperty();
        switch(tcase){
            case(#EmptyTitle) return #Err(#InvalidData{field = "title"; reason = #EmptyString;});
            case(#EmptyDescription) return #Err(#InvalidData{field = "description"; reason = #EmptyString;});
            case(#EmptyURL) return #Err(#InvalidData{field = "URL"; reason = #EmptyString;});
            case(_) {
                let arg = TestCases.createDocumentTestCaseArg(tcase);
                let document = Prop.validDocument(1, arg);
                prop.administrative.documentId += 1;
                prop.administrative.documents.put(1, Stables.fromStableDocument(document));
                prop.updates.add(#Ok(#Document(#Create(arg)))); 
            }
        };
        #Ok(Stables.toStableProperty(prop));
    };

    func updateDocumentExpectedOutcome(tcase: DocumentUpdateCase): UpdateResult {
        let prop = Prop.createBlankProperty();
        switch(tcase){
            case(#NonExistentId) return #Err(#InvalidElementId);
            case(#EmptyTitle) return #Err(#InvalidData{field = "title"; reason = #EmptyString;});
            case(#EmptyDescription) return #Err(#InvalidData{field = "description"; reason = #EmptyString;});
            case(_) {
                let arg = TestCases.updateDocumentTestCaseArg(tcase);
                let document = Prop.updateValidDocument(arg);
                prop.administrative.documents.put(0, Stables.fromStableDocument(document));
                prop.updates.add(#Ok(#Document(#Update(arg)))); 
            }
        };
        #Ok(Stables.toStableProperty(prop));
    };

    func createTenantExpectedOutcome(tcase: TenantCreateCase): UpdateResult {
        let prop = Prop.createBlankProperty();
        switch(tcase) {
            case(#EmptyLeadTenant) return #Err(#InvalidData{field = "lead tenant"; reason = #EmptyString});
            case(#ZeroMonthlyRent) return #Err(#InvalidData{field = "monthly rent"; reason = #CannotBeZero});
            case(#ZeroDeposit) return #Err(#InvalidData{field = "deposit"; reason = #CannotBeZero});
            case(#StartDateInPast) return #Err(#InvalidData{field = "lease start date"; reason = #CannotBeSetInThePast});
            case(_) {
                let arg = TestCases.createTenantTestCaseArg(tcase);
                let tenant = Prop.createValidTenant(arg, 1);
                prop.operational.tenantId += 1;
                prop.operational.tenants.put(1, Stables.fromStableTenant(tenant));
                prop.updates.add(#Ok(#Tenant(#Create(arg)))); 
            }
        };
        #Ok(Stables.toStableProperty(prop));
    };

    func updateTenantExpectedOutcome(tcase: TenantUpdateCase): UpdateResult {
        let prop = Prop.createBlankProperty();
        switch(tcase) {
            case(#NonExistentId) return #Err(#InvalidElementId);
            case(#EmptyLeadTenant) return #Err(#InvalidData{field = "lead tenant"; reason = #EmptyString});
            case(#ZeroMonthlyRent) return #Err(#InvalidData{field = "monthly rent"; reason = #CannotBeZero});
            case(#ZeroDeposit) return #Err(#InvalidData{field = "deposit"; reason = #CannotBeZero});
            case(#StartDateInPast) return #Err(#InvalidData{field = "lease start date"; reason = #CannotBeSetInThePast});
            case(_) {
                let arg = TestCases.updateTenantTestCaseArg(tcase);
                let tenant = Prop.updateValidTenant(arg);
                prop.operational.tenants.put(0, Stables.fromStableTenant(tenant));
                prop.updates.add(#Ok(#Tenant(#Update(arg)))); 
            }
        };
        #Ok(Stables.toStableProperty(prop));
    };

    func createMaintenanceExpectedOutcome(tcase: MaintenanceCreateCase): UpdateResult {
        let prop = Prop.createBlankProperty();
        switch(tcase) {
            case(#EmptyDescription) return #Err(#InvalidData{field = "description"; reason = #EmptyString});
            case(#DateCompletedInFuture) return #Err(#InvalidData{field = "date completed"; reason = #CannotBeSetInTheFuture});
            case(#DateReportedInFuture) return #Err(#InvalidData{field = "date reported"; reason = #CannotBeSetInTheFuture});
            case(_){
                let arg = TestCases.createMaintenanceTestCaseArg(tcase);
                let maintenance = Prop.createValidMaintenanceRecord(arg, 1);
                prop.operational.maintenanceId += 1;
                prop.operational.maintenance.put(1, Stables.fromStableMaintenanceRecord(maintenance));
                prop.updates.add(#Ok(#Maintenance(#Create(arg)))); 
            }
        };
        #Ok(Stables.toStableProperty(prop));
    };

    func updateMaintenanceExpectedOutcome(tcase: MaintenanceUpdateCase): UpdateResult {
        let prop = Prop.createBlankProperty();
        switch(tcase) {
            case(#NonExistentId) return #Err(#InvalidElementId);
            case(#EmptyDescription) return #Err(#InvalidData{field = "description"; reason = #EmptyString});
            case(#DateCompletedInFuture) return #Err(#InvalidData{field = "date completed"; reason = #CannotBeSetInTheFuture});
            case(#DateReportedInFuture) return #Err(#InvalidData{field = "date reported"; reason = #CannotBeSetInTheFuture});
            case(_){
                let arg = TestCases.updateMaintenanceTestCaseArg(tcase);
                let maintenance = Prop.updateValidMaintenanceRecord(arg);
                prop.operational.maintenance.put(0, Stables.fromStableMaintenanceRecord(maintenance));
                prop.updates.add(#Ok(#Maintenance(#Update(arg)))); 
            }
        };
        #Ok(Stables.toStableProperty(prop));
    };

    func createImageExpectedOutcome(tcase: ImageCreateCase): UpdateResult {
        let prop = Prop.createBlankProperty();
        switch(tcase) {
            case(#EmptyURL) return #Err(#InvalidData{field = "image"; reason = #EmptyString});
            case(_){
                let arg = TestCases.createImageTestCaseArg(tcase);
                prop.details.misc.imageId += 1;
                prop.details.misc.images.put(1, "initial url to image");
                prop.updates.add(#Ok(#Images(#Create(arg)))); 
            }
        };
        #Ok(Stables.toStableProperty(prop));
    };

    func updateImageExpectedOutcome(tcase: ImageUpdateCase): UpdateResult {
        let prop = Prop.createBlankProperty();
        switch(tcase) {
            case(#EmptyURL) return #Err(#InvalidData{field = "image"; reason = #EmptyString});
            case(_){
                let arg = TestCases.updateImageTestCaseArg(tcase);
                prop.details.misc.images.put(0, "updated url to image");
                prop.updates.add(#Ok(#Images(#Update(arg)))); 
            }
        };
        #Ok(Stables.toStableProperty(prop));
    };

    func createInspectionExpectedOutcome(tcase: InspectionCreateCase): UpdateResult {
        let prop = Prop.createBlankProperty();
        switch(tcase) {
            case(#EmptyInspectorName) return #Err(#InvalidData{field = "inspector name"; reason = #EmptyString});
            case(#EmptyFindings) return #Err(#InvalidData{field = "findings"; reason = #EmptyString});
            case(#DateInFuture) return #Err(#InvalidData{field = "inspection date"; reason = #CannotBeSetInTheFuture});
            case(_){
                let arg = TestCases.createInspectionTestCaseArg(tcase);
                let inspection = Prop.createValidInspectionRecord(arg, 1);
                prop.operational.inspectionsId += 1;
                prop.operational.inspections.put(1, Stables.fromStableInspectionRecord(inspection));
                prop.updates.add(#Ok(#Inspection(#Create(arg)))); 
            }
        };
        #Ok(Stables.toStableProperty(prop));
    };

    func updateInspectionExpectedOutcome(tcase: InspectionUpdateCase): UpdateResult {
        let prop = Prop.createBlankProperty();
        switch(tcase) {
            case(#NonExistentId) return #Err(#InvalidElementId);
            case(#EmptyInspectorName) return #Err(#InvalidData{field = "inspector name"; reason = #EmptyString});
            case(#EmptyFindings) return #Err(#InvalidData{field = "findings"; reason = #EmptyString});
            case(#DateInFuture) return #Err(#InvalidData{field = "inspection date"; reason = #CannotBeSetInTheFuture});
            case(_){
                let arg = TestCases.updateInspectionTestCaseArg(tcase);
                let inspection = Prop.updateValidInspectionRecord(arg);
                prop.operational.inspections.put(0, Stables.fromStableInspectionRecord(inspection));
                prop.updates.add(#Ok(#Inspection(#Update(arg))));
            }
        };
        #Ok(Stables.toStableProperty(prop));
    };

    func createMonthlyRentExpectedOutcome(tcase: MonthlyRentCreateCase): UpdateResult {
        let prop = Prop.createBlankProperty();
        switch(tcase) {
            case (#Valid) prop.financials.monthlyRent := 1000;
            case (#ZeroRent) return #Err(#InvalidData{field = "Monthly Rent"; reason = #CannotBeZero});
        };
        prop.updates.add(#Ok(#MonthlyRent(1000)));
        prop.financials.yield := Float.fromInt(12 * prop.financials.monthlyRent) / Float.fromInt(prop.financials.currentValue);
        #Ok(Stables.toStableProperty(prop));
    };

    func createFinancialsExpectedOutcome(tcase: FinancialsCreateCase): UpdateResult {
        let prop = Prop.createBlankProperty();
        let arg = TestCases.createFinancialsTestCaseArg(tcase);
        switch(tcase) {
            case (#Valid) prop.financials.currentValue := arg.currentValue;
            case (#ZeroCurrentValue) return #Err(#InvalidData{field = "current value"; reason = #CannotBeZero});
        };
        prop.updates.add(#Ok(#Financials(arg)));
        prop.financials.pricePerSqFoot := prop.financials.currentValue / prop.details.physical.squareFootage;
        #Ok(Stables.toStableProperty(prop));
    };

    func createValuationExpectedOutcome(tcase: ValuationCreateCase): UpdateResult {
        let prop = Prop.createBlankProperty();
        switch(tcase) {
            case (#Valid) {
                let arg = TestCases.createValuationTestCaseArg(tcase);
                let valuation = Prop.createValidValuationRecord(arg, 1);
                prop.financials.valuationId += 1;
                prop.financials.valuations.put(1, Stables.fromStableValuationRecord(valuation));
                prop.updates.add(#Ok(#Valuations(#Create(arg))));
            };
            case (#ZeroValue) return #Err(#InvalidData{field = "value"; reason = #CannotBeZero});
        };
        #Ok(Stables.toStableProperty(prop));
    };

    func updateValuationExpectedOutcome(tcase: ValuationUpdateCase): UpdateResult {
        let prop = Prop.createBlankProperty();
        switch(tcase) {
            case (#NonExistentId) return #Err(#InvalidElementId);
            case (#ZeroValue) return #Err(#InvalidData{field = "value"; reason = #CannotBeZero});
            case (_){
                let arg = TestCases.updateValuationTestCaseArg(tcase);
                let valuation = Prop.updateValidValuationRecord(arg);
                prop.financials.valuations.put(0, Stables.fromStableValuationRecord(valuation));
                prop.updates.add(#Ok(#Valuations(#Update(arg))));
            }
        };
        #Ok(Stables.toStableProperty(prop));
    };

    func createPhysicalDetailsExpectedOutcome(tcase: PhysicalDetailsUpdateCase): UpdateResult {
        let prop = Prop.createBlankProperty();
        switch (tcase) {
            case (#Valid) prop.details.physical := Prop.validUnstablePhysicalDetails();
            case (#RenovationTooOld) return #Err(#InvalidData{field = "renovation"; reason = #InaccurateData});
            case (#TooManyBeds) return #Err(#InvalidData{field = "beds"; reason = #InaccurateData});
            case (#TooManyBaths) return #Err(#InvalidData{field = "baths"; reason = #InaccurateData});
        };
        prop.updates.add(#Ok(#PhysicalDetails(Prop.createPhysicalDetails())));
        #Ok(Stables.toStableProperty(prop));
    };

    func createAdditionalDetailsExpectedOutcome(tcase: AdditionalDetailsUpdateCase): UpdateResult {
        let prop = Prop.createBlankProperty();
        switch (tcase) {
            case (#Valid) prop.details.additional := Prop.validUnstableAdditionalDetails();
            case (#LowCrimeScore) return #Err(#InvalidData{field = "Crime Score"; reason = #OutOfRange});
            case (#HighSchoolScore) return #Err(#InvalidData{field = "School Score"; reason = #OutOfRange});
        };
        prop.updates.add(#Ok(#AdditionalDetails(Prop.createAdditionalDetails())));
        #Ok(Stables.toStableProperty(prop));
    };

      func createDescriptionExpectedOutcome(tcase: DescriptionCase): UpdateResult {
        let prop = Prop.createBlankProperty();
        switch (tcase) {
            case (#Valid) prop.details.misc.description := TestCases.descriptionTestCaseArg(tcase);
            case (_) return #Err(#InvalidData({field = "description"; reason = #EmptyString}));
        };
        prop.updates.add(#Ok(#Description(TestCases.descriptionTestCaseArg(tcase))));
        #Ok(Stables.toStableProperty(prop));
    };

    type What = Types.What;
    func deleteEntries(what: What, property: PropertyUnstable): (){
        switch(what){
            case(#Insurance(_)) property.administrative.insurance.delete(0);
            case(#Document(_)) property.administrative.documents.delete(0);
            case(#Note(_)) property.administrative.notes.delete(0);
            case(#Maintenance(_)) property.operational.maintenance.delete(0);
            case(#Inspection(_)) property.operational.inspections.delete(0);
            case(#Tenant(_)) property.operational.tenants.delete(0);
            case(#Valuations(_)) property.financials.valuations.delete(0);
            case(#Images(_)) property.details.misc.images.delete(0);
            case(_){};
        }
    };



    func deleteCaseExpectedOutcome(tcase: DeleteCase, what: What): UpdateResult {
        let prop = Prop.createBlankProperty();
        switch(tcase){
            case(#Valid) deleteEntries(what, prop);
            case(#NonExistentId) return #Err(#InvalidElementId);
        };
        prop.updates.add(#Ok(what));
        #Ok(Stables.toStableProperty(prop));
    };

    public func createExpectedOutcome(tc: TestCase): UpdateResult {
        switch(tc) {
            case (#Note(#Create(c))) {
                createNoteExpectedOutcome(c);
            };
            case (#Note(#Update(u))) {
                updateNoteExpectedOutcome(u);
            };
            case (#Note(#Delete(d))) {
                deleteCaseExpectedOutcome(d, #Note(#Delete(0)));
            };

            case (#Insurance(#Create(c))) {
                createInsuranceExpectedOutcome(c);
            };
            case (#Insurance(#Update(u))) {
                updateInsuranceExpectedOutcome(u);
            };
            case (#Insurance(#Delete(d))) {
                deleteCaseExpectedOutcome(d, #Insurance(#Delete(0)));
            };

            case (#Documents(#Create(c))) {
                createDocumentExpectedOutcome(c);
            };
            case (#Documents(#Update(u))) {
                updateDocumentExpectedOutcome(u);
            };
            case (#Documents(#Delete(d))) {
                deleteCaseExpectedOutcome(d, #Document(#Delete(0)));
            };
            case (#Tenant(#Create(c))) {
                createTenantExpectedOutcome(c);
            };
            case (#Tenant(#Update(u))) {
                updateTenantExpectedOutcome(u);
            };
            case (#Tenant(#Delete(d))) {
                deleteCaseExpectedOutcome(d, #Tenant(#Delete(0)));
            };

            case (#Maintenance(#Create(c))) {
                createMaintenanceExpectedOutcome(c);
            };
            case (#Maintenance(#Update(u))) {
                updateMaintenanceExpectedOutcome(u);
            };
            case (#Maintenance(#Delete(d))) {
                deleteCaseExpectedOutcome(d, #Maintenance(#Delete(0)));
            };

            case (#Inspection(#Create(c))) {
                createInspectionExpectedOutcome(c);
            };
            case (#Inspection(#Update(u))) {
                updateInspectionExpectedOutcome(u);
            };
            case (#Inspection(#Delete(d))) {
                deleteCaseExpectedOutcome(d, #Inspection(#Delete(0)));
            };

            case (#Valuation(#Create(c))) {
                createValuationExpectedOutcome(c);
            };
            case (#Valuation(#Update(u))) {
                updateValuationExpectedOutcome(u);
            };
            case (#Valuation(#Delete(d))) {
                deleteCaseExpectedOutcome(d, #Valuations(#Delete(0)));
            };

            case (#Financials(c)) {
                createFinancialsExpectedOutcome(c);
            };

            case (#MonthlyRent(c)) {
                createMonthlyRentExpectedOutcome(c);
            };

            case (#PhysicalDetails(c)) {
                createPhysicalDetailsExpectedOutcome(c);
            };

            case (#AdditionalDetails(c)) {
                createAdditionalDetailsExpectedOutcome(c);
            };

            case (#Images(#Create(c))) {
                createImageExpectedOutcome(c);
            };
            case (#Images(#Update(u))) {
                updateImageExpectedOutcome(u);
            };
            case (#Images(#Delete(d))) {
                deleteCaseExpectedOutcome(d, #Images(#Delete(0)));
            };

            case (#Description(c)) {
                createDescriptionExpectedOutcome(c);
            };


        }
    };

}