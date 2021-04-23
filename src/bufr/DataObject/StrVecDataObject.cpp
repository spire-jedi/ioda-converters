/*
 * (C) Copyright 2020 NOAA/NWS/NCEP/EMC
 *
 * This software is licensed under the terms of the Apache Licence Version 2.0
 * which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
 */

#include <iostream>
#include <ostream>

#include "eckit/exception/Exceptions.h"

#include "StrVecDataObject.h"


namespace Ingester
{
    StrVecDataObject::StrVecDataObject(const std::vector<std::string>& strVector) :
        strVector_(strVector)
    {
    }

    ioda::Variable StrVecDataObject::createVariable(ioda::ObsGroup& obsGroup,
                                                    const std::string& name,
                                                    const std::vector<ioda::Variable>& dimensions,
                                                    const std::vector<ioda::Dimensions_t>& chunks,
                                                    int compressionLevel)
    {
        auto params = makeCreationParams(chunks, compressionLevel);
        auto var = obsGroup.vars.createWithScales<std::string>(name, dimensions, params);

        if ((dimensions.size() != 1) ||
            (dimensions[0].getDimensions().numElements != static_cast<long int>(strVector_.size())))
        {
            std::stringstream errStr;
            errStr << "The dimensions of the data for " << name << " does not match the number ";
            errStr << "that is configured for this variable.";
            throw eckit::BadParameter(errStr.str());
        }

        var.write(strVector_);
        return var;
    }

    void StrVecDataObject::print() const
    {
        for (const auto& str : strVector_)
        {
            std::cout << str << std::endl;
        }
    }

    size_t StrVecDataObject::nrows() const
    {
        return strVector_.size();
    }

    size_t StrVecDataObject::ncols() const
    {
        return 1;
    }

    ioda::VariableCreationParameters StrVecDataObject::makeCreationParams(
                                                    const std::vector<ioda::Dimensions_t>& chunks,
                                                    int compressionLevel)
    {
        ioda::VariableCreationParameters params;
        params.chunk = true;
        params.chunks = chunks;
        params.compressWithGZIP(compressionLevel);

        return params;
    }
}  // namespace Ingester
