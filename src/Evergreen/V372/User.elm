module Evergreen.V372.User exposing (..)

import Effect.Time
import Evergreen.V372.CustomEmoji
import Evergreen.V372.Discord
import Evergreen.V372.EmailAddress
import Evergreen.V372.Emoji
import Evergreen.V372.Encryption
import Evergreen.V372.FileStatus
import Evergreen.V372.Id
import Evergreen.V372.LinkedAndOtherDiscordUsers
import Evergreen.V372.Message
import Evergreen.V372.MuteSettings
import Evergreen.V372.NonemptyDict
import Evergreen.V372.OneOrGreater
import Evergreen.V372.Pagination
import Evergreen.V372.PersonName
import Evergreen.V372.RichText
import Evergreen.V372.Sticker
import Evergreen.V372.UserAgent
import Evergreen.V372.UserColor
import Evergreen.V372.UserSession
import Evergreen.V372.X25519
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
    = DmChannelLastViewed (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId) Evergreen.V372.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V372.Discord.Id Evergreen.V372.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V372.PersonName.PersonName
    , color : Evergreen.V372.UserColor.UserColor
    , isAdmin : Bool
    , email : Evergreen.V372.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V372.Id.Id Evergreen.V372.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V372.Id.AnyGuildOrDmId (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V372.Id.AnyGuildOrDmId, Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId ) (Evergreen.V372.Id.Id Evergreen.V372.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId) ( Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelId, Evergreen.V372.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId) ( Evergreen.V372.Discord.Id Evergreen.V372.Discord.ChannelId, Evergreen.V372.Id.ThreadRoute )
    , icon : Maybe Evergreen.V372.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId) (Evergreen.V372.NonemptyDict.NonemptyDict ( Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelId, Evergreen.V372.Id.ThreadRoute ) Evergreen.V372.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId) (Evergreen.V372.NonemptyDict.NonemptyDict ( Evergreen.V372.Discord.Id Evergreen.V372.Discord.ChannelId, Evergreen.V372.Id.ThreadRoute ) Evergreen.V372.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V372.RichText.Domain
    , emojiConfig : Evergreen.V372.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V372.Id.Id Evergreen.V372.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V372.Id.Id Evergreen.V372.Id.CustomEmojiId)
    , muteSettings : Evergreen.V372.MuteSettings.Model
    , publicKey : Maybe Evergreen.V372.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V372.PersonName.PersonName
    , color : Evergreen.V372.UserColor.UserColor
    , icon : Maybe Evergreen.V372.FileStatus.FileHash
    , publicKey : Maybe Evergreen.V372.X25519.PublicKey
    }


type alias LocalUser =
    { session : Evergreen.V372.UserSession.UserSession
    , currentlyViewing : Evergreen.V372.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V372.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V372.UserAgent.UserAgent
    , devicePixelRatio : Float
    , stickers : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.StickerId) Evergreen.V372.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.CustomEmojiId) Evergreen.V372.CustomEmoji.CustomEmojiData
    , emojiData : Maybe Evergreen.V372.Emoji.CachedEmojiData
    , decryptedMessages : SeqDict.SeqDict Evergreen.V372.Encryption.BytesHash (Result () (Evergreen.V372.Message.MessageContent (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId)))
    }
