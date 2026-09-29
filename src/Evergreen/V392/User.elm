module Evergreen.V392.User exposing (..)

import Effect.Time
import Evergreen.V392.CustomEmoji
import Evergreen.V392.Discord
import Evergreen.V392.EmailAddress
import Evergreen.V392.Emoji
import Evergreen.V392.Encryption
import Evergreen.V392.FileStatus
import Evergreen.V392.Id
import Evergreen.V392.LinkedAndOtherDiscordUsers
import Evergreen.V392.Message
import Evergreen.V392.MuteSettings
import Evergreen.V392.NonemptyDict
import Evergreen.V392.OneOrGreater
import Evergreen.V392.Pagination
import Evergreen.V392.PersonName
import Evergreen.V392.RichText
import Evergreen.V392.Sticker
import Evergreen.V392.UserAgent
import Evergreen.V392.UserColor
import Evergreen.V392.UserSession
import Evergreen.V392.X25519
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
    = DmChannelLastViewed (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) Evergreen.V392.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V392.Discord.Id Evergreen.V392.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias FrontendCurrentUser =
    { name : Evergreen.V392.PersonName.PersonName
    , color : Evergreen.V392.UserColor.UserColor
    , isAdmin : Bool
    , email : Evergreen.V392.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V392.Id.Id Evergreen.V392.Pagination.PageId
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , embedVisibility : EmbedVisibility
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V392.Id.AnyGuildOrDmId (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V392.Id.AnyGuildOrDmId, Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId ) (Evergreen.V392.Id.Id Evergreen.V392.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId) ( Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelId, Evergreen.V392.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V392.Discord.Id Evergreen.V392.Discord.GuildId) ( Evergreen.V392.Discord.Id Evergreen.V392.Discord.ChannelId, Evergreen.V392.Id.ThreadRoute )
    , icon : Maybe Evergreen.V392.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V392.Discord.Id Evergreen.V392.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId) (Evergreen.V392.NonemptyDict.NonemptyDict ( Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelId, Evergreen.V392.Id.ThreadRoute ) Evergreen.V392.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V392.Discord.Id Evergreen.V392.Discord.GuildId) (Evergreen.V392.NonemptyDict.NonemptyDict ( Evergreen.V392.Discord.Id Evergreen.V392.Discord.ChannelId, Evergreen.V392.Id.ThreadRoute ) Evergreen.V392.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V392.RichText.Domain
    , emojiConfig : Evergreen.V392.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V392.Id.Id Evergreen.V392.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V392.Id.Id Evergreen.V392.Id.CustomEmojiId)
    , muteSettings : Evergreen.V392.MuteSettings.Model
    , publicKey : Maybe Evergreen.V392.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    , deleteAccountAt : Maybe Effect.Time.Posix
    }


type alias FrontendUser =
    { name : Evergreen.V392.PersonName.PersonName
    , color : Evergreen.V392.UserColor.UserColor
    , icon : Maybe Evergreen.V392.FileStatus.FileHash
    , publicKey : Maybe Evergreen.V392.X25519.PublicKey
    }


type BackendUserStatus
    = DeletedUser
    | UserHasEmail Evergreen.V392.EmailAddress.EmailAddress


type alias BackendUser =
    { name : Evergreen.V392.PersonName.PersonName
    , color : Evergreen.V392.UserColor.UserColor
    , isAdmin : Bool
    , email : BackendUserStatus
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V392.Id.Id Evergreen.V392.Pagination.PageId
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , embedVisibility : EmbedVisibility
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V392.Id.AnyGuildOrDmId (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V392.Id.AnyGuildOrDmId, Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId ) (Evergreen.V392.Id.Id Evergreen.V392.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId) ( Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelId, Evergreen.V392.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V392.Discord.Id Evergreen.V392.Discord.GuildId) ( Evergreen.V392.Discord.Id Evergreen.V392.Discord.ChannelId, Evergreen.V392.Id.ThreadRoute )
    , icon : Maybe Evergreen.V392.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V392.Discord.Id Evergreen.V392.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId) (Evergreen.V392.NonemptyDict.NonemptyDict ( Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelId, Evergreen.V392.Id.ThreadRoute ) Evergreen.V392.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V392.Discord.Id Evergreen.V392.Discord.GuildId) (Evergreen.V392.NonemptyDict.NonemptyDict ( Evergreen.V392.Discord.Id Evergreen.V392.Discord.ChannelId, Evergreen.V392.Id.ThreadRoute ) Evergreen.V392.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V392.RichText.Domain
    , emojiConfig : Evergreen.V392.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V392.Id.Id Evergreen.V392.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V392.Id.Id Evergreen.V392.Id.CustomEmojiId)
    , muteSettings : Evergreen.V392.MuteSettings.Model
    , publicKey : Maybe Evergreen.V392.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    , deleteAccountAt : Maybe Effect.Time.Posix
    }


type alias LocalUser =
    { session : Evergreen.V392.UserSession.UserSession
    , currentlyViewing : Evergreen.V392.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V392.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V392.UserAgent.UserAgent
    , devicePixelRatio : Float
    , safeAreaInsetTop : Int
    , safeAreaInsetBottom : Int
    , stickers : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.StickerId) Evergreen.V392.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.CustomEmojiId) Evergreen.V392.CustomEmoji.CustomEmojiData
    , emojiData : Maybe Evergreen.V392.Emoji.CachedEmojiData
    , decryptedMessages : SeqDict.SeqDict Evergreen.V392.Encryption.BytesHash (Result () (Evergreen.V392.Message.MessageContent (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelId)))
    }
