module Evergreen.V423.User exposing (..)

import Effect.Time
import Evergreen.V423.CustomEmoji
import Evergreen.V423.Discord
import Evergreen.V423.EmailAddress
import Evergreen.V423.Emoji
import Evergreen.V423.Encryption
import Evergreen.V423.FileStatus
import Evergreen.V423.Id
import Evergreen.V423.LinkedAndOtherDiscordUsers
import Evergreen.V423.Message
import Evergreen.V423.MuteSettings
import Evergreen.V423.NonemptyDict
import Evergreen.V423.OneOrGreater
import Evergreen.V423.Pagination
import Evergreen.V423.PeerToPeer
import Evergreen.V423.PersonName
import Evergreen.V423.RichText
import Evergreen.V423.Slack
import Evergreen.V423.Sticker
import Evergreen.V423.UserAgent
import Evergreen.V423.UserColor
import Evergreen.V423.UserSession
import Evergreen.V423.X25519
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
    = DmChannelLastViewed (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) Evergreen.V423.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V423.Discord.Id Evergreen.V423.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias FrontendCurrentUser =
    { name : Evergreen.V423.PersonName.PersonName
    , color : Evergreen.V423.UserColor.UserColor
    , isAdmin : Bool
    , email : Evergreen.V423.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V423.Id.Id Evergreen.V423.Pagination.PageId
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , embedVisibility : EmbedVisibility
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V423.Id.AnyGuildOrDmId (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V423.Id.AnyGuildOrDmId, Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId ) (Evergreen.V423.Id.Id Evergreen.V423.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId) ( Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelId, Evergreen.V423.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId) ( Evergreen.V423.Discord.Id Evergreen.V423.Discord.ChannelId, Evergreen.V423.Id.ThreadRoute )
    , lastSlackChannelViewed : SeqDict.SeqDict (Evergreen.V423.Slack.Id Evergreen.V423.Slack.TeamId) ( Evergreen.V423.Slack.Id Evergreen.V423.Slack.ChannelId, Evergreen.V423.Id.ThreadRoute )
    , icon : Maybe Evergreen.V423.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId)
    , slackNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V423.Slack.Id Evergreen.V423.Slack.TeamId)
    , directMentions : SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId) (Evergreen.V423.NonemptyDict.NonemptyDict ( Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelId, Evergreen.V423.Id.ThreadRoute ) Evergreen.V423.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId) (Evergreen.V423.NonemptyDict.NonemptyDict ( Evergreen.V423.Discord.Id Evergreen.V423.Discord.ChannelId, Evergreen.V423.Id.ThreadRoute ) Evergreen.V423.OneOrGreater.OneOrGreater)
    , slackDirectMentions : SeqDict.SeqDict (Evergreen.V423.Slack.Id Evergreen.V423.Slack.TeamId) (Evergreen.V423.NonemptyDict.NonemptyDict ( Evergreen.V423.Slack.Id Evergreen.V423.Slack.ChannelId, Evergreen.V423.Id.ThreadRoute ) Evergreen.V423.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , linkDiscordAcknowledgementIsChecked : Bool
    , linkSlackAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V423.RichText.Domain
    , emojiConfig : Evergreen.V423.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V423.Id.Id Evergreen.V423.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V423.Id.Id Evergreen.V423.Id.CustomEmojiId)
    , muteSettings : Evergreen.V423.MuteSettings.Model
    , publicKey : Maybe Evergreen.V423.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    , deleteAccountAt : Maybe Effect.Time.Posix
    }


type alias FrontendUser =
    { name : Evergreen.V423.PersonName.PersonName
    , color : Evergreen.V423.UserColor.UserColor
    , icon : Maybe Evergreen.V423.FileStatus.FileHash
    , publicKey : Maybe Evergreen.V423.X25519.PublicKey
    }


type BackendUserStatus
    = DeletedUser
    | UserHasEmail Evergreen.V423.EmailAddress.EmailAddress


type alias BackendUser =
    { name : Evergreen.V423.PersonName.PersonName
    , color : Evergreen.V423.UserColor.UserColor
    , isAdmin : Bool
    , email : BackendUserStatus
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V423.Id.Id Evergreen.V423.Pagination.PageId
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , embedVisibility : EmbedVisibility
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V423.Id.AnyGuildOrDmId (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V423.Id.AnyGuildOrDmId, Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId ) (Evergreen.V423.Id.Id Evergreen.V423.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId) ( Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelId, Evergreen.V423.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId) ( Evergreen.V423.Discord.Id Evergreen.V423.Discord.ChannelId, Evergreen.V423.Id.ThreadRoute )
    , lastSlackChannelViewed : SeqDict.SeqDict (Evergreen.V423.Slack.Id Evergreen.V423.Slack.TeamId) ( Evergreen.V423.Slack.Id Evergreen.V423.Slack.ChannelId, Evergreen.V423.Id.ThreadRoute )
    , icon : Maybe Evergreen.V423.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId)
    , slackNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V423.Slack.Id Evergreen.V423.Slack.TeamId)
    , directMentions : SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId) (Evergreen.V423.NonemptyDict.NonemptyDict ( Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelId, Evergreen.V423.Id.ThreadRoute ) Evergreen.V423.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId) (Evergreen.V423.NonemptyDict.NonemptyDict ( Evergreen.V423.Discord.Id Evergreen.V423.Discord.ChannelId, Evergreen.V423.Id.ThreadRoute ) Evergreen.V423.OneOrGreater.OneOrGreater)
    , slackDirectMentions : SeqDict.SeqDict (Evergreen.V423.Slack.Id Evergreen.V423.Slack.TeamId) (Evergreen.V423.NonemptyDict.NonemptyDict ( Evergreen.V423.Slack.Id Evergreen.V423.Slack.ChannelId, Evergreen.V423.Id.ThreadRoute ) Evergreen.V423.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , linkDiscordAcknowledgementIsChecked : Bool
    , linkSlackAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V423.RichText.Domain
    , emojiConfig : Evergreen.V423.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V423.Id.Id Evergreen.V423.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V423.Id.Id Evergreen.V423.Id.CustomEmojiId)
    , muteSettings : Evergreen.V423.MuteSettings.Model
    , publicKey : Maybe Evergreen.V423.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    , deleteAccountAt : Maybe Effect.Time.Posix
    }


type alias LocalUser =
    { session : Evergreen.V423.UserSession.UserSession
    , currentlyViewing : Evergreen.V423.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V423.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , slackUsers : SeqDict.SeqDict (Evergreen.V423.Slack.Id Evergreen.V423.Slack.UserId) Evergreen.V423.UserSession.SlackFrontendUser
    , linkedSlackUsers : SeqDict.SeqDict (Evergreen.V423.Slack.Id Evergreen.V423.Slack.UserId) (Evergreen.V423.Slack.Id Evergreen.V423.Slack.TeamId)
    , slackUsersNeedingAuth : SeqSet.SeqSet (Evergreen.V423.Slack.Id Evergreen.V423.Slack.UserId)
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V423.UserAgent.UserAgent
    , devicePixelRatio : Float
    , safeAreaInsetTop : Int
    , safeAreaInsetBottom : Int
    , stickers : SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.StickerId) Evergreen.V423.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.CustomEmojiId) Evergreen.V423.CustomEmoji.CustomEmojiData
    , emojiData : Maybe Evergreen.V423.Emoji.CachedEmojiData
    , decryptedMessages : SeqDict.SeqDict Evergreen.V423.Encryption.BytesHash (Result () (Evergreen.V423.Message.MessageContent (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelId)))
    , peerToPeer : Evergreen.V423.PeerToPeer.Model
    }
