#!/usr/bin/env python

import ncepbufr
from netCDF4 import Dataset
from argparse import ArgumentParser, ArgumentDefaultsHelpFormatter
from datetime import datetime as dt
import sys
import os
import yaml
import copy
import re

#sys.path.append("/usr/local/lib/pyiodaconv")
sys.path.append("/scratch2/NCEPDEV/marineda/Jeffrey.Smith/IODA_FEATURE/build/lib/pyiodaconv")
import bufr2ncCommon as cm
from bufr2ncObsTypes_marine import ObsType

# class (used like a C struct) for nodes in a tree for mnemonics from
# a BUFR table

class Mnemonic:
    def __init__(self, name, seq, parent):
        self.name = name
        self.seq = seq
        self.parent = parent
        self.children = []
        return

#config_path = "/usr/local/lib/pyiodaconv/config/"
#config_path = "/scratch2/NCEPDEV/marineda/Jeffrey.Smith/IODA_FEATURE/build/lib/pyiodaconv"
config_path = "/home/Jeffrey.Smith/"

##########################################################################
# SUBROUTINES To be deleted (maybe).
##########################################################################


def MessageCounter(BufrFname):
    # This function counts the number of messages in the file BufrFname
    bufr = ncepbufr.open(BufrFname)
    NumMessages = 0
    Obs.start_msg_selector()
    while (Obs.select_next_msg(bufr)):
        NumMessages += 1

    bufr.close()
    return [NumMessages]


def BfilePreprocess(BufrFname, Obs):
    # This routine will read the BUFR file and figure out how many observations
    # will be read when recording data.

    bufr = ncepbufr.open(BufrFname)

    # The number of observations will be equal to the total number of subsets
    # contained in the selected messages.
    NumObs = 0
    Obs.start_msg_selector()
    while (Obs.select_next_msg(bufr)):
        NumObs += Obs.msg_obs_count(bufr)
    bufr.close()

    return [NumObs, Obs.num_msg_selected, Obs.num_msg_mtype]

# ########################################################################
# ########                  (Prep-) BUFR NCEP Observations               #
# ########################################################################
#
# The class is developed to import all the entries to any BUFR family data set
# that the tables A, B, D of BUFR are embedded to the files.
#


class MarineProfileType(ObsType):
    # # initialize data elements ###
    def __init__(self, bf_type, alt_type, tablefile, dictfile):

        super(MarineProfileType, self).__init__()


        self.bufr_ftype = bf_type
        self.multi_level = False
        # Put the time and date vars in the subclasses so that their dimensions
        # can vary ( [nlocs], [nlocs,nlevs] ).
        self.misc_spec[0].append(
            ['ObsTime@MetaData', '', cm.DTYPE_INTEGER, ['nlocs'], [self.nlocs]])
        self.misc_spec[0].append(
            ['ObsDate@MetaData', '', cm.DTYPE_INTEGER, ['nlocs'], [self.nlocs]])
        self.misc_spec[0].append(
            ['time@MetaData', '', cm.DTYPE_DOUBLE, ['nlocs'], [self.nlocs]])
        self.misc_spec[0].append(
            ['latitude@MetaData', '', cm.DTYPE_FLOAT, ['nlocs'], [self.nlocs]])
        self.misc_spec[0].append(
            ['longitude@MetaData', '', cm.DTYPE_FLOAT, ['nlocs'], [self.nlocs]])
        self.misc_spec[0].append(
            ['datetime@MetaData', '', cm.DTYPE_STRING, ['nlocs', 'nstring'], [self.nlocs, self.nstring]])

        if (bf_type == cm.BFILE_BUFR):
            self.mtype_re = alt_type  # alt_type is the BUFR mnemonic

            if os.path.isfile(dictfile):
                # i.e. 'NC001007.dict'
                full_table = read_yaml(dictfile)
                _, blist = read_table(tablefile)
            else:
                full_table, blist = read_table(
                    tablefile)  # i.e. 'NC001007.tbl'
                write_yaml(full_table, dictfile)

            spec_list = get_int_spec(alt_type, blist)
            intspec = []
            intspecDum = []

            if not os.path.isfile(Lexicon):
                for i in spec_list[alt_type]:
                    if i in full_table:
                        intspecDum = [
                            full_table[i]['name'].replace(
                                ' ',
                                '_').replace('/', '_'),
                            i,
                            full_table[i]['dtype'],
                            full_table[i]['ddims']]
                        if intspecDum not in intspec:
                            intspec.append([full_table[i]['name'].replace(
                                ' ', '_').replace('/', '_'), i, full_table[i]['dtype'], full_table[i]['ddims']])
                    # else:
                    # TODO what to do if the spec is not in the full_table (or
                    # in this case, does not have a unit in the full_table)
                for j, dname in enumerate(intspec):
                    if len(dname[3]) == 1:
                        intspec[j].append([self.nlocs])
                    elif len(dname[3]) == 2:
                        intspec[j].append([self.nlocs, self.nstring])
                    else:
                        print('walked off the edge')

                write_yaml(intspec, Lexicon)
            else:
                intspec = read_yaml(Lexicon)

            self.nvars = 0
            for k in intspec:
                if '@ObsValue' in (" ".join(map(str, k))):
                    self.nvars += 1
            # The last mnemonic (RRSTG) corresponds to the raw data, instead
            # of -1 below, it is explicitly removed. The issue with RRSTG is
            # the Binary length of it, which makes the system to crash
            # during at BufrFloatToActual string convention. Probably, there
            # are more Mnemonics with the same problem.

            self.int_spec = [intspec[x:x + 1]
                             for x in range(0, len(intspec), 1)]
            # TODO Check not sure what the evn_ and rep_ are
            self.evn_spec = []

            spec_list = get_rep_spec(alt_type, blist)
            repspec = []
            repspecDum = []

            for i in spec_list[alt_type]:
                if i in full_table:
                    repspecDum = [
                        full_table[i]['name'].replace(
                            ' ',
                            '_').replace('/', '_'),
                        i,
                        full_table[i]['dtype'],
                        full_table[i]['ddims']]
                    if repspecDum not in repspec:
                        repspec.append([full_table[i]['name'].replace(
                            ' ', '_').replace('/', '_'), i, full_table[i]['dtype'], full_table[i]['ddims']])
                    # else:
                    # TODO what to do if the spec is not in the full_table (or
                    # in this case, does not have a unit in the full_table)
            for j, dname in enumerate(repspec):
                if len(dname[3]) == 1:
                    repspec[j].append([self.nlocs])
                elif len(dname[3]) == 2:
                    repspec[j].append([self.nlocs, self.nstring])
                else:
                    print('walked off the edge')

                #write_yaml(repspec, Lexicon)
            #else:
                #repspec = read_yaml(Lexicon)

            # The last mnemonic (RRSTG) corresponds to the raw data, instead
            # of -1 below, it is explicitly removed. The issue with RRSTG is
            # the Binary length of it, which makes the system to crash
            # during at BufrFloatToActual string convention. Probably, there
            # are more Mnemonics with the same problem.

            self.rep_spec = [repspec[x:x + 1] \
                             for x in range(0, len(repspec), 1) if not repspec[x] in intspec]
            self.rep_spec = self.rep_spec

            #self.rep_spec = []
            # TODO Check the intspec for "SQ" if exist, added at seq_spec
            self.seq_spec = []

            self.nrecs = 1  # place holder

        # Set the dimension specs.
        super(MarineProfileType, self).init_dim_spec()


