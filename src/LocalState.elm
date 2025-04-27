module LocalState exposing
    ( AdminData
    , AdminStatus(..)
    , BackendChannel
    , BackendGuild
    , ChannelStatus(..)
    , FrontendChannel
    , FrontendGuild
    , LocalState
    , LogWithTime
    , Message
    , NotAdminData
    , channelToFrontend
    , createChannel
    , createChannelFrontend
    , createMessage
    , createNewUser
    , currentUser
    , deleteChannel
    , deleteChannelFrontend
    , editChannel
    , getUser
    , guildToFrontend
    , isAdmin
    , updateUser
    )

import Array exposing (Array)
import ChannelName exposing (ChannelName)
import Effect.Time as Time
import EmailAddress exposing (EmailAddress)
import GuildName exposing (GuildName)
import Id exposing (ChannelId, GuildId, Id, UserId)
import Image exposing (Image)
import Log exposing (Log)
import NonemptyDict exposing (NonemptyDict)
import PersonName exposing (PersonName)
import SeqDict exposing (SeqDict)
import SeqSet exposing (SeqSet)
import String.Nonempty exposing (NonemptyString)
import Unsafe
import User exposing (BackendUser, EmailNotifications(..), FrontendUser)


type alias LocalState =
    { userId : Id UserId
    , adminData : AdminStatus
    , guilds : SeqDict (Id GuildId) FrontendGuild
    }


type alias BackendGuild =
    { createdAt : Time.Posix
    , createdBy : Id UserId
    , name : GuildName
    , icon : Maybe Image
    , channels : SeqDict (Id ChannelId) BackendChannel
    , members : SeqDict (Id UserId) { joinedAt : Time.Posix }
    , owner : Id UserId
    }


type alias FrontendGuild =
    { createdAt : Time.Posix
    , createdBy : Id UserId
    , name : GuildName
    , icon : Maybe Image
    , channels : SeqDict (Id ChannelId) FrontendChannel
    , members : SeqDict (Id UserId) { joinedAt : Time.Posix }
    , owner : Id UserId
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
    }


type alias FrontendChannel =
    { createdAt : Time.Posix
    , createdBy : Id UserId
    , name : ChannelName
    , messages : Array Message
    , isArchived : Maybe Archived
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
            }
                |> Just

        ChannelArchived archive ->
            { createdAt = channel.createdAt
            , createdBy = channel.createdBy
            , name = channel.name
            , messages = channel.messages
            , isArchived = Just archive
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


type alias Message =
    { createdAt : Time.Posix
    , createdBy : Id UserId
    , content : NonemptyString
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin NotAdminData


type alias NotAdminData =
    { user : BackendUser
    , otherUsers : SeqDict (Id UserId) FrontendUser
    }


type alias LogWithTime =
    { time : Time.Posix, log : Log }


type alias AdminData =
    { users : NonemptyDict (Id UserId) BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict (Id UserId) Time.Posix
    }


missingUserEmail : EmailAddress
missingUserEmail =
    Unsafe.emailAddress "missing.user@example.com"


currentUser : LocalState -> BackendUser
currentUser localState =
    case localState.adminData of
        IsAdmin data ->
            case NonemptyDict.get localState.userId data.users of
                Just user ->
                    user

                Nothing ->
                    -- This should never happen
                    createNewUser
                        (Time.millisToPosix 0)
                        PersonName.unknown
                        missingUserEmail
                        False

        IsNotAdmin data ->
            data.user


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
getUser userId localState =
    case localState.adminData of
        IsAdmin data ->
            NonemptyDict.get userId data.users |> Maybe.map User.backendToFrontend

        IsNotAdmin data ->
            if localState.userId == userId then
                User.backendToFrontend data.user |> Just

            else
                SeqDict.get userId data.otherUsers


updateUser : Id UserId -> (BackendUser -> BackendUser) -> LocalState -> LocalState
updateUser userId updateFunc localState =
    { localState
        | adminData =
            case localState.adminData of
                IsAdmin data ->
                    IsAdmin { data | users = NonemptyDict.updateIfExists userId updateFunc data.users }

                IsNotAdmin data ->
                    if localState.userId == userId then
                        IsNotAdmin { data | user = updateFunc data.user }

                    else
                        IsNotAdmin data
    }


isAdmin : LocalState -> Bool
isAdmin { adminData } =
    case adminData of
        IsAdmin _ ->
            True

        IsNotAdmin _ ->
            False


createMessage :
    Time.Posix
    -> Id UserId
    -> NonemptyString
    -> { d | messages : Array { createdAt : Time.Posix, createdBy : Id UserId, content : NonemptyString } }
    -> { d | messages : Array { createdAt : Time.Posix, createdBy : Id UserId, content : NonemptyString } }
createMessage createdAt userId text channel =
    { channel
        | messages =
            Array.push
                { createdAt = createdAt
                , createdBy = userId
                , content = text
                }
                channel.messages
    }


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
