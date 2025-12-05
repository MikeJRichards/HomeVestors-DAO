import Map "mo:core/Map";
import Nat "mo:core/Nat";
import Iter "mo:core/Iter";
import Types "./types";
import Principal "mo:core/Principal";
import Result "mo:base/Result";
import List "mo:core/List";
import Time "mo:core/Time";
import Blob "mo:core/Blob";

persistent actor class PropertyDAO(
    initial_nft_collection : Principal,
    initial_dictionary : Principal,
    initial_state : Types.DAOState
){
    type DAOState = Types.DAOState;
    type NFTTransferFromArg = Types.NFTTransferFromArg;
    type NFTTransferArg = Types.NFTTransferArg;
    type Account = Types.Account;
    type NFTTransferFromResult = Types.NFTTransferFromResult;
    type NFTTransferResult = Types.NFTTransferResult;
    type ProposalArg = Types.ProposalArg;
    type VoteArgs = Types.VoteArgs;
    type ActionDictionary = Types.ActionDictionary;
    
    let nftCollection : Principal = initial_nft_collection;
    var actionDictionaryPrincipal : Principal = initial_dictionary;
    var daoState = initial_state;

    public shared ({caller}) func transferNFT(arg: [NFTTransferArg]): async [?NFTTransferResult] {
        if(Principal.notEqual(caller, actionDictionaryPrincipal)) return [?#Err(#Unauthorized)];
        let nftActor : Types.NFTActor = actor(Principal.toText(nftCollection));
        await nftActor.icrc7_transfer(arg);
    };

    public shared ({caller}) func approveNFTTransfer(arg: [Types.NFTApproveTokenArg]): async [?Types.NFTApproveTokenResult] {
        if(Principal.notEqual(caller, actionDictionaryPrincipal)) return [?#Err(#Unauthorized)];
        let nftActor : Types.NFTActor = actor(Principal.toText(nftCollection));
        await nftActor.icrc37_approve_tokens(arg);
    };

    public shared ({caller}) func transferTokens(arg: Types.TokenTransferArg, tokenPrincipal: Principal): async Types.TokenTransferResult {
        if(Principal.notEqual(caller, actionDictionaryPrincipal)) return #Err(#Unauthorized);
        let tokenActor : Types.TokenActor = actor(Principal.toText(tokenPrincipal));
        await tokenActor.icrc1_transfer(arg);
    };

    public shared ({caller}) func approveTokenTransfer(arg: Types.TokenApproveArgs, tokenPrincipal: Principal): async Types.DAOTokenApproveResult {
        if(Principal.notEqual(caller, actionDictionaryPrincipal)) return #Err(#Unauthorized);
        let tokenActor : Types.TokenActor = actor(Principal.toText(tokenPrincipal));
        await tokenActor.icrc2_approve(arg);
    };

    public shared ({caller}) func updateActionDictionary(newActionDictionary: Principal): async Result.Result<(),()> {
        if(Principal.notEqual(caller, actionDictionaryPrincipal)) return #err();
        actionDictionaryPrincipal := newActionDictionary;
        return #ok();
    };

    public shared ({caller}) func createProposal(arg: ProposalArg): async Result.Result<(), ()> {
        let actionDictionary : ActionDictionary = actor(Principal.toText(actionDictionaryPrincipal));
        switch(await actionDictionary.createProposal(daoState,arg, caller, nftCollection)){
            case(#ok(updatedState)){
                daoState := updatedState;
                #ok();
            };
            case(#err()) return #err();
        }
    };

    public shared ({caller}) func executeVote(arg: VoteArgs): async Result.Result<(), ()> {
        let actionDictionary : ActionDictionary = actor(Principal.toText(actionDictionaryPrincipal));
        switch(await actionDictionary.executeVote(daoState, arg, caller, nftCollection)){
            case(#ok(updatedState)){
                daoState := updatedState;
                #ok();
            };
            case(#err()) return #err();
        }
    };

    public shared ({caller}) func executeProposal(proposalId: Nat): async Result.Result<(), ()> {
        let actionDictionary : ActionDictionary = actor(Principal.toText(actionDictionaryPrincipal));
        switch(await actionDictionary.executeProposal(daoState, proposalId)){
            case(#ok(updatedState)){
                daoState := updatedState;
                #ok();
            };
            case(#err()) return #err();
        }
    };

    public query func getDAOState() : async DAOState {daoState};
    public query func getGovernance() : async Blob {daoState.gov};
    public query func getProperty() : async Blob {daoState.property};
    public query func getActionDictionary() : async Principal {actionDictionaryPrincipal};
    public query func getNFTCollection() : async Principal {nftCollection};



    




}