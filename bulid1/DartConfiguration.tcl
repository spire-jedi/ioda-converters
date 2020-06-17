# This file is configured by CMake automatically as DartConfiguration.tcl
# If you choose not to use CMake, this file may be hand configured, by
# filling in the required variables.


# Configuration directories and files
SourceDirectory: /scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters
BuildDirectory: /scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters/bulid1

# Where to place the cost data store
CostDataFile: 

# Site is something like machine.domain, i.e. pragmatic.crd
Site: hfe10

# Build name is osname-revision-compiler, i.e. Linux-2.4.2-2smp-c++
BuildName: Linux-icpc

# Subprojects
LabelsForSubprojects: 

# Submission information
SubmitURL: http://

# Dashboard start time
NightlyStartTime: 00:00:00 EDT

# Commands for the build/test/submit cycle
ConfigureCommand: "/scratch1/NCEPDEV/jcsda/Ryan.Honeyager/jedi/usr/local/intel-18.0.5.274/impi-2018.0.4/netcdf-hdf5parallel-4.7.0/bin/cmake" "/scratch2/NCEPDEV/marineda/Youlong.Xia/save/ioda-converters"
MakeCommand: /scratch1/NCEPDEV/jcsda/Ryan.Honeyager/jedi/usr/local/intel-18.0.5.274/impi-2018.0.4/netcdf-hdf5parallel-4.7.0/bin/cmake --build . --config "${CTEST_CONFIGURATION_TYPE}"
DefaultCTestConfigurationType: Release

# version control
UpdateVersionOnly: 

# CVS options
# Default is "-d -P -A"
CVSCommand: CVSCOMMAND-NOTFOUND
CVSUpdateOptions: -d -A -P

# Subversion options
SVNCommand: /usr/bin/svn
SVNOptions: 
SVNUpdateOptions: 

# Git options
GITCommand: /usr/bin/git
GITInitSubmodules: 
GITUpdateOptions: 
GITUpdateCustom: 

# Perforce options
P4Command: P4COMMAND-NOTFOUND
P4Client: 
P4Options: 
P4UpdateOptions: 
P4UpdateCustom: 

# Generic update command
UpdateCommand: /usr/bin/git
UpdateOptions: 
UpdateType: git

# Compiler info
Compiler: /apps/intel/parallel_studio_xe_2018.4.057/compilers_and_libraries_2018/linux/bin/intel64/icpc
CompilerVersion: 18.0.5.20180823

# Dynamic analysis (MemCheck)
PurifyCommand: 
ValgrindCommand: 
ValgrindCommandOptions: 
MemoryCheckType: 
MemoryCheckSanitizerOptions: 
MemoryCheckCommand: /usr/bin/valgrind
MemoryCheckCommandOptions: --trace-children=yes --leak-check=full --error-exitcode=1
MemoryCheckSuppressionFile: 

# Coverage
CoverageCommand: /usr/bin/gcov
CoverageExtraFlags: -l

# Cluster commands
SlurmBatchCommand: /apps/slurm/default/bin/sbatch
SlurmRunCommand: /apps/slurm/default/bin/srun

# Testing options
# TimeOut is the amount of time in seconds to wait for processes
# to complete during testing.  After TimeOut seconds, the
# process will be summarily terminated.
# Currently set to 25 minutes
TimeOut: 1500

# During parallel testing CTest will not start a new test if doing
# so would cause the system load to exceed this value.
TestLoad: 

UseLaunchers: 
CurlOptions: 
# warning, if you add new options here that have to do with submit,
# you have to update cmCTestSubmitCommand.cxx

# For CTest submissions that timeout, these options
# specify behavior for retrying the submission
CTestSubmitRetryDelay: 5
CTestSubmitRetryCount: 3
