import Types "types";
import Array "mo:base/Array";
import Hash "mo:base/Hash";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";

module PropertiesHelper {
   type Property = Types.Property;
   type Properties = Types.Properties;
   type Update = Types.Update;
   type InsurancePolicy = Types.InsurancePolicy;
   type Document = Types.Document;
   type Note = Types.Note;
   type ValuationRecord = Types.ValuationRecord;
   type Tenant = Types.Tenant;
   type MaintenanceRecord = Types.MaintenanceRecord;
   type InspectionRecord = Types.InspectionRecord;
   type Read = Types.Read;
   type ReadResult = Types.ReadResult;
   type Result = Types.Result;
   type ReadUnsanitized = Types.ReadUnsanitized;
   type GetPropertyResult = Types.GetPropertyResult;
   type UpdateResult = Types.UpdateResult;
   type Account = Types.Account;
   type Intent<T> = Types.Intent<T>;
   type What = Types.What;

    public func accountEqual(a : Account, b : Account) : Bool {
         Principal.equal(a.owner, b.owner) and
         blobEqual(a.subaccount, b.subaccount)
    };
  
    public func blobEqual(a : ?Blob, b : ?Blob) : Bool {
        switch (a, b) {
          case (null, null) true;
          case (?a, ?b) Blob.equal(a, b);
          case _ false;
        }
    };

    public func accountHash(account: Account): Hash.Hash {
        let ownerBlob = Principal.hash(account.owner);
        let subaccountBlob = switch (account.subaccount) {
            case null { Blob.hash(Blob.fromArray([])) };
            case (?sub) { Blob.hash(sub)};
        };
        return ownerBlob ^ subaccountBlob;
    };

    public func natToHash(n: Nat): Hash.Hash {
       Text.hash(Nat.toText(n));  
    };


    public func getNullable<T>(test: ?T, alternative: ?T): ?T {
        switch(test){
            case(?t) ?t;
            case(null) alternative;
        }
    };

     public func get<T>(test: ?T, alternative: T): T {
        switch(test){
            case(?t) t;
            case(null) alternative;
        }
    };

    public func getPropertyFromId(id: Nat, properties: Properties): GetPropertyResult {
        switch(properties.get(id)){
            case(null){
                return #Err();
            };
            case(?property){
                return #Ok(property);
            }
        }
    };

    public func getElementByKey<T>(arr: [(Nat, T)], key: Nat) : ?T {
        for ((k, v) in arr.vals()) {
            if (k == key) {
                return ?v;
            }
        };
        return null;
    };

    public func updateElementByKey<T>(arr: [(Nat, T)], key: Nat, newValue: T) : [(Nat, T)] {
        return Array.map<(Nat, T), (Nat, T)>(arr, func((k, v)) {
            if (k == key) {
                return (k, newValue);
            } else {
                return (k, v);
            }
        });
    };

    public func removeElementByKey<T>(arr: [(Nat, T)], key: Nat) : [(Nat, T)] {
        return Array.filter<(Nat, T)>(arr, func((k, v)) {
            k != key
        });
    };

    public func addElement<T>(arr: [(Nat, T)], key: Nat, value: T) : [(Nat, T)] {
        for ((k, v) in arr.vals()) {
            if (k == key) {
                return arr;
            }
        };
        return Array.append(arr, [(key, value)]);
    };
    
