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
import Time "mo:base/Time";
//import Debug "mo:base/Debug";

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
   type CrudHandler<K, C,U, T, StableT> = UnstableTypes.CrudHandler<K, C,U,T ,StableT>;
   type BeforeVsAfter<K> = Types.BeforeVsAfter<K>;
   type ToStruct<K> = Types.ToStruct<K>;
   type BeforeOrAfter = UnstableTypes.BeforeOrAfter;

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

    public func getElementByKey<K, T>(arr: [(K, T)], key: K, equal: (K, K) -> Bool) : ?T {
        for ((k, v) in arr.vals()) {
            if (equal(k,key)) {
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

    public func updatePropertyEventLog(property: Property, res: [Types.BeforeVsAfter<Nat>]): Types.UpdateResult {
        var okCount = 0;
        var errCount = 0;
        for(el in res.vals()){
            switch(el.outcome){
                case(#Err(_)) errCount += 1;
                case(_) okCount +=1;
            };
        };
        return #Property{
            okCount;
            errCount;
            diffs = res;
            parent = {property with updates = Array.append(property.updates, [res])}
        }
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

    func groupArgsByConflict<P, K, A, T, StableT>(args: [A],handler: Handler<P, K, A, T, StableT>) : [[A]] {
        // Start with an empty list of groups
        var groups : [Buffer.Buffer<A>] = [];

        for (arg in args.vals()) {
          var placed = false;

          // Try to fit this arg into an existing group
          label search for (i in groups.keys()) {
            var conflicts = false;

            // Check against every arg already in the group
            for (placedArg in groups[i].vals()) {
              if (handler.isConflict(placedArg, arg)) {
                conflicts := true;
                break search;  // stop early if conflict found
              };
            };

            if (not conflicts) {
              groups[i].add(arg);
              placed := true;
            };
          };

          // No group without conflicts found → create a new group
          if (not placed) {
            let newGroup = Buffer.Buffer<A>(1);
            newGroup.add(arg);
            groups := Array.append(groups, [newGroup]);
          };
        };

        let arrayGroups = Buffer.Buffer<[A]>(groups.size());
        for (group in groups.vals()) {
            arrayGroups.add(Buffer.toArray(group));
        };

        Buffer.toArray(arrayGroups);
    };

  

    public func makeAutomicAction<C,U>(actions: Actions<C,U>, size: Nat): [Types.AtomicAction<Nat, C,U>] {
        func normalizeId(i: Int) : Nat {
            if (i >= 0) Int.abs(i)
            else {
                let adjusted = size + i;
                if (adjusted >= 0) Int.abs(adjusted) else 0;
            };
        };

        let buf = Buffer.Buffer<Types.AtomicAction<Nat, C,U>>(0);
        switch(actions){
            case(#Create(creates)){
                for(create in creates.vals()){
                    buf.add(#Create(create));
                }
            };
            case(#Update(update, ints)){
                for(int in ints.vals()){
                    buf.add(#Update(normalizeId(int), update));
                }
            };
            case(#Delete(ints)){
                for(int in ints.vals()){
                    buf.add(#Delete(normalizeId(int)));
                }
            };
        };
        Buffer.toArray(buf);
    };

    func isOk<A, K>(arr: [(A, [Result.Result<?K, (?K, UpdateError)>])]): Bool {
        for((_, res) in arr.vals()){
            for(result in res.vals()){
                switch(result){
                    case(#ok(_)) return true;
                    case(#err(_)){};
                }
            }
        };
        false;
    };

    public func applyHandler<P, K, A, T, StableT>(applyArgs: Types.Arg<P>, arg: [A], handler: UnstableTypes.Handler<P, K, A, T, StableT>): async UpdateResult {
        //here you have access to before / creates - but updates already changed
        //grab what elements are before as a array [(Nat, Difference Enum)]
        let argsArray : [[A]] = groupArgsByConflict(arg, handler);
        let beforeVsAfterBuff = Buffer.Buffer<BeforeVsAfter<K>>(arg.size());
        var parent : P = applyArgs.parent;
        for(args in argsArray.vals()){
            let validatedElements = Buffer.Buffer<(?K, A, Result.Result<T, UpdateError>)>(args.size());
            for(arg in args.vals()) validatedElements.add(handler.validateAndPrepare(parent, arg));
            let validatedElementsArr: [(?K, A, Result.Result<T, UpdateError>)] = Buffer.toArray(validatedElements);
            let asyncResults: [Result.Result<(), Types.UpdateError>] = try{
                await handler.asyncEffect(validatedElementsArr);
            } 
            catch(_){
                let buff = Buffer.Buffer<Result.Result<(), Types.UpdateError>>(validatedElementsArr.size());
                buff.add(#err(#AsyncFailure));
                Buffer.toArray(buff);
            };
            let combinedResults : [(A, [(?K, Result.Result<StableT, UpdateError>)])] = zipResults(validatedElementsArr, asyncResults, handler);
            let finalResults = Buffer.Buffer<(A, [Result.Result<?K, (?K, UpdateError)>])>(combinedResults.size());
            for((arg, arr) in combinedResults.vals()){
                let argResults = Buffer.Buffer<Result.Result<?K, (?K, UpdateError)>>(arr.size());
                for ((tempId, res) in arr.vals()) {
                    switch (res) {
                        case (#ok(el)) argResults.add(#ok(handler.applyUpdate(tempId, arg, el))); 
                        case (#err(e)) argResults.add(#err(tempId, e));
                    };
                };
                finalResults.add((arg, Buffer.toArray(argResults)));
            };
            let finalResultsArr = Buffer.toArray(finalResults);
            await handler.finalAsync(finalResultsArr);
            let parentAfter = if (isOk(finalResultsArr)) handler.applyParentUpdate(parent) else parent;
            for((arg, res) in finalResultsArr.vals()){
                for(result in res.vals()){
                    switch(result){
                        case(#ok(id)){
                            beforeVsAfterBuff.add({
                                arg = handler.toArgDomain(arg);
                                id = id; 
                                before = handler.toStruct(parent, id, #Before);
                                outcome = handler.toStruct(parentAfter, id, #After);
                                time = Time.now();
                                caller = applyArgs.caller;
                            })
                        };
                        case(#err(id, e)){
                            beforeVsAfterBuff.add({
                                arg = handler.toArgDomain(arg);
                                id = id; 
                                before = handler.toStruct(parent, id, #Before);
                                outcome = #Err(id, e);
                                time = Time.now();
                                caller = applyArgs.caller;
                            })
                        }
                    }
                }
            };
            parent := parentAfter;  
        };
        handler.updateParentEventLog(parent, Buffer.toArray(beforeVsAfterBuff));
    };

    

    public func applyUpdate<K, C, U, T, StableT>(action: Types.AtomicAction<K, C, U>, idOpt: ?K, el: StableT, handler: UnstableTypes.CrudHandler<K, C, U, T, StableT>): ?K {
        switch(idOpt, action) {
            case (_, #Create(_)) {
                handler.incrementId();
                handler.map.put(handler.assignId(handler.getId(), el));
                return ?handler.getId();
            };
            case (?id, #Update(_)) handler.map.put(id, el);
            case (?id, #Delete(_)) handler.delete(id, el);
            case(_){};
        };
        idOpt;
    };

    public func getValid<K, C, U, T, StableT>(action: Types.AtomicAction<K, C, U>, handler: CrudHandler<K, C, U, T, StableT>): (?K, Types.AtomicAction<K, C, U>, Result.Result<T, Types.UpdateError>) {
        let generateValidateElements = func (id: K, transform: T -> T): (?K, Types.AtomicAction<K, C, U>, Result.Result<T, Types.UpdateError>) {
            let maybeT = switch (handler.map.get(id)) {
                case (null) null;
                case (?el) ?transform(handler.fromStable(el));
            };
            (?id, action, handler.validate(maybeT));
        };
        
        switch(action) {
            case (#Create(arg)) (?handler.createTempId(), action, handler.validate(?handler.create(arg, handler.createTempId())));
            case (#Update(id, arg)) generateValidateElements(id,  func(el: T) = handler.mutate(arg, el));
            case (#Delete(id)) generateValidateElements(id, func(maybeT) = maybeT);
        };
    };


    public func zipResults<P, K, A, T, StableT>(validationArray : [(?K, A, Result.Result<T, Types.UpdateError>)], asyncArray: [Result.Result<(), UpdateError>], handler:UnstableTypes.Handler<P, K, A, T, StableT>) : [(A, [(?K, Result.Result<StableT, UpdateError>)])] {
      let combinedRes = func(val: Result.Result<T, Types.UpdateError>, asyn: Result.Result<(), UpdateError>): Result.Result<T, Types.UpdateError>{
        switch (val, asyn) {
          case (#err(e), _) #err(e);
          case (_, #err(e)) #err(e);
          case (#ok(el), #ok()) #ok(el);
        };
      };
      let arrayError = if (validationArray.size() != asyncArray.size()) true else false;
      let results = Buffer.Buffer<(A, [(?K,Result.Result<StableT, UpdateError>)])>(validationArray.size());
      for(i in validationArray.keys()){
            let (idOpt, arg, vres) = validationArray[i];
            if(arrayError) results.add((arg, [(idOpt, #err(#ArraySizeMisMatch))])) 
            else results.add((arg, handler.applyAsyncEffects(idOpt, combinedRes(vres, asyncArray[i]))));
      };
      /// Returns: [ per-arg group [ per-child result (key, arg, finalResult) ] ]
      return Buffer.toArray(results);
    };

    public func runNoAsync<K, A, T>(arr: [(?K, A, Result.Result<T, Types.UpdateError>)]): [(Result.Result<(), UpdateError>)] {
        let buff = Buffer.Buffer<Result.Result<(), UpdateError>>(arr.size());
        for((id, arg, res) in arr.vals()){
            switch(res){
                case(#err(e)) buff.add(#err(e));
                case(#ok(el)) buff.add((#ok()));
            };
        };
        Buffer.toArray(buff);
    };

    public func toStruct<P, K, C, U, T, StableT>(wrapStableT: ?StableT -> ToStruct<K>, toArray: P -> [(K, StableT)], equal: (K, K) -> Bool): (P, ?K, BeforeOrAfter) -> ToStruct<K> {
        func(parent: P, id: ?K, beforeOrAfter: BeforeOrAfter): ToStruct<K> {
            let array = toArray(parent);
            switch(id, beforeOrAfter){
                case(?id, #Before) wrapStableT(getElementByKey(array, id, equal));
                case(?id, _) wrapStableT(getElementByKey(array, id, equal));
                case(null, _) #Err(id, #NullId);
            }
        };
    };

    public func atomicActionToWhat<C,U>(toWhat: Types.Actions<C,U> -> What): Types.AtomicAction<Nat, C, U> -> What{
        func(arg: Types.AtomicAction<Nat, C, U>){
            switch(arg){
                case(#Create(arg)) toWhat(#Create([arg]));
                case(#Update(id: Int, arg)) toWhat(#Update(arg, [id]));
                case(#Delete(id: Int)) toWhat(#Delete([id]));
            }
        }
    };

    public func isConflictOnNatId<C,U>(): (Types.AtomicAction<Nat, C,U>, Types.AtomicAction<Nat, C,U>) -> Bool {
        func(arg1: Types.AtomicAction<Nat, C,U>, arg2: Types.AtomicAction<Nat, C,U>): Bool {
            switch(arg1, arg2){
                case(#Update(id1, _) or #Delete(id1), #Update(id2, _) or #Delete(id2)) id1 == id2;
                case(_) false;
            }
        };
    };

    type Actions<C,U> = Types.Actions<C,U>;
    type Handler<P, K, A, T, StableT> = UnstableTypes.Handler<P, K, A, T, StableT>;
    public func generateGenericHandler<P, K, C, U, T, StableT, S>(
        crudHandler: CrudHandler<K, C,U,T,StableT>, 
        toStable: T -> StableT, 
        wrapStableT: ?StableT -> ToStruct<K>, 
        toArray: P -> [(K, StableT)], 
        equal: (K, K) -> Bool, 
        isConflict: (Types.AtomicAction<K, C,U>, Types.AtomicAction<K, C,U>) -> Bool,
        applyParentUpdate: P -> P, 
        updateParentEventLog: (P, [Types.BeforeVsAfter<K>]) -> Types.UpdateResult, 
        toArgDomain: Types.AtomicAction<K, C, U> -> What
        ): Handler<P, K, Types.AtomicAction<K, C,U>, T,StableT>{
      {
        isConflict;
        validateAndPrepare = func(parent: P, arg: Types.AtomicAction<K, C, U>) = getValid<K, C, U, T, StableT>(arg, crudHandler);


        asyncEffect = func(arr: [(?K, Types.AtomicAction<K, C, U>, Result.Result<T, UpdateError>)]): async [Result.Result<(), UpdateError>] { runNoAsync<K, Types.AtomicAction<K, C,U>, T>(arr) };
        
        applyAsyncEffects = func(el: (?K, Result.Result<T, Types.UpdateError>)): [(?K, Result.Result<StableT, Types.UpdateError>)]{
          switch(el){
            case(null, _) [(null, #err(#InvalidElementId))];
            case(?id, #ok(el)) [(?id, #ok(toStable(el)))];
            case(?id, #err(e)) [(?id, #err(e))];
          }
        }; 

        applyUpdate = func(id: ?K, arg: Types.AtomicAction<K, C, U>, el: StableT): ?K =applyUpdate(arg, id, el, crudHandler);

        //#Administrative(Stables.fromPartialStableAdministrativeInfo(administrative));
        finalAsync = func(_: [(Types.AtomicAction<K, C, U>, [Result.Result<?K, (?K, UpdateError)>])]):async () {};
        toStruct = toStruct(wrapStableT, toArray, equal);
        applyParentUpdate;
        updateParentEventLog;
        toArgDomain; 
      };
    };

    public func makeDelete<T>(map: HashMap.HashMap<Nat, T>): (Nat, T) -> () {
      func(id: Nat, _el: T): () = map.delete(id);
    };

    public func makeIdVar(initial: Nat): { var value: Nat } {
      { var value = initial };
    };

    public func noConflicts<A>() : (A, A) -> Bool {
      func (_, _) = false;
    };

    

    public func makeFlatHandler<P, K, A, T, StableT>(
        mutate: (arg: A, current: P) -> T, 
        validate: T -> Result.Result<T, UpdateError>, 
        toStable: T -> StableT, 
        toStruct: P -> ToStruct<K>,
        isConflict: ?((A, A) -> Bool),
        applyParentUpdate: P -> P,
        updateParentEventLog: (P, [Types.BeforeVsAfter<K>]) -> Types.UpdateResult,
        toArgDomain: A -> What
        ) : UnstableTypes.Handler<P, K, A, T, StableT> {
    {
        isConflict = switch(isConflict){case(null) noConflicts(); case(?f)f};
        toStruct = func(parent: P, id:?K, beforeVsAfter: BeforeOrAfter): ToStruct<K> = toStruct(parent);
        validateAndPrepare = func(parent: P, arg: A): (?K,A, Result.Result<T, UpdateError>) {
          let mutated = mutate(arg, parent);
          return (null, arg, validate(mutated));
        };
    
        asyncEffect = func(arr: [(?K, A, Result.Result<T, UpdateError>)]): async [Result.Result<(), UpdateError>] {
          runNoAsync<K, A, T>(arr);
        };
    
        applyAsyncEffects = func(res: (?K, Result.Result<T, Types.UpdateError>)): [(?K, Result.Result<StableT, Types.UpdateError>)] {
          switch (res) {
            case (null, #ok(el)) [(null, #ok(toStable(el)))];
            case (_, #err(e)) [(null, #err(e))];
            case (?id, #ok(_)) [(?id, #err(#InvalidElementId))];
          };
        };
    
        applyUpdate = func(id: ?K, arg: A, el: StableT): ?K {
          id;
        };
        applyParentUpdate;
        updateParentEventLog;
        toArgDomain;
    
        finalAsync = func(_: [(A, [Result.Result<?K, (?K, UpdateError)>])]): async () {};
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



