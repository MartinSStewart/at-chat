module Evergreen.V217.VoiceChat exposing (..)

import Bytes
import Effect.Lamdera
import Effect.Time
import Evergreen.V217.Id
import Evergreen.V217.IdString
import Evergreen.V217.NonemptySet
import List.Nonempty
import SeqDict
import SeqSet


type RoomId
    = DmRoomId (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId)


type alias ConnectionId =
    { roomId : RoomId
    , otherClientId : ( Evergreen.V217.Id.Id Evergreen.V217.Id.UserId, Effect.Lamdera.ClientId )
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
    = Local_Join Effect.Time.Posix RoomId
    | Local_Leave Effect.Time.Posix
    | Local_Signal ConnectionId Signal


type ServerChange
    = Server_Joined Effect.Time.Posix ConnectionId
    | Server_Left Effect.Time.Posix ConnectionId
    | Server_SignalReceived ConnectionId Signal


type alias Local =
    { currentRoom : Maybe RoomId
    , voiceChats : SeqDict.SeqDict RoomId (Evergreen.V217.NonemptySet.NonemptySet ( Evergreen.V217.Id.Id Evergreen.V217.Id.UserId, Effect.Lamdera.ClientId ))
    }


type MediaDeviceId
    = MediaDeviceId Never


type DeviceKind
    = AudioInput
    | VideoInput
    | AudioOutput


type alias MediaDevice =
    { deviceId : Evergreen.V217.IdString.IdString MediaDeviceId
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
    , selectedAudioInputDevice : Maybe (Evergreen.V217.IdString.IdString MediaDeviceId)
    , selectedVideoInputDevice : Maybe (Evergreen.V217.IdString.IdString MediaDeviceId)
    , audioInputEnabled : Bool
    , videoInputEnabled : Bool
    , isSpeaking : SeqSet.SeqSet ConnectionId
    , recordings : SeqDict.SeqDict RoomId (List.Nonempty.Nonempty Recording)
    , localIsSpeaking : Bool
    , startConnectionError : Maybe String
    , volume : SeqDict.SeqDict ( Evergreen.V217.Id.Id Evergreen.V217.Id.UserId, Effect.Lamdera.ClientId ) Float
    , videoHover : Maybe LocalOrConnection
    }


type FromJs
    = FromJs_GotSignal ConnectionId Signal
    | FromJs_GotUserMediaDevices (List MediaDevice) (List (Evergreen.V217.IdString.IdString MediaDeviceId))
    | FromJs_GotUserMediaDevicesError String
    | FromJs_SpeakingChanged LocalOrConnection Bool
    | FromJs_StartConnectionError String


type Msg
    = SelectedAudioInputDevice (Evergreen.V217.IdString.IdString MediaDeviceId)
    | SelectedVideoInputDevice (Evergreen.V217.IdString.IdString MediaDeviceId)
    | PressedToggleMute
    | PressedTogglePauseVideo
    | PressedJoinCall RoomId
    | PressedLeaveCall
    | PressedDownloadRecording RoomId
    | PressedCopyError String
    | ChangedVolume ConnectionId Float
    | MouseEnterVideoNode LocalOrConnection
    | MouseExitVideoNode LocalOrConnection
