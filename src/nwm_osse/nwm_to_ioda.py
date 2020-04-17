#!/usr/bin/env python3
from datetime import datetime, timedelta
from multiprocessing import Pool
import numpy as np
import os
import pathlib
import pickle
import sys
import xarray as xr

# temporary for dev
from pprint import pprint as print
from copy import deepcopy

sys.path.append("/jedi/tools/lib/pyiodaconv")  # dummy before install
# sys.path.append("@SCRIPT_LIB_PATH@")
import ioda_conv_ncio as iconv

# (C) Copyright 2019 UCAR
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.

# Author:
# 2020-4-14: James McCreight

# Conceptual Figure:
# https://jointcenterforsatellitedataassimilation-jedi-docs.readthedocs-hosted.com/en/latest/_images/IODA_InMemorySchematic.png

# Purpose: Convert NWM output/restart files to observations in IODA format.

# Notes:
#   Currently not handling any data with vertical coordinates. This
#   can be added. For snow depths which vary in space and time, this
#   may require some effort.
#
#   This MVP implementation uses xarray. That can be changed when needed.

# Example testing usage:
# ipython --pdb -c "%run nwm_to_ioda.py \
#    --restart_dir ../../../../data/domains/v2.1/taylor_park_v2.1/NWM/RESTART_spinup_2007-10-01_v2.1_AORC/ \
#    --wrfinput ../../../../data/domains/v2.1/taylor_park_v2.1/NWM/DOMAIN/wrfinput.nc \
#    --output_file ../../../../data/nwm_osse/nwm_osse_ioda.nc \
#    --times 2017010100,2017010100 "

# ipython --pdb -c "%run nwm_to_ioda.py \
#    --restart_dir ../../../../data/domains/v2.1/taylor_park_v2.1/NWM/RESTART_spinup_2007-10-01_v2.1_AORC/ \  ## these have a fixed name
#    --wrfinput ../../../../data/domains/v2.1/taylor_park_v2.1/NWM/DOMAIN/wrfinput.nc \
#    --output_file ../../../../data/nwm_osse/nwm_osse_ioda.nc \  ## default is to clobber?
#    --times 2017010100,2017010100 \  ## default is all files present. allow range with '-' or just csv?"
#    --xy_inds (1,1),(2,2)"

# Input structure:
# For now we just work with "RESTART" files. "HYDRO_RST" files will be
# added later. The locations of the grid in the "RESTART" file are not
# self-contained. The restart grid info is found in the wrfinput file.
# This is reflected in the current input arguments.

# Output structure:

# root@8bba783e233d:/jedi/repos/ioda-converters/test/testoutput# ncdump -h owp_snow_obs.nc
# netcdf owp_snow_obs {
# dimensions:
# 	nvars = 1 ;
# 	nlocs = 156 ;
# 	nrecs = 1 ;
# 	nstring = 50 ;
# 	ndatetime = 20 ;
# variables:
# 	float snow_depth@PreQC(nlocs) ;
# 	float snow_depth@ObsError(nlocs) ;
# 	float snow_depth@ObsValue(nlocs) ;
# 	float time@MetaData(nlocs) ;
# 	float latitude@MetaData(nlocs) ;
# 	float longitude@MetaData(nlocs) ;
# 	char datetime@MetaData(nlocs, ndatetime) ;
# 	char variable_names@VarMetaData(nvars, nstring) ;

# // global attributes:
# 		:nrecs = 1 ;
# 		:nvars = 1 ;
# 		:nlocs = 156 ;
# 		:thinning = 0.5 ;
# 		:date_time = 2019021502 ;
# 		:converter = "owp_snow_obs_pkl_2_ioda.py" ;
# }

# Some todos on potentially desirable information to add in the future:
# TODO JLM: would be nice if the metadata on time@MetaData would say what the datum is and
#           what they units are.
# TODO JLM: Which of these are standardized?
#           Every variable may not have elevation.... nor station_id etc...
#           Should these be metadata or not?
#       float elevation@MetaData(nlocs) ;
#       float rec_elevation@MetaData(nlocs) ;
#       char station_id@MetaData(nlocs) ;
#       char station_name@MetaData(nlocs) ;
# // global attributes:
# 		:platform = "OWP Snow Obs" ;
# 		:sensor = "Multiple" ;
# 		:processing_level = "??" ;

arg_parse_description = (
    'Read snow NWM/NoahMP RESTART files and convert'
    'to IODA observation files.')

