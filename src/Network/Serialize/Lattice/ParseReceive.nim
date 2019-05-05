#Errors lib.
import ../../../lib/Errors

#Util lib.
import ../../../lib/Util

#Hash lib.
import ../../../lib/Hash

#Wallet lib.
import ../../../Wallet/Wallet

#LatticeIndex object,
import ../../../Database/common/objects/LatticeIndexObj

#Entry and Receive objects.
import ../../../Database/Lattice/objects/EntryObj
import ../../../Database/Lattice/objects/ReceiveObj

#Serialize common functions.
import ../SerializeCommon

#Parse a Receive.
proc parseReceive*(
    recvStr: string
): Receive {.forceCheck: [
    EdPublicKeyError
].} =
    var
        #Public Key | Nonce | Input Key | Input Nonce | Signature
        recvSeq: seq[string] = recvStr.deserialize(
            PUBLIC_KEY_LEN,
            INT_LEN,
            PUBLIC_KEY_LEN,
            INT_LEN,
            SIGNATURE_LEN
        )
        #Sender.
        sender: string
        #Get the nonce.
        nonce: int = recvSeq[1].fromBinary()
        #Input.
        inputAddress: string
        #Get the input nonce.
        inputNonce: int = recvSeq[3].fromBinary()
        #Get the signature.
        signature: EdSignature = newEdSignature(recvSeq[4])

    try:
        sender = newAddress(recvSeq[0])
        inputAddress = newAddress(recvSeq[2])
    except EdPublicKeyError as e:
        fcRaise e

    #Create the Receive.
    result = newReceiveObj(
        newLatticeIndex(
            inputAddress,
            inputNonce
        )
    )

    try:
        #Set the sender.
        result.sender = sender
        #Set the nonce.
        result.nonce = nonce

        #Set the hash.
        result.hash = Blake384("receive" & recvSeq.reserialize(1, 3))
        #Set the signature.
        result.signature = signature
        result.signed = true
    except FinalAttributeError as e:
        doAssert(false, "Set a final attribute twice when parsing a Receive: " & e.msg)
