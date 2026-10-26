module Evergreen.V413.User exposing (..)

import Effect.Time
import Evergreen.V413.CustomEmoji
import Evergreen.V413.Discord
import Evergreen.V413.EmailAddress
import Evergreen.V413.Emoji
import Evergreen.V413.Encryption
import Evergreen.V413.FileStatus
import Evergreen.V413.Id
import Evergreen.V413.LinkedAndOtherDiscordUsers
import Evergreen.V413.Message
import Evergreen.V413.MuteSettings
import Evergreen.V413.NonemptyDict
import Evergreen.V413.OneOrGreater
import Evergreen.V413.Pagination
import Evergreen.V413.PersonName
import Evergreen.V413.RichText
import Evergreen.V413.Slack
import Evergreen.V413.Sticker
import Evergreen.V413.UserAgent
import Evergreen.V413.UserColor
import Evergreen.V413.UserSession
import Evergreen.V413.X25519
import SeqDict
import SeqSet


type EmailNotifications
    = NeverNotifyMe
    | NotifyMeWhenMentioned


type EmbedVisibility
    = ShowEmbeds
    | HideEmbeds


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention


type LastDmViewed
    = DmChannelLastViewed (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) Evergreen.V413.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V413.Discord.Id Evergreen.V413.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias FrontendCurrentUser =
    { name : Evergreen.V413.PersonName.PersonName
    , color : Evergreen.V413.UserColor.UserColor
    , isAdmin : Bool
    , email : Evergreen.V413.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V413.Id.Id Evergreen.V413.Pagination.PageId
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , embedVisibility : EmbedVisibility
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V413.Id.AnyGuildOrDmId (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V413.Id.AnyGuildOrDmId, Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId ) (Evergreen.V413.Id.Id Evergreen.V413.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId) ( Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelId, Evergreen.V413.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V413.Discord.Id Evergreen.V413.Discord.GuildId) ( Evergreen.V413.Discord.Id Evergreen.V413.Discord.ChannelId, Evergreen.V413.Id.ThreadRoute )
    , lastSlackChannelViewed : SeqDict.SeqDict (Evergreen.V413.Slack.Id Evergreen.V413.Slack.TeamId) ( Evergreen.V413.Slack.Id Evergreen.V413.Slack.ChannelId, Evergreen.V413.Id.ThreadRoute )
    , icon : Maybe Evergreen.V413.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V413.Discord.Id Evergreen.V413.Discord.GuildId)
    , slackNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V413.Slack.Id Evergreen.V413.Slack.TeamId)
    , directMentions : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId) (Evergreen.V413.NonemptyDict.NonemptyDict ( Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelId, Evergreen.V413.Id.ThreadRoute ) Evergreen.V413.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V413.Discord.Id Evergreen.V413.Discord.GuildId) (Evergreen.V413.NonemptyDict.NonemptyDict ( Evergreen.V413.Discord.Id Evergreen.V413.Discord.ChannelId, Evergreen.V413.Id.ThreadRoute ) Evergreen.V413.OneOrGreater.OneOrGreater)
    , slackDirectMentions : SeqDict.SeqDict (Evergreen.V413.Slack.Id Evergreen.V413.Slack.TeamId) (Evergreen.V413.NonemptyDict.NonemptyDict ( Evergreen.V413.Slack.Id Evergreen.V413.Slack.ChannelId, Evergreen.V413.Id.ThreadRoute ) Evergreen.V413.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , linkDiscordAcknowledgementIsChecked : Bool
    , linkSlackAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V413.RichText.Domain
    , emojiConfig : Evergreen.V413.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V413.Id.Id Evergreen.V413.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V413.Id.Id Evergreen.V413.Id.CustomEmojiId)
    , muteSettings : Evergreen.V413.MuteSettings.Model
    , publicKey : Maybe Evergreen.V413.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    , deleteAccountAt : Maybe Effect.Time.Posix
    }


type alias FrontendUser =
    { name : Evergreen.V413.PersonName.PersonName
    , color : Evergreen.V413.UserColor.UserColor
    , icon : Maybe Evergreen.V413.FileStatus.FileHash
    , publicKey : Maybe Evergreen.V413.X25519.PublicKey
    }


