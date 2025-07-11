export const icrc1IdlFactory = ({ IDL }) => IDL.Service({
  icrc1_balance_of: IDL.Func([IDL.Record({
    owner: IDL.Principal,
    subaccount: IDL.Opt(IDL.Vec(IDL.Nat8))
  })], [IDL.Nat], ['query']),

  icrc1_transfer: IDL.Func([IDL.Record({
    to: IDL.Record({ owner: IDL.Principal, subaccount: IDL.Opt(IDL.Vec(IDL.Nat8)) }),
    amount: IDL.Nat,
    fee: IDL.Opt(IDL.Nat),
    memo: IDL.Opt(IDL.Vec(IDL.Nat8)),
    created_at_time: IDL.Opt(IDL.Nat64),
    from_subaccount: IDL.Opt(IDL.Vec(IDL.Nat8))
  })], [IDL.Variant({
    Ok: IDL.Nat,
    Err: IDL.Variant({
      BadFee: IDL.Record({ expected_fee: IDL.Nat }),
      InsufficientFunds: IDL.Record({ balance: IDL.Nat }),
      TemporarilyUnavailable: IDL.Null,
      Duplicate: IDL.Record({ duplicate_of: IDL.Nat }),
      CreatedInFuture: IDL.Record({ ledger_time: IDL.Nat64 }),
      TooOld: IDL.Null,
      GenericError: IDL.Record({ error_code: IDL.Nat, message: IDL.Text })
    })
  })], []),

  icrc2_approve: IDL.Func([IDL.Record({
    spender: IDL.Record({ owner: IDL.Principal, subaccount: IDL.Opt(IDL.Vec(IDL.Nat8)) }),
    amount: IDL.Nat,
    expected_allowance: IDL.Opt(IDL.Nat),
    expires_at: IDL.Opt(IDL.Nat64),
    fee: IDL.Opt(IDL.Nat),
    memo: IDL.Opt(IDL.Vec(IDL.Nat8)),
    from_subaccount: IDL.Opt(IDL.Vec(IDL.Nat8)),
    created_at_time: IDL.Opt(IDL.Nat64)
  })], [IDL.Variant({
    Ok: IDL.Nat,
    Err: IDL.Variant({
      BadFee: IDL.Record({ expected_fee: IDL.Nat }),
      InsufficientFunds: IDL.Record({ balance: IDL.Nat }),
      AllowanceChanged: IDL.Record({ current_allowance: IDL.Nat }),
      Expired: IDL.Null,
      GenericError: IDL.Record({ error_code: IDL.Nat, message: IDL.Text })
    })
  })], []),

  // ✅ Optional: ICRC-2 allowance query
  icrc2_allowance: IDL.Func([IDL.Record({
    account: IDL.Record({ owner: IDL.Principal, subaccount: IDL.Opt(IDL.Vec(IDL.Nat8)) }),
    spender: IDL.Record({ owner: IDL.Principal, subaccount: IDL.Opt(IDL.Vec(IDL.Nat8)) })
  })], [IDL.Record({
    allowance: IDL.Nat,
    expires_at: IDL.Opt(IDL.Nat64)
  })], ['query'])
});

