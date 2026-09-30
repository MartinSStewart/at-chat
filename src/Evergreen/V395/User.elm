module Evergreen.V395.User exposing (..)

import Effect.Time
import Evergreen.V395.CustomEmoji
import Evergreen.V395.Discord
import Evergreen.V395.EmailAddress
import Evergreen.V395.Emoji
import Evergreen.V395.Encryption
import Evergreen.V395.FileStatus
import Evergreen.V395.Id
import Evergreen.V395.LinkedAndOtherDiscordUsers
import Evergreen.V395.Message
import Evergreen.V395.MuteSettings
import Evergreen.V395.NonemptyDict
import Evergreen.V395.OneOrGreater
import Evergreen.V395.Pagination
import Evergreen.V395.PersonName
import Evergreen.V395.RichText
import Evergreen.V395.Sticker
import Evergreen.V395.UserAgent
import Evergreen.V395.UserColor
import Evergreen.V395.UserSession
import Evergreen.V395.X25519
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
    = DmChannelLastViewed (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) Evergreen.V395.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V395.Discord.Id Evergreen.V395.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias FrontendCurrentUser =
    { name : Evergreen.V395.PersonName.PersonName
    , color : Evergreen.V395.UserColor.UserColor
    , isAdmin : Bool
    , email : Evergreen.V395.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V395.Id.Id Evergreen.V395.Pagination.PageId
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , embedVisibility : EmbedVisibility
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V395.Id.AnyGuildOrDmId (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V395.Id.AnyGuildOrDmId, Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId ) (Evergreen.V395.Id.Id Evergreen.V395.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId) ( Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelId, Evergreen.V395.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId) ( Evergreen.V395.Discord.Id Evergreen.V395.Discord.ChannelId, Evergreen.V395.Id.ThreadRoute )
    , icon : Maybe Evergreen.V395.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId) (Evergreen.V395.NonemptyDict.NonemptyDict ( Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelId, Evergreen.V395.Id.ThreadRoute ) Evergreen.V395.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId) (Evergreen.V395.NonemptyDict.NonemptyDict ( Evergreen.V395.Discord.Id Evergreen.V395.Discord.ChannelId, Evergreen.V395.Id.ThreadRoute ) Evergreen.V395.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V395.RichText.Domain
    , emojiConfig : Evergreen.V395.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V395.Id.Id Evergreen.V395.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V395.Id.Id Evergreen.V395.Id.CustomEmojiId)
    , muteSettings : Evergreen.V395.MuteSettings.Model
    , publicKey : Maybe Evergreen.V395.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    , deleteAccountAt : Maybe Effect.Time.Posix
    }


type alias FrontendUser =
    { name : Evergreen.V395.PersonName.PersonName
    , color : Evergreen.V395.UserColor.UserColor
    , icon : Maybe Evergreen.V395.FileStatus.FileHash
    , publicKey : Maybe Evergreen.V395.X25519.PublicKey
    }


type BackendUserStatus
    = DeletedUser
    | UserHasEmail Evergreen.V395.EmailAddress.EmailAddress


type alias BackendUser =
    { name : Evergreen.V395.PersonName.PersonName
    , color : Evergreen.V395.UserColor.UserColor
    , isAdmin : Bool
    , email : BackendUserStatus
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V395.Id.Id Evergreen.V395.Pagination.PageId
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , embedVisibility : EmbedVisibility
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V395.Id.AnyGuildOrDmId (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V395.Id.AnyGuildOrDmId, Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId ) (Evergreen.V395.Id.Id Evergreen.V395.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId) ( Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelId, Evergreen.V395.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId) ( Evergreen.V395.Discord.Id Evergreen.V395.Discord.ChannelId, Evergreen.V395.Id.ThreadRoute )
    , icon : Maybe Evergreen.V395.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId) (Evergreen.V395.NonemptyDict.NonemptyDict ( Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelId, Evergreen.V395.Id.ThreadRoute ) Evergreen.V395.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId) (Evergreen.V395.NonemptyDict.NonemptyDict ( Evergreen.V395.Discord.Id Evergreen.V395.Discord.ChannelId, Evergreen.V395.Id.ThreadRoute ) Evergreen.V395.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V395.RichText.Domain
    , emojiConfig : Evergreen.V395.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V395.Id.Id Evergreen.V395.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V395.Id.Id Evergreen.V395.Id.CustomEmojiId)
    , muteSettings : Evergreen.V395.MuteSettings.Model
    , publicKey : Maybe Evergreen.V395.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    , deleteAccountAt : Maybe Effect.Time.Posix
    }


type alias LocalUser =
    { session : Evergreen.V395.UserSession.UserSession
    , currentlyViewing : Evergreen.V395.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V395.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V395.UserAgent.UserAgent
    , devicePixelRatio : Float
    , safeAreaInsetTop : Int
    , safeAreaInsetBottom : Int
    , stickers : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.StickerId) Evergreen.V395.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.CustomEmojiId) Evergreen.V395.CustomEmoji.CustomEmojiData
    , emojiData : Maybe Evergreen.V395.Emoji.CachedEmojiData
    , decryptedMessages : SeqDict.SeqDict Evergreen.V395.Encryption.BytesHash (Result () (Evergreen.V395.Message.MessageContent (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelId)))
    }
