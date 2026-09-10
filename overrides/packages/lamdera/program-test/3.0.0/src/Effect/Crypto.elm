module Effect.Crypto exposing
    ( SecureContext
    , Key
    , PublicKey
    , PrivateKey
    , KeyPair
    , getSecureContext
    , getRandomInt8Values
    , getRandomUInt8Values
    , getRandomInt16Values
    , getRandomUInt16Values
    , getRandomInt32Values
    , getRandomUInt32Values
    , randomUuidV4
    , digest
    , generateAesCtrKey
    , importAesCtrKeyFromRaw
    , importAesCtrKeyFromJwk
    , exportAesCtrKeyAsRaw
    , exportAesCtrKeyAsJwk
    , encryptWithAesCtr
    , decryptWithAesCtr
    , generateAesCbcKey
    , importAesCbcKeyFromRaw
    , importAesCbcKeyFromJwk
    , exportAesCbcKeyAsRaw
    , exportAesCbcKeyAsJwk
    , encryptWithAesCbc
    , decryptWithAesCbc
    , generateAesGcmKey
    , importAesGcmKeyFromRaw
    , importAesGcmKeyFromJwk
    , exportAesGcmKeyAsRaw
    , exportAesGcmKeyAsJwk
    , encryptWithAesGcm
    , decryptWithAesGcm
    , generateHmacKey
    , importHmacKeyFromRaw
    , importHmacKeyFromJwk
    , exportHmacKeyAsRaw
    , exportHmacKeyAsJwk
    , signWithHmac
    , verifyWithHmac
    , generateRsaOaepKeyPair
    , importRsaOaepPublicKeyFromSpki
    , importRsaOaepPublicKeyFromJwk
    , importRsaOaepPrivateKeyFromPkcs8
    , importRsaOaepPrivateKeyFromJwk
    , exportRsaOaepPublicKeyAsSpki
    , exportRsaOaepPublicKeyAsJwk
    , exportRsaOaepPrivateKeyAsPkcs8
    , exportRsaOaepPrivateKeyAsJwk
    , encryptWithRsaOaep
    , decryptWithRsaOaep
    , generateRsaPssKeyPair
    , importRsaPssPublicKeyFromSpki
    , importRsaPssPublicKeyFromJwk
    , importRsaPssPrivateKeyFromPkcs8
    , importRsaPssPrivateKeyFromJwk
    , exportRsaPssPublicKeyAsSpki
    , exportRsaPssPublicKeyAsJwk
    , exportRsaPssPrivateKeyAsPkcs8
    , exportRsaPssPrivateKeyAsJwk
    , signWithRsaPss
    , verifyWithRsaPss
    , generateRsaSsaPkcs1V1_5KeyPair
    , importRsaSsaPkcs1V1_5PublicKeyFromSpki
    , importRsaSsaPkcs1V1_5PublicKeyFromJwk
    , importRsaSsaPkcs1V1_5PrivateKeyFromPkcs8
    , importRsaSsaPkcs1V1_5PrivateKeyFromJwk
    , exportRsaSsaPkcs1V1_5PublicKeyAsSpki
    , exportRsaSsaPkcs1V1_5PublicKeyAsJwk
    , exportRsaSsaPkcs1V1_5PrivateKeyAsPkcs8
    , exportRsaSsaPkcs1V1_5PrivateKeyAsJwk
    , signWithRsaSsaPkcs1V1_5
    , verifyWithRsaSsaPkcs1V1_5
    , generateEcdsaKeyPair
    , importEcdsaPublicKeyFromRaw
    , importEcdsaPublicKeyFromSpki
    , importEcdsaPublicKeyFromJwk
    , importEcdsaPrivateKeyFromPkcs8
    , importEcdsaPrivateKeyFromSpki
    , importEcdsaPrivateKeyFromJwk
    , exportEcdsaPublicKeyAsRaw
    , exportEcdsaPublicKeyAsSpki
    , exportEcdsaPublicKeyAsJwk
    , exportEcdsaPrivateKeyAsPkcs8
    , exportEcdsaPrivateKeyAsJwk
    , signWithEcdsa
    , verifyWithEcdsa
    , encodeKey
    , encodePublicKey
    , encodePrivateKey
    , encodeKeyPair
    , keyDecoder
    , publicKeyDecoder
    , privateKeyDecoder
    , keyPairDecoder
    , aesCtrKeyDecoder
    , aesCbcKeyDecoder
    , aesGcmKeyDecoder
    , hmacKeyDecoder
    , rsaOaepPublicKeyDecoder
    , rsaOaepPrivateKeyDecoder
    , rsaPssPublicKeyDecoder
    , rsaPssPrivateKeyDecoder
    , rsaSsaPkcs1V1_5PublicKeyDecoder
    , rsaSsaPkcs1V1_5PrivateKeyDecoder
    , ecdsaPublicKeyDecoder
    , ecdsaPrivateKeyDecoder
    )

{-| The [`Crypto`](Crypto) module, with every task wrapped as an `Effect.Task` so it can
be used from a program written against `Effect`.

Only the tasks and the key handles are wrapped. The parameter records, the algorithm names
and the error types come straight from `Crypto`, so a call reads
`Effect.Crypto.digest context Crypto.Sha256 bytes`.

Each function turns into an operation that `Effect.Lamdera` runs against Web Crypto and
`Effect.Test` answers itself. A key from a simulated run carries its bytes rather than a
browser handle, which is what lets a pure implementation stand in for the real thing. The
implementations `Effect.Test` ships with today are placeholders: encryption is the
identity and a signature is empty. A test that asserts on ciphertext is asserting on
nothing.

@docs SecureContext

@docs Key

@docs PublicKey

@docs PrivateKey

@docs KeyPair

@docs getSecureContext

@docs getRandomInt8Values

@docs getRandomUInt8Values

@docs getRandomInt16Values

@docs getRandomUInt16Values

@docs getRandomInt32Values

@docs getRandomUInt32Values

@docs randomUuidV4

@docs digest

@docs generateAesCtrKey

@docs importAesCtrKeyFromRaw

@docs importAesCtrKeyFromJwk

@docs exportAesCtrKeyAsRaw

@docs exportAesCtrKeyAsJwk

@docs encryptWithAesCtr

@docs decryptWithAesCtr

@docs generateAesCbcKey

@docs importAesCbcKeyFromRaw

@docs importAesCbcKeyFromJwk

@docs exportAesCbcKeyAsRaw

@docs exportAesCbcKeyAsJwk

@docs encryptWithAesCbc

@docs decryptWithAesCbc

@docs generateAesGcmKey

@docs importAesGcmKeyFromRaw

@docs importAesGcmKeyFromJwk

@docs exportAesGcmKeyAsRaw

@docs exportAesGcmKeyAsJwk

@docs encryptWithAesGcm

@docs decryptWithAesGcm

@docs generateHmacKey

@docs importHmacKeyFromRaw

@docs importHmacKeyFromJwk

@docs exportHmacKeyAsRaw

@docs exportHmacKeyAsJwk

@docs signWithHmac

@docs verifyWithHmac

@docs generateRsaOaepKeyPair

@docs importRsaOaepPublicKeyFromSpki

@docs importRsaOaepPublicKeyFromJwk

@docs importRsaOaepPrivateKeyFromPkcs8

@docs importRsaOaepPrivateKeyFromJwk

@docs exportRsaOaepPublicKeyAsSpki

@docs exportRsaOaepPublicKeyAsJwk

@docs exportRsaOaepPrivateKeyAsPkcs8

@docs exportRsaOaepPrivateKeyAsJwk

@docs encryptWithRsaOaep

@docs decryptWithRsaOaep

@docs generateRsaPssKeyPair

@docs importRsaPssPublicKeyFromSpki

@docs importRsaPssPublicKeyFromJwk

@docs importRsaPssPrivateKeyFromPkcs8

@docs importRsaPssPrivateKeyFromJwk

@docs exportRsaPssPublicKeyAsSpki

@docs exportRsaPssPublicKeyAsJwk

@docs exportRsaPssPrivateKeyAsPkcs8

@docs exportRsaPssPrivateKeyAsJwk

@docs signWithRsaPss

@docs verifyWithRsaPss

@docs generateRsaSsaPkcs1V1_5KeyPair

@docs importRsaSsaPkcs1V1_5PublicKeyFromSpki

@docs importRsaSsaPkcs1V1_5PublicKeyFromJwk

@docs importRsaSsaPkcs1V1_5PrivateKeyFromPkcs8

@docs importRsaSsaPkcs1V1_5PrivateKeyFromJwk

@docs exportRsaSsaPkcs1V1_5PublicKeyAsSpki

@docs exportRsaSsaPkcs1V1_5PublicKeyAsJwk

@docs exportRsaSsaPkcs1V1_5PrivateKeyAsPkcs8

@docs exportRsaSsaPkcs1V1_5PrivateKeyAsJwk

@docs signWithRsaSsaPkcs1V1_5

@docs verifyWithRsaSsaPkcs1V1_5

@docs generateEcdsaKeyPair

@docs importEcdsaPublicKeyFromRaw

@docs importEcdsaPublicKeyFromSpki

@docs importEcdsaPublicKeyFromJwk

@docs importEcdsaPrivateKeyFromPkcs8

@docs importEcdsaPrivateKeyFromSpki

@docs importEcdsaPrivateKeyFromJwk

@docs exportEcdsaPublicKeyAsRaw

@docs exportEcdsaPublicKeyAsSpki

@docs exportEcdsaPublicKeyAsJwk

@docs exportEcdsaPrivateKeyAsPkcs8

@docs exportEcdsaPrivateKeyAsJwk

@docs signWithEcdsa

@docs verifyWithEcdsa

@docs encodeKey

@docs encodePublicKey

@docs encodePrivateKey

@docs encodeKeyPair

@docs keyDecoder

@docs publicKeyDecoder

@docs privateKeyDecoder

@docs keyPairDecoder

@docs aesCtrKeyDecoder

@docs aesCbcKeyDecoder

@docs aesGcmKeyDecoder

@docs hmacKeyDecoder

@docs rsaOaepPublicKeyDecoder

@docs rsaOaepPrivateKeyDecoder

@docs rsaPssPublicKeyDecoder

@docs rsaPssPrivateKeyDecoder

@docs rsaSsaPkcs1V1_5PublicKeyDecoder

@docs rsaSsaPkcs1V1_5PrivateKeyDecoder

@docs ecdsaPublicKeyDecoder

@docs ecdsaPrivateKeyDecoder

-}

