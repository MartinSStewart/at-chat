module DmChannel exposing
    ( BackendDmChannel
    , DiscordDmChannel
    , DiscordFrontendDmChannel
    , E2eeEnabledData
    , E2eeStatus(..)
    , FrontendDmChannel
    , LoadedMessages
    , addRepliedToMatches
    , backendInit
    , frontendInit
    , gamesToFrontend
    , latestFrontendMessageId
    , latestFrontendThreadMessageId
    , latestMessageId
    , latestThreadMessageId
    , loadChannelMessages
    , loadMessages
    , loadOlderChannelMessages
    , loadOlderMessages
    , loadRepliedToMatches
    , loadUnreadMessages
    , loadedMessages
    , toDiscordFrontendHelper
    , toFrontend
    , toFrontendHelper
    , updateArray
    )

import Date exposing (Date)
import Discord
import DmChannelId exposing (DmChannelId, GuildOrFullDmId(..))
import Drawing exposing (Drawing)
import Effect.Time as Time
import Game exposing (BackendGameData)
import Id exposing (ChannelMessageId, GamePublicId, Id, ThreadMessageId, ThreadRoute(..), UserId)
import IdArray exposing (IdArray)
import Message exposing (Message)
import MessageArray exposing (MessageArray)
import NonemptyDict exposing (NonemptyDict)
import OneToOne exposing (OneToOne)
import SecretId exposing (SecretId)
import SeqDict exposing (SeqDict)
import SeqSet exposing (SeqSet)
import SessionIdHash exposing (SessionIdHash)
import Thread exposing (BackendThread, DiscordBackendThread, FrontendThread, LastTypedAt)
import UserSession exposing (ChannelHeaderTab(..), ToBeFilledInByBackend(..))
import VisibleMessages exposing (VisibleMessages)


type alias BackendDmChannel =
    { messages : IdArray ChannelMessageId (Message ChannelMessageId (Id UserId))
    , lastTypedAt : SeqDict (Id UserId) (LastTypedAt ChannelMessageId)
    , threads : SeqDict (Id ChannelMessageId) BackendThread
    , games : SeqDict (Id ChannelMessageId) BackendGameData
    , dateDividerDrawings : SeqDict Date (Drawing (Id UserId))
    , e2ee : E2eeStatus
    }


type E2eeStatus
    = E2eeDisabled (Maybe ( Id UserId, Time.Posix ))
    | E2eeRequestedBy ( Id UserId, SessionIdHash )
    | E2eeDeclinedBy (Id UserId)
    | E2eeEnabled E2eeEnabledData


type alias E2eeEnabledData =
    { enabledAt : Time.Posix, requestedBy : ( Id UserId, SessionIdHash ) }


type alias DiscordDmChannel =
    { messages : IdArray ChannelMessageId (Message ChannelMessageId (Discord.Id Discord.UserId))
    , lastTypedAt : SeqDict (Discord.Id Discord.UserId) (LastTypedAt ChannelMessageId)
    , linkedMessageIds : OneToOne (Discord.Id Discord.MessageId) (Id ChannelMessageId)
    , members : NonemptyDict (Discord.Id Discord.UserId) { messagesSent : Int }
    , dateDividerDrawings : SeqDict Date (Drawing (Discord.Id Discord.UserId))
    }


type alias DiscordFrontendDmChannel =
    { messages : MessageArray ChannelMessageId (Discord.Id Discord.UserId)
    , visibleMessages : VisibleMessages ChannelMessageId
    , lastTypedAt : SeqDict (Discord.Id Discord.UserId) (LastTypedAt ChannelMessageId)
    , members : NonemptyDict (Discord.Id Discord.UserId) { messagesSent : Int }
    , dateDividerDrawings : SeqDict Date (Drawing (Discord.Id Discord.UserId))
    }


type alias FrontendDmChannel =
    { messages : MessageArray ChannelMessageId (Id UserId)
    , visibleMessages : VisibleMessages ChannelMessageId
    , lastTypedAt : SeqDict (Id UserId) (LastTypedAt ChannelMessageId)
    , threads : SeqDict (Id ChannelMessageId) FrontendThread
    , games : SeqDict (Id ChannelMessageId) Game.MatchData
    , dateDividerDrawings : SeqDict Date (Drawing (Id UserId))
    , e2ee : E2eeStatus
    }


