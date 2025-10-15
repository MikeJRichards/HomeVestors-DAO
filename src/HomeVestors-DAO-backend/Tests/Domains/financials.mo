import UnstableTypes "./../unstableTypes";
import Types "./../../types";
import TestTypes "./../testTypes";
import Utils "./../utils";

import Float "mo:base/Float";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";

module{
    type Actions<C,U> = Types.Actions<C,U>;

    type PropertyUnstable = UnstableTypes.PropertyUnstable;
    type WhatWithPropertyId = Types.WhatWithPropertyId;
    type UpdateResult = Types.UpdateResult;
    type  PreTestHandler<C, U, T> = TestTypes. PreTestHandler<C, U, T>;
    type FlatPreTestHandler<U,T> = TestTypes.FlatPreTestHandler<U,T>;


    public func createFinancialTestType2(property: PropertyUnstable, handlePropertyUpdate: (Types.WhatWithPropertyId, Principal) -> async Types.UpdateResultBeforeVsAfter): async [Text] {
        type U = Types.FinancialsArg;
        type T = UnstableTypes.FinancialsUnstable;

        func createFinancialsArg(): U {
            {
                currentValue = 300000;
            };
        };

        let arg : U = createFinancialsArg();

         let financialCases : [(Text, U, Bool)] = [
            Utils.ok1("Financials: update valid", arg),
            Utils.err1("Financials: zero current value", { arg with currentValue = 0 })
        ];

        let handler : FlatPreTestHandler<U,T> = {
            handlePropertyUpdate;
            toStruct   = func(p: PropertyUnstable) = p.financials;
            toWhat      = func(arg: U) = #Financials(arg);

            checkUpdate = func(before: PropertyUnstable, after: PropertyUnstable, arg: U): Text {
                return Utils.assertUpdate2("currentValue", #OptNat(?before.financials.currentValue), #OptNat(?after.financials.currentValue), #OptNat(?arg.currentValue))
                # Utils.assertUpdate2("pricePerSqFoot", #OptNat(?before.financials.pricePerSqFoot), #OptNat(?after.financials.pricePerSqFoot), #OptNat(?(arg.currentValue / after.details.physical.squareFootage)));
            };
        };

        await Utils.runFlatGenericCases<U,T>(property, handler, financialCases);
    };

    public func createMonthlyRentTestType2(
        property: PropertyUnstable,
        handlePropertyUpdate: (Types.WhatWithPropertyId, Principal) -> async Types.UpdateResultBeforeVsAfter
    ) : async [Text] {
        type U = Nat;
        type T = UnstableTypes.FinancialsUnstable;

        let rentCases : [(Text, U, Bool)] = [
            Utils.ok1("MonthlyRent: valid", 1000),
            Utils.err1("MonthlyRent: zero rent", 0)
        ];

        let handler : FlatPreTestHandler<U,T> = {
            handlePropertyUpdate;
            toStruct   = func(p: PropertyUnstable) = p.financials;
            toWhat     = func(arg: U) = #MonthlyRent(arg);

            checkUpdate = func(before: PropertyUnstable, after: PropertyUnstable, arg: U): Text {
                Utils.assertUpdate2("monthlyRent", #OptNat(?before.financials.monthlyRent), #OptNat(?after.financials.monthlyRent), #OptNat(?arg))
                # Utils.assertUpdate2("yield", #OptFloat(?before.financials.yield), #OptFloat(?after.financials.yield), #OptFloat(?(Float.fromInt(12 * arg) / Float.fromInt(after.financials.currentValue))));
            };
        };

        await Utils.runFlatGenericCases<U,T>(property, handler, rentCases);
    };

    // ====================== VALUATIONS ======================
    public func createValuationTestType2(property: PropertyUnstable, handlePropertyUpdate: (Types.WhatWithPropertyId, Principal) -> async Types.UpdateResultBeforeVsAfter):async [Text] {
        type C = Types.ValuationRecordCArg;
        type U = Types.ValuationRecordUArg;
        type T = UnstableTypes.ValuationRecordUnstable;
        func createValuationRecordCArg(): C {
            {
                value = 275000;
                method = #Online;
            };
        };

        func createValuationRecordUArg(): U {
            {
                value = ?290000;
                method = ?#Appraisal;
            };
        };

        let cArg : C = createValuationRecordCArg();
        let uArg : U = createValuationRecordUArg();

        let valuationCases : [(Text, Actions<C,U>, Bool)] = [
            // CREATE
            Utils.ok("Valuation: create valid",      #Create([cArg])),
            Utils.err("Valuation: zero value",       #Create([{ cArg with value = 0 }])),

            // UPDATE
            Utils.ok("Valuation: update valid",      #Update((uArg, [0]))),
            Utils.err("Valuation: update non-existent", #Update((uArg, [9999]))),
            Utils.err("Valuation: update zero value",   #Update(({ uArg with value = ?0 }, [0]))),

            // DELETE
            Utils.ok("Valuation: delete valid",      #Delete([0])),
            Utils.err("Valuation: delete non-existent",#Delete([9999]))
        ];

        let handler : PreTestHandler<C,U,T> = {
            testing = false;
            handlePropertyUpdate;
            toHashMap   = func(p: PropertyUnstable) = p.financials.valuations;
            showMap     = func(map: HashMap.HashMap<Nat,T>) = debug_show(Iter.toArray(map.entries()));
            toId        = func(p: PropertyUnstable) = p.financials.valuationId;
            toWhat      = func(action: Actions<C,U>) = #Valuations(action);

            checkUpdate = func(before: T, after: T, arg: U): Text {
                var s = "";
                s #= Utils.assertUpdate2("value", #OptNat(?before.value), #OptNat(?after.value), #OptNat(arg.value));
                s;
            };

            checkCreate = Utils.createDefaultCheckCreate();
            checkDelete = Utils.createDefaultCheckDelete();
            seedCreate = Utils.createDefaultSeedCreate(cArg);
            validForTest = Utils.createDefaultValidForTest(["Valuation: update non-existent", "Valuation: delete non-existent"]);
        };

        await Utils.runGenericCases<C,U,T>(property, handler, valuationCases)
    };


}