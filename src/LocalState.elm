module LocalState exposing
    ( AdminData
    , AdminStatus(..)
    , Archived
    , BackendChannel
    , BackendGuild
    , ChannelStatus(..)
    , FrontendChannel
    , FrontendGuild
    , JoinGuildError(..)
    , LastTypedAt
    , LocalState
    , LocalUser
    , LogWithTime
    , Message(..)
    , UserTextMessageData
    , addInvite
    , addMember
    , addReactionEmoji
    , allUsers
    , allUsers2
    , createChannel
    , createChannelFrontend
    , createGuild
    , createMessage
    , createNewUser
    , deleteChannel
    , deleteChannelFrontend
    , deleteMessage
    , editChannel
    , editMessage
    , getGuildAndChannel
    , getUser
    , guildToFrontend
    , guildToFrontendForUser
    , markAllChannelsAsViewed
    , memberIsEditTyping
    , memberIsTyping
    , removeReactionEmoji
    )

import Array exposing (Array)
import Array.Extra
import ChannelName exposing (ChannelName)
import Discord.Id
import Duration
import Effect.Time as Time
import EmailAddress exposing (EmailAddress)
import Emoji exposing (Emoji)
import GuildName exposing (GuildName)
import Id exposing (ChannelId, GuildId, Id, InviteLinkId, UserId)
import Image exposing (Image)
import List.Nonempty exposing (Nonempty)
import Log exposing (Log)
import NonemptyDict exposing (NonemptyDict)
import NonemptySet exposing (NonemptySet)
import PersonName exposing (PersonName)
import Quantity
import RichText exposing (RichText(..))
import SecretId exposing (SecretId)
import SeqDict exposing (SeqDict)
import SeqSet
import Unsafe
import User exposing (BackendUser, EmailNotifications(..), FrontendUser)


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict (Id GuildId) FrontendGuild
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    }


type alias LocalUser =
    { userId : Id UserId
    , user : BackendUser
    , otherUsers : SeqDict (Id UserId) FrontendUser
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias BackendGuild =
    { createdAt : Time.Posix
    , createdBy : Id UserId
    , name : GuildName
    , icon : Maybe Image
    , channels : SeqDict (Id ChannelId) BackendChannel
    , members : SeqDict (Id UserId) { joinedAt : Time.Posix }
    , owner : Id UserId
    , invites : SeqDict (SecretId InviteLinkId) { createdAt : Time.Posix, createdBy : Id UserId }
    , announcementChannel : Id ChannelId
    , linkedId : Maybe (Discord.Id.Id Discord.Id.GuildId)
    }


type alias FrontendGuild =
    { createdAt : Time.Posix
    , createdBy : Id UserId
    , name : GuildName
    , icon : Maybe Image
    , channels : SeqDict (Id ChannelId) FrontendChannel
    , members : SeqDict (Id UserId) { joinedAt : Time.Posix }
    , owner : Id UserId
    , invites : SeqDict (SecretId InviteLinkId) { createdAt : Time.Posix, createdBy : Id UserId }
    , announcementChannel : Id ChannelId
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
        , announcementChannel = guild.announcementChannel
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
    , announcementChannel = guild.announcementChannel
    }


type alias BackendChannel =
    { createdAt : Time.Posix
    , createdBy : Id UserId
    , name : ChannelName
    , messages : Array Message
    , status : ChannelStatus
    , lastTypedAt : SeqDict (Id UserId) LastTypedAt
    }


type alias FrontendChannel =
    { createdAt : Time.Posix
    , createdBy : Id UserId
    , name : ChannelName
    , messages : Array Message
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict (Id UserId) LastTypedAt
    }


type alias LastTypedAt =
    { time : Time.Posix, messageIndex : Maybe Int }


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
            }
                |> Just

        ChannelDeleted _ ->
            Nothing


type alias Archived =
    { archivedAt : Time.Posix, archivedBy : Id UserId }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted { deletedAt : Time.Posix, deletedBy : Id UserId }


