port module WebTransport exposing (Response(..), fromJs, sendHelloWorld)

{-| WebTransport connections to the Rust server. This is a proof of concept for replacing
the WebRTC based voice chat, so for now the only thing it can do is send "Hello world!"
and report what the server echoed back.

The Rust server is on a different port than the file API and presents a self-signed
certificate, so elm-pkg-js/webtransport.js first asks the file API where to connect and
which certificate to trust.

-}

import Effect.Command as Command exposing (Command, FrontendOnly)
import Effect.Subscription as Subscription exposing (Subscription)
import FileStatus
import Json.Decode
import Json.Encode


port webtransport_to_js : Json.Encode.Value -> Cmd msg


port webtransport_from_js : (Json.Decode.Value -> msg) -> Sub msg


sendHelloWorld : Command FrontendOnly toMsg msg
sendHelloWorld =
    Command.sendToJs
        "webtransport_to_js"
        webtransport_to_js
        (Json.Encode.object [ ( "serverUrl", Json.Encode.string FileStatus.domain ) ])


type Response
    = Echoed String
    | Failed String


fromJs : (Response -> msg) -> Subscription FrontendOnly msg
fromJs msg =
    Subscription.fromJs
        "webtransport_from_js"
        webtransport_from_js
        (\json ->
            case Json.Decode.decodeValue decodeResponse json of
                Ok response ->
                    msg response

                Err error ->
                    msg (Failed (Json.Decode.errorToString error))
        )


decodeResponse : Json.Decode.Decoder Response
decodeResponse =
    Json.Decode.field "tag" Json.Decode.string
        |> Json.Decode.andThen
            (\tag ->
                case tag of
                    "echoed" ->
                        Json.Decode.map Echoed (Json.Decode.field "message" Json.Decode.string)

                    "failed" ->
                        Json.Decode.map Failed (Json.Decode.field "message" Json.Decode.string)

                    _ ->
                        Json.Decode.fail ("Unknown webtransport_from_js tag " ++ tag)
            )
