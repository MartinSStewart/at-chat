module Evergreen.V383.User exposing (..)

import Effect.Time
import Evergreen.V383.CustomEmoji
import Evergreen.V383.Discord
import Evergreen.V383.EmailAddress
import Evergreen.V383.Emoji
import Evergreen.V383.Encryption
import Evergreen.V383.FileStatus
import Evergreen.V383.Id
import Evergreen.V383.LinkedAndOtherDiscordUsers
import Evergreen.V383.Message
import Evergreen.V383.MuteSettings
import Evergreen.V383.NonemptyDict
import Evergreen.V383.OneOrGreater
import Evergreen.V383.Pagination
import Evergreen.V383.PersonName
import Evergreen.V383.RichText
import Evergreen.V383.Sticker
import Evergreen.V383.UserAgent
import Evergreen.V383.UserColor
import Evergreen.V383.UserSession
import Evergreen.V383.X25519
import SeqDict
import SeqSet


type EmailNotifications
    = NeverNotifyMe
    | NotifyMeWhenMentioned


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention


type LastDmViewed
    = DmChannelLastViewed (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId) Evergreen.V383.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V383.Discord.Id Evergreen.V383.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V383.PersonName.PersonName
    , color : Evergreen.V383.UserColor.UserColor
    , isAdmin : Bool
    , email : Evergreen.V383.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V383.Id.Id Evergreen.V383.Pagination.PageId
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V383.Id.AnyGuildOrDmId (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V383.Id.AnyGuildOrDmId, Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId ) (Evergreen.V383.Id.Id Evergreen.V383.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId) ( Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelId, Evergreen.V383.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId) ( Evergreen.V383.Discord.Id Evergreen.V383.Discord.ChannelId, Evergreen.V383.Id.ThreadRoute )
    , icon : Maybe Evergreen.V383.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId) (Evergreen.V383.NonemptyDict.NonemptyDict ( Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelId, Evergreen.V383.Id.ThreadRoute ) Evergreen.V383.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId) (Evergreen.V383.NonemptyDict.NonemptyDict ( Evergreen.V383.Discord.Id Evergreen.V383.Discord.ChannelId, Evergreen.V383.Id.ThreadRoute ) Evergreen.V383.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V383.RichText.Domain
    , emojiConfig : Evergreen.V383.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V383.Id.Id Evergreen.V383.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V383.Id.Id Evergreen.V383.Id.CustomEmojiId)
    , muteSettings : Evergreen.V383.MuteSettings.Model
    , publicKey : Maybe Evergreen.V383.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V383.PersonName.PersonName
    , color : Evergreen.V383.UserColor.UserColor
    , icon : Maybe Evergreen.V383.FileStatus.FileHash
    , publicKey : Maybe Evergreen.V383.X25519.PublicKey
    }


type alias LocalUser =
    { session : Evergreen.V383.UserSession.UserSession
    , currentlyViewing : Evergreen.V383.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V383.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V383.UserAgent.UserAgent
    , devicePixelRatio : Float
    , stickers : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.StickerId) Evergreen.V383.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.CustomEmojiId) Evergreen.V383.CustomEmoji.CustomEmojiData
    , emojiData : Maybe Evergreen.V383.Emoji.CachedEmojiData
    , decryptedMessages : SeqDict.SeqDict Evergreen.V383.Encryption.BytesHash (Result () (Evergreen.V383.Message.MessageContent (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId)))
    }
