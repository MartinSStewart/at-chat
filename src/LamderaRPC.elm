module LamderaRPC exposing (..)

import Env
import Http exposing (..)
import Json.Decode as D
import Lamdera exposing (SessionId)
import Lamdera.Json as Json
import Lamdera.Wire3 as Wire3
import Task exposing (Task)
import Types exposing (BackendModel)


type RPC a
    = Response a
    | ResponseJson Json.Value
    | ResponseString String
    | Failure Http.Error


fail string =
    Err <| Http.BadBody string


type RPCResult
    = ResultBytes (List Int)
    | ResultJson Json.Value
    | ResultString String
    | ResultFailure Http.Error


type Body
    = Bytes (List Int)
    | JSON Json.Value
    | Raw String


bodyTypeToString : Body -> String
bodyTypeToString body =
    case body of
        Bytes _ ->
            "Bytes"

        JSON _ ->
            "JSON"

        Raw _ ->
            "Raw"


type alias RPCArgs =
    { sessionId : String
    , endpoint : String
    , requestId : String
    , body : Body
    }


argsDecoder : D.Decoder RPCArgs
argsDecoder =
    D.map4 RPCArgs
        (Json.field "s" Json.decoderString)
        (Json.field "e" Json.decoderString)
        (Json.field "r" Json.decoderString)
        (D.oneOf
            [ Json.field "i" (Json.decoderList Json.decoderInt |> D.map Bytes)
            , Json.field "j" (Json.decoderValue |> D.map JSON)
            , Json.field "st" (Json.decoderString |> D.map Raw)
            ]
        )


process :
    (String -> String -> Cmd msg)
    -> (Json.Value -> Cmd msg)
    -> Json.Value
    -> (RPCArgs -> Types.BackendModel -> ( RPCResult, Types.BackendModel, Cmd msg ))
    -> { a | userModel : BackendModel }
    -> ( { a | userModel : BackendModel }, Cmd msg )
process log rpcOut rpcArgsJson handler model =
    case Json.decodeValue argsDecoder rpcArgsJson of
        Ok rpcArgs ->
            let
                ( result, newUserModel, newCmds ) =
                    handler rpcArgs model.userModel

                resolveRpc value =
                    rpcOut
                        (Json.object
                            [ ( "t", Json.string "qr" )
                            , ( "r", Json.string rpcArgs.requestId )
                            , value
                            ]
                        )
            in
            case result of
                ResultBytes intList ->
                    ( { model | userModel = newUserModel }
                    , Cmd.batch [ resolveRpc ( "i", Json.list Json.int <| intList ), newCmds ]
                    )

                ResultJson value ->
                    ( { model | userModel = newUserModel }
                    , Cmd.batch [ resolveRpc ( "v", value ), newCmds ]
                    )

                ResultString value ->
                    ( { model | userModel = newUserModel }
                    , Cmd.batch [ resolveRpc ( "vs", Json.string value ), newCmds ]
                    )

                ResultFailure err ->
                    ( model
                    , Cmd.batch
                        [ resolveRpc ( "v", Json.object [ ( "error", Json.string <| httpErrorToString err ) ] )
                        , newCmds
                        ]
                    )

        Err err ->
            ( model, log "rpcIn failed to decode rpcArgsJson" "" )


asTask :
    (a -> Wire3.Encoder)
    -> Wire3.Decoder b
    -> a
    -> String
    -> Task Http.Error b
asTask encoder decoder requestValue endpoint =
    Http.task
        { method = "POST"
        , headers = []
        , url = "/_r/" ++ endpoint
        , body = Http.bytesBody "application/octet-stream" (Wire3.bytesEncode <| encoder requestValue)
        , resolver =
            case Env.mode of
                Env.Development ->
                    Http.stringResolver <|
                        customResolver
                            (\metadata text ->
                                Json.decodeString (Json.decoderList Json.decoderInt) text
                                    |> Result.mapError (\_ -> BadBody <| "Failed to decode JSON response to intList from " ++ endpoint)
                                    |> Result.andThen
                                        (Wire3.intListToBytes
                                            >> Wire3.bytesDecode decoder
                                            >> Result.fromMaybe (BadBody <| "Failed to decode intList wire response from " ++ endpoint)
                                        )
                            )

                _ ->
                    Http.bytesResolver <|
                        customResolver
                            (\metadata bytes ->
                                Wire3.bytesDecode decoder bytes
                                    |> Result.fromMaybe (BadBody <| "Failed to decode response from " ++ endpoint)
                            )
        , timeout = Just 15000
        }


asTaskJson :
    Json.Value
    -> String
    -> Task Http.Error Json.Value
