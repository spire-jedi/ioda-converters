# Install script for directory: /scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/src/gsi-ncdiag

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
    "/scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/src/gsi-ncdiag/proc_gsi_ncdiag.py"
    "/scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/src/gsi-ncdiag/test_gsidiag.py"
    "/scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/src/gsi-ncdiag/combine_conv.py"
    "/scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/src/gsi-ncdiag/subset_files.py"
    )
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xUnspecifiedx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib/pyiodaconv" TYPE FILE FILES "/scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/src/gsi-ncdiag/gsi_ncdiag.py")
endif()

