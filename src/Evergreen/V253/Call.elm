module Evergreen.V253.Call exposing (..)

import Bytes
import Effect.Lamdera
import Effect.Time
import Evergreen.V253.Cloudflare
import Evergreen.V253.Id
import Evergreen.V253.IdString
import Evergreen.V253.NonemptySet
import Evergreen.V253.UserSession
import List.Nonempty
import SeqDict
import SeqSet


type RoomId
    = DmRoomId (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId)


type alias ConnectionId =
    { roomId : RoomId
    , otherClientId : ( Evergreen.V253.Id.Id Evergreen.V253.Id.UserId, Effect.Lamdera.ClientId )
    }


type alias ExistingPeer =
    { connectionId : ConnectionId
    , sessionId : Evergreen.V253.Cloudflare.RealtimeSessionId
    , trackNames : List Evergreen.V253.Cloudflare.TrackName
    }


type alias PublishResult =
    { answerSdp : Evergreen.V253.Cloudflare.Sdp
    , sessionId : Evergreen.V253.Cloudflare.RealtimeSessionId
    , trackNames : List Evergreen.V253.Cloudflare.TrackName
    }


type LocalChange
    = Local_Join Effect.Time.Posix RoomId (Evergreen.V253.UserSession.ToBeFilledInByBackend (Result () (List ExistingPeer)))
    | Local_Leave Effect.Time.Posix
    | Local_PublishTracks Evergreen.V253.Cloudflare.Sdp (List String) (Evergreen.V253.UserSession.ToBeFilledInByBackend PublishResult)
    | Local_PublishConnected
    | Local_PullTracks ConnectionId Evergreen.V253.Cloudflare.RealtimeSessionId (List Evergreen.V253.Cloudflare.TrackName) (Evergreen.V253.UserSession.ToBeFilledInByBackend (Result () Evergreen.V253.Cloudflare.PullTracksResult))
    | Local_RenegotiateAnswer Evergreen.V253.Cloudflare.Sdp (Evergreen.V253.UserSession.ToBeFilledInByBackend (Result () ()))


type ServerChange
    = Server_Joined Effect.Time.Posix ConnectionId Evergreen.V253.Cloudflare.RealtimeSessionId (List Evergreen.V253.Cloudflare.TrackName)
    | Server_Left Effect.Time.Posix ConnectionId


type CallError
    = MissingApiKeys
    | FailedToPullTracks
    | FailedToRenegotiate


type alias Local =
    { currentRoom : Maybe RoomId
    , voiceChats : SeqDict.SeqDict RoomId (Evergreen.V253.NonemptySet.NonemptySet ( Evergreen.V253.Id.Id Evergreen.V253.Id.UserId, Effect.Lamdera.ClientId ))
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
    { deviceId : Evergreen.V253.IdString.IdString MediaDeviceId
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
    , selectedAudioInputDevice : Maybe (Evergreen.V253.IdString.IdString MediaDeviceId)
    , selectedVideoInputDevice : Maybe (Evergreen.V253.IdString.IdString MediaDeviceId)
    , audioInputEnabled : Bool
    , videoInputEnabled : Bool
    , isSpeaking : SeqSet.SeqSet ConnectionId
    , recordings : SeqDict.SeqDict RoomId (List.Nonempty.Nonempty Recording)
    , localIsSpeaking : Bool
    , startConnectionError : Maybe String
    , volume : SeqDict.SeqDict ( Evergreen.V253.Id.Id Evergreen.V253.Id.UserId, Effect.Lamdera.ClientId ) Float
    , videoHover : Maybe LocalOrConnection
    }


type FromJs
    = FromJs_PublishOffer Evergreen.V253.Cloudflare.Sdp (List String)
    | FromJs_PublishConnected
    | FromJs_PullAnswer ConnectionId Evergreen.V253.Cloudflare.Sdp
    | FromJs_RequestPullTracks ConnectionId Evergreen.V253.Cloudflare.RealtimeSessionId (List Evergreen.V253.Cloudflare.TrackName)
    | FromJs_GotUserMediaDevices (List MediaDevice) (List (Evergreen.V253.IdString.IdString MediaDeviceId))
    | FromJs_GotUserMediaDevicesError String
    | FromJs_SpeakingChanged LocalOrConnection Bool
    | FromJs_StartConnectionError String


type Msg
    = SelectedAudioInputDevice (Evergreen.V253.IdString.IdString MediaDeviceId)
    | SelectedVideoInputDevice (Evergreen.V253.IdString.IdString MediaDeviceId)
    | PressedToggleMute
    | PressedTogglePauseVideo
    | PressedJoinCall RoomId
    | PressedLeaveCall
    | PressedDownloadRecording RoomId
    | PressedCopyError String
    | ChangedVolume ConnectionId Float
    | MouseEnterVideoNode LocalOrConnection
    | MouseExitVideoNode LocalOrConnection
