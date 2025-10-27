import UnstableTypes "./../unstableTypes";
import Types "./../../types";
import TestTypes "./../testTypes";
import Time "mo:base/Time";
import Principal "mo:base/Principal";
import Utils "./../utils";

import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";

module{
    type Actions<C,U> = Types.Actions<C,U>;
    type PropertyUnstable = UnstableTypes.PropertyUnstable;
    type WhatWithPropertyId = Types.WhatWithPropertyId;
    type UpdateResult = Types.UpdateResult;
    type  PreTestHandler<C, U, T> = TestTypes. PreTestHandler<C, U, T>;

    // ====================== INVOICES ======================
    public func createInvoiceTestType2(property: PropertyUnstable, handlePropertyUpdate: (Types.WhatWithPropertyId, Principal) -> async Types.UpdateResultExternal): async [Text] {
        type C = Types.InvoiceCArg;
        type U = Types.InvoiceUArg;
        type T = UnstableTypes.InvoiceUnstable;

        func createInvoiceCArg(): C {
            {
              title = "New Invoice";
              description = "New Invoice Description";
              amount = 10000;
              dueDate = Time.now() + 100000000000;
              direction = #Outgoing{
                category = #Repairs;
                to = {owner = Principal.fromText("2e7fg-mfyxt-iivfx-l7pim-ysvwq-qetwz-h4rhz-t76tr-5zob4-oopr3-hae"); subaccount = null};
                accountReference = "account reference";
                proposalId = 0;
              };             // #Incoming(Account) or #Outgoing(Account)
              recurrence = {
                period = #None;
                endDate = null;
                previousInvoiceIds = [];
                count = 0;
              };             // Can be #None
              paymentMethod = ?#ICP;          // Optional: CKUSDC, HGB, etc.
            };
        };

        func createInvoiceUArg(): U {
            {
              title = ?"Updated Invoice";
              description = ?"Updated Invoice Description";
              amount = null;
              dueDate = null;
              direction = null;    // #Incoming(Account) or #Outgoing(Account)
              paymentMethod = null;          // Optional: CKUSDC, HGB, etc.
              recurrence = null;  // Can be #None
              preApprovedByAdmin = null;
              process = false;
            };
        };

        let investorCArg : C = {
          title = "Investor Payout";
          description = "Distribute rent to investors";
          amount = 50000;
          dueDate = Time.now() + 100000000000;
          direction = #ToInvestors({ proposalId = 0 });
          recurrence = {
            period = #None;
            endDate = null;
            previousInvoiceIds = [];
            count = 0;
          };
          paymentMethod = ?#ICP;
        };


        let cArg : C = createInvoiceCArg();
        let uArg : U = createInvoiceUArg();

        let invoiceCases : [(Text, Actions<C,U>, Bool)] = [
            // CREATE
            Utils.ok("Invoice: create valid", #Create([cArg])),
            // UPDATE
            Utils.ok("Invoice: update valid",     #Update((uArg, [0]))),
            Utils.err("Invoice: update non-exist",#Update((uArg, [9999]))),

            // DELETE
            Utils.ok("Invoice: delete valid",     #Delete([0])),
            Utils.err("Invoice: delete non-exist",#Delete([9999])),
            //To Investors
            Utils.ok("Invoice: create to investors", #Create([investorCArg]))
        ];

        let handler : PreTestHandler<C,U,T> = {
          testing = true;
          handlePropertyUpdate;
          toHashMap   = func(p: PropertyUnstable) = p.financials.invoices;
          showMap     = func(map: HashMap.HashMap<Nat,T>) = debug_show(Iter.toArray(map.entries()));
          toId        = func(p: PropertyUnstable) = p.financials.invoiceId;
          toWhat      = func(action: Actions<C,U>) = #Invoice(action);
          checkUpdate = func(before: T, after: T, arg: U): Text {
              var s = "";
              s #= Utils.assertUpdate2("title",       #OptText(?before.title),      #OptText(?after.title),      #OptText(arg.title));
              s #= Utils.assertUpdate2("description", #OptText(?before.description),#OptText(?after.description),#OptText(arg.description));
              s #= Utils.assertUpdate2("amount",      #OptNat(?before.amount),      #OptNat(?after.amount),      #OptNat(arg.amount));
              s #= Utils.assertUpdate2("dueDate",     #OptInt(?before.due),         #OptInt(?after.due),         #OptInt(arg.dueDate));
              s;
          };

          checkCreate = Utils.createDefaultCheckCreate();
          checkDelete = Utils.createDefaultCheckDelete();
          seedCreate = Utils.createDefaultSeedCreate(cArg);
          validForTest = Utils.createDefaultValidForTest(["Invoice: delete non-exist", "Invoice: update non-exist"]);
        };

        await Utils.runGenericCases<C,U,T>(property, handler, invoiceCases)
    };

}