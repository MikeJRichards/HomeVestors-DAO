import Types "types";
import PropHelper "propHelper";
import Result "mo:base/Result";
module {
    type PhysicalDetails = Types.PhysicalDetails;
    type AdditionalDetails = Types.AdditionalDetails;
    type Property = Types.Property;
    type UpdateResult = Types.UpdateResult;
    type UpdateError = Types.UpdateError;
    type What = Types.What;


    func validatePhysicalDetails(physicalDetails: PhysicalDetails): Result.Result<(), UpdateError> {
        if(physicalDetails.lastRenovation <= 1900) return #err(#InvalidData{field = "renovation"; reason = #InaccurateData});
        if(physicalDetails.beds > 10) return #err(#InvalidData{field = "beds"; reason = #InaccurateData});
        if(physicalDetails.baths > 10) return #err(#InvalidData{field = "baths"; reason = #InaccurateData});
        return #ok();
    };

    public func mutatePhysicalDetails(property: Property, d : PhysicalDetails, action: What): UpdateResult {
        switch(validatePhysicalDetails(d)){case(#err(e)) return #Err(e); case(#ok()){}};
        let updatedDetails = {property.details with physicalDetails = d};
        PropHelper.updateProperty(#Details(updatedDetails), property, action);
    };

    func validateAdditionalDetails(additionalDetails: AdditionalDetails): Result.Result<(), UpdateError> {
        if(additionalDetails.crimeScore <= 100) return #err(#InvalidData{field = "Crime Score"; reason = #OutOfRange});
        if(additionalDetails.schoolScore > 10) return #err(#InvalidData{field = "School Score"; reason = #OutOfRange});
        return #ok();
    };

    public func mutateAdditionalDetails(property: Property, d: AdditionalDetails, action: What): UpdateResult {
        switch(validateAdditionalDetails(d)){case(#err(e)) return #Err(e); case(#ok()){}};
        let updatedDetails = {property.details with additionalDetails = d};
        PropHelper.updateProperty(#Details(updatedDetails), property, action);
    };

}