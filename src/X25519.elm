module X25519 exposing
    ( PrivateKey
    , PublicKey
    , SharedSecret
    , privateKeyFromBytes
    , privateKeyFromListInt
    , privateKeyToBytes
    , publicKeyFromBytes
    , publicKeyToBytes
    , sharedSecret
    , sharedSecretToBytes
    , toPublicKey
    )

{-| X25519 key agreement (RFC 7748), in pure Elm.

This is here so that the end-to-end encryption handshake is an ordinary function rather
than a `Task` through a port, which means `lamdera/program-test` can run the real key
agreement in end-to-end tests instead of a mock. Bulk message and file encryption is a
different trade and is meant to go through the browser's crypto API, where it can use
native AES.

Two things this deliberately does not do:

  - **Generate keys.** Elm has no cryptographically secure random source, and
    `elm/random` is a seeded PRNG that would be guessable. The 32 bytes behind a
    `PrivateKey` have to come from `crypto.getRandomValues` through a port.

  - **Promise constant time execution.** The field arithmetic is written branch free
    over secret data the way the reference implementations are, but a JavaScript engine
    makes no timing guarantees about anything, so treat that as best effort rather than
    a property you can rely on.

Keys are held as a list of bytes rather than as `Bytes` because Elm compares two `Bytes`
values by their (empty) object properties, so `==` on `Bytes` reports equality no matter
what the contents are. Comparing public keys is something callers will want to do.

-}

import Bitwise
import Bytes exposing (Bytes)
import Bytes.Decode
import Bytes.Encode


{-| 32 bytes of secret, exactly as they came out of the random source. The clamping RFC
7748 requires happens when the key is used, not when it is stored, which is what lets a
key survive a round trip through `privateKeyToBytes`.
-}
type PrivateKey
    = PrivateKey (List Int)


type PublicKey
    = PublicKey (List Int)


{-| The raw output of the key agreement. This is not a message key: run it through a key
derivation function (HKDF) before encrypting anything with it.
-}
type SharedSecret
    = SharedSecret (List Int)


keyLength : Int
keyLength =
    32


privateKeyFromBytes : Bytes -> Maybe PrivateKey
privateKeyFromBytes bytes =
    Maybe.map PrivateKey (toByteList bytes)


privateKeyFromListInt : List Int -> Maybe PrivateKey
privateKeyFromListInt ints =
    if List.length ints >= keyLength then
        List.map (modBy 256) ints |> PrivateKey |> Just

    else
        Nothing


publicKeyFromBytes : Bytes -> Maybe PublicKey
publicKeyFromBytes bytes =
    Maybe.map PublicKey (toByteList bytes)


privateKeyToBytes : PrivateKey -> Bytes
privateKeyToBytes (PrivateKey bytes) =
    fromByteList bytes


publicKeyToBytes : PublicKey -> Bytes
publicKeyToBytes (PublicKey bytes) =
    fromByteList bytes


sharedSecretToBytes : SharedSecret -> Bytes
sharedSecretToBytes (SharedSecret bytes) =
    fromByteList bytes


{-| The public key to hand to the person you want to talk to, found by multiplying the
curve's base point by the private key.
-}
toPublicKey : PrivateKey -> PublicKey
toPublicKey (PrivateKey scalar) =
    PublicKey (scalarMult scalar basePoint)


{-| The secret both sides of a conversation arrive at, from one side's private key and
the other side's public key.

`Nothing` means the public key was one of the small subgroup points that drive every
private key to the same all zero secret. RFC 7748 section 6.1 asks for this check, and
without it someone could hand both people a key that forces a shared secret they already
know.

-}
sharedSecret : PrivateKey -> PublicKey -> Maybe SharedSecret
sharedSecret (PrivateKey scalar) (PublicKey point) =
    let
        secret : List Int
        secret =
            scalarMult scalar point
    in
    if List.all (\byte -> byte == 0) secret then
        Nothing

    else
        Just (SharedSecret secret)


{-| u = 9, the base point of Curve25519.
-}
basePoint : List Int
basePoint =
    9 :: List.repeat (keyLength - 1) 0



-- SCALAR MULTIPLICATION


