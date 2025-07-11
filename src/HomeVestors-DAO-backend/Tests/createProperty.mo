import Types "../types";
import UnstableTypes "unstableTypes";
import Stables "stables";
import Time "mo:base/Time";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Utils "utils";
import Arg "createArgs";

module {
    type Property = Types.Property;
    type PropertyDetails = Types.PropertyDetails;
    type Financials = Types.Financials;
    type AdministrativeInfo = Types.AdministrativeInfo;
    type OperationalInfo = Types.OperationalInfo;
    type NFTMarketplace = Types.NFTMarketplace;
    type Result = Types.Result;
    type LocationDetails = Types.LocationDetails;
    type PhysicalDetails = Types.PhysicalDetails;
    type AdditionalDetails = Types.AdditionalDetails;
    type InvestmentDetails = Types.InvestmentDetails;
    type Note = Types.Note;
    type NoteCArg = Types.NoteCArg;
    type Document = Types.Document;
    type NoteUArg = Types.NoteUArg;
    type DocumentCArg = Types.DocumentCArg;
    type DocumentUArg = Types.DocumentUArg;
    type InsurancePolicyCArg = Types.InsurancePolicyCArg;
    type InsurancePolicyUArg = Types.InsurancePolicyUArg;
    type InsurancePolicy = Types.InsurancePolicy;
    type MaintenanceRecord = Types.MaintenanceRecord;
    type InspectionRecord = Types.InspectionRecord;
    type ValuationRecord = Types.ValuationRecord;
    type Tenant = Types.Tenant;
    type Miscellaneous = Types.Miscellaneous;
    
    public func createLocationDetails(): LocationDetails {
        {
            name = "";
            addressLine1 = "";
            addressLine2 = "";
            addressLine3 = null;
            addressLine4 = null;
            location = "";
            postcode = "";
        }
    };

    public func createPhysicalDetails(): PhysicalDetails{
       {
            lastRenovation = 2000;
            yearBuilt = 0;
            squareFootage = 100;
            beds = 0;
            baths = 0;
       } 
    };

    public func createAdditionalDetails(): AdditionalDetails {
        {
            crimeScore = 150;
            schoolScore = 5;
            affordability = 0;
            floodZone = false;
        }
    };

    public func createPropertyDetails(): PropertyDetails {
        {
            location = createLocationDetails();
            physical = createPhysicalDetails();
            additional = createAdditionalDetails();
            misc = createMisc();
        };
    };

    public func createMisc(): Miscellaneous {
      {
        description = "updated description of property";
        imageId = 0;
        images = [(0, "initial url to image")];
      }
    };

    public func createInvestmentDetails(): InvestmentDetails {
        {
            totalInvestmentValue = 0;
            platformFee = 0;
            initialMaintenanceReserve = 0;
            purchasePrice = 0;
        }
    };

    public func createFinancials(): Financials {
        {
            currentValue = 0;
            investment = createInvestmentDetails();
            pricePerSqFoot =0;
            valuationId = 0;
            valuations = [(0, validValuationRecord(0, Utils.getCallers().admin))];
            monthlyRent = 0;
            yield = 0.0;
        }
    };

    public func createAdministrativeInfo(): AdministrativeInfo {
        {
            documentId = 0;
            insuranceId = 0;
            notesId = 0;
            insurance = [(0, validInsurancePolicy(0, Arg.createInsurancePolicyCArg()))];
            documents = [(0, validDocument(0, Arg.createDocumentCArg()))];
            notes = [(0, validNote(0, Arg.createNoteCArg()))];
        }
    };

    public func createOperationalInfo(): OperationalInfo {
        {
            tenantId = 0;
            maintenanceId = 0;
            inspectionsId = 0;
            tenants = [(0, validTenant(0, Utils.getCallers().tenant1))];
            maintenance = [(0, validMaintenanceRecord(0))];
            inspections = [(0, validInspectionRecord(0, Utils.getCallers().admin))];
        }
    };

    public func createNFTMarketplace(): NFTMarketplace {
        {
            collectionId = Principal.fromText("vq2za-kqaaa-aaaas-amlvq-cai");
            listId = 0;
            listings = [];
            royalty = 0;
        }
    };

    public func createBlankProperty(): UnstableTypes.PropertyUnstable {
        Stables.fromStableProperty({
            id = 0;
            details = createPropertyDetails();
            financials = createFinancials();
            administrative = createAdministrativeInfo();
            operational = createOperationalInfo();
            nftMarketplace = createNFTMarketplace();
            updates = [];
        })
    };

    public func validNote(id: Nat, arg: NoteCArg) : Note {
      {
        id = id;
        title = arg.title;
        content = arg.content;
        date = arg.date;
        author = Utils.getCallers().admin;
      }
    };

    public func updatedNote(arg: NoteUArg, id: Nat): Note {
        {
            id = id;
            title = Option.get(arg.title, "");
            content = Option.get(arg.content, "");
            date = arg.date;
            author = Utils.getCallers().admin;
        }
    };

    public func validDocument(id: Nat, doc: DocumentCArg) : Document {
      {
        doc with 
        id = id;
        uploadDate = Time.now();
      }
    };

    func nullText(text: ?Text): Text{
        Option.get(text, "");
    };

    func nullInt(int: ?Int): Int{
        Option.get(int, 0);
    };
    
    func nullNat(nat: ?Nat): Nat{
        Option.get(nat, 0);
    };

    public func updateValidDocument(doc: DocumentUArg, id: Nat) : Document {
      {
        id = id;
        title = nullText(doc.title);
        description = nullText(doc.description);
        documentType = Option.get(doc.documentType, #EPC);
        url = nullText(doc.url);
        uploadDate = Time.now();
      }
    };

    type TenantCArg = Types.TenantCArg;
    type TenantUArg = Types.TenantUArg;
    type MaintenanceRecordCArg = Types.MaintenanceRecordCArg;
    type MaintenanceRecordUArg = Types.MaintenanceRecordUArg;
    public func createValidTenant(tenant: TenantCArg, id: Nat): Tenant {
      {
        tenant with
        id; 
        paymentHistory = [];
      }
    };

    public func updateValidTenant(arg: TenantUArg, id: Nat): Tenant {
      {
        id;
        leadTenant = nullText(arg.leadTenant);
        otherTenants = Option.get(arg.otherTenants, []);
        principal = arg.principal;
        monthlyRent = nullNat(arg.monthlyRent);
        deposit = nullNat(arg.deposit);
        leaseStartDate = nullInt(arg.leaseStartDate);
        contractLength = Option.get(arg.contractLength, #Rolling); 
        paymentHistory = Option.get(arg.paymentHistory, []);
      }
    };

    public func createValidMaintenanceRecord(arg: MaintenanceRecordCArg, id: Nat): MaintenanceRecord {
      {
        arg with
        id; 
      }
    };

     public func updateValidMaintenanceRecord(arg: MaintenanceRecordUArg, id: Nat): MaintenanceRecord {
      {
        id;
        description = nullText(arg.description);
        dateCompleted = arg.dateCompleted;
        cost = arg.cost;
        contractor = arg.contractor;
        status = Option.get(arg.status, #Pending);
        paymentMethod = arg.paymentMethod;
        dateReported = arg.dateReported;
      }
    };

    type InspectionRecordCArg = Types.InspectionRecordCArg;
    type InspectionRecordUArg = Types.InspectionRecordUArg;
    
    public func createValidInspectionRecord(arg: InspectionRecordCArg, id: Nat): InspectionRecord {
      {
        arg with
        id; 
        appraiser = Utils.getCallers().admin;
      }
    };

    public func updateValidInspectionRecord(arg: InspectionRecordUArg, id: Nat): InspectionRecord {
      {
        id;
        inspectorName = nullText(arg.inspectorName);
        date = arg.date;
        findings = nullText(arg.findings);
        actionRequired = arg.actionRequired;
        followUpDate = arg.followUpDate; 
        appraiser = Utils.getCallers().admin;
      }
    };

    type ValuationRecordCArg = Types.ValuationRecordCArg;
    type ValuationRecordUArg = Types.ValuationRecordUArg;

      public func createValidValuationRecord(arg: ValuationRecordCArg, id: Nat): ValuationRecord {
      {
        arg with
        id; 
        date = Time.now();
        appraiser = Utils.getCallers().admin;
      }
    };

    public func updateValidValuationRecord(arg: ValuationRecordUArg, id: Nat): ValuationRecord {
      {
        id; 
        value = nullNat(arg.value);
        method = Option.get(arg.method, #Online);
        date = Time.now();
        appraiser = Utils.getCallers().admin;
      }
    };
    

    public func validInsurancePolicy(id: Nat, insurance: InsurancePolicyCArg) : InsurancePolicy {
      {
        insurance with 
        id = id;
      }
    };

    public func updateValidInsurancePolicy(insurance: InsurancePolicyUArg, id: Nat) : InsurancePolicy {
      {
        id = id;
        policyNumber = nullText(insurance.policyNumber);
        provider = nullText(insurance.provider);
        startDate = Time.now();
        endDate = insurance.endDate; // valid future end date
        premium = nullNat(insurance.premium);
        paymentFrequency = Option.get(insurance.paymentFrequency, #Monthly);
        nextPaymentDate = nullInt(insurance.nextPaymentDate);
        contactInfo = nullText(insurance.contactInfo);
      }
    };

    public func validUnstablePhysicalDetails(): UnstableTypes.PhysicalDetailsUnstable {
        Stables.fromStablePhysicalDetails(createPhysicalDetails());
    };

    public func validUnstableAdditionalDetails(): UnstableTypes.AdditionalDetailsUnstable {
        Stables.fromStableAdditionalDetails(createAdditionalDetails());
    };

    public func validUnstableInsurancePolicy(id: Nat): UnstableTypes.InsurancePolicyUnstable {
        Stables.fromStableInsurancePolicy(validInsurancePolicy(id, Arg.createInsurancePolicyCArg()));
    };

    public func validUnstableDocument(id: Nat): UnstableTypes.DocumentUnstable {
        Stables.fromStableDocument(validDocument(id, Arg.createDocumentCArg()));
    };

    public func validUnstableMaintenanceRecord(id: Nat): UnstableTypes.MaintenanceRecordUnstable {
        Stables.fromStableMaintenanceRecord(validMaintenanceRecord(id));
    };

    public func validUnstableInspectionRecord(id: Nat, inspector: Principal): UnstableTypes.InspectionRecordUnstable {
        Stables.fromStableInspectionRecord(validInspectionRecord(id, inspector));
    };

    public func validUnstableValuationRecord(id: Nat, appraiser: Principal): UnstableTypes.ValuationRecordUnstable {
        Stables.fromStableValuationRecord(validValuationRecord(id, appraiser));
    };

    public func validUnstableTenant(id: Nat, principal: Principal): UnstableTypes.TenantUnstable {
        Stables.fromStableTenant(validTenant(id, principal));
    };

    public func validMaintenanceRecord(id: Nat) : MaintenanceRecord {
      {
        id = id;
        description = "Boiler repair";
        dateCompleted = ?Time.now();
        cost = ?125.0;
        contractor = ?"FixIt Ltd";
        status = #Completed;
        paymentMethod = ?#BankTransfer;
        dateReported = ?(Time.now() - 100_000_000);
      }
    };

    public func validInspectionRecord(id: Nat, inspector: Principal) : InspectionRecord {
      {
        id = id;
        inspectorName = "Inspector Gadget";
        date = ?Time.now();
        findings = "All fine.";
        actionRequired = ?"None";
        followUpDate = ?(Time.now() + 1_000_000);
        appraiser = inspector;
      }
    };

    public func validValuationRecord(id: Nat, appraiser: Principal) : ValuationRecord {
      {
        id = id;
        value = 250_000;
        method = #Appraisal;
        date = Time.now();
        appraiser = appraiser;
      }
    };

    public func validTenant(id: Nat, principal: Principal) : Tenant {
      {
        id = id;
        leadTenant = "Jane Doe";
        otherTenants = ["John Doe"];
        principal = ?principal;
        monthlyRent = 950;
        deposit = 1000;
        leaseStartDate = Time.now();
        contractLength = #Annual;
        paymentHistory = [
          {
            id = 0;
            amount = 950;
            date = Time.now() - 2_000_000_000;
            method = #BankTransfer;
          }
        ];
      }
    };


}