backendInit : BackendDmChannel
backendInit =
    { messages = IdArray.empty
    , lastTypedAt = SeqDict.empty
    , threads = SeqDict.empty
    , games = SeqDict.empty
    , dateDividerDrawings = SeqDict.empty
    , e2ee = E2eeDisabled Nothing
    }


frontendInit : FrontendDmChannel
frontendInit =
    { messages = MessageArray.empty
    , visibleMessages = VisibleMessages.empty
    , lastTypedAt = SeqDict.empty
    , threads = SeqDict.empty
    , games = SeqDict.empty
    , dateDividerDrawings = SeqDict.empty
    , e2ee = E2eeDisabled Nothing
    }


toFrontend :
    Maybe ( ThreadRoute, Maybe ChannelHeaderTab )
    -> DmChannelId
    -> OneToOne (SecretId GamePublicId) ( GuildOrFullDmId, Id ChannelMessageId )
    -> BackendDmChannel
    -> FrontendDmChannel
toFrontend threadRoute dmChannelId goMatchPublicIds dmChannel =
    let
        preloadMessages =
            Just NoThread == Maybe.map Tuple.first threadRoute

        messages : MessageArray ChannelMessageId (Id UserId)
        messages =
            toFrontendHelper preloadMessages dmChannel
    in
    { messages = messages
    , visibleMessages = VisibleMessages.init preloadMessages (IdArray.length dmChannel.messages)
    , lastTypedAt = dmChannel.lastTypedAt
    , threads =
        SeqDict.map
            (\threadId thread ->
                Thread.toFrontend (Just (ViewThread threadId) == Maybe.map Tuple.first threadRoute) thread
            )
            dmChannel.threads
    , games = gamesToFrontend (GuildOrFullDmId_Dm dmChannelId) threadRoute goMatchPublicIds messages dmChannel
    , dateDividerDrawings = dmChannel.dateDividerDrawings
    , e2ee = dmChannel.e2ee
    }


{-| Only the match the route has open and any match a preloaded message replies to are sent
in full. The rest wait until the games tab opens them.
-}
gamesToFrontend :
    GuildOrFullDmId
    -> Maybe ( a, Maybe ChannelHeaderTab )
    -> OneToOne (SecretId GamePublicId) ( GuildOrFullDmId, Id ChannelMessageId )
    -> MessageArray ChannelMessageId userId
    -> { b | games : SeqDict (Id ChannelMessageId) BackendGameData }
    -> SeqDict (Id ChannelMessageId) Game.MatchData
gamesToFrontend guildOrDmId threadRoute goMatchPublicIds messages channel =
    let
        repliedToMatches : SeqSet (Id ChannelMessageId)
        repliedToMatches =
            MessageArray.toList messages
                |> List.filterMap (\( _, message ) -> Message.repliedToMatch message)
                |> SeqSet.fromList

        openMatch : Maybe (Id ChannelMessageId)
        openMatch =
            case threadRoute of
                Just ( _, Just (ChannelHeaderTab_Games (Just matchId) _) ) ->
                    Just matchId

                _ ->
                    Nothing
    in
    SeqDict.map
        (\matchId gameData ->
            if Just matchId == openMatch || SeqSet.member matchId repliedToMatches then
                Game.initMatchData gameData (OneToOne.first ( guildOrDmId, matchId ) goMatchPublicIds)

            else
                Game.matchNotLoaded gameData
        )
        channel.games


{-| A page of a channel's messages, sent along with every match one of them replies to
something inside of. The line drawn above those replies needs the match to say what they
replied to.
-}
type alias LoadedMessages =
    { messages : SeqDict (Id ChannelMessageId) (Message ChannelMessageId (Id UserId))
    , repliedToMatches : SeqDict (Id ChannelMessageId) Game.LoadedMatch
    }


loadedMessages :
    GuildOrFullDmId
    -> OneToOne (SecretId GamePublicId) ( GuildOrFullDmId, Id ChannelMessageId )
    -> { a | games : SeqDict (Id ChannelMessageId) BackendGameData }
    -> SeqDict (Id ChannelMessageId) (Message ChannelMessageId (Id UserId))
    -> LoadedMessages
