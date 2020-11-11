#!/usr/bin/env python

#=============================================================================
# Author:   Jeffrey Smith   IM Systems Group
#=============================================================================

import ncepbufr
import sys

def bufrtblstruc(bufrFileName, obsType):
    """ writes the contents of the tables of a BUFR file to standard output

        Input:
            bufrFileName - full path name of the BUFR file
            obsType - the observation type code (NCxxxxxx)
    """

    bufr = ncepbufr.open(bufrFileName)
    while bufr.advance() == 0:
        if bufr.msg_type == obsType:
            bufr.print_table()
            break
    bufr.close()

    return

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("ERROR: must supply exactly 2 arguments")
        print("bufrtbldump.py <BUFR path name> <observation type>")
        sys.exit(1)
    bufrtblstruc(sys.argv[1], sys.argv[2])
    sys.exit(0)



