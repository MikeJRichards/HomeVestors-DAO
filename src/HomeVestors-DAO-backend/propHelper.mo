import Types "types";
import UnstableTypes "Tests/unstableTypes";
import Array "mo:base/Array";
import Hash "mo:base/Hash";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Blob "mo:base/Blob";
import Result "mo:base/Result";
import Buffer "mo:base/Buffer";
import HashMap "mo:base/HashMap";
import Int "mo:base/Int";
import Debug "mo:base/Debug";

module PropertiesHelper {
   type Property = Types.Property;
   type Properties = Types.Properties;
   type Update = Types.Update;
   type PropertyResult<T> = Types.PropertyResult<T>;
   type Result = Types.Result;
   type GetPropertyResult = Types.GetPropertyResult;
   type UpdateResult = Types.UpdateResult;
   type Account = Types.Account;
   type Intent<T> = Types.Intent<T>;
   type What = Types.What;
   type CrudHandler<C,U, T, StableT> = UnstableTypes.CrudHandler<C,U,T ,StableT>;

    public func accountEqual(a : Account, b : Account) : Bool {
         Principal.equal(a.owner, b.owner) and
         blobEqual(a.subaccount, b.subaccount)
    };
  
    public func blobEqual(a : ?Blob, b : ?Blob) : Bool {
        switch (a, b) {
          case (null, null) true;
          case (?a, ?b) Blob.equal(a, b);
          case _ false;
        }
    };

    public func accountHash(account: Account): Hash.Hash {
        let ownerBlob = Principal.hash(account.owner);
        let subaccountBlob = switch (account.subaccount) {
            case null { Blob.hash(Blob.fromArray([])) };
            case (?sub) { Blob.hash(sub)};
        };
        return ownerBlob ^ subaccountBlob;
    };

    public func natToHash(n: Nat): Hash.Hash {
       Text.hash(Nat.toText(n));  
    };


    public func getNullable<T>(test: ?T, alternative: ?T): ?T {
        switch(test){
            case(?t) ?t;
            case(null) alternative;
        }
    };

     public func get<T>(test: ?T, alternative: T): T {
        switch(test){
            case(?t) t;
            case(null) alternative;
        }
    };

    public func getPropertyFromId(id: Nat, properties: Properties): GetPropertyResult {
        switch(properties.get(id)){
            case(null){
                return #Err();
            };
            case(?property){
                return #Ok(property);
            }
        }
    };

    public func isInList<T>(target: T, list: [T], equal: (T, T) -> Bool) : Bool {
      switch (Array.find<T>(list, func (item) { equal(item, target) })) {
        case (?_) true;
        case null false;
      }
    };

    public func getElementByKey<T>(arr: [(Nat, T)], key: Nat) : ?T {
        for ((k, v) in arr.vals()) {
            if (k == key) {
                return ?v;
            }
        };
        return null;
    };

    public func updateElementByKey<T>(arr: [(Nat, T)], key: Nat, newValue: T) : [(Nat, T)] {
        return Array.map<(Nat, T), (Nat, T)>(arr, func((k, v)) {
            if (k == key) {
                return (k, newValue);
            } else {
                return (k, v);
            }
        });
    };

    public func removeElementByKey<T>(arr: [(Nat, T)], key: Nat) : [(Nat, T)] {
        return Array.filter<(Nat, T)>(arr, func((k, v)) {
            k != key
        });
    };

    public func addElement<T>(arr: [(Nat, T)], key: Nat, value: T) : [(Nat, T)] {
        for ((k, v) in arr.vals()) {
            if (k == key) {
                return arr;
            }
        };
        return Array.append(arr, [(key, value)]);
    };

    public func getAdmin(): Principal {
        Principal.fromText("b7qdj-qbquz-a4rzw-dl5y6-a6gun-mi7yk-tnlxd-jjwom-fqqry-2jpr2-xqe");
    };
    type OkUpdateResult = Types.OkUpdateResult;
    type UpdateError = Types.UpdateError;
    type UpdateResults = Types.UpdateResults;

