include ClientSendRecv

#Handshake.
proc handshake*(
    client: Client,
    id: int,
    protocol: int,
    server: bool,
    tail: Hash[256]
): Future[Hash[256]] {.forceCheck: [
    ClientError
], async.} =
    try:
        #Send a handshake.
        await client.send(
            newMessage(
                MessageType.Handshake,
                char(id) &
                char(protocol) &
                (if server: char(1) else: char(0)) &
                tail.toString()
            )
        )

        #Get their handshake back.
        var handshake: Message = await client.recv()

        #Verify their handshake is a handshake.
        if handshake.content != MessageType.Handshake:
            raise newException(ClientError, "Client responded to a Handshake with something other than a handshake.")

        #Deserialize their message.
        var handshakeSeq: seq[string] = handshake.message.deserialize(
            BYTE_LEN,
            BYTE_LEN,
            BYTE_LEN,
            HASH_LEN
        )
        #Verify their Network ID.
        if int(handshakeSeq[0][0]) != id:
            raise newException(ClientError, "Client responded to a Handshake with a different Network ID.")
        #Verify their Protocol version.
        if int(handshakeSeq[1][0]) != protocol:
            raise newException(ClientError, "Client responded to a Handshake with a different Protocol Version.")

        if int(handshakeSeq[2][0]) == 1:
            client.server = true

        #Return their tail.
        try:
            result = handshake.message[3 ..< 35].toHash(256)
        except ValueError as e:
            doAssert(false, "Couldn't turn a 32-byte string into a 32-byte hash: " & e.msg)
    except ClientError as e:
        raise e
    except Exception as e:
        doAssert(false, "Handshaking with a Client threw an Exception despite catching all thrown Exceptions: " & e.msg)
