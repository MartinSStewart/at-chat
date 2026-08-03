module Evergreen.V344.User exposing (..)

import Effect.Time
import Evergreen.V344.CustomEmoji
import Evergreen.V344.Discord
import Evergreen.V344.EmailAddress
import Evergreen.V344.Emoji
import Evergreen.V344.FileStatus
import Evergreen.V344.Id
import Evergreen.V344.LinkedAndOtherDiscordUsers
import Evergreen.V344.MuteSettings
import Evergreen.V344.NonemptyDict
import Evergreen.V344.OneOrGreater
import Evergreen.V344.Pagination
import Evergreen.V344.PersonName
import Evergreen.V344.RichText
import Evergreen.V344.Sticker
import Evergreen.V344.UserAgent
import Evergreen.V344.UserSession
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
    = DmChannelLastViewed (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId) Evergreen.V344.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V344.Discord.Id Evergreen.V344.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V344.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V344.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V344.Id.Id Evergreen.V344.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V344.Id.AnyGuildOrDmId (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V344.Id.AnyGuildOrDmId, Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelMessageId ) (Evergreen.V344.Id.Id Evergreen.V344.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId) ( Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelId, Evergreen.V344.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId) ( Evergreen.V344.Discord.Id Evergreen.V344.Discord.ChannelId, Evergreen.V344.Id.ThreadRoute )
    , icon : Maybe Evergreen.V344.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId) (Evergreen.V344.NonemptyDict.NonemptyDict ( Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelId, Evergreen.V344.Id.ThreadRoute ) Evergreen.V344.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId) (Evergreen.V344.NonemptyDict.NonemptyDict ( Evergreen.V344.Discord.Id Evergreen.V344.Discord.ChannelId, Evergreen.V344.Id.ThreadRoute ) Evergreen.V344.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V344.RichText.Domain
    , emojiConfig : Evergreen.V344.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V344.Id.Id Evergreen.V344.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V344.Id.Id Evergreen.V344.Id.CustomEmojiId)
    , muteSettings : Evergreen.V344.MuteSettings.Model
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V344.PersonName.PersonName
    , isAdmin : Bool
    , icon : Maybe Evergreen.V344.FileStatus.FileHash
    }


type alias LocalUser =
    { session : Evergreen.V344.UserSession.UserSession
    , currentlyViewing : Evergreen.V344.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V344.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V344.UserAgent.UserAgent
    , devicePixelRatio : Float
    , stickers : SeqDict.SeqDict (Evergreen.V344.Id.Id Evergreen.V344.Id.StickerId) Evergreen.V344.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V344.Id.Id Evergreen.V344.Id.CustomEmojiId) Evergreen.V344.CustomEmoji.CustomEmojiData
    }
