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
    , addInvite
    , addMember
    , addReactionEmoji
    , allUsers
    , allUsers2
    , announcementChannel
    , createChannel
    , createChannelFrontend
    , createGuild
    , createMessage
    , createNewUser
    , deleteChannel
    , deleteChannelFrontend
    , deleteMessage
    , deleteMessageHelper
    , editChannel
    , editMessageHelper
    , getGuildAndChannel
    , getMessages
    , getUser
    , guildToFrontend
    , guildToFrontendForUser
    , linkedChannel
    , markAllChannelsAsViewed
    , memberIsEditTyping
    , memberIsEditTypingHelper
    , memberIsTyping
    , removeReactionEmoji
    , updateChannel
    )

import Array exposing (Array)
import Array.Extra
import ChannelName exposing (ChannelName)
import Discord.Id
import DmChannel exposing (DmChannel, LastTypedAt, Thread)
import Duration
import Effect.Time as Time
import Emoji exposing (Emoji)
import FileStatus exposing (FileData, FileHash, FileId)
import GuildName exposing (GuildName)
import Id exposing (ChannelId, GuildId, GuildOrDmId(..), Id, InviteLinkId, ThreadRoute(..), UserId)
import List.Nonempty exposing (Nonempty)
import Log exposing (Log)
import Message exposing (Message(..), UserTextMessageData)
import NonemptyDict exposing (NonemptyDict)
import OneToOne exposing (OneToOne)
import PersonName exposing (PersonName)
import Quantity
import RichText exposing (RichText(..))
import SecretId exposing (SecretId)
import SeqDict exposing (SeqDict)
import SeqSet
import Unsafe
import User exposing (BackendUser, EmailNotifications(..), EmailStatus, FrontendUser)


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict (Id GuildId) FrontendGuild
    , dmChannels : SeqDict (Id UserId) DmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
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


guildToFrontendForUser : Id UserId -> BackendGuild -> Maybe FrontendGuild
guildToFrontendForUser userId guild =
    if userId == guild.owner || SeqDict.member userId guild.members then
        { createdAt = guild.createdAt
        , createdBy = guild.createdBy
        , name = guild.name
        , icon = guild.icon
        , channels = SeqDict.filterMap (\_ channel -> channelToFrontend channel) guild.channels
        , members = guild.members
        , owner = guild.owner
        , invites = guild.invites
        }
            |> Just

    else
        Nothing


guildToFrontend : BackendGuild -> FrontendGuild
guildToFrontend guild =
    { createdAt = guild.createdAt
    , createdBy = guild.createdBy
    , name = guild.name
    , icon = guild.icon
    , channels = SeqDict.filterMap (\_ channel -> channelToFrontend channel) guild.channels
    , members = guild.members
    , owner = guild.owner
    , invites = guild.invites
    }


type alias BackendChannel =
    { createdAt : Time.Posix
    , createdBy : Id UserId
    , name : ChannelName
    , messages : Array Message
    , status : ChannelStatus
    , lastTypedAt : SeqDict (Id UserId) LastTypedAt
    , linkedMessageIds : OneToOne (Discord.Id.Id Discord.Id.MessageId) Int
    , threads : SeqDict Int Thread
    }


type alias FrontendChannel =
    { createdAt : Time.Posix
    , createdBy : Id UserId
    , name : ChannelName
    , messages : Array Message
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict (Id UserId) LastTypedAt
    , linkedMessageIds : OneToOne (Discord.Id.Id Discord.Id.MessageId) Int
    , threads : SeqDict Int Thread
    }


channelToFrontend : BackendChannel -> Maybe FrontendChannel
channelToFrontend channel =
    case channel.status of
        ChannelActive ->
            { createdAt = channel.createdAt
            , createdBy = channel.createdBy
            , name = channel.name
            , messages = channel.messages
            , isArchived = Nothing
            , lastTypedAt = channel.lastTypedAt
            , linkedMessageIds = channel.linkedMessageIds
            , threads = channel.threads
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
    }


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
    , lastChannelViewed = SeqDict.empty
    , icon = Nothing
    }


