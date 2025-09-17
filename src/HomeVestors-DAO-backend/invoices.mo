import Types "types";
import UnstableTypes "./Tests/unstableTypes";
import Stables "./Tests/stables";
import Tokens "token";
import NFT "nft";
import Governance "proposals";
import PropHelper "propHelper";
import { setTimer; cancelTimer } = "mo:base/Timer";
import Result "mo:base/Result";
import Time "mo:base/Time";
import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Buffer "mo:base/Buffer";
import HashMap "mo:base/HashMap";
import Array "mo:base/Array";
import Text "mo:base/Text";
import Option "mo:base/Option";


module {
    type CreateFinancialsArg = Types.CreateFinancialsArg;
    type InvestmentDetails = Types.InvestmentDetails;
    type Financials = Types.Financials;
    type Handler<T, StableT> = UnstableTypes.Handler<T, StableT>;
    type CrudHandler<C, U, T, StableT> = UnstableTypes.CrudHandler<C, U, T, StableT>;
    type ValuationRecordCArg = Types.ValuationRecordCArg; 
    type ValuationRecordUArg = Types.ValuationRecordUArg; 
    type ValuationRecordUnstable = UnstableTypes.ValuationRecordUnstable;
    type SimpleHandler<T> = UnstableTypes.SimpleHandler<T>;
    type Property = Types.Property;
    type UpdateResult = Types.UpdateResult;
    type UpdateError = Types.UpdateError;
    type FinancialIntentResult = Types.FinancialIntentResult;
    type What = Types.What;
    type PropertyUnstable = UnstableTypes.PropertyUnstable;
    type FinancialsArg = Types.FinancialsArg;
    type Arg = Types.Arg;
    type Actions<C,U> = Types.Actions<C,U>;
    type InvoiceCArg = Types.InvoiceCArg;
    type InvoiceUArg = Types.InvoiceUArg;

    public func createInvoiceHandler(args: Arg, action: Actions<InvoiceCArg, InvoiceUArg>): async UpdateResult {
        type C = InvoiceCArg;
        type U = InvoiceUArg;
        type T = UnstableTypes.InvoiceUnstable;
        type StableT = Types.Invoice;
        type S = UnstableTypes.FinancialsPartialUnstable;
        let financials = Stables.toPartialStableFinancials(args.property.financials);
        let map = financials.invoices;
        let crudHandler: CrudHandler<C, U, T, StableT> = {
            map;
            var id = financials.invoiceId;
            setId = func(id: Nat) = financials.invoiceId := id;
            assignId = func(id: Nat, el: StableT) = (id, {el with id = id;});
            fromStable = Stables.fromStableInvoice;

            create = func(arg: C, id: Nat): T {
              let invoice : StableT = {
                  id;
                  title = arg.title;
                  description = arg.description;
                  amount = arg.amount;
                  due = arg.dueDate;
                  direction = arg.direction;
                  recurrence = arg.recurrence;
                  paymentMethod = switch(arg.paymentMethod){case(null)#HGB; case(?method)method};
                  status = #Draft;
                  paymentStatus = #WaitingApproval; 
                  logs = [];
              };
              Stables.fromStableInvoice(invoice);
            };

            mutate = func(arg: U, el: T): T {
              switch(el.status){
                  case(#Draft){
                      el.title := PropHelper.get(arg.title, el.title);
                      el.description := PropHelper.get(arg.description, el.description);
                      el.amount := PropHelper.get(arg.amount, el.amount);
                      el.due := PropHelper.get(arg.dueDate, el.due);
                      el.direction := PropHelper.get(arg.direction, el.direction);
                      el.paymentMethod := PropHelper.get(arg.paymentMethod, el.paymentMethod);
                      el.recurrence := PropHelper.get(arg.recurrence, el.recurrence);
                      el.status := switch(arg.preApprovedByAdmin, arg.process, Principal.equal(args.caller, PropHelper.getAdmin())){
                          case(?true, true, true) #PreApproved(args.caller);
                          case(_, true, _) #Pending;
                          case(_) el.status; 
                      };
                      return el;
                  };
                  case(#Failed){
                    el.status := switch(arg.preApprovedByAdmin, arg.process, Principal.equal(args.caller, PropHelper.getAdmin())){
                          case(?true, true, true) #PreApproved(args.caller);
                          case(_, true, _) #Pending;
                          case(_) el.status; 
                      };
                      return el;
                  };
                  case(_) return el;
              };
            };


            delete = func(id: Nat, el: StableT):(){
              switch(el.status, el.direction){
                  case(#Pending, #Incoming(_)) financials.invoices.put(id, {el with status = #Approved});
                  case(#Pending, #Outgoing(outgoing)){
                      switch(Governance.isAccepted(Stables.fromStableProperty(args.property), outgoing.proposalId)){
                          case(?true) financials.invoices.put(id, {el with status = #Approved});
                          case(?false) financials.invoices.put(id, {el with status = #Rejected});
                          case(null){};
                      };
                  };
                  case(#Draft, _) financials.invoices.delete(id);
                  case(_){};
              }
            };

            validate = func(el: ?T): Result.Result<T, UpdateError> {
                let invoice = switch (el) {case(null) return #err(#InvalidElementId); case(?v) v;};

                if (invoice.title == "") return #err(#InvalidData { field = "title"; reason = #EmptyString });
                if (invoice.amount <= 0) return #err(#InvalidData { field = "amount"; reason = #CannotBeZero });
                if (invoice.due < Time.now()) return #err(#InvalidData { field = "due"; reason = #CannotBeSetInThePast });
                if(invoice.status == #Paid) return #err(#InvalidType);

                switch (invoice.direction) {
                  case (#Incoming(incoming)) {
                    if(incoming.from == financials.account) return #err(#InvalidData { field = "direction from"; reason = #InvalidRecipient});
                    if (Principal.isAnonymous(incoming.from.owner)) return #err(#InvalidData { field = "direction.from"; reason = #Anonymous });
                  };
                  case (#Outgoing(outgoing)) {
                    if(outgoing.to == financials.account) return #err(#InvalidData { field = "direction to"; reason = #InvalidRecipient});
                    if (Principal.isAnonymous(outgoing.to.owner)) return #err(#InvalidData { field = "direction.to"; reason = #Anonymous });
                    if(args.testing == false){
                        var exists = false;
                        for((id, _) in args.property.governance.proposals.vals()) if(id == outgoing.proposalId) exists := true;
                        if(exists == false) return #err(#InvalidData{field = "direction to"; reason = #NonExistentProposal})
                    }
                  };
                  case(#ToInvestors(arg)){
                    if(args.testing == false){
                        var exists = false;
                        for((id, _) in args.property.governance.proposals.vals()) if(id == arg.proposalId) exists := true;
                        if(exists == false) return #err(#InvalidData{field = "direction to"; reason = #NonExistentProposal})
                    }
                  }
                };

                switch (invoice.recurrence.period) {
                  case (#None) {};
                  case (_) {
                    switch (invoice.recurrence.endDate) {
                      case (null) return #err(#InvalidData { field = "recurrence end Date"; reason = #CannotBeNull });
                      case (?end) {
                        if (end <= invoice.due) return #err(#InvalidData { field = "recurrence end Date"; reason = #OutOfRange });
                      };
                    };
                    if (invoice.recurrence.count != invoice.recurrence.previousInvoiceIds.size()) return #err(#InvalidData { field = "recurrence.count"; reason = #DataMismatch });
                  };
                };
                
                //should also validate the status of the invoice perhaps - although is this actually necessary? no other state other than update is run
                //right now we need to be accepting drafts, pending, approved, revoked - just not Paid
                //Should remove failed and always loop back to pending? Or i need to enable updating failed invoices to pending - might be best

                return #ok(invoice);
            }
        };      

        type AsyncType = {
            #TransactionId: Nat;
            #InvestorTransfers: [Types.InvestorTransfer];
        };
        let transactionIds = HashMap.HashMap<Nat, AsyncType>(0, Nat.equal, PropHelper.natToHash);

        let handler: Handler<T, StableT> = {
                validateAndPrepare = func () = PropHelper.getValid<C, U, T, StableT>(action, crudHandler);

                asyncEffect = func(arr: [(?Nat, Result.Result<T, UpdateError>)]): async [(?Nat, Result.Result<(), UpdateError>)] {
                    if(args.testing) return PropHelper.runNoAsync<T>(arr);
                    let transferFrom = func (id: Nat, token: Types.AcceptedCryptos, amount: Nat, from: Types.Account): async Result.Result<(), Types.UpdateError>{
                      switch(await Tokens.transferFrom(token, amount, financials.account, from)){
                        case(#Ok(transactionId)){
                          transactionIds.put(id, #TransactionId(transactionId));
                          return #ok();
                        };
                        case(#Err(e)) return #err(#Transfer(?e));
                      }
                    };

                    let transfer = func (id: Nat, token: Types.AcceptedCryptos, to: Types.Account, amount: Nat): async Result.Result<(), Types.UpdateError>{
                      switch(await Tokens.transfer(token, financials.account.subaccount, to, amount)){
                        case(#Ok(transactionId)){
                          transactionIds.put(id, #TransactionId(transactionId));
                          return #ok();
                        };
                        case(#Err(e)) return #err(#Transfer(?e));
                      }
                    };

                    let transferToInvestors = func(id: Nat, token: Types.AcceptedCryptos, totalAmount: Nat): async (){
                        let (allAccounts, totalNFTs) = await NFT.getAllAccounts(args.property.nftMarketplace.collectionId);
                        let transferResults = Buffer.Buffer<(Account, async Tokens.TransferResult)>(0);
                        for((account, count) in allAccounts.vals()){
                            let amount = totalAmount * count / totalNFTs;
                            let fromSubaccount = args.property.financials.account.subaccount;
                            transferResults.add((account, Tokens.transfer(token, fromSubaccount, account, amount)));
                        };
                        let results = Buffer.Buffer<Types.InvestorTransfer>(transferResults.size());
                        for((account, transferResult) in transferResults.vals()){
                            let result = switch(await transferResult){
                                case(#Ok(transactionId)) #Ok(transactionId);
                                case(#Err(e)) #Err(e);
                            };
                            results.add({
                                result;
                                timestamp = Time.now();
                                to = account;
                            });
                        };
                        transactionIds.put(id, #InvestorTransfers(Buffer.toArray(results)));
                    };
                    

                    let results = Buffer.Buffer<(?Nat, async Result.Result<(), UpdateError>)>(arr.size());
                    for((idOpt, res) in arr.vals()){
                        switch(idOpt, res){
                            case(?id, #ok(invoice)){
                                switch(invoice.status, invoice.direction){
                                    case(#Approved, #Incoming(income)) results.add((?id, transferFrom(id, invoice.paymentMethod, invoice.amount, income.from)));
                                    case(#Approved, #Outgoing(outgoing)) results.add((?id, transfer(id, invoice.paymentMethod, outgoing.to, invoice.amount)));
                                    case(#Approved, #ToInvestors(proposalId)){
                                        await transferToInvestors(id, invoice.paymentMethod, invoice.amount);
                                        results.add((?id, async #ok()));
                                    };
                                    case(_) results.add((?id, async #ok()));
                                }
                            };
                            case(_, #err(e)) results.add((idOpt, async #err(e)));
                            case(null, #ok(_)) results.add((null, async #err(#InvalidElementId))); 
                        }
                    };

                    let finalResult = Buffer.Buffer<(?Nat, Result.Result<(), UpdateError>)>(results.size());
                    for((idOpt, res) in results.vals())finalResult.add((idOpt, await res));
                    Buffer.toArray(finalResult);
                };

                applyAsyncEffects = func(idOpt: ?Nat, res: Result.Result<T, Types.UpdateError>): [(?Nat, Result.Result<StableT, UpdateError>)]{
                    let buff = Buffer.Buffer<(?Nat, Result.Result<StableT, UpdateError>)>(1);
                    let calculateNextRecurrence = func(freq: Types.PeriodicRecurrence): Int {
                        let time = Time.now();
                        let second : Int = 1_000_000_000;
                        let day : Int = second * 60 * 60 * 24;
                        switch(freq){
                            case(#None) 0; 
                            case(#Daily) time + day;
                            case(#Weekly) time + day * 7;
                            case(#Monthly) time + day * 30;
                            case(#Quarterly) time + day * 91;
                            case(#BiAnnually) time + day * 182;
                            case(#Annually) time + day * 365;
                            case(#Custom({interval})) time + interval;
                        };
                    };
                    let makeRecurringInvoice = func(invoice: T): (){
                        if(invoice.recurrence.period != #None){
                            switch(invoice.recurrence.endDate){
                                case(null){};
                                case(?endDate){
                                    if(endDate > calculateNextRecurrence(invoice.recurrence.period)){
                                        financials.invoiceId += 1;
                                        let newRecurringInvoice : StableT = {
                                            Stables.toStableInvoice(invoice) with
                                            id = financials.invoiceId;
                                            status = #Pending;
                                            paymentStatus = #Pending{timerId = null};
                                            recurrence = {
                                                invoice.recurrence with 
                                                previousInvoiceIds = Array.append(invoice.recurrence.previousInvoiceIds, [invoice.id]);
                                                count = invoice.recurrence.count + 1;
                                            };
                                        };
                                        buff.add((?financials.invoiceId, #ok(newRecurringInvoice)));
                                    }
                                }
                            }
                        };
                    };
                    
                    
                    switch(idOpt, res){
                        case(null, _) buff.add((null, #err(#InvalidElementId)));
                        case(?id, #ok(invoice)){
                            switch(transactionIds.get(id), invoice.status){
                                case(?#InvestorTransfers(transferArray), #Approved){
                                    var success = false;
                                    for(attemptedTransfers in transferArray.vals()){
                                        switch(attemptedTransfers.result){
                                            case(#Ok(_)) success := true;
                                            case(_){};
                                        };
                                    };
                                    invoice.status := if(success) #Paid else #Failed;
                                    invoice.paymentStatus := #TransferAttempted(transferArray);
                                    makeRecurringInvoice(invoice);
                                    buff.add((?id, #ok(Stables.toStableInvoice(invoice))));
                                };
                                case(?#TransactionId(transactionId), #Approved){
                                    invoice.status := #Paid;
                                    invoice.paymentStatus := #Confirmed{transactionId; paid_at = Time.now()};
                                    makeRecurringInvoice(invoice);
                                    buff.add((?id, #ok(Stables.toStableInvoice(invoice))));
                                };
                                case(_) buff.add((?id, #ok(Stables.toStableInvoice(invoice))));
                            };
                        }; 
                        case(?id, #err(#Transfer(?e))){
                            switch(financials.invoices.get(id)){
                                case(?invoice){
                                    let updatedInvoice : StableT = {
                                        invoice with
                                        status = #Failed;
                                        paymentStatus = #Failed{reason = #Transfer(?e); attempted_at = Time.now()};
                                    };
                                    buff.add((?id, #ok(updatedInvoice)));
                                };
                                case(null){};
                            };

                        };
                        case(?id, #err(e)) buff.add((idOpt, #err(e)));
                    };
                    Buffer.toArray(buff);
                };

                applyUpdate = func(id: ?Nat, el: StableT) = PropHelper.applyUpdate<C, U, T, StableT>(action, id, el, crudHandler);

                getUpdate = func() = #Financials(Stables.fromPartialStableFinancials(financials));

                finalAsync = func(arr: [Result.Result<?Nat, (?Nat, UpdateError)>]): async (){
                    if(args.testing) return;
                    let addTimer = func<system>(id: Nat, invoice: StableT): (){
                        switch(invoice.paymentStatus){case(#Pending({timerId})) switch(timerId){case(?id) cancelTimer(id); case(_){}}; case(_){}};
                        switch(invoice.status){
                            case(#Pending or #PreApproved(_)){
                                if(invoice.due > Time.now()){
                                    let delay = Int.abs(invoice.due - Time.now());
                                    let timerId = setTimer<system>(#nanoseconds delay, func () : async () {
                                        let updateInvoice: Types.WhatWithPropertyId = {
                                            propertyId = args.property.id;
                                            what = #Invoice(#Delete([id]));
                                        };
                                        ignore args.handlePropertyUpdate(updateInvoice, args.caller);
                                    });
                                    financials.invoices.put(id, {invoice with paymentStatus = #Pending{timerId = ?timerId}});
                                };

                            };
                            case(_){};
                        };
                    };
                    for(res in arr.vals()){
                        switch(res){
                            case(#ok(?id)){
                                switch(financials.invoices.get(id)){
                                    case(?invoice) addTimer<system>(id, invoice);
                                    case(_){};
                                }
                            };
                            case(_){};
                        };
                    };
                };
            };

        await PropHelper.applyHandler<T, StableT>(args, handler);
    };
    type Invoice = Types.Invoice;
    type Account = Types.Account;
    public func matchInvoiceDirection(dir: Types.InvoiceDirection, flag: ?Types.InvoiceDirectionFlag): Bool {
        func matchAccount(account: Account, account2: ?Account): Bool {
            switch(account2){
                case(null) true;
                case(?acc) acc == account;
            };
        };

        func matchRef(ref1: Text, ref2: ?Text): Bool {
            switch(ref2){
                case(null) true;
                case(?ref) Text.equal(ref, ref1);
            }
        };
        switch(dir, flag){
            case(_, null) true;
            case(#Incoming(income), ?#Incoming(incomeCond)){
                let categoryResult = switch(incomeCond.category){
                    case(null) true;
                    case(?category) category == income.category;
                };
                let fromResult = matchAccount(income.from, incomeCond.from);
                let refResult = matchRef(income.accountReference, incomeCond.accountReference);
                refResult and fromResult and categoryResult;
            };
            case(#Outgoing(outgoing), ?#Outgoing(outgoingCond)){
                let categoryResult = switch(outgoingCond.category){
                    case(null) true;
                    case(?category) category == outgoing.category;
                };
                let toResult = matchAccount(outgoing.to, outgoingCond.to);
                let refResult = matchRef(outgoing.accountReference, outgoingCond.accountReference);
                categoryResult and toResult and refResult;
            };
            case(#ToInvestors(_), ?#ToInvestors) true;
            case(_) false;
        }
    };

    public func matchInvoiceStatus(status: Types.InvoiceStatus, cond: ?Types.InvoiceStatus): Bool {
        switch(cond){
            case(null) true;
            case(?statusCond) statusCond == status;
        }
    };

    public func matchPaymentStatus(paymentStatus: Types.PaymentStatus, cond: ?Types.PaymentStatusFlag): Bool {
        switch(paymentStatus, cond){
            case(_, null) true;
            case(#WaitingApproval, ?#WaitingApproval) true;
            case(#Pending(_), ?#Pending) true;
            case(#Confirmed(paid), ?#Confirmed(arg)){
                switch(arg.paidFrom, arg.paidTo){
                    case(null, ?to) PropHelper.matchEqualityFlag(paid.paid_at, ?#LessThan(to));
                    case(?from, null) PropHelper.matchEqualityFlag(paid.paid_at, ?#MoreThan(from));
                    case(?from, ?to) PropHelper.matchEqualityFlag(paid.paid_at, ?#LessThan(to)) and PropHelper.matchEqualityFlag(paid.paid_at, ?#MoreThan(from));
                    case(null, null) true;
                };
            };
            case(#Failed(_), ?#Failed) true;
            case(_) false;
        }
    };

    public func matchPaymentMethod(pay: Types.AcceptedCryptos, cond:?Types.AcceptedCryptos): Bool {
        switch(cond){
            case(null) true;
            case(?cond) cond == pay;
        };
    };

    public func matchRecurrenceType(rec: Types.PeriodicRecurrence, cond: [Types.PeriodicRecurrence], shouldMatch: Bool): Bool {
        if (cond.size() == 0) {
            // no condition means "always passes"
            true
        } else {
            let inList = Array.find<Types.PeriodicRecurrence>(
                cond,
                func (x) { x == rec }
            ) != null;

            if (shouldMatch) {
                // include semantics: must be in the list
                inList
            } else {
                // exclude semantics: must NOT be in the list
                not inList
            }
        }
    };



    public func filterInvoices(el: Invoice, conditional: Types.InvoiceConditionals): Types.ReadOutcome<Invoice> {
        let endDate = switch(el.recurrence.endDate){case(null) 0; case(?end) end};
        if(
            matchInvoiceStatus(el.status, conditional.status) and
            matchInvoiceDirection(el.direction, conditional.direction) and 
            matchPaymentStatus(el.paymentStatus, conditional.paymentStatus) and 
            matchPaymentMethod(el.paymentMethod, conditional.paymentMethod) and
            matchRecurrenceType(el.recurrence.period, conditional.recurrenceType, true) and
            matchRecurrenceType(el.recurrence.period, conditional.notRecurrenceType, false) and
            PropHelper.matchEqualityFlag(el.amount, conditional.amount) and
            PropHelper.matchEqualityFlag(el.due, conditional.due) and
            PropHelper.matchEqualityFlag(endDate, conditional.recurrenceEndAt)
        ){
            #Ok(el);
        }
        else #Err(#DidNotMatchConditions);
    }

}