output_var_names = {'SNEQV': 'snow_depth', 'SNOWH': 'swe'}


def read_restart(
        restart_dir: pathlib.Path,
        wrfinput: pathlib.Path,
        restart_vars: list,
        assim_window_start: datetime,
        assim_window_end: datetime,
        thin: float = 0.0,
        n_cores: int = 1):
    """
    Based on assimilation window, identifies, reads, and converts multiple
    RESTART  files, performing optional thinning.
    Arguments:
        restart_dir: where to look for RESTART files in the assimilation window
        wrfinput: file path to the wrfinput location data file
        restart_vars: list of variables in the file to convert
        assim_window_start: (exclusive) start time
        assim_window_end: (inclusive?_ end time
        thin: [0,1] decimation amount of data.
        n_cores: currently un used.
    Returns:
        A tuple of (obs_dict, loc_dict, attr_dict) in the location shape
        needed by the ?IODA writer?.
    Notes:
        I dont pass "global_config" since I dont see a definiton or scope and
        I dont need to maintain its use in function...
    """

    # currently unused... 
    attr_dict = {}

    # Get the lon and lat from wrfinput file.
    wrfinput_ds = xr.open_dataset(wrfinput).squeeze('Time')
    wrfinput_lon_grid = wrfinput_ds.XLONG.values
    wrfinput_lat_grid = wrfinput_ds.XLAT.values
    wrfinput_ds.close()

    # Get restart files in the window, this acomodates any time
    # resoultion of the model (outputs are at most hourly)
    time_window_width_hr = (
        assim_window_end - assim_window_start).seconds/3600
    file_time_list = [
        assim_window_start + timedelta(hours=hh)
        for hh in range(int(time_window_width_hr + 1))]
    restart_time_fmt = 'RESTART.%Y%m%d%H_DOMAIN1'
    restart_files = []
    for tt in file_time_list:
        files_at_time = sorted(
            restart_dir.glob(tt.strftime(restart_time_fmt)))
        for ff in files_at_time:
            file_time = datetime.strptime(str(ff.name), restart_time_fmt)
            if file_time > assim_window_start and file_time <= assim_window_end:
                restart_files += [ff]

    if len(restart_files) is 0:
        return(None)

    # Get the data and its dimensions
    restart_ds = xr.open_mfdataset(restart_files)

    # There should not be lots of times, so I'm going to avoid using
    # something else (pandas/numpy) for this
    time = [datetime.strptime(tt,'%Y-%m-%d_%H')
            for tt in restart_ds.Times.values.astype('U13').tolist()]
    time_str = np.array([tt.strftime("%Y-%m-%dT%H:%M:%SZ") for tt in time])

    # Do some dimenion checking
    dim_union = set([])
    for vv in restart_vars:
        dim_union = dim_union.union(set(restart_ds[vv].dims))
    # From the variables requested, have to determine the maximal set of
    # locations. Fairly straight forward lat, lon, time.
    # The NoahMP lon, lat, time variable dimensions:
    #     Time, west_east, south_north
    # Dimensions in the NoahMP RESTART files which are not used by its vars:
    #     west_east_stag, south_north_stag
    # Not currently implementing vertical coordinates here:
    vertical_coord_list = ['soil_layers_stag', 'snow_layers', 'sosn_layers']
    for dd in list(dim_union):
        if dd in vertical_coord_list:
            raise ValueError('Vertical layers not currently implemented')

    # IODA Location (=space *time) Meta Data: Orange box in conceptual figure.
    # Now (un)ravel the native data to IODA locations.
    obs_dict = {}
    dims = restart_ds[restart_vars[0]].dims
    dim_shape = restart_ds[restart_vars[0]].shape
    for vv in restart_vars:
        if restart_ds[vv].dims != dims or restart_ds[vv].shape != dim_shape:
            raise ValueError('Inconsistent dimension order or length of '
                             'requested variables.')
        obs_dict[vv] = restart_ds[vv].values.ravel()

    space_len = np.prod(np.delete(np.array(dim_shape), np.where('Time' in dims)))
    time_len = np.array(dim_shape)[np.where('Time' in dims)]
    time_full = np.tile(time_str, space_len).ravel()
    lon_full = np.tile(wrfinput_lon_grid, len(time_len)).ravel()
    lat_full = np.tile(wrfinput_lat_grid, len(time_len)).ravel()

    # TODO JLM: what is the relationship between the time in the input file and
    #           the time argument which is passed to this "main"? Seems like
    #           something mysterious is happening in the writer.

    # get some of the global attributes that we are interested in
    # data_in['quality_level'] = ncd.variables['quality_level'][:].ravel()
    # mask = data_in['quality_level'] >= 0
    # data_in['quality_level'] = data_in['quality_level'][mask]
    # TODO JLM: Masking operations?
    # TODO JLM: mask on quality? mask on missing?

    # TODO JLM: I dont see formatting options in intrisic np.datetime_as_str,
    #           plus input is not datetime.

    # Additional metadata?
    # The possibilities: ['station_elevation', 'station_id', 'station_name',
    # 'station_rec_elevation'])
    # Optional (reproducibly) random thinning: Create a thin_mask (seed
    # depends on ref_date_time).
    # global_config['ref_date_time']
    # global_config['thin']
    np.random.seed(
        int((assim_window_start - datetime(1970, 1, 1)).total_seconds()))
    thin_mask = np.random.uniform(size=len(lon_full)) > thin

    # final output structure
    loc_dict = {
        'latitude': lat_full[thin_mask],
        'longitude': lon_full[thin_mask],
        'datetime': time_full[thin_mask],}

    # -----------------------------------------------------------------------------
    # Obs data and ObsError: Blue and yellow boxes in conceptual figure.

    # Structure it for easy iteration in populating the output structure.
    # TODO JLM: the err and qc multipliers are COMPLETELY MADE UP.
    obs_dict = {}
    for vv in restart_vars:
        obs_dict[vv] = {
            'values': restart_ds[vv].values.ravel()[thin_mask],
            'err': restart_ds[vv].values.ravel()[thin_mask] * .1,
            'qc': restart_ds[vv].values.ravel()[thin_mask] * 0, }

    return (loc_dict, obs_dict, attr_dict)