getMessages : GuildOrDmId -> LocalState -> Maybe ( ThreadRoute, Array Message )
getMessages guildOrDmId local =
    case guildOrDmId of
        GuildOrDmId_Guild guildId channelId threadRoute ->
            case getGuildAndChannel guildId channelId local of
                Just ( _, channel ) ->
                    case threadRoute of
                        ViewThread threadMessageIndex ->
                            case SeqDict.get threadMessageIndex channel.threads of
                                Just thread ->
                                    Just ( threadRoute, thread.messages )

                                Nothing ->
                                    Nothing

                        NoThread ->
                            Just ( threadRoute, channel.messages )

                Nothing ->
                    Nothing

        GuildOrDmId_Dm otherUserId threadRoute ->
            case SeqDict.get otherUserId local.dmChannels of
                Just dmChannel ->
                    case threadRoute of
                        ViewThread threadMessageIndex ->
                            case SeqDict.get threadMessageIndex dmChannel.threads of
                                Just thread ->
                                    Just ( threadRoute, thread.messages )

                                Nothing ->
                                    Nothing

                        NoThread ->
                            Just ( threadRoute, dmChannel.messages )

                Nothing ->
                    Nothing


getUser : Id UserId -> LocalUser -> Maybe FrontendUser
getUser userId localUser =
    if localUser.userId == userId then
        User.backendToFrontend localUser.user |> Just

    else
        SeqDict.get userId localUser.otherUsers


createMessage :
    Maybe (Discord.Id.Id Discord.Id.MessageId)
    -> Message
    -> ThreadRoute
    ->
        { d
            | messages : Array Message
            , lastTypedAt : SeqDict (Id UserId) LastTypedAt
            , linkedMessageIds : OneToOne (Discord.Id.Id Discord.Id.MessageId) Int
            , threads : SeqDict Int Thread
        }
    ->
        { d
            | messages : Array Message
            , lastTypedAt : SeqDict (Id UserId) LastTypedAt
            , linkedMessageIds : OneToOne (Discord.Id.Id Discord.Id.MessageId) Int
            , threads : SeqDict Int Thread
        }
createMessage maybeDiscordMessageId message threadRoute channel =
    case threadRoute of
        ViewThread threadMessageIndex ->
            { channel
                | threads =
                    SeqDict.update
                        threadMessageIndex
                        (\maybe ->
                            Maybe.withDefault DmChannel.threadInit maybe
                                |> createMessageHelper maybeDiscordMessageId message
                                |> Just
                        )
                        channel.threads
            }

        NoThread ->
            createMessageHelper maybeDiscordMessageId message channel


createMessageHelper :
    Maybe (Discord.Id.Id Discord.Id.MessageId)
    -> Message
    ->
        { d
            | messages : Array Message
            , lastTypedAt : SeqDict (Id UserId) LastTypedAt
            , linkedMessageIds : OneToOne (Discord.Id.Id Discord.Id.MessageId) Int
        }
    ->
        { d
            | messages : Array Message
            , lastTypedAt : SeqDict (Id UserId) LastTypedAt
            , linkedMessageIds : OneToOne (Discord.Id.Id Discord.Id.MessageId) Int
        }
createMessageHelper maybeDiscordMessageId message channel =
    { channel
        | messages =
            case message of
                UserTextMessage data ->
                    let
                        previousIndex : Int
                        previousIndex =
                            Array.length channel.messages - 1
                    in
                    case Array.get previousIndex channel.messages of
                        Just (UserTextMessage previous) ->
                            if
                                (Duration.from previous.createdAt data.createdAt |> Quantity.lessThan (Duration.minutes 5))
                                    && (previous.editedAt == Nothing)
                                    && (previous.createdBy == data.createdBy)
                                    && not (SeqDict.isEmpty previous.reactions)
                                --&& not (OneToOne.memberSecond previousIndex channel.linkedMessageIds)
                            then
                                Array.set
                                    previousIndex
                                    (UserTextMessage
                                        { previous
                                            | content =
                                                RichText.append
                                                    previous.content
                                                    (List.Nonempty.cons (NormalText '\n' "") data.content)
                                        }
                                    )
                                    channel.messages

                            else
                                Array.push message channel.messages

                        _ ->
                            Array.push message channel.messages

                UserJoinedMessage _ _ _ ->
                    Array.push message channel.messages

                DeletedMessage _ ->
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
                    OneToOne.insert discordMessageId (Array.length channel.messages) channel.linkedMessageIds

                Nothing ->
                    channel.linkedMessageIds
    }


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
                , isArchived = Nothing
                , lastTypedAt = SeqDict.empty
                , linkedMessageIds = OneToOne.empty
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
    -> { e | lastTypedAt : SeqDict (Id UserId) LastTypedAt, threads : SeqDict Int Thread }
    -> { e | lastTypedAt : SeqDict (Id UserId) LastTypedAt, threads : SeqDict Int Thread }
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
    -> ThreadRoute
    -> Int
    ->
        { d
            | channels :
                SeqDict
                    (Id ChannelId)
                    { e
                        | messages : Array Message
                        , lastTypedAt : SeqDict (Id UserId) LastTypedAt
                        , threads : SeqDict Int Thread
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
                            | messages : Array Message
                            , lastTypedAt : SeqDict (Id UserId) LastTypedAt
                            , threads : SeqDict Int Thread
                        }
            }
