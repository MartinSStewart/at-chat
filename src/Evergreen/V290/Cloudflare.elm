module Evergreen.V290.Cloudflare exposing (..)


type RealtimeApiToken
    = RealtimeApiToken String


type AppId
    = AppId String


type AccountId
    = AccountId String


type AnalyticsApiToken
    = AnalyticsApiToken String


type RealtimeSessionId
    = SessionId String


type TrackName
    = TrackName String


type Sdp
    = Sdp String


type alias PullTracksResult =
    { offerSdp : Sdp
    , requiresImmediateRenegotiation : Bool
    }


type Location
    = Location_Local
    | Location_Remote


type TrackStatus
    = TrackActive
    | TrackInactive
    | TrackWaiting


type alias TrackObject =
    { location : Location
    , mid : String
    , trackName : String
    , sessionId : Maybe RealtimeSessionId
    , status : TrackStatus
    }


type alias SessionStateResponse =
    { tracks : List TrackObject
    }


type alias PushTracksResult =
    { answerSdp : Sdp
    , trackNames : List TrackName
    }
