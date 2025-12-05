import Types "types";
import Text "mo:base/Text";
import Result "mo:base/Result";
import Principal "mo:base/Principal";

persistent actor Factory {
    //responsibilities:
    //make new nft canisters and property dao canisters
    //index properties after every property update
    //update property dao canisters
    //take in wasms for new versions of code
    //manage cycles of property daos
    let IC : Types.IC = actor("aaaaa-aa");
    transient let state = {
        propertyDAOModules = Types.createMapHandler<Types.VersionKey, Types.Wasm>(Types.versionCompare, []);
        propertyModules = Types.createMapHandler<Types.VersionKey, Principal>(Types.versionCompare, []);
        nftModules = Types.createMapHandler<Types.VersionKey, Types.Wasm>(Types.versionCompare, []);
        propertyDAOs = Types.createMapHandler<Principal, Types.Property>(Principal.compare, []);
    };

    public shared func createCanisterFromWasm(propertyDaoVersion: Types.VersionKey, nftVersion: Types.VersionKey, propertyModuleVersion: Types.VersionKey) : async Result.Result<Types.CanisterIds, ()> {
        if(propertyDaoVersion.struct != propertyModuleVersion.struct or propertyDaoVersion.actions != propertyModuleVersion.actions) return #err();
        let (propertyDaoWasm, nftWasm, propertyModule) = switch(state.propertyDAOModules.get(propertyDaoVersion), state.nftModules.get(nftVersion), state.propertyModules.get(propertyModuleVersion)){case(?daoWasm, ?nftWasm, ?propertyModule) (daoWasm, nftWasm, propertyModule); case(_) return #err();};
        
        // 1. Create a new empty canister with cycles attached to the call
        let settings : ?Types.CanisterSettings = ?{
            controllers = ?[Principal.fromActor(Factory)];   // or ?[caller, Principal.fromActor(Factory)]
            compute_allocation = null;
            memory_allocation = null;
            freezing_threshold = null;
        };

        let propertyDao = await (with cycles = 2_000_000_000_000) IC.create_canister({
                            settings = settings; // or ?{ controllers = ?[Principal.fromActor(Factory)]; ... }
                        });
        let nft = await (with cycles = 2_000_000_000_000) IC.create_canister({
                            settings = settings; // or ?{ controllers = ?[Principal.fromActor(Factory)]; ... }
                        });
        
        let canisterIds : Types.CanisterIds = {
            propertyDao = propertyDao.canister_id;             
            nft = nft.canister_id;
            propertyModule = propertyModule; 
        };

        // 2. Install the wasmModule into the new canister
        await IC.install_code({
          mode = #install;
          canister_id = canisterIds.propertyDao;
          wasm_module = propertyDaoWasm.wasm_module;
          arg = propertyDaoWasm.installArg;
        });

        await IC.install_code({
          mode = #install;
          canister_id = canisterIds.nft;
          wasm_module = nftWasm.wasm_module;
          arg = nftWasm.installArg;
        });

        let dao : Types.PropertyDAO = actor(Principal.toText(canisterIds.propertyDao));
        await dao.setPropertyModule(propertyModule);
        let property = await dao.getProperty();
        state.propertyDAOs.put(canisterIds.propertyDao, property);
        // 3. Return the new canister id
        #ok(canisterIds)
    };

    public shared ({caller}) func updateProperty(property: Types.Property): async (){
        state.propertyDAOs.put(caller, property);
    };

  public func propertyIndexerLive(): async Text {
      "Property Indexer Is Live"
  };
}