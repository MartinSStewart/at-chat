module Evergreen.V382.User exposing (..)

import Effect.Time
import Evergreen.V382.CustomEmoji
import Evergreen.V382.Discord
import Evergreen.V382.EmailAddress
import Evergreen.V382.Emoji
import Evergreen.V382.Encryption
import Evergreen.V382.FileStatus
import Evergreen.V382.Id
import Evergreen.V382.LinkedAndOtherDiscordUsers
import Evergreen.V382.Message
import Evergreen.V382.MuteSettings
import Evergreen.V382.NonemptyDict
import Evergreen.V382.OneOrGreater
import Evergreen.V382.Pagination
import Evergreen.V382.PersonName
import Evergreen.V382.RichText
import Evergreen.V382.Sticker
import Evergreen.V382.UserAgent
import Evergreen.V382.UserColor
import Evergreen.V382.UserSession
import Evergreen.V382.X25519
import SeqDict
import SeqSet


type EmailNotifications
    = NeverNotifyMe
    | NotifyMeWhenMentioned


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention


type LastDmViewed
    = DmChannelLastViewed (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId) Evergreen.V382.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V382.Discord.Id Evergreen.V382.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V382.PersonName.PersonName
    , color : Evergreen.V382.UserColor.UserColor
    , isAdmin : Bool
    , email : Evergreen.V382.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V382.Id.Id Evergreen.V382.Pagination.PageId
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V382.Id.AnyGuildOrDmId (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V382.Id.AnyGuildOrDmId, Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId ) (Evergreen.V382.Id.Id Evergreen.V382.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId) ( Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelId, Evergreen.V382.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId) ( Evergreen.V382.Discord.Id Evergreen.V382.Discord.ChannelId, Evergreen.V382.Id.ThreadRoute )
    , icon : Maybe Evergreen.V382.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId) (Evergreen.V382.NonemptyDict.NonemptyDict ( Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelId, Evergreen.V382.Id.ThreadRoute ) Evergreen.V382.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId) (Evergreen.V382.NonemptyDict.NonemptyDict ( Evergreen.V382.Discord.Id Evergreen.V382.Discord.ChannelId, Evergreen.V382.Id.ThreadRoute ) Evergreen.V382.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V382.RichText.Domain
    , emojiConfig : Evergreen.V382.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V382.Id.Id Evergreen.V382.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V382.Id.Id Evergreen.V382.Id.CustomEmojiId)
    , muteSettings : Evergreen.V382.MuteSettings.Model
    , publicKey : Maybe Evergreen.V382.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V382.PersonName.PersonName
    , color : Evergreen.V382.UserColor.UserColor
    , icon : Maybe Evergreen.V382.FileStatus.FileHash
    , publicKey : Maybe Evergreen.V382.X25519.PublicKey
    }


type alias LocalUser =
    { session : Evergreen.V382.UserSession.UserSession
    , currentlyViewing : Evergreen.V382.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V382.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V382.UserAgent.UserAgent
    , devicePixelRatio : Float
    , stickers : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.StickerId) Evergreen.V382.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.CustomEmojiId) Evergreen.V382.CustomEmoji.CustomEmojiData
    , emojiData : Maybe Evergreen.V382.Emoji.CachedEmojiData
    , decryptedMessages : SeqDict.SeqDict Evergreen.V382.Encryption.BytesHash (Result () (Evergreen.V382.Message.MessageContent (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId)))
    }
