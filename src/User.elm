module User exposing
    ( AdminUiSection(..)
    , BackendUser
    , EmailNotifications(..)
    , EmailStatus(..)
    , FrontendUser
    , allEmailNotifications
    , backendToFrontend
    , backendToFrontendForUser
    , sectionToString
    , setLastChannelViewed
    , setName
    , toString
    )

import Effect.Time as Time
import EmailAddress exposing (EmailAddress)
import Id exposing (ChannelId, GuildId, Id, UserId)
import PersonName exposing (PersonName)
import SeqDict exposing (SeqDict)
import SeqSet exposing (SeqSet)


{-| Contains sensitive data that should only be accessible by admins, the backend, and the user themselves.
-}
type alias BackendUser =
    { name : PersonName
    , isAdmin : Bool
    , email : EmailStatus
    , recentLoginEmails : List Time.Posix
    , lastLogPageViewed : Int
    , expandedSections : SeqSet AdminUiSection
    , createdAt : Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Time.Posix
    , lastViewed : SeqDict ( Id GuildId, Id ChannelId ) Int
    , lastChannelViewed : SeqDict (Id GuildId) (Id ChannelId)
    }


setLastChannelViewed : Id GuildId -> Id ChannelId -> BackendUser -> BackendUser
setLastChannelViewed guildId channelId user =
    { user | lastChannelViewed = SeqDict.insert guildId channelId user.lastChannelViewed }


setName : PersonName -> { b | name : PersonName } -> { b | name : PersonName }
setName name user =
    { user | name = name }


type EmailStatus
    = RegisteredFromDiscord
    | RegisteredDirectly EmailAddress


type EmailNotifications
    = CheckEvery5Minutes
    | CheckEveryHour
    | NeverNotifyMe


allEmailNotifications : List EmailNotifications
allEmailNotifications =
    [ CheckEvery5Minutes
    , CheckEveryHour
    , NeverNotifyMe
    ]


type AdminUiSection
    = UsersSection
    | LogSection


sectionToString : AdminUiSection -> String
sectionToString section2 =
    case section2 of
        UsersSection ->
            "Users"

        LogSection ->
            "Logs"


{-| User containing only publicly visible data
-}
type alias FrontendUser =
    { name : PersonName
    , isAdmin : Bool
    , createdAt : Time.Posix
    }


{-| Convert a BackendUser to a FrontendUser without any permission checks
-}
backendToFrontend : BackendUser -> FrontendUser
backendToFrontend user =
    { name = user.name
    , isAdmin = user.isAdmin
    , createdAt = user.createdAt
    }


{-| Convert a BackendUser to a FrontendUser while only including data the current user has permission to see
-}
backendToFrontendForUser : BackendUser -> FrontendUser
backendToFrontendForUser user =
    { name = user.name
    , isAdmin = user.isAdmin
    , createdAt = user.createdAt
    }


toString : Id UserId -> SeqDict (Id UserId) FrontendUser -> String
toString userId allUsers =
    case SeqDict.get userId allUsers of
        Just user ->
            PersonName.toString user.name

        Nothing ->
            "<missing>"
