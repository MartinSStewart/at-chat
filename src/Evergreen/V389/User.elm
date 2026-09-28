module Evergreen.V389.User exposing (..)

import Effect.Time
import Evergreen.V389.CustomEmoji
import Evergreen.V389.Discord
import Evergreen.V389.EmailAddress
import Evergreen.V389.Emoji
import Evergreen.V389.Encryption
import Evergreen.V389.FileStatus
import Evergreen.V389.Id
import Evergreen.V389.LinkedAndOtherDiscordUsers
import Evergreen.V389.Message
import Evergreen.V389.MuteSettings
import Evergreen.V389.NonemptyDict
import Evergreen.V389.OneOrGreater
import Evergreen.V389.Pagination
import Evergreen.V389.PersonName
import Evergreen.V389.RichText
import Evergreen.V389.Sticker
import Evergreen.V389.UserAgent
import Evergreen.V389.UserColor
import Evergreen.V389.UserSession
import Evergreen.V389.X25519
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
    = DmChannelLastViewed (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) Evergreen.V389.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V389.Discord.Id Evergreen.V389.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias FrontendCurrentUser =
    { name : Evergreen.V389.PersonName.PersonName
    , color : Evergreen.V389.UserColor.UserColor
    , isAdmin : Bool
    , email : Evergreen.V389.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V389.Id.Id Evergreen.V389.Pagination.PageId
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , embedVisibility : EmbedVisibility
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V389.Id.AnyGuildOrDmId (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V389.Id.AnyGuildOrDmId, Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId ) (Evergreen.V389.Id.Id Evergreen.V389.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId) ( Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelId, Evergreen.V389.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId) ( Evergreen.V389.Discord.Id Evergreen.V389.Discord.ChannelId, Evergreen.V389.Id.ThreadRoute )
    , icon : Maybe Evergreen.V389.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId) (Evergreen.V389.NonemptyDict.NonemptyDict ( Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelId, Evergreen.V389.Id.ThreadRoute ) Evergreen.V389.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId) (Evergreen.V389.NonemptyDict.NonemptyDict ( Evergreen.V389.Discord.Id Evergreen.V389.Discord.ChannelId, Evergreen.V389.Id.ThreadRoute ) Evergreen.V389.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V389.RichText.Domain
    , emojiConfig : Evergreen.V389.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V389.Id.Id Evergreen.V389.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V389.Id.Id Evergreen.V389.Id.CustomEmojiId)
    , muteSettings : Evergreen.V389.MuteSettings.Model
    , publicKey : Maybe Evergreen.V389.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    , deleteAccountAt : Maybe Effect.Time.Posix
    }


type alias FrontendUser =
    { name : Evergreen.V389.PersonName.PersonName
    , color : Evergreen.V389.UserColor.UserColor
    , icon : Maybe Evergreen.V389.FileStatus.FileHash
    , publicKey : Maybe Evergreen.V389.X25519.PublicKey
    }


type BackendUserStatus
    = DeletedUser
    | UserHasEmail Evergreen.V389.EmailAddress.EmailAddress


type alias BackendUser =
    { name : Evergreen.V389.PersonName.PersonName
    , color : Evergreen.V389.UserColor.UserColor
    , isAdmin : Bool
    , email : BackendUserStatus
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V389.Id.Id Evergreen.V389.Pagination.PageId
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , embedVisibility : EmbedVisibility
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V389.Id.AnyGuildOrDmId (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V389.Id.AnyGuildOrDmId, Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId ) (Evergreen.V389.Id.Id Evergreen.V389.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId) ( Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelId, Evergreen.V389.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId) ( Evergreen.V389.Discord.Id Evergreen.V389.Discord.ChannelId, Evergreen.V389.Id.ThreadRoute )
    , icon : Maybe Evergreen.V389.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId) (Evergreen.V389.NonemptyDict.NonemptyDict ( Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelId, Evergreen.V389.Id.ThreadRoute ) Evergreen.V389.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId) (Evergreen.V389.NonemptyDict.NonemptyDict ( Evergreen.V389.Discord.Id Evergreen.V389.Discord.ChannelId, Evergreen.V389.Id.ThreadRoute ) Evergreen.V389.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V389.RichText.Domain
    , emojiConfig : Evergreen.V389.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V389.Id.Id Evergreen.V389.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V389.Id.Id Evergreen.V389.Id.CustomEmojiId)
    , muteSettings : Evergreen.V389.MuteSettings.Model
    , publicKey : Maybe Evergreen.V389.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    , deleteAccountAt : Maybe Effect.Time.Posix
    }


type alias LocalUser =
    { session : Evergreen.V389.UserSession.UserSession
    , currentlyViewing : Evergreen.V389.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V389.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V389.UserAgent.UserAgent
    , devicePixelRatio : Float
    , safeAreaInsetTop : Int
    , safeAreaInsetBottom : Int
    , stickers : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.StickerId) Evergreen.V389.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.CustomEmojiId) Evergreen.V389.CustomEmoji.CustomEmojiData
    , emojiData : Maybe Evergreen.V389.Emoji.CachedEmojiData
    , decryptedMessages : SeqDict.SeqDict Evergreen.V389.Encryption.BytesHash (Result () (Evergreen.V389.Message.MessageContent (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelId)))
    }
