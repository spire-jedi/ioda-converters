/*
 * (C) Copyright 2020 UCAR
 * 
 * This software is licensed under the terms of the Apache Licence Version 2.0
 * which can be obtained at http://www.apache.org/licenses/LICENSE-2.0. 
 */

#include "convertIoda.h"

#include <iostream>
#include <numeric>
#include <set>

//**********************************************************************//
// FUNCTIONS
//**********************************************************************//

void getDimensionInfo(const ioda::Group & file, DimInfo_t & dimInfo) {
  // Look through the variables and check how they are dimensioned. Record the dimension
  // names, sizes and mark which ones need to be used in the output file. Also record
  // the variable names and which dimensions go with each variable. There are
  // two primary changes to the variables to consider:
  //     Radiances go from a list of vectors (one per channel) to a single 2D array
  //     String go from 2D character arrays to vectors of strings

  for (auto & dimName: file.vars.list()) {
    ioda::Variable var = file.vars.open(dimName);
    if (var.isDimensionScale()) {
      ioda::Dimensions varDims = var.getDimensions();
      bool unlimited = (dimName == "nlocs");
      DimSpecs dspecs(varDims.dimsCur[0], unlimited);
      dimInfo.insert(std::pair<std::string, DimSpecs>(dimName, dspecs));
    }
  }

}

