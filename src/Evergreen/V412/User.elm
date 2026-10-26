module Evergreen.V412.User exposing (..)

import Effect.Time
import Evergreen.V412.CustomEmoji
import Evergreen.V412.Discord
import Evergreen.V412.EmailAddress
import Evergreen.V412.Emoji
import Evergreen.V412.Encryption
import Evergreen.V412.FileStatus
import Evergreen.V412.Id
import Evergreen.V412.LinkedAndOtherDiscordUsers
import Evergreen.V412.Message
import Evergreen.V412.MuteSettings
import Evergreen.V412.NonemptyDict
import Evergreen.V412.OneOrGreater
import Evergreen.V412.Pagination
import Evergreen.V412.PersonName
import Evergreen.V412.RichText
import Evergreen.V412.Slack
import Evergreen.V412.Sticker
import Evergreen.V412.UserAgent
import Evergreen.V412.UserColor
import Evergreen.V412.UserSession
import Evergreen.V412.X25519
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
    = DmChannelLastViewed (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) Evergreen.V412.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V412.Discord.Id Evergreen.V412.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias FrontendCurrentUser =
    { name : Evergreen.V412.PersonName.PersonName
    , color : Evergreen.V412.UserColor.UserColor
    , isAdmin : Bool
    , email : Evergreen.V412.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V412.Id.Id Evergreen.V412.Pagination.PageId
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , embedVisibility : EmbedVisibility
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V412.Id.AnyGuildOrDmId (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V412.Id.AnyGuildOrDmId, Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId ) (Evergreen.V412.Id.Id Evergreen.V412.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId) ( Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelId, Evergreen.V412.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId) ( Evergreen.V412.Discord.Id Evergreen.V412.Discord.ChannelId, Evergreen.V412.Id.ThreadRoute )
    , lastSlackChannelViewed : SeqDict.SeqDict (Evergreen.V412.Slack.Id Evergreen.V412.Slack.TeamId) ( Evergreen.V412.Slack.Id Evergreen.V412.Slack.ChannelId, Evergreen.V412.Id.ThreadRoute )
    , icon : Maybe Evergreen.V412.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId)
    , slackNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V412.Slack.Id Evergreen.V412.Slack.TeamId)
    , directMentions : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId) (Evergreen.V412.NonemptyDict.NonemptyDict ( Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelId, Evergreen.V412.Id.ThreadRoute ) Evergreen.V412.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId) (Evergreen.V412.NonemptyDict.NonemptyDict ( Evergreen.V412.Discord.Id Evergreen.V412.Discord.ChannelId, Evergreen.V412.Id.ThreadRoute ) Evergreen.V412.OneOrGreater.OneOrGreater)
    , slackDirectMentions : SeqDict.SeqDict (Evergreen.V412.Slack.Id Evergreen.V412.Slack.TeamId) (Evergreen.V412.NonemptyDict.NonemptyDict ( Evergreen.V412.Slack.Id Evergreen.V412.Slack.ChannelId, Evergreen.V412.Id.ThreadRoute ) Evergreen.V412.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , linkDiscordAcknowledgementIsChecked : Bool
    , linkSlackAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V412.RichText.Domain
    , emojiConfig : Evergreen.V412.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V412.Id.Id Evergreen.V412.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V412.Id.Id Evergreen.V412.Id.CustomEmojiId)
    , muteSettings : Evergreen.V412.MuteSettings.Model
    , publicKey : Maybe Evergreen.V412.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    , deleteAccountAt : Maybe Effect.Time.Posix
    }


type alias FrontendUser =
    { name : Evergreen.V412.PersonName.PersonName
    , color : Evergreen.V412.UserColor.UserColor
    , icon : Maybe Evergreen.V412.FileStatus.FileHash
    , publicKey : Maybe Evergreen.V412.X25519.PublicKey
    }


type BackendUserStatus
    = DeletedUser
    | UserHasEmail Evergreen.V412.EmailAddress.EmailAddress


type alias BackendUser =
    { name : Evergreen.V412.PersonName.PersonName
    , color : Evergreen.V412.UserColor.UserColor
    , isAdmin : Bool
    , email : BackendUserStatus
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V412.Id.Id Evergreen.V412.Pagination.PageId
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , embedVisibility : EmbedVisibility
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V412.Id.AnyGuildOrDmId (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V412.Id.AnyGuildOrDmId, Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId ) (Evergreen.V412.Id.Id Evergreen.V412.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId) ( Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelId, Evergreen.V412.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId) ( Evergreen.V412.Discord.Id Evergreen.V412.Discord.ChannelId, Evergreen.V412.Id.ThreadRoute )
    , lastSlackChannelViewed : SeqDict.SeqDict (Evergreen.V412.Slack.Id Evergreen.V412.Slack.TeamId) ( Evergreen.V412.Slack.Id Evergreen.V412.Slack.ChannelId, Evergreen.V412.Id.ThreadRoute )
    , icon : Maybe Evergreen.V412.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId)
    , slackNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V412.Slack.Id Evergreen.V412.Slack.TeamId)
    , directMentions : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId) (Evergreen.V412.NonemptyDict.NonemptyDict ( Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelId, Evergreen.V412.Id.ThreadRoute ) Evergreen.V412.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId) (Evergreen.V412.NonemptyDict.NonemptyDict ( Evergreen.V412.Discord.Id Evergreen.V412.Discord.ChannelId, Evergreen.V412.Id.ThreadRoute ) Evergreen.V412.OneOrGreater.OneOrGreater)
    , slackDirectMentions : SeqDict.SeqDict (Evergreen.V412.Slack.Id Evergreen.V412.Slack.TeamId) (Evergreen.V412.NonemptyDict.NonemptyDict ( Evergreen.V412.Slack.Id Evergreen.V412.Slack.ChannelId, Evergreen.V412.Id.ThreadRoute ) Evergreen.V412.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , linkDiscordAcknowledgementIsChecked : Bool
    , linkSlackAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V412.RichText.Domain
    , emojiConfig : Evergreen.V412.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V412.Id.Id Evergreen.V412.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V412.Id.Id Evergreen.V412.Id.CustomEmojiId)
    , muteSettings : Evergreen.V412.MuteSettings.Model
    , publicKey : Maybe Evergreen.V412.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    , deleteAccountAt : Maybe Effect.Time.Posix
    }


type alias LocalUser =
    { session : Evergreen.V412.UserSession.UserSession
    , currentlyViewing : Evergreen.V412.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V412.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , slackUsers : SeqDict.SeqDict (Evergreen.V412.Slack.Id Evergreen.V412.Slack.UserId) Evergreen.V412.UserSession.SlackFrontendUser
    , linkedSlackUsers : SeqDict.SeqDict (Evergreen.V412.Slack.Id Evergreen.V412.Slack.UserId) (Evergreen.V412.Slack.Id Evergreen.V412.Slack.TeamId)
    , slackUsersNeedingAuth : SeqSet.SeqSet (Evergreen.V412.Slack.Id Evergreen.V412.Slack.UserId)
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V412.UserAgent.UserAgent
    , devicePixelRatio : Float
    , safeAreaInsetTop : Int
    , safeAreaInsetBottom : Int
    , stickers : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.StickerId) Evergreen.V412.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.CustomEmojiId) Evergreen.V412.CustomEmoji.CustomEmojiData
    , emojiData : Maybe Evergreen.V412.Emoji.CachedEmojiData
    , decryptedMessages : SeqDict.SeqDict Evergreen.V412.Encryption.BytesHash (Result () (Evergreen.V412.Message.MessageContent (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelId)))
    }
