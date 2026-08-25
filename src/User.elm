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
    , addRecentlyUsedEmojis
    , allUsers
    , backendToFrontendCurrent
    , backendToFrontendForUser
    , commonlyUsedEmojis
    , discordFullDataUserToFrontendCurrentUser
    , discordProfileImage
    , discordUserColor
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
    , setColor
    , setDiscordGuildNotificationLevel
    , setDomainWhitelist
    , setEmailNotifications
    , setEmojiSkinTone
    , setGuildNotificationLevel
    , setIcon
    , setLastChannelViewed
    , setLastDiscordChannelViewed
    , setLastDiscordDmViewed
    , setLastDmViewed
    , setLastViewedMessage
    , setName
    , smallProfileImage
    , smallProfileImageRounding
    , toString
    , toStringAlt
    , toStringView
    , userColor
    )

import Array
import Base64
import Codec exposing (Codec)
import CustomEmoji exposing (CustomEmojiData)
import Discord exposing (OptionalData(..))
import DiscordUserData exposing (DiscordUserData, DiscordUserLoadingData)
import Effect.Time as Time
import EmailAddress exposing (EmailAddress)
import Emoji exposing (EmojiConfig, EmojiOrCustomEmoji(..), SkinTone)
import FileStatus exposing (FileHash)
import GuildIcon
import Html exposing (Html)
import Html.Attributes
import Id exposing (AnyGuildOrDmId(..), ChannelId, ChannelMessageId, CustomEmojiId, DiscordGuildOrDmId(..), GuildId, GuildOrDmId(..), Id, StickerId, ThreadMessageId, ThreadRoute(..), ThreadRouteWithMaybeMessage(..), ThreadRouteWithMessage(..), UserId, Viewing_ChannelId, Viewing_DiscordChannelId, Viewing_DmId)
import Json.Decode
import LinkedAndOtherDiscordUsers exposing (DiscordFrontendCurrentUser, LinkedAndOtherDiscordUsers)
import MuteSettings
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
import UserColor exposing (UserColor)
import UserSession exposing (DiscordFrontendUser, UserSession)


{-| Contains sensitive data that should only be accessible by admins, the backend, and the user themselves.
-}
type alias BackendUser =
    { name : PersonName
    , color : UserColor
    , isAdmin : Bool
    , email : EmailAddress
    , recentLoginEmails : List Time.Posix
    , lastLogPageViewed : Id PageId
    , expandedSections : SeqSet AdminUiSection
    , createdAt : Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Time.Posix
    , lastViewedMessage : SeqDict AnyGuildOrDmId (Id ChannelMessageId)
    , lastViewedThreadMessage : SeqDict ( AnyGuildOrDmId, Id ChannelMessageId ) (Id ThreadMessageId)
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
    , muteSettings : MuteSettings.Model
    }


setLastViewedMessage :
    AnyGuildOrDmId
    -> ThreadRouteWithMessage
    ->
        { b
            | lastViewedThreadMessage : SeqDict ( AnyGuildOrDmId, Id ChannelMessageId ) (Id ThreadMessageId)
            , lastViewedMessage : SeqDict AnyGuildOrDmId (Id ChannelMessageId)
        }
    ->
        { b
            | lastViewedThreadMessage : SeqDict ( AnyGuildOrDmId, Id ChannelMessageId ) (Id ThreadMessageId)
            , lastViewedMessage : SeqDict AnyGuildOrDmId (Id ChannelMessageId)
        }
setLastViewedMessage guildOrDmId threadRoute user =
    case threadRoute of
        ViewThreadWithMessage threadMessageId messageId ->
            { user
                | lastViewedThreadMessage =
                    SeqDict.insert ( guildOrDmId, threadMessageId ) messageId user.lastViewedThreadMessage
            }

        NoThreadWithMessage messageId ->
            { user | lastViewedMessage = SeqDict.insert guildOrDmId messageId user.lastViewedMessage }


