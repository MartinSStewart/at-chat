module Evergreen.V370.User exposing (..)

import Effect.Time
import Evergreen.V370.CustomEmoji
import Evergreen.V370.Discord
import Evergreen.V370.EmailAddress
import Evergreen.V370.Emoji
import Evergreen.V370.Encryption
import Evergreen.V370.FileStatus
import Evergreen.V370.Id
import Evergreen.V370.LinkedAndOtherDiscordUsers
import Evergreen.V370.Message
import Evergreen.V370.MuteSettings
import Evergreen.V370.NonemptyDict
import Evergreen.V370.OneOrGreater
import Evergreen.V370.Pagination
import Evergreen.V370.PersonName
import Evergreen.V370.RichText
import Evergreen.V370.Sticker
import Evergreen.V370.UserAgent
import Evergreen.V370.UserColor
import Evergreen.V370.UserSession
import Evergreen.V370.X25519
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
    = DmChannelLastViewed (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId) Evergreen.V370.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V370.Discord.Id Evergreen.V370.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V370.PersonName.PersonName
    , color : Evergreen.V370.UserColor.UserColor
    , isAdmin : Bool
    , email : Evergreen.V370.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V370.Id.Id Evergreen.V370.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V370.Id.AnyGuildOrDmId (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V370.Id.AnyGuildOrDmId, Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId ) (Evergreen.V370.Id.Id Evergreen.V370.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId) ( Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelId, Evergreen.V370.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId) ( Evergreen.V370.Discord.Id Evergreen.V370.Discord.ChannelId, Evergreen.V370.Id.ThreadRoute )
    , icon : Maybe Evergreen.V370.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId) (Evergreen.V370.NonemptyDict.NonemptyDict ( Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelId, Evergreen.V370.Id.ThreadRoute ) Evergreen.V370.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId) (Evergreen.V370.NonemptyDict.NonemptyDict ( Evergreen.V370.Discord.Id Evergreen.V370.Discord.ChannelId, Evergreen.V370.Id.ThreadRoute ) Evergreen.V370.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V370.RichText.Domain
    , emojiConfig : Evergreen.V370.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V370.Id.Id Evergreen.V370.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V370.Id.Id Evergreen.V370.Id.CustomEmojiId)
    , muteSettings : Evergreen.V370.MuteSettings.Model
    , publicKey : Maybe Evergreen.V370.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V370.PersonName.PersonName
    , color : Evergreen.V370.UserColor.UserColor
    , icon : Maybe Evergreen.V370.FileStatus.FileHash
    , publicKey : Maybe Evergreen.V370.X25519.PublicKey
    }


type alias LocalUser =
    { session : Evergreen.V370.UserSession.UserSession
    , currentlyViewing : Evergreen.V370.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V370.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V370.UserAgent.UserAgent
    , devicePixelRatio : Float
    , stickers : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.StickerId) Evergreen.V370.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.CustomEmojiId) Evergreen.V370.CustomEmoji.CustomEmojiData
    , emojiData : Maybe Evergreen.V370.Emoji.CachedEmojiData
    , decryptedMessages : SeqDict.SeqDict Evergreen.V370.Encryption.BytesHash (Result () (Evergreen.V370.Message.MessageContent (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId)))
    }
