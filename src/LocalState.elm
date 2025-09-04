module LocalState exposing
    ( AdminData
    , AdminStatus(..)
    , Archived
    , BackendChannel
    , BackendGuild
    , ChannelStatus(..)
    , DiscordBotToken(..)
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
    , createNewUser
    , createThreadMessageBackend
    , createThreadMessageFrontend
    , deleteChannel
    , deleteChannelFrontend
    , deleteMessageBackend
    , deleteMessageBackendHelper
    , deleteMessageFrontend
    , deleteMessageFrontendHelper
    , editChannel
    , editMessageFrontendHelper
    , editMessageHelper
    , getGuildAndChannel
    , getUser
    , guildToFrontend
    , guildToFrontendForUser
    , linkedChannel
    , markAllChannelsAsViewed
    , memberIsEditTyping
    , memberIsEditTypingFrontend
    , memberIsEditTypingFrontendHelper
    , memberIsEditTypingHelper
    , memberIsTyping
    , removeReactionEmoji
    , removeReactionEmojiFrontend
    , repliedToUserIdFrontend
    , updateArray
    , updateChannel
    , usersToNotify
    , usersToNotifyFrontend
    )

import Array exposing (Array)
import Array.Extra
import ChannelName exposing (ChannelName)
import Discord.Id
import DmChannel exposing (DmChannel, FrontendDmChannel, FrontendThread, LastTypedAt, Thread)
import Duration
import Effect.Time as Time
import Emoji exposing (Emoji)
import FileStatus exposing (FileData, FileHash, FileId)
import GuildName exposing (GuildName)
import Id exposing (ChannelId, ChannelMessageId, GuildId, GuildOrDmId, GuildOrDmIdNoThread(..), Id, InviteLinkId, ThreadMessageId, ThreadRoute(..), ThreadRouteWithMaybeMessage(..), ThreadRouteWithMessage(..), UserId)
import List.Nonempty exposing (Nonempty)
import Log exposing (Log)
import Message exposing (Message(..), MessageState(..), UserTextMessageData)
import NonemptyDict exposing (NonemptyDict)
import OneToOne exposing (OneToOne)
import PersonName exposing (PersonName)
import Quantity
import RichText exposing (RichText(..))
import SecretId exposing (SecretId)
import SeqDict exposing (SeqDict)
import SeqSet exposing (SeqSet)
import Slack
import Unsafe
import User exposing (BackendUser, EmailNotifications(..), EmailStatus, FrontendUser)


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict (Id GuildId) FrontendGuild
    , dmChannels : SeqDict (Id UserId) FrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , publicVapidKey : String
    }


type alias LocalUser =
    { userId : Id UserId
    , user : BackendUser
    , otherUsers : SeqDict (Id UserId) FrontendUser
    , -- This data is redundant as it already exists in FrontendLoading and FrontendLoaded. We need it here anyway to reduce the number of parameters passed into messageView so lazy rendering is possible.
      timezone : Time.Zone
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
    , linkedChannelIds : OneToOne (Discord.Id.Id Discord.Id.ChannelId) (Id ChannelId)
    , members : SeqDict (Id UserId) { joinedAt : Time.Posix }
    , owner : Id UserId
    , invites : SeqDict (SecretId InviteLinkId) { createdAt : Time.Posix, createdBy : Id UserId }
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
    , messages : Array (Message ChannelMessageId)
    , status : ChannelStatus
    , lastTypedAt : SeqDict (Id UserId) (LastTypedAt ChannelMessageId)
    , linkedMessageIds : OneToOne (Discord.Id.Id Discord.Id.MessageId) (Id ChannelMessageId)
    , threads : SeqDict (Id ChannelMessageId) Thread
    , linkedThreadIds : OneToOne (Discord.Id.Id Discord.Id.ChannelId) (Id ChannelMessageId)
    }


type alias FrontendChannel =
    { createdAt : Time.Posix
    , createdBy : Id UserId
    , name : ChannelName
    , messages : Array (MessageState ChannelMessageId)
    , oldestVisibleMessage : Id ChannelMessageId
    , newestVisibleMessage : Id ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict (Id UserId) (LastTypedAt ChannelMessageId)
    , threads : SeqDict (Id ChannelMessageId) FrontendThread
    }


