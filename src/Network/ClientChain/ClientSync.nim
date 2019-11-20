include ClientHandshake

#Tell the Client we're syncing.
proc startSyncing*(
    client: Client
) {.forceCheck: [
    ClientError
], async.} =
    #Increment syncLevels.
    inc(client.syncLevels)

    #If we're already syncing, return.
    if client.syncLevels != 1:
        return

    try:
        #Send that we're syncing.
        await client.send(newMessage(MessageType.Syncing))

        #Bool of if we should still wait for a SyncingAcknowledged.
        #Set to false after 5 seconds.
        var shouldWait: bool = true
        try:
            addTimer(
                5000,
                true,
                func (
                    fd: AsyncFD
                ): bool {.forceCheck: [].} =
                    shouldWait = false
            )
        except OSError as e:
            doAssert(false, "Couldn't set a timer due to an OSError: " & e.msg)

        #Discard every message until we get a SyncingAcknowledged.
        var msg: Message
        while shouldWait:
            msg = await client.recv()
            if msg.content == SyncingAcknowledged:
                break

        #If we broke because shouldWait expired, raise a client error.
        if not shouldWait:
            raise newException(ClientError, "Client never responded to the fact we were syncing.")
    except ClientError as e:
        fcRaise e
    except Exception as e:
        doAssert(false, "Starting Syncing with a Client threw an Exception despite catching all thrown Exceptions: " & e.msg)

#Sync a Transaction.
proc syncTransaction*(
    client: Client,
    hash: Hash[384],
    sendDiff: Hash[384],
    dataDiff: Hash[384]
): Future[Transaction] {.forceCheck: [
    ClientError,
    DataMissing,
    Spam
], async.} =
    try:
        #Send the request.
        await client.send(newMessage(MessageType.TransactionRequest, hash.toString()))

        #Get their response.
        var msg: Message = await client.recv()

        #Parse the response.
        try:
            case msg.content:
                of MessageType.Claim:
                    result = msg.message.parseClaim()
                of MessageType.Send:
                    result = msg.message.parseSend(sendDiff)
                of MessageType.Data:
                    result = msg.message.parseData(dataDiff)
                of MessageType.DataMissing:
                    raise newException(DataMissing, "Client didn't have the requested Transaction.")
                else:
                    raise newException(ClientError, "Client didn't respond properly to our TransactionRequest.")
        except ValueError as e:
            raise newException(ClientError, "Client didn't respond with a valid Transaction to our TransactionRequest, as pointed out by a ValueError: " & e.msg)
        except BLSError as e:
            raise newException(ClientError, "Client didn't respond with a valid Transaction to our TransactionRequest, as pointed out by a BLSError: " & e.msg)
        except EdPublicKeyError as e:
            raise newException(ClientError, "Client didn't respond with a valid Transaction to our TransactionRequest, as pointed out by a EdPublicKeyError: " & e.msg)

        #Verify the received data is what was requested.
        if result.hash != hash:
            raise newException(ClientError, "Client sent us the wrong Transaction.")
    except ClientError as e:
        fcRaise e
    except DataMissing as e:
        fcRaise e
    except Spam as e:
        if e.hash != hash:
            raise newException(ClientError, "Client sent us the wrong Transaction.")
        fcRaise e
    except Exception as e:
        doAssert(false, "Sending a `TransactionRequest` and receiving the response threw an Exception despite catching all thrown Exceptions: " & e.msg)

#Sync Verification Packets.
proc syncVerificationPackets*(
    client: Client,
    blockHash: Hash[384],
    sketchHashes: seq[uint64],
    sketchSalt: string
): Future[seq[VerificationPacket]] {.forceCheck: [
    ClientError,
    DataMissing
], async.} =
    try:
        #Send the request.
        var req: string = blockHash.toString() & sketchHashes.len.toBinary().pad(4)
        for hash in sketchHashes:
            req &= hash.toBinary().pad(8)
        await client.send(newMessage(MessageType.SketchHashRequests, req))

        for sketchHash in sketchHashes:
            #Get their response.
            var msg: Message = await client.recv()

            #Parse the response.
            try:
                case msg.content:
                    of MessageType.VerificationPacket:
                        result.add(msg.message.parseVerificationPacket())
                    of MessageType.DataMissing:
                        raise newException(DataMissing, "Client didn't have the requested VerificationPacket.")
                    else:
                        raise newException(ClientError, "Client didn't respond properly to our SketchHashRequests.")
            except ValueError as e:
                raise newException(ClientError, "Client didn't respond with a valid VerificationPacket to our SketchHashRequests, as pointed out by a ValueError: " & e.msg)

            if sketchHash(result[^1], sketchSalt) != sketchHash:
                raise newException(ClientError, "Client didn't respond with the right VerificationPacket for our SketchHashRequests.")
    except ClientError as e:
        fcRaise e
    except DataMissing as e:
        fcRaise e
    except Exception as e:
        doAssert(false, "Sending a `SketchHashRequests` and receiving the responses threw an Exception despite catching all thrown Exceptions: " & e.msg)

