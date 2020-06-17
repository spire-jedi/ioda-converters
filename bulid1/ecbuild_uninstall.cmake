# (C) Copyright 2011- ECMWF.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
# In applying this licence, ECMWF does not waive the privileges and immunities
# granted to it by virtue of its status as an intergovernmental organisation
# nor does it submit to any jurisdiction.

if(NOT EXISTS "/scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/bulid1/install_manifest.txt")
  message(FATAL_ERROR "Cannot find install manifest: /scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/bulid1/install_manifest.txt")
endif()

file(READ "/scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/bulid1/install_manifest.txt" files)
string(REGEX REPLACE "\n" ";" files "${files}")

if(EXISTS "/scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/bulid1/extra_install.txt")
  file(READ "/scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/bulid1/extra_install.txt" __files)
  string(REGEX REPLACE "\n" ";" __files "${__files}")
  list(APPEND files ${__files})
endif()

foreach(file ${files})
  message(STATUS "Uninstalling $ENV{DESTDIR}${file}")
  if(IS_SYMLINK "$ENV{DESTDIR}${file}" OR EXISTS "$ENV{DESTDIR}${file}")
    exec_program(
      "/scratch1/NCEPDEV/jcsda/Ryan.Honeyager/jedi/usr/local/intel-18.0.5.274/impi-2018.0.4/netcdf-hdf5parallel-4.7.0/bin/cmake" ARGS "-E remove \"$ENV{DESTDIR}${file}\""
      OUTPUT_VARIABLE rm_out
      RETURN_VALUE rm_retval
      )
    if(NOT "${rm_retval}" STREQUAL 0)
      message(FATAL_ERROR "Problem when removing $ENV{DESTDIR}${file}")
    endif()
  else()
    message(STATUS "File $ENV{DESTDIR}${file} does not exist.")
  endif()
endforeach(file)
