module X25519Tests exposing (tests)

import Bytes exposing (Bytes)
import Bytes.Decode
import Bytes.Encode
import Expect
import Fuzz
import Test exposing (Test)
import X25519


{-| The vectors here were all checked against an independent implementation written
straight from the RFC 7748 pseudocode with arbitrary precision integers, so that a
mistake in the limb arithmetic here cannot be papered over by the same mistake in what
it is being compared to.
-}
tests : Test
tests =
    Test.describe "X25519"
        [ rfcScalarMultTests
        , rfcDiffieHellmanTest
        , iteratedTest
        , lowOrderPointTests
        , highBitTest
        , crossCheckTests
        , encodingTests
        , agreementFuzzTest
        ]


{-| RFC 7748 section 5.2.
-}
rfcScalarMultTests : Test
rfcScalarMultTests =
    Test.describe "RFC 7748 section 5.2 scalar multiplication"
        (List.indexedMap
            (\index vector ->
                Test.test ("vector " ++ String.fromInt (index + 1))
                    (\_ -> expectScalarMult vector)
            )
            [ { scalar = "a546e36bf0527c9d3b16154b82465edd62144c0ac1fc5a18506a2244ba449ac4"
              , u = "e6db6867583030db3594c1a424b15f7c726624ec26b3353b10a903a6d0ab1c4c"
              , out = "c3da55379de9c6908e94ea4df28d084f32eccf03491c71f754b4075577a28552"
              }
            , { scalar = "4b66e9d4d1b4673c5ad22691957d6af5c11b6421e0ea01d42ca4169e7918ba0d"
              , u = "e5210f12786811d3f4b7959d0538ae2c31dbe7106fc03c3efc4cd549c715a493"
              , out = "95cbde9476e8907d7aade45cb4b873f88b595a68799fa152e6f8f7647aac7957"
              }
            ]
        )


{-| RFC 7748 section 6.1: the worked Diffie-Hellman exchange, including both public keys
so that a bug in the base point would show up separately from a bug in the agreement.
-}
rfcDiffieHellmanTest : Test
rfcDiffieHellmanTest =
    Test.describe "RFC 7748 section 6.1 Diffie-Hellman"
        [ Test.test "Alice's public key"
            (\_ ->
                privateKey alicePrivate
                    |> X25519.toPublicKey
                    |> X25519.publicKeyToBytes
                    |> toHex
                    |> Expect.equal alicePublic
            )
        , Test.test "Bob's public key"
            (\_ ->
                privateKey bobPrivate
                    |> X25519.toPublicKey
                    |> X25519.publicKeyToBytes
                    |> toHex
                    |> Expect.equal bobPublic
            )
        , Test.test "Alice's side of the shared secret"
            (\_ -> expectSharedSecret alicePrivate bobPublic sharedK)
        , Test.test "Bob's side of the shared secret"
            (\_ -> expectSharedSecret bobPrivate alicePublic sharedK)
        ]


alicePrivate : String
alicePrivate =
    "77076d0a7318a57d3c16c17251b26645df4c2f87ebc0992ab177fba51db92c2a"


alicePublic : String
alicePublic =
    "8520f0098930a754748b7ddcb43ef75a0dbf3a0d26381af4eba4a98eaa9b4e6a"


bobPrivate : String
bobPrivate =
    "5dab087e624a8a4b79e17f8b83800ee66f3bb1292618b6fd1c2f8b27ff88e0eb"


bobPublic : String
bobPublic =
    "de9edb7d7b7dc1b4d35b61c2ece435373f8343c85b78674dadfc7e146f882b4f"


sharedK : String
sharedK =
    "4a5d9d5ba4ce2de1728e3bf480350f25e07e21c947d19e3376f09b3c1e161742"


{-| RFC 7748 section 5.2's iterated test, which feeds each result back in as the next
scalar. The RFC also gives results after 1000 and 1000000 rounds; those are left out
because a round is not cheap in Elm and this catches the same class of mistake.
-}
iteratedTest : Test
iteratedTest =
    Test.test "RFC 7748 section 5.2 iterated, 1 round"
        (\_ ->
            let
                base : String
                base =
                    "0900000000000000000000000000000000000000000000000000000000000000"
            in
            iterate 1 base base
                |> Expect.equal "422c8e7a6227d7bca1350b3e2bb7279f7897b87bb6854b783c60e80311ae3079"
        )