{-| The four field elements the Montgomery ladder carries: the x and z coordinates of
the two points it keeps in step with each other.
-}
type alias Ladder =
    { x2 : Fe
    , z2 : Fe
    , x3 : Fe
    , z3 : Fe
    }


scalarMult : List Int -> List Int -> List Int
scalarMult scalarBytes pointBytes =
    let
        x1 : Fe
        x1 =
            feUnpack pointBytes

        final : Ladder
        final =
            List.foldl (ladderStep x1)
                { x2 = feOne, z2 = feZero, x3 = x1, z3 = feOne }
                (scalarBits scalarBytes)
    in
    fePack (feMul final.x2 (feInvert final.z2))


{-| The bits of the scalar the ladder walks, most significant first.

RFC 7748 section 5 clamps a scalar before use: the bottom three bits are cleared so it is
a multiple of the cofactor, the top bit is cleared and the next one set so that every
scalar has the same bit length. Bit 255 is always zero afterwards and is dropped, leaving
the 255 bits the ladder runs over.

-}
scalarBits : List Int -> List Int
scalarBits bytes =
    List.indexedMap
        (\index byte ->
            if index == 0 then
                Bitwise.and 248 byte

            else if index == keyLength - 1 then
                Bitwise.or 64 (Bitwise.and 127 byte)

            else
                byte
        )
        bytes
        |> List.reverse
        |> List.concatMap
            (\byte ->
                List.map
                    (\bit -> Bitwise.and 1 (Bitwise.shiftRightBy bit byte))
                    [ 7, 6, 5, 4, 3, 2, 1, 0 ]
            )
        |> List.drop 1


{-| One rung of the Montgomery ladder, following TweetNaCl's `crypto_scalarmult` step for
step so the two can be read side by side. The names carry a number each time they are
rebound because Elm has no assignment; `a`, `b`, `c`, `d`, `e` and `f` are the same
temporaries TweetNaCl uses.

Which of the two points is which gets swapped by the scalar bit on the way in and back
again on the way out, so that the same sequence of multiplications runs whatever the
secret bit is.

-}
ladderStep : Fe -> Int -> Ladder -> Ladder
ladderStep x1 bit state =
    let
        ( a0, b0 ) =
            feSwap bit state.x2 state.x3

        ( c0, d0 ) =
            feSwap bit state.z2 state.z3

        e0 : Fe
        e0 =
            feAdd a0 c0

        a1 : Fe
        a1 =
            feSub a0 c0

        c1 : Fe
        c1 =
            feAdd b0 d0

        b1 : Fe
        b1 =
            feSub b0 d0

        d1 : Fe
        d1 =
            feSquare e0

        f0 : Fe
        f0 =
            feSquare a1

        a2 : Fe
        a2 =
            feMul c1 a1

        c2 : Fe
        c2 =
            feMul b1 e0

        e1 : Fe
        e1 =
            feAdd a2 c2

        a3 : Fe
        a3 =
            feSub a2 c2

        b2 : Fe
        b2 =
            feSquare a3

        c3 : Fe
        c3 =
            feSub d1 f0

        a4 : Fe
        a4 =
            feAdd (feMul c3 fe121665) d1

        c4 : Fe
        c4 =
            feMul c3 a4

        a5 : Fe
        a5 =
            feMul d1 f0

        d2 : Fe
        d2 =
            feMul b2 x1

        b3 : Fe
        b3 =
            feSquare e1

        ( x2, x3 ) =
            feSwap bit a5 b3

        ( z2, z3 ) =
            feSwap bit c4 d2
    in
    { x2 = x2, z2 = z2, x3 = x3, z3 = z3 }



-- FIELD ARITHMETIC MODULO 2^255 - 19


{-| A field element, as 16 limbs of 16 bits, least significant first.

This is TweetNaCl's representation, and it is the reason this can be written in Elm at
all. Multiplying two limbs gives at most 2^32, and an output limb sums sixteen of those
with a reduction factor of 38, which lands under 2^44: comfortably inside the 2^53 that
Elm's `Int` counts exactly, since it is a JavaScript double. The wider limbs other
implementations use need 64 bit or 128 bit accumulators, which Elm has no way to reach.

A record rather than a list or array because the width is fixed at sixteen. That makes it
impossible to build a field element of the wrong size, where `List.map2` would silently
have truncated one, and it costs nothing to read a limb.

Limbs are signed. Addition and subtraction leave them unreduced, and multiplication
carries them back down afterwards.

-}
type alias Fe =
    { l0 : Int
    , l1 : Int
    , l2 : Int
    , l3 : Int
    , l4 : Int
    , l5 : Int
    , l6 : Int
    , l7 : Int
    , l8 : Int
    , l9 : Int
    , l10 : Int
    , l11 : Int
    , l12 : Int
    , l13 : Int
    , l14 : Int
    , l15 : Int
    }


