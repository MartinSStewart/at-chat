module LocalState exposing
    ( AdminData
    , AdminStatus(..)
    , BackendChannel
    , BackendGuild
    , ChannelStatus(..)
    , FrontendChannel
    , FrontendGuild
    , JoinGuildError(..)
    , LocalState
    , LogWithTime
    , Message(..)
    , addInvite
    , addMember
    , channelToFrontend
    , createChannel
    , createChannelFrontend
    , createMessage
    , createNewUser
    , deleteChannel
    , deleteChannelFrontend
    , editChannel
    , getUser
    , guildToFrontend
    , isAdmin
    , memberIsTyping
    )

import Array exposing (Array)
import ChannelName exposing (ChannelName)
import Effect.Time as Time
import EmailAddress exposing (EmailAddress)
import GuildName exposing (GuildName)
import Id exposing (ChannelId, GuildId, Id, InviteLinkId, UserId)
import Image exposing (Image)
import Log exposing (Log)
import NonemptyDict exposing (NonemptyDict)
import PersonName exposing (PersonName)
import SecretId exposing (SecretId)
import SeqDict exposing (SeqDict)
import SeqSet exposing (SeqSet)
import String.Nonempty exposing (NonemptyString)
import Unsafe
import User exposing (BackendUser, EmailNotifications(..), FrontendUser)


type alias LocalState =
    { userId : Id UserId
    , adminData : AdminStatus
    , guilds : SeqDict (Id GuildId) FrontendGuild
    , joinGuildError : Maybe JoinGuildError
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


guildToFrontend : Id UserId -> BackendGuild -> Maybe FrontendGuild
guildToFrontend userId guild =
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


type alias BackendChannel =
    { createdAt : Time.Posix
    , createdBy : Id UserId
    , name : ChannelName
    , messages : Array Message
    , status : ChannelStatus
    , lastTypedAt : SeqDict (Id UserId) Time.Posix
    }


type alias FrontendChannel =
    { createdAt : Time.Posix
    , createdBy : Id UserId
    , name : ChannelName
    , messages : Array Message
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict (Id UserId) Time.Posix
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
            }
                |> Just

        ChannelArchived archive ->
            { createdAt = channel.createdAt
            , createdBy = channel.createdBy
            , name = channel.name
            , messages = channel.messages
            , isArchived = Just archive
            , lastTypedAt = channel.lastTypedAt
            }
                |> Just

        ChannelDeleted _ ->
            Nothing


type alias Archived =
    { archivedAt : Time.Posix, archivedBy : Id UserId }


type ChannelStatus
    = ChannelActive
    | ChannelArchived Archived
    | ChannelDeleted { deletedAt : Time.Posix, deletedBy : Id UserId }


type Message
    = UserTextMessage
        { createdAt : Time.Posix
        , createdBy : Id UserId
        , content : NonemptyString
        }
    | UserJoinedMessage Time.Posix (Id UserId)


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
    }


getUser : Id UserId -> LocalState -> Maybe FrontendUser
getUser userId local =
    if local.userId == userId then
        User.backendToFrontend local.user |> Just

    else
        SeqDict.get userId local.otherUsers


isAdmin : LocalState -> Bool
isAdmin { adminData } =
    case adminData of
        IsAdmin _ ->
            True

        IsNotAdmin ->
            False


createMessage : Message -> { d | messages : Array Message } -> { d | messages : Array Message }
createMessage message channel =
    { channel | messages = Array.push message channel.messages }


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
    { guild
        | channels =
            SeqDict.updateIfExists
                channelId
                (\channel ->
                    { channel | name = channelName }
                )
                guild.channels
    }


deleteChannel : Time.Posix -> Id UserId -> Id ChannelId -> BackendGuild -> BackendGuild
deleteChannel time userId channelId guild =
    { guild
        | channels =
            SeqDict.updateIfExists
                channelId
                (\channel ->
                    { channel | status = ChannelDeleted { deletedAt = time, deletedBy = userId } }
                )
                guild.channels
    }


deleteChannelFrontend : Id ChannelId -> FrontendGuild -> FrontendGuild
deleteChannelFrontend channelId guild =
    { guild | channels = SeqDict.remove channelId guild.channels }


memberIsTyping :
    Id UserId
    -> Time.Posix
    -> Id ChannelId
    -> { d | channels : SeqDict (Id ChannelId) { e | lastTypedAt : SeqDict (Id UserId) Time.Posix } }
    -> { d | channels : SeqDict (Id ChannelId) { e | lastTypedAt : SeqDict (Id UserId) Time.Posix } }
memberIsTyping userId time channelId guild =
    { guild
        | channels =
            SeqDict.updateIfExists
                channelId
                (\channel ->
                    { channel
                        | lastTypedAt = SeqDict.insert userId time channel.lastTypedAt
                    }
                )
                guild.channels
    }


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
            , channels : SeqDict (Id ChannelId) { d | messages : Array Message }
        }
    ->
        Result
            ()
            { a
                | owner : Id UserId
                , members : SeqDict (Id UserId) { joinedAt : Time.Posix }
                , announcementChannel : Id ChannelId
                , channels : SeqDict (Id ChannelId) { d | messages : Array Message }
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
                    (createMessage (UserJoinedMessage time userId))
                    guild.channels
        }
            |> Ok
