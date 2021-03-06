import random

import ../../../../src/lib/[Util, Hash, Sketcher]
import ../../../../src/Wallet/MinerWallet

import ../../../../src/Database/Merit/Block

import ../../../../src/Network/objects/SketchyBlockObj
import ../../../../src/Network/Serialize/Merit/[
  SerializeBlock,
  ParseBlock
]

import ../../../Fuzzed
import ../../../Database/Consensus/Elements/TestElements
import ../../../Database/Merit/[TestMerit, CompareMerit]
import ../../../Database/Merit/CompareMerit

#Whether or not to create a Block with a new miner.
var newMiner: bool = true

suite "SerializeBlock":
  setup:
    var
      last: Hash[256] = newRandomHash()
      packets: seq[VerificationPacket] = @[]
      elements: seq[BlockElement] = @[]
      newBlock: Block
      reloaded: SketchyBlock
      sketchResult: SketchResult

  highFuzzTest "Serialize and parse.":
    #Randomize the packets.
    for _ in 0 ..< rand(300):
      packets.add(newRandomVerificationPacket())

    #Randomize the elements.
    for _ in 0 ..< rand(300):
      elements.add(newRandomBlockElement())

    while true:
      if newMiner:
        newBlock = newBlankBlock(
          getRandomX(),
          uint32(rand(4096)),
          last,
          uint16(rand(50000)),
          char(rand(255)) & char(rand(255)) & char(rand(255)) & char(rand(255)),
          newMinerWallet(),
          packets,
          elements,
          newMinerWallet().sign($rand(4096)),
          uint32(rand(high(int32))),
          uint32(rand(high(int32)))
        )
      else:
        newBlock = newBlankBlock(
          getRandomX(),
          uint32(rand(4096)),
          last,
          uint16(rand(50000)),
          char(rand(255)) & char(rand(255)) & char(rand(255)) & char(rand(255)),
          uint16(rand(high(int16))),
          newMinerWallet(),
          packets,
          elements,
          newMinerWallet().sign($rand(4096)),
          uint32(rand(high(int32))),
          uint32(rand(high(int32)))
        )

      #Verify the sketch doesn't have a collision.
      if newSketcher(packets).collides(newBlock.header.sketchSalt):
        continue
      break

    #Serialize it and parse it back.
    reloaded = getRandomX().parseBlock(newBlock.serialize())

    #Create the Sketch and extract its elements.
    sketchResult = newSketcher(packets).merge(
      reloaded.sketch,
      reloaded.capacity,
      0,
      reloaded.data.header.sketchSalt
    )
    check sketchResult.missing.len == 0
    reloaded.data.body.packets = sketchResult.packets

    check newBlock.serialize() == reloaded.data.serialize()
    compare(newBlock, reloaded.data)

    #Flip the newMiner bool.
    newMiner = not newMiner
