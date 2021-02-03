#!/usr/bin/env python

import argparse
import array
import ncepbufr
import netCDF4
import numpy as np
import os
import os.path
import subprocess
import sys
import yaml

sys.path.append(os.path.dirname(sys.argv[0]))
import bufrTableTools
from BUFRMsgTypeToYAML import YAML_FILES

import random


class ValidateSatwndsConvError(Exception):
    def __init__(self, message):
        self.message \
            = f"{message}\nProgram validateSatwndsConv exiting due to fatal error\n"
        return

DATETIME_MNEMONICS = ["YEAR", "MNTH", "DAYS", "HOUR", "MINU", "SECO"]

def validateSatwndsConv(bufrFile, obsType, iodaFile, yamlDir):
    """ driver for program to compare BUFR and IODA netCDF files when
        IODA netCDF files are created for a single BUFR observation
        (subset) type. The output is written to the file
        <obsType>_valication.txt

        Input:
            bufrFile - full pathname of the BUFR file
            obsType - the BUFR observation (subset) type
            iodaFile - full pathname of the IODA netCDF file
            yamlDir - directory where the YAML file is
    """

    if not os.path.isfile(bufrFile):
        raise ValidateSatwndsConvError \
            (f"BUFR file {bufrFile} was not found")
    if not (obsType in YAML_FILES.keys()):
        raise ValidateSatwndsConvError \
            (f"Observation type doesn't map to an available YAML file name")
    if not os.path.isfile(iodaFile):
        raise ValidateSatwndsConvError \
            (f"IODA file {iodaFile} was not found")

    # Match IODA netCDF variable names with BUFR mnemonics
    (varPairs, bufrMnemonicList) = matchIodaFieldsToBufr(obsType, yamlDir)

    # Get the IODA netCDF dataset
    iodaDataset = getIodaDataset(iodaFile)

    # Perform the comparison
    msgHdr = "VERIFYING {} BY COMPARING WITH {}\n\n". \
             format(iodaFile, bufrFile)
    varMsg = compareVariables(iodaDataset, bufrFile, obsType, varPairs)
    dateTimeMsg = compareDateTime(iodaDataset, bufrFile, obsType)

    iodaDataset.close()

    # write the output to a file
    fd = open(f"{obsType}_validation.txt", 'w')
    fd.write(f"{msgHdr}\n{varMsg}\n{dateTimeMsg}\n")
    for m in bufrMnemonicList:
        if not m in varPairs.values() and not m in DATETIME_MNEMONICS:
            fd.write(f"BUFR mnemonic {m} not written to IODA file\n")
    fd.close()

    return


def getIodaDataset(iodaFile):
    """ opens the IODA netCDF file

        Input:
            iodaFile - full pathname of the IODA netCDF file

        Return:
            netCDF dataset or None if the file was not found
    """

    if not os.path.isfile(iodaFile):
        return None
    else:
        return netCDF4.Dataset(iodaFile, 'r')


def compareDateTime(iodaDataset, bufrFile, obsType):
    """ compares the date/time fields of a BUFR and IODA netCDF file for
        a single BUFR observation (subset) type

        Input:
            iodaDataset - the IODA netCDF dataset
            bufrFile - full pathname of BUFR file
            obsType - the BUFR observation (subset) type

        Return:
            text description of the result of the comparison
    """

    # an increment for assigning errors to random elements for testing ths 
    # program. Comment out while actually using the program
    #step = random.randrange(10000, 200000)

    # Read the BUFR fields associated with the date and time
    datetimeSearchString = ' '.join(DATETIME_MNEMONICS)
    bufrDatetime = []
    try:
        fd = ncepbufr.open(bufrFile)
    except OSError:
        raise ValidateSatwndsConvError \
            (f"BUFR file {bufrFile} could not be opened")
    while fd.advance() == 0:
        while fd.load_subset() == 0:
            if fd.msg_type == obsType:
                dateTimeFields = fd.read_subset(datetimeSearchString)
                # some BUFR files don't have a seconds field. Set the
                # seconds to 0 if this is the case
                if dateTimeFields.mask.size == 6 and dateTimeFields[5]:
                    dateTimeFields[5] = 0.
                # create a datetime string to match what's in the IODA file

                # Add an error to the YEAR field at every stepth element
                # Comment out the next 3 lines when not testing the program
                #if (len(bufrDatetime) % step) == 0:
                    #dateTimeFields[0] += 1.0
                    #print("changed year at ", len(bufrDatetime))

                bufrDatetime.append(f'{float(dateTimeFields[0]):04.0f}-{float(dateTimeFields[1]):02.0f}-{float(dateTimeFields[2]):02.0f}T{float(dateTimeFields[3]):02.0f}:{float(dateTimeFields[4]):02.0f}:{float(dateTimeFields[5]):02.0f}Z')
    fd.close()

    # Read the datetime variable from the IODA netCDF file
    #iodaDatetime = iodaDataset.groups["MetaData"].variables["datetime"][:]
    iodaDatetime = iodaDataset.variables["datetime@MetaData"][:]

    msg = f"IODA date/time                {iodaDatetime.size:10d}  BUFR date/tim{len(bufrDatetime):12d}"

    # Compare the BUFR and IODA dates/times
    if iodaDatetime.size != len(bufrDatetime):
        msg += "Incorrect number of date/time stamps\n"
    else:
        differCount = 0
        for i in range(len(bufrDatetime)):
            if bufrDatetime[i] != iodaDatetime[i]:
                differCount += 1
        msg += f"{differCount:12d}\n"

    return msg


