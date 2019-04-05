#Errors lib.
import ../../lib/Errors

#Util lib.
import ../../lib/Util

#Numerical libs.
import BN
import ../../lib/Base

#Hash lib.
import ../../lib/Hash

#BLS lib.
import ../../lib/BLS

#Index object.
import ../common/objects/IndexObj
#Export the Index object.
export IndexObj

#Verifications lib.
import ../Verifications/Verifications

#Merit lib.
import ../Merit/Merit

#DB Function Box object.
import ../../objects/GlobalFunctionBoxObj

#Entry and Entry descendants.
import objects/EntryObj
import Mint
import Claim
import Send
import Receive
import Data
#Export the Entry and Entry descendants.
export EntryObj
export Mint
export Claim
export Send
export Receive
export Data

#Account lib.
import Account
export Account

#Lattice Objects.
import objects/LatticeObj
export LatticeObj

#String utils standard lib.
import strutils

#Seq utils standard lib.
import sequtils

#Tables standard lib.
import tables

#Finals lib.
import finals

#Add a Verification to the Verifications' table.
proc verify*(
    lattice: Lattice,
    merit: Merit,
    verif: Verification,
    save: bool = true
): bool {.raises: [KeyError, ValueError, LMDBError].} =
    #Make sure the verifier has weight.
    if merit.state[verif.verifier] == uint(0):
        return false

    #Turn the hash into a string.
    var hash: string = verif.hash.toString()

    #Verify the Entry exists.
    if not lattice.lookup.hasKey(hash):
        return false

    #Create a blank seq if there's not already a seq.
    if not lattice.verifications.hasKey(hash):
        lattice.verifications[hash] = @[]

    #Return if the Verification already exists.
    for verifier in lattice.verifications[hash]:
        if verifier == verif.verifier:
            return false

    result = true

    #Add the Verification.
    lattice.verifications[hash].add(verif.verifier)

    #Calculate the weight.
    var weight: uint = 0
    for i in lattice.verifications[hash]:
        weight += merit.state[i]
    #If the Entry has at least 50.1% of the weight...
    if weight > ((merit.state.live div uint(2)) + 1):
        #Get the Index, Account, and calculate in `entries`.
        var
            index: Index = lattice.lookup[hash]
            account: Account = lattice[index.key]
            i: int = int(index.nonce - lattice[index.key].confirmed)

        #Get said Entry.
        var entry: Entry = nil
        for e in account.entries[i]:
            if e.hash == verif.hash:
                entry = e
        if entry.isNil:
            return false

        #Set it to verified.
        entry.verified = true

        #If we're not just reloading Verifications, and should update balances/save results to the DB...
        if save:
            echo hash.toHex() & " was verified."

            #Update the balance now that the Entry is confirmed.
            var changedBalance: bool = true
            case entry.descendant:
                #If it's a Send Entry...
                of EntryType.Send:
                    #Cast it to a var.
                    var send: Send = cast[Send](entry)
                    #Update the balance.
                    account.balance -= send.amount
                #If it's a Receive Entry...
                of EntryType.Receive:
                    var
                        #Cast it to a var.
                        recv: Receive = cast[Receive](entry)
                        #Get the Send it's Receiving.
                        send: Send = cast[Send](lattice[recv.index.key][recv.index.nonce])
                    #Update the balance.
                    account.balance += send.amount
                of EntryType.Claim:
                    var
                        #Cast it to a var.
                        claim: Claim = cast[Claim](entry)
                        #Get the Mint it's Claiming.
                        mint: Mint = cast[Mint](lattice["minter"][claim.mintNonce])
                    #Update the balance.
                    account.balance += mint.amount
                else:
                    changedBalance = false

            #If the balance was changed, save the new Balance to the DB.
            if changedBalance:
                lattice.db.put("lattice_" & entry.sender & "_balance", lattice[entry.sender].balance.toString(256))

#Constructor.
proc newLattice*(
    db: DatabaseFunctionBox,
    verifications: Verifications,
    merit: Merit,
    txDiff: string,
    dataDiff: string
): Lattice {.raises: [
    ValueError,
    ArgonError,
    BLSError,
    LMDBError,
    FinalAttributeError
].} =
    #Create the Lattice.
    result = newLatticeObj(
        db,
        txDiff,
        dataDiff
    )

    #Grab every Verifier mentioned in the last 6 Blocks of Verifications.
    var verifiers: seq[string] = @[]
    if merit.blockchain.height < 5:
        for b in uint(0) ..< merit.blockchain.height:
            for index in merit.blockchain[b].verifications:
                verifiers.add(index.key)
    else:
        for b in merit.blockchain.height - 5 ..< merit.blockchain.height:
            for index in merit.blockchain[b].verifications:
                verifiers.add(index.key)
    verifiers = verifiers.deduplicate()

    #Iterate over every Verifier.
    for verifier in verifiers:
        #Grab their epoch tip from the Merit database.
        var tip: int
        try:
            tip = db.get("merit_" & verifier & "_epoch").fromBinary()
        except:
            tip = 0

        #Load every verification.
        for v in tip ..< int(verifications[verifier].height):
            discard result.verify(merit, verifications[verifier][v], false)

