# HomeVestors DAO

## Overview

HomeVestors DAO is a decentralized, full-stack property governance system built on the Internet Computer.  
Each property is represented by a deeply structured on-chain record containing:

- **Operational data** (tenants, maintenance, inspections)  
- **Financial data** (valuations, invoices, rental flows)  
- **Administrative data** (documents, insurance, notes)  
- **Governance** (proposals, voting, execution)  
- **Marketplace** (fixed-price listings, auctions, property launches)  
- **User notifications** (alerts to investors)  

All updates flow through a uniform handler system, ensuring validation, immutability, async side-effects, and traceability.


## Architecture

### Handler Pipeline

Every domain uses the same update pipeline:
validate → asyncEffect → applyAsyncEffects → applyUpdate → finalAsync

This ensures:

- **Consistency** across modules  
- **Auditability** of all state changes  
- **Extensibility** when new modules are added  

### Core types (motoko):

- public type Property
- public type What - Enum for each domain
- public type Handler<T, StableT> = { … } - the central flow for all domains
- public type Action {Create, Update, Delete} - Enum for each action type
- public type CrudHandler<C, U, T, StableT> = { … } - the handler for crud Actions across all domains

# Modules

## `property.mo`

- Core entry point for property lifecycle  
- Coordinates create/update/delete across all submodules  
- Maintains the full `Property` struct, embedding financials, operational data, governance, marketplace state, and administrative info  

---

## `operational.mo`

- **Tenants**: lease details, deposits, rent, linked principals  
- **Inspections**: validated against current time, prevents invalid scheduling  
- **Maintenance**: cost, status, contractor, reported/completed dates  
- Fully handler-driven with strict validation (e.g. `rent > 0`, no future dates)  

---

## `financials.mo`

- Tracks property investment details, NAV, and performance  
- Integrates with invoices for rental flows and distributions  
- Records valuations and yield metrics  

---

## `invoices.mo`

- **Lifecycle**: Draft → Approved → Paid/Failed  
- Async token transfer integration  
- Supports recurring invoices with automatic timer scheduling  
- Handles both incoming (tenant → property) and outgoing (property → contractors/investors) flows  
- Distributes income proportionally to NFT holders (via external NFT canister)  

---

## `governance/proposals.mo`

- Full on-chain governance system for each property  
- **Proposal categories**: maintenance, rent, tenancy, valuations, invoices, admin, operations, other  
- **Voting**: timed periods (hours → weeks)  
- **Participation**: NFT holders vote; some categories require tenant approval/veto  
- **Execution**: approved proposals trigger property actions (e.g. invoice approval)  
- Immutable history of votes and outcomes  

---

## `marketplace/`

Implements the property/NFT marketplace logic:

### Fixed-Price Listings
- Create/update/delete at a set price  
- Auto-cancel on expiry or withdrawal  

### Auctions
- Live bidding with reserve/buy-now options  
- Refunds for previous highest bidders  
- Auto-close at expiry  

### Launches
- Bulk property NFT launches (e.g. 1,000 tokens)  
- Parent–child relationships between launch and sub-listings  
- Handles staged token transfers  

**Common features:**
- Bulk NFT/token transfers in/out of canisters  
- Royalty support  
- Timers for expiry/cancellation  
- Query functions for sellers, buyers, and bidders  

---

## `administrative.mo`

- Handles property-level documents, insurance policies, and notes  
- Ensures immutability and traceability of all records  

---

## `details.mo`

- Stores physical property attributes  
- Tracks scoring metrics (affordability, crime, schools, etc.)  

---

## `userNotifications.mo`

- Sends notifications to all current NFT holders on every successful update  
- Provides an on-chain activity feed of property events  

---

## `propHelper.mo`

- Shared utility layer across all modules  
- Provides validation, mutation helpers, delete handlers, and generic handler generation  
- Applies state changes immutably and logs who/what/when for auditability  

---

## `types.mo`

- Central type definitions for all modules  
- Defines `Property`, `Tenant`, `Invoice`, `Proposal`, `Listing`, `Update`, and error/result types  

---

## `token.mo`

- Token transfer utilities  
- Interfaces with external token canisters for ICP/HGB/etc.  
- Used by invoices and marketplace flows  

---

# Design Principles

- **Uniformity**: All domains use the same handler architecture  
- **Auditability**: Immutable history of every change  
- **Extensibility**: Adding modules (e.g. taxes, insurance) follows the same pattern  
- **DAO-Driven**: Investor governance replaces centralized property management  
- **On-Chain Liquidity**: Built-in marketplace integrates with financial flows  

---

# Next Steps

- Expand stablecoin (HGB) integration across financials and marketplace  
- Refine valuation and property scoring mechanisms  
- Deploy live properties to production  
- Integrate with SNS for protocol-level governance  