class NC031001ProfileType(ObsType):

    def __init__(self, bf_type):

        super(NC031001ProfileType, self).__init__()

        alt_type = "NC031001"
        dictfile = "NC031001.dict"
        tablefile = "NC031001.tbl"

        self.bufr_ftype = bf_type
        self.multi_level = False
        # Put the time and date vars in the subclasses so that their dimensions
        # can vary ( [nlocs], [nlocs,nlevs] ).
        self.misc_spec[0].append(
            ['ObsTime@MetaData', '', cm.DTYPE_INTEGER, ['nlocs'], [self.nlocs]])
        self.misc_spec[0].append(
            ['ObsDate@MetaData', '', cm.DTYPE_INTEGER, ['nlocs'], [self.nlocs]])
        self.misc_spec[0].append(
            ['time@MetaData', '', cm.DTYPE_DOUBLE, ['nlocs'], [self.nlocs]])
        self.misc_spec[0].append(
            ['latitude@MetaData', '', cm.DTYPE_FLOAT, ['nlocs'], [self.nlocs]])
        self.misc_spec[0].append(
            ['longitude@MetaData', '', cm.DTYPE_FLOAT, ['nlocs'], [self.nlocs]])
        self.misc_spec[0].append(
            ['datetime@MetaData', '', cm.DTYPE_STRING, ['nlocs', 'nstring'], [self.nlocs, self.nstring]])
        
        if (bf_type == cm.BFILE_BUFR):
            self.mtype_re = "NC031001"  # alt_type is the BUFR mnemonic

            if os.path.isfile(dictfile):
                # i.e. 'NC001007.dict'
                full_table = read_yaml(dictfile)
                _, blist = read_table(tablefile)
            else:
                full_table, blist = read_table(
                    tablefile)  # i.e. 'NC001007.tbl'
                write_yaml(full_table, dictfile)

            spec_list = get_spec(alt_type, blist,
                                 parentsToPrune=["RAWRPT"],
                                 leavesToPrune=[])
            #spec_list = get_int_spec(alt_type, blist)
            intspec = []
            intspecDum = []

            if not os.path.isfile(Lexicon):
                for i in spec_list[alt_type]:
                    if i in full_table:
                        intspecDum = [
                            full_table[i]['name'].replace(
                                ' ',
                                '_').replace('/', '_'),
                            i,
                            full_table[i]['dtype'],
                            full_table[i]['ddims']]
                        if intspecDum not in intspec:
                            intspec.append([full_table[i]['name'].replace(
                                ' ', '_').replace('/', '_'), i, full_table[i]['dtype'], full_table[i]['ddims']])
                    # else:
                    # TODO what to do if the spec is not in the full_table (or
                    # in this case, does not have a unit in the full_table)
                for j, dname in enumerate(intspec):
                    if len(dname[3]) == 1:
                        intspec[j].append([self.nlocs])
                    elif len(dname[3]) == 2:
                        intspec[j].append([self.nlocs, self.nstring])
                    else:
                        print('walked off the edge')

                write_yaml(intspec, Lexicon)
            else:
                intspec = read_yaml(Lexicon)

            self.nvars = 0
            for k in intspec:
                if '@ObsValue' in (" ".join(map(str, k))):
                    self.nvars += 1
            # The last mnemonic (RRSTG) corresponds to the raw data, instead
            # of -1 below, it is explicitly removed. The issue with RRSTG is
            # the Binary length of it, which makes the system to crash
            # during at BufrFloatToActual string convention. Probably, there
            # are more Mnemonics with the same problem.

            self.int_spec = [intspec[x:x + 1]
                             for x in range(0, len(intspec), 1)]
            # TODO Check not sure what the evn_ and rep_ are
            self.evn_spec = []

            
            self.rep_spec = []

            # TODO Check the intspec for "SQ" if exist, added at seq_spec
            #self.seq_spec = []
            seqspec = []
            seqspec.append(["wndsq1", "WNDSQ1", 1, ["nlocs"], [-1]])
            seqspec.append(["wndsq2", "WNDSQ2", 1, ["nlocs"], [-1]])
            seqspec.append(["tmpsq4", "TMPSQ4", 1, ["nlocs"], [-1]])
            seqspec.append(["btocn", "BTOCN", 1, ["nlocs"], [-1]])
            seqspec.append(["id1sq", "ID1SQ", 1, ["nlocs"], [-1]])
            seqspec.append(["id2sq", "ID2SQ", 1, ["nlocs"], [-1]])
            seqspec.append(["id3sq", "ID3SQ", 1, ["nlocs"], [-1]])
            seqspec.append(["ltlonh", "LTLONH", 1, ["nlocs"], [-1]])

            yamlDict = intspec
            yamlDict.append(["depth_below_sea_water_surface_ts", "DBSS", 3, "nlocs", [-1]])
            yamlDict.append(["qualifier_for_gtspp_quality_flag_dbss_ts", "QFQF", 2, "nlocs", [-1]])
            yamlDict.append(["global_gtspp_quality_flag_dbss_ts", "GGQF", 2, "nlocs", [-1]])
            yamlDict.append(["water_pressure_ts", "WPRES", 3, "nlocs", [-1]])
            yamlDict.append(["qualifier_for_gtspp_quality_flag_wpres_ts", "QFQF", 2, "nlocs", [-1]])
            yamlDict.append(["global_gtspp_quality_flag_wpres_ts", "GGQF", 2, "nlocs", [-1]])
            yamlDict.append(["sea_water_temperature_ts", "SST1", 3, "nlocs", [-1]])
            yamlDict.append(["qualifier_for_gtspp_quality_flag_sst1_ts", "QFQF", 2, "nlocs", [-1]])
            yamlDict.append(["global_gtspp_quality_flag_sst1_ts", "GGQF", 2, "nlocs", [-1]])
            yamlDict.append(["salinity_ts", "SALNH", 3, ["nlocs"], [-1]])
            yamlDict.append(["qualifier_for_gtspp_quality_flag_salnh_ts", "QFQF", 2, ["nlocs"], [-1]])
            yamlDict.append(["global_gtspp_quality_flag_salnh_ts", "GGQF", 2, ["nlocs"], [-1]])

            yamlDict.append(["depth_below_sea_water_surface", "DBSS", 3, ["nlocs"], [-1]])
            yamlDict.append(["sea_temperature_at_specified_depth", "STMP", 3, ["nlocs"], [-1]])
            yamlDict.append(["salinity", "SALN", 3, ["nlocs"], [-1]])
            yamlDict.append(["direction_of_current", "DROC", 3, ["nlocs"], [-1]])
            yamlDict.append(["speed_of_current", "SPOC", 3, ["nlocs"], [-1]])

            yamlDict.append(["quips_quality_mark_for_wind_future?", "QMWN", 2, ["nlocs"], [-1]])
            yamlDict.append(["type_of_instrumentation_for_wind_measurement", "TIWM", 2, ["nlocs"], [-1]])
            yamlDict.append(["wind_direction", "WDIR", 3, ["nlocs"], [-1]])
            yamlDict.append(["wind_speed", "WSPD", 3, ["nlocs"], [-1]])

            yamlDict.append(["latitude_high_accuracy", "CLATH", 3, ["nlocs"], [-1]])
            yamlDict.append(["longitude_high_accuracy", "CLONH", 3, ["nlocs"], [-1]])

            yamlDict.append(["quips_quality_mark_for_wind_future?", "QMWN", 2, ["nlocs"], [-1]])
            yamlDict.append(["type_of_instrumentation_for_wind_measurement", "TIWM", 2, ["nlocs"], [-1]])
            yamlDict.append(["wind_direction", "WDIR", 3, ["nlocs"], [-1]])
            yamlDict.append(["wind_speed", "WSPD", 3, ["nlocs"], [-1]])

            yamlDict.append(["maximum_wind_speed_gusts", "MXGS", 3, ["nlocs"], [-1]])

            yamlDict.append(["quips_quality_mark_for_temperature_future?", "QMAT", 2, ["nlocs"], [-1]])
            yamlDict.append(["temperature_dry_bulb_temperature", "TMDB", 3,["nlocs"], [-1]])

            yamlDict.append(["ship_call_sign_8_characters", "SHPC8", 1, ["nlocs", "nstring"], [-1, 20]])

            yamlDict.append(["buoy_platform_identifier", "BPID", 3, ["nlocs"], [-1]])

            yamlDict.append(["stationary_buoy_platform_id", "SBPI", 1, ["nlocs", "nstring"], [-1, 20]])


            write_yaml(yamlDict, Lexicon)
            self.seq_spec = [seqspec[x:x+1] for x in range(0, len(seqspec))]

            self.nrecs = 1  # place holder

        # Set the dimension specs.
        super(NC031001ProfileType, self).init_dim_spec()

        return


