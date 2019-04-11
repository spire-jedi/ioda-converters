#!/usr/bin/env python
# run_viirs2ioda.sh
# process VIIRS files and produce JEDI/IODA compatible obs files
import os
import subprocess as sp
import datetime as dt
import glob

InRoot='/scratch3/BMC/fim/MAPP_2018/OBS/VIIRS/AOT/'
OutRoot='/scratch3/NCEPDEV/stmp1/Cory.R.Martin/VIIRS/thinned/'
FV3Dir='/scratch3/BMC/chem-var/pagowski/tmp/FV3GFS/FV3_FIX/C96'
CycleHrs=6
StartCycle=dt.datetime(2018,4,14,12)
EndCycle=dt.datetime(2018,4,15,12)
viirs2ioda='/scratch4/NCEPDEV/da/save/Cory.R.Martin/JEDI/src/ioda-converters_2/tools/fortran/viirs2ioda/viirs2ioda'

my_env = os.environ.copy()
my_env['OMP_NUM_THREADS'] = '10' # for openmp to speed up fortran call
#./viirs2ioda --validtime=$validtime --gridpath=$fv3dir $infile $outfile
HalfCycle = CycleHrs/2
NowCycle=StartCycle
while NowCycle <= EndCycle:
  print("Processing analysis cycle: "+NowCycle.strftime("%Y-%m-%d_%H:%M UTC"))
  # get +- half of cycle hours
  StartObs = NowCycle - dt.timedelta(hours=HalfCycle)
  EndObs = NowCycle + dt.timedelta(hours=HalfCycle)
  # get possible files to use
  usefiles = []
  dir1 = InRoot+'/'+StartObs.strftime("%Y%m%d")
  dir2 = InRoot+'/'+EndObs.strftime("%Y%m%d")
  files1 = glob.glob(dir1+'/*.nc')
  files2 = glob.glob(dir2+'/*.nc')
  allfiles = set(files1+files2)
  for f in allfiles:
    fshort = f.split('/')[-1].split('_')
    fstart = dt.datetime.strptime(fshort[3][1:-1],"%Y%m%d%H%M%S")
    fend = dt.datetime.strptime(fshort[4][1:-1],"%Y%m%d%H%M%S")
    if (fstart > StartObs) and (fend < EndObs):
      usefiles.append(f)
  validtime=NowCycle.strftime("%Y%m%d%H")
  OutDir = OutRoot+'/'+validtime
  if not os.path.exists(OutDir):
    os.makedirs(OutDir)
  for f in usefiles:
    fout = OutDir+'/'+f.split('/')[-1]
    args = ' --validtime='+validtime+' --gridpath='+FV3Dir+' '+f+' '+fout
    cmd = viirs2ioda+args
    proc = sp.Popen(cmd,env=my_env,shell=True)
    proc.wait() # so that it doesn't overload the system
    # delete empty files because they will cause ncrcat to fail
    if os.path.getsize(fout) < 100:
      os.remove(fout)
  # concatenate them
  cmd = 'ncrcat '+OutDir+'/*.nc '+OutDir+'/viirs_aod_npp_'+validtime+'.nc'
  proc = sp.Popen(cmd,env=my_env,shell=True)
  proc.wait()  
  NowCycle = NowCycle + dt.timedelta(hours=CycleHrs)
