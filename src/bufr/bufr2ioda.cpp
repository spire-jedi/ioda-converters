/*
 * (C) Copyright 2020 NOAA/NWS/NCEP/EMC
 *
 * This software is licensed under the terms of the Apache Licence Version 2.0
 * which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
 */

#include <string>
#include <iostream>
#include <ostream>
#include <iomanip>

#include "eckit/config/YAMLConfiguration.h"
#include "eckit/exception/Exceptions.h"
#include "eckit/filesystem/PathName.h"

#include "Parsers/ParserFactory.h"
#include "Parsers/BufrParser/BufrParser.h"
#include "IodaEncoder/IodaEncoder.h"


namespace iodaconv
{
    void parse(std::string yamlPath)
    {
        std::unique_ptr<eckit::YAMLConfiguration>
            yaml(new eckit::YAMLConfiguration(eckit::PathName(yamlPath)));

        if (yaml->has("observations"))
        {
            for (const auto& obsConf : yaml->getSubConfigurations("observations"))
            {
                if (!obsConf.has("obs space") ||
                    !obsConf.has("ioda"))
                {
                    eckit::BadParameter(
                        "Incomplete obs found. All obs must have a obs space and ioda.");
                }

                auto parser =
                    parser::ParserFactory::create(obsConf.getSubConfiguration("obs space"));
                auto data = parser->parse();

                auto encoder = encoder::IodaEncoder(obsConf.getSubConfiguration("ioda"));
                encoder.encode(data);
            }
        }
        else
        {
            eckit::BadParameter("No section named \"observations\"");
        }
    }

    void registerParsers()
    {
        parser::ParserFactory::registerParser<parser::bufr::BufrParser>("bufr");
    }
}  // namespace iodaconv


int main(int argc, char **argv)
{
    if (argc < 2)
    {
        eckit::BadParameter("Missing argument. Must include YAML file path.");
    }

    iodaconv::registerParsers();
    iodaconv::parse(std::string(argv[1]));

    return 0;
}