class NC031002ProfileType(ObsType):

    def __init__(self, bf_type):

        super(NC031002ProfileType, self).__init__()

        alt_type = "NC031002"
        dictfile = "NC031002.dict"
        tablefile = "NC031002.tbl"

        self.bufr_ftype = bf_type
        self.multi_level = False
        # Put the time and date vars in the subclasses so that their dimensions
        # can vary ( [nlocs], [nlocs,nlevs] ).
        self.misc_spec[0].append(
            ['ObsTime@MetaData', '', cm.DTYPE_INTEGER, ['nlocs'], [self.nlocs]])
        self.misc_spec[0].append(
            ['ObsDate@MetaData', '', cm.DTYPE_INTEGER, ['nlocs'], [self.nlocs]])
        self.misc_spec[0].append(
            ['time@MetaData', '', cm.DTYPE_DOUBLE, ['nlocs'], [self.nlocs]])
        self.misc_spec[0].append(
            ['latitude@MetaData', '', cm.DTYPE_FLOAT, ['nlocs'], [self.nlocs]])
        self.misc_spec[0].append(
            ['longitude@MetaData', '', cm.DTYPE_FLOAT, ['nlocs'], [self.nlocs]])
        self.misc_spec[0].append(
            ['datetime@MetaData', '', cm.DTYPE_STRING, ['nlocs', 'nstring'], [self.nlocs, self.nstring]])
        
        if (bf_type == cm.BFILE_BUFR):
            self.mtype_re = "NC031002"  # alt_type is the BUFR mnemonic

            if os.path.isfile(dictfile):
                # i.e. 'NC001007.dict'
                full_table = read_yaml(dictfile)
                _, blist = read_table(tablefile)
            else:
                full_table, blist = read_table(
                    tablefile)  # i.e. 'NC001007.tbl'
                write_yaml(full_table, dictfile)

            spec_list = get_spec(alt_type, blist,
                                 parentsToPrune=["WNDSQ2", "RAWRPT"],
                                 leavesToPrune=[])
            #spec_list = get_int_spec(alt_type, blist)
            intspec = []
            intspecDum = []

            if not os.path.isfile(Lexicon):
                for i in spec_list[alt_type]:
                    if i in full_table:
                        intspecDum = [
                            full_table[i]['name'].replace(
                                ' ',
                                '_').replace('/', '_'),
                            i,
                            full_table[i]['dtype'],
                            full_table[i]['ddims']]
                        if intspecDum not in intspec:
                            intspec.append([full_table[i]['name'].replace(
                                ' ', '_').replace('/', '_'), i, full_table[i]['dtype'], full_table[i]['ddims']])
                    # else:
                    # TODO what to do if the spec is not in the full_table (or
                    # in this case, does not have a unit in the full_table)
                for j, dname in enumerate(intspec):
                    if len(dname[3]) == 1:
                        intspec[j].append([self.nlocs])
                    elif len(dname[3]) == 2:
                        intspec[j].append([self.nlocs, self.nstring])
                    else:
                        print('walked off the edge')

                write_yaml(intspec, Lexicon)
            else:
                intspec = read_yaml(Lexicon)

            self.nvars = 0
            for k in intspec:
                if '@ObsValue' in (" ".join(map(str, k))):
                    self.nvars += 1
            # The last mnemonic (RRSTG) corresponds to the raw data, instead
            # of -1 below, it is explicitly removed. The issue with RRSTG is
            # the Binary length of it, which makes the system to crash
            # during at BufrFloatToActual string convention. Probably, there
            # are more Mnemonics with the same problem.

            self.int_spec = [intspec[x:x + 1]
                             for x in range(0, len(intspec), 1)]
            # TODO Check not sure what the evn_ and rep_ are
            self.evn_spec = []
            
            self.rep_spec = []

            # TODO Check the intspec for "SQ" if exist, added at seq_spec
            #self.seq_spec = []
            seqspec = []
            seqspec.append(["windsq1", "WNDSQ1", 3, ["nlocs"], [-1]])
            seqspec.append(["windsq2", "WNDSQ2", 3, ["nlocs"], [-1]])
            seqspec.append(["tmpsq4", "TMPSQ4", 3, ["nlocs"], [-1]])
            seqspec.append(["dtpcm", "DTPCM", 3, ["nlocs"], [-1]])
            seqspec.append(["btocn", "BTOCN", 3, ["nlocs"], [-1]])
            seqspec.append(["ltlonh", "LTLONH", 3, ["nlocs"], [-1]])
            seqspec.append(["id1sq", "ID1SQ", 3, ["nlocs"], [-1]])
            seqspec.append(["id2sq", "ID2SQ", 3, ["nlocs"], [-1]])
            seqspec.append(["id3sq", "ID3SQ", 3, ["nlocs"], [-1]])

            yamlDict = intspec
            yamlDict.append(["depth_below_sea_water_surface", "DBSS", 3, ["nlocs"], [-1]])
            yamlDict.append(["sea_temperature_at_specified_depth", "STMP", 3, ["nlocs"], [-1]])
            yamlDict.append(["salinity", "SALN", 3, ["nlocs"], [-1]])
            yamlDict.append(["direction_of_current", "DROC", 3, ["nlocs"], [-1]])
            yamlDict.append(["speed_of_current", "SPOC", 3, ["nlocs"], [-1]])

            yamlDict.append(["quips_quality_mark_for_wind_future?", "QMWN", 2, ["nlocs"], [-1]])
            yamlDict.append(["type_of_instrumentation_for_wind_measurement", "TIWM", 2, ["nlocs"], [-1]])
            yamlDict.append(["wind_direction", "WDIR", 3, ["nlocs"], [-1]])
            yamlDict.append(["wind_speed", "WSPD", 3, ["nlocs"], [-1]])

            yamlDict.append(["maximum_wind_speed_gusts", "MXGS", 3, ["nlocs"], [-1]])

            yamlDict.append(["quips_quality_mark_for_temperature_future?", "QMAT", 2, ["nlocs"], [-1]])
            yamlDict.append(["temperature_dry_bulb_temperature", "TMDB", 3,["nlocs"], [-1]])

            yamlDict.append(["duration_and_time_of_current_measurement", "DTCC", 3, ["nlocs"], [-1]])

            yamlDict.append(["latitude_high_accuracy", "CLATH", 3, ["nlocs"], [-1]])
            yamlDict.append(["longitude_high_accuracy", "CLONH", 3, ["nlocs"], [-1]])

            yamlDict.append(["quips_quality_mark_for_wind_future?", "QMWN", 2, ["nlocs"], [-1]])
            yamlDict.append(["type_of_instrumentation_for_wind_measurement", "TIWM", 2, ["nlocs"], [-1]])
            yamlDict.append(["wind_direction", "WDIR", 3, ["nlocs"], [-1]])
            yamlDict.append(["wind_speed", "WSPD", 3, ["nlocs"], [-1]])

            yamlDict.append(["maximum_wind_speed_gusts", "MXGS", 3, ["nlocs"], [-1]])

            yamlDict.append(["quips_quality_mark_for_temperature_future?", "QMAT", 2, ["nlocs"], [-1]])
            yamlDict.append(["temperature_dry_bulb_temperature", "TMDB", 3,["nlocs"], [-1]])

            yamlDict.append(["duration_and_time_of_current_measurement", "DTCC", 3, ["nlocs"], [-1]])

            yamlDict.append(["ship_call_sign_8_characters", "SHPC8", 1, ["nlocs", "nstring"], [-1, 20]])

            yamlDict.append(["buoy_platform_identifier", "BPID", 3, ["nlocs"], [-1]])

            yamlDict.append(["stationary_buoy_platform_id", "SBPI", 1, ["nlocs", "nstring"], [-1, 20]])


            write_yaml(yamlDict, Lexicon)
            self.seq_spec = [seqspec[x:x+1] for x in range(0, len(seqspec))]

            self.nrecs = 1  # place holder

        # Set the dimension specs.
        super(NC031002ProfileType, self).init_dim_spec()

        return


