import Iter "mo:core/Iter";
import Order "mo:core/Order";
import Map "mo:core/Map";
import List "mo:core/List";
import Nat "mo:core/Nat";
import Result "mo:core/Result";
import PropertyTypes "./propertyTypes";

module {
    public type MapHandler<K,V> = {
        put: (K, V) -> ();
        get: K -> ?V;
        remove: K -> ();
        entries: () -> Iter.Iter<(K, V)>;
        toArray: () -> [(K, V)];
    };
    public func createMapHandler<K,V>(compare: (K, K) -> Order.Order, arr: [(K, V)]): MapHandler<K,V>{
        let map = Map.fromIter(arr.vals(), compare);

        {
            put = func(key : K, value : V) {
                Map.add(map, compare, key, value);
            };

            get = func (key : K) : ?V {
                Map.get(map, compare, key);
            };

            remove = func(key : K) {
                Map.remove(map, compare, key);
            };

            entries = func(): Iter.Iter<(K, V)> {                
                Map.entries(map)
            };

            toArray = func(): [(K, V)]{
                Iter.toArray(Map.entries(map));
            };
        }
    };

    public type ListHandler<T> = {
        list: List.List<T>;
        add : (T) -> ();                            // push to end
        addAll : (Iter.Iter<T>) -> ();              // push many
        removeLast : () -> ?T;                      // pop from end
        clear : () -> ();                           // wipe list
        get : (Nat) -> ?T;                          // safe index
        put : (Nat, T) -> ();                       // overwrite index (trap if OOB)
        size : () -> Nat;                           // current length
        entries : () -> Iter.Iter<T>;                // iterator over values
        filter: (T, T->Bool)->ListHandler<T>;
        toArray : () -> [T];                        // snapshot as array
        find : (T -> Bool) -> ?T;                   // first matching element
        zip : <A, B>(List.List<A>, List.List<B>) -> ListHandler<(A, B)>; //create a tuple list from two lists
    };

    public func createListHandler<T>(arr : [T]) : ListHandler<T> {
        let list = List.fromArray(arr);
        {
            list;
            // add element to the end
            add = func (value : T) {
                List.add<T>(list, value);
            };

            // add all elements from an iterator
            addAll = func (it : Iter.Iter<T>) {
                List.addAll<T>(list, it);
            };

            // remove and return last element, or null if empty
            removeLast = func () : ?T {
                List.removeLast<T>(list);
            };

            // clear the list in-place
            clear = func () {
                List.clear<T>(list);
            };

            // safe get: returns ?T instead of trapping
            get = func (index : Nat) : ?T {
               let sz = List.size<T>(list);
                if (index >= sz) {
                    null
                } else {
                    List.get<T>(list, index)
                }
            };

            // overwrite element at index (traps if index >= size)
            put = func (index : Nat, value : T) {
                List.put<T>(list, index, value);
            };

            filter = func(el: T, match: T -> Bool): ListHandler<T>{
                createListHandler(List.toArray<T>(List.filter<T>(list, match)));
            };

            // current size
            size = func () : Nat {
                List.size<T>(list);
            };

            // iterator over current values
            entries = func () : Iter.Iter<T> {
                List.values<T>(list);
            };

            // snapshot to array
            toArray = func () : [T] {
                List.toArray<T>(list);
            };

            // first element matching predicate
            find = func (pred : T -> Bool) : ?T {
                List.find<T>(list, pred);
            };

            zip = func <A, B>(list: List.List<A>, other : List.List<B>) : ListHandler<(A, B)> {
                let out = List.empty<(A, B)>();
                let len = Nat.min(List.size(list), List.size(other));

                var i : Nat = 0;
                while (i < len) {
                    switch(List.get<A>(list, i), List.get<B>(other, i)){
                        case(?a, ?b) List.add(out, (a, b));
                        case(_){};
                    };
                    i += 1;
                };
                createListHandler(List.toArray<(A,B)>(out));
            };
        };
    };

    public type PropertyModule = actor {
        updateProperty: shared (PropertyTypes.Property, PropertyTypes.What) -> async Result.Result<(PropertyTypes.UpdateResultExternal, PropertyTypes.Property), PropertyTypes.UpdateResultExternal>;
    };

    public type Governance = {
        nextProposalId : Nat;
        nextExecutionOutcomeId: Nat;
        whitelisted: [ProposalActionFlag];
        requiresTenantApproval: [ProposalActionFlag];
        proposals : [(Nat, Proposal)];
        executionOutcomes: [(Nat, ExecutionOutcomes)]
    };

    public type DAOState = {
        gov: Blob;
        property: Blob;
    };

    public type Proposal = {
        id : Nat;
        creator : Principal;
        createdAt : Int;

        // Voting
        votes : [(Principal, Bool)]; // prevents double votes + keeps stats

        startAt : Int;
        endAt : Int;
        requiresTenantApproval: Bool;
        tenantApproved: Bool;
        requiresVote: Bool;

        status : ProposalStatus;

        // The immutable execution payload
        payloadBlob : ProposalAction;
        payloadHash : Blob;
    };

    public type ProposalStatus = {
        #Open;
        #Executed;
        #Rejected;
        #Cancelled;
    };

    public type ProposalArg = {
        startAt : Int;           // must be now or future
        durationNs : Int;        // voting window
        payloadBlob : Blob;      // candid-encoded What[]
        payloadHash : Blob;      // sha256(payloadBlob)
    };

    public type VoteArgs = {
        proposalId : Nat;
        vote : Bool;
    };

    public type CountVotes = {
        yesVotes: Nat;
        noVotes: Nat;
    };

    public type ProposalAction = {
        #Property: PropertyTypes.What;
        #DAO: DAOAction; 
        #Governance: GovernanceAction;
    };

    public type ProposalActionFlag = {
        #Property: PropertyWhatFlag;
        #DAO: DAOActionFlag;
        #Governance: GoveranceActionFlag;
    };

    public type ActionFlag = {
        #Create;
        #Update;
        #Delete;
    };

    public type PropertyWhatFlag = {
        #Insurance: ActionFlag;
        #Document: ActionFlag;
        #Note: ActionFlag;
        #Maintenance: ActionFlag;
        #Inspection: ActionFlag;
        #Tenant: ActionFlag;
        #Valuations: ActionFlag;
        #Financials;
        #MonthlyRent;
        #PhysicalDetails;
        #AdditionalDetails;
        #Images: ActionFlag;
        #Description;
        #Invoice:ActionFlag; 
    };

    public type DAOActionFlag = {
        #TransferToken;
        #ApproveTransferFromToken;
        #TransferNFT;
        #ApproveTransferFromNFT;
        #ChangeActionDictionary;
    };

    public type GoveranceActionFlag = {
        #WhitelistPropertyAction;
        #RequiresTenantApproval;
    };

    public type DAOAction = {
        #TransferToken: TokenTransferArg;
        #ApproveTransferFromToken: TokenApproveArgs;
        #TransferNFT: [NFTTransferArg];
        #ApproveTransferFromNFT: [NFTApproveTokenArg];
        #ChangeActionDictionary: Principal;
    };
    
    public type GovernanceAction = {
        #WhitelistPropertyAction: {
            #Add: [ProposalActionFlag];    
            #Remove: [ProposalActionFlag];
        };
        #RequiresTenantApproval: {
            #Add: [ProposalActionFlag];    
            #Remove: [ProposalActionFlag];
        };
    };

    public type Account = {
        owner: Principal;
        subaccount: ?Blob;
    };

    public type TokenTransferArg = {
      to : Account;
      from_subaccount : ?Blob;
      amount : Nat;
      fee : ?Nat;
      memo : ?Blob;
      created_at_time : ?Nat64;
    };

    public type TokenApproveArgs = {
        from_subaccount : ?Blob;
        spender : Account;
        amount : Nat;
        expected_allowance : ?Nat;
        expires_at : ?Nat64;
        fee : ?Nat;
        memo : ?Blob;
        created_at_time : ?Nat64;
    };

    public type TokenApproveResult = {
      #Ok : Nat;
      #Err : TokenApproveError;
    };

    public type TokenApproveError = {
      #BadFee : { expected_fee : Nat };
      #InsufficientFunds : { balance : Nat };
      #AllowanceChanged : { current_allowance : Nat };
      #Expired : { ledger_time : Nat64 };
      #TooOld;
      #CreatedInFuture : { ledger_time : Nat64 };
      #Duplicate : { duplicate_of : Nat };
      #TemporarilyUnavailable;
      #GenericError : { error_code : Nat; message : Text };
    };

    public type DAOTokenApproveResult ={
        #Ok: Nat;
        #Err: TokenApproveError or {#Unauthorized}; 
    };

    public type NFTApproveTokenArg = {
        token_id : Nat;
        approval_info : NFTApprovalInfo;
    };

    public type NFTApprovalInfo = {
        spender : Account;             // Approval is given to an ICRC Account
        from_subaccount : ?Blob;    // The subaccount the token can be transferred out from with the approval
        expires_at : ?Nat64;
        memo : ?Blob;
        created_at_time : Nat64; 
    };

    public type NFTApproveTokenResult = {
        #Ok : Nat; // Transaction index for successful approval
        #Err : NFTApproveTokenError;
    };

    public type NFTApproveTokenError = {
        #TooOld;
        #CreatedInFuture : {ledger_time: Nat64};
        #GenericError : {error_code : Nat; message : Text};
        #GenericBatchError : {error_code : Nat; message : Text};
        #Unauthorized;
        #NonExistingTokenId;
        #InvalidSpender;
    };

    public type NFTBaseError = {
        #TooOld;
        #CreatedInFuture : {ledger_time: Nat64};
        #GenericError : {error_code : Nat; message : Text};
        #GenericBatchError : {error_code : Nat; message : Text};
    };

    public type NFTStandardError = NFTBaseError or {
        #Unauthorized;
        #NonExistingTokenId;
    };

    public type NFTTransferError = NFTStandardError or {
        #InvalidRecipient;
        #Duplicate : {duplicate_of : Nat};
    };

    public type NFTTransferArg = {
        token_id : Nat;
        from_subaccount : ?Blob;
        memo: ?Blob;
        created_at_time: ?Nat64;
        to: Account;
    };

    public type NFTTransferResult = {
        #Ok : Nat; // Transaction index for successful transfer
        #Err : NFTTransferError;
    };

    public type TokenTransferResult = {
      #Ok : Nat;
      #Err : TokenTransferError;
    };

    public type TokenBaseError = {
        #Unauthorized;
        #BadFee : { expected_fee : Nat };
        #InsufficientFunds : { balance : Nat };
        #TooOld;
        #CreatedInFuture : { ledger_time : Nat64 };
        #Duplicate : { duplicate_of : Nat };
        #TemporarilyUnavailable;
        #GenericError : { error_code : Nat; message : Text };
    };

    public type TokenTransferError = TokenBaseError or {
      #BadBurn : { min_burn_amount : Nat };
    };

    public type NFTActor = actor {
        icrc7_balance_of: query ([Account]) -> async [Nat];
    };

    public type PropertyDAO = actor {
        transferNFT: shared ([NFTTransferArg]) -> async [?NFTTransferResult];
        approveNFTTransfer: shared ([NFTApproveTokenArg]) -> async [?NFTApproveTokenResult];
        transferTokens: shared (TokenTransferArg, Principal) -> async TokenTransferResult;
        approveTokenTransfer: shared (TokenApproveArgs, Principal) -> async DAOTokenApproveResult;
        updateActionDictionary: shared Principal -> async Result.Result<(), ()>;
    };

    public type ExecutionResult = {
        #TransferNFT: [?NFTTransferResult];
        #TransferToken: TokenTransferResult;
        #ApproveToken: DAOTokenApproveResult;
        #ApproveNFTTransfer: [?NFTApproveTokenResult];
        #ChangeActionDictionary: Result.Result<(), ()>;
        #Property: PropertyTypes.UpdateResultExternal;
        #ErrorPropertyBlob;
        #ErrorGovernanceBlob;
        #Governance: GovernanceResults;
    };

    public type GovernanceResults = {
        #Whitelist : FlagArrayResult;
        #RequiresTenantApproval:FlagArrayResult; 
    };

    public type FlagArrayResult = {
        sizeBefore: Nat;
        sizeAfter: Nat;
        argSize: Nat;
    };

    public type ExecutionOutcomes = {
        arg: ProposalAction;
        result: ExecutionResult;
        proposalId: ?Nat;
    }



}