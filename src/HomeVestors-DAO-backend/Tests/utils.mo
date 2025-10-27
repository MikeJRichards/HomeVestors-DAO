import UnstableTypes "./unstableTypes";
import Stables "./stables";
import Types "./../types";
import TestTypes "./testTypes";
import Property "./../property";

import Time "mo:base/Time";
import Nat "mo:base/Nat";
import Option "mo:base/Option";
import Int "mo:base/Int";
import Buffer "mo:base/Buffer";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Debug "mo:base/Debug";
//import Iter "mo:base/Iter";
import HashMap "mo:base/HashMap";
import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Nat8 "mo:base/Nat8";

module{
    type Actions<C,U> = Types.Actions<C,U>;
    type PropertyUnstable = UnstableTypes.PropertyUnstable;
    type WhatWithPropertyId = Types.WhatWithPropertyId;
    type UpdateResult = Types.UpdateResult;
    type SingleActionPreTestHandler<U, T> = TestTypes.SingleActionPreTestHandler<U, T>;
    type PreTestHandler<C, U, T> = TestTypes. PreTestHandler<C, U, T>;
    type FlatPreTestHandler<U, T> = TestTypes.FlatPreTestHandler<U, T>;
    type Value = TestTypes.Value;

    public func safeSub(nat1: Nat, nat2: Nat): Nat {
        if(nat1 > nat2) Nat.sub(nat1, nat2) else 0;
    };

    func assertCreated2<C, U, T>(testCase: Text, propBefore: PropertyUnstable, propertyAfter: Types.Property, handler: PreTestHandler<C, U, T>): Text{
        var string = "";
        let propAfter = Stables.fromStableProperty(propertyAfter);
        let mapBefore = handler.toHashMap(propBefore);
        let mapAfter = handler.toHashMap(propAfter);
        let idBefore = handler.toId(propBefore);
        let idAfter = handler.toId(propAfter);
        if(mapAfter.size() != mapBefore.size() + 1) string := " Map size did not increment \n";
        if(propAfter.updates.size() != propBefore.updates.size() + 1) string := string #" updates log size did not increase \n";
        if(idBefore == idAfter) string := string # " the id did not increase \n";
        if(Option.isSome(mapBefore.get(idAfter))) string := string # " new id key existed in map before - overriden data \n";
        switch(mapAfter.get(idAfter)){
            case(null) string := string # " created element does not exist in map \n";
            case(?el) string := string # handler.checkCreate(el);
        };
        if(string == "") return "\n ✅ " # debug_show(testCase) else return "\n ❌ " # debug_show(testCase) # " failed \n" # string # printMaps(mapBefore, mapAfter, handler);
    };

    func printMaps<C,U,T>(mapBefore: HashMap.HashMap<Nat, T>, mapAfter: HashMap.HashMap<Nat, T>, handler: PreTestHandler<C, U, T>): Text {
        "\n map before: "# handler.showMap(mapBefore) # "\n map after"# handler.showMap(mapAfter);
    };

    func assertDeleted2<C, U, T>(testCase: Text, propBefore: PropertyUnstable, propertyAfter: Types.Property, handler: PreTestHandler<C, U, T>, deletedIds: [Int]): Text{
        var string = "";
        let propAfter = Stables.fromStableProperty(propertyAfter);
        let mapBefore = handler.toHashMap(propBefore);
        let mapAfter = handler.toHashMap(propAfter);
        let idBefore = handler.toId(propBefore);
        let idAfter = handler.toId(propAfter);
        if(propAfter.updates.size() != propBefore.updates.size() + 1) string := string # " updates log size did not increase \n";
        if(idBefore != idAfter) string := string # " the id changed \n";
        for (id in deletedIds.vals()){
            switch(mapBefore.get(Int.abs(id))){
                case(null) string #= " element with id " # debug_show(id) # " didn't exist \n";
                case(?before) string #= handler.checkDelete(before, mapAfter.get(Int.abs(id)), Int.abs(id), propBefore, propAfter, handler);
            };
        }; 
        if(string == "") return "\n ✅ " # debug_show(testCase) else return "\n ❌ " # debug_show(testCase) # " failed \n"#string # printMaps(mapBefore, mapAfter, handler);
    };


    public func assertUpdate2(fieldName: Text, before: Value, after: Value, arg: Value) : Text {
        // local helper: shared null/?val check
        func checkOpt<T>(argOpt: ?T, cons: T -> Value) : Text {
            switch argOpt {
                case null {
                    if (before != after) {
                        return " field " # fieldName # " should not have changed \n";
                    };
                };
                case (?val) {
                    if (after != cons(val)) {
                        return " field " # fieldName # " not updated correctly (before "
                             # debug_show(before) # " expected " # debug_show(cons(val))
                             # ", got " # debug_show(after) # ")\n";
                    };
                };
            };
            "";
        };

        switch arg {
            case (#OptInt(v))   return checkOpt<Int>(v, func x = #OptInt(?x));
            case (#OptNat(v))   return checkOpt<Nat>(v, func x = #OptNat(?x));
            case (#OptFloat(v))  return checkOpt<Float>(v, func x = #OptFloat(?x));
            case (#OptText(v))  return checkOpt<Text>(v, func x = #OptText(?x));
            case (#OptBool(v))  return checkOpt<Bool>(v, func x = #OptBool(?x));
        };
    };

    public func assertEqual<T>(fieldName: Text, expected: T, actual: T, eq: (T, T) -> Bool, show: T -> Text) : Text {
        if (not eq(expected, actual)) {
            return " field " # fieldName # " mismatch (expected "
                 # show(expected) # ", got " # show(actual) # ")\n";
        };
        ""
    };

    public func assertUnchanged<T>(fieldName: Text, before: T, after: T, eq: (T, T) -> Bool, show: T -> Text) : Text {
        if (not eq(before, after)) {
            return " field " # fieldName # " should not have changed (before "
                 # show(before) # ", after " # show(after) # ")\n";
        };
        ""
    };

    func handleUpdate<C, U, T>(testCase: Text, propBefore: PropertyUnstable, propertyAfter: Types.Property, handler: PreTestHandler<C, U, T>, updatedIds: [Int], arg: U): Text {
        var string = "";
        var propAfter = Stables.fromStableProperty(propertyAfter);
        let mapBefore = handler.toHashMap(propBefore);
        let mapAfter = handler.toHashMap(propAfter);
        for(id in updatedIds.vals()){
            switch(mapBefore.get(Int.abs(id)), mapAfter.get(Int.abs(id))){
                case(?elBefore, ?elAfter) string #= handler.checkUpdate(elBefore, elAfter, arg);
                case(null, ?_) string #= " Before there was no element with id "#debug_show(id)# "\n";
                case(?_, null) string #=" After there was no element with the id "#debug_show(id)# "\n";
                case(null, null) string #= " There was no element before or after function" # debug_show(id)#"\n";
            }
        };
        if(string == "") return "\n ✅ " # debug_show(testCase) else return "\n ❌ " # debug_show(testCase) # " failed \n"#string # printMaps(mapBefore, mapAfter, handler);
    };

    public func assertError<R>(output: Text, testCase: Text, result: UpdateResult): Text{
      switch(result) {
        case (#Property(_)) return output # "\n ❌ " # debug_show(testCase) # " failed okay was returned ";
        case (#Err(_))  output # "\n ✅ " # debug_show(testCase);
      };
    };

    public func createDefaultCheckCreate<T>(): T -> Text {
        func(_: T) = "";
    };

    public func createDefaultValidForTest<T>(nullLabels: [Text]): (Text, T) -> ?Bool {
        func(labels: Text, _: T): ?Bool {
            for(nullLabel in nullLabels.vals()){
                if(labels == nullLabel) return null;
            };
            return ?true;
        }
    };

    public func createDefaultSeedCreate<C, U>(cArg: C): (Text, Nat, Actions<C,U> -> Types.What) -> [Types.What] {
        func(_: Text, _: Nat, toWhat: Actions<C,U> -> Types.What) = [toWhat(#Create([cArg, cArg, cArg]))];
    };

    public func createDefaultCheckDelete<C, U, T>(): (T, ?T, Nat, PropertyUnstable, PropertyUnstable, PreTestHandler<C,U,T>) -> Text {
        func(before: T, after: ?T, id: Nat, propBefore: PropertyUnstable, propAfter: PropertyUnstable, handler: PreTestHandler<C,U,T>): Text {
            var s = "";
            if(safeSub(handler.toHashMap(propBefore).size(), 1) != handler.toHashMap(propAfter).size()) s #= "\n The map before and after are the same size, no element was deleted";
            switch(after){
                case(null){};
                case(?_) s #= " element with id " # debug_show(id) # " still exists after deletion attempt\n";
            };
            s;
        };
    };

    public func ok<C,U>(labels: Text, a: Actions<C,U>) : (Text, Actions<C,U>, Bool) = (labels, a, true);
    public func ok1<U>(labels: Text, a: U) : (Text, U, Bool) = (labels, a, true);
    public func err<C,U>(labels: Text, a: Actions<C,U>) : (Text, Actions<C,U>, Bool) = (labels, a, false);
    public func err1<U>(labels: Text, a: U) : (Text, U, Bool) = (labels, a, false);

    public func daysInFuture(days: Int): Int {
        Time.now() + days * 24 * 60 * 60 * 1_000;
    };

    public func getCallers(): TestTypes.Callers {
        {
            anon = Principal.fromText("2vxsx-fae");
            seller = Principal.fromText("2e7fg-mfyxt-iivfx-l7pim-ysvwq-qetwz-h4rhz-t76tr-5zob4-oopr3-hae");
            buyer = Principal.fromText("fdiem-i5wk4-rm5ln-2jctb-zn7b7-wy6qb-vga36-7wodq-4clo4-5ewbb-5qe");
            tenant1 = Principal.fromText("2e7fg-mfyxt-iivfx-l7pim-ysvwq-qetwz-h4rhz-t76tr-5zob4-oopr3-hae");
            tenant2 = Principal.fromText("fdiem-i5wk4-rm5ln-2jctb-zn7b7-wy6qb-vga36-7wodq-4clo4-5ewbb-5qe");
            admin = Principal.fromText("vq2za-kqaaa-aaaas-amlvq-cai");
        }
    };

    public func randomPrincipal(counter: Nat) : Principal {
        // make a unique blob from the counter
        let bytes : [Nat8] = Array.tabulate<Nat8>(29, func(i) { Nat8.fromNat((counter + i) % 256) });
        Principal.fromBlob(Blob.fromArray(bytes))
    };

    public func getCaller(labels: Text): Principal {
        if(Text.contains(labels, #text "nonym")) getCallers().anon 
        else if(Text.contains(labels, #text "Bid")) getCallers().seller
        else getCallers().admin;
    };

    public func getValidIds<C,U,T>(property: PropertyUnstable, labels: Text, handler: PreTestHandler<C, U, T>, ): async ([Int], Types.Property){
        var stableProp : Types.Property = Stables.toStableProperty(property);
        let ids = Buffer.Buffer<Int>(0);
        let getIds = func(prop: PropertyUnstable): (){
            label makeIds for((id, el) in handler.toHashMap(prop).entries()){
                switch(handler.validForTest(labels, el)){
                    case(null){
                        var max = 0;
                        for(id in handler.toHashMap(prop).keys()){
                            if(id > max) max := id;
                        };
                        ids.add(max + 1);
                        break makeIds;
                    };
                    case(?true) ids.add(id);
                    case(?false){};
                };
            };
        };
        getIds(property);
        
        if(ids.size() == 0){

            for(what in handler.seedCreate(labels, handler.toId(property) + 1, handler.toWhat).vals()){
                let arg: Types.Arg<Types.Property> = {
                    what;
                    caller = getCaller(labels); 
                    parent = stableProp; 
                    handlePropertyUpdate = handler.handlePropertyUpdate; 
                    testing = handler.testing;
                };
                switch(await Property.updateProperty(arg)){
                    case(#Property(propAfter)) stableProp := propAfter.parent;
                    case(#Err(_e)){};// Debug.print(labels # debug_show(e));
                };
            };
        };
        //No valid elements for test - call create to make some
        getIds(Stables.fromStableProperty(stableProp));
        if(ids.size() == 0) Debug.print(labels # " No ids were passed, map: " # debug_show(handler.showMap(handler.toHashMap(Stables.fromStableProperty(stableProp)))));
        return (Buffer.toArray(ids), stableProp);
    };

    public func runGenericCases<C, U, T>(prop: PropertyUnstable,handler: PreTestHandler<C, U, T>, cases: [(Text, Types.Actions<C,U>, Bool)]): async [Text] {
        // RUN ALL
        var propertyBefore = prop;
        var results = Buffer.Buffer<Text>(cases.size());
        for ((labels, action, shouldSucceed) in cases.vals()) {
            let (updatedAction, property) = switch(action){
              case (#Create(_)) (action, Stables.toStableProperty(propertyBefore));
              case (#Update((u, _))) {
                let (ids, newProp) = await getValidIds(propertyBefore, labels, handler);
                (#Update((u, ids)), newProp);
              };
              case (#Delete(_)) {
                let (ids, newProp) = await getValidIds(propertyBefore, labels, handler);
                (#Delete(ids), newProp);
              };
            };
            
            let arg: Types.Arg<Types.Property> = {
                what = handler.toWhat(updatedAction);
                parent = property; 
                caller = getCaller(labels); 
                handlePropertyUpdate = handler.handlePropertyUpdate; 
                testing = handler.testing;
            };
            propertyBefore := Stables.fromStableProperty(property);
            let res : UpdateResult = await Property.updateProperty(arg);
            let out = switch (res, shouldSucceed, updatedAction) {
                case (#Property(res), true, #Create(_)) assertCreated2<C, U, T>(labels, propertyBefore, res.parent, handler);
                case (#Property(res), true, #Update(arg, ids)) handleUpdate<C, U, T>(labels, propertyBefore, res.parent, handler, ids, arg);
                case (#Property(res), true, #Delete(ids)) assertDeleted2<C, U, T>(labels, propertyBefore, res.parent, handler, ids);
                case (#Err(e), true, _) "\n ❌ " # debug_show(labels) # " expected ok, got err " # debug_show(e) # "\n map before: "# debug_show(handler.showMap(handler.toHashMap(propertyBefore))) # " args were: " # debug_show(arg.what);
                case (#Err(_), false, _) "\n ✅ " # debug_show(labels);
                case (#Property(res), false, _) "\n ❌ " # debug_show(labels) # " expected failure but succeeded" # printMaps(handler.toHashMap(propertyBefore), handler.toHashMap(Stables.fromStableProperty(res.parent)), handler)  # " args were: " # debug_show(arg.what);
            };
            switch(res){
                case(#Property(res)) propertyBefore := Stables.fromStableProperty(res.parent);
                case(_){};
            };
            results.add(out);
        };

        return Buffer.toArray(results);
    };

    public func getDependentId<C, T>(property: PropertyUnstable, labels: Text, handler: SingleActionPreTestHandler<C, T>): async (Nat, Types.Property){
        var stableProp : Types.Property = Stables.toStableProperty(property);
        let getId = func(prop: PropertyUnstable): ?Nat{
            for((id, el) in handler.toHashMap(prop).entries()){
                switch(handler.validForTest(labels, el)){
                    case(null){
                        var max = 0;
                        for(id in handler.toHashMap(prop).keys()){
                            if(id > max) max := id;
                        };
                        return ?(max + 1);
                    };
                    case(?true) return ?id;
                    case(?false){};
                };
            };
            null;
        };
        switch(getId(property)){
            case(?id) return (id, stableProp);
            case(null){
                for(what in handler.seedCreate(labels, Stables.fromStableProperty(stableProp)).vals()){
                    let arg: Types.Arg<Types.Property> = {
                        what;
                        caller = getCaller(labels); 
                        parent = stableProp; 
                        handlePropertyUpdate = handler.handlePropertyUpdate; 
                        testing = handler.testing;
                    };
                    switch(await Property.updateProperty(arg)){
                        case(#Property(res)) stableProp := res.parent;
                        case(#Err(e)) Debug.print(labels # debug_show(e));
                    };
                };
            };
        };
        switch(getId(Stables.fromStableProperty(stableProp))){
            case(null){
                Debug.print(labels # " No valid ids, map: " # debug_show(handler.showMap(handler.toHashMap(Stables.fromStableProperty(stableProp)))));
                return (99999, stableProp);
            };
            case(?id) return (id, stableProp);
        };
    };




    public func runSingleActionGenericCases<C, T>(prop: PropertyUnstable,handler: SingleActionPreTestHandler<C, T>, cases: [(Text, C, Bool)]): async [Text] {
        // RUN ALL
        var propertyBefore = prop;
        var results = Buffer.Buffer<Text>(cases.size());
        for ((labels, cArg, shouldSucceed) in cases.vals()) {
            let (id, property) = await getDependentId(propertyBefore, labels, handler);
            let updatedArg = handler.setId(id, cArg);
            let arg: Types.Arg<Types.Property> = {
                what = handler.toWhat(updatedArg);
                parent = property; 
                caller = handler.toCaller(labels, id, Stables.fromStableProperty(property)); 
                handlePropertyUpdate = handler.handlePropertyUpdate; 
                testing = handler.testing;
            };
            propertyBefore := Stables.fromStableProperty(property);
            let res : UpdateResult = await Property.updateProperty(arg);
            let out = switch (res, shouldSucceed) {
                case (#Property(res), true){
                    let unstablePropAfter = Stables.fromStableProperty(res.parent);
                    let mapBefore = handler.toHashMap(propertyBefore);
                    let mapAfter = handler.toHashMap(unstablePropAfter);
                    let out = switch(mapBefore.get(id), mapAfter.get(id)){
                        case(?bef, ?aft){
                            let string = handler.checkUpdate(bef, aft, updatedArg);
                            if(string == "") "\n ✅ " # debug_show(labels) else "\n ❌ " # debug_show(labels) # " failed \n"#string # "\n arg: "# debug_show(arg.what)#  "\n map before: " # debug_show(handler.showMap(mapBefore)) # " map after: "# debug_show(handler.showMap(mapAfter));
                        };
                        case(?_, _) "\n element was deleted unexpectedly, map before: " # debug_show(handler.showMap(mapBefore)) # "\n map after: "# debug_show(handler.showMap(mapAfter));
                        case(_, ?_) "\n element was created unexpectedly, map before: " # debug_show(handler.showMap(mapBefore)) # "\n map after: "# debug_show(handler.showMap(mapAfter));
                        case(_) "\n element never existed, map before: " # debug_show(handler.showMap(mapBefore)) # "\n map after: "# debug_show(handler.showMap(mapAfter));
                    };
                    propertyBefore := unstablePropAfter;
                    out;
                }; 
                case (#Err(e), true) "\n ❌ " # debug_show(labels) # " expected ok, got err " # debug_show(e) # "\n map before: "# debug_show(handler.showMap(handler.toHashMap(propertyBefore))) # " args were: " # debug_show(arg.what);
                case (#Err(_), false) "\n ✅ " # debug_show(labels);
                case (#Property(res), false) "\n ❌ " # debug_show(labels) # " expected failure but succeeded";
                // # printMaps(handler.toHashMap(propertyBefore), handler.toHashMap(Stables.fromStableProperty(propAfter)), handler)  # " args were: " # debug_show(arg.what);
            };
            results.add(out);
        };

        return Buffer.toArray(results);
    };


    public func runFlatGenericCases<U, T>(property: PropertyUnstable,handler: FlatPreTestHandler<U, T>, cases: [(Text, U, Bool)]): async [Text] {
        // RUN ALL
        var propertyBefore = property;
        var results = Buffer.Buffer<Text>(cases.size());
        for ((labels, uarg, shouldSucceed) in cases.vals()) {
            let arg: Types.Arg<Types.Property> = {
                what = handler.toWhat(uarg); 
                caller = getCaller(labels); 
                parent = Stables.toStableProperty(propertyBefore); 
                handlePropertyUpdate = handler.handlePropertyUpdate; 
                testing = true;
            };
            let out = switch (await Property.updateProperty(arg), shouldSucceed) {
                case (#Property(res), true){
                    let unstablePropAfter = Stables.fromStableProperty(res.parent);
                    propertyBefore := unstablePropAfter;
                    let string = handler.checkUpdate(propertyBefore, unstablePropAfter, uarg);
                    if(string == "") "\n ✅ " # debug_show(labels) else "\n ❌ " # debug_show(labels) # " failed \n"#string;
                }; 
                case (#Err(e), true) "\n ❌ " # debug_show(labels) # " expected ok, got err " # debug_show(e);
                case (#Err(_), false) "\n ✅ " # debug_show(labels);
                case (#Property(_), false) "\n ❌ " # debug_show(labels) # " expected failure but succeeded";
            };
            results.add(out);
        };

        return Buffer.toArray(results);
    };



}