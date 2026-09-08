module Evergreen.V373.User exposing (..)

import Effect.Time
import Evergreen.V373.CustomEmoji
import Evergreen.V373.Discord
import Evergreen.V373.EmailAddress
import Evergreen.V373.Emoji
import Evergreen.V373.Encryption
import Evergreen.V373.FileStatus
import Evergreen.V373.Id
import Evergreen.V373.LinkedAndOtherDiscordUsers
import Evergreen.V373.Message
import Evergreen.V373.MuteSettings
import Evergreen.V373.NonemptyDict
import Evergreen.V373.OneOrGreater
import Evergreen.V373.Pagination
import Evergreen.V373.PersonName
import Evergreen.V373.RichText
import Evergreen.V373.Sticker
import Evergreen.V373.UserAgent
import Evergreen.V373.UserColor
import Evergreen.V373.UserSession
import Evergreen.V373.X25519
import SeqDict
import SeqSet


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


type EmailNotifications
    = NeverNotifyMe
    | NotifyMeWhenMentioned


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention


type LastDmViewed
    = DmChannelLastViewed (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId) Evergreen.V373.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V373.Discord.Id Evergreen.V373.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V373.PersonName.PersonName
    , color : Evergreen.V373.UserColor.UserColor
    , isAdmin : Bool
    , email : Evergreen.V373.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V373.Id.Id Evergreen.V373.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V373.Id.AnyGuildOrDmId (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V373.Id.AnyGuildOrDmId, Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId ) (Evergreen.V373.Id.Id Evergreen.V373.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId) ( Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelId, Evergreen.V373.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId) ( Evergreen.V373.Discord.Id Evergreen.V373.Discord.ChannelId, Evergreen.V373.Id.ThreadRoute )
    , icon : Maybe Evergreen.V373.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId) (Evergreen.V373.NonemptyDict.NonemptyDict ( Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelId, Evergreen.V373.Id.ThreadRoute ) Evergreen.V373.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId) (Evergreen.V373.NonemptyDict.NonemptyDict ( Evergreen.V373.Discord.Id Evergreen.V373.Discord.ChannelId, Evergreen.V373.Id.ThreadRoute ) Evergreen.V373.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V373.RichText.Domain
    , emojiConfig : Evergreen.V373.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V373.Id.Id Evergreen.V373.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V373.Id.Id Evergreen.V373.Id.CustomEmojiId)
    , muteSettings : Evergreen.V373.MuteSettings.Model
    , publicKey : Maybe Evergreen.V373.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V373.PersonName.PersonName
    , color : Evergreen.V373.UserColor.UserColor
    , icon : Maybe Evergreen.V373.FileStatus.FileHash
    , publicKey : Maybe Evergreen.V373.X25519.PublicKey
    }


type alias LocalUser =
    { session : Evergreen.V373.UserSession.UserSession
    , currentlyViewing : Evergreen.V373.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V373.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V373.UserAgent.UserAgent
    , devicePixelRatio : Float
    , stickers : SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.StickerId) Evergreen.V373.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.CustomEmojiId) Evergreen.V373.CustomEmoji.CustomEmojiData
    , emojiData : Maybe Evergreen.V373.Emoji.CachedEmojiData
    , decryptedMessages : SeqDict.SeqDict Evergreen.V373.Encryption.BytesHash (Result () (Evergreen.V373.Message.MessageContent (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId)))
    }
