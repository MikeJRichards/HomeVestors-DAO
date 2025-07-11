import Types "types";
import UnstableTypes "./Tests/unstableTypes";
import PropHelper "propHelper";
import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Option "mo:base/Option";
import Stables "./Tests/stables";

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
    type Handler<C,U,T> = UnstableTypes.Handler<C, U, T>;
    type MaintenanceRecordUnstable = UnstableTypes.MaintenanceRecordUnstable;
    type PropertyUnstable = UnstableTypes.PropertyUnstable;
    type TenantUnstable = UnstableTypes.TenantUnstable;
    type InspectionRecordUnstable = UnstableTypes.InspectionRecordUnstable;

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

    public func createMaintenanceHandler(): Handler<MaintenanceRecordCArg, MaintenanceRecordUArg, MaintenanceRecordUnstable> {
      {
        map = func(p: PropertyUnstable) = p.operational.maintenance;

        getId = func(p: PropertyUnstable) = p.operational.maintenanceId;

        incrementId = func(p: PropertyUnstable) = p.operational.maintenanceId += 1;

        mutate = func(arg: MaintenanceRecordUArg, maintenance: MaintenanceRecordUnstable): MaintenanceRecordUnstable {
            maintenance.description := PropHelper.get(arg.description, maintenance.description);
            maintenance.status := PropHelper.get(arg.status, maintenance.status);
            maintenance.dateCompleted := PropHelper.getNullable(arg.dateCompleted, maintenance.dateCompleted);
            maintenance.cost := PropHelper.getNullable(arg.cost, maintenance.cost);
            maintenance.contractor := PropHelper.getNullable(arg.contractor, maintenance.contractor);
            maintenance.paymentMethod := PropHelper.getNullable(arg.paymentMethod, maintenance.paymentMethod);
            maintenance.dateReported := PropHelper.getNullable(arg.dateReported, maintenance.dateReported);
            maintenance;
        };

        create = func(arg: MaintenanceRecordCArg, id: Nat, caller: Principal): MaintenanceRecordUnstable {
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

        validate = func(maybeMaintenance: ?MaintenanceRecordUnstable): Result.Result<MaintenanceRecordUnstable, UpdateError> {
            let m = switch(maybeMaintenance){case(null) return #err(#InvalidElementId); case(?maintenance) maintenance};
            if (Text.equal(m.description, "")) return #err(#InvalidData{field = "description"; reason = #EmptyString;});
            if (Option.get(m.dateCompleted, Time.now()) > Time.now()) return #err(#InvalidData{field = "date completed"; reason = #CannotBeSetInTheFuture;});
            if (Option.get(m.dateReported, Time.now()) > Time.now()) return #err(#InvalidData{field = "date reported"; reason = #CannotBeSetInTheFuture;});
            return #ok(m);
        }
      }
    };

    public func createInspectionHandler(): Handler<InspectionRecordCArg, InspectionRecordUArg, InspectionRecordUnstable> {
      {
        map = func(p: PropertyUnstable) = p.operational.inspections;

        getId = func(p: PropertyUnstable) = p.operational.inspectionsId;

        incrementId = func(p: PropertyUnstable) = p.operational.inspectionsId += 1;

        mutate = func(arg: InspectionRecordUArg, i: InspectionRecordUnstable): InspectionRecordUnstable {
            i.inspectorName := PropHelper.get(arg.inspectorName, i.inspectorName);
            i.findings := PropHelper.get(arg.findings, i.findings);
            i.date := PropHelper.getNullable(arg.date, i.date);
            i.actionRequired := PropHelper.getNullable(arg.actionRequired, i.actionRequired);
            i.followUpDate := PropHelper.getNullable(arg.followUpDate, i.followUpDate);
            i;
        };

        create = func(arg: InspectionRecordCArg, id: Nat, caller: Principal): InspectionRecordUnstable {
            {
                var id;
                var inspectorName = arg.inspectorName;
                var date = arg.date;
                var findings = arg.findings;
                var actionRequired = arg.actionRequired;
                var followUpDate = arg.followUpDate;
                var appraiser = caller;
            }
        };

        validate = func(maybeInspection: ?InspectionRecordUnstable): Result.Result<InspectionRecordUnstable, UpdateError> {
            let i = switch(maybeInspection){case(null) return #err(#InvalidElementId); case(?inspection) inspection};
            if (Text.equal(i.inspectorName, "")) return #err(#InvalidData{field = "inspector name"; reason = #EmptyString;});
            if (Text.equal(i.findings, "")) return #err(#InvalidData{field = "findings"; reason = #EmptyString;});
            if (Option.get(i.date, Time.now()) > Time.now()) return #err(#InvalidData{field = "inspection date"; reason = #CannotBeSetInTheFuture;});
            return #ok(i);
        }
      }
    };

    public func createTenantHandler(): Handler<TenantCArg, TenantUArg, TenantUnstable> {
      {
        map = func(p: PropertyUnstable) = p.operational.tenants;

        getId = func(p: PropertyUnstable) = p.operational.tenantId;

        incrementId = func(p: PropertyUnstable) = p.operational.tenantId += 1;

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

        create = func(arg: TenantCArg, id: Nat, caller: Principal): TenantUnstable {
           let tenant: Tenant = {arg with id; paymentHistory = []};
           Stables.fromStableTenant(tenant);
        };

        validate = func(maybeTenant: ?TenantUnstable): Result.Result<TenantUnstable, UpdateError> {
            let t = switch(maybeTenant){case(null) return #err(#InvalidElementId); case(?tenant) tenant};
            if (Text.equal(t.leadTenant, "")) return #err(#InvalidData{field = "lead tenant"; reason = #EmptyString;});
            if (t.monthlyRent <= 0) return #err(#InvalidData{field = "monthly rent"; reason = #CannotBeZero;});
            if (t.deposit <= 0) return #err(#InvalidData{field = "deposit"; reason = #CannotBeZero;});
            if (t.leaseStartDate < Time.now()) return #err(#InvalidData{field = "lease start date"; reason = #CannotBeSetInThePast;});
            return #ok(t);
        }
      }
    };


    
};

