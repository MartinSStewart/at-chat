module User exposing
    ( AdminUiSection(..)
    , BackendUser
    , DiscordFrontendCurrentUser
    , DiscordFrontendUser
    , EmailNotifications(..)
    , FrontendCurrentUser
    , FrontendUser
    , LastDmViewed(..)
    , NotificationLevel(..)
    , addDirectMention
    , addDiscordDirectMention
    , backendToFrontend
    , backendToFrontendCurrent
    , backendToFrontendForUser
    , discordCurrentUserToFrontend
    , init
    , linkDiscordDataCodec
    , profileImage
    , profileImageSize
    , sectionToString
    , setGuildNotificationLevel
    , setLastChannelViewed
    , setLastDiscordChannelViewed
    , setLastDmViewed
    , setName
    , toString
    )

import Base64
import Codec exposing (Codec)
import Discord
import Discord.Id
import Effect.Time as Time
import EmailAddress exposing (EmailAddress)
import FileStatus exposing (FileHash)
import Id exposing (AnyGuildOrDmId, ChannelId, ChannelMessageId, GuildId, GuildOrDmId, Id, ThreadMessageId, ThreadRoute, UserId)
import Json.Decode
import NonemptyDict exposing (NonemptyDict)
import OneOrGreater exposing (OneOrGreater)
import PersonName exposing (PersonName)
import Route exposing (ShowMembersTab)
import SafeJson exposing (SafeJson)
import SeqDict exposing (SeqDict)
import SeqSet exposing (SeqSet)
import Ui exposing (Element)


{-| Contains sensitive data that should only be accessible by admins, the backend, and the user themselves.
-}
type alias BackendUser =
    { name : PersonName
    , isAdmin : Bool
    , email : EmailAddress
    , recentLoginEmails : List Time.Posix
    , lastLogPageViewed : Int
    , expandedSections : SeqSet AdminUiSection
    , createdAt : Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Time.Posix
    , lastViewed : SeqDict AnyGuildOrDmId (Id ChannelMessageId)
    , lastViewedThreads : SeqDict ( AnyGuildOrDmId, Id ChannelMessageId ) (Id ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict (Id GuildId) ( Id ChannelId, ThreadRoute )
    , lastDiscordChannelViewed : SeqDict (Discord.Id.Id Discord.Id.GuildId) ( Discord.Id.Id Discord.Id.ChannelId, ThreadRoute )
    , icon : Maybe FileHash
    , notifyOnAllMessages : SeqSet (Id GuildId)
    , discordNotifyOnAllMessages : SeqSet (Discord.Id.Id Discord.Id.GuildId)
    , directMentions : SeqDict (Id GuildId) (NonemptyDict ( Id ChannelId, ThreadRoute ) OneOrGreater)
    , discordDirectMentions : SeqDict (Discord.Id.Id Discord.Id.GuildId) (NonemptyDict ( Discord.Id.Id Discord.Id.ChannelId, ThreadRoute ) OneOrGreater)
    , lastPushNotification : Maybe Time.Posix
    }


type LastDmViewed
    = DmChannelLastViewed (Id UserId) ThreadRoute
    | DiscordDmChannelLastViewed (Discord.Id.Id Discord.Id.PrivateChannelId)
    | NoLastDmViewed


type alias FrontendCurrentUser =
    BackendUser


linkDiscordDataCodec : Codec Discord.UserAuth
linkDiscordDataCodec =
    Codec.object Discord.UserAuth
        |> Codec.field "token" .token Codec.string
        |> Codec.field "userAgent" .userAgent Codec.string
        |> Codec.field "xSuperProperties" .xSuperProperties superPropertiesCodec
        |> Codec.buildObject


superPropertiesCodec : Codec SafeJson
superPropertiesCodec =
    Codec.andThen
        (\base64 ->
            case Base64.toString base64 of
                Just text ->
                    case Json.Decode.decodeString SafeJson.decoder text of
                        Ok json ->
                            Codec.succeed json

                        Err _ ->
                            Codec.fail "Invalid json"

                Nothing ->
                    Codec.fail "Invalid base64"
        )
        (\a -> Base64.fromString (SafeJson.toString 0 a) |> Maybe.withDefault "")
        Codec.string


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention


init : Time.Posix -> PersonName -> EmailAddress -> Bool -> BackendUser
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
    , lastDmViewed = NoLastDmViewed
    , lastChannelViewed = SeqDict.empty
    , lastDiscordChannelViewed = SeqDict.empty
    , icon = Nothing
    , notifyOnAllMessages = SeqSet.empty
    , discordNotifyOnAllMessages = SeqSet.empty
    , directMentions = SeqDict.empty
    , discordDirectMentions = SeqDict.empty
    , lastPushNotification = Nothing
    }


