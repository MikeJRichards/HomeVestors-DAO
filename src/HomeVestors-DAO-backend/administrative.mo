import Types "types";
import PropHelper "propHelper";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import UnstableTypes "Tests/unstableTypes";

module {
    type AdministrativeInfo = Types.AdministrativeInfo;
    type Handler<C, U, T> = UnstableTypes.Handler<C, U, T>;
    type InsurancePolicyCArg = Types.InsurancePolicyCArg;
    type InsurancePolicyUArg = Types.InsurancePolicyUArg;
    type InsurancePolicyUnstable = UnstableTypes.InsurancePolicyUnstable;
    type DocumentCArg = Types.DocumentCArg;
    type DocumentUArg = Types.DocumentUArg;
    type DocumentUnstable = UnstableTypes.DocumentUnstable;
    type NoteCArg = Types.NoteCArg;
    type NoteUArg = Types.NoteUArg;
    type NoteUnstable = UnstableTypes.NoteUnstable;
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

    public func createInsuranceHandler(): Handler<InsurancePolicyCArg, InsurancePolicyUArg, InsurancePolicyUnstable> {
      {
        map = func(p: PropertyUnstable) = p.administrative.insurance;

        getId = func(p: PropertyUnstable) = p.administrative.insuranceId;

        incrementId = func(p: PropertyUnstable) = p.administrative.insuranceId += 1;

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

        create = func(arg: InsurancePolicyCArg, id: Nat, caller: Principal): InsurancePolicyUnstable {
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

        validate = func(maybeInsurance: ?InsurancePolicyUnstable): Result.Result<InsurancePolicyUnstable, UpdateError> {
            let insurance = switch(maybeInsurance){case(null) return #err(#InvalidElementId); case(?insurance) insurance};
            if(Text.equal(insurance.policyNumber, "")) return #err(#InvalidData{field = "policy Number"; reason = #EmptyString;});
            if(Text.equal(insurance.provider, "")) return #err(#InvalidData{field = "policy Provider"; reason = #EmptyString;});
            if(Option.get(insurance.endDate, Time.now()) < Time.now()) return #err(#InvalidData{field = "Insurance End Date"; reason = #CannotBeSetInThePast;});
            if(insurance.premium <= 0) return #err(#InvalidData{field = "Insurance Premium"; reason = #CannotBeZero});
            if(insurance.nextPaymentDate < Time.now()) return #err(#InvalidData{field = "Next Payment Date"; reason = #CannotBeSetInThePast;});
            if(Text.equal(insurance.contactInfo, "")) return #err(#InvalidData{field = "Contact Info"; reason = #EmptyString;});
            return #ok(insurance);
        }
      }
    };

    public func createDocumentHandler(): Handler<DocumentCArg, DocumentUArg, DocumentUnstable> {
      {
        map = func(p: PropertyUnstable) = p.administrative.documents;

        getId = func(p: PropertyUnstable) = p.administrative.documentId;

        incrementId = func(p: PropertyUnstable) = p.administrative.documentId += 1;

        mutate = func(arg: DocumentUArg, document: DocumentUnstable): DocumentUnstable {
            document.title           := PropHelper.get(arg.title, document.title);
            document.description     := PropHelper.get(arg.description, document.description);
            document.url             := PropHelper.get(arg.url, document.url);
            document.documentType    := PropHelper.get(arg.documentType, document.documentType);
            document;
        };

        create = func(arg: DocumentCArg, id: Nat, caller: Principal): DocumentUnstable {
            {
                var id;
                var uploadDate = Time.now();
                var title = arg.title;
                var description = arg.description;
                var documentType = arg.documentType;
                var url = arg.url;
             }
        };

        validate = func(maybeDoc: ?DocumentUnstable): Result.Result<DocumentUnstable, UpdateError> {
            let doc = switch(maybeDoc){case(null) return #err(#InvalidElementId); case(?doc) doc};
            if(Text.equal(doc.title, "")) return #err(#InvalidData{field = "title"; reason = #EmptyString;});
            if(Text.equal(doc.description, "")) return #err(#InvalidData{field = "description"; reason = #EmptyString;});
            if(Text.equal(doc.url, "")) return #err(#InvalidData{field = "URL"; reason = #EmptyString;});
            return #ok(doc);
        }
      }
    };

    public func createNoteHandler(): Handler<NoteCArg, NoteUArg, NoteUnstable> {
      {
        map = func(p: PropertyUnstable) = p.administrative.notes;

        getId = func(p: PropertyUnstable) = p.administrative.notesId;

        incrementId = func(p: PropertyUnstable) = p.administrative.notesId += 1;

        mutate = func(arg: NoteUArg, note: NoteUnstable): NoteUnstable {
          note.title   := PropHelper.get(arg.title, note.title);
          note.content := PropHelper.get(arg.content, note.content);
          note.date    := PropHelper.getNullable(arg.date, note.date);
          note;
        };

        create = func(arg: NoteCArg, id: Nat, caller: Principal): NoteUnstable {
          {
            var author = caller;
            var content = arg.content;
            var date = arg.date;
            var id = id;
            var title = arg.title;
          }
        };

        validate = func(maybeNote: ?NoteUnstable): Result.Result<NoteUnstable, UpdateError> {
          let note = switch (maybeNote) {case (?n) n; case (null) return #err(#InvalidElementId);};
          if (Text.equal(note.title, "")) return #err(#InvalidData { field = "title"; reason = #EmptyString });
          if (Text.equal(note.content, "")) return #err(#InvalidData { field = "content"; reason = #EmptyString });
          if (Option.get(note.date, Time.now()) > Time.now()) return #err(#InvalidData { field = "Upload Date"; reason = #CannotBeSetInTheFuture });
          if (Principal.isAnonymous(note.author)) return #err(#InvalidData { field = "author"; reason = #Anonymous });
          #ok(note);
        }
      }
    };
}