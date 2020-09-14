      subroutine read_metadata(UNIT, n_obs, n_lvl, n_vrsn)
c.............................START PROLOGUE............................
c
c MODULE NAME:  read_metadata
c
c DESCRIPTION:  reads the metadata from an open ocean obs file
c
c PARAMETERS:
c      Name          Type        Usage            Description
c   ----------     ---------     ------    ---------------------------
c   UNIT            integer      input     fortran unit of opened file
c   n_obs           integer      output    number of obs
c   n_lvl           integer      output    number of levels
c   n_vrsn          integer      output    version number data file
c
c..............................END PROLOGUE.............................
c
      implicit none
c
      integer   UNIT
      integer   n_obs
      integer   n_lvl
      integer   n_vrsn
c
      read (UNIT) n_obs, n_lvl, n_vrsn
c
      end
      subroutine ocn_obs
c
c.............................START PROLOGUE............................
c
c MODULE NAME:  ocn_obs
c
c UPDATE DATE:  12 March 2015
c
c DESCRIPTION:  simple driver for processing GODAE server ocean qc
c               obs files
c                  altim - TOPEX, ERS and GFO altimeter SSHA
c                   amsr - amsr microwave SST retrievals
c                   atsr - advanced along track scanning radiometer
c                   gldr - ocean glider T/S dives
c                   goes - geostationary SST retrievals
c                    lac - NOAA AVHRR LAC SST retrievals
c                  mcsst - NOAA AVHRR GAC SST retrievals
c                  metop - METOP AVHRR GAC SST retrievls
c              metop_lac - METOP AVHRR LAC SST retrievals
c                    msg - METOSAT (SEVIRI) SST retrievals
c                profile - T/S subsurface measures
c                   ship - in situ surface measures of T
c                   ssmi - DMSP sea ice concentration retrievals
c                    swh - altimeter significant wave height
c                   trak - TSG observations
c
c               documentation of the variables for each ocean obs
c               file is contained within the respective "rd" routines:
c                  rd_altim, rd_amsr, rd_atsr, rd_goes, rd_gldr,
c                  rd_lac, rd_mcsst, rd_metop, rd_metop_lac, rd_msg,
c                  rd_prof, rd_ship, rd_ssmi, rd_swh, rd_trak
c
c               the first record in all of the ocean obs files
c               contains three variables:
c               1. number of observations in the file
c               2. maximum number of observations levels in the file
c               3. version number of file
c
c               the number of observations and the maximum number
c               of observation levels in the file can be read and
c               passed as automatic array dimensions to a subroutine.
c               note that the maximum number of levels can only be
c               greater than 1 for the {dtg}.profile and {dtg}.glider
c               files.  the purpose of the version number is to
c               support new  observation variables without having
c               to reformat the entire data archive.  an example of
c               this is the appending of surface wind speed to the
c               satellite sst retrievals files.
c
c               all data files are written using ieee 32 bit fortran
c               sequential writes -- BIG ENDIAN
c
c               the code assumes that the ocean obs data files are
c               in a directory structure given by
c                  $data_dir/altim
c                           /amsr
c                           /atsr
c                           /glider
c                           /goes
c                           /lac
c                           /mcsst
c                           /metop
c                           /metop_lac
c                           /msg
c                           /profile
c                           /ship
c                           /ssmi
c                           /swh
c                           /trak
c               where $data_dir is an environmental variable
c               defined by "OCEAN_OBS_DIR" that describes the
c               directory path to the top of ocean obs tree
c
c               all of the code required is concatentated in
c               the ocn_obs.f file.  a compilation can be
c               done using the following
c                  f90 -o ocn_obs ocn_obs.f
c
c               You may need to specify "big_endian" I/O for your
c               specific compiler.
c
c               to see what command line arguments are required,
c               execute ocn_obs with no command line arguments
c
c               temperature units are deg C, salinity units are
c               PSU, sea surface height units are meters, sea ice
c               concentration units are per cent, significant
c               wave height units are meters.
c
c               unless otherwise specified, missing values are
c               set to -999 in all of the ocean obs data files
c
c UPDATE NOTICE:
c 12 March 2015
c - Update to sfobs read for 7-character call signs in v3 of the files
c - Update goes, lac to version 3
c - Update mcsst to version 4
c - Update metop, metop_lac to version 2
c
c....................MAINTENANCE SECTION................................
c
c MODULES CALLED:
c        Name                    Description
c   --------------     -------------------------------------
c   error_exit         standard error processing
c   GETARG             retrieve command line argument
c   GETENV             retrieve environmental variable
c   rd_altim           read altimeter observations
c   rd_amsr            read amsr microwave SST retrievals
c   rd_atsr            read along track scanning radiometer
c   rd_gldr            read glider profile observations
c   rd_goes            read geostationary SST retrievals
c   rd_lac             read NOAA AVHRR lac SST retrievals
c   rd_mcsst           read NOAA AVHRR gac SST retrievals
c   rd_metop           read METOP AVHRR gac SST retrievals
c   rd_metop_lac       read METOP AVHRR lac SST retrievals
c   rd_msg             read METEOSAT SST retrievals
c   rd_prof            read profile observations
c   rd_ship            read sfc in situ SST observations
c   rd_ssmi            read SSM/I sea ice observations
c   rd_swh             read altimeter SWH observations
c   rd_trak            read TSG track observations
c
c..............................END PROLOGUE.............................
c
      implicit  none
c
c     ..set local work file fortran unit number
c
      integer    UNIT
      parameter (UNIT = 60)
c
      character arg * 20
      character data_dir * 256
      character err_msg * 256
      logical   exist
      character file_dtg * 10
      character file_name * 256
      integer   len
      integer   len_dir
      integer   n_arg
      integer   n_lvl
      integer   n_obs
      integer   n_vrsn
      character obs_typ * 9
c
c     ..functions
c
      integer   IARGC
c
c...............................executable..............................
c
c     ..count number command line arguments
c
      n_arg = IARGC ()
      if (n_arg .eq. 0) then
         write (*, '(/, ''OCN_OBS command line arguments:'')')
         write (*, '(/, 5x, ''ocn_obs {type} {dtg} '')')
         write (*, '(/, 5x, ''{type} = obs data type'')')
         write (*, '(5x, '' {dtg} = file date time group'')')
         write (*, '(/, ''  NOTES: 1. {type} can be '',
     *               ''altim, amsr, atsr, glider, goes,'')')
         write (*, '(''                          '',
     *               ''lac, mcsst, metop, metop_lac, msg,'')')
         write (*, '(''                          '',
     *               ''prof, ship, ssmi, swh or trak'')')
         write (*, '(''         2. {dtg} is in the form '',
     *               ''YYYYMMDDHH'')')
         write (*, '(/, ''OCN_OBS environmental variable:'')')
         write (*, '(/, 5x, ''OCN_OBS_DIR = set to qc obs file '',
     *          ''root directory path'')')
         stop
      endif
c
c     ..retrieve obs data type argument
c
      obs_typ = '         '
      call GETARG (1, arg)
      obs_typ = trim(arg)
c
c     ..retrieve file dtg argument
c
      if (n_arg .gt. 1) then
         call GETARG (2, arg)
         file_dtg = arg(1:10)
      else
         write (err_msg, '(''no DTG specified'')')
         call error_exit ('OCN_OBS', err_msg)
      endif
c
c     ..retrieve file root directory
c
      if (n_arg .gt. 2) then
         call GETARG (3, arg)
         data_dir = trim(arg)
      else
         call GETENV ('OCN_OBS_DIR', data_dir)
      endif
      len_dir = len_trim (data_dir)
      if (len_dir .eq. 0) then
         write (err_msg, '(''no file root directory specified'')')
         call error_exit ('OCN_OBS', err_msg)
      endif
c
c-----------------------------------------------------------------------
c
c     ..profile observations
c
      if (trim(obs_typ) .eq. 'prof') then
         file_name = 'report.profile.' // file_dtg
         len = len_trim (file_name)
         open (45, file=file_name(1:len), status='unknown',
     *             form='formatted')
         write (45, '(''   ****** Reading PROFILE Data ******'')')
         write (45, '(''   file date time group: '', a)') file_dtg
         write (45, '(''    data directory path: '', a)')
     *          data_dir(1:len_dir)
         file_name = data_dir(1:len_dir) // '/profile/' //
     *               file_dtg // '.profile'
         len = len_trim (file_name)
         inquire (file=file_name(1:len), exist=exist)
         if (exist) then
            open (UNIT, file=file_name(1:len), status='old',
     *                  form='unformatted')
            read (UNIT) n_obs, n_lvl, n_vrsn
            write (45, '(''        number profiles: '', i10)') n_obs
            write (45, '(''      max number levels: '', i10)') n_lvl
            write (45, '(''    file version number: '', i10)') n_vrsn
            if (n_obs .gt. 0) then
               call rd_prof (UNIT, n_obs, n_lvl, n_vrsn)
            endif
            close (UNIT)
         else
            write (err_msg, '(''file "'', a, ''" does not exist'')')
     *             file_name(1:len)
            call error_exit ('OCN_OBS', err_msg)
         endif
c
c-----------------------------------------------------------------------
c
c     ..glider observations
c
      else if (trim(obs_typ) .eq. 'glider') then
         file_name = 'report.glider.' // file_dtg
         len = len_trim (file_name)
         open (45, file=file_name(1:len), status='unknown',
     *             form='formatted')
         write (45, '(''   ****** Reading GLIDER Data ******'')')
         write (45, '(''   file date time group: '', a)') file_dtg
         write (45, '(''    data directory path: '', a)')
     *          data_dir(1:len_dir)
         file_name = data_dir(1:len_dir) // '/glider/' //
     *               file_dtg // '.glider'
         len = len_trim (file_name)
         inquire (file=file_name(1:len), exist=exist)
         if (exist) then
            open (UNIT, file=file_name(1:len), status='old',
     *                  form='unformatted')
            read (UNIT) n_obs, n_lvl, n_vrsn
            write (45, '(''         number gliders: '', i10)') n_obs
            write (45, '(''      max number levels: '', i10)') n_lvl
            write (45, '(''    file version number: '', i10)') n_vrsn
            if (n_obs .gt. 0) then
               call rd_gldr (UNIT, n_obs, n_lvl, n_vrsn)
            endif
            close (UNIT)
         else
            write (err_msg, '(''file "'', a, ''" does not exist'')')
     *             file_name(1:len)
            call error_exit ('OCN_OBS', err_msg)
         endif
c
c-----------------------------------------------------------------------
c
c     ..surface ship/buoy SST observations
c
      else if (trim(obs_typ) .eq. 'ship') then
         file_name = 'report.ship.' // file_dtg
         len = len_trim (file_name)
         open (45, file=file_name(1:len), status='unknown',
     *             form='formatted')
         write (45, '(''   ****** Reading SHIP Data ******'')')
         write (45, '(''   file date time group: '', a)') file_dtg
         write (45, '(''    data directory path: '', a)')
     *          data_dir(1:len_dir)
         file_name = data_dir(1:len_dir) // '/ship/' //
     *               file_dtg // '.ship'
         len = len_trim (file_name)
         inquire (file=file_name(1:len), exist=exist)
         if (exist) then
            open (UNIT, file=file_name(1:len), status='old',
     *                  form='unformatted')
            read (UNIT) n_obs, n_lvl, n_vrsn
            write (45, '(''        number ship obs: '', i10)') n_obs
            write (45, '(''      max number levels: '', i10)') n_lvl
            write (45, '(''    file version number: '', i10)') n_vrsn
            if (n_obs .gt. 0) then
               call rd_ship (UNIT, n_obs, n_vrsn)
            endif
            close (UNIT)
         else
            write (err_msg, '(''file "'', a, ''" does not exist'')')
     *             file_name(1:len)
            call error_exit ('OCN_OBS', err_msg)
         endif
c
c-----------------------------------------------------------------------
c
c     ..goes sst observations
c
      else if (trim(obs_typ) .eq. 'goes') then
         file_name = 'report.goes.' // file_dtg
         len = len_trim (file_name)
         open (45, file=file_name(1:len), status='unknown',
     *             form='formatted')
         write (45, '(''   ****** Reading GOES SST Data ******'')')
         write (45, '(''   file date time group: '', a)') file_dtg
         write (45, '(''    data directory path: '', a)')
     *          data_dir(1:len_dir)
         file_name = data_dir(1:len_dir) // '/goes/' //
     *               file_dtg // '.goes'
         len = len_trim (file_name)
         inquire (file=file_name(1:len), exist=exist)
         if (exist) then
            open (UNIT, file=file_name(1:len), status='old',
     *                  form='unformatted')
            read (UNIT) n_obs, n_lvl, n_vrsn
            write (45, '(''        number goes obs: '', i10)') n_obs
            write (45, '(''      max number levels: '', i10)') n_lvl
            write (45, '(''    file version number: '', i10)') n_vrsn
            if (n_obs .gt. 0) then
               call rd_goes (UNIT, n_obs, n_vrsn)
            endif
            close (UNIT)
         else
            write (err_msg, '(''file "'', a, ''" does not exist'')')
     *             file_name(1:len)
            call error_exit ('OCN_OBS', err_msg)
         endif
c
c-----------------------------------------------------------------------
c
c     ..msg sst observations
c
      else if (trim(obs_typ) .eq. 'msg') then
         file_name = 'report.msg.' // file_dtg
         len = len_trim (file_name)
         open (45, file=file_name(1:len), status='unknown',
     *             form='formatted')
         write (45, '(''   ****** Reading MSG SST Data ******'')')
         write (45, '(''   file date time group: '', a)') file_dtg
         write (45, '(''    data directory path: '', a)')
     *          data_dir(1:len_dir)
         file_name = data_dir(1:len_dir) // '/msg/' //
     *               file_dtg // '.msg'
         len = len_trim (file_name)
         inquire (file=file_name(1:len), exist=exist)
         if (exist) then
            open (UNIT, file=file_name(1:len), status='old',
     *                  form='unformatted')
            read (UNIT) n_obs, n_lvl, n_vrsn
            write (45, '(''         number msg obs: '', i10)') n_obs
            write (45, '(''      max number levels: '', i10)') n_lvl
            write (45, '(''    file version number: '', i10)') n_vrsn
            if (n_obs .gt. 0) then
               call rd_msg (UNIT, n_obs, n_vrsn)
            endif
            close (UNIT)
         else
            write (err_msg, '(''file "'', a, ''" does not exist'')')
     *             file_name(1:len)
            call error_exit ('OCN_OBS', err_msg)
         endif
c
c-----------------------------------------------------------------------
c
c     ..atsr sst observations
c
      else if (trim(obs_typ) .eq. 'atsr') then
         file_name = 'report.atsr.' // file_dtg
         len = len_trim (file_name)
         open (45, file=file_name(1:len), status='unknown',
     *             form='formatted')
         write (45, '(''   ****** Reading ATSR SST Data ******'')')
         write (45, '(''   file date time group: '', a)') file_dtg
         write (45, '(''    data directory path: '', a)')
     *          data_dir(1:len_dir)
         file_name = data_dir(1:len_dir) // '/atsr/' //
     *               file_dtg // '.atsr'
         len = len_trim (file_name)
         inquire (file=file_name(1:len), exist=exist)
         if (exist) then
            open (UNIT, file=file_name(1:len), status='old',
     *                  form='unformatted')
            read (UNIT) n_obs, n_lvl, n_vrsn
            write (45, '(''        number atsr obs: '', i10)') n_obs
            write (45, '(''      max number levels: '', i10)') n_lvl
            write (45, '(''    file version number: '', i10)') n_vrsn
            if (n_obs .gt. 0) then
               call rd_atsr (UNIT, n_obs, n_vrsn)
            endif
            close (UNIT)
         else
            write (err_msg, '(''file "'', a, ''" does not exist'')')
     *             file_name(1:len)
            call error_exit ('OCN_OBS', err_msg)
         endif
c
c-----------------------------------------------------------------------
c
c     ..metop sst observations
c
      else if (trim(obs_typ) .eq. 'metop') then
         file_name = 'report.metop.' // file_dtg
         len = len_trim (file_name)
         open (45, file=file_name(1:len), status='unknown',
     *             form='formatted')
         write (45, '(''   ****** Reading METOP SST Data ******'')')
         write (45, '(''   file date time group: '', a)') file_dtg
         write (45, '(''    data directory path: '', a)')
     *          data_dir(1:len_dir)
         file_name = data_dir(1:len_dir) // '/metop/' //
     *               file_dtg // '.metop'
         len = len_trim (file_name)
         inquire (file=file_name(1:len), exist=exist)
         if (exist) then
            open (UNIT, file=file_name(1:len), status='old',
     *                  form='unformatted')
            read (UNIT) n_obs, n_lvl, n_vrsn
            write (45, '(''       number metop obs: '', i10)') n_obs
            write (45, '(''      max number levels: '', i10)') n_lvl
            write (45, '(''    file version number: '', i10)') n_vrsn
            if (n_obs .gt. 0) then
               call rd_metop (UNIT, n_obs, n_vrsn)
            endif
            close (UNIT)
         else
            write (err_msg, '(''file "'', a, ''" does not exist'')')
     *             file_name(1:len)
            call error_exit ('OCN_OBS', err_msg)
         endif
c
c-----------------------------------------------------------------------
c
c     ..metop lac sst observations
c
      else if (trim(obs_typ) .eq. 'metop_lac') then
         file_name = 'report.metop_lac.' // file_dtg
         len = len_trim (file_name)
         open (45, file=file_name(1:len), status='unknown',
     *             form='formatted')
         write (45, '(''   ****** Reading METOP LAC SST Data ******'')')
         write (45, '(''   file date time group: '', a)') file_dtg
         write (45, '(''    data directory path: '', a)')
     *          data_dir(1:len_dir)
         file_name = data_dir(1:len_dir) // '/metop_lac/' //
     *               file_dtg // '.metop_lac'
         len = len_trim (file_name)
         inquire (file=file_name(1:len), exist=exist)
         if (exist) then
            open (UNIT, file=file_name(1:len), status='old',
     *                  form='unformatted')
            read (UNIT) n_obs, n_lvl, n_vrsn
            write (45, '(''   number metop lac obs: '', i10)') n_obs
            write (45, '(''      max number levels: '', i10)') n_lvl
            write (45, '(''    file version number: '', i10)') n_vrsn
            if (n_obs .gt. 0) then
               call rd_metop_lac (UNIT, n_obs, n_vrsn)
            endif
            close (UNIT)
         else
            write (err_msg, '(''file "'', a, ''" does not exist'')')
     *             file_name(1:len)
            call error_exit ('OCN_OBS', err_msg)
         endif
