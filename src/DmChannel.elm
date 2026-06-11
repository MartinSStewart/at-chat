module DmChannel exposing
    ( DiscordDmChannel
    , DiscordFrontendDmChannel
    , DmChannel
    , DmChannelId(..)
    , FrontendDmChannel
    , backendInit
    , channelIdFromString
    , channelIdFromUserIds
    , channelIdToString
    , frontendInit
    , getArray
    , latestMessageId
    , latestThreadMessageId
    , loadMessages
    , loadOlderMessages
    , otherUserId
    , setArray
    , toDiscordFrontendHelper
    , toFrontend
    , toFrontendHelper
    , updateArray
    , userIdsFromChannelId
    )

import Array exposing (Array)
import Array.Extra
import Date exposing (Date)
import Discord
import Drawing exposing (Drawing)
import Go
import Id exposing (ChannelMessageId, GoMatchPublicId, Id(..), ThreadMessageId, ThreadRoute(..), UserId)
import Message exposing (Message, MessageState(..))
import NonemptyDict exposing (NonemptyDict)
import OneToOne exposing (OneToOne)
import SecretId exposing (SecretId)
import SeqDict exposing (SeqDict)
import Thread exposing (BackendThread, DiscordBackendThread, FrontendThread, LastTypedAt)
import UserSession exposing (ToBeFilledInByBackend(..))
import VisibleMessages exposing (VisibleMessages)


type alias DmChannel =
    { messages : Array (Message ChannelMessageId (Id UserId))
    , lastTypedAt : SeqDict (Id UserId) (LastTypedAt ChannelMessageId)
    , threads : SeqDict (Id ChannelMessageId) BackendThread
    , goMatches : SeqDict (Id ChannelMessageId) ( Go.ValidatedSetup, Array Go.ActionWithTime )
    , dateDividerDrawings : SeqDict Date (Drawing (Id UserId))
    }


type alias DiscordDmChannel =
    { messages : Array (Message ChannelMessageId (Discord.Id Discord.UserId))
    , lastTypedAt : SeqDict (Discord.Id Discord.UserId) (LastTypedAt ChannelMessageId)
    , linkedMessageIds : OneToOne (Discord.Id Discord.MessageId) (Id ChannelMessageId)
    , members : NonemptyDict (Discord.Id Discord.UserId) { messagesSent : Int }
    , dateDividerDrawings : SeqDict Date (Drawing (Discord.Id Discord.UserId))
    }


type alias DiscordFrontendDmChannel =
    { messages : Array (MessageState ChannelMessageId (Discord.Id Discord.UserId))
    , visibleMessages : VisibleMessages ChannelMessageId
    , lastTypedAt : SeqDict (Discord.Id Discord.UserId) (LastTypedAt ChannelMessageId)
    , members : NonemptyDict (Discord.Id Discord.UserId) { messagesSent : Int }
    , dateDividerDrawings : SeqDict Date (Drawing (Discord.Id Discord.UserId))
    }


type alias FrontendDmChannel =
    { messages : Array (MessageState ChannelMessageId (Id UserId))
    , visibleMessages : VisibleMessages ChannelMessageId
    , lastTypedAt : SeqDict (Id UserId) (LastTypedAt ChannelMessageId)
    , threads : SeqDict (Id ChannelMessageId) FrontendThread
    , goMatches : SeqDict (Id ChannelMessageId) Go.MatchData
    , dateDividerDrawings : SeqDict Date (Drawing (Id UserId))
    }


{-| OpaqueVariants
-}
type DmChannelId
    = DmChannelId (Id UserId) (Id UserId)


backendInit : DmChannel
backendInit =
    { messages = Array.empty
    , lastTypedAt = SeqDict.empty
    , threads = SeqDict.empty
    , goMatches = SeqDict.empty
    , dateDividerDrawings = SeqDict.empty
    }


frontendInit : FrontendDmChannel
frontendInit =
    { messages = Array.empty
    , visibleMessages = VisibleMessages.empty
    , lastTypedAt = SeqDict.empty
    , threads = SeqDict.empty
    , goMatches = SeqDict.empty
    , dateDividerDrawings = SeqDict.empty
    }


toFrontend :
    Maybe ThreadRoute
    -> DmChannelId
    -> OneToOne (SecretId GoMatchPublicId) ( DmChannelId, Id ChannelMessageId )
    -> DmChannel
    -> FrontendDmChannel
toFrontend threadRoute dmChannelId goMatchPublicIds dmChannel =
    let
        preloadMessages =
            Just NoThread == threadRoute
    in
    { messages = toFrontendHelper preloadMessages dmChannel
    , visibleMessages = VisibleMessages.init preloadMessages dmChannel
    , lastTypedAt = dmChannel.lastTypedAt
    , threads =
        SeqDict.map
            (\threadId thread -> Thread.toFrontend (Just (ViewThread threadId) == threadRoute) thread)
            dmChannel.threads
    , goMatches =
        SeqDict.map
            (\matchId ( setup, actions ) ->
                Go.initMatchData setup actions (OneToOne.first ( dmChannelId, matchId ) goMatchPublicIds)
            )
            dmChannel.goMatches
    , dateDividerDrawings = dmChannel.dateDividerDrawings
    }


