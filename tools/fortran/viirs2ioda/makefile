FC = mpiifort
NETCDF_LIB = -L$(NETCDF)/lib -lnetcdff -L$(NETCDF)/lib -Wl,-rpath -Wl,$(NETCDF)/lib -lnetcdf -lnetcdf
NETCDF_INC = -I/$(NETCDF)/include
FCFLAGS = -convert big_endian
FCFLAGS =
LDFLAGS = $(NETCDF_LIB) $(NEMSIO_LIB) $(BACIO_LIB4) $(W3NCO_LIB4) $(CRTM_LIB) 
INCFLAGS = $(NETCDF_INC) -I$(NEMSIO_INC) -I$(CRTM_INC) 
SOURCEDIR = src
BUILDDIR = build
EXECUTABLE = viirs2ioda 

objects = \
	$(BUILDDIR)/viirs2ioda_init.o\
	$(BUILDDIR)/viirs2ioda_nc.o\
	$(BUILDDIR)/viirs2ioda_vars.o\
	$(BUILDDIR)/main.o

viirs2ioda: $(objects)
	$(FC) -o $(EXECUTABLE) $(objects) $(LDFLAGS) $(INCFLAGS)

$(BUILDDIR)/main.o: $(BUILDDIR)/viirs2ioda_init.o\
		$(BUILDDIR)/viirs2ioda_vars.o\
		$(BUILDDIR)/viirs2ioda_nc.o 
$(BUILDDIR)/viirs2ioda_init.o: $(BUILDDIR)/viirs2ioda_vars.o
$(BUILDDIR)/viirs2ioda_nc.o: $(BUILDDIR)/viirs2ioda_vars.o

$(BUILDDIR)/%: $(BUILDDIR)/%.o
	$(FC) $(FCFLAGS) -o $@ $^ $(INCFLAGS)
$(BUILDDIR)/%.o: $(SOURCEDIR)/%.f90
	$(FC) $(FCFLAGS) -c $< $(INCFLAGS) -o $@ -module $(BUILDDIR)
clean:
	rm $(EXECUTABLE) $(BUILDDIR)/*.mod $(BUILDDIR)/*.o 
