/*
 * (C) Copyright 2020 NOAA/NWS/NCEP/EMC
 *
 * This software is licensed under the terms of the Apache Licence Version 2.0
 * which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
 */

#include "MnemonicVariable.h"

#include <ostream>

#include "eckit/exception/Exceptions.h"

#include "BufrParser/Exports/ConfKeys.h"
#include "IngesterTypes.h"


namespace Ingester
{
    MnemonicVariable::MnemonicVariable(const eckit::Configuration& conf, const Transforms& transforms) :
      transforms_(transforms)
    {
        // From the conf object, parse list of one or more mnemonics.
        if (conf.has(ConfKeys::Variable::Mnemonic))
        {
            mnemonic_ = conf.getStringVector(ConfKeys::Variable::Mnemonic);
        }
        else
        {
            std::stringstream errStr;
            errStr << "Configuration is missing critical ingredient of: " << ConfKeys::Variable::Mnemonic;
            throw eckit::BadParameter(errStr.str());
        }
    }

    std::shared_ptr<DataObject> MnemonicVariable::exportData(const BufrDataMap& map)
    {
        bool allAreMissing = true;
        std::string keysStr;
        const float missingValue = 1.E11;
        const float epsilon = 1.E-09;

        IngesterArray data;
        for (auto mnemonic : mnemonic_)
        {
            if (map.find(mnemonic) == map.end())
            {
                keysStr = ", " + keysStr + mnemonic;
            }
            else
            {
                allAreMissing = false;
                data = map.at(mnemonic);
                if ((data < (missingValue - epsilon)).any())
                {
                    break;
                }
            }
        }

        if (allAreMissing)
        {
            std::stringstream errStr;
            errStr << "None of mnemonic(s) [" << keysStr.substr(3) << "] could be found during export.";
            throw eckit::BadParameter(errStr.str());
        }

        applyTransforms(data);
        return std::make_shared<ArrayDataObject>(data);

    }

    void MnemonicVariable::applyTransforms(IngesterArray& data)
    {
        for (auto transform : transforms_)
        {
            transform->apply(data);
        }
    }

}  // namespace Ingester
