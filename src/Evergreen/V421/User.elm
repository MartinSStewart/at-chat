module Evergreen.V421.User exposing (..)

import Effect.Time
import Evergreen.V421.CustomEmoji
import Evergreen.V421.Discord
import Evergreen.V421.EmailAddress
import Evergreen.V421.Emoji
import Evergreen.V421.Encryption
import Evergreen.V421.FileStatus
import Evergreen.V421.Id
import Evergreen.V421.LinkedAndOtherDiscordUsers
import Evergreen.V421.Message
import Evergreen.V421.MuteSettings
import Evergreen.V421.NonemptyDict
import Evergreen.V421.OneOrGreater
import Evergreen.V421.Pagination
import Evergreen.V421.PeerToPeer
import Evergreen.V421.PersonName
import Evergreen.V421.RichText
import Evergreen.V421.Slack
import Evergreen.V421.Sticker
import Evergreen.V421.UserAgent
import Evergreen.V421.UserColor
import Evergreen.V421.UserSession
import Evergreen.V421.X25519
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
    = DmChannelLastViewed (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) Evergreen.V421.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V421.Discord.Id Evergreen.V421.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias FrontendCurrentUser =
    { name : Evergreen.V421.PersonName.PersonName
    , color : Evergreen.V421.UserColor.UserColor
    , isAdmin : Bool
    , email : Evergreen.V421.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V421.Id.Id Evergreen.V421.Pagination.PageId
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , embedVisibility : EmbedVisibility
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V421.Id.AnyGuildOrDmId (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V421.Id.AnyGuildOrDmId, Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId ) (Evergreen.V421.Id.Id Evergreen.V421.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId) ( Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelId, Evergreen.V421.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId) ( Evergreen.V421.Discord.Id Evergreen.V421.Discord.ChannelId, Evergreen.V421.Id.ThreadRoute )
    , lastSlackChannelViewed : SeqDict.SeqDict (Evergreen.V421.Slack.Id Evergreen.V421.Slack.TeamId) ( Evergreen.V421.Slack.Id Evergreen.V421.Slack.ChannelId, Evergreen.V421.Id.ThreadRoute )
    , icon : Maybe Evergreen.V421.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId)
    , slackNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V421.Slack.Id Evergreen.V421.Slack.TeamId)
    , directMentions : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId) (Evergreen.V421.NonemptyDict.NonemptyDict ( Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelId, Evergreen.V421.Id.ThreadRoute ) Evergreen.V421.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId) (Evergreen.V421.NonemptyDict.NonemptyDict ( Evergreen.V421.Discord.Id Evergreen.V421.Discord.ChannelId, Evergreen.V421.Id.ThreadRoute ) Evergreen.V421.OneOrGreater.OneOrGreater)
    , slackDirectMentions : SeqDict.SeqDict (Evergreen.V421.Slack.Id Evergreen.V421.Slack.TeamId) (Evergreen.V421.NonemptyDict.NonemptyDict ( Evergreen.V421.Slack.Id Evergreen.V421.Slack.ChannelId, Evergreen.V421.Id.ThreadRoute ) Evergreen.V421.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , linkDiscordAcknowledgementIsChecked : Bool
    , linkSlackAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V421.RichText.Domain
    , emojiConfig : Evergreen.V421.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V421.Id.Id Evergreen.V421.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V421.Id.Id Evergreen.V421.Id.CustomEmojiId)
    , muteSettings : Evergreen.V421.MuteSettings.Model
    , publicKey : Maybe Evergreen.V421.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    , deleteAccountAt : Maybe Effect.Time.Posix
    }


type alias FrontendUser =
    { name : Evergreen.V421.PersonName.PersonName
    , color : Evergreen.V421.UserColor.UserColor
    , icon : Maybe Evergreen.V421.FileStatus.FileHash
    , publicKey : Maybe Evergreen.V421.X25519.PublicKey
    }


