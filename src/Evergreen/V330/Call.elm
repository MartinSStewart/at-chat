module Evergreen.V330.Call exposing (..)

import Bytes
import Effect.Lamdera
import Effect.Time
import Evergreen.V330.Cloudflare
import Evergreen.V330.Id
import Evergreen.V330.IdString
import Evergreen.V330.NonemptyDict
import Evergreen.V330.UserSession
import List.Nonempty
import SeqDict
import SeqSet


type CallId
    = DmRoomId (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId)


type alias ConnectionId =
    { roomId : CallId
    , otherClientId : ( Evergreen.V330.Id.Id Evergreen.V330.Id.UserId, Effect.Lamdera.ClientId )
    }


type MediaDeviceId
    = MediaDeviceId Never


type DeviceKind
    = AudioInput
    | VideoInput
    | AudioOutput


type alias MediaDevice =
    { deviceId : Evergreen.V330.IdString.IdString MediaDeviceId
    , groupId : String
    , kind : DeviceKind
    , label : String
    }


type LocalOrConnection
    = IsLocal
    | IsConnection ConnectionId


type FromJs
    = FromJs_PublishOffer Evergreen.V330.Cloudflare.Sdp (List String)
    | FromJs_PublishConnected
    | FromJs_PullAnswer ConnectionId Evergreen.V330.Cloudflare.Sdp
    | FromJs_RequestPullTracks ConnectionId Evergreen.V330.Cloudflare.RealtimeSessionId (List Evergreen.V330.Cloudflare.TrackName)
    | FromJs_GotUserMediaDevices (List MediaDevice) (List (Evergreen.V330.IdString.IdString MediaDeviceId))
    | FromJs_GotUserMediaDevicesError String
    | FromJs_SpeakingChanged LocalOrConnection Bool
    | FromJs_StartConnectionError String


type Msg
    = SelectedAudioInputDevice (Evergreen.V330.IdString.IdString MediaDeviceId)
    | SelectedVideoInputDevice (Evergreen.V330.IdString.IdString MediaDeviceId)
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


type alias RemoteCallData =
    { audioInputEnabled : Bool
    , videoInputEnabled : Bool
    }


type alias ExistingPeer =
    { connectionId : ConnectionId
    , sessionId : Evergreen.V330.Cloudflare.RealtimeSessionId
    , trackNames : List Evergreen.V330.Cloudflare.TrackName
    }


type alias PublishResult =
    { answerSdp : Evergreen.V330.Cloudflare.Sdp
    , sessionId : Evergreen.V330.Cloudflare.RealtimeSessionId
    , trackNames : List Evergreen.V330.Cloudflare.TrackName
    }


type LocalChange
    = Local_Join Effect.Time.Posix CallId (Evergreen.V330.UserSession.ToBeFilledInByBackend (Result () (List ExistingPeer)))
    | Local_Leave Effect.Time.Posix
    | Local_PublishTracks Evergreen.V330.Cloudflare.Sdp (List String) (Evergreen.V330.UserSession.ToBeFilledInByBackend PublishResult)
    | Local_PublishConnected
    | Local_PullTracks ConnectionId Evergreen.V330.Cloudflare.RealtimeSessionId (List Evergreen.V330.Cloudflare.TrackName) (Evergreen.V330.UserSession.ToBeFilledInByBackend (Result () Evergreen.V330.Cloudflare.PullTracksResult))
    | Local_RenegotiateAnswer Evergreen.V330.Cloudflare.Sdp (Evergreen.V330.UserSession.ToBeFilledInByBackend (Result () ()))
    | Local_SetRemoteCallData RemoteCallData


type ServerChange
    = Server_Joined Effect.Time.Posix ConnectionId Evergreen.V330.Cloudflare.RealtimeSessionId (List Evergreen.V330.Cloudflare.TrackName)
    | Server_Joining Effect.Time.Posix ConnectionId
    | Server_Left Effect.Time.Posix ConnectionId
    | Server_SetRemoteCallData ConnectionId RemoteCallData


type CallError
    = MissingApiKeys
    | FailedToPullTracks
    | FailedToRenegotiate


type alias Local =
    { currentRoom : Maybe CallId
    , voiceChats : SeqDict.SeqDict CallId (Evergreen.V330.NonemptyDict.NonemptyDict ( Evergreen.V330.Id.Id Evergreen.V330.Id.UserId, Effect.Lamdera.ClientId ) RemoteCallData)
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


type alias Model =
    { userMediaDevices : MediaDevicesStatus
    , selectedAudioInputDevice : Maybe (Evergreen.V330.IdString.IdString MediaDeviceId)
    , selectedVideoInputDevice : Maybe (Evergreen.V330.IdString.IdString MediaDeviceId)
    , remoteCallData : RemoteCallData
    , isSpeaking : SeqSet.SeqSet ConnectionId
    , recordings : SeqDict.SeqDict CallId (List.Nonempty.Nonempty Recording)
    , localIsSpeaking : Bool
    , startConnectionError : Maybe String
    , volume : SeqDict.SeqDict ( Evergreen.V330.Id.Id Evergreen.V330.Id.UserId, Effect.Lamdera.ClientId ) Float
    , videoHover : Maybe LocalOrConnection
    , thumbnailPosition : ( Float, Float )
    }
