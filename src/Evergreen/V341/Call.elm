module Evergreen.V341.Call exposing (..)

import Bytes
import Effect.Lamdera
import Effect.Time
import Evergreen.V341.Cloudflare
import Evergreen.V341.Id
import Evergreen.V341.IdString
import Evergreen.V341.NonemptyDict
import Evergreen.V341.UserSession
import List.Nonempty
import SeqDict
import SeqSet


type CallId
    = DmRoomId (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId)


type alias ConnectionId =
    { roomId : CallId
    , otherClientId : ( Evergreen.V341.Id.Id Evergreen.V341.Id.UserId, Effect.Lamdera.ClientId )
    }


type MediaDeviceId
    = MediaDeviceId Never


type DeviceKind
    = AudioInput
    | VideoInput
    | AudioOutput


type alias MediaDevice =
    { deviceId : Evergreen.V341.IdString.IdString MediaDeviceId
    , groupId : String
    , kind : DeviceKind
    , label : String
    }


type LocalOrConnection
    = IsLocal
    | IsConnection ConnectionId


type FromJs
    = FromJs_PublishOffer Evergreen.V341.Cloudflare.Sdp (List String)
    | FromJs_PublishConnected
    | FromJs_PullAnswer ConnectionId Evergreen.V341.Cloudflare.Sdp
    | FromJs_RequestPullTracks ConnectionId Evergreen.V341.Cloudflare.RealtimeSessionId (List Evergreen.V341.Cloudflare.TrackName)
    | FromJs_GotUserMediaDevices (List MediaDevice) (List (Evergreen.V341.IdString.IdString MediaDeviceId))
    | FromJs_GotUserMediaDevicesError String
    | FromJs_SpeakingChanged LocalOrConnection Bool
    | FromJs_StartConnectionError String


type Msg
    = SelectedAudioInputDevice (Evergreen.V341.IdString.IdString MediaDeviceId)
    | SelectedVideoInputDevice (Evergreen.V341.IdString.IdString MediaDeviceId)
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
    , sessionId : Evergreen.V341.Cloudflare.RealtimeSessionId
    , trackNames : List Evergreen.V341.Cloudflare.TrackName
    }


type alias PublishResult =
    { answerSdp : Evergreen.V341.Cloudflare.Sdp
    , sessionId : Evergreen.V341.Cloudflare.RealtimeSessionId
    , trackNames : List Evergreen.V341.Cloudflare.TrackName
    }


type LocalChange
    = Local_Join Effect.Time.Posix CallId (Evergreen.V341.UserSession.ToBeFilledInByBackend (Result () (List ExistingPeer)))
    | Local_Leave Effect.Time.Posix
    | Local_PublishTracks Evergreen.V341.Cloudflare.Sdp (List String) (Evergreen.V341.UserSession.ToBeFilledInByBackend PublishResult)
    | Local_PublishConnected
    | Local_PullTracks ConnectionId Evergreen.V341.Cloudflare.RealtimeSessionId (List Evergreen.V341.Cloudflare.TrackName) (Evergreen.V341.UserSession.ToBeFilledInByBackend (Result () Evergreen.V341.Cloudflare.PullTracksResult))
    | Local_RenegotiateAnswer Evergreen.V341.Cloudflare.Sdp (Evergreen.V341.UserSession.ToBeFilledInByBackend (Result () ()))
    | Local_SetRemoteCallData RemoteCallData


type ServerChange
    = Server_Joined Effect.Time.Posix ConnectionId Evergreen.V341.Cloudflare.RealtimeSessionId (List Evergreen.V341.Cloudflare.TrackName)
    | Server_Joining Effect.Time.Posix ConnectionId
    | Server_Left Effect.Time.Posix ConnectionId
    | Server_SetRemoteCallData ConnectionId RemoteCallData


type CallError
    = MissingApiKeys
    | FailedToPullTracks
    | FailedToRenegotiate


type alias Local =
    { currentRoom : Maybe CallId
    , voiceChats : SeqDict.SeqDict CallId (Evergreen.V341.NonemptyDict.NonemptyDict ( Evergreen.V341.Id.Id Evergreen.V341.Id.UserId, Effect.Lamdera.ClientId ) RemoteCallData)
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
    , selectedAudioInputDevice : Maybe (Evergreen.V341.IdString.IdString MediaDeviceId)
    , selectedVideoInputDevice : Maybe (Evergreen.V341.IdString.IdString MediaDeviceId)
    , remoteCallData : RemoteCallData
    , isSpeaking : SeqSet.SeqSet ConnectionId
    , recordings : SeqDict.SeqDict CallId (List.Nonempty.Nonempty Recording)
    , localIsSpeaking : Bool
    , startConnectionError : Maybe String
    , volume : SeqDict.SeqDict ( Evergreen.V341.Id.Id Evergreen.V341.Id.UserId, Effect.Lamdera.ClientId ) Float
    , videoHover : Maybe LocalOrConnection
    , thumbnailPosition : ( Float, Float )
    }
