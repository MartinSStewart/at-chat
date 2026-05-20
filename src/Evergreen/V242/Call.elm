module Evergreen.V242.Call exposing (..)

import Bytes
import Effect.Lamdera
import Effect.Time
import Evergreen.V242.Cloudflare
import Evergreen.V242.Id
import Evergreen.V242.IdString
import Evergreen.V242.NonemptySet
import Evergreen.V242.UserSession
import List.Nonempty
import SeqDict
import SeqSet


type RoomId
    = DmRoomId (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId)


type alias ConnectionId =
    { roomId : RoomId
    , otherClientId : ( Evergreen.V242.Id.Id Evergreen.V242.Id.UserId, Effect.Lamdera.ClientId )
    }


type alias Sdp =
    { sdp : String
    }


type alias Ice =
    { candidate : String
    , sdpMLineIndex : Int
    , sdpMid : String
    , usernameFragment : String
    }


type Signal
    = OfferSignal Sdp
    | AnswerSignal Sdp
    | IceSignal Ice


type LocalChange
    = Local_Join Effect.Time.Posix RoomId (Evergreen.V242.UserSession.ToBeFilledInByBackend (List Evergreen.V242.Cloudflare.TurnConfig))
    | Local_Leave Effect.Time.Posix
    | Local_Signal ConnectionId Signal


type ServerChange
    = Server_Joined Effect.Time.Posix ConnectionId (List Evergreen.V242.Cloudflare.TurnConfig)
    | Server_Left Effect.Time.Posix ConnectionId
    | Server_SignalReceived ConnectionId Signal


type alias Local =
    { currentRoom : Maybe RoomId
    , voiceChats : SeqDict.SeqDict RoomId (Evergreen.V242.NonemptySet.NonemptySet ( Evergreen.V242.Id.Id Evergreen.V242.Id.UserId, Effect.Lamdera.ClientId ))
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
    { deviceId : Evergreen.V242.IdString.IdString MediaDeviceId
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
    , selectedAudioInputDevice : Maybe (Evergreen.V242.IdString.IdString MediaDeviceId)
    , selectedVideoInputDevice : Maybe (Evergreen.V242.IdString.IdString MediaDeviceId)
    , audioInputEnabled : Bool
    , videoInputEnabled : Bool
    , isSpeaking : SeqSet.SeqSet ConnectionId
    , recordings : SeqDict.SeqDict RoomId (List.Nonempty.Nonempty Recording)
    , localIsSpeaking : Bool
    , startConnectionError : Maybe String
    , volume : SeqDict.SeqDict ( Evergreen.V242.Id.Id Evergreen.V242.Id.UserId, Effect.Lamdera.ClientId ) Float
    , videoHover : Maybe LocalOrConnection
    }


type FromJs
    = FromJs_GotSignal ConnectionId Signal
    | FromJs_GotUserMediaDevices (List MediaDevice) (List (Evergreen.V242.IdString.IdString MediaDeviceId))
    | FromJs_GotUserMediaDevicesError String
    | FromJs_SpeakingChanged LocalOrConnection Bool
    | FromJs_StartConnectionError String


type Msg
    = SelectedAudioInputDevice (Evergreen.V242.IdString.IdString MediaDeviceId)
    | SelectedVideoInputDevice (Evergreen.V242.IdString.IdString MediaDeviceId)
    | PressedToggleMute
    | PressedTogglePauseVideo
    | PressedJoinCall RoomId
    | PressedLeaveCall
    | PressedDownloadRecording RoomId
    | PressedCopyError String
    | ChangedVolume ConnectionId Float
    | MouseEnterVideoNode LocalOrConnection
    | MouseExitVideoNode LocalOrConnection
