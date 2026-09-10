module Crypto exposing
    ( SecureContext, getSecureContext
    , getRandomInt8Values, getRandomUInt8Values
    , getRandomInt16Values, getRandomUInt16Values
    , getRandomInt32Values, getRandomUInt32Values
    , randomUuidV4
    , RsaOaepParams
    , encryptWithRsaOaep
    , RsaOaepDecryptionError(..), decryptWithRsaOaep
    , AesCtrParams
    , AesCtrEncryptionError(..), encryptWithAesCtr
    , AesCtrDecryptionError(..), decryptWithAesCtr
    , AesCbcParams
    , AesCbcEncryptionError(..), encryptWithAesCbc
    , AesCbcDecryptionError(..), decryptWithAesCbc
    , AesGcmParams, AesGcmTagLength(..)
    , AesGcmEncryptionError(..), encryptWithAesGcm
    , AesGcmDecryptionError(..), decryptWithAesGcm
    , Signature
    , signWithRsaSsaPkcs1V1_5
    , verifyWithRsaSsaPkcs1V1_5
    , RsaPssParams, RsaPssSigningError(..)
    , signWithRsaPss, verifyWithRsaPss
    , signWithEcdsa, verifyWithEcdsa
    , signWithHmac, verifyWithHmac
    , DigestAlgorithm(..), digest
    , Key, PublicKey, PrivateKey, KeyPair
    , Extractable(..)
    , RsaOaepKey, RsaPssKey, RsaSsaPkcs1V1_5Key, RsaKeyParams, RsaKeyGenerationError(..)
    , generateRsaOaepKeyPair, generateRsaPssKeyPair, generateRsaSsaPkcs1V1_5KeyPair
    , AesCtrKey, AesCbcKey, AesGcmKey, AesKeyParams, AesLength(..)
    , generateAesCtrKey, generateAesCbcKey, generateAesGcmKey
    , EcdsaKey, EcKeyParams, EcNamedCurve(..)
    , generateEcdsaKeyPair
    , HmacKey, HmacKeyParams, HmacKeyGenerationError(..)
    , generateHmacKey
    , ExportKeyError(..)
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
    , ImportRsaKeyParams, ImportRsaKeyError(..)
    , importRsaOaepPublicKeyFromJwk, importRsaOaepPublicKeyFromSpki
    , importRsaOaepPrivateKeyFromJwk, importRsaOaepPrivateKeyFromPkcs8
    , importRsaPssPublicKeyFromJwk, importRsaPssPublicKeyFromSpki
    , importRsaPssPrivateKeyFromJwk, importRsaPssPrivateKeyFromPkcs8
    , importRsaSsaPkcs1V1_5PrivateKeyFromJwk, importRsaSsaPkcs1V1_5PrivateKeyFromPkcs8
    , importRsaSsaPkcs1V1_5PublicKeyFromJwk, importRsaSsaPkcs1V1_5PublicKeyFromSpki
    , ImportAesKeyError(..)
    , importAesCbcKeyFromJwk, importAesCbcKeyFromRaw
    , importAesCtrKeyFromJwk, importAesCtrKeyFromRaw
    , importAesGcmKeyFromJwk, importAesGcmKeyFromRaw
    , ImportEcKeyError(..)
    , importEcdsaPrivateKeyFromJwk, importEcdsaPrivateKeyFromPkcs8, importEcdsaPrivateKeyFromSpki
    , importEcdsaPublicKeyFromJwk, importEcdsaPublicKeyFromRaw, importEcdsaPublicKeyFromSpki
    , ImportHmacKeyError(..)
    , importHmacKeyFromJwk, importHmacKeyFromRaw
    , encodeKey, encodePublicKey, encodePrivateKey, encodeKeyPair
    , keyDecoder, publicKeyDecoder, privateKeyDecoder, keyPairDecoder
    , aesCtrKeyDecoder, aesCbcKeyDecoder, aesGcmKeyDecoder, hmacKeyDecoder
    , rsaOaepPublicKeyDecoder, rsaOaepPrivateKeyDecoder
    , rsaPssPublicKeyDecoder, rsaPssPrivateKeyDecoder
    , rsaSsaPkcs1V1_5PublicKeyDecoder, rsaSsaPkcs1V1_5PrivateKeyDecoder
    , ecdsaPublicKeyDecoder, ecdsaPrivateKeyDecoder
    )