def nwm_to_ioda(
        restart_dir: pathlib.Path,
        wrfinput: pathlib.Path,
        time_window_center: datetime,
        restart_vars: list,
        output_file: pathlib.Path = pathlib.Path('./nwm_osse_ioda.nc'),
        time_window_half_width_hr: float = 0.5,
        thin: float = 0.0,
        n_cores: int = 1):

    writer = iconv.NcWriter(output_file, [], [])

    # TODO JLM: Global config: is what?
    # {
    #   'date': for what purpose - seems to only be used for
    #           setting the thinning seed
    #   'thin': A fractional thinning amt? 0.0,
    #   # The following just provide field names?
    #   'opqc_name': What does this mean? 'PreQC'
    #   'oerr_name': What does this mean? 'ObsError',
    #   'oval_name': What does this mean? 'ObsValue'
    # }
    global_config = {}
    global_config['oval_name'] = writer.OvalName()
    global_config['oerr_name'] = writer.OerrName()
    global_config['opqc_name'] = writer.OqcName()
    global_config['time_window_center'] = time_window_center
    global_config['time_window_half_width_hr'] = time_window_half_width_hr
    global_config['thin'] = thin

    # What is the open/closed convention on this set of the time axis? (,] or [,)?
    time_window_half_width = timedelta(hours=time_window_half_width_hr)
    assim_window_start = time_window_center - time_window_half_width
    assim_window_end = time_window_center + time_window_half_width

    # RESTART Files
    loc_dict, obs_dict, attr_dict = read_restart(
        restart_dir=restart_dir,
        wrfinput=wrfinput,
        restart_vars=restart_vars,
        assim_window_start=assim_window_start,
        assim_window_end=assim_window_end,
        thin=thin,
        n_cores=n_cores)

    # calculate output values
    # Note: the qc flags in GDS2.0 run from 0 to 5, with higher numbers
    # being better. IODA typically expects 0 to be good, and higher numbers
    # are bad, so the qc flags flipped here.
    # Shorten
    oval_name = global_config['oval_name']
    oerr_name = global_config['oerr_name']
    opqc_name = global_config['opqc_name']
    obs_dict_ioda = {}
    for old_name, new_name in output_var_names.items():
        if old_name in obs_dict:
            obs_dict_ioda[(new_name, oval_name)] = obs_dict[old_name]['values']
            obs_dict_ioda[(new_name, oerr_name)] = obs_dict[old_name]['err']
            obs_dict_ioda[(new_name, opqc_name)] = obs_dict[old_name]['qc']

    del obs_dict
    # need to save off names of variables actually returned? or do that in attr?

    # prepare global attributes we want to output in the file,
    # in addition to the ones already loaded in from the input file
    # TODO JLM: is this format reformatted by the writer.BuildNetcdf? does
    # not match output

    # TODO JLM: What is this date_time_string used for?
    #   Apparently it is the self._ref_date_time in the NcWriter class.
    # TODO JLM: could 'date' be called ref_date_time? there are at least
    #   4 names that this value takes:
    #   args.date
    #   global_config['date']
    #   arttr_data['date_time_string']
    #   self._ref_date_time
    #   That's super confusing. I like "args.ref_date_time" ->
    #       global_config['ref_date_time'] ->
    #       attr_data['ref_date_time'] -> self._ref_date_time
    #   ref indicates something useful.
    attr_dict['date_time_string'] = global_config[
        'time_window_center'].strftime("%Y-%m-%dT%H:%M:%SZ")
    attr_dict['thinning'] = global_config['thin']
    attr_dict['converter'] = os.path.basename(__file__)

    loc_dict['datetime'] = writer.FillNcVector(loc_dict['datetime'], "datetime")

    # determine which variables we are going to output
    selected_names = list(set([tt[0] for tt in list(obs_dict_ioda.keys())]))
    var_dict = {
        writer._var_list_name: writer.FillNcVector(selected_names, "string")}

    # pass parameters to the IODA writer
    # (needed because we are bypassing ExtractObsData within BuildNetcdf)
    writer._nrecs = 1
    writer._nvars = len(selected_names)
    writer._nlocs = obs_dict_ioda[(selected_names[0], 'ObsValue')].shape[0]

    # use the writer class to create the final output file
    writer.BuildNetcdf(obs_dict_ioda, {}, loc_dict, var_dict, attr_dict)
    return(0)