type Message
    = UserTextMessage UserTextMessageData
    | UserJoinedMessage Time.Posix (Id UserId) (SeqDict Emoji (NonemptySet (Id UserId)))
    | DeletedMessage


type alias UserTextMessageData =
    { createdAt : Time.Posix
    , createdBy : Id UserId
    , content : Nonempty RichText
    , reactions : SeqDict Emoji (NonemptySet (Id UserId))
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe Int
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LogWithTime =
    { time : Time.Posix, log : Log }


type alias AdminData =
    { users : NonemptyDict (Id UserId) BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict (Id UserId) Time.Posix
    }


createNewUser : Time.Posix -> PersonName -> EmailAddress -> Bool -> BackendUser
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
    , linkedId = Nothing
    }


getUser : Id UserId -> LocalState -> Maybe FrontendUser
getUser userId local =
    if local.localUser.userId == userId then
        User.backendToFrontend local.localUser.user |> Just

    else
        SeqDict.get userId local.localUser.otherUsers


createMessage :
    Message
    -> { d | messages : Array Message, lastTypedAt : SeqDict (Id UserId) LastTypedAt }
    -> { d | messages : Array Message, lastTypedAt : SeqDict (Id UserId) LastTypedAt }
createMessage message channel =
    { channel
        | messages =
            case message of
                UserTextMessage data ->
                    let
                        messageCount : Int
                        messageCount =
                            Array.length channel.messages - 1
                    in
                    case Array.get messageCount channel.messages of
                        Just (UserTextMessage previous) ->
                            if
                                (Duration.from previous.createdAt data.createdAt |> Quantity.lessThan (Duration.minutes 5))
                                    && (previous.editedAt == Nothing)
                                    && (previous.createdBy == data.createdBy)
                                    && not (SeqDict.isEmpty previous.reactions)
                            then
                                Array.set
                                    messageCount
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

                DeletedMessage ->
                    Array.push message channel.messages
        , lastTypedAt =
            case message of
                UserTextMessage { createdBy } ->
                    SeqDict.remove createdBy channel.lastTypedAt

                UserJoinedMessage _ _ _ ->
                    channel.lastTypedAt

                DeletedMessage ->
                    channel.lastTypedAt
    }


createGuild : Time.Posix -> Id UserId -> GuildName -> BackendGuild
createGuild time userId guildName =
    let
        announcementChannelId : Id ChannelId
        announcementChannelId =
            Id.fromInt 0
    in
    { createdAt = time
    , createdBy = userId
    , name = guildName
    , icon = Nothing
    , channels =
        SeqDict.fromList
            [ ( announcementChannelId
              , { createdAt = time
                , createdBy = userId
                , name = defaultChannelName
                , messages = Array.empty
                , status = ChannelActive
                , lastTypedAt = SeqDict.empty
                }
              )
            ]
    , members = SeqDict.empty
    , owner = userId
    , invites = SeqDict.empty
    , announcementChannel = announcementChannelId
    , linkedId = Nothing
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
                }
                guild.channels
    }


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
    -> Id ChannelId
    -> { d | channels : SeqDict (Id ChannelId) { e | lastTypedAt : SeqDict (Id UserId) LastTypedAt } }
    -> { d | channels : SeqDict (Id ChannelId) { e | lastTypedAt : SeqDict (Id UserId) LastTypedAt } }
memberIsTyping userId time channelId guild =
    updateChannel
        (\channel ->
            { channel
                | lastTypedAt =
                    SeqDict.insert userId { time = time, messageIndex = Nothing } channel.lastTypedAt
            }
        )
        channelId
        guild


memberIsEditTyping :
    Id UserId
    -> Time.Posix
    -> Id ChannelId
    -> Int
    -> { d | channels : SeqDict (Id ChannelId) { e | messages : Array Message, lastTypedAt : SeqDict (Id UserId) LastTypedAt } }
    -> Result () { d | channels : SeqDict (Id ChannelId) { e | messages : Array Message, lastTypedAt : SeqDict (Id UserId) LastTypedAt } }
