module Evergreen.V351.User exposing (..)

import Effect.Time
import Evergreen.V351.CustomEmoji
import Evergreen.V351.Discord
import Evergreen.V351.EmailAddress
import Evergreen.V351.Emoji
import Evergreen.V351.FileStatus
import Evergreen.V351.Id
import Evergreen.V351.LinkedAndOtherDiscordUsers
import Evergreen.V351.MuteSettings
import Evergreen.V351.NonemptyDict
import Evergreen.V351.OneOrGreater
import Evergreen.V351.Pagination
import Evergreen.V351.PersonName
import Evergreen.V351.RichText
import Evergreen.V351.Sticker
import Evergreen.V351.UserAgent
import Evergreen.V351.UserSession
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
    = DmChannelLastViewed (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId) Evergreen.V351.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V351.Discord.Id Evergreen.V351.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V351.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V351.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V351.Id.Id Evergreen.V351.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V351.Id.AnyGuildOrDmId (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V351.Id.AnyGuildOrDmId, Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId ) (Evergreen.V351.Id.Id Evergreen.V351.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId) ( Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelId, Evergreen.V351.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId) ( Evergreen.V351.Discord.Id Evergreen.V351.Discord.ChannelId, Evergreen.V351.Id.ThreadRoute )
    , icon : Maybe Evergreen.V351.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId) (Evergreen.V351.NonemptyDict.NonemptyDict ( Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelId, Evergreen.V351.Id.ThreadRoute ) Evergreen.V351.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId) (Evergreen.V351.NonemptyDict.NonemptyDict ( Evergreen.V351.Discord.Id Evergreen.V351.Discord.ChannelId, Evergreen.V351.Id.ThreadRoute ) Evergreen.V351.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V351.RichText.Domain
    , emojiConfig : Evergreen.V351.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V351.Id.Id Evergreen.V351.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V351.Id.Id Evergreen.V351.Id.CustomEmojiId)
    , muteSettings : Evergreen.V351.MuteSettings.Model
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V351.PersonName.PersonName
    , isAdmin : Bool
    , icon : Maybe Evergreen.V351.FileStatus.FileHash
    }


type alias LocalUser =
    { session : Evergreen.V351.UserSession.UserSession
    , currentlyViewing : Evergreen.V351.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V351.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V351.UserAgent.UserAgent
    , devicePixelRatio : Float
    , stickers : SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.StickerId) Evergreen.V351.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.CustomEmojiId) Evergreen.V351.CustomEmoji.CustomEmojiData
    }