{-| The emojis to offer as one-click reactions, most used first. `availableCustomEmojis`
is the set of custom emojis that can be used where the reaction is going, so that a
custom emoji picked up somewhere else isn't offered in a Discord conversation, where
reacting with it is rejected.
-}
commonlyUsedEmojis : SeqSet (Id CustomEmojiId) -> FrontendCurrentUser -> List ( EmojiOrCustomEmoji, Int )
commonlyUsedEmojis availableCustomEmojis user =
    Array.foldl
        (\emoji dict ->
            if canUseEmoji availableCustomEmojis emoji then
                SeqDict.update emoji (\maybe -> Maybe.withDefault 0 maybe |> (+) 1 |> Just) dict

            else
                dict
        )
        (SeqDict.fromList
            [ ( EmojiOrCustomEmoji_Emoji Emoji.heart, 0 )
            , ( EmojiOrCustomEmoji_Emoji Emoji.thumbsUp, 0 )
            , ( EmojiOrCustomEmoji_Emoji Emoji.smiley, 0 )
            ]
        )
        user.emojiConfig.lastUsedEmojis
        |> SeqDict.toList
        |> List.sortBy (\( _, count ) -> -count)


canUseEmoji : SeqSet (Id CustomEmojiId) -> EmojiOrCustomEmoji -> Bool
canUseEmoji availableCustomEmojis emoji =
    case emoji of
        EmojiOrCustomEmoji_Emoji _ ->
            True

        EmojiOrCustomEmoji_CustomEmoji customEmojiId ->
            SeqSet.member customEmojiId availableCustomEmojis


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
                    if count > 50 then
                        Array.push emoji (Array.slice (count - 20) count emojiConfig.lastUsedEmojis)

                    else
                        Array.push emoji emojiConfig.lastUsedEmojis
            }
    }


addRecentlyUsedEmojis : List EmojiOrCustomEmoji -> { a | emojiConfig : EmojiConfig } -> { a | emojiConfig : EmojiConfig }
addRecentlyUsedEmojis emojis user =
    List.foldl addRecentlyUsedEmoji user emojis


setEmailNotifications : EmailNotifications -> { a | emailNotifications : EmailNotifications } -> { a | emailNotifications : EmailNotifications }
setEmailNotifications emailNotifications user =
    { user | emailNotifications = emailNotifications }


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
    , color = UserColor.default
    , isAdmin = userIsAdmin
    , email = email
    , recentLoginEmails = []
    , lastLogPageViewed = Id.fromInt 0
    , expandedSections = SeqSet.empty
    , createdAt = createdAt
    , emailNotifications = NeverNotifyMe
    , lastEmailNotification = createdAt
    , lastViewedMessage = SeqDict.empty
    , lastViewedThreadMessage = SeqDict.empty
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
    , emojiConfig = { skinTone = Nothing, lastUsedEmojis = Array.empty }
    , availableStickers = SeqSet.empty
    , availableCustomEmojis = SeqSet.empty
    , muteSettings = MuteSettings.init
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
    Viewing_ChannelId
    -> ThreadRouteWithMaybeMessage
    ->
        { a
            | lastChannelViewed : SeqDict (Id GuildId) ( Id ChannelId, ThreadRoute )
            , directMentions : SeqDict (Id GuildId) (NonemptyDict ( Id ChannelId, ThreadRoute ) OneOrGreater)
            , lastViewedMessage : SeqDict AnyGuildOrDmId (Id ChannelMessageId)
            , lastViewedThreadMessage : SeqDict ( AnyGuildOrDmId, Id ChannelMessageId ) (Id ThreadMessageId)
        }
    ->
        { a
            | lastChannelViewed : SeqDict (Id GuildId) ( Id ChannelId, ThreadRoute )
            , directMentions : SeqDict (Id GuildId) (NonemptyDict ( Id ChannelId, ThreadRoute ) OneOrGreater)
            , lastViewedMessage : SeqDict AnyGuildOrDmId (Id ChannelMessageId)
            , lastViewedThreadMessage : SeqDict ( AnyGuildOrDmId, Id ChannelMessageId ) (Id ThreadMessageId)
        }
