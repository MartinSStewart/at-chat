module Evergreen.V411.User exposing (..)

import Effect.Time
import Evergreen.V411.CustomEmoji
import Evergreen.V411.Discord
import Evergreen.V411.EmailAddress
import Evergreen.V411.Emoji
import Evergreen.V411.Encryption
import Evergreen.V411.FileStatus
import Evergreen.V411.Id
import Evergreen.V411.LinkedAndOtherDiscordUsers
import Evergreen.V411.Message
import Evergreen.V411.MuteSettings
import Evergreen.V411.NonemptyDict
import Evergreen.V411.OneOrGreater
import Evergreen.V411.Pagination
import Evergreen.V411.PersonName
import Evergreen.V411.RichText
import Evergreen.V411.Slack
import Evergreen.V411.Sticker
import Evergreen.V411.UserAgent
import Evergreen.V411.UserColor
import Evergreen.V411.UserSession
import Evergreen.V411.X25519
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
    = DmChannelLastViewed (Evergreen.V411.Id.Id Evergreen.V411.Id.UserId) Evergreen.V411.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V411.Discord.Id Evergreen.V411.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias FrontendCurrentUser =
    { name : Evergreen.V411.PersonName.PersonName
    , color : Evergreen.V411.UserColor.UserColor
    , isAdmin : Bool
    , email : Evergreen.V411.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V411.Id.Id Evergreen.V411.Pagination.PageId
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , embedVisibility : EmbedVisibility
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V411.Id.AnyGuildOrDmId (Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V411.Id.AnyGuildOrDmId, Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelMessageId ) (Evergreen.V411.Id.Id Evergreen.V411.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V411.Id.Id Evergreen.V411.Id.GuildId) ( Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelId, Evergreen.V411.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V411.Discord.Id Evergreen.V411.Discord.GuildId) ( Evergreen.V411.Discord.Id Evergreen.V411.Discord.ChannelId, Evergreen.V411.Id.ThreadRoute )
    , lastSlackChannelViewed : SeqDict.SeqDict (Evergreen.V411.Slack.Id Evergreen.V411.Slack.TeamId) ( Evergreen.V411.Slack.Id Evergreen.V411.Slack.ChannelId, Evergreen.V411.Id.ThreadRoute )
    , icon : Maybe Evergreen.V411.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V411.Id.Id Evergreen.V411.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V411.Discord.Id Evergreen.V411.Discord.GuildId)
    , slackNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V411.Slack.Id Evergreen.V411.Slack.TeamId)
    , directMentions : SeqDict.SeqDict (Evergreen.V411.Id.Id Evergreen.V411.Id.GuildId) (Evergreen.V411.NonemptyDict.NonemptyDict ( Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelId, Evergreen.V411.Id.ThreadRoute ) Evergreen.V411.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V411.Discord.Id Evergreen.V411.Discord.GuildId) (Evergreen.V411.NonemptyDict.NonemptyDict ( Evergreen.V411.Discord.Id Evergreen.V411.Discord.ChannelId, Evergreen.V411.Id.ThreadRoute ) Evergreen.V411.OneOrGreater.OneOrGreater)
    , slackDirectMentions : SeqDict.SeqDict (Evergreen.V411.Slack.Id Evergreen.V411.Slack.TeamId) (Evergreen.V411.NonemptyDict.NonemptyDict ( Evergreen.V411.Slack.Id Evergreen.V411.Slack.ChannelId, Evergreen.V411.Id.ThreadRoute ) Evergreen.V411.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , linkDiscordAcknowledgementIsChecked : Bool
    , linkSlackAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V411.RichText.Domain
    , emojiConfig : Evergreen.V411.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V411.Id.Id Evergreen.V411.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V411.Id.Id Evergreen.V411.Id.CustomEmojiId)
    , muteSettings : Evergreen.V411.MuteSettings.Model
    , publicKey : Maybe Evergreen.V411.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    , deleteAccountAt : Maybe Effect.Time.Posix
    }


type alias FrontendUser =
    { name : Evergreen.V411.PersonName.PersonName
    , color : Evergreen.V411.UserColor.UserColor
    , icon : Maybe Evergreen.V411.FileStatus.FileHash
    , publicKey : Maybe Evergreen.V411.X25519.PublicKey
    }


type BackendUserStatus
    = DeletedUser
    | UserHasEmail Evergreen.V411.EmailAddress.EmailAddress


