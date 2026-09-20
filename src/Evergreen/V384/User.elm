module Evergreen.V384.User exposing (..)

import Effect.Time
import Evergreen.V384.CustomEmoji
import Evergreen.V384.Discord
import Evergreen.V384.EmailAddress
import Evergreen.V384.Emoji
import Evergreen.V384.Encryption
import Evergreen.V384.FileStatus
import Evergreen.V384.Id
import Evergreen.V384.LinkedAndOtherDiscordUsers
import Evergreen.V384.Message
import Evergreen.V384.MuteSettings
import Evergreen.V384.NonemptyDict
import Evergreen.V384.OneOrGreater
import Evergreen.V384.Pagination
import Evergreen.V384.PersonName
import Evergreen.V384.RichText
import Evergreen.V384.Sticker
import Evergreen.V384.UserAgent
import Evergreen.V384.UserColor
import Evergreen.V384.UserSession
import Evergreen.V384.X25519
import SeqDict
import SeqSet


type EmailNotifications
    = NeverNotifyMe
    | NotifyMeWhenMentioned


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention


type LastDmViewed
    = DmChannelLastViewed (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId) Evergreen.V384.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V384.Discord.Id Evergreen.V384.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V384.PersonName.PersonName
    , color : Evergreen.V384.UserColor.UserColor
    , isAdmin : Bool
    , email : Evergreen.V384.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V384.Id.Id Evergreen.V384.Pagination.PageId
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V384.Id.AnyGuildOrDmId (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V384.Id.AnyGuildOrDmId, Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelMessageId ) (Evergreen.V384.Id.Id Evergreen.V384.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId) ( Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelId, Evergreen.V384.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId) ( Evergreen.V384.Discord.Id Evergreen.V384.Discord.ChannelId, Evergreen.V384.Id.ThreadRoute )
    , icon : Maybe Evergreen.V384.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId) (Evergreen.V384.NonemptyDict.NonemptyDict ( Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelId, Evergreen.V384.Id.ThreadRoute ) Evergreen.V384.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId) (Evergreen.V384.NonemptyDict.NonemptyDict ( Evergreen.V384.Discord.Id Evergreen.V384.Discord.ChannelId, Evergreen.V384.Id.ThreadRoute ) Evergreen.V384.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V384.RichText.Domain
    , emojiConfig : Evergreen.V384.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V384.Id.Id Evergreen.V384.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V384.Id.Id Evergreen.V384.Id.CustomEmojiId)
    , muteSettings : Evergreen.V384.MuteSettings.Model
    , publicKey : Maybe Evergreen.V384.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V384.PersonName.PersonName
    , color : Evergreen.V384.UserColor.UserColor
    , icon : Maybe Evergreen.V384.FileStatus.FileHash
    , publicKey : Maybe Evergreen.V384.X25519.PublicKey
    }


type alias LocalUser =
    { session : Evergreen.V384.UserSession.UserSession
    , currentlyViewing : Evergreen.V384.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V384.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V384.UserAgent.UserAgent
    , devicePixelRatio : Float
    , stickers : SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.StickerId) Evergreen.V384.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.CustomEmojiId) Evergreen.V384.CustomEmoji.CustomEmojiData
    , emojiData : Maybe Evergreen.V384.Emoji.CachedEmojiData
    , decryptedMessages : SeqDict.SeqDict Evergreen.V384.Encryption.BytesHash (Result () (Evergreen.V384.Message.MessageContent (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId)))
    }
