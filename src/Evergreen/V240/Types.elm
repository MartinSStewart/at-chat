module Evergreen.V240.Types exposing (..)

import Array
import Browser
import Bytes
import Duration
import Effect.Browser.Dom
import Effect.Browser.Events
import Effect.Browser.Navigation
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V240.AiChat
import Evergreen.V240.Call
import Evergreen.V240.ChannelDescription
import Evergreen.V240.ChannelName
import Evergreen.V240.Cloudflare
import Evergreen.V240.Coord
import Evergreen.V240.CssPixels
import Evergreen.V240.CustomEmoji
import Evergreen.V240.Discord
import Evergreen.V240.DiscordAttachmentId
import Evergreen.V240.DiscordUserData
import Evergreen.V240.DmChannel
import Evergreen.V240.Editable
import Evergreen.V240.EmailAddress
import Evergreen.V240.Embed
import Evergreen.V240.Emoji
import Evergreen.V240.FileStatus
import Evergreen.V240.Go
import Evergreen.V240.GuildName
import Evergreen.V240.Id
import Evergreen.V240.ImageEditor
import Evergreen.V240.Local
import Evergreen.V240.LocalState
import Evergreen.V240.Log
import Evergreen.V240.LoginForm
import Evergreen.V240.MembersAndOwner
import Evergreen.V240.Message
import Evergreen.V240.MessageInput
import Evergreen.V240.MessageView
import Evergreen.V240.NonemptyDict
import Evergreen.V240.NonemptySet
import Evergreen.V240.OneToOne
import Evergreen.V240.Pages.Admin
import Evergreen.V240.Pagination
import Evergreen.V240.PersonName
import Evergreen.V240.Ports
import Evergreen.V240.Postmark
import Evergreen.V240.Range
import Evergreen.V240.RichText
import Evergreen.V240.Route
import Evergreen.V240.SecretId
import Evergreen.V240.SessionIdHash
import Evergreen.V240.Slack
import Evergreen.V240.Sticker
import Evergreen.V240.TextEditor
import Evergreen.V240.ToBackendLog
import Evergreen.V240.Touch
import Evergreen.V240.TwoFactorAuthentication
import Evergreen.V240.Ui.Anim
import Evergreen.V240.Untrusted
import Evergreen.V240.User
import Evergreen.V240.UserAgent
import Evergreen.V240.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V240.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V240.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V240.Id.Id Evergreen.V240.Id.GuildId) Evergreen.V240.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V240.Id.Id Evergreen.V240.Id.UserId) Evergreen.V240.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V240.Discord.Id Evergreen.V240.Discord.PrivateChannelId) Evergreen.V240.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V240.Discord.Id Evergreen.V240.Discord.GuildId) Evergreen.V240.LocalState.DiscordFrontendGuild
    , user : Evergreen.V240.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V240.Id.Id Evergreen.V240.Id.UserId) Evergreen.V240.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId) Evergreen.V240.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId) Evergreen.V240.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V240.SessionIdHash.SessionIdHash Evergreen.V240.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V240.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V240.Id.Id Evergreen.V240.Id.StickerId) Evergreen.V240.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V240.Id.Id Evergreen.V240.Id.CustomEmojiId) Evergreen.V240.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V240.Call.RoomId (Evergreen.V240.NonemptySet.NonemptySet ( Evergreen.V240.Id.Id Evergreen.V240.Id.UserId, Effect.Lamdera.ClientId ))
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V240.Route.Route
    , windowSize : Evergreen.V240.Coord.Coord Evergreen.V240.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V240.Ports.NotificationPermission
    , pwaStatus : Evergreen.V240.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V240.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V240.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V240.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V240.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V240.Id.Id Evergreen.V240.FileStatus.FileId) Evergreen.V240.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V240.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V240.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V240.Id.Id Evergreen.V240.FileStatus.FileId) Evergreen.V240.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V240.Id.Id Evergreen.V240.Id.GuildId) Evergreen.V240.ChannelName.ChannelName Evergreen.V240.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V240.Id.Id Evergreen.V240.Id.GuildId) (Evergreen.V240.Id.Id Evergreen.V240.Id.ChannelId) Evergreen.V240.ChannelName.ChannelName Evergreen.V240.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V240.Id.Id Evergreen.V240.Id.GuildId) (Evergreen.V240.Id.Id Evergreen.V240.Id.ChannelId)
    | Local_DeleteGuild (Evergreen.V240.Id.Id Evergreen.V240.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V240.Id.Id Evergreen.V240.Id.GuildId) (Evergreen.V240.UserSession.ToBeFilledInByBackend (Evergreen.V240.SecretId.SecretId Evergreen.V240.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V240.GuildName.GuildName (Evergreen.V240.UserSession.ToBeFilledInByBackend (Evergreen.V240.Id.Id Evergreen.V240.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V240.Id.AnyGuildOrDmId, Evergreen.V240.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V240.Id.AnyGuildOrDmId Evergreen.V240.Id.ThreadRouteWithMessage Evergreen.V240.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V240.Id.AnyGuildOrDmId Evergreen.V240.Id.ThreadRouteWithMessage Evergreen.V240.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V240.Id.GuildOrDmId Evergreen.V240.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V240.Id.Id Evergreen.V240.FileStatus.FileId) Evergreen.V240.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId) (Evergreen.V240.Discord.Id Evergreen.V240.Discord.GuildId) (Evergreen.V240.Discord.Id Evergreen.V240.Discord.ChannelId) Evergreen.V240.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V240.Id.DiscordGuildOrDmId_DmData (Evergreen.V240.Id.Id Evergreen.V240.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V240.Id.AnyGuildOrDmId Evergreen.V240.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V240.Id.AnyGuildOrDmId Evergreen.V240.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V240.Id.AnyGuildOrDmId Evergreen.V240.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V240.UserSession.SetViewing
    | Local_SetName Evergreen.V240.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V240.Id.GuildOrDmId (Evergreen.V240.Id.Id Evergreen.V240.Id.ChannelMessageId) (Evergreen.V240.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V240.Id.Id Evergreen.V240.Id.ChannelMessageId) (Evergreen.V240.Message.Message Evergreen.V240.Id.ChannelMessageId (Evergreen.V240.Id.Id Evergreen.V240.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V240.Id.GuildOrDmId (Evergreen.V240.Id.Id Evergreen.V240.Id.ChannelMessageId) (Evergreen.V240.Id.Id Evergreen.V240.Id.ThreadMessageId) (Evergreen.V240.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V240.Id.Id Evergreen.V240.Id.ThreadMessageId) (Evergreen.V240.Message.Message Evergreen.V240.Id.ThreadMessageId (Evergreen.V240.Id.Id Evergreen.V240.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V240.Id.DiscordGuildOrDmId (Evergreen.V240.Id.Id Evergreen.V240.Id.ChannelMessageId) (Evergreen.V240.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V240.Id.Id Evergreen.V240.Id.ChannelMessageId) (Evergreen.V240.Message.Message Evergreen.V240.Id.ChannelMessageId (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V240.Id.DiscordGuildOrDmId (Evergreen.V240.Id.Id Evergreen.V240.Id.ChannelMessageId) (Evergreen.V240.Id.Id Evergreen.V240.Id.ThreadMessageId) (Evergreen.V240.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V240.Id.Id Evergreen.V240.Id.ThreadMessageId) (Evergreen.V240.Message.Message Evergreen.V240.Id.ThreadMessageId (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V240.Id.Id Evergreen.V240.Id.GuildId) Evergreen.V240.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId) (Evergreen.V240.Discord.Id Evergreen.V240.Discord.GuildId) Evergreen.V240.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V240.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V240.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V240.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V240.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V240.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V240.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V240.NonemptySet.NonemptySet (Evergreen.V240.Id.Id Evergreen.V240.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V240.Call.LocalChange
    | Local_Go
        { otherUserId : Evergreen.V240.Id.Id Evergreen.V240.Id.UserId
        }
        Evergreen.V240.Go.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V240.Id.Id Evergreen.V240.Id.UserId) Effect.Time.Posix Evergreen.V240.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V240.RichText.RichText (Evergreen.V240.Id.Id Evergreen.V240.Id.UserId))) Evergreen.V240.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V240.Id.Id Evergreen.V240.FileStatus.FileId) Evergreen.V240.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V240.Id.Id Evergreen.V240.Id.StickerId) Evergreen.V240.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V240.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V240.RichText.RichText (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId))) Evergreen.V240.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V240.Id.Id Evergreen.V240.FileStatus.FileId) Evergreen.V240.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V240.Id.Id Evergreen.V240.Id.StickerId) Evergreen.V240.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V240.Id.Id Evergreen.V240.Id.GuildId) Evergreen.V240.ChannelName.ChannelName Evergreen.V240.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V240.Id.Id Evergreen.V240.Id.GuildId) (Evergreen.V240.Id.Id Evergreen.V240.Id.ChannelId) Evergreen.V240.ChannelName.ChannelName Evergreen.V240.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V240.Id.Id Evergreen.V240.Id.GuildId) (Evergreen.V240.Id.Id Evergreen.V240.Id.ChannelId)
    | Server_DeleteGuild (Evergreen.V240.Id.Id Evergreen.V240.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V240.Id.Id Evergreen.V240.Id.UserId) (Evergreen.V240.Id.Id Evergreen.V240.Id.GuildId) (Evergreen.V240.SecretId.SecretId Evergreen.V240.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V240.Id.Id Evergreen.V240.Id.UserId) (Evergreen.V240.Id.Id Evergreen.V240.Id.GuildId) Evergreen.V240.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V240.LocalState.JoinGuildError
            { guildId : Evergreen.V240.Id.Id Evergreen.V240.Id.GuildId
            , guild : Evergreen.V240.LocalState.FrontendGuild
            , owner : Evergreen.V240.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V240.Id.Id Evergreen.V240.Id.UserId) Evergreen.V240.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V240.Id.Id Evergreen.V240.Id.UserId) Evergreen.V240.Id.GuildOrDmId Evergreen.V240.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId) (Evergreen.V240.Discord.Id Evergreen.V240.Discord.GuildId) (Evergreen.V240.Discord.Id Evergreen.V240.Discord.ChannelId) Evergreen.V240.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId) (Evergreen.V240.Discord.Id Evergreen.V240.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V240.Id.Id Evergreen.V240.Id.UserId) Evergreen.V240.Id.GuildOrDmId Evergreen.V240.Id.ThreadRouteWithMessage Evergreen.V240.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V240.Id.Id Evergreen.V240.Id.UserId) Evergreen.V240.Id.GuildOrDmId Evergreen.V240.Id.ThreadRouteWithMessage Evergreen.V240.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId) (Evergreen.V240.Discord.Id Evergreen.V240.Discord.GuildId) (Evergreen.V240.Discord.Id Evergreen.V240.Discord.ChannelId) Evergreen.V240.Id.ThreadRouteWithMessage Evergreen.V240.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId) (Evergreen.V240.Discord.Id Evergreen.V240.Discord.PrivateChannelId) (Evergreen.V240.Id.Id Evergreen.V240.Id.ChannelMessageId) Evergreen.V240.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId) (Evergreen.V240.Discord.Id Evergreen.V240.Discord.GuildId) (Evergreen.V240.Discord.Id Evergreen.V240.Discord.ChannelId) Evergreen.V240.Id.ThreadRouteWithMessage Evergreen.V240.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId) (Evergreen.V240.Discord.Id Evergreen.V240.Discord.PrivateChannelId) (Evergreen.V240.Id.Id Evergreen.V240.Id.ChannelMessageId) Evergreen.V240.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V240.Id.Id Evergreen.V240.Id.UserId) Evergreen.V240.Id.GuildOrDmId Evergreen.V240.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V240.RichText.RichText (Evergreen.V240.Id.Id Evergreen.V240.Id.UserId))) (SeqDict.SeqDict (Evergreen.V240.Id.Id Evergreen.V240.FileStatus.FileId) Evergreen.V240.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId) (Evergreen.V240.Discord.Id Evergreen.V240.Discord.GuildId) (Evergreen.V240.Discord.Id Evergreen.V240.Discord.ChannelId) Evergreen.V240.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V240.RichText.RichText (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V240.Id.DiscordGuildOrDmId_DmData (Evergreen.V240.Id.Id Evergreen.V240.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V240.RichText.RichText (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V240.Id.Id Evergreen.V240.Id.UserId) Evergreen.V240.Id.AnyGuildOrDmId Evergreen.V240.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V240.Id.AnyGuildOrDmId Evergreen.V240.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V240.Discord.Id Evergreen.V240.Discord.GuildId) (Evergreen.V240.Discord.Id Evergreen.V240.Discord.ChannelId) Evergreen.V240.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V240.Discord.Id Evergreen.V240.Discord.PrivateChannelId) (Evergreen.V240.Id.Id Evergreen.V240.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V240.Id.Id Evergreen.V240.Id.UserId) Evergreen.V240.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V240.Id.Id Evergreen.V240.Id.UserId) Evergreen.V240.FileStatus.FileHash
    | Server_SetGuildIcon (Evergreen.V240.Id.Id Evergreen.V240.Id.GuildId) Evergreen.V240.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V240.Id.Id Evergreen.V240.Id.GuildId) Evergreen.V240.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V240.Discord.Id Evergreen.V240.Discord.GuildId) Evergreen.V240.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V240.SessionIdHash.SessionIdHash Evergreen.V240.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V240.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V240.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V240.Id.AnyGuildOrDmId, Evergreen.V240.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V240.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId) Evergreen.V240.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V240.Discord.Id Evergreen.V240.Discord.GuildId) (Evergreen.V240.Discord.Id Evergreen.V240.Discord.ChannelId) Evergreen.V240.ChannelName.ChannelName (Evergreen.V240.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V240.Discord.Id Evergreen.V240.Discord.PrivateChannelId)
        (Evergreen.V240.NonemptyDict.NonemptyDict
            (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V240.Discord.Id Evergreen.V240.Discord.GuildId) Evergreen.V240.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V240.Discord.Id Evergreen.V240.Discord.PrivateChannelId) Evergreen.V240.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId) Evergreen.V240.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId) (Maybe (Evergreen.V240.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V240.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V240.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V240.Id.Id Evergreen.V240.Id.GuildId) (Evergreen.V240.Id.Id Evergreen.V240.Id.ChannelId) Evergreen.V240.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V240.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V240.Id.Id Evergreen.V240.Id.UserId) Evergreen.V240.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V240.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V240.Discord.Id Evergreen.V240.Discord.GuildId) (Evergreen.V240.Discord.Id Evergreen.V240.Discord.ChannelId) Evergreen.V240.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V240.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V240.Discord.Id Evergreen.V240.Discord.PrivateChannelId) (Evergreen.V240.Id.Id Evergreen.V240.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V240.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V240.Discord.Id Evergreen.V240.Discord.GuildId) Evergreen.V240.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V240.Discord.Id Evergreen.V240.Discord.GuildId) (Evergreen.V240.Discord.Id Evergreen.V240.Discord.ChannelId) (Evergreen.V240.Discord.OptionalData String) (Evergreen.V240.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V240.Discord.Id Evergreen.V240.Discord.GuildId)
        (Evergreen.V240.MembersAndOwner.MembersAndOwner
            (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V240.Discord.Id Evergreen.V240.Discord.GuildId) (Evergreen.V240.Discord.Id Evergreen.V240.Discord.ChannelId) (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId) Evergreen.V240.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V240.Id.Id Evergreen.V240.Id.StickerId) Evergreen.V240.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V240.Id.Id Evergreen.V240.Id.CustomEmojiId) Evergreen.V240.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V240.Call.ServerChange
    | Server_Go
        (Evergreen.V240.Id.Id Evergreen.V240.Id.UserId)
        { otherUserId : Evergreen.V240.Id.Id Evergreen.V240.Id.UserId
        }
        Evergreen.V240.Go.LocalChange


