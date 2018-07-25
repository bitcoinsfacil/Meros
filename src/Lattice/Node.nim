#Number libs.
import BN
import ../lib/Base

#SHA512 lib.
import ../lib/SHA512 as SHA512File
import ../lib/Util

#Wallet libs.
import ../Wallet/Wallet

#Used to handle data strings.
import strutils

#Node object.
type Node* = ref object of RootObj
    #Data used to create the hash.
    #Input address. This address for a send node, a different one for a receive node.
    input*: string
    #Output address. This address for a receive node,  different one for a send node.
    output*: string
    #Amount transacted.
    amount*: BN
    #Data included in the TX.
    data*: string
    #Node hash.
    hash: string

    #Data used to prove it isn't spam.
    #Difficulty units.
    diffUnits*: BN
    #Work to prove this isn't spam.
    work*: BN
    #Argon2 hash.
    argon*: string

    #Data proved to validate ownership.
    #Node signature.
    signature*: string

    #Metadata about when the TX was accepted.
    time*: BN

#Create a new  node.
proc newNode*(input: string, output: string, amount: BN, data: string): Node {.raises: [ValueError, Exception].} =
    #verify input/output.
    if (not Wallet.verify(input)) or (not Wallet.verify(output)):
        raise newException(ValueError, "Node addresses are not valid.")

    #Verify the amount.
    if amount < BNNums.ZERO:
        raise newException(ValueError, "Node amount is negative.")

    #Verify the data argument.
    if data.len > 127:
        raise newException(ValueError, "Node data was too long.")

    #Turn data into a hex string in order to hash it.
    var dataHex: string = ""
    for i in 0 ..< data.len:
        dataHex = dataHex & ord(data[i]).toHex()

    #Craft the result.
    result = Node(
        input: input,
        output: output,
        amount: amount,
        data: data,
        hash: (SHA512^2)(
            input.substr(3, input.len).toBN(58).toString(16) &
            output.substr(3, output.len).toBN(58).toString(16) &
            amount.toString(16) &
            dataHex
        )
    )

#Mine a TX.
proc mine*(toMine: Node, networkDifficulty: BN) {.raises: [].} =
    toMine.diffUnits = newBN(1 + (toMine.data.len * 2))

    var difficulty: BN = toMine.diffUnits * networkDifficulty

#Sign a TX.
proc sign*(wallet: Wallet, toSign: Node): bool {.raises: [ValueError, Exception].} =
    #Set a default return value of true.
    result = true

    #Create a new node and make sure the newNode proc doesn't throw an error.
    var newNode: Node
    try:
        newNode = newNode(
            toSign.input,
            toSign.output,
            toSign.amount,
            toSign.data,
        )
    except:
        result = false
        return

    if toSign.hash != newNode.hash:
        result = false
        return

    if toSign.diffUnits != newBN(1 + (2 * toSign.data.len)):
        result = false
        return

    #Verify work and Argon2 hash.

    #Sign the Argon2 hash of the TX.
    toSign.signature = wallet.sign(toSign.argon)
