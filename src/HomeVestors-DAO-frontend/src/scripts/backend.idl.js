export const idlFactory = ({ IDL }) => {
  const Invoice = IDL.Rec();
  const Property = IDL.Rec();
  const What = IDL.Rec();
  const ContractLength = IDL.Variant({
    'Rolling' : IDL.Null,
    'SixMonths' : IDL.Null,
    'Annual' : IDL.Null,
  });
  const TenantCArg = IDL.Record({
    'principal' : IDL.Opt(IDL.Principal),
    'leadTenant' : IDL.Text,
    'otherTenants' : IDL.Vec(IDL.Text),
    'deposit' : IDL.Nat,
    'contractLength' : ContractLength,
    'monthlyRent' : IDL.Nat,
    'leaseStartDate' : IDL.Int,
  });
  const AcceptedCryptos = IDL.Variant({
    'HGB' : IDL.Null,
    'ICP' : IDL.Null,
    'CKUSDC' : IDL.Null,
  });
  const PaymentMethod = IDL.Variant({
    'Cash' : IDL.Null,
    'BankTransfer' : IDL.Null,
    'Crypto' : IDL.Record({ 'cryptoType' : AcceptedCryptos }),
    'Other' : IDL.Record({ 'description' : IDL.Opt(IDL.Text) }),
  });
  const Payment = IDL.Record({
    'id' : IDL.Nat,
    'method' : PaymentMethod,
    'date' : IDL.Int,
    'amount' : IDL.Nat,
  });
  const TenantUArg = IDL.Record({
    'principal' : IDL.Opt(IDL.Principal),
    'paymentHistory' : IDL.Opt(IDL.Vec(Payment)),
    'leadTenant' : IDL.Opt(IDL.Text),
    'otherTenants' : IDL.Opt(IDL.Vec(IDL.Text)),
    'deposit' : IDL.Opt(IDL.Nat),
    'contractLength' : IDL.Opt(ContractLength),
    'monthlyRent' : IDL.Opt(IDL.Nat),
    'leaseStartDate' : IDL.Opt(IDL.Int),
  });
  const Actions_11 = IDL.Variant({
    'Delete' : IDL.Vec(IDL.Int),
    'Create' : IDL.Vec(TenantCArg),
    'Update' : IDL.Tuple(TenantUArg, IDL.Vec(IDL.Int)),
  });
  const InspectionRecordCArg = IDL.Record({
    'date' : IDL.Opt(IDL.Int),
    'inspectorName' : IDL.Text,
    'findings' : IDL.Text,
    'actionRequired' : IDL.Opt(IDL.Text),
    'followUpDate' : IDL.Opt(IDL.Int),
  });
  const InspectionRecordUArg = IDL.Record({
    'date' : IDL.Opt(IDL.Int),
    'inspectorName' : IDL.Opt(IDL.Text),
    'findings' : IDL.Opt(IDL.Text),
    'actionRequired' : IDL.Opt(IDL.Text),
    'followUpDate' : IDL.Opt(IDL.Int),
  });
  const Actions_3 = IDL.Variant({
    'Delete' : IDL.Vec(IDL.Int),
    'Create' : IDL.Vec(InspectionRecordCArg),
    'Update' : IDL.Tuple(InspectionRecordUArg, IDL.Vec(IDL.Int)),
  });
  const Account = IDL.Record({
    'owner' : IDL.Principal,
    'subaccount' : IDL.Opt(IDL.Vec(IDL.Nat8)),
  });
  const ExpenseCategory = IDL.Variant({
    'Legal' : IDL.Null,
    'CapitalImprovements' : IDL.Null,
    'Insurance' : IDL.Null,
    'ManagementFees' : IDL.Null,
    'OtherExpense' : IDL.Text,
    'Repairs' : IDL.Null,
    'Maintenance' : IDL.Null,
    'Utilities' : IDL.Null,
  });
  const IncomeCategory = IDL.Variant({
    'LateFee' : IDL.Null,
    'Deposit' : IDL.Null,
    'Rent' : IDL.Null,
    'OtherIncome' : IDL.Text,
    'ServiceCharge' : IDL.Null,
  });
  const InvoiceDirection = IDL.Variant({
    'ToInvestors' : IDL.Record({ 'proposalId' : IDL.Nat }),
    'Outgoing' : IDL.Record({
      'to' : Account,
      'accountReference' : IDL.Text,
      'category' : ExpenseCategory,
      'proposalId' : IDL.Nat,
    }),
    'Incoming' : IDL.Record({
      'accountReference' : IDL.Text,
      'from' : Account,
      'category' : IncomeCategory,
    }),
  });
  const PeriodicRecurrence = IDL.Variant({
    'BiAnnually' : IDL.Null,
    'Weekly' : IDL.Null,
    'None' : IDL.Null,
    'Quarterly' : IDL.Null,
    'Daily' : IDL.Null,
    'Custom' : IDL.Record({ 'interval' : IDL.Nat }),
    'Monthly' : IDL.Null,
    'Annually' : IDL.Null,
  });
  const RecurrenceType = IDL.Record({
    'endDate' : IDL.Opt(IDL.Int),
    'period' : PeriodicRecurrence,
    'count' : IDL.Nat,
    'previousInvoiceIds' : IDL.Vec(IDL.Nat),
  });
  const InvoiceCArg = IDL.Record({
    'title' : IDL.Text,
    'direction' : InvoiceDirection,
    'paymentMethod' : IDL.Opt(AcceptedCryptos),
    'dueDate' : IDL.Int,
    'description' : IDL.Text,
    'recurrence' : RecurrenceType,
    'amount' : IDL.Nat,
  });
  const InvoiceUArg = IDL.Record({
    'title' : IDL.Opt(IDL.Text),
    'direction' : IDL.Opt(InvoiceDirection),
    'paymentMethod' : IDL.Opt(AcceptedCryptos),
    'dueDate' : IDL.Opt(IDL.Int),
    'description' : IDL.Opt(IDL.Text),
    'recurrence' : IDL.Opt(RecurrenceType),
    'preApprovedByAdmin' : IDL.Opt(IDL.Bool),
    'amount' : IDL.Opt(IDL.Nat),
    'process' : IDL.Bool,
  });
  const Actions_5 = IDL.Variant({
    'Delete' : IDL.Vec(IDL.Int),
    'Create' : IDL.Vec(InvoiceCArg),
    'Update' : IDL.Tuple(InvoiceUArg, IDL.Vec(IDL.Int)),
  });
  const PaymentFrequency = IDL.Variant({
    'Weekly' : IDL.Null,
    'Monthly' : IDL.Null,
    'Annually' : IDL.Null,
  });
  const InsurancePolicyCArg = IDL.Record({
    'contactInfo' : IDL.Text,
    'paymentFrequency' : PaymentFrequency,
    'provider' : IDL.Text,
    'endDate' : IDL.Opt(IDL.Int),
    'premium' : IDL.Nat,
    'nextPaymentDate' : IDL.Int,
    'policyNumber' : IDL.Text,
    'startDate' : IDL.Int,
  });
  const InsurancePolicyUArg = IDL.Record({
    'contactInfo' : IDL.Opt(IDL.Text),
    'paymentFrequency' : IDL.Opt(PaymentFrequency),
    'provider' : IDL.Opt(IDL.Text),
    'endDate' : IDL.Opt(IDL.Int),
    'premium' : IDL.Opt(IDL.Nat),
    'nextPaymentDate' : IDL.Opt(IDL.Int),
    'policyNumber' : IDL.Opt(IDL.Text),
    'startDate' : IDL.Opt(IDL.Int),
  });
  const Actions_4 = IDL.Variant({
    'Delete' : IDL.Vec(IDL.Int),
    'Create' : IDL.Vec(InsurancePolicyCArg),
    'Update' : IDL.Tuple(InsurancePolicyUArg, IDL.Vec(IDL.Int)),
  });
  const Actions_2 = IDL.Variant({
    'Delete' : IDL.Vec(IDL.Int),
    'Create' : IDL.Vec(IDL.Text),
    'Update' : IDL.Tuple(IDL.Text, IDL.Vec(IDL.Int)),
  });
  const NoteCArg = IDL.Record({
    'title' : IDL.Text,
    'content' : IDL.Text,
    'date' : IDL.Opt(IDL.Int),
  });
  const NoteUArg = IDL.Record({
    'title' : IDL.Opt(IDL.Text),
    'content' : IDL.Opt(IDL.Text),
    'date' : IDL.Opt(IDL.Int),
  });
  const Actions_10 = IDL.Variant({
    'Delete' : IDL.Vec(IDL.Int),
    'Create' : IDL.Vec(NoteCArg),
    'Update' : IDL.Tuple(NoteUArg, IDL.Vec(IDL.Int)),
  });
  const DocumentType = IDL.Variant({
    'AST' : IDL.Null,
    'EPC' : IDL.Null,
    'EICR' : IDL.Null,
    'Other' : IDL.Text,
  });
  const DocumentCArg = IDL.Record({
    'url' : IDL.Text,
    'title' : IDL.Text,
    'documentType' : DocumentType,
    'description' : IDL.Text,
  });
  const DocumentUArg = IDL.Record({
    'url' : IDL.Opt(IDL.Text),
    'title' : IDL.Opt(IDL.Text),
    'documentType' : IDL.Opt(DocumentType),
    'description' : IDL.Opt(IDL.Text),
  });
  const Actions = IDL.Variant({
    'Delete' : IDL.Vec(IDL.Int),
    'Create' : IDL.Vec(DocumentCArg),
    'Update' : IDL.Tuple(DocumentUArg, IDL.Vec(IDL.Int)),
  });
  const ValuationMethod = IDL.Variant({
    'Online' : IDL.Null,
    'Appraisal' : IDL.Null,
    'MarketComparison' : IDL.Null,
  });
  const ValuationRecordCArg = IDL.Record({
    'method' : ValuationMethod,
    'value' : IDL.Nat,
  });
  const ValuationRecordUArg = IDL.Record({
    'method' : IDL.Opt(ValuationMethod),
    'value' : IDL.Opt(IDL.Nat),
  });
  const Actions_12 = IDL.Variant({
    'Delete' : IDL.Vec(IDL.Int),
    'Create' : IDL.Vec(ValuationRecordCArg),
    'Update' : IDL.Tuple(ValuationRecordUArg, IDL.Vec(IDL.Int)),
  });
  const MaintenanceStatus = IDL.Variant({
    'InProgress' : IDL.Null,
    'Completed' : IDL.Null,
    'Pending' : IDL.Null,
  });
  const MaintenanceRecordCArg = IDL.Record({
    'status' : MaintenanceStatus,
    'paymentMethod' : IDL.Opt(PaymentMethod),
    'cost' : IDL.Opt(IDL.Float64),
    'dateCompleted' : IDL.Opt(IDL.Int),
    'description' : IDL.Text,
    'dateReported' : IDL.Opt(IDL.Int),
    'contractor' : IDL.Opt(IDL.Text),
  });
  const MaintenanceRecordUArg = IDL.Record({
    'status' : IDL.Opt(MaintenanceStatus),
    'paymentMethod' : IDL.Opt(PaymentMethod),
    'cost' : IDL.Opt(IDL.Float64),
    'dateCompleted' : IDL.Opt(IDL.Int),
    'description' : IDL.Opt(IDL.Text),
    'dateReported' : IDL.Opt(IDL.Int),
    'contractor' : IDL.Opt(IDL.Text),
  });
  const Actions_6 = IDL.Variant({
    'Delete' : IDL.Vec(IDL.Int),
    'Create' : IDL.Vec(MaintenanceRecordCArg),
    'Update' : IDL.Tuple(MaintenanceRecordUArg, IDL.Vec(IDL.Int)),
  });
  const FinancialsArg = IDL.Record({ 'currentValue' : IDL.Nat });
  const AdditionalDetailsUArg = IDL.Record({
    'schoolScore' : IDL.Opt(IDL.Nat),
    'affordability' : IDL.Opt(IDL.Nat),
    'floodZone' : IDL.Opt(IDL.Bool),
    'crimeScore' : IDL.Opt(IDL.Nat),
  });
  const VoteArgs = IDL.Record({ 'vote' : IDL.Bool, 'proposalId' : IDL.Nat });
  const ImplementationCategory = IDL.Variant({
    'Day' : IDL.Null,
    'BiWeek' : IDL.Null,
    'Week' : IDL.Null,
    'FourDays' : IDL.Null,
    'Month' : IDL.Null,
    'Other' : IDL.Int,
    'Quick' : IDL.Null,
  });
  const ProposalCategoryFlag = IDL.Variant({
    'Valuation' : IDL.Null,
    'Invoice' : IDL.Record({ 'invoiceId' : IDL.Nat }),
    'Rent' : IDL.Null,
    'Maintenance' : IDL.Null,
    'Operations' : IDL.Null,
    'Tenancy' : IDL.Null,
    'Admin' : IDL.Null,
    'Other' : IDL.Text,
  });
  const ProposalCArg = IDL.Record({
    'title' : IDL.Text,
    'startAt' : IDL.Int,
    'implementation' : ImplementationCategory,
    'description' : IDL.Text,
    'actions' : IDL.Vec(What),
    'category' : ProposalCategoryFlag,
  });
  const ProposalCategory = IDL.Variant({
    'Valuation' : IDL.Null,
    'Invoice' : IDL.Record({ 'invoiceId' : IDL.Nat }),
    'Rent' : IDL.Record({ 'tenantApproved' : IDL.Bool }),
    'Maintenance' : IDL.Record({ 'tenantApproved' : IDL.Bool }),
    'Operations' : IDL.Null,
    'Tenancy' : IDL.Record({ 'tenantApproved' : IDL.Bool }),
    'Admin' : IDL.Null,
    'Other' : IDL.Text,
  });
  const ProposalUArg = IDL.Record({
    'title' : IDL.Opt(IDL.Text),
    'startAt' : IDL.Opt(IDL.Int),
    'implementation' : IDL.Opt(ImplementationCategory),
    'description' : IDL.Opt(IDL.Text),
    'actions' : IDL.Opt(IDL.Vec(What)),
    'category' : IDL.Opt(ProposalCategory),
  });
  const Actions_1 = IDL.Variant({
    'Delete' : IDL.Vec(IDL.Int),
    'Create' : IDL.Vec(ProposalCArg),
    'Update' : IDL.Tuple(ProposalUArg, IDL.Vec(IDL.Int)),
  });
  const PhysicalDetailsUArg = IDL.Record({
    'lastRenovation' : IDL.Opt(IDL.Nat),
    'beds' : IDL.Opt(IDL.Nat),
    'squareFootage' : IDL.Opt(IDL.Nat),
    'baths' : IDL.Opt(IDL.Nat),
    'yearBuilt' : IDL.Opt(IDL.Nat),
  });
  const BidArg = IDL.Record({
    'listingId' : IDL.Nat,
    'buyer_subaccount' : IDL.Opt(IDL.Vec(IDL.Nat8)),
    'bidAmount' : IDL.Nat,
  });
  const LaunchCArg = IDL.Record({
    'quoteAsset' : IDL.Opt(AcceptedCryptos),
    'maxListed' : IDL.Opt(IDL.Nat),
    'transferType' : IDL.Variant({
      'Transfer' : IDL.Null,
      'TransferFrom' : IDL.Null,
    }),
    'seller_subaccount' : IDL.Opt(IDL.Vec(IDL.Nat8)),
    'from_subaccount' : IDL.Opt(IDL.Vec(IDL.Nat8)),
    'price' : IDL.Nat,
    'endsAt' : IDL.Opt(IDL.Int),
  });
  const LaunchUArg = IDL.Record({
    'quoteAsset' : IDL.Opt(AcceptedCryptos),
    'price' : IDL.Opt(IDL.Nat),
    'endsAt' : IDL.Opt(IDL.Int),
  });
  const Actions_9 = IDL.Variant({
    'Delete' : IDL.Vec(IDL.Int),
    'Create' : IDL.Vec(LaunchCArg),
    'Update' : IDL.Tuple(LaunchUArg, IDL.Vec(IDL.Int)),
  });
  const AuctionCArg = IDL.Record({
    'startTime' : IDL.Int,
    'quoteAsset' : IDL.Opt(AcceptedCryptos),
    'startingPrice' : IDL.Nat,
    'tokenId' : IDL.Nat,
    'reservePrice' : IDL.Opt(IDL.Nat),
    'buyNowPrice' : IDL.Opt(IDL.Nat),
    'seller_subaccount' : IDL.Opt(IDL.Vec(IDL.Nat8)),
    'endsAt' : IDL.Int,
  });
  const AuctionUArg = IDL.Record({
    'startTime' : IDL.Opt(IDL.Int),
    'quoteAsset' : IDL.Opt(AcceptedCryptos),
    'startingPrice' : IDL.Opt(IDL.Nat),
    'reservePrice' : IDL.Opt(IDL.Nat),
    'listingId' : IDL.Nat,
    'buyNowPrice' : IDL.Opt(IDL.Nat),
    'endsAt' : IDL.Opt(IDL.Int),
  });
  const Actions_7 = IDL.Variant({
    'Delete' : IDL.Vec(IDL.Int),
    'Create' : IDL.Vec(AuctionCArg),
    'Update' : IDL.Tuple(AuctionUArg, IDL.Vec(IDL.Int)),
  });
  const FixedPriceCArg = IDL.Record({
    'quoteAsset' : IDL.Opt(AcceptedCryptos),
    'tokenId' : IDL.Nat,
    'expiresAt' : IDL.Opt(IDL.Int),
    'seller_subaccount' : IDL.Opt(IDL.Vec(IDL.Nat8)),
    'price' : IDL.Nat,
  });
  const FixedPriceUArg = IDL.Record({
    'quoteAsset' : IDL.Opt(AcceptedCryptos),
    'expiresAt' : IDL.Opt(IDL.Int),
    'listingId' : IDL.Nat,
    'price' : IDL.Opt(IDL.Nat),
  });
  const Actions_8 = IDL.Variant({
    'Delete' : IDL.Vec(IDL.Int),
    'Create' : IDL.Vec(FixedPriceCArg),
    'Update' : IDL.Tuple(FixedPriceUArg, IDL.Vec(IDL.Int)),
  });
  What.fill(
    IDL.Variant({
      'Tenant' : Actions_11,
      'Inspection' : Actions_3,
      'Invoice' : Actions_5,
      'Insurance' : Actions_4,
      'Images' : Actions_2,
      'Note' : Actions_10,
      'Description' : IDL.Text,
      'Document' : Actions,
      'Valuations' : Actions_12,
      'Maintenance' : Actions_6,
      'MonthlyRent' : IDL.Nat,
      'Financials' : FinancialsArg,
      'AdditionalDetails' : AdditionalDetailsUArg,
      'Governance' : IDL.Variant({ 'Vote' : VoteArgs, 'Proposal' : Actions_1 }),
      'PhysicalDetails' : PhysicalDetailsUArg,
      'NftMarketplace' : IDL.Variant({
        'Bid' : BidArg,
        'Launch' : Actions_9,
        'Auction' : Actions_7,
        'FixedPrice' : Actions_8,
      }),
    })
  );
  const WhatWithPropertyId = IDL.Record({
    'what' : What,
    'propertyId' : IDL.Nat,
  });
  const Reason = IDL.Variant({
    'AlreadyVoted' : IDL.Null,
    'JSONParseError' : IDL.Null,
    'CannotBeSetInThePast' : IDL.Null,
    'FailedToDecodeResponseBody' : IDL.Null,
    'Anonymous' : IDL.Null,
    'InvalidInput' : IDL.Null,
    'DataMismatch' : IDL.Null,
    'CannotBeSetInTheFuture' : IDL.Null,
    'InvalidRecipient' : IDL.Null,
    'BuyerAndSellerCannotMatch' : IDL.Null,
    'CannotBeNull' : IDL.Null,
    'CannotBeZero' : IDL.Null,
    'EmptyString' : IDL.Null,
    'OutOfRange' : IDL.Null,
    'NonExistentProposal' : IDL.Null,
    'InaccurateData' : IDL.Null,
  });
  const GenericTransferError = IDL.Variant({
    'GenericError' : IDL.Record({
      'message' : IDL.Text,
      'error_code' : IDL.Nat,
    }),
    'TemporarilyUnavailable' : IDL.Null,
    'InsufficientAllowance' : IDL.Record({ 'allowance' : IDL.Nat }),
    'BadBurn' : IDL.Record({ 'min_burn_amount' : IDL.Nat }),
    'Duplicate' : IDL.Record({ 'duplicate_of' : IDL.Nat }),
    'NonExistingTokenId' : IDL.Null,
    'BadFee' : IDL.Record({ 'expected_fee' : IDL.Nat }),
    'Unauthorized' : IDL.Null,
    'CreatedInFuture' : IDL.Record({ 'ledger_time' : IDL.Nat64 }),
    'InvalidRecipient' : IDL.Null,
    'GenericBatchError' : IDL.Record({
      'message' : IDL.Text,
      'error_code' : IDL.Nat,
    }),
    'TooOld' : IDL.Null,
    'InsufficientFunds' : IDL.Record({ 'balance' : IDL.Nat }),
  });
  const UpdateError = IDL.Variant({
    'GenericError' : IDL.Null,
    'InvalidElementId' : IDL.Null,
    'InsufficientBid' : IDL.Record({ 'minimum_bid' : IDL.Nat }),
    'ImmutableLiveAuction' : IDL.Null,
    'AsyncIdLost' : IDL.Null,
    'InvalidPropertyId' : IDL.Null,
    'InvalidData' : IDL.Record({ 'field' : IDL.Text, 'reason' : Reason }),
    'Unauthorized' : IDL.Null,
    'InvalidType' : IDL.Null,
    'Transfer' : IDL.Opt(GenericTransferError),
    'ListingExpired' : IDL.Null,
    'OverWritingData' : IDL.Null,
  });
  const UpdateResultNat = IDL.Variant({
    'Ok' : IDL.Nat,
    'Err' : IDL.Vec(IDL.Tuple(IDL.Opt(IDL.Nat), UpdateError)),
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
  const MintResult = IDL.Variant({ 'Ok' : IDL.Nat, 'Err' : MintError });
  const Launch = IDL.Record({
    'id' : IDL.Nat,
    'quoteAsset' : AcceptedCryptos,
    'listIds' : IDL.Vec(IDL.Nat),
    'maxListed' : IDL.Nat,
    'tokenIds' : IDL.Vec(IDL.Nat),
    'listedAt' : IDL.Int,
    'seller' : Account,
    'caller' : IDL.Principal,
    'price' : IDL.Nat,
    'endsAt' : IDL.Opt(IDL.Int),
  });
  const Bid = IDL.Record({
    'bidAmount' : IDL.Nat,
    'bidTime' : IDL.Int,
    'buyer' : Account,
  });
  const SoldFixedPrice = IDL.Record({
    'id' : IDL.Nat,
    'bid' : Bid,
    'quoteAsset' : AcceptedCryptos,
    'tokenId' : IDL.Nat,
    'expiresAt' : IDL.Opt(IDL.Int),
    'royaltyBps' : IDL.Opt(IDL.Nat),
    'listedAt' : IDL.Int,
    'seller' : Account,
    'price' : IDL.Nat,
  });
  const GenericTransferResult = IDL.Variant({
    'Ok' : IDL.Nat,
    'Err' : GenericTransferError,
  });
  const Ref = IDL.Record({
    'id' : IDL.Nat,
    'to' : Account,
    'attempted_at' : IDL.Int,
    'result' : GenericTransferResult,
    'asset' : AcceptedCryptos,
    'from' : Account,
    'amount' : IDL.Nat,
  });
  const Refund = IDL.Variant({ 'Ok' : Ref, 'Err' : Ref });
  const SoldAuction = IDL.Record({
    'id' : IDL.Nat,
    'startTime' : IDL.Int,
    'quoteAsset' : AcceptedCryptos,
    'startingPrice' : IDL.Nat,
    'tokenId' : IDL.Nat,
    'reservePrice' : IDL.Opt(IDL.Nat),
    'royaltyBps' : IDL.Opt(IDL.Nat),
    'listedAt' : IDL.Int,
    'buyNowPrice' : IDL.Opt(IDL.Nat),
    'auctionEndTime' : IDL.Int,
    'seller' : Account,
    'highestBid' : IDL.Opt(Bid),
    'soldFor' : IDL.Nat,
    'buyer' : Account,
    'previousBids' : IDL.Vec(Bid),
    'boughtNow' : IDL.Bool,
    'refunds' : IDL.Vec(Refund),
    'bidIncrement' : IDL.Nat,
    'endsAt' : IDL.Int,
  });
  const FixedPrice = IDL.Record({
    'id' : IDL.Nat,
    'quoteAsset' : AcceptedCryptos,
    'tokenId' : IDL.Nat,
    'expiresAt' : IDL.Opt(IDL.Int),
    'listedAt' : IDL.Int,
    'seller' : Account,
    'price' : IDL.Nat,
  });
  const CancelledReason = IDL.Variant({
    'CalledByAdmin' : IDL.Null,
    'ReserveNotMet' : IDL.Null,
    'NoBids' : IDL.Null,
    'Expired' : IDL.Null,
    'CancelledBySeller' : IDL.Null,
  });
  const CancelledFixedPrice = IDL.Record({
    'id' : IDL.Nat,
    'quoteAsset' : AcceptedCryptos,
    'tokenId' : IDL.Nat,
    'expiresAt' : IDL.Opt(IDL.Int),
    'listedAt' : IDL.Int,
    'seller' : Account,
    'cancelledAt' : IDL.Int,
    'cancelledBy' : Account,
    'price' : IDL.Nat,
    'reason' : CancelledReason,
  });
  const CancelledLaunch = IDL.Record({
    'id' : IDL.Nat,
    'quoteAsset' : AcceptedCryptos,
    'listIds' : IDL.Vec(IDL.Nat),
    'maxListed' : IDL.Nat,
    'tokenIds' : IDL.Vec(IDL.Nat),
    'listedAt' : IDL.Int,
    'seller' : Account,
    'cancelledAt' : IDL.Int,
    'cancelledBy' : Account,
    'caller' : IDL.Principal,
    'price' : IDL.Nat,
    'endsAt' : IDL.Opt(IDL.Int),
    'reason' : CancelledReason,
  });
  const Auction = IDL.Record({
    'id' : IDL.Nat,
    'startTime' : IDL.Int,
    'quoteAsset' : AcceptedCryptos,
    'startingPrice' : IDL.Nat,
    'tokenId' : IDL.Nat,
    'reservePrice' : IDL.Opt(IDL.Nat),
    'listedAt' : IDL.Int,
    'buyNowPrice' : IDL.Opt(IDL.Nat),
    'seller' : Account,
    'highestBid' : IDL.Opt(Bid),
    'previousBids' : IDL.Vec(Bid),
    'refunds' : IDL.Vec(Refund),
    'bidIncrement' : IDL.Nat,
    'endsAt' : IDL.Int,
  });
  const CancelledAuction = IDL.Record({
    'id' : IDL.Nat,
    'startTime' : IDL.Int,
    'quoteAsset' : AcceptedCryptos,
    'startingPrice' : IDL.Nat,
    'tokenId' : IDL.Nat,
    'reservePrice' : IDL.Opt(IDL.Nat),
    'listedAt' : IDL.Int,
    'buyNowPrice' : IDL.Opt(IDL.Nat),
    'seller' : Account,
    'highestBid' : IDL.Opt(Bid),
    'cancelledAt' : IDL.Int,
    'cancelledBy' : Account,
    'previousBids' : IDL.Vec(Bid),
    'refunds' : IDL.Vec(Refund),
    'bidIncrement' : IDL.Nat,
    'endsAt' : IDL.Int,
    'reason' : CancelledReason,
  });
  const Listing = IDL.Variant({
    'LaunchedProperty' : Launch,
    'SoldFixedPrice' : SoldFixedPrice,
    'SoldAuction' : SoldAuction,
    'LiveFixedPrice' : FixedPrice,
    'SoldLaunchFixedPrice' : SoldFixedPrice,
    'CancelledLaunch' : CancelledFixedPrice,
    'CancelledLaunchedProperty' : CancelledLaunch,
    'LiveAuction' : Auction,
    'CancelledAuction' : CancelledAuction,
    'CancelledFixedPrice' : CancelledFixedPrice,
    'LaunchFixedPrice' : FixedPrice,
  });
  const NFTMarketplace = IDL.Record({
    'timerIds' : IDL.Vec(IDL.Tuple(IDL.Nat, IDL.Nat)),
    'collectionId' : IDL.Principal,
    'listings' : IDL.Vec(IDL.Tuple(IDL.Nat, Listing)),
    'royalty' : IDL.Nat,
    'listId' : IDL.Nat,
  });
  const Document = IDL.Record({
    'id' : IDL.Nat,
    'url' : IDL.Text,
    'title' : IDL.Text,
    'documentType' : DocumentType,
    'description' : IDL.Text,
    'uploadDate' : IDL.Int,
  });
  const InsurancePolicy = IDL.Record({
    'id' : IDL.Nat,
    'contactInfo' : IDL.Text,
    'paymentFrequency' : PaymentFrequency,
    'provider' : IDL.Text,
    'endDate' : IDL.Opt(IDL.Int),
    'premium' : IDL.Nat,
    'nextPaymentDate' : IDL.Int,
    'policyNumber' : IDL.Text,
    'startDate' : IDL.Int,
  });
  const Note = IDL.Record({
    'id' : IDL.Nat,
    'title' : IDL.Text,
    'content' : IDL.Text,
    'date' : IDL.Opt(IDL.Int),
    'author' : IDL.Principal,
  });
  const AdministrativeInfo = IDL.Record({
    'documents' : IDL.Vec(IDL.Tuple(IDL.Nat, Document)),
    'insuranceId' : IDL.Nat,
    'notesId' : IDL.Nat,
    'insurance' : IDL.Vec(IDL.Tuple(IDL.Nat, InsurancePolicy)),
    'notes' : IDL.Vec(IDL.Tuple(IDL.Nat, Note)),
    'documentId' : IDL.Nat,
  });
  const InspectionRecord = IDL.Record({
    'id' : IDL.Nat,
    'date' : IDL.Opt(IDL.Int),
    'inspectorName' : IDL.Text,
    'findings' : IDL.Text,
    'appraiser' : IDL.Principal,
    'actionRequired' : IDL.Opt(IDL.Text),
    'followUpDate' : IDL.Opt(IDL.Int),
  });
  const MaintenanceRecord = IDL.Record({
    'id' : IDL.Nat,
    'status' : MaintenanceStatus,
    'paymentMethod' : IDL.Opt(PaymentMethod),
    'cost' : IDL.Opt(IDL.Float64),
    'dateCompleted' : IDL.Opt(IDL.Int),
    'description' : IDL.Text,
    'dateReported' : IDL.Opt(IDL.Int),
    'contractor' : IDL.Opt(IDL.Text),
  });
  const Tenant = IDL.Record({
    'id' : IDL.Nat,
    'principal' : IDL.Opt(IDL.Principal),
    'paymentHistory' : IDL.Vec(Payment),
    'leadTenant' : IDL.Text,
    'otherTenants' : IDL.Vec(IDL.Text),
    'deposit' : IDL.Nat,
    'contractLength' : ContractLength,
    'monthlyRent' : IDL.Nat,
    'leaseStartDate' : IDL.Int,
  });
  const OperationalInfo = IDL.Record({
    'inspectionsId' : IDL.Nat,
    'inspections' : IDL.Vec(IDL.Tuple(IDL.Nat, InspectionRecord)),
    'tenantId' : IDL.Nat,
    'maintenanceId' : IDL.Nat,
    'maintenance' : IDL.Vec(IDL.Tuple(IDL.Nat, MaintenanceRecord)),
    'tenants' : IDL.Vec(IDL.Tuple(IDL.Nat, Tenant)),
  });
  const Result__1 = IDL.Variant({
    'ok' : IDL.Opt(IDL.Nat),
    'err' : IDL.Tuple(IDL.Opt(IDL.Nat), UpdateError),
  });
  const OkUpdateResult = IDL.Record({
    'what' : What,
    'results' : IDL.Vec(Result__1),
  });
  const Result = IDL.Variant({ 'Ok' : OkUpdateResult, 'Err' : UpdateError });
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
  const InvestmentDetails = IDL.Record({
    'purchasePrice' : IDL.Nat,
    'initialMaintenanceReserve' : IDL.Nat,
    'totalInvestmentValue' : IDL.Nat,
    'platformFee' : IDL.Nat,
  });
  const ValuationRecord = IDL.Record({
    'id' : IDL.Nat,
    'method' : ValuationMethod,
    'value' : IDL.Nat,
    'date' : IDL.Int,
    'appraiser' : IDL.Principal,
  });
  const InvoiceStatus = IDL.Variant({
    'Failed' : IDL.Null,
    'Paid' : IDL.Null,
    'Approved' : IDL.Null,
    'Draft' : IDL.Null,
    'Rejected' : IDL.Null,
    'PreApproved' : IDL.Principal,
    'Pending' : IDL.Null,
  });
  const InvestorTransfer = IDL.Record({
    'to' : Account,
    'result' : GenericTransferResult,
    'timestamp' : IDL.Int,
  });
  const PaymentStatus = IDL.Variant({
    'Failed' : IDL.Record({ 'attempted_at' : IDL.Int, 'reason' : UpdateError }),
    'Confirmed' : IDL.Record({
      'paid_at' : IDL.Int,
      'transactionId' : IDL.Nat,
    }),
    'TransferAttempted' : IDL.Vec(InvestorTransfer),
    'WaitingApproval' : IDL.Null,
    'Pending' : IDL.Record({ 'timerId' : IDL.Opt(IDL.Nat) }),
  });
  const InvoiceLogAction = IDL.Variant({
    'PaymentStatusChange' : IDL.Record({
      'to' : PaymentStatus,
      'from' : PaymentStatus,
    }),
    'PaymentFailed' : IDL.Record({ 'reason' : IDL.Text }),
    'ProposalLinked' : IDL.Record({ 'proposalId' : IDL.Nat }),
    'PaymentConfirmed' : IDL.Record({ 'transactionId' : IDL.Opt(IDL.Text) }),
    'Edited' : IDL.Record({
      'fieldsChanged' : IDL.Vec(IDL.Text),
      'newInvoice' : Invoice,
      'oldInvoice' : Invoice,
    }),
    'Custom' : IDL.Text,
    'Created' : Invoice,
    'StatusChange' : IDL.Record({
      'to' : InvoiceStatus,
      'from' : InvoiceStatus,
    }),
    'Recurring' : IDL.Record({
      'count' : IDL.Nat,
      'newDueDate' : IDL.Int,
      'previousInvoiceId' : IDL.Nat,
    }),
  });
  const InvoiceLog = IDL.Record({
    'changedBy' : IDL.Principal,
    'actionType' : InvoiceLogAction,
    'timestamp' : IDL.Int,
    'details' : IDL.Opt(IDL.Text),
  });
  Invoice.fill(
    IDL.Record({
      'id' : IDL.Nat,
      'due' : IDL.Int,
      'status' : InvoiceStatus,
      'title' : IDL.Text,
      'direction' : InvoiceDirection,
      'paymentStatus' : PaymentStatus,
      'paymentMethod' : AcceptedCryptos,
      'logs' : IDL.Vec(InvoiceLog),
      'description' : IDL.Text,
      'recurrence' : RecurrenceType,
      'amount' : IDL.Nat,
    })
  );
  const Financials = IDL.Record({
    'valuationId' : IDL.Nat,
    'investment' : InvestmentDetails,
    'pricePerSqFoot' : IDL.Nat,
    'invoiceId' : IDL.Nat,
    'currentValue' : IDL.Nat,
    'valuations' : IDL.Vec(IDL.Tuple(IDL.Nat, ValuationRecord)),
    'account' : Account,
    'invoices' : IDL.Vec(IDL.Tuple(IDL.Nat, Invoice)),
    'monthlyRent' : IDL.Nat,
    'yield' : IDL.Float64,
  });
  const UpdateResult__1 = IDL.Variant({
    'Ok' : Property,
    'Err' : IDL.Vec(IDL.Tuple(IDL.Opt(IDL.Nat), UpdateError)),
  });
  const ProposalOutcome = IDL.Variant({
    'Accepted' : IDL.Vec(UpdateResult__1),
    'Refused' : IDL.Text,
    'AwaitingTenantApproval' : IDL.Null,
  });
  const ExecutedProposalArgs = IDL.Record({
    'noVotes' : IDL.Nat,
    'executedAt' : IDL.Int,
    'yesVotes' : IDL.Nat,
    'totalVotesCast' : IDL.Nat,
    'outcome' : ProposalOutcome,
  });
  const LiveProposalArgs = IDL.Record({
    'noVotes' : IDL.Nat,
    'eligibleVoterCount' : IDL.Nat,
    'endTime' : IDL.Int,
    'yesVotes' : IDL.Nat,
    'totalVotesCast' : IDL.Nat,
    'timerId' : IDL.Opt(IDL.Nat),
  });
  const ProposalStatus = IDL.Variant({
    'RejectedEarly' : IDL.Record({ 'reason' : IDL.Text }),
    'Executed' : ExecutedProposalArgs,
    'LiveProposal' : LiveProposalArgs,
  });
  const Proposal = IDL.Record({
    'id' : IDL.Nat,
    'status' : ProposalStatus,
    'title' : IDL.Text,
    'creator' : IDL.Principal,
    'startAt' : IDL.Int,
    'votes' : IDL.Vec(IDL.Tuple(IDL.Principal, IDL.Bool)),
    'createdAt' : IDL.Int,
    'implementation' : ImplementationCategory,
    'description' : IDL.Text,
    'totalEligibleVoters' : IDL.Nat,
    'actions' : IDL.Vec(What),
    'category' : ProposalCategory,
    'eligibleVoters' : IDL.Vec(IDL.Principal),
  });
  const Governance = IDL.Record({
    'quorumPercentage' : IDL.Nat,
    'minTurnout' : IDL.Nat,
    'proposalCost' : IDL.Nat,
    'minYesVotes' : IDL.Nat,
    'assetCost' : AcceptedCryptos,
    'proposals' : IDL.Vec(IDL.Tuple(IDL.Nat, Proposal)),
    'proposalId' : IDL.Nat,
    'requireNftToPropose' : IDL.Bool,
  });
  Property.fill(
    IDL.Record({
      'id' : IDL.Nat,
      'nftMarketplace' : NFTMarketplace,
      'administrative' : AdministrativeInfo,
      'operational' : OperationalInfo,
      'updates' : IDL.Vec(Result),
      'details' : PropertyDetails,
      'financials' : Financials,
      'governance' : Governance,
    })
  );
  const ReadErrors = IDL.Variant({
    'InvalidElementId' : IDL.Null,
    'DidNotMatchConditions' : IDL.Null,
    'InvalidPropertyId' : IDL.Null,
    'Vacant' : IDL.Null,
    'ArrayIndexOutOfBounds' : IDL.Null,
    'EmptyArray' : IDL.Null,
    'Filtered' : IDL.Null,
  });
  const ElementResult_21 = IDL.Record({
    'id' : IDL.Nat,
    'value' : IDL.Variant({ 'Ok' : ValuationRecord, 'Err' : ReadErrors }),
  });
  const PropertyResult_12 = IDL.Record({
    'result' : IDL.Variant({
      'Ok' : IDL.Vec(ElementResult_21),
      'Err' : ReadErrors,
    }),
    'propertyId' : IDL.Nat,
  });
  const ElementResult_5 = IDL.Record({
    'id' : IDL.Nat,
    'value' : IDL.Variant({ 'Ok' : InspectionRecord, 'Err' : ReadErrors }),
  });
  const PropertyResult_2 = IDL.Record({
    'result' : IDL.Variant({
      'Ok' : IDL.Vec(ElementResult_5),
      'Err' : ReadErrors,
    }),
    'propertyId' : IDL.Nat,
  });
  const ElementResult_8 = IDL.Record({
    'id' : IDL.Nat,
    'value' : IDL.Variant({ 'Ok' : Listing, 'Err' : ReadErrors }),
  });
  const PropertyResult_5 = IDL.Record({
    'result' : IDL.Variant({
      'Ok' : IDL.Vec(ElementResult_8),
      'Err' : ReadErrors,
    }),
    'propertyId' : IDL.Nat,
  });
  const ElementResult_6 = IDL.Record({
    'id' : IDL.Nat,
    'value' : IDL.Variant({ 'Ok' : InsurancePolicy, 'Err' : ReadErrors }),
  });
  const PropertyResult_3 = IDL.Record({
    'result' : IDL.Variant({
      'Ok' : IDL.Vec(ElementResult_6),
      'Err' : ReadErrors,
    }),
    'propertyId' : IDL.Nat,
  });
  const ElementResult_11 = IDL.Record({
    'id' : IDL.Nat,
    'value' : IDL.Variant({ 'Ok' : Miscellaneous, 'Err' : ReadErrors }),
  });
  const ElementResult_13 = IDL.Record({
    'id' : IDL.Nat,
    'value' : IDL.Variant({ 'Ok' : IDL.Vec(IDL.Nat), 'Err' : ReadErrors }),
  });
  const ElementResult_14 = IDL.Record({
    'id' : IDL.Nat,
    'value' : IDL.Variant({ 'Ok' : Note, 'Err' : ReadErrors }),
  });
  const PropertyResult_7 = IDL.Record({
    'result' : IDL.Variant({
      'Ok' : IDL.Vec(ElementResult_14),
      'Err' : ReadErrors,
    }),
    'propertyId' : IDL.Nat,
  });
  const ElementResult_4 = IDL.Record({
    'id' : IDL.Nat,
    'value' : IDL.Variant({ 'Ok' : IDL.Text, 'Err' : ReadErrors }),
  });
  const PropertyResult_1 = IDL.Record({
    'result' : IDL.Variant({
      'Ok' : IDL.Vec(ElementResult_4),
      'Err' : ReadErrors,
    }),
    'propertyId' : IDL.Nat,
  });
  const ElementResult_17 = IDL.Record({
    'id' : IDL.Nat,
    'value' : IDL.Variant({ 'Ok' : Proposal, 'Err' : ReadErrors }),
  });
  const PropertyResult_9 = IDL.Record({
    'result' : IDL.Variant({
      'Ok' : IDL.Vec(ElementResult_17),
      'Err' : ReadErrors,
    }),
    'propertyId' : IDL.Nat,
  });
  const ElementResult_2 = IDL.Record({
    'id' : IDL.Nat,
    'value' : IDL.Variant({ 'Ok' : Document, 'Err' : ReadErrors }),
  });
  const PropertyResult = IDL.Record({
    'result' : IDL.Variant({
      'Ok' : IDL.Vec(ElementResult_2),
      'Err' : ReadErrors,
    }),
    'propertyId' : IDL.Nat,
  });
  const ElementResult_20 = IDL.Record({
    'id' : IDL.Nat,
    'value' : IDL.Variant({ 'Ok' : IDL.Vec(Result), 'Err' : ReadErrors }),
  });
  const ElementResult_10 = IDL.Record({
    'id' : IDL.Nat,
    'value' : IDL.Variant({ 'Ok' : MaintenanceRecord, 'Err' : ReadErrors }),
  });
  const PropertyResult_6 = IDL.Record({
    'result' : IDL.Variant({
      'Ok' : IDL.Vec(ElementResult_10),
      'Err' : ReadErrors,
    }),
    'propertyId' : IDL.Nat,
  });
  const ElementResult_7 = IDL.Record({
    'id' : IDL.Nat,
    'value' : IDL.Variant({ 'Ok' : Invoice, 'Err' : ReadErrors }),
  });
  const PropertyResult_4 = IDL.Record({
    'result' : IDL.Variant({
      'Ok' : IDL.Vec(ElementResult_7),
      'Err' : ReadErrors,
    }),
    'propertyId' : IDL.Nat,
  });
  const ElementResult_19 = IDL.Record({
    'id' : IDL.Nat,
    'value' : IDL.Variant({ 'Ok' : Tenant, 'Err' : ReadErrors }),
  });
  const PropertyResult_11 = IDL.Record({
    'result' : IDL.Variant({
      'Ok' : IDL.Vec(ElementResult_19),
      'Err' : ReadErrors,
    }),
    'propertyId' : IDL.Nat,
  });
  const ElementResult_1 = IDL.Record({
    'id' : IDL.Nat,
    'value' : IDL.Variant({ 'Ok' : IDL.Principal, 'Err' : ReadErrors }),
  });
  const ElementResult_16 = IDL.Record({
    'id' : IDL.Nat,
    'value' : IDL.Variant({ 'Ok' : PhysicalDetails, 'Err' : ReadErrors }),
  });
  const ElementResult_12 = IDL.Record({
    'id' : IDL.Nat,
    'value' : IDL.Variant({ 'Ok' : IDL.Nat, 'Err' : ReadErrors }),
  });
  const ElementResult_3 = IDL.Record({
    'id' : IDL.Nat,
    'value' : IDL.Variant({ 'Ok' : Financials, 'Err' : ReadErrors }),
  });
  const ElementResult_18 = IDL.Record({
    'id' : IDL.Nat,
    'value' : IDL.Variant({ 'Ok' : IDL.Vec(Refund), 'Err' : ReadErrors }),
  });
  const PropertyResult_10 = IDL.Record({
    'result' : IDL.Variant({
      'Ok' : IDL.Vec(ElementResult_18),
      'Err' : ReadErrors,
    }),
    'propertyId' : IDL.Nat,
  });
  const ElementResult_9 = IDL.Record({
    'id' : IDL.Nat,
    'value' : IDL.Variant({ 'Ok' : LocationDetails, 'Err' : ReadErrors }),
  });
  const ElementResult = IDL.Record({
    'id' : IDL.Nat,
    'value' : IDL.Variant({ 'Ok' : AdditionalDetails, 'Err' : ReadErrors }),
  });
  const ElementResult_15 = IDL.Record({
    'id' : IDL.Nat,
    'value' : IDL.Variant({ 'Ok' : IDL.Vec(Payment), 'Err' : ReadErrors }),
  });
  const PropertyResult_8 = IDL.Record({
    'result' : IDL.Variant({
      'Ok' : IDL.Vec(ElementResult_15),
      'Err' : ReadErrors,
    }),
    'propertyId' : IDL.Nat,
  });
  const ReadResult = IDL.Variant({
    'Valuation' : IDL.Vec(PropertyResult_12),
    'Inspection' : IDL.Vec(PropertyResult_2),
    'Listings' : IDL.Vec(PropertyResult_5),
    'Insurance' : IDL.Vec(PropertyResult_3),
    'Misc' : IDL.Vec(ElementResult_11),
    'NFTs' : IDL.Vec(ElementResult_13),
    'Note' : IDL.Vec(PropertyResult_7),
    'Image' : IDL.Vec(PropertyResult_1),
    'Proposals' : IDL.Vec(PropertyResult_9),
    'Document' : IDL.Vec(PropertyResult),
    'UpdateResults' : IDL.Vec(ElementResult_20),
    'Maintenance' : IDL.Vec(PropertyResult_6),
    'Invoices' : IDL.Vec(PropertyResult_4),
    'Tenants' : IDL.Vec(PropertyResult_11),
    'CollectionIds' : IDL.Vec(ElementResult_1),
    'Physical' : IDL.Vec(ElementResult_16),
    'MonthlyRent' : IDL.Vec(ElementResult_12),
    'Financials' : IDL.Vec(ElementResult_3),
    'Refunds' : IDL.Vec(PropertyResult_10),
    'Location' : IDL.Vec(ElementResult_9),
    'Additional' : IDL.Vec(ElementResult),
    'PaymentHistory' : IDL.Vec(PropertyResult_8),
  });
  const GetPropertyResult = IDL.Variant({ 'Ok' : Property, 'Err' : IDL.Null });
  const NotificationType = IDL.Variant({
    'New' : IDL.Null,
    'Read' : IDL.Null,
    'Deleted' : IDL.Null,
  });
  const Notification = IDL.Record({
    'id' : IDL.Nat,
    'content' : What,
    'propertyId' : IDL.Nat,
    'ntype' : NotificationType,
  });
  const NotificationResult = IDL.Variant({
    'Ok' : Notification,
    'Err' : IDL.Tuple(IDL.Nat, UpdateError),
  });
  const Selected = IDL.Opt(IDL.Vec(IDL.Int));
  const ScopedProperties = IDL.Record({
    'ids' : Selected,
    'propertyId' : IDL.Nat,
  });
  const BaseRead = IDL.Variant({
    'Ids' : Selected,
    'Properties' : Selected,
    'Scoped' : IDL.Vec(ScopedProperties),
  });
  const MarketplaceOptions = IDL.Variant({
    'SoldFixedPrice' : IDL.Null,
    'SoldAuction' : IDL.Null,
    'LiveFixedPrice' : IDL.Null,
    'SoldLaunchFixedPrice' : IDL.Null,
    'CancelledLaunch' : IDL.Null,
    'LiveAuction' : IDL.Null,
    'PropertyLaunch' : IDL.Null,
    'CancelledAuction' : IDL.Null,
    'CancelledPropertyLaunch' : IDL.Null,
    'CancelledFixedPrice' : IDL.Null,
    'LaunchFixedPrice' : IDL.Null,
  });
  const ListingConditionals = IDL.Record({
    'listingType' : IDL.Opt(IDL.Vec(MarketplaceOptions)),
    'ltype' : IDL.Variant({
      'Purchased' : IDL.Null,
      'Seller' : IDL.Null,
      'PreviousBids' : IDL.Null,
      'Winning' : IDL.Null,
    }),
    'account' : IDL.Opt(Account),
  });
  const ConditionalBaseRead_1 = IDL.Record({
    'base' : BaseRead,
    'conditionals' : ListingConditionals,
  });
  const ProposalStatusFlag = IDL.Variant({
    'RejectedEarly' : IDL.Null,
    'Executed' : IDL.Null,
    'LiveProposal' : IDL.Null,
  });
  const EqualityFlag = IDL.Variant({
    'MoreThan' : IDL.Int,
    'LessThan' : IDL.Int,
  });
  const HasVoted = IDL.Variant({
    'HasVoted' : IDL.Principal,
    'NotVoted' : IDL.Principal,
  });
  const WhatFlag = IDL.Variant({
    'Tenant' : IDL.Null,
    'Inspection' : IDL.Null,
    'Invoice' : IDL.Null,
    'Insurance' : IDL.Null,
    'Images' : IDL.Null,
    'Note' : IDL.Null,
    'Description' : IDL.Null,
    'Document' : IDL.Null,
    'Valuations' : IDL.Null,
    'Maintenance' : IDL.Null,
    'MonthlyRent' : IDL.Null,
    'Financials' : IDL.Null,
    'AdditionalDetails' : IDL.Null,
    'Governance' : IDL.Variant({ 'Vote' : IDL.Null, 'Proposal' : IDL.Null }),
    'PhysicalDetails' : IDL.Null,
    'NftMarketplace' : IDL.Variant({
      'Bid' : IDL.Null,
      'Launch' : IDL.Null,
      'Auction' : IDL.Null,
      'FixedPrice' : IDL.Null,
    }),
  });
  const ProposalOutcomeFlag = IDL.Variant({
    'Accepted' : IDL.Null,
    'Refused' : IDL.Null,
  });
  const ProposalConditionals = IDL.Record({
    'status' : IDL.Opt(ProposalStatusFlag),
    'noVotes' : IDL.Opt(EqualityFlag),
    'creator' : IDL.Opt(IDL.Principal),
    'startAt' : IDL.Opt(EqualityFlag),
    'yesVotes' : IDL.Opt(EqualityFlag),
    'voted' : IDL.Opt(HasVoted),
    'actions' : IDL.Opt(WhatFlag),
    'implementationCategory' : IDL.Opt(ImplementationCategory),
    'totalVoterCount' : IDL.Opt(EqualityFlag),
    'category' : IDL.Opt(ProposalCategoryFlag),
    'eligibleCount' : IDL.Opt(EqualityFlag),
    'outcome' : IDL.Opt(ProposalOutcomeFlag),
  });
  const ConditionalBaseRead_2 = IDL.Record({
    'base' : BaseRead,
    'conditionals' : ProposalConditionals,
  });
  const InvoiceDirectionFlag = IDL.Variant({
    'ToInvestors' : IDL.Null,
    'Outgoing' : IDL.Record({
      'to' : IDL.Opt(Account),
      'accountReference' : IDL.Opt(IDL.Text),
      'category' : IDL.Opt(ExpenseCategory),
    }),
    'Incoming' : IDL.Record({
      'accountReference' : IDL.Opt(IDL.Text),
      'from' : IDL.Opt(Account),
      'category' : IDL.Opt(IncomeCategory),
    }),
  });
  const PaymentStatusFlag = IDL.Variant({
    'Failed' : IDL.Null,
    'Confirmed' : IDL.Null,
    'WaitingApproval' : IDL.Null,
    'Pending' : IDL.Null,
  });
  const InvoiceConditionals = IDL.Record({
    'due' : IDL.Opt(EqualityFlag),
    'status' : IDL.Opt(InvoiceStatus),
    'direction' : IDL.Opt(InvoiceDirectionFlag),
    'paymentStatus' : IDL.Opt(PaymentStatusFlag),
    'paymentMethod' : IDL.Opt(AcceptedCryptos),
    'notRecurrenceType' : IDL.Vec(PeriodicRecurrence),
    'recurrenceEndAt' : IDL.Opt(EqualityFlag),
    'recurrenceType' : IDL.Vec(PeriodicRecurrence),
    'amount' : IDL.Opt(EqualityFlag),
  });
  const ConditionalBaseRead = IDL.Record({
    'base' : BaseRead,
    'conditionals' : InvoiceConditionals,
  });
  const ScopedNestedProperties = IDL.Record({
    'ids' : Selected,
    'propertyId' : IDL.Nat,
    'elements' : Selected,
  });
  const NestedRead = IDL.Variant({
    'Ids' : Selected,
    'NestedScoped' : IDL.Vec(ScopedNestedProperties),
    'Properties' : Selected,
    'Scoped' : IDL.Vec(ScopedProperties),
  });
  const NestedConditionalRead = IDL.Record({
    'nested' : NestedRead,
    'conditionals' : IDL.Variant({
      'Ok' : IDL.Null,
      'All' : IDL.Null,
      'Err' : IDL.Null,
    }),
  });
  const Read2 = IDL.Variant({
    'Valuation' : BaseRead,
    'Inspection' : BaseRead,
    'Listings' : ConditionalBaseRead_1,
    'Insurance' : BaseRead,
    'Images' : BaseRead,
    'Misc' : Selected,
    'Note' : BaseRead,
    'Proposals' : ConditionalBaseRead_2,
    'Document' : BaseRead,
    'UpdateResults' : IDL.Record({
      'conditional' : IDL.Variant({
        'Ok' : IDL.Null,
        'All' : IDL.Null,
        'Err' : IDL.Null,
      }),
      'selected' : Selected,
    }),
    'Maintenance' : BaseRead,
    'Invoices' : ConditionalBaseRead,
    'Tenants' : BaseRead,
    'CollectionIds' : Selected,
    'Physical' : Selected,
    'MonthlyRent' : Selected,
    'Financials' : Selected,
    'Refunds' : NestedConditionalRead,
    'Location' : Selected,
    'Additional' : Selected,
    'PaymentHistory' : NestedRead,
  });
  const FilterProperties = IDL.Record({
    'houseValueMax' : IDL.Opt(IDL.Nat),
    'houseValueMin' : IDL.Opt(IDL.Nat),
    'nftPriceMax' : IDL.Opt(IDL.Nat),
    'nftPriceMin' : IDL.Opt(IDL.Nat),
    'beds' : IDL.Opt(IDL.Vec(IDL.Nat)),
    'monthlyRentMin' : IDL.Opt(IDL.Float64),
    'saved' : IDL.Opt(Account),
    'typeOfProperty' : IDL.Opt(
      IDL.Variant({
        'Detached' : IDL.Null,
        'Semi' : IDL.Null,
        'Terraced' : IDL.Null,
      })
    ),
    'location' : IDL.Opt(IDL.Text),
  });
  const Error = IDL.Variant({ 'InvalidPropertyId' : IDL.Null });
  const Result__1_1 = IDL.Variant({ 'ok' : Property, 'err' : Error });
  const TestOption = IDL.Variant({
    'All' : IDL.Null,
    'Bid' : IDL.Null,
    'Valuation' : IDL.Null,
    'Tenant' : IDL.Null,
    'Inspection' : IDL.Null,
    'Invoice' : IDL.Null,
    'Insurance' : IDL.Null,
    'NFTMarketplaceAuction' : IDL.Null,
    'Images' : IDL.Null,
    'Note' : IDL.Null,
    'NFTMarketplaceFixedPrice' : IDL.Null,
    'Vote' : IDL.Null,
    'Description' : IDL.Null,
    'Document' : IDL.Null,
    'Maintenance' : IDL.Null,
    'Proposal' : IDL.Null,
    'MonthlyRent' : IDL.Null,
    'Financials' : IDL.Null,
    'AdditionalDetails' : IDL.Null,
    'PhysicalDetails' : IDL.Null,
    'NFTMarketplaceLaunch' : IDL.Null,
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
  const http_header = IDL.Record({ 'value' : IDL.Text, 'name' : IDL.Text });
  const http_request_result = IDL.Record({
    'status' : IDL.Nat,
    'body' : IDL.Vec(IDL.Nat8),
    'headers' : IDL.Vec(http_header),
  });
  const TransferFromError = IDL.Variant({
    'GenericError' : IDL.Record({
      'message' : IDL.Text,
      'error_code' : IDL.Nat,
    }),
    'TemporarilyUnavailable' : IDL.Null,
    'InsufficientAllowance' : IDL.Record({ 'allowance' : IDL.Nat }),
    'BadBurn' : IDL.Record({ 'min_burn_amount' : IDL.Nat }),
    'Duplicate' : IDL.Record({ 'duplicate_of' : IDL.Nat }),
    'BadFee' : IDL.Record({ 'expected_fee' : IDL.Nat }),
    'Unauthorized' : IDL.Null,
    'CreatedInFuture' : IDL.Record({ 'ledger_time' : IDL.Nat64 }),
    'TooOld' : IDL.Null,
    'InsufficientFunds' : IDL.Record({ 'balance' : IDL.Nat }),
  });
  const TransferFromResult = IDL.Variant({
    'Ok' : IDL.Nat,
    'Err' : TransferFromError,
  });
  return IDL.Service({
    'bulkPropertyUpdate' : IDL.Func(
        [IDL.Vec(WhatWithPropertyId)],
        [IDL.Vec(UpdateResultNat)],
        [],
      ),
    'createProperty' : IDL.Func(
        [IDL.Principal, IDL.Nat],
        [IDL.Vec(IDL.Opt(MintResult))],
        [],
      ),
    'emptyState' : IDL.Func(
        [IDL.Nat],
        [
          IDL.Vec(
            IDL.Record({
              'ok' : IDL.Nat,
              'err' : IDL.Vec(MintError),
              'nullRes' : IDL.Nat,
            })
          ),
        ],
        [],
      ),
    'getAllProperties' : IDL.Func([], [IDL.Vec(Property)], []),
    'getBackendsNFTs' : IDL.Func([], [IDL.Vec(IDL.Nat)], []),
    'getNFTs' : IDL.Func(
        [IDL.Opt(IDL.Vec(IDL.Int)), Account],
        [ReadResult],
        [],
      ),
    'getProperty' : IDL.Func([IDL.Nat], [GetPropertyResult], []),
    'getTime' : IDL.Func([], [IDL.Nat64], ['query']),
    'getURLs' : IDL.Func([], [IDL.Vec(IDL.Text)], []),
    'getUserNotification' : IDL.Func([Account], [IDL.Vec(Notification)], []),
    'getUserNotificationResults' : IDL.Func(
        [Account],
        [IDL.Vec(NotificationResult)],
        [],
      ),
    'getUserNotificationsOfType' : IDL.Func(
        [Account, NotificationType],
        [IDL.Vec(Notification)],
        [],
      ),
    'readProperties' : IDL.Func(
        [IDL.Vec(Read2), IDL.Opt(FilterProperties)],
        [IDL.Vec(ReadResult)],
        ['query'],
      ),
    'removeProperty' : IDL.Func([IDL.Nat], [Result__1_1], []),
    'runTests' : IDL.Func([TestOption], [IDL.Vec(IDL.Vec(IDL.Text))], []),
    'transferAllNFTs' : IDL.Func([], [IDL.Vec(IDL.Opt(TransferResult))], []),
    'transferNFT' : IDL.Func(
        [Account, IDL.Nat, IDL.Nat, IDL.Nat],
        [IDL.Opt(TransferResult)],
        [],
      ),
    'transferNFTBulk' : IDL.Func([], [IDL.Vec(IDL.Opt(TransferResult))], []),
    'transform' : IDL.Func(
        [
          IDL.Record({
            'context' : IDL.Vec(IDL.Nat8),
            'response' : http_request_result,
          }),
        ],
        [http_request_result],
        ['query'],
      ),
    'updateNotificationType' : IDL.Func(
        [Account, NotificationType, IDL.Nat],
        [NotificationResult],
        [],
      ),
    'updateProperty' : IDL.Func([WhatWithPropertyId], [UpdateResult__1], []),
    'updatePropertyValuations' : IDL.Func([], [IDL.Vec(UpdateResult__1)], []),
    'updateSavedListings' : IDL.Func([IDL.Nat, IDL.Nat], [], ['oneway']),
    'userVerified' : IDL.Func([Account], [IDL.Bool], ['query']),
    'verifyKYC' : IDL.Func([IDL.Bool], [], []),
    'verifyNFTTransfer' : IDL.Func(
        [IDL.Nat, Account, IDL.Nat],
        [IDL.Opt(TransferResult)],
        [],
      ),
    'verifyTokenTransferFrom' : IDL.Func(
        [IDL.Nat, IDL.Nat, Account],
        [IDL.Opt(TransferFromResult)],
        [],
      ),
  });
};
export const init = ({ IDL }) => { return []; };
