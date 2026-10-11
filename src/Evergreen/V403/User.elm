module Evergreen.V403.User exposing (..)

import Effect.Time
import Evergreen.V403.CustomEmoji
import Evergreen.V403.Discord
import Evergreen.V403.EmailAddress
import Evergreen.V403.Emoji
import Evergreen.V403.Encryption
import Evergreen.V403.FileStatus
import Evergreen.V403.Id
import Evergreen.V403.LinkedAndOtherDiscordUsers
import Evergreen.V403.Message
import Evergreen.V403.MuteSettings
import Evergreen.V403.NonemptyDict
import Evergreen.V403.OneOrGreater
import Evergreen.V403.Pagination
import Evergreen.V403.PersonName
import Evergreen.V403.RichText
import Evergreen.V403.Sticker
import Evergreen.V403.UserAgent
import Evergreen.V403.UserColor
import Evergreen.V403.UserSession
import Evergreen.V403.X25519
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
    = DmChannelLastViewed (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) Evergreen.V403.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V403.Discord.Id Evergreen.V403.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias FrontendCurrentUser =
    { name : Evergreen.V403.PersonName.PersonName
    , color : Evergreen.V403.UserColor.UserColor
    , isAdmin : Bool
    , email : Evergreen.V403.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V403.Id.Id Evergreen.V403.Pagination.PageId
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , embedVisibility : EmbedVisibility
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V403.Id.AnyGuildOrDmId (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V403.Id.AnyGuildOrDmId, Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId ) (Evergreen.V403.Id.Id Evergreen.V403.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId) ( Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelId, Evergreen.V403.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId) ( Evergreen.V403.Discord.Id Evergreen.V403.Discord.ChannelId, Evergreen.V403.Id.ThreadRoute )
    , icon : Maybe Evergreen.V403.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId) (Evergreen.V403.NonemptyDict.NonemptyDict ( Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelId, Evergreen.V403.Id.ThreadRoute ) Evergreen.V403.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId) (Evergreen.V403.NonemptyDict.NonemptyDict ( Evergreen.V403.Discord.Id Evergreen.V403.Discord.ChannelId, Evergreen.V403.Id.ThreadRoute ) Evergreen.V403.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V403.RichText.Domain
    , emojiConfig : Evergreen.V403.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V403.Id.Id Evergreen.V403.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V403.Id.Id Evergreen.V403.Id.CustomEmojiId)
    , muteSettings : Evergreen.V403.MuteSettings.Model
    , publicKey : Maybe Evergreen.V403.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    , deleteAccountAt : Maybe Effect.Time.Posix
    }


type alias FrontendUser =
    { name : Evergreen.V403.PersonName.PersonName
    , color : Evergreen.V403.UserColor.UserColor
    , icon : Maybe Evergreen.V403.FileStatus.FileHash
    , publicKey : Maybe Evergreen.V403.X25519.PublicKey
    }


type BackendUserStatus
    = DeletedUser
    | UserHasEmail Evergreen.V403.EmailAddress.EmailAddress


type alias BackendUser =
    { name : Evergreen.V403.PersonName.PersonName
    , color : Evergreen.V403.UserColor.UserColor
    , isAdmin : Bool
    , email : BackendUserStatus
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V403.Id.Id Evergreen.V403.Pagination.PageId
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , embedVisibility : EmbedVisibility
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V403.Id.AnyGuildOrDmId (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V403.Id.AnyGuildOrDmId, Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId ) (Evergreen.V403.Id.Id Evergreen.V403.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId) ( Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelId, Evergreen.V403.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId) ( Evergreen.V403.Discord.Id Evergreen.V403.Discord.ChannelId, Evergreen.V403.Id.ThreadRoute )
    , icon : Maybe Evergreen.V403.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId) (Evergreen.V403.NonemptyDict.NonemptyDict ( Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelId, Evergreen.V403.Id.ThreadRoute ) Evergreen.V403.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId) (Evergreen.V403.NonemptyDict.NonemptyDict ( Evergreen.V403.Discord.Id Evergreen.V403.Discord.ChannelId, Evergreen.V403.Id.ThreadRoute ) Evergreen.V403.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V403.RichText.Domain
    , emojiConfig : Evergreen.V403.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V403.Id.Id Evergreen.V403.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V403.Id.Id Evergreen.V403.Id.CustomEmojiId)
    , muteSettings : Evergreen.V403.MuteSettings.Model
    , publicKey : Maybe Evergreen.V403.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    , deleteAccountAt : Maybe Effect.Time.Posix
    }


type alias LocalUser =
    { session : Evergreen.V403.UserSession.UserSession
    , currentlyViewing : Evergreen.V403.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V403.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V403.UserAgent.UserAgent
    , devicePixelRatio : Float
    , safeAreaInsetTop : Int
    , safeAreaInsetBottom : Int
    , stickers : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.StickerId) Evergreen.V403.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.CustomEmojiId) Evergreen.V403.CustomEmoji.CustomEmojiData
    , emojiData : Maybe Evergreen.V403.Emoji.CachedEmojiData
    , decryptedMessages : SeqDict.SeqDict Evergreen.V403.Encryption.BytesHash (Result () (Evergreen.V403.Message.MessageContent (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelId)))
    }
