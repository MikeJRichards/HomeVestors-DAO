import Types "../Utils/types";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import UnstableTypes "../Utils/unstableTypes";
import Stables "../Utils/stables";
import Handler "../Utils/applyHandler";
import CrudHandler "../Utils/crudHandler";
import Utils "../Utils/utils";



//import HashMap "mo:base/HashMap";
//import Debug "mo:base/Debug";

module {
    type AdministrativeInfo = Types.AdministrativeInfo;
    type Handler<P, K, A, T, StableT> = UnstableTypes.Handler<P, K, A, T, StableT>;
    type InsurancePolicyCArg = Types.InsurancePolicyCArg;
    type InsurancePolicyUArg = Types.InsurancePolicyUArg;
    type InsurancePolicyUnstable = UnstableTypes.InsurancePolicyUnstable;
    type DocumentCArg = Types.DocumentCArg;
    type DocumentUArg = Types.DocumentUArg;
    type DocumentUnstable = UnstableTypes.DocumentUnstable;
    type NoteCArg = Types.NoteCArg;
    type NoteUArg = Types.NoteUArg;
    type NoteUnstable = UnstableTypes.NoteUnstable;
    type Property = Types.Property;
    type PropertyUnstable = UnstableTypes.PropertyUnstable;
    type UpdateError = Types.UpdateError;
    type Arg = Types.Arg<Property, Types.PropertyWhats>;
    type UpdateResult = Types.UpdateResult;
    type Actions<C,U> = Types.Actions<C,U>;
    type CrudHandler<K, C, U, T, StableT> = UnstableTypes.CrudHandler<K, C, U, T, StableT>;


    public func createAdministrativeInfo(): AdministrativeInfo {
        {
            documentId = 0;
            insuranceId = 0;
            notesId = 0;
            insurance = [];
            documents = [];
            notes = [];
        }
    };


    

   


    public func createInsuranceHandler(args: Arg, action: Actions<InsurancePolicyCArg, InsurancePolicyUArg>): async UpdateResult {
      type P = Property;
      type K = Nat;
      type C = InsurancePolicyCArg;
      type U = InsurancePolicyUArg;
      type A = Types.AtomicAction<K, C, U>;
      type T = InsurancePolicyUnstable;
      type StableT = Types.InsurancePolicy;
      type S = UnstableTypes.AdministrativeInfoPartialUnstable;
      let administrative = Stables.toPartialStableAdministrativeInfo(args.parent.administrative);
      let map = administrative.insurance;
      var tempId = administrative.insuranceId;
      let crudHandler: CrudHandler<K, C, U, T, StableT> = {
        map;
        getId = func() = administrative.insuranceId;
        createTempId = func(){
          tempId += 1;
          tempId;
        };
        incrementId = func(){administrative.insuranceId += 1};
        assignId = func(id: Nat, el: StableT) = (id, {el with id = id;});
        delete = Utils.makeDelete(map);
        fromStable = Stables.fromStableInsurancePolicy;
        mutate = func(arg: InsurancePolicyUArg, insurance: InsurancePolicyUnstable): InsurancePolicyUnstable {
            insurance.policyNumber       := Utils.get(arg.policyNumber, insurance.policyNumber);
            insurance.provider           := Utils.get(arg.provider, insurance.provider);
            insurance.startDate          := Utils.get(arg.startDate, insurance.startDate);
            insurance.premium            := Utils.get(arg.premium, insurance.premium);
            insurance.paymentFrequency   := Utils.get(arg.paymentFrequency, insurance.paymentFrequency);
            insurance.nextPaymentDate    := Utils.get(arg.nextPaymentDate, insurance.nextPaymentDate);
            insurance.contactInfo        := Utils.get(arg.contactInfo, insurance.contactInfo);
            insurance.endDate            := Utils.getNullable(arg.endDate, insurance.endDate);
            insurance;
        };

        create = func(arg: InsurancePolicyCArg, id: Nat): T {
            {
                var id;
                var policyNumber = arg.policyNumber;  // Unique policy number
                var provider = arg.provider;  // Insurance provider
                var startDate = arg.startDate;  // Start date of the policy
                var endDate = arg.endDate;  // End date of the policy (None if active)
                var premium = arg.premium;  // Premium cost
                var paymentFrequency = arg.paymentFrequency;  // Whether paid weekly, monthly, or annually
                var nextPaymentDate = arg.nextPaymentDate;  // Date of the next payment
                var contactInfo = arg.contactInfo;  //
            }
        };

        validate = func(maybeInsurance: ?T): Result.Result<T, UpdateError> {
            let insurance = switch(maybeInsurance){case(null) return #err(#InvalidElementId); case(?insurance) insurance};
            if(Text.equal(insurance.policyNumber, "")) return #err(#InvalidData{field = "policy Number"; reason = #EmptyString;});
            if(Text.equal(insurance.provider, "")) return #err(#InvalidData{field = "policy Provider"; reason = #EmptyString;});
            if(Option.get(insurance.endDate, Time.now()) < Time.now()) return #err(#InvalidData{field = "Insurance End Date"; reason = #CannotBeSetInThePast;});
            if(insurance.premium <= 0) return #err(#InvalidData{field = "Insurance Premium"; reason = #CannotBeZero});
            if(insurance.nextPaymentDate < Time.now()) return #err(#InvalidData{field = "Next Payment Date"; reason = #CannotBeSetInThePast;});
            if(Text.equal(insurance.contactInfo, "")) return #err(#InvalidData{field = "Contact Info"; reason = #EmptyString;});
            return #ok(insurance);
        }
      };      
  
      let handler = CrudHandler.generateGenericHandler<P, K, C, U, T, StableT, S>(
        crudHandler, 
        func(t: T): StableT = Stables.toStableInsurancePolicy(t),             // toStable
        func(st: ?StableT) = #Insurance(st),                                  // wrapStableT
        func(p: P): [(K, StableT)] = p.administrative.insurance,              // toArray
        func(id1:K, id2:K): Bool = id1 == id2,
        CrudHandler.isConflictOnNatId(),
        func(property: P){{property with administrative = Stables.fromPartialStableAdministrativeInfo(administrative)}},
        Handler.updatePropertyEventLog,
        CrudHandler.atomicActionToWhat(func(a: Types.Actions<C,U>): Types.What = #Insurance(a))
      );
      await Handler.applyHandler<P, K, A, T, StableT>(args, CrudHandler.makeAutomicAction(action, map.size()), handler);
    };

    public func createDocumentHandler(args: Arg, action: Actions<DocumentCArg, DocumentUArg>): async UpdateResult {
      type P = Property;
      type K = Nat;
      type C = DocumentCArg;
      type U = DocumentUArg;
      type A = Types.AtomicAction<K, C, U>;
      type T = DocumentUnstable;
      type StableT = Types.Document;
      type S = UnstableTypes.AdministrativeInfoPartialUnstable;
      let administrative : S = Stables.toPartialStableAdministrativeInfo(args.parent.administrative);
      let map = administrative.documents;
      var tempId = administrative.documentId + 1;
      let crudHandler: CrudHandler<K, C, U, T, StableT> = {
        map;
        getId = func() = administrative.documentId;
        createTempId = func(){
          tempId += 1;
          tempId;
        };
        incrementId = func() = administrative.documentId += 1;
        assignId = func(id: Nat, el: StableT) = (id, {el with id = id;});
        delete = Utils.makeDelete(map);
        fromStable = Stables.fromStableDocument;
        mutate = func(arg: U, document: T): T {
            document.title           := Utils.get(arg.title, document.title);
            document.description     := Utils.get(arg.description, document.description);
            document.url             := Utils.get(arg.url, document.url);
            document.documentType    := Utils.get(arg.documentType, document.documentType);
            document;
        };

        create = func(arg: C, id: Nat): T {
            {
                var id;
                var uploadDate = Time.now();
                var title = arg.title;
                var description = arg.description;
                var documentType = arg.documentType;
                var url = arg.url;
             }
        };

        validate = func(maybeDoc: ?T): Result.Result<T, UpdateError> {
            let doc = switch(maybeDoc){case(null) return #err(#InvalidElementId); case(?doc) doc};
            if(Text.equal(doc.title, "")) return #err(#InvalidData{field = "title"; reason = #EmptyString;});
            if(Text.equal(doc.description, "")) return #err(#InvalidData{field = "description"; reason = #EmptyString;});
            if(Text.equal(doc.url, "")) return #err(#InvalidData{field = "URL"; reason = #EmptyString;});
            return #ok(doc);
        }
      };      
  
      let handler = CrudHandler.generateGenericHandler<P, K, C, U, T, StableT, S>(
        crudHandler, 
        func(t: T): StableT = Stables.toStableDocument(t),             // toStable
        func(st: ?StableT) = #Document(st),                                  // wrapStableT
        func(p: P): [(K, StableT)] = p.administrative.documents,              // toArray
        func(id1:K, id2:K): Bool = id1 == id2,
        CrudHandler.isConflictOnNatId(),
        func(property: P){{property with administrative = Stables.fromPartialStableAdministrativeInfo(administrative)}},
        Handler.updatePropertyEventLog,
        CrudHandler.atomicActionToWhat(func(a: Types.Actions<C,U>): Types.What = #Document(a))
      );
      await Handler.applyHandler<P, K, A, T, StableT>(args, CrudHandler.makeAutomicAction(action, map.size()), handler);
    };

    public func createNoteHandler(args: Arg, action: Actions<NoteCArg, NoteUArg>): async UpdateResult {
      type P = Property;
      type K = Nat;
      type C = NoteCArg;
      type U = NoteUArg;
      type A = Types.AtomicAction<K, C, U>;
      type T = NoteUnstable;
      type StableT = Types.Note;
      type S = UnstableTypes.AdministrativeInfoPartialUnstable;
      let administrative : S = Stables.toPartialStableAdministrativeInfo(args.parent.administrative);
      let map = administrative.notes;
      var tempId = administrative.notesId + 1;
      //Debug.print("MAP: "# debug_show(args.property.administrative.notes));
      let crudHandler: CrudHandler<K, C, U, T, StableT> = {
        map;
        getId = func() = administrative.notesId;
        createTempId = func(){
          tempId += 1;
          tempId;
        };
        incrementId = func(){administrative.notesId += 1;};
        assignId = func(id: Nat, el: StableT) = (id, {el with id = id;});
        delete = Utils.makeDelete(map);
        fromStable = Stables.fromStableNote;
        mutate = func(arg: U, note: T): T {
          note.title   := Utils.get(arg.title, note.title);
          note.content := Utils.get(arg.content, note.content);
          note.date    := Utils.getNullable(arg.date, note.date);
          note;
        };

        create = func(arg: C, id: Nat): T {
          {
            var author = args.caller;
            var content = arg.content;
            var date = arg.date;
            var id = id;
            var title = arg.title;
          }
        };

        validate = func(maybeNote: ?T): Result.Result<T, UpdateError> {
          let note = switch (maybeNote) {case (?n) n; case (null) return #err(#InvalidElementId);};
          if (Text.equal(note.title, "")) return #err(#InvalidData { field = "title"; reason = #EmptyString });
          if (Text.equal(note.content, "")) return #err(#InvalidData { field = "content"; reason = #EmptyString });
          if (Option.get(note.date, Time.now()) > Time.now()) return #err(#InvalidData { field = "Upload Date"; reason = #CannotBeSetInTheFuture });
          if (Principal.isAnonymous(note.author)) return #err(#InvalidData { field = "author"; reason = #Anonymous });
          #ok(note);
        }
      };      
  
      let handler = CrudHandler.generateGenericHandler<P, K, C, U, T, StableT, S>(
        crudHandler, 
        func(t: T): StableT = Stables.toStableNote(t),             // toStable
        func(st: ?StableT) = #Note(st),                                  // wrapStableT
        func(p: P): [(K, StableT)] = p.administrative.notes,              // toArray
        func(id1:K, id2:K): Bool = id1 == id2,
        CrudHandler.isConflictOnNatId(),
        func(property: P){{property with administrative = Stables.fromPartialStableAdministrativeInfo(administrative)}},
        Handler.updatePropertyEventLog,
        CrudHandler.atomicActionToWhat(func(a: Types.Actions<C,U>): Types.What = #Note(a))
      );
      await Handler.applyHandler<P, K, A, T, StableT>(args, CrudHandler.makeAutomicAction(action, map.size()), handler);
    };
}