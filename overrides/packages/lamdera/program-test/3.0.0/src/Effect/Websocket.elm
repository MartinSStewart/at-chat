module Effect.Websocket exposing (Connection, SendError(..), close, createHandle, listen, sendString, CloseEventCode(..))

{-|

@docs Connection, SendError, close, createHandle, listen, sendString, CloseEventCode

-}

import Effect.Internal
import Effect.Subscription exposing (Subscription)
import Effect.Task exposing (Task)
import Websocket


{-| A websocket connection
-}
type Connection
    = Connection String String


{-| Create a websocket handle that you can then open by calling listen or sendString.
-}
createHandle : String -> Task restriction x Connection
createHandle url =
    Effect.Internal.WebsocketCreateHandle
        url
        (\(Websocket.Connection id url2) ->
            Connection id url2 |> Effect.Internal.Succeed
        )


{-| Errors that might happen when sending data.
-}
type SendError
    = ConnectionClosed


{-| Here are some possible reasons that your websocket connection closed.
-}
type CloseEventCode
    = NormalClosure
    | GoingAway
    | ProtocolError
    | UnsupportedData
    | NoStatusReceived
    | AbnormalClosure
    | InvalidFramePayloadData
    | PolicyViolation
    | MessageTooBig
    | MissingExtension
    | InternalError
    | ServiceRestart
    | TryAgainLater
    | BadGateway
    | TlsHandshake
    | UnknownCode Int


{-| Send a string
-}
sendString : Connection -> String -> Task restriction SendError ()
sendString (Connection id url) data =
    Effect.Internal.WebsocketSendString
        (Websocket.Connection id url)
        data
        (\result ->
            case result of
                Ok () ->
                    Effect.Internal.Succeed ()

                Err Websocket.ConnectionClosed ->
                    Effect.Internal.Fail ConnectionClosed
        )


{-| Close the websocket connection
-}
close : Connection -> Task restriction x ()
close (Connection id url) =
    Effect.Internal.WebsocketClose (Websocket.Connection id url) Effect.Internal.Succeed


{-| Listen for incoming messages through a websocket connection. You'll also get notified if the connection closes.
-}
listen : Connection -> (String -> msg) -> ({ code : CloseEventCode, reason : String } -> msg) -> Subscription restriction msg
listen (Connection id url) onData onClose =
    Effect.Internal.WebsocketListen
        (Websocket.Connection id url)
        onData
        (\closeData ->
            onClose
                { code =
                    case closeData.code of
                        Websocket.NormalClosure ->
                            NormalClosure

                        Websocket.GoingAway ->
                            GoingAway

                        Websocket.ProtocolError ->
                            ProtocolError

                        Websocket.UnsupportedData ->
                            UnsupportedData

                        Websocket.NoStatusReceived ->
                            NoStatusReceived

                        Websocket.AbnormalClosure ->
                            AbnormalClosure

                        Websocket.InvalidFramePayloadData ->
                            InvalidFramePayloadData

                        Websocket.PolicyViolation ->
                            PolicyViolation

                        Websocket.MessageTooBig ->
                            MessageTooBig

                        Websocket.MissingExtension ->
                            MissingExtension

                        Websocket.InternalError ->
                            InternalError

                        Websocket.ServiceRestart ->
                            ServiceRestart

                        Websocket.TryAgainLater ->
                            TryAgainLater

                        Websocket.BadGateway ->
                            BadGateway

                        Websocket.TlsHandshake ->
                            TlsHandshake

                        Websocket.UnknownCode code ->
                            UnknownCode code
                , reason = closeData.reason
                }
        )