loadedMessages guildOrDmId goMatchPublicIds channel messages =
    { messages = messages
    , repliedToMatches =
        SeqDict.values messages
            |> List.filterMap Message.repliedToMatch
            |> loadRepliedToMatches guildOrDmId goMatchPublicIds channel
    }


loadRepliedToMatches :
    GuildOrFullDmId
    -> OneToOne (SecretId GamePublicId) ( GuildOrFullDmId, Id ChannelMessageId )
    -> { a | games : SeqDict (Id ChannelMessageId) BackendGameData }
    -> List (Id ChannelMessageId)
    -> SeqDict (Id ChannelMessageId) Game.LoadedMatch
loadRepliedToMatches guildOrDmId goMatchPublicIds channel matchIds =
    List.filterMap
        (\matchId ->
            case SeqDict.get matchId channel.games of
                Just gameData ->
                    Just
                        ( matchId
                        , { gameData = gameData
                          , publicLink = OneToOne.first ( guildOrDmId, matchId ) goMatchPublicIds
                          }
                        )

                Nothing ->
                    Nothing
        )
        matchIds
        |> SeqDict.fromList


updateArray : Id messageId -> (a -> a) -> IdArray messageId a -> IdArray messageId a
updateArray id updateFunc array =
    case IdArray.get id array of
        Just value ->
            IdArray.set id (updateFunc value) array

        Nothing ->
            array


latestMessageId : { a | messages : IdArray ChannelMessageId b } -> Id ChannelMessageId
latestMessageId channel =
    IdArray.length channel.messages - 1 |> Id.fromInt


latestFrontendMessageId : { a | messages : MessageArray ChannelMessageId b } -> Id ChannelMessageId
latestFrontendMessageId channel =
    MessageArray.length channel.messages - 1 |> Id.fromInt


latestThreadMessageId : { a | messages : IdArray ThreadMessageId b } -> Id ThreadMessageId
latestThreadMessageId thread =
    IdArray.length thread.messages - 1 |> Id.fromInt


latestFrontendThreadMessageId : { a | messages : MessageArray ThreadMessageId b } -> Id ThreadMessageId
latestFrontendThreadMessageId thread =
    MessageArray.length thread.messages - 1 |> Id.fromInt


toFrontendHelper :
    Bool
    -> { a | messages : IdArray messageId (Message messageId userId), threads : SeqDict (Id messageId) BackendThread }
    -> MessageArray messageId userId
toFrontendHelper preloadMessages channel =
    loadThreadStarters channel.threads channel.messages (Thread.loadMessages preloadMessages channel.messages)


toDiscordFrontendHelper :
    Bool
    -> { a | messages : IdArray messageId (Message messageId userId), threads : SeqDict (Id messageId) DiscordBackendThread }
    -> MessageArray messageId userId
toDiscordFrontendHelper preloadMessages channel =
    loadThreadStarters channel.threads channel.messages (Thread.loadMessages preloadMessages channel.messages)


{-| The message a thread was started from is always loaded, even when the rest of
the channel isn't, so that the thread can be previewed.
-}
loadThreadStarters :
    SeqDict (Id messageId) thread
    -> IdArray messageId (Message messageId userId)
    -> MessageArray messageId userId
    -> MessageArray messageId userId
loadThreadStarters threads backendMessages messages =
    SeqDict.foldl
        (\threadId _ list ->
            case IdArray.get threadId backendMessages of
                Just message ->
                    ( threadId, message ) :: list

                Nothing ->
                    list
        )
        []
        threads
        |> (\threadStarters -> MessageArray.setMany threadStarters messages)


loadOlderMessages :
    Id messageId
    -> ToBeFilledInByBackend (SeqDict (Id messageId) (Message messageId userId))
    -> { a | messages : MessageArray messageId userId, visibleMessages : VisibleMessages messageId }
    -> { a | messages : MessageArray messageId userId, visibleMessages : VisibleMessages messageId }