setLastChannelViewed id threadRoute user =
    let
        threadRouteNoMessage : ThreadRoute
        threadRouteNoMessage =
            case threadRoute of
                ViewThreadWithMaybeMessage threadId _ ->
                    ViewThread threadId

                NoThreadWithMaybeMessage _ ->
                    NoThread

        user2 =
            { user
                | lastChannelViewed = SeqDict.insert id.guildId ( id.channelId, threadRouteNoMessage ) user.lastChannelViewed
                , directMentions =
                    SeqDict.update
                        id.guildId
                        (\maybeDict ->
                            case maybeDict of
                                Just dict ->
                                    NonemptyDict.toSeqDict dict
                                        |> SeqDict.remove ( id.channelId, threadRouteNoMessage )
                                        |> NonemptyDict.fromSeqDict

                                Nothing ->
                                    Nothing
                        )
                        user.directMentions
            }
    in
    case threadRoute of
        ViewThreadWithMaybeMessage threadId (Just messageId) ->
            { user2
                | lastViewedThreadMessage =
                    SeqDict.insert
                        ( GuildOrDmId (GuildOrDmId_Guild id), threadId )
                        messageId
                        user2.lastViewedThreadMessage
            }

        ViewThreadWithMaybeMessage _ Nothing ->
            user2

        NoThreadWithMaybeMessage (Just messageId) ->
            { user2
                | lastViewedMessage =
                    SeqDict.insert (GuildOrDmId (GuildOrDmId_Guild id)) messageId user2.lastViewedMessage
            }

        NoThreadWithMaybeMessage Nothing ->
            user2


setLastDiscordChannelViewed :
    Viewing_DiscordChannelId
    -> ThreadRouteWithMaybeMessage
    ->
        { a
            | lastDiscordChannelViewed : SeqDict (Discord.Id Discord.GuildId) ( Discord.Id Discord.ChannelId, ThreadRoute )
            , discordDirectMentions : SeqDict (Discord.Id Discord.GuildId) (NonemptyDict ( Discord.Id Discord.ChannelId, ThreadRoute ) OneOrGreater)
            , lastViewedMessage : SeqDict AnyGuildOrDmId (Id ChannelMessageId)
            , lastViewedThreadMessage : SeqDict ( AnyGuildOrDmId, Id ChannelMessageId ) (Id ThreadMessageId)
        }
    ->
        { a
            | lastDiscordChannelViewed : SeqDict (Discord.Id Discord.GuildId) ( Discord.Id Discord.ChannelId, ThreadRoute )
            , discordDirectMentions : SeqDict (Discord.Id Discord.GuildId) (NonemptyDict ( Discord.Id Discord.ChannelId, ThreadRoute ) OneOrGreater)
            , lastViewedMessage : SeqDict AnyGuildOrDmId (Id ChannelMessageId)
            , lastViewedThreadMessage : SeqDict ( AnyGuildOrDmId, Id ChannelMessageId ) (Id ThreadMessageId)
        }
setLastDiscordChannelViewed id threadRoute user =
    let
        threadRouteNoMessage : ThreadRoute
        threadRouteNoMessage =
            case threadRoute of
                ViewThreadWithMaybeMessage threadId _ ->
                    ViewThread threadId

                NoThreadWithMaybeMessage _ ->
                    NoThread

        user2 =
            { user
                | lastDiscordChannelViewed =
                    SeqDict.insert id.guildId ( id.channelId, threadRouteNoMessage ) user.lastDiscordChannelViewed
                , discordDirectMentions =
                    SeqDict.update
                        id.guildId
                        (\maybeDict ->
                            case maybeDict of
                                Just dict ->
                                    NonemptyDict.toSeqDict dict
                                        |> SeqDict.remove ( id.channelId, threadRouteNoMessage )
                                        |> NonemptyDict.fromSeqDict

                                Nothing ->
                                    Nothing
                        )
                        user.discordDirectMentions
            }
    in
    case threadRoute of
        ViewThreadWithMaybeMessage threadId (Just messageId) ->
            { user2
                | lastViewedThreadMessage =
                    SeqDict.insert
                        ( DiscordGuildOrDmId (DiscordGuildOrDmId_Guild id), threadId )
                        messageId
                        user2.lastViewedThreadMessage
            }

        ViewThreadWithMaybeMessage _ Nothing ->
            user2

        NoThreadWithMaybeMessage (Just messageId) ->
            { user2
                | lastViewedMessage =
                    SeqDict.insert
                        (DiscordGuildOrDmId (DiscordGuildOrDmId_Guild id))
                        messageId
                        user2.lastViewedMessage
            }

        NoThreadWithMaybeMessage Nothing ->
            user2


setLastDmViewed :
    Viewing_DmId
    -> ThreadRouteWithMaybeMessage
    ->
        { a
            | lastDmViewed : LastDmViewed
            , lastViewedMessage : SeqDict AnyGuildOrDmId (Id ChannelMessageId)
            , lastViewedThreadMessage : SeqDict ( AnyGuildOrDmId, Id ChannelMessageId ) (Id ThreadMessageId)
        }
    ->
        { a
            | lastDmViewed : LastDmViewed
            , lastViewedMessage : SeqDict AnyGuildOrDmId (Id ChannelMessageId)
            , lastViewedThreadMessage : SeqDict ( AnyGuildOrDmId, Id ChannelMessageId ) (Id ThreadMessageId)
        }
