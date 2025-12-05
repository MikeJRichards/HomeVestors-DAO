import UnstableTypes "../../../Utils/unstableTypes";
import Types "../../../Utils/types";
import TestTypes "./../testTypes";
import Time "mo:base/Time";
import Utils "../utils";

import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";

module{
    type Actions<C,U> = Types.Actions<C,U>;
    type PropertyUnstable = UnstableTypes.PropertyUnstable;
    type WhatWithPropertyId = Types.WhatWithPropertyId;
    type UpdateResult = Types.UpdateResult;
    type  PreTestHandler<C, U, T> = TestTypes. PreTestHandler<C, U, T>;

    public func createNoteTestType2(property: PropertyUnstable, handlePropertyUpdate: (WhatWithPropertyId, Principal) -> async Types.UpdateResultExternal): async [Text] {
        type C = Types.NoteCArg;
        type U = Types.NoteUArg;
        type T = UnstableTypes.NoteUnstable;
    
        func createNoteCArg(): C {
            {
                date = ?Time.now();
                title = "Initial Note";
                content = "This is a useful note about the property.";
            };
        };

        func createNoteUArg(): U {
            {
                date = ?(Time.now()); // +1 day
                title = ?"Updated Note Title";
                content = ?"Updated content for note.";
            };
        };
        
        let cArg = createNoteCArg();
        let uArg = createNoteUArg();

        let noteCases : [(Text, Types.Actions<C,U>, Bool)] = [
            // CREATE
            Utils.ok("Note: create valid",         #Create([cArg])),
            Utils.err("Note: create anonymous",     #Create([cArg])), // same arg but treated differently in logic
            Utils.err("Note: create empty title",  #Create([{ cArg with title = "" }])),
            Utils.err("Note: create empty content",#Create([{ cArg with content = "" }])),
            Utils.err("Note: create future date",  #Create([{ cArg with date = ?Utils.daysInFuture(7) }])),

            // UPDATE
            Utils.ok("Note: update valid",         #Update((uArg, [0]))),
            Utils.ok("Note: update null content", #Update(({ uArg with content = null }, [0]))),
            Utils.ok("Note: update null title",   #Update(({ uArg with title = null }, [0]))),
            Utils.err("Note: update non-existent", #Update((uArg, [9999]))),
            Utils.err("Note: update empty title",  #Update(({ uArg with title = ?"" }, [0]))),
            Utils.err("Note: update empty content",#Update(({ uArg with content = ?"" }, [0]))),
            Utils.err("Note: update future date",  #Update(({ uArg with date = ?Utils.daysInFuture(7) }, [0]))),

            // DELETE
            Utils.ok("Note: delete valid",         #Delete([0])),
            Utils.err("Note: delete non-existent", #Delete([9999]))
        ];

        let handler : PreTestHandler<C, U, T> = {
            testing = false;
            handlePropertyUpdate;
            toHashMap = func(p: PropertyUnstable) = p.administrative.notes;
            showMap = func(map: HashMap.HashMap<Nat,T>) = debug_show(Iter.toArray(map.entries()));
            toId = func(p: PropertyUnstable) = p.administrative.notesId;
            toWhat = func(action: Types.Actions<C,U>) = #Note(action);
           checkUpdate = func(noteBefore: T, noteAfter: T, uArg: U) : Text {
                var s = "";
                s #= Utils.assertUpdate2("date",    #OptInt(noteBefore.date),     #OptInt(noteAfter.date),     #OptInt(uArg.date));
                s #= Utils.assertUpdate2("title",   #OptText(?noteBefore.title),  #OptText(?noteAfter.title),  #OptText(uArg.title));
                s #= Utils.assertUpdate2("content", #OptText(?noteBefore.content),#OptText(?noteAfter.content),#OptText(uArg.content));
                s;
            };
            checkCreate = Utils.createDefaultCheckCreate();
            checkDelete = Utils.createDefaultCheckDelete();
            seedCreate = Utils.createDefaultSeedCreate(cArg);
            validForTest = Utils.createDefaultValidForTest(["Note: update non-existent", "Note: delete non-existent"]);
        };

        //public func runGenericCases<C, CT, U, UT <: Base, DT <: Base, T>(property: PropertyUnstable, handler: PreTestHandler<C,CT, U, UT, DT, T>, createCases: [(CT, C -> C, Bool)],updateCases: [(UT, U -> U, Bool)],deleteCases: [(DT, Bool)]): [Text] {
        await Utils.runGenericCases<C, U, T>(property, handler, noteCases);
    };

public func createInsuranceTestType(property: PropertyUnstable, handlePropertyUpdate: (Types.WhatWithPropertyId, Principal) -> async Types.UpdateResultExternal): async [Text] {
    type C = Types.InsurancePolicyCArg;
    type U = Types.InsurancePolicyUArg;
    type T = UnstableTypes.InsurancePolicyUnstable;

    let cArg : C = {
        policyNumber = "POL123456";
        provider = "Acme Insurance Ltd.";
        startDate = Time.now();
        endDate = ?(Time.now() + 31536000000); // +1 year
        premium = 499;
        paymentFrequency = #Monthly;
        nextPaymentDate = Time.now() + 2628000000; // +1 month
        contactInfo = "contact@acme.com";
    };
    let uArg : U = {
        policyNumber = ?"UPDATED-POL-7890";
        provider = ?"Updated Insurance Co.";
        startDate = ?(Time.now());
        endDate = ?(Time.now() + 63072000000); // +2 years
        premium = ?799;
        paymentFrequency = ?#Annually;
        nextPaymentDate = ?(Time.now() + 31536000000);
        contactInfo = ?"updated@insurance.com";
    };

    let insuranceCases : [(Text, Actions<C,U>, Bool)] = [

        // CREATE
        Utils.ok("Insurance: create valid",            #Create([cArg])),
        Utils.err("Insurance: create empty policy #",  #Create([{ cArg with policyNumber = "" }])),
        Utils.err("Insurance: create empty provider",  #Create([{ cArg with provider = "" }])),
        Utils.err("Insurance: end date in past",       #Create([{ cArg with endDate = ?(Time.now() - 1_000_000) }])),
        Utils.err("Insurance: premium zero",           #Create([{ cArg with premium = 0 }])),
        Utils.err("Insurance: next payment in past",   #Create([{ cArg with nextPaymentDate = Time.now() - 1_000_000 }])),
        Utils.err("Insurance: empty contact info",     #Create([{ cArg with contactInfo = "" }])),

        // UPDATE
        Utils.ok("Insurance: update valid",            #Update((uArg, [0]))),
        Utils.err("Insurance: update non-existent",    #Update((uArg, [9999]))),
        Utils.err("Insurance: update empty provider",  #Update(({ uArg with provider = ?"" }, [0]))),
        Utils.err("Insurance: update premium zero",    #Update(({ uArg with premium = ?0 }, [0]))),

        // DELETE
        Utils.ok("Insurance: delete valid",            #Delete([0])),
        Utils.err("Insurance: delete non-existent",    #Delete([9999]))
    ];

    let handler : PreTestHandler<C, U, T> = {
        testing = false;
        handlePropertyUpdate;
        showMap     = func(map: HashMap.HashMap<Nat,T>) = debug_show(Iter.toArray(map.entries()));
        toHashMap   = func(p: PropertyUnstable) = p.administrative.insurance;
        toId        = func(p: PropertyUnstable) = p.administrative.insuranceId;
        toWhat      = func(action: Actions<C,U>) = #Insurance(action);
        checkUpdate = func(before: T, after: T, arg: U): Text {
            var s = "";
            s #= Utils.assertUpdate2("policyNumber", #OptText(?before.policyNumber), #OptText(?after.policyNumber), #OptText(uArg.policyNumber));
            s #= Utils.assertUpdate2("provider",     #OptText(?before.provider),     #OptText(?after.provider),     #OptText(uArg.provider));
            s #= Utils.assertUpdate2("endDate",      #OptInt(before.endDate),       #OptInt(after.endDate),       #OptInt(uArg.endDate));
            s #= Utils.assertUpdate2("premium",      #OptNat(?before.premium),       #OptNat(?after.premium),       #OptNat(uArg.premium));
            s #= Utils.assertUpdate2("nextPayment",  #OptInt(?before.nextPaymentDate), #OptInt(?after.nextPaymentDate), #OptInt(uArg.nextPaymentDate));
            s #= Utils.assertUpdate2("contactInfo",  #OptText(?before.contactInfo),  #OptText(?after.contactInfo),  #OptText(uArg.contactInfo));
            s;
        };
        checkCreate = Utils.createDefaultCheckCreate();
        checkDelete = Utils.createDefaultCheckDelete();
        seedCreate = Utils.createDefaultSeedCreate(cArg);
        validForTest = Utils.createDefaultValidForTest(["Insurance: update non-existent", "Insurance: delete non-existent"]);
    };

    await Utils.runGenericCases<C, U, T>(property, handler, insuranceCases);
};

public func createDocumentTestType2(property: PropertyUnstable, handlePropertyUpdate: (Types.WhatWithPropertyId, Principal) -> async Types.UpdateResultExternal): async [Text] {
    type C = Types.DocumentCArg;
    type U = Types.DocumentUArg;
    type T = UnstableTypes.DocumentUnstable;

    let cArg : C = {
        title = "AST Contract";
        description = "Tenancy agreement";
        documentType = #AST;
        url = "https://docs.acme.com/ast.pdf";
    };

    let uArg : U = {
        title = ?"Updated Title";
        description = ?"Updated tenancy agreement";
        documentType = ?#EPC;
        url = ?"https://docs.acme.com/epc.pdf";
    };

    let documentCases : [(Text, Actions<C,U>, Bool)] = [

        // CREATE
        Utils.ok("Document: create valid",           #Create([cArg])),
        Utils.err("Document: create empty title",    #Create([{ cArg with title = "" }])),
        Utils.err("Document: create empty desc",     #Create([{ cArg with description = "" }])),
        Utils.err("Document: create empty url",      #Create([{ cArg with url = "" }])),

        // UPDATE
        Utils.ok("Document: update valid",           #Update((uArg, [0]))),
        Utils.err("Document: update non-existent",   #Update((uArg, [9999]))),
        Utils.err("Document: update empty title",    #Update(({ uArg with title = ?"" }, [0]))),
        Utils.err("Document: update empty desc",     #Update(({ uArg with description = ?"" }, [0]))),
        Utils.err("Document: update empty url",      #Update(({ uArg with url = ?"" }, [0]))),

        // DELETE
        Utils.ok("Document: delete valid",           #Delete([0])),
        Utils.err("Document: delete non-existent",   #Delete([9999]))
    ];

    let handler : PreTestHandler<C,U,T> = {
        testing = false;
        handlePropertyUpdate;
        toHashMap   = func(p: PropertyUnstable) = p.administrative.documents;
        showMap     = func(map: HashMap.HashMap<Nat,T>) = debug_show(Iter.toArray(map.entries()));
        toId        = func(p: PropertyUnstable) = p.administrative.documentId;
        toWhat      = func(action: Actions<C,U>) = #Document(action);

        checkUpdate = func(before: T, after: T, arg: U): Text {
            var s = "";
            s #= Utils.assertUpdate2("title",       #OptText(?before.title),       #OptText(?after.title),       #OptText(arg.title));
            s #= Utils.assertUpdate2("description", #OptText(?before.description), #OptText(?after.description), #OptText(arg.description));
            s #= Utils.assertUpdate2("url",         #OptText(?before.url),         #OptText(?after.url),         #OptText(arg.url));
            s;
        };

        checkCreate = Utils.createDefaultCheckCreate();
        checkDelete = Utils.createDefaultCheckDelete();
        seedCreate = Utils.createDefaultSeedCreate(cArg);
        validForTest = Utils.createDefaultValidForTest(["Document: update non-existent", "Document: delete non-existent"]);
    };

    await Utils.runGenericCases<C,U,T>(property, handler, documentCases)
};

}