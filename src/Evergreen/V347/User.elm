module Evergreen.V347.User exposing (..)

import Effect.Time
import Evergreen.V347.CustomEmoji
import Evergreen.V347.Discord
import Evergreen.V347.EmailAddress
import Evergreen.V347.Emoji
import Evergreen.V347.FileStatus
import Evergreen.V347.Id
import Evergreen.V347.LinkedAndOtherDiscordUsers
import Evergreen.V347.MuteSettings
import Evergreen.V347.NonemptyDict
import Evergreen.V347.OneOrGreater
import Evergreen.V347.Pagination
import Evergreen.V347.PersonName
import Evergreen.V347.RichText
import Evergreen.V347.Sticker
import Evergreen.V347.UserAgent
import Evergreen.V347.UserSession
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
    = DmChannelLastViewed (Evergreen.V347.Id.Id Evergreen.V347.Id.UserId) Evergreen.V347.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V347.Discord.Id Evergreen.V347.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V347.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V347.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V347.Id.Id Evergreen.V347.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V347.Id.AnyGuildOrDmId (Evergreen.V347.Id.Id Evergreen.V347.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V347.Id.AnyGuildOrDmId, Evergreen.V347.Id.Id Evergreen.V347.Id.ChannelMessageId ) (Evergreen.V347.Id.Id Evergreen.V347.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V347.Id.Id Evergreen.V347.Id.GuildId) ( Evergreen.V347.Id.Id Evergreen.V347.Id.ChannelId, Evergreen.V347.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V347.Discord.Id Evergreen.V347.Discord.GuildId) ( Evergreen.V347.Discord.Id Evergreen.V347.Discord.ChannelId, Evergreen.V347.Id.ThreadRoute )
    , icon : Maybe Evergreen.V347.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V347.Id.Id Evergreen.V347.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V347.Discord.Id Evergreen.V347.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V347.Id.Id Evergreen.V347.Id.GuildId) (Evergreen.V347.NonemptyDict.NonemptyDict ( Evergreen.V347.Id.Id Evergreen.V347.Id.ChannelId, Evergreen.V347.Id.ThreadRoute ) Evergreen.V347.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V347.Discord.Id Evergreen.V347.Discord.GuildId) (Evergreen.V347.NonemptyDict.NonemptyDict ( Evergreen.V347.Discord.Id Evergreen.V347.Discord.ChannelId, Evergreen.V347.Id.ThreadRoute ) Evergreen.V347.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V347.Id.Id Evergreen.V347.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V347.Discord.Id Evergreen.V347.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V347.RichText.Domain
    , emojiConfig : Evergreen.V347.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V347.Id.Id Evergreen.V347.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V347.Id.Id Evergreen.V347.Id.CustomEmojiId)
    , muteSettings : Evergreen.V347.MuteSettings.Model
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V347.PersonName.PersonName
    , isAdmin : Bool
    , icon : Maybe Evergreen.V347.FileStatus.FileHash
    }


type alias LocalUser =
    { session : Evergreen.V347.UserSession.UserSession
    , currentlyViewing : Evergreen.V347.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V347.Id.Id Evergreen.V347.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V347.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V347.UserAgent.UserAgent
    , devicePixelRatio : Float
    , stickers : SeqDict.SeqDict (Evergreen.V347.Id.Id Evergreen.V347.Id.StickerId) Evergreen.V347.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V347.Id.Id Evergreen.V347.Id.CustomEmojiId) Evergreen.V347.CustomEmoji.CustomEmojiData
    }
