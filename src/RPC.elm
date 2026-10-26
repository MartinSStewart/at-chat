module RPC exposing (checkFileUpload, checkRecordingUpload, lamdera_handleEndpoints, notifyAdmins, recordingUploaded, roomIdFromString)

import BackendExtra
import Call
import Codec exposing (Codec)
import Coord
import Dict
import DmChannelId
import Effect.Lamdera exposing (ClientId)
import FileStatus
import Http
import Id exposing (Id, UserId)
import Json.Encode as Json
import Lamdera exposing (SessionId)
import LamderaRPC exposing (Headers, HttpRequest, RPCResult(..))
import LocalState
import Message exposing (CallRecording, CallRecordingFile)
import NonemptyDict
import NonemptySet
import RichText
import SecretId
import SeqDict
import String.Nonempty
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


{-| What the Rust server is told about a file someone is uploading from a call recording.
-}
type alias RecordingFileRequest =
    { recordingId : String
    , name : String
    , startedAt : Time.Posix
    , endedAt : Time.Posix
    , size : Int
    }


recordingFileRequestCodec : Codec RecordingFileRequest
recordingFileRequestCodec =
    Codec.object RecordingFileRequest
        |> Codec.field "recordingId" .recordingId Codec.string
        |> Codec.field "name" .name Codec.string
        |> Codec.field "startedAt" .startedAt (Codec.map Time.millisToPosix Time.posixToMillis Codec.int)
        |> Codec.field "endedAt" .endedAt (Codec.map Time.millisToPosix Time.posixToMillis Codec.int)
        |> Codec.field "size" .size Codec.int
        |> Codec.buildObject


type alias RecordingUploadRequest =
    { sessionId : Effect.Lamdera.SessionId
    , file : RecordingFileRequest
    }


recordingUploadRequestCodec : Codec RecordingUploadRequest
recordingUploadRequestCodec =
    Codec.object RecordingUploadRequest
        |> Codec.field "sessionId" .sessionId (Codec.map Effect.Lamdera.sessionIdFromString Effect.Lamdera.sessionIdToString Codec.string)
        |> Codec.field "file" .file recordingFileRequestCodec
        |> Codec.buildObject


type alias RecordingUploadedRequest =
    { userId : Id UserId
    , file : RecordingFileRequest
    , uploaded : Int
    }


recordingUploadedRequestCodec : Codec RecordingUploadedRequest
recordingUploadedRequestCodec =
    Codec.object RecordingUploadedRequest
        |> Codec.field "userId" .userId (Codec.map Id.fromInt Id.toInt Codec.int)
        |> Codec.field "file" .file recordingFileRequestCodec
        |> Codec.field "uploaded" .uploaded Codec.int
        |> Codec.buildObject


maxRecordingFileSize : Int
maxRecordingFileSize =
    64 * 1024 * 1024 * 1024


maxRecordingFilesPerPerson : Int
maxRecordingFilesPerPerson =
    1000


{-| The Rust server checks this too, since the name ends up in a path on its disk.
-}
isValidRecordingFileName : String -> Bool
isValidRecordingFileName name =
    (String.length name <= 200)
        && List.any (\prefix -> String.startsWith prefix name) [ "VIDEO_", "SCREEN_", "AUDIO_" ]
        && List.any (\suffix -> String.endsWith suffix name) [ ".mp4", ".wav" ]
        && not (String.any (\char -> String.contains (String.fromChar char) "/\\:*?\"<>|" || Char.toCode char < 32) name)


