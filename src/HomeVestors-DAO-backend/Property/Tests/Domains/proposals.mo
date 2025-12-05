import UnstableTypes "../../../Utils/unstableTypes";
import Types "../../../Utils/types";
import TestTypes "./../testTypes";
import Utils "./../utils";

import Time "mo:base/Time";
import HashMap "mo:base/HashMap";
import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";

module{
    type Actions<C,U> = Types.Actions<C,U>;
    type PropertyUnstable = UnstableTypes.PropertyUnstable;
    type WhatWithPropertyId = Types.WhatWithPropertyId;
    type UpdateResult = Types.UpdateResult;
    type SingleActionPreTestHandler<C, T> = TestTypes.SingleActionPreTestHandler<C, T>;
    type PreTestHandler<C, U, T> = TestTypes. PreTestHandler<C, U, T>;
    type FlatPreTestHandler<U,T> = TestTypes.FlatPreTestHandler<U,T>;
    type What = Types.What;
    // ====================== PROPOSALS ======================
    public func createProposalTestType2(property: PropertyUnstable, handlePropertyUpdate: (Types.WhatWithPropertyId, Principal) -> async Types.UpdateResultExternal) : async [Text] {
        type C = Types.ProposalCArg;
        type U = Types.ProposalUArg;
        type T = Types.Proposal;
        func createProposalCArg(): C {
            {
              title = "new proposal";
              description = "new proposal description";
              category = #Maintenance;
              implementation = #Week;
              startAt = Time.now() + 100000000;
              actions = [];                 
            };
        };

        func createProposalUArg(): U {
            {
              title = ?"updated proposal";
              description = ?"updated proposal description";
              category = null;
              implementation = null;
              startAt = null;
              actions = null;                      // The proposed mutations
            };
        };


        let cArg : C = createProposalCArg();
        let uArg : U = createProposalUArg();

        let proposalCases : [(Text, Actions<C,U>, Bool)] = [
            // CREATE
            Utils.ok ("Proposal: create valid",           #Create([cArg])),
            Utils.ok("Proposal: create future startAt",  #Create([{cArg with startAt = Time.now() + 999_999_999}])),
            Utils.err("Proposal: create empty title",     #Create([{cArg with title = ""}])),
            Utils.err("Proposal: create empty description", #Create([{cArg with description = ""}])),

            // UPDATE
            Utils.ok ("Proposal: update valid",           #Update((uArg, [0]))),
            Utils.ok ("Proposal: update title only",      #Update(({ uArg with title = ?"New Title"}, [0]))),
            Utils.err("Proposal: update non-exist",       #Update((uArg, [9999]))),
            Utils.err("Proposal: update executed",        #Update((uArg, [1]))), // pre-mark id=1 as executed in setup
            Utils.err("Proposal: update rejected",        #Update((uArg, [2]))), // pre-mark id=2 as rejected
            
            // DELETE
            Utils.ok ("Proposal: delete live proposal",   #Delete([0])),
            Utils.ok ("Proposal: delete by admin",        #Delete([3])),
            Utils.err("Proposal: delete non-exist",       #Delete([9999])),
            Utils.err("Proposal: delete executed",        #Delete([1]))
        ];

        let handler : PreTestHandler<C,U,T> = {
            testing = true;
            handlePropertyUpdate;
            toHashMap   = func(p: PropertyUnstable) = p.governance.proposals;
            showMap     = func(map: HashMap.HashMap<Nat,T>) = debug_show(Iter.toArray(map.entries()));
            toId        = func(p: PropertyUnstable) = p.governance.proposalId;
            toWhat      = func(action: Actions<C,U>) = #Governance(#Proposal(action));

            // ✅ UPDATE checks
            checkUpdate = func(before: T, after: T, arg: U): Text {
                var s = "";
                switch(before.status){
                    case(#LiveProposal(_)){
                        s #= Utils.assertUpdate2("title",        #OptText(?before.title),      #OptText(?after.title),      #OptText(arg.title));
                        s #= Utils.assertUpdate2("description",  #OptText(?before.description),#OptText(?after.description),#OptText(arg.description));
                        s #= Utils.assertUpdate2("startAt",      #OptInt(?before.startAt),     #OptInt(?after.startAt),     #OptInt(arg.startAt));
                        //s #= Utils.assertUpdate2("category",     #OptText(?debug_show(before.category)), #OptText(?debug_show(after.category)), #OptText(?debug_show(arg.category)));
                    };
                    case(_) s #= "\n edited an invalid type";
                };
                s;
            };

            // ✅ CREATE checks
            checkCreate = func(proposal: T): Text {
                var s = "";
                switch(proposal.status){
                    case(#LiveProposal(live)){
                        if(live.endTime < Time.now()) s #= "\n Invalid end time";
                        if (live.totalVotesCast != 0) s #= "\n totalVotesCast not 0";
                        if (live.yesVotes != 0)       s #= "\n yesVotes not 0";
                        if (live.noVotes != 0)        s #= "\n noVotes not 0";
                        if (proposal.votes.size() != 0)   s #= "\n votes not empty";
                        //if(live.timerId == null) s #= "\n timer id is null";
                        if(proposal.title == "") s #= "\n invalid title set - line 181";
                        if(proposal.description == "") s #= "\n invalid description set - line 182";
                        //if(proposal.eligibleVoters.size() == 0) s #= "\n no eligible voters";
                        //if(proposal.eligibleVoters.size() == proposal.totalEligibleVoters) s #= "\n eligible voters and total eligible voters don't match";
                    };
                    case(_) s#= "\n unexpected proposal status";
                };
                s;
            };

            // ✅ DELETE checks
            checkDelete = func(before: T, after: ?T, id: Nat, propBefore: PropertyUnstable, propAfter: PropertyUnstable, handler: PreTestHandler<C,U,T>): Text {
                var s = "";
                let proposalAfter = switch(after){case(null) return "\n el did not exist after"; case(?el) el};
                switch (before.status, proposalAfter.status) {
                    case (#LiveProposal(_), #RejectedEarly(_)) { /* valid early rejection */ };
                    case (#LiveProposal(live), #Executed(exec)) {
                        switch(exec.outcome){
                            case (#Accepted(_)) { if (exec.yesVotes < exec.noVotes) s #= "\n accepted but votes inconsistent" };
                            case (#Refused(_))  { if (exec.noVotes < exec.yesVotes) s #= "\n refused but votes inconsistent" };
                            case(#AwaitingTenantApproval) s #= "\n awaiting tenants approval";
                        };
                        if(live.yesVotes != exec.yesVotes) s #= "\n live yes votes don't equal executed yes votes";
                        if(live.noVotes != exec.noVotes) s #= "\n live no votes don't equal executed no votes";
                        //haven't tessted the impact of calling action here. 
                    };
                    case (_, _) {
                        if (before != proposalAfter) s #= "\n proposal changed unexpectedly";
                    };
                };
                s;
            };
            seedCreate = func(labels: Text, id: Nat, toWhat: Actions<C,U> -> What): [What] {
                let buffer = Buffer.Buffer<What>(0);
                switch(labels){
                    case("Proposal: update rejected" or "Proposal: delete executed" or "Proposal: update executed" or "Proposal: delete by admin"){
                        buffer.add(toWhat(#Create([{cArg with implementation = #Other(Time.now() - 1000000)}])));
                        let voteArg = {
                            proposalId = id;
                            vote = false;
                        };
                        for(i in Iter.range(0, 20)){
                            buffer.add(#Governance(#Vote(voteArg)));
                        };
                        if(labels != "Proposal: delete by admin") buffer.add(toWhat(#Delete([id])));
                        Buffer.toArray(buffer);
                    };
                    case(_) [toWhat(#Create([cArg, cArg, cArg]))];
                }
            };
            validForTest = func(labels: Text, el: T): ?Bool {
                switch(labels, el.status){
                    case("Proposal: update non-exist" or "Proposal: delete non-exist", _) null;
                    case("Proposal: update valid" or "Proposal: update title only" or "Proposal: delete live proposal" or "Proposal: delete by admin", #LiveProposal(_)) ?true;
                    case("Proposal: delete executed" or "Proposal: update executed", #Executed(_)) ?true;
                    case("Proposal: update rejected", #Executed(exec)){
                        switch(exec.outcome){
                            case(#Refused(_)) ?true;
                            case(_) ?false;
                        };
                    };
                    case(_) ?false;
                };
            };
        };

        await Utils.runGenericCases<C,U,T>(property, handler, proposalCases)
    };

    public func createVoteHandlersTest(property: PropertyUnstable, handleUpdate: (Types.WhatWithPropertyId, Principal) -> async Types.UpdateResultExternal) : async [Text] {
    type C = Types.VoteArgs;
    type T = Types.Proposal;

    let baseArg : C = {
        proposalId = 1; // assume seeding will create proposal 1
        vote = true;
    };

    let cases : [(Text, C, Bool)] = [
        // VALID
        Utils.ok1("Vote: Valid: vote YES", baseArg),
        Utils.ok1("Vote: Valid: vote NO", { baseArg with vote = false }),

        // INVALID
        Utils.err1("Vote: Invalid: already voted", baseArg),
        Utils.err1("Vote: Invalid: proposal ended", baseArg),
        Utils.err1("Vote: Invalid: proposal not found", { baseArg with proposalId = 999 }),
        Utils.err1("Vote: Invalid: wrong status (executed)", { baseArg with proposalId = 123 })
    ];
    var counter = 0;

    let handler : SingleActionPreTestHandler<C, T> = {
        testing = true;
        toHashMap = func(p: PropertyUnstable) = p.governance.proposals;
        showMap = func(map: HashMap.HashMap<Nat, T>) = debug_show(Iter.toArray(map.entries()));
        toWhat = func(arg: C) = #Governance(#Vote(arg));
        checkUpdate = func(before: T, after: T, arg: C): Text {
            var s = "";
            switch (before.status, after.status) {
                case (#LiveProposal(beforeLive), #LiveProposal(afterLive)) {
                    if (afterLive.totalVotesCast != beforeLive.totalVotesCast + 1)
                        s #= "\n totalVotesCast not incremented";

                    if (arg.vote) {
                        if (afterLive.yesVotes != beforeLive.yesVotes + 1)
                            s #= "\n yesVotes not incremented";
                    } else {
                        if (afterLive.noVotes != beforeLive.noVotes + 1)
                            s #= "\n noVotes not incremented";
                    };

                    if (after.votes.size() != before.votes.size() + 1)
                        s #= "\n vote not appended";

                };
                case _ {
                    s #= "\n they voted on a non live proposal!";
                };
            };
            s;
        };
        handlePropertyUpdate = handleUpdate;
        seedCreate = func(labels: Text, p: PropertyUnstable): [Types.What] {
            switch(labels){
                case("Vote: Valid: vote YES" or "Vote: Valid: vote NO" or "Vote: Invalid: already voted") {
                    return [
                        #Governance(#Proposal(#Create([{
                            title = "test proposal";
                            description = "desc";
                            category = #Maintenance;
                            implementation = #Week;
                            actions = [];
                            startAt = Time.now();
                        }]))), 
                        #Governance(#Vote({baseArg with proposalId = property.governance.proposalId}))
                    ];
                };
                case("Vote: Invalid: proposal ended"){
                    [
                        #Governance(#Proposal(#Create([{
                            title = "test proposal";
                            description = "desc";
                            category = #Maintenance;
                            implementation = #Week;
                            actions = [];
                            startAt = Time.now();
                        }]))),
                        #Governance(#Proposal(#Delete([property.governance.proposalId + 1])))
                    ];
                };
                case("Vote: Invalid: wrong status (executed)") {
                    return [
                        #Governance(#Proposal(#Create([{
                            title = "executed proposal";
                            description = "desc";
                            category = #Maintenance;
                            implementation = #Week;
                            actions = [];
                            startAt = Time.now();
                        }]))),
                        #Governance(#Proposal(#Delete([p.governance.proposalId + 1])))
                    ];
                };
                case(_) [];
            }
        };
        toCaller = func(labels: Text, id: Nat, p: PropertyUnstable): Principal {
            switch(labels, p.governance.proposals.get(id)){
                case("Vote: Invalid: already voted", ?proposal){
                    proposal.votes[0].0;
                };
                case(_){
                    counter += 1;
                    Utils.randomPrincipal(counter);
                };
            };
            
        };
        validForTest = func(labels: Text, el: T): ?Bool {
            switch(labels, el.status){
                case("Vote: Valid: vote YES" or "Vote: Valid: vote NO", #LiveProposal(_)) ?true;
                case("Vote: Invalid: already voted", #LiveProposal(_)) if(el.votes.size() > 0) ?true else ?false;
                case("Vote: Invalid: proposal ended", #Executed(_)) ?true;
                case("Vote: Invalid: proposal not found", _) null;
                case("Vote: Invalid: wrong status (executed)", #Executed(_)) ?true;
                case(_) ?false;
            }
        };
        setId = func(id: Nat, arg: C) = { arg with proposalId = id };
    };

    await Utils.runSingleActionGenericCases<C, T>(property, handler, cases);
};

}