feZero : Fe
feZero =
    { l0 = 0
    , l1 = 0
    , l2 = 0
    , l3 = 0
    , l4 = 0
    , l5 = 0
    , l6 = 0
    , l7 = 0
    , l8 = 0
    , l9 = 0
    , l10 = 0
    , l11 = 0
    , l12 = 0
    , l13 = 0
    , l14 = 0
    , l15 = 0
    }


feOne : Fe
feOne =
    { feZero | l0 = 1 }


{-| (486662 - 2) / 4, the constant the Montgomery ladder multiplies by. 0xDB41 + 2^16.
-}
fe121665 : Fe
fe121665 =
    { feZero | l0 = 0xDB41, l1 = 1 }


{-| Combine two field elements limb by limb. The caller supplies what to do with each
pair, which is what keeps addition, subtraction and the conditional swap down to a line
each.
-}
feMap2 : (Int -> Int -> Int) -> Fe -> Fe -> Fe
feMap2 combine a b =
    { l0 = combine a.l0 b.l0
    , l1 = combine a.l1 b.l1
    , l2 = combine a.l2 b.l2
    , l3 = combine a.l3 b.l3
    , l4 = combine a.l4 b.l4
    , l5 = combine a.l5 b.l5
    , l6 = combine a.l6 b.l6
    , l7 = combine a.l7 b.l7
    , l8 = combine a.l8 b.l8
    , l9 = combine a.l9 b.l9
    , l10 = combine a.l10 b.l10
    , l11 = combine a.l11 b.l11
    , l12 = combine a.l12 b.l12
    , l13 = combine a.l13 b.l13
    , l14 = combine a.l14 b.l14
    , l15 = combine a.l15 b.l15
    }


feAdd : Fe -> Fe -> Fe
feAdd a b =
    feMap2 (+) a b


feSub : Fe -> Fe -> Fe
feSub a b =
    feMap2 (-) a b


feSquare : Fe -> Fe
feSquare a =
    feMul a a


