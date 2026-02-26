module RPC exposing (checkFileUpload, lamdera_handleEndpoints)

import Broadcast
import Coord
import DiscordSync
import FileStatus
import Http
import Json.Encode as Json
import Lamdera exposing (SessionId)
import LamderaRPC exposing (Headers, HttpRequest, RPCResult(..))
import SeqDict
import SessionIdHash
import Toop exposing (T4(..))
import Types exposing (BackendModel, BackendMsg)


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
                    (sessionId2 == DiscordSync.backendSessionIdHash || Broadcast.getSessionFromSessionIdHash sessionId2 model /= Nothing)
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


lamdera_handleEndpoints : Json.Value -> HttpRequest -> BackendModel -> ( RPCResult, BackendModel, Cmd BackendMsg )
lamdera_handleEndpoints _ req model =
    case req.endpoint of
        "is-file-upload-allowed" ->
            LamderaRPC.handleEndpointString checkFileUpload req model

        _ ->
            ( ResultString "Endpoint not found", model, Cmd.none )
