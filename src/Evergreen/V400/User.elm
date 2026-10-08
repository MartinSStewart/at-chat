module Evergreen.V400.User exposing (..)

import Effect.Time
import Evergreen.V400.CustomEmoji
import Evergreen.V400.Discord
import Evergreen.V400.EmailAddress
import Evergreen.V400.Emoji
import Evergreen.V400.Encryption
import Evergreen.V400.FileStatus
import Evergreen.V400.Id
import Evergreen.V400.LinkedAndOtherDiscordUsers
import Evergreen.V400.Message
import Evergreen.V400.MuteSettings
import Evergreen.V400.NonemptyDict
import Evergreen.V400.OneOrGreater
import Evergreen.V400.Pagination
import Evergreen.V400.PersonName
import Evergreen.V400.RichText
import Evergreen.V400.Sticker
import Evergreen.V400.UserAgent
import Evergreen.V400.UserColor
import Evergreen.V400.UserSession
import Evergreen.V400.X25519
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
    = DmChannelLastViewed (Evergreen.V400.Id.Id Evergreen.V400.Id.UserId) Evergreen.V400.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V400.Discord.Id Evergreen.V400.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias FrontendCurrentUser =
    { name : Evergreen.V400.PersonName.PersonName
    , color : Evergreen.V400.UserColor.UserColor
    , isAdmin : Bool
    , email : Evergreen.V400.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V400.Id.Id Evergreen.V400.Pagination.PageId
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , embedVisibility : EmbedVisibility
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V400.Id.AnyGuildOrDmId (Evergreen.V400.Id.Id Evergreen.V400.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V400.Id.AnyGuildOrDmId, Evergreen.V400.Id.Id Evergreen.V400.Id.ChannelMessageId ) (Evergreen.V400.Id.Id Evergreen.V400.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V400.Id.Id Evergreen.V400.Id.GuildId) ( Evergreen.V400.Id.Id Evergreen.V400.Id.ChannelId, Evergreen.V400.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V400.Discord.Id Evergreen.V400.Discord.GuildId) ( Evergreen.V400.Discord.Id Evergreen.V400.Discord.ChannelId, Evergreen.V400.Id.ThreadRoute )
    , icon : Maybe Evergreen.V400.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V400.Id.Id Evergreen.V400.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V400.Discord.Id Evergreen.V400.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V400.Id.Id Evergreen.V400.Id.GuildId) (Evergreen.V400.NonemptyDict.NonemptyDict ( Evergreen.V400.Id.Id Evergreen.V400.Id.ChannelId, Evergreen.V400.Id.ThreadRoute ) Evergreen.V400.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V400.Discord.Id Evergreen.V400.Discord.GuildId) (Evergreen.V400.NonemptyDict.NonemptyDict ( Evergreen.V400.Discord.Id Evergreen.V400.Discord.ChannelId, Evergreen.V400.Id.ThreadRoute ) Evergreen.V400.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V400.RichText.Domain
    , emojiConfig : Evergreen.V400.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V400.Id.Id Evergreen.V400.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V400.Id.Id Evergreen.V400.Id.CustomEmojiId)
    , muteSettings : Evergreen.V400.MuteSettings.Model
    , publicKey : Maybe Evergreen.V400.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    , deleteAccountAt : Maybe Effect.Time.Posix
    }


type alias FrontendUser =
    { name : Evergreen.V400.PersonName.PersonName
    , color : Evergreen.V400.UserColor.UserColor
    , icon : Maybe Evergreen.V400.FileStatus.FileHash
    , publicKey : Maybe Evergreen.V400.X25519.PublicKey
    }


type BackendUserStatus
    = DeletedUser
    | UserHasEmail Evergreen.V400.EmailAddress.EmailAddress


type alias BackendUser =
    { name : Evergreen.V400.PersonName.PersonName
    , color : Evergreen.V400.UserColor.UserColor
    , isAdmin : Bool
    , email : BackendUserStatus
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V400.Id.Id Evergreen.V400.Pagination.PageId
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , embedVisibility : EmbedVisibility
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V400.Id.AnyGuildOrDmId (Evergreen.V400.Id.Id Evergreen.V400.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V400.Id.AnyGuildOrDmId, Evergreen.V400.Id.Id Evergreen.V400.Id.ChannelMessageId ) (Evergreen.V400.Id.Id Evergreen.V400.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V400.Id.Id Evergreen.V400.Id.GuildId) ( Evergreen.V400.Id.Id Evergreen.V400.Id.ChannelId, Evergreen.V400.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V400.Discord.Id Evergreen.V400.Discord.GuildId) ( Evergreen.V400.Discord.Id Evergreen.V400.Discord.ChannelId, Evergreen.V400.Id.ThreadRoute )
    , icon : Maybe Evergreen.V400.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V400.Id.Id Evergreen.V400.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V400.Discord.Id Evergreen.V400.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V400.Id.Id Evergreen.V400.Id.GuildId) (Evergreen.V400.NonemptyDict.NonemptyDict ( Evergreen.V400.Id.Id Evergreen.V400.Id.ChannelId, Evergreen.V400.Id.ThreadRoute ) Evergreen.V400.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V400.Discord.Id Evergreen.V400.Discord.GuildId) (Evergreen.V400.NonemptyDict.NonemptyDict ( Evergreen.V400.Discord.Id Evergreen.V400.Discord.ChannelId, Evergreen.V400.Id.ThreadRoute ) Evergreen.V400.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V400.RichText.Domain
    , emojiConfig : Evergreen.V400.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V400.Id.Id Evergreen.V400.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V400.Id.Id Evergreen.V400.Id.CustomEmojiId)
    , muteSettings : Evergreen.V400.MuteSettings.Model
    , publicKey : Maybe Evergreen.V400.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    , deleteAccountAt : Maybe Effect.Time.Posix
    }


type alias LocalUser =
    { session : Evergreen.V400.UserSession.UserSession
    , currentlyViewing : Evergreen.V400.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V400.Id.Id Evergreen.V400.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V400.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V400.UserAgent.UserAgent
    , devicePixelRatio : Float
    , safeAreaInsetTop : Int
    , safeAreaInsetBottom : Int
    , stickers : SeqDict.SeqDict (Evergreen.V400.Id.Id Evergreen.V400.Id.StickerId) Evergreen.V400.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V400.Id.Id Evergreen.V400.Id.CustomEmojiId) Evergreen.V400.CustomEmoji.CustomEmojiData
    , emojiData : Maybe Evergreen.V400.Emoji.CachedEmojiData
    , decryptedMessages : SeqDict.SeqDict Evergreen.V400.Encryption.BytesHash (Result () (Evergreen.V400.Message.MessageContent (Evergreen.V400.Id.Id Evergreen.V400.Id.UserId) (Evergreen.V400.Id.Id Evergreen.V400.Id.ChannelId)))
    }