{-| Schoolbook multiplication with the reduction folded in.

The product of two 16 limb numbers is 31 limbs, and a limb at position 16 or above is
worth 2^256 times its place. Since 2^256 is 38 modulo 2^255 - 19, the half that would
overflow is multiplied by 38 and added back into the bottom half instead of ever being
built, which is why every output limb below is sixteen products: those whose positions
add up to it, then those that add up to sixteen more than it.

-}
feMul : Fe -> Fe -> Fe
feMul a b =
    { l0 =
        a.l0 * b.l0 + 38 * (a.l1 * b.l15 + a.l2 * b.l14 + a.l3 * b.l13 + a.l4 * b.l12 + a.l5 * b.l11 + a.l6 * b.l10 + a.l7 * b.l9 + a.l8 * b.l8 + a.l9 * b.l7 + a.l10 * b.l6 + a.l11 * b.l5 + a.l12 * b.l4 + a.l13 * b.l3 + a.l14 * b.l2 + a.l15 * b.l1)
    , l1 =
        a.l0 * b.l1 + a.l1 * b.l0 + 38 * (a.l2 * b.l15 + a.l3 * b.l14 + a.l4 * b.l13 + a.l5 * b.l12 + a.l6 * b.l11 + a.l7 * b.l10 + a.l8 * b.l9 + a.l9 * b.l8 + a.l10 * b.l7 + a.l11 * b.l6 + a.l12 * b.l5 + a.l13 * b.l4 + a.l14 * b.l3 + a.l15 * b.l2)
    , l2 =
        a.l0 * b.l2 + a.l1 * b.l1 + a.l2 * b.l0 + 38 * (a.l3 * b.l15 + a.l4 * b.l14 + a.l5 * b.l13 + a.l6 * b.l12 + a.l7 * b.l11 + a.l8 * b.l10 + a.l9 * b.l9 + a.l10 * b.l8 + a.l11 * b.l7 + a.l12 * b.l6 + a.l13 * b.l5 + a.l14 * b.l4 + a.l15 * b.l3)
    , l3 =
        a.l0 * b.l3 + a.l1 * b.l2 + a.l2 * b.l1 + a.l3 * b.l0 + 38 * (a.l4 * b.l15 + a.l5 * b.l14 + a.l6 * b.l13 + a.l7 * b.l12 + a.l8 * b.l11 + a.l9 * b.l10 + a.l10 * b.l9 + a.l11 * b.l8 + a.l12 * b.l7 + a.l13 * b.l6 + a.l14 * b.l5 + a.l15 * b.l4)
    , l4 =
        a.l0 * b.l4 + a.l1 * b.l3 + a.l2 * b.l2 + a.l3 * b.l1 + a.l4 * b.l0 + 38 * (a.l5 * b.l15 + a.l6 * b.l14 + a.l7 * b.l13 + a.l8 * b.l12 + a.l9 * b.l11 + a.l10 * b.l10 + a.l11 * b.l9 + a.l12 * b.l8 + a.l13 * b.l7 + a.l14 * b.l6 + a.l15 * b.l5)
    , l5 =
        a.l0 * b.l5 + a.l1 * b.l4 + a.l2 * b.l3 + a.l3 * b.l2 + a.l4 * b.l1 + a.l5 * b.l0 + 38 * (a.l6 * b.l15 + a.l7 * b.l14 + a.l8 * b.l13 + a.l9 * b.l12 + a.l10 * b.l11 + a.l11 * b.l10 + a.l12 * b.l9 + a.l13 * b.l8 + a.l14 * b.l7 + a.l15 * b.l6)
    , l6 =
        a.l0 * b.l6 + a.l1 * b.l5 + a.l2 * b.l4 + a.l3 * b.l3 + a.l4 * b.l2 + a.l5 * b.l1 + a.l6 * b.l0 + 38 * (a.l7 * b.l15 + a.l8 * b.l14 + a.l9 * b.l13 + a.l10 * b.l12 + a.l11 * b.l11 + a.l12 * b.l10 + a.l13 * b.l9 + a.l14 * b.l8 + a.l15 * b.l7)
    , l7 =
        a.l0 * b.l7 + a.l1 * b.l6 + a.l2 * b.l5 + a.l3 * b.l4 + a.l4 * b.l3 + a.l5 * b.l2 + a.l6 * b.l1 + a.l7 * b.l0 + 38 * (a.l8 * b.l15 + a.l9 * b.l14 + a.l10 * b.l13 + a.l11 * b.l12 + a.l12 * b.l11 + a.l13 * b.l10 + a.l14 * b.l9 + a.l15 * b.l8)
    , l8 =
        a.l0 * b.l8 + a.l1 * b.l7 + a.l2 * b.l6 + a.l3 * b.l5 + a.l4 * b.l4 + a.l5 * b.l3 + a.l6 * b.l2 + a.l7 * b.l1 + a.l8 * b.l0 + 38 * (a.l9 * b.l15 + a.l10 * b.l14 + a.l11 * b.l13 + a.l12 * b.l12 + a.l13 * b.l11 + a.l14 * b.l10 + a.l15 * b.l9)
    , l9 =
        a.l0 * b.l9 + a.l1 * b.l8 + a.l2 * b.l7 + a.l3 * b.l6 + a.l4 * b.l5 + a.l5 * b.l4 + a.l6 * b.l3 + a.l7 * b.l2 + a.l8 * b.l1 + a.l9 * b.l0 + 38 * (a.l10 * b.l15 + a.l11 * b.l14 + a.l12 * b.l13 + a.l13 * b.l12 + a.l14 * b.l11 + a.l15 * b.l10)
    , l10 =
        a.l0 * b.l10 + a.l1 * b.l9 + a.l2 * b.l8 + a.l3 * b.l7 + a.l4 * b.l6 + a.l5 * b.l5 + a.l6 * b.l4 + a.l7 * b.l3 + a.l8 * b.l2 + a.l9 * b.l1 + a.l10 * b.l0 + 38 * (a.l11 * b.l15 + a.l12 * b.l14 + a.l13 * b.l13 + a.l14 * b.l12 + a.l15 * b.l11)
    , l11 =
        a.l0 * b.l11 + a.l1 * b.l10 + a.l2 * b.l9 + a.l3 * b.l8 + a.l4 * b.l7 + a.l5 * b.l6 + a.l6 * b.l5 + a.l7 * b.l4 + a.l8 * b.l3 + a.l9 * b.l2 + a.l10 * b.l1 + a.l11 * b.l0 + 38 * (a.l12 * b.l15 + a.l13 * b.l14 + a.l14 * b.l13 + a.l15 * b.l12)
    , l12 =
        a.l0 * b.l12 + a.l1 * b.l11 + a.l2 * b.l10 + a.l3 * b.l9 + a.l4 * b.l8 + a.l5 * b.l7 + a.l6 * b.l6 + a.l7 * b.l5 + a.l8 * b.l4 + a.l9 * b.l3 + a.l10 * b.l2 + a.l11 * b.l1 + a.l12 * b.l0 + 38 * (a.l13 * b.l15 + a.l14 * b.l14 + a.l15 * b.l13)
    , l13 =
        a.l0 * b.l13 + a.l1 * b.l12 + a.l2 * b.l11 + a.l3 * b.l10 + a.l4 * b.l9 + a.l5 * b.l8 + a.l6 * b.l7 + a.l7 * b.l6 + a.l8 * b.l5 + a.l9 * b.l4 + a.l10 * b.l3 + a.l11 * b.l2 + a.l12 * b.l1 + a.l13 * b.l0 + 38 * (a.l14 * b.l15 + a.l15 * b.l14)
    , l14 =
        a.l0 * b.l14 + a.l1 * b.l13 + a.l2 * b.l12 + a.l3 * b.l11 + a.l4 * b.l10 + a.l5 * b.l9 + a.l6 * b.l8 + a.l7 * b.l7 + a.l8 * b.l6 + a.l9 * b.l5 + a.l10 * b.l4 + a.l11 * b.l3 + a.l12 * b.l2 + a.l13 * b.l1 + a.l14 * b.l0 + 38 * (a.l15 * b.l15)
    , l15 =
        a.l0 * b.l15 + a.l1 * b.l14 + a.l2 * b.l13 + a.l3 * b.l12 + a.l4 * b.l11 + a.l5 * b.l10 + a.l6 * b.l9 + a.l7 * b.l8 + a.l8 * b.l7 + a.l9 * b.l6 + a.l10 * b.l5 + a.l11 * b.l4 + a.l12 * b.l3 + a.l13 * b.l2 + a.l14 * b.l1 + a.l15 * b.l0
    }
        |> feCarry
        |> feCarry