memberIsEditTyping userId time channelId threadRoute messageIndex guild =
    case SeqDict.get channelId guild.channels of
        Just channel ->
            case memberIsEditTypingHelper time userId messageIndex threadRoute channel of
                Ok channel2 ->
                    Ok { guild | channels = SeqDict.insert channelId channel2 guild.channels }

                _ ->
                    Err ()

        Nothing ->
            Err ()


memberIsEditTypingHelper :
    Time.Posix
    -> Id UserId
    -> Int
    -> ThreadRoute
    -> { a | messages : Array Message, lastTypedAt : SeqDict (Id UserId) LastTypedAt, threads : SeqDict Int Thread }
    -> Result () { a | messages : Array Message, lastTypedAt : SeqDict (Id UserId) LastTypedAt, threads : SeqDict Int Thread }
memberIsEditTypingHelper time userId messageIndex threadRoute channel =
    case threadRoute of
        ViewThread threadMessageIndex ->
            case SeqDict.get threadMessageIndex channel.threads of
                Just thread ->
                    case Array.get messageIndex thread.messages of
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

        NoThread ->
            case Array.get messageIndex channel.messages of
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


addInvite :
    SecretId InviteLinkId
    -> Id UserId
    -> Time.Posix
    -> { d | invites : SeqDict (SecretId InviteLinkId) { createdBy : Id UserId, createdAt : Time.Posix } }
    -> { d | invites : SeqDict (SecretId InviteLinkId) { createdBy : Id UserId, createdAt : Time.Posix } }
addInvite inviteId userId time guild =
    { guild | invites = SeqDict.insert inviteId { createdBy = userId, createdAt = time } guild.invites }


addMember :
    Time.Posix
    -> Id UserId
    ->
        { a
            | owner : Id UserId
            , members : SeqDict (Id UserId) { joinedAt : Time.Posix }
            , channels :
                SeqDict
                    (Id ChannelId)
                    { d
                        | messages : Array Message
                        , lastTypedAt : SeqDict (Id UserId) LastTypedAt
                        , linkedMessageIds : OneToOne (Discord.Id.Id Discord.Id.MessageId) Int
                    }
        }
    ->
        Result
            ()
            { a
                | owner : Id UserId
                , members : SeqDict (Id UserId) { joinedAt : Time.Posix }
                , channels :
                    SeqDict
                        (Id ChannelId)
                        { d
                            | messages : Array Message
                            , lastTypedAt : SeqDict (Id UserId) LastTypedAt
                            , linkedMessageIds : OneToOne (Discord.Id.Id Discord.Id.MessageId) Int
                        }
            }