void getVariableInfo(const ioda::Group & file, DimInfo_t & dimInfo, VarInfo_t & varInfo) {
  for (auto & varName : file.vars.list()) {
    ioda::Variable var = file.vars.open(varName);
    if (!var.isDimensionScale()) {
      // Find which dimensions are attached to this variable
      ioda::Dimensions varDims = var.getDimensions();
      std::vector<std::string> dimList;
      for (std::size_t i = 0; i < varDims.dimensionality; ++i) {
        for (auto & idim : dimInfo) {
          std::string dimName = idim.first;
          ioda::Variable dimVar = file.vars[dimName];
          if (var.isDimensionScaleAttached(i, dimVar)) {
            // Every variable is a vector so just keep track of the first dimension
            // for the output. Strings are stored as 2D character arrays in the input
            // file, but will be stored as string vectors in the output file.
            if (i == 0) {
              idim.second.need_for_output_ = true;
              dimList.push_back(dimName);
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
      VarSpecs varspecs(dimList, varType);
      varInfo.insert(std::pair<std::string, VarSpecs>(varName, varspecs));
    }
  }
}

void copyGlobalAttributes(const ioda::Group & inGroup, ioda::ObsGroup & outGroup) {
  for (auto & attrName : inGroup.atts.list()) {
    std::cout << "    Attribute: " << attrName << std::endl;
    ioda::Attribute inAttr = inGroup.atts[attrName];
    if (inAttr.isA<int>()) {
      int attrValue;
      inAttr.read<int>(attrValue);
      std::cout << "        Integer: " << attrValue << std::endl;
      outGroup.atts.add<int>(attrName, attrValue, { 1 });
    } else if (inAttr.isA<float>()) {
      float attrValue;
      inAttr.read<float>(attrValue);
      std::cout << "        Float: " << attrValue << std::endl;
      outGroup.atts.add<float>(attrName, attrValue, { 1 });
    } else {
      // string type
      std::string attrValue;
      //inAttr.read<std::string>(attrValue);
      attrValue = "X";
      std::cout << "        String: " << attrValue << std::endl;
      outGroup.atts.add<std::string>(attrName, attrValue, { 1 });
    }
  }
}

void copyVarAttributes(const ioda::Variable & inVar, ioda::Variable & outVar) {
  for (auto & attrName : inVar.atts.list()) {
    if ((attrName != "DIMENSION_LIST") && (attrName != "_Netcdf4Coordinates")) {
      std::cout << "    Attribute: " << attrName << std::endl;
      ioda::Attribute inAttr = inVar.atts[attrName];
      if (inAttr.isA<int>()) {
        int attrValue;
        inAttr.read<int>(attrValue);
        std::cout << "        Integer: " << attrValue << std::endl;
        outVar.atts.add<int>(attrName, attrValue, { 1 });
      } else if (inAttr.isA<float>()) {
        float attrValue;
        inAttr.read<float>(attrValue);
        std::cout << "        Float: " << attrValue << std::endl;
        outVar.atts.add<float>(attrName, attrValue, { 1 });
      } else {
        // string type
        std::string attrValue;
        inAttr.read<std::string>(attrValue);
        //attrValue = "X";
        std::cout << "        String: " << attrValue << std::endl;
        outVar.atts.add<std::string>(attrName, attrValue, { 1 });
      }
    }
  }
}

void copyVarData(const ioda::Variable & inVar, ioda::Variable & outVar) {
  if (inVar.isA<int>()) {
    std::cout << "    Data: Integer" << std::endl;
    std::vector<int> varData;
    inVar.read(varData);
    outVar.write(varData);
  } else if (inVar.isA<float>()) {
    std::cout << "    Data: Float" << std::endl;
    std::vector<float> varData;
    inVar.read(varData);
    outVar.write(varData);
  } else {
    std::cout << "    Data: String" << std::endl;
    //std::vector<std::string> varData;
    //inVar.read(varData);
    //outVar.write(varData);
  }
}

//**********************************************************************//
// MAIN
//**********************************************************************//

int main(int argc, char** argv) {

  DimInfo_t dimInfo;
  VarInfo_t varInfo;

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

  // Open the input and grab dimension and variable information. The input file
  // is not in the new ioda format so open it as a Group (not an ObsGroup).
  ioda::Engines::BackendNames beName = ioda::Engines::BackendNames::Hdf5File;
  ioda::Engines::BackendCreationParameters beParams;
  beParams.fileName = inputFile;
  beParams.action = ioda::Engines::BackendFileActions::Open;
  beParams.openMode = ioda::Engines::BackendOpenModes::Read_Only;

  ioda::Group in_group =
      ioda::Engines::constructBackend(beName, beParams);

  // Record information about dimension scales
  getDimensionInfo(in_group, dimInfo);

  // Record information about variables
  getVariableInfo(in_group, dimInfo, varInfo);

  // Create the new dimension specs for generating the ObsGroup
  ioda::NewDimensionScales_t newDims;
  for (auto & idim : dimInfo) {
    if (idim.second.need_for_output_) {
      std::string dimName = idim.first;
      int dimSize = idim.second.size_;
      int dimMaxSize = idim.second.size_;
      int dimChunkSize = idim.second.size_;
      if (idim.second.unlimited_) dimMaxSize = ioda::Unlimited;
      newDims.push_back(
        std::make_shared<ioda::NewDimensionScale<int>>(dimName, dimSize, dimMaxSize, dimSize));
    }
  }

  // Create a backend with a file for writing, and attach to an ObsGroup
  beName = ioda::Engines::BackendNames::Hdf5File;
  beParams.fileName = outputFile;
  beParams.action = ioda::Engines::BackendFileActions::Create;
  beParams.createMode = ioda::Engines::BackendCreateModes::Truncate_If_Exists;

  ioda::Group backend = constructBackend(beName, beParams);
  ioda::ObsGroup out_group = ioda::ObsGroup::generate(backend, newDims);

  // Copy global (top-level group) attribute
  copyGlobalAttributes(in_group, out_group);

  // Transfer the variables to the output file
  for (auto & ivar : varInfo) {
    std::string varName = ivar.first;
    ioda::Variable inVar = in_group.vars.open(varName);

    std::cout << "Input variable: " << varName << std::endl;
    ioda::Variable outVar;
    if (ivar.second.dtype_ == "int") {
      outVar = createOutputVariable<int>(out_group, varName, ivar.second.dim_list_, -999);
    } else if (ivar.second.dtype_ == "float") {
      outVar = createOutputVariable<float>(out_group, varName, ivar.second.dim_list_, -999);
    } else if (ivar.second.dtype_ == "string") {
      outVar = createOutputVariable<std::string>(out_group, varName, ivar.second.dim_list_, { "fill" });
    }

    // Copy attributes
    copyVarAttributes(inVar, outVar);

    // Copy data
    copyVarData(inVar, outVar);
  }

  return 0;
}
