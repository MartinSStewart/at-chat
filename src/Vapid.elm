module Vapid exposing (generateRequestDetails)

import Array
import Bitwise
import Bytes exposing (Bytes)
import Bytes.Decode
import Bytes.Encode
import Duration
import Env
import Hex
import Sha256
import Time
import Unsafe
import Url exposing (Url)
import VendoredBase64


publicKey =
    Unsafe.base64Decode Env.vapidPublicKey


privateKey =
    Unsafe.base64Decode Env.vapidPrivateKey


generateRequestDetails : Time.Posix -> Url -> String
generateRequestDetails time subscriptionEndpoint =
    let
        parsedUrl =
            "https://" ++ subscriptionEndpoint.host

        buf : Bytes
        buf =
            Bytes.Encode.sequence
                [ encodeHex [ 0x30, 0x81, 0x35, 0x02, 0x81, 0x01, 0x01, 0x04, 0x81, 0x20 ]
                , Bytes.Encode.bytes privateKey
                , encodeHex [ 0xA0, 0x81, 0x0B, 0x06, 0x81, 0x08 ]
                , encodeHex [ 0x2A, 0x86, 0x48, 0xCE, 0x3D, 0x03, 0x01, 0x07 ]
                ]
                |> Bytes.Encode.encode

        p : String
        p =
            bytesToBase64 buf

        pemKey =
            [ "-----BEGIN EC PRIVATE KEY-----"
            , String.left 64 p
            , String.dropLeft 64 p
            , "-----END EC PRIVATE KEY-----"
            ]
                |> String.join "\n"

        jwtConfig =
            "{\"typ\":\"JWT\",\"alg\":\"ES256\"}"

        encodedHeader =
            stringToBytes jwtConfig |> bytesToBase64

        expirationTime =
            Duration.addTo time (Duration.weeks 4)
                |> Time.posixToMillis
                |> (\a -> a // 1000)
                |> String.fromInt

        subject =
            "https://at-chat.app"

        encodedPayload =
            """{"aud":"""
                ++ parsedUrl
                ++ ""","exp":"""
                ++ expirationTime
                ++ ""","sub":"""
                ++ subject
                ++ """}"""
                |> stringToBytes
                |> bytesToBase64

        securedInput =
            encodedHeader ++ "." ++ encodedPayload

        sig : Bytes
        sig =
            0

        --SubtleCrypto.sign { name = "ECDSA", hash = "SHA-256" } pemKey securedInput
        jwt =
            securedInput ++ "." ++ derToJose sig
    in
    ""


maxOctet =
    0x80


derToJose signature =
    let
        paramBytes =
            getParamSize 256

        maxEncodedParamLength =
            paramBytes + 1

        inputLength =
            Bytes.width signature

        seqLength =
            if bytesGetAt 1 signature == Bitwise.or 1 maxOctet then
                bytesGetAt 2 signature

            else
                bytesGetAt 1 signature

        offset0 =
            if seqLength == Bitwise.or 1 maxOctet then
                4

            else
                3

        offset1 =
            offset0 + rLength + 2

        sLength =
            bytesGetAt offset1 signature

        sOffset =
            offset1 + 1

        rPadding =
            paramBytes - rLength

        sPadding =
            paramBytes - sLength

        i =
            offset1 + 1 + sLength
    in
    0


bytesGetAt : Int -> Bytes -> Int
bytesGetAt index bytes =
    Bytes.Decode.decode
        (Bytes.Decode.map2
            (\_ value -> value)
            (Bytes.Decode.bytes index)
            Bytes.Decode.unsignedInt8
        )
        bytes
        |> Maybe.withDefault 0


getParamSize : Int -> Int
getParamSize keySize =
    (keySize // 8)
        + (if modBy 8 keySize == 0 then
            0

           else
            1
          )


stringToBytes text =
    Bytes.Encode.encode (Bytes.Encode.string text)


bytesToBase64 : Bytes -> String
bytesToBase64 bytes =
    VendoredBase64.fromBytes bytes |> Maybe.withDefault ""


encodeHex hexList =
    List.map
        Bytes.Encode.unsignedInt8
        hexList
        |> Bytes.Encode.sequence


bytesToHex : Bytes -> Maybe (Array.Array String)
bytesToHex bytes2 =
    Bytes.Decode.decode
        (Bytes.Decode.loop
            ( Array.empty, Bytes.width bytes2 )
            (\( state, count ) ->
                if count <= 0 then
                    Bytes.Decode.succeed (Bytes.Decode.Done state)

                else
                    Bytes.Decode.map
                        (\byte ->
                            ( Array.push (Hex.toString byte) state, count - 1 ) |> Bytes.Decode.Loop
                        )
                        Bytes.Decode.unsignedInt8
            )
        )
        bytes2
