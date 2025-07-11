import Types "types";
import UnstableTypes "./Tests/unstableTypes";
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
import Nat "mo:base/Nat";


module {
    type CreateFinancialsArg = Types.CreateFinancialsArg;
    type InvestmentDetails = Types.InvestmentDetails;
    type Financials = Types.Financials;
    type Handler<C, U, T> = UnstableTypes.Handler<C,U,T>;
    type ValuationRecordCArg = Types.ValuationRecordCArg; 
    type ValuationRecordUArg = Types.ValuationRecordUArg; 
    type ValuationRecordUnstable = UnstableTypes.ValuationRecordUnstable;
    type SimpleHandler<T> = UnstableTypes.SimpleHandler<T>;
    type Property = Types.Property;
    type UpdateResult = Types.UpdateResult;
    type UpdateError = Types.UpdateError;
    type FinancialIntentResult = Types.FinancialIntentResult;
    type What = Types.What;
    type PropertyUnstable = UnstableTypes.PropertyUnstable;
    type FinancialsArg = Types.FinancialsArg;
    

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

   

   public func createValuationHandler(): Handler<ValuationRecordCArg, ValuationRecordUArg, ValuationRecordUnstable> {
      {
        map = func(p: PropertyUnstable) = p.financials.valuations;

        getId = func(p: PropertyUnstable) = p.financials.valuationId;

        incrementId = func(p: PropertyUnstable) = p.financials.valuationId += 1;

        mutate = func(arg: ValuationRecordUArg, v: ValuationRecordUnstable): ValuationRecordUnstable {
            v.value := PropHelper.get(arg.value, v.value);
            v.method := PropHelper.get(arg.method, v.method);
            v;
        };

        create = func(arg: ValuationRecordCArg, id: Nat, caller: Principal): ValuationRecordUnstable {
            {
                var id; 
                var value = arg.value;
                var method = arg.method;
                var date = Time.now(); 
                var appraiser = caller
            };
        };

        validate = func(maybeValuation: ?ValuationRecordUnstable): Result.Result<ValuationRecordUnstable, UpdateError> {
            let v = switch(maybeValuation){case(null) return #err(#InvalidElementId); case(?valuation) valuation};
            if (v.value <= 0) return #err(#InvalidData{field = "value"; reason = #CannotBeZero});
            return #ok(v);
        }
      }
    };
               
    public func monthlyRentHandler(): SimpleHandler<Nat> {
      {
        validate = func(val: Nat): Result.Result<Nat, UpdateError> {
            if(val <= 0) return #err(#InvalidData{field = "Monthly Rent"; reason = #CannotBeZero;});
            #ok(val);
        };

        apply = func(val: Nat, p: PropertyUnstable) {
            p.financials.monthlyRent := val;
            p.financials.yield := Float.fromInt(val * 12) / Float.fromInt(p.financials.currentValue);
        }
      }
    };

    public func currentValueHandler(): SimpleHandler<FinancialsArg> {
      {
        validate = func(arg: FinancialsArg): Result.Result<FinancialsArg, UpdateError> {
           if(arg.currentValue <= 0) return #err(#InvalidData{field = "current value"; reason = #CannotBeZero;});
            #ok(arg);
        };

        apply = func(arg: FinancialsArg, p: PropertyUnstable) {
            p.financials.currentValue := arg.currentValue;
            p.financials.pricePerSqFoot := arg.currentValue / p.details.physical.squareFootage;
        }
      }
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

    public func createURL(property: Property): Text {
        let propertyId = Nat.toText(property.id);

        let postcode = Text.replace(property.details.location.postcode, #char ' ', "");
        let internal_area = if(property.details.physical.squareFootage < 300) Nat.toText(300) else Nat.toText(property.details.physical.squareFootage);
        let bedrooms = Nat.toText(property.details.physical.beds);
        let bathrooms = Nat.toText(property.details.physical.baths);

        // 🟢 Simple logic to pick enums (these can be improved later)
        let construction_date = if (property.details.physical.yearBuilt < 1914) {
          "pre_1914"
        } else if (property.details.physical.yearBuilt <= 2000) {
          "1914_2000"
        } else {
          "2000_onwards"
        };

        let property_type = "semi-detached_house"; // 🟢 Default for now
        let finish_quality = "average";       // 🟢 Default for now
        let outdoor_space = "garden";         // 🟢 Default for now
        let off_street_parking = "0";         // 🟢 Default for now

        let url = "https://property-valuations.fly.dev"
          # "?property_id=" # propertyId
          # "&postcode=" # postcode
          # "&internal_area=" # internal_area
          # "&property_type=" # property_type
          # "&construction_date=" # construction_date
          # "&bedrooms=" # bedrooms
          # "&bathrooms=" # bathrooms
          # "&finish_quality=" # finish_quality
          # "&outdoor_space=" # outdoor_space
          # "&off_street_parking=" # off_street_parking;
        return url;
    };

    public func fetchValuation(property: Property, transform: query ({context : Blob; response : IC.http_request_result;}) -> async IC.http_request_result) : async Result.Result<What, UpdateError> {
  
    let url = createURL(property);
    let req : IC.http_request_args = {
      url = url;
      method = #get;
      headers = [];
      body = null;
      max_response_bytes = ?3000;
      transform = ?{
        function = transform;
        context = Blob.fromArray([]);
      };
    };

    // First HTTP outcall (ignored result)
    ExperimentalCycles.add<system>(100_000_000_000);
    let _ = await IC.http_request(req);

    // Second HTTP outcall (actual result)
    ExperimentalCycles.add<system>(100_000_000_000);
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
      method = #Online;
    };

    return #ok(#Valuations(#Create(valuation)));
};

public func fetchValuationOG(postcode: Text, transform: query ({context : Blob; response : IC.http_request_result;}) -> async IC.http_request_result) : async Result.Result<What, UpdateError> {
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

        // First HTTP outcall (ignored result)
        ExperimentalCycles.add<system>(100_000_000_000);
        let _ = await IC.http_request(req);

        // Second HTTP outcall (actual result)
        ExperimentalCycles.add<system>(100_000_000_000);
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
