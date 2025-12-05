//enum: KYC
import Types "../Utils/types";
import Stables "../Utils/stables";
import UnstableTypes "../Utils/unstableTypes";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Handler "../Utils/applyHandler";
import StabilityHandler "../Utils/stablecoinHandler";
import Utils "../Utils/utils";

module {
    type User = Types.User;
    type AllWhats = Types.AllWhats;
    type Arg = Types.Arg<User, AllWhats>;
    type UpdateResult = Types.UpdateResult;
    type UserUnstable = Types.UserUnstable;

    public func createKycHandler(args: Arg, arg: Bool): async UpdateResult {
        type P = User;
        type K = Principal;
        type A = Bool;
        type T = UserUnstable;
        type StableT = User;
        type S = User;
        
        let user = args.parent;

        let validateAndPrepare = func(parent: UserUnstable, arg: Bool): (?K, A, Result.Result<T, Types.UpdateError>){
            if(parent.kyc == true) return (?parent.id, arg, #err());
            parent.kyc := arg;
            return (?parent.id, arg, #ok(parent));
        };

        let handler = StabilityHandler.generateStabilityHandler<K, A, T, StableT, S>(
            validateAndPrepare,
            Handler.noAsyncEffect(),
            Handler.noApplyAsyncEffect(),
            noFinalAsync, 
            func(p: P)= p,
            toStruct //this needs doing
            null,
            func(arg: A) = #KYC(arg)
        );  
        await Handler.applyHandler<P, K, A, T, StableT>(args, [arg], handler);
    }
}