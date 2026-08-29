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
import IdArray exposing (IdArray)
import Message exposing (ContentAndEmbeds, Message)
import MessageArray exposing (MessageArray)
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
    { messages : MessageArray ThreadMessageId userId
    , visibleMessages : VisibleMessages ThreadMessageId
    , lastTypedAt : SeqDict userId (LastTypedAt ThreadMessageId)
    , dateDividerDrawings : SeqDict Date (Drawing.Drawing userId)
    }


type alias FrontendThread =
    { messages : MessageArray ThreadMessageId (Id UserId)
    , visibleMessages : VisibleMessages ThreadMessageId
    , lastTypedAt : SeqDict (Id UserId) (LastTypedAt ThreadMessageId)
    , dateDividerDrawings : SeqDict Date (Drawing.Drawing (Id UserId))
    }


type alias DiscordFrontendThread =
    { messages : MessageArray ThreadMessageId (Discord.Id Discord.UserId)
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
    { messages = MessageArray.empty
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
    { messages = MessageArray.empty
    , visibleMessages = VisibleMessages.empty
    , lastTypedAt = SeqDict.empty
    , dateDividerDrawings = SeqDict.empty
    }


toFrontend : Bool -> BackendThread -> FrontendThread
toFrontend preloadMessages thread =
    { messages = loadMessages preloadMessages thread.messages
    , visibleMessages = VisibleMessages.init preloadMessages (IdArray.length thread.messages)
    , lastTypedAt = thread.lastTypedAt
    , dateDividerDrawings = thread.dateDividerDrawings
    }


discordToFrontend : Bool -> DiscordBackendThread -> DiscordFrontendThread
discordToFrontend preloadMessages thread =
    { messages = loadMessages preloadMessages thread.messages
    , visibleMessages = VisibleMessages.init preloadMessages (IdArray.length thread.messages)
    , lastTypedAt = thread.lastTypedAt
    , dateDividerDrawings = thread.dateDividerDrawings
    }


loadMessages : Bool -> IdArray messageId (Message messageId userId) -> MessageArray messageId userId
loadMessages preloadMessages messages =
    let
        messageCount : Int
        messageCount =
            IdArray.length messages

        oldestLoaded : Int
        oldestLoaded =
            if preloadMessages then
                messageCount - VisibleMessages.pageSize |> max 0

            else
                -- Load the latest message for each channel/thread in case it's needed for a preview somewhere
                messageCount - 1 |> max 0

        messagesToLoad : Array (Message messageId userId)
        messagesToLoad =
            IdArray.toArray messages |> Array.slice oldestLoaded messageCount

        referencedMessages : List ( Id messageId, Message messageId userId )
        referencedMessages =
            Array.foldl
                (\message list ->
                    case message of
                        Message.UserTextMessage message2 ->
                            case message2.repliedTo of
                                Just repliedToId ->
                                    case IdArray.get repliedToId messages of
                                        Just repliedTo ->
                                            ( repliedToId, repliedTo ) :: list

                                        Nothing ->
                                            list

                                Nothing ->
                                    list

                        _ ->
                            list
                )
                []
                messagesToLoad
    in
    MessageArray.fromArray messageCount (Id.fromInt oldestLoaded) messagesToLoad
        |> MessageArray.setMany referencedMessages