{-| Move the overflow out of each limb and into the next one, wrapping what falls off the
top back into limb 0 multiplied by 38.
-}
feCarry : Fe -> Fe
feCarry fe =
    let
        ( c0, v0 ) =
            carryLimb fe.l0 1

        ( c1, v1 ) =
            carryLimb fe.l1 c0

        ( c2, v2 ) =
            carryLimb fe.l2 c1

        ( c3, v3 ) =
            carryLimb fe.l3 c2

        ( c4, v4 ) =
            carryLimb fe.l4 c3

        ( c5, v5 ) =
            carryLimb fe.l5 c4

        ( c6, v6 ) =
            carryLimb fe.l6 c5

        ( c7, v7 ) =
            carryLimb fe.l7 c6

        ( c8, v8 ) =
            carryLimb fe.l8 c7

        ( c9, v9 ) =
            carryLimb fe.l9 c8

        ( c10, v10 ) =
            carryLimb fe.l10 c9

        ( c11, v11 ) =
            carryLimb fe.l11 c10

        ( c12, v12 ) =
            carryLimb fe.l12 c11

        ( c13, v13 ) =
            carryLimb fe.l13 c12

        ( c14, v14 ) =
            carryLimb fe.l14 c13

        ( c15, v15 ) =
            carryLimb fe.l15 c14
    in
    { l0 = v0 + 38 * (c15 - 1)
    , l1 = v1
    , l2 = v2
    , l3 = v3
    , l4 = v4
    , l5 = v5
    , l6 = v6
    , l7 = v7
    , l8 = v8
    , l9 = v9
    , l10 = v10
    , l11 = v11
    , l12 = v12
    , l13 = v13
    , l14 = v14
    , l15 = v15
    }


