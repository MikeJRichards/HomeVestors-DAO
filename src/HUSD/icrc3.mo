import Types "./types";
import Text "mo:base/Text";
import Principal "mo:base/Principal";
import Nat64 "mo:base/Nat64";
import Time "mo:base/Time";
import Int "mo:base/Int";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";
import Array "mo:core/Array";

import Sha256 "mo:sha2/Sha256";
import NatX "mo:xtended-numbers/NatX";
import IntX "mo:xtended-numbers/IntX";
import CertTree "mo:ic-certification/CertTree";
import CertifiedData "mo:base/CertifiedData";
import MerkleTree "mo:ic-certification/MerkleTree";

module {
    type Tx = {
        tid: Nat;
        op: ?Text;
        to: ?Types.Account;
        from: Types.Account;
        spender: ?Types.Account;
        amount: Nat;
        fee: ?Nat;
        created_at_time: ?Nat64;
        memo: ?Blob;
        expected_allowance: ?Nat;
        expires_at: ?Nat64;
    };


    func accountToValue(acc: Types.Account): Types.Value {
        return #Array([
            #Blob(Principal.toBlob(acc.owner)),
            switch (acc.subaccount) {
                case (?sub) #Blob(sub);
                case null #Blob(Blob.fromArray([])); // empty subaccount = default
            }
        ]);
    };

    public func createTransferTx(caller: Principal, op: Text, arg: Types.TransferArgs, ledger: Types.Ledger): () {
        let tx = {
            tid = ledger.txIndex; 
            op = ?op;
            from = {owner = caller; subaccount = arg.from_subaccount};
            to = ?arg.to;
            spender = null;
            amount = arg.amount;
            fee = arg.fee;
            memo = arg.memo;
            created_at_time = arg.created_at_time;
            expected_allowance = null;
            expires_at = null;
        };
        blockToValue(ledger, op, tx);
    };

    public func createTransferFromTx(caller: Principal, op: Text, arg: Types.TransferFromArgs, ledger: Types.Ledger): () {
        let tx = {
            tid = ledger.txIndex; 
            op = ?op;
            from = arg.from;
            to = ?arg.to;
            spender = ?{owner = caller; subaccount = arg.spender_subaccount};
            amount = arg.amount;
            fee = arg.fee;
            memo = arg.memo;
            created_at_time = arg.created_at_time;
            expected_allowance = null;
            expires_at = null;
        };
        blockToValue(ledger, op, tx);
    };

    public func createApproveTx(caller: Principal, op: Text, arg: Types.ApproveArgs, ledger: Types.Ledger): () {
        let tx = {
            tid = ledger.txIndex; 
            op = ?op;
            from = {owner = caller; subaccount = arg.from_subaccount};
            to = null;
            spender = ?arg.spender;
            amount = arg.amount;
            expected_allowance = arg.expected_allowance;
            expires_at = arg.expires_at;
            fee = arg.fee;
            memo = arg.memo;
            created_at_time = arg.created_at_time;
        };
        blockToValue(ledger, op, tx);
    };

    func txToValue(tx: Tx): Types.Value {
        var fields = Types.createMapHandler<Text, Types.Value>(Text.compare, []);
        fields.put("tid", #Nat(tx.tid));
        fields.put("from", accountToValue(tx.from));
        switch(tx.to){case(?to) fields.put("to", accountToValue(to)); case(null){}};
        switch(tx.spender){case(?spender) fields.put("spender", accountToValue(spender)); case(null){}};
        fields.put("amount", #Nat(tx.amount));
        switch(tx.expected_allowance){case(?allowance) fields.put("expected_allowance", #Nat(allowance)); case(null){}};
        switch(tx.expires_at){case(?expires_at) fields.put("expires_at", #Nat(Nat64.toNat(expires_at))); case(null){}};
        switch(tx.fee){case(?fee) fields.put("fee", #Nat(fee)); case(null){}};
        switch (tx.memo){ case (?memo) fields.put("memo", #Blob(memo)); case(null) {}};
        switch(tx.created_at_time){case(?created_at_time) fields.put("created_at_time", #Nat(Nat64.toNat(created_at_time))); case(null){}};
        fields.put("ts", #Nat(Int.abs(Time.now())));
        return #Map(fields.toArray());
    };

    public func blockToValue(ledger: Types.Ledger, op: Text, tx: Tx): () {
        let value = #Map([
          ("phash", #Blob(ledger.phash)),
          ("btype", #Text(op)),
          ("ts", #Nat(Int.abs(Time.now()))),
          ("tx", txToValue(tx))
        ]);
        ledger.txIndex += 1;
        let blockHash = hashValue(value);
        certifyTip(ledger.txIndex, blockHash, ledger);
        ledger.phash := blockHash;
        ledger.blocks.add({id = ledger.txIndex; block = value});
    };

    public func hashValue(value: Types.Value): Blob {
        switch (value) {
          case (#Nat(n)) {
            let buf = Buffer.Buffer<Nat8>(10);
            NatX.encodeNat(buf, n, #unsignedLEB128);
            Sha256.fromArray(#sha256, Iter.toArray(buf.vals()));
          };

          case (#Int(i)) {
            let buf = Buffer.Buffer<Nat8>(10);
            IntX.encodeInt(buf, i, #signedLEB128);
            Sha256.fromArray(#sha256, Iter.toArray(buf.vals()));
          };

          case (#Text(t)) {
            Sha256.fromBlob(#sha256, Text.encodeUtf8(t));
          };

          case (#Blob(b)) {
            Sha256.fromBlob(#sha256, b);
          };

          case (#Array(arr)) {
            var combined = Types.createListHandler<Nat8>([]);
            for (element in arr.vals()) {
              let hashed = hashValue(element);
              for(byte in hashed.vals()){
                combined.add(byte);
              }
            };
            Sha256.fromBlob(#sha256, Blob.fromArray(combined.toArray()));
          };

          case (#Map(entries)) {
            var kvHashes = Types.createListHandler<[Nat8]>([]);

            for ((key, val) in entries.vals()) {
              let keyHash = Sha256.fromBlob(#sha256, Text.encodeUtf8(key));
              let valHash = hashValue(val);
              kvHashes.add(Array.concat<Nat8>(Blob.toArray(keyHash), Blob.toArray(valHash)));
            };
            let allBytes : [Nat8] = Array.flatten<Nat8>(kvHashes.toArray());
            Sha256.fromBlob(#sha256, Blob.fromArray(allBytes));

          };
        };
    };

    func leb128(n: Nat): Blob {
        let buf = Buffer.Buffer<Nat8>(10);
        NatX.encodeNat(buf, n, #unsignedLEB128);
        Blob.fromArray(Iter.toArray(buf.vals()));
    };

    public func certifyTip(blockIndex: Nat, blockHash: Blob, ledger: Types.Ledger) {
        let cert = CertTree.Ops(ledger.cert);
        cert.put([Text.encodeUtf8("last_block_index")], leb128(blockIndex));
        cert.put([Text.encodeUtf8("last_block_hash")], blockHash);
    
        let root = cert.treeHash();
    
        CertifiedData.set(root);
    };
  
    public func icrc3_get_tip_certificate(store: CertTree.Store): ?Types.DataCertificate {
      switch (CertifiedData.getCertificate()) {
        case null null;
        case (?cert) {
            let ops = CertTree.Ops(store);
            let witness = ops.reveals([
                [Text.encodeUtf8("last_block_index")],
                [Text.encodeUtf8("last_block_hash")]
            ].vals()); // `vals()` makes it iterable
          let encodedTree = MerkleTree.encodeWitness(witness);
    
          ?{
            certificate = cert;
            hash_tree = encodedTree;
          }
        }
      }
    };

    public func getBlocks(ledger: Types.Ledger, args: Types.GetBlocksArgs): [Types.Blocks]{
        let blocks = Types.createListHandler<Types.Blocks>([]);
        for(arg in args.vals()){
            if(arg.start > ledger.blocks.size()) return [];
            let end = arg.start + arg.length;
            for(block in ledger.blocks.entries()){
                if(block.id > arg.start or block.id < end) blocks.add(block);
            };
        };
        blocks.toArray();
    };





};