type alias BackendUser =
    { name : Evergreen.V411.PersonName.PersonName
    , color : Evergreen.V411.UserColor.UserColor
    , isAdmin : Bool
    , email : BackendUserStatus
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V411.Id.Id Evergreen.V411.Pagination.PageId
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , embedVisibility : EmbedVisibility
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V411.Id.AnyGuildOrDmId (Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V411.Id.AnyGuildOrDmId, Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelMessageId ) (Evergreen.V411.Id.Id Evergreen.V411.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V411.Id.Id Evergreen.V411.Id.GuildId) ( Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelId, Evergreen.V411.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V411.Discord.Id Evergreen.V411.Discord.GuildId) ( Evergreen.V411.Discord.Id Evergreen.V411.Discord.ChannelId, Evergreen.V411.Id.ThreadRoute )
    , lastSlackChannelViewed : SeqDict.SeqDict (Evergreen.V411.Slack.Id Evergreen.V411.Slack.TeamId) ( Evergreen.V411.Slack.Id Evergreen.V411.Slack.ChannelId, Evergreen.V411.Id.ThreadRoute )
    , icon : Maybe Evergreen.V411.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V411.Id.Id Evergreen.V411.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V411.Discord.Id Evergreen.V411.Discord.GuildId)
    , slackNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V411.Slack.Id Evergreen.V411.Slack.TeamId)
    , directMentions : SeqDict.SeqDict (Evergreen.V411.Id.Id Evergreen.V411.Id.GuildId) (Evergreen.V411.NonemptyDict.NonemptyDict ( Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelId, Evergreen.V411.Id.ThreadRoute ) Evergreen.V411.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V411.Discord.Id Evergreen.V411.Discord.GuildId) (Evergreen.V411.NonemptyDict.NonemptyDict ( Evergreen.V411.Discord.Id Evergreen.V411.Discord.ChannelId, Evergreen.V411.Id.ThreadRoute ) Evergreen.V411.OneOrGreater.OneOrGreater)
    , slackDirectMentions : SeqDict.SeqDict (Evergreen.V411.Slack.Id Evergreen.V411.Slack.TeamId) (Evergreen.V411.NonemptyDict.NonemptyDict ( Evergreen.V411.Slack.Id Evergreen.V411.Slack.ChannelId, Evergreen.V411.Id.ThreadRoute ) Evergreen.V411.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , linkDiscordAcknowledgementIsChecked : Bool
    , linkSlackAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V411.RichText.Domain
    , emojiConfig : Evergreen.V411.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V411.Id.Id Evergreen.V411.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V411.Id.Id Evergreen.V411.Id.CustomEmojiId)
    , muteSettings : Evergreen.V411.MuteSettings.Model
    , publicKey : Maybe Evergreen.V411.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    , deleteAccountAt : Maybe Effect.Time.Posix
    }


type alias LocalUser =
    { session : Evergreen.V411.UserSession.UserSession
    , currentlyViewing : Evergreen.V411.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V411.Id.Id Evergreen.V411.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V411.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , slackUsers : SeqDict.SeqDict (Evergreen.V411.Slack.Id Evergreen.V411.Slack.UserId) Evergreen.V411.UserSession.SlackFrontendUser
    , linkedSlackUsers : SeqDict.SeqDict (Evergreen.V411.Slack.Id Evergreen.V411.Slack.UserId) (Evergreen.V411.Slack.Id Evergreen.V411.Slack.TeamId)
    , slackUsersNeedingAuth : SeqSet.SeqSet (Evergreen.V411.Slack.Id Evergreen.V411.Slack.UserId)
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V411.UserAgent.UserAgent
    , devicePixelRatio : Float
    , safeAreaInsetTop : Int
    , safeAreaInsetBottom : Int
    , stickers : SeqDict.SeqDict (Evergreen.V411.Id.Id Evergreen.V411.Id.StickerId) Evergreen.V411.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V411.Id.Id Evergreen.V411.Id.CustomEmojiId) Evergreen.V411.CustomEmoji.CustomEmojiData
    , emojiData : Maybe Evergreen.V411.Emoji.CachedEmojiData
    , decryptedMessages : SeqDict.SeqDict Evergreen.V411.Encryption.BytesHash (Result () (Evergreen.V411.Message.MessageContent (Evergreen.V411.Id.Id Evergreen.V411.Id.UserId) (Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelId)))
    }
