#Serialize Data Test.

#Base lib.
import ../../../../src/lib/Base

#Hash lib.
import ../../../../src/lib/Hash

#Wallet lib.
import ../../../../src/Wallet/Wallet

#Entry object and the Data lib.
import ../../../../src/Database/Lattice/objects/EntryObj
import ../../../../src/Database/Lattice/Data

#Serialize lib.
import ../../../../src/Network/Serialize/Lattice/SerializeData
import ../../../../src/Network/Serialize/Lattice/ParseData

#String utils standard lib.
import strutils

#Test data.
var tests: seq[string] = @[
    "",
    "123",
    "abc",
    "abcdefghijklmnopqrstuvwxyz",
    "Test",
    "Test1",
    "Test2",
    "This is a longer Test.",
    "Now we have special character.\r\n",
    "\0\0This Test starts with leading 0s and is meant to Test Issue #46.",
    "Write the tests they said.",
    "Make up phrases they said.",
    "Well here are the phrases.",
    "#^&^%^&*",
    "Phrase.",
    "Another phrase.",
    "Yet another phrase.",
    "This is 32 characters long.     ",
    " This is 255 characters long.   ".repeat(8).substr(1),
    "This is the 20th Test because I wanted a nice number."
]

#Test 20 serializations.
for i in 1 .. 20:
    echo "Testing Data Serialization/Parsing, iteration " & $i & "."

    var
        #Wallet.
        wallet: Wallet = newWallet()
        #Data.
        data: Data = newData(
            tests[i - 1],
            0
        )

    #Sign it.
    wallet.sign(data)
    #Mine the Data.
    data.mine("3333333333333333333333333333333333333333333333333333333333333333".toBN(16))

    #Serialize it and parse it back.
    var dataParsed: Data = data.serialize().parseData()

    #Test the serialized versions.
    assert(data.serialize() == dataParsed.serialize())

    #Test the Entry properties.
    assert(data.descendant == dataParsed.descendant)
    assert(data.sender == dataParsed.sender)
    assert(data.nonce == dataParsed.nonce)
    assert(data.hash == dataParsed.hash)
    assert(data.signature == dataParsed.signature)
    assert(data.verified == dataParsed.verified)

    #Test the Data properties.
    assert(data.data == dataParsed.data)
    assert(data.proof == dataParsed.proof)
    assert(data.argon == dataParsed.argon)

echo "Finished the Network/Serialize/Lattice/Data Test."
