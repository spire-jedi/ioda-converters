/*
 * (C) Copyright 2020 NOAA/NWS/NCEP/EMC
 *
 * This software is licensed under the terms of the Apache Licence Version 2.0
 * which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
 */

#include "ScalingTransform.h"


namespace Ingester
{
    namespace parser
    {
        namespace bufr
        {
            ScalingTransform::ScalingTransform(const double scaling) :
                scaling_(scaling)
            {
            }

            void ScalingTransform::apply(IngesterArray& array)
            {
                array = array * scaling_;
            }
        }  // namespace bufr
    }  // namespace parser
}  // namespace iodaconv