channelToFrontend : Maybe ThreadRoute -> BackendChannel -> Maybe FrontendChannel
channelToFrontend threadRoute channel =
    case channel.status of
        ChannelActive ->
            { createdAt = channel.createdAt
            , createdBy = channel.createdBy
            , name = channel.name
            , messages = DmChannel.toFrontendHelper (Just NoThread == threadRoute) channel
            , oldestVisibleMessage = Array.length channel.messages - DmChannel.pageSize - 1 |> Id.fromInt
            , newestVisibleMessage = DmChannel.latestMessageId channel
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
    , botToken : Maybe DiscordBotToken
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Slack.ClientSecret
    }


type PrivateVapidKey
    = PrivateVapidKey String


type DiscordBotToken
    = DiscordBotToken String


createNewUser : Time.Posix -> PersonName -> EmailStatus -> Bool -> BackendUser
createNewUser createdAt name email userIsAdmin =
    { name = name
    , isAdmin = userIsAdmin
    , email = email
    , recentLoginEmails = []
    , lastLogPageViewed = 0
    , expandedSections = SeqSet.empty
    , createdAt = createdAt
    , emailNotifications = CheckEvery5Minutes
    , lastEmailNotification = createdAt
    , lastViewed = SeqDict.empty
    , lastViewedThreads = SeqDict.empty
    , lastChannelViewed = SeqDict.empty
    , icon = Nothing
    }



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
    if localUser.userId == userId then
        User.backendToFrontend localUser.user |> Just

    else
        SeqDict.get userId localUser.otherUsers


createThreadMessageBackend :
    Maybe ( Discord.Id.Id Discord.Id.MessageId, Discord.Id.Id Discord.Id.ChannelId )
    -> Id ChannelMessageId
    -> Message ThreadMessageId
    -> BackendChannel
    -> BackendChannel
createThreadMessageBackend maybeDiscordMessageId threadId message channel =
    { channel
        | threads =
            SeqDict.update
                threadId
                (\maybe ->
                    Maybe.withDefault DmChannel.threadInit maybe
                        |> createMessageBackend (Maybe.map Tuple.first maybeDiscordMessageId) message
                        |> Just
                )
                channel.threads
        , linkedThreadIds =
            case maybeDiscordMessageId of
                Just ( _, discordChannelId ) ->
                    OneToOne.insert discordChannelId threadId channel.linkedThreadIds

                Nothing ->
                    channel.linkedThreadIds
    }


createChannelMessageBackend :
    Maybe (Discord.Id.Id Discord.Id.MessageId)
    -> Message ChannelMessageId
    ->
        { d
            | messages : Array (Message ChannelMessageId)
            , lastTypedAt : SeqDict (Id UserId) (LastTypedAt ChannelMessageId)
            , linkedMessageIds : OneToOne (Discord.Id.Id Discord.Id.MessageId) (Id ChannelMessageId)
        }
    ->
        { d
            | messages : Array (Message ChannelMessageId)
            , lastTypedAt : SeqDict (Id UserId) (LastTypedAt ChannelMessageId)
            , linkedMessageIds : OneToOne (Discord.Id.Id Discord.Id.MessageId) (Id ChannelMessageId)
        }
createChannelMessageBackend maybeDiscordMessageId message channel =
    createMessageBackend maybeDiscordMessageId message channel


createMessageBackend :
    Maybe (Discord.Id.Id Discord.Id.MessageId)
    -> Message messageId
    ->
        { d
            | messages : Array (Message messageId)
            , lastTypedAt : SeqDict (Id UserId) (LastTypedAt messageId)
            , linkedMessageIds : OneToOne (Discord.Id.Id Discord.Id.MessageId) (Id messageId)
        }
    ->
        { d
            | messages : Array (Message messageId)
            , lastTypedAt : SeqDict (Id UserId) (LastTypedAt messageId)
            , linkedMessageIds : OneToOne (Discord.Id.Id Discord.Id.MessageId) (Id messageId)
        }
createMessageBackend maybeDiscordMessageId message channel =
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
        , linkedMessageIds =
            case maybeDiscordMessageId of
                Just discordMessageId ->
                    OneToOne.insert
                        discordMessageId
                        (Array.length channel.messages |> Id.fromInt)
                        channel.linkedMessageIds

                Nothing ->
                    channel.linkedMessageIds
    }


