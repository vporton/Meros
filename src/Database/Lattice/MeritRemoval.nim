#Numerical libs.
import ../../lib/BN
import ../../lib/Base

#SHA512 lib.
import ../../lib/SHA512

#Errors lib.
import ../../lib/Errors

#Wallet lib.
import ../../Wallet/Wallet

#Import the Serialization library.
import ../../Network/Serialize

#Node object and Verification lib.
import objects/NodeObj
import Verification

#MeritRemoval object.
import objects/MeritRemovalObj
export MeritRemovalObj

#Create a new MeritRemoval object.
proc newMeritRemoval*(first: Verification, second: Verification, nonce: BN): MeritRemoval {.raises: [ResultError, ValueError, Exception].} =
    #Create the MeritRemoval.
    result = newMeritRemovalObj(first, second)

    #Set the descendant type.
    if not result.setDescendant(5):
        raise newException(ResultError, "Couldn't set the node's descendant type.")

    #Set the nonce.
    if not result.setNonce(nonce):
        raise newException(ResultError, "Couldn't set the Merit Removal nonce.")

    #Set the hash.
    if not result.setHash(SHA512(result.serialize())):
        raise newException(ResultError, "Couldn't set the Merit Removal hash.")

#Sign a MeritRemoval object.
proc sign*(wallet: Wallet, mr: MeritRemoval): bool {.raises: [ValueError].} =
    result = true

    #Set the sender behind the node.
    if not mr.setSender(wallet.getAddress()):
        result = false
        return

    #Sign the hash of the MR.
    if not mr.setSignature(wallet.sign(mr.getHash())):
        result = false
        return