module Evergreen.V388.User exposing (..)

import Effect.Time
import Evergreen.V388.CustomEmoji
import Evergreen.V388.Discord
import Evergreen.V388.EmailAddress
import Evergreen.V388.Emoji
import Evergreen.V388.Encryption
import Evergreen.V388.FileStatus
import Evergreen.V388.Id
import Evergreen.V388.LinkedAndOtherDiscordUsers
import Evergreen.V388.Message
import Evergreen.V388.MuteSettings
import Evergreen.V388.NonemptyDict
import Evergreen.V388.OneOrGreater
import Evergreen.V388.Pagination
import Evergreen.V388.PersonName
import Evergreen.V388.RichText
import Evergreen.V388.Sticker
import Evergreen.V388.UserAgent
import Evergreen.V388.UserColor
import Evergreen.V388.UserSession
import Evergreen.V388.X25519
import SeqDict
import SeqSet


type EmailNotifications
    = NeverNotifyMe
    | NotifyMeWhenMentioned


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention


type LastDmViewed
    = DmChannelLastViewed (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) Evergreen.V388.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V388.Discord.Id Evergreen.V388.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V388.PersonName.PersonName
    , color : Evergreen.V388.UserColor.UserColor
    , isAdmin : Bool
    , email : Evergreen.V388.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V388.Id.Id Evergreen.V388.Pagination.PageId
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V388.Id.AnyGuildOrDmId (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V388.Id.AnyGuildOrDmId, Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId ) (Evergreen.V388.Id.Id Evergreen.V388.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId) ( Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelId, Evergreen.V388.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId) ( Evergreen.V388.Discord.Id Evergreen.V388.Discord.ChannelId, Evergreen.V388.Id.ThreadRoute )
    , icon : Maybe Evergreen.V388.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId) (Evergreen.V388.NonemptyDict.NonemptyDict ( Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelId, Evergreen.V388.Id.ThreadRoute ) Evergreen.V388.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId) (Evergreen.V388.NonemptyDict.NonemptyDict ( Evergreen.V388.Discord.Id Evergreen.V388.Discord.ChannelId, Evergreen.V388.Id.ThreadRoute ) Evergreen.V388.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V388.RichText.Domain
    , emojiConfig : Evergreen.V388.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V388.Id.Id Evergreen.V388.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V388.Id.Id Evergreen.V388.Id.CustomEmojiId)
    , muteSettings : Evergreen.V388.MuteSettings.Model
    , publicKey : Maybe Evergreen.V388.X25519.PublicKey
    , e2eeRisksAccepted : Bool
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V388.PersonName.PersonName
    , color : Evergreen.V388.UserColor.UserColor
    , icon : Maybe Evergreen.V388.FileStatus.FileHash
    , publicKey : Maybe Evergreen.V388.X25519.PublicKey
    }


type alias LocalUser =
    { session : Evergreen.V388.UserSession.UserSession
    , currentlyViewing : Evergreen.V388.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V388.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V388.UserAgent.UserAgent
    , devicePixelRatio : Float
    , safeAreaInsetTop : Int
    , safeAreaInsetBottom : Int
    , stickers : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.StickerId) Evergreen.V388.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.CustomEmojiId) Evergreen.V388.CustomEmoji.CustomEmojiData
    , emojiData : Maybe Evergreen.V388.Emoji.CachedEmojiData
    , decryptedMessages : SeqDict.SeqDict Evergreen.V388.Encryption.BytesHash (Result () (Evergreen.V388.Message.MessageContent (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelId)))
    }
