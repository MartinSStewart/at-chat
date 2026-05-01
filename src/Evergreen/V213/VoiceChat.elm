module Evergreen.V213.VoiceChat exposing (..)

import Effect.Lamdera
import Effect.Time
import Evergreen.V213.Id
import Evergreen.V213.NonemptySet
import SeqDict


type RoomId
    = DmRoomId (Evergreen.V213.Id.Id Evergreen.V213.Id.UserId)


type alias ConnectionId =
    { roomId : RoomId
    , otherSession : ( Evergreen.V213.Id.Id Evergreen.V213.Id.UserId, Effect.Lamdera.ClientId )
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


type alias Model =
    { currentRoom : Maybe RoomId
    , voiceChats : SeqDict.SeqDict RoomId (Evergreen.V213.NonemptySet.NonemptySet ( Evergreen.V213.Id.Id Evergreen.V213.Id.UserId, Effect.Lamdera.ClientId ))
    }
