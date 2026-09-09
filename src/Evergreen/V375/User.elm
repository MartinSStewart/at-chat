module Evergreen.V375.User exposing (..)

import Effect.Time
import Evergreen.V375.CustomEmoji
import Evergreen.V375.Discord
import Evergreen.V375.EmailAddress
import Evergreen.V375.Emoji
import Evergreen.V375.Encryption
import Evergreen.V375.FileStatus
import Evergreen.V375.Id
import Evergreen.V375.LinkedAndOtherDiscordUsers
import Evergreen.V375.Message
import Evergreen.V375.MuteSettings
import Evergreen.V375.NonemptyDict
import Evergreen.V375.OneOrGreater
import Evergreen.V375.Pagination
import Evergreen.V375.PersonName
import Evergreen.V375.RichText
import Evergreen.V375.Sticker
import Evergreen.V375.UserAgent
import Evergreen.V375.UserColor
import Evergreen.V375.UserSession
import Evergreen.V375.X25519
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
    = DmChannelLastViewed (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId) Evergreen.V375.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V375.Discord.Id Evergreen.V375.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V375.PersonName.PersonName
    , color : Evergreen.V375.UserColor.UserColor
    , isAdmin : Bool
    , email : Evergreen.V375.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V375.Id.Id Evergreen.V375.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V375.Id.AnyGuildOrDmId (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V375.Id.AnyGuildOrDmId, Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelMessageId ) (Evergreen.V375.Id.Id Evergreen.V375.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId) ( Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelId, Evergreen.V375.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId) ( Evergreen.V375.Discord.Id Evergreen.V375.Discord.ChannelId, Evergreen.V375.Id.ThreadRoute )
    , icon : Maybe Evergreen.V375.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId) (Evergreen.V375.NonemptyDict.NonemptyDict ( Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelId, Evergreen.V375.Id.ThreadRoute ) Evergreen.V375.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId) (Evergreen.V375.NonemptyDict.NonemptyDict ( Evergreen.V375.Discord.Id Evergreen.V375.Discord.ChannelId, Evergreen.V375.Id.ThreadRoute ) Evergreen.V375.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V375.RichText.Domain
    , emojiConfig : Evergreen.V375.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V375.Id.Id Evergreen.V375.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V375.Id.Id Evergreen.V375.Id.CustomEmojiId)
    , muteSettings : Evergreen.V375.MuteSettings.Model
    , publicKey : Maybe Evergreen.V375.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V375.PersonName.PersonName
    , color : Evergreen.V375.UserColor.UserColor
    , icon : Maybe Evergreen.V375.FileStatus.FileHash
    , publicKey : Maybe Evergreen.V375.X25519.PublicKey
    }


type alias LocalUser =
    { session : Evergreen.V375.UserSession.UserSession
    , currentlyViewing : Evergreen.V375.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V375.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V375.UserAgent.UserAgent
    , devicePixelRatio : Float
    , stickers : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.StickerId) Evergreen.V375.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.CustomEmojiId) Evergreen.V375.CustomEmoji.CustomEmojiData
    , emojiData : Maybe Evergreen.V375.Emoji.CachedEmojiData
    , decryptedMessages : SeqDict.SeqDict Evergreen.V375.Encryption.BytesHash (Result () (Evergreen.V375.Message.MessageContent (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId)))
    }
