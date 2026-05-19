module Cloudflare exposing
    ( AppId
    , PullTracksResult
    , PushTracksResult
    , RealtimeApiToken
    , Sdp
    , SessionId
    , TrackName
    , appId
    , appIdToString
    , createSession
    , pullRemoteTracks
    , pushLocalTracks
    , realtimeApiToken
    , realtimeApiTokenToString
    , renegotiate
    , sdpCodec
    , sdpFromString
    , sdpToString
    , sessionIdCodec
    , sessionIdToString
    , trackNameCodec
    , trackNameToString
    )

import Codec exposing (Codec)
import Duration
import Effect.Http as Http
import Effect.Task exposing (Task)
import Json.Decode as Decode
import Json.Encode as Encode


type AppId
    = AppId String


type RealtimeApiToken
    = RealtimeApiToken String


appId : String -> AppId
appId =
    AppId


appIdToString : AppId -> String
appIdToString (AppId a) =
    a


realtimeApiToken : String -> RealtimeApiToken
realtimeApiToken =
    RealtimeApiToken


realtimeApiTokenToString : RealtimeApiToken -> String
realtimeApiTokenToString (RealtimeApiToken a) =
    a


type SessionId
    = SessionId String


sessionIdToString : SessionId -> String
sessionIdToString (SessionId s) =
    s


sessionIdCodec : Codec SessionId
sessionIdCodec =
    Codec.map SessionId sessionIdToString Codec.string


type TrackName
    = TrackName String


trackNameToString : TrackName -> String
trackNameToString (TrackName t) =
    t


trackNameCodec : Codec TrackName
trackNameCodec =
    Codec.map TrackName trackNameToString Codec.string


type Sdp
    = Sdp String


sdpFromString : String -> Sdp
sdpFromString =
    Sdp


sdpToString : Sdp -> String
sdpToString (Sdp s) =
    s


sdpCodec : Codec Sdp
sdpCodec =
    Codec.map Sdp sdpToString Codec.string


apiBase : AppId -> String
apiBase (AppId aid) =
    "https://rtc.live.cloudflare.com/v1/apps/" ++ aid


bearer : RealtimeApiToken -> Http.Header
bearer (RealtimeApiToken token) =
    Http.header "Authorization" ("Bearer " ++ token)


stringResolver : Decode.Decoder a -> Http.Resolver restriction Http.Error a
stringResolver decoder =
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
                    case Decode.decodeString decoder body of
                        Ok value ->
                            Ok value

                        Err decodeError ->
                            Err (Http.BadBody (Decode.errorToString decodeError))
        )


unitResolver : Http.Resolver restriction Http.Error ()
unitResolver =
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

                Http.GoodStatus_ _ _ ->
                    Ok ()
        )


createSession : AppId -> RealtimeApiToken -> Task restriction Http.Error SessionId
createSession app token =
    Http.task
        { method = "POST"
        , headers = [ bearer token ]
        , url = apiBase app ++ "/sessions/new"
        , body = Http.emptyBody
        , resolver =
            stringResolver
                (Decode.field "sessionId" Decode.string |> Decode.map SessionId)
        , timeout = Just (Duration.seconds 30)
        }


type alias PushTracksResult =
    { answerSdp : Sdp
    , trackNames : List TrackName
    }


pushLocalTracks :
    AppId
    -> RealtimeApiToken
    -> SessionId
    -> { offerSdp : Sdp, transceiverMids : List String }
    -> Task restriction Http.Error PushTracksResult
pushLocalTracks app token (SessionId sid) { offerSdp, transceiverMids } =
    let
        body =
            Encode.object
                [ ( "sessionDescription"
                  , Encode.object
                        [ ( "sdp", Encode.string (sdpToString offerSdp) )
                        , ( "type", Encode.string "offer" )
                        ]
                  )
                , ( "tracks"
                  , Encode.list
                        (\mid ->
                            Encode.object
                                [ ( "location", Encode.string "local" )
                                , ( "mid", Encode.string mid )
                                , ( "trackName", Encode.string mid )
                                ]
                        )
                        transceiverMids
                  )
                ]
    in
    Http.task
        { method = "POST"
        , headers = [ bearer token ]
        , url = apiBase app ++ "/sessions/" ++ sid ++ "/tracks/new"
        , body = Http.jsonBody body
        , resolver =
            stringResolver
                (Decode.map2 PushTracksResult
                    (Decode.at [ "sessionDescription", "sdp" ] Decode.string |> Decode.map Sdp)
                    (Decode.field "tracks"
                        (Decode.list (Decode.field "trackName" Decode.string |> Decode.map TrackName))
                    )
                )
        , timeout = Just (Duration.seconds 30)
        }


type alias PullTracksResult =
    { offerSdp : Sdp
    , requiresImmediateRenegotiation : Bool
    }


pullRemoteTracks :
    AppId
    -> RealtimeApiToken
    -> SessionId
    -> { remoteSessionId : SessionId, trackNames : List TrackName }
    -> Task restriction Http.Error PullTracksResult
pullRemoteTracks app token (SessionId localSid) { remoteSessionId, trackNames } =
    let
        (SessionId remoteSid) =
            remoteSessionId

        body =
            Encode.object
                [ ( "tracks"
                  , Encode.list
                        (\(TrackName tn) ->
                            Encode.object
                                [ ( "location", Encode.string "remote" )
                                , ( "sessionId", Encode.string remoteSid )
                                , ( "trackName", Encode.string tn )
                                ]
                        )
                        trackNames
                  )
                ]
    in
    Http.task
        { method = "POST"
        , headers = [ bearer token ]
        , url = apiBase app ++ "/sessions/" ++ localSid ++ "/tracks/new"
        , body = Http.jsonBody body
        , resolver =
            stringResolver
                (Decode.map2 PullTracksResult
                    (Decode.at [ "sessionDescription", "sdp" ] Decode.string |> Decode.map Sdp)
                    (Decode.maybe (Decode.field "requiresImmediateRenegotiation" Decode.bool)
                        |> Decode.map (Maybe.withDefault False)
                    )
                )
        , timeout = Just (Duration.seconds 30)
        }


renegotiate :
    AppId
    -> RealtimeApiToken
    -> SessionId
    -> { answerSdp : Sdp }
    -> Task restriction Http.Error ()
renegotiate app token (SessionId sid) { answerSdp } =
    Http.task
        { method = "PUT"
        , headers = [ bearer token ]
        , url = apiBase app ++ "/sessions/" ++ sid ++ "/renegotiate"
        , body =
            Http.jsonBody
                (Encode.object
                    [ ( "sessionDescription"
                      , Encode.object
                            [ ( "sdp", Encode.string (sdpToString answerSdp) )
                            , ( "type", Encode.string "answer" )
                            ]
                      )
                    ]
                )
        , resolver = unitResolver
        , timeout = Just (Duration.seconds 30)
        }
