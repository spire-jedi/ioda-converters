list(APPEND _godae_srcs
  ocn_types.h
  ocn_obs_jedi.f
  read_ocn_obs_jedi.f90)

if(CMAKE_Fortran_COMPILER_ID MATCHES GNU)
    set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -fconvert=big-endian")
elseif(CMAKE_Fortran_COMPILER_ID MATCHES Intel)
    set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -convert big_endian")
endif()

set(_execName read_godae.x)
add_executable(${_execName} ${_godae_srcs})

if(CMAKE_Fortran_COMPILER_ID MATCHES GNU AND CMAKE_Fortran_COMPILER_VERSION VERSION_GREATER_EQUAL 10)
    target_compile_options(${_execName} PRIVATE -fallow-argument-mismatch)
endif()
install(TARGETS ${_execName} RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
set_target_properties(${_execName} PROPERTIES
                    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
