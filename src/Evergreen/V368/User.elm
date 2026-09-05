module Evergreen.V368.User exposing (..)

import Effect.Time
import Evergreen.V368.CustomEmoji
import Evergreen.V368.Discord
import Evergreen.V368.EmailAddress
import Evergreen.V368.Emoji
import Evergreen.V368.Encryption
import Evergreen.V368.FileStatus
import Evergreen.V368.Id
import Evergreen.V368.LinkedAndOtherDiscordUsers
import Evergreen.V368.Message
import Evergreen.V368.MuteSettings
import Evergreen.V368.NonemptyDict
import Evergreen.V368.OneOrGreater
import Evergreen.V368.Pagination
import Evergreen.V368.PersonName
import Evergreen.V368.RichText
import Evergreen.V368.Sticker
import Evergreen.V368.UserAgent
import Evergreen.V368.UserColor
import Evergreen.V368.UserSession
import Evergreen.V368.X25519
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
    = DmChannelLastViewed (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId) Evergreen.V368.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V368.Discord.Id Evergreen.V368.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V368.PersonName.PersonName
    , color : Evergreen.V368.UserColor.UserColor
    , isAdmin : Bool
    , email : Evergreen.V368.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V368.Id.Id Evergreen.V368.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V368.Id.AnyGuildOrDmId (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V368.Id.AnyGuildOrDmId, Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelMessageId ) (Evergreen.V368.Id.Id Evergreen.V368.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId) ( Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelId, Evergreen.V368.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId) ( Evergreen.V368.Discord.Id Evergreen.V368.Discord.ChannelId, Evergreen.V368.Id.ThreadRoute )
    , icon : Maybe Evergreen.V368.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId) (Evergreen.V368.NonemptyDict.NonemptyDict ( Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelId, Evergreen.V368.Id.ThreadRoute ) Evergreen.V368.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId) (Evergreen.V368.NonemptyDict.NonemptyDict ( Evergreen.V368.Discord.Id Evergreen.V368.Discord.ChannelId, Evergreen.V368.Id.ThreadRoute ) Evergreen.V368.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V368.RichText.Domain
    , emojiConfig : Evergreen.V368.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V368.Id.Id Evergreen.V368.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V368.Id.Id Evergreen.V368.Id.CustomEmojiId)
    , muteSettings : Evergreen.V368.MuteSettings.Model
    , publicKey : Maybe Evergreen.V368.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V368.PersonName.PersonName
    , color : Evergreen.V368.UserColor.UserColor
    , icon : Maybe Evergreen.V368.FileStatus.FileHash
    , publicKey : Maybe Evergreen.V368.X25519.PublicKey
    }


type alias LocalUser =
    { session : Evergreen.V368.UserSession.UserSession
    , currentlyViewing : Evergreen.V368.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V368.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V368.UserAgent.UserAgent
    , devicePixelRatio : Float
    , stickers : SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.Id.StickerId) Evergreen.V368.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.Id.CustomEmojiId) Evergreen.V368.CustomEmoji.CustomEmojiData
    , emojiData : Maybe Evergreen.V368.Emoji.CachedEmojiData
    , decryptedMessages : SeqDict.SeqDict Evergreen.V368.Encryption.BytesHash (Result () (Evergreen.V368.Message.MessageContent (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId)))
    }