memberIsEditTyping userId time channelId messageIndex guild =
    case SeqDict.get channelId guild.channels of
        Just channel ->
            case Array.get messageIndex channel.messages of
                Just (UserTextMessage data) ->
                    if data.createdBy == userId then
                        { guild
                            | channels =
                                SeqDict.insert
                                    channelId
                                    { channel
                                        | lastTypedAt =
                                            SeqDict.insert
                                                userId
                                                { time = time, messageIndex = Just messageIndex }
                                                channel.lastTypedAt
                                    }
                                    guild.channels
                        }
                            |> Ok

                    else
                        Err ()

                _ ->
                    Err ()

        Nothing ->
            Err ()


addInvite :
    SecretId InviteLinkId
    -> Id UserId
    -> Time.Posix
    -> { d | invites : SeqDict (SecretId InviteLinkId) { createdBy : Id UserId, createdAt : Time.Posix } }
    -> { d | invites : SeqDict (SecretId InviteLinkId) { createdBy : Id UserId, createdAt : Time.Posix } }
addInvite inviteId userId time guild =
    { guild
        | invites =
            SeqDict.insert inviteId { createdBy = userId, createdAt = time } guild.invites
    }


addMember :
    Time.Posix
    -> Id UserId
    ->
        { a
            | owner : Id UserId
            , members : SeqDict (Id UserId) { joinedAt : Time.Posix }
            , announcementChannel : Id ChannelId
            , channels :
                SeqDict
                    (Id ChannelId)
                    { d
                        | messages : Array Message
                        , lastTypedAt : SeqDict (Id UserId) LastTypedAt
                    }
        }
    ->
        Result
            ()
            { a
                | owner : Id UserId
                , members : SeqDict (Id UserId) { joinedAt : Time.Posix }
                , announcementChannel : Id ChannelId
                , channels :
                    SeqDict
                        (Id ChannelId)
                        { d
                            | messages : Array Message
                            , lastTypedAt : SeqDict (Id UserId) LastTypedAt
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
                    guild.announcementChannel
                    (createMessage (UserJoinedMessage time userId SeqDict.empty))
                    guild.channels
        }
            |> Ok


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
    -> Id ChannelId
    -> Int
    -> { a | channels : SeqDict (Id ChannelId) { b | messages : Array Message } }
    -> { a | channels : SeqDict (Id ChannelId) { b | messages : Array Message } }
addReactionEmoji emoji userId channelId messageIndex guild =
    updateChannel
        (\channel ->
            { channel
                | messages =
                    Array.Extra.update messageIndex
                        (\message ->
                            case message of
                                UserTextMessage message2 ->
                                    { message2
                                        | reactions =
                                            SeqDict.update
                                                emoji
                                                (\maybeSet ->
                                                    (case maybeSet of
                                                        Just nonempty ->
                                                            NonemptySet.insert userId nonempty

                                                        Nothing ->
                                                            NonemptySet.singleton userId
                                                    )
                                                        |> Just
                                                )
                                                message2.reactions
                                    }
                                        |> UserTextMessage

                                UserJoinedMessage time userJoined reactions ->
                                    UserJoinedMessage
                                        time
                                        userJoined
                                        (SeqDict.update
                                            emoji
                                            (\maybeSet ->
                                                (case maybeSet of
                                                    Just nonempty ->
                                                        NonemptySet.insert userId nonempty

                                                    Nothing ->
                                                        NonemptySet.singleton userId
                                                )
                                                    |> Just
                                            )
                                            reactions
                                        )

                                DeletedMessage ->
                                    message
                        )
                        channel.messages
            }
        )
        channelId
        guild


updateChannel :
    (v -> v)
    -> Id ChannelId
    -> { a | channels : SeqDict (Id ChannelId) v }
    -> { a | channels : SeqDict (Id ChannelId) v }
updateChannel updateFunc channelId guild =
    { guild | channels = SeqDict.updateIfExists channelId updateFunc guild.channels }


editMessage :
    Id UserId
    -> Time.Posix
    -> Nonempty RichText
    -> Id ChannelId
    -> Int
    ->
        { a
            | channels :
                SeqDict
                    (Id ChannelId)
                    { b
                        | messages : Array Message
                        , lastTypedAt : SeqDict (Id UserId) LastTypedAt
                    }
        }
    ->
        Result
            ()
            { a
                | channels :
                    SeqDict
                        (Id ChannelId)
                        { b
                            | messages : Array Message
                            , lastTypedAt : SeqDict (Id UserId) LastTypedAt
                        }
            }
editMessage editedBy time newContent channelId messageIndex guild =
    case SeqDict.get channelId guild.channels of
        Just channel ->
            case Array.get messageIndex channel.messages of
                Just (UserTextMessage data) ->
                    if data.createdBy == editedBy then
                        { guild
                            | channels =
                                SeqDict.insert
                                    channelId
                                    { channel
                                        | messages =
                                            Array.set
                                                messageIndex
                                                ({ data | editedAt = Just time, content = newContent }
                                                    |> UserTextMessage
                                                )
                                                channel.messages
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
                                    guild.channels
                        }
                            |> Ok

                    else
                        Err ()

                _ ->
                    Err ()

        Nothing ->
            Err ()


removeReactionEmoji :
    Emoji
    -> Id UserId
    -> Id ChannelId
    -> Int
    -> { a | channels : SeqDict (Id ChannelId) { b | messages : Array Message } }
    -> { a | channels : SeqDict (Id ChannelId) { b | messages : Array Message } }
removeReactionEmoji emoji userId channelId messageIndex guild =
    updateChannel
        (\channel ->
            { channel
                | messages =
                    Array.Extra.update messageIndex
                        (\message ->
                            case message of
                                UserTextMessage message2 ->
                                    { message2
                                        | reactions =
                                            SeqDict.update
                                                emoji
                                                (\maybeSet ->
                                                    case maybeSet of
                                                        Just nonempty ->
                                                            NonemptySet.toSeqSet nonempty
                                                                |> SeqSet.remove userId
                                                                |> NonemptySet.fromSeqSet

                                                        Nothing ->
                                                            Nothing
                                                )
                                                message2.reactions
                                    }
                                        |> UserTextMessage

                                UserJoinedMessage time userJoined reactions ->
                                    UserJoinedMessage
                                        time
                                        userJoined
                                        (SeqDict.update
                                            emoji
                                            (\maybeSet ->
                                                case maybeSet of
                                                    Just nonempty ->
                                                        NonemptySet.toSeqSet nonempty
                                                            |> SeqSet.remove userId
                                                            |> NonemptySet.fromSeqSet

                                                    Nothing ->
                                                        Nothing
                                            )
                                            reactions
                                        )

                                DeletedMessage ->
                                    message
                        )
                        channel.messages
            }
        )
        channelId
        guild


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
                    SeqDict.insert ( guildId, channelId ) (Array.length channel.messages - 1) state
                )
                user.lastViewed
                guild.channels
    }


deleteMessage :
    Id UserId
    -> Id ChannelId
    -> Int
    -> { a | channels : SeqDict (Id ChannelId) { c | messages : Array Message } }
    -> Result () { a | channels : SeqDict (Id ChannelId) { c | messages : Array Message } }
deleteMessage userId channelId messageIndex guild =
    case SeqDict.get channelId guild.channels of
        Just channel ->
            case Array.get messageIndex channel.messages of
                Just (UserTextMessage message) ->
                    if message.createdBy == userId then
                        { guild
                            | channels =
                                SeqDict.insert
                                    channelId
                                    { channel
                                        | messages =
                                            Array.set messageIndex DeletedMessage channel.messages
                                    }
                                    guild.channels
                        }
                            |> Ok

                    else
                        Err ()

                _ ->
                    Err ()

        Nothing ->
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
