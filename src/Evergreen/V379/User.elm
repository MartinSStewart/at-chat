module Evergreen.V379.User exposing (..)

import Effect.Time
import Evergreen.V379.CustomEmoji
import Evergreen.V379.Discord
import Evergreen.V379.EmailAddress
import Evergreen.V379.Emoji
import Evergreen.V379.Encryption
import Evergreen.V379.FileStatus
import Evergreen.V379.Id
import Evergreen.V379.LinkedAndOtherDiscordUsers
import Evergreen.V379.Message
import Evergreen.V379.MuteSettings
import Evergreen.V379.NonemptyDict
import Evergreen.V379.OneOrGreater
import Evergreen.V379.Pagination
import Evergreen.V379.PersonName
import Evergreen.V379.RichText
import Evergreen.V379.Sticker
import Evergreen.V379.UserAgent
import Evergreen.V379.UserColor
import Evergreen.V379.UserSession
import Evergreen.V379.X25519
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
    = DmChannelLastViewed (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId) Evergreen.V379.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V379.Discord.Id Evergreen.V379.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V379.PersonName.PersonName
    , color : Evergreen.V379.UserColor.UserColor
    , isAdmin : Bool
    , email : Evergreen.V379.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V379.Id.Id Evergreen.V379.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V379.Id.AnyGuildOrDmId (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V379.Id.AnyGuildOrDmId, Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelMessageId ) (Evergreen.V379.Id.Id Evergreen.V379.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId) ( Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelId, Evergreen.V379.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId) ( Evergreen.V379.Discord.Id Evergreen.V379.Discord.ChannelId, Evergreen.V379.Id.ThreadRoute )
    , icon : Maybe Evergreen.V379.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId) (Evergreen.V379.NonemptyDict.NonemptyDict ( Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelId, Evergreen.V379.Id.ThreadRoute ) Evergreen.V379.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId) (Evergreen.V379.NonemptyDict.NonemptyDict ( Evergreen.V379.Discord.Id Evergreen.V379.Discord.ChannelId, Evergreen.V379.Id.ThreadRoute ) Evergreen.V379.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V379.RichText.Domain
    , emojiConfig : Evergreen.V379.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V379.Id.Id Evergreen.V379.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V379.Id.Id Evergreen.V379.Id.CustomEmojiId)
    , muteSettings : Evergreen.V379.MuteSettings.Model
    , publicKey : Maybe Evergreen.V379.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V379.PersonName.PersonName
    , color : Evergreen.V379.UserColor.UserColor
    , icon : Maybe Evergreen.V379.FileStatus.FileHash
    , publicKey : Maybe Evergreen.V379.X25519.PublicKey
    }


type alias LocalUser =
    { session : Evergreen.V379.UserSession.UserSession
    , currentlyViewing : Evergreen.V379.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V379.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V379.UserAgent.UserAgent
    , devicePixelRatio : Float
    , stickers : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.StickerId) Evergreen.V379.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.CustomEmojiId) Evergreen.V379.CustomEmoji.CustomEmojiData
    , emojiData : Maybe Evergreen.V379.Emoji.CachedEmojiData
    , decryptedMessages : SeqDict.SeqDict Evergreen.V379.Encryption.BytesHash (Result () (Evergreen.V379.Message.MessageContent (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId)))
    }
