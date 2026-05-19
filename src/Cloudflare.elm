module Cloudflare exposing
    ( CloudflareTurnConfig
    , TurnApiToken
    , TurnTokenId
    , generateTurnCredentials
    , turnApiToken
    , turnTokenId
    )

import Duration
import Effect.Http as Http
import Effect.Task exposing (Task)
import Json.Decode as Decode
import Json.Encode as Encode


type TurnTokenId
    = TurnTokenId String


type TurnApiToken
    = TurnApiToken String


turnTokenId : String -> TurnTokenId
turnTokenId =
    TurnTokenId


turnApiToken : String -> TurnApiToken
turnApiToken =
    TurnApiToken


type alias CloudflareTurnConfig =
    { username : String
    , credential : String
    }


generateTurnCredentials :
    TurnTokenId
    -> TurnApiToken
    -> { ttlSeconds : Int }
    -> Task restriction Http.Error CloudflareTurnConfig
generateTurnCredentials (TurnTokenId tokenId) (TurnApiToken apiToken) { ttlSeconds } =
    Http.task
        { method = "POST"
        , headers = [ Http.header "Authorization" ("Bearer " ++ apiToken) ]
        , url =
            "https://rtc.live.cloudflare.com/v1/turn/keys/"
                ++ tokenId
                ++ "/credentials/generate-ice-servers"
        , body =
            Http.jsonBody (Encode.object [ ( "ttl", Encode.int ttlSeconds ) ])
        , resolver =
            Http.stringResolver
                (\response ->
                    case response of
                        Http.BadUrl_ url ->
                            Err (Http.BadUrl url)

                        Http.Timeout_ ->
                            Err Http.Timeout

                        Http.NetworkError_ ->
                            Err Http.NetworkError

                        Http.BadStatus_ metadata _ ->
                            Err (Http.BadStatus metadata.statusCode)

                        Http.GoodStatus_ _ body ->
                            case Decode.decodeString decodeIceServers body of
                                Ok result ->
                                    Ok result

                                Err decodeError ->
                                    Err (Http.BadBody (Decode.errorToString decodeError))
                )
        , timeout = Just (Duration.seconds 30)
        }


decodeIceServers : Decode.Decoder CloudflareTurnConfig
decodeIceServers =
    Decode.field "iceServers"
        (Decode.map2 CloudflareTurnConfig
            (Decode.field "username" Decode.string)
            (Decode.field "credential" Decode.string)
        )