c
c-----------------------------------------------------------------------
c
c     ..amsr sst observations
c
      else if (trim(obs_typ) .eq. 'amsr') then
         file_name = 'report.amsr.' // file_dtg
         len = len_trim (file_name)
         open (45, file=file_name(1:len), status='unknown',
     *             form='formatted')
         write (45, '(''   ****** Reading AMSR SST Data ******'')')
         write (45, '(''   file date time group: '', a)') file_dtg
         write (45, '(''    data directory path: '', a)')
     *          data_dir(1:len_dir)
         file_name = data_dir(1:len_dir) // '/amsr/' //
     *               file_dtg // '.amsr'
         len = len_trim (file_name)
         inquire (file=file_name(1:len), exist=exist)
         if (exist) then
            open (UNIT, file=file_name(1:len), status='old',
     *                  form='unformatted')
            read (UNIT) n_obs, n_lvl, n_vrsn
            write (45, '(''        number amsr obs: '', i10)') n_obs
            write (45, '(''      max number levels: '', i10)') n_lvl
            write (45, '(''    file version number: '', i10)') n_vrsn
            if (n_obs .gt. 0) then
               call rd_amsr (UNIT, n_obs, n_vrsn)
            endif
            close (UNIT)
         else
            write (err_msg, '(''file "'', a, ''" does not exist'')')
     *             file_name(1:len)
            call error_exit ('OCN_OBS', err_msg)
         endif
c
c-----------------------------------------------------------------------
c
c     ..avhrr mcsst observations
c
      else if (trim(obs_typ) .eq. 'mcsst') then
         file_name = 'report.mcsst.' // file_dtg
         len = len_trim (file_name)
         open (45, file=file_name(1:len), status='unknown',
     *             form='formatted')
         write (45, '(''   ****** Reading MCSST Data ******'')')
         write (45, '(''   file date time group: '', a)') file_dtg
         write (45, '(''    data directory path: '', a)')
     *          data_dir(1:len_dir)
         file_name = data_dir(1:len_dir) // '/mcsst/' //
     *               file_dtg // '.mcsst'
         len = len_trim (file_name)
         inquire (file=file_name(1:len), exist=exist)
         if (exist) then
            open (UNIT, file=file_name(1:len), status='old',
     *                  form='unformatted')
            read (UNIT) n_obs, n_lvl, n_vrsn
            write (45, '(''       number mcsst obs: '', i10)') n_obs
            write (45, '(''      max number levels: '', i10)') n_lvl
            write (45, '(''    file version number: '', i10)') n_vrsn
            if (n_obs .gt. 0) then
               call rd_mcsst (UNIT, n_obs, n_vrsn)
            endif
            close (UNIT)
         else
            write (err_msg, '(''file "'', a, ''" does not exist'')')
     *             file_name(1:len)
            call error_exit ('OCN_OBS', err_msg)
         endif
c-----------------------------------------------------------------------
c
c     ..lac sst observations
c
      else if (trim(obs_typ) .eq. 'lac') then
         file_name = 'report.lac.' // file_dtg
         len = len_trim (file_name)
         open (45, file=file_name(1:len), status='unknown',
     *             form='formatted')
         write (45, '(''   ****** Reading LAC SST Data ******'')')
         write (45, '(''   file date time group: '', a)') file_dtg
         write (45, '(''    data directory path: '', a)')
     *          data_dir(1:len_dir)
         file_name = data_dir(1:len_dir) // '/lac/' //
     *               file_dtg // '.lac'
         len = len_trim (file_name)
         inquire (file=file_name(1:len), exist=exist)
         if (exist) then
            open (UNIT, file=file_name(1:len), status='old',
     *                  form='unformatted')
            read (UNIT) n_obs, n_lvl, n_vrsn
            write (45, '(''     number lac sst obs: '', i10)') n_obs
            write (45, '(''      max number levels: '', i10)') n_lvl
            write (45, '(''    file version number: '', i10)') n_vrsn
            if (n_obs .gt. 0) then
               call rd_lac (UNIT, n_obs, n_vrsn)
            endif
            close (UNIT)
         else
            write (err_msg, '(''file "'', a, ''" does not exist'')')
     *             file_name(1:len)
            call error_exit ('OCN_OBS', err_msg)
         endif
c
c-----------------------------------------------------------------------
c
c     ..altimeter observations
c
      else if (trim(obs_typ) .eq. 'altim') then
         file_name = 'report.altim.' // file_dtg
         len = len_trim (file_name)
         open (45, file=file_name(1:len), status='unknown',
     *             form='formatted')
         write (45, '(''   ****** Reading ALTIM Data ******'')')
         write (45, '(''   file date time group: '', a)') file_dtg
         write (45, '(''    data directory path: '', a)')
     *          data_dir(1:len_dir)
         file_name = data_dir(1:len_dir) // '/altim/' //
     *               file_dtg // '.altim'
         len = len_trim (file_name)
         inquire (file=file_name(1:len), exist=exist)
         if (exist) then
            open (UNIT, file=file_name(1:len), status='old',
     *                  form='unformatted')
            read (UNIT) n_obs, n_lvl, n_vrsn
            write (45, '(''       number altim obs: '', i10)') n_obs
            write (45, '(''      max number levels: '', i10)') n_lvl
            write (45, '(''    file version number: '', i10)') n_vrsn
            if (n_obs .gt. 0) then
               call rd_altim (UNIT, n_obs, n_vrsn)
            endif
            close (UNIT)
         else
            write (err_msg, '(''file "'', a, ''" does not exist'')')
     *             file_name(1:len)
            call error_exit ('OCN_OBS', err_msg)
         endif
c
c-----------------------------------------------------------------------
c
c     ..SSM/I sea ice observations
c
      else if (trim(obs_typ) .eq. 'ssmi') then
         file_name = 'report.ssmi.' // file_dtg
         len = len_trim (file_name)
         open (45, file=file_name(1:len), status='unknown',
     *             form='formatted')
         write (45, '(''   ****** Reading SSMI Data ******'')')
         write (45, '(''   file date time group: '', a)') file_dtg
         write (45, '(''    data directory path: '', a)')
     *          data_dir(1:len_dir)
         file_name = data_dir(1:len_dir) // '/ssmi/' //
     *               file_dtg // '.ssmi'
         len = len_trim (file_name)
         inquire (file=file_name(1:len), exist=exist)
         if (exist) then
            open (UNIT, file=file_name(1:len), status='old',
     *                  form='unformatted')
            read (UNIT) n_obs, n_lvl, n_vrsn
            write (45, '(''        number ssmi obs: '', i10)') n_obs
            write (45, '(''      max number levels: '', i10)') n_lvl
            write (45, '(''    file version number: '', i10)') n_vrsn
            if (n_obs .gt. 0) then
               call rd_ssmi (UNIT, n_obs, n_vrsn)
            endif
            close (UNIT)
         else
            write (err_msg, '(''file "'', a, ''" does not exist'')')
     *             file_name(1:len)
            call error_exit ('OCN_OBS', err_msg)
         endif
c
c-----------------------------------------------------------------------
c
c     ..SWH observations
c
      else if (trim(obs_typ) .eq. 'swh') then
         file_name = 'report.swh.' // file_dtg
         len = len_trim (file_name)
         open (45, file=file_name(1:len), status='unknown',
     *             form='formatted')
         write (45, '(''   ****** Reading SWH Data ******'')')
         write (45, '(''   file date time group: '', a)') file_dtg
         write (45, '(''    data directory path: '', a)')
     *          data_dir(1:len_dir)
         file_name = data_dir(1:len_dir) // '/swh/' //
     *               file_dtg // '.swh'
         len = len_trim (file_name)
         inquire (file=file_name(1:len), exist=exist)
         if (exist) then
            open (UNIT, file=file_name(1:len), status='old',
     *                  form='unformatted')
            read (UNIT) n_obs, n_lvl, n_vrsn
            write (45, '(''         number swh obs: '', i10)') n_obs
            write (45, '(''      max number levels: '', i10)') n_lvl
            write (45, '(''    file version number: '', i10)') n_vrsn
            if (n_obs .gt. 0) then
               call rd_swh (UNIT, n_obs, n_vrsn)
            endif
            close (UNIT)
         else
            write (err_msg, '(''file "'', a, ''" does not exist'')')
     *             file_name(1:len)
            call error_exit ('OCN_OBS', err_msg)
         endif
c
c-----------------------------------------------------------------------
c
c     ..TRAK observations
c
      else if (trim(obs_typ) .eq. 'trak') then
         file_name = 'report.trak.' // file_dtg
         len = len_trim (file_name)
         open (45, file=file_name(1:len), status='unknown',
     *             form='formatted')
         write (45, '(''   ****** Reading TRAK Data ******'')')
         write (45, '(''   file date time group: '', a)') file_dtg
         write (45, '(''    data directory path: '', a)')
     *          data_dir(1:len_dir)
         file_name = data_dir(1:len_dir) // '/trak/' //
     *               file_dtg // '.trak'
         len = len_trim (file_name)
         inquire (file=file_name(1:len), exist=exist)
         if (exist) then
            open (UNIT, file=file_name(1:len), status='old',
     *                  form='unformatted')
            read (UNIT) n_obs, n_lvl, n_vrsn
            write (45, '(''        number trak obs: '', i10)') n_obs
            write (45, '(''      max number levels: '', i10)') n_lvl
            write (45, '(''    file version number: '', i10)') n_vrsn
            if (n_obs .gt. 0) then
               call rd_trak (UNIT, n_obs, n_vrsn)
            endif
            close (UNIT)
         else
            write (err_msg, '(''file "'', a, ''" does not exist'')')
     *             file_name(1:len)
            call error_exit ('OCN_OBS', err_msg)
         endif
