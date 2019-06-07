#Errors lib.
import ../../lib/Errors

#Hash lib.
import ../../lib/Hash

#MinerWallet lib.
import ../../Wallet/MinerWallet

#Mint object.
import objects/MintObj
export MintObj

#Serialization lib.
import ../../Network/Serialize/Transactions/SerializeMint

#Create a new Mint.
proc newMint*(
    nonce: int,
    key: BLSPublicKey,
    amount: uint64
): Mint {.forceCheck: [].} =
    #Create the result.
    result = newMintObj(
        nonce,
        key,
        amount
    )

    #Hash it.
    try:
        result.hash = Blake384(result.serializeHash())
    except FinalAttributeError as e:
        doAssert(false, "Set a final attribute twice when creating a Mint: " & e.msg)
