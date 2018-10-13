#Errors lib.
import ../lib/Errors

#ED25519 lib.
import ../lib/ED25519
#Export the key objects.
export Seed, PrivateKey, PublicKey

#Address lib.
import Address
#Export the Address lib.
export Address

#Finals lib.
import finals

#String utils standard lib.
import strutils

finalsd:
    #Wallet object.
    type Wallet* = ref object of RootObj
        #Seed.
        seed* {.final.}: Seed
        #Private Key.
        privateKey* {.final.}: PrivateKey
        #Public Key.
        publicKey* {.final.}: PublicKey
        #Address.
        address* {.final.}: string

#Create a new Seed from a string.
func newSeed*(seed: string): Seed {.raises: [ValueError].} =
    #If it's binary...
    if seed.len == 32:
        for i in 0 ..< 32:
            result[i] = seed[i]
    #If it's hex...
    elif seed.len == 64:
        for i in countup(0, 63, 2):
            result[i div 2] = cuchar(parseHexInt(seed[i .. i + 1]))
    else:
        raise newException(ValueError, "Invalid Seed.")

#Create a new Public Key from a string.
func newPublicKey*(key: string): PublicKey {.raises: [ValueError].} =
    #If it's binary...
    if key.len == 32:
        for i in 0 ..< 32:
            result[i] = key[i]
    #If it's hex...
    elif key.len == 64:
        for i in countup(0, 63, 2):
            result[i div 2] = cuchar(parseHexInt(key[i .. i + 1]))
    else:
        raise newException(ValueError, "Invalid Public Key.")

#Stringify a Seed/PublicKey.
func `$`*(key: Seed | PublicKey): string {.raises: [].} =
    result = ""
    for b in key:
        result = result & uint8(b).toHex()

#Constructor.
func newWallet*(
    seed: Seed = newSeed()
): Wallet {.raises: [ValueError, SodiumError].} =
    #Generate a new key pair.
    var pair: tuple[priv: PrivateKey, pub: PublicKey] = newKeyPair(seed)

    #Create a new Wallet based off the seed/key pair.
    result = Wallet(
        seed: seed,
        privateKey: pair.priv,
        publicKey: pair.pub,
        address: newAddress(pair.pub)
    )

#Constructor.
func newWallet*(
    seed: Seed,
    address: string
): Wallet {.raises: [ValueError, SodiumError].} =
    #Create a Wallet based off the Seed (and verify the integrity via the Address).
    result = newWallet(seed)

    #Verify the integrity via the Address.
    if result.address != address:
        raise newException(ValueError, "Invalid Address for this Wallet.")

#Sign a message.
func sign*(key: PrivateKey, msg: string): string {.raises: [SodiumError].} =
    ED25519.sign(key, msg)

#Sign a message via a Wallet.
func sign*(wallet: Wallet, msg: string): string {.raises: [SodiumError].} =
    wallet.privateKey.sign(msg)

#Verify a message.
func verify*(
    key: PublicKey,
    msg: string,
    sig: string
): bool {.raises: [SodiumError].} =
    ED25519.verify(key, msg, sig)

#Verify a message via a Wallet.
func verify*(
    wallet: Wallet,
    msg: string,
    sig: string
): bool {.raises: [SodiumError].} =
    wallet.publicKey.verify(msg, sig)