createThreadMessageFrontend :
    Id ChannelMessageId
    -> Message ThreadMessageId
    ->
        { d
            | messages : Array (MessageState ChannelMessageId)
            , oldestVisibleMessage : Id ChannelMessageId
            , newestVisibleMessage : Id ChannelMessageId
            , lastTypedAt : SeqDict (Id UserId) (LastTypedAt ChannelMessageId)
            , threads : SeqDict (Id ChannelMessageId) FrontendThread
        }
    ->
        { d
            | messages : Array (MessageState ChannelMessageId)
            , oldestVisibleMessage : Id ChannelMessageId
            , newestVisibleMessage : Id ChannelMessageId
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
    Message ChannelMessageId
    ->
        { d
            | messages : Array (MessageState ChannelMessageId)
            , oldestVisibleMessage : Id ChannelMessageId
            , newestVisibleMessage : Id ChannelMessageId
            , lastTypedAt : SeqDict (Id UserId) (LastTypedAt ChannelMessageId)
        }
    ->
        { d
            | messages : Array (MessageState ChannelMessageId)
            , oldestVisibleMessage : Id ChannelMessageId
            , newestVisibleMessage : Id ChannelMessageId
            , lastTypedAt : SeqDict (Id UserId) (LastTypedAt ChannelMessageId)
        }
createChannelMessageFrontend message channel =
    createMessageFrontend message channel


createMessageFrontend :
    Message messageId
    ->
        { d
            | messages : Array (MessageState messageId)
            , oldestVisibleMessage : Id messageId
            , newestVisibleMessage : Id messageId
            , lastTypedAt : SeqDict (Id UserId) (LastTypedAt messageId)
        }
    ->
        { d
            | messages : Array (MessageState messageId)
            , oldestVisibleMessage : Id messageId
            , newestVisibleMessage : Id messageId
            , lastTypedAt : SeqDict (Id UserId) (LastTypedAt messageId)
        }
createMessageFrontend message channel =
    let
        previousIndex : Id messageId
        previousIndex =
            Array.length channel.messages - 1 |> Id.fromInt

        mergeWithPrevious : Maybe (Message messageId)
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
        , oldestVisibleMessage = channel.oldestVisibleMessage
        , newestVisibleMessage =
            case ( mergeWithPrevious, Id.toInt channel.newestVisibleMessage == (Array.length channel.messages - 1) ) of
                ( Nothing, True ) ->
                    Id.increment channel.newestVisibleMessage

                _ ->
                    channel.newestVisibleMessage
        , lastTypedAt =
            case message of
                UserTextMessage { createdBy } ->
                    SeqDict.remove createdBy channel.lastTypedAt

                UserJoinedMessage _ _ _ ->
                    channel.lastTypedAt

                DeletedMessage _ ->
                    channel.lastTypedAt
    }


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
                , linkedMessageIds = OneToOne.empty
                , threads = SeqDict.empty
                , linkedThreadIds = OneToOne.empty
                }
              )
            ]
    , linkedChannelIds = OneToOne.empty
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
                , linkedMessageIds = OneToOne.empty
                , threads = SeqDict.empty
                , linkedThreadIds = OneToOne.empty
                }
                guild.channels
    }


