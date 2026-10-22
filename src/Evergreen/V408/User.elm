module Evergreen.V408.User exposing (..)

import Effect.Time
import Evergreen.V408.CustomEmoji
import Evergreen.V408.Discord
import Evergreen.V408.EmailAddress
import Evergreen.V408.Emoji
import Evergreen.V408.Encryption
import Evergreen.V408.FileStatus
import Evergreen.V408.Id
import Evergreen.V408.LinkedAndOtherDiscordUsers
import Evergreen.V408.Message
import Evergreen.V408.MuteSettings
import Evergreen.V408.NonemptyDict
import Evergreen.V408.OneOrGreater
import Evergreen.V408.Pagination
import Evergreen.V408.PersonName
import Evergreen.V408.RichText
import Evergreen.V408.Slack
import Evergreen.V408.Sticker
import Evergreen.V408.UserAgent
import Evergreen.V408.UserColor
import Evergreen.V408.UserSession
import Evergreen.V408.X25519
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
    = DmChannelLastViewed (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) Evergreen.V408.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V408.Discord.Id Evergreen.V408.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias FrontendCurrentUser =
    { name : Evergreen.V408.PersonName.PersonName
    , color : Evergreen.V408.UserColor.UserColor
    , isAdmin : Bool
    , email : Evergreen.V408.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V408.Id.Id Evergreen.V408.Pagination.PageId
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , embedVisibility : EmbedVisibility
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V408.Id.AnyGuildOrDmId (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V408.Id.AnyGuildOrDmId, Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId ) (Evergreen.V408.Id.Id Evergreen.V408.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId) ( Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelId, Evergreen.V408.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId) ( Evergreen.V408.Discord.Id Evergreen.V408.Discord.ChannelId, Evergreen.V408.Id.ThreadRoute )
    , lastSlackChannelViewed : SeqDict.SeqDict (Evergreen.V408.Slack.Id Evergreen.V408.Slack.TeamId) ( Evergreen.V408.Slack.Id Evergreen.V408.Slack.ChannelId, Evergreen.V408.Id.ThreadRoute )
    , icon : Maybe Evergreen.V408.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId)
    , slackNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V408.Slack.Id Evergreen.V408.Slack.TeamId)
    , directMentions : SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId) (Evergreen.V408.NonemptyDict.NonemptyDict ( Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelId, Evergreen.V408.Id.ThreadRoute ) Evergreen.V408.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId) (Evergreen.V408.NonemptyDict.NonemptyDict ( Evergreen.V408.Discord.Id Evergreen.V408.Discord.ChannelId, Evergreen.V408.Id.ThreadRoute ) Evergreen.V408.OneOrGreater.OneOrGreater)
    , slackDirectMentions : SeqDict.SeqDict (Evergreen.V408.Slack.Id Evergreen.V408.Slack.TeamId) (Evergreen.V408.NonemptyDict.NonemptyDict ( Evergreen.V408.Slack.Id Evergreen.V408.Slack.ChannelId, Evergreen.V408.Id.ThreadRoute ) Evergreen.V408.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , linkDiscordAcknowledgementIsChecked : Bool
    , linkSlackAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V408.RichText.Domain
    , emojiConfig : Evergreen.V408.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V408.Id.Id Evergreen.V408.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V408.Id.Id Evergreen.V408.Id.CustomEmojiId)
    , muteSettings : Evergreen.V408.MuteSettings.Model
    , publicKey : Maybe Evergreen.V408.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    , deleteAccountAt : Maybe Effect.Time.Posix
    }


type alias FrontendUser =
    { name : Evergreen.V408.PersonName.PersonName
    , color : Evergreen.V408.UserColor.UserColor
    , icon : Maybe Evergreen.V408.FileStatus.FileHash
    , publicKey : Maybe Evergreen.V408.X25519.PublicKey
    }


type BackendUserStatus
    = DeletedUser
    | UserHasEmail Evergreen.V408.EmailAddress.EmailAddress


type alias BackendUser =
    { name : Evergreen.V408.PersonName.PersonName
    , color : Evergreen.V408.UserColor.UserColor
    , isAdmin : Bool
    , email : BackendUserStatus
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V408.Id.Id Evergreen.V408.Pagination.PageId
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , embedVisibility : EmbedVisibility
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V408.Id.AnyGuildOrDmId (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V408.Id.AnyGuildOrDmId, Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId ) (Evergreen.V408.Id.Id Evergreen.V408.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId) ( Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelId, Evergreen.V408.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId) ( Evergreen.V408.Discord.Id Evergreen.V408.Discord.ChannelId, Evergreen.V408.Id.ThreadRoute )
    , lastSlackChannelViewed : SeqDict.SeqDict (Evergreen.V408.Slack.Id Evergreen.V408.Slack.TeamId) ( Evergreen.V408.Slack.Id Evergreen.V408.Slack.ChannelId, Evergreen.V408.Id.ThreadRoute )
    , icon : Maybe Evergreen.V408.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId)
    , slackNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V408.Slack.Id Evergreen.V408.Slack.TeamId)
    , directMentions : SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId) (Evergreen.V408.NonemptyDict.NonemptyDict ( Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelId, Evergreen.V408.Id.ThreadRoute ) Evergreen.V408.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId) (Evergreen.V408.NonemptyDict.NonemptyDict ( Evergreen.V408.Discord.Id Evergreen.V408.Discord.ChannelId, Evergreen.V408.Id.ThreadRoute ) Evergreen.V408.OneOrGreater.OneOrGreater)
    , slackDirectMentions : SeqDict.SeqDict (Evergreen.V408.Slack.Id Evergreen.V408.Slack.TeamId) (Evergreen.V408.NonemptyDict.NonemptyDict ( Evergreen.V408.Slack.Id Evergreen.V408.Slack.ChannelId, Evergreen.V408.Id.ThreadRoute ) Evergreen.V408.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , linkDiscordAcknowledgementIsChecked : Bool
    , linkSlackAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V408.RichText.Domain
    , emojiConfig : Evergreen.V408.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V408.Id.Id Evergreen.V408.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V408.Id.Id Evergreen.V408.Id.CustomEmojiId)
    , muteSettings : Evergreen.V408.MuteSettings.Model
    , publicKey : Maybe Evergreen.V408.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    , deleteAccountAt : Maybe Effect.Time.Posix
    }


type alias LocalUser =
    { session : Evergreen.V408.UserSession.UserSession
    , currentlyViewing : Evergreen.V408.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V408.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , slackUsers : SeqDict.SeqDict (Evergreen.V408.Slack.Id Evergreen.V408.Slack.UserId) Evergreen.V408.UserSession.SlackFrontendUser
    , linkedSlackUsers : SeqDict.SeqDict (Evergreen.V408.Slack.Id Evergreen.V408.Slack.UserId) (Evergreen.V408.Slack.Id Evergreen.V408.Slack.TeamId)
    , slackUsersNeedingAuth : SeqSet.SeqSet (Evergreen.V408.Slack.Id Evergreen.V408.Slack.UserId)
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V408.UserAgent.UserAgent
    , devicePixelRatio : Float
    , safeAreaInsetTop : Int
    , safeAreaInsetBottom : Int
    , stickers : SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Id.StickerId) Evergreen.V408.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Id.CustomEmojiId) Evergreen.V408.CustomEmoji.CustomEmojiData
    , emojiData : Maybe Evergreen.V408.Emoji.CachedEmojiData
    , decryptedMessages : SeqDict.SeqDict Evergreen.V408.Encryption.BytesHash (Result () (Evergreen.V408.Message.MessageContent (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelId)))
    }