{-| Asked by the Rust server before it stores each piece of someone's call recording.
Gives back who is uploading, which it keeps their files under.
-}
checkRecordingUpload : SessionId -> BackendModel -> Headers -> String -> ( Result Http.Error String, BackendModel, Cmd BackendMsg )
checkRecordingUpload _ model headers text =
    case ( fromRustServer model headers, Codec.decodeString recordingUploadRequestCodec text ) of
        ( True, Ok request ) ->
            case SeqDict.get request.sessionId model.sessions of
                Just session ->
                    case recordingUpload session.userId request.file 0 model of
                        Just _ ->
                            ( Ok ("valid," ++ Id.toString session.userId), model, Cmd.none )

                        Nothing ->
                            ( Err (Http.BadBody "Invalid request"), model, Cmd.none )

                Nothing ->
                    ( Err (Http.BadBody "Invalid request"), model, Cmd.none )

        _ ->
            ( Err (Http.BadBody "Invalid request"), model, Cmd.none )


{-| Told by the Rust server after it has stored a piece of someone's call recording.
-}
recordingUploaded : SessionId -> BackendModel -> Headers -> String -> ( Result Http.Error String, BackendModel, Cmd BackendMsg )
recordingUploaded _ model headers text =
    case ( fromRustServer model headers, Codec.decodeString recordingUploadedRequestCodec text ) of
        ( True, Ok request ) ->
            case recordingUpload request.userId request.file request.uploaded model of
                Just ( sharedCallId, recordingStartedAt, file ) ->
                    ( Ok "ok"
                    , model
                    , Task.perform
                        (\() -> Rpc_RecordingUploadProgress sharedCallId recordingStartedAt file)
                        (Task.succeed ())
                    )

                Nothing ->
                    ( Err (Http.BadBody "Invalid request"), model, Cmd.none )

        _ ->
            ( Err (Http.BadBody "Invalid request"), model, Cmd.none )


recordingUpload :
    Id UserId
    -> RecordingFileRequest
    -> Int
    -> BackendModel
    -> Maybe ( Call.SharedCallId, Time.Posix, CallRecordingFile (Id UserId) )
recordingUpload userId request uploaded model =
    case Call.recordingIdFromString request.recordingId of
        Just ( sharedCallId, recordingStartedAt ) ->
            let
                file : CallRecordingFile (Id UserId)
                file =
                    { recordedBy = userId
                    , name = request.name
                    , startedAt = request.startedAt
                    , endedAt = request.endedAt
                    , size = request.size
                    , uploaded = uploaded
                    }
            in
            case findCallRecording sharedCallId recordingStartedAt model of
                Just recording ->
                    if isRecordingUploadAllowed file recording then
                        Just ( sharedCallId, recordingStartedAt, file )

                    else
                        Nothing

                Nothing ->
                    Nothing

        Nothing ->
            Nothing


isRecordingUploadAllowed : CallRecordingFile (Id UserId) -> CallRecording (Id UserId) -> Bool
isRecordingUploadAllowed file recording =
    let
        ownFiles : List (CallRecordingFile (Id UserId))
        ownFiles =
            List.filter (\otherFile -> otherFile.recordedBy == file.recordedBy) recording.files
    in
    NonemptySet.member file.recordedBy recording.participants
        && isValidRecordingFileName file.name
        && (file.size > 0)
        && (file.size <= maxRecordingFileSize)
        && (file.uploaded >= 0)
        && (file.uploaded <= file.size)
        && (case List.filter (\otherFile -> otherFile.name == file.name) ownFiles of
                [] ->
                    List.length ownFiles < maxRecordingFilesPerPerson

                existing :: _ ->
                    existing.size == file.size
           )


findCallRecording : Call.SharedCallId -> Time.Posix -> BackendModel -> Maybe (CallRecording (Id UserId))
findCallRecording sharedCallId recordingStartedAt model =
    case sharedCallId of
        Call.SharedDmCall dmChannelId ->
            case SeqDict.get dmChannelId model.dmChannels of
                Just dmChannel ->
                    LocalState.callRecordingBackend recordingStartedAt dmChannel

                Nothing ->
                    Nothing

        Call.SharedGuildCall id ->
            case SeqDict.get id.guildId model.guilds of
                Just guild ->
                    case SeqDict.get id.channelId guild.channels of
                        Just channel ->
                            LocalState.callRecordingBackend recordingStartedAt channel

                        Nothing ->
                            Nothing

                Nothing ->
                    Nothing


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