c
c-----------------------------------------------------------------------
c
c     ..unknown obs data type
c
      else
         write (err_msg, '(''unknown obs TYPE "'', a,
     *                     ''" argument specified'')') obs_typ
         call error_exit ('OCN_OBS', err_msg)
      endif
c
      stop
      end
      subroutine rd_altim (UNIT, n_obs, vrsn)
c
c.............................START PROLOGUE............................
c
c MODULE NAME:  rd_altim
c
c DESCRIPTION:  reads the ALTIM ocean obs files and produces a report.
c               the ALTIM SSHA data are processed at NAVO in the
c               ADFC (Altimeter Data Fusion Center) - contact Greg
c               Jacobs at NRL SSC or Doug May at NAVO for details
c               on ADFC processing.
c
c PARAMETERS:
c      Name          Type        Usage            Description
c   ----------     ---------     ------    ---------------------------
c   n_obs           integer      input     number altim obs
c   unit            integer      input     FORTRAN unit number
c   vrsn            integer      input     version number data file
c
c ALTIMETER VARIABLES:
c     ame       Type                     Description
c   --------  --------    ----------------------------------------------
c   ob_age     real       age of the observation in hours since
c                         January 1, 1992.  provides a continuous
c                         time variable.  reported to nearest second.
c   ob_clm     real       SSHA climatological estimate at obs
c                         location and sampling time
c   ob_cycle   integer    satellite cycle number
c   ob_dtg     character  SSHA obs date time group in the form
c                         year, month, day, hour, minute,
c                         second (YYYYMMDDHHMMSS)
c   ob_glb     real       SSHA global analysis estimate at obs
c                         location and sampling time
c   ob_lat     real       SSHA obs latitude (south negative)
c   ob_lon     real       SSHA obs longitude (west negative)
c   ob_qc      real       SSHA obs probability of a gross error
c                         (assumes normal pdf of SSHA errors)
c   ob_rcpt    character  time SSHA obs received at center
c                         (YYYYMMDDHHMMSS)
c   ob_rgn     real       SSHA regional analysis estimate at obs
c                         location and sampling time
c   ob_sat     integer    satellite ID (TOPEX, ERS, GFO) - see
c                         ocn_types.h for codes
c   ob_sgma    real       climatological variability of SSHA at
c                         obs location and time of year
c   ob_smpl    integer    sequential sample number along a
c                         satellite track
c   ob_ssh     real       SSHA observation (meters) in terms of
c                         deviation from a long term TOPEX mean
c   ob_track   integer    satellite track number for cycle
c
c..............................END PROLOGUE.............................
c
      implicit none
c
      include 'ocn_types.h'
c
c     ..local array dimension
c
      integer   n_obs
c
      integer   i, k
      real      ob_age (n_obs)
      real      ob_clm (n_obs)
      integer   ob_cycle (n_obs)
      character ob_dtg (n_obs) * 14
      real      ob_glb (n_obs)
      real      ob_lat (n_obs)
      real      ob_lon (n_obs)
      real      ob_qc (n_obs)
      character ob_rcpt (n_obs) * 14
      real      ob_rgn (n_obs)
      integer   ob_smpl (n_obs)
      integer   ob_sat (n_obs)
      real      ob_sgma (n_obs)
      real      ob_ssh (n_obs)
      integer   ob_track (n_obs)
      integer   UNIT
      integer   vrsn
c
c...............................executable..............................
c
c     ..read altimeter variables
c
      read (UNIT) (ob_age(i),   i = 1, n_obs)
      read (UNIT) (ob_clm(i),   i = 1, n_obs)
      read (UNIT) (ob_cycle(i), i = 1, n_obs)
      read (UNIT) (ob_glb(i),   i = 1, n_obs)
      read (UNIT) (ob_lat(i),   i = 1, n_obs)
      read (UNIT) (ob_lon(i),   i = 1, n_obs)
      read (UNIT) (ob_qc(i),    i = 1, n_obs)
      read (UNIT) (ob_rgn(i),   i = 1, n_obs)
      read (UNIT) (ob_smpl(i),  i = 1, n_obs)
      read (UNIT) (ob_sat(i),   i = 1, n_obs)
      read (UNIT) (ob_sgma(i),  i = 1, n_obs)
      read (UNIT) (ob_ssh(i),   i = 1, n_obs)
      read (UNIT) (ob_track(i), i = 1, n_obs)
      read (UNIT) (ob_dtg(i),   i = 1, n_obs)
      if (vrsn .gt. 1) then
         read (UNIT) (ob_rcpt(i), i = 1, n_obs)
      else
         do i = 1, n_obs
            ob_rcpt(i) = '              '
         enddo
      endif
c
c     ..produce altimeter report
c
      k = 100
      write (45, '(''  reporting skip factor: '', i10)') k
      write (45, '(11x,''dtg'', 12x,''rcpt'', 7x,''lat'',
     *             5x,''lon'', 1x,''sat'', 5x,''ssh'',
     *             4x,''clim'', 4x,''glbl'', 4x,''regn'',
     *             6x,''qc'',  2x,''cycl'', 2x,''trak'',
     *             2x,''smpl'', 4x,''sgma'')')
      do i = 1, n_obs, k
         write (45, '(a,2x,a,2x,2f8.2,i4,f8.4,3f8.3,f8.3,3i6,
     *          f8.4,a)')
     *          ob_dtg(i), ob_rcpt(i), ob_lat(i), ob_lon(i),
     *          ob_sat(i), ob_ssh(i), ob_clm(i), ob_glb(i),
     *          ob_rgn(i), ob_qc(i), ob_cycle(i), ob_track(i),
     *          ob_smpl(i), ob_sgma(i), data_lbl(ob_sat(i))
      enddo
c
      return
      end
      subroutine rd_amsr (UNIT, n_obs, vrsn)
c
c.............................START PROLOGUE............................
c
c MODULE NAME:  rd_amsr
c
c DESCRIPTION:  reads the AMSR ocean obs files and produces a report
c
c NOTES:        the qc probablity of error includes flags indicating
c               a potential diurnal warming event.  diurnal warming
c               is detected by a significant positive anomaly from
c               the background field in low wind and high solar
c               conditions.  a value of 600 is added to the underlying
c               probability as a diurnal warming flag.
c
c PARAMETERS:
c      Name          Type        Usage            Description
c   ----------     ---------     ------    ---------------------------
c   n_obs           integer      input     number amsr obs
c   unit            integer      input     FORTRAN unit number
c   vrsn            integer      input     version number data file
c
c AMSR VARIABLES:
c      Name      Type                      Description
c   ----------  -------     --------------------------------------------
c   ob_age      real        age of the observation in hours since
c                           January 1, 1992.  provides a continuous
c                           time variable.  reported to the nearest
c                           minute.
c   ob_clm      real        GDEM SST climatological estimate at obs
c                           location and sampling time
c   ob_dtg      character   SST obs date time group in the form year,
c                           month, day, hour, minute (YYYYMMDDHHMM)
c   ob_err      real        observation errors reported by NAVO from
c                           buoy match-up data base
c   ob_glb      real        SST global analysis estimate at obs
c                           location and sampling time
c   ob_lat      real        SST obs latitude (south negative)
c   ob_lon      real        SST obs longitude (west negative)
c   ob_qc       real        SST obs probability of a gross error
c                           (assumes normal pdf of SST errors)
c   ob_rgn                  SST regional analysis estimate at obs
c                           location and sampling time
c   ob_slr      real        NWP solar radiation at amsr retrieval
c                           location and observation time
c   ob_sst      real        SST observation
c   ob_typ      integer     SST obseration data type (see ocn_types.h
c                           for codes)
c   ob_wnd      real        NWP surface wind speed at amsr retrieval
c                           location and observation time
c   ob_wm       integer     SST water mass indicator from Bayesian
c                           classification scheme.
c
c..............................END PROLOGUE.............................
c
      implicit none
c
      include 'ocn_types.h'
c
c     ..local array dimension
c
      integer   n_obs
c
      integer   i, k
      real      ob_age (n_obs)
      real      ob_bias (n_obs)
      real      ob_clm (n_obs)
      character ob_dtg (n_obs) * 12
      real      ob_dw (n_obs)
      real      ob_err (n_obs)
      real      ob_glb (n_obs)
      real      ob_lat (n_obs)
      real      ob_lon (n_obs)
      real      ob_qc (n_obs)
      real      ob_rgn (n_obs)
      real      ob_slr (n_obs)
      real      ob_sst (n_obs)
      integer   ob_typ (n_obs)
      real      ob_wnd (n_obs)
      integer   ob_wm (n_obs)
      integer   UNIT
      integer   vrsn
c
c...............................executable..............................
c
c     ..read amsr variables
c
      read (UNIT) (ob_age(i),  i = 1, n_obs)
      read (UNIT) (ob_bias(i), i = 1, n_obs)
      read (UNIT) (ob_clm(i),  i = 1, n_obs)
      read (UNIT) (ob_dw(i),   i = 1, n_obs)
      read (UNIT) (ob_err(i),  i = 1, n_obs)
      read (UNIT) (ob_glb(i),  i = 1, n_obs)
      read (UNIT) (ob_lat(i),  i = 1, n_obs)
      read (UNIT) (ob_lon(i),  i = 1, n_obs)
      read (UNIT) (ob_qc(i),   i = 1, n_obs)
      read (UNIT) (ob_rgn(i),  i = 1, n_obs)
      read (UNIT) (ob_slr(i),  i = 1, n_obs)
      read (UNIT) (ob_sst(i),  i = 1, n_obs)
      read (UNIT) (ob_typ(i),  i = 1, n_obs)
      read (UNIT) (ob_wnd(i),  i = 1, n_obs)
      read (UNIT) (ob_wm(i),   i = 1, n_obs)
      read (UNIT) (ob_dtg(i),  i = 1, n_obs)
c
c     ..produce amsr report
c
      k = 1
      write (45, '(''  reporting skip factor: '', i10)') k
      write (45, '(9x,''dtg'', 5x,''lat'', 5x,''lon'', 4x,''type'',
     *             5x,''sst'', 4x,''clim'', 4x,''glbl'', 4x,''regn'',
     *             2x,''wm'', 5x,''err'', 4x,''bias'', 6x,''dw'',
     *             4x,''wind'', 3x,''solar'', 6x,''qc'')')
      do i = 1, n_obs, k
         write (45, '(a,2f8.2,i8,4f8.2,i4,5f8.2,f8.3,2x,a)')
     *          ob_dtg(i), ob_lat(i), ob_lon(i), ob_typ(i),
     *          ob_sst(i), ob_clm(i), ob_glb(i), ob_rgn(i),
     *          ob_wm(i), ob_err(i), ob_bias(i), ob_dw(i),
     *          ob_wnd(i), ob_slr(i), ob_qc(i), data_lbl(ob_typ(i))
      enddo
c
      return
      end
      subroutine rd_atsr (UNIT, n_obs, vrsn)
c
c.............................START PROLOGUE............................
c
c MODULE NAME:  rd_atsr
c
c DESCRIPTION:  reads the ATSR ocean obs files and produces a report
c               the SST retrievals are created at NAVO - contact Doug
c               May at NAVO for details on ATSR processing.
c
c NOTES:        the qc probablity of error includes flags indicating
c               a potential diurnal warming event.  diurnal warming
c               is detected by a significant positive anomaly from
c               the background field in low wind and high solar
c               conditions.  a value of 600 is added to the underlying
c               probability as a diurnal warming flag.
c
c PARAMETERS:
c      Name          Type        Usage            Description
c   ----------     ---------     ------    ---------------------------
c   n_obs           integer      input     number atsr obs
c   unit            integer      input     FORTRAN unit number
c   vrsn            integer      input     version number data file
c
c ATSR VARIABLES:
c      Name      Type                      Description
c   ----------  -------     --------------------------------------------
c   ob_age      real        age of the observation in hours since
c                           January 1, 1992.  provides a continuous
c                           time variable.  reported to the nearest
c                           minute.
c   ob_aod      real        NAAPS aeorosol optical depth at SST
c                           obs and sampling time (to within +/-
c                           3 hrs).  missing AODs are set to -1.
c   ob_bias     real        bias correction
c   ob_clm      real        GDEM SST climatological estimate at obs
c                           location and sampling time
c   ob_cls      integer     SST water mass indicator from Bayesian
c                           classification scheme
c   ob_dtg      character   SST obs date time group in the form year,
c                           month, day, hour, minute (YYYYMMDDHHMM)
c   ob_dw       real        diurnal warming correction
c   ob_err      real        observation errors reported by NAVO from
c                           buoy match-up data base
c   ob_glb      real        SST global analysis estimate at obs
c                           location and sampling time
c   ob_lat      real        SST obs latitude (south negative)
c   ob_lon      real        SST obs longitude (west negative)
c   ob_qc       real        SST obs probability of a gross error
c                           (assumes normal pdf of SST errors)
c   ob_rgn                  SST regional analysis estimate at obs
c                           location and sampling time
c   ob_slr      real        NWP solar radiation at atsr retrieval
c                           location and observation time
c   ob_sst      real        SST observation
c   ob_typ      integer     SST obseration data type (see ocn_types.h
c                           for codes)
c   ob_wnd      real        NWP surface wind speed at atsr retrieval
c                           location and observation time
c
c..............................END PROLOGUE.............................
c
      implicit none
c
      include 'ocn_types.h'
c
c     ..local array dimension
c
      integer   n_obs
c
      integer   i, k
      real      ob_age (n_obs)
      real      ob_aod (n_obs)
      real      ob_bias (n_obs)
      real      ob_clm (n_obs)
      integer   ob_cls (n_obs)
      character ob_dtg (n_obs) * 12
      real      ob_dw (n_obs)
      real      ob_err (n_obs)
      real      ob_glb (n_obs)
      real      ob_lat (n_obs)
      real      ob_lon (n_obs)
      real      ob_qc (n_obs)
      real      ob_rgn (n_obs)
      real      ob_slr (n_obs)
      real      ob_sst (n_obs)
      integer   ob_typ (n_obs)
      real      ob_wnd (n_obs)
      integer   UNIT
      integer   vrsn
c
c...............................executable..............................
c
c     ..read atsr variables
c
      read (UNIT) (ob_age(i),  i = 1, n_obs)
      read (UNIT) (ob_aod(i),  i = 1, n_obs)
      read (UNIT) (ob_bias(i), i = 1, n_obs)
      read (UNIT) (ob_clm(i),  i = 1, n_obs)
      read (UNIT) (ob_dw(i),   i = 1, n_obs)
      read (UNIT) (ob_err(i),  i = 1, n_obs)
      read (UNIT) (ob_glb(i),  i = 1, n_obs)
      read (UNIT) (ob_lat(i),  i = 1, n_obs)
      read (UNIT) (ob_lon(i),  i = 1, n_obs)
      read (UNIT) (ob_qc(i),   i = 1, n_obs)
      read (UNIT) (ob_rgn(i),  i = 1, n_obs)
      read (UNIT) (ob_slr(i),  i = 1, n_obs)
      read (UNIT) (ob_sst(i),  i = 1, n_obs)
      read (UNIT) (ob_typ(i),  i = 1, n_obs)
      read (UNIT) (ob_wnd(i),  i = 1, n_obs)
      read (UNIT) (ob_cls(i),  i = 1, n_obs)
      read (UNIT) (ob_dtg(i),  i = 1, n_obs)
c
c     ..produce atsr report
c
      k = 100
      write (45, '(''  reporting skip factor: '', i10)') k
      write (45, '(9x,''dtg'', 5x,''lat'', 5x,''lon'', 4x,''type'',
     *             5x,''sst'', 4x,''clim'', 4x,''glbl'', 4x,''regn'',
     *             5x,''aod'', 2x,''wm'', 5x,''err'', 4x,''wind'',
     *             3x,''solar'', 4x,''bias'', 6x,''dw'', 6x,''qc'')')
      do i = 1, n_obs, k
         write (45, '(a,2f8.2,i8,5f8.2,i4,5f8.2,f8.3,2x,a)')
     *          ob_dtg(i), ob_lat(i), ob_lon(i), ob_typ(i),
     *          ob_sst(i), ob_clm(i), ob_glb(i), ob_rgn(i),
     *          ob_aod(i), ob_cls(i), ob_err(i), ob_wnd(i),
     *          ob_slr(i), ob_bias(i), ob_dw(i), ob_qc(i),
     *          data_lbl(ob_typ(i))
      enddo
c
      return
      end
      subroutine rd_gldr (UNIT, n_obs, n_lvl, vrsn)
c
c.............................START PROLOGUE............................
c
c MODULE NAME:  rd_gldr
c
c DESCRIPTION:  reads the GLIDER ocean obs files and produces a report
c
c PARAMETERS:
c      Name          Type        Usage            Description
c   ----------     ---------     ------    ---------------------------
c   n_obs           integer      input     number profile obs
c   n_lvl           integer      input     number profile levels
c   unit            integer      input     FORTRAN unit number
c   vrsn            integer      input     version number data file
c
c PROFILE VARIABLES:
c     ame       Type                     Description
c   --------  --------    ----------------------------------------------
c   ob_btm     real       bottom depth in meters from DBDBV data base
c                         at profile lat,lon
c   ob_clm_sal real       GDEM 3.0 salinity climatology estimate at
c                         glider location, levels and sampling time
c   ob_clm_ssd real       GDEM 3.0 climate salinitiy variability
c   ob_clm_tmp real       GDEM 3.0 temperature climatology estimate at
c                         glider location, levels and sampling time
c   ob_clm_tsd real       GDEM 3.0 climate temperature variability
c   ob_dtg     character  glider observation sampling date time groups
c                         in the form  year, month, day, hour, minute,
c                         second (YYYYMMDDHHMMSS)
c   ob_glb_sal real       global analysis estimate of profile
c                         salinities at glider obs location,
c                         levels, and sampling time
c   ob_glb_ssd real       global analysis salinity errors
c   ob_glb_tmp real       global analysis estimate of glider
c                         temperatures at profile obs location,
c                         levels, and sampling time
c   ob_glb_tsd real       global analysis temperature errors
c   ob_id      character  unique identifier of glider observation
c                         at FNMOC this is the CRC number computed
c                         from the WMO message
c                         at NAVO this is a home-grown number that
c                         has no meaning to the rest of world
c   ob_lat     real       glider observation latitudes (south negative)
c   ob_lon     real       glider observation longitudes (west negative)
c   ob_ls      integer    number of observed glider salinity levels
c                         (a zero indicates temperature-only glider)
c   ob_lt      integer    number of observed glider temperature levels
c   ob_lvl     real       observed glider levels
c   ob_mds_sal real       modas synthetic salinity estimates at glider
c                         locations, levels, and sampling times, based
c                         on ob_tmp or ob_mds_tmp predictors
c   ob_mds_tmp real       modas synthetic temperature estimates at glider
c                         locations, levels, and sampling times.  the
c                         predictor variables used in the generation of
c                         the modas synthetic temperatures are the ob_sst
c                         (SST) and ob_ssh (SSHA) predictor variables
c   on_mode    character  glider sampling mode
c                         "A" ascending glider profile
c                         "D" descending glider profile
c   ob_rcpt    character  glider observation receipt time at FNMOC in
c                         the form year, month, day, hour, minute
c                         (YYYYMMDDHHMM); the difference between
c                         ob_rcpt and ob_dtg gives the timeliness
c                         of the observation at FNMOC
c   ob_rgn_sal real       regional analysis estimate of glider
c                         salinities at glider locations, levels,
c                         and sampling times
c   ob_rgn_ssd real       regional analysis salinity errors
c   ob_rgn_tmp real       regional analysis estimate of glider
c                         temperatures at glider locations, levels,
c                         and sampling times
c   ob_rgn_tsd real       regional analysis temperature errors
c   ob_sal     real       observed glider salinities, if salinity has
c                         not been observed it has been estimated from
c                         climatological T/S regressions
c   ob_sal_err real       salinity observation errors (use with
c                         caution, reported values are experimental)
c   ob_sal_prb real       glider salinity level-by-level probability
c                         of a gross error
c   ob_sal_qc  real       glider salinity overall probability of gross
c                         error (integrates level-by-level errors taking
c                         into account layer thicknesses)
c   ob_sal_std real       climatolgical estimates of variability of
c                         salinity at glider location, levels and
c                         sampling time (one standard deviation)
c   ob_sal_typ integer    glider salinity data type (see ocean_types.h
c                         for codes)
c   ob_sal_xvl real       glider salinity from cross validation analysis
c                         (GDEM 3.0 climate profile in absence of
c                         near-by data)
c   ob_sal_xsd real       glider salinity cross validation error
c                         (based on error reduction of GDEM 3.0 climate
c                         variability)
c   ob_scr     character  profile obs security classification code; "U"
c                         for unclassified
c   ob_sgn     character  glider observation call sign
c   ob_ssh     real       SSHA of glider dynamic height from long-term
c                         hydrographic mean.  dynamic height has been
c                         calculated relative to 2000 m or the bottom
c                         whichever is shallower.  the glider may have
c                         been vertically extended in the dynamic height
c                         computation, so the ob_ssh values must be used
c                         with care for gliders with shallow maximum
c                         observation depths.
c   ob_sst     real       SST estimate (in order of high resoloution
c                         regional analysis if available, global
c                         analysis if available, profile SST if
c                         observed shallow enough or SST climatology
c                         (MODAS or GDEM)) valid at glider observation
c                         locations and sampling times
c   ob_tmp     real       observed glider temperatures
c   ob_tmp_err real       temperature observation errors (use with
c                         caution, reported values are experimental)
c   ob_tmp_prb real       glider temperature level-by-level probability
c                         of a gross error
c   ob_tmp_qc  real       glider temperature overall probability of
c                         gross error (integrates level-by-level errors
c                         taking into account layer thicknesses)
c   ob_tmp_tsd real       climatolgical estimates of variability of
c                         temperature at glider locations, levels and
c                         sampling times (one standard deviation)
c   ob_tmp_typ integer    glider temperature data type (see
c                         ocean_types.h for codes)
c   ob_tmp_xvl real       glider temperature from cross validation
c                         (GDEM 3.0 climate profile in absence of
c                         near-by data)
c   ob_tmp_xsd real       temperature cross validation glider error
c                         (based on error reduction of GDEM 3.0 climate
c                         variability)
c
c..............................END PROLOGUE.............................
c
      implicit none
c
      include 'ocn_types.h'
c
c     ..local array dimensions
c
      integer   n_obs
      integer   n_lvl
c
      integer   i, j, n
      real      ob_btm (n_lvl, n_obs)
      real      ob_clm_sal (n_lvl, n_obs)
      real      ob_clm_ssd (n_lvl, n_obs)
      real      ob_clm_tmp (n_lvl, n_obs)
      real      ob_clm_tsd (n_lvl, n_obs)
      character ob_dtg (n_lvl, n_obs) * 12
      real      ob_glb_sal (n_lvl, n_obs)
      real      ob_glb_ssd (n_lvl, n_obs)
      real      ob_glb_tmp (n_lvl, n_obs)
      real      ob_glb_tsd (n_lvl, n_obs)
      character ob_id (n_obs) * 10
      real      ob_lat (n_lvl, n_obs)
      real      ob_lon (n_lvl, n_obs)
      real      ob_lvl (n_lvl, n_obs)
      integer   ob_ls (n_obs)
      integer   ob_lt (n_obs)
      character ob_mode (n_obs) * 1
      character ob_rcpt (n_obs) * 12
      real      ob_rgn_sal (n_lvl, n_obs)
      real      ob_rgn_ssd (n_lvl, n_obs)
      real      ob_rgn_tmp (n_lvl, n_obs)
      real      ob_rgn_tsd (n_lvl, n_obs)
      character ob_scr (n_obs) * 1
      character ob_sign (n_obs) * 7
      real      ob_sal (n_lvl, n_obs)
      real      ob_sal_err (n_lvl, n_obs)
      real      ob_sal_prb (n_lvl, n_obs)
      real      ob_sal_qc (n_obs)
      integer   ob_sal_typ (n_obs)
      real      ob_sal_xvl (n_lvl, n_obs)
      real      ob_sal_xsd (n_lvl, n_obs)
      real      ob_ssh (n_obs)
      real      ob_sst (n_obs)
      real      ob_tmp (n_lvl, n_obs)
      real      ob_tmp_err (n_lvl, n_obs)
      real      ob_tmp_prb (n_lvl, n_obs)
      real      ob_tmp_qc (n_obs)
      integer   ob_tmp_typ (n_obs)
      real      ob_tmp_xvl (n_lvl, n_obs)
      real      ob_tmp_xsd (n_lvl, n_obs)
      integer   UNIT
      integer   vrsn
c
c...............................executable..............................
c
c     ..read glider variables
c
      read (UNIT) (ob_ls(i),      i = 1, n_obs)
      read (UNIT) (ob_lt(i),      i = 1, n_obs)
      read (UNIT) (ob_mode(i),    i = 1, n_obs)
      read (UNIT) (ob_ssh(i),     i = 1, n_obs)
      read (UNIT) (ob_sst(i),     i = 1, n_obs)
      read (UNIT) (ob_sal_typ(i), i = 1, n_obs)
      read (UNIT) (ob_sal_qc(i),  i = 1, n_obs)
      read (UNIT) (ob_tmp_typ(i), i = 1, n_obs)
      read (UNIT) (ob_tmp_qc(i),  i = 1, n_obs)
      read (UNIT) (ob_rcpt(i),    i = 1, n_obs)
      read (UNIT) (ob_scr(i),     i = 1, n_obs)
      read (UNIT) (ob_sign(i),    i = 1, n_obs)
      read (UNIT) (ob_id(i),      i = 1, n_obs)
      do i = 1, n_obs
         read (UNIT) (ob_btm(j,i),     j = 1, ob_lt(i))
         read (UNIT) (ob_dtg(j,i),     j = 1, ob_lt(i))
         read (UNIT) (ob_lat(j,i),     j = 1, ob_lt(i))
         read (UNIT) (ob_lon(j,i),     j = 1, ob_lt(i))
         read (UNIT) (ob_lvl(j,i),     j = 1, ob_lt(i))
         read (UNIT) (ob_sal(j,i),     j = 1, ob_lt(i))
         read (UNIT) (ob_sal_err(j,i), j = 1, ob_lt(i))
         read (UNIT) (ob_sal_prb(j,i), j = 1, ob_lt(i))
         read (UNIT) (ob_tmp(j,i),     j = 1, ob_lt(i))
         read (UNIT) (ob_tmp_err(j,i), j = 1, ob_lt(i))
         read (UNIT) (ob_tmp_prb(j,i), j = 1, ob_lt(i))
         read (UNIT) (ob_clm_sal(j,i), j = 1, ob_lt(i))
         read (UNIT) (ob_clm_tmp(j,i), j = 1, ob_lt(i))
         read (UNIT) (ob_clm_ssd(j,i), j = 1, ob_lt(i))
         read (UNIT) (ob_clm_tsd(j,i), j = 1, ob_lt(i))
         read (UNIT) (ob_glb_sal(j,i), j = 1, ob_lt(i))
         read (UNIT) (ob_glb_tmp(j,i), j = 1, ob_lt(i))
         read (UNIT) (ob_glb_ssd(j,i), j = 1, ob_lt(i))
         read (UNIT) (ob_glb_tsd(j,i), j = 1, ob_lt(i))
         read (UNIT) (ob_rgn_sal(j,i), j = 1, ob_lt(i))
         read (UNIT) (ob_rgn_tmp(j,i), j = 1, ob_lt(i))
         read (UNIT) (ob_rgn_ssd(j,i), j = 1, ob_lt(i))
         read (UNIT) (ob_rgn_tsd(j,i), j = 1, ob_lt(i))
         read (UNIT) (ob_sal_xvl(j,i), j = 1, ob_lt(i))
         read (UNIT) (ob_tmp_xvl(j,i), j = 1, ob_lt(i))
         read (UNIT) (ob_sal_xsd(j,i), j = 1, ob_lt(i))
         read (UNIT) (ob_tmp_xsd(j,i), j = 1, ob_lt(i))
      enddo
c
c     ..produce glider report
c
      n = 0
      do i = 1, n_obs
         n = n + 1
         write (45, '(110(''-''))')
         write (45, '(''glider call sign            : "'', a, ''"'',
     *          i8)') ob_sign(i), n
         write (45, '(''glider sampling mode        : "'', a, ''"'',
     *          i8)') ob_mode(i)
         write (45, '(''glider received DTG         : "'', a, ''"'')')
     *          ob_rcpt(i)
         write (45, '(''DBDBV bottom depth          : '', f12.1)')
     *          ob_btm(1,i)
         write (45, '(''glider data type codes      : '', 2i6)')
     *          ob_tmp_typ(i), ob_sal_typ(i)
         write (45, '(''temp data type              : "'', a, ''"'')')
     *          data_lbl(ob_tmp_typ(i))
         write (45, '(''salt data type              : "'', a, ''"'')')
     *          data_lbl(ob_sal_typ(i))
         write (45, '(''observed temperature levels : '', i12)')
     *          ob_lt(i)
         write (45, '(''observed salinity levels    : '', i12)')
     *          ob_ls(i)
         write (45, '(''temperature gross error     : '', f12.4)')
     *          ob_tmp_qc(i)
         write (45, '(''salinity gross error        : '', f12.4)')
     *          ob_sal_qc(i)
         write (45, '(''sea surface height anomaly  : '', f12.4)')
     *          ob_ssh(i)
         write (45, '(''sea surface temperature     : '', f12.2)')
     *          ob_sst(i)
         write (45, '(''security classification     : '', 9x,
     *          ''"'', a, ''"'')') ob_scr(i)
         write (45, '(6x,''lat'',     6x,''lon'',     4x,''depth'',
     *                5x,''temp'',    2x,''clm_std'', 2x,''tmp_err'',
     *                2x,''tmp_prb'', 2x,''clm_tmp'', 2x,''glb_tmp'',
     *                2x,''rgn_tmp'', 2x,''glb_std'', 2x,''rgn_std'',
     *                2x,''tmp_xvl'', 2x,''tmp_xsd'')')
         do j = 1, ob_lt(i)
            write (45, '(2f9.3, f9.1, 3f9.2, f9.3, 7f9.2, 2x, a)')
     *             ob_lat(j,i), ob_lon(j,i), ob_lvl(j,i),
     *             ob_tmp(j,i), ob_clm_tsd(j,i),
     *             ob_tmp_err(j,i), ob_tmp_prb(j,i),
     *             ob_clm_tmp(j,i), ob_glb_tmp(j,i),
     *             ob_rgn_tmp(j,i), ob_glb_tsd(j,i),
     *             ob_rgn_tsd(j,i), ob_tmp_xvl(j,i),
     *             ob_tmp_xsd(j,i), ob_dtg(j,i)(7:12)
         enddo
         if (ob_ls(i) .gt. 0) then
            write (45, '(6x,''lat'',     6x,''lon'',     4x,''depth'',
     *                   5x,''salt'',    2x,''clm_std'', 2x,''sal_err'',
     *                   2x,''sal_prb'', 2x,''clm_sal'', 2x,''glb_sal'',
     *                   2x,''rgn_sal'', 2x,''glb_std'', 2x,''rgn_std'',
     *                   2x,''sal_xvl'', 2x,''sal_xsd'')')
            do j = 1, ob_lt(i)
               write (45, '(2f9.3, f9.1, 3f9.2, f9.3, 7f9.2, 2x, a)')
     *                ob_lat(j,i), ob_lon(j,i), ob_lvl(j,i),
     *                ob_sal(j,i), ob_clm_ssd(j,i),
     *                ob_sal_err(j,i), ob_sal_prb(j,i),
     *                ob_clm_sal(j,i), ob_glb_sal(j,i),
     *                ob_rgn_sal(j,i), ob_glb_ssd(j,i),
     *                ob_rgn_ssd(j,i), ob_sal_xvl(j,i),
     *                ob_sal_xsd(j,i), ob_dtg(j,i)(7:12)
            enddo
         endif
      enddo
c
      return
      end
      subroutine rd_goes (UNIT, n_obs, vrsn)
c
c.............................START PROLOGUE............................
c
c MODULE NAME:  rd_goes
c
c DESCRIPTION:  reads the GOES ocean obs files and produces a report
c               the SST retrievals are created at NAVO - contact Doug
c               May at NAVO for details on GOES processing.
c
c NOTES:        the qc probablity of error includes flags indicating
c               a potential diurnal warming event.  diurnal warming
c               is detected by a significant positive anomaly from
c               the background field in low wind and high solar
c               conditions.  a value of 600 is added to the underlying
c               probability as a diurnal warming flag.
c
c PARAMETERS:
c      Name          Type        Usage            Description
c   ----------     ---------     ------    ---------------------------
c   n_obs           integer      input     number goes obs
c   unit            integer      input     FORTRAN unit number
c   vrsn            integer      input     version number data file
c
c GOES VARIABLES:
c      Name      Type                      Description
c   ----------  -------     --------------------------------------------
c   ob_age      real        age of the observation in hours since
c                           January 1, 1992.  provides a continuous
c                           time variable.  reported to the nearest
c                           minute.
c   ob_ang1     real        Solar zenith angle
c   ob_ang2     real        Solar azimuth angle
c   ob_ang3     real        Satellite zenith angle
c   ob_aod      real        NAAPS aeorosol optical depth at SST
c                           obs and sampling time (to within +/-
c                           3 hrs).  missing AODs are set to -1.
c   ob_bias     real        bias correction
c   ob_bt2      real        Brightness temp: channel 2
c   ob_bt4      real        Brightness temp: channel 4
c   ob_bt5      real        Brightness temp: channel 5
c   ob_clm      real        GDEM SST climatological estimate at obs
c                           location and sampling time
c   ob_dtg      character   SST obs date time group in the form year,
c                           month, day, hour, minute (YYYYMMDDHHMM)
c   ob_dw       real        diurnal warming correction
c   ob_err      real        observation errors reported by NAVO from
c                           buoy match-up data base
c   ob_glb      real        SST global analysis estimate at obs
c                           location and sampling time
c   ob_lat      real        SST obs latitude (south negative)
c   ob_lon      real        SST obs longitude (west negative)
c   ob_qc       real        SST obs probability of a gross error
c                           (assumes normal pdf of SST errors)
c   ob_rgn                  SST regional analysis estimate at obs
c                           location and sampling time
c   ob_slr      real        NWP solar radiation at goes retrieval
c                           location and observation time
c   ob_sst      real        SST observation
c   ob_typ      integer     SST obseration data type; GOES 8, 10, 12
c                           day, night retrievals (see ocn_types.h
c                           for codes)
c   ob_wnd      real        NWP surface wind speed at goes retrieval
c                           location and observation time
c   ob_wm       integer     SST water mass indicator from Bayesian
c                           classification scheme.
c
c..............................END PROLOGUE.............................
c
      implicit none
c
      include 'ocn_types.h'
c
c     ..local array dimension
c
      integer   n_obs
c
      integer   i, k
      real      ob_age (n_obs)
      real      ob_ang1 (n_obs)
      real      ob_ang2 (n_obs)
      real      ob_ang3 (n_obs)
      real      ob_aod (n_obs)
      real      ob_bias (n_obs)
      real      ob_bt2 (n_obs)
      real      ob_bt4 (n_obs)
      real      ob_bt5 (n_obs)
      real      ob_clm (n_obs)
      real      ob_dsst (n_obs)
      character ob_dtg (n_obs) * 12
      real      ob_dw (n_obs)
      real      ob_err (n_obs)
      real      ob_glb (n_obs)
      real      ob_lat (n_obs)
      real      ob_lon (n_obs)
      real      ob_qc (n_obs)
      real      ob_rgn (n_obs)
      real      ob_slr (n_obs)
      real      ob_sst (n_obs)
      integer   ob_typ (n_obs)
      real      ob_wnd (n_obs)
      integer   ob_wm (n_obs)
      integer   UNIT
      integer   vrsn
c
c...............................executable..............................
c
c     ..read goes variables
c
      read (UNIT) (ob_wm(i),  i = 1, n_obs)
      read (UNIT) (ob_glb(i), i = 1, n_obs)
      read (UNIT) (ob_lat(i), i = 1, n_obs)
      read (UNIT) (ob_lon(i), i = 1, n_obs)
      read (UNIT) (ob_age(i), i = 1, n_obs)
      read (UNIT) (ob_clm(i), i = 1, n_obs)
      read (UNIT) (ob_qc(i),  i = 1, n_obs)
      read (UNIT) (ob_typ(i), i = 1, n_obs)
      read (UNIT) (ob_rgn(i), i = 1, n_obs)
      read (UNIT) (ob_sst(i), i = 1, n_obs)
      read (UNIT) (ob_aod(i), i = 1, n_obs)
      read (UNIT) (ob_dtg(i), i = 1, n_obs)
      read (UNIT) (ob_err(i), i = 1, n_obs)
      read (UNIT) (ob_wnd(i), i = 1, n_obs)
      read (UNIT) (ob_slr(i), i = 1, n_obs)
      if (vrsn .gt. 1) then
         read (UNIT) (ob_bias(i), i = 1, n_obs)
         read (UNIT) (ob_dw(i),   i = 1, n_obs)
         if (vrsn .gt. 2) then
            read (UNIT) (ob_dsst(i), i = 1, n_obs)
            read (UNIT) (ob_ang1(i), i = 1, n_obs)
            read (UNIT) (ob_ang2(i), i = 1, n_obs)
            read (UNIT) (ob_ang3(i), i = 1, n_obs)
            read (UNIT) (ob_bt2(i),  i = 1, n_obs)
            read (UNIT) (ob_bt4(i),  i = 1, n_obs)
            read (UNIT) (ob_bt5(i),  i = 1, n_obs)
         endif
      else
         do i = 1, n_obs
            ob_bias(i) = -999.
            ob_dw(i) = -999.
         enddo
      endif
c
c     ..produce goes report
c
      k = 100
      write (45, '(''  reporting skip factor: '', i10)') k
      write (45, '(9x,''dtg'', 5x,''lat'', 5x,''lon'', 4x,''type'',
     *             5x,''sst'', 4x,''clim'', 4x,''glbl'', 4x,''regn'',
     *             5x,''aod'', 2x,''wm'', 5x,''err'', 4x,''wind'',
     *             3x,''solar'', 4x,''bias'', 6x,''dw'', 6x,''qc'',
     *             3x,''ang-1'',3x,''ang-2'',3x,''ang-3'',
     *             4x,''bt-2'',4x,''bt-4'',4x,''bt-5'')')
      do i = 1, n_obs, k
         write (45, '(a,2f8.2,i8,5f8.2,i4,5f8.2,f8.3,6f8.2,2x,a)')
     *          ob_dtg(i), ob_lat(i), ob_lon(i), ob_typ(i),
     *          ob_sst(i), ob_clm(i), ob_glb(i), ob_rgn(i),
     *          ob_aod(i), ob_wm(i), ob_err(i), ob_wnd(i),
     *          ob_slr(i), ob_bias(i), ob_dw(i), ob_qc(i),
     *          ob_ang1(i), ob_ang2(i), ob_ang3(i),
     *          ob_bt2(i), ob_bt4(i), ob_bt5(i),
     *          data_lbl(ob_typ(i))
      enddo
c
      return
      end
      subroutine rd_lac (UNIT, n_obs, vrsn)
c
c.............................START PROLOGUE............................
c
c MODULE NAME:  rd_lac
c
c DESCRIPTION:  reads the LAC SST ocean obs files and produces a report
c               LAC SST retrievals are created at NAVO - contact Doug
c               May at NAVO for details on LAC SST processing.
c
c NOTES:        the qc probablity of error includes flags indicating
c               a potential diurnal warming event.  diurnal warming
c               is detected by a significant positive anomaly from
c               the background field in low wind and high solar
c               conditions.  a value of 600 is added to the underlying
c               probability as a diurnal warming flag.
c
c PARAMETERS:
c      Name          Type        Usage            Description
c   ----------     ---------     ------    ---------------------------
c   n_obs           integer      input     number mcsst obs
c   unit            integer      input     FORTRAN unit number
c   vrsn            integer      input     version number data file
c
c MCSST VARIABLES:
c      Name      Type                      Description
c   ----------  -------     --------------------------------------------
c   ob_age      real        age of the observation in hours since
c                           January 1, 1992.  provides a continuous
c                           time variable.  reported to the nearest
c                           minute.
c   ob_ang1     real        Solar zenith angle
c   ob_ang2     real        Solar azimuth angle
c   ob_ang3     real        Satellite zenith angle
c   ob_aod      real        NAAPS aeorosol optical depth at SST
c                           obs and sampling time (to within +/-
c                           3 hrs).  missing AODs are set to -1.
c   ob_bias     real        bias correction
c   ob_bt3      real        Brightness temp: channel 2
c   ob_bt4      real        Brightness temp: channel 4
c   ob_bt5      real        Brightness temp: channel 5
c   ob_clm      real        GDEM SST climatological estimate at obs
c                           location and sampling time
c   ob_dtg      character   SST obs date time group in the form year,
c                           month, day, hour, minute (YYYYMMDDHHMM)
c   ob_dw       real        diurnal warming correction
c   ob_err      real        observation errors reported by NAVO from
c                           buoy match-up data base
c   ob_glb      real        SST global analysis estimate at obs
c                           location and sampling time
c   ob_lat      real        SST obs latitude (south negative)
c   ob_lon      real        SST obs longitude (west negative)
c   ob_qc       real        SST obs probability of a gross error
c                           (assumes normal pdf of SST errors)
c   ob_rgn                  SST regional analysis estimate at obs
c                           location and sampling time
c   ob_slr      real        NWP solar radiation at mcsst retrieval
c                           location and observation time
c   ob_sst      real        SST observation
c   ob_typ      integer     SST obseration data type; NOAA14, NOAA15
c                           NOAA16, NOAA17, NOAA18 day, night
c                           retrievals
c                           (see ocn_types.h for codes)
c   ob_wnd      real        NWP surface wind speed at lac sst
c                           retrieval location and observation time
c   ob_wm       integer     SST water mass indicator from Bayesian
c                           classification scheme.
c
c..............................END PROLOGUE.............................
c
      implicit none
c
      include 'ocn_types.h'
c
c     ..local array dimension
c
      integer   n_obs
c
      integer   i, k
      real      ob_age (n_obs)
      real      ob_ang1 (n_obs)
      real      ob_ang2 (n_obs)
      real      ob_ang3 (n_obs)
      real      ob_aod (n_obs)
      real      ob_bias (n_obs)
      real      ob_bt3 (n_obs)
      real      ob_bt4 (n_obs)
      real      ob_bt5 (n_obs)
      real      ob_clm (n_obs)
      real      ob_dsst (n_obs)
      character ob_dtg (n_obs) * 12
      real      ob_dw (n_obs)
      real      ob_err (n_obs)
      real      ob_glb (n_obs)
      real      ob_lat (n_obs)
      real      ob_lon (n_obs)
      real      ob_qc (n_obs)
      real      ob_rgn (n_obs)
      real      ob_slr (n_obs)
      real      ob_sst (n_obs)
      integer   ob_typ (n_obs)
      real      ob_wnd (n_obs)
      integer   ob_wm (n_obs)
      integer   UNIT
      integer   vrsn
c
c...............................executable..............................
c
c     ..read lac sst variables
c
      read (UNIT) (ob_wm(i),  i = 1, n_obs)
      read (UNIT) (ob_glb(i), i = 1, n_obs)
      read (UNIT) (ob_lat(i), i = 1, n_obs)
      read (UNIT) (ob_lon(i), i = 1, n_obs)
      read (UNIT) (ob_age(i), i = 1, n_obs)
      read (UNIT) (ob_clm(i), i = 1, n_obs)
      read (UNIT) (ob_qc(i),  i = 1, n_obs)
      read (UNIT) (ob_typ(i), i = 1, n_obs)
      read (UNIT) (ob_rgn(i), i = 1, n_obs)
      read (UNIT) (ob_sst(i), i = 1, n_obs)
      read (UNIT) (ob_aod(i), i = 1, n_obs)
      read (UNIT) (ob_dtg(i), i = 1, n_obs)
      read (UNIT) (ob_err(i), i = 1, n_obs)
      read (UNIT) (ob_wnd(i), i = 1, n_obs)
      read (UNIT) (ob_slr(i), i = 1, n_obs)
      if (vrsn .gt. 1) then
         read (UNIT) (ob_bias(i), i = 1, n_obs)
         read (UNIT) (ob_dw(i),   i = 1, n_obs)
         if (vrsn .gt. 2) then
            read (UNIT) (ob_dsst(i), i = 1, n_obs)
            read (UNIT) (ob_ang1(i), i = 1, n_obs)
            read (UNIT) (ob_ang2(i), i = 1, n_obs)
            read (UNIT) (ob_ang3(i), i = 1, n_obs)
            read (UNIT) (ob_bt3(i),  i = 1, n_obs)
            read (UNIT) (ob_bt4(i),  i = 1, n_obs)
            read (UNIT) (ob_bt5(i),  i = 1, n_obs)
         endif
      else
         do i = 1, n_obs
            ob_bias(i) = -999.
            ob_dw(i) = -999.
         enddo
      endif
c
c     ..produce lac sst report
c
      k = 100
      write (45, '(''  reporting skip factor: '', i10)') k
      write (45, '(9x,''dtg'', 5x,''lat'', 5x,''lon'', 4x,''type'',
     *             5x,''sst'', 4x,''clim'', 4x,''glbl'', 4x,''regn'',
     *             5x,''aod'', 2x,''wm'', 5x,''err'', 4x,''wind'',
     *             3x,''solar'', 4x,''bias'', 6x,''dw'', 6x,''qc'',
     *             3x,''ang-1'',3x,''ang-2'',3x,''ang-3'',
     *             4x,''bt-3'',4x,''bt-4'',4x,''bt-5'')')
      do i = 1, n_obs, k
         write (45, '(a,2f8.2,i8,5f8.2,i4,5f8.2,f8.3,6f8.2,2x,a)')
     *          ob_dtg(i), ob_lat(i), ob_lon(i), ob_typ(i),
     *          ob_sst(i), ob_clm(i), ob_glb(i), ob_rgn(i),
     *          ob_aod(i), ob_wm(i), ob_err(i), ob_wnd(i),
     *          ob_slr(i), ob_bias(i), ob_dw(i), ob_qc(i),
     *          ob_ang1(i), ob_ang2(i), ob_ang3(i),
     *          ob_bt3(i), ob_bt4(i), ob_bt5(i),
     *          data_lbl(ob_typ(i))
      enddo
c
      return
      end
      subroutine rd_mcsst (UNIT, n_obs, vrsn)
c
c.............................START PROLOGUE............................
c
c MODULE NAME:  rd_mcsst
c
c DESCRIPTION:  reads the NOAA AVHRR SST retrieval files and produces
c               a report.  NOAA AVHRR retrievals are created at NAVO -
c               contact Doug May at NAVO for details on NOAA AVHRR
c               SST processing.
c
c NOTES:        the qc probablity of error includes flags indicating
c               a potential diurnal warming event.  diurnal warming
c               is detected by a significant positive anomaly from
c               the background field in low wind and high solar
c               conditions.  a value of 600 is added to the underlying
c               probability as a diurnal warming flag.
c
c PARAMETERS:
c      Name          Type        Usage            Description
c   ----------     ---------     ------    ---------------------------
c   n_obs           integer      input     number mcsst obs
c   unit            integer      input     FORTRAN unit number
c   vrsn            integer      input     version number data file
c
c MCSST VARIABLES:
c      Name      Type                      Description
c   ----------  -------     --------------------------------------------
c   ob_age      real        age of the observation in hours since
c                           January 1, 1992.  provides a continuous
c                           time variable.  reported to the nearest
c                           minute.
c   ob_ang1     real        Solar zenith angle
c   ob_ang2     real        Solar azimuth angle
c   ob_ang3     real        Satellite zenith angle
c   ob_aod      real        NAAPS aeorosol optical depth at SST
c                           obs and sampling time (to within +/-
c                           3 hrs).  missing AODs are set to -1.
c   ob_bias     real        bias correction
c   ob_bt3      real        Brightness temp: channel 3
c   ob_bt4      real        Brightness temp: channel 4
c   ob_bt5      real        Brightness temp: channel 5
c   ob_clm      real        GDEM SST climatological estimate at obs
c                           location and sampling time
c   ob_dtg      character   SST obs date time group in the form year,
c                           month, day, hour, minute (YYYYMMDDHHMM)
c   ob_dw       real        diurnal warming correction
c   ob_err      real        observation errors reported by NAVO from
c                           buoy match-up data base
c   ob_glb      real        SST global analysis estimate at obs
c                           location and sampling time
c   ob_lat      real        SST obs latitude (south negative)
c   ob_lon      real        SST obs longitude (west negative)
c   ob_qc       real        SST obs probability of a gross error
c                           (assumes normal pdf of SST errors)
c   ob_rgn                  SST regional analysis estimate at obs
c                           location and sampling time
c   ob_slr      real        NWP solar radiation at mcsst retrieval
c                           location and observation time
c   ob_sst      real        SST observation
c   ob_typ      integer     SST obseration data type; NOAA14, NOAA15
c                           NOAA16, NOAA17, NOAA18 day, night, relaxed
c                           day retrievals
c                           (see ocn_types.h for codes)
c   ob_wnd      real        NWP surface wind speed at mcsst retrieval
c                           location and observation time
c   ob_wm       integer     SST water mass indicator from Bayesian
c                           classification scheme.
c
c..............................END PROLOGUE.............................
c
      implicit none
c
      include 'ocn_types.h'
c
c     ..local array dimension
c
      integer   n_obs
c
      integer   i, k
      real      ob_age (n_obs)
      real      ob_aod (n_obs)
      real      ob_ang1 (n_obs)
      real      ob_ang2 (n_obs)
      real      ob_ang3 (n_obs)
      real      ob_bias (n_obs)
      real      ob_bt3 (n_obs)
      real      ob_bt4 (n_obs)
      real      ob_bt5 (n_obs)
      real      ob_clm (n_obs)
      real      ob_dsst (n_obs)
      character ob_dtg (n_obs) * 12
      real      ob_dw (n_obs)
      real      ob_err (n_obs)
      real      ob_glb (n_obs)
      real      ob_lat (n_obs)
      real      ob_lon (n_obs)
      real      ob_qc (n_obs)
      real      ob_rgn (n_obs)
      real      ob_slr (n_obs)
      real      ob_sst (n_obs)
      integer   ob_typ (n_obs)
      real      ob_wnd (n_obs)
      integer   ob_wm (n_obs)
      integer   UNIT
      integer   vrsn
c
c...............................executable..............................
c
c     ..initialize supplmental variables
c
      do i = 1, n_obs
         ob_bias(i) = -999.
         ob_dw(i) = -999.
         ob_err(i) = -999.
         ob_slr(i) = -999.
         ob_wnd(i) = -999.
      enddo
c
c     ..read mcsst variables
c
      read (UNIT) (ob_wm(i),  i = 1, n_obs)
      read (UNIT) (ob_glb(i), i = 1, n_obs)
      read (UNIT) (ob_lat(i), i = 1, n_obs)
      read (UNIT) (ob_lon(i), i = 1, n_obs)
      read (UNIT) (ob_age(i), i = 1, n_obs)
      read (UNIT) (ob_clm(i), i = 1, n_obs)
      read (UNIT) (ob_qc(i),  i = 1, n_obs)
      read (UNIT) (ob_typ(i), i = 1, n_obs)
      read (UNIT) (ob_rgn(i), i = 1, n_obs)
      read (UNIT) (ob_sst(i), i = 1, n_obs)
      read (UNIT) (ob_aod(i), i = 1, n_obs)
      read (UNIT) (ob_dtg(i), i = 1, n_obs)
      if (vrsn .gt. 1) then
         read (UNIT) (ob_err(i), i = 1, n_obs)
         read (UNIT) (ob_wnd(i), i = 1, n_obs)
         read (UNIT) (ob_slr(i), i = 1, n_obs)
         if (vrsn .gt. 2) then
            read (UNIT) (ob_bias(i), i = 1, n_obs)
            read (UNIT) (ob_dw(i),   i = 1, n_obs)
            if (vrsn .gt. 3) then
               read (UNIT) (ob_dsst(i), i = 1, n_obs)
               read (UNIT) (ob_ang1(i), i = 1, n_obs)
               read (UNIT) (ob_ang2(i), i = 1, n_obs)
               read (UNIT) (ob_ang3(i), i = 1, n_obs)
               read (UNIT) (ob_bt3(i),  i = 1, n_obs)
               read (UNIT) (ob_bt4(i),  i = 1, n_obs)
               read (UNIT) (ob_bt5(i),  i = 1, n_obs)
            endif
         endif
      endif
c
c     ..produce mcsst report
c
      k = 100
      write (45, '(''  reporting skip factor: '', i10)') k
      write (45, '(9x,''dtg'', 5x,''lat'', 5x,''lon'', 4x,''type'',
     *             5x,''sst'', 4x,''clim'', 4x,''glbl'', 4x,''regn'',
     *             5x,''aod'', 2x,''wm'', 5x,''err'', 4x,''wind'',
     *             3x,''solar'', 4x,''bias'', 6x,''dw'', 6x,''qc'',
     *             3x,''ang-1'',3x,''ang-2'',3x,''ang-3'',
     *             4x,''bt-3'',4x,''bt-4'',4x,''bt-5'')')
      do i = 1, n_obs, k
         write (45, '(a,2f8.2,i8,5f8.2,i4,5f8.2,f8.3,6f8.2,2x,a)')
     *          ob_dtg(i), ob_lat(i), ob_lon(i), ob_typ(i),
     *          ob_sst(i), ob_clm(i), ob_glb(i), ob_rgn(i),
     *          ob_aod(i), ob_wm(i), ob_err(i), ob_wnd(i),
     *          ob_slr(i), ob_bias(i), ob_dw(i), ob_qc(i),
     *          ob_ang1(i), ob_ang2(i), ob_ang3(i),
     *          ob_bt3(i), ob_bt4(i), ob_bt5(i),
     *          data_lbl(ob_typ(i))
      enddo
c
      return
      end
      subroutine rd_metop (UNIT, n_obs, vrsn)
c
c.............................START PROLOGUE............................
c
c MODULE NAME:  rd_metop
c
c DESCRIPTION:  reads the METOP GAC AVHRR ocean obs files and produces
c               a report.  METOP GAC retrievals are created at NAVO -
c               contact Doug May at NAVO for details on METOP SST
c               processing.
c
c NOTES:        the qc probablity of error includes flags indicating
c               a potential diurnal warming event.  diurnal warming
c               is detected by a significant positive anomaly from
c               the background field in low wind and high solar
c               conditions.  a value of 600 is added to the underlying
c               probability as a diurnal warming flag.
c
c PARAMETERS:
c      Name          Type        Usage            Description
c   ----------     ---------     ------    ---------------------------
c   n_obs           integer      input     number metop obs
c   unit            integer      input     FORTRAN unit number
c   vrsn            integer      input     version number data file
c
c METOP VARIABLES:
c      Name      Type                      Description
c   ----------  -------     --------------------------------------------
c   ob_age      real        age of the observation in hours since
c                           January 1, 1992.  provides a continuous
c                           time variable.  reported to the nearest
c                           minute.
c   ob_aod      real        NAAPS aeorosol optical depth at SST
c   ob_ang1     real        Solar zenith angle
c   ob_ang2     real        Solar azimuth angle
c   ob_ang3     real        Satellite zenith angle
c                           obs and sampling time (to within +/-
c                           3 hrs).  missing AODs are set to -1.
c   ob_bt3      real        Brightness temp: channel 3
c   ob_bt4      real        Brightness temp: channel 4
c   ob_bt5      real        Brightness temp: channel 5
c   ob_clm      real        GDEM SST climatological estimate at obs
c                           location and sampling time
c   ob_cls      integer     SST water mass indicator from Bayesian
c                           classification scheme
c   ob_dtg      character   SST obs date time group in the form year,
c                           month, day, hour, minute (YYYYMMDDHHMM)
c   ob_err      real        observation errors reported by NAVO from
c                           buoy match-up data base
c   ob_glb      real        SST global analysis estimate at obs
c                           location and sampling time
c   ob_lat      real        SST obs latitude (south negative)
c   ob_lon      real        SST obs longitude (west negative)
c   ob_qc       real        SST obs probability of a gross error
c                           (assumes normal pdf of SST errors)
c   ob_rgn                  SST regional analysis estimate at obs
c                           location and sampling time
c   ob_slr      real        NWP solar radiation at metop retrieval
c                           location and observation time
c   ob_sst      real        SST observation
c   ob_typ      integer     SST obseration data type; METOP-A,
c                           METOP-B, METOP-C day, night, relaxed
c                           day retrievals
c                           (see ocn_types.h for codes)
c   ob_wnd      real        NWP surface wind speed at metop retrieval
c                           location and observation time
c
c..............................END PROLOGUE.............................
c
      implicit none
c
      include 'ocn_types.h'
c
c     ..local array dimension
c
      integer   n_obs
c
      integer   i, k
      real      ob_age (n_obs)
      real      ob_ang1 (n_obs)
      real      ob_ang2 (n_obs)
      real      ob_ang3 (n_obs)
      real      ob_aod (n_obs)
      real      ob_bias (n_obs)
      real      ob_bt3 (n_obs)
      real      ob_bt4 (n_obs)
      real      ob_bt5 (n_obs)
      real      ob_clm (n_obs)
      real      ob_dsst (n_obs)
      integer   ob_cls (n_obs)
      character ob_dtg (n_obs) * 12
      real      ob_dw  (n_obs)
      real      ob_err (n_obs)
      real      ob_glb (n_obs)
      real      ob_lat (n_obs)
      real      ob_lon (n_obs)
      real      ob_qc (n_obs)
      real      ob_rgn (n_obs)
      real      ob_slr (n_obs)
      real      ob_sst (n_obs)
      integer   ob_typ (n_obs)
      real      ob_wnd (n_obs)
      integer   UNIT
      integer   vrsn
c
c...............................executable..............................
c
c     ..read metop variables
c
      read (UNIT) (ob_cls(i),  i = 1, n_obs)
      read (UNIT) (ob_glb(i),  i = 1, n_obs)
      read (UNIT) (ob_lat(i),  i = 1, n_obs)
      read (UNIT) (ob_lon(i),  i = 1, n_obs)
      read (UNIT) (ob_age(i),  i = 1, n_obs)
      read (UNIT) (ob_clm(i),  i = 1, n_obs)
      read (UNIT) (ob_qc(i),   i = 1, n_obs)
      read (UNIT) (ob_typ(i),  i = 1, n_obs)
      read (UNIT) (ob_rgn(i),  i = 1, n_obs)
      read (UNIT) (ob_sst(i),  i = 1, n_obs)
      read (UNIT) (ob_aod(i),  i = 1, n_obs)
      read (UNIT) (ob_dtg(i),  i = 1, n_obs)
      read (UNIT) (ob_err(i),  i = 1, n_obs)
      read (UNIT) (ob_wnd(i),  i = 1, n_obs)
      read (UNIT) (ob_slr(i),  i = 1, n_obs)
      read (UNIT) (ob_bias(i), i = 1, n_obs)
      read (UNIT) (ob_dw(i),   i = 1, n_obs)
      if (vrsn .gt. 1) then
         read (UNIT) (ob_dsst(i), i = 1, n_obs)
         read (UNIT) (ob_ang1(i), i = 1, n_obs)
         read (UNIT) (ob_ang2(i), i = 1, n_obs)
         read (UNIT) (ob_ang3(i), i = 1, n_obs)
         read (UNIT) (ob_bt3(i),  i = 1, n_obs)
         read (UNIT) (ob_bt4(i),  i = 1, n_obs)
         read (UNIT) (ob_bt5(i),  i = 1, n_obs)
      endif
c
c     ..produce metop report
c
      k = 100
      write (45, '(''  reporting skip factor: '', i10)') k
      write (45, '(9x,''dtg'', 5x,''lat'', 5x,''lon'', 4x,''type'',
     *             5x,''sst'', 4x,''clim'', 4x,''glbl'', 4x,''regn'',
     *             5x,''aod'', 2x,''wm'', 5x,''err'', 4x,''wind'',
     *             3x,''solar'', 4x,''bias'', 6x,''dw'', 6x,''qc'',
     *             3x,''ang-1'',3x,''ang-2'',3x,''ang-3'',
     *             4x,''bt-3'',4x,''bt-4'',4x,''bt-5'')')
      do i = 1, n_obs, k
         write (45, '(a,2f8.2,i8,5f8.2,i4,5f8.2,f8.3,6f8.2,2x,a)')
     *          ob_dtg(i), ob_lat(i), ob_lon(i), ob_typ(i),
     *          ob_sst(i), ob_clm(i), ob_glb(i), ob_rgn(i),
     *          ob_aod(i), ob_cls(i), ob_err(i), ob_wnd(i),
     *          ob_slr(i), ob_bias(i), ob_dw(i), ob_qc(i),
     *          ob_ang1(i), ob_ang2(i), ob_ang3(i),
     *          ob_bt3(i), ob_bt4(i), ob_bt5(i),
     *          data_lbl(ob_typ(i))
      enddo
c
      return
      end
      subroutine rd_metop_lac (UNIT, n_obs, vrsn)
c
c.............................START PROLOGUE............................
c
c MODULE NAME:  rd_metop_lac
c
c DESCRIPTION:  reads the METOP AVHRR LAC SST ocean obs files and
c               produces a report. METOP LAC SST retrievals are
c               created at NAVO - contact Doug May at NAVO for
c               details on METOP LAC SST processing.
c
c NOTES:        the qc probablity of error includes flags indicating
c               a potential diurnal warming event.  diurnal warming
c               is detected by a significant positive anomaly from
c               the background field in low wind and high solar
c               conditions.  a value of 600 is added to the underlying
c               probability as a diurnal warming flag.
c
c PARAMETERS:
c      Name          Type        Usage            Description
c   ----------     ---------     ------    ---------------------------
c   n_obs           integer      input     number lac sst obs
c   unit            integer      input     FORTRAN unit number
c   vrsn            integer      input     version number data file
c
c MCSST VARIABLES:
c      Name      Type                      Description
c   ----------  -------     --------------------------------------------
c   ob_age      real        age of the observation in hours since
c                           January 1, 1992.  provides a continuous
c                           time variable.  reported to the nearest
c                           minute.
c   ob_ang1     real        Solar zenith angle
c   ob_ang2     real        Solar azimuth angle
c   ob_ang3     real        Satellite zenith angle
c   ob_aod      real        NAAPS aeorosol optical depth at SST
c                           obs and sampling time (to within +/-
c                           3 hrs).  missing AODs are set to -1.
c   ob_bt3      real        Brightness temp: channel 3
c   ob_bt4      real        Brightness temp: channel 4
c   ob_bt5      real        Brightness temp: channel 5
c   ob_clm      real        GDEM SST climatological estimate at obs
c                           location and sampling time
c   ob_dtg      character   SST obs date time group in the form year,
c                           month, day, hour, minute (YYYYMMDDHHMM)
c   ob_err      real        observation errors reported by NAVO from
c                           buoy match-up data base
c   ob_glb      real        SST global analysis estimate at obs
c                           location and sampling time
c   ob_lat      real        SST obs latitude (south negative)
c   ob_lon      real        SST obs longitude (west negative)
c   ob_qc       real        SST obs probability of a gross error
c                           (assumes normal pdf of SST errors)
c   ob_rgn                  SST regional analysis estimate at obs
c                           location and sampling time
c   ob_slr      real        NWP solar radiation at lac sst retrieval
c                           location and observation time
c   ob_sst      real        SST observation
c   ob_typ      integer     SST obseration data type; NOAA14, NOAA15
c                           NOAA16, NOAA17, NOAA18 day, night
c                           retrievals
c                           (see ocn_types.h for codes)
c   ob_wnd      real        NWP surface wind speed at metop lac sst
c                           retrieval location and observation time
c   ob_wm       integer     SST water mass indicator from Bayesian
c                           classification scheme.
c
c..............................END PROLOGUE.............................
c
      implicit none
c
      include 'ocn_types.h'
c
c     ..local array dimension
c
      integer   n_obs
c
      integer   i, k
      real      ob_age (n_obs)
      real      ob_ang1 (n_obs)
      real      ob_ang2 (n_obs)
      real      ob_ang3 (n_obs)
      real      ob_aod (n_obs)
      real      ob_bias (n_obs)
      real      ob_bt3 (n_obs)
      real      ob_bt4 (n_obs)
      real      ob_bt5 (n_obs)
      real      ob_clm (n_obs)
      real      ob_dsst (n_obs)
      character ob_dtg (n_obs) * 12
      real      ob_dw (n_obs)
      real      ob_err (n_obs)
      real      ob_glb (n_obs)
      real      ob_lat (n_obs)
      real      ob_lon (n_obs)
      real      ob_qc (n_obs)
      real      ob_rgn (n_obs)
      real      ob_slr (n_obs)
      real      ob_sst (n_obs)
      integer   ob_typ (n_obs)
      real      ob_wnd (n_obs)
      integer   ob_wm (n_obs)
      integer   UNIT
      integer   vrsn
c
c...............................executable..............................
c
c     ..read metop lac sst variables
c
      read (UNIT) (ob_wm(i),   i = 1, n_obs)
      read (UNIT) (ob_glb(i),  i = 1, n_obs)
      read (UNIT) (ob_lat(i),  i = 1, n_obs)
      read (UNIT) (ob_lon(i),  i = 1, n_obs)
      read (UNIT) (ob_age(i),  i = 1, n_obs)
      read (UNIT) (ob_clm(i),  i = 1, n_obs)
      read (UNIT) (ob_qc(i),   i = 1, n_obs)
      read (UNIT) (ob_typ(i),  i = 1, n_obs)
      read (UNIT) (ob_rgn(i),  i = 1, n_obs)
      read (UNIT) (ob_sst(i),  i = 1, n_obs)
      read (UNIT) (ob_aod(i),  i = 1, n_obs)
      read (UNIT) (ob_dtg(i),  i = 1, n_obs)
      read (UNIT) (ob_err(i),  i = 1, n_obs)
      read (UNIT) (ob_wnd(i),  i = 1, n_obs)
      read (UNIT) (ob_slr(i),  i = 1, n_obs)
      read (UNIT) (ob_bias(i), i = 1, n_obs)
      read (UNIT) (ob_dw(i),   i = 1, n_obs)
      if (vrsn .gt. 1) then
         read (UNIT) (ob_dsst(i), i = 1, n_obs)
         read (UNIT) (ob_ang1(i), i = 1, n_obs)
         read (UNIT) (ob_ang2(i), i = 1, n_obs)
         read (UNIT) (ob_ang3(i), i = 1, n_obs)
         read (UNIT) (ob_bt3(i),  i = 1, n_obs)
         read (UNIT) (ob_bt4(i),  i = 1, n_obs)
         read (UNIT) (ob_bt5(i),  i = 1, n_obs)
      endif
c
c     ..produce metop lac sst report
c
      k = 100
      write (45, '(''  reporting skip factor: '', i10)') k
      write (45, '(9x,''dtg'', 5x,''lat'', 5x,''lon'', 4x,''type'',
     *             5x,''sst'', 4x,''clim'', 4x,''glbl'', 4x,''regn'',
     *             5x,''aod'', 2x,''wm'', 5x,''err'', 4x,''wind'',
     *             3x,''solar'', 4x,''bias'', 6x,''dw'', 6x,''qc'',
     *             3x,''ang-1'',3x,''ang-2'',3x,''ang-3'',
     *             4x,''bt-3'',4x,''bt-4'',4x,''bt-5'')')
      do i = 1, n_obs, k
         write (45, '(a,2f8.2,i8,5f8.2,i4,5f8.2,f8.3,6f8.2,2x,a)')
     *          ob_dtg(i), ob_lat(i), ob_lon(i), ob_typ(i),
     *          ob_sst(i), ob_clm(i), ob_glb(i), ob_rgn(i),
     *          ob_aod(i), ob_wm(i), ob_err(i), ob_wnd(i),
     *          ob_slr(i), ob_bias(i), ob_dw(i), ob_qc(i),
     *          ob_ang1(i), ob_ang2(i), ob_ang3(i),
     *          ob_bt3(i), ob_bt4(i), ob_bt5(i),
     *          data_lbl(ob_typ(i))
      enddo
c
      return
      end
      subroutine rd_msg (UNIT, n_obs, vrsn)
c
c.............................START PROLOGUE............................
c
c MODULE NAME:  rd_msg
c
c DESCRIPTION:  reads the MSG ocean obs files and produces a report
c               the SST retrievals are created at NAVO - contact Doug
c               May at NAVO for details on MSG processing.
c
c NOTES:        the qc probablity of error includes flags indicating
c               a potential diurnal warming event.  diurnal warming
c               is detected by a significant positive anomaly from
c               the background field in low wind and high solar
c               conditions.  a value of 600 is added to the underlying
c               probability as a diurnal warming flag.
c
c PARAMETERS:
c      Name          Type        Usage            Description
c   ----------     ---------     ------    ---------------------------
c   n_obs           integer      input     number msg obs
c   unit            integer      input     FORTRAN unit number
c   vrsn            integer      input     version number data file
c
c MSG VARIABLES:
c      Name      Type                      Description
c   ----------  -------     --------------------------------------------
c   ob_age      real        age of the observation in hours since
c                           January 1, 1992.  provides a continuous
c                           time variable.  reported to the nearest
c                           minute.
c   ob_aod      real        NAAPS aeorosol optical depth at SST
c                           obs and sampling time (to within +/-
c                           3 hrs).  missing AODs are set to -1.
c   ob_clm      real        GDEM SST climatological estimate at obs
c                           location and sampling time
c   ob_dtg      character   SST obs date time group in the form year,
c                           month, day, hour, minute (YYYYMMDDHHMM)
c   ob_err      real        observation errors reported by NAVO from
c                           buoy match-up data base
c   ob_glb      real        SST global analysis estimate at obs
c                           location and sampling time
c   ob_lat      real        SST obs latitude (south negative)
c   ob_lon      real        SST obs longitude (west negative)
c   ob_qc       real        SST obs probability of a gross error
c                           (assumes normal pdf of SST errors)
c   ob_rgn                  SST regional analysis estimate at obs
c                           location and sampling time
c   ob_slr      real        NWP solar radiation at msg retrieval
c                           location and observation time
c   ob_sst      real        SST observation
c   ob_typ      integer     SST obseration data type (see ocn_types.h
c                           for codes)
c   ob_wnd      real        NWP surface wind speed at msg retrieval
c                           location and observation time
c   ob_wm       integer     SST water mass indicator from Bayesian
c                           classification scheme.
c
c..............................END PROLOGUE.............................
c
      implicit none
c
      include 'ocn_types.h'
c
c     ..local array dimension
c
      integer   n_obs
c
      integer   i, k
      real      ob_age (n_obs)
      real      ob_aod (n_obs)
      real      ob_bias (n_obs)
      real      ob_clm (n_obs)
      character ob_dtg (n_obs) * 12
      real      ob_dw (n_obs)
      real      ob_err (n_obs)
      real      ob_glb (n_obs)
      real      ob_lat (n_obs)
      real      ob_lon (n_obs)
      real      ob_qc (n_obs)
      real      ob_rgn (n_obs)
      real      ob_slr (n_obs)
      real      ob_sst (n_obs)
      integer   ob_typ (n_obs)
      real      ob_wnd (n_obs)
      integer   ob_wm (n_obs)
      integer   UNIT
      integer   vrsn
c
c...............................executable..............................
c
c     ..read msg variables
c
      read (UNIT) (ob_wm(i),   i = 1, n_obs)
      read (UNIT) (ob_glb(i),  i = 1, n_obs)
      read (UNIT) (ob_lat(i),  i = 1, n_obs)
      read (UNIT) (ob_lon(i),  i = 1, n_obs)
      read (UNIT) (ob_age(i),  i = 1, n_obs)
      read (UNIT) (ob_clm(i),  i = 1, n_obs)
      read (UNIT) (ob_qc(i),   i = 1, n_obs)
      read (UNIT) (ob_typ(i),  i = 1, n_obs)
      read (UNIT) (ob_rgn(i),  i = 1, n_obs)
      read (UNIT) (ob_sst(i),  i = 1, n_obs)
      read (UNIT) (ob_dtg(i),  i = 1, n_obs)
      read (UNIT) (ob_err(i),  i = 1, n_obs)
      read (UNIT) (ob_bias(i), i = 1, n_obs)
      read (UNIT) (ob_dw(i),   i = 1, n_obs)
      read (UNIT) (ob_wnd(i),  i = 1, n_obs)
      read (UNIT) (ob_slr(i),  i = 1, n_obs)
      read (UNIT) (ob_aod(i),  i = 1, n_obs)
c
c     ..produce msg report
c
      k = 100
      write (45, '(''  reporting skip factor: '', i10)') k
      write (45, '(9x,''dtg'', 5x,''lat'', 5x,''lon'', 4x,''type'',
     *             5x,''sst'', 4x,''clim'', 4x,''glbl'', 4x,''regn'',
     *             5x,''aod'', 2x,''wm'', 5x,''err'', 4x,''wind'',
     *             3x,''solar'', 4x,''bias'', 6x,''dw'', 6x,''qc'')')
      do i = 1, n_obs, k
         write (45, '(a,2f8.2,i8,5f8.2,i4,5f8.2,f8.3,2x,a)')
     *          ob_dtg(i), ob_lat(i), ob_lon(i), ob_typ(i),
     *          ob_sst(i), ob_clm(i), ob_glb(i), ob_rgn(i),
     *          ob_aod(i), ob_wm(i), ob_err(i), ob_wnd(i),
     *          ob_slr(i), ob_bias(i), ob_dw(i), ob_qc(i),
     *          data_lbl(ob_typ(i))
      enddo
c
      return
      end
      subroutine rd_prof (UNIT, n_obs, n_lvl, vrsn,
     * ob_dtg, ob_lat, ob_lon, ob_lvl,
     * ob_tmp, ob_tmp_err, ob_tmp_qc,
     * ob_sal, ob_sal_err, ob_sal_qc )
c
c.............................START PROLOGUE............................
c
c MODULE NAME:  rd_prof
c
c DESCRIPTION:  reads the PROFILE ocean obs files and produces a report
c
c PARAMETERS:
c      Name          Type        Usage            Description
c   ----------     ---------     ------    ---------------------------
c   n_obs           integer      input     number profile obs
c   n_lvl           integer      input     number profile levels
c   unit            integer      input     FORTRAN unit number
c   vrsn            integer      input     version number data file
c
c PROFILE VARIABLES:
c     ame       Type                     Description
c   --------  --------    ----------------------------------------------
c   ob_btm     real       bottom depth in meters from DBDBV data base
c                         at profile lat,lon
c   ob_clm_sal real       GDEM 3.0 salinity climatology estimate at
c                         profile location, levels and sampling time
c   ob_clm_ssd real       GDEM 3.0 climate salinitiy variability
c   ob_clm_tmp real       GDEM 3.0 temperature climatology estimate at
c                         profile location, levels and sampling time
c   ob_clm_tsd real       GDEM 3.0 climate temperature variability
c   ob_dtg     character  profile observation sampling date time group
c                         in the form  year, month, day, hour, minute,
c                         second (YYYYMMDDHHMMSS)
c   ob_glb_sal real       global analysis estimate of profile
c                         salinities at profile obs location,
c                         levels, and sampling time
c   ob_glb_ssd real       global analysis salinity errors
c   ob_glb_tmp real       global analysis estimate of profile
c                         temperatures at profile obs location,
c                         levels, and sampling time
c   ob_glb_tsd real       global analysis temperature errors
c   ob_id      character  unique identifier of profile observation
c                         at FNMOC this is the CRC number computed
c                         from the WMO message
c                         at NAVO this is a home-grown number that
c                         has no meaning to the rest of world
c   ob_lat     real       profile observation latitude (south negative)
c   ob_lon     real       profile observation longitude (west negative)
c   ob_ls      integer    number of observed profile salinity levels
c                         (a zero indicates temperature-only profile)
c   ob_lt      integer    number of observed profile temperature levels
c   ob_lvl     real       observed profile levels
c   ob_mds_sal real       modas synthetic salinity profile estimate at
c                         profile location, levels, and sampling time
c                         based on ob_mds_tmp or ob_tmp predictors
c   ob_mds_tmp real       modas synthetic temperature profile estimate
c                         at profile location, levels, and sampling
c                         time.  the predictor variables used in the
c                         generation of the modas synthetic profile
c                         are the ob_sst (SST) and ob_ssh (SSHA)
c                         variables.
c   ob_rcpt    character  profile observation receipt time at FNMOC in
c                         the form year, month, day, hour, minute
c                         (YYYYMMDDHHMM); the difference between
c                         ob_rcpt and ob_dtg gives the timeliness
c                         of the observation at FNMOC
c   ob_rgn_sal real       regional analysis estimate of profile
c                         salinities at profile obs location,
c                         levels, and sampling time
c   ob_rgn_ssd real       regional analysis salinity errors
c   ob_rgn_tmp real       regional analysis estimate of profile
c                         temperatures at profile obs location,
c                         levels, and sampling time
c   ob_rgn_tsd real       regional analysis temperature errors
c   ob_sal     real       observed  profile salinities, if salinity has
c                         not been observed it has been estimated from
c                         climatological T/S regressions
c   ob_sal_err real       salinity observation errors (use with
c                         caution, reported values are experimental)
c   ob_sal_prb real       salinity profile level-by-level probability
c                         of a gross error
c   ob_sal_qc  real       salinity profile overall probability of gross
c                         error (integrates level-by-level errors taking
c                         into account layer thicknesses)
c   ob_sal_std real       climatolgical estimates of variability of
c                         salinity at profile location, levels and
c                         sampling time (one standard deviation)
c   ob_sal_typ integer    profile salinity data type (see ocean_types.h
c                         for codes)
c   ob_sal_xvl real       salinity profile from cross validation
c                         (GDEM 3.0 climate profile in absence of
c                         near-by data)
c   ob_sal_xsd real       salinity cross validation profile error
c                         (based on error reduction of GDEM 3.0 climate
c                         variability)
c   ob_scr     character  profile obs security classification code; "U"
c                         for unclassified
c   ob_sgn     character  profile observation call sign
c   ob_ssh     real       SSHA of profile dynamic height from long-term
c                         hydrographic mean.  dynamic height has been
c                         calculated relative to 2000 m or the bottom
c                         whichever is shallower.  the profile may have
c                         been vertically extended in the dynamic height
c                         computation, so the ob_ssh values must be used
c                         with care for profiles with shallow maximum
c                         observation depths.
c   ob_sst     real       SST estimate (in order of high resoloution
c                         regional analysis if available, global
c                         analysis if available, profile SST if
c                         observed shallow enough or SST climatology
c                         (MODAS or GDEM)) valid at profile observation
c                         location and sampling time
c   ob_tmp     real       observed profile temperatures
c   ob_tmp_err real       temperature observation errors (use with
c                         caution, reported values are experimental)
c   ob_tmp_prb real       temperature profile level-by-level probability
c                         of a gross error
c   ob_tmp_qc  real       temperature profile overall probability of
c                         gross error (integrates level-by-level errors
c                         taking into account layer thicknesses)
c   ob_tmp_tsd real       climatolgical estimates of variability of
c                         temperature at profile location, levels and
c                         sampling time (one standard deviation)
c   ob_tmp_typ integer    profile temperature data type (see
c                         ocean_types.h for codes)
c   ob_tmp_xvl real       temperature profile from cross validation
c                         (GDEM 3.0 climate profile in absence of
c                         near-by data)
c   ob_tmp_xsd real       temperature cross validation profile error
c                         (based on error reduction of GDEM 3.0 climate
c                         variability)
c
c..............................END PROLOGUE.............................
c
      implicit none
c
      include 'ocn_types.h'
c
c     ..local array dimensions
c
      integer   n_obs
      integer   n_lvl
c
      integer   i, j, n
      real      ob_btm (n_obs)
      real      ob_clm_sal (n_lvl, n_obs)
      real      ob_clm_ssd (n_lvl, n_obs)
      real      ob_clm_tmp (n_lvl, n_obs)
      real      ob_clm_tsd (n_lvl, n_obs)
      character ob_dtg (n_obs) * 12
      real      ob_glb_sal (n_lvl, n_obs)
      real      ob_glb_ssd (n_lvl, n_obs)
      real      ob_glb_tmp (n_lvl, n_obs)
      real      ob_glb_tsd (n_lvl, n_obs)
      character ob_id (n_obs) * 10
      real      ob_lat (n_obs)
      real      ob_lon (n_obs)
      real      ob_lvl (n_lvl, n_obs)
      integer   ob_ls (n_obs)
      integer   ob_lt (n_obs)
      real      ob_mds_sal (n_lvl, n_obs)
      real      ob_mds_tmp (n_lvl, n_obs)
      character ob_rcpt (n_obs) * 12
      real      ob_rgn_sal (n_lvl, n_obs)
      real      ob_rgn_ssd (n_lvl, n_obs)
      real      ob_rgn_tmp (n_lvl, n_obs)
      real      ob_rgn_tsd (n_lvl, n_obs)
      character ob_scr (n_obs) * 1
      character ob_sign (n_obs) * 7
      real      ob_sal (n_lvl, n_obs)
      real      ob_sal_err (n_lvl, n_obs)
      real      ob_sal_prb (n_lvl, n_obs)
      real      ob_sal_qc (n_obs)
      integer   ob_sal_typ (n_obs)
      real      ob_sal_xvl (n_lvl, n_obs)
      real      ob_sal_xsd (n_lvl, n_obs)
      real      ob_ssh (n_obs)
      real      ob_sst (n_obs)
      real      ob_tmp (n_lvl, n_obs)
      real      ob_tmp_err (n_lvl, n_obs)
      real      ob_tmp_prb (n_lvl, n_obs)
      real      ob_tmp_qc (n_obs)
      integer   ob_tmp_typ (n_obs)
      real      ob_tmp_xvl (n_lvl, n_obs)
      real      ob_tmp_xsd (n_lvl, n_obs)
      integer   UNIT
      integer   vrsn
c
c...............................executable..............................
c
c     ..initialize supplemental variables
c
      do i = 1, n_obs
         ob_id(i) = '          '
         do j = 1, n_lvl
            ob_sal_xvl(j,i) = -999.
            ob_sal_xsd(j,i) = -999.
            ob_tmp_xvl(j,i) = -999.
            ob_tmp_xsd(j,i) = -999.
         enddo
      enddo
c
c     ..read profile variables
c
      read (UNIT) (ob_btm(i),     i = 1, n_obs)
      read (UNIT) (ob_lat(i),     i = 1, n_obs)
      read (UNIT) (ob_lon(i),     i = 1, n_obs)
      read (UNIT) (ob_ls(i),      i = 1, n_obs)
      read (UNIT) (ob_lt(i),      i = 1, n_obs)
      read (UNIT) (ob_ssh(i),     i = 1, n_obs)
      read (UNIT) (ob_sst(i),     i = 1, n_obs)
      read (UNIT) (ob_sal_typ(i), i = 1, n_obs)
      read (UNIT) (ob_sal_qc(i),  i = 1, n_obs)
      read (UNIT) (ob_tmp_typ(i), i = 1, n_obs)
      read (UNIT) (ob_tmp_qc(i),  i = 1, n_obs)
      do i = 1, n_obs
         read (UNIT) (ob_lvl(j,i),     j = 1, ob_lt(i))
         read (UNIT) (ob_sal(j,i),     j = 1, ob_lt(i))
         read (UNIT) (ob_sal_err(j,i), j = 1, ob_lt(i))
         read (UNIT) (ob_sal_prb(j,i), j = 1, ob_lt(i))
         read (UNIT) (ob_tmp(j,i),     j = 1, ob_lt(i))
         read (UNIT) (ob_tmp_err(j,i), j = 1, ob_lt(i))
         read (UNIT) (ob_tmp_prb(j,i), j = 1, ob_lt(i))
      enddo
      read (UNIT) (ob_dtg(i),  i = 1, n_obs)
      read (UNIT) (ob_rcpt(i), i = 1, n_obs)
      read (UNIT) (ob_scr(i),  i = 1, n_obs)
      read (UNIT) (ob_sign(i), i = 1, n_obs)
      do i = 1, n_obs
         read (UNIT) (ob_clm_sal(j,i), j = 1, ob_lt(i))
         read (UNIT) (ob_clm_tmp(j,i), j = 1, ob_lt(i))
         read (UNIT) (ob_clm_ssd(j,i), j = 1, ob_lt(i))
         read (UNIT) (ob_clm_tsd(j,i), j = 1, ob_lt(i))
         read (UNIT) (ob_glb_sal(j,i), j = 1, ob_lt(i))
         read (UNIT) (ob_glb_tmp(j,i), j = 1, ob_lt(i))
         read (UNIT) (ob_glb_ssd(j,i), j = 1, ob_lt(i))
         read (UNIT) (ob_glb_tsd(j,i), j = 1, ob_lt(i))
         read (UNIT) (ob_mds_sal(j,i), j = 1, ob_lt(i))
         read (UNIT) (ob_mds_tmp(j,i), j = 1, ob_lt(i))
         read (UNIT) (ob_rgn_sal(j,i), j = 1, ob_lt(i))
         read (UNIT) (ob_rgn_tmp(j,i), j = 1, ob_lt(i))
         read (UNIT) (ob_rgn_ssd(j,i), j = 1, ob_lt(i))
         read (UNIT) (ob_rgn_tsd(j,i), j = 1, ob_lt(i))
      enddo
      if (vrsn .gt. 1) then
         do i = 1, n_obs
            read (UNIT) (ob_sal_xvl(j,i), j = 1, ob_lt(i))
            read (UNIT) (ob_sal_xsd(j,i), j = 1, ob_lt(i))
            read (UNIT) (ob_tmp_xvl(j,i), j = 1, ob_lt(i))
            read (UNIT) (ob_tmp_xsd(j,i), j = 1, ob_lt(i))
         enddo
         if (vrsn .gt. 2) then
            read (UNIT) (ob_id(i), i = 1, n_obs)
         endif
      endif
c
c     ..produce profile report
c
      n = 0
      do i = 1, n_obs
         n = n + 1
         write (45, '(110(''-''))')
         write (45, '(''profile number in file      : '', i12)') n
         write (45, '(''profile call sign           : "'', a, ''"'')')
     *          ob_sign(i)
         write (45, '(''profile latitude            : '', f12.2)')
     *          ob_lat(i)
         write (45, '(''profile longitude           : '', f12.2)')
     *          ob_lon(i)
         write (45, '(''profile observed DTG        : "'', a, ''"'')')
     *          ob_dtg(i)
         write (45, '(''profile received DTG        : "'', a, ''"'')')
     *          ob_rcpt(i)
         write (45, '(''DBDBV bottom depth          : '', f12.1)')
     *          ob_btm(i)
         write (45, '(''profile data type codes     : '', 2i6)')
     *          ob_tmp_typ(i), ob_sal_typ(i)
         write (45, '(''temp data type              : "'', a, ''"'')')
     *          data_lbl(ob_tmp_typ(i))
         write (45, '(''salt data type              : "'', a, ''"'')')
     *          data_lbl(ob_sal_typ(i))
         write (45, '(''observed temperature levels : '', i12)')
     *          ob_lt(i)
         write (45, '(''observed salinity levels    : '', i12)')
     *          ob_ls(i)
         write (45, '(''temperature gross error     : '', f12.4)')
     *          ob_tmp_qc(i)
         write (45, '(''salinity gross error        : '', f12.4)')
     *          ob_sal_qc(i)
         write (45, '(''sea surface height anomaly  : '', f12.4)')
     *          ob_ssh(i)
         write (45, '(''sea surface temperature     : '', f12.2)')
     *          ob_sst(i)
         write (45, '(''security classification     : '', 9x,
     *          ''"'', a, ''"'')') ob_scr(i)
         write (45, '(5x,''depth'',   6x,''temp'',
     *                3x,''clm_std'', 3x,''tmp_err'',
     *                3x,''tmp_prb'', 3x,''clm_tmp'',
     *                3x,''mds_tmp'', 3x,''glb_tmp'',
     *                3x,''rgn_tmp'', 3x,''glb_std'',
     *                3x,''rgn_std'', 3x,''tmp_xvl'',
     *                3x,''tmp_xsd'')')
         do j = 1, ob_lt(i)
            write (45, '(f10.1, 3f10.2, f10.3, 8f10.2)')
     *             ob_lvl(j,i), ob_tmp(j,i), ob_clm_tsd(j,i),
     *             ob_tmp_err(j,i), ob_tmp_prb(j,i),
     *             ob_clm_tmp(j,i), ob_mds_tmp(j,i),
     *             ob_glb_tmp(j,i), ob_rgn_tmp(j,i),
     *             ob_glb_tsd(j,i), ob_rgn_tsd(j,i),
     *             ob_tmp_xvl(j,i), ob_tmp_xsd(j,i)
         enddo
         if (ob_ls(i) .gt. 0) then
            write (45, '(5x,''depth'', 6x,''salt'',
     *                   3x,''clm_std'', 3x,''sal_err'',
     *                   3x,''sal_prb'', 3x,''clm_sal'',
     *                   3x,''mds_sal'', 3x,''glb_sal'',
     *                   3x,''rgn_sal'', 3x,''glb_std'',
     *                   3x,''rgn_std'', 3x,''sal_xvl'',
     *                   3x,''sal_xsd'')')
            do j = 1, ob_lt(i)
               write (45, '(f10.1, 3f10.2, f10.3, 8f10.2)')
     *                ob_lvl(j,i), ob_sal(j,i), ob_clm_ssd(j,i),
     *                ob_sal_err(j,i), ob_sal_prb(j,i),
     *                ob_clm_sal(j,i), ob_mds_sal(j,i),
     *                ob_glb_sal(j,i), ob_rgn_sal(j,i),
     *                ob_glb_ssd(j,i), ob_rgn_ssd(j,i),
     *                ob_sal_xvl(j,i), ob_sal_xsd(j,i)
            enddo
         endif
      enddo
c
      return
      end
      subroutine rd_ship (UNIT, n_obs, vrsn,
     * ob_dtg, ob_lat, ob_lon,
     * ob_sst)
c
c.............................START PROLOGUE............................
c
c MODULE NAME:  rd_ship
c
c DESCRIPTION:  reads the SHIP ocean obs files and produces a report
c
c PARAMETERS:
c      Name          Type        Usage            Description
c   ----------     ---------     ------    ---------------------------
c   n_obs           integer      input     number ship obs
c   unit            integer      input     FORTRAN unit number
c   vrsn            integer      input     version number data file
c
c MCSST VARIABLES:
c      Name      Type                     Description
c   ----------  -------     -------------------------------------------
c   ob_age      real        age of the observation in hours since
c                           January 1, 1992.  provides a continuous
c                           time variable.  reported to the nearest
c                           minute.
c   ob_clm      real        GDEM SST climatological estimate at obs
c                           location and sampling time
c   ob_csgm     real        GDEM SST climatology variability estimate
c                           at obs location and samling time
c   ob_dtg      character   SST obs date time group in the form year,
c                           month, day, hour, minute (YYYYMMDDHHMM)
c   ob_glb      real        SST global analysis estimate at obs
c                           location and samplingr time
c   ob_gsgm     real        global SST analysis variability estimate
c                           at obs location and sampling time
c   ob_lat      real        SST obs latitude (south negative)
c   ob_lon      real        SST obs longitude (west negative)
c   ob_qc       real        SST obs probability of a gross error
c                           (assumes normal pdf of SST errors)
c   ob_rcpt     character   SST observation receipt time at FNMOC in
c                           the form year, month, day, hour, minute
c                           (YYYYMMDDHHMM); the difference between
c                           ob_rcpt and ob_dtg gives the timeliness
c                           of the observation and the validity of
c                           ob_glb and ob_rgn background estimates
c   ob_rgn                  SST regional analysis estimate at obs
c                           location and sampling time
c   ob_rsgm     real        regional SST analysis variability estimate
c                           at obs location and sampling time
c   ob_scr      character   SST obs security classification code; "U"
c                           for unclassified
c   ob_sign     character   SST observation call sign
c   ob_sst      real        SST observation
c   ob_typ      integer     SST obseration data type; ship (ERI, bucket,
c                           hull contact), buoy (fixed, drifting), CMAN
c                           (see ocn_types.h for codes)
c   ob_wm       integer     SST water mass indicator from Bayesian
c                           classification scheme.
c
c..............................END PROLOGUE.............................
c
      implicit none
c
      include 'ocn_types.h'
c
c     ..local array dimension
c
      integer   n_obs
c
      integer   i
      real      ob_age (n_obs)
      real      ob_clm (n_obs)
      real      ob_csgm (n_obs)
      character ob_dtg (n_obs) * 12
      real      ob_glb (n_obs)
      real      ob_gsgm (n_obs)
      real      ob_lat (n_obs)
      real      ob_lon (n_obs)
      real      ob_qc (n_obs)
      character ob_rcpt (n_obs) * 12
      real      ob_rgn (n_obs)
      real      ob_rsgm (n_obs)
      character ob_scr (n_obs) * 1
      character ob_sign (n_obs) * 7
      real      ob_sst (n_obs)
      integer   ob_typ (n_obs)
      integer   ob_wm (n_obs)
      integer   UNIT
      integer   vrsn
c
c...............................executable..............................
c
c     ..read ship variables
c
      read (UNIT) (ob_wm(i),   i = 1, n_obs)
      read (UNIT) (ob_glb(i),  i = 1, n_obs)
      read (UNIT) (ob_lat(i),  i = 1, n_obs)
      read (UNIT) (ob_lon(i),  i = 1, n_obs)
      read (UNIT) (ob_age(i),  i = 1, n_obs)
      read (UNIT) (ob_clm(i),  i = 1, n_obs)
      read (UNIT) (ob_qc(i),   i = 1, n_obs)
      read (UNIT) (ob_rgn(i),  i = 1, n_obs)
      read (UNIT) (ob_sst(i),  i = 1, n_obs)
      read (UNIT) (ob_typ(i),  i = 1, n_obs)
      read (UNIT) (ob_dtg(i),  i = 1, n_obs)
      read (UNIT) (ob_rcpt(i), i = 1, n_obs)
      read (UNIT) (ob_scr(i),  i = 1, n_obs)
      if (vrsn .le. 2) then
         ob_sign(:) = " "
         read (UNIT) (ob_sign(i)(1:6), i = 1, n_obs)
      else
         read (UNIT) (ob_sign(i), i = 1, n_obs)
      endif
      if (vrsn .gt. 1) then
         read (UNIT) (ob_csgm(i), i = 1, n_obs)
         read (UNIT) (ob_gsgm(i), i = 1, n_obs)
         read (UNIT) (ob_rsgm(i), i = 1, n_obs)
      else
         do i = 1, n_obs
            ob_csgm(i) = -999.
            ob_gsgm(i) = -999.
            ob_rsgm(i) = -999.
         enddo
      endif
c
c     ..produce ship report
c
      write (45, '(9x,''dtg'', 4x,''sign '', 5x,''lat'', 5x,''lon'',
     *             1x,''typ'', 5x,''sst'', 4x,''clim'', 4x,''glbl'',
     *             4x,''regn'', 6x,''qc'', 4x,''csgm'', 4x,''gsgm'',
     *             4x,''rsgm'', 2x,''wm'', 2x,''sc'')')
      do i = 1, n_obs
         write (45, '(a,2x,a,2f8.2,i4,4f8.2,f8.3,3f8.2,i4,3x,a,2x,a)')
     *          ob_dtg(i), ob_sign(i), ob_lat(i), ob_lon(i),
     *          ob_typ(i), ob_sst(i), ob_clm(i), ob_glb(i),
     *          ob_rgn(i), ob_qc(i), ob_csgm(i), ob_gsgm(i),
     *          ob_rsgm(i), ob_wm(i), ob_scr(i), data_lbl(ob_typ(i))
      enddo
c
      return
      end
      subroutine rd_ssmi (UNIT, n_obs, vrsn)
c
c.............................START PROLOGUE............................
c
c MODULE NAME:  rd_ssmi
c
c DESCRIPTION:  reads the SSMI sea ice ocean obs files and produces a
c               report whether you want one or not
c
c NOTES:        the qc probablity of error includes flags indicating
c               a postive sea ice retrieval in too warm water.  a
c               value of 410 is added to the underlying probability
c               as a warm sst flag if the sst exceeds 1 deg C.
c
c PARAMETERS:
c      Name          Type        Usage            Description
c   ----------     ---------     ------    ---------------------------
c   n_obs           integer      input     number ssmi obs
c   unit            integer      input     FORTRAN unit number
c   vrsn            integer      input     version number data file
c
c SSMI VARIABLES:
c     ame       Type                     Description
c   --------  --------    ----------------------------------------------
c   ob_age     real       age of the observation in hours since
c                         January 1, 1992.  provides a continuous
c                         time variable.  reported to the nearest
c                         minute.
c   ob_clm     real       ECMWF sea ice climatological estimate at
c                         SSM/I sea ice location and sampling time
c   ob_dtg     character  SSM/I sea ice retrieval date time group in
c                         the form  year, month, day, hour, minute,
c                         second (YYYYMMDDHHMMSS)
c   ob_glb     real       SSM/I sea ice global analysis estimate at
c                         obs location and sampling time
c   ob_ice     real       SSM/I sea ice concentration (per cent)
c   ob_lat     real       SSM/I sea ice latitude (south negative)
c   ob_lon     real       SSM/I sea ice longitude (west negative)
c   ob_qc      real       SSM/I sea ice probability of a gross error
c                         (assumes normal pdf of sea ice retrieval
c                         errors)
c   ob_rgn     real       SSM/I sea ice regional analysis estimate at
c                         obs location and sampling time
c   ob_sat     integer    satellite ID (DMSP F11, F13, F14, F15);
c                         see ocn_types.h for codes
c
c..............................END PROLOGUE.............................
c
      implicit none
c
      include 'ocn_types.h'
c
c     ..local array dimensions
c
      integer   n_obs
c
      integer   i, k
      real      ob_age (n_obs)
      real      ob_clm (n_obs)
      real      ob_dmy (n_obs)
      character ob_dtg (n_obs) * 12
      real      ob_glb (n_obs)
      real      ob_ice (n_obs)
      real      ob_lat (n_obs)
      real      ob_lon (n_obs)
      real      ob_qc (n_obs)
      real      ob_rgn (n_obs)
      integer   ob_sat (n_obs)
      integer   UNIT
      integer   vrsn
c
c...............................executable..............................
c
c     ..read ssmi variables
c
      read (UNIT) (ob_glb(i), i = 1, n_obs)
      read (UNIT) (ob_ice(i), i = 1, n_obs)
      read (UNIT) (ob_lat(i), i = 1, n_obs)
      read (UNIT) (ob_lon(i), i = 1, n_obs)
      read (UNIT) (ob_qc(i),  i = 1, n_obs)
      read (UNIT) (ob_age(i), i = 1, n_obs)
      read (UNIT) (ob_rgn(i), i = 1, n_obs)
      read (UNIT) (ob_sat(i), i = 1, n_obs)
      read (UNIT) (ob_clm(i), i = 1, n_obs)
      read (UNIT) (ob_dmy(i), i = 1, n_obs)
      read (UNIT) (ob_dtg(i), i = 1, n_obs)
c
c     ..produce ssmi report
c
      k = 100
      write (45, '(''  reporting skip factor: '', i10)') k
      write (45, '(9x,''dtg'', 5x,''lat'', 5x,''lon'', 5x,''sat'',
     *             5x,''ice'', 4x,''clim'', 4x,''glbl'', 4x,''regn'',
     *             6x,''qc'')')
      do i = 1, n_obs, k
         write (45, '(a,2f8.2,i8,4f8.2,f8.3,2x,f12.1,a)')
     *          ob_dtg(i), ob_lat(i), ob_lon(i), ob_sat(i),
     *          ob_ice(i), ob_clm(i), ob_glb(i), ob_rgn(i),
     *          ob_qc(i), ob_age(i), data_lbl(ob_sat(i))
      enddo
c
      return
      end
      subroutine rd_swh (UNIT, n_obs, vrsn)
c
c.............................START PROLOGUE............................
c
c MODULE NAME:  rd_swh
c
c DESCRIPTION:  reads the altimeter SWH ocean obs files and produces a
c               report whether you want one or not
c
c NOTES:        the qc probablity of error includes flags indicating
c               swh retrieval in ice covered seas and/or shallow
c               water.  a value of 510 is added to the underlying
c               probability to indicate if the ice concentration
c               exceeds 33% and a value of 512 is added if the
c               bottom depth is less than 5 meters.  note that a
c               composite flag of 510 + 512 can also occur.
c
c PARAMETERS:
c      Name          Type        Usage            Description
c   ----------     ---------     ------    ---------------------------
c   n_obs           integer      input     number swh obs
c   unit            integer      input     FORTRAN unit number
c   vrsn            integer      input     version number data file
c
c SWH VARIABLES:
c     ame       Type                     Description
c   --------  --------    ----------------------------------------------
c   ob_age     real       age of the observation in hours since
c                         January 1, 1992.  provides a continuous
c                         time variable.  reported to the nearest
c                         minute.
c   ob_clm     real       SWH climate (not available)
c   ob_dtg     character  SWH retrieval date time group in the form
c                         year, month, day, hour, minute, second
c                         (YYYYMMDDHHMMSS)
c   ob_glb     real       SWH global FNMOC analysis estimate at the
c                         obs location and sampling time
c   ob_lat     real       SWH retrieval latitude (south negative)
c   ob_lon     real       SWH retrieval longitude (west negative)
c   ob_qc      real       SWH retrieval probability of a gross error
c                         (assumes normal pdf of SWH retrieval errors)
c   ob_rcpt    character  SWH retrieval FNMOC receipt date time group
c                         in the form year, month, day, hour, minute,
c                         second (YYYYMMDDHHMMSS)
c   ob_rgn     real       SWH regional FNMOC analysis estimate at the
c                         obs location and sampling time
c   ob_swh     real       SWH retrieval (m)
c   ob_typ     integer    satellite ID (ERS2, Topex, Jason, GFO,
c                         ENVISAT, Topex Interleaved); see ocn_types.h
c                         for codes
c   ob_xvl     real       cross validation SWH value from QC
c   ob_wnd     real       altimeter colocated wind retrieval (m/s)
c
c..............................END PROLOGUE.............................
c
      implicit none
c
      include 'ocn_types.h'
c
c     ..local array dimension
c
      integer   n_obs
c
      integer   i, k
      real      ob_age (n_obs)
      real      ob_clm (n_obs)
      character ob_dtg (n_obs) * 14
      real      ob_glb (n_obs)
      real      ob_lat (n_obs)
      real      ob_lon (n_obs)
      real      ob_qc (n_obs)
      character ob_rcp (n_obs) * 14
      real      ob_rgn (n_obs)
      real      ob_swh (n_obs)
      integer   ob_typ (n_obs)
      real      ob_xvl (n_obs)
      real      ob_wnd (n_obs)
      integer   UNIT
      integer   vrsn
c
c...............................executable..............................
c
c     ..read swh variables
c
      read (UNIT) (ob_glb(i), i = 1, n_obs)
      read (UNIT) (ob_lat(i), i = 1, n_obs)
      read (UNIT) (ob_lon(i), i = 1, n_obs)
      read (UNIT) (ob_age(i), i = 1, n_obs)
      read (UNIT) (ob_clm(i), i = 1, n_obs)
      read (UNIT) (ob_qc(i),  i = 1, n_obs)
      read (UNIT) (ob_typ(i), i = 1, n_obs)
      read (UNIT) (ob_rgn(i), i = 1, n_obs)
      read (UNIT) (ob_swh(i), i = 1, n_obs)
      read (UNIT) (ob_wnd(i), i = 1, n_obs)
      read (UNIT) (ob_xvl(i), i = 1, n_obs)
      read (UNIT) (ob_dtg(i), i = 1, n_obs)
      read (UNIT) (ob_rcp(i), i = 1, n_obs)
c
c     ..produce swh report
c
      k = 1
      write (45, '(''  reporting skip factor: '', i10)') k
      write (45, '(11x,''dtg'', 11x,''rcpt'', 5x,''lat'', 5x,''lon'',
     *             4x,''type'', 5x,''swh'', 4x,''wind'', 4x,''clim'',
     *             4x,''glbl'', 4x,''regn'', 4x,''xval'', 8x,''qc'')')
      do i = 1, n_obs, k
         write (45, '(a,1x,a,2f8.2,i8,6f8.1,2x,f8.3,2x,a)')
     *          ob_dtg(i), ob_rcp(i), ob_lat(i), ob_lon(i),
     *          ob_typ(i), ob_swh(i), ob_wnd(i), ob_clm(i),
     *          ob_glb(i), ob_rgn(i), ob_xvl(i), ob_qc(i),
     *          data_lbl(ob_typ(i))
      enddo
c
      return
      end
      subroutine rd_trak (UNIT, n_obs, vrsn,
     * ob_dtg, ob_lat, ob_lon,
     * ob_sst, ob_sal, ob_uuu, ob_vvv)
c
c.............................START PROLOGUE............................
c
c MODULE NAME:  rd_trak
c
c DESCRIPTION:  reads the TRAK ocean obs files and produces a
c               report whether you want one or not
c
c PARAMETERS:
c      Name          Type        Usage            Description
c   ----------     ---------     ------    ---------------------------
c   n_obs           integer      input     number swh obs
c   unit            integer      input     FORTRAN unit number
c   vrsn            integer      input     version number data file
c
c SWH VARIABLES:
c     ame       Type                     Description
c   --------  --------    ----------------------------------------------
c   ob_age     real       age of the observation in hours since
c                         January 1, 1992.  provides a continuous
c                         time variable.  reported to the nearest
c                         minute.
c   ob_csgm    real       SST climate variability
c   ob_csal    real       SSS climate estimate at the obs location
c                         and sampling time
c   ob_csst    real       SST climate estimate at the obs location
c                         and sampling time
c   ob_dtg     character  TRAKOBS retrieval date time group in the form
c                         year, month, day, hour, minute, second
c                         (YYYYMMDDHHMMSS)
c   ob_gsal    real       SSS global analysis estimate at the obs
c                         location and sampling time
c   ob_gsgm    real       SST global analysis variability
c   ob_gsst    real       SST global analysis estimate at the obs
c                         location and sampling time
c   ob_lat     real       TRAKOBS latitude (south negative)
c   ob_lon     real       TRAKOBS longitude (west negative)
c   ob_qc_sal  real       TRAKOBS salinity probability of gross error
c                         (assumes normal pdf of salinity errors)
c   ob_qc_sst  real       TRAKOBS temperature probability of gross error
c                         (assumes normal pdf of temperature errors)
c   ob_qc_vel  real       TRAKOBS velocity probability of gross error
c                         (assumes normal pdf of velocity errors)
c   ob_rcpt    character  SWH retrieval FNMOC receipt date time group
c                         in the form year, month, day, hour, minute,
c                         second (YYYYMMDDHHMMSS)
c   ob_rgn     real       SWH regional analysis estimate at the obs
c                         location and sampling time
c   ob_rsal    real       SSS regional analysis estimate at the obs
c                         location and sampling time
c   ob_rsgm    real       SST regional analysis variability
c   ob_rsst    real       SST regional analysis estimate at the obs
c                         location and sampling time
c   ob_sal     real       TRAKOBS SSS observation
c   ob_scr     character  TRAKOBS security classification code
c   ob_sgn     character  TRAKOBS call sign
c   ob_sst     real       TRAKOBS SST observation
c   ob_typ     integer    type code indicator; see ocn_types.h for codes
c   ob_uuu     real       TRAKOBS u velocity observation
c   ob_vvv     real       TRAKOBS v velocity observation
c   ob_wm      integer    SST water mass indicator from Bayesian
c                         classification scheme.
c
c..............................END PROLOGUE.............................
c
      implicit none
c
      include 'ocn_types.h'
c
c     ..local array dimension
c
      integer   n_obs
c
      integer   i
      real      ob_age (n_obs)
      real      ob_csal (n_obs)
      real      ob_csst (n_obs)
      real      ob_csgm (n_obs)
      character ob_dtg (n_obs) * 12
      real      ob_gsal (n_obs)
      real      ob_gsst (n_obs)
      real      ob_gsgm (n_obs)
      real      ob_lat (n_obs)
      real      ob_lon (n_obs)
      real      ob_qc_sal (n_obs)
      real      ob_qc_sst (n_obs)
      real      ob_qc_vel (n_obs)
      character ob_rcpt (n_obs) * 12
      real      ob_rsal (n_obs)
      real      ob_rsst (n_obs)
      real      ob_rsgm (n_obs)
      real      ob_sal (n_obs)
      character ob_scr (n_obs) * 1
      character ob_sgn (n_obs) * 6
      real      ob_sst (n_obs)
      integer   ob_typ (n_obs)
      real      ob_uuu (n_obs)
      real      ob_vvv (n_obs)
      integer   ob_wm (n_obs)
      integer   UNIT
      integer   vrsn
c
c...............................executable..............................
c
c     ..read trak obs variables
c
      read (UNIT) (ob_wm(i),     i = 1, n_obs)
      read (UNIT) (ob_gsal(i),   i = 1, n_obs)
      read (UNIT) (ob_gsst(i),   i = 1, n_obs)
      read (UNIT) (ob_lat(i),    i = 1, n_obs)
      read (UNIT) (ob_lon(i),    i = 1, n_obs)
      read (UNIT) (ob_age(i),    i = 1, n_obs)
      read (UNIT) (ob_csal(i),   i = 1, n_obs)
      read (UNIT) (ob_csst(i),   i = 1, n_obs)
      read (UNIT) (ob_qc_sal(i), i = 1, n_obs)
      read (UNIT) (ob_qc_sst(i), i = 1, n_obs)
      read (UNIT) (ob_qc_vel(i), i = 1, n_obs)
      read (UNIT) (ob_rsal(i),   i = 1, n_obs)
      read (UNIT) (ob_rsst(i),   i = 1, n_obs)
      read (UNIT) (ob_sal(i),    i = 1, n_obs)
      read (UNIT) (ob_sst(i),    i = 1, n_obs)
      read (UNIT) (ob_typ(i),    i = 1, n_obs)
      read (UNIT) (ob_uuu(i),    i = 1, n_obs)
      read (UNIT) (ob_vvv(i),    i = 1, n_obs)
      read (UNIT) (ob_dtg(i),    i = 1, n_obs)
      read (UNIT) (ob_rcpt(i),   i = 1, n_obs)
      read (UNIT) (ob_scr(i),    i = 1, n_obs)
      read (UNIT) (ob_sgn(i),    i = 1, n_obs)
      read (UNIT) (ob_csgm(i),   i = 1, n_obs)
      read (UNIT) (ob_gsgm(i),   i = 1, n_obs)
      read (UNIT) (ob_rsgm(i),   i = 1, n_obs)
c
c     ..produce trak obs report
c
      write (45, '(/, ''Sea Surface Temperature'')')
      write (45, '(9x,''dtg'', 3x,''sign '', 5x,''lat'', 5x,''lon'',
     *             1x,''typ'', 5x,''sst'', 4x,''clim'', 4x,''glbl'',
     *             4x,''regn'', 6x,''qc'', 4x,''csgm'', 4x,''gsgm'',
     *             4x,''rsgm'', 2x,''wm'', 2x,''sc'')')
      do i = 1, n_obs
         write (45, '(a,2x,a,2f8.2,i4,4f8.2,f8.3,3f8.2,i4,3x,a,2x,a)')
     *          ob_dtg(i), ob_sgn(i), ob_lat(i), ob_lon(i),
     *          ob_typ(i), ob_sst(i), ob_csst(i), ob_gsst(i),
     *          ob_rsst(i), ob_qc_sst(i), ob_csgm(i), ob_gsgm(i),
     *          ob_rsgm(i), ob_wm(i), ob_scr(i), data_lbl(ob_typ(i))
      enddo
c
      write (45, '(/, ''Sea Surface Salinity'')')
      write (45, '(9x,''dtg'', 3x,''sign '', 5x,''lat'', 5x,''lon'',
     *             1x,''typ'', 5x,''sal'', 4x,''clim'', 4x,''glbl'',
     *             4x,''regn'', 6x,''qc'')')
      do i = 1, n_obs
         ob_typ(i) = 35
         write (45, '(a,2x,a,2f8.2,i4,4f8.2,f8.3,34x,a)')
     *          ob_dtg(i), ob_sgn(i), ob_lat(i), ob_lon(i),
     *          ob_typ(i), ob_sal(i), ob_csal(i), ob_gsal(i),
     *          ob_rsal(i), ob_qc_sal(i), data_lbl(ob_typ(i))
      enddo
c
      write (45, '(/, ''Sea Surface U, V Velocity'')')
      write (45, '(9x,''dtg'', 3x,''sign '', 5x,''lat'', 5x,''lon'',
     *             1x,''typ'', 5x,''uuu'', 5x,''vvv'', 22x,''qc'')')
      do i = 1, n_obs
         write (45, '(a,2x,a,2f8.2,i4,2f8.2,16x,f8.3)')
     *          ob_dtg(i), ob_sgn(i), ob_lat(i), ob_lon(i),
     *          ob_typ(i), ob_uuu(i), ob_vvv(i), ob_qc_vel(i)
      enddo
c
      return
      end
      subroutine error_exit (routine, message)
c
c.............................START PROLOGUE............................
c
c MODULE NAME:  error_exit
c
c DESCRIPTION:  prints a fatal error message and terminates the program.
c
c PARAMETERS:
c    Name          Type       Usage            Description
c   -------     ----------    ------    ---------------------------
c   routine     char * (*)    input     name of routine
c   message     char * (*)    input     user supplied error message
c
c..............................END PROLOGUE.............................
c
      implicit  none
c
      integer   ln
      character message * (*)
      character routine * (*)
c
c..............................executable...............................
c
c     ..determine message string length
c
      ln = len_trim (message)
c
      write (*, '(//, ''*** FATAL ERROR ('', a, '') ***'')') routine
      write (*, '(/, a)') message(1:ln)
      write (*, '(/, ''*** PROGRAM TERMINATED ***'', /)')
c
      stop
      end
