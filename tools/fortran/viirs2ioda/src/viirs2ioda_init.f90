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
    use viirs2ioda_vars, only: thinning, gridpath, infile, outfile,&
                               fv3_gridfiles,ntiles_fv3,validtimestr,&
                               validtime
    use datetime_mod
                
    implicit none
    !! initialize the software
    !! - mainly reads in options from command line
    integer :: nargs,iarg,itile
    character(len=200) :: arg1
    character(len=1) :: tile
    logical :: existin
    integer :: yyyy,mm,dd,hh
   
    nargs = command_argument_count()
    !! exit if not enough args
    if (nargs <= 1) then
      call get_command_argument(1,arg1)
      if (trim(arg1)=='--help' .or. trim(arg1)=='-h') then
        write(*,*) "viirs2ioda [--help] [--thin=] [--validtime=] [--gridpath=] /path/to/infile /path/to/outfile"
        write(*,*) " info:"
        write(*,*) "  --help       this message"
        write(*,*) "  --thin       obs thinning method, default none"
        write(*,*) "  --gridpath   path to grid file to thin to"
        write(*,*) "  --validtime  string of analysis time YYYYMMDDHH"
        write(*,*) "  required arguments:"
        write(*,*) "  /path/to/infile.nc    path to input VIIRS data"
        write(*,*) "  /path/to/outfile.nc   path to output IODA file"
      end if
      write(*,*) "Not enough arguments... see --help for details"
      stop
    end if
    !! default settings for optional args
    thinning=.false.
    gridpath="none"
    fv3_gridfiles="none"
    validtimestr="2018041500"
    !! get args from command line and replace optional ones if defined
    if (nargs >= 2) then
      do iarg=1,nargs-1 
        call get_command_argument(iarg,arg1)
        if (arg1(1:6)=='--thin') then ! figure out thinning method
          print *, "placeholder for thinning!"
        else if (arg1(1:11)=='--validtime') then ! change gridpath
          validtimestr=arg1(13:len(arg1))
          read( validtimestr(1:4), '(i4)' )  yyyy
          read( validtimestr(5:6), '(i2)' )  mm
          read( validtimestr(7:8), '(i2)' )  dd
          read( validtimestr(9:10), '(i2)' )  hh
          validtime = create_datetime(year=yyyy,month=mm,day=dd,hour=hh)
          print *, "Will process observations relative to analysis time:"
          print *, trim(validtimestr)
        else if (arg1(1:10)=='--gridpath') then ! change gridpath
          ! grid path options
          gridpath=arg1(12:len(arg1))
          print *, "Will use FV3 grid for obs thinning located at:" 
          print *, trim(gridpath)
          ! get grid spec files for use
          do itile=1,ntiles_fv3
            write(tile,'(i1)') itile
            fv3_gridfiles(itile) = trim(gridpath)//"/"//"grid_spec.tile"//tile//".nc"
          end do   
          ! end grid path options
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
