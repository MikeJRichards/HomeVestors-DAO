import UnstableTypes "./../unstableTypes";
import Types "./../../types";
import TestTypes "./../testTypes";
import Time "mo:base/Time";
import Stables "./../stables";
import Utils "./../utils";

import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Buffer "mo:base/Buffer";

module{
    type Actions<C,U> = Types.Actions<C,U>;
    type PropertyUnstable = UnstableTypes.PropertyUnstable;
    type WhatWithPropertyId = Types.WhatWithPropertyId;
    type UpdateResult = Types.UpdateResult;
    type  PreTestHandler<C, U, T> = TestTypes. PreTestHandler<C, U, T>;
    
    public func createTenantTestType2(property: PropertyUnstable, handlePropertyUpdate: (Types.WhatWithPropertyId, Principal) -> async Types.UpdateResultExternal): async [Text] {
        type C = Types.TenantCArg;
        type U = Types.TenantUArg;
        type T = UnstableTypes.TenantUnstable;

        func createTenantCArg(): C {
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

        func createTenantUArg(): U {
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

        let cArg : C = createTenantCArg();
        let uArg : U = createTenantUArg();

        let tenantCases : [(Text, Actions<C,U>, Bool)] = [

            // CREATE
            Utils.ok("Tenant: create valid",            #Create([cArg])),
            Utils.err("Tenant: empty lead tenant",      #Create([{ cArg with leadTenant = "" }])),
            Utils.err("Tenant: zero monthly rent",      #Create([{ cArg with monthlyRent = 0 }])),
            Utils.err("Tenant: zero deposit",           #Create([{ cArg with deposit = 0 }])),
            Utils.err("Tenant: start date in past",     #Create([{ cArg with leaseStartDate = Time.now() - 1 }])),

            // UPDATE
            Utils.ok("Tenant: update valid",            #Update((uArg, [0]))),
            Utils.ok("Tenant: update start date past", #Update(({ uArg with leaseStartDate = ?(Time.now() - 1) }, [0]))),
            Utils.err("Tenant: update non-existent",    #Update((uArg, [9999]))),
            Utils.err("Tenant: update empty lead",      #Update(({ uArg with leadTenant = ?"" }, [0]))),
            Utils.err("Tenant: update zero rent",       #Update(({ uArg with monthlyRent = ?0 }, [0]))),
            Utils.err("Tenant: update zero deposit",    #Update(({ uArg with deposit = ?0 }, [0]))),

            // DELETE
            Utils.ok("Tenant: delete valid",            #Delete([0])),
            Utils.err("Tenant: delete non-existent",    #Delete([9999]))
        ];

        let handler : PreTestHandler<C,U,T> = {
            testing = false;
            handlePropertyUpdate;
            toHashMap   = func(p: PropertyUnstable) = p.operational.tenants;
            showMap     = func(map: HashMap.HashMap<Nat,T>): Text {
                let buff = Buffer.Buffer<Text>(map.size());
                for((id, tenant) in map.entries()){
                    buff.add(debug_show(id, Stables.toStableTenant(tenant)));
                };
                return debug_show(Buffer.toArray(buff));
            };
            toId        = func(p: PropertyUnstable) = p.operational.tenantId;
            toWhat      = func(action: Actions<C,U>) = #Tenant(action);

            checkUpdate = func(before: T, after: T, arg: U): Text {
                var s = "";
                s #= Utils.assertUpdate2("leadTenant",   #OptText(?before.leadTenant),   #OptText(?after.leadTenant),   #OptText(arg.leadTenant));
                s #= Utils.assertUpdate2("monthlyRent",  #OptNat(?before.monthlyRent), #OptNat(?after.monthlyRent), #OptNat(arg.monthlyRent));
                s #= Utils.assertUpdate2("deposit",      #OptNat(?before.deposit),     #OptNat(?after.deposit),     #OptNat(arg.deposit));
                s #= Utils.assertUpdate2("leaseStart",   #OptInt(?before.leaseStartDate), #OptInt(?after.leaseStartDate), #OptInt(arg.leaseStartDate));
                s;
            };

            checkCreate = Utils.createDefaultCheckCreate();
            checkDelete = Utils.createDefaultCheckDelete();
            seedCreate = Utils.createDefaultSeedCreate(cArg);
            validForTest = Utils.createDefaultValidForTest(["Tenant: update non-existent", "Tenant: delete non-existent"]);
        };

        await Utils.runGenericCases<C,U,T>(property, handler, tenantCases)
    };

    // ====================== MAINTENANCE ======================
    public func createMaintenanceTestType2(property: PropertyUnstable, handlePropertyUpdate: (Types.WhatWithPropertyId, Principal) -> async Types.UpdateResultExternal):async [Text] {
        type C = Types.MaintenanceRecordCArg;
        type U = Types.MaintenanceRecordUArg;
        type T = UnstableTypes.MaintenanceRecordUnstable;

        func createMaintenanceRecordCArg(): C {
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

        func createMaintenanceRecordUArg(): U {
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


        let cArg : C = createMaintenanceRecordCArg();
        let uArg : U = createMaintenanceRecordUArg();

        let maintenanceCases : [(Text, Actions<C,U>, Bool)] = [
            // CREATE
            Utils.ok("Maintenance: create valid",                 #Create([cArg])),
            Utils.err("Maintenance: empty description",           #Create([{ cArg with description = "" }])),
            Utils.err("Maintenance: date completed in future",    #Create([{ cArg with dateCompleted = ?(Time.now() + 1_000_000_000) }])),
            Utils.err("Maintenance: date reported in future",     #Create([{ cArg with dateReported = ?(Time.now() + 1_000_000_000) }])),

            // UPDATE
            Utils.ok("Maintenance: update valid",                 #Update((uArg, [0]))),
            Utils.err("Maintenance: update non-existent",         #Update((uArg, [9999]))),
            Utils.err("Maintenance: update empty description",    #Update(({ uArg with description = ?"" }, [0]))),
            Utils.err("Maintenance: update date completed future",#Update(({ uArg with dateCompleted = ?(Time.now() + 1_000_000_000) }, [0]))),
            Utils.err("Maintenance: update date reported future", #Update(({ uArg with dateReported = ?(Time.now() + 1_000_000_000) }, [0]))),

            // DELETE
            Utils.ok("Maintenance: delete valid",                 #Delete([0])),
            Utils.err("Maintenance: delete non-existent",         #Delete([9999]))
        ];

        let handler : PreTestHandler<C,U,T> = {
            testing = false;
            handlePropertyUpdate;
            showMap     = func(map: HashMap.HashMap<Nat,T>) = debug_show(Iter.toArray(map.entries()));
            toHashMap   = func(p: PropertyUnstable) = p.operational.maintenance;
            toId        = func(p: PropertyUnstable) = p.operational.maintenanceId;
            toWhat      = func(action: Actions<C,U>) = #Maintenance(action);

            checkUpdate = func(before: T, after: T, arg: U): Text {
                var s = "";
                s #= Utils.assertUpdate2("description", #OptText(?before.description), #OptText(?after.description), #OptText(arg.description));
                s #= Utils.assertUpdate2("dateReported", #OptInt(before.dateReported), #OptInt(after.dateReported), #OptInt(arg.dateReported));
                s #= Utils.assertUpdate2("dateCompleted", #OptInt(before.dateCompleted), #OptInt(after.dateCompleted), #OptInt(arg.dateCompleted));
                s;
            };

            checkCreate = Utils.createDefaultCheckCreate();
            checkDelete = Utils.createDefaultCheckDelete();
            seedCreate = Utils.createDefaultSeedCreate(cArg);
            validForTest = Utils.createDefaultValidForTest(["Maintenance: update non-existent", "Maintenance: delete non-existent"]);
        };

        await Utils.runGenericCases<C,U,T>(property, handler, maintenanceCases)
    };

    // ====================== INSPECTIONS ======================
    public func createInspectionTestType2(property: PropertyUnstable, handlePropertyUpdate: (Types.WhatWithPropertyId, Principal) -> async Types.UpdateResultExternal):async [Text] {
        type C = Types.InspectionRecordCArg;
        type U = Types.InspectionRecordUArg;
        type T = UnstableTypes.InspectionRecordUnstable;

        func createInspectionRecordCArg(): C {
            {
                inspectorName = "Jane Inspector";
                date = ?Time.now();
                findings = "Everything is in order.";
                actionRequired = ?"None";
                followUpDate = ?(Time.now() + 604800000); // +1 week
            };
        };

        func createInspectionRecordUArg(): U {
            {
                inspectorName = ?"Updated Inspector";
                date = ?(Time.now());
                findings = ?"Minor wear observed.";
                actionRequired = ?"Recheck in 3 months";
                followUpDate = ?(Time.now() + 7776000000); // +90 days
            };
        };


        let cArg : C = createInspectionRecordCArg();
        let uArg : U = createInspectionRecordUArg();

        let inspectionCases : [(Text, Actions<C,U>, Bool)] = [
            // CREATE
            Utils.ok("Inspection: create valid",          #Create([cArg])),
            Utils.err("Inspection: empty inspector name", #Create([{ cArg with inspectorName = "" }])),
            Utils.err("Inspection: empty findings",       #Create([{ cArg with findings = "" }])),
            Utils.err("Inspection: date in future",       #Create([{ cArg with date = ?(Time.now() + 100000000000000000) }])),

            // UPDATE
            Utils.ok("Inspection: update valid",          #Update((uArg, [0]))),
            Utils.err("Inspection: update non-existent",  #Update((uArg, [9999]))),
            Utils.err("Inspection: update empty inspector",#Update(({ uArg with inspectorName = ?"" }, [0]))),
            Utils.err("Inspection: update empty findings", #Update(({ uArg with findings = ?"" }, [0]))),
            Utils.err("Inspection: update date in future", #Update(({ uArg with date = ?(Time.now() + 100000000000000000) }, [0]))),

            // DELETE
            Utils.ok("Inspection: delete valid",          #Delete([0])),
            Utils.err("Inspection: delete non-existent",  #Delete([9999]))
        ];

        let handler : PreTestHandler<C,U,T> = {
            testing = false;
            handlePropertyUpdate;
            toHashMap   = func(p: PropertyUnstable) = p.operational.inspections;
            showMap     = func(map: HashMap.HashMap<Nat,T>) = debug_show(Iter.toArray(map.entries()));
            toId        = func(p: PropertyUnstable) = p.operational.inspectionsId;
            toWhat      = func(action: Actions<C,U>) = #Inspection(action);

            checkUpdate = func(before: T, after: T, arg: U): Text {
                var s = "";
                s #= Utils.assertUpdate2("inspectorName", #OptText(?before.inspectorName), #OptText(?after.inspectorName), #OptText(arg.inspectorName));
                s #= Utils.assertUpdate2("findings",      #OptText(?before.findings),      #OptText(?after.findings),      #OptText(arg.findings));
                s #= Utils.assertUpdate2("date",          #OptInt(before.date),           #OptInt(after.date),             #OptInt(arg.date));
                s;
            };

            checkCreate = Utils.createDefaultCheckCreate();
            checkDelete = Utils.createDefaultCheckDelete();
            seedCreate = Utils.createDefaultSeedCreate(cArg);
            validForTest = Utils.createDefaultValidForTest(["Inspection: update non-existent", "Inspection: delete non-existent"]);
        };

        await Utils.runGenericCases<C,U,T>(property, handler, inspectionCases)
    };


}