loadOlderMessages previousOldestVisibleMessage messagesLoaded channel =
    case messagesLoaded of
        FilledInByBackend messagesLoaded2 ->
            { channel
                | messages =
                    MessageArray.setMany (SeqDict.toList messagesLoaded2) channel.messages
                , visibleMessages = VisibleMessages.loadOlder previousOldestVisibleMessage channel.visibleMessages
            }

        EmptyPlaceholder ->
            { channel | visibleMessages = VisibleMessages.isLoading channel.visibleMessages }


loadOlderChannelMessages :
    Id ChannelMessageId
    -> ToBeFilledInByBackend LoadedMessages
    -> { a | messages : MessageArray ChannelMessageId (Id UserId), visibleMessages : VisibleMessages ChannelMessageId, games : SeqDict (Id ChannelMessageId) Game.MatchData }
    -> { a | messages : MessageArray ChannelMessageId (Id UserId), visibleMessages : VisibleMessages ChannelMessageId, games : SeqDict (Id ChannelMessageId) Game.MatchData }
loadOlderChannelMessages previousOldestVisibleMessage messagesLoaded channel =
    case messagesLoaded of
        FilledInByBackend messagesLoaded2 ->
            loadOlderMessages
                previousOldestVisibleMessage
                (FilledInByBackend messagesLoaded2.messages)
                { channel | games = addRepliedToMatches messagesLoaded2.repliedToMatches channel.games }

        EmptyPlaceholder ->
            loadOlderMessages previousOldestVisibleMessage EmptyPlaceholder channel


addRepliedToMatches :
    SeqDict (Id ChannelMessageId) Game.LoadedMatch
    -> SeqDict (Id ChannelMessageId) Game.MatchData
    -> SeqDict (Id ChannelMessageId) Game.MatchData
addRepliedToMatches repliedToMatches games =
    SeqDict.foldl
        (\matchId loaded games2 ->
            SeqDict.updateIfExists matchId (\_ -> Game.initMatchData loaded.gameData loaded.publicLink) games2
        )
        games
        repliedToMatches


{-| Loads the messages the unread overview shows. Unlike `loadMessages` this leaves
`visibleMessages` alone: these are messages of channels the user hasn't opened, so they
aren't the page of messages the channel view would scroll through.
-}
loadUnreadMessages :
    SeqDict (Id messageId) (Message messageId userId)
    -> { a | messages : MessageArray messageId userId }
    -> { a | messages : MessageArray messageId userId }
loadUnreadMessages messages channel =
    { channel | messages = MessageArray.setMany (SeqDict.toList messages) channel.messages }


loadMessages :
    ToBeFilledInByBackend (SeqDict (Id messageId) (Message messageId userId))
    -> { a | messages : MessageArray messageId userId, visibleMessages : VisibleMessages messageId }
    -> { a | messages : MessageArray messageId userId, visibleMessages : VisibleMessages messageId }
loadMessages messagesLoaded channel =
    case messagesLoaded of
        FilledInByBackend messagesLoaded2 ->
            { channel
                | messages = MessageArray.setMany (SeqDict.toList messagesLoaded2) channel.messages
                , visibleMessages =
                    if channel.visibleMessages.count == 0 then
                        VisibleMessages.firstLoad (MessageArray.length channel.messages)

                    else
                        channel.visibleMessages
            }

        EmptyPlaceholder ->
            { channel | visibleMessages = VisibleMessages.isLoading channel.visibleMessages }


loadChannelMessages :
    ToBeFilledInByBackend LoadedMessages
    -> { a | messages : MessageArray ChannelMessageId (Id UserId), visibleMessages : VisibleMessages ChannelMessageId, games : SeqDict (Id ChannelMessageId) Game.MatchData }
    -> { a | messages : MessageArray ChannelMessageId (Id UserId), visibleMessages : VisibleMessages ChannelMessageId, games : SeqDict (Id ChannelMessageId) Game.MatchData }
loadChannelMessages messagesLoaded channel =
    case messagesLoaded of
        FilledInByBackend messagesLoaded2 ->
            loadMessages
                (FilledInByBackend messagesLoaded2.messages)
                { channel | games = addRepliedToMatches messagesLoaded2.repliedToMatches channel.games }

        EmptyPlaceholder ->
            loadMessages EmptyPlaceholder channel
