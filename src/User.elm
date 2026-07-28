module User exposing
    ( AdminUiSection(..)
    , BackendUser
    , EmailNotifications(..)
    , FrontendCurrentUser
    , FrontendUser
    , LastDmViewed(..)
    , LocalUser
    , NotificationLevel(..)
    , addDirectMention
    , addDiscordDirectMention
    , addNewCustomEmojis
    , addNewStickers
    , addRecentlyUsedEmoji
    , backendToFrontendCurrent
    , backendToFrontendForUser
    , commonlyUsedEmojis
    , discordFullDataUserToFrontendCurrentUser
    , discordProfileImage
    , discordUserDataToFrontendUser
    , getDiscordUser
    , getUser
    , init
    , linkDiscordDataCodec
    , multipleProfileImages
    , profileImage
    , profileImageHtml
    , profileImageNoRounding
    , profileImageRounding
    , profileImageSize
    , sectionToString
    , setDiscordGuildNotificationLevel
    , setDomainWhitelist
    , setEmailNotifications
    , setEmojiCategory
    , setEmojiSkinTone
    , setGuildNotificationLevel
    , setIcon
    , setLastChannelViewed
    , setLastDiscordChannelViewed
    , setLastDmViewed
    , setName
    , toString
    )

import Array
import Base64
import Codec exposing (Codec)
import CustomEmoji exposing (CustomEmojiData)
import Discord exposing (OptionalData(..))
import DiscordUserData exposing (DiscordUserData, DiscordUserLoadingData)
import Effect.Time as Time
import EmailAddress exposing (EmailAddress)
import Emoji exposing (Category(..), EmojiCategory(..), EmojiConfig, EmojiOrCustomEmoji(..), SkinTone)
import FileStatus exposing (FileHash)
import GuildIcon
import Html exposing (Html)
import Html.Attributes
import Id exposing (AnyGuildOrDmId, ChannelId, ChannelMessageId, CustomEmojiId, GuildId, Id, StickerId, ThreadMessageId, ThreadRoute, UserId)
import Json.Decode
import LinkedAndOtherDiscordUsers exposing (DiscordFrontendCurrentUser, LinkedAndOtherDiscordUsers)
import MyUi
import NonemptyDict exposing (NonemptyDict)
import OneOrGreater exposing (OneOrGreater)
import Pagination exposing (PageId)
import PersonName exposing (PersonName)
import RichText exposing (Domain)
import SafeJson exposing (SafeJson)
import SeqDict exposing (SeqDict)
import SeqSet exposing (SeqSet)
import Sticker exposing (StickerData)
import Ui exposing (Element)
import Ui.Font
import UserAgent exposing (UserAgent)
import UserSession exposing (DiscordFrontendUser, UserSession)


