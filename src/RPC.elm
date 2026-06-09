module RPC exposing (checkFileUpload, lamdera_handleEndpoints, regeneratePushSubscription)

import Broadcast
import Codec
import Coord
import DiscordSync
import Effect.Lamdera
import FileStatus
import Http
import Json.Decode as Decode
import Json.Encode as Json
import Lamdera exposing (SessionId)
import LamderaRPC exposing (Headers, HttpRequest, RPCResult(..))
import Ports exposing (SubscribeData)
import SeqDict
import SessionIdHash
import Task
import Time
import Toop exposing (T4(..))
import Types exposing (BackendModel, BackendMsg(..))
import UserSession exposing (PushSubscription(..))


checkFileUpload : SessionId -> BackendModel -> Headers -> String -> ( Result Http.Error String, BackendModel, Cmd msg )
checkFileUpload _ model _ text =
    case String.split "," text of
        [ fileHash, fileSize, sessionId, width, height ] ->
            let
                sessionId2 =
                    SessionIdHash.fromString sessionId
            in
            case
                T4
                    (sessionId2 == DiscordSync.backendSessionIdHash model.serverSecret || Broadcast.getSessionFromSessionIdHash sessionId2 model /= Nothing)
                    (String.toInt fileSize)
                    (String.toInt width)
                    (String.toInt height)
            of
                T4 True (Just fileSize2) (Just width2) (Just height2) ->
                    ( Ok "valid"
                    , { model
                        | files =
                            SeqDict.insert
                                (FileStatus.fileHash fileHash)
                                { fileSize = fileSize2
                                , imageSize =
                                    if width2 > 0 then
                                        Just (Coord.xy width2 height2)

                                    else
                                        Nothing
                                }
                                model.files
                      }
                    , Cmd.none
                    )

                _ ->
                    ( Err (Http.BadBody "Invalid request"), model, Cmd.none )

        _ ->
            ( Err (Http.BadBody "Invalid request"), model, Cmd.none )


{-| Called by the service worker when the push service rotates/invalidates a
subscription (the `pushsubscriptionchange` event). The request carries the old
subscription and the freshly created one. We look up the session whose stored
subscription matches the old endpoint and keys — only someone who actually held
that subscription knows them, so this acts as proof of ownership — and replace it
with the new subscription. The model swap and logging happen in a time-stamped
`RegeneratedPushSubscription` backend message so we get an accurate timestamp.
-}
regeneratePushSubscription : SessionId -> BackendModel -> Headers -> Json.Value -> ( Result Http.Error Json.Value, BackendModel, Cmd BackendMsg )
regeneratePushSubscription _ model _ json =
    case Decode.decodeValue decodeRegeneratePushSubscription json of
        Ok data ->
            ( Ok (Json.object [ ( "status", Json.string "ok" ) ])
            , model
            , Task.perform (RegeneratedPushSubscription data) Time.now
            )

        Err error ->
            ( Err (Http.BadBody ("Invalid request: " ++ Decode.errorToString error)), model, Cmd.none )


decodeRegeneratePushSubscription : Decode.Decoder { old : SubscribeData, new : SubscribeData }
decodeRegeneratePushSubscription =
    Decode.map2 (\old new -> { old = old, new = new })
        (Decode.field "old" (Codec.decoder Ports.subscribeDataCodec))
        (Decode.field "new" (Codec.decoder Ports.subscribeDataCodec))


lamdera_handleEndpoints : Json.Value -> HttpRequest -> BackendModel -> ( RPCResult, BackendModel, Cmd BackendMsg )
lamdera_handleEndpoints _ req model =
    case req.endpoint of
        "is-file-upload-allowed" ->
            LamderaRPC.handleEndpointString checkFileUpload req model

        "service-worker-regenerate-push-subscription" ->
            LamderaRPC.handleEndpointJson regeneratePushSubscription req model

        _ ->
            ( ResultString "Endpoint not found", model, Cmd.none )
