#!/usr/bin/env python

#=============================================================================
# 08-19-2020   Jeffrey Smith          Initial version
#=============================================================================

import ncepbufr
import sys

def bufrtblstruc(bufrFileName):
    """ writes the contents of the tables of a BUFR file to standard output

        Input:
            bufrFileName - full path name of the BURR file
    """

    bufr = ncepbufr.open(bufrFileName)
    bufr.print_table()
    bufr.close()

    return

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("ERROR: must supply exactly 1 arguments")
        print("bufrtbldump.py <BUFR path name>")
        sys.exit(1)
    bufrtblstruc(sys.argv[1])
    sys.exit(0)


