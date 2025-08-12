module RPC exposing (checkFileUpload, lamdera_handleEndpoints)

import Backend
import Effect.Lamdera as Lamdera
import Env
import FileStatus
import Http
import Json.Encode as Json
import Lamdera exposing (SessionId)
import LamderaRPC exposing (Headers, HttpRequest, RPCResult(..))
import SeqDict
import Types exposing (BackendModel, BackendMsg)


checkFileUpload : SessionId -> BackendModel -> Headers -> String -> ( Result Http.Error String, BackendModel, Cmd msg )
checkFileUpload _ model headers text =
    case String.split "," text of
        [ fileHash, fileSize, sessionId ] ->
            case
                ( sessionId == Env.secretKey || Backend.getUserFromSessionId (Lamdera.sessionIdFromString sessionId) model /= Nothing
                , String.toInt fileSize
                )
            of
                ( True, Just fileSize2 ) ->
                    ( Ok "valid"
                    , { model
                        | files =
                            SeqDict.insert (FileStatus.fileHash fileHash) { fileSize = fileSize2 } model.files
                      }
                    , Cmd.none
                    )

                _ ->
                    ( Err (Http.BadBody "Invalid request"), model, Cmd.none )

        _ ->
            ( Err (Http.BadBody "Invalid request"), model, Cmd.none )


lamdera_handleEndpoints : Json.Value -> HttpRequest -> BackendModel -> ( RPCResult, BackendModel, Cmd BackendMsg )
lamdera_handleEndpoints reqRaw req model =
    case req.endpoint of
        "is-file-upload-allowed" ->
            LamderaRPC.handleEndpointString checkFileUpload req model

        _ ->
            ( ResultString "Endpoint not found", model, Cmd.none )
