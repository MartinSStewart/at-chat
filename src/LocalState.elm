module LocalState exposing
    ( AdminData
    , AdminStatus(..)
    , Archived
    , BackendChannel
    , BackendGuild
    , ChannelStatus(..)
    , DiscordBackendChannel
    , DiscordBackendGuild
    , DiscordFrontendChannel
    , DiscordFrontendGuild
    , FrontendChannel
    , FrontendGuild
    , JoinGuildError(..)
    , LocalState
    , LocalUser
    , LogWithTime
    , PrivateVapidKey(..)
    , addInvite
    , addMember
    , addMemberFrontend
    , addReactionEmoji
    , addReactionEmojiFrontend
    , allUsers
    , allUsers2
    , announcementChannel
    , createChannel
    , createChannelFrontend
    , createChannelMessageBackend
    , createChannelMessageFrontend
    , createGuild
    , createThreadMessageBackend
    , createThreadMessageFrontend
    , currentDiscordUser
    , deleteChannel
    , deleteChannelFrontend
    , deleteMessageBackend
    , deleteMessageBackendHelper
    , deleteMessageFrontend
    , deleteMessageFrontendHelper
    , discordGuildToFrontendForUser
    , editChannel
    , editMessageFrontendHelper
    , editMessageHelper
    , getDiscordGuildAndChannel
    , getGuildAndChannel
    , getUser
    , guildToFrontend
    , guildToFrontendForUser
    , markAllChannelsAsViewed
    , memberIsEditTyping
    , memberIsEditTypingFrontend
    , memberIsEditTypingFrontendHelper
    , memberIsEditTypingHelper
    , memberIsTyping
    , removeReactionEmoji
    , removeReactionEmojiFrontend
    , updateChannel
    , usersMentionedOrRepliedToBackend
    , usersMentionedOrRepliedToFrontend
    )

import Array exposing (Array)
import Array.Extra
import ChannelName exposing (ChannelName)
import Discord.Id
import DmChannel exposing (DiscordFrontendThread, DiscordThread, ExternalChannelId, ExternalMessageId, FrontendDmChannel, FrontendThread, LastTypedAt, Thread)
import Duration
import Effect.Time as Time
import Emoji exposing (Emoji)
import FileStatus exposing (FileData, FileHash, FileId)
import GuildName exposing (GuildName)
import Id exposing (AnyGuildOrDmIdNoThread(..), ChannelId, ChannelMessageId, GuildId, GuildOrDmIdNoThread(..), Id, InviteLinkId, ThreadMessageId, ThreadRoute(..), ThreadRouteWithMaybeMessage(..), ThreadRouteWithMessage(..), UserId)
import List.Nonempty exposing (Nonempty)
import Log exposing (Log)
import Maybe.Extra
import Message exposing (Message(..), MessageState(..), UserTextMessageData)
import NonemptyDict exposing (NonemptyDict)
import OneToOne exposing (OneToOne)
import Quantity
import RichText exposing (RichText(..))
import SecretId exposing (SecretId)
import SeqDict exposing (SeqDict)
import SeqSet exposing (SeqSet)
import SessionIdHash exposing (SessionIdHash)
import Slack
import TextEditor
import Unsafe
import User exposing (BackendUser, FrontendCurrentUser, FrontendUser)
import UserAgent exposing (UserAgent)
import UserSession exposing (FrontendUserSession, UserSession)
import VisibleMessages exposing (VisibleMessages)


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict (Id GuildId) (FrontendGuild (Id ChannelId))
    , discordGuilds : SeqDict (Discord.Id.Id Discord.Id.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict (Id UserId) FrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict SessionIdHash FrontendUserSession
    , publicVapidKey : String
    , textEditor : TextEditor.LocalState
    }


