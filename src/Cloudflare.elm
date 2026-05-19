module Cloudflare exposing
    ( TurnApiToken
    , TurnConfig
    , TurnTokenId
    , cloudflareTurnTokenId
    , codec
    , generateTurnCredentials
    , turnApiToken
    , turnConfigCodec
    , turnTokenId
    )

import Codec exposing (Codec)
import Duration
import Effect.Http as Http
import Effect.Task exposing (Task)
import Json.Decode as Decode
import Json.Decode.Extra
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


type alias TurnConfig =
    { urls : List String
    , username : Maybe String
    , credential : Maybe String
    }


{-| Cloudflare Realtime TURN App identifier. Created in the Cloudflare
dashboard under Realtime → TURN. Safe to expose; auth uses the API token
set via the admin panel.
-}
cloudflareTurnTokenId : String
cloudflareTurnTokenId =
    "ab40bbb274153a438f78898aaca265a5"


generateTurnCredentials :
    TurnTokenId
    -> TurnApiToken
    -> { ttlSeconds : Int }
    -> Task restriction Http.Error (List TurnConfig)
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
                            case Codec.decodeString codec body of
                                Ok result ->
                                    Ok result

                                Err decodeError ->
                                    Err (Http.BadBody (Decode.errorToString decodeError))
                )
        , timeout = Just (Duration.seconds 30)
        }


codec : Codec (List TurnConfig)
codec =
    Codec.object identity |> Codec.field "iceServers" identity (Codec.list turnConfigCodec) |> Codec.buildObject


turnConfigCodec : Codec TurnConfig
turnConfigCodec =
    Codec.object TurnConfig
        |> Codec.field "urls" .urls (Codec.list Codec.string)
        |> Codec.optionalField "username" .username Codec.string
        |> Codec.optionalField "credential" .credential Codec.string
        |> Codec.buildObject
