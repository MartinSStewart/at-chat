module Evergreen.V293.Call exposing (..)

import Bytes
import Effect.Lamdera
import Effect.Time
import Evergreen.V293.Cloudflare
import Evergreen.V293.Id
import Evergreen.V293.IdString
import Evergreen.V293.NonemptyDict
import Evergreen.V293.UserSession
import List.Nonempty
import SeqDict
import SeqSet


type CallId
    = DmRoomId (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId)


type alias RemoteCallData =
    { audioInputEnabled : Bool
    , videoInputEnabled : Bool
    }


type alias ConnectionId =
    { roomId : CallId
    , otherClientId : ( Evergreen.V293.Id.Id Evergreen.V293.Id.UserId, Effect.Lamdera.ClientId )
    }


type alias ExistingPeer =
    { connectionId : ConnectionId
    , sessionId : Evergreen.V293.Cloudflare.RealtimeSessionId
    , trackNames : List Evergreen.V293.Cloudflare.TrackName
    }


type alias PublishResult =
    { answerSdp : Evergreen.V293.Cloudflare.Sdp
    , sessionId : Evergreen.V293.Cloudflare.RealtimeSessionId
    , trackNames : List Evergreen.V293.Cloudflare.TrackName
    }


type LocalChange
    = Local_Join Effect.Time.Posix CallId (Evergreen.V293.UserSession.ToBeFilledInByBackend (Result () (List ExistingPeer)))
    | Local_Leave Effect.Time.Posix
    | Local_PublishTracks Evergreen.V293.Cloudflare.Sdp (List String) (Evergreen.V293.UserSession.ToBeFilledInByBackend PublishResult)
    | Local_PublishConnected
    | Local_PullTracks ConnectionId Evergreen.V293.Cloudflare.RealtimeSessionId (List Evergreen.V293.Cloudflare.TrackName) (Evergreen.V293.UserSession.ToBeFilledInByBackend (Result () Evergreen.V293.Cloudflare.PullTracksResult))
    | Local_RenegotiateAnswer Evergreen.V293.Cloudflare.Sdp (Evergreen.V293.UserSession.ToBeFilledInByBackend (Result () ()))
    | Local_SetRemoteCallData RemoteCallData


type ServerChange
    = Server_Joined Effect.Time.Posix ConnectionId Evergreen.V293.Cloudflare.RealtimeSessionId (List Evergreen.V293.Cloudflare.TrackName)
    | Server_Joining Effect.Time.Posix ConnectionId
    | Server_Left Effect.Time.Posix ConnectionId
    | Server_SetRemoteCallData ConnectionId RemoteCallData


type CallError
    = MissingApiKeys
    | FailedToPullTracks
    | FailedToRenegotiate


type alias Local =
    { currentRoom : Maybe CallId
    , voiceChats : SeqDict.SeqDict CallId (Evergreen.V293.NonemptyDict.NonemptyDict ( Evergreen.V293.Id.Id Evergreen.V293.Id.UserId, Effect.Lamdera.ClientId ) RemoteCallData)
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
    { deviceId : Evergreen.V293.IdString.IdString MediaDeviceId
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
    , selectedAudioInputDevice : Maybe (Evergreen.V293.IdString.IdString MediaDeviceId)
    , selectedVideoInputDevice : Maybe (Evergreen.V293.IdString.IdString MediaDeviceId)
    , remoteCallData : RemoteCallData
    , isSpeaking : SeqSet.SeqSet ConnectionId
    , recordings : SeqDict.SeqDict CallId (List.Nonempty.Nonempty Recording)
    , localIsSpeaking : Bool
    , startConnectionError : Maybe String
    , volume : SeqDict.SeqDict ( Evergreen.V293.Id.Id Evergreen.V293.Id.UserId, Effect.Lamdera.ClientId ) Float
    , videoHover : Maybe LocalOrConnection
    , thumbnailPosition : ( Float, Float )
    }


type FromJs
    = FromJs_PublishOffer Evergreen.V293.Cloudflare.Sdp (List String)
    | FromJs_PublishConnected
    | FromJs_PullAnswer ConnectionId Evergreen.V293.Cloudflare.Sdp
    | FromJs_RequestPullTracks ConnectionId Evergreen.V293.Cloudflare.RealtimeSessionId (List Evergreen.V293.Cloudflare.TrackName)
    | FromJs_GotUserMediaDevices (List MediaDevice) (List (Evergreen.V293.IdString.IdString MediaDeviceId))
    | FromJs_GotUserMediaDevicesError String
    | FromJs_SpeakingChanged LocalOrConnection Bool
    | FromJs_StartConnectionError String


type Msg
    = SelectedAudioInputDevice (Evergreen.V293.IdString.IdString MediaDeviceId)
    | SelectedVideoInputDevice (Evergreen.V293.IdString.IdString MediaDeviceId)
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
