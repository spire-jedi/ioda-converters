!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!! viirs2ioda_vars
!! - module for variable definition to be used by multiple modules
!!   for viirs2ioda
!!
!! author: Cory Martin - cory.r.martin@noaa.gov
!! history: 2019-02-22 - original
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
module viirs2ioda_vars
  implicit none
  ! global variables provided at the command line
  character(len=255) :: gridpath,infile,outfile
  logical :: thinning
  ! dataset attributes
  character(len=50) :: sensor="v.viirs-m_npp" ! read this in later, for testing now
  ! input data arrays
  real, allocatable, dimension(:,:) :: in_lats, in_lons
  real, allocatable, dimension(:,:) :: in_AOD550
end module viirs2ioda_vars
