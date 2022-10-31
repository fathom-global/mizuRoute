#========================================================================
# Makefile to compile the netCDF test program
#========================================================================
#
# To troubleshoot your paths and setup, type 'make check'
# Change library path HDF, NCDF, LOCAL, SZIP, ZLIB

# Define the Fortran Compiler

CC=gfortran

ifeq "$(CC)" "gfortran"
 NCDF_PATH=/usr/lib/x86_64-linux-gnu
 INCLUDE_PATH = /usr#${IN_PATH}
endif

LIBNETCDF = -Wl,-rpath,$(NCDF_PATH)/lib \
            -L$(NCDF_PATH)/lib -lnetcdff -lnetcdf
INCNETCDF = -I$(INCLUDE_PATH)/include

# define flags
ifeq "$(CC)" "gfortran"
 FLAGS = -Wall -g -ffree-line-length-none
endif

ifeq "$(CC)" "ifort"
  FLAGS = -debug -warn all -check all -FR -O0 -auto -WB -traceback -g -fltconsistency -fpe0
endif

ifeq "$(CC)" "pgf90"
 FLAGS1 = -Bstatic -Mbackslash -g -Mchkptr -Mchkstk -Mpgicoff -Minform=inform -Ktrap=divz,inv -Mprof=lines,time
 #FLAGS = -Bstatic -Mbackslash -g -Mchkptr -Mchkstk -Mpgicoff -Minform=inform -Ktrap=divz,inv
 FLAGS = -Mbackslash -g -Mchkptr -Mchkstk -Mpgicoff -Minform=inform -Ktrap=divz,inv
endif

# define program
PROGRAM = test_netcdf.f90

# define executable
EX = test_netcdf.exe

#FLAGS = -O3 -W -v

#.SUFFIXES: .f .o .f90

# Compile
all: compile link clean

# compile
compile:
	$(CC) $(FLAGS) -c $(PROGRAM) $(INCNETCDF)

# link routines
link:
	$(CC) *.o $(LIBNETCDF) -o $(EX)

# Remove object files
clean:
	rm -f *.o
	rm -f *.mod
