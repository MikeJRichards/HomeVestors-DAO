import Types "types";
import Stables "./Tests/stables";
import UnstableTypes "./Tests/unstableTypes";
import PropHelper "propHelper";
import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Option "mo:base/Option";
//import Debug "mo:base/Debug";

module Operational {
    type OperationalInfo = Types.OperationalInfo;
    type Tenant = Types.Tenant;
    type UpdateError = Types.UpdateError;
    type MaintenanceRecordUArg = Types.MaintenanceRecordUArg;
    type MaintenanceRecordCArg = Types.MaintenanceRecordCArg;
    type InspectionRecordUArg = Types.InspectionRecordUArg;
    type InspectionRecordCArg = Types.InspectionRecordCArg;
    type TenantUArg = Types.TenantUArg;
    type TenantCArg = Types.TenantCArg;
    type Handler<P, K, A, T, StableT> = UnstableTypes.Handler<P, K, A, T, StableT>;
    type CrudHandler<K, C, U, T, StableT> = UnstableTypes.CrudHandler<K, C, U, T, StableT>;
    type MaintenanceRecordUnstable = UnstableTypes.MaintenanceRecordUnstable;
    type PropertyUnstable = UnstableTypes.PropertyUnstable;
    type TenantUnstable = UnstableTypes.TenantUnstable;
    type InspectionRecordUnstable = UnstableTypes.InspectionRecordUnstable;
    type Property = Types.Property;
    type Update = Types.Update;
    type What = Types.What;

