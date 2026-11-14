module Evergreen.V422.User exposing (..)

import Effect.Time
import Evergreen.V422.CustomEmoji
import Evergreen.V422.Discord
import Evergreen.V422.EmailAddress
import Evergreen.V422.Emoji
import Evergreen.V422.Encryption
import Evergreen.V422.FileStatus
import Evergreen.V422.Id
import Evergreen.V422.LinkedAndOtherDiscordUsers
import Evergreen.V422.Message
import Evergreen.V422.MuteSettings
import Evergreen.V422.NonemptyDict
import Evergreen.V422.OneOrGreater
import Evergreen.V422.Pagination
import Evergreen.V422.PeerToPeer
import Evergreen.V422.PersonName
import Evergreen.V422.RichText
import Evergreen.V422.Slack
import Evergreen.V422.Sticker
import Evergreen.V422.UserAgent
import Evergreen.V422.UserColor
import Evergreen.V422.UserSession
import Evergreen.V422.X25519
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
    = DmChannelLastViewed (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) Evergreen.V422.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V422.Discord.Id Evergreen.V422.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias FrontendCurrentUser =
    { name : Evergreen.V422.PersonName.PersonName
    , color : Evergreen.V422.UserColor.UserColor
    , isAdmin : Bool
    , email : Evergreen.V422.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V422.Id.Id Evergreen.V422.Pagination.PageId
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , embedVisibility : EmbedVisibility
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V422.Id.AnyGuildOrDmId (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V422.Id.AnyGuildOrDmId, Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId ) (Evergreen.V422.Id.Id Evergreen.V422.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId) ( Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelId, Evergreen.V422.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId) ( Evergreen.V422.Discord.Id Evergreen.V422.Discord.ChannelId, Evergreen.V422.Id.ThreadRoute )
    , lastSlackChannelViewed : SeqDict.SeqDict (Evergreen.V422.Slack.Id Evergreen.V422.Slack.TeamId) ( Evergreen.V422.Slack.Id Evergreen.V422.Slack.ChannelId, Evergreen.V422.Id.ThreadRoute )
    , icon : Maybe Evergreen.V422.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId)
    , slackNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V422.Slack.Id Evergreen.V422.Slack.TeamId)
    , directMentions : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId) (Evergreen.V422.NonemptyDict.NonemptyDict ( Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelId, Evergreen.V422.Id.ThreadRoute ) Evergreen.V422.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId) (Evergreen.V422.NonemptyDict.NonemptyDict ( Evergreen.V422.Discord.Id Evergreen.V422.Discord.ChannelId, Evergreen.V422.Id.ThreadRoute ) Evergreen.V422.OneOrGreater.OneOrGreater)
    , slackDirectMentions : SeqDict.SeqDict (Evergreen.V422.Slack.Id Evergreen.V422.Slack.TeamId) (Evergreen.V422.NonemptyDict.NonemptyDict ( Evergreen.V422.Slack.Id Evergreen.V422.Slack.ChannelId, Evergreen.V422.Id.ThreadRoute ) Evergreen.V422.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , linkDiscordAcknowledgementIsChecked : Bool
    , linkSlackAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V422.RichText.Domain
    , emojiConfig : Evergreen.V422.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V422.Id.Id Evergreen.V422.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V422.Id.Id Evergreen.V422.Id.CustomEmojiId)
    , muteSettings : Evergreen.V422.MuteSettings.Model
    , publicKey : Maybe Evergreen.V422.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    , deleteAccountAt : Maybe Effect.Time.Posix
    }


type alias FrontendUser =
    { name : Evergreen.V422.PersonName.PersonName
    , color : Evergreen.V422.UserColor.UserColor
    , icon : Maybe Evergreen.V422.FileStatus.FileHash
    , publicKey : Maybe Evergreen.V422.X25519.PublicKey
    }


