/*
 * (C) Copyright 2020 UCAR
 * 
 * This software is licensed under the terms of the Apache Licence Version 2.0
 * which can be obtained at http://www.apache.org/licenses/LICENSE-2.0. 
 */
#ifndef EXAMPLES_CONVERTIODA_H_
#define EXAMPLES_CONVERTIODA_H_

#include <map>
#include <string>
#include <vector>

#include "ioda/Engines/Factory.h"
#include "ioda/ObsGroup.h"
#include "jedi/Error.h"

// record of input dimension specs
struct DimSpecs {
  int size_;
  bool unlimited_;
  bool need_for_output_;

  // constructor
  DimSpecs(const int size, const bool unlimited, const bool needForOutput = false) :
      size_(size), unlimited_(unlimited), need_for_output_(needForOutput) {
  }
};
typedef std::map<std::string, DimSpecs> DimInfo_t;

// record of input variable specs
struct VarSpecs {
  std::vector<std::string> dim_list_;
  std::string dtype_;
  bool has_chans_;
  std::vector<int> chan_nums_;

  // constructor
  VarSpecs(const std::vector<std::string> & dim_list, const std::string & dtype,
           const bool has_chans = false,
           const std::vector<int> & chan_nums = std::vector<int>()) :
      dim_list_(dim_list), dtype_(dtype), has_chans_(has_chans), chan_nums_(chan_nums) {
  }
};
typedef std::map<std::string, VarSpecs> VarInfo_t;

// \brief Collect information about dimensions from an old format ioda file
// \param file Group object with a file backend pointing to an old format ioda file
// \param dimInfo Dimension information structure to be filled in
void getDimensionInfo(const ioda::Group & file, DimInfo_t & dimInfo);

// \brief Collect information about variables from an old format ioda file
// \param file Group object with a file backend pointing to an old format ioda file
// \param varInfo Variable information structure to be filled in
void getVariableInfo(const ioda::Group & file, DimInfo_t & dimInfo, VarInfo_t & varInfo);

// \brief create a variable in the output ObsGroup
// \param file ObsGroup object with a file backend pointing to a new format ioda file
// \param varName Name of new variable
// \param dimList List of names in order of the dimensions to attach to the new variable
// \param fillValue Fill value for the new variable
template <typename DataType>
ioda::Variable createOutputVariable(ioda::ObsGroup & file, const std::string & varName,
                                    const std::vector<std::string> & dimList,
                                    const DataType & fillValue) {
  // Collect the dimension scale varibles
  std::vector<ioda::Variable> dimScaleVars;
  for (auto & dimName : dimList) {
    dimScaleVars.push_back(file.vars[dimName]);
  }

  // Fill in a variable creation parameter structure
  ioda::VariableCreationParameters params;
  params.chunk = true;
  params.compressWithGZIP();
  params.setFillValue<DataType>(fillValue);

  return file.vars.createWithScales<DataType>(varName, dimScaleVars, params);
}

// \brief Copy attributes from input file variable to output file variable
// \param inVar Input file variable
// \param outVar Output file variable
void copyVarAttributes(const ioda::Variable & inVar, ioda::Variable & outVar);

#endif  // EXAMPLES_CONVERTIODA_H_
