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

import Date exposing (Date)
import Discord
import Drawing
import Effect.Time as Time
import Id exposing (Id, ThreadMessageId, UserId)
import IdArray exposing (IdArray)
import Message exposing (Message, MessageState(..))
import OneToOne exposing (OneToOne)
import SeqDict exposing (SeqDict)
import VisibleMessages exposing (VisibleMessages)


type alias BackendThread =
    { messages : IdArray ThreadMessageId (Message ThreadMessageId (Id UserId))
    , lastTypedAt : SeqDict (Id UserId) (LastTypedAt ThreadMessageId)
    , dateDividerDrawings : SeqDict Date (Drawing.Drawing (Id UserId))
    }


type alias DiscordBackendThread =
    { messages : IdArray ThreadMessageId (Message ThreadMessageId (Discord.Id Discord.UserId))
    , lastTypedAt : SeqDict (Discord.Id Discord.UserId) (LastTypedAt ThreadMessageId)
    , linkedMessageIds : OneToOne (Discord.Id Discord.MessageId) (Id ThreadMessageId)
    , dateDividerDrawings : SeqDict Date (Drawing.Drawing (Discord.Id Discord.UserId))
    }


type alias FrontendGenericThread userId =
    { messages : IdArray ThreadMessageId (MessageState ThreadMessageId userId)
    , visibleMessages : VisibleMessages ThreadMessageId
    , lastTypedAt : SeqDict userId (LastTypedAt ThreadMessageId)
    , dateDividerDrawings : SeqDict Date (Drawing.Drawing userId)
    }


type alias FrontendThread =
    { messages : IdArray ThreadMessageId (MessageState ThreadMessageId (Id UserId))
    , visibleMessages : VisibleMessages ThreadMessageId
    , lastTypedAt : SeqDict (Id UserId) (LastTypedAt ThreadMessageId)
    , dateDividerDrawings : SeqDict Date (Drawing.Drawing (Id UserId))
    }


type alias DiscordFrontendThread =
    { messages : IdArray ThreadMessageId (MessageState ThreadMessageId (Discord.Id Discord.UserId))
    , visibleMessages : VisibleMessages ThreadMessageId
    , lastTypedAt : SeqDict (Discord.Id Discord.UserId) (LastTypedAt ThreadMessageId)
    , dateDividerDrawings : SeqDict Date (Drawing.Drawing (Discord.Id Discord.UserId))
    }


type alias LastTypedAt messageId =
    { time : Time.Posix, messageIndex : Maybe (Id messageId) }


backendInit : BackendThread
backendInit =
    { messages = IdArray.empty
    , lastTypedAt = SeqDict.empty
    , dateDividerDrawings = SeqDict.empty
    }


frontendInit : FrontendGenericThread userId
frontendInit =
    { messages = IdArray.empty
    , visibleMessages = VisibleMessages.empty
    , lastTypedAt = SeqDict.empty
    , dateDividerDrawings = SeqDict.empty
    }


discordBackendInit : DiscordBackendThread
discordBackendInit =
    { messages = IdArray.empty
    , lastTypedAt = SeqDict.empty
    , linkedMessageIds = OneToOne.empty
    , dateDividerDrawings = SeqDict.empty
    }


discordFrontendInit : DiscordFrontendThread
discordFrontendInit =
    { messages = IdArray.empty
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


loadMessages : Bool -> IdArray messageId (Message messageId userId) -> IdArray messageId (MessageState messageId userId)
loadMessages preloadMessages messages =
    let
        messageCount : Int
        messageCount =
            IdArray.length messages
    in
    if preloadMessages then
        IdArray.initialize
            messageCount
            (\index ->
                if messageCount - index <= VisibleMessages.pageSize then
                    case IdArray.get (Id.fromInt index) messages of
                        Just message ->
                            MessageLoaded message

                        Nothing ->
                            MessageUnloaded

                else
                    MessageUnloaded
            )

    else
        -- Load the latest message for each channel/thread in case it's needed for a preview somewhere
        IdArray.initialize messageCount (\_ -> MessageUnloaded)
            |> IdArray.set
                (Id.fromInt (messageCount - 1))
                (case IdArray.get (Id.fromInt (messageCount - 1)) messages of
                    Just message ->
                        MessageLoaded message

                    Nothing ->
                        MessageUnloaded
                )
