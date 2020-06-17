# CMake generated Testfile for 
# Source directory: /scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/test
# Build directory: /scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/bulid1/test
# 
# This file includes the relevant testing commands required for 
# testing this directory and lists subdirectories to be tested as well.
add_test(test_iodaconv_gds2_sst_l2p "iodaconv_comp.sh" "netcdf" "/scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/bulid1/bin/gds2_sst2ioda.py
                       -i testinput/gds2_sst_l2p.nc
                       -o testrun/gds2_sst_l2p.nc
                       -d 2018041512
                       -t 0.5" "gds2_sst_l2p.nc")
set_tests_properties(test_iodaconv_gds2_sst_l2p PROPERTIES  ENVIRONMENT "OMP_NUM_THREADS=1" LABELS "iodaconv;script" _BACKTRACE_TRIPLES "/scratch1/NCEPDEV/jcsda/Ryan.Honeyager/jedi/usr/local/intel-18.0.5.274/impi-2018.0.4/netcdf-hdf5parallel-4.7.0/share/ecbuild/cmake/ecbuild_add_test.cmake;406;add_test;/scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/test/CMakeLists.txt;84;ecbuild_add_test;/scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/test/CMakeLists.txt;0;")
add_test(test_iodaconv_gds2_sst_l3u "iodaconv_comp.sh" "netcdf" "/scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/bulid1/bin/gds2_sst2ioda.py
                       -i testinput/gds2_sst_l3u.nc
                       -o testrun/gds2_sst_l3u.nc
                       -d 2018041512
                       -t 0.5" "gds2_sst_l3u.nc")
set_tests_properties(test_iodaconv_gds2_sst_l3u PROPERTIES  ENVIRONMENT "OMP_NUM_THREADS=1" LABELS "iodaconv;script" _BACKTRACE_TRIPLES "/scratch1/NCEPDEV/jcsda/Ryan.Honeyager/jedi/usr/local/intel-18.0.5.274/impi-2018.0.4/netcdf-hdf5parallel-4.7.0/share/ecbuild/cmake/ecbuild_add_test.cmake;406;add_test;/scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/test/CMakeLists.txt;95;ecbuild_add_test;/scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/test/CMakeLists.txt;0;")
add_test(test_iodaconv_smap_sss "iodaconv_comp.sh" "netcdf" "/scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/bulid1/bin/smap_sss2ioda.py
                       -i testinput/smap_sss_rss.nc
                       -o testrun/smap_sss_rss.nc
                       -d 2018041512" "smap_sss_rss.nc")
set_tests_properties(test_iodaconv_smap_sss PROPERTIES  ENVIRONMENT "OMP_NUM_THREADS=1" LABELS "iodaconv;script" _BACKTRACE_TRIPLES "/scratch1/NCEPDEV/jcsda/Ryan.Honeyager/jedi/usr/local/intel-18.0.5.274/impi-2018.0.4/netcdf-hdf5parallel-4.7.0/share/ecbuild/cmake/ecbuild_add_test.cmake;406;add_test;/scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/test/CMakeLists.txt;106;ecbuild_add_test;/scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/test/CMakeLists.txt;0;")
add_test(test_iodaconv_rads_adt "iodaconv_comp.sh" "netcdf" "/scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/bulid1/bin/rads_adt2ioda.py
                       -i testinput/rads_adt.nc
                       -o testrun/rads_adt.nc
                       -d 2018041512" "rads_adt.nc")
set_tests_properties(test_iodaconv_rads_adt PROPERTIES  ENVIRONMENT "OMP_NUM_THREADS=1" LABELS "iodaconv;script" _BACKTRACE_TRIPLES "/scratch1/NCEPDEV/jcsda/Ryan.Honeyager/jedi/usr/local/intel-18.0.5.274/impi-2018.0.4/netcdf-hdf5parallel-4.7.0/share/ecbuild/cmake/ecbuild_add_test.cmake;406;add_test;/scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/test/CMakeLists.txt;116;ecbuild_add_test;/scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/test/CMakeLists.txt;0;")
add_test(test_iodaconv_godae_prof "iodaconv_comp.sh" "netcdf" "/scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/bulid1/bin/godae_profile2ioda.py
                       -i testinput/godae_prof.bin
                       -o testrun/godae_prof.nc
                       -d 1998092212" "godae_prof.nc")
set_tests_properties(test_iodaconv_godae_prof PROPERTIES  ENVIRONMENT "OMP_NUM_THREADS=1" LABELS "iodaconv;script" _BACKTRACE_TRIPLES "/scratch1/NCEPDEV/jcsda/Ryan.Honeyager/jedi/usr/local/intel-18.0.5.274/impi-2018.0.4/netcdf-hdf5parallel-4.7.0/share/ecbuild/cmake/ecbuild_add_test.cmake;406;add_test;/scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/test/CMakeLists.txt;126;ecbuild_add_test;/scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/test/CMakeLists.txt;0;")
add_test(test_iodaconv_godae_ship "iodaconv_comp.sh" "netcdf" "/scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/bulid1/bin/godae_ship2ioda.py
                       -i testinput/godae_ship.bin
                       -o testrun/godae_ship.nc
                       -d 1998090112" "godae_ship.nc")
set_tests_properties(test_iodaconv_godae_ship PROPERTIES  ENVIRONMENT "OMP_NUM_THREADS=1" LABELS "iodaconv;script" _BACKTRACE_TRIPLES "/scratch1/NCEPDEV/jcsda/Ryan.Honeyager/jedi/usr/local/intel-18.0.5.274/impi-2018.0.4/netcdf-hdf5parallel-4.7.0/share/ecbuild/cmake/ecbuild_add_test.cmake;406;add_test;/scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/test/CMakeLists.txt;136;ecbuild_add_test;/scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/test/CMakeLists.txt;0;")
add_test(test_iodaconv_godae_trak "iodaconv_comp.sh" "netcdf" "/scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/bulid1/bin/godae_trak2ioda.py
                       -i testinput/godae_trak.bin
                       -o testrun/godae_trak.nc
                       -d 2004070812" "godae_trak.nc")
set_tests_properties(test_iodaconv_godae_trak PROPERTIES  ENVIRONMENT "OMP_NUM_THREADS=1" LABELS "iodaconv;script" _BACKTRACE_TRIPLES "/scratch1/NCEPDEV/jcsda/Ryan.Honeyager/jedi/usr/local/intel-18.0.5.274/impi-2018.0.4/netcdf-hdf5parallel-4.7.0/share/ecbuild/cmake/ecbuild_add_test.cmake;406;add_test;/scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/test/CMakeLists.txt;146;ecbuild_add_test;/scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/test/CMakeLists.txt;0;")
add_test(test_iodaconv_hgodas_insitu "iodaconv_comp.sh" "netcdf" "/scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/bulid1/bin/hgodas_insitu2ioda.py
                       -i testinput/hgodas_insitu.nc
                       -o testrun/hgodas_insitu.nc
                       -d 2018041512" "hgodas_insitu.nc")
set_tests_properties(test_iodaconv_hgodas_insitu PROPERTIES  ENVIRONMENT "OMP_NUM_THREADS=1" LABELS "iodaconv;script" _BACKTRACE_TRIPLES "/scratch1/NCEPDEV/jcsda/Ryan.Honeyager/jedi/usr/local/intel-18.0.5.274/impi-2018.0.4/netcdf-hdf5parallel-4.7.0/share/ecbuild/cmake/ecbuild_add_test.cmake;406;add_test;/scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/test/CMakeLists.txt;156;ecbuild_add_test;/scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/test/CMakeLists.txt;0;")
add_test(test_iodaconv_hgodas_sst "iodaconv_comp.sh" "netcdf" "/scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/bulid1/bin/hgodas_sst2ioda.py
                       -i testinput/hgodas_sst.nc
                       -o testrun/hgodas_sst.nc
                       -d 2018041512" "hgodas_sst.nc")
set_tests_properties(test_iodaconv_hgodas_sst PROPERTIES  ENVIRONMENT "OMP_NUM_THREADS=1" LABELS "iodaconv;script" _BACKTRACE_TRIPLES "/scratch1/NCEPDEV/jcsda/Ryan.Honeyager/jedi/usr/local/intel-18.0.5.274/impi-2018.0.4/netcdf-hdf5parallel-4.7.0/share/ecbuild/cmake/ecbuild_add_test.cmake;406;add_test;/scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/test/CMakeLists.txt;166;ecbuild_add_test;/scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/test/CMakeLists.txt;0;")
add_test(test_iodaconv_argoclim "iodaconv_comp.sh" "netcdf" "/scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/bulid1/bin/argoClim2ioda.py
                       -i testinput/argoclim_test.nc
                       -o testrun/argoclim.nc
                       -d 2019101600" "argoclim.nc")
set_tests_properties(test_iodaconv_argoclim PROPERTIES  ENVIRONMENT "OMP_NUM_THREADS=1" LABELS "iodaconv;script" _BACKTRACE_TRIPLES "/scratch1/NCEPDEV/jcsda/Ryan.Honeyager/jedi/usr/local/intel-18.0.5.274/impi-2018.0.4/netcdf-hdf5parallel-4.7.0/share/ecbuild/cmake/ecbuild_add_test.cmake;406;add_test;/scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/test/CMakeLists.txt;176;ecbuild_add_test;/scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/test/CMakeLists.txt;0;")
add_test(test_iodaconv_cryosat2 "iodaconv_comp.sh" "netcdf" "/scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/bulid1/bin/cryosat_ice2ioda.py
                       -i testinput/cryosat2_L2_test.nc
                       -o testrun/cryosat2_L2.nc
                       -d 2019092112" "cryosat2_L2.nc")
set_tests_properties(test_iodaconv_cryosat2 PROPERTIES  ENVIRONMENT "OMP_NUM_THREADS=1" LABELS "iodaconv;script" _BACKTRACE_TRIPLES "/scratch1/NCEPDEV/jcsda/Ryan.Honeyager/jedi/usr/local/intel-18.0.5.274/impi-2018.0.4/netcdf-hdf5parallel-4.7.0/share/ecbuild/cmake/ecbuild_add_test.cmake;406;add_test;/scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/test/CMakeLists.txt;186;ecbuild_add_test;/scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/test/CMakeLists.txt;0;")
add_test(test_iodaconv_cryosat2_DBL "iodaconv_comp.sh" "netcdf" "/scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/bulid1/bin/cryosat_ice2ioda_DBL.py
                       -i testinput/CS_OFFL_SIR_GDR_2__20160229T132459_20160229T150412_C001.DBL
                       -o testrun/cryosat2_L2_DBL.nc
                       -d 2016022912" "cryosat2_L2_DBL.nc")
set_tests_properties(test_iodaconv_cryosat2_DBL PROPERTIES  ENVIRONMENT "OMP_NUM_THREADS=1" LABELS "iodaconv;script" _BACKTRACE_TRIPLES "/scratch1/NCEPDEV/jcsda/Ryan.Honeyager/jedi/usr/local/intel-18.0.5.274/impi-2018.0.4/netcdf-hdf5parallel-4.7.0/share/ecbuild/cmake/ecbuild_add_test.cmake;406;add_test;/scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/test/CMakeLists.txt;196;ecbuild_add_test;/scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/test/CMakeLists.txt;0;")
add_test(test_iodaconv_gsidiag_conv "iodaconv_comp.sh" "netcdf" "/scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/bulid1/bin/test_gsidiag.py
                       -i testinput/gsidiag_conv_t_sfc_test.nc
                       -o testrun/
                       -t conv
                       -p sfc" "sfc_tv_obs_2018041500.nc4")
set_tests_properties(test_iodaconv_gsidiag_conv PROPERTIES  ENVIRONMENT "OMP_NUM_THREADS=1" LABELS "iodaconv;script" _BACKTRACE_TRIPLES "/scratch1/NCEPDEV/jcsda/Ryan.Honeyager/jedi/usr/local/intel-18.0.5.274/impi-2018.0.4/netcdf-hdf5parallel-4.7.0/share/ecbuild/cmake/ecbuild_add_test.cmake;406;add_test;/scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/test/CMakeLists.txt;210;ecbuild_add_test;/scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/test/CMakeLists.txt;0;")
add_test(test_iodaconv_gsidiag_rad "iodaconv_comp.sh" "netcdf" "/scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/bulid1/bin/test_gsidiag.py
                       -i testinput/gsidiag_amsua_aqua_radiance_test.nc
                       -o testrun/
                       -t rad" "amsua_aqua_obs_2018041500.nc4")
set_tests_properties(test_iodaconv_gsidiag_rad PROPERTIES  ENVIRONMENT "OMP_NUM_THREADS=1" LABELS "iodaconv;script" _BACKTRACE_TRIPLES "/scratch1/NCEPDEV/jcsda/Ryan.Honeyager/jedi/usr/local/intel-18.0.5.274/impi-2018.0.4/netcdf-hdf5parallel-4.7.0/share/ecbuild/cmake/ecbuild_add_test.cmake;406;add_test;/scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/test/CMakeLists.txt;221;ecbuild_add_test;/scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/test/CMakeLists.txt;0;")
add_test(test_iodaconv_wrfdadiag_rad "iodaconv_comp.sh" "netcdf" "/scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/bulid1/bin/test_wrfdadiag.py
                       -i testinput/wrfdadiags_goes-16-abi_2018041500.nc
                       -o testrun/
                       -t rad" "abi_g16_obs_2018041500.nc4")
set_tests_properties(test_iodaconv_wrfdadiag_rad PROPERTIES  ENVIRONMENT "OMP_NUM_THREADS=1" LABELS "iodaconv;script" _BACKTRACE_TRIPLES "/scratch1/NCEPDEV/jcsda/Ryan.Honeyager/jedi/usr/local/intel-18.0.5.274/impi-2018.0.4/netcdf-hdf5parallel-4.7.0/share/ecbuild/cmake/ecbuild_add_test.cmake;406;add_test;/scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/test/CMakeLists.txt;235;ecbuild_add_test;/scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/test/CMakeLists.txt;0;")
