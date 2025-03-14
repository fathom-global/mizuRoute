[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.4395155.svg)](https://doi.org/10.5281/zenodo.4395155)
[![Documentation Status](https://readthedocs.org/projects/mizuroute/badge/?version=main)](https://mizuroute.readthedocs.io/en/latest/?badge=main)

# mizuRoute
## Table of Contents

- [About](#about)
- [Getting Started and Usage](#getting_started_and_usage)
- [Tests or Validation](#tests)
- [License](#license)
- [Get Help](#help)

## About <a name = "about"></a>

Stand-alone mizuRoute is a post-processor of runoff output from a hydrologic model or Land surface model to produce streamflow estimates in the river network provided by a user. The tool was developed for the large scale, network based river routing (e.g., river network over contiguous United States), but works for gridded river network as well. mizuRoute is a model developped principally at NCAR and published under a **GPLv3 license**.

Technical documentation is now being built on [readthedocs](https://mizuroute.readthedocs.io/en/main/)

## Getting Started and Usage <a name = "#getting_started_and_usage"></a>

### Prerequisites and installation

1. Obtaining mizuRoute package. Just to use the tool, download the package by clicking “Download Zip” button on right column. 

2. Fortran compiler. Since we do not use any compiler-specific extensions, mizuRoute should be complied with any Fortran compilers. We have successfully used the intel Fortran compiler (ifort), the GNU Fortran compiler (gfortran), and PGI fortran compiler (pgf90). If the user does not have a Fortran compiler, [gfortran](https://gcc.gnu.org/wiki/GFortran) can be installed for free. The easiest way is to use a package manager. Which package manager depends on your machine flavor. 
We tested with the following compilers:
   - gfortran 8.3.0
   - ifort 18.0.5
   - pgi 19.3

3. NetCDF libraries. [NetCDF](http://www.unidata.ucar.edu/software/netcdf/) or the Network Common Data Format, is a set of software libraries and self-describing, machine-independent data formats that support the creation, access, and sharing of array-oriented scientific data. All the mizuRoute I/O (except control file and parameter namelist) use NetCDF. The user needs to ensure that:
NetCDF version 4.x is installed in the linux-like machine.
NetCDF Fortran library is installed (libnetcdff.\*) and not just the C-version.
The NetCDF libraries are compiled with the same compiler as you plan to compile mizuRoute
The user may use netcdf test code to check if NetCDF libraries are properly installed.

4. Compiling the source code. Once you have all the above, you can compile mizuRoute source codes using the following steps: Navigate to your local copy of the mizuRoute directory and go to the build subdirectory.
 
    1. Edit F_MASTER (name of path befor build directory) and FC (compiler name: gnu, intel or pgi) and FC_EXE (compiler executable name). You may also need to set NCDF_PATH. You may need to add some extra entries if you are using a different Fortran compiler or your setup is different (if someone wants to contribute an actual configure script that would be great). openMP (shared memory parallel processing) directive is implemented to prallelize the routing process. To activate openMP, set `isOpenMP`= `yes`. 

    2. Type make under directory where Makefile is located. If all goes well, this will create the executable runoff_route.exe to the bin directory. You may get some warnings (depending on your compiler settings), but you should not get any errors.

    3. Pay attention to the make output. You may need to set some environment variables (LD_LIBRARY_PATH in particular) to support dynamic linking;

    4. Try running the executables:
		
			 ./route_runoff.exe
				FATAL ERROR: need to supply name of the control file as a command-line argument

If you get this far then mizuRoute is built correctly and functional. Now, the user will have to generate input data, runoff data, river network topology and runoff mapping data (depending on input runoff option). Please look at [readthedocs](https://mizuroute.readthedocs.io/en/develop/) to learn more about mizuRoute input data. 

### How to run the code

Once you have generated the executable, you can run mizuRoute by specifying a control file, e.g.

```
~/mizuRoute/route/bin/mizu.exe /netapp/data/hydrology/mizuRoute/fuse_conus/settings/fuse_mizu_1979-2020.control

```

The control file defines all the modelling options, including the location of the input files, the routing scheme to be used, the start and end dates of the simulations, and the runoff mapping file. See `/netapp/data/hydrology/mizuRoute/fuse_conus/settings` for a few examples of control files.

## Tests or Validation<a name = "tests"></a>

Scripts to evaluate mizuRoute simulations driven by FUSE are provided by the separate [fuse_deployment](https://github.com/fathom-global/fuse_deployments) repo.

## License <a name = "license"></a>

mizuRoute is distributed under the GNU Public License Version 3. For details see the file `LICENSE` in the root directory or visit the [online version](http://www.gnu.org/licenses/gpl-3.0.html).

## Maintainers<a name = "help"></a>

Naoki Mizukami (mizukami@ucar.edu) - Nans Addor

