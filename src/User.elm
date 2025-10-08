module User exposing
    ( AdminUiSection(..)
    , BackendUser
    , EmailNotifications(..)
    , EmailStatus(..)
    , FrontendCurrentUser
    , FrontendUser
    , LinkDiscordData
    , NotificationLevel(..)
    , addDirectMention
    , addLinkedDiscordUser
    , backendToFrontend
    , backendToFrontendCurrent
    , backendToFrontendForUser
    , init
    , linkDiscordDataCodec
    , profileImage
    , profileImageSize
    , sectionToString
    , setGuildNotificationLevel
    , setLastChannelViewed
    , setLastDmViewed
    , setName
    , toString
    )

import Codec exposing (Codec)
import Discord.Id
import Effect.Time as Time
import EmailAddress exposing (EmailAddress)
import FileStatus exposing (FileHash)
import Id exposing (ChannelId, ChannelMessageId, GuildId, GuildOrDmIdNoThread, Id, ThreadMessageId, ThreadRoute, UserId)
import NonemptyDict exposing (NonemptyDict)
import OneOrGreater exposing (OneOrGreater)
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
    , lastViewed : SeqDict GuildOrDmIdNoThread (Id ChannelMessageId)
    , lastViewedThreads : SeqDict ( GuildOrDmIdNoThread, Id ChannelMessageId ) (Id ThreadMessageId)
    , lastDmViewed : Maybe ( Id UserId, ThreadRoute )
    , lastChannelViewed : SeqDict (Id GuildId) ( Id ChannelId, ThreadRoute )
    , icon : Maybe FileHash
    , notifyOnAllMessages : SeqSet (Id GuildId)
    , directMentions : SeqDict (Id GuildId) (NonemptyDict ( Id ChannelId, ThreadRoute ) OneOrGreater)
    , lastPushNotification : Maybe Time.Posix
    , linkedDiscordUsers : SeqDict (Discord.Id.Id Discord.Id.UserId) { auth : LinkDiscordData, name : String }
    }


type alias FrontendCurrentUser =
    { name : PersonName
    , isAdmin : Bool
    , email : EmailStatus
    , recentLoginEmails : List Time.Posix
    , lastLogPageViewed : Int
    , expandedSections : SeqSet AdminUiSection
    , createdAt : Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Time.Posix
    , lastViewed : SeqDict GuildOrDmIdNoThread (Id ChannelMessageId)
    , lastViewedThreads : SeqDict ( GuildOrDmIdNoThread, Id ChannelMessageId ) (Id ThreadMessageId)
    , lastDmViewed : Maybe ( Id UserId, ThreadRoute )
    , lastChannelViewed : SeqDict (Id GuildId) ( Id ChannelId, ThreadRoute )
    , icon : Maybe FileHash
    , notifyOnAllMessages : SeqSet (Id GuildId)
    , directMentions : SeqDict (Id GuildId) (NonemptyDict ( Id ChannelId, ThreadRoute ) OneOrGreater)
    , lastPushNotification : Maybe Time.Posix
    , linkedDiscordUsers : SeqDict (Discord.Id.Id Discord.Id.UserId) { name : String }
    }


type alias LinkDiscordData =
    { token : String
    , xSuperProperties : String
    , userAgent : String
    }


linkDiscordDataCodec : Codec LinkDiscordData
linkDiscordDataCodec =
    Codec.object LinkDiscordData
        |> Codec.field "token" .token Codec.string
        |> Codec.field "xSuperProperties" .xSuperProperties Codec.string
        |> Codec.field "userAgent" .userAgent Codec.string
        |> Codec.buildObject


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention


init : Time.Posix -> PersonName -> EmailStatus -> Bool -> BackendUser
init createdAt name email userIsAdmin =
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
    , lastDmViewed = Nothing
    , lastChannelViewed = SeqDict.empty
    , icon = Nothing
    , notifyOnAllMessages = SeqSet.empty
    , directMentions = SeqDict.empty
    , lastPushNotification = Nothing
    , linkedDiscordUsers = SeqDict.empty
    }


addLinkedDiscordUser :
    Discord.Id.Id Discord.Id.UserId
    -> data
    -> { a | linkedDiscordUsers : SeqDict (Discord.Id.Id Discord.Id.UserId) data }
    -> { a | linkedDiscordUsers : SeqDict (Discord.Id.Id Discord.Id.UserId) data }
addLinkedDiscordUser discordUserId data user =
    { user | linkedDiscordUsers = SeqDict.insert discordUserId data user.linkedDiscordUsers }


addDirectMention :
    Id GuildId
    -> Id ChannelId
    -> ThreadRoute
    -> { a | directMentions : SeqDict (Id GuildId) (NonemptyDict ( Id ChannelId, ThreadRoute ) OneOrGreater) }
    -> { a | directMentions : SeqDict (Id GuildId) (NonemptyDict ( Id ChannelId, ThreadRoute ) OneOrGreater) }
