module Evergreen.V405.User exposing (..)

import Effect.Time
import Evergreen.V405.CustomEmoji
import Evergreen.V405.Discord
import Evergreen.V405.EmailAddress
import Evergreen.V405.Emoji
import Evergreen.V405.Encryption
import Evergreen.V405.FileStatus
import Evergreen.V405.Id
import Evergreen.V405.LinkedAndOtherDiscordUsers
import Evergreen.V405.Message
import Evergreen.V405.MuteSettings
import Evergreen.V405.NonemptyDict
import Evergreen.V405.OneOrGreater
import Evergreen.V405.Pagination
import Evergreen.V405.PersonName
import Evergreen.V405.RichText
import Evergreen.V405.Slack
import Evergreen.V405.Sticker
import Evergreen.V405.UserAgent
import Evergreen.V405.UserColor
import Evergreen.V405.UserSession
import Evergreen.V405.X25519
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
    = DmChannelLastViewed (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) Evergreen.V405.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V405.Discord.Id Evergreen.V405.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias FrontendCurrentUser =
    { name : Evergreen.V405.PersonName.PersonName
    , color : Evergreen.V405.UserColor.UserColor
    , isAdmin : Bool
    , email : Evergreen.V405.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V405.Id.Id Evergreen.V405.Pagination.PageId
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , embedVisibility : EmbedVisibility
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V405.Id.AnyGuildOrDmId (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V405.Id.AnyGuildOrDmId, Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId ) (Evergreen.V405.Id.Id Evergreen.V405.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId) ( Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelId, Evergreen.V405.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId) ( Evergreen.V405.Discord.Id Evergreen.V405.Discord.ChannelId, Evergreen.V405.Id.ThreadRoute )
    , icon : Maybe Evergreen.V405.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId) (Evergreen.V405.NonemptyDict.NonemptyDict ( Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelId, Evergreen.V405.Id.ThreadRoute ) Evergreen.V405.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId) (Evergreen.V405.NonemptyDict.NonemptyDict ( Evergreen.V405.Discord.Id Evergreen.V405.Discord.ChannelId, Evergreen.V405.Id.ThreadRoute ) Evergreen.V405.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V405.RichText.Domain
    , emojiConfig : Evergreen.V405.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V405.Id.Id Evergreen.V405.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V405.Id.Id Evergreen.V405.Id.CustomEmojiId)
    , muteSettings : Evergreen.V405.MuteSettings.Model
    , publicKey : Maybe Evergreen.V405.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    , deleteAccountAt : Maybe Effect.Time.Posix
    }


type alias FrontendUser =
    { name : Evergreen.V405.PersonName.PersonName
    , color : Evergreen.V405.UserColor.UserColor
    , icon : Maybe Evergreen.V405.FileStatus.FileHash
    , publicKey : Maybe Evergreen.V405.X25519.PublicKey
    }


type BackendUserStatus
    = DeletedUser
    | UserHasEmail Evergreen.V405.EmailAddress.EmailAddress


type alias BackendUser =
    { name : Evergreen.V405.PersonName.PersonName
    , color : Evergreen.V405.UserColor.UserColor
    , isAdmin : Bool
    , email : BackendUserStatus
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V405.Id.Id Evergreen.V405.Pagination.PageId
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , embedVisibility : EmbedVisibility
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V405.Id.AnyGuildOrDmId (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V405.Id.AnyGuildOrDmId, Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId ) (Evergreen.V405.Id.Id Evergreen.V405.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId) ( Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelId, Evergreen.V405.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId) ( Evergreen.V405.Discord.Id Evergreen.V405.Discord.ChannelId, Evergreen.V405.Id.ThreadRoute )
    , icon : Maybe Evergreen.V405.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId) (Evergreen.V405.NonemptyDict.NonemptyDict ( Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelId, Evergreen.V405.Id.ThreadRoute ) Evergreen.V405.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId) (Evergreen.V405.NonemptyDict.NonemptyDict ( Evergreen.V405.Discord.Id Evergreen.V405.Discord.ChannelId, Evergreen.V405.Id.ThreadRoute ) Evergreen.V405.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V405.RichText.Domain
    , emojiConfig : Evergreen.V405.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V405.Id.Id Evergreen.V405.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V405.Id.Id Evergreen.V405.Id.CustomEmojiId)
    , muteSettings : Evergreen.V405.MuteSettings.Model
    , publicKey : Maybe Evergreen.V405.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    , deleteAccountAt : Maybe Effect.Time.Posix
    }


type alias LocalUser =
    { session : Evergreen.V405.UserSession.UserSession
    , currentlyViewing : Evergreen.V405.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V405.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , slackUsers : SeqDict.SeqDict (Evergreen.V405.Slack.Id Evergreen.V405.Slack.UserId) Evergreen.V405.UserSession.SlackFrontendUser
    , linkedSlackUsers : SeqDict.SeqDict (Evergreen.V405.Slack.Id Evergreen.V405.Slack.UserId) (Evergreen.V405.Slack.Id Evergreen.V405.Slack.TeamId)
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V405.UserAgent.UserAgent
    , devicePixelRatio : Float
    , safeAreaInsetTop : Int
    , safeAreaInsetBottom : Int
    , stickers : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.StickerId) Evergreen.V405.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.CustomEmojiId) Evergreen.V405.CustomEmoji.CustomEmojiData
    , emojiData : Maybe Evergreen.V405.Emoji.CachedEmojiData
    , decryptedMessages : SeqDict.SeqDict Evergreen.V405.Encryption.BytesHash (Result () (Evergreen.V405.Message.MessageContent (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelId)))
    }
