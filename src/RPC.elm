module RPC exposing (..)

import Backend
import Effect.Lamdera as Lamdera
import FileStatus
import Http
import Json.Encode as Json
import Lamdera exposing (SessionId)
import LamderaRPC exposing (..)
import SeqSet
import Types exposing (BackendModel, BackendMsg)


checkFileUpload : SessionId -> BackendModel -> Headers -> String -> ( Result Http.Error String, BackendModel, Cmd msg )
checkFileUpload _ model headers text =
    case String.split "," text of
        [ fileHash, sessionId ] ->
            case Backend.getUserFromSessionId (Lamdera.sessionIdFromString sessionId) model of
                Just _ ->
                    ( Ok "valid"
                    , { model | files = SeqSet.insert (FileStatus.fileHash fileHash) model.files }
                    , Cmd.none
                    )

                Nothing ->
                    ( Err (Http.BadBody "Invalid request"), model, Cmd.none )

        _ ->
            ( Err (Http.BadBody "Invalid request"), model, Cmd.none )


lamdera_handleEndpoints : Json.Value -> HttpRequest -> BackendModel -> ( LamderaRPC.RPCResult, BackendModel, Cmd BackendMsg )
lamdera_handleEndpoints reqRaw req model =
    case req.endpoint of
        "is-file-upload-allowed" ->
            LamderaRPC.handleEndpointString checkFileUpload req model

        _ ->
            ( ResultString "Endpoint not found", model, Cmd.none )
