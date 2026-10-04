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
    , withRepliedToMessages
    )

import Array exposing (Array)
import Date exposing (Date)
import Discord
import Drawing
import Effect.Time as Time
import Id exposing (ChannelId, Id, ThreadMessageId, ThreadRouteWithMaybeMessage, UserId)
import IdArray exposing (IdArray)
import Message exposing (Message)
import MessageArray exposing (MessageArray)
import OneToOne exposing (OneToOne)
import SeqDict exposing (SeqDict)
import VisibleMessages exposing (VisibleMessages)


type alias BackendThread =
    { messages : IdArray ThreadMessageId (Message ThreadMessageId (Id UserId) (Id ChannelId))
    , dateDividerDrawings : SeqDict Date (Drawing.Drawing (Id UserId))
    }


type alias DiscordBackendThread =
    { messages : IdArray ThreadMessageId (Message ThreadMessageId (Discord.Id Discord.UserId) (Discord.Id Discord.ChannelId))
    , linkedMessageIds : OneToOne (Discord.Id Discord.MessageId) (Id ThreadMessageId)
    , dateDividerDrawings : SeqDict Date (Drawing.Drawing (Discord.Id Discord.UserId))
    }


type alias FrontendGenericThread userId channelId =
    { messages : MessageArray ThreadMessageId userId channelId
    , visibleMessages : VisibleMessages ThreadMessageId
    , dateDividerDrawings : SeqDict Date (Drawing.Drawing userId)
    }


type alias FrontendThread =
    { messages : MessageArray ThreadMessageId (Id UserId) (Id ChannelId)
    , visibleMessages : VisibleMessages ThreadMessageId
    , dateDividerDrawings : SeqDict Date (Drawing.Drawing (Id UserId))
    }


type alias DiscordFrontendThread =
    { messages : MessageArray ThreadMessageId (Discord.Id Discord.UserId) (Discord.Id Discord.ChannelId)
    , visibleMessages : VisibleMessages ThreadMessageId
    , dateDividerDrawings : SeqDict Date (Drawing.Drawing (Discord.Id Discord.UserId))
    }


type alias LastTypedAt channelId =
    { channelId : channelId, threadRoute : ThreadRouteWithMaybeMessage, time : Time.Posix }


backendInit : BackendThread
backendInit =
    { messages = IdArray.empty
    , dateDividerDrawings = SeqDict.empty
    }


frontendInit : FrontendGenericThread userId channelId
frontendInit =
    { messages = MessageArray.empty
    , visibleMessages = VisibleMessages.empty
    , dateDividerDrawings = SeqDict.empty
    }


discordBackendInit : DiscordBackendThread
discordBackendInit =
    { messages = IdArray.empty
    , linkedMessageIds = OneToOne.empty
    , dateDividerDrawings = SeqDict.empty
    }


discordFrontendInit : DiscordFrontendThread
discordFrontendInit =
    { messages = MessageArray.empty
    , visibleMessages = VisibleMessages.empty
    , dateDividerDrawings = SeqDict.empty
    }


toFrontend : Bool -> BackendThread -> FrontendThread
toFrontend preloadMessages thread =
    { messages = loadMessages preloadMessages thread.messages
    , visibleMessages = VisibleMessages.init preloadMessages (IdArray.length thread.messages)
    , dateDividerDrawings = thread.dateDividerDrawings
    }


discordToFrontend : Bool -> DiscordBackendThread -> DiscordFrontendThread
discordToFrontend preloadMessages thread =
    { messages = loadMessages preloadMessages thread.messages
    , visibleMessages = VisibleMessages.init preloadMessages (IdArray.length thread.messages)
    , dateDividerDrawings = thread.dateDividerDrawings
    }


loadMessages : Bool -> IdArray messageId (Message messageId userId channelId) -> MessageArray messageId userId channelId
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

        messagesToLoad : Array (Message messageId userId channelId)
        messagesToLoad =
            IdArray.toArray messages |> Array.slice oldestLoaded messageCount

        referencedMessages : List ( Id messageId, Message messageId userId channelId )
        referencedMessages =
            Array.foldl
                (\message list ->
                    case Message.repliedToMessage message of
                        Just repliedToId ->
                            case IdArray.get repliedToId messages of
                                Just repliedTo ->
                                    ( repliedToId, repliedTo ) :: list

                                Nothing ->
                                    list

                        Nothing ->
                            list
                )
                []
                messagesToLoad
    in
    MessageArray.fromArray messageCount (Id.fromInt oldestLoaded) messagesToLoad
        |> MessageArray.setMany referencedMessages


{-| Adds the messages that `loaded` reply to, so a reply can show what it replied to even when
that message is older than the page being sent.
-}
withRepliedToMessages :
    IdArray messageId (Message messageId userId channelId)
    -> SeqDict (Id messageId) (Message messageId userId channelId)
    -> SeqDict (Id messageId) (Message messageId userId channelId)
withRepliedToMessages messages loaded =
    SeqDict.foldl
        (\_ message dict ->
            case Message.repliedToMessage message of
                Just repliedToId ->
                    if SeqDict.member repliedToId dict then
                        dict

                    else
                        case IdArray.get repliedToId messages of
                            Just repliedTo ->
                                SeqDict.insert repliedToId repliedTo dict

                            Nothing ->
                                dict

                Nothing ->
                    dict
        )
        loaded
        loaded
