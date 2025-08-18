import Types "../types";
import Time "mo:base/Time";
import Principal "mo:base/Principal";

module {
    type InsurancePolicyCArg = Types.InsurancePolicyCArg;
    type InsurancePolicyUArg = Types.InsurancePolicyUArg;
    type DocumentCArg = Types.DocumentCArg;
    type DocumentUArg = Types.DocumentUArg;
    type NoteCArg = Types.NoteCArg;
    type NoteUArg = Types.NoteUArg;
    type MaintenanceRecordCArg = Types.MaintenanceRecordCArg;
    type MaintenanceRecordUArg = Types.MaintenanceRecordUArg;
    type InspectionRecordCArg = Types.InspectionRecordCArg;
    type InspectionRecordUArg = Types.InspectionRecordUArg;
    type TenantCArg = Types.TenantCArg;
    type TenantUArg = Types.TenantUArg;
    type ValuationRecordCArg = Types.ValuationRecordCArg;
    type ValuationRecordUArg = Types.ValuationRecordUArg;
    type FixedPriceCArg = Types.FixedPriceCArg;
    type FixedPriceUArg = Types.FixedPriceUArg;
    type AuctionCArg = Types.AuctionCArg;
    type AuctionUArg = Types.AuctionUArg;
    type BidArg = Types.BidArg;
    type CancelArg = Types.CancelArg;
    type FinancialsArg = Types.FinancialsArg;

    public func createInsurancePolicyCArg(): InsurancePolicyCArg {
        {
            policyNumber = "POL123456";
            provider = "Acme Insurance Ltd.";
            startDate = Time.now();
            endDate = ?(Time.now() + 31536000000); // +1 year
            premium = 499;
            paymentFrequency = #Monthly;
            nextPaymentDate = Time.now() + 2628000000; // +1 month
            contactInfo = "contact@acme.com";
        }
    };

    public func createInsurancePolicyUArg(): InsurancePolicyUArg {
        {
            policyNumber = ?"UPDATED-POL-7890";
            provider = ?"Updated Insurance Co.";
            startDate = ?(Time.now());
            endDate = ?(Time.now() + 63072000000); // +2 years
            premium = ?799;
            paymentFrequency = ?#Annually;
            nextPaymentDate = ?(Time.now() + 31536000000);
            contactInfo = ?"updated@insurance.com";
        };
    };

    public func createDocumentCArg(): DocumentCArg {
        {
            title = "AST Contract";
            description = "Tenancy agreement";
            documentType = #AST;
            url = "https://docs.acme.com/ast.pdf";
        };
    };

    public func createDocumentUArg(): DocumentUArg {
        {
            title = ?"Updated Title";
            description = ?"Updated tenancy agreement";
            documentType = ?#EPC;
            url = ?"https://docs.acme.com/epc.pdf";
        };
    };

    public func createNoteCArg(): NoteCArg {
        {
            date = ?Time.now();
            title = "Initial Note";
            content = "This is a useful note about the property.";
        };
    };

    public func createNoteUArg(): NoteUArg {
        {
            date = ?(Time.now()); // +1 day
            title = ?"Updated Note Title";
            content = ?"Updated content for note.";
        };
    };

    public func createMaintenanceRecordCArg(): MaintenanceRecordCArg {
        {
            description = "Repair boiler and replace thermostat";
            dateCompleted = ?Time.now();
            cost = ?250_00;
            contractor = ?"BoilerFix Ltd";
            status = #Completed;
            paymentMethod = ?#BankTransfer;
            dateReported = ?(Time.now() - 86400000); // -1 day
        };
    };

    public func createMaintenanceRecordUArg(): MaintenanceRecordUArg {
        {
            description = ?"Updated boiler work";
            dateCompleted = ?Time.now();
            cost = ?300_00;
            contractor = ?"UpdatedFixIt Ltd";
            status = ?#InProgress;
            paymentMethod = ?#Cash;
            dateReported = ?(Time.now() - 172800000); // -2 days
        };
    };

    public func createInspectionRecordCArg(): InspectionRecordCArg {
        {
            inspectorName = "Jane Inspector";
            date = ?Time.now();
            findings = "Everything is in order.";
            actionRequired = ?"None";
            followUpDate = ?(Time.now() + 604800000); // +1 week
        };
    };

    public func createInspectionRecordUArg(): InspectionRecordUArg {
        {
            inspectorName = ?"Updated Inspector";
            date = ?(Time.now());
            findings = ?"Minor wear observed.";
            actionRequired = ?"Recheck in 3 months";
            followUpDate = ?(Time.now() + 7776000000); // +90 days
        };
    };

    public func createTenantCArg(): TenantCArg {
        {
            leadTenant = "Alice Tenant";
            otherTenants = ["Bob Tenant", "Charlie Tenant"];
            principal = ?Principal.fromText("aaaaa-aa");
            monthlyRent = 950;
            deposit = 1200;
            leaseStartDate = Time.now();
            contractLength = #Annual;
        };
    };

    public func createTenantUArg(): TenantUArg {
        {
            leadTenant = ?"Updated Lead Tenant";
            otherTenants = ?["Updated Tenant"];
            principal = ?Principal.fromText("aaaaa-aa");
            monthlyRent = ?1000;
            deposit = ?1000;
            leaseStartDate = ?(Time.now() + 604800000); // +1 week
            contractLength = ?#Rolling;
            paymentHistory = ?[{ id = 0; amount = 950; date = Time.now(); method = #Cash }];
        };
    };

    public func createValuationRecordCArg(): ValuationRecordCArg {
        {
            value = 275000;
            method = #Online;
        };
    };

    public func createValuationRecordUArg(): ValuationRecordUArg {
        {
            value = ?290000;
            method = ?#Appraisal;
        };
    };

    public func createAdditionalDetailsUArg(): Types.AdditionalDetailsUArg {
        {
            crimeScore = ?150;
            schoolScore = ?5;
            affordability = ?0;
            floodZone = ?false;
        }
    };

    public func createPhysicalDetailsUArg(): Types.PhysicalDetailsUArg {
        {
            lastRenovation = ?2000;
            yearBuilt = ?0;
            squareFootage = ?100;
            beds = ?0;
            baths = ?0;
        }
    };

    public func createFixedPriceCArg(): FixedPriceCArg {
        {
            tokenId = 123;
            seller_subaccount = null;
            price = 100000;
            expiresAt = ?(Time.now() + 604800000); // +1 week
            quoteAsset = ?#ICP;
        };
    };

    public func createFixedPriceUArg(): FixedPriceUArg {
        {
            listingId = 123;
            price = ?110000;
            expiresAt = ?(Time.now() + 1209600000); // +2 weeks
            quoteAsset = ?#ICP;
        };
    };

    public func createAuctionCArg(): AuctionCArg {
        {
            tokenId = 999;
            seller_subaccount = null;
            startingPrice = 75000;
            buyNowPrice = ?95000;
            reservePrice = ?80000;
            startTime = Time.now();
            endsAt = Time.now() + 604800000; // +1 week
            quoteAsset = ?#ICP;
        };
    };

    public func createAuctionUArg(): AuctionUArg {
        {
            listingId = 999;
            startingPrice = ?80000;
            buyNowPrice = ?100000;
            reservePrice = ?85000;
            startTime = ?Time.now();
            endsAt = ?(Time.now() + 604800000);
            quoteAsset = ?#ICP;
        };
    };

    public func createBidArg(): BidArg {
        {
            listingId = 999;
            bidAmount = 85000;
            buyer_subaccount = null;
        };
    };

    public func createCancelArg(): CancelArg {
        {
            cancelledBy_subaccount = null;
            listingId = 999;
            reason = #CancelledBySeller;
        };
    };

    public func createFinancialsArg(): FinancialsArg {
        {
            currentValue = 300000;
        };
    };

    public func createProposalCArg(): Types.ProposalCArg {
        {
          title = "new proposal";
          description = "new proposal description";
          category = #Maintenance;
          implementation = #Week;
          startAt = Time.now() + 100000000;
          actions = [#Valuations(#Create([createValuationRecordCArg()]))];                      // The proposed mutations
        };
    };

    public func createProposalUArg(): Types.ProposalUArg {
        {
          title = ?"updated proposal";
          description = ?"updated proposal description";
          category = null;
          implementation = null;
          startAt = null;
          actions = null;                      // The proposed mutations
        };
    };

    public func createInvoiceCArg(): Types.InvoiceCArg {
        {
          title = "New Invoice";
          description = "New Invoice Description";
          amount = 10000;
          dueDate = Time.now() + 100000;
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

    public func createInvoiceUArg(): Types.InvoiceUArg {
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



    
};
