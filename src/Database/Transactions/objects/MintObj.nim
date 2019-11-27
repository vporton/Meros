#Errors lib.
import ../../../lib/Errors

#Transaction object.
import TransactionObj
export TransactionObj

#Finals lib.
import finals

#Mint object.
finalsd:
    type Mint* = ref object of Transaction
        #Nonce of the Mint.
        nonce* {.final.}: uint32

#Mint constructor.
func newMintObj*(
    nonce: uint32,
    key: uint16,
    amount: uint64
): Mint {.forceCheck: [].} =
    #Create the Mint
    result = Mint(
        nonce: nonce,
        inputs: @[],
        outputs: cast[seq[Output]](
            @[
                newMintOutput(key, amount)
            ]
        )
    )
    result.ffinalizeNonce()
