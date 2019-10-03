#Serialize BlockBody Test.

#Util lib.
import ../../../../src/lib/Util

#Hash lib.
import ../../../../src/lib/Hash

#MinerWallet lib.
import ../../../../src/Wallet/MinerWallet

#Elements Testing lib.
import ../../../DatabaseTests/ConsensusTests/ElementsTests/TestElements

#BlockBody object.
import ../../../../src/Database/Merit/objects/BlockBodyObj

#Serialize libs.
import ../../../../src/Network/Serialize/Merit/SerializeBlockBody
import ../../../../src/Network/Serialize/Merit/ParseBlockBody

#Compare Merit lib.
import ../../../DatabaseTests/MeritTests/CompareMerit

#Random standard lib.
import random

proc test*() =
    #Seed Random via the time.
    randomize(int64(getTime()))

    var
        #Hash.
        hash: Hash[384]
        #Transactions.
        transactions: seq[Hash[384]] = @[]
        #Elements.
        elements: seq[BlockElement] = @[]
        #Block Body.
        body: BlockBody
        #Reloaded Block Body.
        reloaded: BlockBody

    #Test 255 serializations.
    for s in 0 .. 255:
        #Randomize the transactions.
        for _ in 0 ..< rand(300):
            for b in 0 ..< 48:
                hash.data[b] = uint8(rand(255))
            transactions.add(hash)

        #Randomize the elements.
        for _ in 0 ..< rand(300):
            elements.add(newRandomBlockElement())

        #Create the BlockBody with a randomized aggregate signature.
        body = newBlockBodyObj(
            transactions,
            elements,
            newMinerWallet().sign($rand(4096))
        )

        #Serialize it and parse it back.
        reloaded = body.serialize().parseBlockBody()

        #Test the serialized versions.
        assert(body.serialize() == reloaded.serialize())

        #Compare the BlockBodies.
        compare(body, reloaded)

        #Clear the elements.
        elements = @[]

    echo "Finished the Network/Serialize/Merit/BlockBody Test."
