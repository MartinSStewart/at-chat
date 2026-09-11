module Evergreen.V378.User exposing (..)

import Effect.Time
import Evergreen.V378.CustomEmoji
import Evergreen.V378.Discord
import Evergreen.V378.EmailAddress
import Evergreen.V378.Emoji
import Evergreen.V378.Encryption
import Evergreen.V378.FileStatus
import Evergreen.V378.Id
import Evergreen.V378.LinkedAndOtherDiscordUsers
import Evergreen.V378.Message
import Evergreen.V378.MuteSettings
import Evergreen.V378.NonemptyDict
import Evergreen.V378.OneOrGreater
import Evergreen.V378.Pagination
import Evergreen.V378.PersonName
import Evergreen.V378.RichText
import Evergreen.V378.Sticker
import Evergreen.V378.UserAgent
import Evergreen.V378.UserColor
import Evergreen.V378.UserSession
import Evergreen.V378.X25519
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
    | BackendMsgLogsSection
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
    = DmChannelLastViewed (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId) Evergreen.V378.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V378.Discord.Id Evergreen.V378.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V378.PersonName.PersonName
    , color : Evergreen.V378.UserColor.UserColor
    , isAdmin : Bool
    , email : Evergreen.V378.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V378.Id.Id Evergreen.V378.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V378.Id.AnyGuildOrDmId (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V378.Id.AnyGuildOrDmId, Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelMessageId ) (Evergreen.V378.Id.Id Evergreen.V378.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId) ( Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelId, Evergreen.V378.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId) ( Evergreen.V378.Discord.Id Evergreen.V378.Discord.ChannelId, Evergreen.V378.Id.ThreadRoute )
    , icon : Maybe Evergreen.V378.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId) (Evergreen.V378.NonemptyDict.NonemptyDict ( Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelId, Evergreen.V378.Id.ThreadRoute ) Evergreen.V378.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId) (Evergreen.V378.NonemptyDict.NonemptyDict ( Evergreen.V378.Discord.Id Evergreen.V378.Discord.ChannelId, Evergreen.V378.Id.ThreadRoute ) Evergreen.V378.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V378.RichText.Domain
    , emojiConfig : Evergreen.V378.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V378.Id.Id Evergreen.V378.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V378.Id.Id Evergreen.V378.Id.CustomEmojiId)
    , muteSettings : Evergreen.V378.MuteSettings.Model
    , publicKey : Maybe Evergreen.V378.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V378.PersonName.PersonName
    , color : Evergreen.V378.UserColor.UserColor
    , icon : Maybe Evergreen.V378.FileStatus.FileHash
    , publicKey : Maybe Evergreen.V378.X25519.PublicKey
    }


type alias LocalUser =
    { session : Evergreen.V378.UserSession.UserSession
    , currentlyViewing : Evergreen.V378.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V378.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V378.UserAgent.UserAgent
    , devicePixelRatio : Float
    , stickers : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.StickerId) Evergreen.V378.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.CustomEmojiId) Evergreen.V378.CustomEmoji.CustomEmojiData
    , emojiData : Maybe Evergreen.V378.Emoji.CachedEmojiData
    , decryptedMessages : SeqDict.SeqDict Evergreen.V378.Encryption.BytesHash (Result () (Evergreen.V378.Message.MessageContent (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId)))
    }
