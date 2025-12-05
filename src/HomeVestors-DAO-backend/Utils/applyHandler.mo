import Types "types";
import UnstableTypes "unstableTypes";
import Buffer "mo:base/Buffer";
import Result "mo:base/Result";
import Array "mo:base/Array";
import Time "mo:base/Time";


module {
    type UpdateResult = Types.UpdateResult;
    type BeforeVsAfter<K> = Types.BeforeVsAfter<K>;
    type UpdateError = Types.UpdateError;
    type Handler<P, K, A, T, StableT> = UnstableTypes.Handler<P, K, A, T, StableT>;
    type OkUpdateResult = Types.OkUpdateResult;
    type UpdateResults = Types.UpdateResults;
    type Property = Types.Property;
    type AllWhats = Types.AllWhats;
    type Arg<P> = Types.Arg<P, AllWhats>;

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

    public func runNoAsync<K, A, T>(arr: [(?K, A, Result.Result<T, Types.UpdateError>)]): [(Result.Result<(), UpdateError>)] {
        let buff = Buffer.Buffer<Result.Result<(), UpdateError>>(arr.size());
        for((id, arg, res) in arr.vals()){
            switch(res){
                case(#err(e)) buff.add(#err(e));
                case(#ok(_)) buff.add((#ok()));
            };
        };
        Buffer.toArray(buff);
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



    public func applyHandler<P, K, A, T, StableT>(applyArgs: Arg<P>, arg: [A], handler: UnstableTypes.Handler<P, K, A, T, StableT>): async UpdateResult {
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
}