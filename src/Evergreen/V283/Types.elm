module Evergreen.V283.Types exposing (..)

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
import Evergreen.V283.AiChat
import Evergreen.V283.Call
import Evergreen.V283.ChannelDescription
import Evergreen.V283.ChannelName
import Evergreen.V283.Cloudflare
import Evergreen.V283.Coord
import Evergreen.V283.CssPixels
import Evergreen.V283.CustomEmoji
import Evergreen.V283.Discord
import Evergreen.V283.DiscordAttachmentId
import Evergreen.V283.DiscordUserData
import Evergreen.V283.DmChannel
import Evergreen.V283.Editable
import Evergreen.V283.EmailAddress
import Evergreen.V283.Embed
import Evergreen.V283.Emoji
import Evergreen.V283.FileStatus
import Evergreen.V283.Go
import Evergreen.V283.GuildName
import Evergreen.V283.Id
import Evergreen.V283.ImageEditor
import Evergreen.V283.ImageViewer
import Evergreen.V283.Local
import Evergreen.V283.LocalState
import Evergreen.V283.Log
import Evergreen.V283.LoginForm
import Evergreen.V283.MembersAndOwner
import Evergreen.V283.Message
import Evergreen.V283.MessageInput
import Evergreen.V283.MessageView
import Evergreen.V283.MyUi
import Evergreen.V283.NonemptyDict
import Evergreen.V283.NonemptySet
import Evergreen.V283.OneToOne
import Evergreen.V283.Pages.Admin
import Evergreen.V283.Pagination
import Evergreen.V283.PersonName
import Evergreen.V283.Ports
import Evergreen.V283.Postmark
import Evergreen.V283.Range
import Evergreen.V283.RichText
import Evergreen.V283.Route
import Evergreen.V283.SecretId
import Evergreen.V283.SessionIdHash
import Evergreen.V283.Slack
import Evergreen.V283.Sticker
import Evergreen.V283.TextEditor
import Evergreen.V283.ToBackendLog
import Evergreen.V283.Touch
import Evergreen.V283.TwoFactorAuthentication
import Evergreen.V283.Ui.Anim
import Evergreen.V283.Untrusted
import Evergreen.V283.User
import Evergreen.V283.UserAgent
import Evergreen.V283.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V283.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V283.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V283.Id.Id Evergreen.V283.Id.GuildId) Evergreen.V283.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V283.Id.Id Evergreen.V283.Id.UserId) Evergreen.V283.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V283.Discord.Id Evergreen.V283.Discord.PrivateChannelId) Evergreen.V283.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V283.Discord.Id Evergreen.V283.Discord.GuildId) Evergreen.V283.LocalState.DiscordFrontendGuild
    , user : Evergreen.V283.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V283.Id.Id Evergreen.V283.Id.UserId) Evergreen.V283.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId) Evergreen.V283.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId) Evergreen.V283.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V283.SessionIdHash.SessionIdHash Evergreen.V283.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V283.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V283.Id.Id Evergreen.V283.Id.StickerId) Evergreen.V283.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V283.Id.Id Evergreen.V283.Id.CustomEmojiId) Evergreen.V283.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V283.Call.CallId (Evergreen.V283.NonemptyDict.NonemptyDict ( Evergreen.V283.Id.Id Evergreen.V283.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V283.Call.RemoteCallData)
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type PublicGoMatch
    = PublicGoMatch_NotLoaded
    | PublicGoMatch_Loading
    | PublicGoMatch_Loaded Evergreen.V283.Go.PublicGoMatchData Evergreen.V283.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V283.Route.Route
    , windowSize : Evergreen.V283.Coord.Coord Evergreen.V283.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V283.Ports.NotificationPermission
    , pwaStatus : Evergreen.V283.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V283.UserAgent.UserAgent
    , publicGoMatch : PublicGoMatch
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V283.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V283.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V283.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V283.Id.Id Evergreen.V283.FileStatus.FileId) Evergreen.V283.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V283.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V283.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V283.Id.Id Evergreen.V283.FileStatus.FileId) Evergreen.V283.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V283.Id.Id Evergreen.V283.Id.GuildId) Evergreen.V283.ChannelName.ChannelName Evergreen.V283.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V283.Id.Id Evergreen.V283.Id.GuildId) (Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelId) Evergreen.V283.ChannelName.ChannelName Evergreen.V283.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V283.Id.Id Evergreen.V283.Id.GuildId) (Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelId)
    | Local_DeleteGuild (Evergreen.V283.Id.Id Evergreen.V283.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V283.Id.Id Evergreen.V283.Id.GuildId) (Evergreen.V283.UserSession.ToBeFilledInByBackend (Evergreen.V283.SecretId.SecretId Evergreen.V283.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V283.Id.Id Evergreen.V283.Id.GuildId) (Evergreen.V283.SecretId.SecretId Evergreen.V283.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V283.GuildName.GuildName (Evergreen.V283.UserSession.ToBeFilledInByBackend (Evergreen.V283.Id.Id Evergreen.V283.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V283.Id.AnyGuildOrDmId, Evergreen.V283.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V283.Id.AnyGuildOrDmId Evergreen.V283.Id.ThreadRouteWithMessage Evergreen.V283.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V283.Id.AnyGuildOrDmId Evergreen.V283.Id.ThreadRouteWithMessage Evergreen.V283.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V283.Id.GuildOrDmId Evergreen.V283.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V283.Id.Id Evergreen.V283.FileStatus.FileId) Evergreen.V283.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId) (Evergreen.V283.Discord.Id Evergreen.V283.Discord.GuildId) (Evergreen.V283.Discord.Id Evergreen.V283.Discord.ChannelId) Evergreen.V283.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V283.Id.DiscordGuildOrDmId_DmData (Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V283.Id.AnyGuildOrDmId Evergreen.V283.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V283.Id.AnyGuildOrDmId Evergreen.V283.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V283.Id.AnyGuildOrDmId Evergreen.V283.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V283.UserSession.SetViewing
    | Local_SetName Evergreen.V283.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V283.Id.GuildOrDmId (Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelMessageId) (Evergreen.V283.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelMessageId) (Evergreen.V283.Message.Message Evergreen.V283.Id.ChannelMessageId (Evergreen.V283.Id.Id Evergreen.V283.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V283.Id.GuildOrDmId (Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelMessageId) (Evergreen.V283.Id.Id Evergreen.V283.Id.ThreadMessageId) (Evergreen.V283.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V283.Id.Id Evergreen.V283.Id.ThreadMessageId) (Evergreen.V283.Message.Message Evergreen.V283.Id.ThreadMessageId (Evergreen.V283.Id.Id Evergreen.V283.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V283.Id.DiscordGuildOrDmId (Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelMessageId) (Evergreen.V283.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelMessageId) (Evergreen.V283.Message.Message Evergreen.V283.Id.ChannelMessageId (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V283.Id.DiscordGuildOrDmId (Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelMessageId) (Evergreen.V283.Id.Id Evergreen.V283.Id.ThreadMessageId) (Evergreen.V283.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V283.Id.Id Evergreen.V283.Id.ThreadMessageId) (Evergreen.V283.Message.Message Evergreen.V283.Id.ThreadMessageId (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V283.Id.Id Evergreen.V283.Id.GuildId) Evergreen.V283.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId) (Evergreen.V283.Discord.Id Evergreen.V283.Discord.GuildId) Evergreen.V283.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V283.UserSession.NotificationMode
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V283.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V283.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V283.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V283.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V283.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V283.NonemptySet.NonemptySet (Evergreen.V283.Id.Id Evergreen.V283.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V283.Call.LocalChange
    | Local_Go
        { otherUserId : Evergreen.V283.Id.Id Evergreen.V283.Id.UserId
        }
        Evergreen.V283.Go.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V283.Id.Id Evergreen.V283.Id.UserId) Effect.Time.Posix Evergreen.V283.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V283.RichText.RichText (Evergreen.V283.Id.Id Evergreen.V283.Id.UserId))) Evergreen.V283.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V283.Id.Id Evergreen.V283.FileStatus.FileId) Evergreen.V283.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V283.Id.Id Evergreen.V283.Id.StickerId) Evergreen.V283.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V283.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V283.RichText.RichText (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId))) Evergreen.V283.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V283.Id.Id Evergreen.V283.FileStatus.FileId) Evergreen.V283.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V283.Id.Id Evergreen.V283.Id.StickerId) Evergreen.V283.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V283.Id.Id Evergreen.V283.Id.GuildId) Evergreen.V283.ChannelName.ChannelName Evergreen.V283.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V283.Id.Id Evergreen.V283.Id.GuildId) (Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelId) Evergreen.V283.ChannelName.ChannelName Evergreen.V283.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V283.Id.Id Evergreen.V283.Id.GuildId) (Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelId)
    | Server_DeleteGuild (Evergreen.V283.Id.Id Evergreen.V283.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V283.Id.Id Evergreen.V283.Id.UserId) (Evergreen.V283.Id.Id Evergreen.V283.Id.GuildId) (Evergreen.V283.SecretId.SecretId Evergreen.V283.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V283.Id.Id Evergreen.V283.Id.GuildId) (Evergreen.V283.SecretId.SecretId Evergreen.V283.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V283.Id.Id Evergreen.V283.Id.UserId) (Evergreen.V283.Id.Id Evergreen.V283.Id.GuildId) Evergreen.V283.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V283.LocalState.JoinGuildError
            { guildId : Evergreen.V283.Id.Id Evergreen.V283.Id.GuildId
            , guild : Evergreen.V283.LocalState.FrontendGuild
            , owner : Evergreen.V283.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V283.Id.Id Evergreen.V283.Id.UserId) Evergreen.V283.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V283.Id.Id Evergreen.V283.Id.UserId) Evergreen.V283.Id.GuildOrDmId Evergreen.V283.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId) (Evergreen.V283.Discord.Id Evergreen.V283.Discord.GuildId) (Evergreen.V283.Discord.Id Evergreen.V283.Discord.ChannelId) Evergreen.V283.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId) (Evergreen.V283.Discord.Id Evergreen.V283.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V283.Id.Id Evergreen.V283.Id.UserId) Evergreen.V283.Id.GuildOrDmId Evergreen.V283.Id.ThreadRouteWithMessage Evergreen.V283.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V283.Id.Id Evergreen.V283.Id.UserId) Evergreen.V283.Id.GuildOrDmId Evergreen.V283.Id.ThreadRouteWithMessage Evergreen.V283.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId) (Evergreen.V283.Discord.Id Evergreen.V283.Discord.GuildId) (Evergreen.V283.Discord.Id Evergreen.V283.Discord.ChannelId) Evergreen.V283.Id.ThreadRouteWithMessage Evergreen.V283.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId) (Evergreen.V283.Discord.Id Evergreen.V283.Discord.PrivateChannelId) (Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelMessageId) Evergreen.V283.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId) (Evergreen.V283.Discord.Id Evergreen.V283.Discord.GuildId) (Evergreen.V283.Discord.Id Evergreen.V283.Discord.ChannelId) Evergreen.V283.Id.ThreadRouteWithMessage Evergreen.V283.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId) (Evergreen.V283.Discord.Id Evergreen.V283.Discord.PrivateChannelId) (Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelMessageId) Evergreen.V283.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V283.Id.Id Evergreen.V283.Id.UserId) Evergreen.V283.Id.GuildOrDmId Evergreen.V283.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V283.RichText.RichText (Evergreen.V283.Id.Id Evergreen.V283.Id.UserId))) (SeqDict.SeqDict (Evergreen.V283.Id.Id Evergreen.V283.FileStatus.FileId) Evergreen.V283.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId) (Evergreen.V283.Discord.Id Evergreen.V283.Discord.GuildId) (Evergreen.V283.Discord.Id Evergreen.V283.Discord.ChannelId) Evergreen.V283.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V283.RichText.RichText (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V283.Id.DiscordGuildOrDmId_DmData (Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V283.RichText.RichText (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V283.Id.Id Evergreen.V283.Id.UserId) Evergreen.V283.Id.AnyGuildOrDmId Evergreen.V283.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V283.Id.AnyGuildOrDmId Evergreen.V283.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V283.Discord.Id Evergreen.V283.Discord.GuildId) (Evergreen.V283.Discord.Id Evergreen.V283.Discord.ChannelId) Evergreen.V283.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V283.Discord.Id Evergreen.V283.Discord.PrivateChannelId) (Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V283.Id.Id Evergreen.V283.Id.UserId) Evergreen.V283.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V283.Id.Id Evergreen.V283.Id.UserId) Evergreen.V283.FileStatus.FileHash
    | Server_SetGuildIcon (Evergreen.V283.Id.Id Evergreen.V283.Id.GuildId) Evergreen.V283.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V283.Id.Id Evergreen.V283.Id.GuildId) Evergreen.V283.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V283.Discord.Id Evergreen.V283.Discord.GuildId) Evergreen.V283.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V283.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V283.SessionIdHash.SessionIdHash Evergreen.V283.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V283.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V283.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V283.Id.AnyGuildOrDmId, Evergreen.V283.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V283.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId) Evergreen.V283.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V283.Discord.Id Evergreen.V283.Discord.GuildId) (Evergreen.V283.Discord.Id Evergreen.V283.Discord.ChannelId) Evergreen.V283.ChannelName.ChannelName (Evergreen.V283.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V283.Discord.Id Evergreen.V283.Discord.PrivateChannelId)
        (Evergreen.V283.NonemptyDict.NonemptyDict
            (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V283.Discord.Id Evergreen.V283.Discord.GuildId) Evergreen.V283.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V283.Discord.Id Evergreen.V283.Discord.PrivateChannelId) Evergreen.V283.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId) Evergreen.V283.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId) (Maybe (Evergreen.V283.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V283.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V283.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V283.Id.Id Evergreen.V283.Id.GuildId) (Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelId) Evergreen.V283.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V283.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V283.Id.Id Evergreen.V283.Id.UserId) Evergreen.V283.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V283.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V283.Discord.Id Evergreen.V283.Discord.GuildId) (Evergreen.V283.Discord.Id Evergreen.V283.Discord.ChannelId) Evergreen.V283.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V283.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V283.Discord.Id Evergreen.V283.Discord.PrivateChannelId) (Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V283.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V283.Discord.Id Evergreen.V283.Discord.GuildId) Evergreen.V283.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V283.Discord.Id Evergreen.V283.Discord.GuildId) (Evergreen.V283.Discord.Id Evergreen.V283.Discord.ChannelId) (Evergreen.V283.Discord.OptionalData String) (Evergreen.V283.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V283.Discord.Id Evergreen.V283.Discord.GuildId)
        (Evergreen.V283.MembersAndOwner.MembersAndOwner
            (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V283.Discord.Id Evergreen.V283.Discord.GuildId) (Evergreen.V283.Discord.Id Evergreen.V283.Discord.ChannelId) (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId) Evergreen.V283.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V283.Id.Id Evergreen.V283.Id.StickerId) Evergreen.V283.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V283.Id.Id Evergreen.V283.Id.CustomEmojiId) Evergreen.V283.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V283.Call.ServerChange
    | Server_Go
        (Evergreen.V283.Id.Id Evergreen.V283.Id.UserId)
        { otherUserId : Evergreen.V283.Id.Id Evergreen.V283.Id.UserId
        }
        Evergreen.V283.Go.LocalChange