type LocalMsg
    = LocalChange (Evergreen.V240.Id.Id Evergreen.V240.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias NewChannelForm =
    { name : String
    , description : String
    , pressedSubmit : Bool
    }


type alias EditChannelForm =
    { name : String
    , description : String
    , deleteConfirmation : String
    , showDeleteConfirmation : Bool
    , pressedSubmit : Bool
    }


type alias EditGuildForm =
    { deleteConfirmation : String
    , showDeleteConfirmation : Bool
    }


type alias NewGuildForm =
    { name : String
    , pressedSubmit : Bool
    }


type GuildChannelNameHover
    = NoChannelNameHover
    | GuildChannelNameHover (Evergreen.V240.Id.Id Evergreen.V240.Id.GuildId) (Evergreen.V240.Id.Id Evergreen.V240.Id.ChannelId) Evergreen.V240.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V240.Discord.Id Evergreen.V240.Discord.GuildId) (Evergreen.V240.Discord.Id Evergreen.V240.Discord.ChannelId) Evergreen.V240.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V240.Id.Id Evergreen.V240.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V240.Id.Id Evergreen.V240.FileStatus.FileId) Evergreen.V240.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V240.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V240.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V240.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V240.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V240.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V240.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V240.Coord.Coord Evergreen.V240.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V240.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V240.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V240.Id.AnyGuildOrDmId Evergreen.V240.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V240.Id.AnyGuildOrDmId Evergreen.V240.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V240.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V240.Coord.Coord Evergreen.V240.CssPixels.CssPixels) (Maybe Evergreen.V240.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V240.Id.AnyGuildOrDmId, Evergreen.V240.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V240.Id.Id Evergreen.V240.Id.ChannelMessageId) (Evergreen.V240.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V240.Id.Id Evergreen.V240.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V240.Id.Id Evergreen.V240.Id.ThreadMessageId) (Evergreen.V240.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V240.Editable.Model
    , showLinkDiscordSetup : Bool
    , domainWhitelistInput : String
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V240.Local.Local LocalMsg Evergreen.V240.LocalState.LocalState
    , admin : Evergreen.V240.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V240.Id.AnyGuildOrDmId, Evergreen.V240.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V240.Id.Id Evergreen.V240.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V240.Id.Id Evergreen.V240.Id.GuildId, Evergreen.V240.Id.Id Evergreen.V240.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V240.Id.Id Evergreen.V240.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V240.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V240.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V240.Id.AnyGuildOrDmId, Evergreen.V240.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V240.Id.AnyGuildOrDmId, Evergreen.V240.Id.ThreadRoute ) (Evergreen.V240.Id.Id Evergreen.V240.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : Evergreen.V240.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V240.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V240.Id.AnyGuildOrDmId, Evergreen.V240.Id.ThreadRoute ) (Evergreen.V240.NonemptyDict.NonemptyDict (Evergreen.V240.Id.Id Evergreen.V240.FileStatus.FileId) Evergreen.V240.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V240.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V240.TextEditor.Model
    , profilePictureEditor : Evergreen.V240.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V240.Id.Id Evergreen.V240.Id.GuildId, Evergreen.V240.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V240.Emoji.Model
    , voiceChat : Evergreen.V240.Call.Model
    , currentDmGoMatch : SeqDict.SeqDict ( Evergreen.V240.Id.Id Evergreen.V240.Id.UserId, Maybe (Evergreen.V240.Id.Id Evergreen.V240.Id.ChannelMessageId) ) Evergreen.V240.Go.Model
    , fileDragOverCount : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V240.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V240.SecretId.SecretId Evergreen.V240.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V240.Range.Range
                , direction : Evergreen.V240.Range.SelectionDirection
                }
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V240.NonemptyDict.NonemptyDict Int Evergreen.V240.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V240.NonemptyDict.NonemptyDict Int Evergreen.V240.Touch.Touch
        }