{-| Contains sensitive data that should only be accessible by admins, the backend, and the user themselves.
-}
type alias BackendUser =
    { name : PersonName
    , isAdmin : Bool
    , email : EmailAddress
    , recentLoginEmails : List Time.Posix
    , lastLogPageViewed : Id PageId
    , expandedSections : SeqSet AdminUiSection
    , createdAt : Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Time.Posix
    , lastViewed : SeqDict AnyGuildOrDmId (Id ChannelMessageId)
    , lastViewedThreads : SeqDict ( AnyGuildOrDmId, Id ChannelMessageId ) (Id ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict (Id GuildId) ( Id ChannelId, ThreadRoute )
    , lastDiscordChannelViewed : SeqDict (Discord.Id Discord.GuildId) ( Discord.Id Discord.ChannelId, ThreadRoute )
    , icon : Maybe FileHash
    , notifyOnAllMessages : SeqSet (Id GuildId)
    , discordNotifyOnAllMessages : SeqSet (Discord.Id Discord.GuildId)
    , directMentions : SeqDict (Id GuildId) (NonemptyDict ( Id ChannelId, ThreadRoute ) OneOrGreater)
    , discordDirectMentions : SeqDict (Discord.Id Discord.GuildId) (NonemptyDict ( Discord.Id Discord.ChannelId, ThreadRoute ) OneOrGreater)
    , lastPushNotification : Maybe Time.Posix
    , expandedGuilds : SeqSet (Id GuildId)
    , expandedDiscordGuilds : SeqSet (Discord.Id Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet Domain
    , emojiConfig : EmojiConfig
    , availableStickers : SeqSet (Id StickerId)
    , availableCustomEmojis : SeqSet (Id CustomEmojiId)
    }


commonlyUsedEmojis : FrontendCurrentUser -> List ( EmojiOrCustomEmoji, Int )
commonlyUsedEmojis user =
    Array.foldl
        (\emoji dict -> SeqDict.update emoji (\maybe -> Maybe.withDefault 0 maybe |> (+) 1 |> Just) dict)
        (SeqDict.fromList
            [ ( EmojiOrCustomEmoji_Emoji Emoji.heart, 0 )
            , ( EmojiOrCustomEmoji_Emoji Emoji.thumbsUp, 0 )
            , ( EmojiOrCustomEmoji_Emoji Emoji.smiley, 0 )
            ]
        )
        user.emojiConfig.lastUsedEmojis
        |> SeqDict.toList
        |> List.sortBy (\( _, count ) -> -count)


addRecentlyUsedEmoji : EmojiOrCustomEmoji -> { a | emojiConfig : EmojiConfig } -> { a | emojiConfig : EmojiConfig }
addRecentlyUsedEmoji emoji user =
    let
        emojiConfig =
            user.emojiConfig

        count =
            Array.length emojiConfig.lastUsedEmojis
    in
    { user
        | emojiConfig =
            { emojiConfig
                | lastUsedEmojis =
                    if count > 30 then
                        Array.push emoji (Array.slice (count - 20) count emojiConfig.lastUsedEmojis)

                    else
                        Array.push emoji emojiConfig.lastUsedEmojis
            }
    }


setEmailNotifications : EmailNotifications -> { a | emailNotifications : EmailNotifications } -> { a | emailNotifications : EmailNotifications }
setEmailNotifications emailNotifications user =
    { user | emailNotifications = emailNotifications }


setEmojiCategory : Category -> { a | emojiConfig : EmojiConfig } -> { a | emojiConfig : EmojiConfig }
setEmojiCategory category user =
    let
        emojiConfig =
            user.emojiConfig
    in
    { user | emojiConfig = { emojiConfig | category = category } }


setEmojiSkinTone : Maybe SkinTone -> { a | emojiConfig : EmojiConfig } -> { a | emojiConfig : EmojiConfig }
setEmojiSkinTone skinTone user =
    let
        emojiConfig =
            user.emojiConfig
    in
    { user | emojiConfig = { emojiConfig | skinTone = skinTone } }


setDomainWhitelist : Bool -> Domain -> { a | domainWhitelist : SeqSet Domain } -> { a | domainWhitelist : SeqSet Domain }
setDomainWhitelist enable domain user =
    { user
        | domainWhitelist =
            if enable then
                SeqSet.insert domain user.domainWhitelist

            else
                SeqSet.remove domain user.domainWhitelist
    }


type LastDmViewed
    = DmChannelLastViewed (Id UserId) ThreadRoute
    | DiscordDmChannelLastViewed (Discord.Id Discord.PrivateChannelId)
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
    , lastLogPageViewed = Id.fromInt 0
    , expandedSections = SeqSet.empty
    , createdAt = createdAt
    , emailNotifications = NeverNotifyMe
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
    , expandedGuilds = SeqSet.empty
    , expandedDiscordGuilds = SeqSet.empty
    , linkDiscordAcknowledgementIsChecked = False
    , domainWhitelist = SeqSet.empty
    , emojiConfig = { skinTone = Nothing, category = EmojiCategory SmileysAndEmotion, lastUsedEmojis = Array.empty }
    , availableStickers = SeqSet.empty
    , availableCustomEmojis = SeqSet.empty
    }


addDirectMention :
    Id GuildId
    -> Id ChannelId
    -> ThreadRoute
    -> { a | directMentions : SeqDict (Id GuildId) (NonemptyDict ( Id ChannelId, ThreadRoute ) OneOrGreater) }
    -> { a | directMentions : SeqDict (Id GuildId) (NonemptyDict ( Id ChannelId, ThreadRoute ) OneOrGreater) }
addDirectMention guildId channelId threadRoute user =
    { user | directMentions = addDirectMentionHelper guildId channelId threadRoute user.directMentions }


addNewStickers :
    SeqDict (Id StickerId) StickerData
    -> { a | availableStickers : SeqSet (Id StickerId) }
    -> { a | availableStickers : SeqSet (Id StickerId) }
addNewStickers stickers user =
    { user | availableStickers = SeqDict.keys stickers |> SeqSet.fromList |> SeqSet.union user.availableStickers }


addNewCustomEmojis :
    SeqDict (Id CustomEmojiId) CustomEmojiData
    -> { a | availableCustomEmojis : SeqSet (Id CustomEmojiId) }
    -> { a | availableCustomEmojis : SeqSet (Id CustomEmojiId) }
addNewCustomEmojis customEmojis user =
    { user | availableCustomEmojis = SeqDict.keys customEmojis |> SeqSet.fromList |> SeqSet.union user.availableCustomEmojis }


addDiscordDirectMention :
    Discord.Id Discord.GuildId
    -> Discord.Id Discord.ChannelId
    -> ThreadRoute
    -> { a | discordDirectMentions : SeqDict (Discord.Id Discord.GuildId) (NonemptyDict ( Discord.Id Discord.ChannelId, ThreadRoute ) OneOrGreater) }
    -> { a | discordDirectMentions : SeqDict (Discord.Id Discord.GuildId) (NonemptyDict ( Discord.Id Discord.ChannelId, ThreadRoute ) OneOrGreater) }
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


setDiscordGuildNotificationLevel :
    Discord.Id Discord.GuildId
    -> NotificationLevel
    -> { a | discordNotifyOnAllMessages : SeqSet (Discord.Id Discord.GuildId) }
    -> { a | discordNotifyOnAllMessages : SeqSet (Discord.Id Discord.GuildId) }
setDiscordGuildNotificationLevel guildId notificationLevel user =
    { user
        | discordNotifyOnAllMessages =
            case notificationLevel of
                NotifyOnEveryMessage ->
                    SeqSet.insert guildId user.discordNotifyOnAllMessages

                NotifyOnMention ->
                    SeqSet.remove guildId user.discordNotifyOnAllMessages
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
    Discord.Id Discord.GuildId
    -> Discord.Id Discord.ChannelId
    -> ThreadRoute
    ->
        { a
            | lastDiscordChannelViewed : SeqDict (Discord.Id Discord.GuildId) ( Discord.Id Discord.ChannelId, ThreadRoute )
            , discordDirectMentions : SeqDict (Discord.Id Discord.GuildId) (NonemptyDict ( Discord.Id Discord.ChannelId, ThreadRoute ) OneOrGreater)
        }
    ->
        { a
            | lastDiscordChannelViewed : SeqDict (Discord.Id Discord.GuildId) ( Discord.Id Discord.ChannelId, ThreadRoute )
            , discordDirectMentions : SeqDict (Discord.Id Discord.GuildId) (NonemptyDict ( Discord.Id Discord.ChannelId, ThreadRoute ) OneOrGreater)
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


setIcon : Maybe FileHash -> { b | icon : Maybe FileHash } -> { b | icon : Maybe FileHash }
setIcon icon user =
    { user | icon = icon }


getUser : Id UserId -> LocalUser -> Maybe FrontendUser
getUser userId localUser =
    if localUser.session.userId == userId then
        backendToFrontend localUser.user |> Just

    else
        SeqDict.get userId localUser.otherUsers


getDiscordUser : Discord.Id Discord.UserId -> LocalUser -> Maybe DiscordFrontendUser
getDiscordUser userId localUser =
    case LinkedAndOtherDiscordUsers.getLinkedUser userId localUser.discordUsers of
        Just user ->
            LinkedAndOtherDiscordUsers.discordCurrentUserToFrontend user |> Just

        Nothing ->
            LinkedAndOtherDiscordUsers.getOtherUser userId localUser.discordUsers


type EmailNotifications
    = NeverNotifyMe
    | NotifyMeWhenMentioned


type AdminUiSection
    = UsersSection
    | LogSection
    | DmChannelsSection
    | DiscordDmChannelsSection
    | DiscordUsersSection
    | DiscordGuildsSection
    | GuildsSection
    | DeletedGuildsSection
    | ApiKeysSection
    | ExportSection
    | ConnectionsSection
    | FilesSection
    | ToBackendLogsSection
    | StickersAndEmojisSection
    | VoiceChatSection
    | WebsocketCloseEventsSection
    | SessionsSection
    | WordSpellingGameSwedishSection


sectionToString : AdminUiSection -> String
sectionToString section2 =
    case section2 of
        UsersSection ->
            "Users"

        LogSection ->
            "Logs"

        DmChannelsSection ->
            "DM channels"

        DiscordDmChannelsSection ->
            "Discord DM channels"

        DiscordUsersSection ->
            "Discord users"

        DiscordGuildsSection ->
            "Discord guilds"

        GuildsSection ->
            "Guilds"

        DeletedGuildsSection ->
            "Deleted guilds"

        ApiKeysSection ->
            "API keys"

        ExportSection ->
            "Export/Import"

        ConnectionsSection ->
            "Connections"

        FilesSection ->
            "Files"

        ToBackendLogsSection ->
            "ToBackend logs"

        StickersAndEmojisSection ->
            "Stickers and emojis"

        VoiceChatSection ->
            "Voice chat"

        WebsocketCloseEventsSection ->
            "Websocket close events"

        SessionsSection ->
            "Sessions"

        WordSpellingGameSwedishSection ->
            "Word spelling game word lists"


{-| User containing only publicly visible data
-}
type alias FrontendUser =
    { name : PersonName
    , isAdmin : Bool
    , createdAt : Time.Posix
    , icon : Maybe FileHash
    }


discordUserDataToFrontendUser : DiscordUserData -> DiscordFrontendUser
discordUserDataToFrontendUser discordUserData =
    case discordUserData of
        DiscordUserData.BasicData data ->
            { name = PersonName.fromStringLossy data.user.username
            , icon = data.icon
            }

        DiscordUserData.FullData data ->
            { name = PersonName.fromStringLossy data.user.username
            , icon = data.icon
            }

        DiscordUserData.NeedsAuthAgain data ->
            { name = PersonName.fromStringLossy data.user.username
            , icon = data.icon
            }


type alias LocalUser =
    { session : UserSession
    , currentlyViewing : UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict (Id UserId) FrontendUser
    , discordUsers : LinkedAndOtherDiscordUsers
    , -- This data is redundant as it already exists in FrontendLoading and FrontendLoaded. We need it here anyway to reduce the number of parameters passed into messageView so lazy rendering is possible.
      timezone : Time.Zone
    , userAgent : UserAgent
    , stickers : SeqDict (Id StickerId) StickerData
    , customEmojis : SeqDict (Id CustomEmojiId) CustomEmojiData
    }


discordFullDataUserToFrontendCurrentUser :
    Bool
    -> { a | user : Discord.User, icon : Maybe FileHash, linkedAt : Time.Posix }
    -> DiscordUserLoadingData
    -> DiscordFrontendCurrentUser
discordFullDataUserToFrontendCurrentUser needsAuthAgain data isLoadingData =
    { name = PersonName.fromStringLossy data.user.username
    , icon = data.icon
    , email =
        case data.user.email of
            Included maybeText ->
                case maybeText of
                    Just text ->
                        EmailAddress.fromString text

                    Nothing ->
                        Nothing

            Missing ->
                Nothing
    , needsAuthAgain = needsAuthAgain
    , linkedAt = data.linkedAt
    , isLoadingData = isLoadingData
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
    , expandedGuilds = user.expandedGuilds
    , expandedDiscordGuilds = user.expandedDiscordGuilds
    , linkDiscordAcknowledgementIsChecked = user.linkDiscordAcknowledgementIsChecked
    , domainWhitelist = user.domainWhitelist
    , emojiConfig = user.emojiConfig
    , availableStickers = user.availableStickers
    , availableCustomEmojis = user.availableCustomEmojis
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


smallProfileImageSize : number
smallProfileImageSize =
    25


profileImageRounding : Int
profileImageRounding =
    8


profileImage : Id UserId -> Maybe FileHash -> Element msg
profileImage userId maybeFileHash =
    case maybeFileHash of
        Just fileHash ->
            Ui.image
                [ Ui.rounded profileImageRounding
                , Ui.width (Ui.px profileImageSize)
                , Ui.height (Ui.px profileImageSize)
                , Ui.clip
                , -- We need no pointer events here so drawing anchoring gets the offset of the parent
                  MyUi.noPointerEvents
                ]
                { source = FileStatus.fileUrl FileStatus.pngContent fileHash
                , description = ""
                , onLoad = Nothing
                }

        Nothing ->
            GuildIcon.defaultUser False profileImageSize 8 userId


profileImageHtml : Id UserId -> Maybe FileHash -> Html msg
profileImageHtml userId maybeFileHash =
    case maybeFileHash of
        Just fileHash ->
            Html.img
                [ Html.Attributes.style "border-radius" (String.fromInt profileImageRounding ++ "px")
                , Html.Attributes.style "width" (String.fromInt profileImageSize ++ "px")
                , Html.Attributes.style "height" (String.fromInt profileImageSize ++ "px")
                , Html.Attributes.src (FileStatus.fileUrl FileStatus.pngContent fileHash)
                ]
                []

        Nothing ->
            GuildIcon.defaultUserHtml profileImageSize 8 userId


discordProfileImage : Discord.Id Discord.UserId -> Maybe FileHash -> Element msg
discordProfileImage userId maybeFileHash =
    Ui.image
        [ Ui.rounded profileImageRounding
        , Ui.width (Ui.px profileImageSize)
        , Ui.height (Ui.px profileImageSize)
        , Ui.clip
        ]
        { source =
            case maybeFileHash of
                Just fileHash ->
                    FileStatus.fileUrl FileStatus.pngContent fileHash

                Nothing ->
                    Discord.defaultUserAvatarUrl (Discord.TwoToNthPower 7) userId
        , description = ""
        , onLoad = Nothing
        }


profileImageNoRounding : Id UserId -> Maybe FileHash -> Element msg
profileImageNoRounding userId maybeFileHash =
    case maybeFileHash of
        Just fileHash ->
            Ui.image
                [ Ui.width (Ui.px profileImageSize)
                , Ui.height (Ui.px profileImageSize)
                ]
                { source = FileStatus.fileUrl FileStatus.pngContent fileHash
                , description = ""
                , onLoad = Nothing
                }

        Nothing ->
            GuildIcon.defaultUser False profileImageSize 0 userId


multipleProfileImages : List ( Discord.Id Discord.UserId, Maybe FileHash ) -> Element msg
multipleProfileImages profileImages =
    case profileImages of
        [] ->
            Ui.none

        [ ( userId, single ) ] ->
            discordProfileImage userId single

        [ one, two ] ->
            Ui.el
                [ Ui.width (Ui.px 40)
                , Ui.height (Ui.px 40)
                , Ui.inFront (Ui.el [ Ui.move { x = 15, y = 15, z = 0 } ] (smallProfileImage two))
                , Ui.inFront (smallProfileImage one)
                ]
                Ui.none

        [ one, two, three ] ->
            Ui.el
                [ Ui.width (Ui.px 55)
                , Ui.height (Ui.px 40)
                , Ui.inFront (Ui.el [ Ui.move { x = 30, y = 0, z = 0 } ] (smallProfileImage three))
                , Ui.inFront (Ui.el [ Ui.move { x = 15, y = 15, z = 0 } ] (smallProfileImage two))
                , Ui.inFront (smallProfileImage one)
                ]
                Ui.none

        [ one, two, three, four ] ->
            Ui.el
                [ Ui.width (Ui.px 70)
                , Ui.height (Ui.px 40)
                , Ui.inFront (Ui.el [ Ui.move { x = 45, y = 15, z = 0 } ] (smallProfileImage four))
                , Ui.inFront (Ui.el [ Ui.move { x = 30, y = 0, z = 0 } ] (smallProfileImage three))
                , Ui.inFront (Ui.el [ Ui.move { x = 15, y = 15, z = 0 } ] (smallProfileImage two))
                , Ui.inFront (smallProfileImage one)
                ]
                Ui.none

        one :: two :: three :: rest ->
            Ui.el
                [ Ui.width (Ui.px 70)
                , Ui.height (Ui.px 40)
                , Ui.inFront (Ui.el [ Ui.move { x = 30, y = 0, z = 0 } ] (smallProfileImage three))
                , Ui.inFront (Ui.el [ Ui.move { x = 15, y = 15, z = 0 } ] (smallProfileImage two))
                , Ui.inFront (smallProfileImage one)
                , Ui.inFront
                    (Ui.el
                        [ Ui.move { x = 45, y = 15, z = 0 }
                        , Ui.background MyUi.background1
                        , Ui.width (Ui.px smallProfileImageSize)
                        , Ui.height (Ui.px smallProfileImageSize)
                        , Ui.Font.center
                        , Ui.Font.bold
                        , Ui.rounded 8
                        , Ui.Font.color MyUi.font3
                        , Ui.Font.size 14
                        , Ui.contentCenterY
                        , MyUi.htmlStyle "white-space" "pre"
                        ]
                        (Ui.text ("+" ++ String.fromInt (List.length rest)))
                    )
                ]
                Ui.none


smallProfileImage : ( Discord.Id Discord.UserId, Maybe FileHash ) -> Element msg
smallProfileImage ( userId, maybeFileHash ) =
    Ui.image
        [ Ui.rounded 8
        , Ui.width (Ui.px smallProfileImageSize)
        , Ui.height (Ui.px smallProfileImageSize)
        , Ui.clip
        ]
        { source =
            case maybeFileHash of
                Just fileHash ->
                    FileStatus.fileUrl FileStatus.pngContent fileHash

                Nothing ->
                    Discord.defaultUserAvatarUrl (Discord.TwoToNthPower 7) userId
        , description = ""
        , onLoad = Nothing
        }
