module Evergreen.V242.Types exposing (..)

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
import Evergreen.V242.AiChat
import Evergreen.V242.Call
import Evergreen.V242.ChannelDescription
import Evergreen.V242.ChannelName
import Evergreen.V242.Cloudflare
import Evergreen.V242.Coord
import Evergreen.V242.CssPixels
import Evergreen.V242.CustomEmoji
import Evergreen.V242.Discord
import Evergreen.V242.DiscordAttachmentId
import Evergreen.V242.DiscordUserData
import Evergreen.V242.DmChannel
import Evergreen.V242.Editable
import Evergreen.V242.EmailAddress
import Evergreen.V242.Embed
import Evergreen.V242.Emoji
import Evergreen.V242.FileStatus
import Evergreen.V242.Go
import Evergreen.V242.GuildName
import Evergreen.V242.Id
import Evergreen.V242.ImageEditor
import Evergreen.V242.Local
import Evergreen.V242.LocalState
import Evergreen.V242.Log
import Evergreen.V242.LoginForm
import Evergreen.V242.MembersAndOwner
import Evergreen.V242.Message
import Evergreen.V242.MessageInput
import Evergreen.V242.MessageView
import Evergreen.V242.NonemptyDict
import Evergreen.V242.NonemptySet
import Evergreen.V242.OneToOne
import Evergreen.V242.Pages.Admin
import Evergreen.V242.Pagination
import Evergreen.V242.PersonName
import Evergreen.V242.Ports
import Evergreen.V242.Postmark
import Evergreen.V242.Range
import Evergreen.V242.RichText
import Evergreen.V242.Route
import Evergreen.V242.SecretId
import Evergreen.V242.SessionIdHash
import Evergreen.V242.Slack
import Evergreen.V242.Sticker
import Evergreen.V242.TextEditor
import Evergreen.V242.ToBackendLog
import Evergreen.V242.Touch
import Evergreen.V242.TwoFactorAuthentication
import Evergreen.V242.Ui.Anim
import Evergreen.V242.Untrusted
import Evergreen.V242.User
import Evergreen.V242.UserAgent
import Evergreen.V242.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V242.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V242.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.Id.GuildId) Evergreen.V242.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId) Evergreen.V242.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V242.Discord.Id Evergreen.V242.Discord.PrivateChannelId) Evergreen.V242.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V242.Discord.Id Evergreen.V242.Discord.GuildId) Evergreen.V242.LocalState.DiscordFrontendGuild
    , user : Evergreen.V242.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId) Evergreen.V242.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId) Evergreen.V242.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId) Evergreen.V242.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V242.SessionIdHash.SessionIdHash Evergreen.V242.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V242.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.Id.StickerId) Evergreen.V242.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.Id.CustomEmojiId) Evergreen.V242.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V242.Call.RoomId (Evergreen.V242.NonemptySet.NonemptySet ( Evergreen.V242.Id.Id Evergreen.V242.Id.UserId, Effect.Lamdera.ClientId ))
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V242.Route.Route
    , windowSize : Evergreen.V242.Coord.Coord Evergreen.V242.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V242.Ports.NotificationPermission
    , pwaStatus : Evergreen.V242.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V242.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V242.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V242.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V242.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.FileStatus.FileId) Evergreen.V242.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V242.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V242.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.FileStatus.FileId) Evergreen.V242.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V242.Id.Id Evergreen.V242.Id.GuildId) Evergreen.V242.ChannelName.ChannelName Evergreen.V242.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V242.Id.Id Evergreen.V242.Id.GuildId) (Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelId) Evergreen.V242.ChannelName.ChannelName Evergreen.V242.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V242.Id.Id Evergreen.V242.Id.GuildId) (Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelId)
    | Local_DeleteGuild (Evergreen.V242.Id.Id Evergreen.V242.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V242.Id.Id Evergreen.V242.Id.GuildId) (Evergreen.V242.UserSession.ToBeFilledInByBackend (Evergreen.V242.SecretId.SecretId Evergreen.V242.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V242.GuildName.GuildName (Evergreen.V242.UserSession.ToBeFilledInByBackend (Evergreen.V242.Id.Id Evergreen.V242.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V242.Id.AnyGuildOrDmId, Evergreen.V242.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V242.Id.AnyGuildOrDmId Evergreen.V242.Id.ThreadRouteWithMessage Evergreen.V242.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V242.Id.AnyGuildOrDmId Evergreen.V242.Id.ThreadRouteWithMessage Evergreen.V242.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V242.Id.GuildOrDmId Evergreen.V242.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.FileStatus.FileId) Evergreen.V242.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId) (Evergreen.V242.Discord.Id Evergreen.V242.Discord.GuildId) (Evergreen.V242.Discord.Id Evergreen.V242.Discord.ChannelId) Evergreen.V242.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V242.Id.DiscordGuildOrDmId_DmData (Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V242.Id.AnyGuildOrDmId Evergreen.V242.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V242.Id.AnyGuildOrDmId Evergreen.V242.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V242.Id.AnyGuildOrDmId Evergreen.V242.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V242.UserSession.SetViewing
    | Local_SetName Evergreen.V242.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V242.Id.GuildOrDmId (Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelMessageId) (Evergreen.V242.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelMessageId) (Evergreen.V242.Message.Message Evergreen.V242.Id.ChannelMessageId (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V242.Id.GuildOrDmId (Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelMessageId) (Evergreen.V242.Id.Id Evergreen.V242.Id.ThreadMessageId) (Evergreen.V242.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.Id.ThreadMessageId) (Evergreen.V242.Message.Message Evergreen.V242.Id.ThreadMessageId (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V242.Id.DiscordGuildOrDmId (Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelMessageId) (Evergreen.V242.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelMessageId) (Evergreen.V242.Message.Message Evergreen.V242.Id.ChannelMessageId (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V242.Id.DiscordGuildOrDmId (Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelMessageId) (Evergreen.V242.Id.Id Evergreen.V242.Id.ThreadMessageId) (Evergreen.V242.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.Id.ThreadMessageId) (Evergreen.V242.Message.Message Evergreen.V242.Id.ThreadMessageId (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V242.Id.Id Evergreen.V242.Id.GuildId) Evergreen.V242.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId) (Evergreen.V242.Discord.Id Evergreen.V242.Discord.GuildId) Evergreen.V242.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V242.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V242.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V242.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V242.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V242.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V242.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V242.NonemptySet.NonemptySet (Evergreen.V242.Id.Id Evergreen.V242.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V242.Call.LocalChange
    | Local_Go
        { otherUserId : Evergreen.V242.Id.Id Evergreen.V242.Id.UserId
        }
        Evergreen.V242.Go.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId) Effect.Time.Posix Evergreen.V242.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V242.RichText.RichText (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId))) Evergreen.V242.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.FileStatus.FileId) Evergreen.V242.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.Id.StickerId) Evergreen.V242.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V242.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V242.RichText.RichText (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId))) Evergreen.V242.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.FileStatus.FileId) Evergreen.V242.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.Id.StickerId) Evergreen.V242.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V242.Id.Id Evergreen.V242.Id.GuildId) Evergreen.V242.ChannelName.ChannelName Evergreen.V242.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V242.Id.Id Evergreen.V242.Id.GuildId) (Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelId) Evergreen.V242.ChannelName.ChannelName Evergreen.V242.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V242.Id.Id Evergreen.V242.Id.GuildId) (Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelId)
    | Server_DeleteGuild (Evergreen.V242.Id.Id Evergreen.V242.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId) (Evergreen.V242.Id.Id Evergreen.V242.Id.GuildId) (Evergreen.V242.SecretId.SecretId Evergreen.V242.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId) (Evergreen.V242.Id.Id Evergreen.V242.Id.GuildId) Evergreen.V242.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V242.LocalState.JoinGuildError
            { guildId : Evergreen.V242.Id.Id Evergreen.V242.Id.GuildId
            , guild : Evergreen.V242.LocalState.FrontendGuild
            , owner : Evergreen.V242.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId) Evergreen.V242.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId) Evergreen.V242.Id.GuildOrDmId Evergreen.V242.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId) (Evergreen.V242.Discord.Id Evergreen.V242.Discord.GuildId) (Evergreen.V242.Discord.Id Evergreen.V242.Discord.ChannelId) Evergreen.V242.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId) (Evergreen.V242.Discord.Id Evergreen.V242.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId) Evergreen.V242.Id.GuildOrDmId Evergreen.V242.Id.ThreadRouteWithMessage Evergreen.V242.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId) Evergreen.V242.Id.GuildOrDmId Evergreen.V242.Id.ThreadRouteWithMessage Evergreen.V242.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId) (Evergreen.V242.Discord.Id Evergreen.V242.Discord.GuildId) (Evergreen.V242.Discord.Id Evergreen.V242.Discord.ChannelId) Evergreen.V242.Id.ThreadRouteWithMessage Evergreen.V242.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId) (Evergreen.V242.Discord.Id Evergreen.V242.Discord.PrivateChannelId) (Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelMessageId) Evergreen.V242.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId) (Evergreen.V242.Discord.Id Evergreen.V242.Discord.GuildId) (Evergreen.V242.Discord.Id Evergreen.V242.Discord.ChannelId) Evergreen.V242.Id.ThreadRouteWithMessage Evergreen.V242.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId) (Evergreen.V242.Discord.Id Evergreen.V242.Discord.PrivateChannelId) (Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelMessageId) Evergreen.V242.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId) Evergreen.V242.Id.GuildOrDmId Evergreen.V242.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V242.RichText.RichText (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId))) (SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.FileStatus.FileId) Evergreen.V242.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId) (Evergreen.V242.Discord.Id Evergreen.V242.Discord.GuildId) (Evergreen.V242.Discord.Id Evergreen.V242.Discord.ChannelId) Evergreen.V242.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V242.RichText.RichText (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V242.Id.DiscordGuildOrDmId_DmData (Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V242.RichText.RichText (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId) Evergreen.V242.Id.AnyGuildOrDmId Evergreen.V242.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V242.Id.AnyGuildOrDmId Evergreen.V242.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V242.Discord.Id Evergreen.V242.Discord.GuildId) (Evergreen.V242.Discord.Id Evergreen.V242.Discord.ChannelId) Evergreen.V242.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V242.Discord.Id Evergreen.V242.Discord.PrivateChannelId) (Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId) Evergreen.V242.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId) Evergreen.V242.FileStatus.FileHash
    | Server_SetGuildIcon (Evergreen.V242.Id.Id Evergreen.V242.Id.GuildId) Evergreen.V242.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V242.Id.Id Evergreen.V242.Id.GuildId) Evergreen.V242.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V242.Discord.Id Evergreen.V242.Discord.GuildId) Evergreen.V242.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V242.SessionIdHash.SessionIdHash Evergreen.V242.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V242.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V242.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V242.Id.AnyGuildOrDmId, Evergreen.V242.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V242.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId) Evergreen.V242.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V242.Discord.Id Evergreen.V242.Discord.GuildId) (Evergreen.V242.Discord.Id Evergreen.V242.Discord.ChannelId) Evergreen.V242.ChannelName.ChannelName (Evergreen.V242.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V242.Discord.Id Evergreen.V242.Discord.PrivateChannelId)
        (Evergreen.V242.NonemptyDict.NonemptyDict
            (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V242.Discord.Id Evergreen.V242.Discord.GuildId) Evergreen.V242.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V242.Discord.Id Evergreen.V242.Discord.PrivateChannelId) Evergreen.V242.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId) Evergreen.V242.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId) (Maybe (Evergreen.V242.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V242.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V242.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V242.Id.Id Evergreen.V242.Id.GuildId) (Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelId) Evergreen.V242.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V242.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId) Evergreen.V242.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V242.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V242.Discord.Id Evergreen.V242.Discord.GuildId) (Evergreen.V242.Discord.Id Evergreen.V242.Discord.ChannelId) Evergreen.V242.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V242.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V242.Discord.Id Evergreen.V242.Discord.PrivateChannelId) (Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V242.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V242.Discord.Id Evergreen.V242.Discord.GuildId) Evergreen.V242.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V242.Discord.Id Evergreen.V242.Discord.GuildId) (Evergreen.V242.Discord.Id Evergreen.V242.Discord.ChannelId) (Evergreen.V242.Discord.OptionalData String) (Evergreen.V242.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V242.Discord.Id Evergreen.V242.Discord.GuildId)
        (Evergreen.V242.MembersAndOwner.MembersAndOwner
            (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V242.Discord.Id Evergreen.V242.Discord.GuildId) (Evergreen.V242.Discord.Id Evergreen.V242.Discord.ChannelId) (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId) Evergreen.V242.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.Id.StickerId) Evergreen.V242.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.Id.CustomEmojiId) Evergreen.V242.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V242.Call.ServerChange
    | Server_Go
        (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId)
        { otherUserId : Evergreen.V242.Id.Id Evergreen.V242.Id.UserId
        }
        Evergreen.V242.Go.LocalChange


