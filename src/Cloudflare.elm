module Cloudflare exposing
    ( AccountId(..)
    , AnalyticsApiToken(..)
    , AppId(..)
    , Location(..)
    , PullTracksResult
    , PushTracksResult
    , RealtimeApiToken(..)
    , RealtimeSessionId(..)
    , Sdp(..)
    , SessionStateResponse
    , TrackName(..)
    , TrackObject
    , TrackStatus(..)
    , accountId
    , accountIdToString
    , analyticsApiToken
    , analyticsApiTokenToString
    , appId
    , appIdToString
    , createSession
    , estimatedMonthlyCostUsd
    , monthlyEgressBytes
    , pullRemoteTracks
    , pushLocalTracks
    , realtimeApiToken
    , realtimeApiTokenToString
    , renegotiate
    , sdpCodec
    , sdpFromString
    , sessionIdCodec
    , sessionIdToString
    , sessionInfo
    , trackNameCodec
    )

import Codec exposing (Codec)
import Duration
import Effect.Http as Http
import Effect.Task exposing (Task)
import Json.Decode as Decode
import Json.Encode as Encode


{-| OpaqueVariants
-}
type AppId
    = AppId String


{-| OpaqueVariants
-}
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


{-| The Cloudflare account tag (the account id, not the Realtime app id). Used as `accountTag`
when querying the GraphQL Analytics API.

OpaqueVariants

-}
type AccountId
    = AccountId String


accountId : String -> AccountId
accountId =
    AccountId


accountIdToString : AccountId -> String
accountIdToString (AccountId a) =
    a


{-| A Cloudflare API token with the "Account Analytics" read permission. Kept distinct from
`RealtimeApiToken` (which is scoped to the Realtime app) so the two can't be mixed up.

OpaqueVariants

-}
type AnalyticsApiToken
    = AnalyticsApiToken String


analyticsApiToken : String -> AnalyticsApiToken
analyticsApiToken =
    AnalyticsApiToken


analyticsApiTokenToString : AnalyticsApiToken -> String
analyticsApiTokenToString (AnalyticsApiToken a) =
    a


{-| OpaqueVariants
-}
type RealtimeSessionId
    = SessionId String


sessionIdFromString : String -> RealtimeSessionId
sessionIdFromString =
    SessionId


sessionIdToString : RealtimeSessionId -> String
sessionIdToString (SessionId s) =
    s


sessionIdCodec : Codec RealtimeSessionId
sessionIdCodec =
    Codec.map SessionId sessionIdToString Codec.string


{-| OpaqueVariants
-}
type TrackName
    = TrackName String


trackNameToString : TrackName -> String
trackNameToString (TrackName t) =
    t


trackNameCodec : Codec TrackName
trackNameCodec =
    Codec.map TrackName trackNameToString Codec.string


{-| OpaqueVariants
-}
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


{-| Realtime SFU and TURN services cost $0.05 per GB of data egress, after a combined free
allowance of 1000 GB per month. See <https://developers.cloudflare.com/realtime/sfu/pricing/>.
-}
freeEgressGb : Float
freeEgressGb =
    1000


usdPerGb : Float
usdPerGb =
    0.05


{-| Estimated monthly cost in USD given the total Realtime egress in bytes (SFU + TURN combined).
-}
estimatedMonthlyCostUsd : Int -> Float
estimatedMonthlyCostUsd egressBytes =
    let
        egressGb : Float
        egressGb =
            toFloat egressBytes / 1.0e9
    in
    max 0 (egressGb - freeEgressGb) * usdPerGb


{-| Query the Cloudflare GraphQL Analytics API for the total Realtime egress (SFU + TURN combined)
in bytes between two dates (inclusive). `startDate` and `endDate` must be formatted as `YYYY-MM-DD`.
The token must have the "Account Analytics" read permission.
-}
monthlyEgressBytes :
    { accountId : AccountId, analyticsToken : AnalyticsApiToken, startDate : String, endDate : String }
    -> Task restriction Http.Error Int
