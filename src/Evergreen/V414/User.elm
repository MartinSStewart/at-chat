module Evergreen.V414.User exposing (..)

import Effect.Time
import Evergreen.V414.CustomEmoji
import Evergreen.V414.Discord
import Evergreen.V414.EmailAddress
import Evergreen.V414.Emoji
import Evergreen.V414.Encryption
import Evergreen.V414.FileStatus
import Evergreen.V414.Id
import Evergreen.V414.LinkedAndOtherDiscordUsers
import Evergreen.V414.Message
import Evergreen.V414.MuteSettings
import Evergreen.V414.NonemptyDict
import Evergreen.V414.OneOrGreater
import Evergreen.V414.Pagination
import Evergreen.V414.PersonName
import Evergreen.V414.RichText
import Evergreen.V414.Slack
import Evergreen.V414.Sticker
import Evergreen.V414.UserAgent
import Evergreen.V414.UserColor
import Evergreen.V414.UserSession
import Evergreen.V414.X25519
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
    = DmChannelLastViewed (Evergreen.V414.Id.Id Evergreen.V414.Id.UserId) Evergreen.V414.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V414.Discord.Id Evergreen.V414.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias FrontendCurrentUser =
    { name : Evergreen.V414.PersonName.PersonName
    , color : Evergreen.V414.UserColor.UserColor
    , isAdmin : Bool
    , email : Evergreen.V414.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V414.Id.Id Evergreen.V414.Pagination.PageId
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , embedVisibility : EmbedVisibility
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V414.Id.AnyGuildOrDmId (Evergreen.V414.Id.Id Evergreen.V414.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V414.Id.AnyGuildOrDmId, Evergreen.V414.Id.Id Evergreen.V414.Id.ChannelMessageId ) (Evergreen.V414.Id.Id Evergreen.V414.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V414.Id.Id Evergreen.V414.Id.GuildId) ( Evergreen.V414.Id.Id Evergreen.V414.Id.ChannelId, Evergreen.V414.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V414.Discord.Id Evergreen.V414.Discord.GuildId) ( Evergreen.V414.Discord.Id Evergreen.V414.Discord.ChannelId, Evergreen.V414.Id.ThreadRoute )
    , lastSlackChannelViewed : SeqDict.SeqDict (Evergreen.V414.Slack.Id Evergreen.V414.Slack.TeamId) ( Evergreen.V414.Slack.Id Evergreen.V414.Slack.ChannelId, Evergreen.V414.Id.ThreadRoute )
    , icon : Maybe Evergreen.V414.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V414.Id.Id Evergreen.V414.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V414.Discord.Id Evergreen.V414.Discord.GuildId)
    , slackNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V414.Slack.Id Evergreen.V414.Slack.TeamId)
    , directMentions : SeqDict.SeqDict (Evergreen.V414.Id.Id Evergreen.V414.Id.GuildId) (Evergreen.V414.NonemptyDict.NonemptyDict ( Evergreen.V414.Id.Id Evergreen.V414.Id.ChannelId, Evergreen.V414.Id.ThreadRoute ) Evergreen.V414.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V414.Discord.Id Evergreen.V414.Discord.GuildId) (Evergreen.V414.NonemptyDict.NonemptyDict ( Evergreen.V414.Discord.Id Evergreen.V414.Discord.ChannelId, Evergreen.V414.Id.ThreadRoute ) Evergreen.V414.OneOrGreater.OneOrGreater)
    , slackDirectMentions : SeqDict.SeqDict (Evergreen.V414.Slack.Id Evergreen.V414.Slack.TeamId) (Evergreen.V414.NonemptyDict.NonemptyDict ( Evergreen.V414.Slack.Id Evergreen.V414.Slack.ChannelId, Evergreen.V414.Id.ThreadRoute ) Evergreen.V414.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , linkDiscordAcknowledgementIsChecked : Bool
    , linkSlackAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V414.RichText.Domain
    , emojiConfig : Evergreen.V414.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V414.Id.Id Evergreen.V414.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V414.Id.Id Evergreen.V414.Id.CustomEmojiId)
    , muteSettings : Evergreen.V414.MuteSettings.Model
    , publicKey : Maybe Evergreen.V414.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    , deleteAccountAt : Maybe Effect.Time.Posix
    }


type alias FrontendUser =
    { name : Evergreen.V414.PersonName.PersonName
    , color : Evergreen.V414.UserColor.UserColor
    , icon : Maybe Evergreen.V414.FileStatus.FileHash
    , publicKey : Maybe Evergreen.V414.X25519.PublicKey
    }


type BackendUserStatus
    = DeletedUser
    | UserHasEmail Evergreen.V414.EmailAddress.EmailAddress


