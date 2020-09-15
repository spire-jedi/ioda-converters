# Data files are Big Endian
if(CMAKE_Fortran_COMPILER_ID MATCHES GNU)
    set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -fconvert=big-endian")
elseif(CMAKE_Fortran_COMPILER_ID MATCHES Intel)
    set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -convert big_endian")
endif()

list(APPEND _godae_lib_srcs
  ocn_types.h
  ocn_obs_jedi.f
  godae.interface.h
  godae.interface.f90)

ecbuild_add_library(TARGET   godae
                    SOURCES  ${_godae_lib_srcs}
                    INSTALL_HEADERS LISTED
                    HEADER_DESTINATION ${INSTALL_INCLUDE_DIR}/iodaconv
                    LINKER_LANGUAGE CXX
                   )
add_library(${PROJECT_NAME}::godae ALIAS godae)

# Test Fortran program to read profile, trak and ship files
set(_execName read_godae.x)
add_executable(${_execName} read_ocn_obs_jedi.f90)
target_link_libraries(${_execName} PRIVATE ${PROJECT_NAME}::godae)
install(TARGETS ${_execName} RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
set_target_properties(${_execName} PROPERTIES
                    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
