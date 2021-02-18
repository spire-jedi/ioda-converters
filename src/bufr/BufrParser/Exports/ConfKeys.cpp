/*
 * (C) Copyright 2021 NOAA/NWS/NCEP/EMC
 *
 * This software is licensed under the terms of the Apache Licence Version 2.0
 * which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
 */

#include "ConfKeys.h"

namespace Ingester
{
    namespace ConfKeys
    {
        const char* Filters = "filters";
        const char* Splits = "splits";
        const char* Variables = "variables";

        namespace Variable
        {
            const char* Datetime = "datetime";
            const char* Mnemonic = "mnemonic";
        }  // namespace Variable

        namespace Split
        {
            const char* Category = "category";
            const char* Mnemonic = "mnemonic";
            const char* NameMap = "map";
        }  // namespace Split

        namespace Filter
        {
            const char* Mnemonic = "mnemonic";
            const char* Bounding = "bounding";
            const char* UpperBound = "upperBound";
            const char* LowerBound = "lowerBound";
        }
    }  // namespace ConfKeys
}  // namespace Ingester

