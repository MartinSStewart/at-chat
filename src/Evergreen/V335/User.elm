module Evergreen.V335.User exposing (..)

import Effect.Time
import Evergreen.V335.CustomEmoji
import Evergreen.V335.Discord
import Evergreen.V335.EmailAddress
import Evergreen.V335.Emoji
import Evergreen.V335.FileStatus
import Evergreen.V335.Id
import Evergreen.V335.LinkedAndOtherDiscordUsers
import Evergreen.V335.NonemptyDict
import Evergreen.V335.OneOrGreater
import Evergreen.V335.Pagination
import Evergreen.V335.PersonName
import Evergreen.V335.RichText
import Evergreen.V335.Sticker
import Evergreen.V335.UserAgent
import Evergreen.V335.UserSession
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
    | VoiceChatSection
    | WebsocketCloseEventsSection
    | SessionsSection
    | WordSpellingGameSwedishSection


type EmailNotifications
    = NeverNotifyMe
    | NotifyMeWhenMentioned


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention


type LastDmViewed
    = DmChannelLastViewed (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId) Evergreen.V335.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V335.Discord.Id Evergreen.V335.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V335.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V335.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V335.Id.Id Evergreen.V335.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V335.Id.AnyGuildOrDmId (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V335.Id.AnyGuildOrDmId, Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelMessageId ) (Evergreen.V335.Id.Id Evergreen.V335.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId) ( Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelId, Evergreen.V335.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V335.Discord.Id Evergreen.V335.Discord.GuildId) ( Evergreen.V335.Discord.Id Evergreen.V335.Discord.ChannelId, Evergreen.V335.Id.ThreadRoute )
    , icon : Maybe Evergreen.V335.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V335.Discord.Id Evergreen.V335.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId) (Evergreen.V335.NonemptyDict.NonemptyDict ( Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelId, Evergreen.V335.Id.ThreadRoute ) Evergreen.V335.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V335.Discord.Id Evergreen.V335.Discord.GuildId) (Evergreen.V335.NonemptyDict.NonemptyDict ( Evergreen.V335.Discord.Id Evergreen.V335.Discord.ChannelId, Evergreen.V335.Id.ThreadRoute ) Evergreen.V335.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V335.Discord.Id Evergreen.V335.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V335.RichText.Domain
    , emojiConfig : Evergreen.V335.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V335.Id.Id Evergreen.V335.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V335.Id.Id Evergreen.V335.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V335.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V335.FileStatus.FileHash
    }


type alias LocalUser =
    { session : Evergreen.V335.UserSession.UserSession
    , currentlyViewing : Evergreen.V335.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V335.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V335.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.Id.StickerId) Evergreen.V335.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.Id.CustomEmojiId) Evergreen.V335.CustomEmoji.CustomEmojiData
    }
