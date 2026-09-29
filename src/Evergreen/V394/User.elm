module Evergreen.V394.User exposing (..)

import Effect.Time
import Evergreen.V394.CustomEmoji
import Evergreen.V394.Discord
import Evergreen.V394.EmailAddress
import Evergreen.V394.Emoji
import Evergreen.V394.Encryption
import Evergreen.V394.FileStatus
import Evergreen.V394.Id
import Evergreen.V394.LinkedAndOtherDiscordUsers
import Evergreen.V394.Message
import Evergreen.V394.MuteSettings
import Evergreen.V394.NonemptyDict
import Evergreen.V394.OneOrGreater
import Evergreen.V394.Pagination
import Evergreen.V394.PersonName
import Evergreen.V394.RichText
import Evergreen.V394.Sticker
import Evergreen.V394.UserAgent
import Evergreen.V394.UserColor
import Evergreen.V394.UserSession
import Evergreen.V394.X25519
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
    = DmChannelLastViewed (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) Evergreen.V394.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V394.Discord.Id Evergreen.V394.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias FrontendCurrentUser =
    { name : Evergreen.V394.PersonName.PersonName
    , color : Evergreen.V394.UserColor.UserColor
    , isAdmin : Bool
    , email : Evergreen.V394.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V394.Id.Id Evergreen.V394.Pagination.PageId
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , embedVisibility : EmbedVisibility
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V394.Id.AnyGuildOrDmId (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V394.Id.AnyGuildOrDmId, Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId ) (Evergreen.V394.Id.Id Evergreen.V394.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId) ( Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelId, Evergreen.V394.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId) ( Evergreen.V394.Discord.Id Evergreen.V394.Discord.ChannelId, Evergreen.V394.Id.ThreadRoute )
    , icon : Maybe Evergreen.V394.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId) (Evergreen.V394.NonemptyDict.NonemptyDict ( Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelId, Evergreen.V394.Id.ThreadRoute ) Evergreen.V394.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId) (Evergreen.V394.NonemptyDict.NonemptyDict ( Evergreen.V394.Discord.Id Evergreen.V394.Discord.ChannelId, Evergreen.V394.Id.ThreadRoute ) Evergreen.V394.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V394.RichText.Domain
    , emojiConfig : Evergreen.V394.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V394.Id.Id Evergreen.V394.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V394.Id.Id Evergreen.V394.Id.CustomEmojiId)
    , muteSettings : Evergreen.V394.MuteSettings.Model
    , publicKey : Maybe Evergreen.V394.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    , deleteAccountAt : Maybe Effect.Time.Posix
    }


type alias FrontendUser =
    { name : Evergreen.V394.PersonName.PersonName
    , color : Evergreen.V394.UserColor.UserColor
    , icon : Maybe Evergreen.V394.FileStatus.FileHash
    , publicKey : Maybe Evergreen.V394.X25519.PublicKey
    }


type BackendUserStatus
    = DeletedUser
    | UserHasEmail Evergreen.V394.EmailAddress.EmailAddress


type alias BackendUser =
    { name : Evergreen.V394.PersonName.PersonName
    , color : Evergreen.V394.UserColor.UserColor
    , isAdmin : Bool
    , email : BackendUserStatus
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V394.Id.Id Evergreen.V394.Pagination.PageId
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , embedVisibility : EmbedVisibility
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V394.Id.AnyGuildOrDmId (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V394.Id.AnyGuildOrDmId, Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId ) (Evergreen.V394.Id.Id Evergreen.V394.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId) ( Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelId, Evergreen.V394.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId) ( Evergreen.V394.Discord.Id Evergreen.V394.Discord.ChannelId, Evergreen.V394.Id.ThreadRoute )
    , icon : Maybe Evergreen.V394.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId) (Evergreen.V394.NonemptyDict.NonemptyDict ( Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelId, Evergreen.V394.Id.ThreadRoute ) Evergreen.V394.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId) (Evergreen.V394.NonemptyDict.NonemptyDict ( Evergreen.V394.Discord.Id Evergreen.V394.Discord.ChannelId, Evergreen.V394.Id.ThreadRoute ) Evergreen.V394.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V394.RichText.Domain
    , emojiConfig : Evergreen.V394.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V394.Id.Id Evergreen.V394.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V394.Id.Id Evergreen.V394.Id.CustomEmojiId)
    , muteSettings : Evergreen.V394.MuteSettings.Model
    , publicKey : Maybe Evergreen.V394.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    , deleteAccountAt : Maybe Effect.Time.Posix
    }


type alias LocalUser =
    { session : Evergreen.V394.UserSession.UserSession
    , currentlyViewing : Evergreen.V394.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V394.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V394.UserAgent.UserAgent
    , devicePixelRatio : Float
    , safeAreaInsetTop : Int
    , safeAreaInsetBottom : Int
    , stickers : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.StickerId) Evergreen.V394.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.CustomEmojiId) Evergreen.V394.CustomEmoji.CustomEmojiData
    , emojiData : Maybe Evergreen.V394.Emoji.CachedEmojiData
    , decryptedMessages : SeqDict.SeqDict Evergreen.V394.Encryption.BytesHash (Result () (Evergreen.V394.Message.MessageContent (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelId)))
    }