type LocalMsg
    = LocalChange (Evergreen.V283.Id.Id Evergreen.V283.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V283.Id.Id Evergreen.V283.Id.GuildId) (Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelId) Evergreen.V283.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V283.Discord.Id Evergreen.V283.Discord.GuildId) (Evergreen.V283.Discord.Id Evergreen.V283.Discord.ChannelId) Evergreen.V283.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V283.Id.Id Evergreen.V283.FileStatus.FileId) Evergreen.V283.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V283.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V283.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V283.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V283.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V283.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V283.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V283.Coord.Coord Evergreen.V283.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V283.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V283.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V283.Id.AnyGuildOrDmId Evergreen.V283.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V283.Id.AnyGuildOrDmId Evergreen.V283.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V283.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V283.Coord.Coord Evergreen.V283.CssPixels.CssPixels) (Maybe Evergreen.V283.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V283.Id.AnyGuildOrDmId, Evergreen.V283.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelMessageId) (Evergreen.V283.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V283.Id.Id Evergreen.V283.Id.ThreadMessageId) (Evergreen.V283.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V283.Editable.Model
    , showLinkDiscordSetup : Bool
    , domainWhitelistInput : String
    , serviceWorkerData : Maybe String
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V283.Local.Local LocalMsg Evergreen.V283.LocalState.LocalState
    , admin : Evergreen.V283.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V283.Id.AnyGuildOrDmId, Evergreen.V283.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V283.Id.Id Evergreen.V283.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V283.Id.Id Evergreen.V283.Id.GuildId, Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V283.Id.Id Evergreen.V283.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V283.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V283.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V283.Id.AnyGuildOrDmId, Evergreen.V283.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V283.Id.AnyGuildOrDmId, Evergreen.V283.Id.ThreadRoute ) (Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : Evergreen.V283.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V283.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V283.Id.AnyGuildOrDmId, Evergreen.V283.Id.ThreadRoute ) (Evergreen.V283.NonemptyDict.NonemptyDict (Evergreen.V283.Id.Id Evergreen.V283.FileStatus.FileId) Evergreen.V283.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V283.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V283.TextEditor.Model
    , profilePictureEditor : Evergreen.V283.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V283.Id.Id Evergreen.V283.Id.GuildId, Evergreen.V283.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V283.Emoji.Model
    , voiceChat : Evergreen.V283.Call.Model
    , currentDmGoMatch : SeqDict.SeqDict ( Evergreen.V283.Id.Id Evergreen.V283.Id.UserId, Maybe (Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelMessageId) ) Evergreen.V283.Go.Model
    , fileDragOverCount : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V283.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V283.SecretId.SecretId Evergreen.V283.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V283.Range.Range
                , direction : Evergreen.V283.Range.SelectionDirection
                }
        }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V283.NonemptyDict.NonemptyDict Int Evergreen.V283.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V283.NonemptyDict.NonemptyDict Int Evergreen.V283.Touch.Touch
        , target : DragTarget
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
    | AdminToFrontend Evergreen.V283.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V283.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V283.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V283.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V283.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V283.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V283.Go.PublicGoMatchResponse)


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V283.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V283.Coord.Coord Evergreen.V283.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V283.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V283.MyUi.LastCopy
    , notificationPermission : Evergreen.V283.Ports.NotificationPermission
    , pwaStatus : Evergreen.V283.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V283.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V283.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V283.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V283.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V283.Id.Id Evergreen.V283.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V283.Id.Id Evergreen.V283.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V283.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V283.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V283.Coord.Coord Evergreen.V283.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V283.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V283.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V283.Id.Id Evergreen.V283.Id.GuildId, Evergreen.V283.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V283.DmChannel.DmChannelId, Evergreen.V283.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V283.Discord.Id Evergreen.V283.Discord.GuildId, Evergreen.V283.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V283.Discord.Id Evergreen.V283.Discord.PrivateChannelId, Evergreen.V283.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V283.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V283.NonemptyDict.NonemptyDict (Evergreen.V283.Id.Id Evergreen.V283.Id.UserId) Evergreen.V283.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V283.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V283.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V283.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V283.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V283.Id.Id Evergreen.V283.Id.UserId) Evergreen.V283.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V283.Id.Id Evergreen.V283.Id.UserId) Evergreen.V283.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V283.Id.Id Evergreen.V283.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V283.Id.Id Evergreen.V283.Id.GuildId) Evergreen.V283.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V283.Id.Id Evergreen.V283.Id.GuildId) Evergreen.V283.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V283.Discord.Id Evergreen.V283.Discord.GuildId) Evergreen.V283.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V283.DmChannel.DmChannelId Evergreen.V283.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V283.Discord.Id Evergreen.V283.Discord.PrivateChannelId) Evergreen.V283.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V283.OneToOne.OneToOne (Evergreen.V283.Slack.Id Evergreen.V283.Slack.ChannelId) Evergreen.V283.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V283.OneToOne.OneToOne String (Evergreen.V283.Id.Id Evergreen.V283.Id.GuildId)
    , slackUsers : Evergreen.V283.OneToOne.OneToOne (Evergreen.V283.Slack.Id Evergreen.V283.Slack.UserId) (Evergreen.V283.Id.Id Evergreen.V283.Id.UserId)
    , slackServers : Evergreen.V283.OneToOne.OneToOne (Evergreen.V283.Slack.Id Evergreen.V283.Slack.TeamId) (Evergreen.V283.Id.Id Evergreen.V283.Id.GuildId)
    , slackToken : Maybe Evergreen.V283.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V283.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V283.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V283.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V283.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V283.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V283.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V283.Cloudflare.AnalyticsApiToken
    , textEditor : Evergreen.V283.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId) Evergreen.V283.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId, Evergreen.V283.Discord.Id Evergreen.V283.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V283.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V283.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V283.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V283.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId) (Evergreen.V283.LocalState.LoadingDiscordChannel (List Evergreen.V283.Discord.Message))
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V283.Id.Id Evergreen.V283.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V283.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V283.Id.Id Evergreen.V283.Id.StickerId) Evergreen.V283.Sticker.StickerData
    , discordStickers : Evergreen.V283.OneToOne.OneToOne (Evergreen.V283.Discord.Id Evergreen.V283.Discord.StickerId) (Evergreen.V283.Id.Id Evergreen.V283.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V283.Id.Id Evergreen.V283.Id.CustomEmojiId) Evergreen.V283.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V283.OneToOne.OneToOne Evergreen.V283.RichText.DiscordCustomEmojiIdAndName (Evergreen.V283.Id.Id Evergreen.V283.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V283.Postmark.ApiKey
    , serverSecret : Evergreen.V283.SecretId.SecretId Evergreen.V283.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V283.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V283.OneToOne.OneToOne (Evergreen.V283.SecretId.SecretId Evergreen.V283.Id.GoMatchPublicId) ( Evergreen.V283.DmChannel.DmChannelId, Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelMessageId )
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V283.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V283.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V283.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V283.Route.Route
    | SelectedFilesToAttach ( Evergreen.V283.Id.AnyGuildOrDmId, Evergreen.V283.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V283.Id.Id Evergreen.V283.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V283.Id.Id Evergreen.V283.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V283.Id.Id Evergreen.V283.Id.GuildId) (Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelId) Evergreen.V283.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V283.Id.Id Evergreen.V283.Id.GuildId) (Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelId) Evergreen.V283.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V283.Discord.Id Evergreen.V283.Discord.GuildId) (Evergreen.V283.Discord.Id Evergreen.V283.Discord.ChannelId) Evergreen.V283.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V283.Discord.Id Evergreen.V283.Discord.GuildId) (Evergreen.V283.Discord.Id Evergreen.V283.Discord.ChannelId) Evergreen.V283.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V283.Id.Id Evergreen.V283.Id.GuildId) (Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V283.Id.Id Evergreen.V283.Id.GuildId) (Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V283.Id.Id Evergreen.V283.Id.GuildId) (Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V283.Id.Id Evergreen.V283.Id.GuildId) (Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V283.Id.Id Evergreen.V283.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V283.Id.Id Evergreen.V283.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V283.Id.Id Evergreen.V283.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V283.Id.Id Evergreen.V283.Id.GuildId) (Evergreen.V283.SecretId.SecretId Evergreen.V283.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V283.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V283.Id.AnyGuildOrDmId Evergreen.V283.Id.ThreadRouteWithMessage (Evergreen.V283.Coord.Coord Evergreen.V283.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V283.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V283.Id.AnyGuildOrDmId Evergreen.V283.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V283.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V283.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V283.Id.AnyGuildOrDmId, Evergreen.V283.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V283.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V283.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V283.Id.AnyGuildOrDmId, Evergreen.V283.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V283.NonemptyDict.NonemptyDict Int Evergreen.V283.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V283.NonemptyDict.NonemptyDict Int Evergreen.V283.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V283.Id.AnyGuildOrDmId Evergreen.V283.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V283.Id.AnyGuildOrDmId Evergreen.V283.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V283.NonemptySet.NonemptySet (Evergreen.V283.Id.Id Evergreen.V283.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V283.Id.AnyGuildOrDmId, Evergreen.V283.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V283.Id.AnyGuildOrDmId Evergreen.V283.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V283.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V283.AiChat.Msg
    | GoMsg Evergreen.V283.Go.Msg
    | GoSpectatorMsg Evergreen.V283.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V283.Editable.Msg Evergreen.V283.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V283.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V283.Id.Id Evergreen.V283.Id.GuildId) Evergreen.V283.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V283.Id.AnyGuildOrDmId, Evergreen.V283.Id.ThreadRoute ) (Evergreen.V283.Id.Id Evergreen.V283.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V283.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V283.Id.AnyGuildOrDmId, Evergreen.V283.Id.ThreadRoute ) (Evergreen.V283.Id.Id Evergreen.V283.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V283.Id.AnyGuildOrDmId, Evergreen.V283.Id.ThreadRoute ) (Evergreen.V283.Id.Id Evergreen.V283.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V283.Id.AnyGuildOrDmId, Evergreen.V283.Id.ThreadRoute )
        { fileId : Evergreen.V283.Id.Id Evergreen.V283.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V283.Id.AnyGuildOrDmId, Evergreen.V283.Id.ThreadRoute ) (Evergreen.V283.Id.Id Evergreen.V283.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V283.Id.AnyGuildOrDmId, Evergreen.V283.Id.ThreadRoute ) (Evergreen.V283.Id.Id Evergreen.V283.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V283.Id.AnyGuildOrDmId, Evergreen.V283.Id.ThreadRoute )
        { fileId : Evergreen.V283.Id.Id Evergreen.V283.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V283.Id.AnyGuildOrDmId, Evergreen.V283.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V283.Id.AnyGuildOrDmId, Evergreen.V283.Id.ThreadRoute ) (Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelMessageId) (Evergreen.V283.Id.Id Evergreen.V283.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V283.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V283.Id.AnyGuildOrDmId, Evergreen.V283.Id.ThreadRoute ) (Evergreen.V283.Id.Id Evergreen.V283.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V283.Id.AnyGuildOrDmId Evergreen.V283.Id.ThreadRouteWithMessage Evergreen.V283.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V283.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V283.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V283.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V283.Id.Id Evergreen.V283.Id.GuildId) Evergreen.V283.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId) (Evergreen.V283.Discord.Id Evergreen.V283.Discord.GuildId) Evergreen.V283.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V283.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V283.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId
        , otherUserId : Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V283.Id.AnyGuildOrDmId Evergreen.V283.Id.ThreadRoute Evergreen.V283.MessageInput.Msg
    | MessageInputMsg Evergreen.V283.Id.AnyGuildOrDmId Evergreen.V283.Id.ThreadRoute Evergreen.V283.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V283.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V283.Range.Range, Evergreen.V283.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V283.Range.Range, Evergreen.V283.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V283.Call.FromJs)
    | VoiceChatMsg Evergreen.V283.Call.Msg
    | PressedChannelHeaderTab Evergreen.V283.Route.DmChannelHeaderTab
    | FileDragEnter
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadServiceWorkerData
    | GotServiceWorkerData String


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V283.Id.Id Evergreen.V283.Id.GuildId) (Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelId) Evergreen.V283.Id.ThreadRoute
    | InitialLoadRequested_Dm Evergreen.V283.DmChannel.DmChannelId Evergreen.V283.Id.ThreadRoute
    | InitialLoadRequested_Discord Evergreen.V283.Id.DiscordGuildOrDmId Evergreen.V283.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V283.Id.Id Evergreen.V283.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V283.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V283.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V283.Untrusted.Untrusted Evergreen.V283.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V283.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V283.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V283.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V283.Id.Id Evergreen.V283.Id.GuildId) (Evergreen.V283.SecretId.SecretId Evergreen.V283.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V283.PersonName.PersonName Evergreen.V283.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V283.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V283.Slack.OAuthCode Evergreen.V283.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V283.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V283.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V283.Id.Id Evergreen.V283.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V283.SecretId.SecretId Evergreen.V283.Id.GoMatchPublicId)


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V283.Discord.Id Evergreen.V283.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V283.Discord.Id Evergreen.V283.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V283.EmailAddress.EmailAddress (Result Evergreen.V283.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V283.EmailAddress.EmailAddress (Result Evergreen.V283.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V283.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V283.Discord.Id Evergreen.V283.Discord.GuildId) (Evergreen.V283.Discord.Id Evergreen.V283.Discord.ChannelId) Evergreen.V283.Id.ThreadRouteWithMaybeMessage (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId) (Result Evergreen.V283.Discord.HttpError Evergreen.V283.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V283.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V283.Discord.Id Evergreen.V283.Discord.PrivateChannelId) (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId) (Result Evergreen.V283.Discord.HttpError Evergreen.V283.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V283.Discord.Id Evergreen.V283.Discord.GuildId) (Evergreen.V283.Discord.Id Evergreen.V283.Discord.ChannelId) Evergreen.V283.Id.ThreadRouteWithMessage (Evergreen.V283.Discord.Id Evergreen.V283.Discord.MessageId) (Result Evergreen.V283.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V283.Discord.Id Evergreen.V283.Discord.PrivateChannelId) (Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelMessageId) (Evergreen.V283.Discord.Id Evergreen.V283.Discord.MessageId) (Result Evergreen.V283.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V283.Discord.Id Evergreen.V283.Discord.GuildId) (Evergreen.V283.Discord.Id Evergreen.V283.Discord.ChannelId) Evergreen.V283.Id.ThreadRouteWithMessage (Evergreen.V283.Discord.Id Evergreen.V283.Discord.MessageId) (Result Evergreen.V283.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V283.Discord.Id Evergreen.V283.Discord.PrivateChannelId) (Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelMessageId) (Evergreen.V283.Discord.Id Evergreen.V283.Discord.MessageId) (Result Evergreen.V283.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V283.Discord.Id Evergreen.V283.Discord.GuildId) (Evergreen.V283.Discord.Id Evergreen.V283.Discord.ChannelId) Evergreen.V283.Id.ThreadRouteWithMessage (Evergreen.V283.Discord.Id Evergreen.V283.Discord.MessageId) Evergreen.V283.Emoji.EmojiOrCustomEmoji (Result Evergreen.V283.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V283.Discord.Id Evergreen.V283.Discord.PrivateChannelId) (Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelMessageId) (Evergreen.V283.Discord.Id Evergreen.V283.Discord.MessageId) Evergreen.V283.Emoji.EmojiOrCustomEmoji (Result Evergreen.V283.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V283.Discord.Id Evergreen.V283.Discord.GuildId) (Evergreen.V283.Discord.Id Evergreen.V283.Discord.ChannelId) Evergreen.V283.Id.ThreadRouteWithMessage (Evergreen.V283.Discord.Id Evergreen.V283.Discord.MessageId) Evergreen.V283.Emoji.EmojiOrCustomEmoji (Result Evergreen.V283.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V283.Discord.Id Evergreen.V283.Discord.PrivateChannelId) (Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelMessageId) (Evergreen.V283.Discord.Id Evergreen.V283.Discord.MessageId) Evergreen.V283.Emoji.EmojiOrCustomEmoji (Result Evergreen.V283.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V283.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V283.Discord.HttpError (List ( Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId, Maybe Evergreen.V283.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V283.Id.Id Evergreen.V283.Id.UserId) Effect.Time.Posix Evergreen.V283.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V283.Id.Id Evergreen.V283.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V283.Slack.CurrentUser
            , team : Evergreen.V283.Slack.Team
            , users : List Evergreen.V283.Slack.User
            , channels : List ( Evergreen.V283.Slack.Channel, List Evergreen.V283.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V283.Id.Id Evergreen.V283.Id.UserId) (Result Effect.Http.Error Evergreen.V283.Slack.TokenResponse)
    | GotCloudflareSessionCreated Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V283.Local.ChangeId Effect.Time.Posix Evergreen.V283.Call.CallId Evergreen.V283.Cloudflare.Sdp (List String) (Result Effect.Http.Error Evergreen.V283.Cloudflare.RealtimeSessionId)
    | GotCloudflareSession Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V283.Local.ChangeId Effect.Time.Posix Evergreen.V283.Call.CallId Evergreen.V283.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V283.Cloudflare.PushTracksResult)
    | GotCloudflarePullOffer Effect.Time.Posix Effect.Lamdera.ClientId Evergreen.V283.Local.ChangeId Evergreen.V283.Call.ConnectionId Evergreen.V283.Cloudflare.RealtimeSessionId (List Evergreen.V283.Cloudflare.TrackName) (Result Effect.Http.Error Evergreen.V283.Cloudflare.PullTracksResult)
    | GotCloudflareRenegotiateAck Effect.Lamdera.ClientId Evergreen.V283.Local.ChangeId Evergreen.V283.Cloudflare.Sdp (Result Effect.Http.Error ())
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V283.Id.Id Evergreen.V283.Id.UserId) Evergreen.V283.Discord.UserAuth (Result Evergreen.V283.Discord.HttpError Evergreen.V283.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V283.Id.Id Evergreen.V283.Id.UserId) (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId) (Result Evergreen.V283.Discord.HttpError Evergreen.V283.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId)
        (Result
            Evergreen.V283.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V283.Discord.Id Evergreen.V283.Discord.PrivateChannelId
                , members : List (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId)
                }
            , List
                ( Evergreen.V283.Discord.Id Evergreen.V283.Discord.GuildId
                , { guild : Evergreen.V283.Discord.GatewayGuild
                  , channels : List Evergreen.V283.Discord.Channel
                  , icon : Maybe Evergreen.V283.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId) Bool Evergreen.V283.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V283.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V283.Discord.Id Evergreen.V283.Discord.AttachmentId, Evergreen.V283.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V283.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V283.Discord.Id Evergreen.V283.Discord.AttachmentId, Evergreen.V283.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId) (Evergreen.V283.Discord.Id Evergreen.V283.Discord.GuildId) (Evergreen.V283.Discord.Id Evergreen.V283.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V283.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V283.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId) (Evergreen.V283.Discord.Id Evergreen.V283.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V283.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V283.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId) (Evergreen.V283.Discord.Id Evergreen.V283.Discord.GuildId) (Evergreen.V283.Discord.Id Evergreen.V283.Discord.ChannelId) (Result Evergreen.V283.Discord.HttpError (List Evergreen.V283.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId) (Evergreen.V283.Discord.Id Evergreen.V283.Discord.PrivateChannelId) (Result Evergreen.V283.Discord.HttpError (List Evergreen.V283.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V283.Id.Id Evergreen.V283.Id.GuildId) (Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelId) Evergreen.V283.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V283.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V283.DmChannel.DmChannelId Evergreen.V283.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V283.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V283.Discord.Id Evergreen.V283.Discord.GuildId) (Evergreen.V283.Discord.Id Evergreen.V283.Discord.ChannelId) Evergreen.V283.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V283.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V283.Discord.Id Evergreen.V283.Discord.PrivateChannelId) (Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V283.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId)
        (Evergreen.V283.Discord.Id Evergreen.V283.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V283.Discord.HttpError
            { guild : Evergreen.V283.Discord.GatewayGuild
            , channels : List Evergreen.V283.Discord.Channel
            , icon : Maybe Evergreen.V283.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V283.Discord.Id Evergreen.V283.Discord.GuildId) (Result Evergreen.V283.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V283.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V283.Id.Id Evergreen.V283.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V283.Id.Id Evergreen.V283.Id.UserId) (List ( Evergreen.V283.Id.Id Evergreen.V283.Id.StickerId, Result Effect.Http.Error Evergreen.V283.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V283.Id.Id Evergreen.V283.Id.StickerId, Result Effect.Http.Error Evergreen.V283.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V283.Id.Id Evergreen.V283.Id.UserId) (List ( Evergreen.V283.Id.Id Evergreen.V283.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V283.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V283.Id.Id Evergreen.V283.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V283.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V283.Discord.HttpError (List Evergreen.V283.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V283.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V283.SecretId.SecretId Evergreen.V283.SecretId.ServerSecret))
    | GotTimeForWebsocketListenClose (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | GotCloudflareUsage Effect.Time.Posix (Result Effect.Http.Error Int)
    | GotCloudflareEgressForAdmin Effect.Lamdera.ClientId (Result Effect.Http.Error Int)
