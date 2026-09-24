module Evergreen.V385.User exposing (..)

import Effect.Time
import Evergreen.V385.CustomEmoji
import Evergreen.V385.Discord
import Evergreen.V385.EmailAddress
import Evergreen.V385.Emoji
import Evergreen.V385.Encryption
import Evergreen.V385.FileStatus
import Evergreen.V385.Id
import Evergreen.V385.LinkedAndOtherDiscordUsers
import Evergreen.V385.Message
import Evergreen.V385.MuteSettings
import Evergreen.V385.NonemptyDict
import Evergreen.V385.OneOrGreater
import Evergreen.V385.Pagination
import Evergreen.V385.PersonName
import Evergreen.V385.RichText
import Evergreen.V385.Sticker
import Evergreen.V385.UserAgent
import Evergreen.V385.UserColor
import Evergreen.V385.UserSession
import Evergreen.V385.X25519
import SeqDict
import SeqSet


type EmailNotifications
    = NeverNotifyMe
    | NotifyMeWhenMentioned


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention


type LastDmViewed
    = DmChannelLastViewed (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId) Evergreen.V385.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V385.Discord.Id Evergreen.V385.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V385.PersonName.PersonName
    , color : Evergreen.V385.UserColor.UserColor
    , isAdmin : Bool
    , email : Evergreen.V385.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V385.Id.Id Evergreen.V385.Pagination.PageId
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V385.Id.AnyGuildOrDmId (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V385.Id.AnyGuildOrDmId, Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId ) (Evergreen.V385.Id.Id Evergreen.V385.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId) ( Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelId, Evergreen.V385.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId) ( Evergreen.V385.Discord.Id Evergreen.V385.Discord.ChannelId, Evergreen.V385.Id.ThreadRoute )
    , icon : Maybe Evergreen.V385.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId) (Evergreen.V385.NonemptyDict.NonemptyDict ( Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelId, Evergreen.V385.Id.ThreadRoute ) Evergreen.V385.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId) (Evergreen.V385.NonemptyDict.NonemptyDict ( Evergreen.V385.Discord.Id Evergreen.V385.Discord.ChannelId, Evergreen.V385.Id.ThreadRoute ) Evergreen.V385.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V385.RichText.Domain
    , emojiConfig : Evergreen.V385.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V385.Id.Id Evergreen.V385.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V385.Id.Id Evergreen.V385.Id.CustomEmojiId)
    , muteSettings : Evergreen.V385.MuteSettings.Model
    , publicKey : Maybe Evergreen.V385.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V385.PersonName.PersonName
    , color : Evergreen.V385.UserColor.UserColor
    , icon : Maybe Evergreen.V385.FileStatus.FileHash
    , publicKey : Maybe Evergreen.V385.X25519.PublicKey
    }


type alias LocalUser =
    { session : Evergreen.V385.UserSession.UserSession
    , currentlyViewing : Evergreen.V385.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V385.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V385.UserAgent.UserAgent
    , devicePixelRatio : Float
    , stickers : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.StickerId) Evergreen.V385.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.CustomEmojiId) Evergreen.V385.CustomEmoji.CustomEmojiData
    , emojiData : Maybe Evergreen.V385.Emoji.CachedEmojiData
    , decryptedMessages : SeqDict.SeqDict Evergreen.V385.Encryption.BytesHash (Result () (Evergreen.V385.Message.MessageContent (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId)))
    }
