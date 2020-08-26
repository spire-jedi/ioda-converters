#!/usr/bin/python

#=============================================================================
# functions that support table and YAML usage with BUFR files
#
# 08/24/2020   Jeffrey Smith          initial version
#=============================================================================

import collections
import os.path
import re
import sys

import yaml

SECTION1_PATTERN = "\|.{10}\|.{8}\|.{58}\|"
SECTION2_PATTERN = "\|.{10}\|.{67}\|"
SECTION3_PATTERN = "\|.{10}\|.{8}\|.{58}\|"

# class (used like a C struct) for nodes in a tree for mnemonics from
# a BUFR table
class MnemonicNode:
    def __init__(self, name, seq, parent):
        self.name = name
        self.seq = seq
        self.parent = parent
        self.children = []
        return

# exception for BUFR files/tables
class BUFRTableError(Exception):
    def __init__(self, message):
        self.message = "BUFRTableError: %s" % (message,)
        return

# exception for .dict files
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
    """ returns a list of the mnemonics that can be extracted from a BUFR
        file for a specific observation type

        Input:
            obsType - observation type (e.g., "NC031001") or parent key
            section2 - dictionary containing Section 2 from a .tbl file

        Return:
            list of mnemonics that will be output
    """

    # need to create a root node for a tree
    treeTop = MnemonicNode(obsType, False, None)

    buildMnemonicTree(treeTop, section2)
    mnemonicList = findSearchableNodes(treeTop)

    return mnemonicList


def buildMnemonicTree(root, section2):
    """ builds a hierarchical tree for the mnemonics for a given observation 
        type

        Input:
            root - root node for segment of tree to process
            section2 - dictionary containing Section 2 from a .tbl file

        Return:
            list of mnemonics that will be output
    """

    mnemonicsForID = section2[root.name]
    for m in mnemonicsForID:
        if re.search("\{|\(|\<", m):
            m = m[1:-1]
            seq = True
        elif m[0] == '"':
            m = m[1:-2]
            seq = True
        else:
            seq = False

        node = MnemonicNode(m, seq, root)

        if m in section2.keys():
            # if m is a key then it is a parent, so get its members
            root.children.append(node)
            buildMnemonicTree(node, section2)
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

    # remove duplicates (can happen if leaf nodes share a parent that is
    # a sequence)
    nodeList = [x for i,x in enumerate(nodeList) if not x in nodeList[:i]]

    return nodeList


def traverseMnemonicTree(root):
    """ returns the leaves of a mnemonic tree by performing a standard
        tree traversal

        Input:
            root - root node of the tree to traverse

        Return:
            list of leaves in the tree (MnemonicNode objects)
    """

    leafList = []

    if len(root.children) > 0:
        for node in root.children:
            leafList.extend(traverseMnemonicTree(node))
    else:
        leafList.append(root)

    return leafList
