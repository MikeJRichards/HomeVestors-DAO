import Types "types";
import PropHelper "propHelper";
import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Option "mo:base/Option";

module Operational {
    type OperationalInfo = Types.OperationalInfo;
    type MaintenanceRecord = Types.MaintenanceRecord;
    type InspectionRecord = Types.InspectionRecord;
    type Tenant = Types.Tenant;
    type Property = Types.Property;
    type UpdateResult = Types.UpdateResult;
    type UpdateError = Types.UpdateError;
    type MaintenanceRecordUArg = Types.MaintenanceRecordUArg;
    type MaintenanceRecordCArg = Types.MaintenanceRecordCArg;
    type InspectionRecordUArg = Types.InspectionRecordUArg;
    type InspectionRecordCArg = Types.InspectionRecordCArg;
    type TenantUArg = Types.TenantUArg;
    type TenantCArg = Types.TenantCArg;
    type Actions<C, U> = Types.Actions<C, U>;
    type OperationalIntentResult = Types.OperationalIntentResult;

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

    // Maintenance

    func validateMaintenance(m: MaintenanceRecord): Result.Result<MaintenanceRecord, UpdateError> {
        if (Text.equal(m.description, "")) return #err(#InvalidData{field = "description"; reason = #EmptyString;});
        if (Option.get(m.dateCompleted, Time.now()) > Time.now()) return #err(#InvalidData{field = "date completed"; reason = #CannotBeSetInTheFuture;});
        if (Option.get(m.dateReported, Time.now()) > Time.now()) return #err(#InvalidData{field = "date reported"; reason = #CannotBeSetInTheFuture;});
        return #ok(m);
    };

    func mutateMaintenance(arg: MaintenanceRecordUArg, m: MaintenanceRecord): MaintenanceRecord {
        {
            m with
            description = PropHelper.get(arg.description, m.description);
            status = PropHelper.get(arg.status, m.status);
            dateCompleted = PropHelper.getNullable(arg.dateCompleted, m.dateCompleted);
            cost = PropHelper.getNullable(arg.cost, m.cost);
            contractor = PropHelper.getNullable(arg.contractor, m.contractor);
            paymentMethod = PropHelper.getNullable(arg.paymentMethod, m.paymentMethod);
            dateReported = PropHelper.getNullable(arg.dateReported, m.dateReported);
        }
    };

