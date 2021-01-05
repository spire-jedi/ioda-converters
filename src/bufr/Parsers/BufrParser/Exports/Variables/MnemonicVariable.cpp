/*
 * (C) Copyright 2020 NOAA/NWS/NCEP/EMC
 *
 * This software is licensed under the terms of the Apache Licence Version 2.0
 * which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
 */

#include "MnemonicVariable.h"

#include "IodaEncoder/EncoderTypes.h"


namespace iodaconv
{
    namespace parser
    {
        namespace bufr
        {
            MnemonicVariable::MnemonicVariable(std::string mnemonic, Transforms transforms) :
                mnemonic_(mnemonic),
                transforms_(transforms)
            {
            }

            std::shared_ptr<encoder::DataObject>
                MnemonicVariable::exportData(const BufrDataMap& map)
            {
                auto data = map.at(mnemonic_);
                applyTransforms(data);
                return std::make_shared<encoder::ArrayDataObject>(data);
            }

            void MnemonicVariable::applyTransforms(encoder::Array& data)
            {
                for (auto transform : transforms_)
                {
                    transform->apply(data);
                }
            }
        }  // namespace bufr
    }  // namespace parser
}  // namespace iodaconv