type LoginResult
    = LoginSuccess LoginData
    | LoginTokenInvalid Int
    | NeedsTwoFactorToken
    | NeedsAccountSetup


type ToFrontend
    = CheckLoginResponse (Result () LoginData)
    | LoginWithTokenResponse LoginResult
    | GetLoginTokenRateLimited
    | SignupsDisabledResponse
    | LoggedOutSession
    | AdminToFrontend Evergreen.V240.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V240.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V240.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V240.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V240.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V240.ImageEditor.ToFrontend


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V240.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V240.Coord.Coord Evergreen.V240.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V240.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , notificationPermission : Evergreen.V240.Ports.NotificationPermission
    , pwaStatus : Evergreen.V240.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V240.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V240.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V240.Emoji.CachedEmojiData
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V240.Id.Id Evergreen.V240.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V240.Id.Id Evergreen.V240.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V240.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V240.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V240.Coord.Coord Evergreen.V240.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V240.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V240.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V240.Id.Id Evergreen.V240.Id.GuildId, Evergreen.V240.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V240.DmChannel.DmChannelId, Evergreen.V240.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V240.Discord.Id Evergreen.V240.Discord.GuildId, Evergreen.V240.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V240.Discord.Id Evergreen.V240.Discord.PrivateChannelId, Evergreen.V240.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V240.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V240.NonemptyDict.NonemptyDict (Evergreen.V240.Id.Id Evergreen.V240.Id.UserId) Evergreen.V240.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V240.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V240.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V240.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V240.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V240.Id.Id Evergreen.V240.Id.UserId) Evergreen.V240.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V240.Id.Id Evergreen.V240.Id.UserId) Evergreen.V240.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V240.Id.Id Evergreen.V240.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V240.Id.Id Evergreen.V240.Id.GuildId) Evergreen.V240.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V240.Id.Id Evergreen.V240.Id.GuildId) Evergreen.V240.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V240.Discord.Id Evergreen.V240.Discord.GuildId) Evergreen.V240.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V240.DmChannel.DmChannelId Evergreen.V240.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V240.Discord.Id Evergreen.V240.Discord.PrivateChannelId) Evergreen.V240.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V240.OneToOne.OneToOne (Evergreen.V240.Slack.Id Evergreen.V240.Slack.ChannelId) Evergreen.V240.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V240.OneToOne.OneToOne String (Evergreen.V240.Id.Id Evergreen.V240.Id.GuildId)
    , slackUsers : Evergreen.V240.OneToOne.OneToOne (Evergreen.V240.Slack.Id Evergreen.V240.Slack.UserId) (Evergreen.V240.Id.Id Evergreen.V240.Id.UserId)
    , slackServers : Evergreen.V240.OneToOne.OneToOne (Evergreen.V240.Slack.Id Evergreen.V240.Slack.TeamId) (Evergreen.V240.Id.Id Evergreen.V240.Id.GuildId)
    , slackToken : Maybe Evergreen.V240.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V240.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V240.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V240.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareTurnApiToken : Maybe String
    , textEditor : Evergreen.V240.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId) Evergreen.V240.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId, Evergreen.V240.Discord.Id Evergreen.V240.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V240.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V240.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V240.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V240.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId) (Evergreen.V240.LocalState.LoadingDiscordChannel (List Evergreen.V240.Discord.Message))
    , signupsEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V240.Id.Id Evergreen.V240.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V240.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V240.Id.Id Evergreen.V240.Id.StickerId) Evergreen.V240.Sticker.StickerData
    , discordStickers : Evergreen.V240.OneToOne.OneToOne (Evergreen.V240.Discord.Id Evergreen.V240.Discord.StickerId) (Evergreen.V240.Id.Id Evergreen.V240.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V240.Id.Id Evergreen.V240.Id.CustomEmojiId) Evergreen.V240.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V240.OneToOne.OneToOne Evergreen.V240.RichText.DiscordCustomEmojiIdAndName (Evergreen.V240.Id.Id Evergreen.V240.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V240.Postmark.ApiKey
    , serverSecret : Evergreen.V240.SecretId.SecretId Evergreen.V240.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V240.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V240.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V240.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V240.Route.Route
    | SelectedFilesToAttach ( Evergreen.V240.Id.AnyGuildOrDmId, Evergreen.V240.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V240.Id.Id Evergreen.V240.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V240.Id.Id Evergreen.V240.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V240.Id.Id Evergreen.V240.Id.GuildId) (Evergreen.V240.Id.Id Evergreen.V240.Id.ChannelId) Evergreen.V240.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V240.Id.Id Evergreen.V240.Id.GuildId) (Evergreen.V240.Id.Id Evergreen.V240.Id.ChannelId) Evergreen.V240.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V240.Discord.Id Evergreen.V240.Discord.GuildId) (Evergreen.V240.Discord.Id Evergreen.V240.Discord.ChannelId) Evergreen.V240.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V240.Discord.Id Evergreen.V240.Discord.GuildId) (Evergreen.V240.Discord.Id Evergreen.V240.Discord.ChannelId) Evergreen.V240.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V240.Id.Id Evergreen.V240.Id.GuildId) (Evergreen.V240.Id.Id Evergreen.V240.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V240.Id.Id Evergreen.V240.Id.GuildId) (Evergreen.V240.Id.Id Evergreen.V240.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V240.Id.Id Evergreen.V240.Id.GuildId) (Evergreen.V240.Id.Id Evergreen.V240.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V240.Id.Id Evergreen.V240.Id.GuildId) (Evergreen.V240.Id.Id Evergreen.V240.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V240.Id.Id Evergreen.V240.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V240.Id.Id Evergreen.V240.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V240.Id.Id Evergreen.V240.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V240.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V240.Id.AnyGuildOrDmId Evergreen.V240.Id.ThreadRouteWithMessage (Evergreen.V240.Coord.Coord Evergreen.V240.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V240.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V240.Id.AnyGuildOrDmId Evergreen.V240.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V240.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V240.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V240.Id.Id Evergreen.V240.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V240.Id.AnyGuildOrDmId, Evergreen.V240.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V240.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V240.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V240.Id.AnyGuildOrDmId, Evergreen.V240.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V240.NonemptyDict.NonemptyDict Int Evergreen.V240.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V240.NonemptyDict.NonemptyDict Int Evergreen.V240.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V240.Id.AnyGuildOrDmId Evergreen.V240.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V240.Id.AnyGuildOrDmId Evergreen.V240.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V240.NonemptySet.NonemptySet (Evergreen.V240.Id.Id Evergreen.V240.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V240.Id.AnyGuildOrDmId, Evergreen.V240.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V240.Id.AnyGuildOrDmId Evergreen.V240.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V240.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V240.AiChat.Msg
    | GoMsg Evergreen.V240.Go.Msg
    | UserNameEditableMsg (Evergreen.V240.Editable.Msg Evergreen.V240.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V240.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V240.Id.Id Evergreen.V240.Id.GuildId) Evergreen.V240.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V240.Id.AnyGuildOrDmId, Evergreen.V240.Id.ThreadRoute ) (Evergreen.V240.Id.Id Evergreen.V240.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V240.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V240.Id.AnyGuildOrDmId, Evergreen.V240.Id.ThreadRoute ) (Evergreen.V240.Id.Id Evergreen.V240.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V240.Id.AnyGuildOrDmId, Evergreen.V240.Id.ThreadRoute ) (Evergreen.V240.Id.Id Evergreen.V240.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V240.Id.AnyGuildOrDmId, Evergreen.V240.Id.ThreadRoute )
        { fileId : Evergreen.V240.Id.Id Evergreen.V240.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V240.Id.AnyGuildOrDmId, Evergreen.V240.Id.ThreadRoute ) (Evergreen.V240.Id.Id Evergreen.V240.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V240.Id.AnyGuildOrDmId, Evergreen.V240.Id.ThreadRoute ) (Evergreen.V240.Id.Id Evergreen.V240.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V240.Id.AnyGuildOrDmId, Evergreen.V240.Id.ThreadRoute )
        { fileId : Evergreen.V240.Id.Id Evergreen.V240.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V240.Id.AnyGuildOrDmId, Evergreen.V240.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V240.Id.AnyGuildOrDmId, Evergreen.V240.Id.ThreadRoute ) (Evergreen.V240.Id.Id Evergreen.V240.Id.ChannelMessageId) (Evergreen.V240.Id.Id Evergreen.V240.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V240.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V240.Id.AnyGuildOrDmId, Evergreen.V240.Id.ThreadRoute ) (Evergreen.V240.Id.Id Evergreen.V240.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V240.Id.AnyGuildOrDmId Evergreen.V240.Id.ThreadRouteWithMessage Evergreen.V240.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V240.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V240.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V240.Id.Id Evergreen.V240.Id.GuildId) Evergreen.V240.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId) (Evergreen.V240.Discord.Id Evergreen.V240.Discord.GuildId) Evergreen.V240.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V240.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V240.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId
        , otherUserId : Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V240.Id.AnyGuildOrDmId Evergreen.V240.Id.ThreadRoute Evergreen.V240.MessageInput.Msg
    | MessageInputMsg Evergreen.V240.Id.AnyGuildOrDmId Evergreen.V240.Id.ThreadRoute Evergreen.V240.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V240.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V240.Range.Range, Evergreen.V240.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V240.Range.Range, Evergreen.V240.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V240.Call.FromJs)
    | VoiceChatMsg Evergreen.V240.Call.Msg
    | PressedChannelHeaderTab Evergreen.V240.Route.DmChannelHeaderTab
    | FileDragEnter
    | FileDragLeave
    | FileDropped (List Effect.File.File)


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V240.Id.Id Evergreen.V240.Id.GuildId) (Evergreen.V240.Id.Id Evergreen.V240.Id.ChannelId) Evergreen.V240.Id.ThreadRoute
    | InitialLoadRequested_Dm Evergreen.V240.DmChannel.DmChannelId Evergreen.V240.Id.ThreadRoute
    | InitialLoadRequested_Discord Evergreen.V240.Id.DiscordGuildOrDmId Evergreen.V240.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V240.Id.Id Evergreen.V240.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V240.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V240.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V240.Untrusted.Untrusted Evergreen.V240.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V240.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V240.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V240.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V240.Id.Id Evergreen.V240.Id.GuildId) (Evergreen.V240.SecretId.SecretId Evergreen.V240.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V240.PersonName.PersonName Evergreen.V240.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V240.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V240.Slack.OAuthCode Evergreen.V240.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V240.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V240.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V240.Id.Id Evergreen.V240.Pagination.PageId))