type LocalMsg
    = LocalChange (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V242.Id.Id Evergreen.V242.Id.GuildId) (Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelId) Evergreen.V242.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V242.Discord.Id Evergreen.V242.Discord.GuildId) (Evergreen.V242.Discord.Id Evergreen.V242.Discord.ChannelId) Evergreen.V242.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.FileStatus.FileId) Evergreen.V242.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V242.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V242.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V242.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V242.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V242.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V242.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V242.Coord.Coord Evergreen.V242.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V242.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V242.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V242.Id.AnyGuildOrDmId Evergreen.V242.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V242.Id.AnyGuildOrDmId Evergreen.V242.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V242.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V242.Coord.Coord Evergreen.V242.CssPixels.CssPixels) (Maybe Evergreen.V242.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V242.Id.AnyGuildOrDmId, Evergreen.V242.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelMessageId) (Evergreen.V242.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.Id.ThreadMessageId) (Evergreen.V242.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V242.Editable.Model
    , showLinkDiscordSetup : Bool
    , domainWhitelistInput : String
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V242.Local.Local LocalMsg Evergreen.V242.LocalState.LocalState
    , admin : Evergreen.V242.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V242.Id.AnyGuildOrDmId, Evergreen.V242.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V242.Id.Id Evergreen.V242.Id.GuildId, Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V242.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V242.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V242.Id.AnyGuildOrDmId, Evergreen.V242.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V242.Id.AnyGuildOrDmId, Evergreen.V242.Id.ThreadRoute ) (Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : Evergreen.V242.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V242.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V242.Id.AnyGuildOrDmId, Evergreen.V242.Id.ThreadRoute ) (Evergreen.V242.NonemptyDict.NonemptyDict (Evergreen.V242.Id.Id Evergreen.V242.FileStatus.FileId) Evergreen.V242.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V242.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V242.TextEditor.Model
    , profilePictureEditor : Evergreen.V242.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V242.Id.Id Evergreen.V242.Id.GuildId, Evergreen.V242.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V242.Emoji.Model
    , voiceChat : Evergreen.V242.Call.Model
    , currentDmGoMatch : SeqDict.SeqDict ( Evergreen.V242.Id.Id Evergreen.V242.Id.UserId, Maybe (Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelMessageId) ) Evergreen.V242.Go.Model
    , fileDragOverCount : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V242.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V242.SecretId.SecretId Evergreen.V242.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V242.Range.Range
                , direction : Evergreen.V242.Range.SelectionDirection
                }
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V242.NonemptyDict.NonemptyDict Int Evergreen.V242.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V242.NonemptyDict.NonemptyDict Int Evergreen.V242.Touch.Touch
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
    | AdminToFrontend Evergreen.V242.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V242.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V242.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V242.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V242.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V242.ImageEditor.ToFrontend


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V242.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V242.Coord.Coord Evergreen.V242.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V242.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , notificationPermission : Evergreen.V242.Ports.NotificationPermission
    , pwaStatus : Evergreen.V242.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V242.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V242.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V242.Emoji.CachedEmojiData
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V242.Id.Id Evergreen.V242.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V242.Id.Id Evergreen.V242.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V242.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V242.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V242.Coord.Coord Evergreen.V242.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V242.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V242.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V242.Id.Id Evergreen.V242.Id.GuildId, Evergreen.V242.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V242.DmChannel.DmChannelId, Evergreen.V242.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V242.Discord.Id Evergreen.V242.Discord.GuildId, Evergreen.V242.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V242.Discord.Id Evergreen.V242.Discord.PrivateChannelId, Evergreen.V242.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V242.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V242.NonemptyDict.NonemptyDict (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId) Evergreen.V242.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V242.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V242.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V242.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V242.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId) Evergreen.V242.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId) Evergreen.V242.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V242.Id.Id Evergreen.V242.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.Id.GuildId) Evergreen.V242.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.Id.GuildId) Evergreen.V242.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V242.Discord.Id Evergreen.V242.Discord.GuildId) Evergreen.V242.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V242.DmChannel.DmChannelId Evergreen.V242.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V242.Discord.Id Evergreen.V242.Discord.PrivateChannelId) Evergreen.V242.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V242.OneToOne.OneToOne (Evergreen.V242.Slack.Id Evergreen.V242.Slack.ChannelId) Evergreen.V242.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V242.OneToOne.OneToOne String (Evergreen.V242.Id.Id Evergreen.V242.Id.GuildId)
    , slackUsers : Evergreen.V242.OneToOne.OneToOne (Evergreen.V242.Slack.Id Evergreen.V242.Slack.UserId) (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId)
    , slackServers : Evergreen.V242.OneToOne.OneToOne (Evergreen.V242.Slack.Id Evergreen.V242.Slack.TeamId) (Evergreen.V242.Id.Id Evergreen.V242.Id.GuildId)
    , slackToken : Maybe Evergreen.V242.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V242.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V242.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V242.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareTurnApiToken : Maybe String
    , textEditor : Evergreen.V242.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId) Evergreen.V242.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId, Evergreen.V242.Discord.Id Evergreen.V242.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V242.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V242.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V242.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V242.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId) (Evergreen.V242.LocalState.LoadingDiscordChannel (List Evergreen.V242.Discord.Message))
    , signupsEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V242.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.Id.StickerId) Evergreen.V242.Sticker.StickerData
    , discordStickers : Evergreen.V242.OneToOne.OneToOne (Evergreen.V242.Discord.Id Evergreen.V242.Discord.StickerId) (Evergreen.V242.Id.Id Evergreen.V242.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.Id.CustomEmojiId) Evergreen.V242.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V242.OneToOne.OneToOne Evergreen.V242.RichText.DiscordCustomEmojiIdAndName (Evergreen.V242.Id.Id Evergreen.V242.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V242.Postmark.ApiKey
    , serverSecret : Evergreen.V242.SecretId.SecretId Evergreen.V242.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketDisconnects : Array.Array Effect.Time.Posix
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V242.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V242.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V242.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V242.Route.Route
    | SelectedFilesToAttach ( Evergreen.V242.Id.AnyGuildOrDmId, Evergreen.V242.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V242.Id.Id Evergreen.V242.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V242.Id.Id Evergreen.V242.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V242.Id.Id Evergreen.V242.Id.GuildId) (Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelId) Evergreen.V242.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V242.Id.Id Evergreen.V242.Id.GuildId) (Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelId) Evergreen.V242.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V242.Discord.Id Evergreen.V242.Discord.GuildId) (Evergreen.V242.Discord.Id Evergreen.V242.Discord.ChannelId) Evergreen.V242.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V242.Discord.Id Evergreen.V242.Discord.GuildId) (Evergreen.V242.Discord.Id Evergreen.V242.Discord.ChannelId) Evergreen.V242.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V242.Id.Id Evergreen.V242.Id.GuildId) (Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V242.Id.Id Evergreen.V242.Id.GuildId) (Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V242.Id.Id Evergreen.V242.Id.GuildId) (Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V242.Id.Id Evergreen.V242.Id.GuildId) (Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V242.Id.Id Evergreen.V242.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V242.Id.Id Evergreen.V242.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V242.Id.Id Evergreen.V242.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V242.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V242.Id.AnyGuildOrDmId Evergreen.V242.Id.ThreadRouteWithMessage (Evergreen.V242.Coord.Coord Evergreen.V242.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V242.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V242.Id.AnyGuildOrDmId Evergreen.V242.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V242.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V242.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V242.Id.AnyGuildOrDmId, Evergreen.V242.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V242.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V242.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V242.Id.AnyGuildOrDmId, Evergreen.V242.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V242.NonemptyDict.NonemptyDict Int Evergreen.V242.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V242.NonemptyDict.NonemptyDict Int Evergreen.V242.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V242.Id.AnyGuildOrDmId Evergreen.V242.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V242.Id.AnyGuildOrDmId Evergreen.V242.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V242.NonemptySet.NonemptySet (Evergreen.V242.Id.Id Evergreen.V242.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V242.Id.AnyGuildOrDmId, Evergreen.V242.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V242.Id.AnyGuildOrDmId Evergreen.V242.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V242.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V242.AiChat.Msg
    | GoMsg Evergreen.V242.Go.Msg
    | UserNameEditableMsg (Evergreen.V242.Editable.Msg Evergreen.V242.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V242.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V242.Id.Id Evergreen.V242.Id.GuildId) Evergreen.V242.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V242.Id.AnyGuildOrDmId, Evergreen.V242.Id.ThreadRoute ) (Evergreen.V242.Id.Id Evergreen.V242.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V242.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V242.Id.AnyGuildOrDmId, Evergreen.V242.Id.ThreadRoute ) (Evergreen.V242.Id.Id Evergreen.V242.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V242.Id.AnyGuildOrDmId, Evergreen.V242.Id.ThreadRoute ) (Evergreen.V242.Id.Id Evergreen.V242.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V242.Id.AnyGuildOrDmId, Evergreen.V242.Id.ThreadRoute )
        { fileId : Evergreen.V242.Id.Id Evergreen.V242.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V242.Id.AnyGuildOrDmId, Evergreen.V242.Id.ThreadRoute ) (Evergreen.V242.Id.Id Evergreen.V242.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V242.Id.AnyGuildOrDmId, Evergreen.V242.Id.ThreadRoute ) (Evergreen.V242.Id.Id Evergreen.V242.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V242.Id.AnyGuildOrDmId, Evergreen.V242.Id.ThreadRoute )
        { fileId : Evergreen.V242.Id.Id Evergreen.V242.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V242.Id.AnyGuildOrDmId, Evergreen.V242.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V242.Id.AnyGuildOrDmId, Evergreen.V242.Id.ThreadRoute ) (Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelMessageId) (Evergreen.V242.Id.Id Evergreen.V242.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V242.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V242.Id.AnyGuildOrDmId, Evergreen.V242.Id.ThreadRoute ) (Evergreen.V242.Id.Id Evergreen.V242.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V242.Id.AnyGuildOrDmId Evergreen.V242.Id.ThreadRouteWithMessage Evergreen.V242.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V242.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V242.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V242.Id.Id Evergreen.V242.Id.GuildId) Evergreen.V242.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId) (Evergreen.V242.Discord.Id Evergreen.V242.Discord.GuildId) Evergreen.V242.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V242.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V242.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId
        , otherUserId : Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V242.Id.AnyGuildOrDmId Evergreen.V242.Id.ThreadRoute Evergreen.V242.MessageInput.Msg
    | MessageInputMsg Evergreen.V242.Id.AnyGuildOrDmId Evergreen.V242.Id.ThreadRoute Evergreen.V242.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V242.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V242.Range.Range, Evergreen.V242.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V242.Range.Range, Evergreen.V242.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V242.Call.FromJs)
    | VoiceChatMsg Evergreen.V242.Call.Msg
    | PressedChannelHeaderTab Evergreen.V242.Route.DmChannelHeaderTab
    | FileDragEnter
    | FileDragLeave
    | FileDropped (List Effect.File.File)


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V242.Id.Id Evergreen.V242.Id.GuildId) (Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelId) Evergreen.V242.Id.ThreadRoute
    | InitialLoadRequested_Dm Evergreen.V242.DmChannel.DmChannelId Evergreen.V242.Id.ThreadRoute
    | InitialLoadRequested_Discord Evergreen.V242.Id.DiscordGuildOrDmId Evergreen.V242.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V242.Id.Id Evergreen.V242.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V242.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V242.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V242.Untrusted.Untrusted Evergreen.V242.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V242.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V242.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V242.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V242.Id.Id Evergreen.V242.Id.GuildId) (Evergreen.V242.SecretId.SecretId Evergreen.V242.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V242.PersonName.PersonName Evergreen.V242.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V242.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V242.Slack.OAuthCode Evergreen.V242.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V242.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V242.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V242.Id.Id Evergreen.V242.Pagination.PageId))


