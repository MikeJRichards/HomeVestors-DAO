import Types "./types";
import Validator "./validate";
import ICRC3 "./icrc3";
import Principal "mo:base/Principal";
import Blob "mo:base/Blob";
import Nat64 "mo:base/Nat64";

import CertTree "mo:ic-certification/CertTree";
persistent actor {
//icrc1 service : {
//    icrc1_metadata : () -> (vec record { text; Value; }) query;
//    icrc1_name : () -> (text) query;
//    icrc1_symbol : () -> (text) query;
//    icrc1_decimals : () -> (nat8) query;
//    icrc1_fee : () -> (nat) query;
//    icrc1_total_supply : () -> (nat) query;
//    icrc1_minting_account : () -> (opt Account) query;
//    icrc1_balance_of : (Account) -> (nat) query;
//    icrc1_transfer : (TransferArgs) -> (variant { Ok : nat; Err : TransferError });
//    icrc1_supported_standards : () -> (vec record { name : text; url : text }) query;
//}
//user balance divide by 100000000 - frontend only

//rules summarised: 
//subaccount length 32 bytes
//memo size not above max size
//created at time valid
//transaction deduplication 
//fee valid

//transfers:
//transfers to minting account = burn no fee decrease supply - can enforce minimum burn amount, from minting account minting increase supply
//person making transfer pays fee (on top of amount transferred)
//incorrect fee - doesn't match protocol but is supplied = bad fee
//memo argument used for transfer deduplication
//memo should be allowed to be atleast 32 bytes in length

//created at time - is nanoseconds is unix epoch UTC, if created_at_time is set before time() - TX Window - Permitted drift = Too Old
//if created at time is greater than time() + permitted drift == Created In Future
//If the ledger observed a structurally equal transfer payload (i.e., all the transfer argument fields and the caller have the same values) at transaction with index i, it should return variant { Duplicate = record { duplicate_of = i } }.
//if no created at time shouldn't use transaction deduplication
//result transaction index or error

//icrc1 supported standards record { name = "ICRC-1"; url = "https://github.com/dfinity/ICRC-1" }

//metadata key: Value
//icrc1:symbol - #Text("")
//icrc1:name - #Text("")
//icrc1:decimals - #Nat(8)
//icrc1:fee #Nat(10000)
//icrc1:logo #Text("") - url of image - data url



//icrc2 service : {
//    icrc1_supported_standards : () -> (vec record { name : text; url : text }) query;
//
//    icrc2_approve : (ApproveArgs) -> (variant { Ok : nat; Err : ApproveError });
//    icrc2_transfer_from : (TransferFromArgs) -> (variant { Ok : nat; Err : TransferFromError });
//    icrc2_allowance : (AllowanceArgs) -> (record { allowance : nat; expires_at : opt nat64 }) query;
//}

//approvals:
//don't get reset to zero upon a transfer from - just deduct it
//approvals don't require the balance they just require the fee
//expires at in future
//if expected allowance set - must equal current allowance

//transfer from:
//takes fees from the from account
//spender allowance must be greater than amount + fees
//deduct fees + amount from from, credit amount to to

//icrc3 service : {
//  icrc3_get_archives : (GetArchivesArgs) -> (GetArchivesResult) query;
//  icrc3_get_tip_certificate : () -> (opt DataCertificate) query;
//  icrc3_get_blocks : (GetBlocksArgs) -> (GetBlocksResult) query;
//  icrc3_supported_block_types : () -> (vec record { block_type : text; url : text }) query;
//};


    type Account = Types.Account;
    var ledgerState : Types.LedgerState = {
        blocks = [];
        balances = [];
        allowances = [];
        metadata = [
            ("icrc1:symbol", #Text("HUSD")), 
            ("icrc1:name", #Text("HomeVestors DAO USD")),
            ("icrc1:decimals", #Nat(8)),
            ("icrc1:fee", #Nat(10000)),
            ("icrc1:logo", #Text(""))
        ];
        totalSupply = 0;
        mintingAccount = { owner = Principal.fromText("vq2za-kqaaa-aaaas-amlvq-cai"); subaccount = null };
        fee = 0;
        txIndex = 0;
        symbol = "HUSD";
        name = "HomeVestors DAO USD";
        decimals = 8;
        tx_window = 86_400_000_000_000; //1 day
        permitted_drift = 300_000_000_000; //5 mins
        cert = CertTree.newStore();
        phash = Blob.fromArray([]);
    };
    transient var ledger = Types.Ledger(ledgerState);
    
    public query func icrc1_metadata(): async [(Text, Types.Value)]{
        ledger.metadata.toArray();
    };

    public func icrc1_name(): async Text {
        ledger.name
    };

    public query func icrc1_symbol(): async Text {
        ledger.symbol;
    };

    public query func icrc1_decimals(): async Nat8 {
        ledger.decimals;
    };

    public query func icrc1_fee(): async Nat {
        ledger.fee;
    };

    public query func icrc1_total_supply(): async Nat {
        ledger.totalSupply
    };

    
    public query func icrc1_minting_account(): async ?Types.Account {
        ?ledger.mintingAccount
    };

    public query func icrc1_balance_of(acc: Account): async Nat {
        ledger.balances.get(acc);
    };

    public shared ({caller}) func icrc1_transfer(arg: Types.TransferArgs): async Types.TransferResult {
        switch(Validator.validateTransfer(caller, arg, ledger)){case(#err(e)) return #Err(e); case(#ok()){}};
        //deduplication
        let op = ledger.transfer({owner = caller; subaccount = arg.from_subaccount}, arg.to, arg.amount, "transfer");
        ICRC3.createTransferTx(caller, op, arg, ledger);
        return #Ok(ledger.txIndex)
    };

    public query func icrc1_supported_standards(): async [{name: Text; url: Text}]{
        [
            {name = "ICRC-1"; url = "https://github.com/dfinity/ICRC-1" }
        ];
    };

    public shared ({caller}) func icrc2_approve(arg: Types.ApproveArgs): async Types.ApproveResult {
        switch(Validator.validateApproval(caller, arg, ledger)){case(#err(e)) return #Err(e); case(#ok()){}};

        //deduplication
        ledger.allowances.put({account = {owner = caller; subaccount = arg.from_subaccount}; spender = arg.spender}, {allowance = arg.amount; expires_at = arg.expires_at});
        ICRC3.createApproveTx(caller, "approve", arg, ledger);

        #Ok(ledger.txIndex);
    };

    public shared ({caller}) func icrc2_transfer_from(arg: Types.TransferFromArgs): async Types.TransferFromResult {
        switch(Validator.validateTransferFrom(caller, arg, ledger)){case(#err(e)) return #Err(e); case(#ok()){}};
        //deduplication
        let op = ledger.transfer(arg.from, arg.to, arg.amount, "transfer_from");
        ICRC3.createTransferFromTx(caller, op, arg, ledger);
        #Ok(ledger.txIndex)
    };

    public query func icrc2_allowance(arg: Types.AllowanceArgs): async {allowance: Nat; expires_at: ?Nat64}{
        ledger.allowances.get(arg)
    };

    public query func icrc3_get_archives(arg: Types.GetArchivesArgs): async Types.GetArchivesResult {
        []
    };

    public query func icrc3_get_tip_certificate(): async ?Types.DataCertificate {
        ICRC3.icrc3_get_tip_certificate(ledger.cert);
    };

    
    public query func icrc3_get_blocks(args: Types.GetBlocksArgs): async Types.GetBlocksResult {
        {
            log_length = ledger.blocks.size();
            blocks = ICRC3.getBlocks(ledger, args);
            archived_blocks = []
        }
    };

    public query func icrc3_supported_block_types():async [{block_type: Text; url: Text}]{
         [
            { block_type = "icrc1.transfer";        url = "https://github.com/dfinity/ICRC-1" },
            { block_type = "icrc2.approve";         url = "https://github.com/dfinity/ICRC-2" },
            { block_type = "icrc2.transfer_from";   url = "https://github.com/dfinity/ICRC-2" }
        ];
    };

    system func preupgrade() {
        ledgerState := ledger.stateSnapshot();
    };

    system func postupgrade() {
        ledger := Types.Ledger(ledgerState);
    }


}