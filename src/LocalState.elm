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
    , DiscordMessageAlreadyExists(..)
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
    , allDiscordUsers2
    , allUsers
    , allUsers2
    , announcementChannel
    , createChannel
    , createChannelFrontend
    , createChannelMessageBackend
    , createChannelMessageFrontend
    , createDiscordChannelMessageBackend
    , createDiscordMessageBackend
    , createDiscordThreadMessageBackend
    , createGuild
    , createThreadMessageBackend
    , createThreadMessageFrontend
    , deleteChannel
    , deleteChannelFrontend
    , deleteMessageBackend
    , deleteMessageBackendHelper
    , deleteMessageFrontend
    , deleteMessageFrontendHelper
    , discordAnnouncementChannel
    , discordGuildToFrontendForUser
    , editChannel
    , editMessageFrontendHelper
    , editMessageHelper
    , getDiscordGuildAndChannel
    , getDiscordUser
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
import DiscordDmChannelId exposing (DiscordDmChannelId)
import DmChannel exposing (FrontendDiscordDmChannel, FrontendDmChannel)
import Duration
import Effect.Time as Time
import Emoji exposing (Emoji)
import FileStatus exposing (FileData, FileHash, FileId)
import GuildName exposing (GuildName)
import Id exposing (AnyGuildOrDmId(..), ChannelId, ChannelMessageId, DiscordGuildOrDmId(..), GuildId, GuildOrDmId(..), Id, InviteLinkId, ThreadMessageId, ThreadRoute(..), ThreadRouteWithMaybeMessage(..), ThreadRouteWithMessage(..), UserId)
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
import Thread exposing (BackendThread, DiscordBackendThread, DiscordFrontendThread, FrontendGenericThread, FrontendThread, LastTypedAt)
import UInt64
import Unsafe
import User exposing (BackendUser, DiscordFrontendCurrentUser, DiscordFrontendUser, FrontendCurrentUser, FrontendUser)
import UserAgent exposing (UserAgent)
import UserSession exposing (FrontendUserSession, UserSession)
import VisibleMessages exposing (VisibleMessages)


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict (Id GuildId) FrontendGuild
    , discordGuilds : SeqDict (Discord.Id.Id Discord.Id.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict (Id UserId) FrontendDmChannel
    , discordDmChannels : SeqDict DiscordDmChannelId FrontendDiscordDmChannel
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
    , otherDiscordUsers : SeqDict (Discord.Id.Id Discord.Id.UserId) DiscordFrontendUser
    , linkedDiscordUsers : SeqDict (Discord.Id.Id Discord.Id.UserId) DiscordFrontendCurrentUser
    , -- This data is redundant as it already exists in FrontendLoading and FrontendLoaded. We need it here anyway to reduce the number of parameters passed into messageView so lazy rendering is possible.
      timezone : Time.Zone
    , userAgent : UserAgent
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias BackendGuild =
    { createdAt : Time.Posix
    , createdBy : Id UserId
    , name : GuildName
    , icon : Maybe FileHash
    , channels : SeqDict (Id ChannelId) BackendChannel
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


type alias FrontendGuild =
    { createdAt : Time.Posix
    , createdBy : Id UserId
    , name : GuildName
    , icon : Maybe FileHash
    , channels : SeqDict (Id ChannelId) FrontendChannel
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


guildToFrontendForUser : Maybe ( Id ChannelId, ThreadRoute ) -> Id UserId -> BackendGuild -> Maybe FrontendGuild
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


guildToFrontend : Maybe ( Id ChannelId, ThreadRoute ) -> BackendGuild -> FrontendGuild
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
    , threads : SeqDict (Id ChannelMessageId) BackendThread
    }


type alias DiscordBackendChannel =
    { name : ChannelName
    , messages : Array (Message ChannelMessageId (Discord.Id.Id Discord.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict (Discord.Id.Id Discord.Id.UserId) (LastTypedAt ChannelMessageId)
    , linkedMessageIds : OneToOne (Discord.Id.Id Discord.Id.MessageId) (Id ChannelMessageId)
    , threads : SeqDict (Id ChannelMessageId) DiscordBackendThread
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


getDiscordUser : Discord.Id.Id Discord.Id.UserId -> LocalUser -> Maybe DiscordFrontendUser
getDiscordUser userId localUser =
    case SeqDict.get userId localUser.linkedDiscordUsers of
        Just user ->
            User.discordCurrentUserToFrontend user |> Just

        Nothing ->
            SeqDict.get userId localUser.otherDiscordUsers


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
                    Maybe.withDefault Thread.backendInit maybe
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


type DiscordMessageAlreadyExists
    = DiscordMessageAlreadyExists


createDiscordChannelMessageBackend :
    Discord.Id.Id Discord.Id.MessageId
    -> Message ChannelMessageId (Discord.Id.Id Discord.Id.UserId)
    -> DiscordBackendChannel
    -> Result DiscordMessageAlreadyExists DiscordBackendChannel
createDiscordChannelMessageBackend messageId message channel =
    createDiscordMessageBackend messageId message channel


createDiscordThreadMessageBackend :
    Discord.Id.Id Discord.Id.MessageId
    -> Id ChannelMessageId
    -> Message ThreadMessageId (Discord.Id.Id Discord.Id.UserId)
    -> DiscordBackendChannel
    -> Result DiscordMessageAlreadyExists DiscordBackendChannel
createDiscordThreadMessageBackend messageId threadId message channel =
    let
        thread : DiscordBackendThread
        thread =
            SeqDict.get threadId channel.threads |> Maybe.withDefault Thread.discordBackendInit
    in
    case createDiscordMessageBackend messageId message thread of
        Ok thread2 ->
            Ok { channel | threads = SeqDict.insert threadId thread2 channel.threads }

        Err err ->
            Err err


createDiscordMessageBackend :
    Discord.Id.Id Discord.Id.MessageId
    -> Message messageId (Discord.Id.Id Discord.Id.UserId)
    ->
        { d
            | messages : Array (Message messageId (Discord.Id.Id Discord.Id.UserId))
            , lastTypedAt : SeqDict (Discord.Id.Id Discord.Id.UserId) (LastTypedAt messageId)
            , linkedMessageIds : OneToOne (Discord.Id.Id Discord.Id.MessageId) (Id messageId)
        }
    ->
        Result
            DiscordMessageAlreadyExists
            { d
                | messages : Array (Message messageId (Discord.Id.Id Discord.Id.UserId))
                , lastTypedAt : SeqDict (Discord.Id.Id Discord.Id.UserId) (LastTypedAt messageId)
                , linkedMessageIds : OneToOne (Discord.Id.Id Discord.Id.MessageId) (Id messageId)
            }
createDiscordMessageBackend messageId message channel =
    if OneToOne.memberFirst messageId channel.linkedMessageIds then
        Err DiscordMessageAlreadyExists

    else
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
            , linkedMessageIds = OneToOne.insert messageId previousIndex channel.linkedMessageIds
        }
            |> Ok


createThreadMessageFrontend :
    Id ChannelMessageId
    -> Message ThreadMessageId userId
    ->
        { d
            | messages : Array (MessageState ChannelMessageId userId)
            , visibleMessages : VisibleMessages ChannelMessageId
            , lastTypedAt : SeqDict userId (LastTypedAt ChannelMessageId)
            , threads : SeqDict (Id ChannelMessageId) (FrontendGenericThread userId)
        }
    ->
        { d
            | messages : Array (MessageState ChannelMessageId userId)
            , visibleMessages : VisibleMessages ChannelMessageId
            , lastTypedAt : SeqDict userId (LastTypedAt ChannelMessageId)
            , threads : SeqDict (Id ChannelMessageId) (FrontendGenericThread userId)
        }
createThreadMessageFrontend threadId message channel =
    { channel
        | threads =
            SeqDict.update
                threadId
                (\maybe ->
                    Maybe.withDefault Thread.frontendInit maybe
                        |> createMessageFrontend message
                        |> Just
                )
                channel.threads
    }


createChannelMessageFrontend :
    Message ChannelMessageId userId
    ->
        { d
            | messages : Array (MessageState ChannelMessageId userId)
            , visibleMessages : VisibleMessages ChannelMessageId
            , lastTypedAt : SeqDict userId (LastTypedAt ChannelMessageId)
        }
    ->
        { d
            | messages : Array (MessageState ChannelMessageId userId)
            , visibleMessages : VisibleMessages ChannelMessageId
            , lastTypedAt : SeqDict userId (LastTypedAt ChannelMessageId)
        }
createChannelMessageFrontend message channel =
    createMessageFrontend message channel


createMessageFrontend :
    Message messageId userId
    ->
        { d
            | messages : Array (MessageState messageId userId)
            , visibleMessages : VisibleMessages messageId
            , lastTypedAt : SeqDict userId (LastTypedAt messageId)
        }
    ->
        { d
            | messages : Array (MessageState messageId userId)
            , visibleMessages : VisibleMessages messageId
            , lastTypedAt : SeqDict userId (LastTypedAt messageId)
        }
createMessageFrontend message channel =
    let
        previousIndex : Id messageId
        previousIndex =
            Array.length channel.messages - 1 |> Id.fromInt

        mergeWithPrevious : Maybe (Message messageId userId)
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


createGuild : Time.Posix -> Id UserId -> GuildName -> BackendGuild
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


createChannel : Time.Posix -> Id UserId -> ChannelName -> BackendGuild -> BackendGuild
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


createChannelFrontend : Time.Posix -> Id UserId -> ChannelName -> FrontendGuild -> FrontendGuild
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


deleteChannel : Time.Posix -> Id UserId -> Id ChannelId -> BackendGuild -> BackendGuild
deleteChannel time userId channelId guild =
    updateChannel
        (\channel -> { channel | status = ChannelDeleted { deletedAt = time, deletedBy = userId } })
        channelId
        guild


deleteChannelFrontend : Id ChannelId -> FrontendGuild -> FrontendGuild
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
                        , threads : SeqDict (Id ChannelMessageId) BackendThread
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
                            , threads : SeqDict (Id ChannelMessageId) BackendThread
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
    -> { a | messages : Array (Message ChannelMessageId (Id UserId)), lastTypedAt : SeqDict (Id UserId) (LastTypedAt ChannelMessageId), threads : SeqDict (Id ChannelMessageId) BackendThread }
    -> Result () { a | messages : Array (Message ChannelMessageId (Id UserId)), lastTypedAt : SeqDict (Id UserId) (LastTypedAt ChannelMessageId), threads : SeqDict (Id ChannelMessageId) BackendThread }
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


addMember : Time.Posix -> Id UserId -> BackendGuild -> Result () BackendGuild
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


addMemberFrontend : Time.Posix -> Id UserId -> FrontendGuild -> Result () FrontendGuild
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


discordAnnouncementChannel :
    { a | channels : SeqDict (Discord.Id.Id Discord.Id.ChannelId) b }
    -> Discord.Id.Id Discord.Id.ChannelId
discordAnnouncementChannel guild =
    SeqDict.keys guild.channels |> List.head |> Maybe.withDefault (Discord.Id.fromUInt64 (UInt64.fromInt 0))


allUsers : LocalState -> SeqDict (Id UserId) FrontendUser
allUsers local =
    allUsers2 local.localUser


allUsers2 : LocalUser -> SeqDict (Id UserId) FrontendUser
allUsers2 localUser =
    SeqDict.insert
        localUser.session.userId
        (User.backendToFrontendForUser localUser.user)
        localUser.otherUsers


allDiscordUsers2 : LocalUser -> SeqDict (Discord.Id.Id Discord.Id.UserId) DiscordFrontendUser
allDiscordUsers2 localUser =
    SeqDict.union
        (SeqDict.map (\_ user -> User.discordCurrentUserToFrontend user) localUser.linkedDiscordUsers)
        localUser.otherDiscordUsers


addReactionEmoji :
    Emoji
    -> Id UserId
    -> ThreadRouteWithMessage
    -> { b | messages : Array (Message ChannelMessageId (Id UserId)), threads : SeqDict (Id ChannelMessageId) BackendThread }
    -> { b | messages : Array (Message ChannelMessageId (Id UserId)), threads : SeqDict (Id ChannelMessageId) BackendThread }
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
    -> { b | messages : Array (Message ChannelMessageId (Id UserId)), lastTypedAt : SeqDict (Id UserId) (LastTypedAt ChannelMessageId), threads : SeqDict (Id ChannelMessageId) BackendThread }
    -> Result () { b | messages : Array (Message ChannelMessageId (Id UserId)), lastTypedAt : SeqDict (Id UserId) (LastTypedAt ChannelMessageId), threads : SeqDict (Id ChannelMessageId) BackendThread }
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
    -> { b | messages : Array (Message ChannelMessageId (Id UserId)), threads : SeqDict (Id ChannelMessageId) BackendThread }
    -> { b | messages : Array (Message ChannelMessageId (Id UserId)), threads : SeqDict (Id ChannelMessageId) BackendThread }
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



--
--currentDiscordUser : LocalUser -> Maybe (Discord.Id.Id Discord.Id.UserId)
--currentDiscordUser local =
--    case local.session.currentlyViewing of
--        Just ( DiscordGuildOrDmId viewing, _ ) ->
--            case viewing of
--                DiscordGuildOrDmId_Guild currentDiscordUserId _ _ ->
--                    Just currentDiscordUserId
--
--                DiscordGuildOrDmId_Dm dmChannelId ->
--                    let
--                        ( userIdA, userIdB ) =
--                            DiscordDmChannelId.toUserIds dmChannelId
--                    in
--                    case SeqDict.get userIdA local.linkedDiscordUsers of
--                        Just userA ->
--                            Just userIdA
--
--                        Nothing ->
--                            case SeqDict.get userIdA local.linkedDiscordUsers of
--                                Just userB ->
--                                    Just userIdB
--
--                                Nothing ->
--                                    Nothing
--
--        _ ->
--            Nothing
--


markAllChannelsAsViewed :
    Id GuildId
    -> { a | channels : SeqDict (Id ChannelId) { b | messages : Array c } }
    -> { d | lastViewed : SeqDict AnyGuildOrDmId (Id ChannelMessageId) }
    -> { d | lastViewed : SeqDict AnyGuildOrDmId (Id ChannelMessageId) }
markAllChannelsAsViewed guildId guild user =
    { user
        | lastViewed =
            SeqDict.foldl
                (\channelId channel state ->
                    SeqDict.insert
                        (GuildOrDmId (GuildOrDmId_Guild guildId channelId))
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
                        , threads : SeqDict (Id ChannelMessageId) BackendThread
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
                            , threads : SeqDict (Id ChannelMessageId) BackendThread
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
            , threads : SeqDict (Id ChannelMessageId) BackendThread
        }
    ->
        Result
            ()
            { a
                | messages : Array (Message ChannelMessageId (Id UserId))
                , threads : SeqDict (Id ChannelMessageId) BackendThread
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


getGuildAndChannel : Id GuildId -> Id ChannelId -> LocalState -> Maybe ( FrontendGuild, FrontendChannel )
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


getDiscordGuildAndChannel :
    Discord.Id.Id Discord.Id.GuildId
    -> Discord.Id.Id Discord.Id.ChannelId
    -> LocalState
    -> Maybe ( DiscordFrontendGuild, DiscordFrontendChannel )
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
    -> Nonempty (RichText userId)
    ->
        { a
            | messages : Array (MessageState ChannelMessageId userId)
            , threads : SeqDict (Id ChannelMessageId) (FrontendGenericThread userId)
        }
    -> SeqSet userId
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


repliedToUserIdFrontend : Maybe (Id messageId) -> { a | messages : Array (MessageState messageId userId) } -> Maybe userId
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
