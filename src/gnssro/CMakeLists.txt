# src/gnssro/CMakeLists.txt
#
# Build gnssro ncepbufr to ioda NetCDF4 converter
#

set(GNSSRO_SRC gnssro_bufr2ioda.f90)
add_executable(gnssro_bufr2ioda ${GNSSRO_SRC})

target_link_libraries(gnssro_bufr2ioda bufr::bufr_4_DA)
target_link_libraries(gnssro_bufr2ioda NetCDF::NetCDF_Fortran)

install(TARGETS gnssro_bufr2ioda RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
set_target_properties(gnssro_bufr2ioda PROPERTIES
                    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