type alias LocalUser =
    { session : UserSession
    , user : FrontendCurrentUser
    , otherUsers : SeqDict (Id UserId) FrontendUser
    , -- This data is redundant as it already exists in FrontendLoading and FrontendLoaded. We need it here anyway to reduce the number of parameters passed into messageView so lazy rendering is possible.
      timezone : Time.Zone
    , userAgent : UserAgent
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias BackendGuild channelId =
    { createdAt : Time.Posix
    , createdBy : Id UserId
    , name : GuildName
    , icon : Maybe FileHash
    , channels : SeqDict channelId BackendChannel
    , members : SeqDict (Id UserId) { joinedAt : Time.Posix }
    , owner : Id UserId
    , invites : SeqDict (SecretId InviteLinkId) { createdAt : Time.Posix, createdBy : Id UserId }
    }


type alias DiscordBackendGuild =
    { name : GuildName
    , icon : Maybe FileHash
    , channels : SeqDict (Discord.Id.Id Discord.Id.ChannelId) DiscordBackendChannel
    , members : SeqDict (Discord.Id.Id Discord.Id.UserId) { joinedAt : Time.Posix }
    , owner : Discord.Id.Id Discord.Id.UserId
    }


type alias FrontendGuild channelId =
    { createdAt : Time.Posix
    , createdBy : Id UserId
    , name : GuildName
    , icon : Maybe FileHash
    , channels : SeqDict channelId FrontendChannel
    , members : SeqDict (Id UserId) { joinedAt : Time.Posix }
    , owner : Id UserId
    , invites : SeqDict (SecretId InviteLinkId) { createdAt : Time.Posix, createdBy : Id UserId }
    }


type alias DiscordFrontendGuild =
    { name : GuildName
    , icon : Maybe FileHash
    , channels : SeqDict (Discord.Id.Id Discord.Id.ChannelId) DiscordFrontendChannel
    , members : SeqDict (Discord.Id.Id Discord.Id.UserId) { joinedAt : Time.Posix }
    , owner : Discord.Id.Id Discord.Id.UserId
    }


guildToFrontendForUser : Maybe ( channelId, ThreadRoute ) -> Id UserId -> BackendGuild channelId -> Maybe (FrontendGuild channelId)
guildToFrontendForUser requestMessagesFor userId guild =
    if userId == guild.owner || SeqDict.member userId guild.members then
        { createdAt = guild.createdAt
        , createdBy = guild.createdBy
        , name = guild.name
        , icon = guild.icon
        , channels =
            SeqDict.filterMap
                (\channelId channel ->
                    channelToFrontend
                        (case requestMessagesFor of
                            Just ( channelIdB, threadRoute ) ->
                                if channelId == channelIdB then
                                    Just threadRoute

                                else
                                    Nothing

                            _ ->
                                Nothing
                        )
                        channel
                )
                guild.channels
        , members = guild.members
        , owner = guild.owner
        , invites = guild.invites
        }
            |> Just

    else
        Nothing


discordGuildToFrontendForUser :
    Maybe ( Discord.Id.Id Discord.Id.ChannelId, ThreadRoute )
    -> DiscordBackendGuild
    -> Maybe DiscordFrontendGuild
discordGuildToFrontendForUser requestMessagesFor guild =
    { name = guild.name
    , icon = guild.icon
    , channels =
        SeqDict.filterMap
            (\channelId channel ->
                discordChannelToFrontend
                    (case requestMessagesFor of
                        Just ( channelIdB, threadRoute ) ->
                            if channelId == channelIdB then
                                Just threadRoute

                            else
                                Nothing

                        _ ->
                            Nothing
                    )
                    channel
            )
            guild.channels
    , members = guild.members
    , owner = guild.owner
    }
        |> Just


guildToFrontend : Maybe ( channelId, ThreadRoute ) -> BackendGuild channelId -> FrontendGuild channelId
guildToFrontend requestMessagesFor guild =
    { createdAt = guild.createdAt
    , createdBy = guild.createdBy
    , name = guild.name
    , icon = guild.icon
    , channels =
        SeqDict.filterMap
            (\channelId channel ->
                channelToFrontend
                    (case requestMessagesFor of
                        Just ( channelIdB, threadRoute ) ->
                            if channelId == channelIdB then
                                Just threadRoute

                            else
                                Nothing

                        _ ->
                            Nothing
                    )
                    channel
            )
            guild.channels
    , members = guild.members
    , owner = guild.owner
    , invites = guild.invites
    }


type alias BackendChannel =
    { createdAt : Time.Posix
    , createdBy : Id UserId
    , name : ChannelName
    , messages : Array (Message ChannelMessageId (Id UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict (Id UserId) (LastTypedAt ChannelMessageId)
    , threads : SeqDict (Id ChannelMessageId) Thread
    }


type alias DiscordBackendChannel =
    { name : ChannelName
    , messages : Array (Message ChannelMessageId (Discord.Id.Id Discord.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict (Discord.Id.Id Discord.Id.UserId) (LastTypedAt ChannelMessageId)
    , linkedMessageIds : OneToOne (Discord.Id.Id Discord.Id.MessageId) (Id ChannelMessageId)
    , threads : SeqDict (Id ChannelMessageId) DiscordThread
    }


type alias FrontendChannel =
    { createdAt : Time.Posix
    , createdBy : Id UserId
    , name : ChannelName
    , messages : Array (MessageState ChannelMessageId (Id UserId))
    , visibleMessages : VisibleMessages ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict (Id UserId) (LastTypedAt ChannelMessageId)
    , threads : SeqDict (Id ChannelMessageId) FrontendThread
    }


type alias DiscordFrontendChannel =
    { name : ChannelName
    , messages : Array (MessageState ChannelMessageId (Discord.Id.Id Discord.Id.UserId))
    , visibleMessages : VisibleMessages ChannelMessageId
    , lastTypedAt : SeqDict (Discord.Id.Id Discord.Id.UserId) (LastTypedAt ChannelMessageId)
    , linkedMessageIds : OneToOne (Discord.Id.Id Discord.Id.MessageId) (Id ChannelMessageId)
    , threads : SeqDict (Id ChannelMessageId) DiscordFrontendThread
    }


channelToFrontend : Maybe ThreadRoute -> BackendChannel -> Maybe FrontendChannel
channelToFrontend threadRoute channel =
    case channel.status of
        ChannelActive ->
            let
                preloadMessages =
                    Just NoThread == threadRoute
            in
            { createdAt = channel.createdAt
            , createdBy = channel.createdBy
            , name = channel.name
            , messages = DmChannel.toFrontendHelper preloadMessages channel
            , visibleMessages = VisibleMessages.init preloadMessages channel
            , isArchived = Nothing
            , lastTypedAt = channel.lastTypedAt
            , threads =
                SeqDict.map
                    (\threadId thread -> DmChannel.threadToFrontend (Just (ViewThread threadId) == threadRoute) thread)
                    channel.threads
            }
                |> Just

        ChannelDeleted _ ->
            Nothing


discordChannelToFrontend : Maybe ThreadRoute -> DiscordBackendChannel -> Maybe DiscordFrontendChannel
discordChannelToFrontend threadRoute channel =
    case channel.status of
        ChannelActive ->
            let
                preloadMessages =
                    Just NoThread == threadRoute

                channel2 : DiscordFrontendChannel
                channel2 =
                    { name = channel.name
                    , messages = DmChannel.toDiscordFrontendHelper preloadMessages channel
                    , visibleMessages = VisibleMessages.init preloadMessages channel
                    , linkedMessageIds = channel.linkedMessageIds
                    , lastTypedAt = channel.lastTypedAt
                    , threads = SeqDict.empty

                    --SeqDict.map
                    --    (\threadId thread -> DmChannel.threadToFrontend (Just (ViewThread threadId) == threadRoute) thread)
                    --    channel.threads
                    }
            in
            channel2
                |> Just

        ChannelDeleted _ ->
            Nothing


type alias Archived =
    { archivedAt : Time.Posix, archivedBy : Id UserId }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted { deletedAt : Time.Posix, deletedBy : Id UserId }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LogWithTime =
    { time : Time.Posix, log : Log }


type alias AdminData =
    { users : NonemptyDict (Id UserId) BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict (Id UserId) Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Slack.ClientSecret
    , openRouterKey : Maybe String
    }


type PrivateVapidKey
    = PrivateVapidKey String



--getMessages : GuildOrDmId -> LocalState -> Maybe ( ThreadRoute, Array (Message messageId) )
--getMessages ( guildOrDmId, threadRoute ) local =
--    case guildOrDmId of
--        GuildOrDmId_Guild_NoThread guildId channelId ->
--            case getGuildAndChannel guildId channelId local of
--                Just ( _, channel ) ->
--                    case threadRoute of
--                        ViewThread threadMessageIndex ->
--                            case SeqDict.get threadMessageIndex channel.threads of
--                                Just thread ->
--                                    Just ( threadRoute, thread.messages )
--
--                                Nothing ->
--                                    Nothing
--
--                        NoThread ->
--                            Just ( threadRoute, channel.messages )
--
--                Nothing ->
--                    Nothing
--
--        GuildOrDmId_Dm_NoThread otherUserId ->
--            case SeqDict.get otherUserId local.dmChannels of
--                Just dmChannel ->
--                    case threadRoute of
--                        ViewThread threadMessageIndex ->
--                            case SeqDict.get threadMessageIndex dmChannel.threads of
--                                Just thread ->
--                                    Just ( threadRoute, thread.messages )
--
--                                Nothing ->
--                                    Nothing
--
--                        NoThread ->
--                            Just ( threadRoute, dmChannel.messages )
--
--                Nothing ->
--                    Nothing


getUser : Id UserId -> LocalUser -> Maybe FrontendUser
getUser userId localUser =
    if localUser.session.userId == userId then
        User.backendToFrontend localUser.user |> Just

    else
        SeqDict.get userId localUser.otherUsers


createThreadMessageBackend :
    Id ChannelMessageId
    -> Message ThreadMessageId (Id UserId)
    -> BackendChannel
    -> BackendChannel
createThreadMessageBackend threadId message channel =
    { channel
        | threads =
            SeqDict.update
                threadId
                (\maybe ->
                    Maybe.withDefault DmChannel.threadInit maybe
                        |> createMessageBackend message
                        |> Just
                )
                channel.threads
    }


createChannelMessageBackend :
    Message ChannelMessageId (Id UserId)
    ->
        { d
            | messages : Array (Message ChannelMessageId (Id UserId))
            , lastTypedAt : SeqDict (Id UserId) (LastTypedAt ChannelMessageId)
        }
    ->
        { d
            | messages : Array (Message ChannelMessageId (Id UserId))
            , lastTypedAt : SeqDict (Id UserId) (LastTypedAt ChannelMessageId)
        }
createChannelMessageBackend message channel =
    createMessageBackend message channel


createMessageBackend :
    Message messageId (Id UserId)
    ->
        { d
            | messages : Array (Message messageId (Id UserId))
            , lastTypedAt : SeqDict (Id UserId) (LastTypedAt messageId)
        }
    ->
        { d
            | messages : Array (Message messageId (Id UserId))
            , lastTypedAt : SeqDict (Id UserId) (LastTypedAt messageId)
        }
createMessageBackend message channel =
    let
        previousIndex : Id messageId
        previousIndex =
            Array.length channel.messages - 1 |> Id.fromInt
    in
    { channel
        | messages =
            case DmChannel.getArray previousIndex channel.messages of
                Just previousMessage ->
                    case mergeMessages message previousMessage of
                        Just mergedMessage ->
                            DmChannel.setArray previousIndex mergedMessage channel.messages

                        Nothing ->
                            Array.push message channel.messages

                Nothing ->
                    Array.push message channel.messages
        , lastTypedAt =
            case message of
                UserTextMessage { createdBy } ->
                    SeqDict.remove createdBy channel.lastTypedAt

                UserJoinedMessage _ _ _ ->
                    channel.lastTypedAt

                DeletedMessage _ ->
                    channel.lastTypedAt
    }


createThreadMessageFrontend :
    Id ChannelMessageId
    -> Message ThreadMessageId (Id UserId)
    ->
        { d
            | messages : Array (MessageState ChannelMessageId (Id UserId))
            , visibleMessages : VisibleMessages ChannelMessageId
            , lastTypedAt : SeqDict (Id UserId) (LastTypedAt ChannelMessageId)
            , threads : SeqDict (Id ChannelMessageId) FrontendThread
        }
    ->
        { d
            | messages : Array (MessageState ChannelMessageId (Id UserId))
            , visibleMessages : VisibleMessages ChannelMessageId
            , lastTypedAt : SeqDict (Id UserId) (LastTypedAt ChannelMessageId)
            , threads : SeqDict (Id ChannelMessageId) FrontendThread
        }
createThreadMessageFrontend threadId message channel =
    { channel
        | threads =
            SeqDict.update
                threadId
                (\maybe ->
                    Maybe.withDefault DmChannel.frontendThreadInit maybe
                        |> createMessageFrontend message
                        |> Just
                )
                channel.threads
    }


createChannelMessageFrontend :
    Message ChannelMessageId (Id UserId)
    ->
        { d
            | messages : Array (MessageState ChannelMessageId (Id UserId))
            , visibleMessages : VisibleMessages ChannelMessageId
            , lastTypedAt : SeqDict (Id UserId) (LastTypedAt ChannelMessageId)
        }
    ->
        { d
            | messages : Array (MessageState ChannelMessageId (Id UserId))
            , visibleMessages : VisibleMessages ChannelMessageId
            , lastTypedAt : SeqDict (Id UserId) (LastTypedAt ChannelMessageId)
        }
createChannelMessageFrontend message channel =
    createMessageFrontend message channel


createMessageFrontend :
    Message messageId (Id UserId)
    ->
        { d
            | messages : Array (MessageState messageId (Id UserId))
            , visibleMessages : VisibleMessages messageId
            , lastTypedAt : SeqDict (Id UserId) (LastTypedAt messageId)
        }
    ->
        { d
            | messages : Array (MessageState messageId (Id UserId))
            , visibleMessages : VisibleMessages messageId
            , lastTypedAt : SeqDict (Id UserId) (LastTypedAt messageId)
        }
createMessageFrontend message channel =
    let
        previousIndex : Id messageId
        previousIndex =
            Array.length channel.messages - 1 |> Id.fromInt

        mergeWithPrevious : Maybe (Message messageId (Id UserId))
        mergeWithPrevious =
            case DmChannel.getArray previousIndex channel.messages of
                Just (MessageLoaded previousMessage) ->
                    mergeMessages message previousMessage

                _ ->
                    Nothing
    in
    { channel
        | messages =
            case mergeWithPrevious of
                Just mergedMessage ->
                    DmChannel.setArray previousIndex (MessageLoaded mergedMessage) channel.messages

                Nothing ->
                    Array.push (MessageLoaded message) channel.messages
        , visibleMessages =
            case mergeWithPrevious of
                Nothing ->
                    VisibleMessages.increment channel channel.visibleMessages

                _ ->
                    channel.visibleMessages
        , lastTypedAt =
            case message of
                UserTextMessage { createdBy } ->
                    SeqDict.remove createdBy channel.lastTypedAt

                UserJoinedMessage _ _ _ ->
                    channel.lastTypedAt

                DeletedMessage _ ->
                    channel.lastTypedAt
    }


mergeMessages : Message messageId userId -> Message messageId userId -> Maybe (Message messageId userId)
mergeMessages message previousMessage =
    case ( message, previousMessage ) of
        ( UserTextMessage data, UserTextMessage previous ) ->
            if
                (Duration.from previous.createdAt data.createdAt |> Quantity.lessThan (Duration.minutes 5))
                    && (previous.editedAt == Nothing)
                    && (previous.createdBy == data.createdBy)
                    && not (SeqDict.isEmpty previous.reactions)
                --&& not (OneToOne.memberSecond previousIndex channel.linkedMessageIds)
            then
                UserTextMessage
                    { previous
                        | content =
                            RichText.append
                                previous.content
                                (List.Nonempty.cons (NormalText '\n' "") data.content)
                    }
                    |> Just

            else
                Nothing

        _ ->
            Nothing


createGuild : Time.Posix -> Id UserId -> GuildName -> BackendGuild (Id ChannelId)
createGuild time userId guildName =
    { createdAt = time
    , createdBy = userId
    , name = guildName
    , icon = Nothing
    , channels =
        SeqDict.fromList
            [ ( Id.fromInt 0
              , { createdAt = time
                , createdBy = userId
                , name = defaultChannelName
                , messages = Array.empty
                , status = ChannelActive
                , lastTypedAt = SeqDict.empty
                , threads = SeqDict.empty
                }
              )
            ]
    , members = SeqDict.empty
    , owner = userId
    , invites = SeqDict.empty
    }


defaultChannelName : ChannelName
defaultChannelName =
    Unsafe.channelName "general"


createChannel : Time.Posix -> Id UserId -> ChannelName -> BackendGuild (Id ChannelId) -> BackendGuild (Id ChannelId)
createChannel time userId channelName guild =
    let
        channelId : Id ChannelId
        channelId =
            Id.nextId guild.channels
    in
    { guild
        | channels =
            SeqDict.insert
                channelId
                { createdAt = time
                , createdBy = userId
                , name = channelName
                , messages = Array.empty
                , status = ChannelActive
                , lastTypedAt = SeqDict.empty
                , threads = SeqDict.empty
                }
                guild.channels
    }


createChannelFrontend : Time.Posix -> Id UserId -> ChannelName -> FrontendGuild (Id ChannelId) -> FrontendGuild (Id ChannelId)
createChannelFrontend time userId channelName guild =
    { guild
        | channels =
            SeqDict.insert
                (Id.nextId guild.channels)
                { createdAt = time
                , createdBy = userId
                , name = channelName
                , messages = Array.empty
                , visibleMessages = VisibleMessages.empty
                , isArchived = Nothing
                , lastTypedAt = SeqDict.empty
                , threads = SeqDict.empty
                }
                guild.channels
    }


editChannel :
    ChannelName
    -> Id ChannelId
    -> { c | channels : SeqDict (Id ChannelId) { d | name : ChannelName } }
    -> { c | channels : SeqDict (Id ChannelId) { d | name : ChannelName } }
editChannel channelName channelId guild =
    updateChannel (\channel -> { channel | name = channelName }) channelId guild


deleteChannel : Time.Posix -> Id UserId -> Id ChannelId -> BackendGuild (Id ChannelId) -> BackendGuild (Id ChannelId)
deleteChannel time userId channelId guild =
    updateChannel
        (\channel -> { channel | status = ChannelDeleted { deletedAt = time, deletedBy = userId } })
        channelId
        guild


deleteChannelFrontend : Id ChannelId -> FrontendGuild (Id ChannelId) -> FrontendGuild (Id ChannelId)
deleteChannelFrontend channelId guild =
    { guild | channels = SeqDict.remove channelId guild.channels }


memberIsTyping :
    userId
    -> Time.Posix
    -> ThreadRoute
    ->
        { e
            | lastTypedAt : SeqDict userId (LastTypedAt ChannelMessageId)
            , threads : SeqDict (Id ChannelMessageId) { f | lastTypedAt : SeqDict userId (LastTypedAt ThreadMessageId) }
        }
    ->
        { e
            | lastTypedAt : SeqDict userId (LastTypedAt ChannelMessageId)
            , threads : SeqDict (Id ChannelMessageId) { f | lastTypedAt : SeqDict userId (LastTypedAt ThreadMessageId) }
        }
memberIsTyping userId time threadRoute channel =
    case threadRoute of
        ViewThread threadMessageIndex ->
            { channel
                | threads =
                    SeqDict.updateIfExists
                        threadMessageIndex
                        (\thread ->
                            { thread
                                | lastTypedAt =
                                    SeqDict.insert
                                        userId
                                        { time = time, messageIndex = Nothing }
                                        thread.lastTypedAt
                            }
                        )
                        channel.threads
            }

        NoThread ->
            { channel
                | lastTypedAt =
                    SeqDict.insert userId { time = time, messageIndex = Nothing } channel.lastTypedAt
            }


memberIsEditTyping :
    Id UserId
    -> Time.Posix
    -> Id ChannelId
    -> ThreadRouteWithMessage
    ->
        { d
            | channels :
                SeqDict
                    (Id ChannelId)
                    { e
                        | messages : Array (Message ChannelMessageId (Id UserId))
                        , lastTypedAt : SeqDict (Id UserId) (LastTypedAt ChannelMessageId)
                        , threads : SeqDict (Id ChannelMessageId) Thread
                    }
        }
    ->
        Result
            ()
            { d
                | channels :
                    SeqDict
                        (Id ChannelId)
                        { e
                            | messages : Array (Message ChannelMessageId (Id UserId))
                            , lastTypedAt : SeqDict (Id UserId) (LastTypedAt ChannelMessageId)
                            , threads : SeqDict (Id ChannelMessageId) Thread
                        }
            }
memberIsEditTyping userId time channelId threadRoute guild =
    case SeqDict.get channelId guild.channels of
        Just channel ->
            case memberIsEditTypingHelper time userId threadRoute channel of
                Ok channel2 ->
                    Ok { guild | channels = SeqDict.insert channelId channel2 guild.channels }

                _ ->
                    Err ()

        Nothing ->
            Err ()


memberIsEditTypingFrontend :
    Id UserId
    -> Time.Posix
    -> Id ChannelId
    -> ThreadRouteWithMessage
    ->
        { d
            | channels :
                SeqDict
                    (Id ChannelId)
                    { e
                        | messages : Array (MessageState ChannelMessageId (Id UserId))
                        , lastTypedAt : SeqDict (Id UserId) (LastTypedAt ChannelMessageId)
                        , threads : SeqDict (Id ChannelMessageId) FrontendThread
                    }
        }
    ->
        Result
            ()
            { d
                | channels :
                    SeqDict
                        (Id ChannelId)
                        { e
                            | messages : Array (MessageState ChannelMessageId (Id UserId))
                            , lastTypedAt : SeqDict (Id UserId) (LastTypedAt ChannelMessageId)
                            , threads : SeqDict (Id ChannelMessageId) FrontendThread
                        }
            }
memberIsEditTypingFrontend userId time channelId threadRoute guild =
    case SeqDict.get channelId guild.channels of
        Just channel ->
            case memberIsEditTypingFrontendHelper time userId threadRoute channel of
                Ok channel2 ->
                    Ok { guild | channels = SeqDict.insert channelId channel2 guild.channels }

                _ ->
                    Err ()

        Nothing ->
            Err ()


updateArray : Id messageId -> (a -> a) -> Array a -> Array a
updateArray id updateFunc array =
    Array.Extra.update (Id.toInt id) updateFunc array


memberIsEditTypingHelper :
    Time.Posix
    -> Id UserId
    -> ThreadRouteWithMessage
    -> { a | messages : Array (Message ChannelMessageId (Id UserId)), lastTypedAt : SeqDict (Id UserId) (LastTypedAt ChannelMessageId), threads : SeqDict (Id ChannelMessageId) Thread }
    -> Result () { a | messages : Array (Message ChannelMessageId (Id UserId)), lastTypedAt : SeqDict (Id UserId) (LastTypedAt ChannelMessageId), threads : SeqDict (Id ChannelMessageId) Thread }
memberIsEditTypingHelper time userId threadRoute channel =
    case threadRoute of
        ViewThreadWithMessage threadMessageIndex messageIndex ->
            case SeqDict.get threadMessageIndex channel.threads of
                Just thread ->
                    case DmChannel.getArray messageIndex thread.messages of
                        Just (UserTextMessage data) ->
                            if data.createdBy == userId then
                                { channel
                                    | threads =
                                        SeqDict.insert
                                            threadMessageIndex
                                            { thread
                                                | lastTypedAt =
                                                    SeqDict.insert
                                                        userId
                                                        { time = time, messageIndex = Just messageIndex }
                                                        thread.lastTypedAt
                                            }
                                            channel.threads
                                }
                                    |> Ok

                            else
                                Err ()

                        _ ->
                            Err ()

                Nothing ->
                    Err ()

        NoThreadWithMessage messageIndex ->
            case DmChannel.getArray messageIndex channel.messages of
                Just (UserTextMessage data) ->
                    if data.createdBy == userId then
                        { channel
                            | lastTypedAt =
                                SeqDict.insert userId { time = time, messageIndex = Just messageIndex } channel.lastTypedAt
                        }
                            |> Ok

                    else
                        Err ()

                _ ->
                    Err ()


memberIsEditTypingFrontendHelper :
    Time.Posix
    -> Id UserId
    -> ThreadRouteWithMessage
    -> { a | messages : Array (MessageState ChannelMessageId (Id UserId)), lastTypedAt : SeqDict (Id UserId) (LastTypedAt ChannelMessageId), threads : SeqDict (Id ChannelMessageId) FrontendThread }
    -> Result () { a | messages : Array (MessageState ChannelMessageId (Id UserId)), lastTypedAt : SeqDict (Id UserId) (LastTypedAt ChannelMessageId), threads : SeqDict (Id ChannelMessageId) FrontendThread }
memberIsEditTypingFrontendHelper time userId threadRoute channel =
    case threadRoute of
        ViewThreadWithMessage threadMessageIndex messageIndex ->
            case SeqDict.get threadMessageIndex channel.threads of
                Just thread ->
                    case DmChannel.getArray messageIndex thread.messages of
                        Just (MessageLoaded (UserTextMessage data)) ->
                            if data.createdBy == userId then
                                { channel
                                    | threads =
                                        SeqDict.insert
                                            threadMessageIndex
                                            { thread
                                                | lastTypedAt =
                                                    SeqDict.insert
                                                        userId
                                                        { time = time, messageIndex = Just messageIndex }
                                                        thread.lastTypedAt
                                            }
                                            channel.threads
                                }
                                    |> Ok

                            else
                                Err ()

                        _ ->
                            Err ()

                Nothing ->
                    Err ()

        NoThreadWithMessage messageIndex ->
            case DmChannel.getArray messageIndex channel.messages of
                Just (MessageLoaded (UserTextMessage data)) ->
                    if data.createdBy == userId then
                        { channel
                            | lastTypedAt =
                                SeqDict.insert userId { time = time, messageIndex = Just messageIndex } channel.lastTypedAt
                        }
                            |> Ok

                    else
                        Err ()

                _ ->
                    Err ()


addInvite :
    SecretId InviteLinkId
    -> Id UserId
    -> Time.Posix
    -> { d | invites : SeqDict (SecretId InviteLinkId) { createdBy : Id UserId, createdAt : Time.Posix } }
    -> { d | invites : SeqDict (SecretId InviteLinkId) { createdBy : Id UserId, createdAt : Time.Posix } }
addInvite inviteId userId time guild =
    { guild | invites = SeqDict.insert inviteId { createdBy = userId, createdAt = time } guild.invites }


addMember : Time.Posix -> Id UserId -> BackendGuild (Id ChannelId) -> Result () (BackendGuild (Id ChannelId))
addMember time userId guild =
    if guild.owner == userId || SeqDict.member userId guild.members then
        Err ()

    else
        { guild
            | members = SeqDict.insert userId { joinedAt = time } guild.members
            , channels =
                SeqDict.updateIfExists
                    (announcementChannel guild)
                    (createChannelMessageBackend (UserJoinedMessage time userId SeqDict.empty))
                    guild.channels
        }
            |> Ok


addMemberFrontend : Time.Posix -> Id UserId -> FrontendGuild (Id ChannelId) -> Result () (FrontendGuild (Id ChannelId))
addMemberFrontend time userId guild =
    if guild.owner == userId || SeqDict.member userId guild.members then
        Err ()

    else
        { guild
            | members = SeqDict.insert userId { joinedAt = time } guild.members
            , channels =
                SeqDict.updateIfExists
                    (announcementChannel guild)
                    (createChannelMessageFrontend (UserJoinedMessage time userId SeqDict.empty))
                    guild.channels
        }
            |> Ok


announcementChannel : { a | channels : SeqDict (Id ChannelId) b } -> Id ChannelId
announcementChannel guild =
    SeqDict.keys guild.channels |> List.head |> Maybe.withDefault (Id.fromInt 0)


allUsers : LocalState -> SeqDict (Id UserId) FrontendUser
allUsers local =
    allUsers2 local.localUser


allUsers2 : LocalUser -> SeqDict (Id UserId) FrontendUser
allUsers2 localUser =
    SeqDict.insert
        localUser.session.userId
        (User.backendToFrontendForUser localUser.user)
        localUser.otherUsers


addReactionEmoji :
    Emoji
    -> Id UserId
    -> ThreadRouteWithMessage
    -> { b | messages : Array (Message ChannelMessageId (Id UserId)), threads : SeqDict (Id ChannelMessageId) Thread }
    -> { b | messages : Array (Message ChannelMessageId (Id UserId)), threads : SeqDict (Id ChannelMessageId) Thread }
addReactionEmoji emoji userId threadRoute channel =
    case threadRoute of
        ViewThreadWithMessage threadId messageId ->
            { channel
                | threads =
                    SeqDict.updateIfExists
                        threadId
                        (\thread ->
                            { thread
                                | messages =
                                    updateArray
                                        messageId
                                        (Message.addReactionEmoji userId emoji)
                                        thread.messages
                            }
                        )
                        channel.threads
            }

        NoThreadWithMessage messageId ->
            { channel
                | messages =
                    updateArray messageId (Message.addReactionEmoji userId emoji) channel.messages
            }


addReactionEmojiFrontend :
    Emoji
    -> userId
    -> ThreadRouteWithMessage
    ->
        { b
            | messages : Array (MessageState ChannelMessageId userId)
            , threads : SeqDict (Id ChannelMessageId) { c | messages : Array (MessageState ThreadMessageId userId) }
        }
    ->
        { b
            | messages : Array (MessageState ChannelMessageId userId)
            , threads : SeqDict (Id ChannelMessageId) { c | messages : Array (MessageState ThreadMessageId userId) }
        }
addReactionEmojiFrontend emoji userId threadRoute channel =
    case threadRoute of
        ViewThreadWithMessage threadId messageId ->
            { channel
                | threads =
                    SeqDict.updateIfExists
                        threadId
                        (\thread ->
                            { thread
                                | messages =
                                    updateArray
                                        messageId
                                        (\message ->
                                            case message of
                                                MessageLoaded message2 ->
                                                    Message.addReactionEmoji userId emoji message2 |> MessageLoaded

                                                MessageUnloaded ->
                                                    message
                                        )
                                        thread.messages
                            }
                        )
                        channel.threads
            }

        NoThreadWithMessage messageId ->
            { channel
                | messages =
                    updateArray
                        messageId
                        (\message ->
                            case message of
                                MessageLoaded message2 ->
                                    Message.addReactionEmoji userId emoji message2 |> MessageLoaded

                                MessageUnloaded ->
                                    message
                        )
                        channel.messages
            }


updateChannel :
    (v -> v)
    -> channelId
    -> { a | channels : SeqDict channelId v }
    -> { a | channels : SeqDict channelId v }
updateChannel updateFunc channelId guild =
    { guild | channels = SeqDict.updateIfExists channelId updateFunc guild.channels }


editMessageHelper :
    Time.Posix
    -> Id UserId
    -> Nonempty (RichText (Id UserId))
    -> SeqDict (Id FileId) FileData
    -> ThreadRouteWithMessage
    -> { b | messages : Array (Message ChannelMessageId (Id UserId)), lastTypedAt : SeqDict (Id UserId) (LastTypedAt ChannelMessageId), threads : SeqDict (Id ChannelMessageId) Thread }
    -> Result () { b | messages : Array (Message ChannelMessageId (Id UserId)), lastTypedAt : SeqDict (Id UserId) (LastTypedAt ChannelMessageId), threads : SeqDict (Id ChannelMessageId) Thread }
editMessageHelper time editedBy newContent attachedFiles threadRoute channel =
    case threadRoute of
        ViewThreadWithMessage threadMessageIndex messageId ->
            case SeqDict.get threadMessageIndex channel.threads of
                Just thread ->
                    case editMessageHelper2 time editedBy newContent attachedFiles messageId thread of
                        Ok thread2 ->
                            Ok { channel | threads = SeqDict.insert threadMessageIndex thread2 channel.threads }

                        Err () ->
                            Err ()

                Nothing ->
                    Err ()

        NoThreadWithMessage messageId ->
            editMessageHelper2 time editedBy newContent attachedFiles messageId channel


editMessageHelper2 :
    Time.Posix
    -> Id UserId
    -> Nonempty (RichText (Id UserId))
    -> SeqDict (Id FileId) FileData
    -> Id messageId
    -> { b | messages : Array (Message messageId (Id UserId)), lastTypedAt : SeqDict (Id UserId) (LastTypedAt messageId) }
    -> Result () { b | messages : Array (Message messageId (Id UserId)), lastTypedAt : SeqDict (Id UserId) (LastTypedAt messageId) }
editMessageHelper2 time editedBy newContent attachedFiles messageIndex channel =
    case DmChannel.getArray messageIndex channel.messages of
        Just (UserTextMessage data) ->
            if data.createdBy == editedBy && data.content /= newContent then
                let
                    data2 : UserTextMessageData messageId (Id UserId)
                    data2 =
                        { data | editedAt = Just time, content = newContent, attachedFiles = attachedFiles }
                in
                { channel
                    | messages = DmChannel.setArray messageIndex (UserTextMessage data2) channel.messages
                    , lastTypedAt =
                        SeqDict.update
                            editedBy
                            (\maybe ->
                                case maybe of
                                    Just a ->
                                        if a.messageIndex == Just messageIndex then
                                            Nothing

                                        else
                                            maybe

                                    Nothing ->
                                        Nothing
                            )
                            channel.lastTypedAt
                }
                    |> Ok

            else
                Err ()

        _ ->
            Err ()


editMessageFrontendHelper :
    Time.Posix
    -> Id UserId
    -> Nonempty (RichText (Id UserId))
    -> SeqDict (Id FileId) FileData
    -> ThreadRouteWithMessage
    -> { b | messages : Array (MessageState ChannelMessageId (Id UserId)), lastTypedAt : SeqDict (Id UserId) (LastTypedAt ChannelMessageId), threads : SeqDict (Id ChannelMessageId) FrontendThread }
    -> Result () { b | messages : Array (MessageState ChannelMessageId (Id UserId)), lastTypedAt : SeqDict (Id UserId) (LastTypedAt ChannelMessageId), threads : SeqDict (Id ChannelMessageId) FrontendThread }
editMessageFrontendHelper time editedBy newContent attachedFiles threadRoute channel =
    case threadRoute of
        ViewThreadWithMessage threadMessageIndex messageId ->
            case SeqDict.get threadMessageIndex channel.threads of
                Just thread ->
                    case editMessageFrontendHelper2 time editedBy newContent attachedFiles messageId thread of
                        Ok thread2 ->
                            Ok { channel | threads = SeqDict.insert threadMessageIndex thread2 channel.threads }

                        Err () ->
                            Err ()

                Nothing ->
                    Err ()

        NoThreadWithMessage messageId ->
            editMessageFrontendHelper2 time editedBy newContent attachedFiles messageId channel


editMessageFrontendHelper2 :
    Time.Posix
    -> Id UserId
    -> Nonempty (RichText (Id UserId))
    -> SeqDict (Id FileId) FileData
    -> Id messageId
    -> { b | messages : Array (MessageState messageId (Id UserId)), lastTypedAt : SeqDict (Id UserId) (LastTypedAt messageId) }
    -> Result () { b | messages : Array (MessageState messageId (Id UserId)), lastTypedAt : SeqDict (Id UserId) (LastTypedAt messageId) }
editMessageFrontendHelper2 time editedBy newContent attachedFiles messageIndex channel =
    case DmChannel.getArray messageIndex channel.messages of
        Just (MessageLoaded (UserTextMessage data)) ->
            if data.createdBy == editedBy && data.content /= newContent then
                let
                    data2 : UserTextMessageData messageId (Id UserId)
                    data2 =
                        { data | editedAt = Just time, content = newContent, attachedFiles = attachedFiles }
                in
                { channel
                    | messages = DmChannel.setArray messageIndex (MessageLoaded (UserTextMessage data2)) channel.messages
                    , lastTypedAt =
                        SeqDict.update
                            editedBy
                            (\maybe ->
                                case maybe of
                                    Just a ->
                                        if a.messageIndex == Just messageIndex then
                                            Nothing

                                        else
                                            maybe

                                    Nothing ->
                                        Nothing
                            )
                            channel.lastTypedAt
                }
                    |> Ok

            else
                Err ()

        _ ->
            Err ()


removeReactionEmoji :
    Emoji
    -> Id UserId
    -> ThreadRouteWithMessage
    -> { b | messages : Array (Message ChannelMessageId (Id UserId)), threads : SeqDict (Id ChannelMessageId) Thread }
    -> { b | messages : Array (Message ChannelMessageId (Id UserId)), threads : SeqDict (Id ChannelMessageId) Thread }
removeReactionEmoji emoji userId threadRoute channel =
    case threadRoute of
        ViewThreadWithMessage threadMessageIndex messageIndex ->
            { channel
                | threads =
                    SeqDict.updateIfExists
                        threadMessageIndex
                        (\thread ->
                            { thread
                                | messages =
                                    updateArray
                                        messageIndex
                                        (Message.removeReactionEmoji userId emoji)
                                        thread.messages
                            }
                        )
                        channel.threads
            }

        NoThreadWithMessage messageIndex ->
            { channel
                | messages =
                    updateArray messageIndex
                        (Message.removeReactionEmoji userId emoji)
                        channel.messages
            }


removeReactionEmojiFrontend :
    Emoji
    -> userId
    -> ThreadRouteWithMessage
    ->
        { b
            | messages : Array (MessageState ChannelMessageId userId)
            , threads : SeqDict (Id ChannelMessageId) { c | messages : Array (MessageState ThreadMessageId userId) }
        }
    ->
        { b
            | messages : Array (MessageState ChannelMessageId userId)
            , threads : SeqDict (Id ChannelMessageId) { c | messages : Array (MessageState ThreadMessageId userId) }
        }
removeReactionEmojiFrontend emoji userId threadRoute channel =
    case threadRoute of
        ViewThreadWithMessage threadMessageIndex messageIndex ->
            { channel
                | threads =
                    SeqDict.updateIfExists
                        threadMessageIndex
                        (\thread ->
                            { thread
                                | messages =
                                    updateArray
                                        messageIndex
                                        (\message ->
                                            case message of
                                                MessageLoaded message2 ->
                                                    Message.removeReactionEmoji userId emoji message2 |> MessageLoaded

                                                MessageUnloaded ->
                                                    message
                                        )
                                        thread.messages
                            }
                        )
                        channel.threads
            }

        NoThreadWithMessage messageIndex ->
            { channel
                | messages =
                    updateArray
                        messageIndex
                        (\message ->
                            case message of
                                MessageLoaded message2 ->
                                    Message.removeReactionEmoji userId emoji message2 |> MessageLoaded

                                MessageUnloaded ->
                                    message
                        )
                        channel.messages
            }


currentDiscordUser : LocalState -> Discord.Id.Id Discord.Id.UserId
currentDiscordUser local =
    Debug.todo ""


markAllChannelsAsViewed :
    Id GuildId
    -> { a | channels : SeqDict (Id ChannelId) { b | messages : Array c } }
    -> { d | lastViewed : SeqDict AnyGuildOrDmIdNoThread (Id ChannelMessageId) }
    -> { d | lastViewed : SeqDict AnyGuildOrDmIdNoThread (Id ChannelMessageId) }
markAllChannelsAsViewed guildId guild user =
    { user
        | lastViewed =
            SeqDict.foldl
                (\channelId channel state ->
                    SeqDict.insert
                        (NormalGuildOrDmId (GuildOrDmId_Guild guildId channelId))
                        (DmChannel.latestMessageId channel)
                        state
                )
                user.lastViewed
                guild.channels
    }


deleteMessageBackend :
    Id UserId
    -> Id ChannelId
    -> ThreadRouteWithMessage
    ->
        { a
            | channels :
                SeqDict
                    (Id ChannelId)
                    { c
                        | messages : Array (Message ChannelMessageId (Id UserId))
                        , threads : SeqDict (Id ChannelMessageId) Thread
                    }
        }
    ->
        Result
            ()
            { a
                | channels :
                    SeqDict
                        (Id ChannelId)
                        { c
                            | messages : Array (Message ChannelMessageId (Id UserId))
                            , threads : SeqDict (Id ChannelMessageId) Thread
                        }
            }
deleteMessageBackend userId channelId threadRoute guild =
    case SeqDict.get channelId guild.channels of
        Just channel ->
            case deleteMessageBackendHelper userId threadRoute channel of
                Ok channel2 ->
                    Ok { guild | channels = SeqDict.insert channelId channel2 guild.channels }

                _ ->
                    Err ()

        Nothing ->
            Err ()


deleteMessageBackendHelper :
    Id UserId
    -> ThreadRouteWithMessage
    ->
        { a
            | messages : Array (Message ChannelMessageId (Id UserId))
            , threads : SeqDict (Id ChannelMessageId) Thread
        }
    ->
        Result
            ()
            { a
                | messages : Array (Message ChannelMessageId (Id UserId))
                , threads : SeqDict (Id ChannelMessageId) Thread
            }
deleteMessageBackendHelper userId threadRoute channel =
    case threadRoute of
        ViewThreadWithMessage threadId messageId ->
            case SeqDict.get threadId channel.threads of
                Just thread ->
                    case DmChannel.getArray messageId thread.messages of
                        Just (UserTextMessage message) ->
                            if message.createdBy == userId then
                                { channel
                                    | threads =
                                        SeqDict.insert
                                            threadId
                                            { thread
                                                | messages = DmChannel.setArray messageId (DeletedMessage message.createdAt) thread.messages
                                            }
                                            channel.threads
                                }
                                    |> Ok

                            else
                                Err ()

                        _ ->
                            Err ()

                Nothing ->
                    Err ()

        NoThreadWithMessage messageId ->
            case DmChannel.getArray messageId channel.messages of
                Just (UserTextMessage message) ->
                    if message.createdBy == userId then
                        { channel | messages = DmChannel.setArray messageId (DeletedMessage message.createdAt) channel.messages }
                            |> Ok

                    else
                        Err ()

                _ ->
                    Err ()


deleteMessageFrontend :
    Id UserId
    -> Id ChannelId
    -> ThreadRouteWithMessage
    ->
        { a
            | channels :
                SeqDict
                    (Id ChannelId)
                    { c
                        | messages : Array (MessageState ChannelMessageId (Id UserId))
                        , threads : SeqDict (Id ChannelMessageId) FrontendThread
                    }
        }
    ->
        { a
            | channels :
                SeqDict
                    (Id ChannelId)
                    { c
                        | messages : Array (MessageState ChannelMessageId (Id UserId))
                        , threads : SeqDict (Id ChannelMessageId) FrontendThread
                    }
        }
deleteMessageFrontend userId channelId threadRoute guild =
    case SeqDict.get channelId guild.channels of
        Just channel ->
            { guild
                | channels =
                    SeqDict.insert
                        channelId
                        (deleteMessageFrontendHelper userId threadRoute channel)
                        guild.channels
            }

        Nothing ->
            guild


deleteMessageFrontendHelper :
    Id UserId
    -> ThreadRouteWithMessage
    ->
        { a
            | messages : Array (MessageState ChannelMessageId (Id UserId))
            , threads : SeqDict (Id ChannelMessageId) FrontendThread
        }
    ->
        { a
            | messages : Array (MessageState ChannelMessageId (Id UserId))
            , threads : SeqDict (Id ChannelMessageId) FrontendThread
        }
deleteMessageFrontendHelper userId threadRoute channel =
    case threadRoute of
        ViewThreadWithMessage threadId messageId ->
            case SeqDict.get threadId channel.threads of
                Just thread ->
                    case DmChannel.getArray messageId thread.messages of
                        Just (MessageLoaded (UserTextMessage message)) ->
                            if message.createdBy == userId then
                                { channel
                                    | threads =
                                        SeqDict.insert
                                            threadId
                                            { thread
                                                | messages =
                                                    DmChannel.setArray
                                                        messageId
                                                        (MessageLoaded (DeletedMessage message.createdAt))
                                                        thread.messages
                                            }
                                            channel.threads
                                }

                            else
                                channel

                        _ ->
                            channel

                Nothing ->
                    channel

        NoThreadWithMessage messageId ->
            case DmChannel.getArray messageId channel.messages of
                Just (MessageLoaded (UserTextMessage message)) ->
                    if message.createdBy == userId then
                        { channel
                            | messages =
                                DmChannel.setArray
                                    messageId
                                    (MessageLoaded (DeletedMessage message.createdAt))
                                    channel.messages
                        }

                    else
                        channel

                _ ->
                    channel


getGuildAndChannel : Id GuildId -> Id ChannelId -> LocalState -> Maybe ( FrontendGuild (Id ChannelId), FrontendChannel )
getGuildAndChannel guildId channelId local =
    case SeqDict.get guildId local.guilds of
        Just guild ->
            case SeqDict.get channelId guild.channels of
                Just channel ->
                    Just ( guild, channel )

                Nothing ->
                    Nothing

        Nothing ->
            Nothing


getDiscordGuildAndChannel : Discord.Id.Id Discord.Id.GuildId -> Discord.Id.Id Discord.Id.ChannelId -> LocalState -> Maybe ( DiscordFrontendGuild, DiscordFrontendChannel )
getDiscordGuildAndChannel guildId channelId local =
    case SeqDict.get guildId local.discordGuilds of
        Just guild ->
            case SeqDict.get channelId guild.channels of
                Just channel ->
                    Just ( guild, channel )

                Nothing ->
                    Nothing

        Nothing ->
            Nothing


usersMentionedOrRepliedToBackend :
    ThreadRouteWithMaybeMessage
    -> Nonempty (RichText userId)
    -> List userId
    ->
        { a
            | threads : SeqDict (Id ChannelMessageId) { b | messages : Array (Message ThreadMessageId userId) }
            , messages : Array (Message ChannelMessageId userId)
        }
    -> SeqSet userId
usersMentionedOrRepliedToBackend threadRouteWithRepliedTo content members channel =
    let
        userIds : SeqSet userId
        userIds =
            (case threadRouteWithRepliedTo of
                ViewThreadWithMaybeMessage threadId maybeRepliedTo ->
                    (case SeqDict.get threadId channel.threads of
                        Just thread ->
                            repliedToUserId maybeRepliedTo thread |> Maybe.Extra.toList

                        Nothing ->
                            []
                    )
                        ++ (case DmChannel.getArray threadId channel.messages of
                                Just (UserTextMessage data) ->
                                    [ data.createdBy ]

                                Just (UserJoinedMessage _ userJoined _) ->
                                    [ userJoined ]

                                Just (DeletedMessage _) ->
                                    []

                                Nothing ->
                                    []
                           )

                NoThreadWithMaybeMessage maybeRepliedTo ->
                    repliedToUserId maybeRepliedTo channel |> Maybe.Extra.toList
            )
                |> List.foldl SeqSet.insert (RichText.mentionsUser content)
    in
    List.foldl
        (\userId validUserIds ->
            if SeqSet.member userId userIds then
                SeqSet.insert userId validUserIds

            else
                validUserIds
        )
        SeqSet.empty
        members


usersMentionedOrRepliedToFrontend :
    ThreadRouteWithMaybeMessage
    -> Nonempty (RichText (Id UserId))
    -> FrontendChannel
    -> SeqSet (Id UserId)
usersMentionedOrRepliedToFrontend threadRouteWithRepliedTo content channel =
    (case threadRouteWithRepliedTo of
        ViewThreadWithMaybeMessage threadId maybeRepliedTo ->
            (case SeqDict.get threadId channel.threads of
                Just thread ->
                    repliedToUserIdFrontend maybeRepliedTo thread |> Maybe.Extra.toList

                Nothing ->
                    []
            )
                ++ (case DmChannel.getArray threadId channel.messages of
                        Just (MessageLoaded message) ->
                            case message of
                                UserTextMessage data ->
                                    [ data.createdBy ]

                                UserJoinedMessage _ userJoined _ ->
                                    [ userJoined ]

                                DeletedMessage _ ->
                                    []

                        _ ->
                            []
                   )

        NoThreadWithMaybeMessage maybeRepliedTo ->
            repliedToUserIdFrontend maybeRepliedTo channel |> Maybe.Extra.toList
    )
        |> List.foldl SeqSet.insert (RichText.mentionsUser content)


repliedToUserId : Maybe (Id messageId) -> { a | messages : Array (Message messageId userId) } -> Maybe userId
repliedToUserId maybeRepliedTo channel =
    case maybeRepliedTo of
        Just repliedTo ->
            case DmChannel.getArray repliedTo channel.messages of
                Just message ->
                    case message of
                        UserTextMessage repliedToData ->
                            Just repliedToData.createdBy

                        UserJoinedMessage _ joinedUser _ ->
                            Just joinedUser

                        DeletedMessage _ ->
                            Nothing

                Nothing ->
                    Nothing

        Nothing ->
            Nothing


repliedToUserIdFrontend : Maybe (Id messageId) -> { a | messages : Array (MessageState messageId (Id UserId)) } -> Maybe (Id UserId)
repliedToUserIdFrontend maybeRepliedTo channel =
    case maybeRepliedTo of
        Just repliedTo ->
            case DmChannel.getArray repliedTo channel.messages of
                Just (MessageLoaded message) ->
                    case message of
                        UserTextMessage repliedToData ->
                            Just repliedToData.createdBy

                        UserJoinedMessage _ joinedUser _ ->
                            Just joinedUser

                        DeletedMessage _ ->
                            Nothing

                _ ->
                    Nothing

        Nothing ->
            Nothing
