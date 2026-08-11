module RPC exposing (checkFileUpload, lamdera_handleEndpoints)

import BackendExtra
import Call
import Codec exposing (Codec)
import Coord
import Dict
import DmChannelId
import Effect.Lamdera exposing (ClientId)
import FileStatus
import Http
import Json.Encode as Json
import Lamdera exposing (SessionId)
import LamderaRPC exposing (Headers, HttpRequest, RPCResult(..))
import SecretId
import SeqDict
import Task
import Time
import Toop exposing (T4(..))
import Types exposing (BackendModel, BackendMsg(..))


{-| Only the Rust server is allowed to ask this. It knows the server secret, and
nobody else does, so an outsider can't reach `_r/is-file-upload-allowed` directly
and register a file that was never uploaded.
-}
fromRustServer : BackendModel -> Headers -> Bool
fromRustServer model headers =
    case Dict.get "x-secret-key" headers of
        Just secretKey ->
            secretKey == SecretId.toString model.serverSecret

        Nothing ->
            False


{-| The session comes from the `sid` cookie that the Rust server read off the
upload request, so it is whoever the browser really is rather than something the
page could pick for itself. An empty session means the upload came from our own
backend, which has no cookie and authenticated with the server secret instead.
-}
checkFileUpload : SessionId -> BackendModel -> Headers -> String -> ( Result Http.Error String, BackendModel, Cmd BackendMsg )
checkFileUpload _ model headers text =
    case String.split "," text of
        [ fileHash, fileSize, sessionId, width, height ] ->
            case
                T4
                    (fromRustServer model headers
                        && (sessionId == "" || SeqDict.member (Effect.Lamdera.sessionIdFromString sessionId) model.sessions)
                    )
                    (String.toInt fileSize)
                    (String.toInt width)
                    (String.toInt height)
            of
                T4 True (Just fileSize2) (Just width2) (Just height2) ->
                    ( Ok "valid"
                    , model
                    , Task.perform
                        (\() ->
                            Rpc_GotFileUpload
                                (FileStatus.fileHash fileHash)
                                fileSize2
                                (if width2 > 0 then
                                    Just (Coord.xy width2 height2)

                                 else
                                    Nothing
                                )
                        )
                        (Task.succeed ())
                    )

                _ ->
                    ( Err (Http.BadBody "Invalid request"), model, Cmd.none )

        _ ->
            ( Err (Http.BadBody "Invalid request"), model, Cmd.none )


{-| The session is whoever the `sid` cookie on the WebSocket handshake says it
is, so unlike the room id and the client id it isn't something the page chose.
-}
type alias CheckCallRequest =
    { sessionId : Effect.Lamdera.SessionId
    , clientId : ClientId
    , roomId : String
    }


checkCallRequestCodec : Codec CheckCallRequest
checkCallRequestCodec =
    Codec.object CheckCallRequest
        |> Codec.field "sessionId" .sessionId (Codec.map Effect.Lamdera.sessionIdFromString Effect.Lamdera.sessionIdToString Codec.string)
        |> Codec.field "clientId" .clientId (Codec.map Effect.Lamdera.clientIdFromString Effect.Lamdera.clientIdToString Codec.string)
        |> Codec.field "roomId" .roomId Codec.string
        |> Codec.buildObject


{-| A room id is a `DmChannelId`, which both people in a DM derive the same way
from the pair of user ids. That makes it guessable, so being in the room is not
something the room id can be trusted to prove. `DmChannelId.otherUserId` is what
proves it: it only answers for a user the room actually belongs to.
-}
checkCall : SessionId -> BackendModel -> Headers -> String -> ( Result Http.Error String, BackendModel, Cmd BackendMsg )
checkCall _ model headers text =
    case ( fromRustServer model headers, Codec.decodeString checkCallRequestCodec text ) of
        ( True, Ok request ) ->
            case
                ( SeqDict.get request.sessionId model.sessions
                , DmChannelId.fromString request.roomId
                )
            of
                ( Just session, Ok dmChannelId ) ->
                    case DmChannelId.otherUserId session.userId dmChannelId of
                        Just otherUserId ->
                            BackendExtra.asDmUserRpc
                                model
                                request.sessionId
                                { otherUserId = otherUserId }
                                (\_ _ _ _ _ ->
                                    ( Ok "valid"
                                    , model
                                    , Task.perform
                                        (\time ->
                                            Rpc_UserJoinedCall
                                                time
                                                request.sessionId
                                                request.clientId
                                                session.userId
                                                (Call.DmRoomId otherUserId)
                                        )
                                        Time.now
                                    )
                                )

                        Nothing ->
                            ( Err (Http.BadBody "Invalid request"), model, Cmd.none )

                _ ->
                    ( Err (Http.BadBody "Invalid request"), model, Cmd.none )

        _ ->
            ( Err (Http.BadBody "Invalid request"), model, Cmd.none )


lamdera_handleEndpoints : Json.Value -> HttpRequest -> BackendModel -> ( RPCResult, BackendModel, Cmd BackendMsg )
lamdera_handleEndpoints _ req model =
    case req.endpoint of
        "is-file-upload-allowed" ->
            LamderaRPC.handleEndpointString checkFileUpload req model

        "is-call-allowed" ->
            LamderaRPC.handleEndpointString checkCall req model

        _ ->
            ( ResultString "Endpoint not found", model, Cmd.none )
