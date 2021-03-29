#!/usr/bin/env python

#==============================================================================
# Program to display a map of the mnemonic hierarchy in a BUFR table
#==============================================================================

import argparse
import ncepbufr
import os.path
import subprocess
import sys

sys.path.append(os.path.dirname(sys.argv[0]))
import bufrTableTools


def bufrmnemonicmap(BUFRFileName, obsType, textFile=None):
    """ dumps a field from a BUFR file

        Input:
            BUFRFileName - complete pathname of file that a field is to be
                           dumped from
            obsType - the observation type (e.g., NC001001)
            textFile - if passed, write output as text to this file
    """

    # there undoubtedly is a better way to extract tables from BUFR files
    # than by running another process that dumps the tables but I don't know
    # what it is
    execDir = os.path.dirname(sys.argv[0])
    executable = os.path.join(execDir, "bufrtblstruc.py")
    ts = subprocess.run(args=[executable, BUFRFileName, obsType],
                        capture_output=True)
    tblLines = ts.stdout.decode("utf-8").split('\n')
    try:
        (section1, section2, section3) = bufrTableTools.parseTable(tblLines)
    except bufrTableTools.BUFRTableError as bte:
        print(bte.message)
        sys.exit(-1)

    # get a list of the mnemonics of all the fields shown for the observation
    # type in the .tbl file
    #treeTop = bufrTableTools.MnemonicNode(obsType, False, None, 0)
    treeTop = bufrTableTools.MnemonicNode(obsType, None, seq=True)
    bufrTableTools.buildMnemonicTree(treeTop, section2)

    indentation = 0
    msg = createMap(treeTop, section1, indentation)
    
    if textFile:
        fd = open(textFile, 'w')
        fd.write(f"{msg}\n")
        fd.close()
    else:
        sys.stdout.write(f"{msg}\n")

    return


def createMap(node, section1, indentation):
    """ Adds a node and its children nodes to the map

        Input:
            node - node representing a mnemonic in the table
            section1 - 1st section from a table in a BUFR file
            indentation - number of spaces to indent the node entry in the
                          map

        Return:
            portion of map for the node and its children nodes
    """

    spaces = indentation*' '
    if node.name[0] == '.':
        # Don't know what to do with mnemnonics that begin with '.', so 
        # just list the mnemonic
        msg = f"\n{spaces}{node.name}"
    else:
        if node.repl:
            replication = " (replicated)"
        elif node.name[0]:
            replication = ""
        msg = f"\n{spaces}{node.name}{replication}   {section1[node.name]}"

        for i in range(len(node.children)):
            msg += createMap(node.children[i], section1, indentation + 4)

    return msg


if __name__ == "__main__":

    # parse command line
    parser = argparse.ArgumentParser()
    parser.add_argument("bufr_file", type=str, 
                        help="full pathname of input file")
    parser.add_argument("observation_type", type=str, 
                        help="observation type (e.g., NC031001)")
    group = parser.add_mutually_exclusive_group()
    group.add_argument("-o", type=str, required=False, \
                        help="write text output to specified file rather than stdout")
    args = parser.parse_args()

    # run dump program
    if args.o:
        bufrmnemonicmap(args.bufr_file, args.observation_type, textFile=args.o)
    else:
        bufrmnemonicmap(args.bufr_file, args.observation_type)