addMember time userId guild =
    if guild.owner == userId || SeqDict.member userId guild.members then
        Err ()

    else
        { guild
            | members = SeqDict.insert userId { joinedAt = time } guild.members
            , channels =
                SeqDict.updateIfExists
                    (announcementChannel guild)
                    (createMessageHelper Nothing (UserJoinedMessage time userId SeqDict.empty))
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
    -> ThreadRoute
    -> Int
    -> { b | messages : Array Message, threads : SeqDict Int Thread }
    -> { b | messages : Array Message, threads : SeqDict Int Thread }
addReactionEmoji emoji userId threadRoute messageIndex channel =
    case threadRoute of
        ViewThread threadMessageIndex ->
            { channel
                | threads =
                    SeqDict.updateIfExists
                        threadMessageIndex
                        (\thread ->
                            { thread
                                | messages =
                                    Array.Extra.update
                                        messageIndex
                                        (Message.addReactionEmoji userId emoji)
                                        thread.messages
                            }
                        )
                        channel.threads
            }

        NoThread ->
            { channel
                | messages =
                    Array.Extra.update messageIndex (Message.addReactionEmoji userId emoji) channel.messages
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
    -> Int
    -> ThreadRoute
    -> { b | messages : Array Message, lastTypedAt : SeqDict (Id UserId) LastTypedAt, threads : SeqDict Int Thread }
    -> Result () { b | messages : Array Message, lastTypedAt : SeqDict (Id UserId) LastTypedAt, threads : SeqDict Int Thread }
editMessageHelper time editedBy newContent attachedFiles messageIndex threadRoute channel =
    case threadRoute of
        ViewThread threadMessageIndex ->
            case SeqDict.get threadMessageIndex channel.threads of
                Just thread ->
                    case editMessageHelper2 time editedBy newContent attachedFiles messageIndex thread of
                        Ok thread2 ->
                            Ok { channel | threads = SeqDict.insert threadMessageIndex thread2 channel.threads }

                        Err () ->
                            Err ()

                Nothing ->
                    Err ()

        NoThread ->
            editMessageHelper2 time editedBy newContent attachedFiles messageIndex channel


editMessageHelper2 :
    Time.Posix
    -> Id UserId
    -> Nonempty RichText
    -> SeqDict (Id FileId) FileData
    -> Int
    -> { b | messages : Array Message, lastTypedAt : SeqDict (Id UserId) LastTypedAt }
    -> Result () { b | messages : Array Message, lastTypedAt : SeqDict (Id UserId) LastTypedAt }
editMessageHelper2 time editedBy newContent attachedFiles messageIndex channel =
    case Array.get messageIndex channel.messages of
        Just (UserTextMessage data) ->
            if data.createdBy == editedBy then
                let
                    data2 : UserTextMessageData
                    data2 =
                        { data | editedAt = Just time, content = newContent, attachedFiles = attachedFiles }
                in
                { channel
                    | messages = Array.set messageIndex (UserTextMessage data2) channel.messages
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
    -> ThreadRoute
    -> Int
    -> { b | messages : Array Message, threads : SeqDict Int Thread }
    -> { b | messages : Array Message, threads : SeqDict Int Thread }
removeReactionEmoji emoji userId threadRoute messageIndex channel =
    case threadRoute of
        ViewThread threadMessageIndex ->
            { channel
                | threads =
                    SeqDict.updateIfExists
                        threadMessageIndex
                        (\thread ->
                            { thread
                                | messages =
                                    Array.Extra.update
                                        messageIndex
                                        (Message.removeReactionEmoji userId emoji)
                                        thread.messages
                            }
                        )
                        channel.threads
            }

        NoThread ->
            { channel
                | messages =
                    Array.Extra.update messageIndex
                        (Message.removeReactionEmoji userId emoji)
                        channel.messages
            }


markAllChannelsAsViewed :
    Id GuildId
    -> { a | channels : SeqDict (Id ChannelId) { b | messages : Array Message } }
    -> BackendUser
    -> BackendUser
markAllChannelsAsViewed guildId guild user =
    { user
        | lastViewed =
            SeqDict.foldl
                (\channelId channel state ->
                    SeqDict.insert
                        (GuildOrDmId_Guild guildId channelId NoThread)
                        (Array.length channel.messages - 1)
                        state
                )
                user.lastViewed
                guild.channels
    }


deleteMessage :
    Id UserId
    -> Id ChannelId
    -> ThreadRoute
    -> Int
    -> { a | channels : SeqDict (Id ChannelId) { c | messages : Array Message, threads : SeqDict Int Thread } }
    -> Result () { a | channels : SeqDict (Id ChannelId) { c | messages : Array Message, threads : SeqDict Int Thread } }
deleteMessage userId channelId threadRoute messageIndex guild =
    case SeqDict.get channelId guild.channels of
        Just channel ->
            case deleteMessageHelper userId messageIndex threadRoute channel of
                Ok channel2 ->
                    Ok { guild | channels = SeqDict.insert channelId channel2 guild.channels }

                _ ->
                    Err ()

        Nothing ->
            Err ()


deleteMessageHelper :
    Id UserId
    -> Int
    -> ThreadRoute
    -> { a | messages : Array Message, threads : SeqDict Int Thread }
    -> Result () { a | messages : Array Message, threads : SeqDict Int Thread }
deleteMessageHelper userId messageIndex threadRoute channel =
    case threadRoute of
        ViewThread threadMessageIndex ->
            case SeqDict.get threadMessageIndex channel.threads of
                Just thread ->
                    case Array.get messageIndex thread.messages of
                        Just (UserTextMessage message) ->
                            if message.createdBy == userId then
                                { channel
                                    | threads =
                                        SeqDict.insert
                                            threadMessageIndex
                                            { thread
                                                | messages = Array.set messageIndex (DeletedMessage message.createdAt) thread.messages
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

        NoThread ->
            case Array.get messageIndex channel.messages of
                Just (UserTextMessage message) ->
                    if message.createdBy == userId then
                        Ok { channel | messages = Array.set messageIndex (DeletedMessage message.createdAt) channel.messages }

                    else
                        Err ()

                _ ->
                    Err ()


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
