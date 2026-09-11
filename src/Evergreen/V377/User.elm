module Evergreen.V377.User exposing (..)

import Effect.Time
import Evergreen.V377.CustomEmoji
import Evergreen.V377.Discord
import Evergreen.V377.EmailAddress
import Evergreen.V377.Emoji
import Evergreen.V377.Encryption
import Evergreen.V377.FileStatus
import Evergreen.V377.Id
import Evergreen.V377.LinkedAndOtherDiscordUsers
import Evergreen.V377.Message
import Evergreen.V377.MuteSettings
import Evergreen.V377.NonemptyDict
import Evergreen.V377.OneOrGreater
import Evergreen.V377.Pagination
import Evergreen.V377.PersonName
import Evergreen.V377.RichText
import Evergreen.V377.Sticker
import Evergreen.V377.UserAgent
import Evergreen.V377.UserColor
import Evergreen.V377.UserSession
import Evergreen.V377.X25519
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
    = DmChannelLastViewed (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId) Evergreen.V377.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V377.Discord.Id Evergreen.V377.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V377.PersonName.PersonName
    , color : Evergreen.V377.UserColor.UserColor
    , isAdmin : Bool
    , email : Evergreen.V377.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V377.Id.Id Evergreen.V377.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V377.Id.AnyGuildOrDmId (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V377.Id.AnyGuildOrDmId, Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId ) (Evergreen.V377.Id.Id Evergreen.V377.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId) ( Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelId, Evergreen.V377.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId) ( Evergreen.V377.Discord.Id Evergreen.V377.Discord.ChannelId, Evergreen.V377.Id.ThreadRoute )
    , icon : Maybe Evergreen.V377.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId) (Evergreen.V377.NonemptyDict.NonemptyDict ( Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelId, Evergreen.V377.Id.ThreadRoute ) Evergreen.V377.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId) (Evergreen.V377.NonemptyDict.NonemptyDict ( Evergreen.V377.Discord.Id Evergreen.V377.Discord.ChannelId, Evergreen.V377.Id.ThreadRoute ) Evergreen.V377.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V377.RichText.Domain
    , emojiConfig : Evergreen.V377.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V377.Id.Id Evergreen.V377.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V377.Id.Id Evergreen.V377.Id.CustomEmojiId)
    , muteSettings : Evergreen.V377.MuteSettings.Model
    , publicKey : Maybe Evergreen.V377.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V377.PersonName.PersonName
    , color : Evergreen.V377.UserColor.UserColor
    , icon : Maybe Evergreen.V377.FileStatus.FileHash
    , publicKey : Maybe Evergreen.V377.X25519.PublicKey
    }


type alias LocalUser =
    { session : Evergreen.V377.UserSession.UserSession
    , currentlyViewing : Evergreen.V377.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V377.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V377.UserAgent.UserAgent
    , devicePixelRatio : Float
    , stickers : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.StickerId) Evergreen.V377.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.CustomEmojiId) Evergreen.V377.CustomEmoji.CustomEmojiData
    , emojiData : Maybe Evergreen.V377.Emoji.CachedEmojiData
    , decryptedMessages : SeqDict.SeqDict Evergreen.V377.Encryption.BytesHash (Result () (Evergreen.V377.Message.MessageContent (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId)))
    }