type alias BackendUser =
    { name : Evergreen.V414.PersonName.PersonName
    , color : Evergreen.V414.UserColor.UserColor
    , isAdmin : Bool
    , email : BackendUserStatus
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V414.Id.Id Evergreen.V414.Pagination.PageId
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , embedVisibility : EmbedVisibility
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V414.Id.AnyGuildOrDmId (Evergreen.V414.Id.Id Evergreen.V414.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V414.Id.AnyGuildOrDmId, Evergreen.V414.Id.Id Evergreen.V414.Id.ChannelMessageId ) (Evergreen.V414.Id.Id Evergreen.V414.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V414.Id.Id Evergreen.V414.Id.GuildId) ( Evergreen.V414.Id.Id Evergreen.V414.Id.ChannelId, Evergreen.V414.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V414.Discord.Id Evergreen.V414.Discord.GuildId) ( Evergreen.V414.Discord.Id Evergreen.V414.Discord.ChannelId, Evergreen.V414.Id.ThreadRoute )
    , lastSlackChannelViewed : SeqDict.SeqDict (Evergreen.V414.Slack.Id Evergreen.V414.Slack.TeamId) ( Evergreen.V414.Slack.Id Evergreen.V414.Slack.ChannelId, Evergreen.V414.Id.ThreadRoute )
    , icon : Maybe Evergreen.V414.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V414.Id.Id Evergreen.V414.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V414.Discord.Id Evergreen.V414.Discord.GuildId)
    , slackNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V414.Slack.Id Evergreen.V414.Slack.TeamId)
    , directMentions : SeqDict.SeqDict (Evergreen.V414.Id.Id Evergreen.V414.Id.GuildId) (Evergreen.V414.NonemptyDict.NonemptyDict ( Evergreen.V414.Id.Id Evergreen.V414.Id.ChannelId, Evergreen.V414.Id.ThreadRoute ) Evergreen.V414.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V414.Discord.Id Evergreen.V414.Discord.GuildId) (Evergreen.V414.NonemptyDict.NonemptyDict ( Evergreen.V414.Discord.Id Evergreen.V414.Discord.ChannelId, Evergreen.V414.Id.ThreadRoute ) Evergreen.V414.OneOrGreater.OneOrGreater)
    , slackDirectMentions : SeqDict.SeqDict (Evergreen.V414.Slack.Id Evergreen.V414.Slack.TeamId) (Evergreen.V414.NonemptyDict.NonemptyDict ( Evergreen.V414.Slack.Id Evergreen.V414.Slack.ChannelId, Evergreen.V414.Id.ThreadRoute ) Evergreen.V414.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , linkDiscordAcknowledgementIsChecked : Bool
    , linkSlackAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V414.RichText.Domain
    , emojiConfig : Evergreen.V414.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V414.Id.Id Evergreen.V414.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V414.Id.Id Evergreen.V414.Id.CustomEmojiId)
    , muteSettings : Evergreen.V414.MuteSettings.Model
    , publicKey : Maybe Evergreen.V414.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    , deleteAccountAt : Maybe Effect.Time.Posix
    }


type alias LocalUser =
    { session : Evergreen.V414.UserSession.UserSession
    , currentlyViewing : Evergreen.V414.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V414.Id.Id Evergreen.V414.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V414.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , slackUsers : SeqDict.SeqDict (Evergreen.V414.Slack.Id Evergreen.V414.Slack.UserId) Evergreen.V414.UserSession.SlackFrontendUser
    , linkedSlackUsers : SeqDict.SeqDict (Evergreen.V414.Slack.Id Evergreen.V414.Slack.UserId) (Evergreen.V414.Slack.Id Evergreen.V414.Slack.TeamId)
    , slackUsersNeedingAuth : SeqSet.SeqSet (Evergreen.V414.Slack.Id Evergreen.V414.Slack.UserId)
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V414.UserAgent.UserAgent
    , devicePixelRatio : Float
    , safeAreaInsetTop : Int
    , safeAreaInsetBottom : Int
    , stickers : SeqDict.SeqDict (Evergreen.V414.Id.Id Evergreen.V414.Id.StickerId) Evergreen.V414.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V414.Id.Id Evergreen.V414.Id.CustomEmojiId) Evergreen.V414.CustomEmoji.CustomEmojiData
    , emojiData : Maybe Evergreen.V414.Emoji.CachedEmojiData
    , decryptedMessages : SeqDict.SeqDict Evergreen.V414.Encryption.BytesHash (Result () (Evergreen.V414.Message.MessageContent (Evergreen.V414.Id.Id Evergreen.V414.Id.UserId) (Evergreen.V414.Id.Id Evergreen.V414.Id.ChannelId)))
    }
