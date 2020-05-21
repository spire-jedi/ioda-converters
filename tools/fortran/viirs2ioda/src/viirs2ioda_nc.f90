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
                               nobs, viirs_aod_input, n_abich,&
                               sat, inst, tendstr,validtime,tdiff
    use timedelta_mod
    use datetime_mod

    implicit none
    ! netCDF required variables
    integer :: ncid ! netCDF file ID
    integer :: dimid ! dimension ID for inquiry
    integer :: rowid, colid, abichid, lndchid
    ! dimension sizes
    integer :: nrows, ncols, n_lndch 
    ! variable IDs
    integer :: varid
    integer :: qcid

    ! data arrays
    real, allocatable, dimension(:,:) :: in_lats, in_lons
    real, allocatable, dimension(:,:,:) :: in_AOD
    real, allocatable, dimension(:) :: in_lats1, in_lons1, in_aodtmp,in_aodtmp2
    real, allocatable, dimension(:,:) :: in_AOD1,in_AOD550
    real, allocatable, dimension(:) :: in_AOD5501
    integer(SELECTED_INT_KIND(2)), allocatable, dimension(:,:) :: in_qcpath,in_qcall
    integer(SELECTED_INT_KIND(2)), allocatable, dimension(:) :: in_qcpath1,in_qcall1
    
    integer :: i,j,nobs2,qcval
    real :: ab,bb,au,bu
    integer :: yyyy,mm,dd,hh,ii,qc

    type(datetime_type) :: datatime
    type(timedelta_type) dt

    qc = 0 ! Retrieval quality:  0: high; 1: medium; 2: low; 3: no retrieval

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

    nobs = nrows*ncols

    ! allocate arrays
    allocate(in_lats(ncols,nrows),in_lons(ncols,nrows))
    allocate(in_AOD(n_abich,ncols,nrows))
    allocate(in_lats1(nobs),in_lons1(nobs),in_AOD1(n_abich,nobs))
    allocate(in_aodtmp(nobs))
    allocate(in_qcpath(ncols,nrows),in_qcall(ncols,nrows))
    allocate(in_qcpath1(nobs),in_qcall1(nobs))
    allocate(in_AOD550(ncols,nrows),in_AOD5501(nobs))

    !!! TODO - what all variables are needed? what metadata to retain?
    call check_nc(nf90_inq_varid(ncid,"Latitude",varid))
    call check_nc(nf90_get_var(ncid,varid,in_lats))
    call check_nc(nf90_inq_varid(ncid,"Longitude",varid))
    call check_nc(nf90_get_var(ncid,varid,in_lons))
    call check_nc(nf90_inq_varid(ncid,"AOD_channel",varid))
    call check_nc(nf90_get_var(ncid,varid,in_AOD))
    call check_nc(nf90_inq_varid(ncid,"AOD550",varid))
    call check_nc(nf90_get_var(ncid,varid,in_AOD550))
    call check_nc(nf90_inq_varid(ncid,"QCPath",qcid))
    call check_nc(nf90_get_var(ncid,qcid,in_qcpath))
    call check_nc(nf90_inq_varid(ncid,"QCAll",qcid))
    call check_nc(nf90_get_var(ncid,qcid,in_qcall))
    ! metadata
    call check_nc(nf90_get_att(ncid,NF90_GLOBAL,"satellite_name",sat))
    call check_nc(nf90_get_att(ncid,NF90_GLOBAL,"instrument_name",inst))
    call check_nc(nf90_get_att(ncid,NF90_GLOBAL,"time_coverage_end",tendstr))
    
    ! place into viirs_aod type array
    where (in_AOD<-1) in_AOD=NF90_FILL_REAL ! cannot have negative AOD!
    in_aodtmp2 = pack(in_qcall,in_qcall<=qc)
    in_lats1 = reshape(in_lats,shape(in_lats1))
    in_lons1 = reshape(in_lons,shape(in_lons1))
    in_AOD1 = reshape(in_AOD,shape(in_AOD1))
    in_AOD5501 = reshape(in_AOD550,shape(in_AOD5501))
    in_qcall1 = reshape(in_qcall,shape(in_qcall1))
    in_qcpath1 = reshape(in_qcpath,shape(in_qcpath1))
    nobs2 = nobs
    nobs = size(in_aodtmp2)
    allocate(viirs_aod_input(nobs))
    i=1
    do j=1,nobs2
      if (in_qcall1(j) <= qc) then 
        if (allocated(viirs_aod_input(i)%values)) &
           & deallocate(viirs_aod_input(i)%values)
        allocate(viirs_aod_input(i)%values(n_abich))
        viirs_aod_input(i)%values(:)=in_AOD1(:,j)
        viirs_aod_input(i)%lat=in_lats1(j)
        viirs_aod_input(i)%lon=in_lons1(j)
        viirs_aod_input(i)%qcall=in_qcall1(j)
        if (btest(in_qcpath1(j),0)) then ! water
          qcval = 0 + in_qcall1(j) 
          viirs_aod_input(i)%stype = 0
        else
          if (btest(in_qcpath1(j),1)) then ! bright land
            qcval = 10 + in_qcall1(j)
            viirs_aod_input(i)%stype = 1
          else ! dark land
            qcval = 20 + in_qcall1(j)
            viirs_aod_input(i)%stype = 2
          end if
        end if
        select case(qcval)
        ! case all land high quality
        !ab = -0.0137694 ; bb = 0.153738 ; au = 0.111351 ; bu = 0.148685
        ! case all land medium quality
        !ab = 0.0177766 ; bb = 0.383993; au = 0.0468670 ; bu = 0.259278 
        case (20) ! case dark land high quality
          ab = -0.0138969; bb = 0.157877; au = 0.111431; bu = 0.128699
        case (21) ! case dark land medium quality
          ab = 0.0193166; bb = 0.376421; au = 0.0374849; bu = 0.266073
        case (10) ! case bright land high quality
          ab = -0.0107621; bb = 0.150480; au = 0.0550472; bu = 0.299558
        case (11) ! case bright land medium quality
          ab = 0.0124126; bb = 0.261174; au = 0.0693246; bu = 0.270070
        case (0) ! case water high quality
          ab = 0.0151799; bb = 0.0767385; au = 0.00784394; bu = 0.219923
        case (1) ! case water medium quality
          ab = 0.0377016; bb = 0.283547; au = 0.0416146; bu = 0.0808841
        case default
          ab = 0; bb = 100.; au = 0; bu = 100.
        end select
        viirs_aod_input(i)%bias = ab + bb*in_AOD5501(j)
        viirs_aod_input(i)%uncertainty = au + bu*in_AOD5501(j)
                 

        i = i+1
      else
        cycle
      end if
    end do
    
    deallocate(in_lats,in_lats1,in_lons,in_lons1,in_AOD,in_AOD1)

    ! get time information, just assume the end time of the swath is the time
    ! for all obs (VIIRS will only be 1-2 mins per file, close enough
    read( tendstr(1:4), '(i4)' )  yyyy
    read( tendstr(6:7), '(i2)' )  mm
    read( tendstr(9:10), '(i2)' )  dd
    read( tendstr(12:13), '(i2)' )  hh
    read( tendstr(15:17), '(i2)' )  ii 
    datatime = create_datetime(year=yyyy,month=mm,day=dd,hour=hh,minute=ii)
    dt = datatime-validtime
    tdiff = dt%total_hours()      

    ! close the file
    call check_nc(nf90_close(ncid))

  end subroutine read_viirsaod_nc




  subroutine write_iodaaod_nc
    ! write netCDF file in a format that is readable by IODA
    use viirs2ioda_vars, only: outfile, &
                               n_abich,nobs_out, viirs_aod_output,&
                               sat,inst,validtimestr,tdiff,tdiffout
    use datetime_mod
    implicit none
    ! netCDF required variables
    integer :: ncid ! netCDF file ID
    integer :: nlocsid, nobsid, nrecsid, nvarsid, nchansid ! dimension IDs
    integer, dimension((n_abich*4)+11) :: varids
    integer :: i,j
    character(5) :: chchar
    character(len=100) :: varname
    integer :: validtimeint

    real, dimension(n_abich) :: freqs, wvlens, wvnums
    integer, dimension(n_abich) :: chans,polar
    integer, dimension(nobs_out) :: deepblue

    ! create the file, add dimensions, variables, and metadata
    call check_nc(nf90_create(path=outfile,cmode=nf90_clobber,ncid=ncid))

    ! global attributes
    !call check_nc(nf90_put_att(ncid,NF90_GLOBAL,"Satellite_Sensor",trim(sensor)))
    call check_nc(nf90_put_att(ncid,NF90_GLOBAL,"observation_type","Aod"))
    
    read(validtimestr,"(i)") validtimeint
    call check_nc(nf90_put_att(ncid,NF90_GLOBAL,"date_time",validtimeint))
    ! below to conform to current JEDI names, use better logic later
    if (trim(sat) == 'NPP') sat='suomi_npp'
    if (trim(inst) == 'VIIRS') inst='v.viirs-m_npp' 
    call check_nc(nf90_put_att(ncid,NF90_GLOBAL,"satellite",sat))
    call check_nc(nf90_put_att(ncid,NF90_GLOBAL,"sensor",inst))

    ! dimensions
    call check_nc(nf90_def_dim(ncid,'nlocs',NF90_UNLIMITED,nlocsid))
    call check_nc(nf90_def_dim(ncid,'nobs',nobs_out,nobsid)) ! force just ch 4
    !call check_nc(nf90_def_dim(ncid,'nobs',nobs_out*n_abich,nobsid))
    !call check_nc(nf90_def_dim(ncid,'nrecs',nobs_out,nrecsid))
    call check_nc(nf90_def_dim(ncid,'nrecs',1,nrecsid)) ! one record here?
    !call check_nc(nf90_def_dim(ncid,'nvars',n_abich,nvarsid))
    call check_nc(nf90_def_dim(ncid,'nvars',1,nvarsid)) ! force just outputting channel 4
    !call check_nc(nf90_def_dim(ncid,'nchans',n_abich,nchansid))

    ! variables
    ! note, some of these variable names need to be changed eventually (see
    ! commented out lines for example)
    call check_nc(nf90_def_var(ncid,'frequency@VarMetaData',nf90_real,nvarsid,varids(1)))
    !call check_nc(nf90_def_var(ncid,'sensor_band_central_radiation_frequency@VarMetaData',nf90_real,nvarsid,varids(1)))
    call check_nc(nf90_def_var(ncid,'polarization@VarMetaData',nf90_int,nvarsid,varids(2)))
    !call check_nc(nf90_def_var(ncid,'sensor_band_central_radiation_polarization@VarMetaData',nf90_int,nvarsid,varids(2)))
    call check_nc(nf90_def_var(ncid,'wavenumber@VarMetaData',nf90_real,nvarsid,varids(3)))
    !call check_nc(nf90_def_var(ncid,'sensor_band_central_radiation_wavenumber@VarMetaData',nf90_real,nvarsid,varids(3)))
    call check_nc(nf90_def_var(ncid,'sensor_channel@VarMetaData',nf90_int,nvarsid,varids(4)))
    !call check_nc(nf90_def_var(ncid,'sensor_band_identifier@VarMetaData',nf90_int,nvarsid,varids(4)))
    call check_nc(nf90_def_var(ncid,'latitude@MetaData',nf90_float,nlocsid,varids(5)))
    call check_nc(nf90_def_var(ncid,'longitude@MetaData',nf90_float,nlocsid,varids(6)))
    call check_nc(nf90_def_var(ncid,'sol_zenith_angle@MetaData',nf90_float,nlocsid,varids(7)))
    call check_nc(nf90_def_var(ncid,'sol_azimuth_angle@MetaData',nf90_float,nlocsid,varids(8)))
    !call check_nc(nf90_def_var(ncid,'solar_zenith_angle@MetaData',nf90_float,nlocsid,varids(7)))
    !call check_nc(nf90_def_var(ncid,'solar_azimuth_angle@MetaData',nf90_float,nlocsid,varids(8)))
    call check_nc(nf90_def_var(ncid,'modis_deep_blue_flag@MetaData',nf90_int,nlocsid,varids(9)))
    call check_nc(nf90_def_var(ncid,'surface_type@MetaData',nf90_int,nlocsid,varids(10)))
    call check_nc(nf90_def_var(ncid,'time@MetaData',nf90_float,nlocsid,varids(11)))
    j = 12
    do i=1,n_abich
      if (i /= 4 ) cycle
      write(chchar,'(i5)') i
      varname = 'aerosol_optical_depth_'//trim(adjustl(chchar))//'@ObsValue'
      call check_nc(nf90_def_var(ncid,trim(varname),nf90_float,nlocsid,varids(j))) 
      j=j+1
      varname = 'aerosol_optical_depth_'//trim(adjustl(chchar))//'@ObsError'
      call check_nc(nf90_def_var(ncid,trim(varname),nf90_float,nlocsid,varids(j))) 
      j=j+1
      varname = 'aerosol_optical_depth_'//trim(adjustl(chchar))//'@PreQc'
      call check_nc(nf90_def_var(ncid,trim(varname),nf90_float,nlocsid,varids(j))) 
      j=j+1
      varname = 'aerosol_optical_depth_'//trim(adjustl(chchar))//'@ObsBias'
      call check_nc(nf90_def_var(ncid,trim(varname),nf90_float,nlocsid,varids(j))) 
      j=j+1
    end do
    
    call check_nc(nf90_enddef(ncid))

    wvlens = (/412.,445.,488.,555.,672.,746.,865.,1240.,1378.,1610.,2250./)
    wvnums = 10000000./wvlens
    freqs = 2.99792458e8 / (wvlens*1e-9)
    do i=1,n_abich
      chans(i) = i
      polar(i) = 1 ! idk what this should be, it is 1 for ch 4 in sample file
    end do
    do i=1,nobs_out
      deepblue(i) = 0
    enddo

    ! for now assign the same time to all the obs
    tdiffout(:) = tdiff

    ! put the variables into the file
    !call check_nc(nf90_put_var(ncid,varids(1),freqs))
    !call check_nc(nf90_put_var(ncid,varids(2),polar)) ! polarization? 1?
    !call check_nc(nf90_put_var(ncid,varids(3),wvnums))
    !call check_nc(nf90_put_var(ncid,varids(4),chans))
    call check_nc(nf90_put_var(ncid,varids(1),freqs(4)))
    call check_nc(nf90_put_var(ncid,varids(2),polar(4))) ! polarization? 1?
    call check_nc(nf90_put_var(ncid,varids(3),wvnums(4)))
    call check_nc(nf90_put_var(ncid,varids(4),chans(4)))
    call check_nc(nf90_put_var(ncid,varids(5),viirs_aod_output(:)%lat))
    call check_nc(nf90_put_var(ncid,varids(6),viirs_aod_output(:)%lon))
    call check_nc(nf90_put_var(ncid,varids(7),0.))! solar zenith all 0 for test
    call check_nc(nf90_put_var(ncid,varids(8),0.))! solar azimuth all 0 for test
    call check_nc(nf90_put_var(ncid,varids(9),deepblue)) ! modis_deep_blue_flag all zeros
    call check_nc(nf90_put_var(ncid,varids(10),viirs_aod_output(:)%stype)) !surface type
    call check_nc(nf90_put_var(ncid,varids(11),tdiffout(:)))
    j=12
    do i=1,n_abich
      if (i /= 4 ) cycle ! just write out channel 4
      ! observation value
      call check_nc(nf90_put_var(ncid,varids(j),viirs_aod_output(:)%values(i)))
      j=j+1
      ! obs error
      call check_nc(nf90_put_var(ncid,varids(j),viirs_aod_output(:)%uncertainty))
      j=j+1
      ! obs qc
      call check_nc(nf90_put_var(ncid,varids(j),viirs_aod_output(:)%qcall))
      j=j+1
      ! obs bias
      call check_nc(nf90_put_var(ncid,varids(j),viirs_aod_output(:)%bias))
      j=j+1
    end do

    call check_nc(nf90_close(ncid)) ! close and finish writing out
    print *, 'Wrote to outfile: ', trim(outfile)
    
  end subroutine write_iodaaod_nc


  subroutine read_fv3_grid(griddata,grid_files)
    ! read FV3 grid for regridding/thinning purposes
    ! from M. Pagowski
    use viirs2ioda_vars, only: ntiles_fv3
    integer, parameter :: &
       &max_name_length_fv3=NF90_MAX_NAME, max_dims_fv3=4, max_vars_fv3=100
    real, allocatable, dimension(:,:), intent(out) :: griddata
    character(len = max_name_length_fv3), dimension(ntiles_fv3) :: grid_files

    integer, dimension(max_dims_fv3) :: dimids,dims
    character(len = max_name_length_fv3) :: input_file

    real, allocatable, dimension(:,:,:) :: tmpdata
    integer :: ncid,status,varid_lon,varid_lat,numdims,i,j,l,ij
    character(len = max_name_length_fv3) :: aname
    integer :: nx, ny, nxy, nxyg
    character(len = max_name_length_fv3), parameter :: &
       &varname_lon_fv3='grid_lont',varname_lat_fv3='grid_latt'

    input_file=trim(grid_files(1))

    call check_nc(nf90_open(input_file, nf90_nowrite, ncid))
    call check_nc(nf90_inq_varid(ncid, varname_lon_fv3, varid_lon))
    call check_nc(nf90_inquire_variable(ncid, varid_lon, aname, ndims=numdims))
    call check_nc(nf90_inquire_variable(ncid, varid_lon, dimids = dimids(:numdims)))
    call check_nc(nf90_inq_varid(ncid, varname_lat_fv3, varid_lat))

    dims=1

    do i=1,numdims
       call check_nc(nf90_inquire_dimension(ncid,dimids(i),len=dims(i)))
    end do

    nx=dims(1)
    ny=dims(2)
    nxy=nx*ny
    nxyg=ntiles_fv3*nxy
    allocate(tmpdata(nx,ny,2),griddata(2,nxyg))

    call check_nc(nf90_close(ncid))

    do l=1,ntiles_fv3
       input_file=trim(grid_files(l))
       call check_nc(nf90_open(input_file, nf90_nowrite, ncid))
       call check_nc(nf90_get_var(ncid,varid_lat,tmpdata(:,:,1), &
            start = (/ 1, 1 /), &
            count = (/ nx, ny /) ))
       call check_nc(nf90_get_var(ncid,varid_lon,tmpdata(:,:,2), &
            start = (/ 1, 1 /), &
            count = (/ nx, ny /) ))
       call check_nc(nf90_close(ncid))
       ij=1
       do j=1,ny
          do i=1,nx
             griddata(:,ij+(l-1)*nxy) = tmpdata(i,j,:)
             ij=ij+1
          end do
       end do
    end do

    deallocate(tmpdata)

  end subroutine read_fv3_grid


  subroutine check_nc(status)
    integer, intent(in) :: status

    if(status /= nf90_noerr) then
      print *, trim(nf90_strerror(status))
      stop "netCDF error...Stopped."
    end if
  end subroutine check_nc

end module viirs2ioda_nc