def compareVariables(iodaDataset, bufrFile, obsType, varPairs):
    """ driver for comparing variables other than date time

        Input:
            iodaDataset - file descriptor for the IODA netCDF file
            bufrFile - full pathname of the BUFR file
            obsType - the observation (subset) type
            varPairs - dictionary containing mapping of BUFR mnemonics
                       to IODA netCDF variables

        Return:
            text description of the comparisons
    """

    bufrValues = retrvFromBufr(bufrFile, obsType, varPairs.values())

    msg = "         IODA Variable         IODA Size  BUFR Mnemonic   BUFR Size  Difference\n"
    for iodaVar in varPairs.keys():
        msg += checkVariable(iodaDataset, iodaVar, varPairs[iodaVar], 
                             bufrValues[varPairs[iodaVar]])

    return msg


def checkVariable(iodaDataset, iodaVar, bufrMnemonic, bufrValues):
    """ compares a single fields from a BUFR and an IODA netCDF file for
        a single BUFR observation (subset) type

        Input:
            iodaDataset - the IODA netCDF dataset
            iodaVar - variable name of the variable in the IODA netCDF file
            obsType - the BUFR observation (subset) type
            bufrMnemonic - the mnemonic name for the variable in the BUFR file

        Return:
            text description of the comparison result
    """

    msg = ''

    # Get the data from the IODA netCDF file
    iodaValues = iodaDataset.variables[iodaVar][:]
    if len(iodaValues.shape) != 1 or len(bufrValues.shape) != 1:
        # BUFR field is part of a sequence with repetition,  so the IODA
        # array is 2-dimensional
        if bufrValues.shape[0] == iodaValues.shape[0]:
            # There were the same number of rows in the IODA file as
            # in the BUFR file, which is a good thing. The IODA array
            # may have fewer columns due to duplicate use of mnemonics
            # in BUFR files, so only compare as many columns as there
            # are in the IODA file
            try:
                if bufrValues.shape[1] > iodaValues.shape[1]:
                    bufrValues = bufrValues[:,:iodaValues.shape[1]]
                    iodaValues = np.transpose(iodaValues).flatten()
                else:
                    iodaValues \
                        = iodaValues[:,:bufrValues.shape[1]]
                    iodaValues = iodaValues.flatten()
                #msg += f"{iodaVar:30s}{iodaValues.size:10d}  {bufrMnemonic:15s}{bufrValues.shape:10d}"
            except IndexError:
                bufrValues = bufrValues[:,0]
                msg += f"IODA variable {iodaVar} compared to first column from BUFR variable {bufrMnemonic}\n"

        bufrValues = bufrValues.flatten()

    #else:
        #msg += f"{iodaVar:30s}{iodaValues.size:10d}  {bufrMnemonic:15s}{bufrValues.size:10d}"
    msg += f"{iodaVar[:30]:30s}{iodaValues.size:10d}  {bufrMnemonic:15s}{bufrValues.size:10d}"

    # Perform the comparison
    if iodaValues.size != bufrValues.size:
        msg += "lengths differ"
    else:
        if iodaValues.dtype == np.float32:
            diffMeasure = max([0.00001, 0.00001*min(min(abs(iodaValues)),
                                                    min(abs(bufrValues)))])
            differCount = 0
            diffArray = np.where(abs(iodaValues - bufrValues) > diffMeasure,
                                 True, False)
            differCount = len(np.extract(diffArray == True, diffArray))
            msg += f"{differCount:12d}"

        else:
            msg += f"{iodaVar} is not a floating point variable"
    msg += "\n"

    return msg


