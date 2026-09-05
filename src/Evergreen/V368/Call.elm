module Evergreen.V368.Call exposing (..)

import Bytes
import Effect.Lamdera
import Effect.Time
import Evergreen.V368.Id
import Evergreen.V368.IdString
import Evergreen.V368.NonemptyDict
import List.Nonempty
import SeqDict
import SeqSet


type MediaDeviceId
    = MediaDeviceId Never


type DeviceKind
    = AudioInput
    | VideoInput
    | AudioOutput


type alias MediaDevice =
    { deviceId : Evergreen.V368.IdString.IdString MediaDeviceId
    , groupId : String
    , kind : DeviceKind
    , label : String
    }


type CallId
    = DmRoomId Evergreen.V368.Id.Viewing_DmId
    | GuildRoomId Evergreen.V368.Id.Viewing_ChannelId


type alias ConnectionId =
    { roomId : CallId
    , otherClientId : ( Evergreen.V368.Id.Id Evergreen.V368.Id.UserId, Effect.Lamdera.ClientId )
    }


type LocalOrConnection
    = IsLocal
    | IsConnection ConnectionId


type FromJs
    = FromJs_GotUserMediaDevices (List MediaDevice) (List (Evergreen.V368.IdString.IdString MediaDeviceId))
    | FromJs_GotUserMediaDevicesError String
    | FromJs_SpeakingChanged LocalOrConnection Bool
    | FromJs_StartConnectionError String


type Msg
    = SelectedAudioInputDevice (Evergreen.V368.IdString.IdString MediaDeviceId)
    | SelectedVideoInputDevice (Evergreen.V368.IdString.IdString MediaDeviceId)
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


type LocalChange
    = Local_Leave Effect.Time.Posix
    | Local_SetRemoteCallData RemoteCallData


type ServerChange
    = Server_YouJoined Effect.Time.Posix CallId
    | Server_OtherJoined Effect.Time.Posix ConnectionId
    | Server_Left Effect.Time.Posix ConnectionId
    | Server_SetRemoteCallData ConnectionId RemoteCallData


type alias Local =
    { currentRoom : Maybe CallId
    , voiceChats : SeqDict.SeqDict CallId (Evergreen.V368.NonemptyDict.NonemptyDict ( Evergreen.V368.Id.Id Evergreen.V368.Id.UserId, Effect.Lamdera.ClientId ) RemoteCallData)
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
    , selectedAudioInputDevice : Maybe (Evergreen.V368.IdString.IdString MediaDeviceId)
    , selectedVideoInputDevice : Maybe (Evergreen.V368.IdString.IdString MediaDeviceId)
    , remoteCallData : RemoteCallData
    , isSpeaking : SeqSet.SeqSet ConnectionId
    , recordings : SeqDict.SeqDict CallId (List.Nonempty.Nonempty Recording)
    , localIsSpeaking : Bool
    , startConnectionError : Maybe String
    , volume : SeqDict.SeqDict ( Evergreen.V368.Id.Id Evergreen.V368.Id.UserId, Effect.Lamdera.ClientId ) Float
    , videoHover : Maybe LocalOrConnection
    , thumbnailPosition : ( Float, Float )
    }
