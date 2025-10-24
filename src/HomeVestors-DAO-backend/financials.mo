import Types "types";
import UnstableTypes "./Tests/unstableTypes";
import Stables "./Tests/stables";
import PropHelper "propHelper";
import Float "mo:base/Float";
import Result "mo:base/Result";
import Time "mo:base/Time";
import JSON "mo:json";
import IC "mo:ic"; // Updated to use ic@3.2.0 structure
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
  type Handler<P, K, A, T, StableT> = UnstableTypes.Handler<P, K, A, T, StableT>;
  type CrudHandler<K, C, U, T, StableT> = UnstableTypes.CrudHandler<K, C, U, T, StableT>;
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
  type Arg = Types.Arg<Property>;
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
    type P = Property;
    type K = Nat;
    type C = ValuationRecordCArg;
    type U = ValuationRecordUArg;
    type A = Types.AtomicAction<K, C, U>;
    type T = ValuationRecordUnstable;
    type StableT = Types.ValuationRecord;
    type S = UnstableTypes.FinancialsPartialUnstable;
    let financials = Stables.toPartialStableFinancials(args.parent.financials);
    let map = financials.valuations;
    var tempId = financials.valuationId;
    let crudHandler: CrudHandler<K, C, U, T, StableT> = {
      map;
      getId = func() = financials.valuationId;
      createTempId = func(){
        tempId += 1;
        tempId;
      };
      incrementId = func(){financials.valuationId += 1;}; // Fixed typo: was misc.imageId
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

    let handler = PropHelper.generateGenericHandler<P, K, C, U, T, StableT, S>(
      crudHandler, 
      func(t: T): StableT = Stables.toStableValuationRecord(t),             // toStable
      func(st: ?StableT) = #Valuations(st),                                  // wrapStableT
      func(p: P): [(K, StableT)] = p.financials.valuations,              // toArray
      func(id1:K, id2:K): Bool = id1 == id2,
      PropHelper.isConflictOnNatId(),
      func(property: P){{property with financials = Stables.fromPartialStableFinancials(financials)}},
      PropHelper.updatePropertyEventLog,
      PropHelper.atomicActionToWhat(func(a: Types.Actions<C,U>): Types.What = #Valuations(a))
    );
    await PropHelper.applyHandler<P, K, A, T, StableT>(args, PropHelper.makeAutomicAction(action, map.size()), handler);
  };

  public func monthlyRentHandler(args: Arg, arg: Nat): async UpdateResult {
    type P = Property;
    type K = Nat;
    type A = Nat;
    type T = UnstableTypes.FinancialsPartialUnstable;
    type StableT = Financials;
    var financials = Stables.toPartialStableFinancials(args.parent.financials);
    
    let mutate = func(arg: A, property: P): T{
      financials := Stables.toPartialStableFinancials(property.financials);
      financials.monthlyRent := arg;
      financials.yield := Float.fromInt(arg * 12) / Float.fromInt(financials.currentValue);
      financials;
    };

    let validate = func(arg: T): Result.Result<T, UpdateError> {
      if(arg.monthlyRent <= 0) return #err(#InvalidData{field = "Monthly Rent"; reason = #CannotBeZero;});
      #ok(arg);
    };

    let handler = PropHelper.makeFlatHandler<P, K, A, T, StableT>(
      mutate,
      validate,
      Stables.fromPartialStableFinancials,
      func(p: P):Types.ToStruct<K>{#MonthlyRent(?p.financials.monthlyRent)},
      null,
      func(p: P): P {{p with financials = Stables.fromPartialStableFinancials(financials)}},
      PropHelper.updatePropertyEventLog,
      func(arg:A) = #MonthlyRent(arg)
    );

    await PropHelper.applyHandler(args, [arg], handler);
  };

  public func currentValueHandler(args: Arg, arg: FinancialsArg): async UpdateResult {
    type P = Property;
    type K = Nat;
    type A = FinancialsArg;
    type T = UnstableTypes.FinancialsPartialUnstable;
    type StableT = Financials;
    var financials = Stables.toPartialStableFinancials(args.parent.financials);
    
    let mutate = func(arg: A, property: P): T{
      financials := Stables.toPartialStableFinancials(property.financials);
      financials.currentValue := arg.currentValue;
      financials.pricePerSqFoot := arg.currentValue / args.parent.details.physical.squareFootage;
      financials;
    };

    let validate = func(arg: T): Result.Result<T, UpdateError> {
      if(arg.currentValue <= 0) return #err(#InvalidData{field = "current value"; reason = #CannotBeZero;});
      #ok(arg);
    };

    let handler = PropHelper.makeFlatHandler<P, K, A, T, StableT>(
      mutate,
      validate,
      Stables.fromPartialStableFinancials,
      func(p: P):Types.ToStruct<K>{#Value(?{currentValue = p.financials.currentValue; pricePerSqFoot = p.financials.pricePerSqFoot})},
      null,
      func(p: P): P {{p with financials = Stables.fromPartialStableFinancials(financials)}},
      PropHelper.updatePropertyEventLog,
      func(arg:A) = #Financials(arg)
    );

    await PropHelper.applyHandler(args, [arg], handler);
  };

  public func createURL(property: Property): Text {
    let propertyId = Nat.toText(property.id);
    let postcode = Text.replace(property.details.location.postcode, #char ' ', "");
    let internal_area = if(property.details.physical.squareFootage < 300) Nat.toText(300) else Nat.toText(property.details.physical.squareFootage);
    let bedrooms = Nat.toText(property.details.physical.beds);
    let bathrooms = Nat.toText(property.details.physical.baths);
    
    let construction_date = if (property.details.physical.yearBuilt < 1914) {
      "pre_1914"
    } else if (property.details.physical.yearBuilt <= 2000) {
      "1914_2000"
    } else {
      "2000_onwards"
    };
    
    let property_type = "semi-detached_house";
    let finish_quality = "average";
    let outdoor_space = "garden";
    let off_street_parking = "0";
    
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

  public func fetchValuation(property: Property, transform: query ({context : Blob; response : IC.HttpRequestResult}) -> async IC.HttpRequestResult) : async Result.Result<What, [(?Nat, UpdateError)]> {
    let url = createURL(property);
    let req : IC.HttpRequestArgs = {
      url = url;
      method = #get;
      headers = [];
      is_replicated = ?false;
      body = null;
      max_response_bytes = ?3000;
      transform = ?{
        function = transform;
        context = Blob.fromArray([]);
      };
    };

    // First HTTP outcall (ignored result, warmup)
    let _ = await IC.ic.http_request(req); // Using IC.httpRequest

    // Second HTTP outcall (actual result)
    let res = await IC.ic.http_request(req); // Using IC.httpRequest

    let bodyText = switch (Text.decodeUtf8(res.body)) { // res.body is Blob
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