setLastDmViewed id threadRoute user =
    let
        user2 =
            { user
                | lastDmViewed =
                    DmChannelLastViewed
                        id.otherUserId
                        (case threadRoute of
                            ViewThreadWithMaybeMessage threadId _ ->
                                ViewThread threadId

                            NoThreadWithMaybeMessage _ ->
                                NoThread
                        )
            }
    in
    case threadRoute of
        ViewThreadWithMaybeMessage threadId (Just messageId) ->
            { user2
                | lastViewedThreadMessage =
                    SeqDict.insert
                        ( GuildOrDmId (GuildOrDmId_Dm id), threadId )
                        messageId
                        user2.lastViewedThreadMessage
            }

        ViewThreadWithMaybeMessage _ Nothing ->
            user2

        NoThreadWithMaybeMessage (Just messageId) ->
            { user2
                | lastViewedMessage =
                    SeqDict.insert
                        (GuildOrDmId (GuildOrDmId_Dm id))
                        messageId
                        user2.lastViewedMessage
            }

        NoThreadWithMaybeMessage Nothing ->
            user2


setLastDiscordDmViewed :
    Discord.Id Discord.UserId
    -> Discord.Id Discord.PrivateChannelId
    -> Maybe (Id ChannelMessageId)
    -> { a | lastDmViewed : LastDmViewed, lastViewedMessage : SeqDict AnyGuildOrDmId (Id ChannelMessageId) }
    -> { a | lastDmViewed : LastDmViewed, lastViewedMessage : SeqDict AnyGuildOrDmId (Id ChannelMessageId) }
setLastDiscordDmViewed currentUserId channelId maybeMessageId user =
    case maybeMessageId of
        Just messageId ->
            { user
                | lastDmViewed = DiscordDmChannelLastViewed channelId
                , lastViewedMessage =
                    SeqDict.insert
                        (DiscordGuildOrDmId (DiscordGuildOrDmId_Dm { currentUserId = currentUserId, channelId = channelId }))
                        messageId
                        user.lastViewedMessage
            }

        Nothing ->
            { user | lastDmViewed = DiscordDmChannelLastViewed channelId }


setName : PersonName -> { b | name : PersonName } -> { b | name : PersonName }
setName name user =
    { user | name = name }


setColor : UserColor -> { b | color : UserColor } -> { b | color : UserColor }
setColor color user =
    { user | color = color }


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
    | WebsocketCloseEventsSection
    | SessionsSection
    | WordSpellingGameSwedishSection
    | WebCodecsTestSection


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

        WebCodecsTestSection ->
            "WebCodecs streaming test"

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
    , color : UserColor
    , icon : Maybe FileHash
    }


discordUserDataToFrontendUser : NonemptyDict (Id UserId) BackendUser -> DiscordUserData -> DiscordFrontendUser
discordUserDataToFrontendUser users discordUserData =
    case discordUserData of
        DiscordUserData.BasicData data ->
            { name = PersonName.fromStringLossy data.user.username
            , icon = data.icon
            , color = UserColor.default
            }

        DiscordUserData.FullData data ->
            { name = PersonName.fromStringLossy data.user.username
            , icon = data.icon
            , color =
                case NonemptyDict.get data.linkedTo users of
                    Just linkedUser ->
                        linkedUser.color

                    Nothing ->
                        UserColor.default
            }

        DiscordUserData.NeedsAuthAgain data ->
            { name = PersonName.fromStringLossy data.user.username
            , icon = data.icon
            , color =
                case NonemptyDict.get data.linkedTo users of
                    Just linkedUser ->
                        linkedUser.color

                    Nothing ->
                        UserColor.default
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
    , devicePixelRatio : Float
    , stickers : SeqDict (Id StickerId) StickerData
    , customEmojis : SeqDict (Id CustomEmojiId) CustomEmojiData
    , emojiData : Maybe Emoji.CachedEmojiData
    }


allUsers : LocalUser -> SeqDict (Id UserId) FrontendUser
allUsers localUser =
    SeqDict.insert
        localUser.session.userId
        (backendToFrontendForUser localUser.user)
        localUser.otherUsers


