module Evergreen.V214.VoiceChat exposing (..)

import Effect.Lamdera
import Effect.Time
import Evergreen.V214.Id
import Evergreen.V214.IdString
import Evergreen.V214.NonemptySet
import SeqDict


type RoomId
    = DmRoomId (Evergreen.V214.Id.Id Evergreen.V214.Id.UserId)


type alias ConnectionId =
    { roomId : RoomId
    , otherSession : ( Evergreen.V214.Id.Id Evergreen.V214.Id.UserId, Effect.Lamdera.ClientId )
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
    , voiceChats : SeqDict.SeqDict RoomId (Evergreen.V214.NonemptySet.NonemptySet ( Evergreen.V214.Id.Id Evergreen.V214.Id.UserId, Effect.Lamdera.ClientId ))
    }


type MediaDeviceId
    = MediaDeviceId Never


type DeviceKind
    = AudioInput
    | VideoInput
    | AudioOutput


type alias MediaDevice =
    { deviceId : Evergreen.V214.IdString.IdString MediaDeviceId
    , groupId : String
    , kind : DeviceKind
    , label : String
    }


type MediaDevicesStatus
    = MediaDevicesNotLoaded
    | HasMediaDevices (List MediaDevice)
    | FailedToGetMediaDevices String


type alias Model =
    { userMediaDevices : MediaDevicesStatus
    , selectedAudioInputDevice : Maybe (Evergreen.V214.IdString.IdString MediaDeviceId)
    , selectedVideoInputDevice : Maybe (Evergreen.V214.IdString.IdString MediaDeviceId)
    }


type alias VideoTrackData =
    { deviceId : String
    , frameRate : Int
    , groupId : String
    , width : Int
    , height : Int
    , resizeMode : String
    }


type alias AudioTrackData =
    { deviceId : String
    , autoGainControl : Bool
    , groupId : String
    , channelCount : Int
    , echoCancellation : Bool
    , noiseSuppression : Bool
    }


type Track
    = VideoTrack VideoTrackData
    | AudioTrack AudioTrackData


type VoiceChatSubscription
    = GotSignal ConnectionId Signal
    | GotMediaStreamTracks (List Track)
    | GotUserMediaDevices (List MediaDevice) (List (Evergreen.V214.IdString.IdString MediaDeviceId))
    | GotUserMediaDevicesError String


type Msg
    = SelectedAudioInputDevice (Evergreen.V214.IdString.IdString MediaDeviceId)
    | SelectedVideoInputDevice (Evergreen.V214.IdString.IdString MediaDeviceId)