monthlyEgressBytes config =
    let
        (AccountId accountTag) =
            config.accountId

        (AnalyticsApiToken token) =
            config.analyticsToken

        query : String
        query =
            "query Usage($accountTag: String!, $start: Date!, $end: Date!) { viewer { accounts(filter: { accountTag: $accountTag }) { sfu: callsUsageAdaptiveGroups(filter: { date_geq: $start, date_leq: $end }, limit: 10000) { sum { egressBytes } } turn: callsTurnUsageAdaptiveGroups(filter: { date_geq: $start, date_leq: $end }, limit: 10000) { sum { egressBytes } } } } }"

        body : Encode.Value
        body =
            Encode.object
                [ ( "query", Encode.string query )
                , ( "variables"
                  , Encode.object
                        [ ( "accountTag", Encode.string accountTag )
                        , ( "start", Encode.string config.startDate )
                        , ( "end", Encode.string config.endDate )
                        ]
                  )
                ]
    in
    Http.task
        { method = "POST"
        , headers = [ Http.header "Authorization" ("Bearer " ++ token) ]
        , url = "https://api.cloudflare.com/client/v4/graphql"
        , body = Http.jsonBody body
        , resolver = stringResolver egressBytesDecoder
        , timeout = Just (Duration.seconds 30)
        }


egressBytesDecoder : Decode.Decoder Int
egressBytesDecoder =
    Decode.at [ "data", "viewer", "accounts" ]
        (Decode.list
            (Decode.map2 (+)
                (datasetEgressBytes "sfu")
                (datasetEgressBytes "turn")
            )
        )
        |> Decode.map List.sum


datasetEgressBytes : String -> Decode.Decoder Int
datasetEgressBytes field =
    Decode.field field
        (Decode.list (Decode.at [ "sum", "egressBytes" ] Decode.int))
        |> Decode.map List.sum


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


createSession : AppId -> RealtimeApiToken -> Task restriction Http.Error RealtimeSessionId
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


type Location
    = Location_Local
    | Location_Remote


locationCodec : Codec Location
locationCodec =
    Codec.enum
        Codec.string
        [ ( "local", Location_Local )
        , ( "remote", Location_Remote )
        ]


pushLocalTracks :
    AppId
    -> RealtimeApiToken
    -> RealtimeSessionId
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
                                [ ( "location", Codec.encoder locationCodec Location_Local )
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
    -> RealtimeSessionId
    -> { remoteSessionId : RealtimeSessionId, trackNames : List TrackName }
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
                                [ ( "location", Codec.encoder locationCodec Location_Remote )
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
    -> RealtimeSessionId
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

                        Http.GoodStatus_ _ _ ->
                            Ok ()
                )
        , timeout = Just (Duration.seconds 30)
        }


sessionInfo : AppId -> RealtimeApiToken -> RealtimeSessionId -> Task restriction Http.Error SessionStateResponse
sessionInfo app token (SessionId sid) =
    Http.task
        { method = "GET"
        , headers = [ bearer token ]
        , url = apiBase app ++ "/sessions/" ++ sid
        , body = Http.emptyBody
        , resolver = stringResolver (Codec.decoder sessionStateResponseCodec)
        , timeout = Just (Duration.seconds 30)
        }


type alias SessionStateResponse =
    { tracks : List TrackObject
    }


sessionStateResponseCodec : Codec SessionStateResponse
sessionStateResponseCodec =
    Codec.object SessionStateResponse
        |> Codec.field "tracks" .tracks (Codec.list trackObjectCodec)
        |> Codec.buildObject


type alias TrackObject =
    { location : Location
    , mid : String
    , trackName : String
    , sessionId : Maybe RealtimeSessionId

    --, bidirectionalMediaStream : Bool
    --, kind : String
    , status : TrackStatus
    }


type TrackStatus
    = TrackActive
    | TrackInactive
    | TrackWaiting


trackStatusCodec : Codec TrackStatus
trackStatusCodec =
    Codec.enum
        Codec.string
        [ ( "active", TrackActive )
        , ( "inactive", TrackInactive )
        , ( "waiting", TrackWaiting )
        ]


realtimeSessionIdCodec : Codec RealtimeSessionId
realtimeSessionIdCodec =
    Codec.map sessionIdFromString sessionIdToString Codec.string


trackObjectCodec : Codec TrackObject
trackObjectCodec =
    Codec.object TrackObject
        |> Codec.field "location" .location locationCodec
        |> Codec.field "mid" .mid Codec.string
        |> Codec.field "trackName" .trackName Codec.string
        |> Codec.optionalField "sessionId" .sessionId realtimeSessionIdCodec
        --|> Codec.field "bidirectionalMediaStream" .bidirectionalMediaStream Codec.bool
        --|> Codec.field "kind" .kind Codec.string
        |> Codec.field "status" .status trackStatusCodec
        |> Codec.buildObject
