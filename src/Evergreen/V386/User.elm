module Evergreen.V386.User exposing (..)

import Effect.Time
import Evergreen.V386.CustomEmoji
import Evergreen.V386.Discord
import Evergreen.V386.EmailAddress
import Evergreen.V386.Emoji
import Evergreen.V386.Encryption
import Evergreen.V386.FileStatus
import Evergreen.V386.Id
import Evergreen.V386.LinkedAndOtherDiscordUsers
import Evergreen.V386.Message
import Evergreen.V386.MuteSettings
import Evergreen.V386.NonemptyDict
import Evergreen.V386.OneOrGreater
import Evergreen.V386.Pagination
import Evergreen.V386.PersonName
import Evergreen.V386.RichText
import Evergreen.V386.Sticker
import Evergreen.V386.UserAgent
import Evergreen.V386.UserColor
import Evergreen.V386.UserSession
import Evergreen.V386.X25519
import SeqDict
import SeqSet


type EmailNotifications
    = NeverNotifyMe
    | NotifyMeWhenMentioned


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention


type LastDmViewed
    = DmChannelLastViewed (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) Evergreen.V386.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V386.Discord.Id Evergreen.V386.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V386.PersonName.PersonName
    , color : Evergreen.V386.UserColor.UserColor
    , isAdmin : Bool
    , email : Evergreen.V386.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V386.Id.Id Evergreen.V386.Pagination.PageId
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V386.Id.AnyGuildOrDmId (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V386.Id.AnyGuildOrDmId, Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId ) (Evergreen.V386.Id.Id Evergreen.V386.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId) ( Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelId, Evergreen.V386.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId) ( Evergreen.V386.Discord.Id Evergreen.V386.Discord.ChannelId, Evergreen.V386.Id.ThreadRoute )
    , icon : Maybe Evergreen.V386.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId) (Evergreen.V386.NonemptyDict.NonemptyDict ( Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelId, Evergreen.V386.Id.ThreadRoute ) Evergreen.V386.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId) (Evergreen.V386.NonemptyDict.NonemptyDict ( Evergreen.V386.Discord.Id Evergreen.V386.Discord.ChannelId, Evergreen.V386.Id.ThreadRoute ) Evergreen.V386.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V386.RichText.Domain
    , emojiConfig : Evergreen.V386.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V386.Id.Id Evergreen.V386.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V386.Id.Id Evergreen.V386.Id.CustomEmojiId)
    , muteSettings : Evergreen.V386.MuteSettings.Model
    , publicKey : Maybe Evergreen.V386.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V386.PersonName.PersonName
    , color : Evergreen.V386.UserColor.UserColor
    , icon : Maybe Evergreen.V386.FileStatus.FileHash
    , publicKey : Maybe Evergreen.V386.X25519.PublicKey
    }


type alias LocalUser =
    { session : Evergreen.V386.UserSession.UserSession
    , currentlyViewing : Evergreen.V386.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V386.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V386.UserAgent.UserAgent
    , devicePixelRatio : Float
    , safeAreaInsetTop : Int
    , safeAreaInsetBottom : Int
    , stickers : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.StickerId) Evergreen.V386.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.CustomEmojiId) Evergreen.V386.CustomEmoji.CustomEmojiData
    , emojiData : Maybe Evergreen.V386.Emoji.CachedEmojiData
    , decryptedMessages : SeqDict.SeqDict Evergreen.V386.Encryption.BytesHash (Result () (Evergreen.V386.Message.MessageContent (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelId)))
    }
