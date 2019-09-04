#TransactionsDB Spendable Test.
#Tests saving UTXOs, checking which UYTXOs an account can spend, and deleting UTXOs.

#Util lib.
import ../../../../../src/lib/Util

#Hash lib.
import ../../../../../src/lib/Hash

#Wallet lib.
import ../../../../../src/Wallet/Wallet

#TransactionDB lib.
import ../../../../../src/Database/Filesystem/DB/TransactionsDB

#Input/Output objects.
import ../../../../../src/Database/Transactions/objects/TransactionObj

#Send lib.
import ../../../../../src/Database/Transactions/Send

#Test Database lib.
import ../../../TestDatabase

#Algorithm standard lib.
import algorithm

#Tables lib.
import tables

#Random standard lib.
import random

proc test*() =
    #Seed Random via the time.
    randomize(int64(getTime()))

    var
        #DB.
        db = newTestDatabase()
        #Wallets.
        wallets: seq[Wallet] = @[]

        #Outputs.
        outputs: seq[SendOutput]
        #Send.
        send: Send

        #Public Key -> Spendable Outputs.
        spendable: OrderedTable[string, seq[SendInput]]
        #Inputs.
        inputs: seq[SendInput]
        #Loaded Spendable.
        loaded: seq[SendInput]

    proc compare() =
        #Test each spendable.
        for key in spendable.keys():
            loaded = db.loadSpendable(newEdPublicKey(key))

            assert(spendable[key].len == loaded.len)
            for i in 0 ..< spendable[key].len:
                assert(spendable[key][i].hash == loaded[i].hash)
                assert(spendable[key][i].nonce == loaded[i].nonce)

    #Generate 10 wallets.
    for _ in 0 ..< 10:
        wallets.add(newWallet(""))

    #Test 100 Transactions.
    for _ in 0 .. 100:
        outputs = newSeq[SendOutput](rand(254) + 1)
        for o in 0 ..< outputs.len:
            outputs[o] = newSendOutput(
                wallets[rand(10 - 1)].publicKey,
                0
            )

        send = newSend(@[], outputs)
        db.save(send)

        if rand(2) != 0:
            db.verify(send)
            for o in 0 ..< outputs.len:
                if not spendable.hasKey(outputs[o].key.toString()):
                    spendable[outputs[o].key.toString()] = @[]
                spendable[outputs[o].key.toString()].add(
                    newSendInput(send.hash, o)
                )

        compare()

        #Spend outputs.
        for key in spendable.keys():
            if spendable[key].len == 0:
                continue

            inputs = @[]
            var i: int = 0
            while true:
                if rand(1) == 0:
                    inputs.add(spendable[key][i])
                    spendable[key].delete(i)
                else:
                    inc(i)

                if i == spendable[key].len:
                    break

            if inputs.len != 0:
                var outputKey: EdPublicKey = wallets[rand(10 - 1)].publicKey
                send = newSend(inputs, newSendOutput(outputKey, 0))
                db.save(send)
                db.verify(send)

                if not spendable.hasKey(outputKey.toString()):
                    spendable[outputKey.toString()] = @[]
                spendable[outputKey.toString()].add(newSendInput(send.hash, 0))

        compare()

    echo "Finished the Database/Filesystem/DB/TransactionsDB/Spendable Test."
