module Evergreen.V387.User exposing (..)

import Effect.Time
import Evergreen.V387.CustomEmoji
import Evergreen.V387.Discord
import Evergreen.V387.EmailAddress
import Evergreen.V387.Emoji
import Evergreen.V387.Encryption
import Evergreen.V387.FileStatus
import Evergreen.V387.Id
import Evergreen.V387.LinkedAndOtherDiscordUsers
import Evergreen.V387.Message
import Evergreen.V387.MuteSettings
import Evergreen.V387.NonemptyDict
import Evergreen.V387.OneOrGreater
import Evergreen.V387.Pagination
import Evergreen.V387.PersonName
import Evergreen.V387.RichText
import Evergreen.V387.Sticker
import Evergreen.V387.UserAgent
import Evergreen.V387.UserColor
import Evergreen.V387.UserSession
import Evergreen.V387.X25519
import SeqDict
import SeqSet


type EmailNotifications
    = NeverNotifyMe
    | NotifyMeWhenMentioned


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention


type LastDmViewed
    = DmChannelLastViewed (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) Evergreen.V387.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V387.Discord.Id Evergreen.V387.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V387.PersonName.PersonName
    , color : Evergreen.V387.UserColor.UserColor
    , isAdmin : Bool
    , email : Evergreen.V387.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V387.Id.Id Evergreen.V387.Pagination.PageId
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V387.Id.AnyGuildOrDmId (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V387.Id.AnyGuildOrDmId, Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId ) (Evergreen.V387.Id.Id Evergreen.V387.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId) ( Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelId, Evergreen.V387.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId) ( Evergreen.V387.Discord.Id Evergreen.V387.Discord.ChannelId, Evergreen.V387.Id.ThreadRoute )
    , icon : Maybe Evergreen.V387.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId) (Evergreen.V387.NonemptyDict.NonemptyDict ( Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelId, Evergreen.V387.Id.ThreadRoute ) Evergreen.V387.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId) (Evergreen.V387.NonemptyDict.NonemptyDict ( Evergreen.V387.Discord.Id Evergreen.V387.Discord.ChannelId, Evergreen.V387.Id.ThreadRoute ) Evergreen.V387.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V387.RichText.Domain
    , emojiConfig : Evergreen.V387.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V387.Id.Id Evergreen.V387.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V387.Id.Id Evergreen.V387.Id.CustomEmojiId)
    , muteSettings : Evergreen.V387.MuteSettings.Model
    , publicKey : Maybe Evergreen.V387.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V387.PersonName.PersonName
    , color : Evergreen.V387.UserColor.UserColor
    , icon : Maybe Evergreen.V387.FileStatus.FileHash
    , publicKey : Maybe Evergreen.V387.X25519.PublicKey
    }


type alias LocalUser =
    { session : Evergreen.V387.UserSession.UserSession
    , currentlyViewing : Evergreen.V387.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V387.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V387.UserAgent.UserAgent
    , devicePixelRatio : Float
    , safeAreaInsetTop : Int
    , safeAreaInsetBottom : Int
    , stickers : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.StickerId) Evergreen.V387.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.CustomEmojiId) Evergreen.V387.CustomEmoji.CustomEmojiData
    , emojiData : Maybe Evergreen.V387.Emoji.CachedEmojiData
    , decryptedMessages : SeqDict.SeqDict Evergreen.V387.Encryption.BytesHash (Result () (Evergreen.V387.Message.MessageContent (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelId)))
    }