{-| One limb's worth of carrying, giving back the carry into the next limb and what is
left behind.

The 65535 added before dividing biases the value positive so that limbs which went
negative during a subtraction still round the way C's arithmetic shift does; the matching
1 is taken back off the final carry in `feCarry`.

-}
carryLimb : Int -> Int -> ( Int, Int )
carryLimb limb carry =
    let
        value : Int
        value =
            limb + carry + 65535

        nextCarry : Int
        nextCarry =
            floor (toFloat value / 65536)
    in
    ( nextCarry, value - nextCarry * 65536 )


{-| Swap two field elements when `swap` is 1 and leave them alone when it is 0, without
branching on the value, since it is a bit of the private key.

`swap - 1` is 0 or -1, and complementing that gives a mask of all ones or all zeros to
and the difference with.

-}
feSwap : Int -> Fe -> Fe -> ( Fe, Fe )
feSwap swap p q =
    let
        mask : Int
        mask =
            Bitwise.complement (swap - 1)

        difference : Fe
        difference =
            feMap2 (\left right -> Bitwise.and mask (Bitwise.xor left right)) p q
    in
    ( feMap2 Bitwise.xor p difference, feMap2 Bitwise.xor q difference )


{-| The multiplicative inverse, as a raise to the power of 2^255 - 21. Fermat's little
theorem says that is the same as dividing, and unlike the extended Euclidean algorithm it
takes the same path whatever the input is.

The exponent is all ones except at bit positions 2 and 4, which is why those two rounds
square without also multiplying.

-}
feInvert : Fe -> Fe
feInvert fe =
    invertStep fe 253 fe


invertStep : Fe -> Int -> Fe -> Fe
invertStep base bitIndex acc =
    if bitIndex < 0 then
        acc

    else
        let
            squared : Fe
            squared =
                feSquare acc
        in
        invertStep base
            (bitIndex - 1)
            (if bitIndex == 2 || bitIndex == 4 then
                squared

             else
                feMul squared base
            )


{-| Read 32 little endian bytes as a field element. The top bit of the last byte is not
part of the u coordinate, and RFC 7748 says to ignore it rather than reject the key.
-}
feUnpack : List Int -> Fe
feUnpack bytes =
    case pairBytes bytes of
        [ l0, l1, l2, l3, l4, l5, l6, l7, l8, l9, l10, l11, l12, l13, l14, l15 ] ->
            { l0 = l0
            , l1 = l1
            , l2 = l2
            , l3 = l3
            , l4 = l4
            , l5 = l5
            , l6 = l6
            , l7 = l7
            , l8 = l8
            , l9 = l9
            , l10 = l10
            , l11 = l11
            , l12 = l12
            , l13 = l13
            , l14 = l14
            , l15 = Bitwise.and 0x7FFF l15
            }

        _ ->
            feZero


{-| Little endian byte pairs into 16 bit limbs. A key that is not 32 bytes long cannot
reach here, since `privateKeyFromBytes` and `publicKeyFromBytes` reject those.
-}
pairBytes : List Int -> List Int
pairBytes bytes =
    case bytes of
        low :: high :: rest ->
            (low + Bitwise.shiftLeftBy 8 high) :: pairBytes rest

        _ ->
            []


{-| Write a field element as 32 little endian bytes, fully reduced first so that the same
number always encodes the same way.

Three carry passes bring the limbs into range, then subtracting the prime twice with a
constant time select brings a value in [p, 2p) down into [0, p).

-}
fePack : Fe -> List Int
fePack fe =
    let
        reduced : Fe
        reduced =
            fe
                |> feCarry
                |> feCarry
                |> feCarry
                |> subtractPrime
                |> subtractPrime
    in
    List.concatMap
        (\limb -> [ Bitwise.and 0xFF limb, Bitwise.and 0xFF (Bitwise.shiftRightBy 8 limb) ])
        [ reduced.l0
        , reduced.l1
        , reduced.l2
        , reduced.l3
        , reduced.l4
        , reduced.l5
        , reduced.l6
        , reduced.l7
        , reduced.l8
        , reduced.l9
        , reduced.l10
        , reduced.l11
        , reduced.l12
        , reduced.l13
        , reduced.l14
        , reduced.l15
        ]