    public func createOperationalInfo(): OperationalInfo {
        {
            tenantId = 0;
            maintenanceId = 0;
            inspectionsId = 0;
            tenants = [];
            maintenance = [];
            inspections = [];
        }
    };

    
    type Arg = Types.Arg<Property>;
    type Actions<C, U> = Types.Actions<C, U>;
    type UpdateResult = Types.UpdateResult;
    public func createMaintenanceHandler(args: Arg, action: Actions<MaintenanceRecordCArg, MaintenanceRecordUArg>): async UpdateResult {
        type P = Property;
        type K = Nat;
        type C = MaintenanceRecordCArg;
        type U = MaintenanceRecordUArg;
        type A = Types.AtomicAction<K, C, U>;
        type T = MaintenanceRecordUnstable;
        type StableT = Types.MaintenanceRecord;
        type S = UnstableTypes.OperationalInfoPartialUnstable;
        let operational = Stables.toPartailStableOperationalInfo(args.parent.operational);
          
        let map = operational.maintenance;
        var tempId = operational.maintenanceId + 1;

        let crudHandler: CrudHandler<K, C, U, T, StableT> = {
            map;
            getId = func() = operational.maintenanceId;
            createTempId = func(){
              tempId += 1;
              tempId;
            };
            incrementId = func(){operational.maintenanceId += 1;};
            assignId = func(id: Nat, el: StableT) = (id, {el with id = id;});
            delete = PropHelper.makeDelete(map);
            fromStable = Stables.fromStableMaintenanceRecord;
            validate = func(maybeMaintenance: ?T): Result.Result<T, UpdateError> {
                    let now = Time.now();
                    let m = switch(maybeMaintenance){case(null) return #err(#InvalidElementId); case(?maintenance) maintenance};
                    if (Text.equal(m.description, "")) return #err(#InvalidData{field = "description"; reason = #EmptyString;});
                    if (Option.get(m.dateCompleted, now) > now) return #err(#InvalidData{field = "date completed"; reason = #CannotBeSetInTheFuture;});
                    if (Option.get(m.dateReported, now) > now) return #err(#InvalidData{field = "date reported"; reason = #CannotBeSetInTheFuture;});
                    return #ok(m);
            };

            mutate = func(arg: MaintenanceRecordUArg, maintenance: T): T {
                maintenance.description := PropHelper.get(arg.description, maintenance.description);
                maintenance.status := PropHelper.get(arg.status, maintenance.status);
                maintenance.dateCompleted := PropHelper.getNullable(arg.dateCompleted, maintenance.dateCompleted);
                maintenance.cost := PropHelper.getNullable(arg.cost, maintenance.cost);
                maintenance.contractor := PropHelper.getNullable(arg.contractor, maintenance.contractor);
                maintenance.paymentMethod := PropHelper.getNullable(arg.paymentMethod, maintenance.paymentMethod);
                maintenance.dateReported := PropHelper.getNullable(arg.dateReported, maintenance.dateReported);
                maintenance;
            };

            create = func(arg: MaintenanceRecordCArg, id: Nat): T {
                {
                    var id;
                    var description = arg.description;
                    var dateCompleted = arg.dateCompleted;
                    var cost = arg.cost;
                    var contractor = arg.contractor;
                    var status = arg.status;
                    var paymentMethod = arg.paymentMethod;
                    var dateReported = arg.dateReported;
                }
            };
        };      
  
      let handler = PropHelper.generateGenericHandler<P, Nat, C, U, T, StableT, S>(
        crudHandler, 
        func(t: T): StableT = Stables.toStableMaintenanceRecord(t),  
        func(s: ?StableT) = #Maintenance(s), 
        func(p: P) = p.operational.maintenance,
        func(id1:K, id2:K)= id1 == id2,
        PropHelper.isConflictOnNatId(),
        func(property: P){{property with operational = Stables.fromPartailStableOperationalInfo(operational)}},
        PropHelper.updatePropertyEventLog,
        PropHelper.atomicActionToWhat(func(a: Types.Actions<C,U>): Types.What = #Maintenance(a))
      );
      await PropHelper.applyHandler<P, K, A, T, StableT>(args, PropHelper.makeAutomicAction(action, map.size()), handler);
    };

    public func createInspectionHandler(args: Arg, action: Actions<InspectionRecordCArg, InspectionRecordUArg>): async UpdateResult {
        type P = Property;
        type K = Nat;
        type C = InspectionRecordCArg;
        type U = InspectionRecordUArg;
        type T = InspectionRecordUnstable;
        type A = Types.AtomicAction<K, C, U>;
        type StableT = Types.InspectionRecord;
        type S = UnstableTypes.OperationalInfoPartialUnstable;
        let operational = Stables.toPartailStableOperationalInfo(args.parent.operational);
        let map = operational.inspections;
        var tempId = operational.inspectionsId + 1;
                  
        let crudHandler: CrudHandler<K, C, U, T, StableT> = {
            map;
            getId = func() = operational.inspectionsId;
            createTempId = func(){
              tempId += 1;
              tempId;
            };
            incrementId = func(){operational.inspectionsId += 1;};
            assignId = func(id: Nat, el: StableT) = (id, {el with id = id;});
            delete = PropHelper.makeDelete(map);
            fromStable = Stables.fromStableInspectionRecord;
            mutate = func(arg: InspectionRecordUArg, i: InspectionRecordUnstable): InspectionRecordUnstable {
            i.inspectorName := PropHelper.get(arg.inspectorName, i.inspectorName);
            i.findings := PropHelper.get(arg.findings, i.findings);
            i.date := PropHelper.getNullable(arg.date, i.date);
            i.actionRequired := PropHelper.getNullable(arg.actionRequired, i.actionRequired);
            i.followUpDate := PropHelper.getNullable(arg.followUpDate, i.followUpDate);
            i;
        };

        create = func(arg: InspectionRecordCArg, id: Nat): T {
            {
                var id;
                var inspectorName = arg.inspectorName;
                var date = arg.date;
                var findings = arg.findings;
                var actionRequired = arg.actionRequired;
                var followUpDate = arg.followUpDate;
                var appraiser = args.caller;
            }
        };

        validate = func(maybeInspection: ?T): Result.Result<T, UpdateError> {
            let i = switch(maybeInspection){case(null) return #err(#InvalidElementId); case(?inspection) inspection};
            if (Text.equal(i.inspectorName, "")) return #err(#InvalidData{field = "inspector name"; reason = #EmptyString;});
            if (Text.equal(i.findings, "")) return #err(#InvalidData{field = "findings"; reason = #EmptyString;});
            if (Option.get(i.date, Time.now()) > Time.now()) return #err(#InvalidData{field = "inspection date"; reason = #CannotBeSetInTheFuture;});
            return #ok(i);
        }
      };      
  
      let handler = PropHelper.generateGenericHandler<P, Nat, C, U, T, StableT, S>(
        crudHandler, 
        func(t: T): StableT = Stables.toStableInspectionRecord(t),  
        func(s: ?StableT) = #Inspection(s), 
        func(p: P) = p.operational.inspections,
        func(id1:K, id2:K)= id1 == id2,
        PropHelper.isConflictOnNatId(),
        func(property: P){{property with operational = Stables.fromPartailStableOperationalInfo(operational)}},
        PropHelper.updatePropertyEventLog,
        PropHelper.atomicActionToWhat(func(a: Types.Actions<C,U>): Types.What = #Inspection(a))
      );
      await PropHelper.applyHandler<P, K, A, T, StableT>(args, PropHelper.makeAutomicAction(action, map.size()), handler);
    };

     public func isTenant(caller : Principal, property : Property) : Bool {
        let tenants = property.operational.tenants;
        if (tenants.size() == 0) return false;
    
        // Get last element in tenants array
        let (_, lastTenant) = tenants[tenants.size() - 1];
    
        switch (lastTenant.principal) {
            case (null) false;
            case (?p) Principal.equal(caller, p);
        }
    };
    
    public func createTenantHandler(args: Arg, action: Actions<TenantCArg, TenantUArg>): async UpdateResult {
        type P = Property;
        type K = Nat;
        type C = TenantCArg;
        type U = TenantUArg;
        type A = Types.AtomicAction<K, C, U>;
        type T = TenantUnstable;
        type StableT = Types.Tenant;
        type S = UnstableTypes.OperationalInfoPartialUnstable;
        
        let operational = Stables.toPartailStableOperationalInfo(args.parent.operational);
        let map = operational.tenants;
        var tempId = operational.tenantId;   
        
        let crudHandler: CrudHandler<K, C, U, T, StableT> = {
            map;
            getId = func() = operational.tenantId;
            createTempId = func(){
              tempId += 1;
              tempId;
            };
            incrementId = func(){operational.tenantId += 1;}; // Fixed typo: was misc.imageId
            assignId = func(id: Nat, el: StableT) = (id, {el with id = id;});
            delete = PropHelper.makeDelete(map);
            fromStable = Stables.fromStableTenant;
            mutate = func(arg: TenantUArg, tenant: TenantUnstable): TenantUnstable {
                let t = Stables.toStableTenant(tenant);
                let updatedTenant = {
                    t with
                    leadTenant = PropHelper.get(arg.leadTenant, t.leadTenant);
                    otherTenants = PropHelper.get(arg.otherTenants, t.otherTenants);
                    monthlyRent = PropHelper.get(arg.monthlyRent, t.monthlyRent);
                    deposit = PropHelper.get(arg.deposit, t.deposit);
                    leaseStartDate = PropHelper.get(arg.leaseStartDate, t.leaseStartDate);
                    contractLength = PropHelper.get(arg.contractLength, t.contractLength);
                    paymentHistory = PropHelper.get(arg.paymentHistory, t.paymentHistory);
                    principal = PropHelper.getNullable(arg.principal, t.principal);
                };
               Stables.fromStableTenant(updatedTenant);
            };

            create = func(arg: TenantCArg, id: Nat): TenantUnstable {
               let tenant: Tenant = {arg with id; paymentHistory = []};
               Stables.fromStableTenant(tenant);
            };

            validate = func(maybeTenant: ?TenantUnstable): Result.Result<TenantUnstable, UpdateError> {
                let t = switch(maybeTenant){case(null) return #err(#InvalidElementId); case(?tenant) tenant};
                if (Text.equal(t.leadTenant, "")) return #err(#InvalidData{field = "lead tenant"; reason = #EmptyString;});
                if (t.monthlyRent <= 0) return #err(#InvalidData{field = "monthly rent"; reason = #CannotBeZero;});
                if (t.deposit <= 0) return #err(#InvalidData{field = "deposit"; reason = #CannotBeZero;});
                switch(action, t.leaseStartDate < Time.now()){
                    case(#Create(_), true) return #err(#InvalidData{field = "lease start date"; reason = #CannotBeSetInThePast;});
                    case(_){};
                };
                return #ok(t);
            }
        };  

        let handler = PropHelper.generateGenericHandler<P, Nat, C, U, T, StableT, S>(
        crudHandler, 
        func(t: T): StableT = Stables.toStableTenant(t),  
        func(s: ?StableT) = #Tenant(s), 
        func(p: P) = p.operational.tenants,
        func(id1:K, id2:K)= id1 == id2,
        PropHelper.isConflictOnNatId(),
        func(property: P){{property with operational = Stables.fromPartailStableOperationalInfo(operational)}},
        PropHelper.updatePropertyEventLog,
        PropHelper.atomicActionToWhat(func(a: Types.Actions<C,U>): Types.What = #Tenant(a))
      );
      await PropHelper.applyHandler<P, K, A, T, StableT>(args, PropHelper.makeAutomicAction(action, map.size()), handler);    
    };

    
};

