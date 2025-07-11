export const idlFactory = ({ IDL }) => {
  const GetBlocksResult__1 = IDL.Rec();
  const Value = IDL.Rec();
  const BurnArg = IDL.Record({
    'token_id' : IDL.Nat,
    'memo' : IDL.Opt(IDL.Vec(IDL.Nat8)),
    'from_subaccount' : IDL.Opt(IDL.Vec(IDL.Nat8)),
    'created_at_time' : IDL.Opt(IDL.Nat64),
  });
  const TransferError = IDL.Variant({
    'GenericError' : IDL.Record({
      'message' : IDL.Text,
      'error_code' : IDL.Nat,
    }),
    'Duplicate' : IDL.Record({ 'duplicate_of' : IDL.Nat }),
    'NonExistingTokenId' : IDL.Null,
    'Unauthorized' : IDL.Null,
    'CreatedInFuture' : IDL.Record({ 'ledger_time' : IDL.Nat64 }),
    'InvalidRecipient' : IDL.Null,
    'GenericBatchError' : IDL.Record({
      'message' : IDL.Text,
      'error_code' : IDL.Nat,
    }),
    'TooOld' : IDL.Null,
  });
  const TransferResult = IDL.Variant({ 'Ok' : IDL.Nat, 'Err' : TransferError });
  const Subaccount = IDL.Vec(IDL.Nat8);
  const Account = IDL.Record({
    'owner' : IDL.Principal,
    'subaccount' : IDL.Opt(Subaccount),
  });
  const ApprovalInfo = IDL.Record({
    'memo' : IDL.Opt(IDL.Vec(IDL.Nat8)),
    'from_subaccount' : IDL.Opt(IDL.Vec(IDL.Nat8)),
    'created_at_time' : IDL.Nat64,
    'expires_at' : IDL.Opt(IDL.Nat64),
    'spender' : Account,
  });
  const AccountRecord = IDL.Record({
    'balance' : IDL.Nat,
    'owned_tokens' : IDL.Vec(IDL.Nat),
    'approvals' : IDL.Vec(ApprovalInfo),
  });
  Value.fill(
    IDL.Variant({
      'Int' : IDL.Int,
      'Map' : IDL.Vec(IDL.Tuple(IDL.Text, Value)),
      'Nat' : IDL.Nat,
      'Blob' : IDL.Vec(IDL.Nat8),
      'Text' : IDL.Text,
      'Array' : IDL.Vec(Value),
    })
  );
  const TokenRecord = IDL.Record({
    'owner' : Account,
    'metadata' : IDL.Vec(IDL.Tuple(IDL.Text, Value)),
    'approvals' : IDL.Vec(ApprovalInfo),
  });
  const ArgFlag = IDL.Variant({
    'RevokeCollection' : IDL.Null,
    'UpdateMetadata' : IDL.Null,
    'ApproveToken' : IDL.Null,
    'Burn' : IDL.Null,
    'Mint' : IDL.Null,
    'RevokeToken' : IDL.Null,
    'Transfer' : IDL.Null,
    'ApproveCollection' : IDL.Null,
    'TransferFrom' : IDL.Null,
  });
  const ValidationErrorFlag = IDL.Variant({
    'BaseError' : IDL.Null,
    'TransferError' : IDL.Null,
    'MintError' : IDL.Null,
    'LogicError' : IDL.Null,
    'RevokeTokenApprovalError' : IDL.Null,
    'Automic' : IDL.Null,
    'StandardError' : IDL.Null,
    'ApproveTokenError' : IDL.Null,
    'ApproveCollectionError' : IDL.Null,
    'RevokeCollectionApprovalError' : IDL.Null,
  });
  const RevokeCollectionApprovalArg = IDL.Record({
    'memo' : IDL.Opt(IDL.Vec(IDL.Nat8)),
    'from_subaccount' : IDL.Opt(IDL.Vec(IDL.Nat8)),
    'created_at_time' : IDL.Opt(IDL.Nat64),
    'spender' : IDL.Opt(Account),
  });
  const TokenMetadataArg = IDL.Record({
    'key' : IDL.Text,
    'token_id' : IDL.Nat,
    'value' : Value,
    'memo' : IDL.Opt(IDL.Vec(IDL.Nat8)),
    'from_subaccount' : IDL.Opt(IDL.Vec(IDL.Nat8)),
    'created_at_time' : IDL.Opt(IDL.Nat64),
  });
  const ApproveTokenArg = IDL.Record({
    'token_id' : IDL.Nat,
    'approval_info' : ApprovalInfo,
  });
  const MintArg = IDL.Record({
    'to' : Account,
    'memo' : IDL.Opt(IDL.Vec(IDL.Nat8)),
    'meta' : IDL.Vec(IDL.Tuple(IDL.Text, Value)),
    'from_subaccount' : IDL.Opt(IDL.Vec(IDL.Nat8)),
    'created_at_time' : IDL.Opt(IDL.Nat64),
  });
  const RevokeTokenApprovalArg = IDL.Record({
    'token_id' : IDL.Nat,
    'memo' : IDL.Opt(IDL.Vec(IDL.Nat8)),
    'from_subaccount' : IDL.Opt(IDL.Vec(IDL.Nat8)),
    'created_at_time' : IDL.Opt(IDL.Nat64),
    'spender' : IDL.Opt(Account),
  });
  const TransferArg = IDL.Record({
    'to' : Account,
    'token_id' : IDL.Nat,
    'memo' : IDL.Opt(IDL.Vec(IDL.Nat8)),
    'from_subaccount' : IDL.Opt(IDL.Vec(IDL.Nat8)),
    'created_at_time' : IDL.Opt(IDL.Nat64),
  });
  const ApproveCollectionArg = IDL.Record({ 'approval_info' : ApprovalInfo });
  const TransferFromArg = IDL.Record({
    'to' : Account,
    'spender_subaccount' : IDL.Opt(IDL.Vec(IDL.Nat8)),
    'token_id' : IDL.Nat,
    'from' : Account,
    'memo' : IDL.Opt(IDL.Vec(IDL.Nat8)),
    'created_at_time' : IDL.Opt(IDL.Nat64),
  });
  const Arg = IDL.Variant({
    'RevokeCollection' : RevokeCollectionApprovalArg,
    'UpdateMetadata' : TokenMetadataArg,
    'ApproveToken' : ApproveTokenArg,
    'Burn' : BurnArg,
    'Mint' : MintArg,
    'RevokeToken' : RevokeTokenApprovalArg,
    'Transfer' : TransferArg,
    'ApproveCollection' : ApproveCollectionArg,
    'TransferFrom' : TransferFromArg,
  });
  const BaseError = IDL.Variant({
    'GenericError' : IDL.Record({
      'message' : IDL.Text,
      'error_code' : IDL.Nat,
    }),
    'CreatedInFuture' : IDL.Record({ 'ledger_time' : IDL.Nat64 }),
    'GenericBatchError' : IDL.Record({
      'message' : IDL.Text,
      'error_code' : IDL.Nat,
    }),
    'TooOld' : IDL.Null,
  });
  const MintError = IDL.Variant({
    'GenericError' : IDL.Record({
      'message' : IDL.Text,
      'error_code' : IDL.Nat,
    }),
    'Duplicate' : IDL.Record({ 'duplicate_of' : IDL.Nat }),
    'NonExistingTokenId' : IDL.Null,
    'ExceedsMaxSupply' : IDL.Null,
    'Unauthorized' : IDL.Null,
    'CreatedInFuture' : IDL.Record({ 'ledger_time' : IDL.Nat64 }),
    'InvalidRecipient' : IDL.Null,
    'GenericBatchError' : IDL.Record({
      'message' : IDL.Text,
      'error_code' : IDL.Nat,
    }),
    'TooOld' : IDL.Null,
  });
  const RevokeTokenApprovalError = IDL.Variant({
    'GenericError' : IDL.Record({
      'message' : IDL.Text,
      'error_code' : IDL.Nat,
    }),
    'NonExistingTokenId' : IDL.Null,
    'Unauthorized' : IDL.Null,
    'CreatedInFuture' : IDL.Record({ 'ledger_time' : IDL.Nat64 }),
    'ApprovalDoesNotExist' : IDL.Null,
    'GenericBatchError' : IDL.Record({
      'message' : IDL.Text,
      'error_code' : IDL.Nat,
    }),
    'TooOld' : IDL.Null,
  });
  const StandardError = IDL.Variant({
    'GenericError' : IDL.Record({
      'message' : IDL.Text,
      'error_code' : IDL.Nat,
    }),
    'NonExistingTokenId' : IDL.Null,
    'Unauthorized' : IDL.Null,
    'CreatedInFuture' : IDL.Record({ 'ledger_time' : IDL.Nat64 }),
    'GenericBatchError' : IDL.Record({
      'message' : IDL.Text,
      'error_code' : IDL.Nat,
    }),
    'TooOld' : IDL.Null,
  });
  const ApproveTokenError = IDL.Variant({
    'GenericError' : IDL.Record({
      'message' : IDL.Text,
      'error_code' : IDL.Nat,
    }),
    'InvalidSpender' : IDL.Null,
    'NonExistingTokenId' : IDL.Null,
    'Unauthorized' : IDL.Null,
    'CreatedInFuture' : IDL.Record({ 'ledger_time' : IDL.Nat64 }),
    'GenericBatchError' : IDL.Record({
      'message' : IDL.Text,
      'error_code' : IDL.Nat,
    }),
    'TooOld' : IDL.Null,
  });
  const ApproveCollectionError = IDL.Variant({
    'GenericError' : IDL.Record({
      'message' : IDL.Text,
      'error_code' : IDL.Nat,
    }),
    'InvalidSpender' : IDL.Null,
    'CreatedInFuture' : IDL.Record({ 'ledger_time' : IDL.Nat64 }),
    'GenericBatchError' : IDL.Record({
      'message' : IDL.Text,
      'error_code' : IDL.Nat,
    }),
    'TooOld' : IDL.Null,
  });
  const RevokeCollectionApprovalError = IDL.Variant({
    'GenericError' : IDL.Record({
      'message' : IDL.Text,
      'error_code' : IDL.Nat,
    }),
    'CreatedInFuture' : IDL.Record({ 'ledger_time' : IDL.Nat64 }),
    'ApprovalDoesNotExist' : IDL.Null,
    'GenericBatchError' : IDL.Record({
      'message' : IDL.Text,
      'error_code' : IDL.Nat,
    }),
    'TooOld' : IDL.Null,
  });
  const ValidationError = IDL.Variant({
    'BaseError' : BaseError,
    'TransferError' : TransferError,
    'MintError' : MintError,
    'LogicError' : IDL.Null,
    'RevokeTokenApprovalError' : RevokeTokenApprovalError,
    'Automic' : IDL.Null,
    'StandardError' : StandardError,
    'ApproveTokenError' : ApproveTokenError,
    'ApproveCollectionError' : ApproveCollectionError,
    'RevokeCollectionApprovalError' : RevokeCollectionApprovalError,
  });
  const Error = IDL.Record({
    'id' : IDL.Nat,
    'arg' : Arg,
    'time' : IDL.Nat64,
    'error' : ValidationError,
    'caller' : IDL.Principal,
  });
  const SupportedStandards = IDL.Record({
    'url' : IDL.Text,
    'name' : IDL.Text,
  });
  const ApproveCollectionResult = IDL.Variant({
    'Ok' : IDL.Nat,
    'Err' : ApproveCollectionError,
  });
  const ApproveTokenResult = IDL.Variant({
    'Ok' : IDL.Nat,
    'Err' : ApproveTokenError,
  });
  const CollectionApproval = IDL.Record({
    'memo' : IDL.Opt(IDL.Vec(IDL.Nat8)),
    'from_subaccount' : IDL.Opt(IDL.Vec(IDL.Nat8)),
    'created_at_time' : IDL.Nat64,
    'expires_at' : IDL.Opt(IDL.Nat64),
    'spender' : Account,
  });
  const TokenApproval = IDL.Record({
    'token_id' : IDL.Nat,
    'approval_info' : ApprovalInfo,
  });
  const IsApprovedArg = IDL.Record({
    'token_id' : IDL.Nat,
    'from_subaccount' : IDL.Opt(IDL.Vec(IDL.Nat8)),
    'spender' : Account,
  });
  const RevokeCollectionApprovalResult = IDL.Variant({
    'Ok' : IDL.Nat,
    'Err' : RevokeCollectionApprovalError,
  });
  const RevokeTokenApprovalResponse = IDL.Variant({
    'Ok' : IDL.Nat,
    'Err' : RevokeTokenApprovalError,
  });
  const TransferFromError = IDL.Variant({
    'GenericError' : IDL.Record({
      'message' : IDL.Text,
      'error_code' : IDL.Nat,
    }),
    'Duplicate' : IDL.Record({ 'duplicate_of' : IDL.Nat }),
    'NonExistingTokenId' : IDL.Null,
    'Unauthorized' : IDL.Null,
    'CreatedInFuture' : IDL.Record({ 'ledger_time' : IDL.Nat64 }),
    'InvalidRecipient' : IDL.Null,
    'GenericBatchError' : IDL.Record({
      'message' : IDL.Text,
      'error_code' : IDL.Nat,
    }),
    'TooOld' : IDL.Null,
  });
  const TransferFromResult = IDL.Variant({
    'Ok' : IDL.Nat,
    'Err' : TransferFromError,
  });
  const GetArchivesArgs = IDL.Record({ 'from' : IDL.Opt(IDL.Principal) });
  const GetArchivesResult = IDL.Vec(
    IDL.Record({
      'end' : IDL.Nat,
      'canister_id' : IDL.Principal,
      'start' : IDL.Nat,
    })
  );
  const GetBlocksArgs = IDL.Vec(
    IDL.Record({ 'start' : IDL.Nat, 'length' : IDL.Nat })
  );
  GetBlocksResult__1.fill(
    IDL.Record({
      'log_length' : IDL.Nat,
      'blocks' : IDL.Vec(IDL.Record({ 'id' : IDL.Nat, 'block' : Value })),
      'archived_blocks' : IDL.Vec(
        IDL.Record({
          'args' : GetBlocksArgs,
          'callback' : IDL.Func(
              [GetBlocksArgs],
              [GetBlocksResult__1],
              ['query'],
            ),
        })
      ),
    })
  );
  const DataCertificate = IDL.Record({
    'certificate' : IDL.Vec(IDL.Nat8),
    'hash_tree' : IDL.Vec(IDL.Nat8),
  });
  const CreateFinancialsArg = IDL.Record({
    'purchasePrice' : IDL.Nat,
    'platformFee' : IDL.Nat,
    'reserve' : IDL.Nat,
    'currentValue' : IDL.Nat,
    'sqrFoot' : IDL.Nat,
    'monthlyRent' : IDL.Nat,
  });
  const Miscellaneous = IDL.Record({
    'description' : IDL.Text,
    'imageId' : IDL.Nat,
    'images' : IDL.Vec(IDL.Tuple(IDL.Nat, IDL.Text)),
  });
  const AdditionalDetails = IDL.Record({
    'schoolScore' : IDL.Nat,
    'affordability' : IDL.Nat,
    'floodZone' : IDL.Bool,
    'crimeScore' : IDL.Nat,
  });
  const PhysicalDetails = IDL.Record({
    'lastRenovation' : IDL.Nat,
    'beds' : IDL.Nat,
    'squareFootage' : IDL.Nat,
    'baths' : IDL.Nat,
    'yearBuilt' : IDL.Nat,
  });
  const LocationDetails = IDL.Record({
    'postcode' : IDL.Text,
    'name' : IDL.Text,
    'addressLine1' : IDL.Text,
    'addressLine2' : IDL.Text,
    'addressLine3' : IDL.Opt(IDL.Text),
    'addressLine4' : IDL.Opt(IDL.Text),
    'location' : IDL.Text,
  });
  const PropertyDetails = IDL.Record({
    'misc' : Miscellaneous,
    'additional' : AdditionalDetails,
    'physical' : PhysicalDetails,
    'location' : LocationDetails,
  });
  const MintResult = IDL.Variant({ 'Ok' : IDL.Nat, 'Err' : MintError });
  const TokenMetadataArgs = IDL.Record({
    'key' : IDL.Text,
    'token_id' : IDL.Nat,
    'value' : Value,
    'memo' : IDL.Opt(IDL.Vec(IDL.Nat8)),
    'from_subaccount' : IDL.Opt(IDL.Vec(IDL.Nat8)),
    'created_at_time' : IDL.Opt(IDL.Nat64),
  });
  const TokenMetadataResult = IDL.Variant({
    'Ok' : IDL.Nat,
    'Err' : StandardError,
  });
  return IDL.Service({
    'burnNFT' : IDL.Func(
        [IDL.Vec(BurnArg)],
        [IDL.Vec(IDL.Opt(TransferResult))],
        [],
      ),
    'clearState' : IDL.Func([], [], []),
    'debug_get_account' : IDL.Func(
        [Account],
        [IDL.Opt(AccountRecord)],
        ['query'],
      ),
    'debug_get_token' : IDL.Func([IDL.Nat], [IDL.Opt(TokenRecord)], ['query']),
    'exportState' : IDL.Func(
        [],
        [
          IDL.Vec(IDL.Tuple(IDL.Nat, TokenRecord)),
          IDL.Vec(IDL.Tuple(Account, AccountRecord)),
          IDL.Vec(IDL.Tuple(IDL.Text, Value)),
        ],
        [],
      ),
    'getAccountRecord' : IDL.Func(
        [Account],
        [IDL.Opt(AccountRecord)],
        ['query'],
      ),
    'getAllAccountRecords' : IDL.Func(
        [],
        [IDL.Vec(IDL.Tuple(Account, AccountRecord))],
        ['query'],
      ),
    'getErrors' : IDL.Func(
        [
          IDL.Opt(IDL.Nat),
          IDL.Opt(IDL.Nat),
          IDL.Opt(ArgFlag),
          IDL.Opt(ValidationErrorFlag),
        ],
        [IDL.Vec(Error)],
        ['query'],
      ),
    'getTokenRecord' : IDL.Func([IDL.Nat], [IDL.Opt(TokenRecord)], ['query']),
    'get_all_tokens' : IDL.Func(
        [],
        [IDL.Vec(IDL.Tuple(IDL.Nat, TokenRecord))],
        ['query'],
      ),
    'icrc10_supported_standards' : IDL.Func(
        [],
        [IDL.Vec(SupportedStandards)],
        ['query'],
      ),
    'icrc37_approve_collection' : IDL.Func(
        [IDL.Vec(ApproveCollectionArg)],
        [IDL.Vec(IDL.Opt(ApproveCollectionResult))],
        [],
      ),
    'icrc37_approve_tokens' : IDL.Func(
        [IDL.Vec(ApproveTokenArg)],
        [IDL.Vec(IDL.Opt(ApproveTokenResult))],
        [],
      ),
    'icrc37_get_collection_approvals' : IDL.Func(
        [Account, IDL.Opt(CollectionApproval), IDL.Opt(IDL.Nat)],
        [IDL.Vec(CollectionApproval)],
        ['query'],
      ),
    'icrc37_get_token_approvals' : IDL.Func(
        [IDL.Nat, IDL.Opt(TokenApproval), IDL.Opt(IDL.Nat)],
        [IDL.Vec(TokenApproval)],
        ['query'],
      ),
    'icrc37_is_approved' : IDL.Func(
        [IDL.Vec(IsApprovedArg)],
        [IDL.Vec(IDL.Bool)],
        ['query'],
      ),
    'icrc37_max_approvals_per_token_or_collection' : IDL.Func(
        [],
        [IDL.Opt(IDL.Nat)],
        ['query'],
      ),
    'icrc37_max_revoke_approvals' : IDL.Func([], [IDL.Opt(IDL.Nat)], ['query']),
    'icrc37_revoke_collection_approvals' : IDL.Func(
        [IDL.Vec(RevokeCollectionApprovalArg)],
        [IDL.Vec(IDL.Opt(RevokeCollectionApprovalResult))],
        [],
      ),
    'icrc37_revoke_token_approvals' : IDL.Func(
        [IDL.Vec(RevokeTokenApprovalArg)],
        [IDL.Vec(IDL.Opt(RevokeTokenApprovalResponse))],
        [],
      ),
    'icrc37_transfer_from' : IDL.Func(
        [IDL.Vec(TransferFromArg)],
        [IDL.Vec(IDL.Opt(TransferFromResult))],
        [],
      ),
    'icrc3_get_archives' : IDL.Func(
        [GetArchivesArgs],
        [IDL.Vec(GetArchivesResult)],
        ['query'],
      ),
    'icrc3_get_blocks' : IDL.Func(
        [GetBlocksArgs],
        [GetBlocksResult__1],
        ['query'],
      ),
    'icrc3_get_tip_certificate' : IDL.Func(
        [],
        [IDL.Opt(DataCertificate)],
        ['query'],
      ),
    'icrc3_supported_block_types' : IDL.Func(
        [],
        [IDL.Vec(IDL.Record({ 'url' : IDL.Text, 'block_type' : IDL.Text }))],
        ['query'],
      ),
    'icrc7_atomic_batch_transfers' : IDL.Func(
        [],
        [IDL.Opt(IDL.Bool)],
        ['query'],
      ),
    'icrc7_balance_of' : IDL.Func(
        [IDL.Vec(Account)],
        [IDL.Vec(IDL.Nat)],
        ['query'],
      ),
    'icrc7_collection_metadata' : IDL.Func(
        [],
        [IDL.Vec(IDL.Tuple(IDL.Text, Value))],
        ['query'],
      ),
    'icrc7_default_take_value' : IDL.Func([], [IDL.Opt(IDL.Nat)], ['query']),
    'icrc7_description' : IDL.Func([], [IDL.Opt(IDL.Text)], ['query']),
    'icrc7_logo' : IDL.Func([], [IDL.Opt(IDL.Text)], ['query']),
    'icrc7_max_memo_size' : IDL.Func([], [IDL.Opt(IDL.Nat)], ['query']),
    'icrc7_max_query_batch_size' : IDL.Func([], [IDL.Opt(IDL.Nat)], ['query']),
    'icrc7_max_take_value' : IDL.Func([], [IDL.Opt(IDL.Nat)], ['query']),
    'icrc7_max_update_batch_size' : IDL.Func([], [IDL.Opt(IDL.Nat)], ['query']),
    'icrc7_name' : IDL.Func([], [IDL.Text], ['query']),
    'icrc7_owner_of' : IDL.Func(
        [IDL.Vec(IDL.Nat)],
        [IDL.Vec(IDL.Opt(Account))],
        ['query'],
      ),
    'icrc7_permitted_drift' : IDL.Func([], [IDL.Opt(IDL.Nat)], ['query']),
    'icrc7_supply_cap' : IDL.Func([], [IDL.Opt(IDL.Nat)], ['query']),
    'icrc7_symbol' : IDL.Func([], [IDL.Text], ['query']),
    'icrc7_token_metadata' : IDL.Func(
        [IDL.Vec(IDL.Nat)],
        [IDL.Vec(IDL.Opt(IDL.Vec(IDL.Tuple(IDL.Text, Value))))],
        ['query'],
      ),
    'icrc7_tokens' : IDL.Func(
        [IDL.Opt(IDL.Nat), IDL.Opt(IDL.Nat)],
        [IDL.Vec(IDL.Nat)],
        ['query'],
      ),
    'icrc7_tokens_of' : IDL.Func(
        [Account, IDL.Opt(IDL.Nat), IDL.Opt(IDL.Nat)],
        [IDL.Vec(IDL.Nat)],
        ['query'],
      ),
    'icrc7_total_supply' : IDL.Func([], [IDL.Nat], ['query']),
    'icrc7_transfer' : IDL.Func(
        [IDL.Vec(TransferArg)],
        [IDL.Vec(IDL.Opt(TransferResult))],
        [],
      ),
    'icrc7_tx_window' : IDL.Func([], [IDL.Opt(IDL.Nat)], ['query']),
    'initiateMetadata' : IDL.Func([IDL.Nat], [], []),
    'initiateProperty' : IDL.Func(
        [],
        [CreateFinancialsArg, PropertyDetails],
        ['query'],
      ),
    'mintNFT' : IDL.Func(
        [IDL.Vec(MintArg)],
        [IDL.Vec(IDL.Opt(MintResult))],
        [],
      ),
    'removeTokenMetadata' : IDL.Func([IDL.Nat, IDL.Text], [], []),
    'runTests' : IDL.Func([IDL.Opt(ArgFlag)], [], []),
    'updateCollectionMetadata' : IDL.Func(
        [IDL.Vec(IDL.Tuple(IDL.Text, Value))],
        [],
        [],
      ),
    'updateTokenMetadata' : IDL.Func(
        [IDL.Vec(TokenMetadataArgs)],
        [IDL.Vec(IDL.Opt(TokenMetadataResult))],
        [],
      ),
    'verifyApproveCollection' : IDL.Func(
        [IDL.Vec(ApproveCollectionArg)],
        [IDL.Vec(IDL.Opt(ApproveCollectionResult))],
        [],
      ),
    'verifyApproveTokenRecords' : IDL.Func(
        [IDL.Vec(ApproveTokenArg)],
        [IDL.Vec(IDL.Opt(ApproveTokenResult))],
        [],
      ),
    'verifyRevokeCollectionApproval' : IDL.Func(
        [IDL.Vec(RevokeCollectionApprovalArg)],
        [IDL.Vec(IDL.Opt(RevokeCollectionApprovalResult))],
        [],
      ),
    'verifyRevokeTokenApprovals' : IDL.Func(
        [IDL.Vec(RevokeTokenApprovalArg)],
        [IDL.Vec(IDL.Opt(RevokeTokenApprovalResponse))],
        [],
      ),
    'verifyTokenMetadata' : IDL.Func(
        [IDL.Vec(TokenMetadataArgs)],
        [IDL.Vec(IDL.Opt(TokenMetadataResult))],
        [],
      ),
    'verifyTransferFrom' : IDL.Func(
        [IDL.Vec(TransferFromArg)],
        [IDL.Vec(IDL.Opt(TransferFromResult))],
        [],
      ),
    'verify_icrc7_Burn' : IDL.Func(
        [IDL.Vec(BurnArg)],
        [IDL.Vec(IDL.Opt(TransferResult))],
        [],
      ),
    'verify_icrc7_Mint' : IDL.Func(
        [IDL.Vec(MintArg)],
        [IDL.Vec(IDL.Opt(MintResult))],
        [],
      ),
    'verify_icrc7_transfer' : IDL.Func(
        [IDL.Vec(TransferArg)],
        [IDL.Vec(IDL.Opt(TransferResult))],
        [],
      ),
  });
};
export const init = ({ IDL }) => { return []; };
