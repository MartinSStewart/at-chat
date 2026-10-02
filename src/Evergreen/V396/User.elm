module Evergreen.V396.User exposing (..)

import Effect.Time
import Evergreen.V396.CustomEmoji
import Evergreen.V396.Discord
import Evergreen.V396.EmailAddress
import Evergreen.V396.Emoji
import Evergreen.V396.Encryption
import Evergreen.V396.FileStatus
import Evergreen.V396.Id
import Evergreen.V396.LinkedAndOtherDiscordUsers
import Evergreen.V396.Message
import Evergreen.V396.MuteSettings
import Evergreen.V396.NonemptyDict
import Evergreen.V396.OneOrGreater
import Evergreen.V396.Pagination
import Evergreen.V396.PersonName
import Evergreen.V396.RichText
import Evergreen.V396.Sticker
import Evergreen.V396.UserAgent
import Evergreen.V396.UserColor
import Evergreen.V396.UserSession
import Evergreen.V396.X25519
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
    = DmChannelLastViewed (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) Evergreen.V396.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V396.Discord.Id Evergreen.V396.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias FrontendCurrentUser =
    { name : Evergreen.V396.PersonName.PersonName
    , color : Evergreen.V396.UserColor.UserColor
    , isAdmin : Bool
    , email : Evergreen.V396.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V396.Id.Id Evergreen.V396.Pagination.PageId
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , embedVisibility : EmbedVisibility
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V396.Id.AnyGuildOrDmId (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V396.Id.AnyGuildOrDmId, Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId ) (Evergreen.V396.Id.Id Evergreen.V396.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId) ( Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelId, Evergreen.V396.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId) ( Evergreen.V396.Discord.Id Evergreen.V396.Discord.ChannelId, Evergreen.V396.Id.ThreadRoute )
    , icon : Maybe Evergreen.V396.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId) (Evergreen.V396.NonemptyDict.NonemptyDict ( Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelId, Evergreen.V396.Id.ThreadRoute ) Evergreen.V396.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId) (Evergreen.V396.NonemptyDict.NonemptyDict ( Evergreen.V396.Discord.Id Evergreen.V396.Discord.ChannelId, Evergreen.V396.Id.ThreadRoute ) Evergreen.V396.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V396.RichText.Domain
    , emojiConfig : Evergreen.V396.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V396.Id.Id Evergreen.V396.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V396.Id.Id Evergreen.V396.Id.CustomEmojiId)
    , muteSettings : Evergreen.V396.MuteSettings.Model
    , publicKey : Maybe Evergreen.V396.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    , deleteAccountAt : Maybe Effect.Time.Posix
    }


type alias FrontendUser =
    { name : Evergreen.V396.PersonName.PersonName
    , color : Evergreen.V396.UserColor.UserColor
    , icon : Maybe Evergreen.V396.FileStatus.FileHash
    , publicKey : Maybe Evergreen.V396.X25519.PublicKey
    }


type BackendUserStatus
    = DeletedUser
    | UserHasEmail Evergreen.V396.EmailAddress.EmailAddress


type alias BackendUser =
    { name : Evergreen.V396.PersonName.PersonName
    , color : Evergreen.V396.UserColor.UserColor
    , isAdmin : Bool
    , email : BackendUserStatus
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V396.Id.Id Evergreen.V396.Pagination.PageId
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , embedVisibility : EmbedVisibility
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V396.Id.AnyGuildOrDmId (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V396.Id.AnyGuildOrDmId, Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId ) (Evergreen.V396.Id.Id Evergreen.V396.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId) ( Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelId, Evergreen.V396.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId) ( Evergreen.V396.Discord.Id Evergreen.V396.Discord.ChannelId, Evergreen.V396.Id.ThreadRoute )
    , icon : Maybe Evergreen.V396.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId) (Evergreen.V396.NonemptyDict.NonemptyDict ( Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelId, Evergreen.V396.Id.ThreadRoute ) Evergreen.V396.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId) (Evergreen.V396.NonemptyDict.NonemptyDict ( Evergreen.V396.Discord.Id Evergreen.V396.Discord.ChannelId, Evergreen.V396.Id.ThreadRoute ) Evergreen.V396.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V396.RichText.Domain
    , emojiConfig : Evergreen.V396.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V396.Id.Id Evergreen.V396.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V396.Id.Id Evergreen.V396.Id.CustomEmojiId)
    , muteSettings : Evergreen.V396.MuteSettings.Model
    , publicKey : Maybe Evergreen.V396.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    , deleteAccountAt : Maybe Effect.Time.Posix
    }


type alias LocalUser =
    { session : Evergreen.V396.UserSession.UserSession
    , currentlyViewing : Evergreen.V396.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V396.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V396.UserAgent.UserAgent
    , devicePixelRatio : Float
    , safeAreaInsetTop : Int
    , safeAreaInsetBottom : Int
    , stickers : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.StickerId) Evergreen.V396.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.CustomEmojiId) Evergreen.V396.CustomEmoji.CustomEmojiData
    , emojiData : Maybe Evergreen.V396.Emoji.CachedEmojiData
    , decryptedMessages : SeqDict.SeqDict Evergreen.V396.Encryption.BytesHash (Result () (Evergreen.V396.Message.MessageContent (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelId)))
    }
