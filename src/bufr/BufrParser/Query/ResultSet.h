//
// Created by rmclaren on 6/30/21.
//

#pragma once

#include "FortranObject.h"

#include <iostream>
#include <memory>
#include <string>
#include <vector>
#include <map>


namespace Ingester {
namespace bufr {
    const double MissingValue = 10e10;

    struct DataField
    {
        std::string name;
        std::string queryStr;
        bool isString;
        bool missing = false;
        std::vector<double> data;
        std::vector<size_t> seqPath;
        std::vector<std::vector<int>> seqCounts;
        std::vector<std::string> dimPaths;
        std::vector<int> exportDims;
    };

    class DataFrame
    {
     public:
        DataFrame(int fieldCnt)
        {
            fields_.resize(fieldCnt);
        }

        inline DataField& fieldAtIdx(size_t idx) { return fields_[idx]; }
        inline DataField& fieldForNodeNamed(const std::string& name) { return fields_[fieldIdxMap_[name]]; }
        int fieldIndexForNodeNamed(const std::string& name) { return fieldIdxMap_[name]; }

     private:
        std::vector<DataField> fields_;
        std::map<std::string, int> fieldIdxMap_;
    };

    struct ResultBase
    {
        std::string field_name;
        std::string group_by_field_name;
        std::vector<std::size_t> dims;
        std::vector<std::string> dimPaths;

        virtual ~ResultBase() {}
        virtual void print() = 0;
    };

    template <typename T>
    struct Result : ResultBase
    {
        typedef T value_type;
        
        std::vector<T> data;

        void print() final
        {
            std::cout << data.size() << std::endl;
            for (auto val : data)
            {
                std::cout << val << ", ";
            }
        }
    };

    class ResultSet
    {
     public:
        ResultSet(const std::vector<std::string>& names);
        ~ResultSet();

        std::shared_ptr<ResultBase> get(const std::string& field_name, 
                                        const std::string& group_by_field = "") const;

        DataFrame& nextDataFrame();

     private:
        std::vector<DataFrame> dataFrames_;
        std::vector<std::string> names_;
        std::vector<int> fieldWidths;

        void getRawValues(const std::string& fieldName,
                          const std::string& groupByFieldName,
                          std::vector<double>& data,
                          std::vector<int>& dims,
                          std::vector<std::string>& dimPaths);

        bool isString(const std::string& fieldName) const;
    };
}  // namespace bufr
}  // namespace Ingester
