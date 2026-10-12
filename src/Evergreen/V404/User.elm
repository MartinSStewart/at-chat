module Evergreen.V404.User exposing (..)

import Effect.Time
import Evergreen.V404.CustomEmoji
import Evergreen.V404.Discord
import Evergreen.V404.EmailAddress
import Evergreen.V404.Emoji
import Evergreen.V404.Encryption
import Evergreen.V404.FileStatus
import Evergreen.V404.Id
import Evergreen.V404.LinkedAndOtherDiscordUsers
import Evergreen.V404.Message
import Evergreen.V404.MuteSettings
import Evergreen.V404.NonemptyDict
import Evergreen.V404.OneOrGreater
import Evergreen.V404.Pagination
import Evergreen.V404.PersonName
import Evergreen.V404.RichText
import Evergreen.V404.Sticker
import Evergreen.V404.UserAgent
import Evergreen.V404.UserColor
import Evergreen.V404.UserSession
import Evergreen.V404.X25519
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
    = DmChannelLastViewed (Evergreen.V404.Id.Id Evergreen.V404.Id.UserId) Evergreen.V404.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V404.Discord.Id Evergreen.V404.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias FrontendCurrentUser =
    { name : Evergreen.V404.PersonName.PersonName
    , color : Evergreen.V404.UserColor.UserColor
    , isAdmin : Bool
    , email : Evergreen.V404.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V404.Id.Id Evergreen.V404.Pagination.PageId
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , embedVisibility : EmbedVisibility
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V404.Id.AnyGuildOrDmId (Evergreen.V404.Id.Id Evergreen.V404.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V404.Id.AnyGuildOrDmId, Evergreen.V404.Id.Id Evergreen.V404.Id.ChannelMessageId ) (Evergreen.V404.Id.Id Evergreen.V404.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V404.Id.Id Evergreen.V404.Id.GuildId) ( Evergreen.V404.Id.Id Evergreen.V404.Id.ChannelId, Evergreen.V404.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V404.Discord.Id Evergreen.V404.Discord.GuildId) ( Evergreen.V404.Discord.Id Evergreen.V404.Discord.ChannelId, Evergreen.V404.Id.ThreadRoute )
    , icon : Maybe Evergreen.V404.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V404.Id.Id Evergreen.V404.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V404.Discord.Id Evergreen.V404.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V404.Id.Id Evergreen.V404.Id.GuildId) (Evergreen.V404.NonemptyDict.NonemptyDict ( Evergreen.V404.Id.Id Evergreen.V404.Id.ChannelId, Evergreen.V404.Id.ThreadRoute ) Evergreen.V404.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V404.Discord.Id Evergreen.V404.Discord.GuildId) (Evergreen.V404.NonemptyDict.NonemptyDict ( Evergreen.V404.Discord.Id Evergreen.V404.Discord.ChannelId, Evergreen.V404.Id.ThreadRoute ) Evergreen.V404.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V404.RichText.Domain
    , emojiConfig : Evergreen.V404.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V404.Id.Id Evergreen.V404.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V404.Id.Id Evergreen.V404.Id.CustomEmojiId)
    , muteSettings : Evergreen.V404.MuteSettings.Model
    , publicKey : Maybe Evergreen.V404.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    , deleteAccountAt : Maybe Effect.Time.Posix
    }


type alias FrontendUser =
    { name : Evergreen.V404.PersonName.PersonName
    , color : Evergreen.V404.UserColor.UserColor
    , icon : Maybe Evergreen.V404.FileStatus.FileHash
    , publicKey : Maybe Evergreen.V404.X25519.PublicKey
    }


type BackendUserStatus
    = DeletedUser
    | UserHasEmail Evergreen.V404.EmailAddress.EmailAddress


type alias BackendUser =
    { name : Evergreen.V404.PersonName.PersonName
    , color : Evergreen.V404.UserColor.UserColor
    , isAdmin : Bool
    , email : BackendUserStatus
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V404.Id.Id Evergreen.V404.Pagination.PageId
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , embedVisibility : EmbedVisibility
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V404.Id.AnyGuildOrDmId (Evergreen.V404.Id.Id Evergreen.V404.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V404.Id.AnyGuildOrDmId, Evergreen.V404.Id.Id Evergreen.V404.Id.ChannelMessageId ) (Evergreen.V404.Id.Id Evergreen.V404.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V404.Id.Id Evergreen.V404.Id.GuildId) ( Evergreen.V404.Id.Id Evergreen.V404.Id.ChannelId, Evergreen.V404.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V404.Discord.Id Evergreen.V404.Discord.GuildId) ( Evergreen.V404.Discord.Id Evergreen.V404.Discord.ChannelId, Evergreen.V404.Id.ThreadRoute )
    , icon : Maybe Evergreen.V404.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V404.Id.Id Evergreen.V404.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V404.Discord.Id Evergreen.V404.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V404.Id.Id Evergreen.V404.Id.GuildId) (Evergreen.V404.NonemptyDict.NonemptyDict ( Evergreen.V404.Id.Id Evergreen.V404.Id.ChannelId, Evergreen.V404.Id.ThreadRoute ) Evergreen.V404.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V404.Discord.Id Evergreen.V404.Discord.GuildId) (Evergreen.V404.NonemptyDict.NonemptyDict ( Evergreen.V404.Discord.Id Evergreen.V404.Discord.ChannelId, Evergreen.V404.Id.ThreadRoute ) Evergreen.V404.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V404.RichText.Domain
    , emojiConfig : Evergreen.V404.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V404.Id.Id Evergreen.V404.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V404.Id.Id Evergreen.V404.Id.CustomEmojiId)
    , muteSettings : Evergreen.V404.MuteSettings.Model
    , publicKey : Maybe Evergreen.V404.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    , deleteAccountAt : Maybe Effect.Time.Posix
    }


type alias LocalUser =
    { session : Evergreen.V404.UserSession.UserSession
    , currentlyViewing : Evergreen.V404.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V404.Id.Id Evergreen.V404.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V404.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V404.UserAgent.UserAgent
    , devicePixelRatio : Float
    , safeAreaInsetTop : Int
    , safeAreaInsetBottom : Int
    , stickers : SeqDict.SeqDict (Evergreen.V404.Id.Id Evergreen.V404.Id.StickerId) Evergreen.V404.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V404.Id.Id Evergreen.V404.Id.CustomEmojiId) Evergreen.V404.CustomEmoji.CustomEmojiData
    , emojiData : Maybe Evergreen.V404.Emoji.CachedEmojiData
    , decryptedMessages : SeqDict.SeqDict Evergreen.V404.Encryption.BytesHash (Result () (Evergreen.V404.Message.MessageContent (Evergreen.V404.Id.Id Evergreen.V404.Id.UserId) (Evergreen.V404.Id.Id Evergreen.V404.Id.ChannelId)))
    }
