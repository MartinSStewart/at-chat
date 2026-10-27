module Evergreen.V417.Call exposing (..)

import Effect.Lamdera
import Effect.Time
import Evergreen.V417.DmChannelId
import Evergreen.V417.Id
import Evergreen.V417.IdString
import Evergreen.V417.NonemptyDict
import SeqDict
import SeqSet


type MediaDeviceId
    = MediaDeviceId Never


type DeviceKind
    = AudioInput
    | VideoInput
    | AudioOutput


type alias MediaDevice =
    { deviceId : Evergreen.V417.IdString.IdString MediaDeviceId
    , groupId : String
    , kind : DeviceKind
    , label : String
    }


type CallId
    = DmRoomId Evergreen.V417.Id.Viewing_DmId
    | GuildRoomId Evergreen.V417.Id.Viewing_ChannelId


type alias ConnectionId =
    { roomId : CallId
    , otherClientId : ( Evergreen.V417.Id.Id Evergreen.V417.Id.UserId, Effect.Lamdera.ClientId )
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
    = FromJs_GotUserMediaDevices (List MediaDevice) (List (Evergreen.V417.IdString.IdString MediaDeviceId))
    | FromJs_GotUserMediaDevicesError String
    | FromJs_SpeakingChanged LocalOrConnection Bool
    | FromJs_StartConnectionError String
    | FromJs_DebugData (List DebugSection)
    | FromJs_ScreenShareStarted
    | FromJs_ScreenShareStopped
    | FromJs_RecordingUploadProgress Int Int
    | FromJs_RecordingUploadsStopped


type VideoTile
    = CameraTile LocalOrConnection
    | ScreenShareTile LocalOrConnection


type Msg
    = SelectedAudioInputDevice (Evergreen.V417.IdString.IdString MediaDeviceId)
    | SelectedVideoInputDevice (Evergreen.V417.IdString.IdString MediaDeviceId)
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
    | PressedVideoTile VideoTile
    | PressedToggleDeviceSettings
    | PressedToggleDebugData
    | PolledDebugData


type alias RemoteCallData =
    { audioInputEnabled : Bool
    , videoInputEnabled : Bool
    , screenShareEnabled : Bool
    }


type RecordingStatus
    = AskingToRecord
        { requestedBy : Evergreen.V417.Id.Id Evergreen.V417.Id.UserId
        , requestedAt : Effect.Time.Posix
        , allowedBy : SeqSet.SeqSet (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId)
        }
    | RecordingDeclined
        { requestedBy : Evergreen.V417.Id.Id Evergreen.V417.Id.UserId
        , declinedBy : Maybe (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId)
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
    , voiceChats : SeqDict.SeqDict CallId (Evergreen.V417.NonemptyDict.NonemptyDict ( Evergreen.V417.Id.Id Evergreen.V417.Id.UserId, Effect.Lamdera.ClientId ) RemoteCallData)
    , recordings : SeqDict.SeqDict CallId RecordingStatus
    }


type MediaDevicesStatus
    = MediaDevicesNotLoaded
    | HasMediaDevices (List MediaDevice)
    | FailedToGetMediaDevices String


type alias Model =
    { userMediaDevices : MediaDevicesStatus
    , selectedAudioInputDevice : Maybe (Evergreen.V417.IdString.IdString MediaDeviceId)
    , selectedVideoInputDevice : Maybe (Evergreen.V417.IdString.IdString MediaDeviceId)
    , remoteCallData : RemoteCallData
    , isSpeaking : SeqSet.SeqSet ConnectionId
    , localIsSpeaking : Bool
    , startConnectionError : Maybe String
    , volume : SeqDict.SeqDict ( Evergreen.V417.Id.Id Evergreen.V417.Id.UserId, Effect.Lamdera.ClientId ) Float
    , videoHover : Maybe LocalOrConnection
    , focusedTile : Maybe VideoTile
    , showDeviceSettings : Bool
    , thumbnailPosition : ( Float, Float )
    , pollDebugData : Bool
    , debugData : List DebugSection
    , recordingUpload :
        Maybe
            { uploaded : Int
            , total : Int
            }
    }


type SharedCallId
    = SharedDmCall Evergreen.V417.DmChannelId.DmChannelId
    | SharedGuildCall Evergreen.V417.Id.Viewing_ChannelId