iterate : Int -> String -> String -> String
iterate remaining k u =
    if remaining <= 0 then
        k

    else
        case X25519.sharedSecret (privateKey k) (publicKey u) of
            Just secret ->
                iterate (remaining - 1) (toHex (X25519.sharedSecretToBytes secret)) k

            Nothing ->
                "all zero output"


{-| The small subgroup points. Every one of them forces the shared secret to all zeros
whatever the private key is, so agreeing to one would let whoever supplied it read the
conversation. RFC 7748 section 6.1 says to reject them, which is what `Nothing` means.
-}
lowOrderPointTests : Test
lowOrderPointTests =
    Test.describe "low order public keys are rejected"
        (List.indexedMap
            (\index point ->
                Test.test ("point " ++ String.fromInt (index + 1))
                    (\_ ->
                        X25519.sharedSecret (privateKey alicePrivate) (publicKey point)
                            |> Expect.equal Nothing
                    )
            )
            [ "0000000000000000000000000000000000000000000000000000000000000000"
            , "0100000000000000000000000000000000000000000000000000000000000000"
            , "e0eb7a7c3b41b8ae1656e3faf19fc46ada098deb9c32b1fd866205165f49b800"
            , "5f9c95bca3508c24b1d0b1559c83ef5b04445cc4581c8e86d8224eddd09f1157"
            , "ecffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff7f"
            , "edffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff7f"
            , "eeffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff7f"
            ]
        )


{-| The top bit of the last byte of a u coordinate is not part of the number, and RFC
7748 says to ignore it rather than reject the key.
-}
highBitTest : Test
highBitTest =
    Test.test "the unused high bit of a public key is ignored"
        (\_ ->
            let
                withoutBit : String
                withoutBit =
                    "1f7bed81a4926eab9d9045618b82930a2a12fa670385f3847ddbcba1f2335242"

                withBit : String
                withBit =
                    "1f7bed81a4926eab9d9045618b82930a2a12fa670385f3847ddbcba1f23352c2"

                secretFor : String -> Maybe String
                secretFor point =
                    X25519.sharedSecret (privateKey alicePrivate) (publicKey point)
                        |> Maybe.map (\secret -> toHex (X25519.sharedSecretToBytes secret))
            in
            secretFor withBit |> Expect.equal (secretFor withoutBit)
        )


