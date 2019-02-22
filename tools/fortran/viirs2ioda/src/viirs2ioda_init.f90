!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!! viirs2ioda_init
!! - contains initialization subroutines
!!     init      - reads in options from command line
!!
!! author: Cory Martin - cory.r.martin@noaa.gov
!! history: 2019-02-22 - original
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
module viirs2ioda_init
  implicit none
contains
  subroutine init
    use viirs2ioda_vars, only: thinning, gridpath, infile, outfile
    implicit none
    !! initialize the software
    !! - mainly reads in options from command line
    integer :: nargs,iarg
    character(len=100) :: arg1
    logical :: existin
    nargs = command_argument_count()
    !! exit if not enough args
    if (nargs == 1) then
      call get_command_argument(1,arg1)
      if (trim(arg1)=='--help' .or. trim(arg1)=='-h') then
        write(*,*) "viirs2ioda [--help] [--thin=] [--gridpath=] /path/to/infile /path/to/outfile"
        write(*,*) " info:"
        write(*,*) "  --help       this message"
        write(*,*) "  --thin       obs thinning method, default none"
        write(*,*) "  --gridpath   path to grid file to thin to"
        write(*,*) "  required arguments:"
        write(*,*) "  /path/to/infile.nc    path to input VIIRS data"
        write(*,*) "  /path/to/outfile.nc   path to output IODA file"
      end if
      write(*,*) "Not enough arguments... see --help for details"
      stop
    end if
    !! default settings for optional args
    thinning=.false.
    gridpath="/path/to/nowhere/fornow.nc"
    !! get args from command line and replace optional ones if defined
    if (nargs >= 2) then
      do iarg=1,nargs-1 
        call get_command_argument(iarg,arg1)
        if (arg1(1:6)=='--thin') then ! figure out thinning method
          print *, "placeholder for thinning!"
        else if (arg1(1:10)=='--gridpath') then ! change gridpath
          print *, "placeholder for gridpath!"
        end if
      end do
      call get_command_argument(nargs-1,infile)
      call get_command_argument(nargs,outfile)
    else
      stop
    end if
    !! finally, let's ensure that infile exists
    inquire(file=infile,exist=existin)
    if (.not. existin) then
      write(*,*) "Input netCDF file does not exist. Abort!"
      stop
    end if
    
  end subroutine init

end module viirs2ioda_init 
