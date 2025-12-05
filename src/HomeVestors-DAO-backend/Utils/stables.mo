import UnstableTypes "unstableTypes";
import Types "types";
import HashMap "mo:base/HashMap";
import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Array "mo:base/Array";
import Text "mo:base/Text";
import Order "mo:base/Order";
import Utils "utils";

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
            governance = fromPartialStableGovernance(pu.governance);
            updates = Buffer.toArray(pu.updates);
        }
    };

    public func toStableNFTMarketplace(m: UnstableTypes.NFTMarketplaceUnstable): Types.NFTMarketplace {
        {
            collectionId = m.collectionId;
            listId = m.listId;
            listings = Iter.toArray(m.listings.entries());
            timerIds = Iter.toArray(m.timerIds.entries());
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
            account = f.account;
            currentValue = f.currentValue;
            investment = toStableInvestmentDetails(f.investment);
            pricePerSqFoot = f.pricePerSqFoot;
            valuationId = f.valuationId;
            invoiceId = f.invoiceId;
            invoices = sortedArrayConverter<UnstableTypes.InvoiceUnstable, Types.Invoice>(f.invoices, toStableInvoice);
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
            var governance = toPartialStableGovernance(p.governance);
            var updates = Buffer.fromArray(p.updates);
        }
    };

    public func fromStableNFTMarketplace(m: Types.NFTMarketplace): UnstableTypes.NFTMarketplaceUnstable {
        {
            var collectionId = m.collectionId;
            var listId = m.listId;
            var listings = HashMap.fromIter<Nat, Types.Listing>(m.listings.vals(), 0, Nat.equal, Utils.natToHash);
            var timerIds = HashMap.fromIter<Nat, Nat>(m.timerIds.vals(), 0, Nat.equal, Utils.natToHash);
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
            images = HashMap.fromIter<Nat, Text>(misc.images.vals(), misc.images.size(), Nat.equal, Utils.natToHash)
        }
    };  

    public func fromStableAdministrativeInfo(a: Types.AdministrativeInfo): UnstableTypes.AdministrativeInfoUnstable {
        let insurance = HashMap.fromIter<Nat, UnstableTypes.InsurancePolicyUnstable>(
            Iter.map<(Nat, Types.InsurancePolicy), (Nat, UnstableTypes.InsurancePolicyUnstable)>(a.insurance.vals(), func ((k, v)) = (k, fromStableInsurancePolicy(v))),
            0,
            Nat.equal,
            Utils.natToHash
        );
        let documents = HashMap.fromIter<Nat, UnstableTypes.DocumentUnstable>(
            Iter.map<(Nat, Types.Document), (Nat, UnstableTypes.DocumentUnstable)>(a.documents.vals(), func ((k, v)) = (k, fromStableDocument(v))),
            0,
            Nat.equal,
            Utils.natToHash
        );
        let notes = HashMap.fromIter<Nat, UnstableTypes.NoteUnstable>(
            Iter.map<(Nat, Types.Note), (Nat, UnstableTypes.NoteUnstable)>(a.notes.vals(), func ((k, v)) = (k, fromStableNote(v))),
            0,
            Nat.equal,
            Utils.natToHash
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
                Utils.natToHash
            );
            var maintenance = HashMap.fromIter<Nat, UnstableTypes.MaintenanceRecordUnstable>(
                Iter.map<(Nat, Types.MaintenanceRecord), (Nat, UnstableTypes.MaintenanceRecordUnstable)>(o.maintenance.vals(), func ((k, v)) = (k, fromStableMaintenanceRecord(v))),
                0,
                Nat.equal,
                Utils.natToHash
            );
            var inspections = HashMap.fromIter<Nat, UnstableTypes.InspectionRecordUnstable>(
                Iter.map<(Nat, Types.InspectionRecord), (Nat, UnstableTypes.InspectionRecordUnstable)>(o.inspections.vals(), func ((k, v)) = (k, fromStableInspectionRecord(v))),
                0,
                Nat.equal,
                Utils.natToHash
            );
        }
    };

    public func fromStableFinancials(f: Types.Financials): UnstableTypes.FinancialsUnstable {
        {
            var account = f.account;
            var investment = fromStableInvestmentDetails(f.investment);
            var pricePerSqFoot = f.pricePerSqFoot;
            var valuationId = f.valuationId;
            var valuations = HashMap.fromIter<Nat, UnstableTypes.ValuationRecordUnstable>(
                Iter.map<(Nat, Types.ValuationRecord), (Nat, UnstableTypes.ValuationRecordUnstable)>(f.valuations.vals(), func ((k, v)) = (k, fromStableValuationRecord(v))),
                0,
                Nat.equal,
                Utils.natToHash
            );
            var invoiceId = f.invoiceId;
            var invoices = HashMap.fromIter<Nat, UnstableTypes.InvoiceUnstable>(
                Iter.map<(Nat, Types.Invoice), (Nat, UnstableTypes.InvoiceUnstable)>(f.invoices.vals(), func((k, v)) = (k, fromStableInvoice(v))),
                f.invoices.size(), 
                Nat.equal,
                Utils.natToHash
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

    ////////////////////////////////////////////////
    /////Partial Unstables
    ///////////////////////////////////////////////
    type MiscellaneousPartialUnstable = UnstableTypes.MiscellaneousPartialUnstable;
    type FinancialsPartialUnstable = UnstableTypes.FinancialsPartialUnstable;
    type AdministrativeInfoPartialUnstable = UnstableTypes.AdministrativeInfoPartialUnstable;
    type OperationalInfoPartialUnstable = UnstableTypes.OperationalInfoPartialUnstable;
    type GovernanceUnstable = UnstableTypes.GovernanceUnstable;
    type NftMarketplacePartialUnstable = UnstableTypes.NftMarketplacePartialUnstable;
    type BaseListingUnstable = UnstableTypes.BaseListingUnstable;
    type FixedPriceUnstable = UnstableTypes.FixedPriceUnstable;
    type SoldFixedPriceUnstable = UnstableTypes.SoldFixedPriceUnstable;
    type CancelledFixedPriceUnstable = UnstableTypes.CancelledFixedPriceUnstable;
    type AuctionUnstable = UnstableTypes.AuctionUnstable;
    type SoldAuctionUnstable = UnstableTypes.SoldAuctionUnstable;
    type CancelledAuctionUnstable = UnstableTypes.CancelledAuctionUnstable;
    type LaunchUnstable = UnstableTypes.LaunchUnstable;
    type ListingUnstable = UnstableTypes.ListingUnstable;
    type CancelledLaunchUnstable = UnstableTypes.CancelledLaunchUnstable;

    public func toPartailStableOperationalInfo(o: Types.OperationalInfo):OperationalInfoPartialUnstable{
        {
            var tenantId = o.tenantId;
            var maintenanceId = o.maintenanceId;
            var inspectionsId = o.inspectionsId;
            var tenants = HashMap.fromIter<Nat, Types.Tenant>(o.tenants.vals(), o.tenants.size(), Nat.equal, Utils.natToHash);
            var maintenance = HashMap.fromIter<Nat, Types.MaintenanceRecord>(o.maintenance.vals(), o.maintenance.size(), Nat.equal, Utils.natToHash);
            var inspections = HashMap.fromIter<Nat, Types.InspectionRecord>(o.inspections.vals(), o.inspections.size(), Nat.equal, Utils.natToHash);
        }
    };

    public func fromPartailStableOperationalInfo(o: OperationalInfoPartialUnstable):Types.OperationalInfo{
        {
            tenantId = o.tenantId;
            maintenanceId = o.maintenanceId;
            inspectionsId = o.inspectionsId;
            tenants = sortedEntries(o.tenants);
            maintenance = sortedEntries(o.maintenance);
            inspections = sortedEntries(o.inspections);
        }
    };

        // ------------------ MISCELLANEOUS ------------------
    public func toPartialStableMiscellaneous(m: Types.Miscellaneous): MiscellaneousPartialUnstable {
        {
            var description = m.description;
            var imageId = m.imageId;
            var images = HashMap.fromIter<Nat, Text>(m.images.vals(), m.images.size(), Nat.equal, Utils.natToHash);
        }
    };

    public func fromPartialStableMiscellaneous(m: MiscellaneousPartialUnstable): Types.Miscellaneous {
        {
            description = m.description;
            imageId = m.imageId;
            images = sortedEntries(m.images);
        }
    };

    // ------------------ FINANCIALS ------------------
    public func toPartialStableFinancials(f: Types.Financials): FinancialsPartialUnstable {
        {
            var account = f.account;
            var currentValue = f.currentValue;
            var investment = f.investment;
            var pricePerSqFoot = f.pricePerSqFoot;
            var valuationId = f.valuationId;
            var invoiceId = f.invoiceId;
            var valuations = HashMap.fromIter<Nat, Types.ValuationRecord>(f.valuations.vals(), f.valuations.size(), Nat.equal, Utils.natToHash);
            var invoices = HashMap.fromIter<Nat, Types.Invoice>(f.invoices.vals(), f.invoices.size(), Nat.equal, Utils.natToHash);
            var monthlyRent = f.monthlyRent;
            var yield = f.yield;
        }
    };

    public func fromPartialStableFinancials(f: FinancialsPartialUnstable): Types.Financials {
        {
            account = f.account;
            currentValue = f.currentValue;
            investment = f.investment;
            pricePerSqFoot = f.pricePerSqFoot;
            valuationId = f.valuationId;
            valuations = sortedEntries(f.valuations);
            invoiceId = f.invoiceId;
            invoices = sortedEntries(f.invoices);
            monthlyRent = f.monthlyRent;
            yield = f.yield;
        }
    };

    public func toStableInvoice(i: UnstableTypes.InvoiceUnstable): Types.Invoice {
        {
          id = i.id;
          status = i.status;
          direction = i.direction;
          title = i.title;
          description = i.description;
          amount = i.amount;
          due =i.due;
          paymentStatus = i.paymentStatus;
          paymentMethod = i.paymentMethod;
          recurrence= i.recurrence;
          logs = i.logs;
        };
    };

    public func fromStableInvoice(i: Types.Invoice): UnstableTypes.InvoiceUnstable {
        {
          var id = i.id;
          var status=i.status;
          var direction = i.direction;
          var title = i.title;
          var description = i.description;
          var amount = i.amount;
          var due =i.due;
          var paymentStatus = i.paymentStatus;
          var paymentMethod = i.paymentMethod;
          var recurrence= i.recurrence;
          var logs = i.logs;
        };
    };

    // ------------------ ADMINISTRATIVE INFO ------------------
    public func toPartialStableAdministrativeInfo(a: Types.AdministrativeInfo): AdministrativeInfoPartialUnstable {
        {
            var documentId = a.documentId;
            var insuranceId = a.insuranceId;
            var notesId = a.notesId;
            var insurance = HashMap.fromIter<Nat, Types.InsurancePolicy>(a.insurance.vals(), a.insurance.size(), Nat.equal, Utils.natToHash);
            var documents = HashMap.fromIter<Nat, Types.Document>(a.documents.vals(), a.documents.size(), Nat.equal, Utils.natToHash);
            var notes = HashMap.fromIter<Nat, Types.Note>(a.notes.vals(), a.notes.size(), Nat.equal, Utils.natToHash);
        }
    };

    public func sortedEntries<T>(map: HashMap.HashMap<Nat, T>) : [(Nat, T)] {
        Array.sort(
            Iter.toArray(map.entries()),
            func((id1, _) : (Nat, T), (id2, _) : (Nat, T)): Order.Order {
                Nat.compare(id1, id2)
            }
        )
    };

    public func fromPartialStableAdministrativeInfo(a: AdministrativeInfoPartialUnstable): Types.AdministrativeInfo {
        {
            documentId = a.documentId;
            insuranceId = a.insuranceId;
            notesId = a.notesId;
            insurance = sortedEntries(a.insurance);
            documents = sortedEntries(a.documents);
            notes = sortedEntries(a.notes);
        }
    };

    //--------------------- Governance ---------------------
    public func toPartialStableGovernance(g: Types.Governance): GovernanceUnstable {
        {
            var proposalId = g.proposalId;
            var proposals = HashMap.fromIter<Nat, Types.Proposal>(g.proposals.vals(), g.proposals.size(), Nat.equal, Utils.natToHash);
            var assetCost = g.assetCost;
            var proposalCost = g.proposalCost;
            var requireNftToPropose = g.requireNftToPropose;
            var minYesVotes = g.minYesVotes;
            var minTurnout= g.minTurnout;
            var quorumPercentage = g.quorumPercentage;
        }
    };

    public func fromPartialStableGovernance(g: GovernanceUnstable): Types.Governance {
        {
            proposalId = g.proposalId;
            proposals = sortedEntries(g.proposals);
            assetCost = g.assetCost;
            proposalCost = g.proposalCost;
            requireNftToPropose = g.requireNftToPropose;
            minYesVotes = g.minYesVotes;
            minTurnout= g.minTurnout;
            quorumPercentage = g.quorumPercentage;
        }
    };

    public func toStableProposal(p: UnstableTypes.ProposalUnstable): Types.Proposal {
        {
            id = p.id;
            title = p.title;
            description = p.description;
            creator = p.creator;
            createdAt = p.createdAt;
            startAt = p.startAt;
            eligibleVoters = p.eligibleVoters;
            totalEligibleVoters = p.totalEligibleVoters;            // ← stored for convenience
            votes = p.votes;
            status = p.status;
            category = p.category;
            implementation = p.implementation;
            actions = p.actions;
        }
    };

    public func fromStableProposal(p: Types.Proposal): UnstableTypes.ProposalUnstable {
        {
            var id = p.id;
            var title = p.title;
            var description = p.description;
            var creator = p.creator;
            var startAt = p.startAt;
            var createdAt = p.createdAt;
            var eligibleVoters = p.eligibleVoters;
            var totalEligibleVoters = p.totalEligibleVoters;            // ← stored for convenience
            var votes = p.votes;
            var status = p.status;
            var category = p.category;
            var implementation = p.implementation;
            var actions = p.actions;
        }
    };



    // ------------------ NFT MARKETPLACE ------------------
    public func toPartialStableNftMarketplace(n: Types.NFTMarketplace): NftMarketplacePartialUnstable {
        {
            var collectionId = n.collectionId;
            var listId = n.listId;
            var listings = HashMap.fromIter<Nat, Types.Listing>(n.listings.vals(), n.listings.size(), Nat.equal, Utils.natToHash);
            var timerIds = HashMap.fromIter<Nat, Nat>(n.timerIds.vals(), n.timerIds.size(), Nat.equal, Utils.natToHash);
            var royalty = n.royalty;
        }
    };

    public func fromPartialStableNftMarketplace(n: NftMarketplacePartialUnstable): Types.NFTMarketplace {
        {
            collectionId = n.collectionId;
            listId = n.listId;
            listings = sortedEntries(n.listings);
            timerIds = sortedEntries(n.timerIds);
            royalty = n.royalty;
        }
    };

    ////////////Listing

    public func fromStableBaseListing<X <:Types.BaseListing>(base: X): BaseListingUnstable {
        {
            var id = base.id;
            var tokenId = base.tokenId;
            var listedAt = base.listedAt;
            var seller = base.seller;
            var quoteAsset = base.quoteAsset;
        };
    };

    public func toStableBaseListing<X <: BaseListingUnstable>(base: X): Types.BaseListing {
        {
            id = base.id;
            tokenId = base.tokenId;
            listedAt = base.listedAt;
            seller = base.seller;
            quoteAsset = base.quoteAsset;
        };
    };

    public func fromStableFixedPrice<X <: Types.FixedPrice>(fixed: X): FixedPriceUnstable {
        {
            var id = fixed.id;
            var tokenId = fixed.tokenId;
            var listedAt = fixed.listedAt;
            var seller = fixed.seller;
            var quoteAsset = fixed.quoteAsset;
            var price = fixed.price;
            var expiresAt = fixed.expiresAt;
        }
    };

    public func toStableFixedPrice<X <: FixedPriceUnstable>(fixed: X): Types.FixedPrice {
        {
            toStableBaseListing(fixed) with
            price = fixed.price;
            expiresAt = fixed.expiresAt;
        }
    };

    public func fromStableSoldFixedPrice(sold: Types.SoldFixedPrice): SoldFixedPriceUnstable {
        {
            var id = sold.id;
            var tokenId = sold.tokenId;
            var listedAt = sold.listedAt;
            var seller = sold.seller;
            var quoteAsset = sold.quoteAsset;
            var price = sold.price;
            var expiresAt = sold.expiresAt;
            var bid = sold.bid;
            var royaltyBps = sold.royaltyBps;
        }
    };

    public func toStableSoldFixedPrice(sold: SoldFixedPriceUnstable): Types.SoldFixedPrice {
        {
            toStableFixedPrice(sold) with
            bid = sold.bid;
            royaltyBps = sold.royaltyBps;
        }
    };

  

    public func fromStableCancelledFixedPrice(cancelled: Types.CancelledFixedPrice): CancelledFixedPriceUnstable {
        {
            var id = cancelled.id;
            var tokenId = cancelled.tokenId;
            var listedAt = cancelled.listedAt;
            var seller = cancelled.seller;
            var quoteAsset = cancelled.quoteAsset;
            var price = cancelled.price;
            var expiresAt = cancelled.expiresAt;
            var cancelledBy = cancelled.cancelledBy;
            var cancelledAt = cancelled.cancelledAt;
            var reason = cancelled.reason;
        }
    };

    public func toStableCancelledFixedPrice(cancelled: CancelledFixedPriceUnstable): Types.CancelledFixedPrice {
        {
            toStableFixedPrice(cancelled) with
            cancelledBy = cancelled.cancelledBy;
            cancelledAt = cancelled.cancelledAt;
            reason = cancelled.reason;
        }
    };

    public func fromStableAuctions<X <:Types.Auction>(auction: X): AuctionUnstable {
        {
            var id = auction.id;
            var tokenId = auction.tokenId;
            var listedAt = auction.listedAt;
            var seller = auction.seller;
            var quoteAsset = auction.quoteAsset;
            var startingPrice = auction.startingPrice;
            var buyNowPrice = auction.buyNowPrice;
            var bidIncrement = auction.bidIncrement;
            var reservePrice = auction.reservePrice;
            var startTime = auction.startTime;
            var endsAt = auction.endsAt;
            var highestBid = auction.highestBid;
            var previousBids = Buffer.fromArray(auction.previousBids);
            var refunds = Buffer.fromArray(auction.refunds);
        }
    };

    public func toStableAuctions<X <:AuctionUnstable>(auction: X): Types.Auction {
        {
            toStableBaseListing(auction) with
            startingPrice = auction.startingPrice;
            buyNowPrice = auction.buyNowPrice;
            bidIncrement = auction.bidIncrement;
            reservePrice = auction.reservePrice;
            startTime = auction.startTime;
            endsAt = auction.endsAt;
            highestBid = auction.highestBid;
            previousBids = Buffer.toArray(auction.previousBids);
            refunds = Buffer.toArray(auction.refunds);
        }
    };

    public func fromStableSoldAuction(sold: Types.SoldAuction): SoldAuctionUnstable {
        {
            var id = sold.id;
            var tokenId = sold.tokenId;
            var listedAt = sold.listedAt;
            var seller = sold.seller;
            var quoteAsset = sold.quoteAsset;
            var startingPrice = sold.startingPrice;
            var buyNowPrice = sold.buyNowPrice;
            var bidIncrement = sold.bidIncrement;
            var reservePrice = sold.reservePrice;
            var startTime = sold.startTime;
            var endsAt = sold.endsAt;
            var highestBid = sold.highestBid;
            var previousBids = Buffer.fromArray(sold.previousBids);
            var refunds = Buffer.fromArray(sold.refunds); 
            var auctionEndTime = sold.auctionEndTime;
            var soldFor = sold.soldFor;
            var boughtNow = sold.boughtNow;
            var buyer = sold.buyer;
            var royaltyBps = sold.royaltyBps;
        }
    };

    public func toStableSoldAuction(sold: SoldAuctionUnstable): Types.SoldAuction {
        {
            toStableAuctions(sold) with 
            auctionEndTime = sold.auctionEndTime;
            soldFor = sold.soldFor;
            boughtNow = sold.boughtNow;
            buyer = sold.buyer;
            royaltyBps = sold.royaltyBps;
        }
    };

    public func fromStableCancelledAuction(cancelled: Types.CancelledAuction): CancelledAuctionUnstable {
        {
            var id = cancelled.id;
            var tokenId = cancelled.tokenId;
            var listedAt = cancelled.listedAt;
            var seller = cancelled.seller;
            var quoteAsset = cancelled.quoteAsset;
            var startingPrice = cancelled.startingPrice;
            var buyNowPrice = cancelled.buyNowPrice;
            var bidIncrement = cancelled.bidIncrement;
            var reservePrice = cancelled.reservePrice;
            var startTime = cancelled.startTime;
            var endsAt = cancelled.endsAt;
            var highestBid = cancelled.highestBid;
            var previousBids = Buffer.fromArray(cancelled.previousBids);
            var refunds = Buffer.fromArray(cancelled.refunds);
            var cancelledBy = cancelled.cancelledBy;
            var cancelledAt = cancelled.cancelledAt;
            var reason = cancelled.reason;
        }
    };

    public func toStableCancelledAuction(cancelled: CancelledAuctionUnstable): Types.CancelledAuction {
        {
            toStableAuctions(cancelled) with 
            cancelledBy = cancelled.cancelledBy;
            cancelledAt = cancelled.cancelledAt;
            reason = cancelled.reason;
        }
    };

    public func fromStableLaunch(launch: Types.Launch): LaunchUnstable {
        {
            var id = launch.id;
            var seller = launch.seller;
            var caller = launch.caller;
            var tokenIds = Buffer.fromArray(launch.tokenIds);
            var listIds = Buffer.fromArray(launch.listIds);
            var maxListed = launch.maxListed;
            var listedAt = launch.listedAt;
            var price = launch.price;
            var quoteAsset = launch.quoteAsset;
            var endsAt = launch.endsAt;
        }
    };

    public func fromStableCancelledLaunch(launch: Types.CancelledLaunch): CancelledLaunchUnstable {
        {
            var id = launch.id;
            var seller = launch.seller;
            var caller = launch.caller;
            var tokenIds = Buffer.fromArray(launch.tokenIds);
            var listIds = Buffer.fromArray(launch.listIds);
            var maxListed = launch.maxListed;
            var listedAt = launch.listedAt;
            var price = launch.price;
            var quoteAsset = launch.quoteAsset;
            var endsAt = launch.endsAt;
            var cancelledBy = launch.cancelledBy;
            var cancelledAt = launch.cancelledAt;
            var reason = launch.reason;
        }
    };

    public func toStableCancelledLaunch(launch: CancelledLaunchUnstable): Types.CancelledLaunch {
        {
            toStableLaunch(launch) with
            cancelledBy = launch.cancelledBy;
            cancelledAt = launch.cancelledAt;
            reason = launch.reason;
        }
    };

    public func toStableLaunch<X <: LaunchUnstable>(launch: X): Types.Launch {
        {
            id = launch.id;
            seller = launch.seller;
            caller = launch.caller;
            tokenIds = Buffer.toArray(launch.tokenIds);
            listIds = Buffer.toArray(launch.listIds);
            maxListed = launch.maxListed;
            listedAt = launch.listedAt;
            price = launch.price;
            quoteAsset = launch.quoteAsset;
            endsAt = launch.endsAt;
        }
    };

    

    public func fromStableListing(listing: Types.Listing): ListingUnstable{
        switch(listing){
            case(#LaunchedProperty(arg)) #LaunchedProperty(fromStableLaunch(arg));
            case(#CancelledLaunchedProperty(arg)) #CancelledLaunchedProperty(fromStableCancelledLaunch(arg));
            case(#LaunchFixedPrice(arg)) #LaunchFixedPrice(fromStableFixedPrice(arg));
            case(#CancelledLaunch(arg)) #CancelledLaunch(fromStableCancelledFixedPrice(arg));
            case(#SoldLaunchFixedPrice(arg)) #SoldLaunchFixedPrice(fromStableSoldFixedPrice(arg));
            case(#LiveFixedPrice(arg)) #LiveFixedPrice(fromStableFixedPrice(arg));
            case(#SoldFixedPrice(arg)) #SoldFixedPrice(fromStableSoldFixedPrice(arg));
            case(#CancelledFixedPrice(arg)) #CancelledFixedPrice(fromStableCancelledFixedPrice(arg));
            case(#LiveAuction(arg)) #LiveAuction(fromStableAuctions(arg));
            case(#SoldAuction(arg)) #SoldAuction(fromStableSoldAuction(arg));
            case(#CancelledAuction(arg)) #CancelledAuction(fromStableCancelledAuction(arg));
        }
    };

    public func toStableListing(listing: ListingUnstable): Types.Listing{
        switch(listing){
            case(#LaunchedProperty(arg)) #LaunchedProperty(toStableLaunch(arg));
            case(#CancelledLaunchedProperty(arg)) #CancelledLaunchedProperty(toStableCancelledLaunch(arg));
            case(#LaunchFixedPrice(arg)) #LaunchFixedPrice(toStableFixedPrice(arg));
            case(#CancelledLaunch(arg)) #CancelledLaunch(toStableCancelledFixedPrice(arg));
            case(#SoldLaunchFixedPrice(arg)) #SoldLaunchFixedPrice(toStableSoldFixedPrice(arg));
            case(#LiveFixedPrice(arg)) #LiveFixedPrice(toStableFixedPrice(arg));
            case(#SoldFixedPrice(arg)) #SoldFixedPrice(toStableSoldFixedPrice(arg));
            case(#CancelledFixedPrice(arg)) #CancelledFixedPrice(toStableCancelledFixedPrice(arg));
            case(#LiveAuction(arg)) #LiveAuction(toStableAuctions(arg));
            case(#SoldAuction(arg)) #SoldAuction(toStableSoldAuction(arg));
            case(#CancelledAuction(arg)) #CancelledAuction(toStableCancelledAuction(arg));
        }
    };





};

