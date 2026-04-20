module VoiceChat exposing
    ( LocalChange(..)
    , ServerChange(..)
    , VoiceChatState
    , changeCmd
    , changeUpdate
    , localChangeUpdate
    )

import Effect.Command as Command exposing (Command, FrontendOnly)
import Id exposing (Id, UserId)
import Ports
import SeqDict


type LocalChange
    = Local_Join (Id UserId)
    | Local_Leave (Id UserId)
    | Local_Signal (Id UserId) String


type ServerChange
    = Server_PeerJoined (Id UserId)
    | Server_PeerLeft (Id UserId)
    | Server_SignalReceived (Id UserId) String


type alias VoiceChatState =
    { iJoined : Bool
    , peerJoined : Bool
    }


changeCmd :
    ServerChange
    -> Id UserId
    -> { a | voiceChats : SeqDict.SeqDict (Id UserId) VoiceChatState }
    -> Command FrontendOnly toBackend msg
changeCmd change currentUserId local =
    case change of
        Server_PeerJoined peerId ->
            let
                current : VoiceChatState
                current =
                    SeqDict.get peerId local.voiceChats
                        |> Maybe.withDefault { iJoined = False, peerJoined = False }
            in
            if current.iJoined then
                Ports.voiceChatStart peerId (Id.toInt currentUserId < Id.toInt peerId)

            else
                Command.none

        Server_PeerLeft peerId ->
            Ports.voiceChatStop peerId

        Server_SignalReceived peerId signal ->
            Ports.voiceChatDeliverSignal peerId signal


localChangeUpdate :
    LocalChange
    -> { a | voiceChats : SeqDict.SeqDict (Id UserId) VoiceChatState }
    -> { a | voiceChats : SeqDict.SeqDict (Id UserId) VoiceChatState }
localChangeUpdate change local =
    case change of
        Local_Join peerId ->
            let
                current : VoiceChatState
                current =
                    SeqDict.get peerId local.voiceChats |> Maybe.withDefault { iJoined = False, peerJoined = False }
            in
            { local | voiceChats = SeqDict.insert peerId { current | iJoined = True } local.voiceChats }

        Local_Leave peerId ->
            let
                current : VoiceChatState
                current =
                    SeqDict.get peerId local.voiceChats |> Maybe.withDefault { iJoined = False, peerJoined = False }
            in
            { local | voiceChats = SeqDict.insert peerId { current | iJoined = False } local.voiceChats }

        Local_Signal _ _ ->
            local


changeUpdate :
    ServerChange
    -> { a | voiceChats : SeqDict.SeqDict (Id UserId) VoiceChatState }
    -> { a | voiceChats : SeqDict.SeqDict (Id UserId) VoiceChatState }
changeUpdate change local =
    case change of
        Server_PeerJoined peerId ->
            let
                current : VoiceChatState
                current =
                    SeqDict.get peerId local.voiceChats
                        |> Maybe.withDefault { iJoined = False, peerJoined = False }
            in
            { local | voiceChats = SeqDict.insert peerId { current | peerJoined = True } local.voiceChats }

        Server_PeerLeft peerId ->
            let
                current : VoiceChatState
                current =
                    SeqDict.get peerId local.voiceChats
                        |> Maybe.withDefault { iJoined = False, peerJoined = False }
            in
            { local | voiceChats = SeqDict.insert peerId { current | peerJoined = False } local.voiceChats }

        Server_SignalReceived _ _ ->
            local
