#Errors lib.
import ../../../lib/Errors

#Hash lib.
import ../../../lib/Hash

#MinerWallet lib.
import ../../../Wallet/MinerWallet

#Verification object.
import ../../../Database/Consensus/Elements/objects/VerificationObj

#Common serialization functions.
import ../SerializeCommon

#SerializeElement method.
import SerializeElement
export SerializeElement

#Serialize a Verification.
method serialize*(
    verif: Verification
): string {.forceCheck: [].} =
    result =
        verif.holder.toBinary().pad(NICKNAME_LEN) &
        verif.hash.toString()

#Serialize a Verification for signing or a MeritRemoval.
method serializeWithoutHolder*(
    verif: Verification
): string {.forceCheck: [].} =
    result =
        char(VERIFICATION_PREFIX) &
        verif.hash.toString()

#Serialize a Verification for inclusion in a BlockHeader's contents merkle.
#This should never happen.
method serializeContents*(
    verif: Verification
): string {.forceCheck: [].} =
    doAssert(false, "Verification was serialized for inclusion in a BlockHeader's contents merkle.")

#Serialize a Signed Verification.
method signedSerialize*(
    verif: SignedVerification
): string {.forceCheck: [].} =
    result =
        verif.serialize() &
        verif.signature.toString()