    public func addPropertyEvent(action: What, property: Property):  Property{
        {property with updates = Array.append(property.updates, [#Ok(action)])};
    };

    public func updateProperty<C,U>(update: Update, property: Property, action: What): UpdateResult {
        var updatedProperty = switch(update){
            case(#Details(d)){{property with details = d;}};
            case(#Financials(f)){{property with financials = f}};
            case(#Administrative(a)){{property with administrative = a}};
            case(#Operational(o)){{property with operational = o}};
            case(#NFTMarketplace(m)){{property with nftMarketplace = m}}
        };
        updatedProperty := addPropertyEvent(action, updatedProperty);
        return #Ok(updatedProperty);
    };

    public func updateId<T>(action: Intent<T>, currentId: Nat): Nat{
        switch(action){
            case(#Create(_)) return currentId + 1;
            case(_) return currentId;
        };
    };

    public func performAction<T>(action: Intent<T>, arr: [(Nat, T)]): [(Nat, T)]{
        switch(action){
            case(#Create(el, id)){
                return addElement<T>(arr, id, el);
            };
            case(#Update(el, id)){
                return updateElementByKey<T>(arr, id, el)
            };
            case(#Delete(id)){
                return removeElementByKey<T>(arr, id);
            }
        };
    };

    func lastEntry<T,V>(arr: [(T, V)]): ?V {
        if(arr.size() == 0) {
            return null
        } 
        else {
            let (_, v) = arr[arr.size() - 1];
            return ?v
        };
    };

    public func readPropertyData(p: Property, read: Read): ReadResult {
        let result :ReadUnsanitized = switch(read){
            case(#AllInsurance){ #AllInsurance(p.administrative.insurance)};
            case(#InsuranceById(id)){#Insurance(getElementByKey<InsurancePolicy>(p.administrative.insurance, id))};
            case(#AllDocuments){ #AllDocuments(p.administrative.documents)};
            case(#DocumentById(id)){#Document(getElementByKey<Document>(p.administrative.documents, id))};
            case(#AllNotes){ #AllNotes(p.administrative.notes)};
            case(#NoteById(id)){#Note(getElementByKey<Note>(p.administrative.notes, id))};
            case(#LastNote){#LastNote(lastEntry(p.administrative.notes))};
            case(#AllValuations){#AllValuations(p.financials.valuations)};
            case(#ValuationById(id)){#Valuation(getElementByKey<ValuationRecord>(p.financials.valuations, id))};
            case(#LastValuation){#LastValuation(lastEntry(p.financials.valuations))};
            case(#AllTenants){ #AllTenants(p.operational.tenants)};
            case(#CurrentTenant){#CurrentTenant(lastEntry(p.operational.tenants))};
            case(#TenantById(id)){#Tenant(getElementByKey<Tenant>(p.operational.tenants, id))};
            case(#TenantPaymentHistory(id)){#TenantPaymentHistory(switch(getElementByKey<Tenant>(p.operational.tenants, id)){case(null) null; case(?t) ?t.paymentHistory})};
            case(#AllMaintenance){ #AllMaintenance(p.operational.maintenance)};
            case(#MaintenanceById(id)){#Maintenance(getElementByKey<MaintenanceRecord>(p.operational.maintenance, id))};
            case(#LastMaintenance){#LastMaintenance(lastEntry(p.operational.maintenance))};
            case(#AllInspections){ #AllInspections(p.operational.inspections)};
            case(#InspectionById(id)){#Inspection(getElementByKey<InspectionRecord>(p.operational.inspections, id))};
            case(#LastInspection){#LastInspection(lastEntry(p.operational.inspections))};
            case(#PhysicalDetails){ #PhysicalDetails(p.details.physical)};
            case(#LocationDetails){#LocationDetails(p.details.location)};
            case(#AdditionalDetails){#AdditionalDetails(p.details.additional)};
            case(#Financials){ #Financials(p.financials)};
            case(#MonthlyRent){#MonthlyRent(p.financials.monthlyRent)};
            case(#UpdateResults){#UpdateResults(p.updates)};
            case(#UpdatedState){#UpdateResults(handleUpdateResults(p.updates, true))};
            case(#UpdateErrors){#UpdateResults(handleUpdateResults(p.updates, false))}
        };

        return sanitizeResult(result);
    };

    func handleUpdateResults(arr: [Result], updatedState: Bool): [Result]{
        let results = Buffer.Buffer<Result>(0);
        for(result in arr.vals()){
            switch(result, updatedState){
                case(#Ok(n), true){
                    results.add(#Ok(n));
                };
                case(#Err(n), false){
                    results.add(#Err(n));
                };
                case(_, _){};
            };
        };
        Iter.toArray(results.vals());
    };

    func handleArray<T>(arr: [(Nat, T)], result: ReadUnsanitized): ReadResult {
        if(arr.size() == 0){
            return #Err(#EmptyArray);
        };
        return #Ok(result);
    }; 


    func sanitizeResult(result: ReadUnsanitized): ReadResult {
       switch(result){
            case(#AllInsurance(d)){ handleArray(d, result)};
            case(#Insurance(null)){ #Err(#InvalidElementId)};
            case(#AllDocuments(d)){handleArray(d, result)};
            case(#Document(null)){#Err(#InvalidElementId)};
            case(#AllNotes(d)){handleArray(d, result)};
            case(#Note(null)){#Err(#InvalidElementId)};
            case(#LastNote(null)){#Err(#EmptyArray)};
            case(#AllValuations(d)){handleArray(d, result)};
            case(#Valuation(null)){#Err(#InvalidElementId)};
            case(#LastValuation(null)){#Err(#EmptyArray)};
            case(#AllTenants(d)){handleArray(d, result)};
            case(#Tenant(null)){#Err(#InvalidElementId)};
            case(#CurrentTenant(null)){#Err(#Vacant)};
            case(#AllMaintenance(d)){handleArray(d, result)};
            case(#Maintenance(null)){#Err(#InvalidElementId)};
            case(#LastMaintenance(null)){#Err(#EmptyArray)};
            case(#AllInspections(d)){handleArray(d, result)};
            case(#Inspection(null)){#Err(#InvalidElementId)};
            case(#LastInspection(null)){#Err(#EmptyArray)};
            case(_){return #Ok(result)}
        };
    };


    
}