module Effect.Websocket exposing (Connection, SendError(..), close, createHandle, listen, sendString, CloseEventCode(..))

{-|

@docs Connection, SendError, close, createHandle, listen, sendString, CloseEventCode

-}

import Effect.Internal
import Effect.Subscription exposing (Subscription)
import Effect.Task exposing (Task)


{-| A websocket connection
-}
type Connection
    = Connection String String


{-| Create a websocket handle that you can then open by calling listen or sendString.
-}
createHandle : String -> Task restriction Never Connection
createHandle url =
    Effect.Internal.WebsocketCreateHandle
        url
        (\(Effect.Internal.WebsocketConnection id url2) ->
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
        (Effect.Internal.WebsocketConnection id url)
        data
        (\result ->
            case result of
                Ok () ->
                    Effect.Internal.Succeed ()

                Err Effect.Internal.ConnectionClosed ->
                    Effect.Internal.Fail ConnectionClosed
        )


{-| Close the websocket connection
-}
close : Connection -> Task restriction Never ()
close (Connection id url) =
    Effect.Internal.WebsocketClose (Effect.Internal.WebsocketConnection id url) Effect.Internal.Succeed


{-| Listen for incoming messages through a websocket connection. You'll also get notified if the connection closes.
-}
listen : Connection -> (String -> msg) -> ({ code : CloseEventCode, reason : String } -> msg) -> Subscription restriction msg
listen (Connection id url) onData onClose =
    Effect.Internal.WebsocketListen
        (Effect.Internal.WebsocketConnection id url)
        onData
        (\closeData ->
            onClose
                { code =
                    case closeData.code of
                        Effect.Internal.NormalClosure ->
                            NormalClosure

                        Effect.Internal.GoingAway ->
                            GoingAway

                        Effect.Internal.ProtocolError ->
                            ProtocolError

                        Effect.Internal.UnsupportedData ->
                            UnsupportedData

                        Effect.Internal.NoStatusReceived ->
                            NoStatusReceived

                        Effect.Internal.AbnormalClosure ->
                            AbnormalClosure

                        Effect.Internal.InvalidFramePayloadData ->
                            InvalidFramePayloadData

                        Effect.Internal.PolicyViolation ->
                            PolicyViolation

                        Effect.Internal.MessageTooBig ->
                            MessageTooBig

                        Effect.Internal.MissingExtension ->
                            MissingExtension

                        Effect.Internal.InternalError ->
                            InternalError

                        Effect.Internal.ServiceRestart ->
                            ServiceRestart

                        Effect.Internal.TryAgainLater ->
                            TryAgainLater

                        Effect.Internal.BadGateway ->
                            BadGateway

                        Effect.Internal.TlsHandshake ->
                            TlsHandshake

                        Effect.Internal.UnknownCode code ->
                            UnknownCode code
                , reason = closeData.reason
                }
        )