{-| This module gives access to various cryptographic functions provided by the Web
Crypto API.

In addition to supporting generating random values and [UUIDs](#randomUuidV4), this
module supports the following algorithms and operations:

  - RSA-OAEP - [Encryption](#encryptWithRsaOaep) and [decryption](#decryptWithRsaOaep)
  - AES-CTR - [Encryption](#encryptWithAesCtr) and [decryption](#decryptWithAesCtr)
  - AES-CBC - [Encryption](#encryptWithAesCbc) and [decryption](#decryptWithAesCbc)
  - AES-GCM - [Encryption](#encryptWithAesGcm) and [decryption](#decryptWithAesGcm)
  - RSA-SSAPKCS1v1.5 - [Signing](#signWithRsaSsaPkcs1V1_5) and [verifying](#verifyWithRsaSsaPkcs1V1_5)
  - RSA-PSS - [Signing](#signWithRsaPss) and [verifying](#verifyWithRsaPss)
  - ECDSA - [Signing](#signWithEcdsa) and [verifying](#verifyWithEcdsa)
  - HMAC - [Signing](#signWithHmac) and [verifying](#verifyWithHmac)
  - SHA - [Digest](#digest)

All of the above algorithms also have appropriate key generation, import, and
export functions.

This is a port of the `Crypto` module from `gren-lang/core` 7.4.2.


## Secure Context

Many functions in this module must be run in a secure context to operate safely
and correctly. Before you use any functions, it's likely that you'll need to obtain
and store the SecureContext value in your model.

@docs SecureContext, getSecureContext


## Generate Random Values

Generate random values of 8, 16, or 32 bits long (signed and unsigned).

All functions for generating random values take an `Int` as the single parameter.
This value is clamped to a minimum of `0` and a maximum of however many values can
be generated.

The maximum number of values that can be generated depends on the amount of bytes
the values you're generating are. 65536 is the maximum number of bytes that can be
generated. For example, when using `getRandomInt16Values`, each value is 16 bits
(or 2 bytes), so the maximum number of values that `getRandomInt16Values` can generate
is 32768 values.

@docs getRandomInt8Values, getRandomUInt8Values

@docs getRandomInt16Values, getRandomUInt16Values

@docs getRandomInt32Values, getRandomUInt32Values


## Generate Random UUIDs

@docs randomUuidV4


## Encryption & Decryption

Encrypt and decrypt values. Each operation requires a specific key for the algorithm
being used. You can learn more about key generation in the "Key Generation" section of
this module.


### Encrypt & decrypt with the RSA-OAEP algorithm

Encrypt and decrypt `Bytes` with the RSA-OAEP (Rivest-Shamir-Adleman Optimal Asymmetric
Encryption Padding) algorithm. These functions require an RSA-OAEP key pair. You can
generate one with the [`generateRsaOaepKeyPair`](#generateRsaOaepKeyPair) function.

@docs RsaOaepParams

@docs encryptWithRsaOaep

@docs RsaOaepDecryptionError, decryptWithRsaOaep


### Encrypt & decrypt with the AES-CTR algorithm

Encrypt and decrypt `Bytes` with the AES-CTR (Advanced Encryption Standard - Counter Mode)
algorithm. These functions require an AES-CTR key. You can generate one with the
[`generateAesCtrKey`](#generateAesCtrKey) function.

@docs AesCtrParams

@docs AesCtrEncryptionError, encryptWithAesCtr

@docs AesCtrDecryptionError, decryptWithAesCtr


### Encrypt & decrypt with the AES-CBC algorithm

Encrypt and decrypt `Bytes` with the AES-CBC (Advanced Encryption Standard - Cipher Block
Chaining) algorithm. These functions require an AES-CBC key. You can generate one with the
[`generateAesCbcKey`](#generateAesCbcKey) function.

@docs AesCbcParams

@docs AesCbcEncryptionError, encryptWithAesCbc

@docs AesCbcDecryptionError, decryptWithAesCbc


### Encrypt & decrypt with the AES-GCM algorithm

Encrypt and decrypt `Bytes` with the AES-GCM (Advanced Encryption Standard - Galois/Counter Mode)
algorithm. These functions require an AES-GCM key. You can generate one with the
[`generateAesGcmKey`](#generateAesGcmKey) function.

@docs AesGcmParams, AesGcmTagLength

@docs AesGcmEncryptionError, encryptWithAesGcm

@docs AesGcmDecryptionError, decryptWithAesGcm


## Signing & Verifying

Sign and verify values. Each operation requires a specific key for the algorithm being used. You can
learn more about key generation in the "Key Generation" section of this module.

@docs Signature


### Sign & verify with the RSASSA-PKCS1-v1\_5 algorithm

Sign and verify some `Bytes` with the RSASSA-PKCS1-v1\_5 algorithm. These functions require
an RSASSA-PKCS1-v1\_5 key. You can generate one with the
[`generateRsaSsaPkcs1V1_5KeyPair`](#generateRsaSsaPkcs1V1_5KeyPair) function.

@docs signWithRsaSsaPkcs1V1_5

@docs verifyWithRsaSsaPkcs1V1_5


### Sign & verify with the RSA-PSS algorithm

Sign and verify some `Bytes` with the RSA-PSS (Rivest, Shamir, and Adleman - Probabilistic Signature
Scheme) algorithm. These functions require an RSA-PSS key. You can generate one with the
[`generateRsaPssKeyPair`](#generateRsaPssKeyPair) function.

@docs RsaPssParams, RsaPssSigningError

@docs signWithRsaPss, verifyWithRsaPss


### Sign & verify with the ECDSA algorithm

Sign and verify some `Bytes` with the ECDSA (Elliptic Curve Digital Signature Algorithm) algorithm.
These functions require an ECDSA key. You can generate one with the
[`generateEcdsaKeyPair`](#generateEcdsaKeyPair) function.

@docs signWithEcdsa, verifyWithEcdsa


### Sign & verify with the HMAC algorithm

Sign and verify some `Bytes` with the HMAC (Hash-Based Message Authentication Code) algorithm.
These functions require an HMAC key. You can generate one with the
[`generateHmacKey`](#generateHmacKey) function.

@docs signWithHmac, verifyWithHmac


## Digest

@docs DigestAlgorithm, digest


## Generate Keys

Generate, import, and export keys for completing cryptographic operations.

@docs Key, PublicKey, PrivateKey, KeyPair

@docs Extractable


### Generate RSA Keys

Generate keys to use with RSA (Rivest-Shamir-Adleman) algorithm.

@docs RsaOaepKey, RsaPssKey, RsaSsaPkcs1V1_5Key, RsaKeyParams, RsaKeyGenerationError

@docs generateRsaOaepKeyPair, generateRsaPssKeyPair, generateRsaSsaPkcs1V1_5KeyPair


### Generate AES Keys

Generate keys to use with AES (Advanced Encryption Standard) algorithm.

@docs AesCtrKey, AesCbcKey, AesGcmKey, AesKeyParams, AesLength

@docs generateAesCtrKey, generateAesCbcKey, generateAesGcmKey


### Generate EC Keys

Generate keys to use with EC (Elliptic Curve) algorithm.

@docs EcdsaKey, EcKeyParams, EcNamedCurve

@docs generateEcdsaKeyPair


### Generate HMAC Keys

Generate keys to use with HMAC (Hash-Based Message Authentication Code) algorithm.

@docs HmacKey, HmacKeyParams, HmacKeyGenerationError

@docs generateHmacKey


## Export Keys

Export keys in various formats. Available formats depend on the key being exported. For more
information on exporting keys, check out the [MDN web docs](https://developer.mozilla.org/en-US/docs/Web/API/SubtleCrypto/exportKey)
for the Web Crypto API.

@docs ExportKeyError


### Export RSA Keys

@docs exportRsaOaepPublicKeyAsSpki, exportRsaOaepPublicKeyAsJwk

@docs exportRsaOaepPrivateKeyAsPkcs8, exportRsaOaepPrivateKeyAsJwk

@docs exportRsaPssPublicKeyAsSpki, exportRsaPssPublicKeyAsJwk

@docs exportRsaPssPrivateKeyAsPkcs8, exportRsaPssPrivateKeyAsJwk

@docs exportRsaSsaPkcs1V1_5PublicKeyAsSpki, exportRsaSsaPkcs1V1_5PublicKeyAsJwk

@docs exportRsaSsaPkcs1V1_5PrivateKeyAsPkcs8, exportRsaSsaPkcs1V1_5PrivateKeyAsJwk


### Export AES Keys

@docs exportAesCtrKeyAsRaw, exportAesCtrKeyAsJwk

@docs exportAesCbcKeyAsRaw, exportAesCbcKeyAsJwk

@docs exportAesGcmKeyAsRaw, exportAesGcmKeyAsJwk


### Export EC Keys

@docs exportEcdsaPublicKeyAsRaw, exportEcdsaPublicKeyAsSpki, exportEcdsaPublicKeyAsJwk

@docs exportEcdsaPrivateKeyAsPkcs8, exportEcdsaPrivateKeyAsJwk


### Export HMAC Keys

@docs exportHmacKeyAsRaw, exportHmacKeyAsJwk


## Import Keys

Import keys generated in this module or generated elsewhere. For more information on importing keys,
check out the [MDN web docs](https://developer.mozilla.org/en-US/docs/Web/API/SubtleCrypto/importKey)
for the Web Crypto API.


### Import RSA Keys

@docs ImportRsaKeyParams, ImportRsaKeyError

@docs importRsaOaepPublicKeyFromJwk, importRsaOaepPublicKeyFromSpki

@docs importRsaOaepPrivateKeyFromJwk, importRsaOaepPrivateKeyFromPkcs8

@docs importRsaPssPublicKeyFromJwk, importRsaPssPublicKeyFromSpki

@docs importRsaPssPrivateKeyFromJwk, importRsaPssPrivateKeyFromPkcs8

@docs importRsaSsaPkcs1V1_5PrivateKeyFromJwk, importRsaSsaPkcs1V1_5PrivateKeyFromPkcs8

@docs importRsaSsaPkcs1V1_5PublicKeyFromJwk, importRsaSsaPkcs1V1_5PublicKeyFromSpki


### Import AES Keys

@docs ImportAesKeyError

@docs importAesCbcKeyFromJwk, importAesCbcKeyFromRaw

@docs importAesCtrKeyFromJwk, importAesCtrKeyFromRaw

@docs importAesGcmKeyFromJwk, importAesGcmKeyFromRaw


### Import EC Keys

@docs ImportEcKeyError

@docs importEcdsaPrivateKeyFromJwk, importEcdsaPrivateKeyFromPkcs8, importEcdsaPrivateKeyFromSpki

@docs importEcdsaPublicKeyFromJwk, importEcdsaPublicKeyFromRaw, importEcdsaPublicKeyFromSpki


### Import HMAC Keys

@docs ImportHmacKeyError

@docs importHmacKeyFromJwk, importHmacKeyFromRaw


## Sending Keys Through Ports

A `CryptoKey` is a browser object, not data, so it cannot be turned into JSON and back.
It can still travel through a port though, because a port hands the value to JavaScript
as-is, and it can be stored in IndexedDB, because IndexedDB stores it with the structured
clone algorithm.

That is what these functions are for: `encodeKey` hands you the underlying `CryptoKey`
wrapped as a `Json.Encode.Value` to send out through a port, and the decoders take one
that came back in through a port and rebuild the `Key` around it. A key that was generated
with `CannotBeExtracted` survives the round trip intact, so writing it to IndexedDB and
reading it back later never exposes the key material to the page.

The decoders check the algorithm and the key type of what they are given, so a key stored
for one algorithm cannot be read back as a key for another.

@docs encodeKey, encodePublicKey, encodePrivateKey, encodeKeyPair

@docs keyDecoder, publicKeyDecoder, privateKeyDecoder, keyPairDecoder

@docs aesCtrKeyDecoder, aesCbcKeyDecoder, aesGcmKeyDecoder, hmacKeyDecoder

@docs rsaOaepPublicKeyDecoder, rsaOaepPrivateKeyDecoder

@docs rsaPssPublicKeyDecoder, rsaPssPrivateKeyDecoder

@docs rsaSsaPkcs1V1_5PublicKeyDecoder, rsaSsaPkcs1V1_5PrivateKeyDecoder

@docs ecdsaPublicKeyDecoder, ecdsaPrivateKeyDecoder

-}

import Bytes exposing (Bytes)
import Elm.Kernel.Crypto
import Json.Decode
import Json.Encode
import Task exposing (Task)



-- RANDOM UUID


{-| Generate a random UUID using the UUID v4 algorithm.
-}
randomUuidV4 : SecureContext -> Task x String
randomUuidV4 _ =
    Elm.Kernel.Crypto.randomUUID



-- RANDOM VALUES


{-| Get some `Bytes` of random, signed, 8-bit values equal to the length of the passed `Int`
with a maximum of 65536 values.
-}
getRandomInt8Values : Int -> Task x Bytes
getRandomInt8Values int =
    Elm.Kernel.Crypto.getRandomValues (clamp 0 65536 int) "int8"


{-| Get some `Bytes` of random, unsigned, 8-bit values equal to the length of the passed `Int`
with a maximum of 65536 values.
-}
getRandomUInt8Values : Int -> Task x Bytes
getRandomUInt8Values int =
    Elm.Kernel.Crypto.getRandomValues (clamp 0 65536 int) "uint8"


{-| Get some `Bytes` of random, signed, 16-bit values equal to the length of the passed `Int`.
with a maximum of 32768 values.
-}
getRandomInt16Values : Int -> Task x Bytes
getRandomInt16Values int =
    Elm.Kernel.Crypto.getRandomValues (clamp 0 32768 int) "int16"


{-| Get some `Bytes` of random, unsigned, 16-bit values equal to the length of the passed `Int`.
with a maximum of 32768 values.
-}
getRandomUInt16Values : Int -> Task x Bytes
getRandomUInt16Values int =
    Elm.Kernel.Crypto.getRandomValues (clamp 0 32768 int) "uint16"


{-| Get some `Bytes` of random, signed, 32-bit values equal to the length of the passed `Int`
with a maximum of 16384 values.
-}
getRandomInt32Values : Int -> Task x Bytes
getRandomInt32Values int =
    Elm.Kernel.Crypto.getRandomValues (clamp 0 16384 int) "int32"


{-| Get some `Bytes` of random, unsigned, 32-bit values equal to the length of the passed `Int`
with a maximum of 16384 values.
-}
getRandomUInt32Values : Int -> Task x Bytes
getRandomUInt32Values int =
    Elm.Kernel.Crypto.getRandomValues (clamp 0 16384 int) "uint32"



-- ENVIRONMENT


{-| Represents the platform being considered secure. This type can be generated using the
`getSecureContext` function and is required for some functions to be run in this package.
-}
type SecureContext
    = SecureContext


{-| A `Task` that succeeds with `SecureContext` if the code is being run in a
secure context. If this `Task` fails, most of the functions within this module
will not be able to run.

In the browser it will succeed if the application being run is
[considered as being in a secure context](https://developer.mozilla.org/en-US/docs/Web/Security/Secure_Contexts).

-}
getSecureContext : Task () SecureContext
getSecureContext =
    Elm.Kernel.Crypto.getContext



-- KEYS


{-| Denotes if a key can be exported using the export functions. If a key is not marked as
exportable when it is created or imported, any attempts to export the key will fail.

Public keys will always be exportable when generated or imported, regardless of
the `Extractable` value provided when generating the key.

-}
type Extractable
    = CanBeExtracted
    | CannotBeExtracted


{-| A generated key.
-}
type Key key keyData
    = Key
        { key : key
        , data : keyData
        }


{-| A public key that is used for encrypting and verifying values. This key type,
as the name suggests, can be exposed publicly and is safe to transport across the network.
-}
type PublicKey a b
    = PublicKey (Key a b)


{-| A private key that is used for decrypting and signing values. This key should
be protected and not revealed to any system outside of your application.
-}
type PrivateKey a b
    = PrivateKey (Key a b)


{-| A set of public and private keys created by some key generation algorithms.
-}
type alias KeyPair a b =
    { publicKey : PublicKey a b
    , privateKey : PrivateKey a b
    }



-- RSA KEYS


{-| A key generated and for use with the RSA-OAEP algorithm used to encrypt and
decrypt values.
-}
type RsaOaepKey
    = RsaOaepKey


{-| A key generated for use with the RSA-PSS algorithm. Used to sign and verify
values.
-}
type RsaPssKey
    = RsaPssKey


{-| A key generated for use with the RSASSA-PKCS1-v1\_5 algorithm. Used to sign
and verify values.
-}
type RsaSsaPkcs1V1_5Key
    = RsaSsaPkcs1V1_5Key


{-| Parameters required to generate a key for use with the RSA algorithm.

  - `modulusLength` is clamped be at least 2048 and no greater than 4096. If the
    `Int` used is outside of that range, it will be corrected. It also needs to be
    divisible by 8.
  - `hash` is the `DigestAlgorithm` that's used for key generation
  - `extractable` denotes that if this key is extractable or not. For more information,
    see the [`Extractable` type documentation](#Extractable).

A missing part of these parameters is the public exponent. Generated keys will always
have a `[ 1, 0, 1 ]` or `65537` public exponent. This is a recommended value and a value
that works across the browser and node platforms.

-}
type alias RsaKeyParams =
    { modulusLength : Int
    , hash : DigestAlgorithm
    , extractable : Extractable
    }


{-| Errors that can happen when generating a key for use with the RSA algorithm. There is
a single case where this function can fail at runtime:

  - When the passed `modulusLength` is not divisible by 8, as is required by the algorithm.
    This is captured by `ModulusLengthNotDivisibleByEight`.

-}
type RsaKeyGenerationError
    = ModulusLengthNotDivisibleByEight


{-| Generate a new key pair using the RSA-OAEP algorithm.

Produces a `KeyPair` that can be used to encrypt data with [`encryptWithRsaOaep`](#encryptWithRsaOaep)
and decrypt data with [`decryptWithRsaOaep`](#decryptWithRsaOaep).

-}
generateRsaOaepKeyPair : SecureContext -> RsaKeyParams -> Task RsaKeyGenerationError (KeyPair RsaOaepKey RsaKeyParams)
generateRsaOaepKeyPair _ params =
    generateRsaKeyHelper
        "RSA-OAEP"
        [ "encrypt", "decrypt" ]
        params


{-| Generate a new key using the RSA-PSS algorithm.

Produces a `KeyPair` that can be used to sign data with [`signWithRsaPss`](#signWithRsaPss)
and verify data with [`verifyWithRsaPss`](#verifyWithRsaPss).

-}
generateRsaPssKeyPair : SecureContext -> RsaKeyParams -> Task RsaKeyGenerationError (KeyPair RsaPssKey RsaKeyParams)
generateRsaPssKeyPair _ params =
    generateRsaKeyHelper
        "RSA-PSS"
        [ "sign", "verify" ]
        params


{-| Generate a new key using the RSASSA-PKCS1-v1\_5 algorithm.

Produces a `KeyPair` that can be used to sign data with
[`signWithRsaSsaPkcs1V1_5`](#signWithRsaSsaPkcs1V1_5) and verify data with
[`verifyWithRsaSsaPkcs1V1_5`](#verifyWithRsaSsaPkcs1V1_5).

-}
generateRsaSsaPkcs1V1_5KeyPair : SecureContext -> RsaKeyParams -> Task RsaKeyGenerationError (KeyPair RsaSsaPkcs1V1_5Key RsaKeyParams)
generateRsaSsaPkcs1V1_5KeyPair _ params =
    generateRsaKeyHelper
        "RSASSA-PKCS1-v1_5"
        [ "sign", "verify" ]
        params


generateRsaKeyHelper : String -> List String -> RsaKeyParams -> Task RsaKeyGenerationError a
generateRsaKeyHelper name permissions { modulusLength, hash, extractable } =
    let
        clampedModulusLength =
            clamp 2048 4096 modulusLength
    in
    if remainderBy 8 clampedModulusLength == 0 then
        Elm.Kernel.Crypto.generateRsaKey
            name
            clampedModulusLength
            [ 1, 0, 1 ]
            (digestAlgorithmToString hash)
            (extractableToBool extractable)
            permissions

    else
        Task.fail ModulusLengthNotDivisibleByEight



-- AES KEYS


{-| Represents a key generated and for use with the AES-CTR algorithm used to
encrypt and decrypt values.
-}
type AesCtrKey
    = AesCtrKey


{-| Represents a key generated and for use with the AES-CBC algorithm used to
encrypt and decrypt values.
-}
type AesCbcKey
    = AesCbcKey


{-| Represents a key generated and for use with the AES-GCM algorithm used to
encrypt and decrypt values.
-}
type AesGcmKey
    = AesGcmKey


{-| Parameters required to generate an AES key.

  - `length` is the length, in bits, of the generated key. It must be one of the
    [`AesLength`](#AesLength) type.
  - `extractable` denotes that if this key is extractable or not. For more information,
    see the [`Extractable` type documentation](#Extractable).

-}
type alias AesKeyParams =
    { length : AesLength
    , extractable : Extractable
    }


{-| The length of bits of the key that is being generated using the AES
algorithm. These are the only values that can be chosen.
-}
type AesLength
    = AesLength128
    | AesLength192
    | AesLength256


{-| Generate a new key using the AES-CTR algorithm.

Produces a `Key` that can be used to encrypt data with [`encryptWithAesCtr`](#encryptWithAesCtr)
and decrypt data with [`decryptWithAesCtr`](#decryptWithAesCtr).

-}
generateAesCtrKey : SecureContext -> AesKeyParams -> Task x (Key AesCtrKey AesKeyParams)
generateAesCtrKey _ { length, extractable } =
    Elm.Kernel.Crypto.generateAesKey
        "AES-CTR"
        (aesLengthToInt length)
        (extractableToBool extractable)
        [ "encrypt", "decrypt" ]


{-| Generate a new key using the AES-CBC algorithm.

Produces a `Key` that can be used to encrypt data with [`encryptWithAesCbc`](#encryptWithAesCbc)
and decrypt data with [`decryptWithAesCbc`](#decryptWithAesCbc).

-}
generateAesCbcKey : SecureContext -> AesKeyParams -> Task x (Key AesCbcKey AesKeyParams)
generateAesCbcKey _ { length, extractable } =
    Elm.Kernel.Crypto.generateAesKey
        "AES-CBC"
        (aesLengthToInt length)
        (extractableToBool extractable)
        [ "encrypt", "decrypt" ]


{-| Generate a new key using the AES-GCM algorithm.

Produces a `Key` that can be used to encrypt data with [`encryptWithAesGcm`](#encryptWithAesGcm)
and decrypt data with [`decryptWithAesGcm`](#decryptWithAesGcm).

-}
generateAesGcmKey : SecureContext -> AesKeyParams -> Task x (Key AesGcmKey AesKeyParams)
generateAesGcmKey _ { length, extractable } =
    Elm.Kernel.Crypto.generateAesKey
        "AES-GCM"
        (aesLengthToInt length)
        (extractableToBool extractable)
        [ "encrypt", "decrypt" ]



-- EC KEYS


{-| Represents a key generated and for use with the ECDSA algorithm used to
sign and verify values.
-}
type EcdsaKey
    = EcdsaKey


{-| Parameters required to generate an EC key.

  - `namedCurve` is the curve used to generate the key. It must be one of the
    [`EcNamedCurve`](#EcNamedCurve) variant.
  - `extractable` denotes that if this key is extractable or not. For more information,
    see the [`Extractable` type documentation](#Extractable).

-}
type alias EcKeyParams =
    { namedCurve : EcNamedCurve
    , extractable : Extractable
    }


{-| The name of the elliptic curve to use for the generated key.
-}
type EcNamedCurve
    = P256
    | P384
    | P521


{-| Generate a new key using the ECDSA algorithm.

Produces a `KeyPair` that can be used to sign data with [`signWithEcdsa`](#signWithEcdsa)
and verify data with [`verifyWithEcdsa`](#verifyWithEcdsa).

-}
generateEcdsaKeyPair : SecureContext -> EcKeyParams -> Task x (KeyPair EcdsaKey EcKeyParams)
generateEcdsaKeyPair _ { namedCurve, extractable } =
    Elm.Kernel.Crypto.generateEcKey
        "ECDSA"
        (ecNamedCurveToString namedCurve)
        (extractableToBool extractable)
        [ "sign", "verify" ]



-- HMAC KEYS


{-| A key generated and for use with the HMAC algorithm used to sign and verify
values.
-}
type HmacKey
    = HmacKey


{-| Errors that can happen when generating a key for use with the HMAC algorithm.
There's a single case where this function can fail:

  - When the passed `length` is not divisible by 8, as is required by the
    algorithm. This is captured by `HmacLengthNotDivisibleByEight`.

-}
type HmacKeyGenerationError
    = HmacLengthNotDivisibleByEight


{-| Parameters required to generate a key for use with the HMAC algorithm.

  - `length` is the length of the resulting key in bits. If `Nothing`, the key
    will be equal in bits to the passed `DigestAlgorithm`. It's recommended to pass
    `Nothing` and let the length of the key be equal to the hash function (`DigestAlgorithm`).
    If passed, the `length` is clamped be at least 8 and no greater than 2048.
    If the `Int` used is outside of that range, it will be corrected.
  - `hash` is the `DigestAlgorithm` that's used for key generation
  - `extractable` denotes that if this key is extractable or not. For more information,
    see the [`Extractable` type documentation](#Extractable).

-}
type alias HmacKeyParams =
    { length : Maybe Int
    , hash : DigestAlgorithm
    , extractable : Extractable
    }


{-| Generate a new key using the HMAC algorithm.

Produces a `Key` that can be used to sign data with [`signWithHmac`](#signWithHmac)
and verify data with [`verifyWithHmac`](#verifyWithHmac).

-}
generateHmacKey : SecureContext -> HmacKeyParams -> Task HmacKeyGenerationError (Key HmacKey HmacKeyParams)
generateHmacKey _ { hash, length, extractable } =
    case length of
        Just passedLength ->
            let
                clampedLength =
                    clamp 8 2048 passedLength
            in
            if remainderBy 8 clampedLength == 0 then
                Elm.Kernel.Crypto.generateHmacKey
                    "HMAC"
                    (digestAlgorithmToString hash)
                    clampedLength
                    (extractableToBool extractable)
                    [ "sign", "verify" ]

            else
                Task.fail HmacLengthNotDivisibleByEight

        Nothing ->
            Elm.Kernel.Crypto.generateHmacKey
                "HMAC"
                (digestAlgorithmToString hash)
                ""
                (extractableToBool extractable)
                [ "sign", "verify" ]



-- EXPORT KEYS


{-| Errors that can arise when exporting keys.

  - `KeyNotExportable` happens when trying to export a key that was not made
    `Extractable` during creation or import. This only applies to private keys,
    as public keys are always exportable.

-}
type ExportKeyError
    = KeyNotExportable


{-| -}
exportRsaOaepPublicKeyAsSpki : PublicKey RsaOaepKey RsaKeyParams -> Task () Bytes
exportRsaOaepPublicKeyAsSpki (PublicKey key) =
    exportPublicKeyAsSpki key


{-| -}
exportRsaOaepPublicKeyAsJwk : PublicKey RsaOaepKey RsaKeyParams -> Task () Json.Encode.Value
exportRsaOaepPublicKeyAsJwk (PublicKey key) =
    exportPublicKeyAsJwk key


{-| -}
exportRsaOaepPrivateKeyAsPkcs8 : PrivateKey RsaOaepKey RsaKeyParams -> Task ExportKeyError Bytes
exportRsaOaepPrivateKeyAsPkcs8 (PrivateKey key) =
    exportKeyAsPkcs8 key


{-| -}
exportRsaOaepPrivateKeyAsJwk : PrivateKey RsaOaepKey RsaKeyParams -> Task ExportKeyError Json.Encode.Value
exportRsaOaepPrivateKeyAsJwk (PrivateKey key) =
    exportKeyAsJwk key


{-| -}
exportRsaPssPublicKeyAsSpki : PublicKey RsaPssKey RsaKeyParams -> Task () Bytes
exportRsaPssPublicKeyAsSpki (PublicKey key) =
    exportPublicKeyAsSpki key


{-| -}
exportRsaPssPublicKeyAsJwk : PublicKey RsaPssKey RsaKeyParams -> Task () Json.Encode.Value
exportRsaPssPublicKeyAsJwk (PublicKey key) =
    exportPublicKeyAsJwk key


{-| -}
exportRsaPssPrivateKeyAsPkcs8 : PrivateKey RsaPssKey RsaKeyParams -> Task ExportKeyError Bytes
exportRsaPssPrivateKeyAsPkcs8 (PrivateKey key) =
    exportKeyAsPkcs8 key


{-| -}
exportRsaPssPrivateKeyAsJwk : PrivateKey RsaPssKey RsaKeyParams -> Task ExportKeyError Json.Encode.Value
exportRsaPssPrivateKeyAsJwk (PrivateKey key) =
    exportKeyAsJwk key


{-| -}
exportRsaSsaPkcs1V1_5PublicKeyAsSpki : PublicKey RsaSsaPkcs1V1_5Key RsaKeyParams -> Task () Bytes
exportRsaSsaPkcs1V1_5PublicKeyAsSpki (PublicKey key) =
    exportPublicKeyAsSpki key


{-| -}
exportRsaSsaPkcs1V1_5PublicKeyAsJwk : PublicKey RsaSsaPkcs1V1_5Key RsaKeyParams -> Task () Json.Encode.Value
exportRsaSsaPkcs1V1_5PublicKeyAsJwk (PublicKey key) =
    exportPublicKeyAsJwk key


{-| -}
exportRsaSsaPkcs1V1_5PrivateKeyAsPkcs8 : PrivateKey RsaSsaPkcs1V1_5Key RsaKeyParams -> Task ExportKeyError Bytes
exportRsaSsaPkcs1V1_5PrivateKeyAsPkcs8 (PrivateKey key) =
    exportKeyAsPkcs8 key


{-| -}
exportRsaSsaPkcs1V1_5PrivateKeyAsJwk : PrivateKey RsaSsaPkcs1V1_5Key RsaKeyParams -> Task ExportKeyError Json.Encode.Value
exportRsaSsaPkcs1V1_5PrivateKeyAsJwk (PrivateKey key) =
    exportKeyAsJwk key


{-| -}
exportAesCtrKeyAsRaw : Key AesCtrKey AesKeyParams -> Task ExportKeyError Bytes
exportAesCtrKeyAsRaw =
    exportKeyAsRaw


{-| -}
exportAesCtrKeyAsJwk : Key AesCtrKey AesKeyParams -> Task ExportKeyError Json.Encode.Value
exportAesCtrKeyAsJwk =
    exportKeyAsJwk


{-| -}
exportAesCbcKeyAsRaw : Key AesCbcKey AesKeyParams -> Task ExportKeyError Bytes
exportAesCbcKeyAsRaw =
    exportKeyAsRaw


{-| -}
exportAesCbcKeyAsJwk : Key AesCbcKey AesKeyParams -> Task ExportKeyError Json.Encode.Value
exportAesCbcKeyAsJwk =
    exportKeyAsJwk


{-| -}
exportAesGcmKeyAsRaw : Key AesGcmKey AesKeyParams -> Task ExportKeyError Bytes
exportAesGcmKeyAsRaw =
    exportKeyAsRaw


{-| -}
exportAesGcmKeyAsJwk : Key AesGcmKey AesKeyParams -> Task ExportKeyError Json.Encode.Value
exportAesGcmKeyAsJwk =
    exportKeyAsJwk


{-| -}
exportEcdsaPublicKeyAsRaw : PublicKey EcdsaKey EcKeyParams -> Task () Bytes
exportEcdsaPublicKeyAsRaw (PublicKey key) =
    exportPublicKeyAsRaw key


{-| -}
exportEcdsaPublicKeyAsSpki : PublicKey EcdsaKey EcKeyParams -> Task () Bytes
exportEcdsaPublicKeyAsSpki (PublicKey key) =
    exportPublicKeyAsSpki key


{-| -}
exportEcdsaPublicKeyAsJwk : PublicKey EcdsaKey EcKeyParams -> Task () Json.Encode.Value
exportEcdsaPublicKeyAsJwk (PublicKey key) =
    exportPublicKeyAsJwk key


{-| -}
exportEcdsaPrivateKeyAsPkcs8 : PrivateKey EcdsaKey EcKeyParams -> Task ExportKeyError Bytes
exportEcdsaPrivateKeyAsPkcs8 (PrivateKey key) =
    exportKeyAsPkcs8 key


{-| -}
exportEcdsaPrivateKeyAsJwk : PrivateKey EcdsaKey EcKeyParams -> Task ExportKeyError Json.Encode.Value
exportEcdsaPrivateKeyAsJwk (PrivateKey key) =
    exportKeyAsJwk key


{-| -}
exportHmacKeyAsRaw : Key HmacKey HmacKeyParams -> Task ExportKeyError Bytes
exportHmacKeyAsRaw =
    exportKeyAsRaw


{-| -}
exportHmacKeyAsJwk : Key HmacKey HmacKeyParams -> Task ExportKeyError Json.Encode.Value
exportHmacKeyAsJwk =
    exportKeyAsJwk


exportKeyHelper : String -> Key a b -> Task ExportKeyError c
exportKeyHelper keyType (Key { key }) =
    Elm.Kernel.Crypto.exportKey keyType key


{-| Identical to `exportKeyHelper`, only different in the return type.

As the name suggests, this is used when exporting public keys. These exports cannot
fail because public keys cannot be marked as not exportable.

-}
exportPublicKeyHelper : String -> Key a b -> Task () c
exportPublicKeyHelper keyType (Key { key }) =
    Elm.Kernel.Crypto.exportKey keyType key


exportPublicKeyAsRaw : Key a b -> Task () Bytes
exportPublicKeyAsRaw =
    exportPublicKeyHelper "raw"


exportKeyAsRaw : Key a b -> Task ExportKeyError Bytes
exportKeyAsRaw =
    exportKeyHelper "raw"


exportKeyAsPkcs8 : Key a b -> Task ExportKeyError Bytes
exportKeyAsPkcs8 =
    exportKeyHelper "pkcs8"


exportPublicKeyAsSpki : Key a b -> Task () Bytes
exportPublicKeyAsSpki =
    exportPublicKeyHelper "spki"


exportPublicKeyAsJwk : Key a b -> Task () Json.Encode.Value
exportPublicKeyAsJwk key =
    Task.map Elm.Kernel.Crypto.wrapJson (exportPublicKeyHelper "jwk" key)


exportKeyAsJwk : Key a b -> Task ExportKeyError Json.Encode.Value
exportKeyAsJwk key =
    Task.map Elm.Kernel.Crypto.wrapJson (exportKeyHelper "jwk" key)



-- IMPORT KEYS


{-| Parameters required for importing a key using an RSA algorithm.
-}
type alias ImportRsaKeyParams =
    { hash : DigestAlgorithm
    }


{-| Errors that can happen when importing a key using an RSA algorithm. There are a few possible
reasons this error happens:

  - The passed key value (either `Json.Encode.Value` or `Bytes`) is not a valid key and cannot be
    imported.
  - The `hash` passed to the function does not match the `hash` of the imported key. This only
    happens when importing a JSON Web Key. It is recommended to _always_ match the hash of the
    imported key or you will get different results when using the imported key, even when not importing
    in the JSON Web Key format.

-}
type ImportRsaKeyError
    = ImportRsaKeyError


{-| -}
importRsaOaepPublicKeyFromJwk : SecureContext -> ImportRsaKeyParams -> Json.Encode.Value -> Task ImportRsaKeyError (PublicKey RsaOaepKey RsaKeyParams)
importRsaOaepPublicKeyFromJwk _ { hash } jwk =
    Elm.Kernel.Crypto.importRsaKey
        "public"
        "jwk"
        (Elm.Kernel.Crypto.unwrapJson jwk)
        "RSA-OAEP"
        (digestAlgorithmToString hash)
        True
        [ "encrypt" ]


{-| -}
importRsaOaepPublicKeyFromSpki : SecureContext -> ImportRsaKeyParams -> Bytes -> Task ImportRsaKeyError (PublicKey RsaOaepKey RsaKeyParams)
importRsaOaepPublicKeyFromSpki _ { hash } bytes =
    Elm.Kernel.Crypto.importRsaKey
        "public"
        "spki"
        bytes
        "RSA-OAEP"
        (digestAlgorithmToString hash)
        True
        [ "encrypt" ]


{-| -}
importRsaPssPublicKeyFromJwk : SecureContext -> ImportRsaKeyParams -> Json.Encode.Value -> Task ImportRsaKeyError (PublicKey RsaPssKey RsaKeyParams)
importRsaPssPublicKeyFromJwk _ { hash } jwk =
    Elm.Kernel.Crypto.importRsaKey
        "public"
        "jwk"
        (Elm.Kernel.Crypto.unwrapJson jwk)
        "RSA-PSS"
        (digestAlgorithmToString hash)
        True
        [ "verify" ]


{-| -}
importRsaPssPublicKeyFromSpki : SecureContext -> ImportRsaKeyParams -> Bytes -> Task ImportRsaKeyError (PublicKey RsaPssKey RsaKeyParams)
importRsaPssPublicKeyFromSpki _ { hash } bytes =
    Elm.Kernel.Crypto.importRsaKey
        "public"
        "spki"
        bytes
        "RSA-PSS"
        (digestAlgorithmToString hash)
        True
        [ "verify" ]


{-| -}
importRsaOaepPrivateKeyFromJwk : SecureContext -> Extractable -> ImportRsaKeyParams -> Json.Encode.Value -> Task ImportRsaKeyError (PrivateKey RsaOaepKey RsaKeyParams)
importRsaOaepPrivateKeyFromJwk _ extractable { hash } jwk =
    Elm.Kernel.Crypto.importRsaKey
        "private"
        "jwk"
        (Elm.Kernel.Crypto.unwrapJson jwk)
        "RSA-OAEP"
        (digestAlgorithmToString hash)
        (extractableToBool extractable)
        [ "decrypt" ]


{-| -}
importRsaOaepPrivateKeyFromPkcs8 : SecureContext -> Extractable -> ImportRsaKeyParams -> Bytes -> Task ImportRsaKeyError (PrivateKey RsaOaepKey RsaKeyParams)
importRsaOaepPrivateKeyFromPkcs8 _ extractable { hash } bytes =
    Elm.Kernel.Crypto.importRsaKey
        "private"
        "pkcs8"
        bytes
        "RSA-OAEP"
        (digestAlgorithmToString hash)
        (extractableToBool extractable)
        [ "decrypt" ]


{-| -}
importRsaPssPrivateKeyFromJwk : SecureContext -> Extractable -> ImportRsaKeyParams -> Json.Encode.Value -> Task ImportRsaKeyError (PrivateKey RsaPssKey RsaKeyParams)
importRsaPssPrivateKeyFromJwk _ extractable { hash } jwk =
    Elm.Kernel.Crypto.importRsaKey
        "private"
        "jwk"
        (Elm.Kernel.Crypto.unwrapJson jwk)
        "RSA-PSS"
        (digestAlgorithmToString hash)
        (extractableToBool extractable)
        [ "sign" ]


{-| -}
importRsaPssPrivateKeyFromPkcs8 : SecureContext -> Extractable -> ImportRsaKeyParams -> Bytes -> Task ImportRsaKeyError (PrivateKey RsaPssKey RsaKeyParams)
importRsaPssPrivateKeyFromPkcs8 _ extractable { hash } bytes =
    Elm.Kernel.Crypto.importRsaKey
        "private"
        "pkcs8"
        bytes
        "RSA-PSS"
        (digestAlgorithmToString hash)
        (extractableToBool extractable)
        [ "sign" ]


{-| -}
importRsaSsaPkcs1V1_5PublicKeyFromJwk : SecureContext -> ImportRsaKeyParams -> Json.Encode.Value -> Task ImportRsaKeyError (PublicKey RsaSsaPkcs1V1_5Key RsaKeyParams)
importRsaSsaPkcs1V1_5PublicKeyFromJwk _ { hash } jwk =
    Elm.Kernel.Crypto.importRsaKey
        "public"
        "jwk"
        (Elm.Kernel.Crypto.unwrapJson jwk)
        "RSASSA-PKCS1-v1_5"
        (digestAlgorithmToString hash)
        True
        [ "verify" ]


{-| -}
importRsaSsaPkcs1V1_5PublicKeyFromSpki : SecureContext -> ImportRsaKeyParams -> Bytes -> Task ImportRsaKeyError (PublicKey RsaSsaPkcs1V1_5Key RsaKeyParams)
importRsaSsaPkcs1V1_5PublicKeyFromSpki _ { hash } bytes =
    Elm.Kernel.Crypto.importRsaKey
        "public"
        "spki"
        bytes
        "RSASSA-PKCS1-v1_5"
        (digestAlgorithmToString hash)
        True
        [ "verify" ]


{-| -}
importRsaSsaPkcs1V1_5PrivateKeyFromJwk : SecureContext -> Extractable -> ImportRsaKeyParams -> Json.Encode.Value -> Task ImportRsaKeyError (PrivateKey RsaSsaPkcs1V1_5Key RsaKeyParams)
importRsaSsaPkcs1V1_5PrivateKeyFromJwk _ extractable { hash } jwk =
    Elm.Kernel.Crypto.importRsaKey
        "private"
        "jwk"
        (Elm.Kernel.Crypto.unwrapJson jwk)
        "RSASSA-PKCS1-v1_5"
        (digestAlgorithmToString hash)
        (extractableToBool extractable)
        [ "sign" ]


{-| -}
importRsaSsaPkcs1V1_5PrivateKeyFromPkcs8 : SecureContext -> Extractable -> ImportRsaKeyParams -> Bytes -> Task ImportRsaKeyError (PrivateKey RsaSsaPkcs1V1_5Key RsaKeyParams)
importRsaSsaPkcs1V1_5PrivateKeyFromPkcs8 _ extractable { hash } bytes =
    Elm.Kernel.Crypto.importRsaKey
        "private"
        "pkcs8"
        bytes
        "RSASSA-PKCS1-v1_5"
        (digestAlgorithmToString hash)
        (extractableToBool extractable)
        [ "sign" ]


{-| Errors that can happen when importing a key using an AES algorithm. There's only one known
instance where this error can appear:

  - The passed key value (either `Json.Encode.Value` or `Bytes`) is not a valid key and cannot be
    imported.

-}
type ImportAesKeyError
    = ImportAesKeyError


{-| -}
importAesCtrKeyFromRaw : SecureContext -> Extractable -> Bytes -> Task ImportAesKeyError (Key AesCtrKey AesKeyParams)
importAesCtrKeyFromRaw _ extractable bytes =
    Elm.Kernel.Crypto.importAesKey
        "raw"
        bytes
        "AES-CTR"
        (extractableToBool extractable)
        [ "encrypt", "decrypt" ]


{-| -}
importAesCtrKeyFromJwk : SecureContext -> Extractable -> Json.Encode.Value -> Task ImportAesKeyError (Key AesCtrKey AesKeyParams)
importAesCtrKeyFromJwk _ extractable jwk =
    Elm.Kernel.Crypto.importAesKey
        "jwk"
        (Elm.Kernel.Crypto.unwrapJson jwk)
        "AES-CTR"
        (extractableToBool extractable)
        [ "encrypt", "decrypt" ]


{-| -}
importAesCbcKeyFromRaw : SecureContext -> Extractable -> Bytes -> Task ImportAesKeyError (Key AesCbcKey AesKeyParams)
importAesCbcKeyFromRaw _ extractable bytes =
    Elm.Kernel.Crypto.importAesKey
        "raw"
        bytes
        "AES-CBC"
        (extractableToBool extractable)
        [ "encrypt", "decrypt" ]


{-| -}
importAesCbcKeyFromJwk : SecureContext -> Extractable -> Json.Encode.Value -> Task ImportAesKeyError (Key AesCbcKey AesKeyParams)
importAesCbcKeyFromJwk _ extractable jwk =
    Elm.Kernel.Crypto.importAesKey
        "jwk"
        (Elm.Kernel.Crypto.unwrapJson jwk)
        "AES-CBC"
        (extractableToBool extractable)
        [ "encrypt", "decrypt" ]


{-| -}
importAesGcmKeyFromRaw : SecureContext -> Extractable -> Bytes -> Task ImportAesKeyError (Key AesGcmKey AesKeyParams)
importAesGcmKeyFromRaw _ extractable bytes =
    Elm.Kernel.Crypto.importAesKey
        "raw"
        bytes
        "AES-GCM"
        (extractableToBool extractable)
        [ "encrypt", "decrypt" ]


{-| -}
importAesGcmKeyFromJwk : SecureContext -> Extractable -> Json.Encode.Value -> Task ImportAesKeyError (Key AesGcmKey AesKeyParams)
importAesGcmKeyFromJwk _ extractable jwk =
    Elm.Kernel.Crypto.importAesKey
        "jwk"
        (Elm.Kernel.Crypto.unwrapJson jwk)
        "AES-GCM"
        (extractableToBool extractable)
        [ "encrypt", "decrypt" ]


{-| Errors that can happen when importing a key using an EC algorithm. There are two
possible reasons this error happens:

  - The passed key value (either `Json.Encode.Value` or `Bytes`) is not a valid key
    and cannot be imported.
  - The `EcNamedCurve` passed to the function does not match the `EcNamedCurve` of
    the imported key.

-}
type ImportEcKeyError
    = ImportEcKeyError


{-| -}
importEcdsaPublicKeyFromRaw : SecureContext -> EcNamedCurve -> Bytes -> Task ImportEcKeyError (PublicKey EcdsaKey EcKeyParams)
importEcdsaPublicKeyFromRaw _ namedCurve bytes =
    Elm.Kernel.Crypto.importEcKey
        "public"
        "raw"
        bytes
        "ECDSA"
        (ecNamedCurveToString namedCurve)
        True
        [ "verify" ]


{-| -}
importEcdsaPublicKeyFromSpki : SecureContext -> EcNamedCurve -> Bytes -> Task ImportEcKeyError (PublicKey EcdsaKey EcKeyParams)
importEcdsaPublicKeyFromSpki _ namedCurve bytes =
    Elm.Kernel.Crypto.importEcKey
        "public"
        "spki"
        bytes
        "ECDSA"
        (ecNamedCurveToString namedCurve)
        True
        [ "verify" ]


{-| -}
importEcdsaPublicKeyFromJwk : SecureContext -> EcNamedCurve -> Json.Encode.Value -> Task ImportEcKeyError (PublicKey EcdsaKey EcKeyParams)
importEcdsaPublicKeyFromJwk _ namedCurve jwk =
    Elm.Kernel.Crypto.importEcKey
        "public"
        "jwk"
        (Elm.Kernel.Crypto.unwrapJson jwk)
        "ECDSA"
        (ecNamedCurveToString namedCurve)
        True
        [ "verify" ]


{-| -}
importEcdsaPrivateKeyFromPkcs8 : SecureContext -> Extractable -> EcNamedCurve -> Bytes -> Task ImportEcKeyError (PrivateKey EcdsaKey EcKeyParams)
importEcdsaPrivateKeyFromPkcs8 _ extractable namedCurve bytes =
    Elm.Kernel.Crypto.importEcKey
        "private"
        "pkcs8"
        bytes
        "ECDSA"
        (ecNamedCurveToString namedCurve)
        (extractableToBool extractable)
        [ "sign" ]


{-| -}
importEcdsaPrivateKeyFromSpki : SecureContext -> Extractable -> EcNamedCurve -> Bytes -> Task ImportEcKeyError (PrivateKey EcdsaKey EcKeyParams)
importEcdsaPrivateKeyFromSpki _ extractable namedCurve bytes =
    Elm.Kernel.Crypto.importEcKey
        "private"
        "spki"
        bytes
        "ECDSA"
        (ecNamedCurveToString namedCurve)
        (extractableToBool extractable)
        [ "sign" ]


{-| -}
importEcdsaPrivateKeyFromJwk : SecureContext -> Extractable -> EcNamedCurve -> Json.Encode.Value -> Task ImportEcKeyError (PrivateKey EcdsaKey EcKeyParams)
importEcdsaPrivateKeyFromJwk _ extractable namedCurve jwk =
    Elm.Kernel.Crypto.importEcKey
        "private"
        "jwk"
        (Elm.Kernel.Crypto.unwrapJson jwk)
        "ECDSA"
        (ecNamedCurveToString namedCurve)
        (extractableToBool extractable)
        [ "sign" ]


{-| Errors that can happen when importing a key using an HMAC algorithm. There are three
known reasons an error can happen when importing HMAC keys:

  - The passed key value (either `Json.Encode.Value` or `Bytes`) is not a valid key
    and cannot be imported.
  - The `length` passed to the function is not correct for the imported key.
  - The `hash` passed to the function does not match the `hash` of the imported key.
    This only happens when importing a JSON Web Key. It is recommended to _always_ match
    the hash of the imported key or you will get different results when using the imported
    key for cryptographic functions.

-}
type ImportHmacKeyError
    = ImportHmacKeyError


{-| -}
importHmacKeyFromJwk : SecureContext -> Extractable -> DigestAlgorithm -> Maybe Int -> Json.Encode.Value -> Task ImportHmacKeyError (Key HmacKey HmacKeyParams)
importHmacKeyFromJwk _ extractable hash passedLength jwk =
    case passedLength of
        Just length ->
            Elm.Kernel.Crypto.importHmacKey
                "jwk"
                (Elm.Kernel.Crypto.unwrapJson jwk)
                "HMAC"
                (digestAlgorithmToString hash)
                length
                (extractableToBool extractable)
                [ "sign", "verify" ]

        Nothing ->
            Elm.Kernel.Crypto.importHmacKey
                "jwk"
                (Elm.Kernel.Crypto.unwrapJson jwk)
                "HMAC"
                (digestAlgorithmToString hash)
                ""
                (extractableToBool extractable)
                [ "sign", "verify" ]


{-| -}
importHmacKeyFromRaw : SecureContext -> Extractable -> DigestAlgorithm -> Maybe Int -> Bytes -> Task ImportHmacKeyError (Key HmacKey HmacKeyParams)
importHmacKeyFromRaw _ extractable hash passedLength bytes =
    case passedLength of
        Just length ->
            Elm.Kernel.Crypto.importHmacKey
                "raw"
                bytes
                "HMAC"
                (digestAlgorithmToString hash)
                length
                (extractableToBool extractable)
                [ "sign", "verify" ]

        Nothing ->
            Elm.Kernel.Crypto.importHmacKey
                "raw"
                bytes
                "HMAC"
                (digestAlgorithmToString hash)
                ""
                (extractableToBool extractable)
                [ "sign", "verify" ]



-- SENDING KEYS THROUGH PORTS


{-| Hand the `CryptoKey` behind a `Key` to JavaScript, so it can be sent out through a
port and stored in IndexedDB.

The `Json.Encode.Value` this returns is not JSON and there is nothing useful to read
inside it. `Json.Encode.encode` on it will not give you the key back, and neither will
sending it to a server. It only survives being passed through a port, put in IndexedDB,
and read back with the matching decoder.

-}
encodeKey : Key key keyData -> Json.Encode.Value
encodeKey (Key { key }) =
    Elm.Kernel.Crypto.wrapJson key


{-| The same as [`encodeKey`](#encodeKey) for a public key.
-}
encodePublicKey : PublicKey key keyData -> Json.Encode.Value
encodePublicKey (PublicKey (Key { key })) =
    Elm.Kernel.Crypto.wrapJson key


{-| The same as [`encodeKey`](#encodeKey) for a private key.
-}
encodePrivateKey : PrivateKey key keyData -> Json.Encode.Value
encodePrivateKey (PrivateKey (Key { key })) =
    Elm.Kernel.Crypto.wrapJson key


{-| Encode both halves of a key pair into an object with a `publicKey` and a `privateKey`
field. Read it back with [`keyPairDecoder`](#keyPairDecoder).
-}
encodeKeyPair : KeyPair key keyData -> Json.Encode.Value
encodeKeyPair keyPair =
    Json.Encode.object
        [ ( "publicKey", encodePublicKey keyPair.publicKey )
        , ( "privateKey", encodePrivateKey keyPair.privateKey )
        ]


{-| Read back a secret key that was written with [`encodeKey`](#encodeKey), given the
name of the algorithm it was generated for (`"AES-GCM"`, `"HMAC"` and so on).

Decoding fails if the value is not a `CryptoKey`, or if it is a key for a different
algorithm, or if it is one half of a key pair rather than a secret key.

-}
keyDecoder : String -> Json.Decode.Decoder (Key key keyData)
keyDecoder algorithm =
    Json.Decode.value
        |> Json.Decode.andThen
            (\value ->
                case Elm.Kernel.Crypto.decodeSecretKey algorithm value of
                    Just key ->
                        Json.Decode.succeed key

                    Nothing ->
                        Json.Decode.fail ("Expected a CryptoKey for " ++ algorithm)
            )


{-| The same as [`keyDecoder`](#keyDecoder) for a public key.
-}
publicKeyDecoder : String -> Json.Decode.Decoder (PublicKey key keyData)
publicKeyDecoder algorithm =
    Json.Decode.value
        |> Json.Decode.andThen
            (\value ->
                case Elm.Kernel.Crypto.decodePublicKey algorithm value of
                    Just key ->
                        Json.Decode.succeed key

                    Nothing ->
                        Json.Decode.fail ("Expected a public CryptoKey for " ++ algorithm)
            )


{-| The same as [`keyDecoder`](#keyDecoder) for a private key.
-}
privateKeyDecoder : String -> Json.Decode.Decoder (PrivateKey key keyData)
privateKeyDecoder algorithm =
    Json.Decode.value
        |> Json.Decode.andThen
            (\value ->
                case Elm.Kernel.Crypto.decodePrivateKey algorithm value of
                    Just key ->
                        Json.Decode.succeed key

                    Nothing ->
                        Json.Decode.fail ("Expected a private CryptoKey for " ++ algorithm)
            )


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
aesCtrKeyDecoder : Json.Decode.Decoder (Key AesCtrKey AesKeyParams)
aesCtrKeyDecoder =
    keyDecoder "AES-CTR"


{-| -}
aesCbcKeyDecoder : Json.Decode.Decoder (Key AesCbcKey AesKeyParams)
aesCbcKeyDecoder =
    keyDecoder "AES-CBC"


{-| -}
aesGcmKeyDecoder : Json.Decode.Decoder (Key AesGcmKey AesKeyParams)
aesGcmKeyDecoder =
    keyDecoder "AES-GCM"


{-| -}
hmacKeyDecoder : Json.Decode.Decoder (Key HmacKey HmacKeyParams)
hmacKeyDecoder =
    keyDecoder "HMAC"


{-| -}
rsaOaepPublicKeyDecoder : Json.Decode.Decoder (PublicKey RsaOaepKey RsaKeyParams)
rsaOaepPublicKeyDecoder =
    publicKeyDecoder "RSA-OAEP"


{-| -}
rsaOaepPrivateKeyDecoder : Json.Decode.Decoder (PrivateKey RsaOaepKey RsaKeyParams)
rsaOaepPrivateKeyDecoder =
    privateKeyDecoder "RSA-OAEP"


{-| -}
rsaPssPublicKeyDecoder : Json.Decode.Decoder (PublicKey RsaPssKey RsaKeyParams)
rsaPssPublicKeyDecoder =
    publicKeyDecoder "RSA-PSS"


{-| -}
rsaPssPrivateKeyDecoder : Json.Decode.Decoder (PrivateKey RsaPssKey RsaKeyParams)
rsaPssPrivateKeyDecoder =
    privateKeyDecoder "RSA-PSS"


{-| -}
rsaSsaPkcs1V1_5PublicKeyDecoder : Json.Decode.Decoder (PublicKey RsaSsaPkcs1V1_5Key RsaKeyParams)
rsaSsaPkcs1V1_5PublicKeyDecoder =
    publicKeyDecoder "RSASSA-PKCS1-v1_5"


{-| -}
rsaSsaPkcs1V1_5PrivateKeyDecoder : Json.Decode.Decoder (PrivateKey RsaSsaPkcs1V1_5Key RsaKeyParams)
rsaSsaPkcs1V1_5PrivateKeyDecoder =
    privateKeyDecoder "RSASSA-PKCS1-v1_5"


{-| -}
ecdsaPublicKeyDecoder : Json.Decode.Decoder (PublicKey EcdsaKey EcKeyParams)
ecdsaPublicKeyDecoder =
    publicKeyDecoder "ECDSA"


{-| -}
ecdsaPrivateKeyDecoder : Json.Decode.Decoder (PrivateKey EcdsaKey EcKeyParams)
ecdsaPrivateKeyDecoder =
    privateKeyDecoder "ECDSA"



-- ENCRYPT


{-| The parameters needed to encrypt or decrypt with the RSA-OAEP algorithm. There's only
one parameter: a `label` consisting of some `Bytes`. The label is completely optional and
passing `Nothing` will not make the operation less secure.
-}
type alias RsaOaepParams =
    { label : Maybe Bytes
    }


{-| Encrypt some `Bytes` with a `PublicKey RsaOaepKey`. You can generate the appropriate
key with the [`generateRsaOaepKeyPair`](#generateRsaOaepKeyPair) function.
-}
encryptWithRsaOaep : RsaOaepParams -> PublicKey RsaOaepKey RsaKeyParams -> Bytes -> Task x Bytes
encryptWithRsaOaep { label } (PublicKey (Key { key })) bytes =
    case label of
        Nothing ->
            Elm.Kernel.Crypto.encryptWithRsaOaep
                ""
                key
                bytes

        Just actualLabel ->
            Elm.Kernel.Crypto.encryptWithRsaOaep
                actualLabel
                key
                bytes


{-| Errors that can happen when encrypting using the [`encryptWithAesCtr`](#encryptWithAesCtr)
function. There are two cases where this function can fail:

  - When the passed `counter` in `AesCtrParams` is greater or less than the required 16 bytes.
    This is captured by `AesCtrEncryptionErrorCounterTooLong`.
  - Any unknown or unexpected errors are captured with `AesCtrEncryptionError`.

-}
type AesCtrEncryptionError
    = AesCtrEncryptionError
    | AesCtrEncryptionErrorCounterTooLong


{-| Required parameters to encrypt and decrypt values with the AES-CTR algorithm.

  - `counter` must be exactly 16 bytes, or else encryption and decryption will fail.
  - `length` must be between 1 and 128. If provided an `Int` that is below or above that
    range, it will be clamped to prevent the operation from failing.

-}
type alias AesCtrParams =
    { counter : Bytes
    , length : Int
    }


{-| Encrypt some `Bytes` with a `Key AesCtrKey`. You can generate the appropriate key
with the [`generateAesCtrKey`](#generateAesCtrKey) function.
-}
encryptWithAesCtr : AesCtrParams -> Key AesCtrKey AesKeyParams -> Bytes -> Task AesCtrEncryptionError Bytes
encryptWithAesCtr { counter, length } (Key { key }) bytes =
    if Bytes.width counter == 16 then
        Elm.Kernel.Crypto.encryptWithAesCtr
            counter
            (clamp 1 128 length)
            key
            bytes

    else
        Task.fail AesCtrEncryptionErrorCounterTooLong


{-| Errors that can happen when encrypting `Bytes` using the [`encryptWithAesCbc`](#encryptWithAesCbc)
function. There are a few cases where this function can fail:

  - When the passed `iv` in `AesCbcParams` is greater or less than the required 16 bytes.
    This is captured by `AesCbcEncryptionErrorIvTooLong`.
  - Any unknown or unexpected errors are captured by `AesCbcEncryptionError`.

-}
type AesCbcEncryptionError
    = AesCbcEncryptionErrorIvTooLong
    | AesCbcEncryptionError


{-| Required parameters to encrypt and decrypt values with the AES-CBC algorithm.

  - `iv` should be exactly 16 bytes. These bytes should be random, but do not need to
    be secret.

-}
type alias AesCbcParams =
    { iv : Bytes
    }


{-| Encrypt some `Bytes` with a `Key AesCbcKey`. You can generate the appropriate key
with the [`generateAesCbcKey`](#generateAesCbcKey) function.
-}
encryptWithAesCbc : AesCbcParams -> Key AesCbcKey AesKeyParams -> Bytes -> Task AesCbcEncryptionError Bytes
encryptWithAesCbc { iv } (Key { key }) bytes =
    if Bytes.width iv == 16 then
        Elm.Kernel.Crypto.encryptWithAesCbc
            iv
            key
            bytes

    else
        Task.fail AesCbcEncryptionErrorIvTooLong


{-| The set of allowed tag lengths for the AES-GCM algorithm.
-}
type AesGcmTagLength
    = AesGcmTagLength96
    | AesGcmTagLength104
    | AesGcmTagLength112
    | AesGcmTagLength120
    | AesGcmTagLength128


{-| Required parameters to encrypt and decrypt values with the AES-GCM algorithm.

  - `iv` needs to be at least 12 bytes, but no more than 128 bytes. The recommended
    length is 12 bytes.
  - `additionalData` is completely optional data that is not encrypted, but will be
    a part of the completed, encrypted, `Bytes`. If provided when encrypting data, the
    same value must be provided when decrypting it or else the operation will fail.
  - `tagLength` is optional and defaults to `AesGcmTagLength128`, which is recommended.
    You can find more information about this on the
    [Web Crypto API docs](https://developer.mozilla.org/en-US/docs/Web/API/AesGcmParams#taglength).

-}
type alias AesGcmParams =
    { iv : Bytes
    , additionalData : Maybe Bytes
    , tagLength : Maybe AesGcmTagLength
    }


{-| Errors that can happen when encrypting `Bytes` using the [`encryptWithAesGcm`](#encryptWithAesGcm)
function. There are a few cases where this function can fail:

  - When the passed `iv` in `AesGcmParams` is longer or shorter than required. This is captured by
    `AesGcmEncryptionErrorInvalidIvByteLength`.
  - Any unknown or unexpected errors are captured with `AesGcmEncryptionError`.

-}
type AesGcmEncryptionError
    = AesGcmEncryptionErrorInvalidIvByteLength
    | AesGcmEncryptionError


{-| Encrypt some `Bytes` with a `Key AesGcmKey`. You can generate the appropriate
key with the [`generateAesGcmKey`](#generateAesGcmKey) function.
-}
encryptWithAesGcm : AesGcmParams -> Key AesGcmKey AesKeyParams -> Bytes -> Task AesGcmEncryptionError Bytes
encryptWithAesGcm { iv, additionalData, tagLength } (Key { key }) bytes =
    let
        byteWidth =
            Bytes.width iv
    in
    if byteWidth <= 128 && byteWidth >= 12 then
        case ( additionalData, tagLength ) of
            ( Nothing, Nothing ) ->
                Elm.Kernel.Crypto.encryptWithAesGcm
                    iv
                    ""
                    ""
                    key
                    bytes

            ( Just ad, Nothing ) ->
                Elm.Kernel.Crypto.encryptWithAesGcm
                    iv
                    ad
                    ""
                    key
                    bytes

            ( Nothing, Just tl ) ->
                Elm.Kernel.Crypto.encryptWithAesGcm
                    iv
                    ""
                    (aesTagLengthToInt tl)
                    key
                    bytes

            ( Just ad, Just tl ) ->
                Elm.Kernel.Crypto.encryptWithAesGcm
                    iv
                    ad
                    (aesTagLengthToInt tl)
                    key
                    bytes

    else
        Task.fail AesGcmEncryptionErrorInvalidIvByteLength



-- DECRYPT


{-| Errors that can happen when decrypting `Bytes` using the [`decryptWithRsaOaep`](#decryptWithRsaOaep) function.
There are two cases where the function can fail:

  - The `label` used to encrypt the data does not match the label used when decrypting the data
  - The decryption algorithm fails due to the passed `Bytes` not being suitable for decryption (for whatever reason)

-}
type RsaOaepDecryptionError
    = RsaOaepDecryptionError


{-| Decrypt some `Bytes` with a `PrivateKey RsaOaepKey`. You can generate the appropriate key with the
[`generateRsaOaepKeyPair`](#generateRsaOaepKeyPair) function.
-}
decryptWithRsaOaep : RsaOaepParams -> PrivateKey RsaOaepKey RsaKeyParams -> Bytes -> Task RsaOaepDecryptionError Bytes
decryptWithRsaOaep { label } (PrivateKey (Key { key })) bytes =
    case label of
        Nothing ->
            Elm.Kernel.Crypto.decryptWithRsaOaep
                ""
                key
                bytes

        Just actualLabel ->
            Elm.Kernel.Crypto.decryptWithRsaOaep
                actualLabel
                key
                bytes


{-| Errors that can happen when decrypting `Bytes` using the [`decryptWithAesCtr`](#decryptWithAesCtr) function.
There are a few cases where this function can fail:

  - The passed `Bytes` are unable to be decrypted for whatever reason. This is captured by `AesCtrDecryptionError`.
  - When the passed `counter` in `AesCtrParams` is greater or less than the required 16 bytes. This is captured
    by `AesCtrDecryptionErrorCounterTooLong`.

-}
type AesCtrDecryptionError
    = AesCtrDecryptionError
    | AesCtrDecryptionErrorCounterTooLong


{-| Decrypt some `Bytes` with a `Key AesCtrKey`. You can generate the appropriate key
with the [`generateAesCtrKey`](#generateAesCtrKey) function.
-}
decryptWithAesCtr : AesCtrParams -> Key AesCtrKey AesKeyParams -> Bytes -> Task AesCtrDecryptionError Bytes
decryptWithAesCtr { counter, length } (Key { key }) bytes =
    if Bytes.width counter == 16 then
        Elm.Kernel.Crypto.decryptWithAesCtr
            counter
            (clamp 1 128 length)
            key
            bytes

    else
        Task.fail AesCtrDecryptionErrorCounterTooLong


{-| Errors that can happen when decrypting `Bytes` using the [`decryptWithAesCbc`](#decryptWithAesCbc)
function. There are a few cases where this function can fail:

  - The passed `Bytes` are unable to be decrypted for whatever reason. This is captured by
    `AesCbcDecryptionError`.
  - When the passed `iv` in `AesCbcParams` is greater or less than the required 16 bytes. This is
    captured by `AesCbcDecryptionErrorIvTooLong`.

-}
type AesCbcDecryptionError
    = AesCbcDecryptionErrorIvTooLong
    | AesCbcDecryptionError


{-| Decrypt some `Bytes` with a `Key AesCbcKey`. You can generate the appropriate key with the
[`generateAesCbcKey`](#generateAesCbcKey) function.

It's important to use the same `iv` value when encrypting and decrypting. Using a different `iv`
value will succeed, but the resulting `Bytes` will not match the `Bytes` originally encrypted.

-}
decryptWithAesCbc : AesCbcParams -> Key AesCbcKey AesKeyParams -> Bytes -> Task AesCbcDecryptionError Bytes
decryptWithAesCbc { iv } (Key { key }) bytes =
    if Bytes.width iv == 16 then
        Elm.Kernel.Crypto.decryptWithAesCbc
            iv
            key
            bytes

    else
        Task.fail AesCbcDecryptionErrorIvTooLong


{-| Errors that can happen when decrypting `Bytes` using the [`decryptWithAesGcm`](#decryptWithAesGcm)
function. There are a few cases where this function can fail:

  - The passed `Bytes` are unable to be decrypted for whatever reason. This is captured by
    `AesGcmDecryptionError`.
  - When the passed `iv` in `AesGcmParams` is longer or shorter than required. This is captured by
    `AesGcmDecryptionErrorInvalidIvByteLength`.
  - If the passed `iv` for encrypting the data does not match the `iv` being used to decrypt the data.
    This is captured with `AesGcmDecryptionError`.

-}
type AesGcmDecryptionError
    = AesGcmDecryptionErrorInvalidIvByteLength
    | AesGcmDecryptionError


{-| Decrypt some `Bytes` with a `Key AesGcmKey`. You can generate the appropriate
key with the [`generateAesGcmKey`](#generateAesGcmKey) function.
-}
decryptWithAesGcm : AesGcmParams -> Key AesGcmKey AesKeyParams -> Bytes -> Task AesGcmDecryptionError Bytes
decryptWithAesGcm { iv, additionalData, tagLength } (Key { key }) bytes =
    let
        byteWidth =
            Bytes.width iv
    in
    if byteWidth <= 128 && byteWidth >= 12 then
        case ( additionalData, tagLength ) of
            ( Nothing, Nothing ) ->
                Elm.Kernel.Crypto.decryptWithAesGcm
                    iv
                    ""
                    ""
                    key
                    bytes

            ( Just ad, Nothing ) ->
                Elm.Kernel.Crypto.decryptWithAesGcm
                    iv
                    ad
                    ""
                    key
                    bytes

            ( Nothing, Just tl ) ->
                Elm.Kernel.Crypto.decryptWithAesGcm
                    iv
                    ""
                    (aesTagLengthToInt tl)
                    key
                    bytes

            ( Just ad, Just tl ) ->
                Elm.Kernel.Crypto.decryptWithAesGcm
                    iv
                    ad
                    (aesTagLengthToInt tl)
                    key
                    bytes

    else
        Task.fail AesGcmDecryptionErrorInvalidIvByteLength



-- SIGN & VERIFY TYPES


{-| A handy alias for differentiating between arbitrary `Bytes` and the `Bytes` of a generated
signature (using a signing function).
-}
type alias Signature =
    Bytes



-- SIGN


{-| Sign some `Bytes` with the RSA-SSAPKCS1v1.5 algorithm. This produces a `Signature` (which
is just some `Bytes`). The `Signature` can be used with the corresponding verification function
to verify that the passed `Bytes` were signed with the passed key.
-}
signWithRsaSsaPkcs1V1_5 : PrivateKey RsaSsaPkcs1V1_5Key RsaKeyParams -> Bytes -> Task x Signature
signWithRsaSsaPkcs1V1_5 (PrivateKey (Key { key })) bytes =
    Elm.Kernel.Crypto.signWithRsaSsaPkcs1V1_5
        key
        bytes


{-| The parameters needed to sign or verify with the RSA-PSS algorithm.
-}
type alias RsaPssParams =
    { salt : Int
    }


{-| Errors that can happen when signing using the [`signWithRsaPss`](#signWithRsaPss) function. There are
a few cases where this function can fail:

  - If the passed `salt` as part of the `RsaPssParams` is not equal to or less than the amount of bytes of
    the `DigestAlgorithm` that was used to generate the key. For example, if the `RsaPssKey` was generated
    with SHA-256, the maximum number for the `salt` value must be 32 or less. This is captured by
    `RsaPssSigningErrorInvalidSalt`.
  - Any unknown or unexpected errors are captured with `RsaPssSigningError`.

-}
type RsaPssSigningError
    = RsaPssSigningErrorInvalidSalt
    | RsaPssSigningError


{-| Sign some `Bytes` with the RSA-PSS algorithm. This produces a `Signature` (which
is just some `Bytes`). The `Signature` can be used with the corresponding verification function
to verify that the passed `Bytes` were signed with the passed key.
-}
signWithRsaPss : RsaPssParams -> PrivateKey RsaPssKey RsaKeyParams -> Bytes -> Task RsaPssSigningError Signature
signWithRsaPss { salt } (PrivateKey (Key { key, data })) bytes =
    let
        clampedSaltBytes =
            clamp 0 2147483647 salt

        maxSalt =
            -- Safari (Webkit) will error if the salt length is greater than the hash of the
            -- created key. Capping it here keeps behaviour the same across platforms.
            case data.hash of
                Sha256 ->
                    32

                Sha384 ->
                    48

                Sha512 ->
                    64
    in
    if clampedSaltBytes > maxSalt then
        Task.fail RsaPssSigningErrorInvalidSalt

    else
        Elm.Kernel.Crypto.signWithRsaPss
            clampedSaltBytes
            key
            bytes


{-| Sign some `Bytes` with the ECDSA algorithm. This produces a `Signature` (which
is just some `Bytes`). The `Signature` can be used with the corresponding verification function
to verify that the passed `Bytes` were signed with the passed key.
-}
signWithEcdsa : DigestAlgorithm -> PrivateKey EcdsaKey EcKeyParams -> Bytes -> Task x Signature
signWithEcdsa hash (PrivateKey (Key { key })) bytes =
    Elm.Kernel.Crypto.signWithEcdsa
        (digestAlgorithmToString hash)
        key
        bytes


{-| Sign some `Bytes` with the HMAC algorithm. This produces a `Signature` (which
is just some `Bytes`). The `Signature` can be used with the corresponding verification function
to verify that the passed `Bytes` were signed with the passed key.
-}
signWithHmac : Key HmacKey HmacKeyParams -> Bytes -> Task x Signature
signWithHmac (Key { key }) bytes =
    Elm.Kernel.Crypto.signWithHmac
        key
        bytes



-- VERIFY


{-| Verify that some `Bytes` were signed with the passed `Signature` with the
RSA-SSAPKCS1v1.5 algorithm.

The `Task` succeeds with the verified `Bytes` if the passed signature is valid and
fails otherwise.

-}
verifyWithRsaSsaPkcs1V1_5 : PublicKey RsaSsaPkcs1V1_5Key RsaKeyParams -> Signature -> Bytes -> Task () Bytes
verifyWithRsaSsaPkcs1V1_5 (PublicKey (Key { key })) signature bytes =
    Elm.Kernel.Crypto.verifyWithRsaSsaPkcs1V1_5
        key
        signature
        bytes


{-| Verify that some `Bytes` were signed with the passed `Signature` with the
RSA-PSS algorithm.

The `Task` succeeds with the verified `Bytes` if the passed signature is valid and
fails otherwise.

-}
verifyWithRsaPss : RsaPssParams -> PublicKey RsaPssKey RsaKeyParams -> Signature -> Bytes -> Task () Bytes
verifyWithRsaPss { salt } (PublicKey (Key { key })) signature bytes =
    Elm.Kernel.Crypto.verifyWithRsaPss
        salt
        key
        signature
        bytes


{-| Verify that some `Bytes` were signed with the passed `Signature` with the
ECDSA algorithm.

The `Task` succeeds with the verified `Bytes` if the passed signature is valid and
fails otherwise.

-}
verifyWithEcdsa : DigestAlgorithm -> PublicKey EcdsaKey EcKeyParams -> Signature -> Bytes -> Task () Bytes
verifyWithEcdsa hash (PublicKey (Key { key })) signature bytes =
    Elm.Kernel.Crypto.verifyWithEcdsa
        (digestAlgorithmToString hash)
        key
        signature
        bytes


{-| Verify that some `Bytes` were signed with the passed `Signature` with the
HMAC algorithm.

The `Task` succeeds with the verified `Bytes` if the passed signature is valid and
fails otherwise.

-}
verifyWithHmac : Key HmacKey HmacKeyParams -> Signature -> Bytes -> Task () Bytes
verifyWithHmac (Key { key }) signature bytes =
    Elm.Kernel.Crypto.verifyWithHmac
        key
        signature
        bytes



-- DIGEST


{-| Supported algorithms suitable for digesting data.

Note: The algorithm `SHA1` is supported by the WebCrypto API, but not available
in this module due to known security vulnerabilities.

-}
type DigestAlgorithm
    = Sha256
    | Sha384
    | Sha512


{-| Take some `Bytes` and create a hash from them using the passed `DigestAlgorithm`.
This operation should always succeed.
-}
digest : SecureContext -> DigestAlgorithm -> Bytes -> Task x Bytes
digest _ algorithm data =
    Elm.Kernel.Crypto.digest
        (digestAlgorithmToString algorithm)
        data



-- UTILITIES


ecNamedCurveToString : EcNamedCurve -> String
ecNamedCurveToString namedCurve =
    case namedCurve of
        P256 ->
            "P-256"

        P384 ->
            "P-384"

        P521 ->
            "P-521"


aesLengthToInt : AesLength -> Int
aesLengthToInt length =
    case length of
        AesLength128 ->
            128

        AesLength192 ->
            192

        AesLength256 ->
            256


aesTagLengthToInt : AesGcmTagLength -> Int
aesTagLengthToInt aesTagLength =
    case aesTagLength of
        AesGcmTagLength96 ->
            96

        AesGcmTagLength104 ->
            104

        AesGcmTagLength112 ->
            112

        AesGcmTagLength120 ->
            120

        AesGcmTagLength128 ->
            128


extractableToBool : Extractable -> Bool
extractableToBool extractable =
    case extractable of
        CanBeExtracted ->
            True

        CannotBeExtracted ->
            False


digestAlgorithmToString : DigestAlgorithm -> String
digestAlgorithmToString digestAlgorithm =
    case digestAlgorithm of
        Sha256 ->
            "SHA-256"

        Sha384 ->
            "SHA-384"

        Sha512 ->
            "SHA-512"