    public func updateProperty(update: Update, property: Property, action: What, results: [Result.Result<?Nat, (?Nat, UpdateError)>]): UpdateResult {
       // Debug.print("ultimate results are "#debug_show(results));
        if(Array.find<Result.Result<?Nat, (?Nat, UpdateError)>>(results, func(res) {Result.isOk(res)}) != null){
            var updatedProperty = switch(update){
                case(#Details(d)){{property with details = d;}};
                case(#Financials(f)){{property with financials = f}};
                case(#Administrative(a)){{property with administrative = a}};
                case(#Operational(o)){{property with operational = o}};
                case(#NFTMarketplace(m)){{property with nftMarketplace = m}};
                case(#Governance(g)){{property with governance = g}};
            };
            return #Ok({updatedProperty with updates = Array.append(property.updates, [ #Ok( {what = action; results} ) ] )});
        }
        else {
            let buf = Buffer.Buffer<(?Nat, UpdateError)>(results.size());
            for(res in results.vals()){
                switch(res){
                    case(#err(e)) buf.add(e);
                    case(_){};
                }
            };
           // Debug.print("result buff"#debug_show(Buffer.toArray(buf)));
            #Err(Buffer.toArray(buf));
        };
    };

    public func noAsyncEffect<T>(): (T -> async Result.Result<(), Types.UpdateError>) {
        func(_: T): async Result.Result<(), Types.UpdateError> {
            #ok();
        }
    };

    public func updateId<T>(action: Intent<T>, currentId: Nat): Nat{
        switch(action){
            case(#Create(_)) return currentId + 1;
            case(_) return currentId;
        };
    };

    public func performAction<T>(action: Intent<T>, arr: [(Nat, T)]): [(Nat, T)]{
        switch(action){
            case(#Create(el, id)){
                return addElement<T>(arr, id, el);
            };
            case(#Update(el, id)){
                return updateElementByKey<T>(arr, id, el)
            };
            case(#Delete(id)){
                return removeElementByKey<T>(arr, id);
            }
        };
    };

    public func lastEntry<T,V>(arr: [(T, V)]): ?V {
        if(arr.size() == 0) {
            return null
        } 
        else {
            let (_, v) = arr[arr.size() - 1];
            return ?v
        };
    };

    public func matchNullableAccounts(acc1: ?Account, acc2: ?Account): Bool {
        switch(acc1, acc2){
            case(?account1, ?account2) account1 == account2;
            case(_) true; 
        }
    };

    public func matchNullableAccountArr(account: ?Account, accounts: [Account]): Bool {
        switch(account){
            case(?acc1){
                for(acc2 in accounts.vals()){
                    if(acc1 == acc2) return true;
                };
                return false;
            };
            case(_) true; 
        }
    };



    public func applyHandler<T, StableT>(args: Types.Arg, handler: UnstableTypes.Handler<T, StableT>): async UpdateResult {
        //here you have access to before / creates - but updates already changed
        let validatedElementsArr :  [(?Nat, Result.Result<T, UpdateError>)] = handler.validateAndPrepare();
        // 3️⃣ Run asyncEffect in batch
        let asyncResults: [(?Nat, Result.Result<(), Types.UpdateError>)] = await handler.asyncEffect(validatedElementsArr);
        //Debug.print("ASYNC RESULTS: "# debug_show(asyncResults));
        let combinedResults : [(?Nat, Result.Result<StableT, UpdateError>)] = zipResults(validatedElementsArr, asyncResults, handler);
        
        //for((id, res) in combinedResults.vals()){
        //    switch(res){
        //        case(#ok(el)) Debug.print("COMBINED RESULT OK");
        //        case(#err(e)) Debug.print("COMBINED RESULT ERR"# debug_show(e));
        //    }
        //};

        let finalResults = Buffer.Buffer<Result.Result<?Nat, (?Nat, UpdateError)>>(validatedElementsArr.size());
        for ((tempId, res) in combinedResults.vals()) {
            switch (res) {
                case (#ok(el)) finalResults.add(#ok(handler.applyUpdate(tempId, el)));
                case (#err(e)) finalResults.add(#err(tempId, e));
            };
        };
        //Debug.print("FINAL RESULTS"# debug_show(Buffer.toArray(finalResults)));

        //true afters aren't real until finalAsync... but in reality here you'd have all the children too. 
        await handler.finalAsync(Buffer.toArray(finalResults));
        // 5️⃣ Return full result map for caller to know per-element success/failure
        updateProperty(handler.getUpdate(), args.property, args.what, Buffer.toArray(finalResults));
    };

    public func applyUpdate<C, U, T, StableT>(action: Types.Actions<C, U>, idOpt: ?Nat, el: StableT, handler: UnstableTypes.CrudHandler<C, U, T, StableT>): ?Nat {
        switch(idOpt, action) {
            case (_, #Create(_)) {
                handler.id += 1;
                handler.map.put(handler.assignId(handler.id, el));
                handler.setId(handler.id);
                return ?handler.id;
            };
            case (?id, #Update(_)) handler.map.put(id, el);
            case (?id, #Delete(_)) handler.delete(id, el);
            case(_){};
        };
        idOpt;
    };

    public func getValid<C, U, T, StableT>(action: Types.Actions<C, U>, handler: CrudHandler<C, U, T, StableT>): [(?Nat, Result.Result<T, Types.UpdateError>)] {
        let generateValidateElements = func (ids: [Int], transform: T -> T) {
        for (i in ids.vals()) {
            let actualId : ?Nat = 
                if (i >= 0) {
                    ?Int.abs(i) // safe cast from positive Int to Nat
                } else {
                    let adjusted = handler.map.size() + i;
                    if (adjusted >= 0) ?Int.abs(adjusted) else null;
                };
    
            switch (actualId) {
                case (?idNat) {
                    let maybeEl = handler.map.get(idNat);
                    let maybeT = switch (maybeEl) {
                        case (null) null;
                        case (?el) ?transform(handler.fromStable(el));
                    };
                    validatedElements.add((?idNat, handler.validate(maybeT)));
                };
                case (null) {
                    // Invalid id
                    validatedElements.add((null, #err(#InvalidElementId)));
                };
            };
        };
    };

        
        let validatedElements = Buffer.Buffer<(?Nat, Result.Result<T, Types.UpdateError>)>(0);
        switch(action) {
            case (#Create(args)){
                var id = handler.id;
                for(arg in args.vals()){
                    validatedElements.add((?id, handler.validate(?handler.create(arg, id))));
                    id += 1;
                };
               // Debug.print("IDS: "#debug_show(id));
            }; 
            case (#Update(arg, ids)){
                generateValidateElements(ids,  func(el: T) = handler.mutate(arg, el));
                //Debug.print("IDS: "#debug_show(ids));
            }; 
            case (#Delete(ids)){
                generateValidateElements(ids, func(maybeT) = maybeT);
                //Debug.print("IDS: "#debug_show(ids));
            }; 
        };
        return Buffer.toArray(validatedElements);
    };


    public func zipResults<T, StableT>(validationArray : [(?Nat, Result.Result<T, Types.UpdateError>)], asyncArray: [(?Nat, Result.Result<(), UpdateError>)], handler:UnstableTypes.Handler<T, StableT>) : [(?Nat, Result.Result<StableT, UpdateError>)] {
      let combinedRes = func(val: Result.Result<T, Types.UpdateError>, asyn: Result.Result<(), UpdateError>): Result.Result<T, Types.UpdateError>{
        switch (val, asyn) {
          case (#err(e), _) #err(e);
          case (_, #err(e)) #err(e);
          case (#ok(el), #ok()) #ok(el);
        };
      };
     // Debug.print("validationArray size" # debug_show(validationArray.size()));
     // Debug.print("async Array size"# debug_show(asyncArray.size()));
      
      var validationNullCount = 0;
      var asyncNullCount = 0;
      var nonMatchingIds = 0;

      let validationHashMap = HashMap.HashMap<Nat, Result.Result<T, Types.UpdateError>>(validationArray.size(), Nat.equal, natToHash);
    
      for ((idOpt, res) in validationArray.vals()) {
        switch (idOpt) {
          case (?id) validationHashMap.put(id, res);
          case (null) validationNullCount += 1;
        };
      };

      let combinedResults = Buffer.Buffer<(?Nat, Result.Result<StableT, UpdateError>)>(validationArray.size());
    
      for ((idOpt, res) in asyncArray.vals()) {
        switch (idOpt) {
          case (?id) {
            switch (validationHashMap.get(id)) {
              case (?valRes){
                let arr = handler.applyAsyncEffects(idOpt, combinedRes(valRes, res));
                for((id, res) in arr.vals()){
                    combinedResults.add(id, res);
                };
              }; 
              case (null) nonMatchingIds += 1;
            };
          };
          case (null) asyncNullCount += 1;
        };
      };
        //Debug.print("validation null count"# debug_show(validationNullCount)# " async null count "# debug_show(asyncNullCount));
      if (validationNullCount == 0 and asyncNullCount == 0 and nonMatchingIds == 0 and validationArray.size() == asyncArray.size()) {
        return Buffer.toArray(combinedResults);
      } 
      else if (validationNullCount == 1 and asyncNullCount == 1 and validationArray.size() == 1 and asyncArray.size() == 1) {
        return handler.applyAsyncEffects(null, combinedRes(validationArray[0].1, asyncArray[0].1));
      };

      return [(null, #err(#OverWritingData))];
    };

    public func runNoAsync<T>(arr: [(?Nat, Result.Result<T, Types.UpdateError>)]): [(?Nat, Result.Result<(), UpdateError>)] {
        let buff = Buffer.Buffer<(?Nat, Result.Result<(), UpdateError>)>(arr.size());
        for((id, res) in arr.vals()){
            switch(res){
                case(#err(e)) buff.add(id, #err(e));
                case(#ok(el)) buff.add((id, #ok()));
            };
        };
        Buffer.toArray(buff);
    };

    type Actions<C,U> = Types.Actions<C,U>;
    type Handler<T, StableT> = UnstableTypes.Handler<T, StableT>;
    public func generateGenericHandler<C, U, T, StableT, S>(crudHandler: CrudHandler<C,U,T,StableT>, action: Actions<C, U>, toStable: T -> StableT,getUpdate: S -> Types.Update, struct: S): Handler<T,StableT>{
      {
        validateAndPrepare = func() = getValid<C, U, T, StableT>(action, crudHandler);


        asyncEffect = func(arr: [(?Nat, Result.Result<T, UpdateError>)]): async [(?Nat, Result.Result<(), UpdateError>)] { runNoAsync<T>(arr) };
        
        applyAsyncEffects = func(el: (?Nat, Result.Result<T, Types.UpdateError>)): [(?Nat, Result.Result<StableT, Types.UpdateError>)]{
          switch(el){
            case(null, _) [(null, #err(#InvalidElementId))];
            case(?id, #ok(el)) [(?id, #ok(toStable(el)))];
            case(?id, #err(e)) [(?id, #err(e))];
          }
        }; 

        applyUpdate = func(id: ?Nat, el: StableT): ?Nat =applyUpdate(action, id, el, crudHandler);

        getUpdate = func() = getUpdate(struct); 
        //#Administrative(Stables.fromPartialStableAdministrativeInfo(administrative));
        finalAsync = func(_: [Result.Result<?Nat, (?Nat, UpdateError)>]):async () {};
      };
    };

    public func makeDelete<T>(map: HashMap.HashMap<Nat, T>): (Nat, T) -> () {
      func(id: Nat, _el: T): () = map.delete(id);
    };

    public func makeIdVar(initial: Nat): { var value: Nat } {
      { var value = initial };
    };

    public func makeFlatHandler<U, T, StableT>(arg: U, current: T, mutate: (arg: U, current: T) -> T, validate: T -> Result.Result<T, UpdateError>, toStable: T -> StableT, toPropertyUpdate: StableT -> Types.Update) : UnstableTypes.Handler<T, StableT> {
    {
      validateAndPrepare = func(): [(?Nat, Result.Result<T, UpdateError>)] {
        let mutated = mutate(arg, current);
        return [(null, validate(mutated))];
      };

      asyncEffect = func(arr: [(?Nat, Result.Result<T, UpdateError>)]): async [(?Nat, Result.Result<(), UpdateError>)] {
        runNoAsync<T>(arr);
      };

      applyAsyncEffects = func(res: (?Nat, Result.Result<T, Types.UpdateError>)): [(?Nat, Result.Result<StableT, Types.UpdateError>)] {
        switch (res) {
          case (null, #ok(el)) [(null, #ok(toStable(el)))];
          case (_, #err(e)) [(null, #err(e))];
          case (?id, #ok(_)) [(?id, #err(#InvalidElementId))];
        };
      };

      applyUpdate = func(id: ?Nat, el: StableT): ?Nat {
        id;
      };

      getUpdate = func(): Types.Update {
        toPropertyUpdate(toStable(current));
      };

      finalAsync = func(_: [Result.Result<?Nat, (?Nat, UpdateError)>]): async () {};
    }
  };

    public func matchEqualityFlag(int: Int, eq: ?Types.EqualityFlag): Bool {
        switch(eq){
            case(null) true;
            case(?#LessThan(cond)) int < cond; 
            case(?#MoreThan(cond)) int > cond;
        };
    };

    public func matchNullablePrincipals(p1: ?Principal, p2: ?Principal): Bool{
        //function used for reads / conditionals so defaults to true if either are null
        switch(p1, p2){
            case(?p1, ?p2) Principal.equal(p1, p2);
            case(_) true;
        }
    };

    public func matchWhat(what: [What], whatFlag: ?Types.WhatFlag): Bool {
    switch (whatFlag) {
        case (null) { 
            return true;  // Always match if flag is null, even for empty actions
        };
        case (?flag) {
            for (w in what.vals()) {
                switch (w, flag) {
                    case (#Insurance(_), #Insurance) return true;
                    case (#Document(_), #Document) return true;
                    case (#Note(_), #Note) return true;
                    case (#Maintenance(_), #Maintenance) return true;
                    case (#Inspection(_), #Inspection) return true;
                    case (#Tenant(_), #Tenant) return true;
                    case (#Valuations(_), #Valuations) return true;
                    case (#Financials(_), #Financials) return true;
                    case (#MonthlyRent(_), #MonthlyRent) return true;
                    case (#PhysicalDetails(_), #PhysicalDetails) return true;
                    case (#AdditionalDetails(_), #AdditionalDetails) return true;
                    case (#NftMarketplace(#FixedPrice(_)), #NftMarketplace(#FixedPrice)) return true;
                    case (#NftMarketplace(#Auction(_)), #NftMarketplace(#Auction)) return true;
                    case (#NftMarketplace(#Launch(_)), #NftMarketplace(#Launch)) return true;
                    case (#NftMarketplace(#Bid(_)), #NftMarketplace(#Bid)) return true;
                    case (#Images(_), #Images) return true;
                    case (#Invoice(_), #Invoice) return true;
                    case (#Description(_), #Description) return true;
                    case (#Governance(#Vote(_)), #Governance(#Vote)) return true;
                    case (#Governance(#Proposal(_)), #Governance(#Proposal)) return true;
                    case (_) {};  // No match for this action/flag combo
                };
            };
            return false;  // No matching actions found for non-null flag
        };
    };
};
}



