module LocalState exposing
    ( AdminData
    , AdminStatus(..)
    , Channel
    , Guild
    , LocalState
    , LogWithTime
    , Message
    , NotAdminData
    , createChannel
    , createMessage
    , createNewUser
    , currentUser
    , getUser
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
    , guilds : SeqDict (Id GuildId) Guild
    }


type alias Guild =
    { createdAt : Time.Posix
    , createdBy : Id UserId
    , name : GuildName
    , icon : Maybe Image
    , channels : SeqDict (Id ChannelId) Channel
    , members : SeqDict (Id UserId) { joinedAt : Time.Posix }
    , owner : Id UserId
    }


type alias Channel =
    { createdAt : Time.Posix
    , createdBy : Id UserId
    , name : ChannelName
    , messages : Array Message
    }


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


createMessage : Time.Posix -> Id UserId -> NonemptyString -> Channel -> Channel
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


createChannel : Time.Posix -> Id UserId -> ChannelName -> Guild -> Guild
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
                }
                guild.channels
    }
