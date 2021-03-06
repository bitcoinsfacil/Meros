#Tests the proper handling of Transactions which spend the same input twice.

#Types.
from typing import Dict, List, IO, Any

#Sketch class.
from PythonTests.Libs.Minisketch import Sketch

#Merit classes.
from PythonTests.Classes.Merit.Block import Block
from PythonTests.Classes.Merit.Merit import Merit

#VerificationPacket class.
from PythonTests.Classes.Consensus.VerificationPacket import VerificationPacket

#Transactions class.
from PythonTests.Classes.Transactions.Transactions import Transactions

#Exceptions.
from PythonTests.Tests.Errors import TestError, SuccessError

#Meros classes.
from PythonTests.Meros.RPC import RPC
from PythonTests.Meros.Meros import MessageType
from PythonTests.Meros.Liver import Liver

#JSON standard lib.
import json

#pylint: disable=too-many-statements
def SameInputTest(
    rpc: RPC
) -> None:
    file: IO[Any] = open("PythonTests/Vectors/Transactions/SameInput.json", "r")
    vectors: Dict[str, Any] = json.loads(file.read())
    file.close()

    #Merit.
    merit: Merit = Merit.fromJSON(vectors["blockchain"])
    #Transactions.
    transactions: Transactions = Transactions.fromJSON(vectors["transactions"])

    #Custom function to send the last Block and verify it errors at the right place.
    def checkFail() -> None:
        #This Block should cause the node to disconnect us AFTER it syncs our Transaction.
        syncedTX: bool = False

        #Grab the Block.
        block: Block = merit.blockchain.blocks[13]

        #Send the Block.
        rpc.meros.blockHeader(block.header)

        #Handle sync requests.
        reqHash: bytes = bytes()
        while True:
            try:
                msg: bytes = rpc.meros.recv()
            except TestError:
                if syncedTX:
                    raise SuccessError("Node disconnected us after we sent an invalid Transaction.")
                raise TestError("Node errored before syncing our Transaction.")

            if MessageType(msg[0]) == MessageType.Syncing:
                rpc.meros.syncingAcknowledged()

            elif MessageType(msg[0]) == MessageType.BlockBodyRequest:
                reqHash = msg[1 : 33]
                if reqHash != block.header.hash:
                    raise TestError("Meros asked for a Block Body that didn't belong to the Block we just sent it.")

                #Send the BlockBody.
                rpc.meros.blockBody(merit.state.nicks, block)

            elif MessageType(msg[0]) == MessageType.SketchHashesRequest:
                if not block.body.packets:
                    raise TestError("Meros asked for Sketch Hashes from a Block without any.")

                reqHash = msg[1 : 33]
                if reqHash != block.header.hash:
                    raise TestError("Meros asked for Sketch Hashes that didn't belong to the Block we just sent it.")

                #Create the haashes.
                hashes: List[int] = []
                for packet in block.body.packets:
                    hashes.append(Sketch.hash(block.header.sketchSalt, packet))

                #Send the Sketch Hashes.
                rpc.meros.sketchHashes(hashes)

            elif MessageType(msg[0]) == MessageType.SketchHashRequests:
                if not block.body.packets:
                    raise TestError("Meros asked for Verification Packets from a Block without any.")

                reqHash = msg[1 : 33]
                if reqHash != block.header.hash:
                    raise TestError("Meros asked for Verification Packets that didn't belong to the Block we just sent it.")

                #Create a lookup of hash to packets.
                packets: Dict[int, VerificationPacket] = {}
                for packet in block.body.packets:
                    packets[Sketch.hash(block.header.sketchSalt, packet)] = packet

                #Look up each requested packet and respond accordingly.
                for h in range(int.from_bytes(msg[33 : 37], byteorder="big")):
                    sketchHash: int = int.from_bytes(msg[37 + (h * 8) : 45 + (h * 8)], byteorder="big")
                    if sketchHash not in packets:
                        raise TestError("Meros asked for a non-existent Sketch Hash.")
                    rpc.meros.packet(packets[sketchHash])

            elif MessageType(msg[0]) == MessageType.TransactionRequest:
                reqHash = msg[1 : 33]

                if reqHash not in transactions.txs:
                    raise TestError("Meros asked for a non-existent Transaction.")

                rpc.meros.transaction(transactions.txs[reqHash])
                syncedTX = True

            elif MessageType(msg[0]) == MessageType.SyncingOver:
                pass

            elif MessageType(msg[0]) == MessageType.BlockHeader:
                #Raise a TestError if the Block was added.
                raise TestError("Meros synced a Transaction which spent the same input twice.")

            else:
                raise TestError("Unexpected message sent: " + msg.hex().upper())

    #Create and execute a Liver.
    Liver(rpc, vectors["blockchain"], transactions, callbacks={12: checkFail}).live()