{-| Subtract 2^255 - 19 limb by limb, then keep the result only if it did not go negative.
The borrow out of the top limb is what says which happened, and the select is constant
time because whether a key's coordinate needed reducing is not worth leaking.
-}
subtractPrime : Fe -> Fe
subtractPrime fe =
    let
        ( b0, m0 ) =
            borrowLimb fe.l0 0xFFED 0

        ( b1, m1 ) =
            borrowLimb fe.l1 0xFFFF b0

        ( b2, m2 ) =
            borrowLimb fe.l2 0xFFFF b1

        ( b3, m3 ) =
            borrowLimb fe.l3 0xFFFF b2

        ( b4, m4 ) =
            borrowLimb fe.l4 0xFFFF b3

        ( b5, m5 ) =
            borrowLimb fe.l5 0xFFFF b4

        ( b6, m6 ) =
            borrowLimb fe.l6 0xFFFF b5

        ( b7, m7 ) =
            borrowLimb fe.l7 0xFFFF b6

        ( b8, m8 ) =
            borrowLimb fe.l8 0xFFFF b7

        ( b9, m9 ) =
            borrowLimb fe.l9 0xFFFF b8

        ( b10, m10 ) =
            borrowLimb fe.l10 0xFFFF b9

        ( b11, m11 ) =
            borrowLimb fe.l11 0xFFFF b10

        ( b12, m12 ) =
            borrowLimb fe.l12 0xFFFF b11

        ( b13, m13 ) =
            borrowLimb fe.l13 0xFFFF b12

        ( b14, m14 ) =
            borrowLimb fe.l14 0xFFFF b13

        ( b15, m15 ) =
            borrowLimb fe.l15 0x7FFF b14

        subtracted : Fe
        subtracted =
            { l0 = Bitwise.and 0xFFFF m0
            , l1 = Bitwise.and 0xFFFF m1
            , l2 = Bitwise.and 0xFFFF m2
            , l3 = Bitwise.and 0xFFFF m3
            , l4 = Bitwise.and 0xFFFF m4
            , l5 = Bitwise.and 0xFFFF m5
            , l6 = Bitwise.and 0xFFFF m6
            , l7 = Bitwise.and 0xFFFF m7
            , l8 = Bitwise.and 0xFFFF m8
            , l9 = Bitwise.and 0xFFFF m9
            , l10 = Bitwise.and 0xFFFF m10
            , l11 = Bitwise.and 0xFFFF m11
            , l12 = Bitwise.and 0xFFFF m12
            , l13 = Bitwise.and 0xFFFF m13
            , l14 = Bitwise.and 0xFFFF m14
            , l15 = m15
            }
    in
    feSwap (1 - b15) fe subtracted |> Tuple.first


{-| One limb's worth of subtracting, giving back the borrow into the next limb and the
difference, which is left unmasked so that the borrow can be read out of it.
-}
borrowLimb : Int -> Int -> Int -> ( Int, Int )
borrowLimb limb subtrahend borrow =
    let
        value : Int
        value =
            limb - subtrahend - borrow
    in
    ( Bitwise.and 1 (Bitwise.shiftRightBy 16 value), value )



-- BYTES


toByteList : Bytes -> Maybe (List Int)
toByteList bytes =
    if Bytes.width bytes == keyLength then
        Bytes.Decode.decode (Bytes.Decode.loop ( keyLength, [] ) byteListStep) bytes

    else
        Nothing


byteListStep :
    ( Int, List Int )
    -> Bytes.Decode.Decoder (Bytes.Decode.Step ( Int, List Int ) (List Int))
byteListStep ( remaining, acc ) =
    if remaining <= 0 then
        Bytes.Decode.succeed (Bytes.Decode.Done (List.reverse acc))

    else
        Bytes.Decode.map
            (\byte -> Bytes.Decode.Loop ( remaining - 1, byte :: acc ))
            Bytes.Decode.unsignedInt8


fromByteList : List Int -> Bytes
fromByteList bytes =
    List.map Bytes.Encode.unsignedInt8 bytes
        |> Bytes.Encode.sequence
        |> Bytes.Encode.encode
