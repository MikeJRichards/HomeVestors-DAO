import Types "types";
import UnstableTypes "Tests/unstableTypes";
import Stables "Tests/stables";
import Result "mo:base/Result";
module {
    type SimpleHandler<T> = UnstableTypes.SimpleHandler<T>;
    type Handler<C, U, T> = UnstableTypes.Handler<C, U, T>;
    type AdditionalDetails = Types.AdditionalDetails;
    type PhysicalDetails = Types.PhysicalDetails;
    type PropertyDetails = Types.PropertyDetails;
    type UpdateResult = Types.UpdateResult;
    type PropertyUnstable = UnstableTypes.PropertyUnstable;
    type UpdateError = Types.UpdateError;


    public func additionalDetailsHandler(): SimpleHandler<AdditionalDetails> {
      {
        validate = func(additionalDetails: AdditionalDetails): Result.Result<AdditionalDetails, UpdateError> {
            if(additionalDetails.crimeScore <= 100) return #err(#InvalidData{field = "Crime Score"; reason = #OutOfRange});
            if(additionalDetails.schoolScore > 10) return #err(#InvalidData{field = "School Score"; reason = #OutOfRange});
            return #ok(additionalDetails);
        };

        apply = func(arg: AdditionalDetails, p: PropertyUnstable) {
           p.details.additional := Stables.fromStableAdditionalDetails(arg);
        }
      }
    };

    public func physicalDetailsHandler(): SimpleHandler<PhysicalDetails> {
      {
        validate = func(physicalDetails: PhysicalDetails): Result.Result<PhysicalDetails, UpdateError> {
            if(physicalDetails.lastRenovation <= 1900) return #err(#InvalidData{field = "renovation"; reason = #InaccurateData});
            if(physicalDetails.beds > 10) return #err(#InvalidData{field = "beds"; reason = #InaccurateData});
            if(physicalDetails.baths > 10) return #err(#InvalidData{field = "baths"; reason = #InaccurateData});
            return #ok(physicalDetails);
        };

        apply = func(arg: PhysicalDetails, p: PropertyUnstable) {
            p.details.physical := Stables.fromStablePhysicalDetails(arg);
        }
      }
    };

    public func descriptionHandler(): SimpleHandler<Text> {
      {
        validate = func(arg: Text): Result.Result<Text, UpdateError> {
           if(arg.size() == 0) return #err(#InvalidData{field = "description"; reason = #EmptyString;});
            return #ok(arg);
        };

        apply = func(arg: Text, p: PropertyUnstable) {
            p.details.misc.description := arg;
        }
      }
    };

    public func createImageHandler(): Handler<Text, Text, Text> {
      {
        map = func(p: PropertyUnstable) = p.details.misc.images;

        getId = func(p: PropertyUnstable) = p.details.misc.imageId;

        incrementId = func(p: PropertyUnstable) = p.details.misc.imageId += 1;

        mutate = func(arg: Text, image: Text) = arg;

        create = func(arg: Text, id: Nat, caller: Principal): Text = arg;

        validate = func(maybeImage: ?Text): Result.Result<Text, UpdateError> {
            let image = switch(maybeImage){case(null) return #err(#InvalidElementId); case(?image) image};
            if(image.size() == 0) return #err(#InvalidData{field = "image"; reason = #EmptyString;});
            return #ok(image);
        }
      }
    };   

}