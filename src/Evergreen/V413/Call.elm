module Evergreen.V413.Call exposing (..)

import Effect.Lamdera
import Effect.Time
import Evergreen.V413.DmChannelId
import Evergreen.V413.Id
import Evergreen.V413.IdString
import Evergreen.V413.NonemptyDict
import SeqDict
import SeqSet


type MediaDeviceId
    = MediaDeviceId Never


type DeviceKind
    = AudioInput
    | VideoInput
    | AudioOutput


type alias MediaDevice =
    { deviceId : Evergreen.V413.IdString.IdString MediaDeviceId
    , groupId : String
    , kind : DeviceKind
    , label : String
    }


type CallId
    = DmRoomId Evergreen.V413.Id.Viewing_DmId
    | GuildRoomId Evergreen.V413.Id.Viewing_ChannelId


type alias ConnectionId =
    { roomId : CallId
    , otherClientId : ( Evergreen.V413.Id.Id Evergreen.V413.Id.UserId, Effect.Lamdera.ClientId )
    }


type LocalOrConnection
    = IsLocal
    | IsConnection ConnectionId


type alias DebugRow =
    { label : String
    , value : String
    }


type alias DebugSection =
    { title : String
    , rows : List DebugRow
    }


type FromJs
    = FromJs_GotUserMediaDevices (List MediaDevice) (List (Evergreen.V413.IdString.IdString MediaDeviceId))
    | FromJs_GotUserMediaDevicesError String
    | FromJs_SpeakingChanged LocalOrConnection Bool
    | FromJs_StartConnectionError String
    | FromJs_DebugData (List DebugSection)
    | FromJs_ScreenShareStarted
    | FromJs_ScreenShareStopped


type Msg
    = SelectedAudioInputDevice (Evergreen.V413.IdString.IdString MediaDeviceId)
    | SelectedVideoInputDevice (Evergreen.V413.IdString.IdString MediaDeviceId)
    | PressedToggleMute
    | PressedTogglePauseVideo
    | PressedToggleScreenShare
    | PressedJoinCall CallId
    | PressedLeaveCall
    | PressedRecord
    | PressedCancelRecording
    | PressedAnswerRecording Bool
    | PressedCopyError String
    | ChangedVolume ConnectionId Float
    | MouseEnterVideoNode LocalOrConnection
    | MouseExitVideoNode LocalOrConnection
    | DoubleClickedVideoNode
    | PressedToggleDebugData
    | PolledDebugData


type alias RemoteCallData =
    { audioInputEnabled : Bool
    , videoInputEnabled : Bool
    , screenShareEnabled : Bool
    }


type RecordingStatus
    = AskingToRecord
        { requestedBy : Evergreen.V413.Id.Id Evergreen.V413.Id.UserId
        , requestedAt : Effect.Time.Posix
        , allowedBy : SeqSet.SeqSet (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId)
        }
    | RecordingDeclined
        { requestedBy : Evergreen.V413.Id.Id Evergreen.V413.Id.UserId
        , declinedBy : Maybe (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId)
        , declinedAt : Effect.Time.Posix
        }
    | RecordingSince Effect.Time.Posix


type LocalChange
    = Local_Leave Effect.Time.Posix
    | Local_SetRemoteCallData RemoteCallData
    | Local_RequestRecording
    | Local_AnswerRecording Bool
    | Local_CancelRecording


type ServerChange
    = Server_YouJoined Effect.Time.Posix CallId
    | Server_OtherJoined Effect.Time.Posix ConnectionId
    | Server_Left Effect.Time.Posix ConnectionId
    | Server_SetRemoteCallData ConnectionId RemoteCallData
    | Server_RecordingChanged CallId (Maybe RecordingStatus)


type alias Local =
    { currentRoom : Maybe CallId
    , voiceChats : SeqDict.SeqDict CallId (Evergreen.V413.NonemptyDict.NonemptyDict ( Evergreen.V413.Id.Id Evergreen.V413.Id.UserId, Effect.Lamdera.ClientId ) RemoteCallData)
    , recordings : SeqDict.SeqDict CallId RecordingStatus
    }


type MediaDevicesStatus
    = MediaDevicesNotLoaded
    | HasMediaDevices (List MediaDevice)
    | FailedToGetMediaDevices String


type alias Model =
    { userMediaDevices : MediaDevicesStatus
    , selectedAudioInputDevice : Maybe (Evergreen.V413.IdString.IdString MediaDeviceId)
    , selectedVideoInputDevice : Maybe (Evergreen.V413.IdString.IdString MediaDeviceId)
    , remoteCallData : RemoteCallData
    , isSpeaking : SeqSet.SeqSet ConnectionId
    , localIsSpeaking : Bool
    , startConnectionError : Maybe String
    , volume : SeqDict.SeqDict ( Evergreen.V413.Id.Id Evergreen.V413.Id.UserId, Effect.Lamdera.ClientId ) Float
    , videoHover : Maybe LocalOrConnection
    , thumbnailPosition : ( Float, Float )
    , pollDebugData : Bool
    , debugData : List DebugSection
    }


type SharedCallId
    = SharedDmCall Evergreen.V413.DmChannelId.DmChannelId
    | SharedGuildCall Evergreen.V413.Id.Viewing_ChannelId
