module RPC exposing (checkFileUpload, lamdera_handleEndpoints)

import Coord
import Dict
import Effect.Lamdera
import FileStatus
import Http
import Json.Encode as Json
import Lamdera exposing (SessionId)
import LamderaRPC exposing (Headers, HttpRequest, RPCResult(..))
import SecretId
import SeqDict
import Task
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
                            GotRustServerFileUpload
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


lamdera_handleEndpoints : Json.Value -> HttpRequest -> BackendModel -> ( RPCResult, BackendModel, Cmd BackendMsg )
lamdera_handleEndpoints _ req model =
    case req.endpoint of
        "is-file-upload-allowed" ->
            LamderaRPC.handleEndpointString checkFileUpload req model

        _ ->
            ( ResultString "Endpoint not found", model, Cmd.none )
