# (C) Copyright 2020 NOAA/NWS/NCEP/EMC
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.

list(APPEND _iodaconv_srcs
  IodaEncoder/EncoderTypes.h
  IodaEncoder/DataContainer.h
  IodaEncoder/DataContainer.cpp
  Parsers/Parser.h
  Parsers/ParserFactory.h
  IodaEncoder/DataObject/DataObject.h
  IodaEncoder/DataObject/StrVecDataObject.h
  IodaEncoder/DataObject/StrVecDataObject.cpp
  IodaEncoder/DataObject/ArrayDataObject.h
  IodaEncoder/DataObject/ArrayDataObject.cpp
  Parsers/BufrParser/BufrParser.h
  Parsers/BufrParser/BufrParser.cpp
  Parsers/BufrParser/BufrDescription.h
  Parsers/BufrParser/BufrDescription.cpp
  Parsers/BufrParser/BufrMnemonicSet.h
  Parsers/BufrParser/BufrMnemonicSet.cpp
  Parsers/BufrParser/BufrTypes.h
  Parsers/BufrParser/BufrCollectors/BufrAccumulator.cpp
  Parsers/BufrParser/BufrCollectors/BufrAccumulator.h
  Parsers/BufrParser/BufrCollectors/BufrCollector.cpp
  Parsers/BufrParser/BufrCollectors/BufrCollector.h
  Parsers/BufrParser/BufrCollectors/BufrIntCollector.cpp
  Parsers/BufrParser/BufrCollectors/BufrIntCollector.h
  Parsers/BufrParser/BufrCollectors/BufrRepCollector.cpp
  Parsers/BufrParser/BufrCollectors/BufrRepCollector.h
  Parsers/BufrParser/BufrCollectors/BufrCollectors.cpp
  Parsers/BufrParser/BufrCollectors/BufrCollectors.h
  Parsers/BufrParser/Exports/Export.h
  Parsers/BufrParser/Exports/Export.cpp
  Parsers/BufrParser/Exports/RowSlice.h
  Parsers/BufrParser/Exports/Filters/Filter.h
  Parsers/BufrParser/Exports/Filters/RangeFilter.h
  Parsers/BufrParser/Exports/Filters/RangeFilter.cpp
  Parsers/BufrParser/Exports/Filters/GreaterFilter.h
  Parsers/BufrParser/Exports/Filters/GreaterFilter.cpp
  Parsers/BufrParser/Exports/Filters/LesserFilter.h
  Parsers/BufrParser/Exports/Filters/LesserFilter.cpp
  Parsers/BufrParser/Exports/Splits/Split.h
  Parsers/BufrParser/Exports/Splits/CategorySplit.h
  Parsers/BufrParser/Exports/Splits/CategorySplit.cpp
  Parsers/BufrParser/Exports/Variables/Variable.h
  Parsers/BufrParser/Exports/Variables/DatetimeVariable.h
  Parsers/BufrParser/Exports/Variables/DatetimeVariable.cpp
  Parsers/BufrParser/Exports/Variables/MnemonicVariable.h
  Parsers/BufrParser/Exports/Variables/MnemonicVariable.cpp
  Parsers/BufrParser/Exports/Variables/Transforms/Transform.h
  Parsers/BufrParser/Exports/Variables/Transforms/OffsetTransform.h
  Parsers/BufrParser/Exports/Variables/Transforms/OffsetTransform.cpp
  Parsers/BufrParser/Exports/Variables/Transforms/ScalingTransform.h
  Parsers/BufrParser/Exports/Variables/Transforms/ScalingTransform.cpp
  Parsers/BufrParser/Exports/Variables/Transforms/TransformBuilder.h
  Parsers/BufrParser/Exports/Variables/Transforms/TransformBuilder.cpp
  IodaEncoder/IodaEncoder.cpp
  IodaEncoder/IodaEncoder.h
  IodaEncoder/IodaDescription.cpp
  IodaEncoder/IodaDescription.h
)

list(APPEND _iodaconv_deps
  Eigen3::Eigen
  eckit
  ${oops_LIBRARIES}
  ioda_engines
  bufr::bufr_4_DA
)

ecbuild_add_library( TARGET   ingester
                     SOURCES  ${_iodaconv_srcs}
                     LIBS     ${_iodaconv_deps}
                     INSTALL_HEADERS LISTED
                     HEADER_DESTINATION ${INSTALL_INCLUDEDIR}/bufr
                     LINKER_LANGUAGE CXX
                    )

add_library( ${PROJECT_NAME}::ingester ALIAS ingester )

ecbuild_add_executable( TARGET  bufr2ioda.x
                        SOURCES bufr2ioda.cpp
                        LIBS    ingester )

ecbuild_add_test( TARGET  test_${PROJECT_NAME}_bufr_coding_norms
                  TYPE    SCRIPT
                  COMMAND ${CMAKE_BINARY_DIR}/bin/${PROJECT_NAME}_cpplint.py
                  ARGS    --quiet --recursive ${CMAKE_CURRENT_SOURCE_DIR}
                  WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/bin )
