import Types "types";
import Nat64 "mo:base/Nat64";
import Time "mo:base/Time";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";

module {
    type Account = Types.Account;
    type AcceptedCryptos = Types.AcceptedCryptos;
    public type TransferResult = {
      #Ok : Nat;
      #Err : TransferError;
    };

    public type TransferFromResult = {
        #Ok : Nat;
        #Err : TransferFromError;
    };

    public type BaseError = {
        #Unauthorized;
      #BadFee : { expected_fee : Nat };
        #InsufficientFunds : { balance : Nat };
        #TooOld;
        #CreatedInFuture : { ledger_time : Nat64 };
        #Duplicate : { duplicate_of : Nat };
        #TemporarilyUnavailable;
        #GenericError : { error_code : Nat; message : Text };
    };

    public type TransferError = BaseError or {
      #BadBurn : { min_burn_amount : Nat };
    };

    public type TransferFromError = TransferError or {
      #InsufficientAllowance : { allowance : Nat };
    };

    public type GenericTransferArg = {
      amount : Nat;
      fee : ?Nat;
      memo : ?Blob;
      created_at_time : ?Nat64;
    };

    public type TransferArg = GenericTransferArg and {
      to : Account;
      from_subaccount : ?Blob;
    };

    public type TransferFromArgs = GenericTransferArg and {
      to : Account;
      spender_subaccount : ?Blob;
      from : Account;
    };

    public type TokenActor = actor {
      //fee and balance
      icrc1_balance_of: query (Account) -> async Nat;
      icrc1_fee: query() -> async Nat;
      icrc1_transfer: shared (TransferArg) -> async TransferResult;
      icrc2_transfer_from: shared (TransferFromArgs) -> async TransferFromResult;
    };

    func getTokenPrincipal(token: AcceptedCryptos): Text{
        switch(token){
            case(#CKUSDC) "xevnm-gaaaa-aaaar-qafnq-cai";
            case(#ICP) "ryjl3-tyaaa-aaaaa-aaaba-cai";
            case(#HGB) "xevnm-gaaaa-aaaar-qafnq-cai";
        }
    };

    public func transferFrom(token: AcceptedCryptos, amount: Nat, to: Account, from: Account): async TransferFromResult {
        let arg : TransferFromArgs = {
            spender_subaccount = null;
            from;
            to;
            amount;
            fee = null;
            memo = null;
            created_at_time = ?Nat64.fromIntWrap(Time.now());
        };
        
        let tokenActor : TokenActor = actor(getTokenPrincipal(token));
        await tokenActor.icrc2_transfer_from(arg);
    };



    public func transferFromBackend(token: AcceptedCryptos, maxAmount: Nat, to: Account, from_subaccount:?Blob): async TransferResult {
        let tokenActor : TokenActor = actor(getTokenPrincipal(token));
        let fee = await tokenActor.icrc1_fee();
        let balance = await tokenActor.icrc1_balance_of({owner = Principal.fromText("vq2za-kqaaa-aaaas-amlvq-cai"); subaccount = from_subaccount});
        let amount = Nat.min(balance - fee, maxAmount);
        let arg : TransferArg = {
            from_subaccount;
            to;
            amount;
            fee = null;
            memo = null;
            created_at_time = ?Nat64.fromIntWrap(Time.now());
        };
        
        await tokenActor.icrc1_transfer(arg);
    };

    public func transfer(token: AcceptedCryptos, from_subaccount: ?Blob, to: Account, amount: Nat): async TransferResult {
      let tokenActor : TokenActor = actor(getTokenPrincipal(token));
      let arg : TransferArg = {
        from_subaccount;
        to;
        amount;
        fee = null;
        memo = null;
        created_at_time = ?Nat64.fromIntWrap(Time.now());
      };
      await tokenActor.icrc1_transfer(arg);
    };

}