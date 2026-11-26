module Evergreen.V425.User exposing (..)

import Effect.Time
import Evergreen.V425.CustomEmoji
import Evergreen.V425.Discord
import Evergreen.V425.EmailAddress
import Evergreen.V425.Emoji
import Evergreen.V425.Encryption
import Evergreen.V425.FileStatus
import Evergreen.V425.Id
import Evergreen.V425.LinkedAndOtherDiscordUsers
import Evergreen.V425.Message
import Evergreen.V425.MuteSettings
import Evergreen.V425.NonemptyDict
import Evergreen.V425.OneOrGreater
import Evergreen.V425.Pagination
import Evergreen.V425.PeerToPeer
import Evergreen.V425.PersonName
import Evergreen.V425.RichText
import Evergreen.V425.Slack
import Evergreen.V425.Sticker
import Evergreen.V425.UserAgent
import Evergreen.V425.UserColor
import Evergreen.V425.UserSession
import Evergreen.V425.X25519
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
    = DmChannelLastViewed (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) Evergreen.V425.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V425.Discord.Id Evergreen.V425.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias FrontendCurrentUser =
    { name : Evergreen.V425.PersonName.PersonName
    , color : Evergreen.V425.UserColor.UserColor
    , isAdmin : Bool
    , email : Evergreen.V425.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V425.Id.Id Evergreen.V425.Pagination.PageId
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , embedVisibility : EmbedVisibility
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V425.Id.AnyGuildOrDmId (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V425.Id.AnyGuildOrDmId, Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId ) (Evergreen.V425.Id.Id Evergreen.V425.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId) ( Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelId, Evergreen.V425.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId) ( Evergreen.V425.Discord.Id Evergreen.V425.Discord.ChannelId, Evergreen.V425.Id.ThreadRoute )
    , lastSlackChannelViewed : SeqDict.SeqDict (Evergreen.V425.Slack.Id Evergreen.V425.Slack.TeamId) ( Evergreen.V425.Slack.Id Evergreen.V425.Slack.ChannelId, Evergreen.V425.Id.ThreadRoute )
    , icon : Maybe Evergreen.V425.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId)
    , slackNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V425.Slack.Id Evergreen.V425.Slack.TeamId)
    , directMentions : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId) (Evergreen.V425.NonemptyDict.NonemptyDict ( Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelId, Evergreen.V425.Id.ThreadRoute ) Evergreen.V425.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId) (Evergreen.V425.NonemptyDict.NonemptyDict ( Evergreen.V425.Discord.Id Evergreen.V425.Discord.ChannelId, Evergreen.V425.Id.ThreadRoute ) Evergreen.V425.OneOrGreater.OneOrGreater)
    , slackDirectMentions : SeqDict.SeqDict (Evergreen.V425.Slack.Id Evergreen.V425.Slack.TeamId) (Evergreen.V425.NonemptyDict.NonemptyDict ( Evergreen.V425.Slack.Id Evergreen.V425.Slack.ChannelId, Evergreen.V425.Id.ThreadRoute ) Evergreen.V425.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , linkDiscordAcknowledgementIsChecked : Bool
    , linkSlackAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V425.RichText.Domain
    , emojiConfig : Evergreen.V425.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V425.Id.Id Evergreen.V425.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V425.Id.Id Evergreen.V425.Id.CustomEmojiId)
    , muteSettings : Evergreen.V425.MuteSettings.Model
    , publicKey : Maybe Evergreen.V425.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    , deleteAccountAt : Maybe Effect.Time.Posix
    }


type alias FrontendUser =
    { name : Evergreen.V425.PersonName.PersonName
    , color : Evergreen.V425.UserColor.UserColor
    , icon : Maybe Evergreen.V425.FileStatus.FileHash
    , publicKey : Maybe Evergreen.V425.X25519.PublicKey
    }


