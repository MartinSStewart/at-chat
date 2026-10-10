module Evergreen.V402.User exposing (..)

import Effect.Time
import Evergreen.V402.CustomEmoji
import Evergreen.V402.Discord
import Evergreen.V402.EmailAddress
import Evergreen.V402.Emoji
import Evergreen.V402.Encryption
import Evergreen.V402.FileStatus
import Evergreen.V402.Id
import Evergreen.V402.LinkedAndOtherDiscordUsers
import Evergreen.V402.Message
import Evergreen.V402.MuteSettings
import Evergreen.V402.NonemptyDict
import Evergreen.V402.OneOrGreater
import Evergreen.V402.Pagination
import Evergreen.V402.PersonName
import Evergreen.V402.RichText
import Evergreen.V402.Sticker
import Evergreen.V402.UserAgent
import Evergreen.V402.UserColor
import Evergreen.V402.UserSession
import Evergreen.V402.X25519
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
    = DmChannelLastViewed (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) Evergreen.V402.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V402.Discord.Id Evergreen.V402.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias FrontendCurrentUser =
    { name : Evergreen.V402.PersonName.PersonName
    , color : Evergreen.V402.UserColor.UserColor
    , isAdmin : Bool
    , email : Evergreen.V402.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V402.Id.Id Evergreen.V402.Pagination.PageId
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , embedVisibility : EmbedVisibility
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V402.Id.AnyGuildOrDmId (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V402.Id.AnyGuildOrDmId, Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId ) (Evergreen.V402.Id.Id Evergreen.V402.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId) ( Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelId, Evergreen.V402.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId) ( Evergreen.V402.Discord.Id Evergreen.V402.Discord.ChannelId, Evergreen.V402.Id.ThreadRoute )
    , icon : Maybe Evergreen.V402.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId) (Evergreen.V402.NonemptyDict.NonemptyDict ( Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelId, Evergreen.V402.Id.ThreadRoute ) Evergreen.V402.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId) (Evergreen.V402.NonemptyDict.NonemptyDict ( Evergreen.V402.Discord.Id Evergreen.V402.Discord.ChannelId, Evergreen.V402.Id.ThreadRoute ) Evergreen.V402.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V402.RichText.Domain
    , emojiConfig : Evergreen.V402.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V402.Id.Id Evergreen.V402.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V402.Id.Id Evergreen.V402.Id.CustomEmojiId)
    , muteSettings : Evergreen.V402.MuteSettings.Model
    , publicKey : Maybe Evergreen.V402.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    , deleteAccountAt : Maybe Effect.Time.Posix
    }


type alias FrontendUser =
    { name : Evergreen.V402.PersonName.PersonName
    , color : Evergreen.V402.UserColor.UserColor
    , icon : Maybe Evergreen.V402.FileStatus.FileHash
    , publicKey : Maybe Evergreen.V402.X25519.PublicKey
    }


type BackendUserStatus
    = DeletedUser
    | UserHasEmail Evergreen.V402.EmailAddress.EmailAddress


type alias BackendUser =
    { name : Evergreen.V402.PersonName.PersonName
    , color : Evergreen.V402.UserColor.UserColor
    , isAdmin : Bool
    , email : BackendUserStatus
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V402.Id.Id Evergreen.V402.Pagination.PageId
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , embedVisibility : EmbedVisibility
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V402.Id.AnyGuildOrDmId (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V402.Id.AnyGuildOrDmId, Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId ) (Evergreen.V402.Id.Id Evergreen.V402.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId) ( Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelId, Evergreen.V402.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId) ( Evergreen.V402.Discord.Id Evergreen.V402.Discord.ChannelId, Evergreen.V402.Id.ThreadRoute )
    , icon : Maybe Evergreen.V402.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId) (Evergreen.V402.NonemptyDict.NonemptyDict ( Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelId, Evergreen.V402.Id.ThreadRoute ) Evergreen.V402.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId) (Evergreen.V402.NonemptyDict.NonemptyDict ( Evergreen.V402.Discord.Id Evergreen.V402.Discord.ChannelId, Evergreen.V402.Id.ThreadRoute ) Evergreen.V402.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V402.RichText.Domain
    , emojiConfig : Evergreen.V402.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V402.Id.Id Evergreen.V402.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V402.Id.Id Evergreen.V402.Id.CustomEmojiId)
    , muteSettings : Evergreen.V402.MuteSettings.Model
    , publicKey : Maybe Evergreen.V402.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    , deleteAccountAt : Maybe Effect.Time.Posix
    }


type alias LocalUser =
    { session : Evergreen.V402.UserSession.UserSession
    , currentlyViewing : Evergreen.V402.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V402.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V402.UserAgent.UserAgent
    , devicePixelRatio : Float
    , safeAreaInsetTop : Int
    , safeAreaInsetBottom : Int
    , stickers : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.StickerId) Evergreen.V402.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.CustomEmojiId) Evergreen.V402.CustomEmoji.CustomEmojiData
    , emojiData : Maybe Evergreen.V402.Emoji.CachedEmojiData
    , decryptedMessages : SeqDict.SeqDict Evergreen.V402.Encryption.BytesHash (Result () (Evergreen.V402.Message.MessageContent (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelId)))
    }
