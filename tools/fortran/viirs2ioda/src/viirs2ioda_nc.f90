!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!! viirs2ioda_nc
!! - module for netCDF i/o routines for viirs2ioda 
!!
!! author: Cory Martin - cory.r.martin@noaa.gov
!! history: 2019-03-04 - original
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
module viirs2ioda_nc
  use netcdf
  implicit none
contains
  subroutine read_viirsaod_nc
    ! reads input netCDF file, allocates arrays,
    ! and puts observation data into memory
    use viirs2ioda_vars, only: infile, &
                               in_lats, in_lons, in_AOD550
    implicit none
    ! netCDF required variables
    integer :: ncid ! netCDF file ID
    integer :: dimid ! dimension ID for inquiry
    integer :: rowid, colid, abichid, lndchid
    ! dimension sizes
    integer :: nrows, ncols, n_abich, n_lndch 
    ! variable IDs

    ! open the file
    call check_nc(nf90_open(infile, nf90_nowrite, ncid))
    ! get the size of the dimensions in the file to allocate arrays
    call check_nc(nf90_inq_dimid(ncid,"Rows",dimid))
    call check_nc(nf90_inquire_dimension(ncid,dimid,len=nrows))
    call check_nc(nf90_inq_dimid(ncid,"Columns",dimid))
    call check_nc(nf90_inquire_dimension(ncid,dimid,len=ncols))
    call check_nc(nf90_inq_dimid(ncid,"AbiAODnchn",dimid))
    call check_nc(nf90_inquire_dimension(ncid,dimid,len=n_abich))
    call check_nc(nf90_inq_dimid(ncid,"LndLUTnchn",dimid))
    call check_nc(nf90_inquire_dimension(ncid,dimid,len=n_lndch))

    ! remove prints later, just for debug purposes
    print *, 'nrows,ncols,n_abich,n_lndch'    
    print *, nrows,ncols,n_abich,n_lndch    

    ! allocate arrays
    allocate(in_lats(ncols,nrows),in_lons(ncols,nrows))
    allocate(in_AOD550(ncols,nrows))

    !!! TODO - what all variables are needed? what metadata to retain?
    
    
  end subroutine read_viirsaod_nc

  subroutine write_iodaaod_nc
    ! write netCDF file in a format that is readable by IODA
    use viirs2ioda_vars, only: outfile, &
                               sensor
    implicit none
    ! netCDF required variables
    integer :: ncid ! netCDF file ID
    integer :: nlocsid, nobsid, nrecsid, nvarsid, nchansid ! dimension IDs

    ! create the file, add dimensions, variables, and metadata
    call check_nc(nf90_create(path=outfile,cmode=nf90_clobber,ncid=ncid))
    call check_nc(nf90_put_att(ncid,NF90_GLOBAL,"Satellite_Sensor",trim(sensor)))
    !call check_nc(nf90_def_dim(ncid,'AOD_bin',nbins,bdimid))
    !dimids2 = (/xdimid,ydimid/)
    !call check_nc(nf90_def_var(ncid,'AOD_bins',nf90_real,bdimid,binvarid))
    call check_nc(nf90_enddef(ncid))

    ! put the variables into the file
    !call check_nc(nf90_put_var(ncid,aodvarid,AODmean))

    call check_nc(nf90_close(ncid)) ! close and finish writing out
    
  end subroutine write_iodaaod_nc

  subroutine check_nc(status)
    integer, intent(in) :: status

    if(status /= nf90_noerr) then
      print *, trim(nf90_strerror(status))
      stop "netCDF error...Stopped."
    end if
  end subroutine check_nc

end module viirs2ioda_nc
