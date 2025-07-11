import UnstableTypes "unstableTypes";
import Types "../types";
import PropHelper "../propHelper";
import HashMap "mo:base/HashMap";
import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Array "mo:base/Array";
import Text "mo:base/Text";

module {
    type PropertyUnstable = UnstableTypes.PropertyUnstable;
    type PropertyDetailsUnstable = UnstableTypes.PropertyDetailsUnstable;
    type LocationDetailsUnstable = UnstableTypes.LocationDetailsUnstable;
    type PhysicalDetailsUnstable = UnstableTypes.PhysicalDetailsUnstable;
    type AdditionalDetailsUnstable = UnstableTypes.AdditionalDetailsUnstable;
    type AdministrativeInfoUnstable = UnstableTypes.AdministrativeInfoUnstable;
    type OperationalInfoUnstable = UnstableTypes.OperationalInfoUnstable;
    type FinancialsUnstable = UnstableTypes.FinancialsUnstable;
    type InvestmentDetailsUnstable = UnstableTypes.InvestmentDetailsUnstable;
    type InsurancePolicyUnstable = UnstableTypes.InsurancePolicyUnstable;
    type DocumentUnstable = UnstableTypes.DocumentUnstable;
    type NoteUnstable = UnstableTypes.NoteUnstable;
    type TenantUnstable = UnstableTypes.TenantUnstable;
    type PaymentUnstable = UnstableTypes.PaymentUnstable;
    type MaintenanceRecordUnstable = UnstableTypes.MaintenanceRecordUnstable;
    type InspectionRecordUnstable = UnstableTypes.InspectionRecordUnstable;
    type ValuationRecordUnstable = UnstableTypes.ValuationRecordUnstable;

    public func toStableProperty(pu: PropertyUnstable): Types.Property {
        {
            id = pu.id;
            details = toStablePropertyDetails(pu.details);
            financials = toStableFinancials(pu.financials);
            administrative = toStableAdministrativeInfo(pu.administrative);
            operational = toStableOperationalInfo(pu.operational);
            nftMarketplace = toStableNFTMarketplace(pu.nftMarketplace);
            updates = Buffer.toArray(pu.updates);
        }
    };

    public func toStableNFTMarketplace(m: UnstableTypes.NFTMarketplaceUnstable): Types.NFTMarketplace {
        {
            collectionId = m.collectionId;
            listId = m.listId;
            listings = Iter.toArray(m.listings.entries());
            royalty = m.royalty;
        }
    };

    type MiscellaneousUnstable = UnstableTypes.MiscellaneousUnstable;

    public func toStablePropertyDetails(pd: PropertyDetailsUnstable): Types.PropertyDetails {
        {
            location = toStableLocationDetails(pd.location);
            physical = toStablePhysicalDetails(pd.physical);
            additional = toStableAdditionalDetails(pd.additional);
            misc = toStableMiscellaneous(pd.misc);
        }
    };

    public func toStableMiscellaneous(misc: MiscellaneousUnstable): Types.Miscellaneous {
        {
            description = misc.description;
            imageId = misc.imageId;
            images = Array.sort<(Nat, Text)>(Iter.toArray(misc.images.entries()),func ((a, _), (b, _)) = Nat.compare(a, b)); 
        }
    };  

    public func toStableLocationDetails(l: LocationDetailsUnstable): Types.LocationDetails {
        {
            name = l.name;
            addressLine1 = l.addressLine1;
            addressLine2 = l.addressLine2;
            addressLine3 = l.addressLine3;
            addressLine4 = l.addressLine4;
            location = l.location;
            postcode = l.postcode;
        }
    };

    public func toStablePhysicalDetails(p: PhysicalDetailsUnstable): Types.PhysicalDetails {
        {
            lastRenovation = p.lastRenovation;
            yearBuilt = p.yearBuilt;
            squareFootage = p.squareFootage;
            beds = p.beds;
            baths = p.baths;
        }
    };

    public func toStableAdditionalDetails(a: AdditionalDetailsUnstable): Types.AdditionalDetails {
        {
            crimeScore = a.crimeScore;
            schoolScore = a.schoolScore;
            affordability = a.affordability;
            floodZone = a.floodZone;
        }
    };

    public func toStableAdministrativeInfo(a: AdministrativeInfoUnstable): Types.AdministrativeInfo {
        {
            documentId = a.documentId;
            insuranceId = a.insuranceId;
            notesId = a.notesId;
            insurance = sortedArrayConverter<InsurancePolicyUnstable, Types.InsurancePolicy>(a.insurance, toStableInsurancePolicy);
            documents = sortedArrayConverter<DocumentUnstable, Types.Document>(a.documents, toStableDocument);
            notes = sortedArrayConverter<NoteUnstable, Types.Note>(a.notes, toStableNote); 
        }
    };

    public func toStableOperationalInfo(o: OperationalInfoUnstable): Types.OperationalInfo {
        {
            tenantId = o.tenantId;
            maintenanceId = o.maintenanceId;
            inspectionsId = o.inspectionsId;
            tenants = sortedArrayConverter<TenantUnstable, Types.Tenant>(o.tenants, toStableTenant);
            maintenance = sortedArrayConverter<MaintenanceRecordUnstable, Types.MaintenanceRecord>(o.maintenance, toStableMaintenanceRecord);
            inspections = sortedArrayConverter<InspectionRecordUnstable, Types.InspectionRecord>(o.inspections, toStableInspectionRecord);
        }
    };

    func sortedArrayConverter<U, S>(hashMap: HashMap.HashMap<Nat, U>, toStable: U -> S): [(Nat, S)]{
        let array = Iter.toArray<(Nat, S)>(
            Iter.map<(Nat, U), (Nat, S)>(
                hashMap.entries(), 
                func ((k, v)) = (k, toStable(v))
        ));
        Array.sort<(Nat, S)>(
            array,
            func ((a, _), (b, _)) = Nat.compare(a, b)
        )
    };

    public func toStableFinancials(f: FinancialsUnstable): Types.Financials {
        {
            currentValue = f.currentValue;
            investment = toStableInvestmentDetails(f.investment);
            pricePerSqFoot = f.pricePerSqFoot;
            valuationId = f.valuationId;
            valuations = sortedArrayConverter<ValuationRecordUnstable, Types.ValuationRecord>(f.valuations, toStableValuationRecord);
            monthlyRent = f.monthlyRent;
            yield = f.yield;
        }
    };

    public func toStableInvestmentDetails(i: InvestmentDetailsUnstable): Types.InvestmentDetails {
        {
            totalInvestmentValue = i.totalInvestmentValue;
            platformFee = i.platformFee;
            initialMaintenanceReserve = i.initialMaintenanceReserve;
            purchasePrice = i.purchasePrice;
        }
    };
    public func toStableInsurancePolicy(x: InsurancePolicyUnstable): Types.InsurancePolicy {
        {
            id = x.id;
            policyNumber = x.policyNumber;
            provider = x.provider;
            startDate = x.startDate;
            endDate = x.endDate;
            premium = x.premium;
            paymentFrequency = x.paymentFrequency;
            nextPaymentDate = x.nextPaymentDate;
            contactInfo = x.contactInfo;
        }
    };

    public func toStableDocument(x: DocumentUnstable): Types.Document {
        {
            id = x.id;
            uploadDate = x.uploadDate;
            title = x.title;
            description = x.description;
            documentType = x.documentType;
            url = x.url;
        }
    };

    public func toStableNote(x: NoteUnstable): Types.Note {
        {
            id = x.id;
            date = x.date;
            title = x.title;
            content = x.content;
            author = x.author;
        }
    };

    public func toStableTenant(x: TenantUnstable): Types.Tenant {
        {
            id = x.id;
            leadTenant = x.leadTenant;
            otherTenants = Buffer.toArray(x.otherTenants);
            principal = x.principal;
            monthlyRent = x.monthlyRent;
            deposit = x.deposit;
            leaseStartDate = x.leaseStartDate;
            contractLength = x.contractLength;
            paymentHistory = Iter.toArray<Types.Payment>(Iter.map<PaymentUnstable, Types.Payment>(x.paymentHistory.vals(), func (p) = toStablePayment(p)));
        }
    };


    public func toStablePayment(x: PaymentUnstable): Types.Payment {
        {
            id = x.id;
            amount = x.amount;
            date = x.date;
            method = x.method;
        }
    };

    public func toStableMaintenanceRecord(x: MaintenanceRecordUnstable): Types.MaintenanceRecord {
        {
            id = x.id;
            description = x.description;
            dateCompleted = x.dateCompleted;
            cost = x.cost;
            contractor = x.contractor;
            status = x.status;
            paymentMethod = x.paymentMethod;
            dateReported = x.dateReported;
        }
    };

    public func toStableInspectionRecord(x: InspectionRecordUnstable): Types.InspectionRecord {
        {
            id = x.id;
            inspectorName = x.inspectorName;
            date = x.date;
            findings = x.findings;
            actionRequired = x.actionRequired;
            followUpDate = x.followUpDate;
            appraiser = x.appraiser;
        }
    };

    public func toStableValuationRecord(x: UnstableTypes.ValuationRecordUnstable): Types.ValuationRecord {
        {
            id = x.id;
            value = x.value;
            method = x.method;
            date = x.date;
            appraiser = x.appraiser;
        }
    };


    /////////////////////////////////////
    //Converting Stable to Unstable Types
    //////////////////////////////////////
    public func fromStableProperty(p: Types.Property): UnstableTypes.PropertyUnstable {
        {
            var id = p.id;
            var details = fromStablePropertyDetails(p.details);
            var financials = fromStableFinancials(p.financials);
            var administrative = fromStableAdministrativeInfo(p.administrative);
            var operational = fromStableOperationalInfo(p.operational);
            var nftMarketplace = fromStableNFTMarketplace(p.nftMarketplace);
            var updates = Buffer.fromArray(p.updates);
        }
    };

    public func fromStableNFTMarketplace(m: Types.NFTMarketplace): UnstableTypes.NFTMarketplaceUnstable {
        {
            var collectionId = m.collectionId;
            var listId = m.listId;
            var listings = HashMap.fromIter<Nat, Types.Listing>(m.listings.vals(), 0, Nat.equal, PropHelper.natToHash);
            var royalty = m.royalty;
        }
    };

    public func fromStablePropertyDetails(pd: Types.PropertyDetails): UnstableTypes.PropertyDetailsUnstable {
        {
            var location = fromStableLocationDetails(pd.location);
            var physical = fromStablePhysicalDetails(pd.physical);
            var additional = fromStableAdditionalDetails(pd.additional);
            var misc = fromStableMiscellaneous(pd.misc);
        }
    };

    public func fromStableLocationDetails(l: Types.LocationDetails): UnstableTypes.LocationDetailsUnstable {
        {
            var name = l.name;
            var addressLine1 = l.addressLine1;
            var addressLine2 = l.addressLine2;
            var addressLine3 = l.addressLine3;
            var addressLine4 = l.addressLine4;
            var location = l.location;
            var postcode = l.postcode;
        }
    };

    public func fromStablePhysicalDetails(p: Types.PhysicalDetails): UnstableTypes.PhysicalDetailsUnstable {
        {
            var lastRenovation = p.lastRenovation;
            var yearBuilt = p.yearBuilt;
            var squareFootage = p.squareFootage;
            var beds = p.beds;
            var baths = p.baths;
        }
    };

    public func fromStableAdditionalDetails(a: Types.AdditionalDetails): UnstableTypes.AdditionalDetailsUnstable {
        {
            var crimeScore = a.crimeScore;
            var schoolScore = a.schoolScore;
            var affordability = a.affordability;
            var floodZone = a.floodZone;
        }
    };

       
    public func fromStableMiscellaneous(misc: Types.Miscellaneous): MiscellaneousUnstable {
        {
            var description = misc.description;
            var imageId = misc.imageId;
            images = HashMap.fromIter<Nat, Text>(misc.images.vals(), misc.images.size(), Nat.equal, PropHelper.natToHash)
        }
    };  

    public func fromStableAdministrativeInfo(a: Types.AdministrativeInfo): UnstableTypes.AdministrativeInfoUnstable {
        let insurance = HashMap.fromIter<Nat, UnstableTypes.InsurancePolicyUnstable>(
            Iter.map<(Nat, Types.InsurancePolicy), (Nat, UnstableTypes.InsurancePolicyUnstable)>(a.insurance.vals(), func ((k, v)) = (k, fromStableInsurancePolicy(v))),
            0,
            Nat.equal,
            PropHelper.natToHash
        );
        let documents = HashMap.fromIter<Nat, UnstableTypes.DocumentUnstable>(
            Iter.map<(Nat, Types.Document), (Nat, UnstableTypes.DocumentUnstable)>(a.documents.vals(), func ((k, v)) = (k, fromStableDocument(v))),
            0,
            Nat.equal,
            PropHelper.natToHash
        );
        let notes = HashMap.fromIter<Nat, UnstableTypes.NoteUnstable>(
            Iter.map<(Nat, Types.Note), (Nat, UnstableTypes.NoteUnstable)>(a.notes.vals(), func ((k, v)) = (k, fromStableNote(v))),
            0,
            Nat.equal,
            PropHelper.natToHash
        );
        {
            var documentId = a.documentId;
            var insuranceId = a.insuranceId;
            var notesId = a.notesId;
            var insurance = insurance;
            var documents = documents;
            var notes = notes;
        }
    };

    public func fromStableOperationalInfo(o: Types.OperationalInfo): UnstableTypes.OperationalInfoUnstable {
        {
            var tenantId = o.tenantId;
            var maintenanceId = o.maintenanceId;
            var inspectionsId = o.inspectionsId;
            var tenants = HashMap.fromIter<Nat, UnstableTypes.TenantUnstable>(
                Iter.map<(Nat, Types.Tenant), (Nat, UnstableTypes.TenantUnstable)>(o.tenants.vals(), func ((k, v)) = (k, fromStableTenant(v))),
                0,
                Nat.equal,
                PropHelper.natToHash
            );
            var maintenance = HashMap.fromIter<Nat, UnstableTypes.MaintenanceRecordUnstable>(
                Iter.map<(Nat, Types.MaintenanceRecord), (Nat, UnstableTypes.MaintenanceRecordUnstable)>(o.maintenance.vals(), func ((k, v)) = (k, fromStableMaintenanceRecord(v))),
                0,
                Nat.equal,
                PropHelper.natToHash
            );
            var inspections = HashMap.fromIter<Nat, UnstableTypes.InspectionRecordUnstable>(
                Iter.map<(Nat, Types.InspectionRecord), (Nat, UnstableTypes.InspectionRecordUnstable)>(o.inspections.vals(), func ((k, v)) = (k, fromStableInspectionRecord(v))),
                0,
                Nat.equal,
                PropHelper.natToHash
            );
        }
    };

    public func fromStableFinancials(f: Types.Financials): UnstableTypes.FinancialsUnstable {
        {
            var investment = fromStableInvestmentDetails(f.investment);
            var pricePerSqFoot = f.pricePerSqFoot;
            var valuationId = f.valuationId;
            var valuations = HashMap.fromIter<Nat, UnstableTypes.ValuationRecordUnstable>(
                Iter.map<(Nat, Types.ValuationRecord), (Nat, UnstableTypes.ValuationRecordUnstable)>(f.valuations.vals(), func ((k, v)) = (k, fromStableValuationRecord(v))),
                0,
                Nat.equal,
                PropHelper.natToHash
            );
            var monthlyRent = f.monthlyRent;
            var yield = f.yield;
            var currentValue = f.currentValue;
        }
    };

    public func fromStableInvestmentDetails(i: Types.InvestmentDetails): UnstableTypes.InvestmentDetailsUnstable {
        {
            var totalInvestmentValue = i.totalInvestmentValue;
            var platformFee = i.platformFee;
            var initialMaintenanceReserve = i.initialMaintenanceReserve;
            var purchasePrice = i.purchasePrice;
        }
    };

    public func fromStableInsurancePolicy(x: Types.InsurancePolicy): UnstableTypes.InsurancePolicyUnstable {
        {
            var id = x.id;
            var policyNumber = x.policyNumber;
            var provider = x.provider;
            var startDate = x.startDate;
            var endDate = x.endDate;
            var premium = x.premium;
            var paymentFrequency = x.paymentFrequency;
            var nextPaymentDate = x.nextPaymentDate;
            var contactInfo = x.contactInfo;
        }
    };

    public func fromStableDocument(x: Types.Document): UnstableTypes.DocumentUnstable {
        {
            var id = x.id;
            var uploadDate = x.uploadDate;
            var title = x.title;
            var description = x.description;
            var documentType = x.documentType;
            var url = x.url;
        }
    };

    public func fromStableNote(x: Types.Note): UnstableTypes.NoteUnstable {
        {
            var id = x.id;
            var date = x.date;
            var title = x.title;
            var content = x.content;
            var author = x.author;
        }
    };

    public func fromStableTenant(x: Types.Tenant): UnstableTypes.TenantUnstable {
        {
            var id = x.id;
            var leadTenant = x.leadTenant;
            var otherTenants = Buffer.fromArray(x.otherTenants);
            var principal = x.principal;
            var monthlyRent = x.monthlyRent;
            var deposit = x.deposit;
            var leaseStartDate = x.leaseStartDate;
            var contractLength = x.contractLength;
            var paymentHistory = Buffer.fromArray(
                Iter.toArray(Iter.map<Types.Payment, UnstableTypes.PaymentUnstable>(x.paymentHistory.vals(), func (p) = fromStablePayment(p)))
            );
        }
    };

    public func fromStablePayment(x: Types.Payment): UnstableTypes.PaymentUnstable {
        {
            var id = x.id;
            var amount = x.amount;
            var date = x.date;
            var method = x.method;
        }
    };

    public func fromStableMaintenanceRecord(x: Types.MaintenanceRecord): UnstableTypes.MaintenanceRecordUnstable {
        {
            var id = x.id;
            var description = x.description;
            var dateCompleted = x.dateCompleted;
            var cost = x.cost;
            var contractor = x.contractor;
            var status = x.status;
            var paymentMethod = x.paymentMethod;
            var dateReported = x.dateReported;
        }
    };

    public func fromStableInspectionRecord(x: Types.InspectionRecord): UnstableTypes.InspectionRecordUnstable {
        {
            var id = x.id;
            var inspectorName = x.inspectorName;
            var date = x.date;
            var findings = x.findings;
            var actionRequired = x.actionRequired;
            var followUpDate = x.followUpDate;
            var appraiser = x.appraiser;
        }
    };

    public func fromStableValuationRecord(x: Types.ValuationRecord): UnstableTypes.ValuationRecordUnstable {
        {
            var id = x.id;
            var value = x.value;
            var method = x.method;
            var date = x.date;
            var appraiser = x.appraiser;
        }
    };
};