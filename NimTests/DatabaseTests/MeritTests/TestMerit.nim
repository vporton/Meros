#Merit Testing Functions.

#Util lib.
import ../../../src/lib/Util

#Hash and Merkle libs.
import ../../../src/lib/Hash
import ../../../src/lib/Merkle

#Sketcher lib.
import ../../../src/lib/Sketcher

#MinerWallet lib.
import ../../../src/Wallet/MinerWallet

#Element lib.
import ../../../src/Database/Consensus/Elements/Element

#Element Serialization libs.
import ../../../src/Network/Serialize/Consensus/SerializeVerification
import ../../../src/Network/Serialize/Consensus/SerializeVerificationPacket
import ../../../src/Network/Serialize/Consensus/SerializeMeritRemoval

#Block lib.
import ../../../src/Database/Merit/Block

#Test Database lib.
import ../TestDatabase
export TestDatabase

#Random standard lib.
import random

#Algorithm standard lib.
import algorithm

#Create a valid VerificationPacket.
proc newValidVerificationPacket*(
    holders: seq[BLSPublicKey],
    exclude: seq[uint16] = @[],
    hashArg: Hash[384] = Hash[384]()
): VerificationPacket =
    var hash: Hash[384] = hashArg
    if hash == Hash[384]():
        for b in 0 ..< 48:
            hash.data[b] = uint8(rand(255))

    result = newVerificationPacketObj(hash)
    for h in 0 ..< holders.len:
        var found: bool = false
        for e in exclude:
            if uint16(h) == e:
                found = true
                break
        if found:
            continue

        if rand(1) == 0:
            result.holders.add(uint16(h))

    #Make sure there's at least one holder.
    while result.holders.len == 0:
        var
            h: uint16 = uint16(rand(high(holders)))
            found: bool = false
        for e in exclude:
            if h == e:
                found = true
                break
        if found:
            continue

        result.holders.add(uint16(h))

#Create a contents Merkle.
proc newContents(
    sketchSalt: string = newString(4),
    packets: seq[VerificationPacket] = @[],
    elements: seq[BlockElement] = @[],
): Hash[384] =
    #Verify the contents merkle.
    if (packets.len != 0) or (elements.len != 0):
        var
            sketchHashes: seq[uint64] = @[]
            packetsSide: Merkle = newMerkle()

            elementsSide: Merkle = newMerkle()

        for packet in packets:
            sketchHashes.add(sketchHash(sketchSalt, packet))
        sketchHashes.sort(SortOrder.Descending)

        for hash in sketchHashes:
            packetsSide.add(Blake384(hash.toBinary().pad(8)))

        for elem in elements:
            elementsSide.add(Blake384(elem.serializeContents()))

        result = Blake384(packetsSide.hash.toString() & elementsSide.hash.toString())

#Create a Block, with every setting optional.
proc newBlankBlock*(
    version: uint32 = 0,
    last: ArgonHash = ArgonHash(),
    significant: uint16 = 0,
    sketchSalt: string = newString(4),
    miner: MinerWallet = newMinerWallet(),
    packets: seq[VerificationPacket] = @[],
    elements: seq[BlockElement] = @[],
    aggregate: BLSSignature = nil,
    time: uint32 = getTime(),
    proof: uint32 = 0
): Block =
    result = newBlockObj(
        version,
        last,
        newContents(sketchSalt, packets, elements),
        significant,
        sketchSalt,
        miner.publicKey,
        packets,
        elements,
        aggregate,
        time
    )
    miner.hash(result.header, proof)

#Create a Block with a nicname.
proc newBlankBlock*(
    version: uint32 = 0,
    last: ArgonHash = ArgonHash(),
    significant: uint16 = 0,
    sketchSalt: string = newString(4),
    nick: uint16,
    miner: MinerWallet = newMinerWallet(),
    packets: seq[VerificationPacket] = @[],
    elements: seq[BlockElement] = @[],
    aggregate: BLSSignature = nil,
    time: uint32 = getTime(),
    proof: uint32 = 0
): Block =
    result = newBlockObj(
        version,
        last,
        newContents(sketchSalt, packets, elements),
        significant,
        sketchSalt,
        nick,
        packets,
        elements,
        aggregate,
        time
    )
    miner.hash(result.header, proof)
