import Types "types";
import UnstableTypes "./Tests/unstableTypes";
import Stables "./Tests/stables";
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
import Sha256 "mo:sha2/Sha256";
import Principal "mo:base/Principal";


module {
  type CreateFinancialsArg = Types.CreateFinancialsArg;
  type InvestmentDetails = Types.InvestmentDetails;
  type Financials = Types.Financials;
  type Handler<T, StableT> = UnstableTypes.Handler<T, StableT>;
  type CrudHandler<C, U, T, StableT> = UnstableTypes.CrudHandler<C, U, T, StableT>;
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
  type Arg = Types.Arg;
  type Actions<C,U> = Types.Actions<C,U>;
    

  func createInvestmentDetails (arg: CreateFinancialsArg): InvestmentDetails {
      return {
          totalInvestmentValue = arg.reserve + arg.purchasePrice + arg.platformFee;
          platformFee = arg.platformFee;
          initialMaintenanceReserve = arg.reserve;
          purchasePrice = arg.purchasePrice;
      }
  };

  func toSubaccountFromPropertyId(propertyId: Nat): Blob {
    let seedText = "property-" # Nat.toText(propertyId);
    Sha256.fromBlob(#sha256, Text.encodeUtf8(seedText));
  };

  public func createFinancials(arg : CreateFinancialsArg, id: Nat) : Financials {
      {
          account = {owner = Principal.fromText("vq2za-kqaaa-aaaas-amlvq-cai"); subaccount = ?toSubaccountFromPropertyId(id)}; 
          investment = createInvestmentDetails(arg);
          currentValue = arg.currentValue;
          pricePerSqFoot = arg.currentValue / arg.sqrFoot;
          valuationId = 0;
          valuations = [];
          invoiceId = 0;
          invoices = [];
          monthlyRent = arg.monthlyRent;
          yield = Float.fromInt(arg.monthlyRent) / Float.fromInt(arg.currentValue);
      }
  };

  public func createValuationHandler(args: Arg, action: Actions<ValuationRecordCArg, ValuationRecordUArg>): async UpdateResult {
    type C = ValuationRecordCArg;
    type U = ValuationRecordUArg;
    type T = ValuationRecordUnstable;
    type StableT = Types.ValuationRecord;
    type S = UnstableTypes.FinancialsPartialUnstable;
    let financials = Stables.toPartialStableFinancials(args.property.financials);
    let map = financials.valuations;
    let crudHandler: CrudHandler<C, U, T, StableT> = {
      map;
      var id = financials.valuationId;
      setId = func(id: Nat) = financials.valuationId := id;
      assignId = func(id: Nat, el: StableT) = (id, {el with id = id;});
      delete = PropHelper.makeDelete(map);
      fromStable = Stables.fromStableValuationRecord;
      
      mutate = func(arg: U, v: T): T {
        v.value := PropHelper.get(arg.value, v.value);
        v.method := PropHelper.get(arg.method, v.method);
        v;
      };

      create = func(arg: C, id: Nat): T {
          {
              var id; 
              var value = arg.value;
              var method = arg.method;
              var date = Time.now(); 
              var appraiser = args.caller
          };
      };

      validate = func(maybeValuation: ?T): Result.Result<T, UpdateError> {
          let v = switch(maybeValuation){case(null) return #err(#InvalidElementId); case(?valuation) valuation};
          if (v.value <= 0) return #err(#InvalidData{field = "value"; reason = #CannotBeZero});
          return #ok(v);
      }
    };      

    let handler = PropHelper.generateGenericHandler<C, U, T, StableT, S>(crudHandler, action, Stables.toStableValuationRecord, func(s: S) = #Financials(Stables.fromPartialStableFinancials(financials)), financials, func(stableT: ?StableT) = #Valuations(stableT), func(property: Property) = property.financials.valuations);
    await PropHelper.applyHandler<T, StableT>(args, handler);
  };

  public func monthlyRentHandler(args: Arg, arg: Nat): async UpdateResult {
    type U = Nat;
    type T = UnstableTypes.FinancialsPartialUnstable;
    type StableT = Financials;
    
    let mutate = func(arg: U, financials: T): T{
      financials.monthlyRent := arg;
      financials.yield := Float.fromInt(arg * 12) / Float.fromInt(financials.currentValue);
      financials;
    };

    let validate = func(arg: T): Result.Result<T, UpdateError> {
      if(arg.monthlyRent <= 0) return #err(#InvalidData{field = "Monthly Rent"; reason = #CannotBeZero;});
      #ok(arg);
    };

    let handler = PropHelper.makeFlatHandler<U, T, StableT>(
      arg,
      Stables.toPartialStableFinancials(args.property.financials),
      mutate,
      validate,
      Stables.fromPartialStableFinancials,
      func(el: StableT) = #Financials(
        {
          args.property.financials with
          monthlyRent = el.monthlyRent; 
          yield = el.yield;
        }
      ), 
      func(property: Property) = #Financials(?property.financials)
    );

    await PropHelper.applyHandler(args, handler);
  };

  public func currentValueHandler(args: Arg, arg: FinancialsArg): async UpdateResult {
    type U = FinancialsArg;
    type T = UnstableTypes.FinancialsPartialUnstable;
    type StableT = Financials;
    
    let mutate = func(arg: U, financials: T): T{
      financials.currentValue := arg.currentValue;
      financials.pricePerSqFoot := arg.currentValue / args.property.details.physical.squareFootage;
      financials;
    };

    let validate = func(arg: T): Result.Result<T, UpdateError> {
      if(arg.currentValue <= 0) return #err(#InvalidData{field = "current value"; reason = #CannotBeZero;});
      #ok(arg);
    };

    let handler = PropHelper.makeFlatHandler<U, T, StableT>(
      arg,
      Stables.toPartialStableFinancials(args.property.financials),
      mutate,
      validate,
      Stables.fromPartialStableFinancials,
      func(el: StableT) = #Financials(
        {
          args.property.financials with 
          currentValue = el.currentValue; 
          pricePerSqFoot = el.pricePerSqFoot;
        }
      ),
      func(property: Property) = #Value(?{
        currentValue = property.financials.currentValue; 
        pricePerSqFoot = property.financials.pricePerSqFoot
      })
    );

    await PropHelper.applyHandler(args, handler);
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

  public func fetchValuation(property: Property, transform: query ({context : Blob; response : IC.http_request_result;}) -> async IC.http_request_result) : async Result.Result<What, [(?Nat, UpdateError)]> {
  
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
        case null return #err([(?property.id, #InvalidData{field = "valuation"; reason = #FailedToDecodeResponseBody})]);
      };

      let parsed = switch (JSON.parse(bodyText)) {
        case (#ok(val)) val;
        case (#err(_)) return #err([(?property.id, #InvalidData{field = "valuation"; reason = #JSONParseError})]);
      };

      let estimate = switch (JSON.get(parsed, "estimate")) {
        case (?#number(#int(n))) Int.abs(n);
        case (?#number(#float(n))) Int.abs(Float.toInt(n));
        case (_) return #err([(?property.id, #InvalidData{field = "valuation"; reason = #CannotBeNull})]);
      };


    let valuation = {
      value = estimate;
      method = #Online;
    };

    return #ok(#Valuations(#Create([valuation])));
};




}