class NC031003ProfileType(ObsType):

    def __init__(self, bf_type):

        super(NC031003ProfileType, self).__init__()

        alt_type = "NC031003"
        dictfile = "NC031003.dict"
        tablefile = "NC031003.tbl"

        self.bufr_ftype = bf_type
        self.multi_level = False
        # Put the time and date vars in the subclasses so that their dimensions
        # can vary ( [nlocs], [nlocs,nlevs] ).
        self.misc_spec[0].append(
            ['ObsTime@MetaData', '', cm.DTYPE_INTEGER, ['nlocs'], [self.nlocs]])
        self.misc_spec[0].append(
            ['ObsDate@MetaData', '', cm.DTYPE_INTEGER, ['nlocs'], [self.nlocs]])
        self.misc_spec[0].append(
            ['time@MetaData', '', cm.DTYPE_DOUBLE, ['nlocs'], [self.nlocs]])
        self.misc_spec[0].append(
            ['latitude@MetaData', '', cm.DTYPE_FLOAT, ['nlocs'], [self.nlocs]])
        self.misc_spec[0].append(
            ['longitude@MetaData', '', cm.DTYPE_FLOAT, ['nlocs'], [self.nlocs]])
        self.misc_spec[0].append(
            ['datetime@MetaData', '', cm.DTYPE_STRING, ['nlocs', 'nstring'], [self.nlocs, self.nstring]])
        
        if (bf_type == cm.BFILE_BUFR):
            self.mtype_re = "NC031003"  # alt_type is the BUFR mnemonic

            if os.path.isfile(dictfile):
                # i.e. 'NC001007.dict'
                full_table = read_yaml(dictfile)
                _, blist = read_table(tablefile)
            else:
                full_table, blist = read_table(
                    tablefile)  # i.e. 'NC001007.tbl'
                write_yaml(full_table, dictfile)

            spec_list = get_spec(alt_type, blist,
                                 parentsToPrune=["RAWRPT"],
                                 leavesToPrune=[])
            #spec_list = get_int_spec(alt_type, blist)
            intspec = []
            intspecDum = []

            if not os.path.isfile(Lexicon):
                for i in spec_list[alt_type]:
                    if i in full_table:
                        intspecDum = [
                            full_table[i]['name'].replace(
                                ' ',
                                '_').replace('/', '_'),
                            i,
                            full_table[i]['dtype'],
                            full_table[i]['ddims']]
                        if intspecDum not in intspec:
                            intspec.append([full_table[i]['name'].replace(
                                ' ', '_').replace('/', '_'), i, full_table[i]['dtype'], full_table[i]['ddims']])
                    # else:
                    # TODO what to do if the spec is not in the full_table (or
                    # in this case, does not have a unit in the full_table)
                for j, dname in enumerate(intspec):
                    if len(dname[3]) == 1:
                        intspec[j].append([self.nlocs])
                    elif len(dname[3]) == 2:
                        intspec[j].append([self.nlocs, self.nstring])
                    else:
                        print('walked off the edge')

                write_yaml(intspec, Lexicon)
            else:
                intspec = read_yaml(Lexicon)

            self.nvars = 0
            for k in intspec:
                if '@ObsValue' in (" ".join(map(str, k))):
                    self.nvars += 1
            # The last mnemonic (RRSTG) corresponds to the raw data, instead
            # of -1 below, it is explicitly removed. The issue with RRSTG is
            # the Binary length of it, which makes the system to crash
            # during at BufrFloatToActual string convention. Probably, there
            # are more Mnemonics with the same problem.

            self.int_spec = [intspec[x:x + 1]
                             for x in range(0, len(intspec), 1)]
            # TODO Check not sure what the evn_ and rep_ are
            self.evn_spec = []

            
            self.rep_spec = []

            # TODO Check the intspec for "SQ" if exist, added at seq_spec
            #self.seq_spec = []
            seqspec = []
            seqspec.append(["avgpdg", "AVGPDG", 3, ["nlocs"], [-1]])
            seqspec.append(["btocn", "BTOCN", 3, ["nlocs"], [-1]])

            yamlDict = intspec
            yamlDict.append(["depth_below_sea_water_surface", "DBSS", 3, ["nlocs"], [-1]])
            yamlDict.append(["sea_temperature_at_specified_depth", "STMP", 3, ["nlocs"], [-1]])
            yamlDict.append(["salinity", "SALN", 3, ["nlocs"], [-1]])
            yamlDict.append(["direction_of_current", "DROC", 3, ["nlocs"], [-1]])
            yamlDict.append(["speed_of_current", "SPOC", 3, ["nlocs"], [-1]])

            yamlDict.append(["averaging_periods_for_trackob_parameters", "AVGPER", 2, ["nlocs"], [-1]])

            write_yaml(yamlDict, Lexicon)
            self.seq_spec = [seqspec[x:x+1] for x in range(0, len(seqspec))]

            self.nrecs = 1  # place holder

        # Set the dimension specs.
        super(NC031003ProfileType, self).init_dim_spec()

        return


class NC031005ProfileType(ObsType):

    def __init__(self, bf_type):

        super(NC031005ProfileType, self).__init__()

        alt_type = "NC031005"
        dictfile = "NC031005.dict"
        tablefile = "NC031005.tbl"

        self.bufr_ftype = bf_type
        self.multi_level = False
        # Put the time and date vars in the subclasses so that their dimensions
        # can vary ( [nlocs], [nlocs,nlevs] ).
        self.misc_spec[0].append(
            ['ObsTime@MetaData', '', cm.DTYPE_INTEGER, ['nlocs'], [self.nlocs]])
        self.misc_spec[0].append(
            ['ObsDate@MetaData', '', cm.DTYPE_INTEGER, ['nlocs'], [self.nlocs]])
        self.misc_spec[0].append(
            ['time@MetaData', '', cm.DTYPE_DOUBLE, ['nlocs'], [self.nlocs]])
        self.misc_spec[0].append(
            ['latitude@MetaData', '', cm.DTYPE_FLOAT, ['nlocs'], [self.nlocs]])
        self.misc_spec[0].append(
            ['longitude@MetaData', '', cm.DTYPE_FLOAT, ['nlocs'], [self.nlocs]])
        self.misc_spec[0].append(
            ['datetime@MetaData', '', cm.DTYPE_STRING, ['nlocs', 'nstring'], [self.nlocs, self.nstring]])
        
        if (bf_type == cm.BFILE_BUFR):
            self.mtype_re = "NC031005"  # alt_type is the BUFR mnemonic

            if os.path.isfile(dictfile):
                # i.e. 'NC001007.dict'
                full_table = read_yaml(dictfile)
                _, blist = read_table(tablefile)
            else:
                full_table, blist = read_table(
                    tablefile)  # i.e. 'NC001007.tbl'
                write_yaml(full_table, dictfile)

            spec_list = get_spec(alt_type, blist,
                                 parentsToPrune=["RAWRPT"],
                                 leavesToPrune=[["QFQF", "NC031005"],
                                                ["GGQF", "NC031005"],
                                                ["QFQF", "DOXYPFSQ"],
                                                ["GGQF", "DOXYPFSQ"],
                                                ["QFQF", "GLPFDATA"],
                                                ["GGQF", "GLPFDATA"]])
            #spec_list = get_int_spec(alt_type, blist)
            intspec = []
            intspecDum = []

            if not os.path.isfile(Lexicon):
                for i in spec_list[alt_type]:
                    if i in full_table:
                        intspecDum = [
                            full_table[i]['name'].replace(
                                ' ',
                                '_').replace('/', '_'),
                            i,
                            full_table[i]['dtype'],
                            full_table[i]['ddims']]
                        if intspecDum not in intspec:
                            intspec.append([full_table[i]['name'].replace(
                                ' ', '_').replace('/', '_'), i, full_table[i]['dtype'], full_table[i]['ddims']])
                    # else:
                    # TODO what to do if the spec is not in the full_table (or
                    # in this case, does not have a unit in the full_table)
                for j, dname in enumerate(intspec):
                    if len(dname[3]) == 1:
                        intspec[j].append([self.nlocs])
                    elif len(dname[3]) == 2:
                        intspec[j].append([self.nlocs, self.nstring])
                    else:
                        print('walked off the edge')

                write_yaml(intspec, Lexicon)
            else:
                intspec = read_yaml(Lexicon)

            self.nvars = 0
            for k in intspec:
                if '@ObsValue' in (" ".join(map(str, k))):
                    self.nvars += 1
            # The last mnemonic (RRSTG) corresponds to the raw data, instead
            # of -1 below, it is explicitly removed. The issue with RRSTG is
            # the Binary length of it, which makes the system to crash
            # during at BufrFloatToActual string convention. Probably, there
            # are more Mnemonics with the same problem.

            self.int_spec = [intspec[x:x + 1]
                             for x in range(0, len(intspec), 1)]
            # TODO Check not sure what the evn_ and rep_ are
            self.evn_spec = []

            
            self.rep_spec = []

            # TODO Check the intspec for "SQ" if exist, added at seq_spec
            #self.seq_spec = []
            seqspec = []
            seqspec.append(["doxypfsq", "DOXYPFSQ", 3, ["nlocs"], [-1]])
            seqspec.append(["glpfdata", "GLPFDATA", 3, ["nlocs"], [-1]])

            yamlDict = intspec
            yamlDict.append(["indicator_for_digitization_oxy", "IDGT", 2, ["nlocs"], [-1]])
            yamlDict.append(["instrument_type_sensor_for_dissolved_oxygen_measurement", "SDOM", 2, ["nlocs"], [-1]])
            yamlDict.append(["method_of_depth_calculation_oxy", "MDCL", 2, ["nlocs"], [-1]])

            yamlDict.append(["depth_below_sea_water_surface_oxy", "DBSS", 3, ["nlocs"], [-1]])
            yamlDict.append(["qualifier_for_gtspp_quality_flag_dbss_oxy", "QFQF", 2, ["nlocs"], [-1]])
            yamlDict.append(["global_gtspp_quality_flag_dbss_oxy", "GGQF", 2, ["nlocs"], [-1]])
            yamlDict.append(["water_pressure_oxy", "WPRES", 3, ["nlocs"], [-1]])
            yamlDict.append(["qualifier_for_gtspp_quality_flag_wpres_oxy", "QFQF", 2, ["nlocs"], [-1]])
            yamlDict.append(["global_gtspp_quality_flag_wpres_oxy", "GGQF", 2, ["nlocs"], [-1]])
            yamlDict.append(["dissolved_oxygen", "DOXY", 3, ["nlocs"], [-1]])
            yamlDict.append(["qualifier_for_gtspp_quality_flag_doxy_oxy", "QFQF", 2, ["nlocs"], [-1]])
            yamlDict.append(["global_gtspp_quality_flag_doxy_oxy", "GGQF", 2, ["nlocs"], [-1]])

            yamlDict.append(["water_pressure_gldr", "WPRES", 3, ["nlocs"], [-1]])
            yamlDict.append(["qualifier_for_gtspp_quality_flag_wpres_gldr", "QFQF", 2, ["nlocs"], [-1]])
            yamlDict.append(["global_gtspp_quality_flag_wpres_gldr", "GGQF", 2, ["nlocs"], [-1]])
            yamlDict.append(["sea_water_temperature_gldr", "SSTH", 3, ["nlocs"], [-1]])
            yamlDict.append(["qualifier_for_gtspp_quality_flag_ssth_gldr", "QFQF", 2, ["nlocs"], [-1]])
            yamlDict.append(["global_gtspp_quality_flag_ssth_gldr", "GGQF", 2, ["nlocs"], [-1]])
            yamlDict.append(["salinity_gldr", "SALNH", 3, ["nlocs"], [-1]])
            yamlDict.append(["qualifier_for_gtspp_quality_flag_salnh_gldr", "QFQF", 2, ["nlocs"], [-1]])
            yamlDict.append(["global_gtspp_quality_flag_salnh_gldr", "GGQF", 2, ["nlocs"], [-1]])

            write_yaml(yamlDict, Lexicon)
            self.seq_spec = [seqspec[x:x+1] for x in range(0, len(seqspec))]

            self.nrecs = 1  # place holder

        # Set the dimension specs.
        super(NC031005ProfileType, self).init_dim_spec()

        return