type alias PendingVoiceChatJoin =
    { sessionId : Effect.Lamdera.SessionId
    , clientId : Effect.Lamdera.ClientId
    , changeId : Evergreen.V242.Local.ChangeId
    , time : Effect.Time.Posix
    , userId : Evergreen.V242.Id.Id Evergreen.V242.Id.UserId
    , otherUserId : Evergreen.V242.Id.Id Evergreen.V242.Id.UserId
    , dmChannelId : Evergreen.V242.DmChannel.DmChannelId
    , roomId : Evergreen.V242.Call.RoomId
    }


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V242.Discord.Id Evergreen.V242.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V242.Discord.Id Evergreen.V242.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V242.EmailAddress.EmailAddress (Result Evergreen.V242.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V242.EmailAddress.EmailAddress (Result Evergreen.V242.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId) Evergreen.V242.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V242.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V242.Discord.Id Evergreen.V242.Discord.GuildId) (Evergreen.V242.Discord.Id Evergreen.V242.Discord.ChannelId) Evergreen.V242.Id.ThreadRouteWithMaybeMessage (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId) (Result Evergreen.V242.Discord.HttpError Evergreen.V242.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V242.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V242.Discord.Id Evergreen.V242.Discord.PrivateChannelId) (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId) (Result Evergreen.V242.Discord.HttpError Evergreen.V242.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V242.Discord.Id Evergreen.V242.Discord.GuildId) (Evergreen.V242.Discord.Id Evergreen.V242.Discord.ChannelId) Evergreen.V242.Id.ThreadRouteWithMessage (Evergreen.V242.Discord.Id Evergreen.V242.Discord.MessageId) (Result Evergreen.V242.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V242.Discord.Id Evergreen.V242.Discord.PrivateChannelId) (Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelMessageId) (Evergreen.V242.Discord.Id Evergreen.V242.Discord.MessageId) (Result Evergreen.V242.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V242.Discord.Id Evergreen.V242.Discord.GuildId) (Evergreen.V242.Discord.Id Evergreen.V242.Discord.ChannelId) Evergreen.V242.Id.ThreadRouteWithMessage (Evergreen.V242.Discord.Id Evergreen.V242.Discord.MessageId) (Result Evergreen.V242.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V242.Discord.Id Evergreen.V242.Discord.PrivateChannelId) (Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelMessageId) (Evergreen.V242.Discord.Id Evergreen.V242.Discord.MessageId) (Result Evergreen.V242.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V242.Discord.Id Evergreen.V242.Discord.GuildId) (Evergreen.V242.Discord.Id Evergreen.V242.Discord.ChannelId) Evergreen.V242.Id.ThreadRouteWithMessage (Evergreen.V242.Discord.Id Evergreen.V242.Discord.MessageId) Evergreen.V242.Emoji.EmojiOrCustomEmoji (Result Evergreen.V242.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V242.Discord.Id Evergreen.V242.Discord.PrivateChannelId) (Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelMessageId) (Evergreen.V242.Discord.Id Evergreen.V242.Discord.MessageId) Evergreen.V242.Emoji.EmojiOrCustomEmoji (Result Evergreen.V242.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V242.Discord.Id Evergreen.V242.Discord.GuildId) (Evergreen.V242.Discord.Id Evergreen.V242.Discord.ChannelId) Evergreen.V242.Id.ThreadRouteWithMessage (Evergreen.V242.Discord.Id Evergreen.V242.Discord.MessageId) Evergreen.V242.Emoji.EmojiOrCustomEmoji (Result Evergreen.V242.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V242.Discord.Id Evergreen.V242.Discord.PrivateChannelId) (Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelMessageId) (Evergreen.V242.Discord.Id Evergreen.V242.Discord.MessageId) Evergreen.V242.Emoji.EmojiOrCustomEmoji (Result Evergreen.V242.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V242.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V242.Discord.HttpError (List ( Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId, Maybe Evergreen.V242.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V242.Slack.CurrentUser
            , team : Evergreen.V242.Slack.Team
            , users : List Evergreen.V242.Slack.User
            , channels : List ( Evergreen.V242.Slack.Channel, List Evergreen.V242.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId) (Result Effect.Http.Error Evergreen.V242.Slack.TokenResponse)
    | GotCloudflareTurnCredentials PendingVoiceChatJoin (Result Effect.Http.Error (List Evergreen.V242.Cloudflare.TurnConfig))
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId) Evergreen.V242.Discord.UserAuth (Result Evergreen.V242.Discord.HttpError Evergreen.V242.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId) (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId) (Result Evergreen.V242.Discord.HttpError Evergreen.V242.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId)
        (Result
            Evergreen.V242.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V242.Discord.Id Evergreen.V242.Discord.PrivateChannelId
                , members : List (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId)
                }
            , List
                ( Evergreen.V242.Discord.Id Evergreen.V242.Discord.GuildId
                , { guild : Evergreen.V242.Discord.GatewayGuild
                  , channels : List Evergreen.V242.Discord.Channel
                  , icon : Maybe Evergreen.V242.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId) Bool
    | WebsocketSentDataForUser (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V242.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V242.Discord.Id Evergreen.V242.Discord.AttachmentId, Evergreen.V242.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V242.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V242.Discord.Id Evergreen.V242.Discord.AttachmentId, Evergreen.V242.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId) (Evergreen.V242.Discord.Id Evergreen.V242.Discord.GuildId) (Evergreen.V242.Discord.Id Evergreen.V242.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V242.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V242.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId) (Evergreen.V242.Discord.Id Evergreen.V242.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V242.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V242.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId) (Evergreen.V242.Discord.Id Evergreen.V242.Discord.GuildId) (Evergreen.V242.Discord.Id Evergreen.V242.Discord.ChannelId) (Result Evergreen.V242.Discord.HttpError (List Evergreen.V242.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId) (Evergreen.V242.Discord.Id Evergreen.V242.Discord.PrivateChannelId) (Result Evergreen.V242.Discord.HttpError (List Evergreen.V242.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V242.Id.Id Evergreen.V242.Id.GuildId) (Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelId) Evergreen.V242.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V242.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V242.DmChannel.DmChannelId Evergreen.V242.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V242.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V242.Discord.Id Evergreen.V242.Discord.GuildId) (Evergreen.V242.Discord.Id Evergreen.V242.Discord.ChannelId) Evergreen.V242.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V242.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V242.Discord.Id Evergreen.V242.Discord.PrivateChannelId) (Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V242.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId)
        (Evergreen.V242.Discord.Id Evergreen.V242.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V242.Discord.HttpError
            { guild : Evergreen.V242.Discord.GatewayGuild
            , channels : List Evergreen.V242.Discord.Channel
            , icon : Maybe Evergreen.V242.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V242.Discord.Id Evergreen.V242.Discord.GuildId) (Result Evergreen.V242.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V242.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId) (List ( Evergreen.V242.Id.Id Evergreen.V242.Id.StickerId, Result Effect.Http.Error Evergreen.V242.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V242.Id.Id Evergreen.V242.Id.StickerId, Result Effect.Http.Error Evergreen.V242.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId) (List ( Evergreen.V242.Id.Id Evergreen.V242.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V242.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V242.Id.Id Evergreen.V242.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V242.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V242.Discord.HttpError (List Evergreen.V242.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V242.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V242.SecretId.SecretId Evergreen.V242.SecretId.ServerSecret))
