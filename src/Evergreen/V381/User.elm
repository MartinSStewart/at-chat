module Evergreen.V381.User exposing (..)

import Effect.Time
import Evergreen.V381.CustomEmoji
import Evergreen.V381.Discord
import Evergreen.V381.EmailAddress
import Evergreen.V381.Emoji
import Evergreen.V381.Encryption
import Evergreen.V381.FileStatus
import Evergreen.V381.Id
import Evergreen.V381.LinkedAndOtherDiscordUsers
import Evergreen.V381.Message
import Evergreen.V381.MuteSettings
import Evergreen.V381.NonemptyDict
import Evergreen.V381.OneOrGreater
import Evergreen.V381.Pagination
import Evergreen.V381.PersonName
import Evergreen.V381.RichText
import Evergreen.V381.Sticker
import Evergreen.V381.UserAgent
import Evergreen.V381.UserColor
import Evergreen.V381.UserSession
import Evergreen.V381.X25519
import SeqDict
import SeqSet


type EmailNotifications
    = NeverNotifyMe
    | NotifyMeWhenMentioned


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention


type LastDmViewed
    = DmChannelLastViewed (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId) Evergreen.V381.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V381.Discord.Id Evergreen.V381.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V381.PersonName.PersonName
    , color : Evergreen.V381.UserColor.UserColor
    , isAdmin : Bool
    , email : Evergreen.V381.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V381.Id.Id Evergreen.V381.Pagination.PageId
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V381.Id.AnyGuildOrDmId (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V381.Id.AnyGuildOrDmId, Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelMessageId ) (Evergreen.V381.Id.Id Evergreen.V381.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId) ( Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelId, Evergreen.V381.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId) ( Evergreen.V381.Discord.Id Evergreen.V381.Discord.ChannelId, Evergreen.V381.Id.ThreadRoute )
    , icon : Maybe Evergreen.V381.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId) (Evergreen.V381.NonemptyDict.NonemptyDict ( Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelId, Evergreen.V381.Id.ThreadRoute ) Evergreen.V381.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId) (Evergreen.V381.NonemptyDict.NonemptyDict ( Evergreen.V381.Discord.Id Evergreen.V381.Discord.ChannelId, Evergreen.V381.Id.ThreadRoute ) Evergreen.V381.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V381.RichText.Domain
    , emojiConfig : Evergreen.V381.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V381.Id.Id Evergreen.V381.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V381.Id.Id Evergreen.V381.Id.CustomEmojiId)
    , muteSettings : Evergreen.V381.MuteSettings.Model
    , publicKey : Maybe Evergreen.V381.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V381.PersonName.PersonName
    , color : Evergreen.V381.UserColor.UserColor
    , icon : Maybe Evergreen.V381.FileStatus.FileHash
    , publicKey : Maybe Evergreen.V381.X25519.PublicKey
    }


type alias LocalUser =
    { session : Evergreen.V381.UserSession.UserSession
    , currentlyViewing : Evergreen.V381.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V381.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V381.UserAgent.UserAgent
    , devicePixelRatio : Float
    , stickers : SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.StickerId) Evergreen.V381.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.CustomEmojiId) Evergreen.V381.CustomEmoji.CustomEmojiData
    , emojiData : Maybe Evergreen.V381.Emoji.CachedEmojiData
    , decryptedMessages : SeqDict.SeqDict Evergreen.V381.Encryption.BytesHash (Result () (Evergreen.V381.Message.MessageContent (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId)))
    }