class NC031006ProfileType(ObsType):

    def __init__(self, bf_type):

        super(NC031006ProfileType, self).__init__()

        alt_type = "NC031006"
        dictfile = "NC031006.dict"
        tablefile = "NC031006.tbl"

        self.bufr_ftype = bf_type
        self.multi_level = False
        # Put the time and date vars in the subclasses so that their dimensions
        # can vary ( [nlocs], [nlocs,nlevs] ).
        self.misc_spec[0].append(
            ['ObsTime@MetaData', '', cm.DTYPE_INTEGER, ['nlocs'], [self.nlocs]])
        self.misc_spec[0].append(
            ['ObsDate@MetaData', '', cm.DTYPE_INTEGER, ['nlocs'], [self.nlocs]])
        self.misc_spec[0].append(
            ['time@MetaData', '', cm.DTYPE_DOUBLE, ['nlocs'], [self.nlocs]])
        self.misc_spec[0].append(
            ['latitude@MetaData', '', cm.DTYPE_FLOAT, ['nlocs'], [self.nlocs]])
        self.misc_spec[0].append(
            ['longitude@MetaData', '', cm.DTYPE_FLOAT, ['nlocs'], [self.nlocs]])
        self.misc_spec[0].append(
            ['datetime@MetaData', '', cm.DTYPE_STRING, ['nlocs', 'nstring'], [self.nlocs, self.nstring]])

        if (bf_type == cm.BFILE_BUFR):
            self.mtype_re = "NC031006"  # alt_type is the BUFR mnemonic

            if os.path.isfile(dictfile):
                # i.e. 'NC001007.dict'
                full_table = read_yaml(dictfile)
                _, blist = read_table(tablefile)
            else:
                full_table, blist = read_table(
                    tablefile)  # i.e. 'NC001007.tbl'
                write_yaml(full_table, dictfile)

            spec_list = get_spec(alt_type, blist, \
                                 parentsToPrune=[],
                                 leavesToPrune=[["RRSTG", "RAWRPT"]])
            #spec_list = get_int_spec(alt_type, blist)
            intspec = []
            intspecDum = []

            if not os.path.isfile(Lexicon):
                for i in spec_list[alt_type]:
                    if i in full_table:
                        intspecDum = [
                            full_table[i]['name'].replace(
                                ' ',
                                '_').replace('/', '_'),
                            i,
                            full_table[i]['dtype'],
                            full_table[i]['ddims']]
                        if intspecDum not in intspec:
                            intspec.append([full_table[i]['name'].replace(
                                ' ', '_').replace('/', '_'), i, full_table[i]['dtype'], full_table[i]['ddims']])
                    # else:
                    # TODO what to do if the spec is not in the full_table (or
                    # in this case, does not have a unit in the full_table)
                for j, dname in enumerate(intspec):
                    if len(dname[3]) == 1:
                        intspec[j].append([self.nlocs])
                    elif len(dname[3]) == 2:
                        intspec[j].append([self.nlocs, self.nstring])
                    else:
                        print('walked off the edge')

                write_yaml(intspec, Lexicon)
            else:
                intspec = read_yaml(Lexicon)

            self.nvars = 0
            for k in intspec:
                if '@ObsValue' in (" ".join(map(str, k))):
                    self.nvars += 1
            # The last mnemonic (RRSTG) corresponds to the raw data, instead
            # of -1 below, it is explicitly removed. The issue with RRSTG is
            # the Binary length of it, which makes the system to crash
            # during at BufrFloatToActual string convention. Probably, there
            # are more Mnemonics with the same problem.

            self.int_spec = [intspec[x:x + 1]
                             for x in range(0, len(intspec), 1)]
            # TODO Check not sure what the evn_ and rep_ are
            self.evn_spec = []

            
            self.rep_spec = []

            # TODO Check the intspec for "SQ" if exist, added at seq_spec
            #self.seq_spec = []
            seqspec = []
            seqspec.append(["bsywnd2", "BSYWND2", 3, ["nlocs"], [-1]])
            seqspec.append(["pressq03", "PRESSQ03", 3, ["nlocs"], [-1]])
            seqspec.append(["tmslpfsq", "TMSLPFSQ", 3, ["nlocs"], [-1]])
            seqspec.append(["doxypfdt", "DOXYPFDT", 3, ["nlocs"], [-1]])
            seqspec.append(["doxypfsq", "DOXYPFSQ", 3, ["nlocs"], [-1]])
            seqspec.append(["currpfdt", "CURRPFDT", 3, ["nlocs"], [-1]])
            seqspec.append(["currpfsq", "CURRPFSQ", 3, ["nlocs"], [-1]])

            yamlDict = intspec
            yamlDict.append(["depth_below_sea_water_surface_ts", "DBSS", 3, "nlocs", [-1]])
            yamlDict.append(["qualifier_for_gtspp_quality_flag_dbss_ts", "QFQF", 2, "nlocs", [-1]])
            yamlDict.append(["global_gtspp_quality_flag_dbss_ts", "GGQF", 2, "nlocs", [-1]])
            yamlDict.append(["water_pressure_ts", "WPRES", 3, "nlocs", [-1]])
            yamlDict.append(["qualifier_for_gtspp_quality_flag_wpres_ts", "QFQF", 2, "nlocs", [-1]])
            yamlDict.append(["global_gtspp_quality_flag_wpres_ts", "GGQF", 2, "nlocs", [-1]])
            yamlDict.append(["sea_water_temperature_ts", "SST1", 3, "nlocs", [-1]])
            yamlDict.append(["qualifier_for_gtspp_quality_flag_sst1_ts", "QFQF", 2, "nlocs", [-1]])
            yamlDict.append(["global_gtspp_quality_flag_sst1_ts", "GGQF", 2, "nlocs", [-1]])
            yamlDict.append(["salinity_ts", "SALNH", 3, ["nlocs"], [-1]])
            yamlDict.append(["qualifier_for_gtspp_quality_flag_salnh_ts", "QFQF", 2, ["nlocs"], [-1]])
            yamlDict.append(["global_gtspp_quality_flag_salnh_ts", "GGQF", 2, ["nlocs"], [-1]])

            yamlDict.append(["indicator_for_digitization_oxy", "IDGT", 2, ["nlocs"], [-1]])
            yamlDict.append(["instrument_type_sensor_for_dissolved_oxygen_measurement", "SDOM", 2, ["nlocs"], [-1]])
            yamlDict.append(["method_of_depth_calculation_oxy", "MDCL", 2, ["nlocs"], [-1]])

            yamlDict.append(["depth_below_sea_water_surface_oxy", "DBSS", 3, ["nlocs"], [-1]])
            yamlDict.append(["qualifier_for_gtspp_quality_flag_dbss_oxy", "QFQF", 2, ["nlocs"], [-1]])
            yamlDict.append(["global_gtspp_quality_flag_dbss_oxy", "GGQF", 2, ["nlocs"], [-1]])
            yamlDict.append(["water_pressure_oxy", "WPRES", 3, ["nlocs"], [-1]])
            yamlDict.append(["qualifier_for_gtspp_quality_flag_wpres_oxy", "QFQF", 2, ["nlocs"], [-1]])
            yamlDict.append(["global_gtspp_quality_flag_wpres_oxy", "GGQF", 2, ["nlocs"], [-1]])
            yamlDict.append(["dissolved_oxygen", "DOXY", 3, ["nlocs"], [-1]])
            yamlDict.append(["qualifier_for_gtspp_quality_flag_doxy_oxy", "QFQF", 2, ["nlocs"], [-1]])
            yamlDict.append(["global_gtspp_quality_flag_doxy_oxy", "GGQF", 2, ["nlocs"], [-1]])

            yamlDict.append(["indicator_for_digitization_oc", "IDGT", 2, ["nlocs"], [-1]])
            yamlDict.append(["method_of_sea_water_current_measurement_oc", "MSCM", 3, ["nlocs"], [-1]])
            yamlDict.append(["duration_and_time_of_current_measurement_oc", "DTCC", 3, ["nlocs"], [-1]])
            yamlDict.append(["meth_of_rmv_velocity_and_motion_of_platform_from_curren_oc", "MRMV", 2, ["nlocs"], [-1]])
            yamlDict.append(["direction_of_profile_oc", "DIPR", 3, ["nlocs"], [-1]])
            yamlDict.append(["method_of_depth_calculation_oc", "MDCL", 2, ["nlocs"], [-1]])

            yamlDict.append(["depth_below_sea_water_surface_oc", "DBSS", 3, ["nlocs"], [-1]])
            yamlDict.append(["qualifier_for_gtspp_quality_flag_dbss_oc", "QFQF", 2, ["nlocs"], [-1]])
            yamlDict.append(["global_gtspp_quality_flag_dbss_oc", "GGQF", 2, ["nlocs"], [-1]])
            yamlDict.append(["water_pressure_oc", "WPRES", 3, ["nlocs"], [-1]])
            yamlDict.append(["qualifier_for_gtspp_quality_flag_wpres_oc", "QFQF", 2, ["nlocs"], [-1]])
            yamlDict.append(["global_gtspp_quality_flag_wpres_oc", "GGQF", 2, ["nlocs"], [-1]])
            yamlDict.append(["speed_of_current", "SPOC", 3, ["nlocs"], [-1]])
            yamlDict.append(["qualifier_for_gtspp_quality_flag_spoc_oc", "QFQF", 2, ["nlocs"], [-1]])
            yamlDict.append(["global_gtspp_quality_flag_spoc_oc", "GGQF", 2, ["nlocs"], [-1]])
            yamlDict.append(["direction_of_current", "DROC", 3, ["nlocs"], [-1]])
            yamlDict.append(["qualifier_for_gtspp_quality_flag_droc_oc", "QFQF", 2, ["nlocs"], [-1]])
            yamlDict.append(["global_gtspp_quality_flag_droc_oc", "GGQF", 2, ["nlocs"], [-1]])

            yamlDict.append(["height_of_sensor_above_local_ground_or_deck_or_marine_shp", "HSALG", 3, ["nlocs"], [-1]])
            yamlDict.append(["height_of_sensor_above_water_surface_shp", "HSAWS", 3, ["nlocs"], [-1]])
            yamlDict.append(["temperature_dry_bulb_temperature_shp", "TMDB", 3, ["nlocs"], [-1]])
            yamlDict.append(["method_of_web_bulb_temperature_measurement_shp", "MWBT", 2
                             , ["nlocs"], [-1]])
            yamlDict.append(["wet_bulb_temperature_shp", "TMWB", 3, ["nlocs"], [-1]])
            yamlDict.append(["dewpoint_temperature_shp", "TMDP", 3, ["nlocs"], [-1]])
            yamlDict.append(["relative_humidity_shp", "REHU", 3, ["nlocs"], [-1]])

            yamlDict.append(["maximum_wind_gust_direction", "MXGD", 3, ["nlocs"], [-1]])
            yamlDict.append(["maximum_wind_speed_gusts", "MXGS", 3, ["nlocs"], [-1]])

            yamlDict.append(["pressure", "PRES", 3, ["nlocs"], [-1]])
            yamlDict.append(["pressure_reduced_to_mean_sea_level", "PMSL", 3, ["nlocs"], [-1]])
            yamlDict.append(["3hour_pressure_change", "3HPC", 3, ["nlocs"], [-1]])
            yamlDict.append(["characteristic_of_pressure_tendency", "CHPT", 1, ["nlocs", "nstring"], [-1,20]])

            write_yaml(yamlDict, Lexicon)
            self.seq_spec = [seqspec[x:x+1] for x in range(0, len(seqspec))]

            self.nrecs = 1  # place holder

        # Set the dimension specs.
        super(NC031006ProfileType, self).init_dim_spec()

        return


