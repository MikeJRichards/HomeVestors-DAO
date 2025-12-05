import Nat "mo:core/Nat";
import Types "./types";
import PropertyTypes "./propertyTypes";
import Principal "mo:core/Principal";
import Result "mo:base/Result";
import Array "mo:core/Array";
import Time "mo:core/Time";
import Sha256 "mo:sha2/Sha256";
import Blob "mo:core/Blob";

persistent actor {
    type Governance = Types.Governance;
    type Proposal = Types.Proposal;
    type ProposalStatus = Types.ProposalStatus;
    type ProposalArg = Types.ProposalArg;
    type VoteArgs = Types.VoteArgs;
    type CountVotes = Types.CountVotes;
    type DAOState = Types.DAOState;

    let husdPrincipal = Principal.fromText("vq2za-kqaaa-aaaas-amlvq-cai");

    func proposalActionToFlag(action: Types.ProposalAction): Types.ProposalActionFlag {
        switch(action){
            case(#Property(#Insurance(#Create(_))))             #Property(#Insurance(#Create));
            case(#Property(#Insurance(#Update(_))))             #Property(#Insurance(#Update));
            case(#Property(#Insurance(#Delete(_))))             #Property(#Insurance(#Delete));
            case(#Property(#Document(#Create(_))))              #Property(#Document(#Create));
            case(#Property(#Document(#Update(_))))              #Property(#Document(#Update));
            case(#Property(#Document(#Delete(_))))              #Property(#Document(#Delete));
            case(#Property(#Note(#Create(_))))                  #Property(#Note(#Create));
            case(#Property(#Note(#Update(_))))                  #Property(#Note(#Update));
            case(#Property(#Note(#Delete(_))))                  #Property(#Note(#Delete));
            case(#Property(#Maintenance(#Create(_))))           #Property(#Maintenance(#Create));
            case(#Property(#Maintenance(#Update(_))))           #Property(#Maintenance(#Update));
            case(#Property(#Maintenance(#Delete(_))))           #Property(#Maintenance(#Delete));
            case(#Property(#Inspection(#Create(_))))            #Property(#Inspection(#Create));
            case(#Property(#Inspection(#Update(_))))            #Property(#Inspection(#Update));
            case(#Property(#Inspection(#Delete(_))))            #Property(#Inspection(#Delete));
            case(#Property(#Tenant(#Create(_))))                #Property(#Tenant(#Create));
            case(#Property(#Tenant(#Update(_))))                #Property(#Tenant(#Update));
            case(#Property(#Tenant(#Delete(_))))                #Property(#Tenant(#Delete));
            case(#Property(#Valuations(#Create(_))))            #Property(#Valuations(#Create));
            case(#Property(#Valuations(#Update(_))))            #Property(#Valuations(#Update));
            case(#Property(#Valuations(#Delete(_))))            #Property(#Valuations(#Delete));
            case(#Property(#Financials(_)))                     #Property(#Financials);
            case(#Property(#MonthlyRent(_)))                    #Property(#MonthlyRent);
            case(#Property(#PhysicalDetails(_)))                #Property(#PhysicalDetails);
            case(#Property(#AdditionalDetails(_)))              #Property(#AdditionalDetails);
            case(#Property(#Description(_)))                    #Property(#Description);
            case(#Property(#Images(#Create(_))))                #Property(#Images(#Create));
            case(#Property(#Images(#Update(_))))                #Property(#Images(#Update));
            case(#Property(#Images(#Delete(_))))                #Property(#Images(#Delete));
            case(#Property(#Invoice(#Create(_))))               #Property(#Invoice(#Create));
            case(#Property(#Invoice(#Update(_))))               #Property(#Invoice(#Update));
            case(#Property(#Invoice(#Delete(_))))               #Property(#Invoice(#Delete));
            case(#DAO(#TransferToken(_)))                       #DAO(#TransferToken);
            case(#DAO(#ApproveTransferFromToken(_)))            #DAO(#ApproveTransferFromToken);
            case(#DAO(#TransferNFT(_)))                         #DAO(#TransferNFT);
            case(#DAO(#ApproveTransferFromNFT(_)))              #DAO(#ApproveTransferFromNFT);
            case(#DAO(#ChangeActionDictionary(_)))              #DAO(#ChangeActionDictionary);
            case(#Governance(#WhitelistPropertyAction(_)))      #Governance(#WhitelistPropertyAction);
            case(#Governance(#RequiresTenantApproval(_)))       #Governance(#RequiresTenantApproval)
        }
    };
    
    func whitelistApproved(gov: Governance, action: Types.ProposalAction): Bool {
        let actionFlag = proposalActionToFlag(action);
        Array.any<Types.ProposalActionFlag>(gov.whitelisted, func x = x == actionFlag);
    };

    func executeAction(state: DAOState, action: Types.ProposalAction, dao: Principal, proposalId: ?Nat): async Result.Result<DAOState, ()> {
        let propertyDAO: Types.PropertyDAO = actor(Principal.toText(dao));
        let propertyModule: Types.PropertyModule = actor("");
        let propertyOpt : ?PropertyTypes.Property = from_candid(state.property);
        var property = switch(propertyOpt){case(?property)property; case(null)return #err()};
        let governanceOpt : ?Governance = from_candid(state.gov);
        var governance = switch(governanceOpt){case(?gov)gov; case(null) return #err()};
        let result = switch(action){
            case(#Property(action)){
                switch(await propertyModule.updateProperty(property, action)){
                    case(#ok(result, prop)){
                        property := prop;
                        #Property(result); 
                    };
                    case(#err(e)) #Property(e);
                }
            };
            case(#DAO(#TransferToken(arg))) #TransferToken(await propertyDAO.transferTokens(arg, husdPrincipal));
            case(#DAO(#ApproveTransferFromToken(arg))) #ApproveToken(await propertyDAO.approveTokenTransfer(arg, husdPrincipal));
            case(#DAO(#TransferNFT(arg))) #TransferNFT(await propertyDAO.transferNFT(arg));
            case(#DAO(#ApproveTransferFromNFT(arg))) #ApproveNFTTransfer(await propertyDAO.approveNFTTransfer(arg));
            case(#DAO(#ChangeActionDictionary(arg))) #ChangeActionDictionary(await propertyDAO.updateActionDictionary(arg));
            case(#Governance(#WhitelistPropertyAction(#Add(arg)))){
                let (updatedGov, res) = addActionFlagToWhitelist(arg, governance);
                governance := updatedGov;
                #Governance(res);
            };
            case(#Governance(#WhitelistPropertyAction(#Remove(arg)))){
                let (updatedGov, res) = removeActionFlagFromWhitelist(arg, governance);
                governance := updatedGov;
                #Governance(res);
            };
            case(#Governance(#RequiresTenantApproval(#Add(arg)))){
                let (updatedGov, res) = addActionFlagToRequiresTenantApproval(arg, governance);
                governance := updatedGov;
                #Governance(res);
            };
            case(#Governance(#RequiresTenantApproval(#Remove(arg)))){
                let (updatedGov, res) = removeActionFlagFromRequiresTenantApproval(arg, governance);
                governance := updatedGov;
                #Governance(res);
            };
        };
        let outcome : Types.ExecutionOutcomes = {
            arg = action;
            result;
            proposalId;
        };
        let outcomes = Types.createMapHandler<Nat, Types.ExecutionOutcomes>(Nat.compare, governance.executionOutcomes);
        outcomes.put(governance.nextExecutionOutcomeId, outcome);
        let updatedState = {
            property = to_candid(property);
            gov = to_candid({
                governance with
                nextExecutionOutcomeId = governance.nextExecutionOutcomeId + 1;
                executionOutcomes = outcomes.toArray();
            })
        };
        #ok(updatedState);
    };

    func addActionFlagToWhitelist(flags: [Types.ProposalActionFlag], gov: Governance): (Governance, Types.GovernanceResults) {
        let whitelist = Types.createListHandler<Types.ProposalActionFlag>(gov.whitelisted);
        let sizeBefore = whitelist.size();
        for(flag in flags.vals()){
            switch(whitelist.find(func(x) = x == flag)){
                case(null) whitelist.add(flag);
                case(_){};
            }
        };
        let result = #Whitelist({
            sizeBefore;
            sizeAfter = whitelist.size();
            argSize = flags.size();
        });
        ({gov with whitelisted = whitelist.toArray()}, result)
    };

    func removeActionFlagFromWhitelist(flags: [Types.ProposalActionFlag], gov: Governance): (Governance, Types.GovernanceResults) {
        var whitelist = Types.createListHandler<Types.ProposalActionFlag>(gov.whitelisted);
        let sizeBefore = whitelist.size();
        for(flag in flags.vals()) whitelist := whitelist.filter(flag, func(x) = x == flag);
        let result = #Whitelist({
            sizeBefore;
            sizeAfter = whitelist.size();
            argSize = flags.size();
        });
        ({gov with whitelisted = whitelist.toArray()}, result)
    };

     func addActionFlagToRequiresTenantApproval(flags: [Types.ProposalActionFlag], gov: Governance): (Governance, Types.GovernanceResults) {
        let requiresTenantApproval = Types.createListHandler<Types.ProposalActionFlag>(gov.requiresTenantApproval);
        let sizeBefore = requiresTenantApproval.size();
        for(flag in flags.vals()){
            switch(requiresTenantApproval.find(func(x) = x == flag)){
                case(null) requiresTenantApproval.add(flag);
                case(_){};
            }
        };
        let result = #RequiresTenantApproval({
            sizeBefore;
            sizeAfter = requiresTenantApproval.size();
            argSize = flags.size();
        });
        ({gov with requiresTenantApproval = requiresTenantApproval.toArray()}, result)
    };

    func removeActionFlagFromRequiresTenantApproval(flags: [Types.ProposalActionFlag], gov: Governance): (Governance, Types.GovernanceResults) {
        var requiresTenantApproval = Types.createListHandler<Types.ProposalActionFlag>(gov.requiresTenantApproval);
        let sizeBefore = requiresTenantApproval.size();
        for(flag in flags.vals()) requiresTenantApproval := requiresTenantApproval.filter(flag, func(x) = x == flag);
        let result = #RequiresTenantApproval({
            sizeBefore;
            sizeAfter = requiresTenantApproval.size();
            argSize = flags.size();
        });
        ({gov with requiresTenantApproval = requiresTenantApproval.toArray()}, result)
    };
    
    func isTenant(state: DAOState, caller: Principal): Bool {
        let propertyOpt : ?PropertyTypes.Property = from_candid(state.property);
        let property = switch(propertyOpt){case(null) return false; case(?prop)prop};
        let tenants = Types.createMapHandler<Nat, PropertyTypes.Tenant>(Nat.compare, property.operational.tenants);
        switch(tenants.get(property.operational.tenantId)){
            case(?tenant){
                switch(tenant.principal){
                    case(null) false;
                    case(?principal) principal == caller;
                };
            };
            case(null) false
        }
    };

    func doesRequireTenantApproval(flag: Types.ProposalActionFlag, gov: Governance): Bool {
        var requiresTenantApproval = Types.createListHandler<Types.ProposalActionFlag>(gov.requiresTenantApproval);
         switch(requiresTenantApproval.find(func(x) = x == flag)){
            case(null) false;
            case(_) true;
        }
    };

    func notNftOwner(caller: Principal, nftCollection: Principal): async Bool {
        let nftActor : Types.NFTActor = actor(Principal.toText(nftCollection));
        let tokensOwned = await nftActor.icrc7_balance_of([{owner = caller; subaccount = null}]);
        tokensOwned[0] == 0;
    };

    func alreadyVoted(proposal: Proposal, caller: Principal): Bool {
        let votes = Types.createMapHandler(Principal.compare, proposal.votes);
        switch(votes.get(caller)){
            case(null) false;
            case(_) true;
        }
    };

    func votingLive(proposal:Proposal): Bool {
        let time = Time.now();
        switch(proposal.status == #Open, proposal.startAt < time, proposal.endAt > time){
            case(true, true, true) true;
            case(_) false;
        }
    };

    func votingEnded(proposal:Proposal): Bool {
        let time = Time.now();
        switch(proposal.status == #Open, proposal.endAt < time){
            case(true, true) true;
            case(_) false;
        }
    };

    func countVotes(voteMap: Types.MapHandler<Principal, Bool>): CountVotes {
        var no = 0;
        var yes = 0;
        for((_,vote) in voteMap.entries()){
            if(vote) yes += 1 else no += 1;
        };
        {
            yesVotes = yes;
            noVotes = no;
        }
    };

    func closeProposal(proposal: Proposal): ProposalStatus {
        let count = countVotes(Types.createMapHandler(Principal.compare, proposal.votes));
        //here you could add a tenant approval check here
        if(count.yesVotes > count.noVotes) #Executed else #Rejected;
    };

    let MAX_DURATION = 1_209_600_000_000_000_000;

    func validProposalArgs(arg: ProposalArg): Bool{
        if (arg.startAt < Time.now()) return false; // must be in the future
        if (arg.durationNs <= 0) return false; 
        if (arg.durationNs > MAX_DURATION) return false;
        if (arg.payloadBlob.size() > 2_000_000) return false;
        let computedHash : Blob = Sha256.fromArray(#sha256, Blob.toArray(arg.payloadBlob));
        if (computedHash != arg.payloadHash) return false; // reject mismatch
        return true;
    };

    public shared ({caller}) func createProposal(state: DAOState, arg: ProposalArg, user: Principal, nftCollection: Principal): async Result.Result<DAOState,()>{
        if(not validProposalArgs(arg)) return #err();
        if((await notNftOwner(user, nftCollection)) and not isTenant(state, user)) return #err();
        let govOpt: ?Governance = from_candid(state.gov);
        var gov = switch(govOpt){case(?gov) gov; case(null) return #err()};
        let actionOpt : ?Types.ProposalAction = from_candid(arg.payloadBlob);
        let action = switch(actionOpt){case(?action) action; case(null) return #err();};
        let flag = proposalActionToFlag(action);
        let requiresTenantApproval = doesRequireTenantApproval(flag, gov);
        let isWhitelisted = whitelistApproved(gov, action);
        if(isWhitelisted and not requiresTenantApproval) return await executeAction(state, action, caller, null);

        let proposals = Types.createMapHandler<Nat, Proposal>(Nat.compare, gov.proposals);
        let proposal : Proposal = {
            id = gov.nextProposalId;
            creator = caller;
            createdAt = Time.now();
            votes = [];
            requiresTenantApproval;
            tenantApproved = if(requiresTenantApproval) false else true;
            requiresVote = isWhitelisted;
            startAt = arg.startAt;
            status = #Open;
            endAt = arg.startAt + arg.durationNs;
            payloadBlob = action;
            payloadHash = arg.payloadHash;
        };
        proposals.put(gov.nextProposalId, proposal);
        gov := {
            gov with
            nextProposalId = gov.nextProposalId + 1;
            proposals = proposals.toArray();
        };
        #ok({state with gov = to_candid(gov)});
    };

    public shared ({caller}) func executeVote(daoState: DAOState, arg: VoteArgs, user: Principal, nftCollection: Principal): async Result.Result<DAOState,()>{
        //if it is tenant and it doesn't require a vote - then can execute
        //if it is tenant and it does - just flip the bool
        //if tenant and proposal doesn't tenant vote - return error
        //if tenant and proposal already approved by tenant - return error - because of above - this is same as line above
        if((await notNftOwner(user, nftCollection)) and not isTenant(daoState, user)) return #err();
        let govOpt: ?Governance = from_candid(daoState.gov);
        var gov = switch(govOpt){case(?gov) gov; case(null) return #err()};
        let proposals = Types.createMapHandler<Nat, Proposal>(Nat.compare, gov.proposals);
        let proposal = switch(proposals.get(arg.proposalId)){case(null) return #err();case(?proposal) proposal;};
        if(not votingLive(proposal)) return #err();
        if(isTenant(daoState, user)){
            if(proposal.tenantApproved) return #err();
            if(not proposal.requiresVote){
                let updatedProposal = {
                    proposal with 
                    tenantApproved = true;
                    status = #Executed;
                };
                proposals.put(arg.proposalId, updatedProposal);
                let updatedDaoState = {daoState with gov = to_candid({gov with proposals = proposals.toArray()})};
                return await executeAction(updatedDaoState, proposal.payloadBlob, caller, ?arg.proposalId);
            } 
            else {
                proposals.put(arg.proposalId, {proposal with tenantApproved = true});
                return #ok({daoState with gov = to_candid({gov with proposals = proposals.toArray()})});
            }
        } 
        else {
            let votes = Types.createMapHandler(Principal.compare, proposal.votes);
            if(alreadyVoted(proposal, caller)) return #err();
            votes.put(caller, arg.vote);
            let updatedProposal = {proposal with votes = votes.toArray()};
            proposals.put(arg.proposalId, updatedProposal);
            #ok({daoState with gov = to_candid({gov with proposals = proposals.toArray()})});
        }
    };

    public shared ({caller}) func executeProposal(daoState: DAOState, proposalId: Nat): async Result.Result<DAOState,()>{
        let govOpt: ?Governance = from_candid(daoState.gov);
        var gov = switch(govOpt){case(?gov) gov; case(null) return #err()};
        let proposals = Types.createMapHandler<Nat, Proposal>(Nat.compare, gov.proposals);
        let proposal = switch(proposals.get(proposalId)){case(null) return #err();case(?proposal) proposal;};
        if(not votingEnded(proposal)) return #err();
        let outcome = closeProposal(proposal);
        proposals.put(proposalId, {proposal with status = outcome;});
        let updatedDaoState = {daoState with gov = to_candid({gov with proposals = proposals.toArray()})};
        if(outcome == #Executed) await executeAction(updatedDaoState, proposal.payloadBlob, caller, ?proposalId) else #ok(updatedDaoState);
    };
    
    public func daoAlive(): async Text {
        "Property Dao Canister is alive"
    };


}