    func createUpdatedMaintenance(arg: MaintenanceRecordUArg, property: Property, id: Nat): OperationalIntentResult {
        switch(PropHelper.getElementByKey(property.operational.maintenance, id)) {
            case(null) return #Err(#InvalidElementId);
            case(?m) {
                let updated = mutateMaintenance(arg, m);
                switch(validateMaintenance(updated)) {
                    case(#err(e)) return #Err(e);
                    case(_) return #Ok(#Maintenance(#Update(updated, id)));
                }
            }
        }
    };

    public func createMaintenance(arg: MaintenanceRecordCArg, property: Property): OperationalIntentResult {
        let newId = property.operational.maintenanceId + 1;
        let newMaintenance = {arg with id = newId};
        switch(validateMaintenance(newMaintenance)) {
            case(#err(e)) return #Err(e);
            case(_) return #Ok(#Maintenance(#Create(newMaintenance, newId)));
        }
    };

    public func deleteMaintenance(property: Property, id: Nat): OperationalIntentResult {
        switch(PropHelper.getElementByKey(property.operational.maintenance, id)) {
            case(null) return #Err(#InvalidElementId);
            case(_) return #Ok(#Maintenance(#Delete(id)));
        }
    };

    public func writeMaintenance(action: Actions<MaintenanceRecordCArg, (MaintenanceRecordUArg, Nat)>, property: Property): UpdateResult {
        let result = switch(action) {
            case(#Create(arg)) createMaintenance(arg, property);
            case(#Update(arg, id)) createUpdatedMaintenance(arg, property, id);
            case(#Delete(id)) deleteMaintenance(property, id);
        };

        applyOperationalUpdate(result, property, #Maintenance(action));
    };

    // Inspection

    func validateInspection(i: InspectionRecord): Result.Result<InspectionRecord, UpdateError> {
        if (Text.equal(i.inspectorName, "")) return #err(#InvalidData{field = "inspector name"; reason = #EmptyString;});
        if (Text.equal(i.findings, "")) return #err(#InvalidData{field = "findings"; reason = #EmptyString;});
        if (Option.get(i.date, Time.now()) > Time.now()) return #err(#InvalidData{field = "inspection date"; reason = #CannotBeSetInTheFuture;});
        return #ok(i);
    };

    func mutateInspection(arg: InspectionRecordUArg, i: InspectionRecord): InspectionRecord {
        {
            i with
            inspectorName = PropHelper.get(arg.inspectorName, i.inspectorName);
            findings = PropHelper.get(arg.findings, i.findings);
            date = PropHelper.getNullable(arg.date, i.date);
            actionRequired = PropHelper.getNullable(arg.actionRequired, i.actionRequired);
            followUpDate = PropHelper.getNullable(arg.followUpDate, i.followUpDate);
        }
    };

    func createUpdatedInspection(arg: InspectionRecordUArg, property: Property, id: Nat): OperationalIntentResult {
        switch(PropHelper.getElementByKey(property.operational.inspections, id)) {
            case(null) return #Err(#InvalidElementId);
            case(?i) {
                let updated = mutateInspection(arg, i);
                switch(validateInspection(updated)) {
                    case(#err(e)) return #Err(e);
                    case(_) return #Ok(#Inspection(#Update(updated, id)));
                }
            }
        }
    };

    public func createInspection(arg: InspectionRecordCArg, property: Property, caller: Principal): OperationalIntentResult {
        let newId = property.operational.inspectionsId + 1;
        let newInspection = {arg with id = newId; appraiser = caller};
        switch(validateInspection(newInspection)) {
            case(#err(e)) return #Err(e);
            case(_) return #Ok(#Inspection(#Create(newInspection, newId)));
        }
    };

    public func deleteInspection(property: Property, id: Nat): OperationalIntentResult {
        switch(PropHelper.getElementByKey(property.operational.inspections, id)) {
            case(null) return #Err(#InvalidElementId);
            case(_) return #Ok(#Inspection(#Delete(id)));
        }
    };

    public func writeInspection(action: Actions<InspectionRecordCArg, (InspectionRecordUArg, Nat)>, property: Property, caller: Principal): UpdateResult {
        let result = switch(action) {
            case(#Create(arg)) createInspection(arg, property, caller);
            case(#Update(arg, id)) createUpdatedInspection(arg, property, id);
            case(#Delete(id)) deleteInspection(property, id);
        };

        applyOperationalUpdate(result, property, #Inspection(action));
    };

    // Tenant

    func validateTenant(t: Tenant): Result.Result<Tenant, UpdateError> {
        if (Text.equal(t.leadTenant, "")) return #err(#InvalidData{field = "lead tenant"; reason = #EmptyString;});
        if (t.monthlyRent <= 0) return #err(#InvalidData{field = "monthly rent"; reason = #CannotBeZero;});
        if (t.deposit <= 0) return #err(#InvalidData{field = "deposit"; reason = #CannotBeZero;});
        if (t.leaseStartDate < Time.now()) return #err(#InvalidData{field = "lease start date"; reason = #CannotBeSetInThePast;});
        return #ok(t);
    };

    func mutateTenant(arg: TenantUArg, t: Tenant): Tenant {
        {
            t with
            leadTenant = PropHelper.get(arg.leadTenant, t.leadTenant);
            otherTenants = PropHelper.get(arg.otherTenants, t.otherTenants);
            monthlyRent = PropHelper.get(arg.monthlyRent, t.monthlyRent);
            deposit = PropHelper.get(arg.deposit, t.deposit);
            leaseStartDate = PropHelper.get(arg.leaseStartDate, t.leaseStartDate);
            contractLength = PropHelper.get(arg.contractLength, t.contractLength);
            paymentHistory = PropHelper.get(arg.paymentHistory, t.paymentHistory);
            principal = PropHelper.getNullable(arg.principal, t.principal);
        }
    };

    func createUpdatedTenant(arg: TenantUArg, property: Property, id: Nat): OperationalIntentResult {
        switch(PropHelper.getElementByKey(property.operational.tenants, id)) {
            case(null) return #Err(#InvalidElementId);
            case(?t) {
                let updated = mutateTenant(arg, t);
                switch(validateTenant(updated)) {
                    case(#err(e)) return #Err(e);
                    case(_) return #Ok(#Tenant(#Update(updated, id)));
                }
            }
        }
    };

    public func createTenant(arg: TenantCArg, property: Property): OperationalIntentResult {
        let newId = property.operational.tenantId + 1;
        let newTenant = {arg with id = newId; paymentHistory = []};
        switch(validateTenant(newTenant)) {
            case(#err(e)) return #Err(e);
            case(_) return #Ok(#Tenant(#Create(newTenant, newId)));
        }
    };

    public func deleteTenant(property: Property, id: Nat): OperationalIntentResult {
        switch(PropHelper.getElementByKey(property.operational.tenants, id)) {
            case(null) return #Err(#InvalidElementId);
            case(_) return #Ok(#Tenant(#Delete(id)));
        }
    };

    public func writeTenant(action: Actions<TenantCArg, (TenantUArg, Nat)>, property: Property): UpdateResult {
        let result = switch(action) {
            case(#Create(arg)) createTenant(arg, property);
            case(#Update(arg, id)) createUpdatedTenant(arg, property, id);
            case(#Delete(id)) deleteTenant(property, id);
        };

        applyOperationalUpdate(result, property, #Tenant(action));
    };

    public func applyOperationalUpdate<C, U>(intent: OperationalIntentResult, property: Property, action: Types.What): UpdateResult {
        let operational = switch(intent) {
            case(#Ok(#Maintenance(act))) {
                {
                    property.operational with
                    maintenanceId = PropHelper.updateId(act, property.operational.maintenanceId);
                    maintenance = PropHelper.performAction(act, property.operational.maintenance);
                }
            };
            case(#Ok(#Inspection(act))) {
                {
                    property.operational with
                    inspectionsId = PropHelper.updateId(act, property.operational.inspectionsId);
                    inspections = PropHelper.performAction(act, property.operational.inspections);
                }
            };
            case(#Ok(#Tenant(act))) {
                {
                    property.operational with
                    tenantId = PropHelper.updateId(act, property.operational.tenantId);
                    tenants = PropHelper.performAction(act, property.operational.tenants);
                }
            };
            case(#Err(e)) return #Err(e);
        };

        PropHelper.updateProperty(#Operational(operational), property, action);
    };
}