roomIdFromString : Id UserId -> String -> Maybe Call.CallId
roomIdFromString userId text =
    case String.split "-" text of
        [ "guild", guildId, channelId ] ->
            case ( Id.fromString guildId, Id.fromString channelId ) of
                ( Just guildId2, Just channelId2 ) ->
                    Just (Call.GuildRoomId { guildId = guildId2, channelId = channelId2 })

                _ ->
                    Nothing

        _ ->
            case DmChannelId.fromString text of
                Ok dmChannelId ->
                    case DmChannelId.otherUserId userId dmChannelId of
                        Just otherUserId ->
                            Just (Call.DmRoomId { otherUserId = otherUserId })

                        Nothing ->
                            Nothing

                Err _ ->
                    Nothing


{-| A room id is a `DmChannelId`, which both people in a DM derive the same way
from the pair of user ids. That makes it guessable, so being in the room is not
something the room id can be trusted to prove. `DmChannelId.otherUserId` is what
proves it: it only answers for a user the room actually belongs to.
-}
checkCall : SessionId -> BackendModel -> Headers -> String -> ( Result Http.Error String, BackendModel, Cmd BackendMsg )
checkCall _ model headers text =
    case ( fromRustServer model headers, Codec.decodeString checkCallRequestCodec text ) of
        ( True, Ok request ) ->
            case SeqDict.get request.sessionId model.sessions of
                Just session ->
                    let
                        maybeRoomId : Maybe Call.CallId
                        maybeRoomId =
                            roomIdFromString session.userId request.roomId
                    in
                    case maybeRoomId of
                        Just (Call.DmRoomId { otherUserId }) ->
                            BackendExtra.asDmUserRpc
                                model
                                request.sessionId
                                request.clientId
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
                                                (Call.DmRoomId { otherUserId = otherUserId })
                                        )
                                        Time.now
                                    )
                                )

                        Just (Call.GuildRoomId { guildId, channelId }) ->
                            BackendExtra.asGuildMemberRpc
                                model
                                request.sessionId
                                request.clientId
                                guildId
                                (\_ _ _ ->
                                    ( Ok "valid"
                                    , model
                                    , Task.perform
                                        (\time ->
                                            Rpc_UserJoinedCall
                                                time
                                                request.sessionId
                                                request.clientId
                                                session.userId
                                                (Call.GuildRoomId { guildId = guildId, channelId = channelId })
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


{-| Lets a Claude thread working on at-chat tell the admins that it's waiting on them. Those threads
run somewhere that can't open the websocket the app needs, but can make plain HTTPS requests.
-}
notifyAdmins : SessionId -> BackendModel -> Headers -> String -> ( Result Http.Error String, BackendModel, Cmd BackendMsg )
notifyAdmins _ model headers text =
    case
        T4
            (Dict.get "x-notify-token" headers)
            (String.Nonempty.fromString (String.trim text))
            model.notifyAdminsToken
            model.notifyAdminsBotUserId
    of
        T4 (Just token) (Just text2) (Just notifyAdminsToken) (Just botUserId) ->
            if
                (token == notifyAdminsToken)
                    && (String.Nonempty.length text2 <= RichText.maxLength)
                    && NonemptyDict.member botUserId model.users
            then
                ( Ok "sent"
                , model
                , Task.perform (\time -> Rpc_NotifyAdmins time botUserId text2) Time.now
                )

            else
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

        "recording-upload" ->
            LamderaRPC.handleEndpointString checkRecordingUpload req model

        "recording-uploaded" ->
            LamderaRPC.handleEndpointString recordingUploaded req model

        "notify-admins" ->
            LamderaRPC.handleEndpointString notifyAdmins req model

        _ ->
            ( ResultString "Endpoint not found", model, Cmd.none )
