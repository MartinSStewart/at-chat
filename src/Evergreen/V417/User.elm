module Evergreen.V417.User exposing (..)

import Effect.Time
import Evergreen.V417.CustomEmoji
import Evergreen.V417.Discord
import Evergreen.V417.EmailAddress
import Evergreen.V417.Emoji
import Evergreen.V417.Encryption
import Evergreen.V417.FileStatus
import Evergreen.V417.Id
import Evergreen.V417.LinkedAndOtherDiscordUsers
import Evergreen.V417.Message
import Evergreen.V417.MuteSettings
import Evergreen.V417.NonemptyDict
import Evergreen.V417.OneOrGreater
import Evergreen.V417.Pagination
import Evergreen.V417.PersonName
import Evergreen.V417.RichText
import Evergreen.V417.Slack
import Evergreen.V417.Sticker
import Evergreen.V417.UserAgent
import Evergreen.V417.UserColor
import Evergreen.V417.UserSession
import Evergreen.V417.X25519
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
    = DmChannelLastViewed (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) Evergreen.V417.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V417.Discord.Id Evergreen.V417.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias FrontendCurrentUser =
    { name : Evergreen.V417.PersonName.PersonName
    , color : Evergreen.V417.UserColor.UserColor
    , isAdmin : Bool
    , email : Evergreen.V417.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V417.Id.Id Evergreen.V417.Pagination.PageId
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , embedVisibility : EmbedVisibility
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V417.Id.AnyGuildOrDmId (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V417.Id.AnyGuildOrDmId, Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId ) (Evergreen.V417.Id.Id Evergreen.V417.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId) ( Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelId, Evergreen.V417.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId) ( Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId, Evergreen.V417.Id.ThreadRoute )
    , lastSlackChannelViewed : SeqDict.SeqDict (Evergreen.V417.Slack.Id Evergreen.V417.Slack.TeamId) ( Evergreen.V417.Slack.Id Evergreen.V417.Slack.ChannelId, Evergreen.V417.Id.ThreadRoute )
    , icon : Maybe Evergreen.V417.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId)
    , slackNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V417.Slack.Id Evergreen.V417.Slack.TeamId)
    , directMentions : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId) (Evergreen.V417.NonemptyDict.NonemptyDict ( Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelId, Evergreen.V417.Id.ThreadRoute ) Evergreen.V417.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId) (Evergreen.V417.NonemptyDict.NonemptyDict ( Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId, Evergreen.V417.Id.ThreadRoute ) Evergreen.V417.OneOrGreater.OneOrGreater)
    , slackDirectMentions : SeqDict.SeqDict (Evergreen.V417.Slack.Id Evergreen.V417.Slack.TeamId) (Evergreen.V417.NonemptyDict.NonemptyDict ( Evergreen.V417.Slack.Id Evergreen.V417.Slack.ChannelId, Evergreen.V417.Id.ThreadRoute ) Evergreen.V417.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , linkDiscordAcknowledgementIsChecked : Bool
    , linkSlackAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V417.RichText.Domain
    , emojiConfig : Evergreen.V417.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V417.Id.Id Evergreen.V417.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V417.Id.Id Evergreen.V417.Id.CustomEmojiId)
    , muteSettings : Evergreen.V417.MuteSettings.Model
    , publicKey : Maybe Evergreen.V417.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    , deleteAccountAt : Maybe Effect.Time.Posix
    }


type alias FrontendUser =
    { name : Evergreen.V417.PersonName.PersonName
    , color : Evergreen.V417.UserColor.UserColor
    , icon : Maybe Evergreen.V417.FileStatus.FileHash
    , publicKey : Maybe Evergreen.V417.X25519.PublicKey
    }


type BackendUserStatus
    = DeletedUser
    | UserHasEmail Evergreen.V417.EmailAddress.EmailAddress


type alias BackendUser =
    { name : Evergreen.V417.PersonName.PersonName
    , color : Evergreen.V417.UserColor.UserColor
    , isAdmin : Bool
    , email : BackendUserStatus
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V417.Id.Id Evergreen.V417.Pagination.PageId
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , embedVisibility : EmbedVisibility
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V417.Id.AnyGuildOrDmId (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V417.Id.AnyGuildOrDmId, Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId ) (Evergreen.V417.Id.Id Evergreen.V417.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId) ( Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelId, Evergreen.V417.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId) ( Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId, Evergreen.V417.Id.ThreadRoute )
    , lastSlackChannelViewed : SeqDict.SeqDict (Evergreen.V417.Slack.Id Evergreen.V417.Slack.TeamId) ( Evergreen.V417.Slack.Id Evergreen.V417.Slack.ChannelId, Evergreen.V417.Id.ThreadRoute )
    , icon : Maybe Evergreen.V417.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId)
    , slackNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V417.Slack.Id Evergreen.V417.Slack.TeamId)
    , directMentions : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId) (Evergreen.V417.NonemptyDict.NonemptyDict ( Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelId, Evergreen.V417.Id.ThreadRoute ) Evergreen.V417.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId) (Evergreen.V417.NonemptyDict.NonemptyDict ( Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId, Evergreen.V417.Id.ThreadRoute ) Evergreen.V417.OneOrGreater.OneOrGreater)
    , slackDirectMentions : SeqDict.SeqDict (Evergreen.V417.Slack.Id Evergreen.V417.Slack.TeamId) (Evergreen.V417.NonemptyDict.NonemptyDict ( Evergreen.V417.Slack.Id Evergreen.V417.Slack.ChannelId, Evergreen.V417.Id.ThreadRoute ) Evergreen.V417.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , linkDiscordAcknowledgementIsChecked : Bool
    , linkSlackAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V417.RichText.Domain
    , emojiConfig : Evergreen.V417.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V417.Id.Id Evergreen.V417.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V417.Id.Id Evergreen.V417.Id.CustomEmojiId)
    , muteSettings : Evergreen.V417.MuteSettings.Model
    , publicKey : Maybe Evergreen.V417.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    , deleteAccountAt : Maybe Effect.Time.Posix
    }


type alias LocalUser =
    { session : Evergreen.V417.UserSession.UserSession
    , currentlyViewing : Evergreen.V417.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V417.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , slackUsers : SeqDict.SeqDict (Evergreen.V417.Slack.Id Evergreen.V417.Slack.UserId) Evergreen.V417.UserSession.SlackFrontendUser
    , linkedSlackUsers : SeqDict.SeqDict (Evergreen.V417.Slack.Id Evergreen.V417.Slack.UserId) (Evergreen.V417.Slack.Id Evergreen.V417.Slack.TeamId)
    , slackUsersNeedingAuth : SeqSet.SeqSet (Evergreen.V417.Slack.Id Evergreen.V417.Slack.UserId)
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V417.UserAgent.UserAgent
    , devicePixelRatio : Float
    , safeAreaInsetTop : Int
    , safeAreaInsetBottom : Int
    , stickers : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.StickerId) Evergreen.V417.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.CustomEmojiId) Evergreen.V417.CustomEmoji.CustomEmojiData
    , emojiData : Maybe Evergreen.V417.Emoji.CachedEmojiData
    , decryptedMessages : SeqDict.SeqDict Evergreen.V417.Encryption.BytesHash (Result () (Evergreen.V417.Message.MessageContent (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelId)))
    }