##########################################################################
# read bufr table and return new table with bufr names and units
##########################################################################


def write_yaml(dictionary, dictfileName):
    f = open(dictfileName, 'w')
    yaml.dump(dictionary, f)
    f.close()


def read_yaml(dictfileName):
    f = open(dictfileName, 'r')
    dictionary = yaml.safe_load(f)
    f.close()

    return dictionary


def read_table(filename):
    all = []
    with open(filename) as f:
        for line in f:
            if line[:11] != '|' + '-' * 10 + '|' \
                    and line[:11] != '|' + ' ' * 10 + '|' \
                    and line.find('-' * 20) == -1:
                all.append(line)

    all = all[1:]
    stops = []
    for ndx, line in enumerate(all[1:]):
        if line.find('MNEMONIC') != -1:
            stops.append(ndx)

    part_a = all[2:stops[0]]
    part_b = all[stops[0] + 3:stops[1]]
    part_c = all[stops[1] + 3:]
    dum = []
    for x in part_a:
        dum.append(
            ' '.join(
                x.replace(
                    "(",
                    "").replace(
                    ")",
                    "").replace(
                    "-",
                    "").split()))

    part_a = dum

    tbl_a = {line.split('|')[1].strip(): line.split(
        '|')[3].strip().lower() for line in part_a}
    tbl_c = {line.split('|')[1].strip(): line.split(
        '|')[5].strip().lower() for line in part_c}

    full_table = {i: {'name': tbl_a[i], 'units': tbl_c[i]}
                  for i in tbl_c.keys()}