discordFullDataUserToFrontendCurrentUser :
    NonemptyDict (Id UserId) BackendUser
    -> Bool
    -> { a | user : Discord.User, icon : Maybe FileHash, linkedAt : Time.Posix, linkedTo : Id UserId }
    -> DiscordUserLoadingData
    -> DiscordFrontendCurrentUser
discordFullDataUserToFrontendCurrentUser users needsAuthAgain data isLoadingData =
    { name = PersonName.fromStringLossy data.user.username
    , icon = data.icon
    , color =
        case NonemptyDict.get data.linkedTo users of
            Just linkedUser ->
                linkedUser.color

            Nothing ->
                UserColor.default
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
    , color = user.color
    , isAdmin = user.isAdmin
    , email = user.email
    , recentLoginEmails = user.recentLoginEmails
    , lastLogPageViewed = user.lastLogPageViewed
    , expandedSections = user.expandedSections
    , createdAt = user.createdAt
    , emailNotifications = user.emailNotifications
    , lastEmailNotification = user.lastEmailNotification
    , lastViewedMessage = user.lastViewedMessage
    , lastViewedThreadMessage = user.lastViewedThreadMessage
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
    , muteSettings = user.muteSettings
    }


{-| Convert a BackendUser to a FrontendUser without any permission checks
-}
backendToFrontend : FrontendCurrentUser -> FrontendUser
backendToFrontend user =
    { name = user.name
    , color = user.color
    , icon = user.icon
    }


{-| Convert a BackendUser to a FrontendUser while only including data the current user has permission to see
-}
backendToFrontendForUser :
    { a | name : PersonName, color : UserColor, icon : Maybe FileHash }
    -> FrontendUser
backendToFrontendForUser user =
    { name = user.name
    , color = user.color
    , icon = user.icon
    }


toString : userId -> SeqDict userId { a | name : PersonName } -> String
toString userId allUsers2 =
    case SeqDict.get userId allUsers2 of
        Just user ->
            PersonName.toString user.name

        Nothing ->
            "<missing>"


toStringView : userId -> SeqDict userId { a | name : PersonName, color : UserColor } -> Ui.Element msg
toStringView userId allUsers2 =
    case SeqDict.get userId allUsers2 of
        Just user ->
            PersonName.toString user.name
                |> Ui.text
                |> Ui.el [ Ui.Font.bold, Ui.Font.color (UserColor.toColor user.color) ]

        Nothing ->
            Ui.text "<missing>"


toStringAlt : Id UserId -> LocalUser -> String
toStringAlt userId local =
    if local.session.userId == userId then
        PersonName.toString local.user.name

    else
        case SeqDict.get userId local.otherUsers of
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


smallProfileImageRounding : Int
smallProfileImageRounding =
    4


userColor : LocalUser -> Id UserId -> UserColor
userColor localUser userId =
    case getUser userId localUser of
        Just user ->
            user.color

        Nothing ->
            UserColor.default


discordUserColor : LocalUser -> Discord.Id Discord.UserId -> UserColor
discordUserColor localUser userId =
    case getDiscordUser userId localUser of
        Just user ->
            user.color

        Nothing ->
            UserColor.default


profileOutlineColor : UserColor -> String
profileOutlineColor userColor2 =
    UserColor.toColor userColor2
        |> MyUi.colorWithAlpha 0.5
        |> MyUi.colorToStyle


profileImage : Maybe { a | color : UserColor, icon : Maybe FileHash } -> Element msg
profileImage user =
    profileImageHtml user |> Ui.html


smallProfileImage : Maybe { a | color : UserColor, icon : Maybe FileHash } -> Element msg
smallProfileImage user =
    let
        rounding =
            Ui.roundedWith
                { topLeft = smallProfileImageRounding
                , bottomLeft = smallProfileImageRounding
                , topRight = 0
                , bottomRight = 0
                }
    in
    case user of
        Just user2 ->
            case user2.icon of
                Just fileHash ->
                    Ui.imageLazy
                        [ Ui.width (Ui.px (smallProfileImageSize + 4))
                        , Ui.height (Ui.px (smallProfileImageSize + 4))
                        , Ui.move { x = -2, y = -2, z = 0 }
                        ]
                        { source = FileStatus.fileUrl FileStatus.pngContent fileHash
                        , description = ""
                        , onLoad = Nothing
                        }
                        |> Ui.el
                            [ Ui.width (Ui.px smallProfileImageSize)
                            , Ui.height (Ui.px smallProfileImageSize)
                            , Ui.clip
                            , rounding
                            , MyUi.htmlStyle "outline" ("solid 1px " ++ profileOutlineColor user2.color)
                            , MyUi.htmlStyle "outline-offset" "-1px"
                            , MyUi.noPointerEvents
                            ]

                Nothing ->
                    GuildIcon.defaultUser False smallProfileImageSize rounding user2.color

        Nothing ->
            GuildIcon.defaultUser False smallProfileImageSize rounding UserColor.default


