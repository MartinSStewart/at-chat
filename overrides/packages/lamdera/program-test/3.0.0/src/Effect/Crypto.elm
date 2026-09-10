module Effect.Crypto exposing
    ( SecureContext, getSecureContext
    , getRandomInt8Values, getRandomUInt8Values
    , getRandomInt16Values, getRandomUInt16Values
    , getRandomInt32Values, getRandomUInt32Values
    , randomUuidV4
    , digest
    , Key, PublicKey, PrivateKey, KeyPair
    , generateRsaOaepKeyPair, generateRsaPssKeyPair, generateRsaSsaPkcs1V1_5KeyPair
    , generateAesCtrKey, generateAesCbcKey, generateAesGcmKey
    , generateEcdsaKeyPair
    , generateHmacKey
    , encryptWithRsaOaep, decryptWithRsaOaep
    , encryptWithAesCtr, decryptWithAesCtr
    , encryptWithAesCbc, decryptWithAesCbc
    , encryptWithAesGcm, decryptWithAesGcm
    , signWithRsaSsaPkcs1V1_5, verifyWithRsaSsaPkcs1V1_5
    , signWithRsaPss, verifyWithRsaPss
    , signWithEcdsa, verifyWithEcdsa
    , signWithHmac, verifyWithHmac
    , exportRsaOaepPublicKeyAsSpki, exportRsaOaepPublicKeyAsJwk
    , exportRsaOaepPrivateKeyAsPkcs8, exportRsaOaepPrivateKeyAsJwk
    , exportRsaPssPublicKeyAsSpki, exportRsaPssPublicKeyAsJwk
    , exportRsaPssPrivateKeyAsPkcs8, exportRsaPssPrivateKeyAsJwk
    , exportRsaSsaPkcs1V1_5PublicKeyAsSpki, exportRsaSsaPkcs1V1_5PublicKeyAsJwk
    , exportRsaSsaPkcs1V1_5PrivateKeyAsPkcs8, exportRsaSsaPkcs1V1_5PrivateKeyAsJwk
    , exportAesCtrKeyAsRaw, exportAesCtrKeyAsJwk
    , exportAesCbcKeyAsRaw, exportAesCbcKeyAsJwk
    , exportAesGcmKeyAsRaw, exportAesGcmKeyAsJwk
    , exportEcdsaPublicKeyAsRaw, exportEcdsaPublicKeyAsSpki, exportEcdsaPublicKeyAsJwk
    , exportEcdsaPrivateKeyAsPkcs8, exportEcdsaPrivateKeyAsJwk
    , exportHmacKeyAsRaw, exportHmacKeyAsJwk
    , importRsaOaepPublicKeyFromJwk, importRsaOaepPublicKeyFromSpki
    , importRsaOaepPrivateKeyFromJwk, importRsaOaepPrivateKeyFromPkcs8
    , importRsaPssPublicKeyFromJwk, importRsaPssPublicKeyFromSpki
    , importRsaPssPrivateKeyFromJwk, importRsaPssPrivateKeyFromPkcs8
    , importRsaSsaPkcs1V1_5PublicKeyFromJwk, importRsaSsaPkcs1V1_5PublicKeyFromSpki
    , importRsaSsaPkcs1V1_5PrivateKeyFromJwk, importRsaSsaPkcs1V1_5PrivateKeyFromPkcs8
    , importAesCtrKeyFromRaw, importAesCtrKeyFromJwk
    , importAesCbcKeyFromRaw, importAesCbcKeyFromJwk
    , importAesGcmKeyFromRaw, importAesGcmKeyFromJwk
    , importEcdsaPublicKeyFromRaw, importEcdsaPublicKeyFromSpki, importEcdsaPublicKeyFromJwk
    , importEcdsaPrivateKeyFromPkcs8, importEcdsaPrivateKeyFromSpki, importEcdsaPrivateKeyFromJwk
    , importHmacKeyFromJwk, importHmacKeyFromRaw
    , encodeKey, encodePublicKey, encodePrivateKey, encodeKeyPair
    , keyDecoder, publicKeyDecoder, privateKeyDecoder, keyPairDecoder
    , aesCtrKeyDecoder, aesCbcKeyDecoder, aesGcmKeyDecoder, hmacKeyDecoder
    , rsaOaepPublicKeyDecoder, rsaOaepPrivateKeyDecoder
    , rsaPssPublicKeyDecoder, rsaPssPrivateKeyDecoder
    , rsaSsaPkcs1V1_5PublicKeyDecoder, rsaSsaPkcs1V1_5PrivateKeyDecoder
    , ecdsaPublicKeyDecoder, ecdsaPrivateKeyDecoder
    )

{-| The [`Crypto`](Crypto) module, with every task wrapped as an `Effect.Task` so
it can be used from a program written against `Effect`.

Only the tasks and the key handles are wrapped. Everything else, the parameter
records, the algorithm names and the error types, comes straight from `Crypto`,
so a call reads `Effect.Crypto.digest context Crypto.Sha256 bytes`.

Web Crypto only exists in a browser, so `Effect.Test` cannot run any of this for
real. Each task therefore carries a stand-in result that a simulated run uses
instead: keys become simulated handles, `Bytes` come back empty or zeroed, and a
verification passes. Those results are placeholders, not encryption, so a test
that asserts on encrypted output is asserting on nothing. Test the crypto itself
in a browser.

@docs SecureContext, getSecureContext


## Generate Random Values

@docs getRandomInt8Values, getRandomUInt8Values

@docs getRandomInt16Values, getRandomUInt16Values

@docs getRandomInt32Values, getRandomUInt32Values

@docs randomUuidV4


## Digest

@docs digest


## Keys

@docs Key, PublicKey, PrivateKey, KeyPair

@docs generateRsaOaepKeyPair, generateRsaPssKeyPair, generateRsaSsaPkcs1V1_5KeyPair

@docs generateAesCtrKey, generateAesCbcKey, generateAesGcmKey

@docs generateEcdsaKeyPair

@docs generateHmacKey


## Encryption & Decryption

@docs encryptWithRsaOaep, decryptWithRsaOaep

@docs encryptWithAesCtr, decryptWithAesCtr

@docs encryptWithAesCbc, decryptWithAesCbc

@docs encryptWithAesGcm, decryptWithAesGcm


## Signing & Verifying

@docs signWithRsaSsaPkcs1V1_5, verifyWithRsaSsaPkcs1V1_5

@docs signWithRsaPss, verifyWithRsaPss

@docs signWithEcdsa, verifyWithEcdsa

@docs signWithHmac, verifyWithHmac


## Export Keys

@docs exportRsaOaepPublicKeyAsSpki, exportRsaOaepPublicKeyAsJwk

@docs exportRsaOaepPrivateKeyAsPkcs8, exportRsaOaepPrivateKeyAsJwk

@docs exportRsaPssPublicKeyAsSpki, exportRsaPssPublicKeyAsJwk

@docs exportRsaPssPrivateKeyAsPkcs8, exportRsaPssPrivateKeyAsJwk

@docs exportRsaSsaPkcs1V1_5PublicKeyAsSpki, exportRsaSsaPkcs1V1_5PublicKeyAsJwk

@docs exportRsaSsaPkcs1V1_5PrivateKeyAsPkcs8, exportRsaSsaPkcs1V1_5PrivateKeyAsJwk

@docs exportAesCtrKeyAsRaw, exportAesCtrKeyAsJwk

@docs exportAesCbcKeyAsRaw, exportAesCbcKeyAsJwk

@docs exportAesGcmKeyAsRaw, exportAesGcmKeyAsJwk

@docs exportEcdsaPublicKeyAsRaw, exportEcdsaPublicKeyAsSpki, exportEcdsaPublicKeyAsJwk

@docs exportEcdsaPrivateKeyAsPkcs8, exportEcdsaPrivateKeyAsJwk

@docs exportHmacKeyAsRaw, exportHmacKeyAsJwk


## Import Keys

@docs importRsaOaepPublicKeyFromJwk, importRsaOaepPublicKeyFromSpki

@docs importRsaOaepPrivateKeyFromJwk, importRsaOaepPrivateKeyFromPkcs8

@docs importRsaPssPublicKeyFromJwk, importRsaPssPublicKeyFromSpki

@docs importRsaPssPrivateKeyFromJwk, importRsaPssPrivateKeyFromPkcs8

@docs importRsaSsaPkcs1V1_5PublicKeyFromJwk, importRsaSsaPkcs1V1_5PublicKeyFromSpki

@docs importRsaSsaPkcs1V1_5PrivateKeyFromJwk, importRsaSsaPkcs1V1_5PrivateKeyFromPkcs8

@docs importAesCtrKeyFromRaw, importAesCtrKeyFromJwk

@docs importAesCbcKeyFromRaw, importAesCbcKeyFromJwk

@docs importAesGcmKeyFromRaw, importAesGcmKeyFromJwk

@docs importEcdsaPublicKeyFromRaw, importEcdsaPublicKeyFromSpki, importEcdsaPublicKeyFromJwk

@docs importEcdsaPrivateKeyFromPkcs8, importEcdsaPrivateKeyFromSpki, importEcdsaPrivateKeyFromJwk

@docs importHmacKeyFromJwk, importHmacKeyFromRaw


## Sending Keys Through Ports

@docs encodeKey, encodePublicKey, encodePrivateKey, encodeKeyPair

@docs keyDecoder, publicKeyDecoder, privateKeyDecoder, keyPairDecoder

@docs aesCtrKeyDecoder, aesCbcKeyDecoder, aesGcmKeyDecoder, hmacKeyDecoder

@docs rsaOaepPublicKeyDecoder, rsaOaepPrivateKeyDecoder

@docs rsaPssPublicKeyDecoder, rsaPssPrivateKeyDecoder

@docs rsaSsaPkcs1V1_5PublicKeyDecoder, rsaSsaPkcs1V1_5PrivateKeyDecoder

@docs ecdsaPublicKeyDecoder, ecdsaPrivateKeyDecoder

-}

