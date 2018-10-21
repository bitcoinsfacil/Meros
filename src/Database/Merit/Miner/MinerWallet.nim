#Errors lib.
import ../../../lib/Errors

#BLS lib.
import ../../../lib/BLS

#Finals lib.
import finals

#nimcrypto; used to generate a valid seed.
import nimcrypto

#String utils standard lib.
import strutils

finalsd:
    #Miner object.
    type MinerWallet* = ref object of RootObj
        #Private Key.
        privateKey* {.final.}: BLSPrivateKey
        #Public Key.
        publicKey* {.final.}: BLSPublicKey

#Constructors.
proc newMinerWallet*(): MinerWallet {.raises: [RandomError, BLSError].} =
    #Create a seed.
    var seed: string = newString(32)
    try:
        #Use nimcrypto to fill the Seed with random bytes.
        if randomBytes(seed) != 32:
            raise newException(RandomError, "Couldn't get enough bytes for the Seed.")
    except:
        raise newException(RandomError, getCurrentExceptionMsg())

    var priv: BLSPrivateKey
    try:
        priv = newBLSPrivateKeyFromSeed(seed)
    except:
        raise newException(BLSError, "Couldn't create a Private Key. " & getCurrentExceptionMsg())

    result = MinerWallet(
        privateKey: priv,
        publicKey: priv.getPublicKey()
    )

proc newMinerWallet*(priv: BLSPrivateKey): MinerWallet {.raises: [].} =
    result = MinerWallet(
        privateKey: priv,
        publicKey: priv.getPublicKey()
    )

#Sign a message via a MinerWallet.
func sign*(miner: MinerWallet, msg: string): BLSSignature {.raises: [].} =
    miner.privateKey.sign(msg)

#Verify a message.
proc verify*(
    miner: MinerWallet,
    msg: string,
    sigArg: string
): bool {.raises: [BLSError].} =
    #Create the Signature.
    var sig: BLSSignature
    try:
        sig = newBLSSignature(sigArg)
    except:
        raise newException(BLSError, "Couldn't load the BLS Signature.")

    #Create the Aggregation Info.
    var agInfo: BLSAggregationInfo
    try:
        agInfo = newBLSAggregationInfo(miner.publicKey, msg)
    except:
        raise newException(BLSError, "Couldn't load the BLS Aggregation Info.")

    #Add the Aggregation Info to the signature.
    sig.setAggregationInfo(agInfo)

    #Verify the signature.
    result = sig.verify()