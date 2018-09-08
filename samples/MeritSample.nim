#Number libs.
import BN
import ../src/lib/Base

#Time lib.
import ../src/lib/Time

#Hash lib.
import ../src/lib/Hash
#Argon lib.
import ../src/lib/Argon

#Merit lib.
import ../src/Database/Merit/Merit

#Wallet lib.
import ../src/Wallet/Wallet

#Serialization libs.
import ../src/Network/Serialize/SerializeMiners

#Main function is so these varriables can be GC'd.
proc main() =
    var
        #Create a wallet to mine to.
        wallet: Wallet = newWallet()
        #Get the address.
        miner: string = wallet.getAddress()
        #Get the publisher.
        publisher: string = $wallet.getPublicKey()
        #Gensis var.
        genesis: string = "mainnet"
        #Merit var.
        merit: Merit = newMerit(genesis)
        #Block var; defined here to stop a memory leak.
        newBlock: Block
        #Last block hash, nonce, time, and proof vars.
        last: string = Argon(SHA512(genesis), "00")
        nonce: BN = newBN(1)
        time: BN
        proof: BN = newBN()
        miners: seq[tuple[miner: string, amount: int]] = @[(
            miner: miner,
            amount: 100
        )]

    echo "First balance: " & $merit.getBalance(miner)

    #Mine the chain.
    while true:
        echo "Looping..."

        #Update the time.
        time = getTime()

        #Create a block.
        newBlock = newBlock(
            last,
            nonce,
            time,
            @[],
            newMerkleTree(@[]),
            publisher,
            proof,
            miners,
            wallet.sign(SHA512(miners.serialize(nonce)))
        )

        #Try to add it.
        if not merit.processBlock(newBlock):
            #If it's invalid, increase the proof and continue.
            inc(proof)
            continue

        #If we didn't continue, the block was valid! Print that we mined a block!
        echo "Mined a block: " & $nonce
        echo "The miner's Merit is " & $merit.getBalance(miner) & "."

        #Finally, update the last hash, increase the nonce, and reset the proof.
        last = newBlock.getArgon()
        nonce = nonce + BNNums.ONE
        proof = newBN()

main()