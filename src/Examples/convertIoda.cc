/*
 * (C) Copyright 2020 UCAR
 * 
 * This software is licensed under the terms of the Apache Licence Version 2.0
 * which can be obtained at http://www.apache.org/licenses/LICENSE-2.0. 
 */

#include <iostream>
#include <map>
#include <numeric>
#include <set>
#include <string>
#include <typeindex>
#include <typeinfo>

#include "ioda/Engines/Factory.h"
#include "ioda/ObsGroup.h"
#include "jedi/Error.h"

int main(int argc, char** argv) {
  // Need two arguments: input file and output file
  std::string fullProgName{ argv[0] };
  std::string progName;
  auto pos = fullProgName.find_last_of("/\\");
  if (pos == fullProgName.npos) {
    progName = fullProgName;
  } else {
    progName = fullProgName.substr(pos+1);
  }

  std::string usage = "Usage: " + progName + ": <input_file> <output_file>";

  if (argc != 3) {
    std::cerr << "Error: must supply exactly 2 arguments" << std::endl << usage << std::endl;
    return -1;
  }

  // Have the required two arguments
  std::string inputFile{ argv[1] };
  std::string outputFile{ argv[2] };
  std::cout << "Converting old ioda format to new ioda format: " << std::endl
            << "    Input file: " << inputFile << std::endl
            << "    Output file: " << outputFile << std::endl;

  // Open the input and output files. The input file is not in the ioda format so
  // open it as a Group (not an ObsGroup).
  ioda::Engines::BackendCreationParameters beParams;
  beParams.fileName = inputFile;
  beParams.action = ioda::Engines::BackendFileActions::Open;
  beParams.openMode = ioda::Engines::BackendOpenModes::Read_Only;
  ioda::Group in_group =
      ioda::Engines::constructBackend(ioda::Engines::BackendNames::Hdf5File, beParams);

  bool clobber = true;
  ioda::ObsGroup out_group = ioda::ObsGroup::createObsGroupFile(outputFile, clobber);

  // Look through the variables and check how they are dimensioned. Record the dimension
  // names, sizes and mark which ones need to be used in the output file. Also record
  // the variable names and which dimensions go with each variable. There are
  // two primary changes to the variables to consider:
  //     Radiances go from a list of vectors (one per channel) to a single 2D array
  //     String go from 2D character arrays to vectors of strings

  // record of input dimension specs
  struct dimSpecs {
    int size_;
    bool has_coords_;
    std::string var_name_;

    // constructor
    dimSpecs(const int size, const bool has_coords = false, const std::string & var_name = "") :
        size_(size), has_coords_(has_coords), var_name_(var_name) {
    }
  };
  std::map<std::string, dimSpecs> dimInfo;

  // record of input variable specs
  struct varSpecs {
    std::vector<std::string> dim_list_;
    std::string dtype_;
    bool has_chans_;
    std::vector<int> chan_nums_;

    // constructor
    varSpecs(const std::vector<std::string> & dim_list, const std::string & dtype,
             const bool has_chans = false,
             const std::vector<int> & chan_nums = std::vector<int>()) :
        dim_list_(dim_list), dtype_(dtype), has_chans_(has_chans), chan_nums_(chan_nums) {
    }
  };
  std::map<std::string, varSpecs> varInfo;

  // Record information about dimension scales
  for (auto & dimName: in_group.vars.list()) {
    ioda::Variable var = in_group.vars.open(dimName);
    if (var.isDimensionScale()) {
      ioda::Dimensions varDims = var.getDimensions();
      dimSpecs dspecs(varDims.dimsCur[0]);
      dimInfo.insert(std::pair<std::string, dimSpecs>(dimName, dspecs));
    }
  }

  // Record information about variables
  std::set<std::string> necessaryDims;
  for (auto & varName : in_group.vars.list()) {
    ioda::Variable var = in_group.vars.open(varName);
    if (!var.isDimensionScale()) {
      // Find which dimensions are attached to this variable
      ioda::Dimensions varDims = var.getDimensions();
      std::vector<std::string> dimList;
      for (std::size_t i = 0; i < varDims.dimensionality; ++i) {
        for (auto & idim : dimInfo) {
          std::string dimName = idim.first;
          ioda::Variable dimVar = in_group.vars[dimName];
          if (var.isDimensionScaleAttached(i, dimVar)) {
            dimList.push_back(dimName);
            // Every variable is a vector so just keep track of the first dimension
            // for the output. Strings are stored as 2D character arrays in the input
            // file, but will be stored as string vectors in the output file.
            if (i == 0) {
              necessaryDims.insert(dimName);
            }
          }
        }
      }

      // Find the type of this variable, only have int, float and string
      std::string varType;
      if (var.isA<int>()) {
        varType = "int";
      } else if (var.isA<float>()) {
        varType = "float";
      } else {
        varType = "string";
      }

      // Record the variable information
      varSpecs varspecs(dimList, varType);
      varInfo.insert(std::pair<std::string, varSpecs>(varName, varspecs));
    }
  }

  // Create the dimension scales in the output file
  for (auto & dimName : necessaryDims) {
    std::vector<int> dimIndices(dimInfo.at(dimName).size_);
    std::iota(dimIndices.begin(), dimIndices.end(), 1);
    out_group.createDimScale(dimName, dimIndices);
  }

  // Transfer the variables to the output file
  for (auto & ivar : varInfo) {
    std::string varName = ivar.first;
    ioda::Variable inVar = in_group.vars.open(varName);

    std::cout << "Input variable: " << varName << std::endl;
    for (auto & attrName : inVar.atts.list()) {
      std::cout << "    Attribute: " << attrName << std::endl;
    }
  }

  return 0;
}
