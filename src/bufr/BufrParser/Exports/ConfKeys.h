/*
 * (C) Copyright 2021 NOAA/NWS/NCEP/EMC
 *
 * This software is licensed under the terms of the Apache Licence Version 2.0
 * which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
 */

#pragma once

namespace Ingester
{
    namespace ConfKeys
    {
        extern const char* Filters;
        extern const char* Splits;
        extern const char* Variables;

        namespace Variable
        {
            extern const char* Datetime;
            extern const char* Mnemonic;
        }  // namespace Variable

        namespace Split
        {
            extern const char* Category;
            extern const char* Mnemonic;
            extern const char* NameMap;
        }  // namespace Split

        namespace Filter
        {
            extern const char* Mnemonic;
            extern const char* Bounding;
            extern const char* UpperBound;
            extern const char* LowerBound;
        }
    }  // namespace ConfKeys
}  // namespace Ingester
