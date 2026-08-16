module Evergreen.V353.User exposing (..)

import Effect.Time
import Evergreen.V353.CustomEmoji
import Evergreen.V353.Discord
import Evergreen.V353.EmailAddress
import Evergreen.V353.Emoji
import Evergreen.V353.FileStatus
import Evergreen.V353.Id
import Evergreen.V353.LinkedAndOtherDiscordUsers
import Evergreen.V353.MuteSettings
import Evergreen.V353.NonemptyDict
import Evergreen.V353.OneOrGreater
import Evergreen.V353.Pagination
import Evergreen.V353.PersonName
import Evergreen.V353.RichText
import Evergreen.V353.Sticker
import Evergreen.V353.UserAgent
import Evergreen.V353.UserSession
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
    = DmChannelLastViewed (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId) Evergreen.V353.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V353.Discord.Id Evergreen.V353.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V353.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V353.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V353.Id.Id Evergreen.V353.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V353.Id.AnyGuildOrDmId (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V353.Id.AnyGuildOrDmId, Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId ) (Evergreen.V353.Id.Id Evergreen.V353.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId) ( Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelId, Evergreen.V353.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId) ( Evergreen.V353.Discord.Id Evergreen.V353.Discord.ChannelId, Evergreen.V353.Id.ThreadRoute )
    , icon : Maybe Evergreen.V353.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId) (Evergreen.V353.NonemptyDict.NonemptyDict ( Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelId, Evergreen.V353.Id.ThreadRoute ) Evergreen.V353.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId) (Evergreen.V353.NonemptyDict.NonemptyDict ( Evergreen.V353.Discord.Id Evergreen.V353.Discord.ChannelId, Evergreen.V353.Id.ThreadRoute ) Evergreen.V353.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V353.RichText.Domain
    , emojiConfig : Evergreen.V353.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V353.Id.Id Evergreen.V353.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V353.Id.Id Evergreen.V353.Id.CustomEmojiId)
    , muteSettings : Evergreen.V353.MuteSettings.Model
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V353.PersonName.PersonName
    , isAdmin : Bool
    , icon : Maybe Evergreen.V353.FileStatus.FileHash
    }


type alias LocalUser =
    { session : Evergreen.V353.UserSession.UserSession
    , currentlyViewing : Evergreen.V353.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V353.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V353.UserAgent.UserAgent
    , devicePixelRatio : Float
    , stickers : SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.StickerId) Evergreen.V353.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.CustomEmojiId) Evergreen.V353.CustomEmoji.CustomEmojiData
    }
