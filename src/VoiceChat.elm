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
    = VoiceChat_Join (Id UserId)
    | VoiceChat_Leave (Id UserId)
    | VoiceChat_Signal (Id UserId) String


type ServerChange
    = VoiceChat_PeerJoined (Id UserId)
    | VoiceChat_PeerLeft (Id UserId)
    | VoiceChat_SignalReceived (Id UserId) String


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
        VoiceChat_PeerJoined peerId ->
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

        VoiceChat_PeerLeft peerId ->
            Ports.voiceChatStop peerId

        VoiceChat_SignalReceived peerId signal ->
            Ports.voiceChatDeliverSignal peerId signal


localChangeUpdate :
    LocalChange
    -> { a | voiceChats : SeqDict.SeqDict (Id UserId) VoiceChatState }
    -> { a | voiceChats : SeqDict.SeqDict (Id UserId) VoiceChatState }
localChangeUpdate change local =
    case change of
        VoiceChat_Join peerId ->
            let
                current : VoiceChatState
                current =
                    SeqDict.get peerId local.voiceChats |> Maybe.withDefault { iJoined = False, peerJoined = False }
            in
            { local | voiceChats = SeqDict.insert peerId { current | iJoined = True } local.voiceChats }

        VoiceChat_Leave peerId ->
            let
                current : VoiceChatState
                current =
                    SeqDict.get peerId local.voiceChats |> Maybe.withDefault { iJoined = False, peerJoined = False }
            in
            { local | voiceChats = SeqDict.insert peerId { current | iJoined = False } local.voiceChats }

        VoiceChat_Signal _ _ ->
            local


changeUpdate :
    ServerChange
    -> { a | voiceChats : SeqDict.SeqDict (Id UserId) VoiceChatState }
    -> { a | voiceChats : SeqDict.SeqDict (Id UserId) VoiceChatState }
changeUpdate change local =
    case change of
        VoiceChat_PeerJoined peerId ->
            let
                current : VoiceChatState
                current =
                    SeqDict.get peerId local.voiceChats
                        |> Maybe.withDefault { iJoined = False, peerJoined = False }
            in
            { local | voiceChats = SeqDict.insert peerId { current | peerJoined = True } local.voiceChats }

        VoiceChat_PeerLeft peerId ->
            let
                current : VoiceChatState
                current =
                    SeqDict.get peerId local.voiceChats
                        |> Maybe.withDefault { iJoined = False, peerJoined = False }
            in
            { local | voiceChats = SeqDict.insert peerId { current | peerJoined = False } local.voiceChats }

        VoiceChat_SignalReceived _ _ ->
            local
