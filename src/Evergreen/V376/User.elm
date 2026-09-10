module Evergreen.V376.User exposing (..)

import Effect.Time
import Evergreen.V376.CustomEmoji
import Evergreen.V376.Discord
import Evergreen.V376.EmailAddress
import Evergreen.V376.Emoji
import Evergreen.V376.Encryption
import Evergreen.V376.FileStatus
import Evergreen.V376.Id
import Evergreen.V376.LinkedAndOtherDiscordUsers
import Evergreen.V376.Message
import Evergreen.V376.MuteSettings
import Evergreen.V376.NonemptyDict
import Evergreen.V376.OneOrGreater
import Evergreen.V376.Pagination
import Evergreen.V376.PersonName
import Evergreen.V376.RichText
import Evergreen.V376.Sticker
import Evergreen.V376.UserAgent
import Evergreen.V376.UserColor
import Evergreen.V376.UserSession
import Evergreen.V376.X25519
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
    = DmChannelLastViewed (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId) Evergreen.V376.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V376.Discord.Id Evergreen.V376.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V376.PersonName.PersonName
    , color : Evergreen.V376.UserColor.UserColor
    , isAdmin : Bool
    , email : Evergreen.V376.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V376.Id.Id Evergreen.V376.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V376.Id.AnyGuildOrDmId (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V376.Id.AnyGuildOrDmId, Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelMessageId ) (Evergreen.V376.Id.Id Evergreen.V376.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId) ( Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelId, Evergreen.V376.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId) ( Evergreen.V376.Discord.Id Evergreen.V376.Discord.ChannelId, Evergreen.V376.Id.ThreadRoute )
    , icon : Maybe Evergreen.V376.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId) (Evergreen.V376.NonemptyDict.NonemptyDict ( Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelId, Evergreen.V376.Id.ThreadRoute ) Evergreen.V376.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId) (Evergreen.V376.NonemptyDict.NonemptyDict ( Evergreen.V376.Discord.Id Evergreen.V376.Discord.ChannelId, Evergreen.V376.Id.ThreadRoute ) Evergreen.V376.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V376.RichText.Domain
    , emojiConfig : Evergreen.V376.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V376.Id.Id Evergreen.V376.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V376.Id.Id Evergreen.V376.Id.CustomEmojiId)
    , muteSettings : Evergreen.V376.MuteSettings.Model
    , publicKey : Maybe Evergreen.V376.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V376.PersonName.PersonName
    , color : Evergreen.V376.UserColor.UserColor
    , icon : Maybe Evergreen.V376.FileStatus.FileHash
    , publicKey : Maybe Evergreen.V376.X25519.PublicKey
    }


type alias LocalUser =
    { session : Evergreen.V376.UserSession.UserSession
    , currentlyViewing : Evergreen.V376.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V376.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V376.UserAgent.UserAgent
    , devicePixelRatio : Float
    , stickers : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.StickerId) Evergreen.V376.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.CustomEmojiId) Evergreen.V376.CustomEmoji.CustomEmojiData
    , emojiData : Maybe Evergreen.V376.Emoji.CachedEmojiData
    , decryptedMessages : SeqDict.SeqDict Evergreen.V376.Encryption.BytesHash (Result () (Evergreen.V376.Message.MessageContent (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId)))
    }
