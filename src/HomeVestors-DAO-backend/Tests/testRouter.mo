import TestTypes "testTypes";
import Types "../types";
import Admin "./Domains/administration";
import Details "./Domains/details";
import Invoices "./Domains/invoices";
import Marketplace "./Domains/nftmarketplace";
import Operations "./Domains/operations";
import Gov "./Domains/proposals";
import Financials "./Domains/financials";

import Principal "mo:base/Principal";
import Buffer "mo:base/Buffer";
import Text "mo:base/Text";
import TProp "createProperty";
import Debug "mo:base/Debug";



module {
    public func runTestsForOption(option: TestTypes.TestOption, handleUpdate: (Types.WhatWithPropertyId, Principal) -> async Types.UpdateResultExternal) : async [[Text]] {
        let buf = Buffer.Buffer<[Text]>(0);
        var property = TProp.createBlankProperty();

        if (option == #All or option == #Note) buf.add(await Admin.createNoteTestType2(property, handleUpdate));
        if (option == #All or option == #Insurance) buf.add(await Admin.createInsuranceTestType(property, handleUpdate));
        if (option == #All or option == #Document) buf.add(await Admin.createDocumentTestType2(property, handleUpdate));
        if (option == #All or option == #Tenant) buf.add(await Operations.createTenantTestType2(property, handleUpdate));
        if (option == #All or option == #Maintenance) buf.add(await Operations.createMaintenanceTestType2(property, handleUpdate));
        if (option == #All or option == #Inspection) buf.add(await Operations.createInspectionTestType2(property, handleUpdate));
        if (option == #All or option == #Valuation) buf.add(await Financials.createValuationTestType2(property, handleUpdate));
        if (option == #All or option == #Images) buf.add(await Details.createImageTestType2(property, handleUpdate));
        if (option == #All or option == #NFTMarketplaceFixedPrice) buf.add(await Marketplace.createFixedPriceTestType2(property, handleUpdate));
        if (option == #All or option == #NFTMarketplaceAuction) buf.add(await Marketplace.createAuctionTestType2(property, handleUpdate));
        if (option == #All or option == #NFTMarketplaceLaunch) buf.add(["⚠️ NFTMarketplaceLaunch tests not implemented yet"]);
        if (option == #All or option == #Proposal) buf.add(await Gov.createProposalTestType2(property, handleUpdate));
        if (option == #All or option == #Invoice) buf.add(await Invoices.createInvoiceTestType2(property, handleUpdate));
        if (option == #All or option == #Financials) buf.add(await Financials.createFinancialTestType2(property, handleUpdate));
        if (option == #All or option == #MonthlyRent) buf.add(await Financials.createMonthlyRentTestType2(property, handleUpdate));
        if (option == #All or option == #PhysicalDetails) buf.add(await Details.createPhysicalDetailsTestType2(property, handleUpdate));
        if (option == #All or option == #AdditionalDetails) buf.add(await Details.createAdditionalDetailsTestType2(property, handleUpdate));
        if (option == #All or option == #Description) buf.add(await Details.createDescriptionTestType2(property, handleUpdate));
        if (option == #All or option == #Bid) buf.add(await Marketplace.createBidHandlersTest(property, handleUpdate));
        if (option == #All or option == #Vote) buf.add(await Gov.createVoteHandlersTest(property, handleUpdate));
        
        let arr = Buffer.toArray(buf);
        Debug.print(debug_show(arr));
        arr;
    };



    
}