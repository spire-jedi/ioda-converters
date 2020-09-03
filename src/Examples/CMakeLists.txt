# src/gnssro/CMakeLists.txt
#
# Build gnssro ncepbufr to ioda NetCDF4 converter
#


add_executable(netcdf2ioda.x netcdf2ioda.cc)
target_link_libraries(netcdf2ioda.x PUBLIC ioda_engines::ioda_engines)