type BackendUserStatus
    = DeletedUser
    | UserHasEmail Evergreen.V425.EmailAddress.EmailAddress


type alias BackendUser =
    { name : Evergreen.V425.PersonName.PersonName
    , color : Evergreen.V425.UserColor.UserColor
    , isAdmin : Bool
    , email : BackendUserStatus
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V425.Id.Id Evergreen.V425.Pagination.PageId
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , embedVisibility : EmbedVisibility
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V425.Id.AnyGuildOrDmId (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V425.Id.AnyGuildOrDmId, Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId ) (Evergreen.V425.Id.Id Evergreen.V425.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId) ( Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelId, Evergreen.V425.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId) ( Evergreen.V425.Discord.Id Evergreen.V425.Discord.ChannelId, Evergreen.V425.Id.ThreadRoute )
    , lastSlackChannelViewed : SeqDict.SeqDict (Evergreen.V425.Slack.Id Evergreen.V425.Slack.TeamId) ( Evergreen.V425.Slack.Id Evergreen.V425.Slack.ChannelId, Evergreen.V425.Id.ThreadRoute )
    , icon : Maybe Evergreen.V425.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId)
    , slackNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V425.Slack.Id Evergreen.V425.Slack.TeamId)
    , directMentions : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId) (Evergreen.V425.NonemptyDict.NonemptyDict ( Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelId, Evergreen.V425.Id.ThreadRoute ) Evergreen.V425.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId) (Evergreen.V425.NonemptyDict.NonemptyDict ( Evergreen.V425.Discord.Id Evergreen.V425.Discord.ChannelId, Evergreen.V425.Id.ThreadRoute ) Evergreen.V425.OneOrGreater.OneOrGreater)
    , slackDirectMentions : SeqDict.SeqDict (Evergreen.V425.Slack.Id Evergreen.V425.Slack.TeamId) (Evergreen.V425.NonemptyDict.NonemptyDict ( Evergreen.V425.Slack.Id Evergreen.V425.Slack.ChannelId, Evergreen.V425.Id.ThreadRoute ) Evergreen.V425.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , linkDiscordAcknowledgementIsChecked : Bool
    , linkSlackAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V425.RichText.Domain
    , emojiConfig : Evergreen.V425.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V425.Id.Id Evergreen.V425.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V425.Id.Id Evergreen.V425.Id.CustomEmojiId)
    , muteSettings : Evergreen.V425.MuteSettings.Model
    , publicKey : Maybe Evergreen.V425.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    , deleteAccountAt : Maybe Effect.Time.Posix
    }


type alias LocalUser =
    { session : Evergreen.V425.UserSession.UserSession
    , currentlyViewing : Evergreen.V425.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V425.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , slackUsers : SeqDict.SeqDict (Evergreen.V425.Slack.Id Evergreen.V425.Slack.UserId) Evergreen.V425.UserSession.SlackFrontendUser
    , linkedSlackUsers : SeqDict.SeqDict (Evergreen.V425.Slack.Id Evergreen.V425.Slack.UserId) (Evergreen.V425.Slack.Id Evergreen.V425.Slack.TeamId)
    , slackUsersNeedingAuth : SeqSet.SeqSet (Evergreen.V425.Slack.Id Evergreen.V425.Slack.UserId)
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V425.UserAgent.UserAgent
    , devicePixelRatio : Float
    , safeAreaInsetTop : Int
    , safeAreaInsetBottom : Int
    , stickers : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.StickerId) Evergreen.V425.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.CustomEmojiId) Evergreen.V425.CustomEmoji.CustomEmojiData
    , emojiData : Maybe Evergreen.V425.Emoji.CachedEmojiData
    , decryptedMessages : SeqDict.SeqDict Evergreen.V425.Encryption.BytesHash (Result () (Evergreen.V425.Message.MessageContent (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelId)))
    , peerToPeer : Evergreen.V425.PeerToPeer.Model
    }