latestMessageId : { a | messages : Array b } -> Id ChannelMessageId
latestMessageId channel =
    Array.length channel.messages - 1 |> Id.fromInt


latestThreadMessageId : { a | messages : Array b } -> Id ThreadMessageId
latestThreadMessageId thread =
    Array.length thread.messages - 1 |> Id.fromInt


toFrontendHelper :
    Bool
    -> { a | messages : Array (Message messageId userId), threads : SeqDict (Id messageId) BackendThread }
    -> Array (MessageState messageId userId)
toFrontendHelper preloadMessages channel =
    SeqDict.foldl
        (\threadId _ messages ->
            setArray
                threadId
                (case getArray threadId channel.messages of
                    Just message ->
                        MessageLoaded message

                    Nothing ->
                        MessageUnloaded
                )
                messages
        )
        (Thread.loadMessages preloadMessages channel.messages)
        channel.threads


toDiscordFrontendHelper :
    Bool
    -> { a | messages : Array (Message messageId userId), threads : SeqDict (Id messageId) DiscordBackendThread }
    -> Array (MessageState messageId userId)
toDiscordFrontendHelper preloadMessages channel =
    SeqDict.foldl
        (\threadId _ messages ->
            setArray
                threadId
                (case getArray threadId channel.messages of
                    Just message ->
                        MessageLoaded message

                    Nothing ->
                        MessageUnloaded
                )
                messages
        )
        (Thread.loadMessages preloadMessages channel.messages)
        channel.threads


getArray : Id messageId -> Array a -> Maybe a
getArray id array =
    Array.get (Id.toInt id) array


setArray : Id messageId -> a -> Array a -> Array a
setArray id message array =
    Array.set (Id.toInt id) message array


updateArray : Id messageId -> (a -> a) -> Array a -> Array a
updateArray id message array =
    Array.Extra.update (Id.toInt id) message array


channelIdFromUserIds : Id UserId -> Id UserId -> DmChannelId
channelIdFromUserIds (Id userIdA) (Id userIdB) =
    DmChannelId (min userIdA userIdB |> Id) (max userIdA userIdB |> Id)


userIdsFromChannelId : DmChannelId -> ( Id UserId, Id UserId )
userIdsFromChannelId (DmChannelId userIdA userIdB) =
    ( userIdA, userIdB )


channelIdToString : DmChannelId -> String
channelIdToString (DmChannelId userIdA userIdB) =
    Id.toString userIdA ++ "-" ++ Id.toString userIdB


channelIdFromString : String -> Result () DmChannelId
channelIdFromString text =
    case String.split "-" text of
        [ idA, idB ] ->
            case ( Id.fromString idA, Id.fromString idB ) of
                ( Just idA2, Just idB2 ) ->
                    channelIdFromUserIds idA2 idB2 |> Ok

                _ ->
                    Err ()

        _ ->
            Err ()


otherUserId : Id UserId -> DmChannelId -> Maybe (Id UserId)
otherUserId userId (DmChannelId userIdA userIdB) =
    if userId == userIdA then
        Just userIdB

    else if userId == userIdB then
        Just userIdA

    else
        Nothing


loadOlderMessages :
    Id messageId
    -> ToBeFilledInByBackend (SeqDict (Id messageId) (Message messageId userId))
    -> { a | messages : Array (MessageState messageId userId), visibleMessages : VisibleMessages messageId }
    -> { a | messages : Array (MessageState messageId userId), visibleMessages : VisibleMessages messageId }
loadOlderMessages previousOldestVisibleMessage messagesLoaded channel =
    case messagesLoaded of
        FilledInByBackend messagesLoaded2 ->
            { channel
                | messages =
                    SeqDict.foldl
                        (\messageId message messages ->
                            setArray messageId (MessageLoaded message) messages
                        )
                        channel.messages
                        messagesLoaded2
                , visibleMessages = VisibleMessages.loadOlder previousOldestVisibleMessage channel.visibleMessages
            }

        EmptyPlaceholder ->
            channel


loadMessages :
    ToBeFilledInByBackend (SeqDict (Id messageId) (Message messageId userId))
    -> { a | messages : Array (MessageState messageId userId), visibleMessages : VisibleMessages messageId }
    -> { a | messages : Array (MessageState messageId userId), visibleMessages : VisibleMessages messageId }
loadMessages messagesLoaded channel =
    case messagesLoaded of
        FilledInByBackend messagesLoaded2 ->
            { channel
                | messages =
                    SeqDict.foldl
                        (\messageId message messages -> setArray messageId (MessageLoaded message) messages)
                        channel.messages
                        messagesLoaded2
                , visibleMessages = VisibleMessages.firstLoad channel
            }

        EmptyPlaceholder ->
            channel