{-| Randomly generated inputs plus a few awkward ones: an all zero scalar, an all ones
scalar, u coordinates sitting on and just past the field's modulus, and coordinates with
the unused top bit set. Each expected result comes from the arbitrary precision reference.
-}
crossCheckTests : Test
crossCheckTests =
    Test.describe "cross checked against an arbitrary precision reference"
        (List.indexedMap
            (\index vector ->
                Test.test ("vector " ++ String.fromInt (index + 1))
                    (\_ -> expectScalarMult vector)
            )
            [ { scalar = "0000000000000000000000000000000000000000000000000000000000000000"
              , u = "0200000000000000000000000000000000000000000000000000000000000000"
              , out = "1bfd8c01d2fe9fca58ae61ab792b0a68feebfc17a2e95068d12fa5007a519541"
              }
            , { scalar = "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
              , u = "0900000000000000000000000000000000000000000000000000000000000000"
              , out = "847c0d2c375234f365e660955187a3735a0f7613d1609d3a6a4d8c53aeaa5a22"
              }
            , { scalar = "0000000000000000000000000000000000000000000000000000000000000080"
              , u = "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff7f"
              , out = "b32d1362c248d62fe62619cff04dd43db73ffc1b6308ede30b78d87380f1e834"
              }
            , { scalar = "0100000000000000000000000000000000000000000000000000000000000000"
              , u = "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
              , out = "b32d1362c248d62fe62619cff04dd43db73ffc1b6308ede30b78d87380f1e834"
              }
            , { scalar = "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff7f"
              , u = "0a00000000000000000000000000000000000000000000000000000000000000"
              , out = "0896fca46d88fb47ffc66086ffe8c0e819f006e65b294f4adabba9c815a8ba1c"
              }
            , { scalar = "69d288864cf87cc604a7b32654937e91c004fb9ef394913d219c1368775a3a00"
              , u = "1f7bed81a4926eab9d9045618b82930a2a12fa670385f3847ddbcba1f2335242"
              , out = "ef42ba3ae669c5690bb41dbd649e64514cb6ea8b47b42a840a60527f40fc9461"
              }
            , { scalar = "11a2022fec0e853e8ab65b2ca1dc54082139d7aa73858238c2a5b20ea416da92"
              , u = "1cffba0b8b021676127341ddb97837ed5ad76430ece134ecc9d0b3b0175d57be"
              , out = "c65b9eb984353d5126d1ac6c000b86c9a9139a4912edac7bcd2289a352030b7d"
              }
            , { scalar = "1c4a9bc589217c6c05d79de3cdac0089c7bb26a5d6d9b08a28f1fcce15c8156b"
              , u = "ef5c1e0b7948fae84a9f0e4d63961ca2c2afa2c624ec146f44b4ebe49be7e947"
              , out = "9ee9a2066ea0f5027bb3659490e7a77b5063983abb3eeb8459b3a53217ad0f7d"
              }
            , { scalar = "469a5a2ab322a8f005ef7702d12182dbf7ccec54b610cf2e8b02a76febf751c9"
              , u = "5bce67da6d8632951bdeac930d5ddce8ffa560c390b81bc113ffb420324559c1"
              , out = "94de19b8a18f5b045ebc671769cdd22b450a2f568427ff7657006bb6b2127b76"
              }
            , { scalar = "0cf6da5897175fbe58c6a0e7e77e30e5518fbb18ca12a1bfc34b35da3ddf9698"
              , u = "742a60fd36e18baa2c913f766c93e462dc145b3b88139abf6468afb32cd6adb6"
              , out = "cccdb2262c1b5f6b9f228071f834faad6d3598c5e6231d45205f3928c010e205"
              }
            , { scalar = "88166fdee34637807e89d10db1ec5e7c08c9566de2adbb316f0e7ccbf7e7037b"
              , u = "22d22464b4cddd73fa1a056a1aad2625461de9bbf92a8d3c39d0c300e48216ff"
              , out = "39715b243d9105e6294f7212baa26523cc9edd305fac157a1042e66173ee7e71"
              }
            , { scalar = "b82aa558f3d4313c88a710b29d8671429a3387f2a5b0e094deaf06c82eb80276"
              , u = "e3ddf1a9f6f0314f8e12749066d0d6f9997dbd30635983a1ea8bd277edd0feb1"
              , out = "d665aa73ec7e16692115c1d5ec9ddbe6a4a587c1348dcb0392e3db5de8c57c3f"
              }
            , { scalar = "2bf5e038bd3e8be8370cc4f41185f07db4727918a4b93571e846aadfc29f3286"
              , u = "31ab838f3a0691a34c512be3f292aa7d9b98abd31b8b7a8a3b04f1766d908488"
              , out = "22f73b1fff8da07f29f35d17aa5029b8dc538435d330d2aaa7fcc5c4a26f4165"
              }
            , { scalar = "f3d7bd32e6826742934259a8b540aa1c614c417097a4c481115554793ce25145"
              , u = "8af13ac53b834f8126ade08e8fc0c509eb358ad2ed1d410b175128093e544cae"
              , out = "317f5cb6fb89a9db863ccaaa0be52028561dc8f85920ee78fbb0e4e7a72dab6b"
              }
            , { scalar = "c92e1c483f86702f6d3747c4d5dd1226fd542cf600b8c9df4de18735d544c760"
              , u = "af8c31126ace4b2682f681b2133ea0443f1ccebd3f2a6e81175fb96e8cd7a63b"
              , out = "85cbf2f6455a867ef94c2faa1b6c3e83f60b3330d43ef77e215f34ae86758041"
              }
            , { scalar = "3dbec6c4cf5282dea85e58755bd036bedac35e91e30fb5b4fddb126a22b12693"
              , u = "16636cd172a16c99d46f625098c27ed16cd54a1b0368628c870da8052e3e00dc"
              , out = "e292a1e81eccd3de8ce3bd42d035f2246ba448f379a16849983d07bc673d0c66"
              }
            , { scalar = "1a3767c74a456e570038c9183888750b7efa40f0bad80f71f0636eb13f174b7f"
              , u = "4d95f3c90d34adafd4fbc63b3957f5dddb58819d426bebc09631091c5dfca9e9"
              , out = "41955f15161c864a0f433265a8c00f54fcea544c4ed242cd797a6b6d007c6877"
              }
            , { scalar = "7e4049a94b9a8cac2ec68d79c86414c1d987c2123ba539b63ce5ea757b8ec9b0"
              , u = "511538bcd30f98be26219287312780e7ae14d616b04e6b5147bba45d6a022141"
              , out = "27d22cda77d584061ce31c19b1cd26c584b93d51dfb47f530a6f0d99c26f226d"
              }
            , { scalar = "68fcf5e0adf388398c5d01ed08f62d236d0a56ef0a37487f2370456b06aa0935"
              , u = "85a80e94d0d541b120a7de3a8087e042dd2b1238ab096e4f36a4f71c818911f0"
              , out = "e6799732f87ccf070a1ff91e74336c4d9be1910400b52d8d4fc75bfaa6965077"
              }
            , { scalar = "7f64de7cfba971b5da3026a2b1d1b2384768bda2a3d04ae6e519c6181c65f99a"
              , u = "0eaa82b4a7f7d0d47ea7005190d74ac8f70aeda97272c9bc0a23609a582e9895"
              , out = "af976b3dff338a88753a09e0da2d266ecad4809fec25db9d644b35a67fc3231b"
              }
            , { scalar = "4e53d08e739ca29a6e7a41050f56a8df40f274e48c479f7750f3a0db311f4530"
              , u = "2ba7970bcb087e4f2448399a7ca7c9bdf8502599cc4f659ef807286bd1186e76"
              , out = "bbfa545e66ca33d284bc45eb74623c676b903e131401ab37bc8a143d112db959"
              }
            , { scalar = "d55f78c4814500c6f5913713fd5cf3d865afe1c3c0f34302ff193c856318ff28"
              , u = "0ec233ce0116f403ece3a232d73cd7fc63ff76b650ac3d144fb435fa14c1235a"
              , out = "51f1a4ef3ad8be5a39c35e2085ac6f3936cce911426a6e973be4ac1eb12a284a"
              }
            , { scalar = "dd21cde87fc22bcd36fd492d02e91ae0401aafb03fa5b7b9c178b8b5d0d99fb1"
              , u = "d29a0e0327b084082bb261a88e40a4804c3517c9db11ec8943b5dce72842d7e2"
              , out = "7d77b1282a778917fa423517a312e3e2d2ba741ce097061fb7749c2b556d2b74"
              }
            , { scalar = "4bdeb1bc13a1769c13c07e57dc52ac3a6825ec81bfd42d754b07dda07018e7fb"
              , u = "0224e10a648f7f49099dc29f2717f52962b10fc63701478f51d6014b6fa77e4c"
              , out = "7a44c06657640da8235e04a4ce2b9aa5cfa89ec7df678ca18e1eab24fcd48a3f"
              }
            ]
        )


