module User exposing
    ( AdminUiSection(..)
    , BackendUser
    , EmailNotifications(..)
    , EmailStatus(..)
    , FrontendUser
    , backendToFrontend
    , backendToFrontendForUser
    , profileImage
    , profileImageSize
    , sectionToString
    , setLastChannelViewed
    , setName
    , toString
    )

import Effect.Time as Time
import EmailAddress exposing (EmailAddress)
import FileStatus exposing (FileHash)
import Id exposing (ChannelId, ChannelMessageId, GuildId, GuildOrDmId, Id, UserId)
import PersonName exposing (PersonName)
import SeqDict exposing (SeqDict)
import SeqSet exposing (SeqSet)
import Ui exposing (Element)


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
    , lastViewed : SeqDict GuildOrDmId (Id ChannelMessageId)
    , lastChannelViewed : SeqDict (Id GuildId) (Id ChannelId)
    , icon : Maybe FileHash
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
    , icon : Maybe FileHash
    }


{-| Convert a BackendUser to a FrontendUser without any permission checks
-}
backendToFrontend : BackendUser -> FrontendUser
backendToFrontend user =
    { name = user.name
    , isAdmin = user.isAdmin
    , createdAt = user.createdAt
    , icon = user.icon
    }


{-| Convert a BackendUser to a FrontendUser while only including data the current user has permission to see
-}
backendToFrontendForUser : BackendUser -> FrontendUser
backendToFrontendForUser user =
    { name = user.name
    , isAdmin = user.isAdmin
    , createdAt = user.createdAt
    , icon = user.icon
    }


toString : Id UserId -> SeqDict (Id UserId) FrontendUser -> String
toString userId allUsers =
    case SeqDict.get userId allUsers of
        Just user ->
            PersonName.toString user.name

        Nothing ->
            "<missing>"


profileImageSize : number
profileImageSize =
    40


profileImage : Maybe FileHash -> Element msg
profileImage maybeFileHash =
    case maybeFileHash of
        Just fileHash ->
            Ui.image
                [ Ui.rounded 8
                , Ui.width (Ui.px profileImageSize)
                , Ui.height (Ui.px profileImageSize)
                , Ui.clip
                ]
                { source = FileStatus.fileUrl FileStatus.pngContent fileHash
                , description = ""
                , onLoad = Nothing
                }

        Nothing ->
            Ui.el
                [ Ui.background (Ui.rgb 100 100 100)
                , Ui.rounded 8
                , Ui.width (Ui.px profileImageSize)
                , Ui.height (Ui.px profileImageSize)
                ]
                Ui.none
