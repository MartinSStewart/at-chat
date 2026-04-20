module VoiceChat exposing
    ( LocalChange(..)
    , Model
    , ServerChange(..)
    , VoiceChatId(..)
    , VoiceChatState
    , addSessionIdHash
    , changeCmd
    , changeUpdate
    , hasJoined
    , leaveVoiceChatCmds
    , localChangeUpdate
    , peerHasJoined
    )

import Effect.Command as Command exposing (Command, FrontendOnly)
import Id exposing (Id, UserId)
import NonemptySet exposing (NonemptySet)
import Ports
import SeqDict exposing (SeqDict)
import SeqSet
import SessionIdHash exposing (SessionIdHash)


type LocalChange
    = Local_Join VoiceChatId
    | Local_Leave VoiceChatId
    | Local_Signal VoiceChatId String


type ServerChange
    = Server_Joined VoiceChatId SessionIdHash
    | Server_Left VoiceChatId SessionIdHash
    | Server_SignalReceived VoiceChatId SessionIdHash String


type alias Model =
    { voiceChats : SeqDict VoiceChatId (NonemptySet SessionIdHash) }


type VoiceChatId
    = DmVoiceChat (Id UserId)


type alias VoiceChatState =
    { iJoined : Bool
    , peerJoined : Bool
    }


hasJoined :
    VoiceChatId
    ->
        { b
            | calls : Model
            , localUser : { d | session : { e | sessionIdHash : SessionIdHash } }
        }
    -> Bool
hasJoined otherUserId local =
    case SeqDict.get otherUserId local.calls.voiceChats of
        Just voiceChat ->
            NonemptySet.member local.localUser.session.sessionIdHash voiceChat

        Nothing ->
            False


leaveVoiceChatCmds : VoiceChatId -> SessionIdHash -> Model -> Command FrontendOnly toMsg msg
leaveVoiceChatCmds voiceChatId sessionIdHash model =
    case SeqDict.get voiceChatId model.voiceChats of
        Just voiceChat ->
            NonemptySet.toList voiceChat
                |> List.map Ports.voiceChatStop
                |> Command.batch

        Nothing ->
            Command.none


peerHasJoined :
    VoiceChatId
    ->
        { b
            | calls : Model
            , localUser : { d | session : { e | sessionIdHash : SessionIdHash } }
            , otherSessions : SeqDict SessionIdHash f
        }
    -> Bool
peerHasJoined otherUserId local =
    case SeqDict.get otherUserId local.calls.voiceChats of
        Just voiceChat ->
            SeqDict.foldl
                (\sessionId _ set ->
                    SeqSet.remove sessionId set
                )
                (NonemptySet.remove local.localUser.session.sessionIdHash voiceChat)
                local.otherSessions
                |> SeqSet.isEmpty
                |> not

        Nothing ->
            False


changeCmd :
    ServerChange
    -> Id UserId
    -> SessionIdHash
    -> { a | voiceChats : SeqDict VoiceChatId VoiceChatState }
    -> Command FrontendOnly toBackend msg
changeCmd change currentUserId sessionIdHash local =
    case change of
        Server_Joined peerId peerSessionIdHash ->
            let
                current : VoiceChatState
                current =
                    SeqDict.get peerId local.voiceChats
                        |> Maybe.withDefault { iJoined = False, peerJoined = False }
            in
            if current.iJoined then
                Ports.voiceChatStart
                    peerSessionIdHash
                    (SessionIdHash.toString sessionIdHash < SessionIdHash.toString peerSessionIdHash)

            else
                Command.none

        Server_Left peerId peerSessionIdHash ->
            Ports.voiceChatStop peerSessionIdHash

        Server_SignalReceived peerId peerSessionIdHash signal ->
            Ports.voiceChatDeliverSignal peerSessionIdHash signal


addSessionIdHash :
    dmChannelId
    -> sessionId
    -> SeqDict dmChannelId (NonemptySet sessionId)
    -> SeqDict dmChannelId (NonemptySet sessionId)
addSessionIdHash otherUserId sessionIdHash dmVoiceChats =
    SeqDict.update
        otherUserId
        (\maybe ->
            case maybe of
                Just nonemptySet ->
                    NonemptySet.insert sessionIdHash nonemptySet |> Just

                Nothing ->
                    NonemptySet.singleton sessionIdHash |> Just
        )
        dmVoiceChats


removeSessionIdHash : VoiceChatId -> SessionIdHash -> Model -> Model
removeSessionIdHash peerId peerSessionIdHash model =
    case SeqDict.get peerId model.voiceChats of
        Just dmVoiceChat ->
            let
                voiceChatParticipants2 =
                    NonemptySet.remove peerSessionIdHash dmVoiceChat
                        |> NonemptySet.fromSeqSet
            in
            { model
                | voiceChats = SeqDict.update peerId (\_ -> voiceChatParticipants2) model.voiceChats
            }

        Nothing ->
            model


localChangeUpdate : LocalChange -> SessionIdHash -> { a | calls : Model } -> { a | calls : Model }
localChangeUpdate change sessionIdHash local =
    case change of
        Local_Join peerId ->
            let
                calls : Model
                calls =
                    local.calls
            in
            { local | calls = { calls | voiceChats = addSessionIdHash peerId sessionIdHash calls.voiceChats } }

        Local_Leave peerId ->
            { local | calls = removeSessionIdHash peerId sessionIdHash local.calls }

        Local_Signal _ _ ->
            local


changeUpdate : ServerChange -> SessionIdHash -> { a | calls : Model } -> { a | calls : Model }
changeUpdate change sessionIdHash local =
    case change of
        Server_Joined peerId peerSessionIdHash ->
            let
                calls : Model
                calls =
                    local.calls
            in
            { local | calls = { calls | voiceChats = addSessionIdHash peerId peerSessionIdHash calls.voiceChats } }

        Server_Left peerId peerSessionIdHash ->
            { local | calls = removeSessionIdHash peerId peerSessionIdHash local.calls }

        Server_SignalReceived _ peerSessionIdHash _ ->
            local
