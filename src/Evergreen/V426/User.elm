module Evergreen.V426.User exposing (..)

import Effect.Time
import Evergreen.V426.CustomEmoji
import Evergreen.V426.Discord
import Evergreen.V426.EmailAddress
import Evergreen.V426.Emoji
import Evergreen.V426.Encryption
import Evergreen.V426.FileStatus
import Evergreen.V426.Id
import Evergreen.V426.LinkedAndOtherDiscordUsers
import Evergreen.V426.Message
import Evergreen.V426.MuteSettings
import Evergreen.V426.NonemptyDict
import Evergreen.V426.OneOrGreater
import Evergreen.V426.Pagination
import Evergreen.V426.PeerToPeer
import Evergreen.V426.PersonName
import Evergreen.V426.RichText
import Evergreen.V426.Slack
import Evergreen.V426.Sticker
import Evergreen.V426.UserAgent
import Evergreen.V426.UserColor
import Evergreen.V426.UserSession
import Evergreen.V426.X25519
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
    = DmChannelLastViewed (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) Evergreen.V426.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V426.Discord.Id Evergreen.V426.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias FrontendCurrentUser =
    { name : Evergreen.V426.PersonName.PersonName
    , color : Evergreen.V426.UserColor.UserColor
    , isAdmin : Bool
    , email : Evergreen.V426.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V426.Id.Id Evergreen.V426.Pagination.PageId
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , embedVisibility : EmbedVisibility
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V426.Id.AnyGuildOrDmId (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V426.Id.AnyGuildOrDmId, Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId ) (Evergreen.V426.Id.Id Evergreen.V426.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId) ( Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelId, Evergreen.V426.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId) ( Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId, Evergreen.V426.Id.ThreadRoute )
    , lastSlackChannelViewed : SeqDict.SeqDict (Evergreen.V426.Slack.Id Evergreen.V426.Slack.TeamId) ( Evergreen.V426.Slack.Id Evergreen.V426.Slack.ChannelId, Evergreen.V426.Id.ThreadRoute )
    , icon : Maybe Evergreen.V426.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId)
    , slackNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V426.Slack.Id Evergreen.V426.Slack.TeamId)
    , directMentions : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId) (Evergreen.V426.NonemptyDict.NonemptyDict ( Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelId, Evergreen.V426.Id.ThreadRoute ) Evergreen.V426.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId) (Evergreen.V426.NonemptyDict.NonemptyDict ( Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId, Evergreen.V426.Id.ThreadRoute ) Evergreen.V426.OneOrGreater.OneOrGreater)
    , slackDirectMentions : SeqDict.SeqDict (Evergreen.V426.Slack.Id Evergreen.V426.Slack.TeamId) (Evergreen.V426.NonemptyDict.NonemptyDict ( Evergreen.V426.Slack.Id Evergreen.V426.Slack.ChannelId, Evergreen.V426.Id.ThreadRoute ) Evergreen.V426.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , linkDiscordAcknowledgementIsChecked : Bool
    , linkSlackAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V426.RichText.Domain
    , emojiConfig : Evergreen.V426.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V426.Id.Id Evergreen.V426.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V426.Id.Id Evergreen.V426.Id.CustomEmojiId)
    , muteSettings : Evergreen.V426.MuteSettings.Model
    , publicKey : Maybe Evergreen.V426.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    , deleteAccountAt : Maybe Effect.Time.Posix
    }


type alias FrontendUser =
    { name : Evergreen.V426.PersonName.PersonName
    , color : Evergreen.V426.UserColor.UserColor
    , icon : Maybe Evergreen.V426.FileStatus.FileHash
    , publicKey : Maybe Evergreen.V426.X25519.PublicKey
    }


type BackendUserStatus
    = DeletedUser
    | UserHasEmail Evergreen.V426.EmailAddress.EmailAddress


type alias BackendUser =
    { name : Evergreen.V426.PersonName.PersonName
    , color : Evergreen.V426.UserColor.UserColor
    , isAdmin : Bool
    , email : BackendUserStatus
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V426.Id.Id Evergreen.V426.Pagination.PageId
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , embedVisibility : EmbedVisibility
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V426.Id.AnyGuildOrDmId (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V426.Id.AnyGuildOrDmId, Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId ) (Evergreen.V426.Id.Id Evergreen.V426.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId) ( Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelId, Evergreen.V426.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId) ( Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId, Evergreen.V426.Id.ThreadRoute )
    , lastSlackChannelViewed : SeqDict.SeqDict (Evergreen.V426.Slack.Id Evergreen.V426.Slack.TeamId) ( Evergreen.V426.Slack.Id Evergreen.V426.Slack.ChannelId, Evergreen.V426.Id.ThreadRoute )
    , icon : Maybe Evergreen.V426.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId)
    , slackNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V426.Slack.Id Evergreen.V426.Slack.TeamId)
    , directMentions : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId) (Evergreen.V426.NonemptyDict.NonemptyDict ( Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelId, Evergreen.V426.Id.ThreadRoute ) Evergreen.V426.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId) (Evergreen.V426.NonemptyDict.NonemptyDict ( Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId, Evergreen.V426.Id.ThreadRoute ) Evergreen.V426.OneOrGreater.OneOrGreater)
    , slackDirectMentions : SeqDict.SeqDict (Evergreen.V426.Slack.Id Evergreen.V426.Slack.TeamId) (Evergreen.V426.NonemptyDict.NonemptyDict ( Evergreen.V426.Slack.Id Evergreen.V426.Slack.ChannelId, Evergreen.V426.Id.ThreadRoute ) Evergreen.V426.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , linkDiscordAcknowledgementIsChecked : Bool
    , linkSlackAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V426.RichText.Domain
    , emojiConfig : Evergreen.V426.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V426.Id.Id Evergreen.V426.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V426.Id.Id Evergreen.V426.Id.CustomEmojiId)
    , muteSettings : Evergreen.V426.MuteSettings.Model
    , publicKey : Maybe Evergreen.V426.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    , deleteAccountAt : Maybe Effect.Time.Posix
    }


type alias LocalUser =
    { session : Evergreen.V426.UserSession.UserSession
    , currentlyViewing : Evergreen.V426.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V426.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , slackUsers : SeqDict.SeqDict (Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId) Evergreen.V426.UserSession.SlackFrontendUser
    , linkedSlackUsers : SeqDict.SeqDict (Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId) (Evergreen.V426.Slack.Id Evergreen.V426.Slack.TeamId)
    , slackUsersNeedingAuth : SeqSet.SeqSet (Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId)
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V426.UserAgent.UserAgent
    , devicePixelRatio : Float
    , safeAreaInsetTop : Int
    , safeAreaInsetBottom : Int
    , stickers : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.StickerId) Evergreen.V426.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.CustomEmojiId) Evergreen.V426.CustomEmoji.CustomEmojiData
    , emojiData : Maybe Evergreen.V426.Emoji.CachedEmojiData
    , decryptedMessages : SeqDict.SeqDict Evergreen.V426.Encryption.BytesHash (Result () (Evergreen.V426.Message.MessageContent (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelId)))
    , peerToPeer : Evergreen.V426.PeerToPeer.Model
    }
