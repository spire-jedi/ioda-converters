/*
 * (C) Copyright 2020 NOAA/NWS/NCEP/EMC
 *
 * This software is licensed under the terms of the Apache Licence Version 2.0
 * which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
 */

#include "MnemonicVariable.h"

#include <ostream>

#include "eckit/exception/Exceptions.h"
#include "eckit/value/Value.h"

#include "BufrParser/Exports/ConfKeys.h"
#include "IngesterTypes.h"

namespace
{
    const double MissingValue = 1e10;
    const double MissingValueEpsilon = 1.0e-9;
}


namespace Ingester
{
    MnemonicVariable::MnemonicVariable(const eckit::Configuration& conf,
                                       const Transforms& transforms) :
      transforms_(transforms)
    {
        eckit::Value value = conf.get();
        if (value.contains(ConfKeys::Variable::Mnemonic))
        {
            auto mnemonicVal = value[ConfKeys::Variable::Mnemonic];
            if (mnemonicVal.isList())
            {
                mnemonic_ = conf.getStringVector(ConfKeys::Variable::Mnemonic);
            }
            else if (mnemonicVal.isString())
            {
                mnemonic_.push_back(conf.getString(ConfKeys::Variable::Mnemonic));
            }
        }
    }

    std::shared_ptr<DataObject> MnemonicVariable::exportData(const BufrDataMap& map)
    {
        IngesterArray data;

        bool mnemonicsAreMissing = true;
        for (const auto& mnemonic : mnemonic_)
        {
            if (map.find(mnemonic) != map.end())
            {
                data = map.at(mnemonic);
                if ((data < (MissingValue - MissingValueEpsilon)).any())
                {
                    mnemonicsAreMissing = false;
                    break;
                }
            }
        }

        if (mnemonicsAreMissing)
        {
            std::stringstream errStr;
            errStr << "None of mnemonic(s) [";
            for (const auto& mnemonic : mnemonic_) errStr << mnemonic << ", ";
            errStr.seekp(-2, std::ios_base::end);  // move the cursor back 2 positions
            errStr << "] could be found during export.";

            throw eckit::BadParameter(errStr.str());
        }

        applyTransforms(data);
        return std::make_shared<ArrayDataObject>(data);
    }

    void MnemonicVariable::applyTransforms(IngesterArray& data)
    {
        for (const auto& transform : transforms_)
        {
            transform->apply(data);
        }
    }

}  // namespace Ingester
