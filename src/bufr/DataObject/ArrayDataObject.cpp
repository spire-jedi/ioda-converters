/*
 * (C) Copyright 2020 NOAA/NWS/NCEP/EMC
 *
 * This software is licensed under the terms of the Apache Licence Version 2.0
 * which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
 */

#include <iostream>
#include <ostream>

#include "eckit/exception/Exceptions.h"

#include "ArrayDataObject.h"

namespace Ingester
{
    ArrayDataObject::ArrayDataObject(const IngesterArray& eigArray) :
        eigArray_(eigArray)
    {
    }

    ioda::Variable ArrayDataObject::createVariable(ioda::ObsGroup& obsGroup,
                                                   const std::string& name,
                                                   const std::vector<ioda::Variable>& dimensions,
                                                   const std::vector<ioda::Dimensions_t>& chunks,
                                                   int compressionLevel)
    {
        auto params = makeCreationParams(chunks, compressionLevel);
        auto var = obsGroup.vars.createWithScales<FloatType>(name, dimensions, params);

        if ((dimensions.size() != 1 + static_cast<size_t>(eigArray_.cols() > 1)) ||
            (dimensions[0].getDimensions().numElements != eigArray_.rows()) ||
            ((dimensions.size() == 2) &&
             (dimensions[1].getDimensions().numElements != eigArray_.cols())))
        {
            std::stringstream errStr;
            errStr << "The dimensions of the data for " << name << " does not match the number ";
            errStr << "that is configured for this variable.";
            throw eckit::BadParameter(errStr.str());
        }

        var.writeWithEigenRegular(eigArray_);
        return var;
    }

    void ArrayDataObject::print() const
    {
        std::cout << eigArray_ << std::endl;
    }

    size_t ArrayDataObject::nrows() const
    {
        return eigArray_.rows();
    }

    size_t ArrayDataObject::ncols() const
    {
        return eigArray_.cols();
    }

    ioda::VariableCreationParameters ArrayDataObject::makeCreationParams(
                                                    const std::vector<ioda::Dimensions_t>& chunks,
                                                    int compressionLevel)
    {
        ioda::VariableCreationParameters params;
        params.chunk = true;
        params.chunks = chunks;
        params.compressWithGZIP(compressionLevel);
        params.setFillValue<FloatType>(-999);

        return params;
    }

}  // namespace Ingester
