# Run ASCAT

Split a prepbufr file into its subsets, and runs bufr2ioda.x on the 
resulting scatterometer prepbufr file

## Dependencies

* **Python 3.6+**

The following executables must be available in the shell path.

* **bufr2ioda.x** - From ioda_converters
* **split_by_subset.x** - From NCEPLibs-Bufr

## Usage

./run_ascat.py **path/to/*.prepbufr**

## Output

Script will create a directory that follows the pattern 
**ascat_processing**__datetime_, where _datetime_ is the timestamp when the 
script was run. The resulting .nc file will appear here.
