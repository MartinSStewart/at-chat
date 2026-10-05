module Evergreen.V398.User exposing (..)

import Effect.Time
import Evergreen.V398.CustomEmoji
import Evergreen.V398.Discord
import Evergreen.V398.EmailAddress
import Evergreen.V398.Emoji
import Evergreen.V398.Encryption
import Evergreen.V398.FileStatus
import Evergreen.V398.Id
import Evergreen.V398.LinkedAndOtherDiscordUsers
import Evergreen.V398.Message
import Evergreen.V398.MuteSettings
import Evergreen.V398.NonemptyDict
import Evergreen.V398.OneOrGreater
import Evergreen.V398.Pagination
import Evergreen.V398.PersonName
import Evergreen.V398.RichText
import Evergreen.V398.Sticker
import Evergreen.V398.UserAgent
import Evergreen.V398.UserColor
import Evergreen.V398.UserSession
import Evergreen.V398.X25519
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
    = DmChannelLastViewed (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) Evergreen.V398.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V398.Discord.Id Evergreen.V398.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias FrontendCurrentUser =
    { name : Evergreen.V398.PersonName.PersonName
    , color : Evergreen.V398.UserColor.UserColor
    , isAdmin : Bool
    , email : Evergreen.V398.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V398.Id.Id Evergreen.V398.Pagination.PageId
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , embedVisibility : EmbedVisibility
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V398.Id.AnyGuildOrDmId (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V398.Id.AnyGuildOrDmId, Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId ) (Evergreen.V398.Id.Id Evergreen.V398.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId) ( Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelId, Evergreen.V398.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId) ( Evergreen.V398.Discord.Id Evergreen.V398.Discord.ChannelId, Evergreen.V398.Id.ThreadRoute )
    , icon : Maybe Evergreen.V398.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId) (Evergreen.V398.NonemptyDict.NonemptyDict ( Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelId, Evergreen.V398.Id.ThreadRoute ) Evergreen.V398.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId) (Evergreen.V398.NonemptyDict.NonemptyDict ( Evergreen.V398.Discord.Id Evergreen.V398.Discord.ChannelId, Evergreen.V398.Id.ThreadRoute ) Evergreen.V398.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V398.RichText.Domain
    , emojiConfig : Evergreen.V398.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V398.Id.Id Evergreen.V398.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V398.Id.Id Evergreen.V398.Id.CustomEmojiId)
    , muteSettings : Evergreen.V398.MuteSettings.Model
    , publicKey : Maybe Evergreen.V398.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    , deleteAccountAt : Maybe Effect.Time.Posix
    }


type alias FrontendUser =
    { name : Evergreen.V398.PersonName.PersonName
    , color : Evergreen.V398.UserColor.UserColor
    , icon : Maybe Evergreen.V398.FileStatus.FileHash
    , publicKey : Maybe Evergreen.V398.X25519.PublicKey
    }


type BackendUserStatus
    = DeletedUser
    | UserHasEmail Evergreen.V398.EmailAddress.EmailAddress


type alias BackendUser =
    { name : Evergreen.V398.PersonName.PersonName
    , color : Evergreen.V398.UserColor.UserColor
    , isAdmin : Bool
    , email : BackendUserStatus
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V398.Id.Id Evergreen.V398.Pagination.PageId
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , embedVisibility : EmbedVisibility
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V398.Id.AnyGuildOrDmId (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V398.Id.AnyGuildOrDmId, Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId ) (Evergreen.V398.Id.Id Evergreen.V398.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId) ( Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelId, Evergreen.V398.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId) ( Evergreen.V398.Discord.Id Evergreen.V398.Discord.ChannelId, Evergreen.V398.Id.ThreadRoute )
    , icon : Maybe Evergreen.V398.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId) (Evergreen.V398.NonemptyDict.NonemptyDict ( Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelId, Evergreen.V398.Id.ThreadRoute ) Evergreen.V398.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId) (Evergreen.V398.NonemptyDict.NonemptyDict ( Evergreen.V398.Discord.Id Evergreen.V398.Discord.ChannelId, Evergreen.V398.Id.ThreadRoute ) Evergreen.V398.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V398.RichText.Domain
    , emojiConfig : Evergreen.V398.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V398.Id.Id Evergreen.V398.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V398.Id.Id Evergreen.V398.Id.CustomEmojiId)
    , muteSettings : Evergreen.V398.MuteSettings.Model
    , publicKey : Maybe Evergreen.V398.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    , deleteAccountAt : Maybe Effect.Time.Posix
    }


type alias LocalUser =
    { session : Evergreen.V398.UserSession.UserSession
    , currentlyViewing : Evergreen.V398.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V398.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V398.UserAgent.UserAgent
    , devicePixelRatio : Float
    , safeAreaInsetTop : Int
    , safeAreaInsetBottom : Int
    , stickers : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.StickerId) Evergreen.V398.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.CustomEmojiId) Evergreen.V398.CustomEmoji.CustomEmojiData
    , emojiData : Maybe Evergreen.V398.Emoji.CachedEmojiData
    , decryptedMessages : SeqDict.SeqDict Evergreen.V398.Encryption.BytesHash (Result () (Evergreen.V398.Message.MessageContent (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelId)))
    }
