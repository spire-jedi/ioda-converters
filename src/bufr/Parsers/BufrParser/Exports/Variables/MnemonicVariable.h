/*
 * (C) Copyright 2020 NOAA/NWS/NCEP/EMC
 *
 * This software is licensed under the terms of the Apache Licence Version 2.0
 * which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
 */

#pragma once

#include <string>
#include <memory>

#include "eckit/config/LocalConfiguration.h"

#include "Variable.h"
#include "IodaEncoder/EncoderTypes.h"
#include "IodaEncoder/DataObject/ArrayDataObject.h"
#include "Parsers/BufrParser/Exports/Variables/Transforms/Transform.h"


namespace iodaconv
{
    namespace parser
    {
        namespace bufr
        {
            /// \brief Exports parsed data associated with a mnemonic (ex: "CLAT")
            class MnemonicVariable final : public Variable
            {
             public:
                explicit MnemonicVariable(std::string mnemonicStr, Transforms transforms);

                ~MnemonicVariable() final = default;

                /// \brief Gets the requested data, applies transforms, and returns the requested data
                /// \param map BufrDataMap that contains the parsed data for each mnemonic
                std::shared_ptr<encoder::DataObject> exportData(const BufrDataMap& map) final;

             private:
                /// \brief The BUFR mnemonic of interest
                std::string mnemonic_;

                /// \brief Collection of transforms to apply to the data during export
                Transforms transforms_;

                /// \brief Apply the transforms
                /// \param data Eigen Array data to apply the transform to.
                void applyTransforms(encoder::Array& data);
            };
        }  // namespace bufr
    }  // namespace parser
}  // namespace iodaconv