addDirectMention :
    Id GuildId
    -> Id ChannelId
    -> ThreadRoute
    -> { a | directMentions : SeqDict (Id GuildId) (NonemptyDict ( Id ChannelId, ThreadRoute ) OneOrGreater) }
    -> { a | directMentions : SeqDict (Id GuildId) (NonemptyDict ( Id ChannelId, ThreadRoute ) OneOrGreater) }
addDirectMention guildId channelId threadRoute user =
    { user | directMentions = addDirectMentionHelper guildId channelId threadRoute user.directMentions }


addDiscordDirectMention :
    Discord.Id.Id Discord.Id.GuildId
    -> Discord.Id.Id Discord.Id.ChannelId
    -> ThreadRoute
    -> { a | discordDirectMentions : SeqDict (Discord.Id.Id Discord.Id.GuildId) (NonemptyDict ( Discord.Id.Id Discord.Id.ChannelId, ThreadRoute ) OneOrGreater) }
    -> { a | discordDirectMentions : SeqDict (Discord.Id.Id Discord.Id.GuildId) (NonemptyDict ( Discord.Id.Id Discord.Id.ChannelId, ThreadRoute ) OneOrGreater) }
addDiscordDirectMention guildId channelId threadRoute user =
    { user | discordDirectMentions = addDirectMentionHelper guildId channelId threadRoute user.discordDirectMentions }


addDirectMentionHelper :
    guildId
    -> channelId
    -> ThreadRoute
    -> SeqDict guildId (NonemptyDict ( channelId, ThreadRoute ) OneOrGreater)
    -> SeqDict guildId (NonemptyDict ( channelId, ThreadRoute ) OneOrGreater)
addDirectMentionHelper guildId channelId threadRoute =
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


setLastDiscordChannelViewed :
    Discord.Id.Id Discord.Id.GuildId
    -> Discord.Id.Id Discord.Id.ChannelId
    -> ThreadRoute
    ->
        { a
            | lastDiscordChannelViewed : SeqDict (Discord.Id.Id Discord.Id.GuildId) ( Discord.Id.Id Discord.Id.ChannelId, ThreadRoute )
            , discordDirectMentions : SeqDict (Discord.Id.Id Discord.Id.GuildId) (NonemptyDict ( Discord.Id.Id Discord.Id.ChannelId, ThreadRoute ) OneOrGreater)
        }
    ->
        { a
            | lastDiscordChannelViewed : SeqDict (Discord.Id.Id Discord.Id.GuildId) ( Discord.Id.Id Discord.Id.ChannelId, ThreadRoute )
            , discordDirectMentions : SeqDict (Discord.Id.Id Discord.Id.GuildId) (NonemptyDict ( Discord.Id.Id Discord.Id.ChannelId, ThreadRoute ) OneOrGreater)
        }
setLastDiscordChannelViewed guildId channelId threadRoute user =
    { user
        | lastDiscordChannelViewed = SeqDict.insert guildId ( channelId, threadRoute ) user.lastDiscordChannelViewed
        , discordDirectMentions =
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
                user.discordDirectMentions
    }


setLastDmViewed : LastDmViewed -> { a | lastDmViewed : LastDmViewed } -> { a | lastDmViewed : LastDmViewed }
setLastDmViewed lastDmViewed user =
    { user | lastDmViewed = lastDmViewed }


setName : PersonName -> { b | name : PersonName } -> { b | name : PersonName }
setName name user =
    { user | name = name }


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


type alias DiscordFrontendUser =
    { name : PersonName
    , icon : Maybe FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : PersonName
    , icon : Maybe FileHash
    , email : Maybe EmailAddress
    }


discordCurrentUserToFrontend : DiscordFrontendCurrentUser -> DiscordFrontendUser
discordCurrentUserToFrontend user =
    { name = user.name
    , icon = user.icon
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
    , lastDiscordChannelViewed = user.lastDiscordChannelViewed
    , icon = user.icon
    , notifyOnAllMessages = user.notifyOnAllMessages
    , discordNotifyOnAllMessages = user.discordNotifyOnAllMessages
    , directMentions = user.directMentions
    , discordDirectMentions = user.discordDirectMentions
    , lastPushNotification = user.lastPushNotification
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


toString : userId -> SeqDict userId { a | name : PersonName } -> String
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
