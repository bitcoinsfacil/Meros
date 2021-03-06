include MainConsensus

#Creates and publishes a Verification.
proc verify(
    transaction: Transaction
) {.forceCheck: [], async.} =
    #Make sure we're a Miner with Merit.
    if wallet.miner.initiated and (merit.state[wallet.miner.nick] > 0):
        #Inform the WalletDB were verifying a Transaction.
        try:
            wallet.verifyTransaction(transaction)
        #We already verified a competitor.
        except ValueError:
            return

        #Make sure this Transaction can be verified.
        try:
            if consensus.getStatus(transaction.hash).beaten:
                return
        except IndexError as e:
            doAssert(false, "Asked to verify a Transaction without a Status: " & e.msg)

        #Verify the Transaction.
        var verif: SignedVerification = newSignedVerificationObj(transaction.hash)
        wallet.miner.sign(verif)

        #Add the Verification.
        try:
            functions.consensus.addSignedVerification(verif)
        except ValueError as e:
            doAssert(false, "Created a Verification with an invalid signature: " & e.msg)
        except DataExists as e:
            doAssert(false, "Created a Verification which already exists: " & e.msg)

proc mainTransactions() {.forceCheck: [].} =
    {.gcsafe.}:
        #Create the Transactions.
        transactions = newTransactions(database, merit.blockchain)

        #Handle requests for an Transaction.
        functions.transactions.getTransaction = proc (
            hash: Hash[256]
        ): Transaction {.forceCheck: [
            IndexError
        ].} =
            try:
                result = transactions[hash]
            except IndexError as e:
                try:
                    result = consensus.getMeritRemovalTransaction(hash)
                except IndexError:
                    raise e

        #Get a Transaction's spenders.
        functions.transactions.getSpenders = proc (
            input: Input
        ): seq[Hash[256]] {.inline, forceCheck: [].} =
            transactions.loadSpenders(input)

        #Handle Claims.
        functions.transactions.addClaim = proc (
            claim: Claim,
            syncing: bool = false
        ) {.forceCheck: [
            ValueError,
            DataExists
        ].} =
            #Print that we're adding the Claim.
            echo "Adding a new Claim."

            #Add the Claim.
            try:
                transactions.add(claim, functions.merit.getPublicKey)
            #Passing a function which can raise IndexError raised one.
            except IndexError as e:
                doAssert(false, "Passing a function which can raise an IndexError raised an IndexError: " & e.msg)
            #Invalid Claim.
            except ValueError as e:
                raise e
            #Data already exists.
            except DataExists as e:
                raise e

            #Register the Claim with Consensus.
            consensus.register(merit.state, claim, merit.blockchain.height)

            echo "Successfully added the Claim."

            if not syncing:
                #Broadcast the Claim.
                functions.network.broadcast(
                    MessageType.Claim,
                    claim.serialize()
                )

                #Create a Verification.
                try:
                    asyncCheck verify(claim)
                except Exception as e:
                    doAssert(false, "Verify threw an Exception despite not naturally throwing anything: " & e.msg)

        #Handle Sends.
        functions.transactions.addSend = proc (
            send: Send,
            syncing: bool = false
        ) {.forceCheck: [
            ValueError,
            DataExists
        ].} =
            #Print that we're adding the Send.
            echo "Adding a new Send."

            #Add the Send.
            try:
                transactions.add(send)
            #Invalid Send.
            except ValueError as e:
                raise e
            #Data already exisrs.
            except DataExists as e:
                raise e

            #Register the Send with Consensus.
            consensus.register(merit.state, send, merit.blockchain.height)

            echo "Successfully added the Send."

            if not syncing:
                #Broadcast the Send.
                functions.network.broadcast(
                    MessageType.Send,
                    send.serialize()
                )

                #Create a Verification.
                try:
                    asyncCheck verify(send)
                except Exception as e:
                    doAssert(false, "Verify threw an Exception despite not naturally throwing anything: " & e.msg)

        #Handle Datas.
        functions.transactions.addData = proc (
            data: Data,
            syncing: bool = false
        ) {.forceCheck: [
            ValueError,
            DataExists
        ].} =
            #Print that we're adding the Data.
            echo "Adding a new Data."

            #Add the Data.
            try:
                transactions.add(data)
            #Invalid Data.
            except ValueError as e:
                raise e
            #Data already exisrs.
            except DataExists as e:
                raise e

            #Register the Data with Consensus.
            consensus.register(merit.state, data, merit.blockchain.height)

            echo "Successfully added the Data."

            if not syncing:
                #Broadcast the Data.
                functions.network.broadcast(
                    MessageType.Data,
                    data.serialize()
                )

                #Create a Verification.
                try:
                    asyncCheck verify(data)
                except Exception as e:
                    doAssert(false, "Verify threw an Exception despite not naturally throwing anything: " & e.msg)

        #Mark a Transaction as verified.
        functions.transactions.verify = proc (
            hash: Hash[256]
        ) {.forceCheck: [].} =
            transactions.verify(hash)

        #Mark a Transaction as unverified.
        functions.transactions.unverify = proc (
            hash: Hash[256]
        ) {.forceCheck: [].} =
            transactions.unverify(hash)