def matchIodaFieldsToBufr(obsType, yamlDir):
    """ matches variable names from IODA netCDF file with mnemonic names
        from BUFR file

        Input:
            obsType - the message (subset) type (e.g., NC005044)
            yamlDir - directory where the YAML file is

        Return:
            fieldNamePairs  - dictionary with IODA netCDF variables as keys
                              and corresponding BUFR mnemonics as values
            bufrMnemonicList - list of mnemonics that bufr2ioda.x expects to
                               pull from the BUFR file
    """

    fieldNamePairs = {}

    try:
        with open(f"{yamlDir}/{YAML_FILES[obsType]}") as fd:
            y = yaml.safe_load(fd)
    except FileNotFoundError:
        raise ValidateSatwndsConvError \
            (f"YAML file {YAML_FILES[obsType]} could not be opened")

    for v in y["observations"][0]["ioda"]["variables"]:
        if v["name"] != "datetime@MetaData":
            varName = v["source"].split('/')[-1]
            fieldNamePairs[v["name"]] \
                = y["observations"][0]["obs space"]["exports"]["variables"][varName]["mnemonic"]

    bufrMnemonicList = []
    for ms in y["observations"][0]["obs space"]["mnemonicSets"]:
        if "mnemonics" in ms.keys():
            bufrMnemonicList.extend(ms["mnemonics"])

    return fieldNamePairs, bufrMnemonicList


def retrvFromBufr(bufrFileName, obsType, bufrMnemonics):
    """ driver for reading data from BUFR file

        Input:
            bufrFileName - full pathname of the BUFR file
            obsType - the observation (subset) type
            bufrMnemonics - list of mnemonics that according to the YAML
                            file are to be read from the BUFR file
    """

    (soloList, seqList) = prepMnemonics(bufrFileName, obsType, bufrMnemonics)
    bufrValues = retrvBufrData(bufrFileName, obsType, soloList, seqList)
    missingMnemonics = []
    for m in bufrMnemonics:
        if not (m in [x.name for x in soloList] or
                m in [x.name for x in seqList]):
            bufrValues[m] = np.empty((0,), dtype=np.float64)

    return bufrValues


def prepMnemonics(bufrFileName, obsType, bufrMnemonics):
    """ returns information needed for pulling data from a BUFR file.
        Needed because some fields are part of sequences and in those
        cases the entire sequence needs to be read in.

        Input:
            bufrFileName - full pathname of the BUFR file
            obsType - the observation (subset) type
            bufrMnemonics - list of mnemonics that according to the YAML
                            file are to be read from the BUFR file

        Return:
            soloList - list of MnemonicNode objects for BUFR fields that
                       are not part of a sequence
            seqList - list of MnemonicNode objects for BUFR fields that
                      are part of a sequence
    """

    # there undoubtedly is a better way to extract tables from BUFR files
    # than by running another process that dumps the tables but I don't know
    # what it is
    execDir = os.path.dirname(sys.argv[0])
    executable = os.path.join(execDir, "bufrtblstruc.py")
    ts = subprocess.run(args=[executable, bufrFileName, obsType],
                        capture_output=True)
    tblLines = ts.stdout.decode("utf-8").split('\n')
    try:
        (section1, section2, section3) = bufrTableTools.parseTable(tblLines)
    except bufrTableTools.BUFRTableError as bte:
        raise ValidateSatwndsConvError(bte.message)

    # get a list of the mnemonics of all the fields shown for the observation
    # type in the .tbl file
    mnemonicList = bufrTableTools.getMnemonicListLeaves(obsType, section2)

    # if the parent name is the observation (subset) type, then the
    # field is not part or a sequence
    soloList = [x for x in mnemonicList if x.name in bufrMnemonics
                and x.parent.name == obsType]
    # remove duplicate mnemonics because that's how bufr2ioda.x
    # appears to work
    soloList = [x for i, x in enumerate(soloList) if x.name not in 
                [y.name for y in soloList[:i]]]

    # if the parent name is no the observation (subset) type, then the
    # field is part of a sequence.
    seqList = [x for x in mnemonicList if x.name in bufrMnemonics
               and x.name not in soloList and x.parent.name != obsType]
    # mnemonic names are sometimes used in more than 1 sequence or in
    # a sequence and on the top level, so remove duplicates and hope for
    # the best
    seqList = [x for i, x in enumerate(seqList) if x.name not in 
               [y.name for y in seqList[:i]] and x.name not in 
               [y.name for y in soloList]]

    return soloList, seqList