addDirectMention guildId channelId threadRoute user =
    { user
        | directMentions =
            SeqDict.update
                guildId
                (\maybeDict ->
                    case maybeDict of
                        Just dict ->
                            NonemptyDict.updateOrInsert
                                ( channelId, threadRoute )
                                (\maybeCount ->
                                    case maybeCount of
                                        Just count ->
                                            OneOrGreater.increment count

                                        Nothing ->
                                            OneOrGreater.one
                                )
                                dict
                                |> Just

                        Nothing ->
                            NonemptyDict.singleton ( channelId, threadRoute ) OneOrGreater.one |> Just
                )
                user.directMentions
    }


setGuildNotificationLevel :
    Id GuildId
    -> NotificationLevel
    -> { a | notifyOnAllMessages : SeqSet (Id GuildId) }
    -> { a | notifyOnAllMessages : SeqSet (Id GuildId) }
setGuildNotificationLevel guildId notificationLevel user =
    { user
        | notifyOnAllMessages =
            case notificationLevel of
                NotifyOnEveryMessage ->
                    SeqSet.insert guildId user.notifyOnAllMessages

                NotifyOnMention ->
                    SeqSet.remove guildId user.notifyOnAllMessages
    }


setLastChannelViewed :
    Id GuildId
    -> Id ChannelId
    -> ThreadRoute
    ->
        { a
            | lastChannelViewed : SeqDict (Id GuildId) ( Id ChannelId, ThreadRoute )
            , directMentions : SeqDict (Id GuildId) (NonemptyDict ( Id ChannelId, ThreadRoute ) OneOrGreater)
        }
    ->
        { a
            | lastChannelViewed : SeqDict (Id GuildId) ( Id ChannelId, ThreadRoute )
            , directMentions : SeqDict (Id GuildId) (NonemptyDict ( Id ChannelId, ThreadRoute ) OneOrGreater)
        }
setLastChannelViewed guildId channelId threadRoute user =
    { user
        | lastChannelViewed = SeqDict.insert guildId ( channelId, threadRoute ) user.lastChannelViewed
        , directMentions =
            SeqDict.update
                guildId
                (\maybeDict ->
                    case maybeDict of
                        Just dict ->
                            NonemptyDict.toSeqDict dict
                                |> SeqDict.remove ( channelId, threadRoute )
                                |> NonemptyDict.fromSeqDict

                        Nothing ->
                            Nothing
                )
                user.directMentions
    }


setLastDmViewed :
    Id UserId
    -> ThreadRoute
    -> { a | lastDmViewed : Maybe ( Id UserId, ThreadRoute ) }
    -> { a | lastDmViewed : Maybe ( Id UserId, ThreadRoute ) }
setLastDmViewed otherUserId threadRoute user =
    { user | lastDmViewed = Just ( otherUserId, threadRoute ) }


setName : PersonName -> { b | name : PersonName } -> { b | name : PersonName }
setName name user =
    { user | name = name }


type EmailStatus
    = RegisteredFromDiscord
    | RegisteredFromSlack
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


backendToFrontendCurrent : BackendUser -> FrontendCurrentUser
backendToFrontendCurrent user =
    { name = user.name
    , isAdmin = user.isAdmin
    , email = user.email
    , recentLoginEmails = user.recentLoginEmails
    , lastLogPageViewed = user.lastLogPageViewed
    , expandedSections = user.expandedSections
    , createdAt = user.createdAt
    , emailNotifications = user.emailNotifications
    , lastEmailNotification = user.lastEmailNotification
    , lastViewed = user.lastViewed
    , lastViewedThreads = user.lastViewedThreads
    , lastDmViewed = user.lastDmViewed
    , lastChannelViewed = user.lastChannelViewed
    , icon = user.icon
    , notifyOnAllMessages = user.notifyOnAllMessages
    , directMentions = user.directMentions
    , lastPushNotification = user.lastPushNotification
    , linkedDiscordUsers = SeqDict.map (\_ data -> { name = data.name }) user.linkedDiscordUsers
    }


{-| Convert a BackendUser to a FrontendUser without any permission checks
-}
backendToFrontend : FrontendCurrentUser -> FrontendUser
backendToFrontend user =
    { name = user.name
    , isAdmin = user.isAdmin
    , createdAt = user.createdAt
    , icon = user.icon
    }


{-| Convert a BackendUser to a FrontendUser while only including data the current user has permission to see
-}
backendToFrontendForUser :
    { a | name : PersonName, isAdmin : Bool, createdAt : Time.Posix, icon : Maybe FileHash }
    -> FrontendUser
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
