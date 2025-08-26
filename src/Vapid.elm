module Vapid exposing
    ( NotificationError(..)
    , RawKeyPair
    , bytesToHex
    , bytesToHexString
    , derToJose
    , encodeHex
    , urlSafeBase64
    , urlSafeBase64ToBytes
    )

import Array
import Bitwise
import Bytes exposing (Bytes)
import Bytes.Decode
import Bytes.Encode
import Hex
import Http
import VendoredBase64


urlSafeBase64 : Bytes -> String
urlSafeBase64 bytes =
    VendoredBase64.fromBytes bytes |> String.replace "=" "" |> String.replace "+" "-" |> String.replace "/" "_"


urlSafeBase64ToBytes : String -> Maybe Bytes
urlSafeBase64ToBytes text =
    String.replace "-" "+" text |> String.replace "_" "/" |> VendoredBase64.toBytes


type alias RawKeyPair =
    { publicKey : String, privateKey : String }


type NotificationError
    = GetSecureContextFailed
    | ImportKeyFailed
    | SignFailed
    | VapidHttpRequestFailed Http.Error


bytesToString : Bytes -> String
bytesToString bytes =
    Bytes.Decode.decode (Bytes.Decode.string (Bytes.width bytes)) bytes
        |> Maybe.withDefault ""


appendBytes list =
    Bytes.Encode.sequence (List.map Bytes.Encode.bytes list) |> Bytes.Encode.encode


maxOctet =
    0x80


derToJose : Bytes -> Bytes
derToJose signature =
    let
        paramBytes =
            getParamSize 256 |> Debug.log "paramBytes"

        maxEncodedParamLength =
            paramBytes + 1

        inputLength =
            Bytes.width signature

        seqLength =
            (if bytesGetAt 1 signature == Bitwise.or 1 maxOctet then
                bytesGetAt 2 signature

             else
                bytesGetAt 1 signature
            )
                |> Debug.log "seqLength"

        offset0 =
            (if seqLength == Bitwise.or 1 maxOctet then
                4

             else
                3
            )
                |> Debug.log "offset0"

        rLength =
            bytesGetAt offset0 signature |> Debug.log "rLength"

        rOffset =
            offset0 + 1 |> Debug.log "rOffset"

        offset1 =
            offset0 + rLength + 2 |> Debug.log "offset1"

        sLength =
            bytesGetAt offset1 signature |> Debug.log "sLength"

        sOffset =
            offset1 + 1 |> Debug.log "sOffset"

        rPadding =
            paramBytes - rLength |> Debug.log "rPadding"

        sPadding =
            paramBytes - sLength |> Debug.log "sPadding"

        i =
            0

        dst : Bytes
        dst =
            List.range 1 (rPadding + rLength + sPadding + sLength)
                |> List.map (\_ -> Bytes.Encode.unsignedInt8 0)
                |> Bytes.Encode.sequence
                |> Bytes.Encode.encode

        _ =
            Debug.log "signature" (bytesToHex signature)

        _ =
            Debug.log "dst" (bytesToHex dst)

        dst2 : Bytes
        dst2 =
            copy dst i signature (rOffset + max -rPadding 0) (rOffset + rLength)

        _ =
            Debug.log "dst2" (bytesToHex dst2)

        offset =
            paramBytes

        dst3 =
            copy dst2 offset signature (sOffset + max -sPadding 0) (sOffset + sLength)

        --const dst = Buffer(rPadding + rLength + sPadding + sLength);
        --
        --var i = 0;//offset1 + 1 + sLength;
        --for (i = 0; i < rPadding; i + 1) {
        --	dst[offset] = 0;
        --}
        --
        --signature.copy(dst, i, rOffset + Math.max(-rPadding, 0), rOffset + rLength);
        --
        --var offset = paramBytes;
        --
        --for (const o = offset; offset < o + sPadding; offset + 1) {
        --	dst[offset] = 0;
        --}
        --signature.copy(dst, offset, sOffset + Math.max(-sPadding, 0), sOffset + sLength);
        --
        --console.log(dst.toString('hex'));
        --return base64Url(dst.toString('base64'));
    in
    dst3



----seqLength: 69
----paramBytes: 32
----offset0: 3
----rLength: 32
----offset1: 37
----sLength: 33
----sPadding: -1
----sOffset: 38
----rPadding: 0
----rOffset: 4
--304502206591431e2e2c6645d6b75784f4429da8bd943bc6cbc1d1a2c76e74068d3be6c7022100f95b6ba3093f9cb37820873982425e78f3f15fcfa5db279cbe3b44ab07dd63f8
--paramBytes 32
--inputLength 71
--seqLength 69
--offset0 3
--rLength 32
--rOffset 4
--offset1 37
--sLength 33
--sOffset 38
--rPadding 0
--sPadding -1
--00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
--6591431e2e2c6645d6b75784f4429da8bd943bc6cbc1d1a2c76e74068d3be6c70000000000000000000000000000000000000000000000000000000000000000
--6591431e2e2c6645d6b75784f4429da8bd943bc6cbc1d1a2c76e74068d3be6c7f95b6ba3093f9cb37820873982425e78f3f15fcfa5db279cbe3b44ab07dd63f8


copy : Bytes -> Int -> Bytes -> Int -> Int -> Bytes
copy target targetStart source sourceStart sourceEnd =
    let
        sourceSlice =
            bytesSlice sourceStart sourceEnd source

        a =
            targetStart + Bytes.width sourceSlice |> Debug.log "a"
    in
    appendBytes
        [ bytesSlice 0 targetStart target |> logBytes "target start"
        , sourceSlice |> logBytes "sourceSlice"
        , bytesSlice a (Bytes.width target) target |> logBytes "target end"
        ]
        |> logBytes "appended"
        |> bytesSlice 0 (Bytes.width target)


logBytes name bytes =
    let
        _ =
            Debug.log name (bytesToHex bytes)
    in
    bytes


bytesSlice : Int -> Int -> Bytes -> Bytes
bytesSlice start end bytes =
    Bytes.Decode.decode
        (Bytes.Decode.map2
            (\_ slice -> slice)
            (Bytes.Decode.bytes start)
            (Bytes.Decode.bytes (end - start))
        )
        bytes
        |> Maybe.withDefault bytes


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


encodeHex : List Int -> Bytes.Encode.Encoder
encodeHex hexList =
    List.map
        Bytes.Encode.unsignedInt8
        hexList
        |> Bytes.Encode.sequence


bytesToHex : Bytes -> Array.Array Int
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
                            ( Array.push byte state, count - 1 ) |> Bytes.Decode.Loop
                        )
                        Bytes.Decode.unsignedInt8
            )
        )
        bytes2
        |> Maybe.withDefault Array.empty


bytesToHexString : Bytes -> String
bytesToHexString bytes2 =
    bytesToHex bytes2
        |> Array.toList
        |> List.map (\int -> Hex.toString int |> String.padLeft 2 '0')
        |> String.join " "
