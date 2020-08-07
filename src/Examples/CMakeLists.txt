# src/gnssro/CMakeLists.txt
#
# Build gnssro ncepbufr to ioda NetCDF4 converter
#

ecbuild_add_executable( TARGET  netcdf2ioda.x
                        SOURCES netcdf2ioda.cc
                        LIBS    ioda-engines
                       )