#Sync Sketch Hashes.
proc syncSketchHashes*(
    client: Client,
    hash: Hash[384]
): Future[seq[uint64]] {.forceCheck: [
    ClientError,
    DataMissing
], async.} =
    try:
        #Send the request.
        await client.send(newMessage(MessageType.SketchHashesRequest, hash.toString()))

        #Get the response.
        var msg: Message = await client.recv()

        #Parse out the sketch hashes.
        for i in 0 ..< msg.message[0 ..< 4].fromBinary():
            result.add(uint64(msg.message[4 + (i * 8) ..< 12 + (i * 8)].fromBinary()))
    except ClientError as e:
        fcRaise e
    except DataMissing as e:
        fcRaise e
    except Exception as e:
        doAssert(false, "Sending a `SketchHashesRequest` and receiving the responses threw an Exception despite catching all thrown Exceptions: " & e.msg)

#Sync a BlockBody.
proc syncBlockBody*(
    client: Client,
    hash: Hash[384]
): Future[SketchyBlockBody] {.forceCheck: [
    ClientError,
    DataMissing
], async.} =
    try:
        #Send the request.
        await client.send(newMessage(MessageType.BlockBodyRequest, hash.toString()))

        #Get their response.
        var msg: Message = await client.recv()

        #Parse the response.
        try:
            case msg.content:
                of MessageType.BlockBody:
                    result = msg.message.parseBlockBody()
                of MessageType.DataMissing:
                    raise newException(DataMissing, "Client didn't have the requested BlockBody.")
                else:
                    raise newException(ClientError, "Client didn't respond properly to our BlockBodyRequest.")
        except ValueError as e:
            raise newException(ClientError, "Client didn't respond with a valid BlockBody to our BlockBodyRequest, as pointed out by a ValueError: " & e.msg)
        except BLSError as e:
            raise newException(ClientError, "Client didn't respond with a valid BlockBody to our BlockBodyRequest, as pointed out by a BLSError: " & e.msg)
    except ClientError as e:
        fcRaise e
    except DataMissing as e:
        fcRaise e
    except Exception as e:
        doAssert(false, "Sending a `BlockBodyRequest` and receiving the response threw an Exception despite catching all thrown Exceptions: " & e.msg)

#Sync a BlockHeader.
proc syncBlockHeader*(
    client: Client,
    hash: Hash[384]
): Future[BlockHeader] {.forceCheck: [
    ClientError,
    DataMissing
], async.} =
    try:
        #Send the request.
        await client.send(newMessage(MessageType.BlockHeaderRequest, hash.toString()))

        #Get their response.
        var msg: Message = await client.recv()

        #Parse the response.
        try:
            case msg.content:
                of MessageType.BlockHeader:
                    result = msg.message.parseBlockHeader()
                of MessageType.DataMissing:
                    raise newException(DataMissing, "Client didn't have the requested BlockHeader.")
                else:
                    raise newException(ClientError, "Client didn't respond properly to our BlockHeaderRequest.")
        except ValueError as e:
            raise newException(ClientError, "Client didn't respond with a valid BlockHeader to our BlockHeaderRequest, as pointed out by a ValueError: " & e.msg)
        except BLSError as e:
            raise newException(ClientError, "Client didn't respond with a valid BlockHeader to our BlockHeaderRequest, as pointed out by a BLSError: " & e.msg)

        #Verify the received data is what was requested.
        if result.hash != hash:
            raise newException(ClientError, "Client sent us the wrong BlockHeader.")
    except ClientError as e:
        fcRaise e
    except DataMissing as e:
        fcRaise e
    except Exception as e:
        doAssert(false, "Sending a `BlockHeaderRequest` and receiving the response threw an Exception despite catching all thrown Exceptions: " & e.msg)

#Sync a Block List.
proc syncBlockList*(
    client: Client,
    forwards: bool,
    amount: int,
    hash: Hash[384]
): Future[seq[Hash[384]]] {.forceCheck: [
    ClientError,
    DataMissing
], async.} =
    try:
        #Send the request.
        await client.send(newMessage(MessageType.BlockListRequest, (if forwards: '\1' else: '\0') & char(amount - 1) & hash.toString()))

        #Get their response.
        var msg: Message = await client.recv()

        #Parse the response.
        try:
            case msg.content:
                of MessageType.BlockList:
                    for h in countup(1, msg.message.len - 2, 48):
                        result.add(msg.message[h ..< h + 48].toHash(384))
                of MessageType.DataMissing:
                    raise newException(DataMissing, "Client didn't have the requested Block List.")
                else:
                    raise newException(ClientError, "Client didn't respond properly to our BlockListRequest.")
        except ValueError as e:
            doAssert(false, "48-byte string isn't a valid 48-byte hash: " & e.msg)
    except ClientError as e:
        fcRaise e
    except DataMissing as e:
        fcRaise e
    except Exception as e:
        doAssert(false, "Sending a `BlockListRequest` and receiving the response threw an Exception despite catching all thrown Exceptions: " & e.msg)

#Tell the Client we're done syncing.
proc stopSyncing*(
    client: Client
) {.forceCheck: [
    ClientError
], async.} =
    #decrement syncLevels.
    dec(client.syncLevels)

    #If this isn't the last sync level, return.
    if client.syncLevels != 0:
        return

    try:
        #Send that we're done syncing.
        await client.send(newMessage(MessageType.SyncingOver))
    except ClientError as e:
        fcRaise e
    except Exception as e:
        doAssert(false, "Starting Syncing with a Client threw an Exception despite catching all thrown Exceptions: " & e.msg)
