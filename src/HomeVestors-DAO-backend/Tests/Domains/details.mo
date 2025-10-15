import UnstableTypes "./../unstableTypes";
import Types "./../../types";
import TestTypes "./../testTypes";
import Utils "./../utils";

import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";

module{
    type Actions<C,U> = Types.Actions<C,U>;
    type PropertyUnstable = UnstableTypes.PropertyUnstable;
    type WhatWithPropertyId = Types.WhatWithPropertyId;
    type UpdateResult = Types.UpdateResult;
    type  PreTestHandler<C, U, T> = TestTypes. PreTestHandler<C, U, T>;
    type FlatPreTestHandler<U,T> = TestTypes.FlatPreTestHandler<U,T>;

    

    // ====================== IMAGES ======================
public func createImageTestType2(property: PropertyUnstable, handlePropertyUpdate: (Types.WhatWithPropertyId, Principal) -> async Types.UpdateResultBeforeVsAfter):async [Text] {
    type C = Text;
    type U = Text;
    type T = Text; // stored directly

    let cArg : C = "initial url to image";
    let uArg : U = "updated url to image";

    let imageCases : [(Text, Actions<C,U>, Bool)] = [
        // CREATE
        Utils.ok("Image: create valid",       #Create([cArg])),
        Utils.err("Image: empty URL",         #Create([""])),

        // UPDATE
        Utils.ok("Image: update valid",       #Update((uArg, [0]))),
        Utils.err("Image: update non-existent", #Update((uArg, [0]))),
        Utils.err("Image: update empty URL",  #Update(("", [0]))),

        // DELETE
        Utils.ok("Image: delete valid",       #Delete([0])),
        Utils.err("Image: delete non-existent",#Delete([9999]))
    ];

    let handler : PreTestHandler<C,U,T> = {
        testing = false;
        handlePropertyUpdate;
        toHashMap   = func(p: PropertyUnstable) = p.details.misc.images;
        showMap     = func(map: HashMap.HashMap<Nat,T>) = debug_show(Iter.toArray(map.entries()));
        toId        = func(p: PropertyUnstable) = p.details.misc.imageId;
        toWhat      = func(action: Actions<C,U>) = #Images(action);

        checkUpdate = func(before: T, after: T, arg: U): Text {
            var s = "";
            s #= Utils.assertUpdate2("image", #OptText(?before), #OptText(?after), #OptText(?arg));
            s;
        };

        checkCreate = Utils.createDefaultCheckCreate();
        checkDelete = Utils.createDefaultCheckDelete();
        seedCreate = Utils.createDefaultSeedCreate(cArg);
        validForTest = Utils.createDefaultValidForTest(["Image: update non-existent", "Image: delete non-existent"]);
    };

    await Utils.runGenericCases<C,U,T>(property, handler, imageCases)
};

public func createDescriptionTestType2(
    property: PropertyUnstable,
    handlePropertyUpdate: (Types.WhatWithPropertyId, Principal) -> async Types.UpdateResultBeforeVsAfter
) : async [Text] {
    type U = Text;
    type T = UnstableTypes.MiscellaneousUnstable;

    let descCases : [(Text, U, Bool)] = [
        Utils.ok1("Description: valid", "updated description of property"),
        Utils.err1("Description: empty", "")
    ];

    let handler : FlatPreTestHandler<U,T> = {
        handlePropertyUpdate;
        toStruct   = func(p: PropertyUnstable) = p.details.misc;
        toWhat     = func(arg: U) = #Description(arg);

        checkUpdate = func(before: PropertyUnstable, after: PropertyUnstable, arg: U): Text {
            Utils.assertUpdate2("description", #OptText(?before.details.misc.description), #OptText(?after.details.misc.description), #OptText(?arg));
        };
    };

    await Utils.runFlatGenericCases<U,T>(property, handler, descCases);
};


// PHYSICAL DETAILS
public func createPhysicalDetailsTestType2(property: PropertyUnstable, handlePropertyUpdate: (Types.WhatWithPropertyId, Principal) -> async Types.UpdateResultBeforeVsAfter) : async [Text] {
    type U = Types.PhysicalDetailsUArg;
    type T = UnstableTypes.PhysicalDetailsUnstable;
    func createPhysicalDetailsUArg(): U {
        {
            lastRenovation = ?2000;
            yearBuilt = ?0;
            squareFootage = ?100;
            beds = ?0;
            baths = ?0;
        }
    };

    let arg = createPhysicalDetailsUArg();

    let physicalCases : [(Text, U, Bool)] = [
        Utils.ok1("Physical: valid", arg),
        Utils.err1("Physical: renovation too old", { arg with lastRenovation = ?1890 }),
        Utils.err1("Physical: too many beds", { arg with beds = ?11 }),
        Utils.err1("Physical: too many baths", { arg with baths = ?11 })
    ];

    let handler : FlatPreTestHandler<U,T> = {
        handlePropertyUpdate;
        toStruct   = func(p: PropertyUnstable) = p.details.physical;
        toWhat     = func(arg: U) = #PhysicalDetails(arg);

        checkUpdate = func(before: PropertyUnstable, after: PropertyUnstable, arg: U): Text {
            Utils.assertUpdate2("beds", #OptNat(?before.details.physical.beds), #OptNat(?after.details.physical.beds), #OptNat(arg.beds))
            # Utils.assertUpdate2("baths", #OptNat(?before.details.physical.baths), #OptNat(?after.details.physical.baths), #OptNat(arg.baths))
            # Utils.assertUpdate2("lastRenovation", #OptNat(?before.details.physical.lastRenovation), #OptNat(?after.details.physical.lastRenovation), #OptNat(arg.lastRenovation));
        };
    };

    await Utils.runFlatGenericCases<U,T>(property, handler, physicalCases);
};


// ADDITIONAL DETAILS
public func createAdditionalDetailsTestType2(
    property: PropertyUnstable,
    handlePropertyUpdate: (Types.WhatWithPropertyId, Principal) -> async Types.UpdateResultBeforeVsAfter
) : async [Text] {
    type U = Types.AdditionalDetailsUArg;
    type T = UnstableTypes.AdditionalDetailsUnstable;
    func createAdditionalDetailsUArg(): Types.AdditionalDetailsUArg {
        {
            crimeScore = ?150;
            schoolScore = ?5;
            affordability = ?0;
            floodZone = ?false;
        }
    };

    let arg = createAdditionalDetailsUArg();

    let additionalCases : [(Text, U, Bool)] = [
        Utils.ok1("Additional: valid", arg),
        Utils.err1("Additional: low crime score", { arg with crimeScore = ?10 }),
        Utils.err1("Additional: high school score", { arg with schoolScore = ?11 })
    ];

    let handler : FlatPreTestHandler<U,T> = {
        handlePropertyUpdate;
        toStruct   = func(p: PropertyUnstable) = p.details.additional;
        toWhat     = func(arg: U) = #AdditionalDetails(arg);

        checkUpdate = func(before: PropertyUnstable, after: PropertyUnstable, arg: U): Text {
            Utils.assertUpdate2("crimeScore", #OptNat(?before.details.additional.crimeScore), #OptNat(?after.details.additional.crimeScore), #OptNat(arg.crimeScore))
            # Utils.assertUpdate2("schoolScore", #OptNat(?before.details.additional.schoolScore), #OptNat(?after.details.additional.schoolScore), #OptNat(arg.schoolScore));
        };
    };

    await Utils.runFlatGenericCases<U,T>(property, handler, additionalCases);
};

}