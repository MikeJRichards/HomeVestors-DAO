export const idlFactory = ({ IDL }) => {
  const Listing = IDL.Rec();
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
  const Actions_6 = IDL.Variant({
    'Delete' : IDL.Nat,
    'Create' : TenantCArg,
    'Update' : IDL.Tuple(TenantUArg, IDL.Nat),
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
  const Actions_2 = IDL.Variant({
    'Delete' : IDL.Nat,
    'Create' : InspectionRecordCArg,
    'Update' : IDL.Tuple(InspectionRecordUArg, IDL.Nat),
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
  const Actions_3 = IDL.Variant({
    'Delete' : IDL.Nat,
    'Create' : InsurancePolicyCArg,
    'Update' : IDL.Tuple(InsurancePolicyUArg, IDL.Nat),
  });
  const Actions_1 = IDL.Variant({
    'Delete' : IDL.Nat,
    'Create' : IDL.Text,
    'Update' : IDL.Tuple(IDL.Text, IDL.Nat),
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
  const Actions_5 = IDL.Variant({
    'Delete' : IDL.Nat,
    'Create' : NoteCArg,
    'Update' : IDL.Tuple(NoteUArg, IDL.Nat),
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
    'Delete' : IDL.Nat,
    'Create' : DocumentCArg,
    'Update' : IDL.Tuple(DocumentUArg, IDL.Nat),
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
  const Actions_7 = IDL.Variant({
    'Delete' : IDL.Nat,
    'Create' : ValuationRecordCArg,
    'Update' : IDL.Tuple(ValuationRecordUArg, IDL.Nat),
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
  const Actions_4 = IDL.Variant({
    'Delete' : IDL.Nat,
    'Create' : MaintenanceRecordCArg,
    'Update' : IDL.Tuple(MaintenanceRecordUArg, IDL.Nat),
  });
  const FinancialsArg = IDL.Record({ 'currentValue' : IDL.Nat });
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
  const BidArg = IDL.Record({
    'listingId' : IDL.Nat,
    'buyer_subaccount' : IDL.Opt(IDL.Vec(IDL.Nat8)),
    'bidAmount' : IDL.Nat,
  });
  const CancelledReason = IDL.Variant({
    'CalledByAdmin' : IDL.Null,
    'ReserveNotMet' : IDL.Null,
    'NoBids' : IDL.Null,
    'Expired' : IDL.Null,
    'CancelledBySeller' : IDL.Null,
  });
  const CancelArg = IDL.Record({
    'listingId' : IDL.Nat,
    'cancelledBy_subaccount' : IDL.Opt(IDL.Vec(IDL.Nat8)),
    'reason' : CancelledReason,
  });
  const FixedPriceUArg = IDL.Record({
    'quoteAsset' : IDL.Opt(AcceptedCryptos),
    'expiresAt' : IDL.Opt(IDL.Int),
    'listingId' : IDL.Nat,
    'price' : IDL.Opt(IDL.Nat),
  });
  const LaunchArg = IDL.Record({
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
  const FixedPriceCArg = IDL.Record({
    'quoteAsset' : IDL.Opt(AcceptedCryptos),
    'tokenId' : IDL.Nat,
    'expiresAt' : IDL.Opt(IDL.Int),
    'seller_subaccount' : IDL.Opt(IDL.Vec(IDL.Nat8)),
    'price' : IDL.Nat,
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
  const MarketplaceAction = IDL.Variant({
    'Bid' : BidArg,
    'CancelListing' : CancelArg,
    'UpdateLaunch' : FixedPriceUArg,
    'LaunchProperty' : LaunchArg,
    'CreateFixedListing' : FixedPriceCArg,
    'UpdateFixedListing' : FixedPriceUArg,
    'CreateAuctionListing' : AuctionCArg,
    'UpdateAuctionListing' : AuctionUArg,
  });
  const What = IDL.Variant({
    'Tenant' : Actions_6,
    'Inspection' : Actions_2,
    'Insurance' : Actions_3,
    'Images' : Actions_1,
    'Note' : Actions_5,
    'Description' : IDL.Text,
    'Document' : Actions,
    'Valuations' : Actions_7,
    'Maintenance' : Actions_4,
    'MonthlyRent' : IDL.Nat,
    'Financials' : FinancialsArg,
    'AdditionalDetails' : AdditionalDetails,
    'PhysicalDetails' : PhysicalDetails,
    'NFTMarketplace' : MarketplaceAction,
  });
  const WhatWithPropertyId = IDL.Record({
    'what' : What,
    'propertyId' : IDL.Nat,
  });
  const Reason = IDL.Variant({
    'JSONParseError' : IDL.Null,
    'CannotBeSetInThePast' : IDL.Null,
    'FailedToDecodeResponseBody' : IDL.Null,
    'Anonymous' : IDL.Null,
    'InvalidInput' : IDL.Null,
    'DataMismatch' : IDL.Null,
    'CannotBeSetInTheFuture' : IDL.Null,
    'BuyerAndSellerCannotMatch' : IDL.Null,
    'CannotBeNull' : IDL.Null,
    'CannotBeZero' : IDL.Null,
    'EmptyString' : IDL.Null,
    'OutOfRange' : IDL.Null,
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
    'InvalidPropertyId' : IDL.Null,
    'InvalidData' : IDL.Record({ 'field' : IDL.Text, 'reason' : Reason }),
    'Unauthorized' : IDL.Null,
    'InvalidType' : IDL.Null,
    'Transfer' : IDL.Opt(GenericTransferError),
    'ListingExpired' : IDL.Null,
    'OverWritingData' : IDL.Null,
  });
  const UpdateResultNat = IDL.Variant({ 'Ok' : IDL.Nat, 'Err' : UpdateError });
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
  const Account = IDL.Record({
    'owner' : IDL.Principal,
    'subaccount' : IDL.Opt(IDL.Vec(IDL.Nat8)),
  });
  const Launch = IDL.Record({
    'id' : IDL.Nat,
    'quoteAsset' : AcceptedCryptos,
    'maxListed' : IDL.Nat,
    'tokenIds' : IDL.Vec(IDL.Nat),
    'listedAt' : IDL.Int,
    'args' : IDL.Vec(IDL.Tuple(IDL.Nat, Listing)),
    'seller' : Account,
    'caller' : IDL.Principal,
    'price' : IDL.Nat,
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
  Listing.fill(
    IDL.Variant({
      'LaunchedProperty' : Launch,
      'SoldFixedPrice' : SoldFixedPrice,
      'SoldAuction' : SoldAuction,
      'LiveFixedPrice' : FixedPrice,
      'SoldLaunchFixedPrice' : SoldFixedPrice,
      'CancelledLaunch' : CancelledFixedPrice,
      'LiveAuction' : Auction,
      'CancelledAuction' : CancelledAuction,
      'CancelledFixedPrice' : CancelledFixedPrice,
      'LaunchFixedPrice' : FixedPrice,
    })
  );
  const NFTMarketplace = IDL.Record({
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
  const Result = IDL.Variant({ 'Ok' : What, 'Err' : UpdateError });
  const Miscellaneous = IDL.Record({
    'description' : IDL.Text,
    'imageId' : IDL.Nat,
    'images' : IDL.Vec(IDL.Tuple(IDL.Nat, IDL.Text)),
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
  const Financials = IDL.Record({
    'valuationId' : IDL.Nat,
    'investment' : InvestmentDetails,
    'pricePerSqFoot' : IDL.Nat,
    'currentValue' : IDL.Nat,
    'valuations' : IDL.Vec(IDL.Tuple(IDL.Nat, ValuationRecord)),
    'monthlyRent' : IDL.Nat,
    'yield' : IDL.Float64,
  });
  const Property = IDL.Record({
    'id' : IDL.Nat,
    'nftMarketplace' : NFTMarketplace,
    'administrative' : AdministrativeInfo,
    'operational' : OperationalInfo,
    'updates' : IDL.Vec(Result),
    'details' : PropertyDetails,
    'financials' : Financials,
  });
  const ReadErrors = IDL.Variant({
    'InvalidElementId' : IDL.Null,
    'DidNotMatchConditions' : IDL.Null,
    'InvalidPropertyId' : IDL.Null,
    'Vacant' : IDL.Null,
    'ArrayIndexOutOfBounds' : IDL.Null,
    'EmptyArray' : IDL.Null,
    'Filtered' : IDL.Null,
  });
  const ElementResult_19 = IDL.Record({
    'id' : IDL.Nat,
    'value' : IDL.Variant({ 'Ok' : ValuationRecord, 'Err' : ReadErrors }),
  });
  const PropertyResult_10 = IDL.Record({
    'result' : IDL.Variant({
      'Ok' : IDL.Vec(ElementResult_19),
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
  const ElementResult_7 = IDL.Record({
    'id' : IDL.Nat,
    'value' : IDL.Variant({ 'Ok' : Listing, 'Err' : ReadErrors }),
  });
  const PropertyResult_4 = IDL.Record({
    'result' : IDL.Variant({
      'Ok' : IDL.Vec(ElementResult_7),
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
  const ElementResult_10 = IDL.Record({
    'id' : IDL.Nat,
    'value' : IDL.Variant({ 'Ok' : Miscellaneous, 'Err' : ReadErrors }),
  });
  const ElementResult_12 = IDL.Record({
    'id' : IDL.Nat,
    'value' : IDL.Variant({ 'Ok' : IDL.Vec(IDL.Nat), 'Err' : ReadErrors }),
  });
  const ElementResult_13 = IDL.Record({
    'id' : IDL.Nat,
    'value' : IDL.Variant({ 'Ok' : Note, 'Err' : ReadErrors }),
  });
  const PropertyResult_6 = IDL.Record({
    'result' : IDL.Variant({
      'Ok' : IDL.Vec(ElementResult_13),
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
  const ElementResult_18 = IDL.Record({
    'id' : IDL.Nat,
    'value' : IDL.Variant({ 'Ok' : IDL.Vec(Result), 'Err' : ReadErrors }),
  });
  const ElementResult_9 = IDL.Record({
    'id' : IDL.Nat,
    'value' : IDL.Variant({ 'Ok' : MaintenanceRecord, 'Err' : ReadErrors }),
  });
  const PropertyResult_5 = IDL.Record({
    'result' : IDL.Variant({
      'Ok' : IDL.Vec(ElementResult_9),
      'Err' : ReadErrors,
    }),
    'propertyId' : IDL.Nat,
  });
  const ElementResult_17 = IDL.Record({
    'id' : IDL.Nat,
    'value' : IDL.Variant({ 'Ok' : Tenant, 'Err' : ReadErrors }),
  });
  const PropertyResult_9 = IDL.Record({
    'result' : IDL.Variant({
      'Ok' : IDL.Vec(ElementResult_17),
      'Err' : ReadErrors,
    }),
    'propertyId' : IDL.Nat,
  });
  const ElementResult_1 = IDL.Record({
    'id' : IDL.Nat,
    'value' : IDL.Variant({ 'Ok' : IDL.Principal, 'Err' : ReadErrors }),
  });
  const ElementResult_15 = IDL.Record({
    'id' : IDL.Nat,
    'value' : IDL.Variant({ 'Ok' : PhysicalDetails, 'Err' : ReadErrors }),
  });
  const ElementResult_11 = IDL.Record({
    'id' : IDL.Nat,
    'value' : IDL.Variant({ 'Ok' : IDL.Nat, 'Err' : ReadErrors }),
  });
  const ElementResult_3 = IDL.Record({
    'id' : IDL.Nat,
    'value' : IDL.Variant({ 'Ok' : Financials, 'Err' : ReadErrors }),
  });
  const ElementResult_16 = IDL.Record({
    'id' : IDL.Nat,
    'value' : IDL.Variant({ 'Ok' : IDL.Vec(Refund), 'Err' : ReadErrors }),
  });
  const PropertyResult_8 = IDL.Record({
    'result' : IDL.Variant({
      'Ok' : IDL.Vec(ElementResult_16),
      'Err' : ReadErrors,
    }),
    'propertyId' : IDL.Nat,
  });
  const ElementResult_8 = IDL.Record({
    'id' : IDL.Nat,
    'value' : IDL.Variant({ 'Ok' : LocationDetails, 'Err' : ReadErrors }),
  });
  const ElementResult = IDL.Record({
    'id' : IDL.Nat,
    'value' : IDL.Variant({ 'Ok' : AdditionalDetails, 'Err' : ReadErrors }),
  });
  const ElementResult_14 = IDL.Record({
    'id' : IDL.Nat,
    'value' : IDL.Variant({ 'Ok' : IDL.Vec(Payment), 'Err' : ReadErrors }),
  });
  const PropertyResult_7 = IDL.Record({
    'result' : IDL.Variant({
      'Ok' : IDL.Vec(ElementResult_14),
      'Err' : ReadErrors,
    }),
    'propertyId' : IDL.Nat,
  });
  const ReadResult = IDL.Variant({
    'Valuation' : IDL.Vec(PropertyResult_10),
    'Inspection' : IDL.Vec(PropertyResult_2),
    'Listings' : IDL.Vec(PropertyResult_4),
    'Insurance' : IDL.Vec(PropertyResult_3),
    'Misc' : IDL.Vec(ElementResult_10),
    'NFTs' : IDL.Vec(ElementResult_12),
    'Note' : IDL.Vec(PropertyResult_6),
    'Image' : IDL.Vec(PropertyResult_1),
    'Document' : IDL.Vec(PropertyResult),
    'UpdateResults' : IDL.Vec(ElementResult_18),
    'Maintenance' : IDL.Vec(PropertyResult_5),
    'Tenants' : IDL.Vec(PropertyResult_9),
    'CollectionIds' : IDL.Vec(ElementResult_1),
    'Physical' : IDL.Vec(ElementResult_15),
    'MonthlyRent' : IDL.Vec(ElementResult_11),
    'Financials' : IDL.Vec(ElementResult_3),
    'Refunds' : IDL.Vec(PropertyResult_8),
    'Location' : IDL.Vec(ElementResult_8),
    'Additional' : IDL.Vec(ElementResult),
    'PaymentHistory' : IDL.Vec(PropertyResult_7),
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
  const LaunchProperty = IDL.Record({
    'quoteAsset' : IDL.Opt(AcceptedCryptos),
    'propertyId' : IDL.Nat,
    'price' : IDL.Nat,
    'endsAt' : IDL.Opt(IDL.Int),
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
  const ConditionalBaseRead = IDL.Record({
    'base' : BaseRead,
    'conditionals' : ListingConditionals,
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
    'Listings' : ConditionalBaseRead,
    'Insurance' : BaseRead,
    'Images' : BaseRead,
    'Misc' : Selected,
    'Note' : BaseRead,
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
  const Result__1 = IDL.Variant({ 'ok' : Property, 'err' : Error });
  const TestOption = IDL.Variant({
    'All' : IDL.Null,
    'TenantDelete' : IDL.Null,
    'FinancialsCreate' : IDL.Null,
    'DescriptionUpdate' : IDL.Null,
    'ValuationDelete' : IDL.Null,
    'NoteCreate' : IDL.Null,
    'TenantCreate' : IDL.Null,
    'NoteUpdate' : IDL.Null,
    'TenantUpdate' : IDL.Null,
    'ValuationCreate' : IDL.Null,
    'ValuationUpdate' : IDL.Null,
    'MaintenanceDelete' : IDL.Null,
    'AdditionalDetailsUpdate' : IDL.Null,
    'ImagesDelete' : IDL.Null,
    'MaintenanceCreate' : IDL.Null,
    'ImagesCreate' : IDL.Null,
    'MaintenanceUpdate' : IDL.Null,
    'ImagesUpdate' : IDL.Null,
    'DocumentDelete' : IDL.Null,
    'DocumentCreate' : IDL.Null,
    'InspectionDelete' : IDL.Null,
    'DocumentUpdate' : IDL.Null,
    'InsuranceDelete' : IDL.Null,
    'InspectionCreate' : IDL.Null,
    'InspectionUpdate' : IDL.Null,
    'InsuranceCreate' : IDL.Null,
    'InsuranceUpdate' : IDL.Null,
    'PhysicalDetailsUpdate' : IDL.Null,
    'MonthlyRentCreate' : IDL.Null,
    'NoteDelete' : IDL.Null,
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
  const UpdateResult = IDL.Variant({ 'Ok' : Property, 'Err' : UpdateError });
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
    'launchProperty' : IDL.Func(
        [LaunchProperty],
        [IDL.Vec(UpdateResultNat)],
        [],
      ),
    'readProperties' : IDL.Func(
        [IDL.Vec(Read2), IDL.Opt(FilterProperties)],
        [IDL.Vec(ReadResult)],
        ['query'],
      ),
    'removeProperty' : IDL.Func([IDL.Nat], [Result__1], []),
    'runTests' : IDL.Func([TestOption], [], []),
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
    'updateProperty' : IDL.Func([WhatWithPropertyId], [UpdateResult], []),
    'updatePropertyValuations' : IDL.Func([], [IDL.Vec(UpdateResult)], []),
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
