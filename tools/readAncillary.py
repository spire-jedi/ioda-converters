#!/usr/bin/python

#==============================================================================
# 08-19-2020   Jeffrey Smith          Initial version
#=============================================================================

import collections
import os.path
import re
import sys

import yaml

SECTION1_PATTERN = "\|.{10}\|.{8}\|.{58}\|"
SECTION2_PATTERN = "\|.{10}\|.{67}\|"
SECTION3_PATTERN = "\|.{10}\|.{8}\|.{58}\|"

class BUFRTableError(Exception):
    def __init__(self, message):
        self.message = "BUFRTableError: %s" % (message,)
        return

class YAMLFileError(Exception):
    def __init__(self, message):
        self.message = "YAMLFileError: %s" % (message,)
        return

def readTable(tableFileName):
    """ reads a .tbl file

        Input:
            tableFileName - full path name of the .tbl file

        Return:
            list of lines from the table
    """

    if not os.path.isfile(tableFileName):
        raise BUFRTableError("Table file %s was not found\n" % 
                             (tableFileName,))

    with open(tableFileName, 'r') as fd:
        tblLines = fd.read().split('\n')

    return tblLines


def parseTable(tblLines):
    """ parses an NCEP BUFR table. The code for section3 has not been written.

        Input:
            tblLines - list containing the lines of an NCEP BUFR table

        Return:
            3 ordered dictionaries containing the information for the 3
            tables contained in a .tbl file
    """

    section1 = collections.OrderedDict()
    section2 = collections.OrderedDict()
    section3 = collections.OrderedDict()

    idx = 0
    try:
        # skip to the first line of information from Section 1.
        while not re.search(SECTION1_PATTERN, tblLines[idx]):
            idx += 1

        # fill in dictionary of Section 1 values
        while re.search(SECTION1_PATTERN, tblLines[idx]):
            if re.search("^\| [A-Z|0-9]{3,}", tblLines[idx]) and \
               not ("MNEMONIC" in tblLines[idx]):
                fields = tblLines[idx].split('|')
                section1[fields[1].strip()] = fields[3].strip()
            idx += 1

        # skip to the frist line of information from Section 2
        while not re.search(SECTION2_PATTERN, tblLines[idx]):
            idx += 1

        # fill in dictionary of Section 2 values
        currentKey = ""
        while re.search(SECTION2_PATTERN, tblLines[idx]):
            if re.search("^\| [A-Z|0-9]{3,}", tblLines[idx]) and \
               not ("MNEMONIC" in tblLines[idx]):
                fields = tblLines[idx].split('|')
                parts = fields[2].split()
                if fields[1].strip() == currentKey:
                    section2[currentKey].extend(parts)
                else:
                    currentKey = fields[1].strip()
                    section2[currentKey] = parts
            idx += 1

    except IndexError:
        # Didn't find a proper end line, so assume that there is something
        # wrong with the file
        #raise BUFRTableError("Program failed to read table file %s\n" % \
                             #(tableFileName,))
        raise BUFRTableError("Program did not find proper table\n")

    return (section1, section2, section3)


def readYAMLFile(yamlFile):
    """ reads a .dict file

    Input:
        name of the .dict file

    Return:
        a dictionary containing the information from the .dict file. The
        mnemonics are the keys in the dictionary
    """

    if os.path.isfile(yamlFile):
        with open(yamlFile, 'r') as fd:
            yamlDict = yaml.safe_load(fd)
    else:
        yamlDict = None
        raise YAMLFileError("YAML file %s could not be read." % (yamlFile,))

    return yamlDict


def getMnemonicList(obsType, section2):
    """ returns a list of the mnemonics for a given observation type.
        The mnemonics contain the entire hierarchy of a field chained
        together with underscores, e.g., YYMMDD_YEAR for the YEAR field
        that is grouped into YYMMDD. Ideally, this should instead be
        handled in a tree data structure.

        Input:
            obsType - observation type (e.g., "NC031001") or parent key
            section2 - dictionary containing Section 2 from a .tbl file

        Return:
            list of mnemonics that will be output
    """

    mnemonicList = []

    mnemonicsForID = section2[obsType]
    for m in mnemonicsForID:
        if re.search("\{|\(|\<", m):
            mSearch = m[1:-1]
        elif m[0] == '"':
            mSearch = m[1:-2]
        else:
            mSearch = m

        if mSearch in section2.keys():
            # if m is a key then it is a parent mnemonic, so get its members
            mnemonicList.extend([m + '_' + x for x in \
                                 getMnemonicList(mSearch, section2)])
        else:
            # not a parent, so it is a field name.
            mnemonicList.append(m)

    return mnemonicList


if __name__ == "__main__":
    (a,b,c) = readTable("NC031001.tbl")
    #print('A', a)
    #print
    #print('B', b)
#!/usr/bin/env python
