#This is named NetworkLibFunctionBox, not NetworkFunctionBox, `because GlobalFunctionBox` also defines a `NetworkFunctionBox`.

#Errors lib.
import ../../lib/Errors

#Hash lib.
import ../../lib/Hash

#Block lib.
import ../../Database/Merit/Block

#Transaction lib.
import ../../Database/Transactions/Transaction

#Message object.
import MessageObj

#Async standard lib.
import asyncdispatch

type NetworkLibFunctionBox* = ref object
    getNetworkID*: proc (): int {.noSideEffect, raises: [].}
    getProtocol*: proc (): int {.noSideEffect, raises: [].}

    getTail*: proc (): Hash[256] {.inline, raises: [].}

    getBlockHashBefore*: proc (
        hash: Hash[256]
    ): Hash[256] {.raises: [
        IndexError
    ].}

    getBlockHashAfter*: proc (
        hash: Hash[256]
    ): Hash[256] {.raises: [
        IndexError
    ].}

    getBlock*: proc (
        hash: Hash[256]
    ): Block {.raises: [
        IndexError
    ].}

    getTransaction*: proc (
        hash: Hash[256]
    ): Transaction {.raises: [
        IndexError
    ].}

    handle*: proc (
        msg: Message
    ): Future[void]

func newNetworkLibFunctionBox*(): NetworkLibFunctionBox {.forceCheck: [].} =
    NetworkLibFunctionBox()
