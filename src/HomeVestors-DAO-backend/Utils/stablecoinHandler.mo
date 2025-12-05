import Types "types";
import UnstableTypes "unstableTypes";
import Result "mo:base/Result";
import Handler "applyHandler";

module {
    type UpdateResult = Types.UpdateResult;
    type BeforeVsAfter<K> = Types.BeforeVsAfter<K>;
    type UpdateError = Types.UpdateError;
    type Handler<P, K, A, T, StableT> = UnstableTypes.Handler<P, K, A, T, StableT>;
    type User = Types.User;
    type ToStruct<K> = Types.ToStruct<K>;
    type What = Types.What;
    type BeforeOrAfter = UnstableTypes.BeforeOrAfter;

    
    
    public func generateStabilityHandler<K, A, T, StableT, S>(
        validateAndPrepare: (User, A) -> (?K, A, Result.Result<T, Types.UpdateError>),
        asyncEffect: [(?K, A, Result.Result<T, UpdateError>)] -> async [Result.Result<(), UpdateError>],
        applyAsyncEffects: (?K, Result.Result<T, Types.UpdateError>) -> [(?K, Result.Result<StableT, Types.UpdateError>)],
        finalAsync: [(A, [Result.Result<?K, (?K, UpdateError)>])] -> async (),
        applyParentUpdate: User -> User,
        toStruct: User -> ToStruct<K>,
        updateTransactions: User -> User,
        toArgDomain: A -> What
    ):Handler<User, K, A, T,StableT>{
        //P is User
        //T, stableT is vault, stability position, transaction
        //K i guess is Nat, the principal is already used
        {
            isConflict= func(arg1: A, arg2: A) = false;
            validateAndPrepare;
            asyncEffect;
            applyAsyncEffects;
            applyUpdate = func(idOpt: ?K, arg: A, s: StableT) = idOpt;
            finalAsync;
            applyParentUpdate;
            toStruct = func(parent: User, id:?K, beforeVsAfter: BeforeOrAfter): ToStruct<K> = toStruct(parent);
            updateParentEventLog = func(parent: User, res: [Types.BeforeVsAfter<K>]): Types.UpdateResult {
                var user = parent;
                for(result in res.vals()){
                    switch(result.outcome){
                        case(#Err(_)){};
                        case(_) user := updateTransactions(user);
                    }
                };
                return #User(user);
            };
            toArgDomain;
        }
    };

}