#Add a Entry to the Lattice.
proc add*(
    lattice: Lattice,
    entry: Entry,
    mintOverride: bool = false
): bool {.raises: [ValueError, BLSError, SodiumError, LMDBError].} =
    #Make sure the sender is only minter when mintOverride is true.
    if (
        (entry.sender == "minter") and
        (not mintOverride)
    ):
        return false

    #Get the Account.
    var account: Account = lattice[entry.sender]

    case entry.descendant:
        of EntryType.Mint:
            #Add the casted entry.
            result = account.add(cast[Mint](entry))

        of EntryType.Claim:
            #Cast it to a claim.
            var claim: Claim = cast[Claim](entry)

            #Add the casted entry (and the Mint it's trying to claim).
            result = account.add(
                claim,
                cast[Mint](lattice["minter"][claim.mintNonce])
            )

        of EntryType.Send:
            #Cast the Entry.
            var send: Send = cast[Send](entry)

            #Add it.
            result = account.add(
                #Send Entry.
                send,
                #Transaction Difficulty.
                lattice.difficulties.transaction
            )

        of EntryType.Receive:
            var recv: Receive = cast[Receive](entry)

            result = account.add(
                #Receive Entry.
                recv,
                #Supposed Send Entry.
                lattice[
                    recv.index
                ]
            )

        of EntryType.Data:
            var data: Data = cast[Data](entry)

            result = account.add(
                #Data Entry.
                data,
                #Data Difficulty.
                lattice.difficulties.data
            )

    #If that didn't work, return.
    if not result:
        return

    #If this isn't a Mint, add the Entry to the lookup table.
    if entry.descendant != EntryType.Mint:
        lattice.addHash(
            entry.hash,
            newIndex(
                entry.sender,
                entry.nonce
            )
        )

proc mint*(
    lattice: Lattice,
    key: string,
    amount: BN
): uint {.raises: [
    ValueError,
    MintError,
    BLSError,
    SodiumError,
    LMDBError,
    FinalAttributeError
].} =
    #Store the height as the result.
    result = lattice["minter"].height

    #Create the Mint Entry.
    var mint: Mint = newMint(
        key,
        amount,
        result
    )

    #Add it to the Lattice.
    if not lattice.add(mint, true):
        raise newException(MintError, "Couldn't add the Mint Entry to the Lattice.")

    #Save the minter's new height to the DB.
    lattice.db.put("lattice_minter", lattice["minter"].height.toBinary())

    #Save the hash to the DB.
    lattice.db.put("lattice_minter_" & mint.nonce.toBinary(), mint.hash.toString())

    #Update the minter's confirmed field.
    lattice["minter"].confirmed = lattice["minter"].height
    lattice.db.put("lattice_minter_confirmed", lattice["minter"].confirmed.toBinary())

    #Clear the minter's cache.
    lattice["minter"].entries.delete(0)

#Remove every hash in this Epoch from the cache/RAM, updating confirmed.
proc archive*(
    lattice: Lattice,
    epoch: Epoch
) {.raises: [ValueError, LMDBError].} =
    for hash in epoch.keys():
        #Grab the Index for this hash.
        var index: Index
        try:
            index = lattice.lookup[hash]
        #If we couldn't grab it, it's because we're handling hashes out of order and already handled this one.
        except:
            continue

        #If this index points to a newer Entry than the previously newest Entry out of Epochs...
        if index.nonce >= lattice[index.key].confirmed:
            #Handle all previous Entries, if we're going out of order.
            while (
                (lattice[index.key].entries.len > 0) and
                (lattice[index.key].entries[0][0].nonce <= index.nonce)
            ):
                #Remove the hashes of all Entries at this position from the lookup/verifications table.
                for e in lattice[index.key].entries[0]:
                    lattice.rmHash(e.hash.toString())

                #Save the verified Entry's hash to the DB under SENDER_NONCE.
                lattice.db.put("lattice_" & lattice[index].sender & "_" & lattice[index.key].entries[0][0].nonce.toBinary(), lattice[index.key][0].hash.toString())

                #Clear these Entries at this position.
                lattice[index.key].entries.delete(0)

            #Update confirmed.
            lattice[index.key].confirmed = index.nonce + 1
            #Save the new confirmed to the DB.
            lattice.db.put("lattice_" & index.key & "_confirmed", lattice[index.key].confirmed.toBinary())
