import Types "types";
import PropHelper "propHelper";
import Float "mo:base/Float";
import Result "mo:base/Result";
import Time "mo:base/Time";
import IC "ic:aaaaa-aa";
import JSON "mo:json";
import ExperimentalCycles "mo:base/ExperimentalCycles";
import Int "mo:base/Int";
import Blob "mo:base/Blob";
import Text "mo:base/Text";


module {
    type Financials = Types.Financials;
    type InvestmentDetails = Types.InvestmentDetails;
    type ValuationRecord = Types.ValuationRecord;
    type CreateFinancialsArg = Types.CreateFinancialsArg;
    type Property = Types.Property;
    type UpdateResult = Types.UpdateResult;
    type UpdateError = Types.UpdateError;
    type ValuationRecordUArg = Types.ValuationRecordUArg; 
    type ValuationRecordCArg = Types.ValuationRecordCArg; 
    type FinancialIntentResult = Types.FinancialIntentResult;
    type Actions<C,U> = Types.Actions<C,U>;
    type What = Types.What;
    type Reason = Types.Reason;

     func createInvestmentDetails (arg: CreateFinancialsArg): InvestmentDetails {
        return {
            totalInvestmentValue = arg.reserve + arg.purchasePrice + arg.platformFee;
            platformFee = arg.platformFee;
            initialMaintenanceReserve = arg.reserve;
            purchasePrice = arg.purchasePrice;
        }
    };

    public func createFinancials (arg : CreateFinancialsArg) : Financials {
        {
            investment = createInvestmentDetails(arg);
            currentValue = arg.currentValue;
            pricePerSqFoot = arg.currentValue / arg.sqrFoot;
            valuationId = 0;
            valuations = [];
            monthlyRent = arg.monthlyRent;
            yield = Float.fromInt(arg.monthlyRent) / Float.fromInt(arg.currentValue);
        }
    };

    func validateValuation(v: ValuationRecord): Result.Result<ValuationRecord, UpdateError> {
        if (v.value <= 0) return #err(#InvalidData{field = "value"; reason = #CannotBeZero});
        return #ok(v);
    };

    func mutateValuation(arg: ValuationRecordUArg, v: ValuationRecord): ValuationRecord {
        {
            v with
            value = PropHelper.get(arg.value, v.value);
            method = PropHelper.get(arg.method, v.method);
        }
    };

    func createUpdatedValuation(arg: ValuationRecordUArg, property: Property, id: Nat): FinancialIntentResult {
        switch (PropHelper.getElementByKey(property.financials.valuations, id)) {
            case (null) return #Err(#InvalidElementId);
            case (?v) {
                let updated = mutateValuation(arg, v);
                switch (validateValuation(updated)) {
                    case (#err(e)) return #Err(e);
                    case (_) return #Ok(#Valuation(#Update(updated, id)));
                }
            }
        }
    };

    public func createValuation(arg: ValuationRecordCArg, property: Property, caller: Principal): FinancialIntentResult {
        let newId = property.financials.valuationId + 1;
        let newValuation = {arg with id = newId; date = Time.now(); appraiser = caller};
        switch (validateValuation(newValuation)) {
            case (#err(e)) return #Err(e);
            case (_) return #Ok(#Valuation(#Create(newValuation, newId)));
        }
    };

    public func deleteValuation(property: Property, id: Nat): FinancialIntentResult {
        switch (PropHelper.getElementByKey(property.financials.valuations, id)) {
            case (null) return #Err(#InvalidElementId);
            case (_) return #Ok(#Valuation(#Delete(id)));
        }
    };

    public func writeValuation(action: Actions<ValuationRecordCArg, (ValuationRecordUArg, Nat)>, property: Property, caller: Principal): UpdateResult {
        let result = switch (action) {
            case (#Create(arg)) createValuation(arg, property, caller);
            case (#Update(arg, id)) createUpdatedValuation(arg, property, id);
            case (#Delete(id)) deleteValuation(property, id);
        };

        applyFinancialUpdate(result, property, #Valuations(action));
    };

    public func applyFinancialUpdate<C, U>(intent: FinancialIntentResult, property: Property, action: What): UpdateResult {
        let financials : Financials = switch (intent) {
            case (#Ok(#Valuation(act))) {
                {
                    property.financials with
                    valuationId = PropHelper.updateId(act, property.financials.valuationId);
                    valuations = PropHelper.performAction(act, property.financials.valuations);
                }
            };
            case (#Ok(#Financials(arg))){
                if(arg.currentValue <= 0) return #Err(#InvalidData{field = "current value"; reason = #CannotBeZero;});
                {
                    property.financials with
                    currentValue = arg.currentValue;
                    pricePerSqFoot = arg.currentValue / property.details.physical.squareFootage;
                }
            };
            case(#Ok(#MonthlyRent(rent))){
                if(rent <= 0) return #Err(#InvalidData{field = "rent"; reason = #CannotBeZero;});
                {
                    property.financials with 
                    monthlyRent = rent;
                    yield = Float.fromInt(rent * 12) / Float.fromInt(property.financials.currentValue);
                }
            };
            case (#Err(e)) return #Err(e);
        };

        PropHelper.updateProperty(#Financials(financials), property, action);
    };

    public func fetchValuation(postcode: Text, transform: query ({context : Blob; response : IC.http_request_result;}) -> async IC.http_request_result) : async Result.Result<What, UpdateError> {
        ExperimentalCycles.add<system>(100_000_000_000);
        let validPostcode = Text.replace(postcode, #char ' ', "");
        let url = "https://valuation-fly.fly.dev/valuation?postcode="#validPostcode;

        let req : IC.http_request_args = {
          url = url;
          method = #get;
          headers = [];
          body = null;
          max_response_bytes = ?2000;
          transform = ?{
            function = transform;
            context = Blob.fromArray([]);
          };
        };

        let res = await IC.http_request(req);

        let bodyText = switch (Text.decodeUtf8(res.body)) {
          case (?text) text;
          case null return #err(#InvalidData{field = "valuation"; reason = #FailedToDecodeResponseBody});
        };

        let parsed = switch (JSON.parse(bodyText)) {
          case (#ok(val)) val;
          case (#err(_)) return #err(#InvalidData{field = "valuation"; reason = #JSONParseError});
        };

        let estimate = switch (JSON.get(parsed, "estimate")) {
          case (?#number(#int(n))) Int.abs(n);
          case (?#number(#float(n))) Int.abs(Float.toInt(n));
          case (_) return #err(#InvalidData{field = "valuation"; reason = #CannotBeNull});
        };

        let valuation = {
            value = estimate;
            method = #Online
        };

        return #ok(#Valuations(#Create(valuation)));
    };



}