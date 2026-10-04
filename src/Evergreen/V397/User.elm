module Evergreen.V397.User exposing (..)

import Effect.Time
import Evergreen.V397.CustomEmoji
import Evergreen.V397.Discord
import Evergreen.V397.EmailAddress
import Evergreen.V397.Emoji
import Evergreen.V397.Encryption
import Evergreen.V397.FileStatus
import Evergreen.V397.Id
import Evergreen.V397.LinkedAndOtherDiscordUsers
import Evergreen.V397.Message
import Evergreen.V397.MuteSettings
import Evergreen.V397.NonemptyDict
import Evergreen.V397.OneOrGreater
import Evergreen.V397.Pagination
import Evergreen.V397.PersonName
import Evergreen.V397.RichText
import Evergreen.V397.Sticker
import Evergreen.V397.UserAgent
import Evergreen.V397.UserColor
import Evergreen.V397.UserSession
import Evergreen.V397.X25519
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
    = DmChannelLastViewed (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) Evergreen.V397.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V397.Discord.Id Evergreen.V397.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias FrontendCurrentUser =
    { name : Evergreen.V397.PersonName.PersonName
    , color : Evergreen.V397.UserColor.UserColor
    , isAdmin : Bool
    , email : Evergreen.V397.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V397.Id.Id Evergreen.V397.Pagination.PageId
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , embedVisibility : EmbedVisibility
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V397.Id.AnyGuildOrDmId (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V397.Id.AnyGuildOrDmId, Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId ) (Evergreen.V397.Id.Id Evergreen.V397.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId) ( Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelId, Evergreen.V397.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId) ( Evergreen.V397.Discord.Id Evergreen.V397.Discord.ChannelId, Evergreen.V397.Id.ThreadRoute )
    , icon : Maybe Evergreen.V397.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId) (Evergreen.V397.NonemptyDict.NonemptyDict ( Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelId, Evergreen.V397.Id.ThreadRoute ) Evergreen.V397.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId) (Evergreen.V397.NonemptyDict.NonemptyDict ( Evergreen.V397.Discord.Id Evergreen.V397.Discord.ChannelId, Evergreen.V397.Id.ThreadRoute ) Evergreen.V397.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V397.RichText.Domain
    , emojiConfig : Evergreen.V397.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V397.Id.Id Evergreen.V397.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V397.Id.Id Evergreen.V397.Id.CustomEmojiId)
    , muteSettings : Evergreen.V397.MuteSettings.Model
    , publicKey : Maybe Evergreen.V397.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    , deleteAccountAt : Maybe Effect.Time.Posix
    }


type alias FrontendUser =
    { name : Evergreen.V397.PersonName.PersonName
    , color : Evergreen.V397.UserColor.UserColor
    , icon : Maybe Evergreen.V397.FileStatus.FileHash
    , publicKey : Maybe Evergreen.V397.X25519.PublicKey
    }


type BackendUserStatus
    = DeletedUser
    | UserHasEmail Evergreen.V397.EmailAddress.EmailAddress


type alias BackendUser =
    { name : Evergreen.V397.PersonName.PersonName
    , color : Evergreen.V397.UserColor.UserColor
    , isAdmin : Bool
    , email : BackendUserStatus
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V397.Id.Id Evergreen.V397.Pagination.PageId
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , embedVisibility : EmbedVisibility
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V397.Id.AnyGuildOrDmId (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V397.Id.AnyGuildOrDmId, Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId ) (Evergreen.V397.Id.Id Evergreen.V397.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId) ( Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelId, Evergreen.V397.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId) ( Evergreen.V397.Discord.Id Evergreen.V397.Discord.ChannelId, Evergreen.V397.Id.ThreadRoute )
    , icon : Maybe Evergreen.V397.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId) (Evergreen.V397.NonemptyDict.NonemptyDict ( Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelId, Evergreen.V397.Id.ThreadRoute ) Evergreen.V397.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId) (Evergreen.V397.NonemptyDict.NonemptyDict ( Evergreen.V397.Discord.Id Evergreen.V397.Discord.ChannelId, Evergreen.V397.Id.ThreadRoute ) Evergreen.V397.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V397.RichText.Domain
    , emojiConfig : Evergreen.V397.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V397.Id.Id Evergreen.V397.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V397.Id.Id Evergreen.V397.Id.CustomEmojiId)
    , muteSettings : Evergreen.V397.MuteSettings.Model
    , publicKey : Maybe Evergreen.V397.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    , deleteAccountAt : Maybe Effect.Time.Posix
    }


type alias LocalUser =
    { session : Evergreen.V397.UserSession.UserSession
    , currentlyViewing : Evergreen.V397.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V397.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V397.UserAgent.UserAgent
    , devicePixelRatio : Float
    , safeAreaInsetTop : Int
    , safeAreaInsetBottom : Int
    , stickers : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.StickerId) Evergreen.V397.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.CustomEmojiId) Evergreen.V397.CustomEmoji.CustomEmojiData
    , emojiData : Maybe Evergreen.V397.Emoji.CachedEmojiData
    , decryptedMessages : SeqDict.SeqDict Evergreen.V397.Encryption.BytesHash (Result () (Evergreen.V397.Message.MessageContent (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelId)))
    }