# TODO Double check the declarations below.
    # DTYPE_INTEGER
    integer_types = [
        'CODE TABLE',
        'FLAG TABLE',
        'YEAR',
        'MONTH',
        'DAY',
        'MINUTE',
        'MINUTES',
        'PASCALS']
    # DTYPE_FLOAT
    float_types = [
        'SECOND',
        'NUMERIC',
        'DEGREES',
        'METERS',
        'METERS/SECOND',
        'M',
        'DECIBELS',
        'HZ',
        'DB',
        'K',
        'KG/M**2',
        'M/S',
        'DEGREE**2',
        'M**2',
        'DEGREES TRUE',
        'PERCENT',
        '%',
        'KG/METER**2',
        'SIEMENS/M',
        'METERS**3/SECOND',
        'JOULE/METER**2',
        'PART PER THOUSAND',
        'PARTS/1000',
        'METERS**2/HZ',
        'S',
        'METERS**2/SECOND',
        'VOLTS',
        'V',
        'DEGREE TRUE',
        'DEGREES KELVIN',
        'HERTZ',
        'HOURS',
        'HOUR',
        'METER/SECOND',
        'DEGREE',
        'SECONDS']
    # DTYPE_STRING
    string_types = ['CCITT IA5']

    string_dims = ['nlocs', 'nstring']
    nums_dims = ['nlocs']

    for key, item in full_table.items():
        if item['units'].upper() in integer_types:
            full_table[key]['dtype'] = cm.DTYPE_INTEGER
            full_table[key]['ddims'] = nums_dims
        elif item['units'].upper() in float_types:
            full_table[key]['dtype'] = cm.DTYPE_FLOAT
            full_table[key]['ddims'] = nums_dims
        elif item['units'].upper() in string_types:
            full_table[key]['dtype'] = cm.DTYPE_STRING
            full_table[key]['ddims'] = string_dims
        else:
            full_table[key]['dtype'] = cm.DTYPE_UNDEF
            full_table[key]['ddims'] = nums_dims
    return full_table, part_b


def get_spec(mnemonic, part_b, parentsToPrune=[], leavesToPrune=[]):
    """ returns a list of the mnemonics that can be extracted from a BUFR
        file for a specific observation type

        Input:
            obsType - observation type (e.g., "NC031001") or parent key
            section2 - dictionary containing Section 2 from a .tbl file

        Return:
            list of mnemonics that will be output
    """

    # need to create a root node for a tree
    treeTop = Mnemonic(mnemonic, False, None)

    buildMnemonicTree(treeTop, part_b)
    if parentsToPrune or leavesToPrune:
        pruneTree(treeTop, parentsToPrune, leavesToPrune)
    mnemonicList = findSearchableNodes(treeTop)
    #mnemonicList = traverseTree(treeTop)

    mnemonicDict = {}
    mnemonicDict[mnemonic] = [x.name for x in mnemonicList]
    return mnemonicDict


def buildMnemonicTree(root, part_b):
    """ builds a hierarchical tree for the mnemonics for a given observation 
        type

        Input:
            root - root node for segment of tree to process
            section2 - dictionary containing Section 2 from a .tbl file

        Return:
            list of mnemonics that will be output
    """

    mnemonicsForID = []
    for line in part_b:
        if re.search("^\| %s " % (root.name), line):
            segments = line.split('|')
            mnemonicsForID.extend(segments[2].split())
    for m in mnemonicsForID:
        if re.search("\{|\(|\<", m):
            m = m[1:-1]
            seq = True
        elif m[0] == '"':
            m = m[1:-2]
            seq = True
        else:
            seq = False

        node = Mnemonic(m, seq, root)

        isKey = False
        for line in part_b:
            if re.search("^\| %s " % (m), line):
                isKey = True
                break
        if isKey:
            # if m is a key then it is a parent, so get its members
            root.children.append(node)
            buildMnemonicTree(node, part_b)
        else:
            # not a parent, so it is a field name.
            root.children.append(node)

    return 


def findSearchableNodes(root):
    """ finds the nodes that reference a mnemonic that can be retrieved
        from a BUFR file. These nodes are the leaves except when a node
        that is a sequence is a parent of 1 or more leaves.

        Input:
            root - the root node of the tree to search

        Return:
            a list of nodes that reference mnemonics that can be retrieved
            from a BUFR file
    """

    nodeList = []

    if len(root.children) > 0:
        # root is not a leaf so visit its children
        for node in root.children:
            nodeList.extend(findSearchableNodes(node))
    else:
        # a leaf, so it is added to the list unless its parent is a sequence,
        # in which case its parent is added
        if root.parent.seq:
            nodeList.append(root.parent)
        else:
            nodeList.append(root)

    # remove duplicates
    nodeList = [x for i,x in enumerate(nodeList) if x not in nodeList[:i]]

    return nodeList


def traverseTree(root):

    nodeList = []

    if len(root.children) > 0:
        for node in root.children:
            nodeList.extend(traverseTree(node))
    else:
        nodeList.append(root)

    return nodeList


def pruneTree(root, parentsToPrune, leavesToPrune):

    pruned = False
    if root.name in parentsToPrune:
        # if root is a sequence, prune its children
        idx = 0
        while idx < len(root.children):
            if root.children[idx].seq:
                # if the child is a sequence, add it to the list of
                # parents to prune
                pruned = pruneTree(root.children[idx], 
                                   [x for x in parentsToPrune or
                                    x in root.children[idx].name],
                                   leavesToPrune)
            else:
                # the child is not a sequence, add it to the list of
                # leaves to prune
                #print([x.name for x in root.children])
                if leavesToPrune:
                    pruned = pruneTree(root.children[idx], parentsToPrune,
                                       [x for x in leavesToPrune or
                                        x in [root.children[idx].name,
                                              root.name]])
                else:
                    pruned = pruneTree(root.children[idx], parentsToPrune,
                                       [root.children[idx].name, root.name])
            if not pruned:
                idx += 1
        root.parent.children.remove(root)
        pruned = True
    elif root.parent and (root.name, root.parent.name) in \
         [(x[0], x[1]) for x in leavesToPrune]:
        # first clause handles when root is the root of the entire tree
        root.parent.children.remove(root)
        pruned = True
    else:
        # root is not a node that is to be pruned, but if it has children
        # then process the children
        idx = 0
        while idx < len(root.children):
            pruned = pruneTree(root.children[idx], parentsToPrune,
                                   leavesToPrune)
            if not pruned:
                idx += 1

    return pruned


##########################################################################
# get the int_spec entries from satellite table
##########################################################################


def get_int_spec(mnemonic, part_b):
    # mnemonic is the BUFR msg_type, i.e. 'NC001007'
    # part_b from the read_table, table entries associated with the mnemonic
    #
    # find the table entries for the bufr msg_type (mnemonic):
    bentries = {}
    for line in part_b:
        line = line.replace(
            '{',
            '').replace(
            '}',
            '').replace(
            '<',
            '').replace(
                '>',
            '')
        if line.find(mnemonic) != -1:
            if mnemonic in bentries:
                bentries[mnemonic] = bentries[mnemonic] + \
                    ''.join(line.split('|')[2:]).strip().split()
            else:
                bentries[mnemonic] = ''.join(
                    line.split('|')[2:]).strip().split()
                # bentries is a dictionary for the mnemonic

    for b_monic in bentries[mnemonic]:
        for line in part_b:
            line = line.replace(
                '{',
                '').replace(
                '}',
                '').replace(
                '<',
                '').replace(
                '>',
                '')
            if line.split('|')[1].find(b_monic) != -1:
                bentries[mnemonic] = bentries[mnemonic] + \
                    ''.join(line.split('|')[2:]).strip().split()
    for c_monic in bentries[mnemonic]:
        for line in part_b:
            line = line.replace(
                '{',
                '').replace(
                '}',
                '').replace(
                '<',
                '').replace(
                '>',
                '')
            if line.split('|')[1].find(c_monic) != -1:
                bentries[mnemonic] = bentries[mnemonic] + \
                    ''.join(line.split('|')[2:]).strip().split()

    for d_monic in bentries[mnemonic]:
        for line in part_b:
            line = line.replace(
                '{',
                '').replace(
                '}',
                '').replace(
                '<',
                '').replace(
                '>',
                '')
            if line.split('|')[1].find(d_monic) != -1:
                bentries[mnemonic] = bentries[mnemonic] + \
                    ''.join(line.split('|')[2:]).strip().split()
    return bentries


##########################################################################
# get the rep_spec entries from satellite table
##########################################################################


