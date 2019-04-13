discard """
This is named NetworkLibFB, not NetworkFB, `because GlobalFunctionBox` also defines a `NetworkFunctionBox`.
"""

#Errors lib.
import ../../lib/Errors

#Block lib.
import ../../Database/Merit/Block

#Message object.
import MessageObj

#Async standard lib.
import asyncdispatch

type NetworkLibFunctionBox* = ref object of RootObj
    getNetworkID*: proc (): int {.raises: [].}
    getProtocol*:  proc (): int {.raises: [].}
    getHeight*:    proc (): int {.raises: [LMDBError].}

    handle*: proc (msg: Message): Future[bool]
    handleBlock*: proc (newBlock: Block): Future[bool]

proc newNetworkLibFunctionBox*(): NetworkLibFunctionBox {.raises: [].} =
    NetworkLibFunctionBox()