def retrvBufrData(bufrFile, obsType, soloList, seqList):
    """ reads data for the specified observation (subset) type and
        mnemonics from a BUFR file

        Input:
            bufrFile - full pathname of the BUFR file
            obsType - observation (subset) type
            soloList - list of MnemonicNode objects for fields that are not
                       part of a sequence
            seqList - list of MnemonicNode objects for fields that are not
                      part of a sequence

        Return:
            numpy array containing the data read from the BUFR file
    """

    # an increment for assigning random errors for testing ths program
    # Comment out while actually using the program
    #steps = {}
    #for s in soloList:
        #steps[s.name] = random.randrange(10000, 200000)

    tmpArrays = {}

    # initialize variables for non-sequence fields
    toplevelMnemonics = [x.name for x in soloList]
    for m in toplevelMnemonics:
        tmpArrays[m] = array.array('d')
    toplevelSearchString = ' '.join(toplevelMnemonics)

    # initialize variables for fields that are in sequences
    for m in [x.name for x in seqList]:
        tmpArrays[m] = array.array('d')

    fd = ncepbufr.open(bufrFile, mode='r')

    # step through the BUFR file
    ncols = {}
    while fd.advance() == 0:
        while fd.load_subset() == 0:
            if fd.msg_type == obsType:

                # Retrieve the fields that are not part of a sequence
                wholeBunch = fd.read_subset(toplevelSearchString)
                idx = 0
                for m in toplevelMnemonics:
                    tmpArrays[m].append(wholeBunch[idx,0])
                    idx += 1
                    # Add error at every stepth element. Comment out the
                    # next 3 lines when not testing the program
                    #if (len(tmpArrays[m]) % steps[m]) == 0:
                        #tmpArrays[m][-1] *= 0.99
                        #print(f"changed element {len(tmpArrays[m])} for {m}")

                # Retrieve the fields that are part of a sequence. This
                # section of code unfortunately will cause multiple reads
                # of sequenes for which more than 1 field is needed
                for m in seqList:
                    slug = fd.read_subset(m.parent.name, seq=True)
                    for i in range(slug.shape[1]):
                        tmpArrays[m.name].append(slug[m.seq_index][i])
                    ncols[m.name] = slug.shape[1]

    fd.close()

    # re-write data in numpy arrays
    returnValues = {}
    for m in toplevelMnemonics:
        returnValues[m] = np.array(tmpArrays[m], dtype=np.float64)
    for m in [x.name for x in seqList]:
        returnValues[m] = np.array(tmpArrays[m], dtype=np.float64)
        returnValues[m] = np.reshape(returnValues[m],
                                     (len(tmpArrays[m])//ncols[m], ncols[m]))

    return returnValues


if __name__ == "__main__":

    a = argparse.ArgumentParser()
    a.add_argument("bufr_file", help="Input BUFR file full pathname")
    a.add_argument("obs_type", help="BUFR message type")
    a.add_argument("ioda_file", help="IODA netCDF file name")
    a.add_argument("-y",
                   help="directory of YAML file (default is current working directory)", 
                   type=str, default=os.getcwd())

    args = a.parse_args()

    try:
        validateSatwndsConv(args.bufr_file, args.obs_type, args.ioda_file,
                            args.y)
        sys.exit(0)
    except ValidateSatwndsConvError as err:
        sys.stderr.write \
            (f"Fatal error in validateSatwndsConv:\n{err.message}\n\n")
        sys.exit(-1)