def get_rep_spec(mnemonic, part_b):
    # mnemonic is the BUFR msg_type, i.e. 'NC001007'
    # part_b from the read_table, table entries associated with the mnemonic
    #
    # find the table entries for the bufr msg_type (mnemonic):
    bentries = {}
    for line in part_b:
        #line = line.replace(
            #'(',
            #'').replace(
            #')',
            #'')
        if line.find(mnemonic) != -1:
            if mnemonic in bentries:
                bentries[mnemonic] = bentries[mnemonic] + \
                    ''.join(line.split('|')[2:]).strip().split()
            else:
                bentries[mnemonic] = ''.join(
                    line.split('|')[2:]).strip().split()
                # bentries is a dictionary for the mnemonic
    #bentries[mnemonic] = [x[1:-1] for x in bentries[mnemonic] if '(' in x]

    for b_monic in bentries[mnemonic]:
        for line in part_b:
            line = line.replace(
                '(',
                '').replace(
                ')',
                '')
            if line.split('|')[1].find(b_monic) != -1:
                bentries[mnemonic] = bentries[mnemonic] + \
                    ''.join(line.split('|')[2:]).strip().split()
    #for c_monic in bentries[mnemonic]:
        #for line in part_b:
            #line = line.replace('(', '').replace(')', '')
            #if line.split('|')[1].find(c_monic) != -1:
                #bentries[mnemonic] = bentries[mnemonic] + \
                    #''.join(line.split('|')[2:]).strip().split()

    #for d_monic in bentries[mnemonic]:
        #for line in part_b:
            #line = line.replace('(', '').replace(')', '')
            #if line.split('|')[1].find(d_monic) != -1:
                #bentries[mnemonic] = bentries[mnemonic] + \
                    #''.join(line.split('|')[2:]).strip().split()
    return bentries

def get_seq_spec(mnemonic, part_b):
    # mnemonic is the BUFR msg_type, i.e. 'NC001007'
    # part_b from the read_table, table entries associated with the mnemonic
    #
    # find the table entries for the bufr msg_type (mnemonic):
    bentries = {}
    for line in part_b:
        #line = line.replace(
            #'(',
            #'').replace(
            #')',
            #'')
        if line.find(mnemonic) != -1:
            if mnemonic in bentries:
                bentries[mnemonic] = bentries[mnemonic] + \
                    ''.join(line.split('|')[2:]).strip().split()
            else:
                bentries[mnemonic] = ''.join(
                    line.split('|')[2:]).strip().split()
                # bentries is a dictionary for the mnemonic
    bentries[mnemonic] = [x[1:-1] for x in bentries[mnemonic] if '(' in x]

    for b_monic in bentries[mnemonic]:
        for line in part_b:
            line = line.replace(
                '(',
                '').replace(
                ')',
                '')
            if line.split('|')[1].find(b_monic) != -1:
                bentries[mnemonic] = bentries[mnemonic] + \
                    ''.join(line.split('|')[2:]).strip().split()
    #for c_monic in bentries[mnemonic]:
        #for line in part_b:
            #line = line.replace('(', '').replace(')', '')
            #if line.split('|')[1].find(c_monic) != -1:
                #bentries[mnemonic] = bentries[mnemonic] + \
                    #''.join(line.split('|')[2:]).strip().split()

    #for d_monic in bentries[mnemonic]:
        #for line in part_b:
            #line = line.replace('(', '').replace(')', '')
            #if line.split('|')[1].find(d_monic) != -1:
                #bentries[mnemonic] = bentries[mnemonic] + \
                    #''.join(line.split('|')[2:]).strip().split()
    return bentries


##########################################################################
# function to create the full path of
##########################################################################


def get_fname(base_mnemo, BufrPath):
    BufrFname = BufrPath + BufrFname
    BufrTname = base_mnemo + '.tbl'
    NetcdfFname = 'xx' + base_mnemo[5:] + '.nc'

    return BufrFname, BufrTname, NetcdfFname


def create_bufrtable(BufrFname, ObsTable):
    bufr = ncepbufr.open(BufrFname)
    bufr.advance()
    bufr.dump_table(ObsTable)
    bufr.close()
    return

##########################################################################
# MAIN
##########################################################################


if __name__ == '__main__':

    desc = ('Read NCEP BUFR data and convert to IODA netCDF4 format'
            'example: ncep_clases -p /path/to/obs/ -i obs_filename'
            ' -ot observation type -l yamlfile')

    parser = ArgumentParser(
        description=desc,
        formatter_class=ArgumentDefaultsHelpFormatter)

    parser.add_argument(
        '-p', '--obs_path', help='path with the observations',
        type=str, required=True)

    parser.add_argument(
        '-i', '--input_bufr', help='name of the input BUFR file',
        type=str, required=True)

    parser.add_argument(
        '-ot', '--obs_type', help='Submessage of the input BUFR file, e.g., NC001007',
        type=str, required=True)

    parser.add_argument(
        '-o', '--output_netcdf', help='name of the output NC file',
        type=str, required=False, default=None)

    parser.add_argument(
        '-m', '--maxmsgs', help="maximum number of messages to keep",
        type=int, required=False, default=0, metavar="<max_num_msgs>")

    parser.add_argument(
        '-Th', '--thin', type=int, default=1,
        help="select every nth message (thinning)", metavar="<thin_interval>")

    parser.add_argument(
        '-d', '--date', help='file date', metavar='YYYYMMDDHH',
        type=str, required=True)

    parser.add_argument(
        '-l', '--lexicon', help='yaml file with the dictionary', metavar="name_of_dict",
        type=str, required=False, default=config_path + 'bufr2ioda.yaml')

    parser.add_argument(
        '-Pr', '--bufr', action='store_true', default=1,
        help='input BUFR file is in prepBUFR format')

    args = parser.parse_args()

    BufrPath = args.obs_path    # Path of the observations
    MaxNumMsg = args.maxmsgs    # Maximum number of messages to be imported
    ThinInterval = args.thin    # Thinning window. TODO: To be removed, legacy
    ObsType = args.obs_type     # Observation type. e.g., NC001007
    BufrFname = BufrPath + args.input_bufr  # path and name of BUFR name
    DateCentral = dt.strptime(args.date, '%Y%m%d%H')  # DateHH of analysis
    if (config_path + args.lexicon):
        Lexicon = config_path + args.lexicon  # Existing yaml file in config
    else:
        args.lexicon   # User defined Lexicon name

    if (args.bufr):
        BfileType = cm.BFILE_BUFR  # BUFR or prepBUFR. TODO: To be removed
    else:
        BfileType = cm.BFILE_PREPBUFR

    if (args.output_netcdf):
        NetcdfFname = args.output_netcdf   # Filename of the netcdf ioda file
    else:
        NetcdfFname = 'ioda.' + ObsType + '.' + \
            DateCentral.strftime("%Y%m%d%H") + '.nc'

    date_time = DateCentral.strftime("%Y%m%d%H")

    ObsTable = ObsType + '.tbl'       # Bufr table from the data.
    DictObs = ObsType + '.dict'      # Bufr dict

    # Check if BufrFname exists

    if os.path.isfile(BufrFname):
        bufr = ncepbufr.open(BufrFname)
        bufr.advance()
        mnemonic = bufr.msg_type
        bufr.close()
    else:
        sys.exit('The ', BufrFname, 'does not exist.')

    #  Check if Bufr Observation Table exists, if not created.
    #  The table is defined as base_mnemo.tbl, it is a text file.

    if os.path.isfile(ObsTable):
        print('ObsTable exists: ', ObsTable)
    else:
        print('ObsTable does not exist, the ', ObsTable, 'is created!')
        create_bufrtable(BufrFname, ObsTable)

    # Create the observation instance

    #Obs = MarineProfileType(BfileType, mnemonic, ObsTable, DictObs)
    if ObsType == "NC031001":
        Obs = NC031001ProfileType(BfileType)
    elif ObsType == "NC031002":
        Obs = NC031002ProfileType(BfileType)
    elif ObsType == "NC031003":
        Obs = NC031003ProfileType(BfileType)
    elif ObsType == "NC031005":
        Obs = NC031005ProfileType(BfileType)
    elif ObsType == "NC031006":
        Obs = NC031006ProfileType(BfileType)
    else:
        Obs = MarineProfileType(BfileType, ObsType, ObsType + ".tbl", 
                                ObsType + ".dict")
    NumMessages = MessageCounter(BufrFname)
    if MaxNumMsg > 0:
        Obs.max_num_msg = MaxNumMsg
    else:
        Obs.max_num_msg = NumMessages[0]
    print("NumMessages = ", NumMessages[0])

    Obs.thin_interval = ThinInterval
    Obs.date_central = DateCentral

    [NumObs, NumMsgs, TotalMsgs] = BfilePreprocess(BufrFname, Obs)
    Obs.set_nlocs(NumObs)

    nc = Dataset(NetcdfFname, 'w', format='NETCDF4')

    nc.date_time = int(date_time[0:10])

    Obs.create_nc_datasets(nc)
    Obs.fill_coords(nc)

    bufr = ncepbufr.open(BufrFname)

    Obs.convert(bufr, nc, True)
    bufr.close()