import Bytes exposing (Bytes)
import Bytes.Encode
import Crypto
import Effect.Internal
import Effect.Task exposing (Task)
import Json.Decode
import Json.Encode
import Task



-- RUNNING A CRYPTO TASK


{-| Wrap a task from `Crypto`, pairing it with the result a simulated run uses in
place of running it.
-}
cryptoTask : Task.Task x a -> a -> Task restriction x a
cryptoTask realTask simulatedResult =
    Effect.Internal.CryptoTask
        (realTask
            |> Task.map Effect.Internal.Succeed
            |> Task.onError (\error -> Task.succeed (Effect.Internal.Fail error))
        )
        (Effect.Internal.Succeed simulatedResult)


{-| The same, for a task built from a handle that may itself be a simulated
stand-in. There is no real task to run in that case, so the simulated result is
all there is.
-}
maybeCryptoTask : Maybe (Task.Task x a) -> a -> Task restriction x a
maybeCryptoTask maybeRealTask simulatedResult =
    case maybeRealTask of
        Just realTask ->
            cryptoTask realTask simulatedResult

        Nothing ->
            Effect.Internal.Succeed simulatedResult



-- HANDLES


{-| Proof that the code is running somewhere Web Crypto works. Obtained with
[`getSecureContext`](#getSecureContext).
-}
type SecureContext
    = RealSecureContext Crypto.SecureContext
    | SimulatedSecureContext


{-| A generated key.
-}
type Key key keyData
    = RealKey (Crypto.Key key keyData)
    | SimulatedKey


{-| A public key, used for encrypting and verifying values.
-}
type PublicKey key keyData
    = RealPublicKey (Crypto.PublicKey key keyData)
    | SimulatedPublicKey


{-| A private key, used for decrypting and signing values.
-}
type PrivateKey key keyData
    = RealPrivateKey (Crypto.PrivateKey key keyData)
    | SimulatedPrivateKey


{-| A set of public and private keys created by some key generation algorithms.
-}
type alias KeyPair key keyData =
    { publicKey : PublicKey key keyData
    , privateKey : PrivateKey key keyData
    }


realContext : SecureContext -> Maybe Crypto.SecureContext
realContext context =
    case context of
        RealSecureContext real ->
            Just real

        SimulatedSecureContext ->
            Nothing


realKey : Key key keyData -> Maybe (Crypto.Key key keyData)
realKey key =
    case key of
        RealKey real ->
            Just real

        SimulatedKey ->
            Nothing


realPublicKey : PublicKey key keyData -> Maybe (Crypto.PublicKey key keyData)
realPublicKey key =
    case key of
        RealPublicKey real ->
            Just real

        SimulatedPublicKey ->
            Nothing


realPrivateKey : PrivateKey key keyData -> Maybe (Crypto.PrivateKey key keyData)
realPrivateKey key =
    case key of
        RealPrivateKey real ->
            Just real

        SimulatedPrivateKey ->
            Nothing


toKeyPair : Crypto.KeyPair key keyData -> KeyPair key keyData
toKeyPair keyPair =
    { publicKey = RealPublicKey keyPair.publicKey
    , privateKey = RealPrivateKey keyPair.privateKey
    }


simulatedKeyPair : KeyPair key keyData
simulatedKeyPair =
    { publicKey = SimulatedPublicKey, privateKey = SimulatedPrivateKey }


emptyBytes : Bytes
emptyBytes =
    Bytes.Encode.encode (Bytes.Encode.sequence [])


zeroBytes : Int -> Bytes
zeroBytes width =
    Bytes.Encode.encode (Bytes.Encode.sequence (List.repeat width (Bytes.Encode.unsignedInt8 0)))


digestWidth : Crypto.DigestAlgorithm -> Int
digestWidth algorithm =
    case algorithm of
        Crypto.Sha256 ->
            32

        Crypto.Sha384 ->
            48

        Crypto.Sha512 ->
            64



-- SECURE CONTEXT


{-| Succeeds with a `SecureContext` if Web Crypto is available. A simulated run
always succeeds, with a context that stands in for a real one.
-}
getSecureContext : Task restriction () SecureContext
getSecureContext =
    cryptoTask (Task.map RealSecureContext Crypto.getSecureContext) SimulatedSecureContext



-- RANDOM VALUES


{-| -}
getRandomInt8Values : Int -> Task restriction x Bytes
getRandomInt8Values count =
    cryptoTask (Crypto.getRandomInt8Values count) (zeroBytes (clamp 0 65536 count))


{-| -}
getRandomUInt8Values : Int -> Task restriction x Bytes
getRandomUInt8Values count =
    cryptoTask (Crypto.getRandomUInt8Values count) (zeroBytes (clamp 0 65536 count))


{-| -}
getRandomInt16Values : Int -> Task restriction x Bytes
getRandomInt16Values count =
    cryptoTask (Crypto.getRandomInt16Values count) (zeroBytes (2 * clamp 0 32768 count))


{-| -}
getRandomUInt16Values : Int -> Task restriction x Bytes
getRandomUInt16Values count =
    cryptoTask (Crypto.getRandomUInt16Values count) (zeroBytes (2 * clamp 0 32768 count))


{-| -}
getRandomInt32Values : Int -> Task restriction x Bytes
getRandomInt32Values count =
    cryptoTask (Crypto.getRandomInt32Values count) (zeroBytes (4 * clamp 0 16384 count))


{-| -}
getRandomUInt32Values : Int -> Task restriction x Bytes
getRandomUInt32Values count =
    cryptoTask (Crypto.getRandomUInt32Values count) (zeroBytes (4 * clamp 0 16384 count))


{-| Generate a random UUID. A simulated run always gives the same one, so a test
that shows a UUID stays stable.
-}
randomUuidV4 : SecureContext -> Task restriction x String
randomUuidV4 context =
    maybeCryptoTask
        (Maybe.map Crypto.randomUuidV4 (realContext context))
        "00000000-0000-4000-8000-000000000000"



-- DIGEST


{-| -}
digest : SecureContext -> Crypto.DigestAlgorithm -> Bytes -> Task restriction x Bytes
digest context algorithm data =
    maybeCryptoTask
        (Maybe.map (\real -> Crypto.digest real algorithm data) (realContext context))
        (zeroBytes (digestWidth algorithm))



-- GENERATE KEYS


{-| -}
generateRsaOaepKeyPair : SecureContext -> Crypto.RsaKeyParams -> Task restriction Crypto.RsaKeyGenerationError (KeyPair Crypto.RsaOaepKey Crypto.RsaKeyParams)
generateRsaOaepKeyPair context params =
    maybeCryptoTask
        (Maybe.map
            (\real -> Task.map toKeyPair (Crypto.generateRsaOaepKeyPair real params))
            (realContext context)
        )
        simulatedKeyPair


{-| -}
generateRsaPssKeyPair : SecureContext -> Crypto.RsaKeyParams -> Task restriction Crypto.RsaKeyGenerationError (KeyPair Crypto.RsaPssKey Crypto.RsaKeyParams)
generateRsaPssKeyPair context params =
    maybeCryptoTask
        (Maybe.map
            (\real -> Task.map toKeyPair (Crypto.generateRsaPssKeyPair real params))
            (realContext context)
        )
        simulatedKeyPair


{-| -}
generateRsaSsaPkcs1V1_5KeyPair : SecureContext -> Crypto.RsaKeyParams -> Task restriction Crypto.RsaKeyGenerationError (KeyPair Crypto.RsaSsaPkcs1V1_5Key Crypto.RsaKeyParams)
generateRsaSsaPkcs1V1_5KeyPair context params =
    maybeCryptoTask
        (Maybe.map
            (\real -> Task.map toKeyPair (Crypto.generateRsaSsaPkcs1V1_5KeyPair real params))
            (realContext context)
        )
        simulatedKeyPair


{-| -}
generateAesCtrKey : SecureContext -> Crypto.AesKeyParams -> Task restriction x (Key Crypto.AesCtrKey Crypto.AesKeyParams)
generateAesCtrKey context params =
    maybeCryptoTask
        (Maybe.map
            (\real -> Task.map RealKey (Crypto.generateAesCtrKey real params))
            (realContext context)
        )
        SimulatedKey


{-| -}
generateAesCbcKey : SecureContext -> Crypto.AesKeyParams -> Task restriction x (Key Crypto.AesCbcKey Crypto.AesKeyParams)
generateAesCbcKey context params =
    maybeCryptoTask
        (Maybe.map
            (\real -> Task.map RealKey (Crypto.generateAesCbcKey real params))
            (realContext context)
        )
        SimulatedKey


{-| -}
generateAesGcmKey : SecureContext -> Crypto.AesKeyParams -> Task restriction x (Key Crypto.AesGcmKey Crypto.AesKeyParams)
generateAesGcmKey context params =
    maybeCryptoTask
        (Maybe.map
            (\real -> Task.map RealKey (Crypto.generateAesGcmKey real params))
            (realContext context)
        )
        SimulatedKey


{-| -}
generateEcdsaKeyPair : SecureContext -> Crypto.EcKeyParams -> Task restriction x (KeyPair Crypto.EcdsaKey Crypto.EcKeyParams)
generateEcdsaKeyPair context params =
    maybeCryptoTask
        (Maybe.map
            (\real -> Task.map toKeyPair (Crypto.generateEcdsaKeyPair real params))
            (realContext context)
        )
        simulatedKeyPair


{-| -}
generateHmacKey : SecureContext -> Crypto.HmacKeyParams -> Task restriction Crypto.HmacKeyGenerationError (Key Crypto.HmacKey Crypto.HmacKeyParams)
generateHmacKey context params =
    maybeCryptoTask
        (Maybe.map
            (\real -> Task.map RealKey (Crypto.generateHmacKey real params))
            (realContext context)
        )
        SimulatedKey



-- ENCRYPT & DECRYPT


{-| -}
encryptWithRsaOaep : Crypto.RsaOaepParams -> PublicKey Crypto.RsaOaepKey Crypto.RsaKeyParams -> Bytes -> Task restriction x Bytes
encryptWithRsaOaep params key bytes =
    maybeCryptoTask
        (Maybe.map (\real -> Crypto.encryptWithRsaOaep params real bytes) (realPublicKey key))
        emptyBytes


{-| -}
decryptWithRsaOaep : Crypto.RsaOaepParams -> PrivateKey Crypto.RsaOaepKey Crypto.RsaKeyParams -> Bytes -> Task restriction Crypto.RsaOaepDecryptionError Bytes
decryptWithRsaOaep params key bytes =
    maybeCryptoTask
        (Maybe.map (\real -> Crypto.decryptWithRsaOaep params real bytes) (realPrivateKey key))
        emptyBytes


{-| -}
encryptWithAesCtr : Crypto.AesCtrParams -> Key Crypto.AesCtrKey Crypto.AesKeyParams -> Bytes -> Task restriction Crypto.AesCtrEncryptionError Bytes
encryptWithAesCtr params key bytes =
    maybeCryptoTask
        (Maybe.map (\real -> Crypto.encryptWithAesCtr params real bytes) (realKey key))
        emptyBytes


{-| -}
decryptWithAesCtr : Crypto.AesCtrParams -> Key Crypto.AesCtrKey Crypto.AesKeyParams -> Bytes -> Task restriction Crypto.AesCtrDecryptionError Bytes
decryptWithAesCtr params key bytes =
    maybeCryptoTask
        (Maybe.map (\real -> Crypto.decryptWithAesCtr params real bytes) (realKey key))
        emptyBytes


{-| -}
encryptWithAesCbc : Crypto.AesCbcParams -> Key Crypto.AesCbcKey Crypto.AesKeyParams -> Bytes -> Task restriction Crypto.AesCbcEncryptionError Bytes
encryptWithAesCbc params key bytes =
    maybeCryptoTask
        (Maybe.map (\real -> Crypto.encryptWithAesCbc params real bytes) (realKey key))
        emptyBytes


{-| -}
decryptWithAesCbc : Crypto.AesCbcParams -> Key Crypto.AesCbcKey Crypto.AesKeyParams -> Bytes -> Task restriction Crypto.AesCbcDecryptionError Bytes
decryptWithAesCbc params key bytes =
    maybeCryptoTask
        (Maybe.map (\real -> Crypto.decryptWithAesCbc params real bytes) (realKey key))
        emptyBytes


{-| -}
encryptWithAesGcm : Crypto.AesGcmParams -> Key Crypto.AesGcmKey Crypto.AesKeyParams -> Bytes -> Task restriction Crypto.AesGcmEncryptionError Bytes
encryptWithAesGcm params key bytes =
    maybeCryptoTask
        (Maybe.map (\real -> Crypto.encryptWithAesGcm params real bytes) (realKey key))
        emptyBytes


{-| -}
decryptWithAesGcm : Crypto.AesGcmParams -> Key Crypto.AesGcmKey Crypto.AesKeyParams -> Bytes -> Task restriction Crypto.AesGcmDecryptionError Bytes
decryptWithAesGcm params key bytes =
    maybeCryptoTask
        (Maybe.map (\real -> Crypto.decryptWithAesGcm params real bytes) (realKey key))
        emptyBytes



-- SIGN & VERIFY


{-| -}
signWithRsaSsaPkcs1V1_5 : PrivateKey Crypto.RsaSsaPkcs1V1_5Key Crypto.RsaKeyParams -> Bytes -> Task restriction x Bytes
signWithRsaSsaPkcs1V1_5 key bytes =
    maybeCryptoTask
        (Maybe.map (\real -> Crypto.signWithRsaSsaPkcs1V1_5 real bytes) (realPrivateKey key))
        emptyBytes


{-| A simulated run always reports the signature as valid.
-}
verifyWithRsaSsaPkcs1V1_5 : PublicKey Crypto.RsaSsaPkcs1V1_5Key Crypto.RsaKeyParams -> Crypto.Signature -> Bytes -> Task restriction () Bytes
verifyWithRsaSsaPkcs1V1_5 key signature bytes =
    maybeCryptoTask
        (Maybe.map (\real -> Crypto.verifyWithRsaSsaPkcs1V1_5 real signature bytes) (realPublicKey key))
        bytes


{-| -}
signWithRsaPss : Crypto.RsaPssParams -> PrivateKey Crypto.RsaPssKey Crypto.RsaKeyParams -> Bytes -> Task restriction Crypto.RsaPssSigningError Bytes
signWithRsaPss params key bytes =
    maybeCryptoTask
        (Maybe.map (\real -> Crypto.signWithRsaPss params real bytes) (realPrivateKey key))
        emptyBytes


{-| A simulated run always reports the signature as valid.
-}
verifyWithRsaPss : Crypto.RsaPssParams -> PublicKey Crypto.RsaPssKey Crypto.RsaKeyParams -> Crypto.Signature -> Bytes -> Task restriction () Bytes
verifyWithRsaPss params key signature bytes =
    maybeCryptoTask
        (Maybe.map (\real -> Crypto.verifyWithRsaPss params real signature bytes) (realPublicKey key))
        bytes


{-| -}
signWithEcdsa : Crypto.DigestAlgorithm -> PrivateKey Crypto.EcdsaKey Crypto.EcKeyParams -> Bytes -> Task restriction x Bytes
signWithEcdsa hash key bytes =
    maybeCryptoTask
        (Maybe.map (\real -> Crypto.signWithEcdsa hash real bytes) (realPrivateKey key))
        emptyBytes


{-| A simulated run always reports the signature as valid.
-}
verifyWithEcdsa : Crypto.DigestAlgorithm -> PublicKey Crypto.EcdsaKey Crypto.EcKeyParams -> Crypto.Signature -> Bytes -> Task restriction () Bytes
verifyWithEcdsa hash key signature bytes =
    maybeCryptoTask
        (Maybe.map (\real -> Crypto.verifyWithEcdsa hash real signature bytes) (realPublicKey key))
        bytes


{-| -}
signWithHmac : Key Crypto.HmacKey Crypto.HmacKeyParams -> Bytes -> Task restriction x Bytes
signWithHmac key bytes =
    maybeCryptoTask
        (Maybe.map (\real -> Crypto.signWithHmac real bytes) (realKey key))
        emptyBytes


{-| A simulated run always reports the signature as valid.
-}
verifyWithHmac : Key Crypto.HmacKey Crypto.HmacKeyParams -> Crypto.Signature -> Bytes -> Task restriction () Bytes
verifyWithHmac key signature bytes =
    maybeCryptoTask
        (Maybe.map (\real -> Crypto.verifyWithHmac real signature bytes) (realKey key))
        bytes



-- EXPORT KEYS


{-| -}
exportRsaOaepPublicKeyAsSpki : PublicKey Crypto.RsaOaepKey Crypto.RsaKeyParams -> Task restriction () Bytes
exportRsaOaepPublicKeyAsSpki key =
    maybeCryptoTask (Maybe.map Crypto.exportRsaOaepPublicKeyAsSpki (realPublicKey key)) emptyBytes


{-| -}
exportRsaOaepPublicKeyAsJwk : PublicKey Crypto.RsaOaepKey Crypto.RsaKeyParams -> Task restriction () Json.Encode.Value
exportRsaOaepPublicKeyAsJwk key =
    maybeCryptoTask (Maybe.map Crypto.exportRsaOaepPublicKeyAsJwk (realPublicKey key)) Json.Encode.null


{-| -}
exportRsaOaepPrivateKeyAsPkcs8 : PrivateKey Crypto.RsaOaepKey Crypto.RsaKeyParams -> Task restriction Crypto.ExportKeyError Bytes
exportRsaOaepPrivateKeyAsPkcs8 key =
    maybeCryptoTask (Maybe.map Crypto.exportRsaOaepPrivateKeyAsPkcs8 (realPrivateKey key)) emptyBytes


{-| -}
exportRsaOaepPrivateKeyAsJwk : PrivateKey Crypto.RsaOaepKey Crypto.RsaKeyParams -> Task restriction Crypto.ExportKeyError Json.Encode.Value
exportRsaOaepPrivateKeyAsJwk key =
    maybeCryptoTask (Maybe.map Crypto.exportRsaOaepPrivateKeyAsJwk (realPrivateKey key)) Json.Encode.null


{-| -}
exportRsaPssPublicKeyAsSpki : PublicKey Crypto.RsaPssKey Crypto.RsaKeyParams -> Task restriction () Bytes
exportRsaPssPublicKeyAsSpki key =
    maybeCryptoTask (Maybe.map Crypto.exportRsaPssPublicKeyAsSpki (realPublicKey key)) emptyBytes


{-| -}
exportRsaPssPublicKeyAsJwk : PublicKey Crypto.RsaPssKey Crypto.RsaKeyParams -> Task restriction () Json.Encode.Value
exportRsaPssPublicKeyAsJwk key =
    maybeCryptoTask (Maybe.map Crypto.exportRsaPssPublicKeyAsJwk (realPublicKey key)) Json.Encode.null


{-| -}
exportRsaPssPrivateKeyAsPkcs8 : PrivateKey Crypto.RsaPssKey Crypto.RsaKeyParams -> Task restriction Crypto.ExportKeyError Bytes
exportRsaPssPrivateKeyAsPkcs8 key =
    maybeCryptoTask (Maybe.map Crypto.exportRsaPssPrivateKeyAsPkcs8 (realPrivateKey key)) emptyBytes


{-| -}
exportRsaPssPrivateKeyAsJwk : PrivateKey Crypto.RsaPssKey Crypto.RsaKeyParams -> Task restriction Crypto.ExportKeyError Json.Encode.Value
exportRsaPssPrivateKeyAsJwk key =
    maybeCryptoTask (Maybe.map Crypto.exportRsaPssPrivateKeyAsJwk (realPrivateKey key)) Json.Encode.null


{-| -}
exportRsaSsaPkcs1V1_5PublicKeyAsSpki : PublicKey Crypto.RsaSsaPkcs1V1_5Key Crypto.RsaKeyParams -> Task restriction () Bytes
exportRsaSsaPkcs1V1_5PublicKeyAsSpki key =
    maybeCryptoTask (Maybe.map Crypto.exportRsaSsaPkcs1V1_5PublicKeyAsSpki (realPublicKey key)) emptyBytes


{-| -}
exportRsaSsaPkcs1V1_5PublicKeyAsJwk : PublicKey Crypto.RsaSsaPkcs1V1_5Key Crypto.RsaKeyParams -> Task restriction () Json.Encode.Value
exportRsaSsaPkcs1V1_5PublicKeyAsJwk key =
    maybeCryptoTask (Maybe.map Crypto.exportRsaSsaPkcs1V1_5PublicKeyAsJwk (realPublicKey key)) Json.Encode.null


{-| -}
exportRsaSsaPkcs1V1_5PrivateKeyAsPkcs8 : PrivateKey Crypto.RsaSsaPkcs1V1_5Key Crypto.RsaKeyParams -> Task restriction Crypto.ExportKeyError Bytes
exportRsaSsaPkcs1V1_5PrivateKeyAsPkcs8 key =
    maybeCryptoTask (Maybe.map Crypto.exportRsaSsaPkcs1V1_5PrivateKeyAsPkcs8 (realPrivateKey key)) emptyBytes


{-| -}
exportRsaSsaPkcs1V1_5PrivateKeyAsJwk : PrivateKey Crypto.RsaSsaPkcs1V1_5Key Crypto.RsaKeyParams -> Task restriction Crypto.ExportKeyError Json.Encode.Value
exportRsaSsaPkcs1V1_5PrivateKeyAsJwk key =
    maybeCryptoTask (Maybe.map Crypto.exportRsaSsaPkcs1V1_5PrivateKeyAsJwk (realPrivateKey key)) Json.Encode.null


{-| -}
exportAesCtrKeyAsRaw : Key Crypto.AesCtrKey Crypto.AesKeyParams -> Task restriction Crypto.ExportKeyError Bytes
exportAesCtrKeyAsRaw key =
    maybeCryptoTask (Maybe.map Crypto.exportAesCtrKeyAsRaw (realKey key)) emptyBytes


{-| -}
exportAesCtrKeyAsJwk : Key Crypto.AesCtrKey Crypto.AesKeyParams -> Task restriction Crypto.ExportKeyError Json.Encode.Value
exportAesCtrKeyAsJwk key =
    maybeCryptoTask (Maybe.map Crypto.exportAesCtrKeyAsJwk (realKey key)) Json.Encode.null


{-| -}
exportAesCbcKeyAsRaw : Key Crypto.AesCbcKey Crypto.AesKeyParams -> Task restriction Crypto.ExportKeyError Bytes
exportAesCbcKeyAsRaw key =
    maybeCryptoTask (Maybe.map Crypto.exportAesCbcKeyAsRaw (realKey key)) emptyBytes


{-| -}
exportAesCbcKeyAsJwk : Key Crypto.AesCbcKey Crypto.AesKeyParams -> Task restriction Crypto.ExportKeyError Json.Encode.Value
exportAesCbcKeyAsJwk key =
    maybeCryptoTask (Maybe.map Crypto.exportAesCbcKeyAsJwk (realKey key)) Json.Encode.null


{-| -}
exportAesGcmKeyAsRaw : Key Crypto.AesGcmKey Crypto.AesKeyParams -> Task restriction Crypto.ExportKeyError Bytes
exportAesGcmKeyAsRaw key =
    maybeCryptoTask (Maybe.map Crypto.exportAesGcmKeyAsRaw (realKey key)) emptyBytes


{-| -}
exportAesGcmKeyAsJwk : Key Crypto.AesGcmKey Crypto.AesKeyParams -> Task restriction Crypto.ExportKeyError Json.Encode.Value
exportAesGcmKeyAsJwk key =
    maybeCryptoTask (Maybe.map Crypto.exportAesGcmKeyAsJwk (realKey key)) Json.Encode.null


{-| -}
exportEcdsaPublicKeyAsRaw : PublicKey Crypto.EcdsaKey Crypto.EcKeyParams -> Task restriction () Bytes
exportEcdsaPublicKeyAsRaw key =
    maybeCryptoTask (Maybe.map Crypto.exportEcdsaPublicKeyAsRaw (realPublicKey key)) emptyBytes


{-| -}
exportEcdsaPublicKeyAsSpki : PublicKey Crypto.EcdsaKey Crypto.EcKeyParams -> Task restriction () Bytes
exportEcdsaPublicKeyAsSpki key =
    maybeCryptoTask (Maybe.map Crypto.exportEcdsaPublicKeyAsSpki (realPublicKey key)) emptyBytes


{-| -}
exportEcdsaPublicKeyAsJwk : PublicKey Crypto.EcdsaKey Crypto.EcKeyParams -> Task restriction () Json.Encode.Value
exportEcdsaPublicKeyAsJwk key =
    maybeCryptoTask (Maybe.map Crypto.exportEcdsaPublicKeyAsJwk (realPublicKey key)) Json.Encode.null


{-| -}
exportEcdsaPrivateKeyAsPkcs8 : PrivateKey Crypto.EcdsaKey Crypto.EcKeyParams -> Task restriction Crypto.ExportKeyError Bytes
exportEcdsaPrivateKeyAsPkcs8 key =
    maybeCryptoTask (Maybe.map Crypto.exportEcdsaPrivateKeyAsPkcs8 (realPrivateKey key)) emptyBytes


{-| -}
exportEcdsaPrivateKeyAsJwk : PrivateKey Crypto.EcdsaKey Crypto.EcKeyParams -> Task restriction Crypto.ExportKeyError Json.Encode.Value
exportEcdsaPrivateKeyAsJwk key =
    maybeCryptoTask (Maybe.map Crypto.exportEcdsaPrivateKeyAsJwk (realPrivateKey key)) Json.Encode.null


{-| -}
exportHmacKeyAsRaw : Key Crypto.HmacKey Crypto.HmacKeyParams -> Task restriction Crypto.ExportKeyError Bytes
exportHmacKeyAsRaw key =
    maybeCryptoTask (Maybe.map Crypto.exportHmacKeyAsRaw (realKey key)) emptyBytes


{-| -}
exportHmacKeyAsJwk : Key Crypto.HmacKey Crypto.HmacKeyParams -> Task restriction Crypto.ExportKeyError Json.Encode.Value
exportHmacKeyAsJwk key =
    maybeCryptoTask (Maybe.map Crypto.exportHmacKeyAsJwk (realKey key)) Json.Encode.null



-- IMPORT KEYS


{-| -}
importRsaOaepPublicKeyFromJwk : SecureContext -> Crypto.ImportRsaKeyParams -> Json.Encode.Value -> Task restriction Crypto.ImportRsaKeyError (PublicKey Crypto.RsaOaepKey Crypto.RsaKeyParams)
importRsaOaepPublicKeyFromJwk context params jwk =
    maybeCryptoTask
        (Maybe.map
            (\real -> Task.map RealPublicKey (Crypto.importRsaOaepPublicKeyFromJwk real params jwk))
            (realContext context)
        )
        SimulatedPublicKey


{-| -}
importRsaOaepPublicKeyFromSpki : SecureContext -> Crypto.ImportRsaKeyParams -> Bytes -> Task restriction Crypto.ImportRsaKeyError (PublicKey Crypto.RsaOaepKey Crypto.RsaKeyParams)
importRsaOaepPublicKeyFromSpki context params bytes =
    maybeCryptoTask
        (Maybe.map
            (\real -> Task.map RealPublicKey (Crypto.importRsaOaepPublicKeyFromSpki real params bytes))
            (realContext context)
        )
        SimulatedPublicKey


{-| -}
importRsaOaepPrivateKeyFromJwk : SecureContext -> Crypto.Extractable -> Crypto.ImportRsaKeyParams -> Json.Encode.Value -> Task restriction Crypto.ImportRsaKeyError (PrivateKey Crypto.RsaOaepKey Crypto.RsaKeyParams)
importRsaOaepPrivateKeyFromJwk context extractable params jwk =
    maybeCryptoTask
        (Maybe.map
            (\real -> Task.map RealPrivateKey (Crypto.importRsaOaepPrivateKeyFromJwk real extractable params jwk))
            (realContext context)
        )
        SimulatedPrivateKey


{-| -}
importRsaOaepPrivateKeyFromPkcs8 : SecureContext -> Crypto.Extractable -> Crypto.ImportRsaKeyParams -> Bytes -> Task restriction Crypto.ImportRsaKeyError (PrivateKey Crypto.RsaOaepKey Crypto.RsaKeyParams)
importRsaOaepPrivateKeyFromPkcs8 context extractable params bytes =
    maybeCryptoTask
        (Maybe.map
            (\real -> Task.map RealPrivateKey (Crypto.importRsaOaepPrivateKeyFromPkcs8 real extractable params bytes))
            (realContext context)
        )
        SimulatedPrivateKey


{-| -}
importRsaPssPublicKeyFromJwk : SecureContext -> Crypto.ImportRsaKeyParams -> Json.Encode.Value -> Task restriction Crypto.ImportRsaKeyError (PublicKey Crypto.RsaPssKey Crypto.RsaKeyParams)
importRsaPssPublicKeyFromJwk context params jwk =
    maybeCryptoTask
        (Maybe.map
            (\real -> Task.map RealPublicKey (Crypto.importRsaPssPublicKeyFromJwk real params jwk))
            (realContext context)
        )
        SimulatedPublicKey


{-| -}
importRsaPssPublicKeyFromSpki : SecureContext -> Crypto.ImportRsaKeyParams -> Bytes -> Task restriction Crypto.ImportRsaKeyError (PublicKey Crypto.RsaPssKey Crypto.RsaKeyParams)
importRsaPssPublicKeyFromSpki context params bytes =
    maybeCryptoTask
        (Maybe.map
            (\real -> Task.map RealPublicKey (Crypto.importRsaPssPublicKeyFromSpki real params bytes))
            (realContext context)
        )
        SimulatedPublicKey


{-| -}
importRsaPssPrivateKeyFromJwk : SecureContext -> Crypto.Extractable -> Crypto.ImportRsaKeyParams -> Json.Encode.Value -> Task restriction Crypto.ImportRsaKeyError (PrivateKey Crypto.RsaPssKey Crypto.RsaKeyParams)
importRsaPssPrivateKeyFromJwk context extractable params jwk =
    maybeCryptoTask
        (Maybe.map
            (\real -> Task.map RealPrivateKey (Crypto.importRsaPssPrivateKeyFromJwk real extractable params jwk))
            (realContext context)
        )
        SimulatedPrivateKey


{-| -}
importRsaPssPrivateKeyFromPkcs8 : SecureContext -> Crypto.Extractable -> Crypto.ImportRsaKeyParams -> Bytes -> Task restriction Crypto.ImportRsaKeyError (PrivateKey Crypto.RsaPssKey Crypto.RsaKeyParams)
importRsaPssPrivateKeyFromPkcs8 context extractable params bytes =
    maybeCryptoTask
        (Maybe.map
            (\real -> Task.map RealPrivateKey (Crypto.importRsaPssPrivateKeyFromPkcs8 real extractable params bytes))
            (realContext context)
        )
        SimulatedPrivateKey


{-| -}
importRsaSsaPkcs1V1_5PublicKeyFromJwk : SecureContext -> Crypto.ImportRsaKeyParams -> Json.Encode.Value -> Task restriction Crypto.ImportRsaKeyError (PublicKey Crypto.RsaSsaPkcs1V1_5Key Crypto.RsaKeyParams)
importRsaSsaPkcs1V1_5PublicKeyFromJwk context params jwk =
    maybeCryptoTask
        (Maybe.map
            (\real -> Task.map RealPublicKey (Crypto.importRsaSsaPkcs1V1_5PublicKeyFromJwk real params jwk))
            (realContext context)
        )
        SimulatedPublicKey


{-| -}
importRsaSsaPkcs1V1_5PublicKeyFromSpki : SecureContext -> Crypto.ImportRsaKeyParams -> Bytes -> Task restriction Crypto.ImportRsaKeyError (PublicKey Crypto.RsaSsaPkcs1V1_5Key Crypto.RsaKeyParams)
importRsaSsaPkcs1V1_5PublicKeyFromSpki context params bytes =
    maybeCryptoTask
        (Maybe.map
            (\real -> Task.map RealPublicKey (Crypto.importRsaSsaPkcs1V1_5PublicKeyFromSpki real params bytes))
            (realContext context)
        )
        SimulatedPublicKey


{-| -}
importRsaSsaPkcs1V1_5PrivateKeyFromJwk : SecureContext -> Crypto.Extractable -> Crypto.ImportRsaKeyParams -> Json.Encode.Value -> Task restriction Crypto.ImportRsaKeyError (PrivateKey Crypto.RsaSsaPkcs1V1_5Key Crypto.RsaKeyParams)
importRsaSsaPkcs1V1_5PrivateKeyFromJwk context extractable params jwk =
    maybeCryptoTask
        (Maybe.map
            (\real -> Task.map RealPrivateKey (Crypto.importRsaSsaPkcs1V1_5PrivateKeyFromJwk real extractable params jwk))
            (realContext context)
        )
        SimulatedPrivateKey


{-| -}
importRsaSsaPkcs1V1_5PrivateKeyFromPkcs8 : SecureContext -> Crypto.Extractable -> Crypto.ImportRsaKeyParams -> Bytes -> Task restriction Crypto.ImportRsaKeyError (PrivateKey Crypto.RsaSsaPkcs1V1_5Key Crypto.RsaKeyParams)
importRsaSsaPkcs1V1_5PrivateKeyFromPkcs8 context extractable params bytes =
    maybeCryptoTask
        (Maybe.map
            (\real -> Task.map RealPrivateKey (Crypto.importRsaSsaPkcs1V1_5PrivateKeyFromPkcs8 real extractable params bytes))
            (realContext context)
        )
        SimulatedPrivateKey


{-| -}
importAesCtrKeyFromRaw : SecureContext -> Crypto.Extractable -> Bytes -> Task restriction Crypto.ImportAesKeyError (Key Crypto.AesCtrKey Crypto.AesKeyParams)
importAesCtrKeyFromRaw context extractable bytes =
    maybeCryptoTask
        (Maybe.map
            (\real -> Task.map RealKey (Crypto.importAesCtrKeyFromRaw real extractable bytes))
            (realContext context)
        )
        SimulatedKey


{-| -}
importAesCtrKeyFromJwk : SecureContext -> Crypto.Extractable -> Json.Encode.Value -> Task restriction Crypto.ImportAesKeyError (Key Crypto.AesCtrKey Crypto.AesKeyParams)
importAesCtrKeyFromJwk context extractable jwk =
    maybeCryptoTask
        (Maybe.map
            (\real -> Task.map RealKey (Crypto.importAesCtrKeyFromJwk real extractable jwk))
            (realContext context)
        )
        SimulatedKey


{-| -}
importAesCbcKeyFromRaw : SecureContext -> Crypto.Extractable -> Bytes -> Task restriction Crypto.ImportAesKeyError (Key Crypto.AesCbcKey Crypto.AesKeyParams)
importAesCbcKeyFromRaw context extractable bytes =
    maybeCryptoTask
        (Maybe.map
            (\real -> Task.map RealKey (Crypto.importAesCbcKeyFromRaw real extractable bytes))
            (realContext context)
        )
        SimulatedKey


{-| -}
importAesCbcKeyFromJwk : SecureContext -> Crypto.Extractable -> Json.Encode.Value -> Task restriction Crypto.ImportAesKeyError (Key Crypto.AesCbcKey Crypto.AesKeyParams)
importAesCbcKeyFromJwk context extractable jwk =
    maybeCryptoTask
        (Maybe.map
            (\real -> Task.map RealKey (Crypto.importAesCbcKeyFromJwk real extractable jwk))
            (realContext context)
        )
        SimulatedKey


{-| -}
importAesGcmKeyFromRaw : SecureContext -> Crypto.Extractable -> Bytes -> Task restriction Crypto.ImportAesKeyError (Key Crypto.AesGcmKey Crypto.AesKeyParams)
importAesGcmKeyFromRaw context extractable bytes =
    maybeCryptoTask
        (Maybe.map
            (\real -> Task.map RealKey (Crypto.importAesGcmKeyFromRaw real extractable bytes))
            (realContext context)
        )
        SimulatedKey


{-| -}
importAesGcmKeyFromJwk : SecureContext -> Crypto.Extractable -> Json.Encode.Value -> Task restriction Crypto.ImportAesKeyError (Key Crypto.AesGcmKey Crypto.AesKeyParams)
importAesGcmKeyFromJwk context extractable jwk =
    maybeCryptoTask
        (Maybe.map
            (\real -> Task.map RealKey (Crypto.importAesGcmKeyFromJwk real extractable jwk))
            (realContext context)
        )
        SimulatedKey


{-| -}
importEcdsaPublicKeyFromRaw : SecureContext -> Crypto.EcNamedCurve -> Bytes -> Task restriction Crypto.ImportEcKeyError (PublicKey Crypto.EcdsaKey Crypto.EcKeyParams)
importEcdsaPublicKeyFromRaw context namedCurve bytes =
    maybeCryptoTask
        (Maybe.map
            (\real -> Task.map RealPublicKey (Crypto.importEcdsaPublicKeyFromRaw real namedCurve bytes))
            (realContext context)
        )
        SimulatedPublicKey


{-| -}
importEcdsaPublicKeyFromSpki : SecureContext -> Crypto.EcNamedCurve -> Bytes -> Task restriction Crypto.ImportEcKeyError (PublicKey Crypto.EcdsaKey Crypto.EcKeyParams)
importEcdsaPublicKeyFromSpki context namedCurve bytes =
    maybeCryptoTask
        (Maybe.map
            (\real -> Task.map RealPublicKey (Crypto.importEcdsaPublicKeyFromSpki real namedCurve bytes))
            (realContext context)
        )
        SimulatedPublicKey


{-| -}
importEcdsaPublicKeyFromJwk : SecureContext -> Crypto.EcNamedCurve -> Json.Encode.Value -> Task restriction Crypto.ImportEcKeyError (PublicKey Crypto.EcdsaKey Crypto.EcKeyParams)
importEcdsaPublicKeyFromJwk context namedCurve jwk =
    maybeCryptoTask
        (Maybe.map
            (\real -> Task.map RealPublicKey (Crypto.importEcdsaPublicKeyFromJwk real namedCurve jwk))
            (realContext context)
        )
        SimulatedPublicKey


{-| -}
importEcdsaPrivateKeyFromPkcs8 : SecureContext -> Crypto.Extractable -> Crypto.EcNamedCurve -> Bytes -> Task restriction Crypto.ImportEcKeyError (PrivateKey Crypto.EcdsaKey Crypto.EcKeyParams)
importEcdsaPrivateKeyFromPkcs8 context extractable namedCurve bytes =
    maybeCryptoTask
        (Maybe.map
            (\real -> Task.map RealPrivateKey (Crypto.importEcdsaPrivateKeyFromPkcs8 real extractable namedCurve bytes))
            (realContext context)
        )
        SimulatedPrivateKey


{-| -}
importEcdsaPrivateKeyFromSpki : SecureContext -> Crypto.Extractable -> Crypto.EcNamedCurve -> Bytes -> Task restriction Crypto.ImportEcKeyError (PrivateKey Crypto.EcdsaKey Crypto.EcKeyParams)
importEcdsaPrivateKeyFromSpki context extractable namedCurve bytes =
    maybeCryptoTask
        (Maybe.map
            (\real -> Task.map RealPrivateKey (Crypto.importEcdsaPrivateKeyFromSpki real extractable namedCurve bytes))
            (realContext context)
        )
        SimulatedPrivateKey


{-| -}
importEcdsaPrivateKeyFromJwk : SecureContext -> Crypto.Extractable -> Crypto.EcNamedCurve -> Json.Encode.Value -> Task restriction Crypto.ImportEcKeyError (PrivateKey Crypto.EcdsaKey Crypto.EcKeyParams)
importEcdsaPrivateKeyFromJwk context extractable namedCurve jwk =
    maybeCryptoTask
        (Maybe.map
            (\real -> Task.map RealPrivateKey (Crypto.importEcdsaPrivateKeyFromJwk real extractable namedCurve jwk))
            (realContext context)
        )
        SimulatedPrivateKey


{-| -}
importHmacKeyFromJwk : SecureContext -> Crypto.Extractable -> Crypto.DigestAlgorithm -> Maybe Int -> Json.Encode.Value -> Task restriction Crypto.ImportHmacKeyError (Key Crypto.HmacKey Crypto.HmacKeyParams)
importHmacKeyFromJwk context extractable hash length jwk =
    maybeCryptoTask
        (Maybe.map
            (\real -> Task.map RealKey (Crypto.importHmacKeyFromJwk real extractable hash length jwk))
            (realContext context)
        )
        SimulatedKey


{-| -}
importHmacKeyFromRaw : SecureContext -> Crypto.Extractable -> Crypto.DigestAlgorithm -> Maybe Int -> Bytes -> Task restriction Crypto.ImportHmacKeyError (Key Crypto.HmacKey Crypto.HmacKeyParams)
importHmacKeyFromRaw context extractable hash length bytes =
    maybeCryptoTask
        (Maybe.map
            (\real -> Task.map RealKey (Crypto.importHmacKeyFromRaw real extractable hash length bytes))
            (realContext context)
        )
        SimulatedKey



-- SENDING KEYS THROUGH PORTS


{-| Hand the `CryptoKey` behind a key to JavaScript, so it can be sent out through
a port and stored in IndexedDB. See [`Crypto.encodeKey`](Crypto#encodeKey).

A simulated key encodes as `null`, since there is no `CryptoKey` behind it.

-}
encodeKey : Key key keyData -> Json.Encode.Value
encodeKey key =
    case key of
        RealKey real ->
            Crypto.encodeKey real

        SimulatedKey ->
            Json.Encode.null


{-| The same as [`encodeKey`](#encodeKey) for a public key.
-}
encodePublicKey : PublicKey key keyData -> Json.Encode.Value
encodePublicKey key =
    case key of
        RealPublicKey real ->
            Crypto.encodePublicKey real

        SimulatedPublicKey ->
            Json.Encode.null


{-| The same as [`encodeKey`](#encodeKey) for a private key.
-}
encodePrivateKey : PrivateKey key keyData -> Json.Encode.Value
encodePrivateKey key =
    case key of
        RealPrivateKey real ->
            Crypto.encodePrivateKey real

        SimulatedPrivateKey ->
            Json.Encode.null


{-| Encode both halves of a key pair into an object with a `publicKey` and a
`privateKey` field.
-}
encodeKeyPair : KeyPair key keyData -> Json.Encode.Value
encodeKeyPair keyPair =
    Json.Encode.object
        [ ( "publicKey", encodePublicKey keyPair.publicKey )
        , ( "privateKey", encodePrivateKey keyPair.privateKey )
        ]


{-| Read back a secret key that came in through a port, given the name of the
algorithm it was generated for. See [`Crypto.keyDecoder`](Crypto#keyDecoder).
-}
keyDecoder : String -> Json.Decode.Decoder (Key key keyData)
keyDecoder algorithm =
    Json.Decode.map RealKey (Crypto.keyDecoder algorithm)


{-| The same as [`keyDecoder`](#keyDecoder) for a public key.
-}
publicKeyDecoder : String -> Json.Decode.Decoder (PublicKey key keyData)
publicKeyDecoder algorithm =
    Json.Decode.map RealPublicKey (Crypto.publicKeyDecoder algorithm)


{-| The same as [`keyDecoder`](#keyDecoder) for a private key.
-}
privateKeyDecoder : String -> Json.Decode.Decoder (PrivateKey key keyData)
privateKeyDecoder algorithm =
    Json.Decode.map RealPrivateKey (Crypto.privateKeyDecoder algorithm)


{-| Read back a key pair that was written with [`encodeKeyPair`](#encodeKeyPair).
-}
keyPairDecoder :
    Json.Decode.Decoder (PublicKey key keyData)
    -> Json.Decode.Decoder (PrivateKey key keyData)
    -> Json.Decode.Decoder (KeyPair key keyData)
keyPairDecoder decodePublic decodePrivate =
    Json.Decode.map2 KeyPair
        (Json.Decode.field "publicKey" decodePublic)
        (Json.Decode.field "privateKey" decodePrivate)


{-| -}
aesCtrKeyDecoder : Json.Decode.Decoder (Key Crypto.AesCtrKey Crypto.AesKeyParams)
aesCtrKeyDecoder =
    Json.Decode.map RealKey Crypto.aesCtrKeyDecoder


{-| -}
aesCbcKeyDecoder : Json.Decode.Decoder (Key Crypto.AesCbcKey Crypto.AesKeyParams)
aesCbcKeyDecoder =
    Json.Decode.map RealKey Crypto.aesCbcKeyDecoder


{-| -}
aesGcmKeyDecoder : Json.Decode.Decoder (Key Crypto.AesGcmKey Crypto.AesKeyParams)
aesGcmKeyDecoder =
    Json.Decode.map RealKey Crypto.aesGcmKeyDecoder


{-| -}
hmacKeyDecoder : Json.Decode.Decoder (Key Crypto.HmacKey Crypto.HmacKeyParams)
hmacKeyDecoder =
    Json.Decode.map RealKey Crypto.hmacKeyDecoder


{-| -}
rsaOaepPublicKeyDecoder : Json.Decode.Decoder (PublicKey Crypto.RsaOaepKey Crypto.RsaKeyParams)
rsaOaepPublicKeyDecoder =
    Json.Decode.map RealPublicKey Crypto.rsaOaepPublicKeyDecoder


{-| -}
rsaOaepPrivateKeyDecoder : Json.Decode.Decoder (PrivateKey Crypto.RsaOaepKey Crypto.RsaKeyParams)
rsaOaepPrivateKeyDecoder =
    Json.Decode.map RealPrivateKey Crypto.rsaOaepPrivateKeyDecoder


{-| -}
rsaPssPublicKeyDecoder : Json.Decode.Decoder (PublicKey Crypto.RsaPssKey Crypto.RsaKeyParams)
rsaPssPublicKeyDecoder =
    Json.Decode.map RealPublicKey Crypto.rsaPssPublicKeyDecoder


{-| -}
rsaPssPrivateKeyDecoder : Json.Decode.Decoder (PrivateKey Crypto.RsaPssKey Crypto.RsaKeyParams)
rsaPssPrivateKeyDecoder =
    Json.Decode.map RealPrivateKey Crypto.rsaPssPrivateKeyDecoder


{-| -}
rsaSsaPkcs1V1_5PublicKeyDecoder : Json.Decode.Decoder (PublicKey Crypto.RsaSsaPkcs1V1_5Key Crypto.RsaKeyParams)
rsaSsaPkcs1V1_5PublicKeyDecoder =
    Json.Decode.map RealPublicKey Crypto.rsaSsaPkcs1V1_5PublicKeyDecoder


{-| -}
rsaSsaPkcs1V1_5PrivateKeyDecoder : Json.Decode.Decoder (PrivateKey Crypto.RsaSsaPkcs1V1_5Key Crypto.RsaKeyParams)
rsaSsaPkcs1V1_5PrivateKeyDecoder =
    Json.Decode.map RealPrivateKey Crypto.rsaSsaPkcs1V1_5PrivateKeyDecoder


{-| -}
ecdsaPublicKeyDecoder : Json.Decode.Decoder (PublicKey Crypto.EcdsaKey Crypto.EcKeyParams)
ecdsaPublicKeyDecoder =
    Json.Decode.map RealPublicKey Crypto.ecdsaPublicKeyDecoder


{-| -}
ecdsaPrivateKeyDecoder : Json.Decode.Decoder (PrivateKey Crypto.EcdsaKey Crypto.EcKeyParams)
ecdsaPrivateKeyDecoder =
    Json.Decode.map RealPrivateKey Crypto.ecdsaPrivateKeyDecoder