encodingTests : Test
encodingTests =
    Test.describe "encoding"
        [ Test.test "a private key survives a round trip through bytes"
            (\_ ->
                privateKey alicePrivate
                    |> X25519.privateKeyToBytes
                    |> toHex
                    |> Expect.equal alicePrivate
            )
        , Test.test "a public key survives a round trip through bytes"
            (\_ ->
                publicKey alicePublic
                    |> X25519.publicKeyToBytes
                    |> toHex
                    |> Expect.equal alicePublic
            )
        , Test.test "a private key has to be 32 bytes"
            (\_ ->
                X25519.privateKeyFromBytes (fromHex "0011223344")
                    |> Expect.equal Nothing
            )
        , Test.test "a public key has to be 32 bytes"
            (\_ ->
                X25519.publicKeyFromBytes (fromHex (alicePublic ++ "00"))
                    |> Expect.equal Nothing
            )
        ]


{-| The property the whole thing exists for: two people who exchange public keys reach
the same secret. Fuzzed over the private keys, which also exercises clamping, since the
fuzzer has no reason to produce scalars that are already clamped.

Each run is four scalar multiplications, so the count is kept well below the default.

-}
agreementFuzzTest : Test
agreementFuzzTest =
    Test.fuzzWith
        { runs = 20, distribution = Test.noDistribution }
        (Fuzz.pair keyBytesFuzzer keyBytesFuzzer)
        "both sides agree on the same secret"
        (\( aBytes, bBytes ) ->
            let
                a : X25519.PrivateKey
                a =
                    privateKeyFromByteList aBytes

                b : X25519.PrivateKey
                b =
                    privateKeyFromByteList bBytes
            in
            Expect.equal
                (X25519.sharedSecret a (X25519.toPublicKey b))
                (X25519.sharedSecret b (X25519.toPublicKey a))
        )


