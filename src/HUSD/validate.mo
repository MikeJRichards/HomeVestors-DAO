import Types "types";

import Result "mo:base/Result";
import Time "mo:base/Time";
import Nat64 "mo:base/Nat64";
import Int "mo:base/Int";

module {
    func validateSubaccount(sa : ?Blob) : Bool {
        switch sa {
            case(null) true;
            case(?b) b.size() == 32;
        }
    };

    func validateFee(required : Nat, provided : ?Nat) : Bool {
        switch provided {
            case(null) true;
            case(?f) f == required;
        }
    };

    func validateMemo(m : ?Blob) : Bool {
        switch m {
            case(null) true;
            case(?b) b.size() == 32;
        }
    };

    func validateTimestamp(t : ?Nat64, now : Nat, ledger: Types.Ledger) : Result.Result<(), Types.BaseError> {
        switch t {
            case(null) #ok();
            case(?x) {
                let cx = Nat64.toNat(x);
                if(now >= cx + ledger.permitted_drift + ledger.tx_window) return #err(#TooOld);
                if(cx >= now + ledger.permitted_drift) return #err(#CreatedInFuture({ledger_time = Nat64.fromNat(now)}));  // preserves your exact logic
                #ok();
            };
        }
    };

    func validateAllowance(key : Types.AllowanceArgs, amount : Nat, ledger: Types.Ledger, now : Nat) : Result.Result<(), Types.TransferFromError> {
        let total = amount + ledger.fee;
        let allowance = ledger.allowances.get(key);
        switch(allowance.expires_at){
            case(null){};
            case(?exp) {
                if(now >= Nat64.toNat(exp)) return #err(#InsufficientAllowance({allowance = 0}));
            }
        };
        if(total >= allowance.allowance) return #err(#InsufficientAllowance({allowance = allowance.allowance}));
        return #ok();
    };

    func validateAllowanceMatches(caller: Principal, arg : Types.ApproveArgs, ledger: Types.Ledger) : Bool {
        let allowance = ledger.allowances.get({account = {owner = caller; subaccount = arg.from_subaccount}; spender = arg.spender});

        switch(arg.expected_allowance){
            case(null) true;
            case(?exp) {
                exp == allowance.allowance;
            }
        }
    };

    func validateExpiresAt(now: Nat, expires_at: ?Nat64): Bool {
        switch(expires_at){
            case(null) true;
            case(?x) Nat64.toNat(x) > now;
        }
    };

    func commonValidationChecks(ledger: Types.Ledger, fee: ?Nat, memo: ?Blob, created_at_time: ?Nat64): Result.Result<(),Types.BaseError>{
        if(not validateFee(ledger.fee, fee)) return #err(#BadFee({expected_fee = ledger.fee}));
        if(not validateMemo(memo)) return #err(#GenericError({error_code = 500; message = "Memo is too long"}));
        validateTimestamp(created_at_time, Int.abs(Time.now()), ledger)
    };

    func commonTransferValidationChecks(ledger: Types.Ledger, to: Types.Account, from: Types.Account, amount: Nat): Result.Result<(),Types.TransferError>{
        if (to == from) return #err(#GenericError({error_code = 600; message = "to and from may not be the same"}));
        if (not validateSubaccount(to.subaccount)) return #err(#GenericError({error_code = 700; message = "subaccounts must be exactly 32 bytes long"}));
        if(to == ledger.mintingAccount and ledger.fee > amount) return #err(#BadBurn({min_burn_amount = ledger.fee}));
        if (amount + ledger.fee > ledger.balances.get(from)) return #err(#InsufficientFunds({balance = ledger.balances.get(from)}));
        #ok();
    };

    public func validateTransfer(caller: Principal, arg: Types.TransferArgs, ledger: Types.Ledger): Result.Result<(),Types.TransferError>{
        switch(commonValidationChecks(ledger, arg.fee, arg.memo, arg.created_at_time)){case(#ok()){}; case(#err(e)) return #err(e)};
        commonTransferValidationChecks(ledger, arg.to, {owner = caller; subaccount = arg.from_subaccount}, arg.amount);
    };

    public func validateApproval(caller: Principal, arg: Types.ApproveArgs, ledger: Types.Ledger): Result.Result<(), Types.ApproveError>{
        if(not validateAllowanceMatches(caller, arg, ledger)) return #err(#AllowanceChanged({current_allowance = ledger.allowances.get({account = {owner = caller; subaccount = arg.from_subaccount}; spender = arg.spender}).allowance}));
        if(not validateExpiresAt(Int.abs(Time.now()), arg.expires_at)) return #err(#Expired({ledger_time = Nat64.fromNat(Int.abs(Time.now()))}));
        let balance = ledger.balances.get({owner = caller; subaccount = arg.from_subaccount});
        if(ledger.fee > balance) return #err(#InsufficientFunds{balance = balance});
        commonValidationChecks(ledger, arg.fee, arg.memo, arg.created_at_time);
    };

    public func validateTransferFrom(caller: Principal, arg: Types.TransferFromArgs, ledger: Types.Ledger): Result.Result<(), Types.TransferFromError>{
        let key = {account = arg.from; spender = { owner = caller; subaccount = arg.spender_subaccount}};
        switch(validateAllowance(key, arg.amount, ledger, Int.abs(Time.now()))){case(#err(e)) return #err(e); case(#ok()){}};
        switch(commonValidationChecks(ledger, arg.fee, arg.memo, arg.created_at_time)){case(#ok()){}; case(#err(e)) return #err(e)};
        commonTransferValidationChecks(ledger, arg.to, arg.from, arg.amount);
    };

}