module Evergreen.V401.User exposing (..)

import Effect.Time
import Evergreen.V401.CustomEmoji
import Evergreen.V401.Discord
import Evergreen.V401.EmailAddress
import Evergreen.V401.Emoji
import Evergreen.V401.Encryption
import Evergreen.V401.FileStatus
import Evergreen.V401.Id
import Evergreen.V401.LinkedAndOtherDiscordUsers
import Evergreen.V401.Message
import Evergreen.V401.MuteSettings
import Evergreen.V401.NonemptyDict
import Evergreen.V401.OneOrGreater
import Evergreen.V401.Pagination
import Evergreen.V401.PersonName
import Evergreen.V401.RichText
import Evergreen.V401.Sticker
import Evergreen.V401.UserAgent
import Evergreen.V401.UserColor
import Evergreen.V401.UserSession
import Evergreen.V401.X25519
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
    = DmChannelLastViewed (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) Evergreen.V401.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V401.Discord.Id Evergreen.V401.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias FrontendCurrentUser =
    { name : Evergreen.V401.PersonName.PersonName
    , color : Evergreen.V401.UserColor.UserColor
    , isAdmin : Bool
    , email : Evergreen.V401.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V401.Id.Id Evergreen.V401.Pagination.PageId
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , embedVisibility : EmbedVisibility
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V401.Id.AnyGuildOrDmId (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V401.Id.AnyGuildOrDmId, Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId ) (Evergreen.V401.Id.Id Evergreen.V401.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId) ( Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelId, Evergreen.V401.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId) ( Evergreen.V401.Discord.Id Evergreen.V401.Discord.ChannelId, Evergreen.V401.Id.ThreadRoute )
    , icon : Maybe Evergreen.V401.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId) (Evergreen.V401.NonemptyDict.NonemptyDict ( Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelId, Evergreen.V401.Id.ThreadRoute ) Evergreen.V401.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId) (Evergreen.V401.NonemptyDict.NonemptyDict ( Evergreen.V401.Discord.Id Evergreen.V401.Discord.ChannelId, Evergreen.V401.Id.ThreadRoute ) Evergreen.V401.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V401.RichText.Domain
    , emojiConfig : Evergreen.V401.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V401.Id.Id Evergreen.V401.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V401.Id.Id Evergreen.V401.Id.CustomEmojiId)
    , muteSettings : Evergreen.V401.MuteSettings.Model
    , publicKey : Maybe Evergreen.V401.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    , deleteAccountAt : Maybe Effect.Time.Posix
    }


type alias FrontendUser =
    { name : Evergreen.V401.PersonName.PersonName
    , color : Evergreen.V401.UserColor.UserColor
    , icon : Maybe Evergreen.V401.FileStatus.FileHash
    , publicKey : Maybe Evergreen.V401.X25519.PublicKey
    }


type BackendUserStatus
    = DeletedUser
    | UserHasEmail Evergreen.V401.EmailAddress.EmailAddress


type alias BackendUser =
    { name : Evergreen.V401.PersonName.PersonName
    , color : Evergreen.V401.UserColor.UserColor
    , isAdmin : Bool
    , email : BackendUserStatus
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V401.Id.Id Evergreen.V401.Pagination.PageId
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , embedVisibility : EmbedVisibility
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V401.Id.AnyGuildOrDmId (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V401.Id.AnyGuildOrDmId, Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId ) (Evergreen.V401.Id.Id Evergreen.V401.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId) ( Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelId, Evergreen.V401.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId) ( Evergreen.V401.Discord.Id Evergreen.V401.Discord.ChannelId, Evergreen.V401.Id.ThreadRoute )
    , icon : Maybe Evergreen.V401.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId) (Evergreen.V401.NonemptyDict.NonemptyDict ( Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelId, Evergreen.V401.Id.ThreadRoute ) Evergreen.V401.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId) (Evergreen.V401.NonemptyDict.NonemptyDict ( Evergreen.V401.Discord.Id Evergreen.V401.Discord.ChannelId, Evergreen.V401.Id.ThreadRoute ) Evergreen.V401.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V401.RichText.Domain
    , emojiConfig : Evergreen.V401.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V401.Id.Id Evergreen.V401.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V401.Id.Id Evergreen.V401.Id.CustomEmojiId)
    , muteSettings : Evergreen.V401.MuteSettings.Model
    , publicKey : Maybe Evergreen.V401.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    , deleteAccountAt : Maybe Effect.Time.Posix
    }


type alias LocalUser =
    { session : Evergreen.V401.UserSession.UserSession
    , currentlyViewing : Evergreen.V401.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V401.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V401.UserAgent.UserAgent
    , devicePixelRatio : Float
    , safeAreaInsetTop : Int
    , safeAreaInsetBottom : Int
    , stickers : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.StickerId) Evergreen.V401.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.CustomEmojiId) Evergreen.V401.CustomEmoji.CustomEmojiData
    , emojiData : Maybe Evergreen.V401.Emoji.CachedEmojiData
    , decryptedMessages : SeqDict.SeqDict Evergreen.V401.Encryption.BytesHash (Result () (Evergreen.V401.Message.MessageContent (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelId)))
    }
