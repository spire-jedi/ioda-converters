program read_ocn_obs_jedi

implicit none

integer   UNIT
parameter (UNIT = 60)

character arg * 256
character err_msg * 256
logical   exist
character file_name * 256
integer   n_arg
integer   n_obs
integer   n_lvl
integer   n_vrsn
character obs_typ * 9

integer   IARGC

n_arg = IARGC ()
if (n_arg .eq. 0) then
   write (*, '(/, ''OCN_OBS command line arguments:'')')
   write (*, '(/, 5x, ''ocn_obs {type} {filename} '')')
   write (*, '(/, 5x, ''{type} = obs data type'')')
   write (*, '(5x, '' {filename} = file name to read'')')
   write (*, '(/, ''  NOTES: 1. {type} can be '', &
                  ''altim, amsr, atsr, glider, goes,'')')
   write (*, '(''                          '', &
               ''lac, mcsst, metop, metop_lac, msg,'')')
   write (*, '(''                          '', &
               ''prof, ship, ssmi, swh or trak'')')
   write (*, '(''         2. {filename} is in the form '', &
               ''./YYYYMMDDHH.type'')')
   stop
endif

!     ..retrieve obs data type argument
obs_typ = '         '
call GETARG (1, arg)
obs_typ = trim(arg)

!     ..retrieve file name
if (n_arg .gt. 1) then
   call GETARG (2, arg)
   file_name = trim(arg)
else
   write (err_msg, '(''no file name specified'')')
   call error_exit ('OCN_OBS', err_msg)
endif

!-----------------------------------------------------------------------

inquire (file=trim(adjustl(file_name)), exist=exist)
if (.not. exist) then
  write (err_msg, '(''file "'', a, ''" does not exist'')') &
         trim(adjustl(file_name))
  call error_exit ('OCN_OBS', err_msg)
endif

open (UNIT, file=trim(adjustl(file_name)), status='old', &
      form='unformatted')
call read_metadata(UNIT, n_obs, n_lvl, n_vrsn)
write (6, '(''          number of obs: '', i10)') n_obs
write (6, '(''      max number levels: '', i10)') n_lvl
write (6, '(''    file version number: '', i10)') n_vrsn

if (trim(obs_typ) .eq. 'prof') then
  call read_prof(UNIT, n_obs, n_lvl, n_vrsn)
else if (trim(obs_typ) .eq. 'trak') then
  call read_trak(UNIT, n_obs, n_lvl, n_vrsn)
else if (trim(obs_typ) .eq. 'ship') then
  call read_ship(UNIT, n_obs, n_lvl, n_vrsn)
endif

close(UNIT)

stop

contains

subroutine read_prof(UNIT, n_obs, n_lvl, n_vrsn)

integer   UNIT
integer   n_obs
integer   n_lvl
integer   n_vrsn
integer   nn
character(len=12), allocatable, dimension(:) :: ob_dtg
real, allocatable, dimension(:) :: ob_lat, ob_lon
real, allocatable, dimension(:,:) :: ob_lvl
real, allocatable, dimension(:,:) :: ob_tmp, ob_sal
real, allocatable, dimension(:,:) :: ob_tmp_err, ob_sal_err
real, allocatable, dimension(:) :: ob_tmp_qc, ob_sal_qc

allocate(ob_dtg(n_obs))
allocate(ob_lat(n_obs))
allocate(ob_lon(n_obs))
allocate(ob_lvl(n_lvl, n_obs))
allocate(ob_tmp(n_lvl, n_obs))
allocate(ob_sal(n_lvl, n_obs))
allocate(ob_tmp_err(n_lvl, n_obs))
allocate(ob_sal_err(n_lvl, n_obs))
allocate(ob_tmp_qc(n_obs))
allocate(ob_sal_qc(n_obs))

call rd_prof(UNIT, n_obs, n_lvl, n_vrsn, &
ob_dtg, ob_lat, ob_lon, ob_lvl, &
ob_tmp, ob_tmp_err, ob_tmp_qc, &
ob_sal, ob_sal_err, ob_sal_qc)

do nn = 1, n_obs
  print*, ob_dtg(nn), ob_lat(nn), ob_lon(nn)
enddo

end subroutine read_prof

subroutine read_trak(UNIT, n_obs, n_lvl, n_vrsn)

integer   UNIT
integer   n_obs
integer   n_lvl
integer   n_vrsn
integer   nn
character(len=12), allocatable, dimension(:) :: ob_dtg
real, allocatable, dimension(:) :: ob_lat, ob_lon
real, allocatable, dimension(:) :: ob_sst, ob_sal, ob_uuu, ob_vvv

allocate(ob_dtg(n_obs))
allocate(ob_lat(n_obs))
allocate(ob_lon(n_obs))
allocate(ob_sst(n_obs))
allocate(ob_sal(n_obs))
allocate(ob_uuu(n_obs))
allocate(ob_vvv(n_obs))

call rd_trak(UNIT, n_obs, n_vrsn, &
ob_dtg, ob_lat, ob_lon, &
ob_sst, ob_sal, ob_uuu, ob_vvv)

do nn = 1, n_obs
  print*, ob_dtg(nn), ob_lat(nn), ob_lon(nn)
enddo

end subroutine read_trak

subroutine read_ship(UNIT, n_obs, n_lvl, n_vrsn)

integer   UNIT
integer   n_obs
integer   n_lvl
integer   n_vrsn
integer   nn
character(len=12), allocatable, dimension(:) :: ob_dtg
real, allocatable, dimension(:) :: ob_lat, ob_lon
real, allocatable, dimension(:) :: ob_sst, ob_sal, ob_uuu, ob_vvv

allocate(ob_dtg(n_obs))
allocate(ob_lat(n_obs))
allocate(ob_lon(n_obs))
allocate(ob_sst(n_obs))

call rd_ship(UNIT, n_obs, n_vrsn, &
ob_dtg, ob_lat, ob_lon, &
ob_sst)

do nn = 1, n_obs
  print*, ob_dtg(nn), ob_lat(nn), ob_lon(nn)
enddo

end subroutine read_ship

end program read_ocn_obs_jedi