profileImageHtml : Maybe { a | color : UserColor, icon : Maybe FileHash } -> Html msg
profileImageHtml user =
    case user of
        Just user2 ->
            case user2.icon of
                Just fileHash ->
                    profileImgHtml fileHash user2.color

                Nothing ->
                    GuildIcon.defaultUserHtml profileImageSize 8 user2.color

        Nothing ->
            GuildIcon.defaultUserHtml profileImageSize 8 UserColor.default


profileImgHtml : FileHash -> UserColor -> Html msg
profileImgHtml fileHash color =
    Html.img
        [ Html.Attributes.style "border-radius" (String.fromInt profileImageRounding ++ "px")
        , Html.Attributes.style "width" (String.fromInt profileImageSize ++ "px")
        , Html.Attributes.style "height" (String.fromInt profileImageSize ++ "px")
        , Html.Attributes.style "outline" ("solid 1px " ++ profileOutlineColor color)
        , Html.Attributes.style "outline-offset" "-1px"
        , Html.Attributes.src (FileStatus.fileUrl FileStatus.pngContent fileHash)
        , MyUi.lazyLoading
        ]
        []


discordProfileImage : Discord.Id Discord.UserId -> Maybe FileHash -> Element msg
discordProfileImage userId maybeFileHash =
    Ui.imageLazy
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


profileImageNoRounding : Maybe { a | color : UserColor, icon : Maybe FileHash } -> Element msg
profileImageNoRounding user =
    case user of
        Just user2 ->
            case user2.icon of
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
                    GuildIcon.defaultUser False profileImageSize Ui.noAttr user2.color

        Nothing ->
            GuildIcon.defaultUser False profileImageSize Ui.noAttr UserColor.default


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
                , Ui.inFront (Ui.el [ Ui.move { x = 15, y = 15, z = 0 } ] (discordSmallProfileImage two))
                , Ui.inFront (discordSmallProfileImage one)
                ]
                Ui.none

        [ one, two, three ] ->
            Ui.el
                [ Ui.width (Ui.px 55)
                , Ui.height (Ui.px 40)
                , Ui.inFront (Ui.el [ Ui.move { x = 30, y = 0, z = 0 } ] (discordSmallProfileImage three))
                , Ui.inFront (Ui.el [ Ui.move { x = 15, y = 15, z = 0 } ] (discordSmallProfileImage two))
                , Ui.inFront (discordSmallProfileImage one)
                ]
                Ui.none

        [ one, two, three, four ] ->
            Ui.el
                [ Ui.width (Ui.px 70)
                , Ui.height (Ui.px 40)
                , Ui.inFront (Ui.el [ Ui.move { x = 45, y = 15, z = 0 } ] (discordSmallProfileImage four))
                , Ui.inFront (Ui.el [ Ui.move { x = 30, y = 0, z = 0 } ] (discordSmallProfileImage three))
                , Ui.inFront (Ui.el [ Ui.move { x = 15, y = 15, z = 0 } ] (discordSmallProfileImage two))
                , Ui.inFront (discordSmallProfileImage one)
                ]
                Ui.none

        one :: two :: three :: rest ->
            Ui.el
                [ Ui.width (Ui.px 70)
                , Ui.height (Ui.px 40)
                , Ui.inFront (Ui.el [ Ui.move { x = 30, y = 0, z = 0 } ] (discordSmallProfileImage three))
                , Ui.inFront (Ui.el [ Ui.move { x = 15, y = 15, z = 0 } ] (discordSmallProfileImage two))
                , Ui.inFront (discordSmallProfileImage one)
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


discordSmallProfileImage : ( Discord.Id Discord.UserId, Maybe FileHash ) -> Element msg
discordSmallProfileImage ( userId, maybeFileHash ) =
    Ui.imageLazy
        [ Ui.rounded smallProfileImageRounding
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