type BackendUserStatus
    = DeletedUser
    | UserHasEmail Evergreen.V422.EmailAddress.EmailAddress


type alias BackendUser =
    { name : Evergreen.V422.PersonName.PersonName
    , color : Evergreen.V422.UserColor.UserColor
    , isAdmin : Bool
    , email : BackendUserStatus
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V422.Id.Id Evergreen.V422.Pagination.PageId
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , embedVisibility : EmbedVisibility
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V422.Id.AnyGuildOrDmId (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V422.Id.AnyGuildOrDmId, Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId ) (Evergreen.V422.Id.Id Evergreen.V422.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId) ( Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelId, Evergreen.V422.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId) ( Evergreen.V422.Discord.Id Evergreen.V422.Discord.ChannelId, Evergreen.V422.Id.ThreadRoute )
    , lastSlackChannelViewed : SeqDict.SeqDict (Evergreen.V422.Slack.Id Evergreen.V422.Slack.TeamId) ( Evergreen.V422.Slack.Id Evergreen.V422.Slack.ChannelId, Evergreen.V422.Id.ThreadRoute )
    , icon : Maybe Evergreen.V422.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId)
    , slackNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V422.Slack.Id Evergreen.V422.Slack.TeamId)
    , directMentions : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId) (Evergreen.V422.NonemptyDict.NonemptyDict ( Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelId, Evergreen.V422.Id.ThreadRoute ) Evergreen.V422.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId) (Evergreen.V422.NonemptyDict.NonemptyDict ( Evergreen.V422.Discord.Id Evergreen.V422.Discord.ChannelId, Evergreen.V422.Id.ThreadRoute ) Evergreen.V422.OneOrGreater.OneOrGreater)
    , slackDirectMentions : SeqDict.SeqDict (Evergreen.V422.Slack.Id Evergreen.V422.Slack.TeamId) (Evergreen.V422.NonemptyDict.NonemptyDict ( Evergreen.V422.Slack.Id Evergreen.V422.Slack.ChannelId, Evergreen.V422.Id.ThreadRoute ) Evergreen.V422.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , linkDiscordAcknowledgementIsChecked : Bool
    , linkSlackAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V422.RichText.Domain
    , emojiConfig : Evergreen.V422.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V422.Id.Id Evergreen.V422.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V422.Id.Id Evergreen.V422.Id.CustomEmojiId)
    , muteSettings : Evergreen.V422.MuteSettings.Model
    , publicKey : Maybe Evergreen.V422.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    , deleteAccountAt : Maybe Effect.Time.Posix
    }


type alias LocalUser =
    { session : Evergreen.V422.UserSession.UserSession
    , currentlyViewing : Evergreen.V422.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V422.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , slackUsers : SeqDict.SeqDict (Evergreen.V422.Slack.Id Evergreen.V422.Slack.UserId) Evergreen.V422.UserSession.SlackFrontendUser
    , linkedSlackUsers : SeqDict.SeqDict (Evergreen.V422.Slack.Id Evergreen.V422.Slack.UserId) (Evergreen.V422.Slack.Id Evergreen.V422.Slack.TeamId)
    , slackUsersNeedingAuth : SeqSet.SeqSet (Evergreen.V422.Slack.Id Evergreen.V422.Slack.UserId)
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V422.UserAgent.UserAgent
    , devicePixelRatio : Float
    , safeAreaInsetTop : Int
    , safeAreaInsetBottom : Int
    , stickers : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.StickerId) Evergreen.V422.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.CustomEmojiId) Evergreen.V422.CustomEmoji.CustomEmojiData
    , emojiData : Maybe Evergreen.V422.Emoji.CachedEmojiData
    , decryptedMessages : SeqDict.SeqDict Evergreen.V422.Encryption.BytesHash (Result () (Evergreen.V422.Message.MessageContent (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelId)))
    , peerToPeer : Evergreen.V422.PeerToPeer.Model
    }