keyBytesFuzzer : Fuzz.Fuzzer (List Int)
keyBytesFuzzer =
    Fuzz.listOfLength 32 (Fuzz.intRange 0 255)


privateKeyFromByteList : List Int -> X25519.PrivateKey
privateKeyFromByteList bytes =
    case X25519.privateKeyFromBytes (bytesFromByteList bytes) of
        Just key ->
            key

        Nothing ->
            privateKey alicePrivate



-- HELPERS


expectScalarMult : { scalar : String, u : String, out : String } -> Expect.Expectation
expectScalarMult vector =
    expectSharedSecret vector.scalar vector.u vector.out


expectSharedSecret : String -> String -> String -> Expect.Expectation
expectSharedSecret scalar point expected =
    X25519.sharedSecret (privateKey scalar) (publicKey point)
        |> Maybe.map (\secret -> toHex (X25519.sharedSecretToBytes secret))
        |> Expect.equal (Just expected)


privateKey : String -> X25519.PrivateKey
privateKey hex =
    case X25519.privateKeyFromBytes (fromHex hex) of
        Just key ->
            key

        Nothing ->
            Debug.todo ("Not a 32 byte private key: " ++ hex)


publicKey : String -> X25519.PublicKey
publicKey hex =
    case X25519.publicKeyFromBytes (fromHex hex) of
        Just key ->
            key

        Nothing ->
            Debug.todo ("Not a 32 byte public key: " ++ hex)


fromHex : String -> Bytes
fromHex hex =
    String.toList hex
        |> chunkPairs
        |> List.filterMap hexPairToInt
        |> bytesFromByteList


chunkPairs : List Char -> List ( Char, Char )
chunkPairs chars =
    case chars of
        first :: second :: rest ->
            ( first, second ) :: chunkPairs rest

        _ ->
            []


hexPairToInt : ( Char, Char ) -> Maybe Int
hexPairToInt ( high, low ) =
    Maybe.map2 (\a b -> a * 16 + b) (hexDigit high) (hexDigit low)


hexDigit : Char -> Maybe Int
hexDigit char =
    let
        code : Int
        code =
            Char.toCode char
    in
    if code >= 0x30 && code <= 0x39 then
        Just (code - 0x30)

    else if code >= 0x61 && code <= 0x66 then
        Just (code - 0x61 + 10)

    else if code >= 0x41 && code <= 0x46 then
        Just (code - 0x41 + 10)

    else
        Nothing


bytesFromByteList : List Int -> Bytes
bytesFromByteList bytes =
    List.map Bytes.Encode.unsignedInt8 bytes
        |> Bytes.Encode.sequence
        |> Bytes.Encode.encode


toHex : Bytes -> String
toHex bytes =
    Bytes.Decode.decode
        (Bytes.Decode.loop ( Bytes.width bytes, [] ) toHexStep)
        bytes
        |> Maybe.withDefault "could not decode"


toHexStep :
    ( Int, List String )
    -> Bytes.Decode.Decoder (Bytes.Decode.Step ( Int, List String ) String)
toHexStep ( remaining, acc ) =
    if remaining <= 0 then
        Bytes.Decode.succeed (Bytes.Decode.Done (String.concat (List.reverse acc)))

    else
        Bytes.Decode.map
            (\byte -> Bytes.Decode.Loop ( remaining - 1, byteToHex byte :: acc ))
            Bytes.Decode.unsignedInt8


byteToHex : Int -> String
byteToHex byte =
    String.fromList
        [ hexChar (byte // 16), hexChar (modBy 16 byte) ]


hexChar : Int -> Char
hexChar digit =
    if digit < 10 then
        Char.fromCode (0x30 + digit)

    else
        Char.fromCode (0x61 + digit - 10)
