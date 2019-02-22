!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!! viirs2ioda
!!  - utility to convert VIIRS AOD netCDF files provided by NOAA
!!    and output them to a format readable by IODA
!!
!! author: Cory Martin - cory.r.martin@noaa.gov
!! history: 2019-02-22 - original
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
program viirs2ioda
  use viirs2ioda_init, only: init
  !! top level driver program, calls all subroutines from other modules
  implicit none
  call init ! read in command line arguments

end program viirs2ioda
