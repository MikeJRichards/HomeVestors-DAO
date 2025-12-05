import Types "types";
import UnstableTypes "unstableTypes";
import Handler "applyHandler";
import Result "mo:base/Result";

module {
    type UpdateResult = Types.UpdateResult;
    type BeforeVsAfter<K> = Types.BeforeVsAfter<K>;
    type UpdateError = Types.UpdateError;
    type Handler<P, K, A, T, StableT> = UnstableTypes.Handler<P, K, A, T, StableT>;
    type ToStruct<K> = Types.ToStruct<K>;
    type What = Types.What;
    type BeforeOrAfter = UnstableTypes.BeforeOrAfter;

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
        toArgDomain: A -> What,
        ) : UnstableTypes.Handler<P, K, A, T, StableT> {
    {
        isConflict = switch(isConflict){case(null) noConflicts(); case(?f)f};
        toStruct = func(parent: P, id:?K, beforeVsAfter: BeforeOrAfter): ToStruct<K> = toStruct(parent);
        validateAndPrepare = func(parent: P, arg: A): (?K,A, Result.Result<T, UpdateError>) {
          let mutated = mutate(arg, parent);
          return (null, arg, validate(mutated));
        };
    
        asyncEffect = func(arr: [(?K, A, Result.Result<T, UpdateError>)]): async [Result.Result<(), UpdateError>] {
          Handler.runNoAsync<K, A, T>(arr);
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
}