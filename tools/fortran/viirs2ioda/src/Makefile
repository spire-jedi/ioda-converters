FC =  ifort #mpiifort
FCFLAGS = -qopenmp

LIBCDF = -I$(NETCDF)/include -L$(NETCDF)/lib -lnetcdff -lnetcdf
DATETIME=/home/Mariusz.Pagowski/MAPP_2018/libs/fortran-datetime
LIBDATETIME = -I$(DATETIME)/include -L$(DATETIME)/lib -lfortran_datetime
SLINT = /home/Mariusz.Pagowski/MAPP_2018/libs/slint
LIBSLINT = -I$(SLINT) -L$(SLINT) -lslint
LDFLAGS = $(LIBCDF) $(LIBSLINT) $(LIBDATETIME)

SOURCEDIR = /home/Mariusz.Pagowski/mapp_2018/src_omp
BUILDDIR = /scratch1/BMC/gsd-fv3-dev/MAPP_2018/pagowski/build_omp
EXECDIR = /scratch1/BMC/gsd-fv3-dev/MAPP_2018/pagowski/exec

RM = /bin/rm -f

OBJ106 = \
	$(BUILDDIR)/orderpack.o \
	$(BUILDDIR)/viirs2ioda_init.o \
	$(BUILDDIR)/viirs2ioda_nc.o \
	$(BUILDDIR)/viirs2ioda_vars.o \
	$(BUILDDIR)/viirs2ioda_thin.o \
	$(BUILDDIR)/viirs2ioda.o  	

$(EXECDIR)/viirs2ioda.x: $(OBJ106)
	$(FC) $(OBJ106) $(FCFLAGS) $(LDFLAGS) -o $@

$(BUILDDIR)/viirs2ioda.o: $(BUILDDIR)/viirs2ioda_init.o \
                $(BUILDDIR)/viirs2ioda_vars.o \
                $(BUILDDIR)/viirs2ioda_nc.o \
                $(BUILDDIR)/viirs2ioda_thin.o
$(BUILDDIR)/viirs2ioda_init.o: $(BUILDDIR)/viirs2ioda_vars.o
$(BUILDDIR)/viirs2ioda_nc.o: $(BUILDDIR)/viirs2ioda_vars.o
$(BUILDDIR)/viirs2ioda_thin.o: $(BUILDDIR)/viirs2ioda_vars.o \
                $(BUILDDIR)/viirs2ioda_nc.o \
                $(BUILDDIR)/orderpack.o

#$(BUILDDIR)/%: $(BUILDDIR)/%.o
#	$(FC) $(FCFLAGS) -o $@ $^ $(LDFLAGS) 
$(BUILDDIR)/%.o: $(SOURCEDIR)/%.f90
	$(FC) $(FCFLAGS) -c $< $(LDFLAGS) -o $@ -module $(BUILDDIR) 

clean:
	$(RM) $(BUILDDIR)/*.o $(BUILDDIR)/*.mod

