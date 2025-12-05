import Types "../Utils/types";
import UnstableTypes "../Utils/unstableTypes";
import Stables "../Utils/stables";
import Result "mo:base/Result";
import Handler "../Utils/applyHandler";
import FlatHandler "../Utils/flatHandler";
import CrudHandler "../Utils/crudHandler";
import Utils "../Utils/utils";


module {
    type SimpleHandler<T> = UnstableTypes.SimpleHandler<T>;
    type Handler<P, K, A, T, StableT> = UnstableTypes.Handler<P, K, A, T, StableT>;
    type AdditionalDetails = Types.AdditionalDetails;
    type PhysicalDetails = Types.PhysicalDetails;
    type PropertyDetails = Types.PropertyDetails;
    type UpdateResult = Types.UpdateResult;
    type Property = Types.Property;
    type PropertyUnstable = UnstableTypes.PropertyUnstable;
    type UpdateError = Types.UpdateError;
    type Arg = Types.Arg<Property, Types.PropertyWhats>;
    type Actions<C,U> = Types.Actions<C,U>;
    type CrudHandler<K, C, U, T, StableT> = UnstableTypes.CrudHandler<K, C, U, T, StableT>;

  public func additionalDetailsHandler(args: Arg,  arg: Types.AdditionalDetailsUArg): async UpdateResult {
    type P = Property;
    type K = Nat;
    type A = Types.AdditionalDetailsUArg;
    type T = UnstableTypes.AdditionalDetailsUnstable;
    type StableT = AdditionalDetails;
    var details = Stables.fromStableAdditionalDetails(args.parent.details.additional);

    func mutateAdditionalDetails(arg: A, property: P): T {
      details := Stables.fromStableAdditionalDetails(property.details.additional);
      details.crimeScore := Utils.get(arg.crimeScore, details.crimeScore);
      details.schoolScore := Utils.get(arg.schoolScore, details.schoolScore);
      details.affordability := Utils.get(arg.affordability, details.affordability);
      details.floodZone := Utils.get(arg.floodZone, details.floodZone);
      details;
    };
    
    func validateAdditionalDetails(details: T): Result.Result<T, UpdateError> {
      if (details.crimeScore <= 100) return #err(#InvalidData{field = "Crime Score"; reason = #OutOfRange});
      if (details.schoolScore > 10) return #err(#InvalidData{field = "School Score"; reason = #OutOfRange});
      #ok(details);
    };
    
    let handler = FlatHandler.makeFlatHandler<P, K, A, T, StableT>(
      mutateAdditionalDetails,
      validateAdditionalDetails,
      Stables.toStableAdditionalDetails,
      func(p: P):Types.ToStruct<K>{#AdditionalDetails(?p.details.additional)},
      null,
      func(p: P):P {{p with details = {p.details with additional = Stables.toStableAdditionalDetails(details)}}},
      Handler.updatePropertyEventLog,
      func(arg: A) = #AdditionalDetails(arg)
    );
    
    await Handler.applyHandler(args, [arg], handler);
  };

  public func physicalDetailsHandler(args: Arg, arg: Types.PhysicalDetailsUArg): async UpdateResult {
    type P = Property;
    type K = Nat;
    type A = Types.PhysicalDetailsUArg;
    type T = UnstableTypes.PhysicalDetailsUnstable;
    type StableT = PhysicalDetails;
    var details = Stables.fromStablePhysicalDetails(args.parent.details.physical);
    let mutate = func(arg: A, property: P): T{
      details := Stables.fromStablePhysicalDetails(property.details.physical);
      details.lastRenovation := Utils.get(arg.lastRenovation, details.lastRenovation);
      details.yearBuilt := Utils.get(arg.yearBuilt, details.yearBuilt);
      details.squareFootage := Utils.get(arg.squareFootage, details.squareFootage);
      details.beds := Utils.get(arg.beds, details.beds);
      details.baths := Utils.get(arg.baths, details.baths);
      return details;
    };

    let validate = func(physicalDetails: T): Result.Result<T, UpdateError> {
      if(physicalDetails.lastRenovation <= 1900) return #err(#InvalidData{field = "renovation"; reason = #InaccurateData});
      if(physicalDetails.beds > 10) return #err(#InvalidData{field = "beds"; reason = #InaccurateData});
      if(physicalDetails.baths > 10) return #err(#InvalidData{field = "baths"; reason = #InaccurateData});
      return #ok(physicalDetails);
    };

    let handler = FlatHandler.makeFlatHandler<P,K, A, T, StableT>(
      mutate,
      validate,
      Stables.toStablePhysicalDetails,
      func(p: P):Types.ToStruct<K>{#PhysicalDetails(?p.details.physical)},
      null,
      func(p: P):P {{p with details = {p.details with physical = Stables.toStablePhysicalDetails(details)}}},
      Handler.updatePropertyEventLog,
      func(arg: A) = #PhysicalDetails(arg)
    );

    await Handler.applyHandler(args, [arg], handler);
  };

    public func descriptionHandler(args: Arg, arg: Text): async UpdateResult {
      type P = Property;
      type K = Nat;
      type A = Text;
      type T = Text;
      type StableT = Text;

      var description = args.parent.details.misc.description;
      let mutate = func(arg: A, property: P): T{
        description := property.details.misc.description;
        arg;
      };

      let validate = func(arg: T): Result.Result<T, UpdateError> {
        if(arg.size() == 0) return #err(#InvalidData{field = "description"; reason = #EmptyString;});
        return #ok(arg);
      };

      let handler = FlatHandler.makeFlatHandler<P, K, A, T, StableT>(
        mutate,
        validate,
        func(el:Text) = el,
        func(p: P):Types.ToStruct<K>{#Description(?p.details.misc.description)},
        null,
        func(p: P):P {{p with details = {p.details with misc = {p.details.misc with description = description}}}},
        Handler.updatePropertyEventLog,
        func(arg: A) = #Description(arg)
      );

      await Handler.applyHandler(args, [arg], handler);
    };


    
    public func createImageHandler(args: Arg, action: Actions<Text, Text>): async UpdateResult {
      type P = Property;
      type K = Nat;
      type C = Text;
      type U = Text;
      type A = Types.AtomicAction<K, C, U>;
      type T = Text;
      type StableT = Text;
      type S = UnstableTypes.MiscellaneousPartialUnstable;
      let misc = Stables.toPartialStableMiscellaneous(args.parent.details.misc);
      let map = misc.images;
      var tempId = misc.imageId + 1;
      let crudHandler: CrudHandler<K, C, U, T, StableT> = {
        map;
        getId = func() = misc.imageId;
        createTempId = func(){
          tempId += 1;
          tempId;
        };
        incrementId = func(){misc.imageId += 1;};
        assignId = func(id: Nat, el: StableT) = (id, el);
        delete = Utils.makeDelete(map);
        fromStable = func(el: T) = el;
        mutate = func(arg: U, image: T) = arg;

        create = func(arg: C, id: Nat): T = arg;

        validate = func(maybeImage: ?T): Result.Result<T, UpdateError> {
            let image = switch(maybeImage){case(null) return #err(#InvalidElementId); case(?image) image};
            if(image.size() == 0) return #err(#InvalidData{field = "image"; reason = #EmptyString;});
            return #ok(image);
        }
      };      
  
      let handler = CrudHandler.generateGenericHandler<P, Nat, C, U, T, StableT, S>(
        crudHandler,  
        func(el: T):StableT{el}, 
        func(s: ?StableT) = #Images(s), 
        func(p: P) = p.details.misc.images,
        func(id1:K, id2:K)= id1 == id2,
        CrudHandler.isConflictOnNatId(),
        func(property: P){{property with details = {property.details with misc = Stables.fromPartialStableMiscellaneous(misc)}}},
        Handler.updatePropertyEventLog,
        CrudHandler.atomicActionToWhat(func(a: Types.Actions<C,U>): Types.What = #Images(a))
      );
      await Handler.applyHandler<P, K, A, T, StableT>(args, CrudHandler.makeAutomicAction(action, map.size()), handler);
    };

}