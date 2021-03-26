#!/usr/bin/env python

#==============================================================================
# lists the observation (subset message) types in a BUFR file
#==============================================================================

import ncepbufr
import sys

def bufrmsgtypelist(bufrFileName):

    msgTypeList = []

    fd1 = ncepbufr.open(bufrFileName, mode='r')
    
    currentMsgType = ""
    while fd1.advance() == 0:
        if fd1.msg_type != currentMsgType:
            currentMsgType = fd1.msg_type
            if not (currentMsgType in msgTypeList):
                msgTypeList.append(currentMsgType)

    fd1.close()

    print(f"File {bufrFileName} contains the following observation types:")
    print('\n'.join(msgTypeList))

    return


if __name__ == "__main__":
    bufrmsgtypelist(sys.argv[1])

