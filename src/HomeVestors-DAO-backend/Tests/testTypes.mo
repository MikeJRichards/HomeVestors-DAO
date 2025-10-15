import Types "../types";
import UnstableTypes "unstableTypes";
import HashMap "mo:base/HashMap";

module TestTypes {
  type What = Types.What;
  type Property = Types.Property;
  type PropertyUnstable = UnstableTypes.PropertyUnstable;
  type UpdateResult = Types.UpdateResult;
  type Actions<C,U> = Types.Actions<C,U>;

  public type SingleActionPreTestHandler<C, T> = {
    testing: Bool;
    toHashMap: PropertyUnstable -> HashMap.HashMap<Nat, T>;
    showMap: HashMap.HashMap<Nat, T> -> Text;
    toWhat: C -> What;
    checkUpdate: (T, T, C) -> Text;
    handlePropertyUpdate: (Types.WhatWithPropertyId, Principal) -> async Types.UpdateResultBeforeVsAfter;
    seedCreate: (Text, PropertyUnstable) -> [What];
    validForTest: (Text, T) -> ?Bool;
    toCaller: (Text, Nat, PropertyUnstable) -> Principal;
    setId: (Nat, C) -> C;
  };

  public type PreTestHandler<C, U, T> = {
    testing: Bool;
    toHashMap: PropertyUnstable -> HashMap.HashMap<Nat, T>;
    showMap: HashMap.HashMap<Nat, T> -> Text;
    toId: PropertyUnstable -> Nat;
    toWhat: Types.Actions<C,U> -> What;
    checkCreate: T -> Text;
    checkUpdate: (T, T, U) -> Text;
    checkDelete: (T, ?T, Nat, PropertyUnstable, PropertyUnstable, PreTestHandler<C,U,T>) -> Text;
    handlePropertyUpdate: (Types.WhatWithPropertyId, Principal) -> async Types.UpdateResultBeforeVsAfter;
    seedCreate: (Text, Nat, Actions<C,U> ->What) -> [What];
    validForTest: (Text, T) -> ?Bool;
  };

  public type FlatPreTestHandler<U, T> = {
    toStruct: PropertyUnstable -> T;
    toWhat: U -> What;
    checkUpdate: (PropertyUnstable, PropertyUnstable, U) -> Text;
    handlePropertyUpdate: (Types.WhatWithPropertyId, Principal) -> async Types.UpdateResultBeforeVsAfter;
  };

  public type Callers = {
    anon: Principal;
    seller: Principal;
    buyer: Principal;
    tenant1: Principal;
    tenant2: Principal;
    admin: Principal;
  };

  public type Value = {
    #OptInt  : ?Int;
    #OptNat  : ?Nat;
    #OptFloat: ?Float;
    #OptText : ?Text;
    #OptBool : ?Bool;
  };

  public type TestOption = {
    #NFTMarketplaceFixedPrice;
    #NFTMarketplaceAuction;
    #NFTMarketplaceLaunch;
    #Bid;
    #Proposal;
    #Vote;
    #Invoice;
    #Note;
    #Insurance;
    #Document;
    #Tenant;
    #Maintenance;
    #Inspection;
    #Valuation;
    #Financials;
    #MonthlyRent;
    #PhysicalDetails;
    #AdditionalDetails;
    #Images;
    #Description;
    #All;
  };

}