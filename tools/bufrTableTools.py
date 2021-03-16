#!/usr/bin/python

#=============================================================================
# functions that support table and .cict usage with BUFR files
#
# 08/24/2020   Jeffrey Smith          initial version
#=============================================================================

import collections
import os.path
import re
import sys

#from marineprofile_consts import *

# Patterns for searching
SECTION1_PATTERN = "\|.{10}\|.{8}\|.{58}\|"
SECTION2_PATTERN = "\|.{10}\|.{67}\|"
SECTION3_PATTERN = "\|.{10}\|.{6}\|.{13}\|.{5}\|.{26}\|-{13}\|"
DEFINED_MNEMONIC_PATTERN = "^\| [A-Z|0-9|_]{3,}"
DELAYED_REP_PATTERN = "\{|\(|\<|\[[A-Z|0-9|_]{3,}"
REGULAR_REP_PATTERN = "\"[A-Z|0-9|_]{3,}\"\d{1,}"

# exception for BUFR files/tables
class BUFRTableError(Exception):
    def __init__(self, message):
        self.message = "BUFRTableError: %s" % (message,)
        return

# exception for .dict files
class DictFileError(Exception):
    def __init__(self, message):
        self.message = "DictFileError: %s" % (message,)
        return

# class (used like a C struct) for nodes in a tree for mnemonics from
# a BUFR table
class MnemonicNode:
    def __init__(self, name, repl, parent, seqIndex):
        """ contructor

            Input:
                name - mnemonic name
                repl - True if the mnemonic has replication, False otherwise
                parent - the MnemonicNode for the current mnemonic's parent
                seqIndex - if the parent is a sequence mnemonic, the position
                           in the list of children
        """

        self.name = name
        self.repl = repl
        self.parent = parent
        self.seq_index = seqIndex
        self.children = []
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
    """ parses an NCEP BUFR table.

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
            if re.search(DEFINED_MNEMONIC_PATTERN, tblLines[idx]) and \
               not ("MNEMONIC" in tblLines[idx]):
                fields = tblLines[idx].split('|')
                section1[fields[1].strip()] = fields[3].strip()
            idx += 1

        # skip to the first line of information from Section 2
        while not re.search(SECTION2_PATTERN, tblLines[idx]):
            idx += 1

        # fill in dictionary of Section 2 values
        currentKey = ""
        while re.search(SECTION2_PATTERN, tblLines[idx]):
            if re.search(DEFINED_MNEMONIC_PATTERN, tblLines[idx]) and \
               not ("MNEMONIC" in tblLines[idx]):
                fields = tblLines[idx].split('|')
                parts = fields[2].split()
                if fields[1].strip() == currentKey:
                    section2[currentKey].extend(parts)
                else:
                    currentKey = fields[1].strip()
                    section2[currentKey] = parts
            idx += 1

        # skip to the first line of information from Section 3.
        while not re.search(SECTION3_PATTERN, tblLines[idx]):
            idx += 1

        # fill in dictionary of Section 3 values
        while re.search(SECTION3_PATTERN, tblLines[idx]):
            if re.search(DEFINED_MNEMONIC_PATTERN, tblLines[idx]) and \
               not ("MNEMONIC" in tblLines[idx]):
                fields = tblLines[idx].split('|')
                section3[fields[1].strip()] \
                    = {"scale":float(fields[2].strip()),
                       "reference":float(fields[3].strip()),
                       "num_bits":int(fields[4].strip()),
                       "units":fields[5].strip()}
            idx += 1

    except IndexError:
        # Didn't find a proper end line, so assume that there is something
        # wrong with the file
        #raise BUFRTableError("Program failed to read table file %s\n" % \
                             #(tableFileName,))
        raise BUFRTableError("Program did not find proper table\n")

    return (section1, section2, section3)


def readDictFile(dictFile):
    """ reads a .dict file

    Input:
        name of the .dict file

    Return:
        a dictionary containing the information from the .dict file. The
        mnemonics are the keys in the dictionary. (This routine might only
        be used for working with Marine Data Assimilation BUFR files.)
    """

    if os.path.isfile(dictFile):
        with open(dictFile, 'r') as fd:
            dictDict = dict.safe_load(fd)
    else:
        dictDict = None
        raise YAMLFileError("Dict file %s could not be read." % (dictFile,))

    return dictDict


def getMnemonicListAll(obsType, section2, parentsToPrune=[], leavesToPrune=[]):
    """ returns a list of the mnemonics, both leaves and sequences, that can 
        be used to read fields from a BUFR file for a specific observation type

        Input:
            obsType - observation type (e.g., "NC031001") or parent key
            section2 - dictionary containing Section 2 from a .tbl file
            parentsToPrune - list of mnemonic objects for nodes that
                             are parents, so that the node and all its
                             descendents are pruned
            leavesToPrune - list for pruning mnemonics that are leaves.
                            Each element is a list that contains the Menomic
                            objects for the leaf and its parent (so that
                            mnemonics with duplicate names can be differinated)

        Return:
            list of mnemonics that will be output
    """

    # need to create a root node for a tree
    treeTop = MnemonicNode(obsType, False, None, 0)

    buildMnemonicTree(treeTop, section2)
    if parentsToPrune or leavesToPrune:
        status = pruneTree(treeTop, parentsToPrune, leavesToPrune)
    mnemonicList = findDumpableNodes(treeTop, obsType)
    # There are numerous instances in which leaves from different sequences
    # have the same mnemonic. For the purposes of this function, these
    # leaves are deleted.
    #mnemonicList = [x for i,x in enumerate(mnemonicList)
                    #if x.name not in [y.name for y in mnemonicList[:i]] and 
                    #x.name not in [y.name for y in mnemonicList[i+1:]]]

    return mnemonicList


def getMnemonicListBase(obsType, section2, parentsToPrune=[],
                        leavesToPrune=[]):
    """ returns a minimalist list of the mnemonics that can be extracted from 
        a BUFR file for a specific observation type. This means that 
        mnemonics for leaves that are in a sequence are not included because 
        those fields can be retrieved when the entire sequence is retrieved

        Input:
            obsType - observation type (e.g., "NC031001") or parent key
            section2 - dictionary containing Section 2 from a .tbl file
            parentsToPrune - list of mnemonic objects for nodes that
                             are parents, so that the node and all its
                             descendents are pruned
            leavesToPrune - list for pruning mnemonics that are leaves.
                            Each element is a list that contains the Menomic
                            objects for the leaf and its parent (so that
                            mnemonics with duplicate names can be differinated)

        Return:
            list of mnemonics that will be output
    """

    # need to create a root node for a tree
    treeTop = MnemonicNode(obsType, False, None, 0)

    buildMnemonicTree(treeTop, section2)
    if parentsToPrune or leavesToPrune:
        status = pruneTree(treeTop, parentsToPrune, leavesToPrune)
    mnemonicList = findSearchableNodes(treeTop, obsType)

    return mnemonicList


def getMnemonicListLeaves(obsType, section2):
    """ returns a list of the mnemonics that are leaves in a Mnemonic tree
        for a file

        Input:
            obsType - observation type (e.g., "NC031001") or parent key
            section2 - dictionary containing Section 2 from a .tbl file

        Return:
            list of mnemonics that will be output
    """

    # need to create a root node for a tree
    treeTop = MnemonicNode(obsType, False, None, 0)

    buildMnemonicTree(treeTop, section2)
    mnemonicList = traverseMnemonicTree(treeTop)

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
        if re.search(DELAYED_REP_PATTERN, m):
            m = m[1:-1]
            repl = True
        elif re.search(REGULAR_REP_PATTERN, m):
            m = m[1:m[1:].index('"') + 1]
            repl = True
        #elif m[0] == '.':
            # don't know how to handle mnemonics beginning with a .
            #continue
        elif m[0:2] == "20":
            # mnemonics of the form 20xxxx aren't an actual data field
            continue
        else:
            repl = False

        # last argument assigns 0 to 1st child, 1 to 2nd child, etc.
        node = MnemonicNode(m, repl, root, findIndexInSequence(root.children))

        if m in section2.keys():
            # if m is a key then it is a parent, so get its members
            root.children.append(node)
            buildMnemonicTree(node, section2)
        else:
            # not a parent, so it is a field name.
            root.children.append(node)

    return 


def findSearchableNodes(root, obsType):
    """ finds the nodes that reference a mnemonic that can be retrieved
        from a BUFR file. These nodes are the leaves except when a node
        that is a sequence is a parent of 1 or more leaves. Leaves are not
        included if they are part of a sequence.

        Input:
            root - the root node of the tree to search
            obsType - observation type (e.g., "NC031001") or parent key

        Return:
            a list of nodes that reference mnemonics that can be retrieved
            from a BUFR file
    """

    nodeList = []

    if len(root.children) > 0:
        # root is not a leaf so visit its children
        for node in root.children:
            nodeList.extend(findSearchableNodes(node, obsType))
    else:
        # a leaf, so it is added to the list unless its parent is a sequence,
        # in which case its parent is added (unless its parent is the obs type)
        if root.parent.name != obsType and root.parent.name != "TMSLPFDT" \
           and root.parent.name not in [x.name for x in nodeList]:
            #root.parent.children = [x for x in root.parent.children if x.name[0] != '.']
            nodeList.append(root.parent)
        else:
            if root.name[0] != '.':
                nodeList.append(root)

    # remove duplicates (will happen if leaf nodes share a parent that is
    # a sequence)
    #nodeList = [x for i,x in enumerate(nodeList) if not x in nodeList[:i]
                #or len(x.children) == 0]

    return nodeList


def findDumpableNodes(root, obsType):
    """ finds the nodes that reference a mnemonic that can be retrieved
        from a BUFR file. These nodes are the leaves except when a node
        that is a sequence is a parent of 1 or more leaves. If a node is
        a leaf that is part of a sequence, both the node and its parent
        are included in the list of nodes that is returned.

        Input:
            root - the root node of the tree to search
            obsType - observation type (e.g., "NC031001") or parent key

        Return:
            a list of nodes that reference mnemonics that can be retrieved
            from a BUFR file
    """

    nodeList = []

    if len(root.children) > 0:
        # root is not a leaf so visit its children
        for node in root.children:
            nodeList.extend(findDumpableNodes(node, obsType))
    else:
        # a leaf, so it is added to the list unless its parent is a sequence,
        # in which case its parent is added (unless its parent is the obs type)
        nodeList.append(root)
        if root.parent.name != obsType and root.parent.name != "TMSLPFDT" \
           and root.parent.children.index(root) == 0:
            # last clause is so that a parent node won't get entered 
            # multiple times
            nodeList.append(root.parent)
            #root.parent.children \
                #= [x for x in root.parent.children if x.name[0] != '.']

    # remove duplicates (will happen if leaf nodes share a parent that is
    # a sequence)
    #nodeList = [x for i,x in enumerate(nodeList) if not x in nodeList[:i]]

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


def firstMnemonicOccurrence(mnemonicList):
    """ Returns a list of mnemonics with only the first occurrence of
        mnemonics that appear more than once

        Input/Output:
            mnemonicList - list of mnemonics in the BUFR file. Returned
                           with all occurrences of duplicate mnemonics
                           removed
    """
    mnemonicList = [x for i,x in enumerate(mnemonicList)
                    if x.name not in [y.name for y in mnemonicList[:i]]]

    return mnemonicList


def removeDuplicateMnemonics(mnemonicList):
    """ From a list of mnemonics, removes all occurrences of mnemonics that
        appear more than once in the list

        Input/Output:
            mnemonicList - list of mnemonics in the BUFR file. Returned
                           with all occurrences of duplicate mnemonics
                           removed
    """
    mnemonicList = [x for i,x in enumerate(mnemonicList)
                    if x.name not in [y.name for y in mnemonicList[:i]] and 
                    x.name not in [y.name for y in mnemonicList[i+1:]]]

    return mnemonicList


def pruneTree(root, parentsToPrune, leavesToPrune):
    """ prunes nodes from a tree of Mnemonics. An entire subtree can be
        pruned (mnemonic object for top of subtree in parentsToPrune) or
        individual leaves can be pruned (from leavesToPrune).

        Input:
            root - root node of the tree
            parentsToPrune - list of mnemonic objects for nodes that
                             are parents, so that the node and all its
                             descendents are pruned
            leavesToPrune - list for pruning mnemonics that are leaves.
                            Each element is a list that contains the Menomic
                            objects for the leaf and its parent (so that
                            mnemonics with duplicate names can be differinated)

        Return:
            True if root and its descendants were pruned, False otherwise
    """


    pruned = False

    if root.name in parentsToPrune:
        idx = 0
        while idx < len(root.children):
            # if the field is a sequence, prune all its children
            #if root.children[idx].seq:
            if len(root.children[idx].children) > 0:
                # if the child is a sequence, add its name to the list
                # of sequences to prune
                pruned = pruneTree(root.children[idx],
                                   [x for x in parentsToPrune or
                                    x in root.children[idx].name],
                                   leavesToPrune)
            else:
                # child is not a sequence, so add its name and parent's
                # name to list of leaves to prune
                pruned = pruneTree(root.children[idx], parentsToPrune,
                                   [x for x in leavesToPrune or
                                    x in [root.children[idx].name, root.name]])
            if not pruned:
                idx += 1
        root.parent.children.remove(root)
        pruned = True
    elif root.parent and (root.name, root.parent.name) \
         in [(x[0], x[1]) for x in leavesToPrune]:
        # first clause handles when root is the root of the entire tree
        root.parent.children.remove(root)
        pruned = True
    else:
        # node is not in prune list but if it has any children then
        # process the children
        idx = 0
        while idx < len(root.children):
            pruned = pruneTree(root.children[idx], parentsToPrune,
                               leavesToPrune)
            if not pruned:
                idx += 1
        
    return pruned


def findIndexInSequence(sequenceMnemonics):
    """ finds the position of a specific mnemonic in the list of 
        fields returned by a call to read_subset

        Input:
            sequenceMnemonics - a subtree of MnemonicNode objects that
                                map the structure of the sequence

       Return:
           the position of the data for the mnemonic in the list of
           fields return by a call to read_subset
    """

    idx = 0
    for m in sequenceMnemonics:
        if len(m.children) > 0:
            idx = idx + findIndexInSequence(m.children)
        else:
            idx += 1

    return idx