type BackendUserStatus
    = DeletedUser
    | UserHasEmail Evergreen.V421.EmailAddress.EmailAddress


type alias BackendUser =
    { name : Evergreen.V421.PersonName.PersonName
    , color : Evergreen.V421.UserColor.UserColor
    , isAdmin : Bool
    , email : BackendUserStatus
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V421.Id.Id Evergreen.V421.Pagination.PageId
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , embedVisibility : EmbedVisibility
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V421.Id.AnyGuildOrDmId (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V421.Id.AnyGuildOrDmId, Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId ) (Evergreen.V421.Id.Id Evergreen.V421.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId) ( Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelId, Evergreen.V421.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId) ( Evergreen.V421.Discord.Id Evergreen.V421.Discord.ChannelId, Evergreen.V421.Id.ThreadRoute )
    , lastSlackChannelViewed : SeqDict.SeqDict (Evergreen.V421.Slack.Id Evergreen.V421.Slack.TeamId) ( Evergreen.V421.Slack.Id Evergreen.V421.Slack.ChannelId, Evergreen.V421.Id.ThreadRoute )
    , icon : Maybe Evergreen.V421.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId)
    , slackNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V421.Slack.Id Evergreen.V421.Slack.TeamId)
    , directMentions : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId) (Evergreen.V421.NonemptyDict.NonemptyDict ( Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelId, Evergreen.V421.Id.ThreadRoute ) Evergreen.V421.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId) (Evergreen.V421.NonemptyDict.NonemptyDict ( Evergreen.V421.Discord.Id Evergreen.V421.Discord.ChannelId, Evergreen.V421.Id.ThreadRoute ) Evergreen.V421.OneOrGreater.OneOrGreater)
    , slackDirectMentions : SeqDict.SeqDict (Evergreen.V421.Slack.Id Evergreen.V421.Slack.TeamId) (Evergreen.V421.NonemptyDict.NonemptyDict ( Evergreen.V421.Slack.Id Evergreen.V421.Slack.ChannelId, Evergreen.V421.Id.ThreadRoute ) Evergreen.V421.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , linkDiscordAcknowledgementIsChecked : Bool
    , linkSlackAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V421.RichText.Domain
    , emojiConfig : Evergreen.V421.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V421.Id.Id Evergreen.V421.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V421.Id.Id Evergreen.V421.Id.CustomEmojiId)
    , muteSettings : Evergreen.V421.MuteSettings.Model
    , publicKey : Maybe Evergreen.V421.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    , deleteAccountAt : Maybe Effect.Time.Posix
    }


type alias LocalUser =
    { session : Evergreen.V421.UserSession.UserSession
    , currentlyViewing : Evergreen.V421.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V421.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , slackUsers : SeqDict.SeqDict (Evergreen.V421.Slack.Id Evergreen.V421.Slack.UserId) Evergreen.V421.UserSession.SlackFrontendUser
    , linkedSlackUsers : SeqDict.SeqDict (Evergreen.V421.Slack.Id Evergreen.V421.Slack.UserId) (Evergreen.V421.Slack.Id Evergreen.V421.Slack.TeamId)
    , slackUsersNeedingAuth : SeqSet.SeqSet (Evergreen.V421.Slack.Id Evergreen.V421.Slack.UserId)
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V421.UserAgent.UserAgent
    , devicePixelRatio : Float
    , safeAreaInsetTop : Int
    , safeAreaInsetBottom : Int
    , stickers : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.StickerId) Evergreen.V421.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.CustomEmojiId) Evergreen.V421.CustomEmoji.CustomEmojiData
    , emojiData : Maybe Evergreen.V421.Emoji.CachedEmojiData
    , decryptedMessages : SeqDict.SeqDict Evergreen.V421.Encryption.BytesHash (Result () (Evergreen.V421.Message.MessageContent (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelId)))
    , peerToPeer : Evergreen.V421.PeerToPeer.Model
    }
