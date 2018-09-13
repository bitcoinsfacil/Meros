#Numerical libs.
import BN
import ../src/lib/Base

#Wallet lib.
import ../src/Wallet/Wallet

#Send/Receive nodes.
import ../src/Database/Lattice/Send
import ../src/Database/Lattice/Receive

#Serialization libs.
import ../src/Network/Serialize/SerializeSend
import ../src/Network/Serialize/SerializeReceive

#SetOnce lib.
import SetOnce

var
    sender: Wallet = newWallet()   #Sender's wallet.
    receiver: Wallet = newWallet() #Receiver's wallet.
    send: Send = newSend(          #Send.
        receiver.address,
        newBN("10000000000"),
        newBN()
    )
    recv: Receive = newReceive(    #Receive.
        sender.address,
        newBN(),
        newBN()
    )

#Mine and sign the Send.
send.mine("3333333333333333333333333333333333333333333333333333333333333333".toBN(16))
discard sender.sign(send)

#Sign the Receive.
receiver.sign(recv)

#Print info on them. The length is better than a garbage string.
echo "The serialized Send is " & $send.serialize().len & " bytes long."
echo "The serialized Receive is " & $recv.serialize().len & " bytes long."