linkedChannel : Discord.Id.Id Discord.Id.ChannelId -> BackendGuild -> Maybe ( Id ChannelId, BackendChannel )
linkedChannel discordChannelId guild =
    case OneToOne.second discordChannelId guild.linkedChannelIds of
        Just channelId ->
            case SeqDict.get channelId guild.channels of
                Just channel ->
                    Just ( channelId, channel )

                Nothing ->
                    Nothing

        Nothing ->
            Nothing


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
                , oldestVisibleMessage = Id.fromInt 0
                , newestVisibleMessage = Id.fromInt 0
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
    Id UserId
    -> Time.Posix
    -> ThreadRoute
    ->
        { e
            | lastTypedAt : SeqDict (Id UserId) (LastTypedAt ChannelMessageId)
            , threads : SeqDict (Id ChannelMessageId) { f | lastTypedAt : SeqDict (Id UserId) (LastTypedAt ThreadMessageId) }
        }
    ->
        { e
            | lastTypedAt : SeqDict (Id UserId) (LastTypedAt ChannelMessageId)
            , threads : SeqDict (Id ChannelMessageId) { f | lastTypedAt : SeqDict (Id UserId) (LastTypedAt ThreadMessageId) }
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
                        | messages : Array (Message ChannelMessageId)
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
                            | messages : Array (Message ChannelMessageId)
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
                        | messages : Array (MessageState ChannelMessageId)
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
                            | messages : Array (MessageState ChannelMessageId)
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
    -> { a | messages : Array (Message ChannelMessageId), lastTypedAt : SeqDict (Id UserId) (LastTypedAt ChannelMessageId), threads : SeqDict (Id ChannelMessageId) Thread }
    -> Result () { a | messages : Array (Message ChannelMessageId), lastTypedAt : SeqDict (Id UserId) (LastTypedAt ChannelMessageId), threads : SeqDict (Id ChannelMessageId) Thread }
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
    -> { a | messages : Array (MessageState ChannelMessageId), lastTypedAt : SeqDict (Id UserId) (LastTypedAt ChannelMessageId), threads : SeqDict (Id ChannelMessageId) FrontendThread }
    -> Result () { a | messages : Array (MessageState ChannelMessageId), lastTypedAt : SeqDict (Id UserId) (LastTypedAt ChannelMessageId), threads : SeqDict (Id ChannelMessageId) FrontendThread }
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
                    (createChannelMessageBackend Nothing (UserJoinedMessage time userId SeqDict.empty))
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


allUsers : LocalState -> SeqDict (Id UserId) FrontendUser
allUsers local =
    allUsers2 local.localUser


allUsers2 : LocalUser -> SeqDict (Id UserId) FrontendUser
allUsers2 localUser =
    SeqDict.insert
        localUser.userId
        (User.backendToFrontendForUser localUser.user)
        localUser.otherUsers


addReactionEmoji :
    Emoji
    -> Id UserId
    -> ThreadRouteWithMessage
    -> { b | messages : Array (Message ChannelMessageId), threads : SeqDict (Id ChannelMessageId) Thread }
    -> { b | messages : Array (Message ChannelMessageId), threads : SeqDict (Id ChannelMessageId) Thread }
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
    -> Id UserId
    -> ThreadRouteWithMessage
    -> { b | messages : Array (MessageState ChannelMessageId), threads : SeqDict (Id ChannelMessageId) FrontendThread }
    -> { b | messages : Array (MessageState ChannelMessageId), threads : SeqDict (Id ChannelMessageId) FrontendThread }
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
    -> Id ChannelId
    -> { a | channels : SeqDict (Id ChannelId) v }
    -> { a | channels : SeqDict (Id ChannelId) v }
updateChannel updateFunc channelId guild =
    { guild | channels = SeqDict.updateIfExists channelId updateFunc guild.channels }


editMessageHelper :
    Time.Posix
    -> Id UserId
    -> Nonempty RichText
    -> SeqDict (Id FileId) FileData
    -> ThreadRouteWithMessage
    -> { b | messages : Array (Message ChannelMessageId), lastTypedAt : SeqDict (Id UserId) (LastTypedAt ChannelMessageId), threads : SeqDict (Id ChannelMessageId) Thread }
    -> Result () { b | messages : Array (Message ChannelMessageId), lastTypedAt : SeqDict (Id UserId) (LastTypedAt ChannelMessageId), threads : SeqDict (Id ChannelMessageId) Thread }
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
    -> Nonempty RichText
    -> SeqDict (Id FileId) FileData
    -> Id messageId
    -> { b | messages : Array (Message messageId), lastTypedAt : SeqDict (Id UserId) (LastTypedAt messageId) }
    -> Result () { b | messages : Array (Message messageId), lastTypedAt : SeqDict (Id UserId) (LastTypedAt messageId) }
editMessageHelper2 time editedBy newContent attachedFiles messageIndex channel =
    case DmChannel.getArray messageIndex channel.messages of
        Just (UserTextMessage data) ->
            if data.createdBy == editedBy && data.content /= newContent then
                let
                    data2 : UserTextMessageData messageId
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
    -> Nonempty RichText
    -> SeqDict (Id FileId) FileData
    -> ThreadRouteWithMessage
    -> { b | messages : Array (MessageState ChannelMessageId), lastTypedAt : SeqDict (Id UserId) (LastTypedAt ChannelMessageId), threads : SeqDict (Id ChannelMessageId) FrontendThread }
    -> Result () { b | messages : Array (MessageState ChannelMessageId), lastTypedAt : SeqDict (Id UserId) (LastTypedAt ChannelMessageId), threads : SeqDict (Id ChannelMessageId) FrontendThread }
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
    -> Nonempty RichText
    -> SeqDict (Id FileId) FileData
    -> Id messageId
    -> { b | messages : Array (MessageState messageId), lastTypedAt : SeqDict (Id UserId) (LastTypedAt messageId) }
    -> Result () { b | messages : Array (MessageState messageId), lastTypedAt : SeqDict (Id UserId) (LastTypedAt messageId) }
editMessageFrontendHelper2 time editedBy newContent attachedFiles messageIndex channel =
    case DmChannel.getArray messageIndex channel.messages of
        Just (MessageLoaded (UserTextMessage data)) ->
            if data.createdBy == editedBy && data.content /= newContent then
                let
                    data2 : UserTextMessageData messageId
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
    -> { b | messages : Array (Message ChannelMessageId), threads : SeqDict (Id ChannelMessageId) Thread }
    -> { b | messages : Array (Message ChannelMessageId), threads : SeqDict (Id ChannelMessageId) Thread }
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
    -> Id UserId
    -> ThreadRouteWithMessage
    -> { b | messages : Array (MessageState ChannelMessageId), threads : SeqDict (Id ChannelMessageId) FrontendThread }
    -> { b | messages : Array (MessageState ChannelMessageId), threads : SeqDict (Id ChannelMessageId) FrontendThread }
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


markAllChannelsAsViewed :
    Id GuildId
    -> { a | channels : SeqDict (Id ChannelId) { b | messages : Array c } }
    -> BackendUser
    -> BackendUser
markAllChannelsAsViewed guildId guild user =
    { user
        | lastViewed =
            SeqDict.foldl
                (\channelId channel state ->
                    SeqDict.insert
                        (GuildOrDmId_Guild_NoThread guildId channelId)
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
                        | messages : Array (Message ChannelMessageId)
                        , threads : SeqDict (Id ChannelMessageId) Thread
                        , linkedMessageIds : OneToOne (Discord.Id.Id Discord.Id.MessageId) (Id ChannelMessageId)
                    }
        }
    ->
        Result
            ()
            ( Maybe (Discord.Id.Id Discord.Id.MessageId)
            , { a
                | channels :
                    SeqDict
                        (Id ChannelId)
                        { c
                            | messages : Array (Message ChannelMessageId)
                            , threads : SeqDict (Id ChannelMessageId) Thread
                            , linkedMessageIds : OneToOne (Discord.Id.Id Discord.Id.MessageId) (Id ChannelMessageId)
                        }
              }
            )
deleteMessageBackend userId channelId threadRoute guild =
    case SeqDict.get channelId guild.channels of
        Just channel ->
            case deleteMessageBackendHelper userId threadRoute channel of
                Ok ( maybeDiscordId, channel2 ) ->
                    Ok ( maybeDiscordId, { guild | channels = SeqDict.insert channelId channel2 guild.channels } )

                _ ->
                    Err ()

        Nothing ->
            Err ()


deleteMessageBackendHelper :
    Id UserId
    -> ThreadRouteWithMessage
    ->
        { a
            | messages : Array (Message ChannelMessageId)
            , threads : SeqDict (Id ChannelMessageId) Thread
            , linkedMessageIds : OneToOne (Discord.Id.Id Discord.Id.MessageId) (Id ChannelMessageId)
        }
    ->
        Result
            ()
            ( Maybe (Discord.Id.Id Discord.Id.MessageId)
            , { a
                | messages : Array (Message ChannelMessageId)
                , threads : SeqDict (Id ChannelMessageId) Thread
                , linkedMessageIds : OneToOne (Discord.Id.Id Discord.Id.MessageId) (Id ChannelMessageId)
              }
            )
deleteMessageBackendHelper userId threadRoute channel =
    case threadRoute of
        ViewThreadWithMessage threadId messageId ->
            case SeqDict.get threadId channel.threads of
                Just thread ->
                    case DmChannel.getArray messageId thread.messages of
                        Just (UserTextMessage message) ->
                            if message.createdBy == userId then
                                ( OneToOne.first messageId thread.linkedMessageIds
                                , { channel
                                    | threads =
                                        SeqDict.insert
                                            threadId
                                            { thread
                                                | messages = DmChannel.setArray messageId (DeletedMessage message.createdAt) thread.messages
                                            }
                                            channel.threads
                                  }
                                )
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
                        ( OneToOne.first messageId channel.linkedMessageIds
                        , { channel | messages = DmChannel.setArray messageId (DeletedMessage message.createdAt) channel.messages }
                        )
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
                        | messages : Array (MessageState ChannelMessageId)
                        , threads : SeqDict (Id ChannelMessageId) FrontendThread
                    }
        }
    ->
        { a
            | channels :
                SeqDict
                    (Id ChannelId)
                    { c
                        | messages : Array (MessageState ChannelMessageId)
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
            | messages : Array (MessageState ChannelMessageId)
            , threads : SeqDict (Id ChannelMessageId) FrontendThread
        }
    ->
        { a
            | messages : Array (MessageState ChannelMessageId)
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


usersToNotify :
    Id UserId
    -> ThreadRouteWithMaybeMessage
    -> { a | messages : Array (Message ChannelMessageId), threads : SeqDict (Id ChannelMessageId) Thread }
    -> Nonempty RichText
    -> SeqSet (Id UserId)
usersToNotify senderId threadRouteWithRepliedTo channel content =
    let
        usersToNotify2 =
            RichText.mentionsUser content

        repliedToUserId2 : Maybe (Id UserId)
        repliedToUserId2 =
            case threadRouteWithRepliedTo of
                ViewThreadWithMaybeMessage threadId maybeRepliedTo ->
                    case SeqDict.get threadId channel.threads of
                        Just thread ->
                            repliedToUserId maybeRepliedTo thread

                        Nothing ->
                            case DmChannel.getArray threadId channel.messages of
                                Just (UserTextMessage data) ->
                                    Just data.createdBy

                                Just (UserJoinedMessage _ userJoined _) ->
                                    Just userJoined

                                Just (DeletedMessage _) ->
                                    Nothing

                                Nothing ->
                                    Nothing

                NoThreadWithMaybeMessage maybeRepliedTo ->
                    repliedToUserId maybeRepliedTo channel
    in
    (case repliedToUserId2 of
        Just a ->
            SeqSet.insert a usersToNotify2

        Nothing ->
            usersToNotify2
    )
        |> SeqSet.remove senderId


usersToNotifyFrontend :
    Id UserId
    -> ThreadRouteWithMaybeMessage
    -> { a | messages : Array (MessageState ChannelMessageId), threads : SeqDict (Id ChannelMessageId) FrontendThread }
    -> Nonempty RichText
    -> SeqSet (Id UserId)
usersToNotifyFrontend senderId threadRouteWithRepliedTo channel content =
    let
        usersToNotify2 =
            RichText.mentionsUser content

        repliedToUserId2 : Maybe (Id UserId)
        repliedToUserId2 =
            case threadRouteWithRepliedTo of
                ViewThreadWithMaybeMessage threadId maybeRepliedTo ->
                    case SeqDict.get threadId channel.threads of
                        Just thread ->
                            repliedToUserIdFrontend maybeRepliedTo thread

                        Nothing ->
                            case DmChannel.getArray threadId channel.messages of
                                Just (MessageLoaded message) ->
                                    case message of
                                        UserTextMessage data ->
                                            Just data.createdBy

                                        UserJoinedMessage _ userJoined _ ->
                                            Just userJoined

                                        DeletedMessage _ ->
                                            Nothing

                                _ ->
                                    Nothing

                NoThreadWithMaybeMessage maybeRepliedTo ->
                    repliedToUserIdFrontend maybeRepliedTo channel
    in
    (case repliedToUserId2 of
        Just a ->
            SeqSet.insert a usersToNotify2

        Nothing ->
            usersToNotify2
    )
        |> SeqSet.remove senderId


repliedToUserId : Maybe (Id messageId) -> { a | messages : Array (Message messageId) } -> Maybe (Id UserId)
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


repliedToUserIdFrontend : Maybe (Id messageId) -> { a | messages : Array (MessageState messageId) } -> Maybe (Id UserId)
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