type BackendUserStatus
    = DeletedUser
    | UserHasEmail Evergreen.V413.EmailAddress.EmailAddress


type alias BackendUser =
    { name : Evergreen.V413.PersonName.PersonName
    , color : Evergreen.V413.UserColor.UserColor
    , isAdmin : Bool
    , email : BackendUserStatus
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V413.Id.Id Evergreen.V413.Pagination.PageId
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , embedVisibility : EmbedVisibility
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V413.Id.AnyGuildOrDmId (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V413.Id.AnyGuildOrDmId, Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId ) (Evergreen.V413.Id.Id Evergreen.V413.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId) ( Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelId, Evergreen.V413.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V413.Discord.Id Evergreen.V413.Discord.GuildId) ( Evergreen.V413.Discord.Id Evergreen.V413.Discord.ChannelId, Evergreen.V413.Id.ThreadRoute )
    , lastSlackChannelViewed : SeqDict.SeqDict (Evergreen.V413.Slack.Id Evergreen.V413.Slack.TeamId) ( Evergreen.V413.Slack.Id Evergreen.V413.Slack.ChannelId, Evergreen.V413.Id.ThreadRoute )
    , icon : Maybe Evergreen.V413.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V413.Discord.Id Evergreen.V413.Discord.GuildId)
    , slackNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V413.Slack.Id Evergreen.V413.Slack.TeamId)
    , directMentions : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId) (Evergreen.V413.NonemptyDict.NonemptyDict ( Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelId, Evergreen.V413.Id.ThreadRoute ) Evergreen.V413.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V413.Discord.Id Evergreen.V413.Discord.GuildId) (Evergreen.V413.NonemptyDict.NonemptyDict ( Evergreen.V413.Discord.Id Evergreen.V413.Discord.ChannelId, Evergreen.V413.Id.ThreadRoute ) Evergreen.V413.OneOrGreater.OneOrGreater)
    , slackDirectMentions : SeqDict.SeqDict (Evergreen.V413.Slack.Id Evergreen.V413.Slack.TeamId) (Evergreen.V413.NonemptyDict.NonemptyDict ( Evergreen.V413.Slack.Id Evergreen.V413.Slack.ChannelId, Evergreen.V413.Id.ThreadRoute ) Evergreen.V413.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , linkDiscordAcknowledgementIsChecked : Bool
    , linkSlackAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V413.RichText.Domain
    , emojiConfig : Evergreen.V413.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V413.Id.Id Evergreen.V413.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V413.Id.Id Evergreen.V413.Id.CustomEmojiId)
    , muteSettings : Evergreen.V413.MuteSettings.Model
    , publicKey : Maybe Evergreen.V413.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    , deleteAccountAt : Maybe Effect.Time.Posix
    }


type alias LocalUser =
    { session : Evergreen.V413.UserSession.UserSession
    , currentlyViewing : Evergreen.V413.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V413.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , slackUsers : SeqDict.SeqDict (Evergreen.V413.Slack.Id Evergreen.V413.Slack.UserId) Evergreen.V413.UserSession.SlackFrontendUser
    , linkedSlackUsers : SeqDict.SeqDict (Evergreen.V413.Slack.Id Evergreen.V413.Slack.UserId) (Evergreen.V413.Slack.Id Evergreen.V413.Slack.TeamId)
    , slackUsersNeedingAuth : SeqSet.SeqSet (Evergreen.V413.Slack.Id Evergreen.V413.Slack.UserId)
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V413.UserAgent.UserAgent
    , devicePixelRatio : Float
    , safeAreaInsetTop : Int
    , safeAreaInsetBottom : Int
    , stickers : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.StickerId) Evergreen.V413.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.CustomEmojiId) Evergreen.V413.CustomEmoji.CustomEmojiData
    , emojiData : Maybe Evergreen.V413.Emoji.CachedEmojiData
    , decryptedMessages : SeqDict.SeqDict Evergreen.V413.Encryption.BytesHash (Result () (Evergreen.V413.Message.MessageContent (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelId)))
    }
