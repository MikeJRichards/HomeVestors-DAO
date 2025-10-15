import Types "types";
import Stables "./Tests/stables";
import Operational "operational";
import { setTimer; cancelTimer } = "mo:base/Timer";
import UnstableTypes "./Tests/unstableTypes";
import NFT "nft";
import PropHelper "propHelper";
import Time "mo:base/Time";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import Array "mo:base/Array";
import Result "mo:base/Result";
import Int "mo:base/Int";
import Buffer "mo:base/Buffer";
import Nat "mo:base/Nat";
import HashMap "mo:base/HashMap";
//import Option "mo:base/Option";

module {
    type Proposal = Types.Proposal;
    type Property = Types.Property;
    type ProposalUnstable = UnstableTypes.ProposalUnstable;
    type ProposalCategory = Types.ProposalCategory;
    type ImplementationCategory = Types.ImplementationCategory;
    type ProposalStatus = Types.ProposalStatus;
    type ProposalCArg = Types.ProposalCArg;
    type ProposalUArg = Types.ProposalUArg;
    type Governance = Types.Governance;
    type Arg = Types.Arg;
    type Actions<C,U> = Types.Actions<C,U>;
    type UpdateResult = Types.UpdateResult;
    type UpdateResultBeforeVsAfter = Types.UpdateResultBeforeVsAfter;
    type What = Types.What;
    type Handler<C, U> = UnstableTypes.Handler<C, U>;
    type CrudHandler<C, U, T, StableT> = UnstableTypes.CrudHandler<C, U, T, StableT>;
    type UpdateError = Types.UpdateError;

    public func isAccepted(property: UnstableTypes.PropertyUnstable, id: Nat): ?Bool {
        switch(property.governance.proposals.get(id)){
            case(?proposal){
                switch(proposal.status){
                    case(#Executed(executed)){
                        switch(executed.outcome){
                            case(#Refused(_)) ?false;
                            case(#Accepted(_)) ?true;
                            case(#AwaitingTenantApproval) ?false;
                        }
                    };
                    case(_) null;
                }
            };
            case(null) null;
        }
    };

    func executeProposal(arg: Arg, governance: UnstableTypes.GovernanceUnstable, id: Nat): async (){
        switch(governance.proposals.get(id)){
            case(null){};
            case(?proposal){
                switch(proposal.status){
                    case(#Executed(executed)){
                        switch(executed.outcome){
                            case(#Accepted(_)){
                                let results = Buffer.Buffer<UpdateResultBeforeVsAfter>(proposal.actions.size());
                                for(what in proposal.actions.vals()){
                                    let whatWithPropertyId: Types.WhatWithPropertyId = {
                                        propertyId = arg.property.id;
                                        what;
                                    };
                                    results.add(await arg.handlePropertyUpdate(whatWithPropertyId, arg.caller));
                                };
                                let status : Types.ProposalStatus = #Executed {
                                    executed with 
                                    outcome = #Accepted(Buffer.toArray(results));
                                };
                                let updatedProposal :Proposal = {
                                    proposal with 
                                    status; 
                                };
                                governance.proposals.put(id, updatedProposal);
                            };
                            case(_){};
                        };
                    };
                    case(_){};
                }
            }
        }
    };

    public func createTimers<system>(arg: Arg, g: UnstableTypes.GovernanceUnstable, proposalId: Nat): async (){
        let addTimer = func<system>(delay: Nat): ?Nat{
            ?setTimer<system>(#nanoseconds delay, func () : async () {
                let updateProposal: Types.WhatWithPropertyId = {
                    propertyId = arg.property.id;
                    what = #Governance(#Proposal(#Delete([proposalId])))
                };
                ignore arg.handlePropertyUpdate(updateProposal, Principal.fromText("vq2za-kqaaa-aaaas-amlvq-cai"));
            }); 
        };

        switch(g.proposals.get(proposalId)){
            case(?proposal){
                switch(proposal.status){
                    case(#LiveProposal(live)){
                        switch(live.timerId){case(null){}; case(?timerId) cancelTimer(timerId)};
                        
                        let updatedProposal = {
                            proposal with 
                            status = #LiveProposal{
                                live with
                                timerId = if(live.endTime > Time.now()) addTimer<system>(Int.abs(live.endTime - Time.now())) else null; 
                            }
                        };
                        g.proposals.put(proposalId, updatedProposal);
                        
                    };
                    case(_){};
                };
            };
            case(_){};
        };
    };


    public func createProposalHandlers(arg: Arg, action: Actions<ProposalCArg, ProposalUArg>):async UpdateResult {
        type C = ProposalCArg;
        type U = ProposalUArg;
        type T = ProposalUnstable;
        type StableT = Proposal;
        let governance = Stables.toPartialStableGovernance(arg.property.governance);
        
        let calculateEndTime = func(startTime: Int, category: ImplementationCategory) : Int {
            let HOUR_NS : Int = 3_600_000_000_000;
            let DAY_NS : Int = 24 * HOUR_NS;
        
            let duration = switch (category) {
              case (#Quick)    6 * HOUR_NS;
              case (#Day)      1 * DAY_NS;
              case (#FourDays) 4 * DAY_NS;
              case (#Week)     7 * DAY_NS;
              case (#BiWeek)   14 * DAY_NS;
              case (#Month)    30 * DAY_NS;
              case(#Other(endAt)) endAt;
            };
            startTime + duration
        };  

        let crudHandler : CrudHandler<C, U, T, StableT> = {
            map = governance.proposals;
            var id = governance.proposalId;
            setId = func(id: Nat) = governance.proposalId := id;
            
            assignId = func(id: Nat, el: StableT): (Nat, StableT){
                (id, {el with id = id});
            };

            delete =  func(id: Nat, el: StableT): (){
                switch(el.status){
                    case(#LiveProposal(live)){
                        if(arg.caller == PropHelper.getAdmin()){
                            switch(live.timerId){case(null){}; case(?timerId) cancelTimer(timerId)};
                            governance.proposals.put(id, {el with status = #RejectedEarly{reason = "cancelled By Admin"}});
                        }
                        else if(live.endTime <= Time.now()){
                            switch(live.timerId){case(null){}; case(?timerId) cancelTimer(timerId)};
                            let awaitingTenantApproval = switch(el.category){
                                case(#Maintenance(arg) or #Tenancy(arg) or #Rent(arg)) not arg.tenantApproved;
                                case(_) false;
                            };
                            let executedProposal : Types.ProposalStatus = #Executed{
                                outcome = if(live.yesVotes > live.noVotes and awaitingTenantApproval) #AwaitingTenantApproval else if(live.yesVotes > live.noVotes) #Accepted([]) else #Refused("");
                                executedAt = Time.now();
                                yesVotes = live.yesVotes;
                                noVotes = live.noVotes;
                                totalVotesCast = el.votes.size();
                            };
                            governance.proposals.put(id, {el with status = executedProposal});
                        }
                    };
                    case(_){};
                };
            };
            fromStable = Stables.fromStableProposal;

            create = func(args: C, id: Nat): T {
                let configureCategory = func(): ProposalCategory {
                    switch(args.category){
                        case(#Maintenance) #Maintenance({tenantApproved= false});
                        case(#Rent) #Rent({tenantApproved= false});
                        case(#Operations) #Operations;
                        case(#Admin) #Admin;
                        case(#Valuation) #Valuation;
                        case(#Invoice(arg)) #Invoice({invoiceId = arg.invoiceId});
                        case(#Tenancy(arg)) #Tenancy({tenantApproved= false});
                        case(#Other(arg)) #Other(arg);
                    };
                };
                let newProposal : Proposal = {
                    args with
                    category = configureCategory();
                    id;
                    creator = arg.caller;
                    createdAt = Time.now();
                    eligibleVoters = []; //do intercanister calls to determine prinicples
                    totalEligibleVoters = 0; //use array above to calculate size
                    votes = [];
                    status = #LiveProposal{
                        endTime = calculateEndTime(args.startAt, args.implementation);
                        yesVotes = 0;
                        noVotes = 0;
                        eligibleVoterCount = 0;
                        totalVotesCast = 0; 
                        timerId = null;
                    };
                };
                Stables.fromStableProposal(newProposal);
            };
            mutate = func(arg: U, el: T): T {
                switch(el.status){
                    case(#LiveProposal(live)){
                        el.title := PropHelper.get(arg.title, el.title);
                        el.startAt := PropHelper.get(arg.startAt, el.startAt);
                        el.description := PropHelper.get(arg.description, el.description);
                        el.category := PropHelper.get(arg.category, el.category);
                        el.implementation := PropHelper.get(arg.implementation, el.implementation); //need to alter timer and end time - if this has changed
                        el.actions := PropHelper.get(arg.actions, el.actions);
                        el.status := #LiveProposal{live with endTime = calculateEndTime(el.startAt, el.implementation)};
                        el;
                    };
                    case(_){el};
                }
            };
            validate = func(el: ?T): Result.Result<T, UpdateError>{
                let proposal = switch(el){case(null) return #err(#InvalidElementId); case(?p) p};
                switch(proposal.status){
                    case(#LiveProposal(live)){
                        if(proposal.title == "") return #err(#InvalidData{field = "title"; reason = #EmptyString;});
                        if(proposal.description == "") return #err(#InvalidData{field = "description"; reason = #EmptyString;});
                        if(Principal.isAnonymous(proposal.creator)) return #err(#InvalidData{field = "creator"; reason = #Anonymous;});
                        switch(action){
                            case(#Create(_)) if(proposal.startAt < Time.now()) return #err(#InvalidData{field = "start at"; reason = #CannotBeSetInThePast;});
                            case(#Update(_)){
                                if(proposal.startAt < Time.now()) return #err(#InvalidData{field = "start at"; reason = #CannotBeSetInThePast;});
                                if(not arg.testing){
                                    if(proposal.eligibleVoters.size() == 0) return #err(#InvalidData{field = "eligible voters"; reason = #CannotBeNull;})
                                };
                            };
                            case(#Delete(_)){
                                if(not arg.testing){
                                    if(arg.caller != PropHelper.getAdmin() and live.endTime > Time.now()) return #err(#InvalidData{field = "End Time"; reason = #CannotBeSetInTheFuture;});
                                    if(proposal.eligibleVoters.size() == 0) return #err(#InvalidData{field = "eligible voters"; reason = #CannotBeNull;});
                                }
                            }; 
                        };
                        #ok(proposal);
                    };
                    case(_) return #err(#InvalidType);
                };
            };
        };

        let voters = HashMap.HashMap<Nat, [Principal]>(0, Nat.equal, PropHelper.natToHash);

        let handler: Handler<T, StableT> = {
            toStruct = PropHelper.toStruct<C, U, T, StableT>(action, crudHandler, func(stableT: ?StableT) = #Proposal(stableT), func(property: Property) = property.governance.proposals);
            validateAndPrepare = func () = PropHelper.getValid<C, U, T, StableT>(action, crudHandler);
            
            asyncEffect = func(arr: [(?Nat, Result.Result<T, UpdateError>)]): async [(?Nat, Result.Result<(), UpdateError>)] {
                if(arg.testing) return PropHelper.runNoAsync<T>(arr);
                switch(action){
                    case(#Create(_)){
                                    let tokenIds = Buffer.Buffer<Nat>(1000);
                                    for(i in Iter.range(0, 1000)){
                                        tokenIds.add(i);
                                    };
                                    let accounts = await NFT.icrc7_owner_of(Buffer.toArray(tokenIds), arg.property.nftMarketplace.collectionId);
                                    let map = HashMap.HashMap<Principal, Nat>(0, Principal.equal, Principal.hash);
                                    for(accountOpt in accounts.vals()){
                                        let account = PropHelper.get(accountOpt, {owner = PropHelper.getAdmin(); subaccount = null});
                                        switch(map.get(account.owner)){
                                            case(null) map.put(account.owner, 1);
                                            case(?count) map.put(account.owner, count + 1);
                                        };
                                    };
                        let results = Buffer.Buffer<(?Nat, Result.Result<(), UpdateError>)>(arr.size());
                        for((id, res) in arr.vals()){
                            switch(id, res){
                                case(?id, #ok(_)){
                                    voters.put(id, Iter.toArray(map.keys()));
                                    results.add((?id, #ok()));
                                };
                                case(_, #err(e)) results.add((id, #err(e)));
                                case(null, _) results.add((id, #err(#InvalidElementId)));
                            }
                        };
                        return Buffer.toArray(results);
                    };
                    case(_) PropHelper.runNoAsync<T>(arr);
                }
            };

            applyAsyncEffects = func(idOpt: ?Nat, res: Result.Result<T, Types.UpdateError>): [(?Nat, Result.Result<StableT, UpdateError>)]{
                switch(idOpt, res){
                    case(null, _) return [(null, #err(#InvalidElementId))];
                    case(?id, #ok(el)){
                        switch(voters.get(id)){
                            case(?voters){
                                el.eligibleVoters := voters;
                                el.totalEligibleVoters := voters.size();
                            };
                            case(null){};
                        };
                        return [(idOpt, #ok(Stables.toStableProposal(el)))];
                    }; 
                    case(?id, #err(e)) return [(idOpt, #err(e))];
                };
            };

            applyUpdate = func(id: ?Nat, el: StableT) = PropHelper.applyUpdate<C, U, T, StableT>(action, id, el, crudHandler);

            getUpdate = func() = #Governance(Stables.fromPartialStableGovernance(governance));

            finalAsync = func(arr: [Result.Result<?Nat, (?Nat, UpdateError)>]): async (){
                if(arg.testing) return;
                for(res in arr.vals()){
                    switch(res, action){
                        case(#ok(?id), #Create(_) or #Update(_)) ignore createTimers(arg, governance, id);
                        case(#ok(?id), #Delete(_)) await executeProposal(arg, governance, id);
                        case(_){};
                    }

                };
            };
        };

        await PropHelper.applyHandler<T, StableT>(arg, handler);
    };

    public func voteHandler(args: Arg, arg: Types.VoteArgs): async UpdateResult {
        type U = Types.VoteArgs;
        type T = UnstableTypes.ProposalUnstable;
        type StableT = Proposal;
        let governance = Stables.toPartialStableGovernance(args.property.governance);

        let requiresTenantApproval = func(category: Types.ProposalCategory): Bool {
            switch(category){
                case(#Maintenance(arg) or #Tenancy(arg) or #Rent(arg)) not arg.tenantApproved;
                case(_) false;
            }
        };

        let updateWithTenantApproval = func(category: Types.ProposalCategory): Types.ProposalCategory {
            switch(category){
                case(#Maintenance(_)) #Maintenance({tenantApproved = true;});
                case(#Tenancy(_)) #Tenancy({tenantApproved = true;});
                case(#Rent(_))#Rent({tenantApproved = true;});
                case(other) other;
            }
        };

        let handler: Handler<T, StableT> = {
            toStruct = func(property: Property, idOpt: ?Nat, beforeOrAfter: UnstableTypes.BeforeOrAfter): Types.ToStruct {
                let id = switch(idOpt){case(null) return #Err(idOpt, #NullId); case(?id) id;};
                switch(governance.proposals.get(id)){
                    case(null) return #Err(idOpt, #InvalidElementId);
                    case(?proposal) return #Proposal(?proposal)
                }
            };
            validateAndPrepare = func(): [(?Nat, Result.Result<T, UpdateError>)] {
              switch(governance.proposals.get(arg.proposalId)){
                  case(null) return [(?arg.proposalId,#err(#InvalidType))];
                  case(?proposal){
                      switch(proposal.status){
                          case(#LiveProposal(live)){
                            //dao voting system
                            if(Time.now() > live.endTime) return [(?arg.proposalId, #err(#InvalidData{field = "End Time"; reason = #CannotBeSetInThePast}))];
                            if(not PropHelper.isInList<Principal>(args.caller, proposal.eligibleVoters, Principal.equal) and not args.testing) return [(?arg.proposalId, #err(#InvalidData{field = "Eligible Voters"; reason = #InvalidInput}))];
                            if(PropHelper.isInList<(Principal, Bool)>((args.caller, true), proposal.votes, func ((a, _), (b, _)) { Principal.equal(a, b) })) return [(?arg.proposalId, #err(#InvalidData{field = "Votes"; reason = #AlreadyVoted}))];
                            var updatedProposal : Proposal = {
                                proposal with
                                votes = Array.append(proposal.votes, [(args.caller, arg.vote)]);
                                status = #LiveProposal{
                                    live with
                                    yesVotes = if(arg.vote) live.yesVotes + 1 else live.yesVotes;
                                    noVotes = if(not arg.vote) live.noVotes + 1 else live.noVotes;
                                    totalVotesCast = live.totalVotesCast + 1;
                                }
                            };

                            //deal with tenant vote here - changes category to true - or executed rejected by tenant here
                            if (requiresTenantApproval(proposal.category) 
                                and Operational.isTenant(args.caller, args.property)) {
                                updatedProposal := switch (arg.vote) {
                                  case (false) {
                                    // tenant veto
                                     {
                                      proposal with
                                      status = #Executed{
                                        outcome = #Refused("Rejected by tenant");
                                        executedAt = Time.now();
                                        yesVotes = live.yesVotes;
                                        noVotes  = live.noVotes;
                                        totalVotesCast = proposal.votes.size();
                                      }
                                    };
                                  };
                                  case (true) {
                                    // tenant pre-approves
                                    {
                                      proposal with
                                      category = updateWithTenantApproval(proposal.category)
                                    };
                                  };
                                };
                            };
                            return [(?arg.proposalId, #ok(Stables.fromStableProposal(updatedProposal)))];
                          };
                          case (#Executed(executed)) {
                              switch (executed.outcome) {
                                case (#AwaitingTenantApproval) {
                                  if (Operational.isTenant(args.caller, args.property)) {
                                    if (arg.vote == false) {
                                        let updatedProposal : StableT = {proposal with status = #Executed({ executed with outcome = #Refused("Rejected by tenant")})};
                                        [(?arg.proposalId, #ok(Stables.fromStableProposal(updatedProposal)))];
                                    } else {
                                      let updatedProposal = {proposal with status = #Executed{executed with outcome = #Accepted([])}};
                                      [(?arg.proposalId, #ok(Stables.fromStableProposal(updatedProposal)))];
                                    };
                                  } else {
                                    return [(?arg.proposalId, #err(#InvalidType))];
                                  }
                                };
                                case (_) return [(?arg.proposalId, #err(#InvalidType))];
                              }
                            };
                          //deal with executed (outcome = awaiting tenant approval)
                          case(_) return [(?arg.proposalId, #err(#InvalidType))];
                      }
                  }
              };
            };

            asyncEffect = func(arr: [(?Nat, Result.Result<T, UpdateError>)]): async [(?Nat, Result.Result<(), UpdateError>)] { PropHelper.runNoAsync<T>(arr);};

            applyAsyncEffects = func(res: (?Nat, Result.Result<T, Types.UpdateError>)): [(?Nat, Result.Result<StableT, Types.UpdateError>)] {
              switch (res) {
                case (?id, #ok(el)) [(?id, #ok(Stables.toStableProposal(el)))];
                case (_, #err(e)) [(null, #err(e))];
                case (null, #ok(_)) [(null, #err(#InvalidElementId))];
              };
            };

            applyUpdate = func(id: ?Nat, el: StableT): ?Nat {
                switch(id){case(?id) governance.proposals.put(id, el); case(_){};};
                return id;
            };

            getUpdate = func() = #Governance(Stables.fromPartialStableGovernance(governance));


            finalAsync = func(arr: [Result.Result<?Nat, (?Nat, UpdateError)>]): async () {
                if(args.testing) return;
                for(res in arr.vals()){
                    switch(res){
                        case(#ok(?id)) await executeProposal(args, governance, id);
                        case(_){};
                    }

                };
            };
        };

        await PropHelper.applyHandler(args, handler);
    };    

    func matchProposalCategory(el: Proposal, cats: ?[Types.ProposalCategoryFlag]): Bool {
        switch (cats) {
            case null true;
            case (?c) {
                var matched = false;
                for (cat in c.vals()) {
                    switch (cat, el.category) {
                        case (#Maintenance, #Maintenance(_)) { matched := true };
                        case (#Operations,  #Operations) { matched := true };
                        case (#Admin,       #Admin) { matched := true };
                        case (#Valuation,   #Valuation) { matched := true };
                        case (#Invoice(_),  #Invoice(_)) { matched := true };
                        case (#Rent,        #Rent(_)) { matched := true };
                        case (#Other(_),    #Other(_)) { matched := true };
                        case (#Tenancy,     #Tenancy(_)) { matched := true };
                        case (_) {};
                    };
                };
                return matched;
            };
        };
    };

    func matchStatus(el: Proposal, status: ?Types.ProposalStatusFlag): Bool {
        switch(el.status, status){
            case(_, null) true;
            case(#LiveProposal(_), ?#LiveProposal) true;
            case(#Executed(_), ?#Executed) true;
            case(#RejectedEarly(_), ?#RejectedEarly) true;
            case(_) false;
        }
    };

   func matchOutcome(el: Proposal, outcome: ?Types.ProposalOutcomeFlag): Bool {
      switch (outcome, el.status) {
        case (null, _) true; // no filter → always match
        case (?#Refused, #Executed({ outcome = #Refused(_) })) true;
        case (?#Accepted, #Executed({ outcome = #Accepted(_) })) true;
        case (_) false;
      }
    };

    func matchProposalImplementation(el: Proposal, implementation: ?ImplementationCategory): Bool {
        switch(implementation){
            case(null) true;
            case(?implementation) el.implementation == implementation;
        }
    };

    func matchVotedCondition(el: Proposal, voted: ?Types.HasVoted): Bool {
        func previouslyVoted(voter: Principal): Bool {
            for((principal, _) in el.votes.vals()){
                if(Principal.equal(principal, voter)) return true;
            };
            false;
        };

        switch(voted){
            case(null) true; 
            case(?#HasVoted(principal)) previouslyVoted(principal);
            case(?#NotVoted(principal)) not previouslyVoted(principal);
        };
    };

    public func matchProposalConditions(el: Proposal, conditionals: Types.ProposalConditionals): Types.ReadOutcome<Proposal> {
        let (yesVotes, noVotes) = switch(el.status){
            case(#LiveProposal(proposal)) (proposal.yesVotes, proposal.noVotes);
            case(#Executed(proposal)) (proposal.yesVotes, proposal.noVotes);
            case(_) (0, 0);
        };
        if(
            matchProposalCategory(el, conditionals.category) and
            matchProposalImplementation(el, conditionals.implementationCategory) and 
            matchStatus(el, conditionals.status) and
            matchOutcome(el, conditionals.outcome) and
            matchVotedCondition(el, conditionals.voted) and
            PropHelper.matchWhat(el.actions, conditionals.actions) and
            PropHelper.matchNullablePrincipals(?el.creator, conditionals.creator) and
            PropHelper.matchEqualityFlag(el.eligibleVoters.size(): Int, conditionals.eligibleCount) and
            PropHelper.matchEqualityFlag(el.votes.size(): Int, conditionals.totalVoterCount) and
            PropHelper.matchEqualityFlag(el.startAt, conditionals.startAt) and
            PropHelper.matchEqualityFlag(yesVotes, conditionals.yesVotes) and
            PropHelper.matchEqualityFlag(noVotes, conditionals.noVotes)
        ){
            #Ok(el);
        }
        else #Err(#DidNotMatchConditions);
    };



}