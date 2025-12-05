import Types "types";
import UnstableTypes "unstableTypes";
import Result "mo:base/Result";
import Handler "applyHandler";
import Buffer "mo:base/Buffer";
import Int "mo:base/Int";
import Utils "utils";



module {
    type UpdateResult = Types.UpdateResult;
    type BeforeVsAfter<K> = Types.BeforeVsAfter<K>;
    type UpdateError = Types.UpdateError;
    type Handler<P, K, A, T, StableT> = UnstableTypes.Handler<P, K, A, T, StableT>;
    type CrudHandler<K, C,U,T,StableT> = UnstableTypes.CrudHandler<K, C,U,T,StableT>;
    type ToStruct<K> = Types.ToStruct<K>;
    type What = Types.What;
    type BeforeOrAfter = UnstableTypes.BeforeOrAfter;
    type Actions<C,U> = Types.Actions<C,U>;
    type Intent<T> = Types.Intent<T>;

    public func updateId<T>(action: Intent<T>, currentId: Nat): Nat{
        switch(action){
            case(#Create(_)) return currentId + 1;
            case(_) return currentId;
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

    public func toStruct<P, K, C, U, T, StableT>(wrapStableT: ?StableT -> ToStruct<K>, toArray: P -> [(K, StableT)], equal: (K, K) -> Bool): (P, ?K, BeforeOrAfter) -> ToStruct<K> {
        func(parent: P, id: ?K, beforeOrAfter: BeforeOrAfter): ToStruct<K> {
            let array = toArray(parent);
            switch(id, beforeOrAfter){
                case(?id, #Before) wrapStableT(Utils.getElementByKey(array, id, equal));
                case(?id, _) wrapStableT(Utils.getElementByKey(array, id, equal));
                case(null, _) #Err(id, #NullId);
            }
        };
    };

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


        asyncEffect = func(arr: [(?K, Types.AtomicAction<K, C, U>, Result.Result<T, UpdateError>)]): async [Result.Result<(), UpdateError>] { Handler.runNoAsync<K, Types.AtomicAction<K, C,U>, T>(arr) };
        
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
}