# Make parser separate, testable.
def parse_arguments():
    import argparse
    parser = argparse.ArgumentParser(
        description=arg_parse_description
    )

    required = parser.add_argument_group(title='required arguments')
    required.add_argument(
        '--restart_dir',
        help="director containing NWM RESTART (LSM) files",
        type=str,
        required=True)
    required.add_argument(
        '--wrfinput',
        help="path to the wrf_input.nc (or other name) file for the domain",
        type=str,
        required=True)
    required.add_argument(
        '--time_window_center',
        metavar="YYYYMMDDHH",
        help="date and time of the center of the assimilation window",
        type=str,
        required=True)
    required.add_argument(
        '--restart_vars',
        metavar="var1,var2",
        help="comma separated variable names in the restart file",
        type=str,
        required=True)

    optional = parser.add_argument_group(title='optional arguments')
    optional.add_argument(
        '--output_file',
        help="output files",
        type=str,
        default='./nwm_osse_ioda.nc')
    optional.add_argument(
        '--time_window_half_width_hr',
        metavar="HH",
        help="half-width of the assimilation window in hours",
        type=float,
        default='0.5')
    optional.add_argument(
        '--thin',
        help="percentage of random thinning, from 0.0 to 1.0. Zero indicates"
             " no thinning is performed. (default: %(default)s)",
        type=float,
        default=0.0)
    optional.add_argument(
        '--n_cores',
        # TODO JLM: multiprocessing.Pool provides process based parallelism.
        # TODO JLM: multiprocessing.pool.ThreadPool provides unsupported
        #           thread-based pool parallelism.
        help='multiprocessing.Pool can load input files in parallel.'
             ' (default: %(default)s)',
        type=int,
        default=1)

    args = parser.parse_args()

    # required args
    restart_dir = pathlib.Path(args.restart_dir)
    wrfinput = pathlib.Path(args.wrfinput)
    time_window_center = datetime.strptime(
        args.time_window_center, "%Y%m%d%H")
    restart_vars = args.restart_vars.replace(' ', '').split(',')

    # optional args
    output_file = pathlib.Path(args.output_file)
    time_window_half_width_hr = args.time_window_half_width_hr
    thin = args.thin
    n_cores = args.n_cores

    arg_dict = {
        'restart_dir': restart_dir,
        'wrfinput': wrfinput,
        'time_window_center': time_window_center,
        'restart_vars': restart_vars,
        'output_file': output_file,
        'time_window_half_width_hr': time_window_half_width_hr,
        'thin': thin,
        'n_cores': n_cores}
    return arg_dict


if __name__ == '__main__':
    kwarg_dict = parse_arguments()
    return_code = nwm_to_ioda(**kwarg_dict)
    sys.exit(return_code)
