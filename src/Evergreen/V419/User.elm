module Evergreen.V419.User exposing (..)

import Effect.Time
import Evergreen.V419.CustomEmoji
import Evergreen.V419.Discord
import Evergreen.V419.EmailAddress
import Evergreen.V419.Emoji
import Evergreen.V419.Encryption
import Evergreen.V419.FileStatus
import Evergreen.V419.Id
import Evergreen.V419.LinkedAndOtherDiscordUsers
import Evergreen.V419.Message
import Evergreen.V419.MuteSettings
import Evergreen.V419.NonemptyDict
import Evergreen.V419.OneOrGreater
import Evergreen.V419.Pagination
import Evergreen.V419.PersonName
import Evergreen.V419.RichText
import Evergreen.V419.Slack
import Evergreen.V419.Sticker
import Evergreen.V419.UserAgent
import Evergreen.V419.UserColor
import Evergreen.V419.UserSession
import Evergreen.V419.X25519
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
    = DmChannelLastViewed (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) Evergreen.V419.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V419.Discord.Id Evergreen.V419.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias FrontendCurrentUser =
    { name : Evergreen.V419.PersonName.PersonName
    , color : Evergreen.V419.UserColor.UserColor
    , isAdmin : Bool
    , email : Evergreen.V419.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V419.Id.Id Evergreen.V419.Pagination.PageId
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , embedVisibility : EmbedVisibility
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V419.Id.AnyGuildOrDmId (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V419.Id.AnyGuildOrDmId, Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId ) (Evergreen.V419.Id.Id Evergreen.V419.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId) ( Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelId, Evergreen.V419.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId) ( Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId, Evergreen.V419.Id.ThreadRoute )
    , lastSlackChannelViewed : SeqDict.SeqDict (Evergreen.V419.Slack.Id Evergreen.V419.Slack.TeamId) ( Evergreen.V419.Slack.Id Evergreen.V419.Slack.ChannelId, Evergreen.V419.Id.ThreadRoute )
    , icon : Maybe Evergreen.V419.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId)
    , slackNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V419.Slack.Id Evergreen.V419.Slack.TeamId)
    , directMentions : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId) (Evergreen.V419.NonemptyDict.NonemptyDict ( Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelId, Evergreen.V419.Id.ThreadRoute ) Evergreen.V419.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId) (Evergreen.V419.NonemptyDict.NonemptyDict ( Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId, Evergreen.V419.Id.ThreadRoute ) Evergreen.V419.OneOrGreater.OneOrGreater)
    , slackDirectMentions : SeqDict.SeqDict (Evergreen.V419.Slack.Id Evergreen.V419.Slack.TeamId) (Evergreen.V419.NonemptyDict.NonemptyDict ( Evergreen.V419.Slack.Id Evergreen.V419.Slack.ChannelId, Evergreen.V419.Id.ThreadRoute ) Evergreen.V419.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , linkDiscordAcknowledgementIsChecked : Bool
    , linkSlackAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V419.RichText.Domain
    , emojiConfig : Evergreen.V419.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V419.Id.Id Evergreen.V419.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V419.Id.Id Evergreen.V419.Id.CustomEmojiId)
    , muteSettings : Evergreen.V419.MuteSettings.Model
    , publicKey : Maybe Evergreen.V419.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    , deleteAccountAt : Maybe Effect.Time.Posix
    }


type alias FrontendUser =
    { name : Evergreen.V419.PersonName.PersonName
    , color : Evergreen.V419.UserColor.UserColor
    , icon : Maybe Evergreen.V419.FileStatus.FileHash
    , publicKey : Maybe Evergreen.V419.X25519.PublicKey
    }


type BackendUserStatus
    = DeletedUser
    | UserHasEmail Evergreen.V419.EmailAddress.EmailAddress


type alias BackendUser =
    { name : Evergreen.V419.PersonName.PersonName
    , color : Evergreen.V419.UserColor.UserColor
    , isAdmin : Bool
    , email : BackendUserStatus
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V419.Id.Id Evergreen.V419.Pagination.PageId
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , embedVisibility : EmbedVisibility
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V419.Id.AnyGuildOrDmId (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V419.Id.AnyGuildOrDmId, Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId ) (Evergreen.V419.Id.Id Evergreen.V419.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId) ( Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelId, Evergreen.V419.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId) ( Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId, Evergreen.V419.Id.ThreadRoute )
    , lastSlackChannelViewed : SeqDict.SeqDict (Evergreen.V419.Slack.Id Evergreen.V419.Slack.TeamId) ( Evergreen.V419.Slack.Id Evergreen.V419.Slack.ChannelId, Evergreen.V419.Id.ThreadRoute )
    , icon : Maybe Evergreen.V419.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId)
    , slackNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V419.Slack.Id Evergreen.V419.Slack.TeamId)
    , directMentions : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId) (Evergreen.V419.NonemptyDict.NonemptyDict ( Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelId, Evergreen.V419.Id.ThreadRoute ) Evergreen.V419.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId) (Evergreen.V419.NonemptyDict.NonemptyDict ( Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId, Evergreen.V419.Id.ThreadRoute ) Evergreen.V419.OneOrGreater.OneOrGreater)
    , slackDirectMentions : SeqDict.SeqDict (Evergreen.V419.Slack.Id Evergreen.V419.Slack.TeamId) (Evergreen.V419.NonemptyDict.NonemptyDict ( Evergreen.V419.Slack.Id Evergreen.V419.Slack.ChannelId, Evergreen.V419.Id.ThreadRoute ) Evergreen.V419.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , linkDiscordAcknowledgementIsChecked : Bool
    , linkSlackAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V419.RichText.Domain
    , emojiConfig : Evergreen.V419.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V419.Id.Id Evergreen.V419.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V419.Id.Id Evergreen.V419.Id.CustomEmojiId)
    , muteSettings : Evergreen.V419.MuteSettings.Model
    , publicKey : Maybe Evergreen.V419.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    , deleteAccountAt : Maybe Effect.Time.Posix
    }


type alias LocalUser =
    { session : Evergreen.V419.UserSession.UserSession
    , currentlyViewing : Evergreen.V419.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V419.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , slackUsers : SeqDict.SeqDict (Evergreen.V419.Slack.Id Evergreen.V419.Slack.UserId) Evergreen.V419.UserSession.SlackFrontendUser
    , linkedSlackUsers : SeqDict.SeqDict (Evergreen.V419.Slack.Id Evergreen.V419.Slack.UserId) (Evergreen.V419.Slack.Id Evergreen.V419.Slack.TeamId)
    , slackUsersNeedingAuth : SeqSet.SeqSet (Evergreen.V419.Slack.Id Evergreen.V419.Slack.UserId)
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V419.UserAgent.UserAgent
    , devicePixelRatio : Float
    , safeAreaInsetTop : Int
    , safeAreaInsetBottom : Int
    , stickers : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.StickerId) Evergreen.V419.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.CustomEmojiId) Evergreen.V419.CustomEmoji.CustomEmojiData
    , emojiData : Maybe Evergreen.V419.Emoji.CachedEmojiData
    , decryptedMessages : SeqDict.SeqDict Evergreen.V419.Encryption.BytesHash (Result () (Evergreen.V419.Message.MessageContent (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelId)))
    }
