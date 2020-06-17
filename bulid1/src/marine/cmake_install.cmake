# Install script for directory: /scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/src/marine

# Set the install prefix
if(NOT DEFINED CMAKE_INSTALL_PREFIX)
  set(CMAKE_INSTALL_PREFIX "/scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/build1")
endif()
string(REGEX REPLACE "/$" "" CMAKE_INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}")

# Set the install configuration name.
if(NOT DEFINED CMAKE_INSTALL_CONFIG_NAME)
  if(BUILD_TYPE)
    string(REGEX REPLACE "^[^A-Za-z0-9_]+" ""
           CMAKE_INSTALL_CONFIG_NAME "${BUILD_TYPE}")
  else()
    set(CMAKE_INSTALL_CONFIG_NAME "Release")
  endif()
  message(STATUS "Install configuration: \"${CMAKE_INSTALL_CONFIG_NAME}\"")
endif()

# Set the component getting installed.
if(NOT CMAKE_INSTALL_COMPONENT)
  if(COMPONENT)
    message(STATUS "Install component: \"${COMPONENT}\"")
    set(CMAKE_INSTALL_COMPONENT "${COMPONENT}")
  else()
    set(CMAKE_INSTALL_COMPONENT)
  endif()
endif()

# Install shared libraries without execute permission?
if(NOT DEFINED CMAKE_INSTALL_SO_NO_EXE)
  set(CMAKE_INSTALL_SO_NO_EXE "0")
endif()

# Is this installation the result of a crosscompile?
if(NOT DEFINED CMAKE_CROSSCOMPILING)
  set(CMAKE_CROSSCOMPILING "FALSE")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xUnspecifiedx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/bin" TYPE PROGRAM FILES
    "/scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/bulid1/install-bin/cryosat_ice2ioda.py"
    "/scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/bulid1/install-bin/cryosat_ice2ioda_DBL.py"
    "/scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/bulid1/install-bin/emc_ice2ioda.py"
    "/scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/bulid1/install-bin/gds2_sst2ioda.py"
    "/scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/bulid1/install-bin/gmao_obs2ioda.py"
    "/scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/bulid1/install-bin/godae_profile2ioda.py"
    "/scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/bulid1/install-bin/godae_ship2ioda.py"
    "/scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/bulid1/install-bin/godae_trak2ioda.py"
    "/scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/bulid1/install-bin/hgodas_adt2ioda.py"
    "/scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/bulid1/install-bin/hgodas_insitu2ioda.py"
    "/scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/bulid1/install-bin/hgodas_sst2ioda.py"
    "/scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/bulid1/install-bin/rads_adt2ioda.py"
    "/scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/bulid1/install-bin/smap_sss2ioda.py"
    "/scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/bulid1/install-bin/argoClim2ioda.py"
    )
endif()

