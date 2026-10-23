module Evergreen.V409.User exposing (..)

import Effect.Time
import Evergreen.V409.CustomEmoji
import Evergreen.V409.Discord
import Evergreen.V409.EmailAddress
import Evergreen.V409.Emoji
import Evergreen.V409.Encryption
import Evergreen.V409.FileStatus
import Evergreen.V409.Id
import Evergreen.V409.LinkedAndOtherDiscordUsers
import Evergreen.V409.Message
import Evergreen.V409.MuteSettings
import Evergreen.V409.NonemptyDict
import Evergreen.V409.OneOrGreater
import Evergreen.V409.Pagination
import Evergreen.V409.PersonName
import Evergreen.V409.RichText
import Evergreen.V409.Slack
import Evergreen.V409.Sticker
import Evergreen.V409.UserAgent
import Evergreen.V409.UserColor
import Evergreen.V409.UserSession
import Evergreen.V409.X25519
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
    = DmChannelLastViewed (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) Evergreen.V409.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V409.Discord.Id Evergreen.V409.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias FrontendCurrentUser =
    { name : Evergreen.V409.PersonName.PersonName
    , color : Evergreen.V409.UserColor.UserColor
    , isAdmin : Bool
    , email : Evergreen.V409.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V409.Id.Id Evergreen.V409.Pagination.PageId
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , embedVisibility : EmbedVisibility
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V409.Id.AnyGuildOrDmId (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V409.Id.AnyGuildOrDmId, Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId ) (Evergreen.V409.Id.Id Evergreen.V409.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId) ( Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelId, Evergreen.V409.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId) ( Evergreen.V409.Discord.Id Evergreen.V409.Discord.ChannelId, Evergreen.V409.Id.ThreadRoute )
    , lastSlackChannelViewed : SeqDict.SeqDict (Evergreen.V409.Slack.Id Evergreen.V409.Slack.TeamId) ( Evergreen.V409.Slack.Id Evergreen.V409.Slack.ChannelId, Evergreen.V409.Id.ThreadRoute )
    , icon : Maybe Evergreen.V409.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId)
    , slackNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V409.Slack.Id Evergreen.V409.Slack.TeamId)
    , directMentions : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId) (Evergreen.V409.NonemptyDict.NonemptyDict ( Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelId, Evergreen.V409.Id.ThreadRoute ) Evergreen.V409.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId) (Evergreen.V409.NonemptyDict.NonemptyDict ( Evergreen.V409.Discord.Id Evergreen.V409.Discord.ChannelId, Evergreen.V409.Id.ThreadRoute ) Evergreen.V409.OneOrGreater.OneOrGreater)
    , slackDirectMentions : SeqDict.SeqDict (Evergreen.V409.Slack.Id Evergreen.V409.Slack.TeamId) (Evergreen.V409.NonemptyDict.NonemptyDict ( Evergreen.V409.Slack.Id Evergreen.V409.Slack.ChannelId, Evergreen.V409.Id.ThreadRoute ) Evergreen.V409.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , linkDiscordAcknowledgementIsChecked : Bool
    , linkSlackAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V409.RichText.Domain
    , emojiConfig : Evergreen.V409.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V409.Id.Id Evergreen.V409.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V409.Id.Id Evergreen.V409.Id.CustomEmojiId)
    , muteSettings : Evergreen.V409.MuteSettings.Model
    , publicKey : Maybe Evergreen.V409.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    , deleteAccountAt : Maybe Effect.Time.Posix
    }


type alias FrontendUser =
    { name : Evergreen.V409.PersonName.PersonName
    , color : Evergreen.V409.UserColor.UserColor
    , icon : Maybe Evergreen.V409.FileStatus.FileHash
    , publicKey : Maybe Evergreen.V409.X25519.PublicKey
    }


type BackendUserStatus
    = DeletedUser
    | UserHasEmail Evergreen.V409.EmailAddress.EmailAddress


type alias BackendUser =
    { name : Evergreen.V409.PersonName.PersonName
    , color : Evergreen.V409.UserColor.UserColor
    , isAdmin : Bool
    , email : BackendUserStatus
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V409.Id.Id Evergreen.V409.Pagination.PageId
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , embedVisibility : EmbedVisibility
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V409.Id.AnyGuildOrDmId (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V409.Id.AnyGuildOrDmId, Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId ) (Evergreen.V409.Id.Id Evergreen.V409.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId) ( Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelId, Evergreen.V409.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId) ( Evergreen.V409.Discord.Id Evergreen.V409.Discord.ChannelId, Evergreen.V409.Id.ThreadRoute )
    , lastSlackChannelViewed : SeqDict.SeqDict (Evergreen.V409.Slack.Id Evergreen.V409.Slack.TeamId) ( Evergreen.V409.Slack.Id Evergreen.V409.Slack.ChannelId, Evergreen.V409.Id.ThreadRoute )
    , icon : Maybe Evergreen.V409.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId)
    , slackNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V409.Slack.Id Evergreen.V409.Slack.TeamId)
    , directMentions : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId) (Evergreen.V409.NonemptyDict.NonemptyDict ( Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelId, Evergreen.V409.Id.ThreadRoute ) Evergreen.V409.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId) (Evergreen.V409.NonemptyDict.NonemptyDict ( Evergreen.V409.Discord.Id Evergreen.V409.Discord.ChannelId, Evergreen.V409.Id.ThreadRoute ) Evergreen.V409.OneOrGreater.OneOrGreater)
    , slackDirectMentions : SeqDict.SeqDict (Evergreen.V409.Slack.Id Evergreen.V409.Slack.TeamId) (Evergreen.V409.NonemptyDict.NonemptyDict ( Evergreen.V409.Slack.Id Evergreen.V409.Slack.ChannelId, Evergreen.V409.Id.ThreadRoute ) Evergreen.V409.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , linkDiscordAcknowledgementIsChecked : Bool
    , linkSlackAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V409.RichText.Domain
    , emojiConfig : Evergreen.V409.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V409.Id.Id Evergreen.V409.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V409.Id.Id Evergreen.V409.Id.CustomEmojiId)
    , muteSettings : Evergreen.V409.MuteSettings.Model
    , publicKey : Maybe Evergreen.V409.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    , deleteAccountAt : Maybe Effect.Time.Posix
    }


type alias LocalUser =
    { session : Evergreen.V409.UserSession.UserSession
    , currentlyViewing : Evergreen.V409.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V409.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , slackUsers : SeqDict.SeqDict (Evergreen.V409.Slack.Id Evergreen.V409.Slack.UserId) Evergreen.V409.UserSession.SlackFrontendUser
    , linkedSlackUsers : SeqDict.SeqDict (Evergreen.V409.Slack.Id Evergreen.V409.Slack.UserId) (Evergreen.V409.Slack.Id Evergreen.V409.Slack.TeamId)
    , slackUsersNeedingAuth : SeqSet.SeqSet (Evergreen.V409.Slack.Id Evergreen.V409.Slack.UserId)
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V409.UserAgent.UserAgent
    , devicePixelRatio : Float
    , safeAreaInsetTop : Int
    , safeAreaInsetBottom : Int
    , stickers : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.StickerId) Evergreen.V409.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.CustomEmojiId) Evergreen.V409.CustomEmoji.CustomEmojiData
    , emojiData : Maybe Evergreen.V409.Emoji.CachedEmojiData
    , decryptedMessages : SeqDict.SeqDict Evergreen.V409.Encryption.BytesHash (Result () (Evergreen.V409.Message.MessageContent (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelId)))
    }
