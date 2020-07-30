# src/gnssro/CMakeLists.txt
#
# Build gnssro ncepbufr to ioda NetCDF4 converter
#

ecbuild_add_executable( TARGET  convertIoda.x
                        SOURCES convertIoda.cc
                        LIBS    ioda::ioda-engines
                       )
