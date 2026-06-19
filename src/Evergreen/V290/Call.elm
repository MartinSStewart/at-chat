module Evergreen.V290.Call exposing (..)

import Bytes
import Effect.Lamdera
import Effect.Time
import Evergreen.V290.Cloudflare
import Evergreen.V290.Id
import Evergreen.V290.IdString
import Evergreen.V290.NonemptyDict
import Evergreen.V290.UserSession
import List.Nonempty
import SeqDict
import SeqSet


type CallId
    = DmRoomId (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId)


type alias RemoteCallData =
    { audioInputEnabled : Bool
    , videoInputEnabled : Bool
    }


type alias ConnectionId =
    { roomId : CallId
    , otherClientId : ( Evergreen.V290.Id.Id Evergreen.V290.Id.UserId, Effect.Lamdera.ClientId )
    }


type alias ExistingPeer =
    { connectionId : ConnectionId
    , sessionId : Evergreen.V290.Cloudflare.RealtimeSessionId
    , trackNames : List Evergreen.V290.Cloudflare.TrackName
    }


type alias PublishResult =
    { answerSdp : Evergreen.V290.Cloudflare.Sdp
    , sessionId : Evergreen.V290.Cloudflare.RealtimeSessionId
    , trackNames : List Evergreen.V290.Cloudflare.TrackName
    }


type LocalChange
    = Local_Join Effect.Time.Posix CallId (Evergreen.V290.UserSession.ToBeFilledInByBackend (Result () (List ExistingPeer)))
    | Local_Leave Effect.Time.Posix
    | Local_PublishTracks Evergreen.V290.Cloudflare.Sdp (List String) (Evergreen.V290.UserSession.ToBeFilledInByBackend PublishResult)
    | Local_PublishConnected
    | Local_PullTracks ConnectionId Evergreen.V290.Cloudflare.RealtimeSessionId (List Evergreen.V290.Cloudflare.TrackName) (Evergreen.V290.UserSession.ToBeFilledInByBackend (Result () Evergreen.V290.Cloudflare.PullTracksResult))
    | Local_RenegotiateAnswer Evergreen.V290.Cloudflare.Sdp (Evergreen.V290.UserSession.ToBeFilledInByBackend (Result () ()))
    | Local_SetRemoteCallData RemoteCallData


type ServerChange
    = Server_Joined Effect.Time.Posix ConnectionId Evergreen.V290.Cloudflare.RealtimeSessionId (List Evergreen.V290.Cloudflare.TrackName)
    | Server_Joining Effect.Time.Posix ConnectionId
    | Server_Left Effect.Time.Posix ConnectionId
    | Server_SetRemoteCallData ConnectionId RemoteCallData


type CallError
    = MissingApiKeys
    | FailedToPullTracks
    | FailedToRenegotiate


type alias Local =
    { currentRoom : Maybe CallId
    , voiceChats : SeqDict.SeqDict CallId (Evergreen.V290.NonemptyDict.NonemptyDict ( Evergreen.V290.Id.Id Evergreen.V290.Id.UserId, Effect.Lamdera.ClientId ) RemoteCallData)
    , error : Maybe CallError
    }


type ChannelSidebarMode
    = ChannelSidebarClosed
    | ChannelSidebarOpened
    | ChannelSidebarClosing
        { offset : Float
        }
    | ChannelSidebarOpening
        { offset : Float
        }
    | ChannelSidebarDragging
        { offset : Float
        , previousOffset : Float
        , time : Effect.Time.Posix
        }


type MediaDeviceId
    = MediaDeviceId Never


type DeviceKind
    = AudioInput
    | VideoInput
    | AudioOutput


type alias MediaDevice =
    { deviceId : Evergreen.V290.IdString.IdString MediaDeviceId
    , groupId : String
    , kind : DeviceKind
    , label : String
    }


type MediaDevicesStatus
    = MediaDevicesNotLoaded
    | HasMediaDevices (List MediaDevice)
    | FailedToGetMediaDevices String


type alias Recording =
    { mimeType : String
    , extraData : String
    , startTime : Effect.Time.Posix
    , endTime : Effect.Time.Posix
    , data : Bytes.Bytes
    }


type LocalOrConnection
    = IsLocal
    | IsConnection ConnectionId


type alias Model =
    { userMediaDevices : MediaDevicesStatus
    , selectedAudioInputDevice : Maybe (Evergreen.V290.IdString.IdString MediaDeviceId)
    , selectedVideoInputDevice : Maybe (Evergreen.V290.IdString.IdString MediaDeviceId)
    , remoteCallData : RemoteCallData
    , isSpeaking : SeqSet.SeqSet ConnectionId
    , recordings : SeqDict.SeqDict CallId (List.Nonempty.Nonempty Recording)
    , localIsSpeaking : Bool
    , startConnectionError : Maybe String
    , volume : SeqDict.SeqDict ( Evergreen.V290.Id.Id Evergreen.V290.Id.UserId, Effect.Lamdera.ClientId ) Float
    , videoHover : Maybe LocalOrConnection
    , thumbnailPosition : ( Float, Float )
    }


type FromJs
    = FromJs_PublishOffer Evergreen.V290.Cloudflare.Sdp (List String)
    | FromJs_PublishConnected
    | FromJs_PullAnswer ConnectionId Evergreen.V290.Cloudflare.Sdp
    | FromJs_RequestPullTracks ConnectionId Evergreen.V290.Cloudflare.RealtimeSessionId (List Evergreen.V290.Cloudflare.TrackName)
    | FromJs_GotUserMediaDevices (List MediaDevice) (List (Evergreen.V290.IdString.IdString MediaDeviceId))
    | FromJs_GotUserMediaDevicesError String
    | FromJs_SpeakingChanged LocalOrConnection Bool
    | FromJs_StartConnectionError String


type Msg
    = SelectedAudioInputDevice (Evergreen.V290.IdString.IdString MediaDeviceId)
    | SelectedVideoInputDevice (Evergreen.V290.IdString.IdString MediaDeviceId)
    | PressedToggleMute
    | PressedTogglePauseVideo
    | PressedJoinCall CallId
    | PressedLeaveCall
    | PressedDownloadRecording CallId
    | PressedCopyError String
    | ChangedVolume ConnectionId Float
    | MouseEnterVideoNode LocalOrConnection
    | MouseExitVideoNode LocalOrConnection
    | DoubleClickedVideoNode
