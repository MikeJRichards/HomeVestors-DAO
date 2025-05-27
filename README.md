# HomeVestors DAO - Milestone 1 Documentation

## Overview

HomeVestors DAO is a transformative, fully decentralized, full-stack solution designed to enhance flexibility and adaptability in the UK’s increasingly challenging buy-to-let property market. Rising mortgage costs and restrictive government policies have made property investment more burdensome and risky, driving many landlords out of the market.

In contrast, HomeVestors DAO empowers investors with dynamic options, providing both flexibility and direct control through governance. Each property functions as its own DAO with a dedicated account, enabling investors to control key decisions like tenant selection, maintenance, and expenses while eliminating time-consuming property management.

Our model introduces liquidity through fractionalized property NFTs and our stablecoin, allowing investors to seamlessly buy, sell, leverage, or de-leverage their assets as life’s needs evolve. Whether investors seek full control over property management decisions or prefer a passive approach, HomeVestors DAO adapts to their preferences, unlocking access to property governance that aligns with modern financial and personal realities.

---

## System Architecture

### Core Concepts

- **Property NFT Collections**: Each property has a dedicated ICRC-7 and ICRC-37 compliant NFT collection representing fractional ownership.
- **DAO Governance**: Each NFT holder can vote on property-related proposals.
- **Modular Data Layers**: Properties contain deeply structured metadata across five domains:
  - Property details
  - Financials
  - Administrative
  - Operational
  - NFT Marketplace

---

### System Modules

The platform is organized into modular, file-based components that separate logic by domain. This structure enhances readability, testability, and scalability as the system grows.

- **Property Module**: Coordinates property creation and routes updates to the appropriate module based on the `What` action type.
- **Administrative Module**: Handles operations related to documents, insurance policies, and notes. Contains its own validation and mutation logic.
- **Operational Module**: Manages tenants, inspections, and maintenance workflows.
- **Financials Module**: Controls purchase data, rental income, yield calculations, and valuation tracking. Integrates with the valuation outcall logic.
- **Details Module**: Encapsulates logic for physical attributes and scoring metrics such as crime, affordability, and school quality.
- **NFT Module**: Interfaces with ICRC-7/37-compliant NFT collections for minting, ownership tracking, and metadata updates.
- **User Notifications Module**: Sends on-chain alerts to all holders of property NFTs following any successful update.
- **PropHelper (Utils)**: A centralized utility module that applies the final, validated `Intent` to the stable `Property` struct. It also:
  - Updates the property's persistent updates history with a record of who made the change, when it occurred, and what was changed.
  - Returns the modified struct back to the main actor to make the change permanent.

---

## Key Flows

### Property Creation

- Triggered via `createProperty()`
- Requires a new NFT collection canister to be deployed externally.
- Metadata returned from the NFT canister is used to create the full `Property` struct.

### NFT Metadata Synchronization

- Every successful update triggers `handleNFTMetadataUpdate()`, which updates the ICRC-7 collection metadata.
- Ensures that external viewers and marketplaces always reflect accurate property state.

### Data Retrieval

- `readProperty()` returns sanitized, structured data based on a `Read` selector and property ID.
- All user-readable information can be extracted without exposing sensitive or internal logic.

---

## Create, Update, and Delete Flow & Logic

The update flow is strictly pattern-driven and modular, following a “What then How” design principle:

1. The `handlePropertyUpdate()` function retrieves the target property and triggers a call to `updateProperty()` in the Property module.
2. This function switches on the `What` type, routing the action to the relevant domain module.
3. Inside the domain module, a second switch occurs on the action type — `create`, `update`, or `delete` — defined by the `Actions<CreateArg, (UpdateArg, Nat)>` interface.
4. Validation uses a unified function that checks each argument and returns either:
   - A sanitized update, or
   - A detailed error (e.g., invalid date, empty string, or zero value).
5. All update arguments are fully nullable, allowing minimal and flexible changes.
6. A sanitized `Intent` is passed to the PropHelper:
   - Mutates the relevant part of the `Property` struct immutably.
   - Ensures consistency and traceability.
7. After a successful state change:
   - All current NFT holders are notified.
   - The update is logged in the immutable history (with what, when, and who).

This ensures:

- A uniform update pattern across all domains.
- Clear separation of concerns between validation, logic, and mutation.
- High scalability and ease of adding new modules/actions.

---

## NFT Design and Implementation

Although Milestone 1 only required ICRC-7, HomeVestors DAO integrates both ICRC-7 and ICRC-37 standards to support fractional ownership with advanced access control, approvals, metadata handling, and future governance utility.

### Architecture and Standards

- **ICRC-7 Compliance**:
  - Minting
  - Transfer
  - Burn
  - Balance queries
  - Owner queries
  - Metadata
  - Pagination
  - Token enumeration

- **ICRC-37 Extensions**:
  - `approve`, `transfer_from`, `revoke`
  - Delegated transfers with related metadata

- **Collection Metadata**:
  - Stored in `HashMap<Text, Value>`
  - Includes all ICRC-7 fields + property-specific metadata (valuation, rent, address)

---

## Validation System

To avoid per-method validation repetition, all validation flows through:

```motoko
validate<T <: BaseArg>(
  arg: Arg,
  x: T,
  authorized: ?Authorized,
  spender: ?Account,
  caller: Principal,
  ctx: TxnContext,
  count: Nat
)
