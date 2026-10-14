module Evergreen.V407.User exposing (..)

import Effect.Time
import Evergreen.V407.CustomEmoji
import Evergreen.V407.Discord
import Evergreen.V407.EmailAddress
import Evergreen.V407.Emoji
import Evergreen.V407.Encryption
import Evergreen.V407.FileStatus
import Evergreen.V407.Id
import Evergreen.V407.LinkedAndOtherDiscordUsers
import Evergreen.V407.Message
import Evergreen.V407.MuteSettings
import Evergreen.V407.NonemptyDict
import Evergreen.V407.OneOrGreater
import Evergreen.V407.Pagination
import Evergreen.V407.PersonName
import Evergreen.V407.RichText
import Evergreen.V407.Slack
import Evergreen.V407.Sticker
import Evergreen.V407.UserAgent
import Evergreen.V407.UserColor
import Evergreen.V407.UserSession
import Evergreen.V407.X25519
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
    = DmChannelLastViewed (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) Evergreen.V407.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V407.Discord.Id Evergreen.V407.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias FrontendCurrentUser =
    { name : Evergreen.V407.PersonName.PersonName
    , color : Evergreen.V407.UserColor.UserColor
    , isAdmin : Bool
    , email : Evergreen.V407.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V407.Id.Id Evergreen.V407.Pagination.PageId
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , embedVisibility : EmbedVisibility
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V407.Id.AnyGuildOrDmId (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V407.Id.AnyGuildOrDmId, Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId ) (Evergreen.V407.Id.Id Evergreen.V407.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId) ( Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelId, Evergreen.V407.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId) ( Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId, Evergreen.V407.Id.ThreadRoute )
    , icon : Maybe Evergreen.V407.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId) (Evergreen.V407.NonemptyDict.NonemptyDict ( Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelId, Evergreen.V407.Id.ThreadRoute ) Evergreen.V407.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId) (Evergreen.V407.NonemptyDict.NonemptyDict ( Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId, Evergreen.V407.Id.ThreadRoute ) Evergreen.V407.OneOrGreater.OneOrGreater)
    , slackDirectMentions : SeqDict.SeqDict (Evergreen.V407.Slack.Id Evergreen.V407.Slack.TeamId) (Evergreen.V407.NonemptyDict.NonemptyDict ( Evergreen.V407.Slack.Id Evergreen.V407.Slack.ChannelId, Evergreen.V407.Id.ThreadRoute ) Evergreen.V407.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V407.RichText.Domain
    , emojiConfig : Evergreen.V407.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V407.Id.Id Evergreen.V407.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V407.Id.Id Evergreen.V407.Id.CustomEmojiId)
    , muteSettings : Evergreen.V407.MuteSettings.Model
    , publicKey : Maybe Evergreen.V407.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    , deleteAccountAt : Maybe Effect.Time.Posix
    }


type alias FrontendUser =
    { name : Evergreen.V407.PersonName.PersonName
    , color : Evergreen.V407.UserColor.UserColor
    , icon : Maybe Evergreen.V407.FileStatus.FileHash
    , publicKey : Maybe Evergreen.V407.X25519.PublicKey
    }


type BackendUserStatus
    = DeletedUser
    | UserHasEmail Evergreen.V407.EmailAddress.EmailAddress


type alias BackendUser =
    { name : Evergreen.V407.PersonName.PersonName
    , color : Evergreen.V407.UserColor.UserColor
    , isAdmin : Bool
    , email : BackendUserStatus
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V407.Id.Id Evergreen.V407.Pagination.PageId
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , embedVisibility : EmbedVisibility
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V407.Id.AnyGuildOrDmId (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V407.Id.AnyGuildOrDmId, Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId ) (Evergreen.V407.Id.Id Evergreen.V407.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId) ( Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelId, Evergreen.V407.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId) ( Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId, Evergreen.V407.Id.ThreadRoute )
    , icon : Maybe Evergreen.V407.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId) (Evergreen.V407.NonemptyDict.NonemptyDict ( Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelId, Evergreen.V407.Id.ThreadRoute ) Evergreen.V407.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId) (Evergreen.V407.NonemptyDict.NonemptyDict ( Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId, Evergreen.V407.Id.ThreadRoute ) Evergreen.V407.OneOrGreater.OneOrGreater)
    , slackDirectMentions : SeqDict.SeqDict (Evergreen.V407.Slack.Id Evergreen.V407.Slack.TeamId) (Evergreen.V407.NonemptyDict.NonemptyDict ( Evergreen.V407.Slack.Id Evergreen.V407.Slack.ChannelId, Evergreen.V407.Id.ThreadRoute ) Evergreen.V407.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V407.RichText.Domain
    , emojiConfig : Evergreen.V407.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V407.Id.Id Evergreen.V407.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V407.Id.Id Evergreen.V407.Id.CustomEmojiId)
    , muteSettings : Evergreen.V407.MuteSettings.Model
    , publicKey : Maybe Evergreen.V407.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    , deleteAccountAt : Maybe Effect.Time.Posix
    }


type alias LocalUser =
    { session : Evergreen.V407.UserSession.UserSession
    , currentlyViewing : Evergreen.V407.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V407.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , slackUsers : SeqDict.SeqDict (Evergreen.V407.Slack.Id Evergreen.V407.Slack.UserId) Evergreen.V407.UserSession.SlackFrontendUser
    , linkedSlackUsers : SeqDict.SeqDict (Evergreen.V407.Slack.Id Evergreen.V407.Slack.UserId) (Evergreen.V407.Slack.Id Evergreen.V407.Slack.TeamId)
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V407.UserAgent.UserAgent
    , devicePixelRatio : Float
    , safeAreaInsetTop : Int
    , safeAreaInsetBottom : Int
    , stickers : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.StickerId) Evergreen.V407.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.CustomEmojiId) Evergreen.V407.CustomEmoji.CustomEmojiData
    , emojiData : Maybe Evergreen.V407.Emoji.CachedEmojiData
    , decryptedMessages : SeqDict.SeqDict Evergreen.V407.Encryption.BytesHash (Result () (Evergreen.V407.Message.MessageContent (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelId)))
    }
