import Types "types";
import UnstableTypes "Tests/unstableTypes";
import Stables "Tests/stables";
import Result "mo:base/Result";
import PropHelper "propHelper";
module {
    type SimpleHandler<T> = UnstableTypes.SimpleHandler<T>;
    type Handler<T, StableT> = UnstableTypes.Handler<T, StableT>;
    type AdditionalDetails = Types.AdditionalDetails;
    type PhysicalDetails = Types.PhysicalDetails;
    type PropertyDetails = Types.PropertyDetails;
    type UpdateResult = Types.UpdateResult;
    type Property = Types.Property;
    type PropertyUnstable = UnstableTypes.PropertyUnstable;
    type UpdateError = Types.UpdateError;

  public func additionalDetailsHandler(args: Arg, arg: Types.AdditionalDetailsUArg): async UpdateResult {
    type U = Types.AdditionalDetailsUArg;
    type T = UnstableTypes.AdditionalDetailsUnstable;
    type StableT = AdditionalDetails;

    func mutateAdditionalDetails(arg: U, details: T): T {
      details.crimeScore := PropHelper.get(arg.crimeScore, details.crimeScore);
      details.schoolScore := PropHelper.get(arg.schoolScore, details.schoolScore);
      details.affordability := PropHelper.get(arg.affordability, details.affordability);
      details.floodZone := PropHelper.get(arg.floodZone, details.floodZone);
      details;
    };
    
    func validateAdditionalDetails(details: T): Result.Result<T, UpdateError> {
      if (details.crimeScore <= 100) return #err(#InvalidData{field = "Crime Score"; reason = #OutOfRange});
      if (details.schoolScore > 10) return #err(#InvalidData{field = "School Score"; reason = #OutOfRange});
      #ok(details);
    };
    
    let handler = PropHelper.makeFlatHandler<U, T, StableT>(
      arg,
      Stables.fromStableAdditionalDetails(args.property.details.additional),
      mutateAdditionalDetails,
      validateAdditionalDetails,
      Stables.toStableAdditionalDetails,
      func(el: StableT) = #Details({ args.property.details with additional =el}),
      func(property: Property) = #AdditionalDetails(?property.details.additional)
    );
    
    await PropHelper.applyHandler(args, handler);
  };

  public func physicalDetailsHandler(args: Arg, arg: Types.PhysicalDetailsUArg): async UpdateResult {
    type U = Types.PhysicalDetailsUArg;
    type T = UnstableTypes.PhysicalDetailsUnstable;
    type StableT = PhysicalDetails;
    
    let mutate = func(arg: U, details: T): T{
      details.lastRenovation := PropHelper.get(arg.lastRenovation, details.lastRenovation);
      details.yearBuilt := PropHelper.get(arg.yearBuilt, details.yearBuilt);
      details.squareFootage := PropHelper.get(arg.squareFootage, details.squareFootage);
      details.beds := PropHelper.get(arg.beds, details.beds);
      details.baths := PropHelper.get(arg.baths, details.baths);
      return details;
    };

    let validate = func(physicalDetails: T): Result.Result<T, UpdateError> {
      if(physicalDetails.lastRenovation <= 1900) return #err(#InvalidData{field = "renovation"; reason = #InaccurateData});
      if(physicalDetails.beds > 10) return #err(#InvalidData{field = "beds"; reason = #InaccurateData});
      if(physicalDetails.baths > 10) return #err(#InvalidData{field = "baths"; reason = #InaccurateData});
      return #ok(physicalDetails);
    };

    let handler = PropHelper.makeFlatHandler<U, T, StableT>(
      arg,
      Stables.fromStablePhysicalDetails(args.property.details.physical),
      mutate,
      validate,
      Stables.toStablePhysicalDetails,
      func(el: StableT) = #Details({ args.property.details with physical =el}),
      func(property: Property) = #PhysicalDetails(?property.details.physical)
    );

    await PropHelper.applyHandler(args, handler);
  };

    public func descriptionHandler(args: Arg, arg: Text): async UpdateResult {
      type U = Text;
      type T = Text;
      type StableT = Text;

      let mutate = func(arg: U, _:T): T{
        arg;
      };

      let validate = func(arg: T): Result.Result<T, UpdateError> {
        if(arg.size() == 0) return #err(#InvalidData{field = "description"; reason = #EmptyString;});
        return #ok(arg);
      };

      let handler = PropHelper.makeFlatHandler<U, T, StableT>(
        arg,
        args.property.details.misc.description,
        mutate,
        validate,
        func(el:Text) = el,
        func(el: StableT) = #Details({ args.property.details with misc ={args.property.details.misc with description = el }}),
        func(property: Property) = #Description(?property.details.misc.description)
      );

      await PropHelper.applyHandler(args, handler);
    };


    type Arg = Types.Arg;
    type Actions<C,U> = Types.Actions<C,U>;
    type CrudHandler<C, U, T, StableT> = UnstableTypes.CrudHandler<C, U, T, StableT>;
    public func createImageHandler(args: Arg, action: Actions<Text, Text>): async UpdateResult {
      type C = Text;
      type U = Text;
      type T = Text;
      type StableT = Text;
      type S = UnstableTypes.MiscellaneousPartialUnstable;
      let misc = Stables.toPartialStableMiscellaneous(args.property.details.misc);
      let map = misc.images;
      let crudHandler: CrudHandler<C, U, T, StableT> = {
        map;
        var id = misc.imageId;
        setId = func(id: Nat) = misc.imageId := id;
        assignId = func(id: Nat, el: StableT) = (id, el);
        delete = PropHelper.makeDelete(map);
        fromStable = func(el: T) = el;
        mutate = func(arg: U, image: T) = arg;

        create = func(arg: C, id: Nat): T = arg;

        validate = func(maybeImage: ?T): Result.Result<T, UpdateError> {
            let image = switch(maybeImage){case(null) return #err(#InvalidElementId); case(?image) image};
            if(image.size() == 0) return #err(#InvalidData{field = "image"; reason = #EmptyString;});
            return #ok(image);
        }
      };      
  
      let handler = PropHelper.generateGenericHandler<C, U, T, StableT, S>(crudHandler, action, func(el: Text) = el, func(s: S) = #Details({args.property.details with misc = Stables.fromPartialStableMiscellaneous(s)}), misc, func(stableT: ?StableT) = #Images(stableT), func(property: Property) = property.details.misc.images);
      await PropHelper.applyHandler<T, StableT>(args, handler);
    };

}