asTaskJson json endpoint =
    Http.task
        { method = "POST"
        , headers = []
        , url = "/_r/" ++ endpoint
        , body = Http.jsonBody json
        , resolver =
            Http.stringResolver <|
                customResolver
                    (\metadata text ->
                        Json.decodeString Json.decoderValue text
                            |> Result.mapError (\_ -> BadBody <| "Failed to decode response from " ++ endpoint)
                    )
        , timeout = Just 15000
        }


asTaskString :
    String
    -> String
    -> Task Http.Error String
asTaskString requestBody endpoint =
    Http.task
        { method = "POST"
        , headers = []
        , url = "/_r/" ++ endpoint
        , body = Http.stringBody "text/plain" requestBody
        , resolver = Http.stringResolver <| customResolver (\metadata text -> Ok text)
        , timeout = Just 15000
        }


customResolver : (Http.Metadata -> responseType -> Result Http.Error b) -> Http.Response responseType -> Result Http.Error b
customResolver fn response =
    case response of
        BadUrl_ urlString ->
            Err <| BadUrl urlString

        Timeout_ ->
            Err <| Timeout

        NetworkError_ ->
            Err <| NetworkError

        BadStatus_ metadata body ->
            -- @TODO use metadata better here
            Err <| BadStatus metadata.statusCode

        GoodStatus_ metadata text ->
            fn metadata text


handleEndpoint :
    (SessionId -> BackendModel -> input -> ( Result Http.Error output, BackendModel, Cmd msg ))
    -> Wire3.Decoder input
    -> (output -> Wire3.Encoder)
    -> RPCArgs
    -> BackendModel
    -> ( RPCResult, BackendModel, Cmd msg )
handleEndpoint fn decoder encoder args model =
    case args.body of
        Bytes intList ->
            case Wire3.bytesDecode decoder (Wire3.intListToBytes intList) of
                Just arg ->
                    case fn args.sessionId model arg of
                        ( response, newModel, newCmds ) ->
                            case response of
                                Ok value ->
                                    ( ResultBytes <| Wire3.intListFromBytes <| Wire3.bytesEncode <| encoder value, newModel, newCmds )

                                Err httpErr ->
                                    ( ResultFailure httpErr, newModel, newCmds )

                Nothing ->
                    ( ResultFailure <| BadBody <| "Failed to decode arg for " ++ args.endpoint, model, Cmd.none )

        _ ->
            ( ResultFailure <| BadBody <| "Bytes endpoint '" ++ args.endpoint ++ "' was given body type " ++ bodyTypeToString args.body
            , model
            , Cmd.none
            )


handleEndpointJson :
    (SessionId -> BackendModel -> Json.Value -> ( Result Http.Error Json.Value, BackendModel, Cmd msg ))
    -> RPCArgs
    -> BackendModel
    -> ( RPCResult, BackendModel, Cmd msg )
handleEndpointJson fn args model =
    case args.body of
        JSON json ->
            case fn args.sessionId model json of
                ( response, newModel, newCmds ) ->
                    case response of
                        Ok value ->
                            ( ResultJson value, newModel, newCmds )

                        Err httpErr ->
                            ( ResultFailure httpErr, newModel, newCmds )

        _ ->
            ( ResultFailure <| BadBody <| "JSON endpoint '" ++ args.endpoint ++ "' was given body type " ++ bodyTypeToString args.body
            , model
            , Cmd.none
            )


handleEndpointString :
    (SessionId -> BackendModel -> String -> ( Result Http.Error String, BackendModel, Cmd msg ))
    -> RPCArgs
    -> BackendModel
    -> ( RPCResult, BackendModel, Cmd msg )
handleEndpointString fn args model =
    case args.body of
        Raw string ->
            case fn args.sessionId model string of
                ( response, newModel, newCmds ) ->
                    case response of
                        Ok value ->
                            ( ResultString value, newModel, newCmds )

                        Err httpErr ->
                            ( ResultFailure httpErr, newModel, newCmds )

        _ ->
            ( ResultFailure <| BadBody <| "String endpoint '" ++ args.endpoint ++ "' was given body type " ++ bodyTypeToString args.body
            , model
            , Cmd.none
            )


httpErrorToString : Http.Error -> String
httpErrorToString err =
    case err of
        BadUrl url ->
            "HTTP Malformed url: " ++ url

        Timeout ->
            "HTTP Timeout exceeded"

        NetworkError ->
            "HTTP Network error"

        BadStatus code ->
            "Unexpected HTTP response code: " ++ String.fromInt code

        BadBody text ->
            "Unexpected HTTP response: " ++ text
