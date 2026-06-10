module Thread exposing
    ( BackendThread
    , DiscordBackendThread
    , DiscordFrontendThread
    , FrontendGenericThread
    , FrontendThread
    , LastTypedAt
    , backendInit
    , discordBackendInit
    , discordFrontendInit
    , discordToFrontend
    , frontendInit
    , loadMessages
    , toFrontend
    )

import Array exposing (Array)
import Date exposing (Date)
import Discord
import Drawing
import Effect.Time as Time
import Id exposing (Id, ThreadMessageId, UserId)
import Message exposing (Message, MessageState(..))
import OneToOne exposing (OneToOne)
import SeqDict exposing (SeqDict)
import VisibleMessages exposing (VisibleMessages)


type alias BackendThread =
    { messages : Array (Message ThreadMessageId (Id UserId))
    , lastTypedAt : SeqDict (Id UserId) (LastTypedAt ThreadMessageId)
    , dateDividerDrawings : SeqDict Date (Drawing.ChannelDrawing (Id UserId))
    }


type alias DiscordBackendThread =
    { messages : Array (Message ThreadMessageId (Discord.Id Discord.UserId))
    , lastTypedAt : SeqDict (Discord.Id Discord.UserId) (LastTypedAt ThreadMessageId)
    , linkedMessageIds : OneToOne (Discord.Id Discord.MessageId) (Id ThreadMessageId)
    , dateDividerDrawings : SeqDict Date (Drawing.ChannelDrawing (Discord.Id Discord.UserId))
    }


type alias FrontendGenericThread userId =
    { messages : Array (MessageState ThreadMessageId userId)
    , visibleMessages : VisibleMessages ThreadMessageId
    , lastTypedAt : SeqDict userId (LastTypedAt ThreadMessageId)
    , dateDividerDrawings : SeqDict Date (Drawing.ChannelDrawing userId)
    }


type alias FrontendThread =
    { messages : Array (MessageState ThreadMessageId (Id UserId))
    , visibleMessages : VisibleMessages ThreadMessageId
    , lastTypedAt : SeqDict (Id UserId) (LastTypedAt ThreadMessageId)
    , dateDividerDrawings : SeqDict Date (Drawing.ChannelDrawing (Id UserId))
    }


type alias DiscordFrontendThread =
    { messages : Array (MessageState ThreadMessageId (Discord.Id Discord.UserId))
    , visibleMessages : VisibleMessages ThreadMessageId
    , lastTypedAt : SeqDict (Discord.Id Discord.UserId) (LastTypedAt ThreadMessageId)
    , dateDividerDrawings : SeqDict Date (Drawing.ChannelDrawing (Discord.Id Discord.UserId))
    }


type alias LastTypedAt messageId =
    { time : Time.Posix, messageIndex : Maybe (Id messageId) }


backendInit : BackendThread
backendInit =
    { messages = Array.empty
    , lastTypedAt = SeqDict.empty
    , dateDividerDrawings = SeqDict.empty
    }


frontendInit : FrontendGenericThread userId
frontendInit =
    { messages = Array.empty
    , visibleMessages = VisibleMessages.empty
    , lastTypedAt = SeqDict.empty
    , dateDividerDrawings = SeqDict.empty
    }


discordBackendInit : DiscordBackendThread
discordBackendInit =
    { messages = Array.empty
    , lastTypedAt = SeqDict.empty
    , linkedMessageIds = OneToOne.empty
    , dateDividerDrawings = SeqDict.empty
    }


discordFrontendInit : DiscordFrontendThread
discordFrontendInit =
    { messages = Array.empty
    , visibleMessages = VisibleMessages.empty
    , lastTypedAt = SeqDict.empty
    , dateDividerDrawings = SeqDict.empty
    }


toFrontend : Bool -> BackendThread -> FrontendThread
toFrontend preloadMessages thread =
    { messages = loadMessages preloadMessages thread.messages
    , visibleMessages = VisibleMessages.init preloadMessages thread
    , lastTypedAt = thread.lastTypedAt
    , dateDividerDrawings = thread.dateDividerDrawings
    }


discordToFrontend : Bool -> DiscordBackendThread -> DiscordFrontendThread
discordToFrontend preloadMessages thread =
    { messages = loadMessages preloadMessages thread.messages
    , visibleMessages = VisibleMessages.init preloadMessages thread
    , lastTypedAt = thread.lastTypedAt
    , dateDividerDrawings = thread.dateDividerDrawings
    }


loadMessages : Bool -> Array (Message messageId userId) -> Array (MessageState messageId userId)
loadMessages preloadMessages messages =
    let
        messageCount : Int
        messageCount =
            Array.length messages
    in
    if preloadMessages then
        Array.initialize
            messageCount
            (\index ->
                if messageCount - index <= VisibleMessages.pageSize then
                    case Array.get index messages of
                        Just message ->
                            MessageLoaded message

                        Nothing ->
                            MessageUnloaded

                else
                    MessageUnloaded
            )

    else
        -- Load the latest message for each channel/thread in case it's needed for a preview somewhere
        Array.repeat messageCount MessageUnloaded
            |> Array.set
                (messageCount - 1)
                (case Array.get (messageCount - 1) messages of
                    Just message ->
                        MessageLoaded message

                    Nothing ->
                        MessageUnloaded
                )
