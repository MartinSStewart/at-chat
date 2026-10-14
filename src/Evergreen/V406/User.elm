module Evergreen.V406.User exposing (..)

import Effect.Time
import Evergreen.V406.CustomEmoji
import Evergreen.V406.Discord
import Evergreen.V406.EmailAddress
import Evergreen.V406.Emoji
import Evergreen.V406.Encryption
import Evergreen.V406.FileStatus
import Evergreen.V406.Id
import Evergreen.V406.LinkedAndOtherDiscordUsers
import Evergreen.V406.Message
import Evergreen.V406.MuteSettings
import Evergreen.V406.NonemptyDict
import Evergreen.V406.OneOrGreater
import Evergreen.V406.Pagination
import Evergreen.V406.PersonName
import Evergreen.V406.RichText
import Evergreen.V406.Slack
import Evergreen.V406.Sticker
import Evergreen.V406.UserAgent
import Evergreen.V406.UserColor
import Evergreen.V406.UserSession
import Evergreen.V406.X25519
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
    = DmChannelLastViewed (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) Evergreen.V406.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V406.Discord.Id Evergreen.V406.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias FrontendCurrentUser =
    { name : Evergreen.V406.PersonName.PersonName
    , color : Evergreen.V406.UserColor.UserColor
    , isAdmin : Bool
    , email : Evergreen.V406.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V406.Id.Id Evergreen.V406.Pagination.PageId
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , embedVisibility : EmbedVisibility
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V406.Id.AnyGuildOrDmId (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V406.Id.AnyGuildOrDmId, Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId ) (Evergreen.V406.Id.Id Evergreen.V406.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId) ( Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelId, Evergreen.V406.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId) ( Evergreen.V406.Discord.Id Evergreen.V406.Discord.ChannelId, Evergreen.V406.Id.ThreadRoute )
    , icon : Maybe Evergreen.V406.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId) (Evergreen.V406.NonemptyDict.NonemptyDict ( Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelId, Evergreen.V406.Id.ThreadRoute ) Evergreen.V406.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId) (Evergreen.V406.NonemptyDict.NonemptyDict ( Evergreen.V406.Discord.Id Evergreen.V406.Discord.ChannelId, Evergreen.V406.Id.ThreadRoute ) Evergreen.V406.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V406.RichText.Domain
    , emojiConfig : Evergreen.V406.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V406.Id.Id Evergreen.V406.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V406.Id.Id Evergreen.V406.Id.CustomEmojiId)
    , muteSettings : Evergreen.V406.MuteSettings.Model
    , publicKey : Maybe Evergreen.V406.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    , deleteAccountAt : Maybe Effect.Time.Posix
    }


type alias FrontendUser =
    { name : Evergreen.V406.PersonName.PersonName
    , color : Evergreen.V406.UserColor.UserColor
    , icon : Maybe Evergreen.V406.FileStatus.FileHash
    , publicKey : Maybe Evergreen.V406.X25519.PublicKey
    }


type BackendUserStatus
    = DeletedUser
    | UserHasEmail Evergreen.V406.EmailAddress.EmailAddress


type alias BackendUser =
    { name : Evergreen.V406.PersonName.PersonName
    , color : Evergreen.V406.UserColor.UserColor
    , isAdmin : Bool
    , email : BackendUserStatus
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V406.Id.Id Evergreen.V406.Pagination.PageId
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , embedVisibility : EmbedVisibility
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V406.Id.AnyGuildOrDmId (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V406.Id.AnyGuildOrDmId, Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId ) (Evergreen.V406.Id.Id Evergreen.V406.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId) ( Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelId, Evergreen.V406.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId) ( Evergreen.V406.Discord.Id Evergreen.V406.Discord.ChannelId, Evergreen.V406.Id.ThreadRoute )
    , icon : Maybe Evergreen.V406.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId) (Evergreen.V406.NonemptyDict.NonemptyDict ( Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelId, Evergreen.V406.Id.ThreadRoute ) Evergreen.V406.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId) (Evergreen.V406.NonemptyDict.NonemptyDict ( Evergreen.V406.Discord.Id Evergreen.V406.Discord.ChannelId, Evergreen.V406.Id.ThreadRoute ) Evergreen.V406.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V406.RichText.Domain
    , emojiConfig : Evergreen.V406.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V406.Id.Id Evergreen.V406.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V406.Id.Id Evergreen.V406.Id.CustomEmojiId)
    , muteSettings : Evergreen.V406.MuteSettings.Model
    , publicKey : Maybe Evergreen.V406.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    , deleteAccountAt : Maybe Effect.Time.Posix
    }


type alias LocalUser =
    { session : Evergreen.V406.UserSession.UserSession
    , currentlyViewing : Evergreen.V406.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V406.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , slackUsers : SeqDict.SeqDict (Evergreen.V406.Slack.Id Evergreen.V406.Slack.UserId) Evergreen.V406.UserSession.SlackFrontendUser
    , linkedSlackUsers : SeqDict.SeqDict (Evergreen.V406.Slack.Id Evergreen.V406.Slack.UserId) (Evergreen.V406.Slack.Id Evergreen.V406.Slack.TeamId)
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V406.UserAgent.UserAgent
    , devicePixelRatio : Float
    , safeAreaInsetTop : Int
    , safeAreaInsetBottom : Int
    , stickers : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.StickerId) Evergreen.V406.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.CustomEmojiId) Evergreen.V406.CustomEmoji.CustomEmojiData
    , emojiData : Maybe Evergreen.V406.Emoji.CachedEmojiData
    , decryptedMessages : SeqDict.SeqDict Evergreen.V406.Encryption.BytesHash (Result () (Evergreen.V406.Message.MessageContent (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelId)))
    }