type alias PendingVoiceChatJoin =
    { sessionId : Effect.Lamdera.SessionId
    , clientId : Effect.Lamdera.ClientId
    , changeId : Evergreen.V240.Local.ChangeId
    , time : Effect.Time.Posix
    , userId : Evergreen.V240.Id.Id Evergreen.V240.Id.UserId
    , otherUserId : Evergreen.V240.Id.Id Evergreen.V240.Id.UserId
    , dmChannelId : Evergreen.V240.DmChannel.DmChannelId
    , roomId : Evergreen.V240.Call.RoomId
    }


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V240.Discord.Id Evergreen.V240.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V240.Discord.Id Evergreen.V240.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V240.EmailAddress.EmailAddress (Result Evergreen.V240.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V240.EmailAddress.EmailAddress (Result Evergreen.V240.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId) Evergreen.V240.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V240.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V240.Discord.Id Evergreen.V240.Discord.GuildId) (Evergreen.V240.Discord.Id Evergreen.V240.Discord.ChannelId) Evergreen.V240.Id.ThreadRouteWithMaybeMessage (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId) (Result Evergreen.V240.Discord.HttpError Evergreen.V240.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V240.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V240.Discord.Id Evergreen.V240.Discord.PrivateChannelId) (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId) (Result Evergreen.V240.Discord.HttpError Evergreen.V240.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V240.Discord.Id Evergreen.V240.Discord.GuildId) (Evergreen.V240.Discord.Id Evergreen.V240.Discord.ChannelId) Evergreen.V240.Id.ThreadRouteWithMessage (Evergreen.V240.Discord.Id Evergreen.V240.Discord.MessageId) (Result Evergreen.V240.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V240.Discord.Id Evergreen.V240.Discord.PrivateChannelId) (Evergreen.V240.Id.Id Evergreen.V240.Id.ChannelMessageId) (Evergreen.V240.Discord.Id Evergreen.V240.Discord.MessageId) (Result Evergreen.V240.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V240.Discord.Id Evergreen.V240.Discord.GuildId) (Evergreen.V240.Discord.Id Evergreen.V240.Discord.ChannelId) Evergreen.V240.Id.ThreadRouteWithMessage (Evergreen.V240.Discord.Id Evergreen.V240.Discord.MessageId) (Result Evergreen.V240.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V240.Discord.Id Evergreen.V240.Discord.PrivateChannelId) (Evergreen.V240.Id.Id Evergreen.V240.Id.ChannelMessageId) (Evergreen.V240.Discord.Id Evergreen.V240.Discord.MessageId) (Result Evergreen.V240.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V240.Discord.Id Evergreen.V240.Discord.GuildId) (Evergreen.V240.Discord.Id Evergreen.V240.Discord.ChannelId) Evergreen.V240.Id.ThreadRouteWithMessage (Evergreen.V240.Discord.Id Evergreen.V240.Discord.MessageId) Evergreen.V240.Emoji.EmojiOrCustomEmoji (Result Evergreen.V240.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V240.Discord.Id Evergreen.V240.Discord.PrivateChannelId) (Evergreen.V240.Id.Id Evergreen.V240.Id.ChannelMessageId) (Evergreen.V240.Discord.Id Evergreen.V240.Discord.MessageId) Evergreen.V240.Emoji.EmojiOrCustomEmoji (Result Evergreen.V240.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V240.Discord.Id Evergreen.V240.Discord.GuildId) (Evergreen.V240.Discord.Id Evergreen.V240.Discord.ChannelId) Evergreen.V240.Id.ThreadRouteWithMessage (Evergreen.V240.Discord.Id Evergreen.V240.Discord.MessageId) Evergreen.V240.Emoji.EmojiOrCustomEmoji (Result Evergreen.V240.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V240.Discord.Id Evergreen.V240.Discord.PrivateChannelId) (Evergreen.V240.Id.Id Evergreen.V240.Id.ChannelMessageId) (Evergreen.V240.Discord.Id Evergreen.V240.Discord.MessageId) Evergreen.V240.Emoji.EmojiOrCustomEmoji (Result Evergreen.V240.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V240.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V240.Discord.HttpError (List ( Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId, Maybe Evergreen.V240.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V240.Id.Id Evergreen.V240.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V240.Id.Id Evergreen.V240.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V240.Slack.CurrentUser
            , team : Evergreen.V240.Slack.Team
            , users : List Evergreen.V240.Slack.User
            , channels : List ( Evergreen.V240.Slack.Channel, List Evergreen.V240.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V240.Id.Id Evergreen.V240.Id.UserId) (Result Effect.Http.Error Evergreen.V240.Slack.TokenResponse)
    | GotCloudflareTurnCredentials PendingVoiceChatJoin (Result Effect.Http.Error (List Evergreen.V240.Cloudflare.TurnConfig))
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V240.Id.Id Evergreen.V240.Id.UserId) Evergreen.V240.Discord.UserAuth (Result Evergreen.V240.Discord.HttpError Evergreen.V240.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V240.Id.Id Evergreen.V240.Id.UserId) (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId) (Result Evergreen.V240.Discord.HttpError Evergreen.V240.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId)
        (Result
            Evergreen.V240.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V240.Discord.Id Evergreen.V240.Discord.PrivateChannelId
                , members : List (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId)
                }
            , List
                ( Evergreen.V240.Discord.Id Evergreen.V240.Discord.GuildId
                , { guild : Evergreen.V240.Discord.GatewayGuild
                  , channels : List Evergreen.V240.Discord.Channel
                  , icon : Maybe Evergreen.V240.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId) Bool
    | WebsocketSentDataForUser (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V240.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V240.Discord.Id Evergreen.V240.Discord.AttachmentId, Evergreen.V240.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V240.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V240.Discord.Id Evergreen.V240.Discord.AttachmentId, Evergreen.V240.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId) (Evergreen.V240.Discord.Id Evergreen.V240.Discord.GuildId) (Evergreen.V240.Discord.Id Evergreen.V240.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V240.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V240.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId) (Evergreen.V240.Discord.Id Evergreen.V240.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V240.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V240.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId) (Evergreen.V240.Discord.Id Evergreen.V240.Discord.GuildId) (Evergreen.V240.Discord.Id Evergreen.V240.Discord.ChannelId) (Result Evergreen.V240.Discord.HttpError (List Evergreen.V240.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId) (Evergreen.V240.Discord.Id Evergreen.V240.Discord.PrivateChannelId) (Result Evergreen.V240.Discord.HttpError (List Evergreen.V240.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V240.Id.Id Evergreen.V240.Id.GuildId) (Evergreen.V240.Id.Id Evergreen.V240.Id.ChannelId) Evergreen.V240.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V240.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V240.DmChannel.DmChannelId Evergreen.V240.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V240.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V240.Discord.Id Evergreen.V240.Discord.GuildId) (Evergreen.V240.Discord.Id Evergreen.V240.Discord.ChannelId) Evergreen.V240.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V240.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V240.Discord.Id Evergreen.V240.Discord.PrivateChannelId) (Evergreen.V240.Id.Id Evergreen.V240.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V240.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId)
        (Evergreen.V240.Discord.Id Evergreen.V240.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V240.Discord.HttpError
            { guild : Evergreen.V240.Discord.GatewayGuild
            , channels : List Evergreen.V240.Discord.Channel
            , icon : Maybe Evergreen.V240.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V240.Discord.Id Evergreen.V240.Discord.GuildId) (Result Evergreen.V240.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V240.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V240.Id.Id Evergreen.V240.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V240.Id.Id Evergreen.V240.Id.UserId) (List ( Evergreen.V240.Id.Id Evergreen.V240.Id.StickerId, Result Effect.Http.Error Evergreen.V240.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V240.Id.Id Evergreen.V240.Id.StickerId, Result Effect.Http.Error Evergreen.V240.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V240.Id.Id Evergreen.V240.Id.UserId) (List ( Evergreen.V240.Id.Id Evergreen.V240.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V240.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V240.Id.Id Evergreen.V240.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V240.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V240.Discord.HttpError (List Evergreen.V240.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V240.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V240.SecretId.SecretId Evergreen.V240.SecretId.ServerSecret))
