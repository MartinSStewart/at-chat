port module WebTransport exposing (Request(..), Response(..), fromJs, toJs)

{-| WebTransport connections to the Rust server. This is a proof of concept for replacing
the WebRTC based voice chat, so for now the only thing it can do is send "Hello world!"
and report what the server echoed back.

The Rust server is on a different port than the file API and presents a self-signed
certificate, so elm-pkg-js/webtransport.js first asks the file API where to connect and
which certificate to trust.

-}

import Codec exposing (Codec)
import Effect.Command as Command exposing (Command, FrontendOnly)
import Effect.Subscription as Subscription exposing (Subscription)
import Json.Decode
import Json.Encode


port webtransport_to_js : Json.Encode.Value -> Cmd msg


port webtransport_from_js : (Json.Decode.Value -> msg) -> Sub msg


toJs : Request -> Command FrontendOnly toMsg msg
toJs request =
    Command.sendToJs "webtransport_to_js" webtransport_to_js (Codec.encodeToValue requestCodec request)


requestCodec : Codec Request
requestCodec =
    Codec.custom
        (\encodeA value ->
            case value of
                SendHelloWorld a ->
                    encodeA a
        )
        |> Codec.variant1 "SendHelloWorld" SendHelloWorld Codec.string
        |> Codec.buildCustom


type Request
    = SendHelloWorld String


type Response
    = Failed String
    | GotServerData String


fromJs : (Response -> msg) -> Subscription FrontendOnly msg
fromJs msg =
    Subscription.fromJs
        "webtransport_from_js"
        webtransport_from_js
        (\json ->
            case Codec.decodeValue responseCodec json of
                Ok response ->
                    msg response

                Err error ->
                    msg (Failed (Json.Decode.errorToString error))
        )


responseCodec : Codec Response
responseCodec =
    Codec.custom
        (\encodeA encodeB value ->
            case value of
                Failed a ->
                    encodeA a

                GotServerData a ->
                    encodeB a
        )
        |> Codec.variant1 "Failed" Failed Codec.string
        |> Codec.variant1 "GotServerData" GotServerData Codec.string
        |> Codec.buildCustom



--Json.Decode.field "tag" Json.Decode.string
--    |> Json.Decode.andThen
--        (\tag ->
--            case tag of
--                "echoed" ->
--                    Json.Decode.map Echoed (Json.Decode.field "message" Json.Decode.string)
--
--                "failed" ->
--                    Json.Decode.map Failed (Json.Decode.field "message" Json.Decode.string)
--
--                _ ->
--                    Json.Decode.fail ("Unknown webtransport_from_js tag " ++ tag)
--        )
