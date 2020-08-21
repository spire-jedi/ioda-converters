#!/usr/bin/env python

#==============================================================================
# 08-19-2020   Jeffrey Smith          Initial version
#==============================================================================

import argparse
import ncepbufr
import numpy as np
import sys
import netCDF4
import subprocess

import readAncillary


def bufrdump(BUFRFileName, obsType, outputFile=None):
    """ dumps a field from a BUFR file

        Input:
            BUFRFileName - complete pathname of file that a field is to be
                           dumped from
            obsType - the observation type (e.g., NC001001)
            outputFile - optional file to hold output. defaults to stdout
    """

    # there undoubtedly is a better way to extract tables from BUFR files
    # than by running another process that dumps the tables but I don't know
    # what it is
    ts = subprocess.run(args=["./bufrtblstruc.py", BUFRFileName], 
                        capture_output=True)
    tblLines = ts.stdout.decode("utf-8").split('\n')
    try:
        (section1, section2, section3) = readAncillary.parseTable(tblLines)
    except readAncillary.BUFRTableError as bte:
        print(bte.message)
        sys.exit(-1)

    # get a list of the mnemonics of all the fields shown for the observation
    # type in the .tbl file
    mnemonicChains = readAncillary.getMnemonicList(obsType, section2)

    # get the user's choice of which field to dump
    (whichField, seq) = getMnemonicChoice(mnemonicChains, section1)

    # dump the field
    if outputFile:
        fd = open(outputFile, 'w')
        dumpBUFRField(BUFRFileName, whichField, mnemonicChains, seq, fd)
        fd.close()
    else:
        dumpBUFRField(BUFRFileName, whichField, mnemonicChains, seq, 
                      sys.stdout)

    return


def getMnemonicChoice(mnemonicChains, section1):
    """ gets users choice of which field to dump

        Input:
            mnemonicChains - list containing a the field names from the .tbl
                             file
            section1 - first section from a .tbl file

        Return:
            whichField - mnemonic of field to dump
            seq - True if field is a sequence, False otherwise
    """

    # separate the fields into sequences and single ("solitary") fields
    solitaryList = []
    sequenceList = []
    for m in mnemonicChains:
        if m.count('_') == 0:
            solitaryList.append(m)
        else:
            chainLinks = m.split('_')
            if chainLinks[-2][0] in ['{', '(', '<']:
                sequenceList.append(chainLinks[-2][1:-1])
            elif chainLinks[-2][0] == '"':
                sequenceList.append(chainLinks[-2][1:-2])
            else:
                solitaryList.append(chainLinks[-1])
    # remove duplicates from sequenceList
    sequenceList = list(dict.fromkeys(sequenceList))

    # post a list of the fields
    idx = 0
    print("\nIndividual Fields:")
    for m in solitaryList:
        idx += 1
        # don't know what to do with mnemonics that start with a period
        if m[0] == '"':
            print("{:3}) {:10} - {}".format(idx, m[1:-2], section1[m[1:-2]]))
        elif m[0] != '.':
            print("{:3}) {:10} - {}".format(idx, m, section1[m]))

    print("\nSequences:")
    for m in sequenceList:
        idx += 1
        print("{:3}) {:10} - {}".format(idx, m, section1[m]))
    print()

    # get user's selection
    selection = int(input("Enter number of selection: "))
    if selection <= len(solitaryList):
        whichField = solitaryList[selection - 1]
        seq = False
    else:
        whichField = sequenceList[selection - len(solitaryList) - 1]
        seq = True

    return (whichField, seq)


def dumpBUFRField(BUFRFilePath, whichField, mnemonicChains, seq, fd):
    """ dumps the field from the BUFR file. The bulk of the code in this
        function was blatantly plagiarized from Steve Herbener's bufrtest.py.

        Input:
            BUFRFilePath - complete pathname of the BUFR file
            whichField - the mnemonic of the field to dump
            mnemonicChains - list containing a the field names from the .tbl
                             file
            seq - True if the field to be dumped is a sequence, False otherwise
            fd - file descriptor of file to write output to
    """

    if seq:
        sequenceLength = len([x for x in mnemonicChains if whichField in x])
        fd.write("Order of individual fields: {}\n".format(
            [x.split('_')[-1] for x in mnemonicChains if whichField in x]))
    else:
        sequenceLength = 1

    # open file and read through contents
    bufr = ncepbufr.open(BUFRFilePath)

    while (bufr.advance() == 0):
        fd.write("  MSG: {0:d} {1:s} {2:d} ({3:d})\n".format(
            bufr.msg_counter,bufr.msg_type,bufr.msg_date,bufr._subsets()))

        isub = 0
        while (bufr.load_subset() == 0):
            isub += 1
            Vals = bufr.read_subset(whichField, seq=seq).data.squeeze()
            if seq:
                try:
                    fd.write(
                        "    SUBSET: {0:d}: MNEMONIC VALUES: {other}\n".
                        format(isub, other=Vals[:sequenceLength,:]))
                except IndexError:
                    fd.write("    SUBSET: {0:d}: MNEMONIC VALUES: {other}\n".
                             format(isub, other=Vals[:sequenceLength]))
            
            else:
                fd.write("    SUBSET: {0:d}: MNEMONIC VALUES: {other}\n".
                         format(isub, other=Vals))

    # clean up
    bufr.close()

    return


if __name__ == "__main__":

    parser = argparse.ArgumentParser()
    parser.add_argument("bufr_file", type=str, 
                        help="full pathname of input file")
    parser.add_argument("observation_type", type=str, 
                        help="observation type (e.g., NC031001)")
    parser.add_argument("-o", type=str, required=False, \
                        help="file for output. Output to terminal if omitted")
    args = parser.parse_args()

    if args.o:
        bufrdump(args.bufr_file, args.observation_type, outputFile=args.o)
    else:
        bufrdump(args.bufr_file, args.observation_type)