import Bytes exposing (Bytes)
import Bytes.Encode
import Crypto
import Effect.Internal
import Effect.Task exposing (Task)
import Json.Decode
import Json.Encode



-- HANDLES


{-| Proof that Web Crypto is available, from [`getSecureContext`](#getSecureContext).
-}
type alias SecureContext =
    Effect.Internal.CryptoSecureContext


{-| A generated key.
-}
type alias Key key keyData =
    Effect.Internal.CryptoKey key keyData


{-| A public key, used for encrypting and verifying values.
-}
type alias PublicKey key keyData =
    Effect.Internal.CryptoPublicKey key keyData


{-| A private key, used for decrypting and signing values.
-}
type alias PrivateKey key keyData =
    Effect.Internal.CryptoPrivateKey key keyData


{-| A set of public and private keys created by some key generation algorithms.
-}
type alias KeyPair key keyData =
    { publicKey : PublicKey key keyData
    , privateKey : PrivateKey key keyData
    }



-- READING A RESULT
--
-- An interpreter answers with the family's result type, so each function narrows that to
-- the one shape its own operation produces. The other shapes cannot occur. Where the
-- function has an error type it fails with it, and where its Task cannot fail it falls
-- back to a value instead.


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


simulatedKey : keyData -> Key key keyData
simulatedKey keyData =
    Effect.Internal.SimulatedCryptoKey { keyBytes = emptyBytes, data = keyData }


simulatedKeyPair : keyData -> KeyPair key keyData
simulatedKeyPair keyData =
    { publicKey = Effect.Internal.SimulatedCryptoPublicKey { keyBytes = emptyBytes, data = keyData }
    , privateKey = Effect.Internal.SimulatedCryptoPrivateKey { keyBytes = emptyBytes, data = keyData }
    }


plainContext : x -> Effect.Internal.PlainResult -> Task restriction x SecureContext
plainContext error result =
    case result of
        Effect.Internal.GotSecureContext context ->
            Effect.Internal.Succeed context

        _ ->
            Effect.Internal.Fail error


plainUuid : Effect.Internal.PlainResult -> Task restriction x String
plainUuid result =
    case result of
        Effect.Internal.GotUuid uuid ->
            Effect.Internal.Succeed uuid

        _ ->
            Effect.Internal.Succeed ""


plainBytesOr : Bytes -> Effect.Internal.PlainResult -> Task restriction x Bytes
plainBytesOr fallback result =
    case result of
        Effect.Internal.GotPlainBytes bytes ->
            Effect.Internal.Succeed bytes

        _ ->
            Effect.Internal.Succeed fallback


cipherKey : x -> Effect.Internal.CipherResult key keyData -> Task restriction x (Key key keyData)
cipherKey error result =
    case result of
        Effect.Internal.GotCipherKey key ->
            Effect.Internal.Succeed key

        _ ->
            Effect.Internal.Fail error


cipherKeyOr : Key key keyData -> Effect.Internal.CipherResult key keyData -> Task restriction x (Key key keyData)
cipherKeyOr fallback result =
    case result of
        Effect.Internal.GotCipherKey key ->
            Effect.Internal.Succeed key

        _ ->
            Effect.Internal.Succeed fallback


cipherBytes : x -> Effect.Internal.CipherResult key keyData -> Task restriction x Bytes
cipherBytes error result =
    case result of
        Effect.Internal.GotCipherBytes bytes ->
            Effect.Internal.Succeed bytes

        _ ->
            Effect.Internal.Fail error


cipherJwk : x -> Effect.Internal.CipherResult key keyData -> Task restriction x Json.Encode.Value
cipherJwk error result =
    case result of
        Effect.Internal.GotCipherJwk jwk ->
            Effect.Internal.Succeed jwk

        _ ->
            Effect.Internal.Fail error


macKey : x -> Effect.Internal.MacResult key keyData -> Task restriction x (Key key keyData)
macKey error result =
    case result of
        Effect.Internal.GotMacKey key ->
            Effect.Internal.Succeed key

        _ ->
            Effect.Internal.Fail error


macBytes : x -> Effect.Internal.MacResult key keyData -> Task restriction x Bytes
macBytes error result =
    case result of
        Effect.Internal.GotMacBytes bytes ->
            Effect.Internal.Succeed bytes

        _ ->
            Effect.Internal.Fail error


macBytesOr : Bytes -> Effect.Internal.MacResult key keyData -> Task restriction x Bytes
macBytesOr fallback result =
    case result of
        Effect.Internal.GotMacBytes bytes ->
            Effect.Internal.Succeed bytes

        _ ->
            Effect.Internal.Succeed fallback


macJwk : x -> Effect.Internal.MacResult key keyData -> Task restriction x Json.Encode.Value
macJwk error result =
    case result of
        Effect.Internal.GotMacJwk jwk ->
            Effect.Internal.Succeed jwk

        _ ->
            Effect.Internal.Fail error


publicKeyCipherKeyPair : x -> Effect.Internal.PublicKeyCipherResult key -> Task restriction x (KeyPair key Crypto.RsaKeyParams)
publicKeyCipherKeyPair error result =
    case result of
        Effect.Internal.GotCipherKeyPair publicKey privateKey ->
            Effect.Internal.Succeed { publicKey = publicKey, privateKey = privateKey }

        _ ->
            Effect.Internal.Fail error


publicKeyCipherPublicKey : x -> Effect.Internal.PublicKeyCipherResult key -> Task restriction x (PublicKey key Crypto.RsaKeyParams)
publicKeyCipherPublicKey error result =
    case result of
        Effect.Internal.GotCipherPublicKey key ->
            Effect.Internal.Succeed key

        _ ->
            Effect.Internal.Fail error


publicKeyCipherPrivateKey : x -> Effect.Internal.PublicKeyCipherResult key -> Task restriction x (PrivateKey key Crypto.RsaKeyParams)
publicKeyCipherPrivateKey error result =
    case result of
        Effect.Internal.GotCipherPrivateKey key ->
            Effect.Internal.Succeed key

        _ ->
            Effect.Internal.Fail error


publicKeyCipherBytes : x -> Effect.Internal.PublicKeyCipherResult key -> Task restriction x Bytes
publicKeyCipherBytes error result =
    case result of
        Effect.Internal.GotPublicKeyCipherBytes bytes ->
            Effect.Internal.Succeed bytes

        _ ->
            Effect.Internal.Fail error


publicKeyCipherBytesOr : Bytes -> Effect.Internal.PublicKeyCipherResult key -> Task restriction x Bytes
publicKeyCipherBytesOr fallback result =
    case result of
        Effect.Internal.GotPublicKeyCipherBytes bytes ->
            Effect.Internal.Succeed bytes

        _ ->
            Effect.Internal.Succeed fallback


publicKeyCipherJwk : x -> Effect.Internal.PublicKeyCipherResult key -> Task restriction x Json.Encode.Value
publicKeyCipherJwk error result =
    case result of
        Effect.Internal.GotPublicKeyCipherJwk jwk ->
            Effect.Internal.Succeed jwk

        _ ->
            Effect.Internal.Fail error


rsaSignatureKeyPair : x -> Effect.Internal.RsaSignatureResult key -> Task restriction x (KeyPair key Crypto.RsaKeyParams)
rsaSignatureKeyPair error result =
    case result of
        Effect.Internal.GotRsaSignatureKeyPair publicKey privateKey ->
            Effect.Internal.Succeed { publicKey = publicKey, privateKey = privateKey }

        _ ->
            Effect.Internal.Fail error


rsaSignaturePublicKey : x -> Effect.Internal.RsaSignatureResult key -> Task restriction x (PublicKey key Crypto.RsaKeyParams)
rsaSignaturePublicKey error result =
    case result of
        Effect.Internal.GotRsaSignaturePublicKey key ->
            Effect.Internal.Succeed key

        _ ->
            Effect.Internal.Fail error


rsaSignaturePrivateKey : x -> Effect.Internal.RsaSignatureResult key -> Task restriction x (PrivateKey key Crypto.RsaKeyParams)
rsaSignaturePrivateKey error result =
    case result of
        Effect.Internal.GotRsaSignaturePrivateKey key ->
            Effect.Internal.Succeed key

        _ ->
            Effect.Internal.Fail error


rsaSignatureBytes : x -> Effect.Internal.RsaSignatureResult key -> Task restriction x Bytes
rsaSignatureBytes error result =
    case result of
        Effect.Internal.GotRsaSignatureBytes bytes ->
            Effect.Internal.Succeed bytes

        _ ->
            Effect.Internal.Fail error


rsaSignatureBytesOr : Bytes -> Effect.Internal.RsaSignatureResult key -> Task restriction x Bytes
rsaSignatureBytesOr fallback result =
    case result of
        Effect.Internal.GotRsaSignatureBytes bytes ->
            Effect.Internal.Succeed bytes

        _ ->
            Effect.Internal.Succeed fallback


rsaSignatureJwk : x -> Effect.Internal.RsaSignatureResult key -> Task restriction x Json.Encode.Value
rsaSignatureJwk error result =
    case result of
        Effect.Internal.GotRsaSignatureJwk jwk ->
            Effect.Internal.Succeed jwk

        _ ->
            Effect.Internal.Fail error


ecSignatureKeyPairOr : KeyPair key Crypto.EcKeyParams -> Effect.Internal.EcSignatureResult key -> Task restriction x (KeyPair key Crypto.EcKeyParams)
ecSignatureKeyPairOr fallback result =
    case result of
        Effect.Internal.GotEcSignatureKeyPair publicKey privateKey ->
            Effect.Internal.Succeed { publicKey = publicKey, privateKey = privateKey }

        _ ->
            Effect.Internal.Succeed fallback


ecSignaturePublicKey : x -> Effect.Internal.EcSignatureResult key -> Task restriction x (PublicKey key Crypto.EcKeyParams)
ecSignaturePublicKey error result =
    case result of
        Effect.Internal.GotEcSignaturePublicKey key ->
            Effect.Internal.Succeed key

        _ ->
            Effect.Internal.Fail error


ecSignaturePrivateKey : x -> Effect.Internal.EcSignatureResult key -> Task restriction x (PrivateKey key Crypto.EcKeyParams)
ecSignaturePrivateKey error result =
    case result of
        Effect.Internal.GotEcSignaturePrivateKey key ->
            Effect.Internal.Succeed key

        _ ->
            Effect.Internal.Fail error


ecSignatureBytes : x -> Effect.Internal.EcSignatureResult key -> Task restriction x Bytes
ecSignatureBytes error result =
    case result of
        Effect.Internal.GotEcSignatureBytes bytes ->
            Effect.Internal.Succeed bytes

        _ ->
            Effect.Internal.Fail error


ecSignatureBytesOr : Bytes -> Effect.Internal.EcSignatureResult key -> Task restriction x Bytes
ecSignatureBytesOr fallback result =
    case result of
        Effect.Internal.GotEcSignatureBytes bytes ->
            Effect.Internal.Succeed bytes

        _ ->
            Effect.Internal.Succeed fallback


ecSignatureJwk : x -> Effect.Internal.EcSignatureResult key -> Task restriction x Json.Encode.Value
ecSignatureJwk error result =
    case result of
        Effect.Internal.GotEcSignatureJwk jwk ->
            Effect.Internal.Succeed jwk

        _ ->
            Effect.Internal.Fail error


{-| -}
getSecureContext : Task restriction () SecureContext
getSecureContext =
    Effect.Internal.CryptoTaskPlain Effect.Internal.GetSecureContext (plainContext ())


{-| -}
getRandomInt8Values : Int -> Task restriction x Bytes
getRandomInt8Values count =
    Effect.Internal.CryptoTaskPlain
        (Effect.Internal.GetRandomValues Effect.Internal.RandomInt8 count)
        (plainBytesOr (zeroBytes (clamp 0 65536 count)))


{-| -}
getRandomUInt8Values : Int -> Task restriction x Bytes
getRandomUInt8Values count =
    Effect.Internal.CryptoTaskPlain
        (Effect.Internal.GetRandomValues Effect.Internal.RandomUInt8 count)
        (plainBytesOr (zeroBytes (clamp 0 65536 count)))


{-| -}
getRandomInt16Values : Int -> Task restriction x Bytes
getRandomInt16Values count =
    Effect.Internal.CryptoTaskPlain
        (Effect.Internal.GetRandomValues Effect.Internal.RandomInt16 count)
        (plainBytesOr (zeroBytes (2 * clamp 0 32768 count)))


{-| -}
getRandomUInt16Values : Int -> Task restriction x Bytes
getRandomUInt16Values count =
    Effect.Internal.CryptoTaskPlain
        (Effect.Internal.GetRandomValues Effect.Internal.RandomUInt16 count)
        (plainBytesOr (zeroBytes (2 * clamp 0 32768 count)))


{-| -}
getRandomInt32Values : Int -> Task restriction x Bytes
getRandomInt32Values count =
    Effect.Internal.CryptoTaskPlain
        (Effect.Internal.GetRandomValues Effect.Internal.RandomInt32 count)
        (plainBytesOr (zeroBytes (4 * clamp 0 16384 count)))


{-| -}
getRandomUInt32Values : Int -> Task restriction x Bytes
getRandomUInt32Values count =
    Effect.Internal.CryptoTaskPlain
        (Effect.Internal.GetRandomValues Effect.Internal.RandomUInt32 count)
        (plainBytesOr (zeroBytes (4 * clamp 0 16384 count)))


{-| -}
randomUuidV4 : SecureContext -> Task restriction x String
randomUuidV4 context =
    Effect.Internal.CryptoTaskPlain (Effect.Internal.RandomUuid context) plainUuid


{-| -}
digest : SecureContext -> Crypto.DigestAlgorithm -> Bytes -> Task restriction x Bytes
digest context algorithm data =
    Effect.Internal.CryptoTaskPlain
        (Effect.Internal.Digest context algorithm data)
        (plainBytesOr (zeroBytes (digestWidth algorithm)))


{-| -}
generateAesCtrKey : SecureContext -> Crypto.AesKeyParams -> Task restriction x (Key Crypto.AesCtrKey Crypto.AesKeyParams)
generateAesCtrKey context params =
    Effect.Internal.CryptoTaskAesCtr
        (Effect.Internal.GenerateCipherKey context params)
        (cipherKeyOr (simulatedKey params))


{-| -}
importAesCtrKeyFromRaw : SecureContext -> Crypto.Extractable -> Bytes -> Task restriction Crypto.ImportAesKeyError (Key Crypto.AesCtrKey Crypto.AesKeyParams)
importAesCtrKeyFromRaw context extractable bytes =
    Effect.Internal.CryptoTaskAesCtr
        (Effect.Internal.ImportCipherKeyFromRaw context extractable bytes)
        (cipherKey Crypto.ImportAesKeyError)


{-| -}
importAesCtrKeyFromJwk : SecureContext -> Crypto.Extractable -> Json.Encode.Value -> Task restriction Crypto.ImportAesKeyError (Key Crypto.AesCtrKey Crypto.AesKeyParams)
importAesCtrKeyFromJwk context extractable jwk =
    Effect.Internal.CryptoTaskAesCtr
        (Effect.Internal.ImportCipherKeyFromJwk context extractable jwk)
        (cipherKey Crypto.ImportAesKeyError)


{-| -}
exportAesCtrKeyAsRaw : Key Crypto.AesCtrKey Crypto.AesKeyParams -> Task restriction Crypto.ExportKeyError Bytes
exportAesCtrKeyAsRaw key =
    Effect.Internal.CryptoTaskAesCtr (Effect.Internal.ExportCipherKeyAsRaw key) (cipherBytes Crypto.KeyNotExportable)


{-| -}
exportAesCtrKeyAsJwk : Key Crypto.AesCtrKey Crypto.AesKeyParams -> Task restriction Crypto.ExportKeyError Json.Encode.Value
exportAesCtrKeyAsJwk key =
    Effect.Internal.CryptoTaskAesCtr (Effect.Internal.ExportCipherKeyAsJwk key) (cipherJwk Crypto.KeyNotExportable)


{-| -}
encryptWithAesCtr : Crypto.AesCtrParams -> Key Crypto.AesCtrKey Crypto.AesKeyParams -> Bytes -> Task restriction Crypto.AesCtrEncryptionError Bytes
encryptWithAesCtr params key bytes =
    Effect.Internal.CryptoTaskAesCtr
        (Effect.Internal.Encrypt params key bytes)
        (cipherBytes Crypto.AesCtrEncryptionError)


{-| -}
decryptWithAesCtr : Crypto.AesCtrParams -> Key Crypto.AesCtrKey Crypto.AesKeyParams -> Bytes -> Task restriction Crypto.AesCtrDecryptionError Bytes
decryptWithAesCtr params key bytes =
    Effect.Internal.CryptoTaskAesCtr
        (Effect.Internal.Decrypt params key bytes)
        (cipherBytes Crypto.AesCtrDecryptionError)


{-| -}
generateAesCbcKey : SecureContext -> Crypto.AesKeyParams -> Task restriction x (Key Crypto.AesCbcKey Crypto.AesKeyParams)
generateAesCbcKey context params =
    Effect.Internal.CryptoTaskAesCbc
        (Effect.Internal.GenerateCipherKey context params)
        (cipherKeyOr (simulatedKey params))


{-| -}
importAesCbcKeyFromRaw : SecureContext -> Crypto.Extractable -> Bytes -> Task restriction Crypto.ImportAesKeyError (Key Crypto.AesCbcKey Crypto.AesKeyParams)
importAesCbcKeyFromRaw context extractable bytes =
    Effect.Internal.CryptoTaskAesCbc
        (Effect.Internal.ImportCipherKeyFromRaw context extractable bytes)
        (cipherKey Crypto.ImportAesKeyError)


{-| -}
importAesCbcKeyFromJwk : SecureContext -> Crypto.Extractable -> Json.Encode.Value -> Task restriction Crypto.ImportAesKeyError (Key Crypto.AesCbcKey Crypto.AesKeyParams)
importAesCbcKeyFromJwk context extractable jwk =
    Effect.Internal.CryptoTaskAesCbc
        (Effect.Internal.ImportCipherKeyFromJwk context extractable jwk)
        (cipherKey Crypto.ImportAesKeyError)


{-| -}
exportAesCbcKeyAsRaw : Key Crypto.AesCbcKey Crypto.AesKeyParams -> Task restriction Crypto.ExportKeyError Bytes
exportAesCbcKeyAsRaw key =
    Effect.Internal.CryptoTaskAesCbc (Effect.Internal.ExportCipherKeyAsRaw key) (cipherBytes Crypto.KeyNotExportable)


{-| -}
exportAesCbcKeyAsJwk : Key Crypto.AesCbcKey Crypto.AesKeyParams -> Task restriction Crypto.ExportKeyError Json.Encode.Value
exportAesCbcKeyAsJwk key =
    Effect.Internal.CryptoTaskAesCbc (Effect.Internal.ExportCipherKeyAsJwk key) (cipherJwk Crypto.KeyNotExportable)


{-| -}
encryptWithAesCbc : Crypto.AesCbcParams -> Key Crypto.AesCbcKey Crypto.AesKeyParams -> Bytes -> Task restriction Crypto.AesCbcEncryptionError Bytes
encryptWithAesCbc params key bytes =
    Effect.Internal.CryptoTaskAesCbc
        (Effect.Internal.Encrypt params key bytes)
        (cipherBytes Crypto.AesCbcEncryptionError)


{-| -}
decryptWithAesCbc : Crypto.AesCbcParams -> Key Crypto.AesCbcKey Crypto.AesKeyParams -> Bytes -> Task restriction Crypto.AesCbcDecryptionError Bytes
decryptWithAesCbc params key bytes =
    Effect.Internal.CryptoTaskAesCbc
        (Effect.Internal.Decrypt params key bytes)
        (cipherBytes Crypto.AesCbcDecryptionError)


{-| -}
generateAesGcmKey : SecureContext -> Crypto.AesKeyParams -> Task restriction x (Key Crypto.AesGcmKey Crypto.AesKeyParams)
generateAesGcmKey context params =
    Effect.Internal.CryptoTaskAesGcm
        (Effect.Internal.GenerateCipherKey context params)
        (cipherKeyOr (simulatedKey params))


{-| -}
importAesGcmKeyFromRaw : SecureContext -> Crypto.Extractable -> Bytes -> Task restriction Crypto.ImportAesKeyError (Key Crypto.AesGcmKey Crypto.AesKeyParams)
importAesGcmKeyFromRaw context extractable bytes =
    Effect.Internal.CryptoTaskAesGcm
        (Effect.Internal.ImportCipherKeyFromRaw context extractable bytes)
        (cipherKey Crypto.ImportAesKeyError)


{-| -}
importAesGcmKeyFromJwk : SecureContext -> Crypto.Extractable -> Json.Encode.Value -> Task restriction Crypto.ImportAesKeyError (Key Crypto.AesGcmKey Crypto.AesKeyParams)
importAesGcmKeyFromJwk context extractable jwk =
    Effect.Internal.CryptoTaskAesGcm
        (Effect.Internal.ImportCipherKeyFromJwk context extractable jwk)
        (cipherKey Crypto.ImportAesKeyError)


{-| -}
exportAesGcmKeyAsRaw : Key Crypto.AesGcmKey Crypto.AesKeyParams -> Task restriction Crypto.ExportKeyError Bytes
exportAesGcmKeyAsRaw key =
    Effect.Internal.CryptoTaskAesGcm (Effect.Internal.ExportCipherKeyAsRaw key) (cipherBytes Crypto.KeyNotExportable)


{-| -}
exportAesGcmKeyAsJwk : Key Crypto.AesGcmKey Crypto.AesKeyParams -> Task restriction Crypto.ExportKeyError Json.Encode.Value
exportAesGcmKeyAsJwk key =
    Effect.Internal.CryptoTaskAesGcm (Effect.Internal.ExportCipherKeyAsJwk key) (cipherJwk Crypto.KeyNotExportable)


{-| -}
encryptWithAesGcm : Crypto.AesGcmParams -> Key Crypto.AesGcmKey Crypto.AesKeyParams -> Bytes -> Task restriction Crypto.AesGcmEncryptionError Bytes
encryptWithAesGcm params key bytes =
    Effect.Internal.CryptoTaskAesGcm
        (Effect.Internal.Encrypt params key bytes)
        (cipherBytes Crypto.AesGcmEncryptionError)


{-| -}
decryptWithAesGcm : Crypto.AesGcmParams -> Key Crypto.AesGcmKey Crypto.AesKeyParams -> Bytes -> Task restriction Crypto.AesGcmDecryptionError Bytes
decryptWithAesGcm params key bytes =
    Effect.Internal.CryptoTaskAesGcm
        (Effect.Internal.Decrypt params key bytes)
        (cipherBytes Crypto.AesGcmDecryptionError)


{-| -}
generateHmacKey : SecureContext -> Crypto.HmacKeyParams -> Task restriction Crypto.HmacKeyGenerationError (Key Crypto.HmacKey Crypto.HmacKeyParams)
generateHmacKey context params =
    Effect.Internal.CryptoTaskHmac
        (Effect.Internal.GenerateMacKey context params)
        (macKey Crypto.HmacLengthNotDivisibleByEight)


{-| -}
importHmacKeyFromRaw : SecureContext -> Crypto.Extractable -> Crypto.DigestAlgorithm -> Maybe Int -> Bytes -> Task restriction Crypto.ImportHmacKeyError (Key Crypto.HmacKey Crypto.HmacKeyParams)
importHmacKeyFromRaw context extractable hash length bytes =
    Effect.Internal.CryptoTaskHmac
        (Effect.Internal.ImportMacKeyFromRaw context extractable hash length bytes)
        (macKey Crypto.ImportHmacKeyError)


{-| -}
importHmacKeyFromJwk : SecureContext -> Crypto.Extractable -> Crypto.DigestAlgorithm -> Maybe Int -> Json.Encode.Value -> Task restriction Crypto.ImportHmacKeyError (Key Crypto.HmacKey Crypto.HmacKeyParams)
importHmacKeyFromJwk context extractable hash length jwk =
    Effect.Internal.CryptoTaskHmac
        (Effect.Internal.ImportMacKeyFromJwk context extractable hash length jwk)
        (macKey Crypto.ImportHmacKeyError)


{-| -}
exportHmacKeyAsRaw : Key Crypto.HmacKey Crypto.HmacKeyParams -> Task restriction Crypto.ExportKeyError Bytes
exportHmacKeyAsRaw key =
    Effect.Internal.CryptoTaskHmac (Effect.Internal.ExportMacKeyAsRaw key) (macBytes Crypto.KeyNotExportable)


{-| -}
exportHmacKeyAsJwk : Key Crypto.HmacKey Crypto.HmacKeyParams -> Task restriction Crypto.ExportKeyError Json.Encode.Value
exportHmacKeyAsJwk key =
    Effect.Internal.CryptoTaskHmac (Effect.Internal.ExportMacKeyAsJwk key) (macJwk Crypto.KeyNotExportable)


{-| -}
signWithHmac : Key Crypto.HmacKey Crypto.HmacKeyParams -> Bytes -> Task restriction x Crypto.Signature
signWithHmac key bytes =
    Effect.Internal.CryptoTaskHmac (Effect.Internal.SignWithMacKey key bytes) (macBytesOr emptyBytes)


{-| -}
verifyWithHmac : Key Crypto.HmacKey Crypto.HmacKeyParams -> Crypto.Signature -> Bytes -> Task restriction () Bytes
verifyWithHmac key signature bytes =
    Effect.Internal.CryptoTaskHmac (Effect.Internal.VerifyWithMacKey key signature bytes) (macBytes ())


{-| -}
generateRsaOaepKeyPair : SecureContext -> Crypto.RsaKeyParams -> Task restriction Crypto.RsaKeyGenerationError (KeyPair Crypto.RsaOaepKey Crypto.RsaKeyParams)
generateRsaOaepKeyPair context params =
    Effect.Internal.CryptoTaskRsaOaep
        (Effect.Internal.GenerateCipherKeyPair context params)
        (publicKeyCipherKeyPair Crypto.ModulusLengthNotDivisibleByEight)


{-| -}
importRsaOaepPublicKeyFromSpki : SecureContext -> Crypto.ImportRsaKeyParams -> Bytes -> Task restriction Crypto.ImportRsaKeyError (PublicKey Crypto.RsaOaepKey Crypto.RsaKeyParams)
importRsaOaepPublicKeyFromSpki context params bytes =
    Effect.Internal.CryptoTaskRsaOaep
        (Effect.Internal.ImportCipherPublicKeyFromSpki context params bytes)
        (publicKeyCipherPublicKey Crypto.ImportRsaKeyError)


{-| -}
importRsaOaepPublicKeyFromJwk : SecureContext -> Crypto.ImportRsaKeyParams -> Json.Encode.Value -> Task restriction Crypto.ImportRsaKeyError (PublicKey Crypto.RsaOaepKey Crypto.RsaKeyParams)
importRsaOaepPublicKeyFromJwk context params jwk =
    Effect.Internal.CryptoTaskRsaOaep
        (Effect.Internal.ImportCipherPublicKeyFromJwk context params jwk)
        (publicKeyCipherPublicKey Crypto.ImportRsaKeyError)


{-| -}
importRsaOaepPrivateKeyFromPkcs8 : SecureContext -> Crypto.Extractable -> Crypto.ImportRsaKeyParams -> Bytes -> Task restriction Crypto.ImportRsaKeyError (PrivateKey Crypto.RsaOaepKey Crypto.RsaKeyParams)
importRsaOaepPrivateKeyFromPkcs8 context extractable params bytes =
    Effect.Internal.CryptoTaskRsaOaep
        (Effect.Internal.ImportCipherPrivateKeyFromPkcs8 context extractable params bytes)
        (publicKeyCipherPrivateKey Crypto.ImportRsaKeyError)


{-| -}
importRsaOaepPrivateKeyFromJwk : SecureContext -> Crypto.Extractable -> Crypto.ImportRsaKeyParams -> Json.Encode.Value -> Task restriction Crypto.ImportRsaKeyError (PrivateKey Crypto.RsaOaepKey Crypto.RsaKeyParams)
importRsaOaepPrivateKeyFromJwk context extractable params jwk =
    Effect.Internal.CryptoTaskRsaOaep
        (Effect.Internal.ImportCipherPrivateKeyFromJwk context extractable params jwk)
        (publicKeyCipherPrivateKey Crypto.ImportRsaKeyError)


{-| -}
exportRsaOaepPublicKeyAsSpki : PublicKey Crypto.RsaOaepKey Crypto.RsaKeyParams -> Task restriction () Bytes
exportRsaOaepPublicKeyAsSpki key =
    Effect.Internal.CryptoTaskRsaOaep (Effect.Internal.ExportCipherPublicKeyAsSpki key) (publicKeyCipherBytes ())


{-| -}
exportRsaOaepPublicKeyAsJwk : PublicKey Crypto.RsaOaepKey Crypto.RsaKeyParams -> Task restriction () Json.Encode.Value
exportRsaOaepPublicKeyAsJwk key =
    Effect.Internal.CryptoTaskRsaOaep (Effect.Internal.ExportCipherPublicKeyAsJwk key) (publicKeyCipherJwk ())


{-| -}
exportRsaOaepPrivateKeyAsPkcs8 : PrivateKey Crypto.RsaOaepKey Crypto.RsaKeyParams -> Task restriction Crypto.ExportKeyError Bytes
exportRsaOaepPrivateKeyAsPkcs8 key =
    Effect.Internal.CryptoTaskRsaOaep (Effect.Internal.ExportCipherPrivateKeyAsPkcs8 key) (publicKeyCipherBytes Crypto.KeyNotExportable)


{-| -}
exportRsaOaepPrivateKeyAsJwk : PrivateKey Crypto.RsaOaepKey Crypto.RsaKeyParams -> Task restriction Crypto.ExportKeyError Json.Encode.Value
exportRsaOaepPrivateKeyAsJwk key =
    Effect.Internal.CryptoTaskRsaOaep (Effect.Internal.ExportCipherPrivateKeyAsJwk key) (publicKeyCipherJwk Crypto.KeyNotExportable)


{-| -}
encryptWithRsaOaep : Crypto.RsaOaepParams -> PublicKey Crypto.RsaOaepKey Crypto.RsaKeyParams -> Bytes -> Task restriction x Bytes
encryptWithRsaOaep params key bytes =
    Effect.Internal.CryptoTaskRsaOaep
        (Effect.Internal.EncryptWithPublicKey params key bytes)
        (publicKeyCipherBytesOr emptyBytes)


{-| -}
decryptWithRsaOaep : Crypto.RsaOaepParams -> PrivateKey Crypto.RsaOaepKey Crypto.RsaKeyParams -> Bytes -> Task restriction Crypto.RsaOaepDecryptionError Bytes
decryptWithRsaOaep params key bytes =
    Effect.Internal.CryptoTaskRsaOaep
        (Effect.Internal.DecryptWithPrivateKey params key bytes)
        (publicKeyCipherBytes Crypto.RsaOaepDecryptionError)


{-| -}
generateRsaPssKeyPair : SecureContext -> Crypto.RsaKeyParams -> Task restriction Crypto.RsaKeyGenerationError (KeyPair Crypto.RsaPssKey Crypto.RsaKeyParams)
generateRsaPssKeyPair context params =
    Effect.Internal.CryptoTaskRsaPss
        (Effect.Internal.GenerateRsaSignatureKeyPair context params)
        (rsaSignatureKeyPair Crypto.ModulusLengthNotDivisibleByEight)


{-| -}
importRsaPssPublicKeyFromSpki : SecureContext -> Crypto.ImportRsaKeyParams -> Bytes -> Task restriction Crypto.ImportRsaKeyError (PublicKey Crypto.RsaPssKey Crypto.RsaKeyParams)
importRsaPssPublicKeyFromSpki context params bytes =
    Effect.Internal.CryptoTaskRsaPss
        (Effect.Internal.ImportRsaSignaturePublicKeyFromSpki context params bytes)
        (rsaSignaturePublicKey Crypto.ImportRsaKeyError)


{-| -}
importRsaPssPublicKeyFromJwk : SecureContext -> Crypto.ImportRsaKeyParams -> Json.Encode.Value -> Task restriction Crypto.ImportRsaKeyError (PublicKey Crypto.RsaPssKey Crypto.RsaKeyParams)
importRsaPssPublicKeyFromJwk context params jwk =
    Effect.Internal.CryptoTaskRsaPss
        (Effect.Internal.ImportRsaSignaturePublicKeyFromJwk context params jwk)
        (rsaSignaturePublicKey Crypto.ImportRsaKeyError)


{-| -}
importRsaPssPrivateKeyFromPkcs8 : SecureContext -> Crypto.Extractable -> Crypto.ImportRsaKeyParams -> Bytes -> Task restriction Crypto.ImportRsaKeyError (PrivateKey Crypto.RsaPssKey Crypto.RsaKeyParams)
importRsaPssPrivateKeyFromPkcs8 context extractable params bytes =
    Effect.Internal.CryptoTaskRsaPss
        (Effect.Internal.ImportRsaSignaturePrivateKeyFromPkcs8 context extractable params bytes)
        (rsaSignaturePrivateKey Crypto.ImportRsaKeyError)


{-| -}
importRsaPssPrivateKeyFromJwk : SecureContext -> Crypto.Extractable -> Crypto.ImportRsaKeyParams -> Json.Encode.Value -> Task restriction Crypto.ImportRsaKeyError (PrivateKey Crypto.RsaPssKey Crypto.RsaKeyParams)
importRsaPssPrivateKeyFromJwk context extractable params jwk =
    Effect.Internal.CryptoTaskRsaPss
        (Effect.Internal.ImportRsaSignaturePrivateKeyFromJwk context extractable params jwk)
        (rsaSignaturePrivateKey Crypto.ImportRsaKeyError)


{-| -}
exportRsaPssPublicKeyAsSpki : PublicKey Crypto.RsaPssKey Crypto.RsaKeyParams -> Task restriction () Bytes
exportRsaPssPublicKeyAsSpki key =
    Effect.Internal.CryptoTaskRsaPss (Effect.Internal.ExportRsaSignaturePublicKeyAsSpki key) (rsaSignatureBytes ())


{-| -}
exportRsaPssPublicKeyAsJwk : PublicKey Crypto.RsaPssKey Crypto.RsaKeyParams -> Task restriction () Json.Encode.Value
exportRsaPssPublicKeyAsJwk key =
    Effect.Internal.CryptoTaskRsaPss (Effect.Internal.ExportRsaSignaturePublicKeyAsJwk key) (rsaSignatureJwk ())


{-| -}
exportRsaPssPrivateKeyAsPkcs8 : PrivateKey Crypto.RsaPssKey Crypto.RsaKeyParams -> Task restriction Crypto.ExportKeyError Bytes
exportRsaPssPrivateKeyAsPkcs8 key =
    Effect.Internal.CryptoTaskRsaPss (Effect.Internal.ExportRsaSignaturePrivateKeyAsPkcs8 key) (rsaSignatureBytes Crypto.KeyNotExportable)


{-| -}
exportRsaPssPrivateKeyAsJwk : PrivateKey Crypto.RsaPssKey Crypto.RsaKeyParams -> Task restriction Crypto.ExportKeyError Json.Encode.Value
exportRsaPssPrivateKeyAsJwk key =
    Effect.Internal.CryptoTaskRsaPss (Effect.Internal.ExportRsaSignaturePrivateKeyAsJwk key) (rsaSignatureJwk Crypto.KeyNotExportable)


{-| -}
signWithRsaPss : Crypto.RsaPssParams -> PrivateKey Crypto.RsaPssKey Crypto.RsaKeyParams -> Bytes -> Task restriction Crypto.RsaPssSigningError Crypto.Signature
signWithRsaPss params key bytes =
    Effect.Internal.CryptoTaskRsaPss
        (Effect.Internal.SignWithRsaPrivateKey params key bytes)
        (rsaSignatureBytes Crypto.RsaPssSigningError)


{-| -}
verifyWithRsaPss : Crypto.RsaPssParams -> PublicKey Crypto.RsaPssKey Crypto.RsaKeyParams -> Crypto.Signature -> Bytes -> Task restriction () Bytes
verifyWithRsaPss params key signature bytes =
    Effect.Internal.CryptoTaskRsaPss
        (Effect.Internal.VerifyWithRsaPublicKey params key signature bytes)
        (rsaSignatureBytes ())


{-| -}
generateRsaSsaPkcs1V1_5KeyPair : SecureContext -> Crypto.RsaKeyParams -> Task restriction Crypto.RsaKeyGenerationError (KeyPair Crypto.RsaSsaPkcs1V1_5Key Crypto.RsaKeyParams)
generateRsaSsaPkcs1V1_5KeyPair context params =
    Effect.Internal.CryptoTaskRsaSsaPkcs1V1_5
        (Effect.Internal.GenerateRsaSignatureKeyPair context params)
        (rsaSignatureKeyPair Crypto.ModulusLengthNotDivisibleByEight)


{-| -}
importRsaSsaPkcs1V1_5PublicKeyFromSpki : SecureContext -> Crypto.ImportRsaKeyParams -> Bytes -> Task restriction Crypto.ImportRsaKeyError (PublicKey Crypto.RsaSsaPkcs1V1_5Key Crypto.RsaKeyParams)
importRsaSsaPkcs1V1_5PublicKeyFromSpki context params bytes =
    Effect.Internal.CryptoTaskRsaSsaPkcs1V1_5
        (Effect.Internal.ImportRsaSignaturePublicKeyFromSpki context params bytes)
        (rsaSignaturePublicKey Crypto.ImportRsaKeyError)


{-| -}
importRsaSsaPkcs1V1_5PublicKeyFromJwk : SecureContext -> Crypto.ImportRsaKeyParams -> Json.Encode.Value -> Task restriction Crypto.ImportRsaKeyError (PublicKey Crypto.RsaSsaPkcs1V1_5Key Crypto.RsaKeyParams)
importRsaSsaPkcs1V1_5PublicKeyFromJwk context params jwk =
    Effect.Internal.CryptoTaskRsaSsaPkcs1V1_5
        (Effect.Internal.ImportRsaSignaturePublicKeyFromJwk context params jwk)
        (rsaSignaturePublicKey Crypto.ImportRsaKeyError)


{-| -}
importRsaSsaPkcs1V1_5PrivateKeyFromPkcs8 : SecureContext -> Crypto.Extractable -> Crypto.ImportRsaKeyParams -> Bytes -> Task restriction Crypto.ImportRsaKeyError (PrivateKey Crypto.RsaSsaPkcs1V1_5Key Crypto.RsaKeyParams)
importRsaSsaPkcs1V1_5PrivateKeyFromPkcs8 context extractable params bytes =
    Effect.Internal.CryptoTaskRsaSsaPkcs1V1_5
        (Effect.Internal.ImportRsaSignaturePrivateKeyFromPkcs8 context extractable params bytes)
        (rsaSignaturePrivateKey Crypto.ImportRsaKeyError)


{-| -}
importRsaSsaPkcs1V1_5PrivateKeyFromJwk : SecureContext -> Crypto.Extractable -> Crypto.ImportRsaKeyParams -> Json.Encode.Value -> Task restriction Crypto.ImportRsaKeyError (PrivateKey Crypto.RsaSsaPkcs1V1_5Key Crypto.RsaKeyParams)
importRsaSsaPkcs1V1_5PrivateKeyFromJwk context extractable params jwk =
    Effect.Internal.CryptoTaskRsaSsaPkcs1V1_5
        (Effect.Internal.ImportRsaSignaturePrivateKeyFromJwk context extractable params jwk)
        (rsaSignaturePrivateKey Crypto.ImportRsaKeyError)


{-| -}
exportRsaSsaPkcs1V1_5PublicKeyAsSpki : PublicKey Crypto.RsaSsaPkcs1V1_5Key Crypto.RsaKeyParams -> Task restriction () Bytes
exportRsaSsaPkcs1V1_5PublicKeyAsSpki key =
    Effect.Internal.CryptoTaskRsaSsaPkcs1V1_5 (Effect.Internal.ExportRsaSignaturePublicKeyAsSpki key) (rsaSignatureBytes ())


{-| -}
exportRsaSsaPkcs1V1_5PublicKeyAsJwk : PublicKey Crypto.RsaSsaPkcs1V1_5Key Crypto.RsaKeyParams -> Task restriction () Json.Encode.Value
exportRsaSsaPkcs1V1_5PublicKeyAsJwk key =
    Effect.Internal.CryptoTaskRsaSsaPkcs1V1_5 (Effect.Internal.ExportRsaSignaturePublicKeyAsJwk key) (rsaSignatureJwk ())


{-| -}
exportRsaSsaPkcs1V1_5PrivateKeyAsPkcs8 : PrivateKey Crypto.RsaSsaPkcs1V1_5Key Crypto.RsaKeyParams -> Task restriction Crypto.ExportKeyError Bytes
exportRsaSsaPkcs1V1_5PrivateKeyAsPkcs8 key =
    Effect.Internal.CryptoTaskRsaSsaPkcs1V1_5 (Effect.Internal.ExportRsaSignaturePrivateKeyAsPkcs8 key) (rsaSignatureBytes Crypto.KeyNotExportable)


{-| -}
exportRsaSsaPkcs1V1_5PrivateKeyAsJwk : PrivateKey Crypto.RsaSsaPkcs1V1_5Key Crypto.RsaKeyParams -> Task restriction Crypto.ExportKeyError Json.Encode.Value
exportRsaSsaPkcs1V1_5PrivateKeyAsJwk key =
    Effect.Internal.CryptoTaskRsaSsaPkcs1V1_5 (Effect.Internal.ExportRsaSignaturePrivateKeyAsJwk key) (rsaSignatureJwk Crypto.KeyNotExportable)


{-| -}
signWithRsaSsaPkcs1V1_5 : PrivateKey Crypto.RsaSsaPkcs1V1_5Key Crypto.RsaKeyParams -> Bytes -> Task restriction x Crypto.Signature
signWithRsaSsaPkcs1V1_5 key bytes =
    Effect.Internal.CryptoTaskRsaSsaPkcs1V1_5
        (Effect.Internal.SignWithRsaPrivateKey () key bytes)
        (rsaSignatureBytesOr emptyBytes)


{-| -}
verifyWithRsaSsaPkcs1V1_5 : PublicKey Crypto.RsaSsaPkcs1V1_5Key Crypto.RsaKeyParams -> Crypto.Signature -> Bytes -> Task restriction () Bytes
verifyWithRsaSsaPkcs1V1_5 key signature bytes =
    Effect.Internal.CryptoTaskRsaSsaPkcs1V1_5
        (Effect.Internal.VerifyWithRsaPublicKey () key signature bytes)
        (rsaSignatureBytes ())


{-| -}
generateEcdsaKeyPair : SecureContext -> Crypto.EcKeyParams -> Task restriction x (KeyPair Crypto.EcdsaKey Crypto.EcKeyParams)
generateEcdsaKeyPair context params =
    Effect.Internal.CryptoTaskEcdsa
        (Effect.Internal.GenerateEcSignatureKeyPair context params)
        (ecSignatureKeyPairOr (simulatedKeyPair params))


{-| -}
importEcdsaPublicKeyFromRaw : SecureContext -> Crypto.EcNamedCurve -> Bytes -> Task restriction Crypto.ImportEcKeyError (PublicKey Crypto.EcdsaKey Crypto.EcKeyParams)
importEcdsaPublicKeyFromRaw context namedCurve bytes =
    Effect.Internal.CryptoTaskEcdsa
        (Effect.Internal.ImportEcSignaturePublicKeyFromRaw context namedCurve bytes)
        (ecSignaturePublicKey Crypto.ImportEcKeyError)


{-| -}
importEcdsaPublicKeyFromSpki : SecureContext -> Crypto.EcNamedCurve -> Bytes -> Task restriction Crypto.ImportEcKeyError (PublicKey Crypto.EcdsaKey Crypto.EcKeyParams)
importEcdsaPublicKeyFromSpki context namedCurve bytes =
    Effect.Internal.CryptoTaskEcdsa
        (Effect.Internal.ImportEcSignaturePublicKeyFromSpki context namedCurve bytes)
        (ecSignaturePublicKey Crypto.ImportEcKeyError)


{-| -}
importEcdsaPublicKeyFromJwk : SecureContext -> Crypto.EcNamedCurve -> Json.Encode.Value -> Task restriction Crypto.ImportEcKeyError (PublicKey Crypto.EcdsaKey Crypto.EcKeyParams)
importEcdsaPublicKeyFromJwk context namedCurve jwk =
    Effect.Internal.CryptoTaskEcdsa
        (Effect.Internal.ImportEcSignaturePublicKeyFromJwk context namedCurve jwk)
        (ecSignaturePublicKey Crypto.ImportEcKeyError)


{-| -}
importEcdsaPrivateKeyFromPkcs8 : SecureContext -> Crypto.Extractable -> Crypto.EcNamedCurve -> Bytes -> Task restriction Crypto.ImportEcKeyError (PrivateKey Crypto.EcdsaKey Crypto.EcKeyParams)
importEcdsaPrivateKeyFromPkcs8 context extractable namedCurve bytes =
    Effect.Internal.CryptoTaskEcdsa
        (Effect.Internal.ImportEcSignaturePrivateKeyFromPkcs8 context extractable namedCurve bytes)
        (ecSignaturePrivateKey Crypto.ImportEcKeyError)


{-| -}
importEcdsaPrivateKeyFromSpki : SecureContext -> Crypto.Extractable -> Crypto.EcNamedCurve -> Bytes -> Task restriction Crypto.ImportEcKeyError (PrivateKey Crypto.EcdsaKey Crypto.EcKeyParams)
importEcdsaPrivateKeyFromSpki context extractable namedCurve bytes =
    Effect.Internal.CryptoTaskEcdsa
        (Effect.Internal.ImportEcSignaturePrivateKeyFromSpki context extractable namedCurve bytes)
        (ecSignaturePrivateKey Crypto.ImportEcKeyError)


{-| -}
importEcdsaPrivateKeyFromJwk : SecureContext -> Crypto.Extractable -> Crypto.EcNamedCurve -> Json.Encode.Value -> Task restriction Crypto.ImportEcKeyError (PrivateKey Crypto.EcdsaKey Crypto.EcKeyParams)
importEcdsaPrivateKeyFromJwk context extractable namedCurve jwk =
    Effect.Internal.CryptoTaskEcdsa
        (Effect.Internal.ImportEcSignaturePrivateKeyFromJwk context extractable namedCurve jwk)
        (ecSignaturePrivateKey Crypto.ImportEcKeyError)


{-| -}
exportEcdsaPublicKeyAsRaw : PublicKey Crypto.EcdsaKey Crypto.EcKeyParams -> Task restriction () Bytes
exportEcdsaPublicKeyAsRaw key =
    Effect.Internal.CryptoTaskEcdsa (Effect.Internal.ExportEcSignaturePublicKeyAsRaw key) (ecSignatureBytes ())


{-| -}
exportEcdsaPublicKeyAsSpki : PublicKey Crypto.EcdsaKey Crypto.EcKeyParams -> Task restriction () Bytes
exportEcdsaPublicKeyAsSpki key =
    Effect.Internal.CryptoTaskEcdsa (Effect.Internal.ExportEcSignaturePublicKeyAsSpki key) (ecSignatureBytes ())


{-| -}
exportEcdsaPublicKeyAsJwk : PublicKey Crypto.EcdsaKey Crypto.EcKeyParams -> Task restriction () Json.Encode.Value
exportEcdsaPublicKeyAsJwk key =
    Effect.Internal.CryptoTaskEcdsa (Effect.Internal.ExportEcSignaturePublicKeyAsJwk key) (ecSignatureJwk ())


{-| -}
exportEcdsaPrivateKeyAsPkcs8 : PrivateKey Crypto.EcdsaKey Crypto.EcKeyParams -> Task restriction Crypto.ExportKeyError Bytes
exportEcdsaPrivateKeyAsPkcs8 key =
    Effect.Internal.CryptoTaskEcdsa (Effect.Internal.ExportEcSignaturePrivateKeyAsPkcs8 key) (ecSignatureBytes Crypto.KeyNotExportable)


{-| -}
exportEcdsaPrivateKeyAsJwk : PrivateKey Crypto.EcdsaKey Crypto.EcKeyParams -> Task restriction Crypto.ExportKeyError Json.Encode.Value
exportEcdsaPrivateKeyAsJwk key =
    Effect.Internal.CryptoTaskEcdsa (Effect.Internal.ExportEcSignaturePrivateKeyAsJwk key) (ecSignatureJwk Crypto.KeyNotExportable)


{-| -}
signWithEcdsa : Crypto.DigestAlgorithm -> PrivateKey Crypto.EcdsaKey Crypto.EcKeyParams -> Bytes -> Task restriction x Crypto.Signature
signWithEcdsa hash key bytes =
    Effect.Internal.CryptoTaskEcdsa
        (Effect.Internal.SignWithEcPrivateKey hash key bytes)
        (ecSignatureBytesOr emptyBytes)


{-| -}
verifyWithEcdsa : Crypto.DigestAlgorithm -> PublicKey Crypto.EcdsaKey Crypto.EcKeyParams -> Crypto.Signature -> Bytes -> Task restriction () Bytes
verifyWithEcdsa hash key signature bytes =
    Effect.Internal.CryptoTaskEcdsa
        (Effect.Internal.VerifyWithEcPublicKey hash key signature bytes)
        (ecSignatureBytes ())


{-| Hand the `CryptoKey` behind a key to JavaScript, so it can be sent out through a port
and stored in IndexedDB. See [`Crypto.encodeKey`](Crypto#encodeKey). A key from a
simulated run encodes as `null`, since there is no `CryptoKey` behind it.
-}
encodeKey : Key key keyData -> Json.Encode.Value
encodeKey key =
    case key of
        Effect.Internal.BrowserCryptoKey realKey ->
            Crypto.encodeKey realKey

        Effect.Internal.SimulatedCryptoKey _ ->
            Json.Encode.null


{-| The same as [`encodeKey`](#encodeKey) for a public key.
-}
encodePublicKey : PublicKey key keyData -> Json.Encode.Value
encodePublicKey key =
    case key of
        Effect.Internal.BrowserCryptoPublicKey realKey ->
            Crypto.encodePublicKey realKey

        Effect.Internal.SimulatedCryptoPublicKey _ ->
            Json.Encode.null


{-| The same as [`encodeKey`](#encodeKey) for a private key.
-}
encodePrivateKey : PrivateKey key keyData -> Json.Encode.Value
encodePrivateKey key =
    case key of
        Effect.Internal.BrowserCryptoPrivateKey realKey ->
            Crypto.encodePrivateKey realKey

        Effect.Internal.SimulatedCryptoPrivateKey _ ->
            Json.Encode.null


{-| Encode both halves of a key pair into an object with a `publicKey` and a `privateKey`
field.
-}
encodeKeyPair : KeyPair key keyData -> Json.Encode.Value
encodeKeyPair keyPair =
    Json.Encode.object
        [ ( "publicKey", encodePublicKey keyPair.publicKey )
        , ( "privateKey", encodePrivateKey keyPair.privateKey )
        ]


{-| Read back a secret key that came in through a port, given the name of the algorithm it
was generated for. See [`Crypto.keyDecoder`](Crypto#keyDecoder).
-}
keyDecoder : String -> Json.Decode.Decoder (Key key keyData)
keyDecoder algorithm =
    Json.Decode.map Effect.Internal.BrowserCryptoKey (Crypto.keyDecoder algorithm)


{-| The same as [`keyDecoder`](#keyDecoder) for a public key.
-}
publicKeyDecoder : String -> Json.Decode.Decoder (PublicKey key keyData)
publicKeyDecoder algorithm =
    Json.Decode.map Effect.Internal.BrowserCryptoPublicKey (Crypto.publicKeyDecoder algorithm)


{-| The same as [`keyDecoder`](#keyDecoder) for a private key.
-}
privateKeyDecoder : String -> Json.Decode.Decoder (PrivateKey key keyData)
privateKeyDecoder algorithm =
    Json.Decode.map Effect.Internal.BrowserCryptoPrivateKey (Crypto.privateKeyDecoder algorithm)


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
    Json.Decode.map Effect.Internal.BrowserCryptoKey Crypto.aesCtrKeyDecoder


{-| -}
aesCbcKeyDecoder : Json.Decode.Decoder (Key Crypto.AesCbcKey Crypto.AesKeyParams)
aesCbcKeyDecoder =
    Json.Decode.map Effect.Internal.BrowserCryptoKey Crypto.aesCbcKeyDecoder


{-| -}
aesGcmKeyDecoder : Json.Decode.Decoder (Key Crypto.AesGcmKey Crypto.AesKeyParams)
aesGcmKeyDecoder =
    Json.Decode.map Effect.Internal.BrowserCryptoKey Crypto.aesGcmKeyDecoder


{-| -}
hmacKeyDecoder : Json.Decode.Decoder (Key Crypto.HmacKey Crypto.HmacKeyParams)
hmacKeyDecoder =
    Json.Decode.map Effect.Internal.BrowserCryptoKey Crypto.hmacKeyDecoder


{-| -}
rsaOaepPublicKeyDecoder : Json.Decode.Decoder (PublicKey Crypto.RsaOaepKey Crypto.RsaKeyParams)
rsaOaepPublicKeyDecoder =
    Json.Decode.map Effect.Internal.BrowserCryptoPublicKey Crypto.rsaOaepPublicKeyDecoder


{-| -}
rsaOaepPrivateKeyDecoder : Json.Decode.Decoder (PrivateKey Crypto.RsaOaepKey Crypto.RsaKeyParams)
rsaOaepPrivateKeyDecoder =
    Json.Decode.map Effect.Internal.BrowserCryptoPrivateKey Crypto.rsaOaepPrivateKeyDecoder


{-| -}
rsaPssPublicKeyDecoder : Json.Decode.Decoder (PublicKey Crypto.RsaPssKey Crypto.RsaKeyParams)
rsaPssPublicKeyDecoder =
    Json.Decode.map Effect.Internal.BrowserCryptoPublicKey Crypto.rsaPssPublicKeyDecoder


{-| -}
rsaPssPrivateKeyDecoder : Json.Decode.Decoder (PrivateKey Crypto.RsaPssKey Crypto.RsaKeyParams)
rsaPssPrivateKeyDecoder =
    Json.Decode.map Effect.Internal.BrowserCryptoPrivateKey Crypto.rsaPssPrivateKeyDecoder


{-| -}
rsaSsaPkcs1V1_5PublicKeyDecoder : Json.Decode.Decoder (PublicKey Crypto.RsaSsaPkcs1V1_5Key Crypto.RsaKeyParams)
rsaSsaPkcs1V1_5PublicKeyDecoder =
    Json.Decode.map Effect.Internal.BrowserCryptoPublicKey Crypto.rsaSsaPkcs1V1_5PublicKeyDecoder


{-| -}
rsaSsaPkcs1V1_5PrivateKeyDecoder : Json.Decode.Decoder (PrivateKey Crypto.RsaSsaPkcs1V1_5Key Crypto.RsaKeyParams)
rsaSsaPkcs1V1_5PrivateKeyDecoder =
    Json.Decode.map Effect.Internal.BrowserCryptoPrivateKey Crypto.rsaSsaPkcs1V1_5PrivateKeyDecoder


{-| -}
ecdsaPublicKeyDecoder : Json.Decode.Decoder (PublicKey Crypto.EcdsaKey Crypto.EcKeyParams)
ecdsaPublicKeyDecoder =
    Json.Decode.map Effect.Internal.BrowserCryptoPublicKey Crypto.ecdsaPublicKeyDecoder


{-| -}
ecdsaPrivateKeyDecoder : Json.Decode.Decoder (PrivateKey Crypto.EcdsaKey Crypto.EcKeyParams)
ecdsaPrivateKeyDecoder =
    Json.Decode.map Effect.Internal.BrowserCryptoPrivateKey Crypto.ecdsaPrivateKeyDecoder
