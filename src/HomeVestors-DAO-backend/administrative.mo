import Types "types";
import PropHelper "propHelper";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Option "mo:base/Option";
import Principal "mo:base/Principal";

module {
    type AdministrativeInfo = Types.AdministrativeInfo;
    type InsurancePolicy = Types.InsurancePolicy;
    type UpdateError = Types.UpdateError;
    type Property = Types.Property;
    type InsurancePolicyUArg = Types.InsurancePolicyUArg;
    type AdministrativeIntentResult = Types.AdministrativeIntentResult;
    type InsurancePolicyCArg = Types.InsurancePolicyCArg;
    type Actions<C, U> = Types.Actions<C, U>;
    type UpdateResult = Types.UpdateResult;
    type DocumentUArg = Types.DocumentUArg;
    type Document = Types.Document;
    type Note = Types.Note;
    type DocumentCArg = Types.DocumentCArg;
    type NoteCArg = Types.NoteCArg;
    type NoteUArg = Types.NoteUArg;
    type What = Types.What;

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
    
    func validateInsurance(insurance: InsurancePolicy): Result.Result<InsurancePolicy, UpdateError>{
        if(Text.equal(insurance.policyNumber, "")) return #err(#InvalidData{field = "policy Number"; reason = #EmptyString;});
        if(Text.equal(insurance.provider, "")) return #err(#InvalidData{field = "policy Provider"; reason = #EmptyString;});
        if(Option.get(insurance.endDate, Time.now()) < Time.now()) return #err(#InvalidData{field = "Insurance End Date"; reason = #CannotBeSetInThePast;});
        if(insurance.premium <= 0) return #err(#InvalidData{field = "Insurance Premium"; reason = #CannotBeZero});
        if(insurance.nextPaymentDate < Time.now()) return #err(#InvalidData{field = "Next Payment Date"; reason = #CannotBeSetInThePast;});
        if(Text.equal(insurance.contactInfo, "")) return #err(#InvalidData{field = "Contact Info"; reason = #EmptyString;});
        return #ok(insurance);
    };

    func mutateInsurance(arg: InsurancePolicyUArg, insurance: InsurancePolicy): InsurancePolicy {
        {
            insurance with
            policyNumber       = PropHelper.get(arg.policyNumber, insurance.policyNumber);
            provider           = PropHelper.get(arg.provider, insurance.provider);
            startDate          = PropHelper.get(arg.startDate, insurance.startDate);
            premium            = PropHelper.get(arg.premium, insurance.premium);
            paymentFrequency   = PropHelper.get(arg.paymentFrequency, insurance.paymentFrequency);
            nextPaymentDate    = PropHelper.get(arg.nextPaymentDate, insurance.nextPaymentDate);
            contactInfo        = PropHelper.get(arg.contactInfo, insurance.contactInfo);
            endDate            = PropHelper.getNullable(arg.endDate, insurance.endDate);
        };
    };

    func createUpdatedInsurance(arg: InsurancePolicyUArg, property: Property, id: Nat): AdministrativeIntentResult {
        switch(PropHelper.getElementByKey(property.administrative.insurance, id)){
            case(?insurance){
                let updatedInsurance = mutateInsurance(arg, insurance);
                switch(validateInsurance(updatedInsurance)){case(#err(e)) return #Err(e); case(_) {}};
                return #Ok(#Insurance (#Update (updatedInsurance, id)));
            };
            case(null){
                return #Err(#InvalidElementId)
            };
        };
    };

    public func createInsurance(arg: InsurancePolicyCArg, property: Property): AdministrativeIntentResult {        
        let newId = property.administrative.insuranceId + 1;
        let newInsurance = {arg with id = newId};
        switch(validateInsurance(newInsurance)){
            case(#err(e)) return #Err(e); 
            case(_) return #Ok(#Insurance (#Create (newInsurance, newId)));
        };
    };



    public func deleteInsurance(property: Property, id: Nat): AdministrativeIntentResult {
        switch(PropHelper.getElementByKey(property.administrative.insurance, id)){
            case(null){return #Err(#InvalidElementId)};
            case(_){return #Ok(#Insurance(#Delete(id)))}
        }
    };

    public func writeInsurance(action: Actions<InsurancePolicyCArg, (InsurancePolicyUArg, Nat)>, property: Property): UpdateResult {
        let result = switch(action){
            case(#Create(arg)){
                createInsurance(arg, property);
            };
            case(#Update(arg, id)){
                createUpdatedInsurance(arg, property, id);
            };
            case(#Delete(id)){
                deleteInsurance(property, id);
            };
        };

        applyAdministrativeUpdate(result, property, #Insurance(action));
    };



    func createUpdatedDocument(arg: DocumentUArg, property: Property, id: Nat): AdministrativeIntentResult {
        switch(PropHelper.getElementByKey(property.administrative.documents, id)){
            case(?document){
                let updatedDocument = mutateDocument(arg, document);
                switch(validateDocument(updatedDocument)){case(#err(e)) return #Err(e); case(_) {}};
                return #Ok(#Documents (#Update (updatedDocument, id)));
            };
            case(null){
                return #Err(#InvalidElementId)
            };
        };
    };

    func validateDocument(doc: Document): Result.Result<Document, UpdateError>{
        if(Text.equal(doc.title, "")) return #err(#InvalidData{field = "title"; reason = #EmptyString;});
        if(Text.equal(doc.description, "")) return #err(#InvalidData{field = "description"; reason = #EmptyString;});
        if(Text.equal(doc.url, "")) return #err(#InvalidData{field = "URL"; reason = #EmptyString;});
        if(doc.uploadDate > Time.now()) return #err(#InvalidData{field = "Upload Date"; reason = #CannotBeSetInTheFuture;});
        return #ok(doc);
    };

    func mutateDocument(arg: DocumentUArg, document: Document): Document {
        {
            document with
            title           = PropHelper.get(arg.title, document.title);
            description     = PropHelper.get(arg.description, document.description);
            url             = PropHelper.get(arg.url, document.url);
            documentType    = PropHelper.get(arg.documentType, document.documentType);
        };
    };

     public func createDocument(arg: DocumentCArg, property: Property): AdministrativeIntentResult {        
        let newId = property.administrative.documentId + 1;
        let newDocument : Document = {
            arg with 
            id = newId;
            uploadDate = Time.now();
        };
        switch(validateDocument(newDocument)){
            case(#err(e)) return #Err(e); 
            case(_) return #Ok(#Documents (#Create (newDocument, newId)));
        };
    };

    public func deleteDocument(property: Property, id: Nat): AdministrativeIntentResult {
        switch(PropHelper.getElementByKey(property.administrative.documents, id)){
            case(null){return #Err(#InvalidElementId)};
            case(_){return #Ok(#Documents(#Delete(id)))}
        }
    };

    public func writeDocument(action: Actions<DocumentCArg, (DocumentUArg, Nat)>, property: Property): UpdateResult {
        let result = switch(action){
            case(#Create(arg)){
                createDocument(arg, property);
            };
            case(#Update(arg, id)){
                createUpdatedDocument(arg, property, id);
            };
            case(#Delete(id)){
                deleteDocument(property, id);
            };
        };

        applyAdministrativeUpdate(result, property, #Document(action));
    };

    func validateNote(note: Note): Result.Result<Note, UpdateError>{
        if(Text.equal(note.title, "")) return #err(#InvalidData{field = "title"; reason = #EmptyString;});
        if(Text.equal(note.content, "")) return #err(#InvalidData{field = "content"; reason = #EmptyString;});
        if(Option.get(note.date, Time.now()) > Time.now()) return #err(#InvalidData{field = "Upload Date"; reason = #CannotBeSetInTheFuture;});
        if(Principal.isAnonymous(note.author)) return #err(#InvalidData{field= "author"; reason = #Anonymous;});
        return #ok(note);
    };

    func mutateNote(arg: NoteUArg, note: Note): Note {
        {
            note with
            title   = PropHelper.get(arg.title, note.title);
            content = PropHelper.get(arg.content, note.content);
            date    = PropHelper.getNullable(arg.date, note.date);
        };
    };

    func createUpdatedNote(arg: NoteUArg, property: Property, id: Nat): AdministrativeIntentResult {
        switch(PropHelper.getElementByKey(property.administrative.notes, id)){
            case(?note){
                let updatedNote = mutateNote(arg, note);
                switch(validateNote(updatedNote)){case(#err(e)) return #Err(e); case(_) {}};
                return #Ok(#Notes (#Update (updatedNote, id)));
            };
            case(null){
                return #Err(#InvalidElementId)
            };
        };
    };

     public func createNote(arg: NoteCArg, property: Property, caller: Principal): AdministrativeIntentResult {        
        let newId = property.administrative.notesId + 1;
        let newNote: Note = {
            arg with 
            id = newId;
            author = caller;
        };
        switch(validateNote(newNote)){
            case(#err(e)) return #Err(e); 
            case(_) return #Ok(#Notes (#Create (newNote, newId)));
        };
    };

    public func deleteNote(property: Property, id: Nat): AdministrativeIntentResult {
        switch(PropHelper.getElementByKey(property.administrative.notes, id)){
            case(null){return #Err(#InvalidElementId)};
            case(_){return #Ok(#Notes(#Delete(id)))}
        }
    };

    public func writeNote(action: Actions<NoteCArg, (NoteUArg, Nat)>, property: Property, caller: Principal): UpdateResult {
        let result = switch(action){
            case(#Create(arg)){
                createNote(arg, property, caller);
            };
            case(#Update(arg, id)){
                createUpdatedNote(arg, property, id);
            };
            case(#Delete(id)){
                deleteNote(property, id);
            };
        };

        applyAdministrativeUpdate(result, property, #Note(action));
    };

    public func applyAdministrativeUpdate<C,U>(intent: AdministrativeIntentResult, property: Property, action: What): UpdateResult {
        let admin = switch(intent){
            case(#Ok(#Insurance(action))){
                {
                    property.administrative with
                    insuranceId = PropHelper.updateId(action, property.administrative.insuranceId);
                    insurance = PropHelper.performAction(action, property.administrative.insurance);
                };
            };
            case(#Ok(#Documents(action))){
                {
                    property.administrative with
                    documentId = PropHelper.updateId(action, property.administrative.documentId);
                    documents = PropHelper.performAction(action, property.administrative.documents);
                };
            };
            case(#Ok(#Notes(action))){
                {
                    property.administrative with
                    notesId = PropHelper.updateId(action, property.administrative.notesId);
                    notes = PropHelper.performAction(action, property.administrative.notes);
                };
            };
            case(#Err(e)){
                return #Err(e)
            };  
        };
        PropHelper.updateProperty(#Administrative(admin), property, action);
    };




    






}