import Types "types";
import PropHelper "propHelper";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import UnstableTypes "Tests/unstableTypes";
import Stables "Tests/stables";
//import HashMap "mo:base/HashMap";
//import Debug "mo:base/Debug";

module {
    type AdministrativeInfo = Types.AdministrativeInfo;
    type Handler<T, StableT> = UnstableTypes.Handler<T, StableT>;
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


    

    type Arg = Types.Arg;
    type UpdateResult = Types.UpdateResult;
    type Actions<C,U> = Types.Actions<C,U>;
    type CrudHandler<C, U, T, StableT> = UnstableTypes.CrudHandler<C, U, T, StableT>;



    public func createInsuranceHandler(args: Arg, action: Actions<InsurancePolicyCArg, InsurancePolicyUArg>): async UpdateResult {
      type C = InsurancePolicyCArg;
      type U = InsurancePolicyUArg;
      type T = InsurancePolicyUnstable;
      type StableT = Types.InsurancePolicy;
      type S = UnstableTypes.AdministrativeInfoPartialUnstable;
      let administrative = Stables.toPartialStableAdministrativeInfo(args.property.administrative);
      let map = administrative.insurance;
      let crudHandler: CrudHandler<C, U, T, StableT> = {
        map;
        var id = administrative.insuranceId;
        setId = func(id: Nat) = administrative.insuranceId := id;
        assignId = func(id: Nat, el: StableT) = (id, {el with id = id;});
        delete = PropHelper.makeDelete(map);
        fromStable = Stables.fromStableInsurancePolicy;
        mutate = func(arg: InsurancePolicyUArg, insurance: InsurancePolicyUnstable): InsurancePolicyUnstable {
            insurance.policyNumber       := PropHelper.get(arg.policyNumber, insurance.policyNumber);
            insurance.provider           := PropHelper.get(arg.provider, insurance.provider);
            insurance.startDate          := PropHelper.get(arg.startDate, insurance.startDate);
            insurance.premium            := PropHelper.get(arg.premium, insurance.premium);
            insurance.paymentFrequency   := PropHelper.get(arg.paymentFrequency, insurance.paymentFrequency);
            insurance.nextPaymentDate    := PropHelper.get(arg.nextPaymentDate, insurance.nextPaymentDate);
            insurance.contactInfo        := PropHelper.get(arg.contactInfo, insurance.contactInfo);
            insurance.endDate            := PropHelper.getNullable(arg.endDate, insurance.endDate);
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
  
      let handler = PropHelper.generateGenericHandler<C, U, T, StableT, S>(crudHandler, action, Stables.toStableInsurancePolicy, func(s: S) = #Administrative(Stables.fromPartialStableAdministrativeInfo(s)), administrative, func(stableT: ?StableT) = #Insurance(stableT), func(property: Property) = property.administrative.insurance);
      await PropHelper.applyHandler<T, StableT>(args, handler);
    };

    public func createDocumentHandler(args: Arg, action: Actions<DocumentCArg, DocumentUArg>): async UpdateResult {
      type C = DocumentCArg;
      type U = DocumentUArg;
      type T = DocumentUnstable;
      type StableT = Types.Document;
      type S = UnstableTypes.AdministrativeInfoPartialUnstable;
      let administrative : S = Stables.toPartialStableAdministrativeInfo(args.property.administrative);
      let map = administrative.documents;
      let crudHandler: CrudHandler<C, U, T, StableT> = {
        map;
        var id = administrative.documentId;
        setId = func(id: Nat) = administrative.documentId := id;
        assignId = func(id: Nat, el: StableT) = (id, {el with id = id;});
        delete = PropHelper.makeDelete(map);
        fromStable = Stables.fromStableDocument;
        mutate = func(arg: U, document: T): T {
            document.title           := PropHelper.get(arg.title, document.title);
            document.description     := PropHelper.get(arg.description, document.description);
            document.url             := PropHelper.get(arg.url, document.url);
            document.documentType    := PropHelper.get(arg.documentType, document.documentType);
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
  
      let handler = PropHelper.generateGenericHandler<C, U, T, StableT, S>(crudHandler, action, Stables.toStableDocument, func(s: S) = #Administrative(Stables.fromPartialStableAdministrativeInfo(s)), administrative, func(stableT: ?StableT) = #Document(stableT), func(property: Property) = property.administrative.documents);
      await PropHelper.applyHandler<T, StableT>(args, handler);
    };

    public func createNoteHandler(args: Arg, action: Actions<NoteCArg, NoteUArg>): async UpdateResult {
      type C = NoteCArg;
      type U = NoteUArg;
      type T = NoteUnstable;
      type StableT = Types.Note;
      type S = UnstableTypes.AdministrativeInfoPartialUnstable;
      let administrative : S = Stables.toPartialStableAdministrativeInfo(args.property.administrative);
      let map = administrative.notes;
      //Debug.print("MAP: "# debug_show(args.property.administrative.notes));
      let crudHandler: CrudHandler<C, U, T, StableT> = {
        map;
        var id = administrative.notesId;
        setId = func(id: Nat) = administrative.notesId := id;
        assignId = func(id: Nat, el: StableT) = (id, {el with id = id;});
        delete = PropHelper.makeDelete(map);
        fromStable = Stables.fromStableNote;
        mutate = func(arg: U, note: T): T {
          note.title   := PropHelper.get(arg.title, note.title);
          note.content := PropHelper.get(arg.content, note.content);
          note.date    := PropHelper.getNullable(arg.date, note.date);
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
  
      let handler = PropHelper.generateGenericHandler<C, U, T, StableT, S>(crudHandler, action, Stables.toStableNote, func(s: S) = #Administrative(Stables.fromPartialStableAdministrativeInfo(s)), administrative, func(stableT: ?StableT) = #Note(stableT), func(property: Property) = property.administrative.notes);
      await PropHelper.applyHandler<T, StableT>(args, handler);
    };
}