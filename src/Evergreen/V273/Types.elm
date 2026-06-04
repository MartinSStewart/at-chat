module Evergreen.V273.Types exposing (..)

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
import Evergreen.V273.AiChat
import Evergreen.V273.Call
import Evergreen.V273.ChannelDescription
import Evergreen.V273.ChannelName
import Evergreen.V273.Cloudflare
import Evergreen.V273.Coord
import Evergreen.V273.CssPixels
import Evergreen.V273.CustomEmoji
import Evergreen.V273.Discord
import Evergreen.V273.DiscordAttachmentId
import Evergreen.V273.DiscordUserData
import Evergreen.V273.DmChannel
import Evergreen.V273.Editable
import Evergreen.V273.EmailAddress
import Evergreen.V273.Embed
import Evergreen.V273.Emoji
import Evergreen.V273.FileStatus
import Evergreen.V273.Go
import Evergreen.V273.GuildName
import Evergreen.V273.Id
import Evergreen.V273.ImageEditor
import Evergreen.V273.ImageViewer
import Evergreen.V273.Local
import Evergreen.V273.LocalState
import Evergreen.V273.Log
import Evergreen.V273.LoginForm
import Evergreen.V273.MembersAndOwner
import Evergreen.V273.Message
import Evergreen.V273.MessageInput
import Evergreen.V273.MessageView
import Evergreen.V273.MyUi
import Evergreen.V273.NonemptyDict
import Evergreen.V273.NonemptySet
import Evergreen.V273.OneToOne
import Evergreen.V273.Pages.Admin
import Evergreen.V273.Pagination
import Evergreen.V273.PersonName
import Evergreen.V273.Ports
import Evergreen.V273.Postmark
import Evergreen.V273.Range
import Evergreen.V273.RichText
import Evergreen.V273.Route
import Evergreen.V273.SecretId
import Evergreen.V273.SessionIdHash
import Evergreen.V273.Slack
import Evergreen.V273.Sticker
import Evergreen.V273.TextEditor
import Evergreen.V273.ToBackendLog
import Evergreen.V273.Touch
import Evergreen.V273.TwoFactorAuthentication
import Evergreen.V273.Ui.Anim
import Evergreen.V273.Untrusted
import Evergreen.V273.User
import Evergreen.V273.UserAgent
import Evergreen.V273.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V273.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V273.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.Id.GuildId) Evergreen.V273.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId) Evergreen.V273.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V273.Discord.Id Evergreen.V273.Discord.PrivateChannelId) Evergreen.V273.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V273.Discord.Id Evergreen.V273.Discord.GuildId) Evergreen.V273.LocalState.DiscordFrontendGuild
    , user : Evergreen.V273.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId) Evergreen.V273.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId) Evergreen.V273.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId) Evergreen.V273.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V273.SessionIdHash.SessionIdHash Evergreen.V273.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V273.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.Id.StickerId) Evergreen.V273.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.Id.CustomEmojiId) Evergreen.V273.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V273.Call.CallId (Evergreen.V273.NonemptySet.NonemptySet ( Evergreen.V273.Id.Id Evergreen.V273.Id.UserId, Effect.Lamdera.ClientId ))
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type PublicGoMatch
    = PublicGoMatch_NotLoaded
    | PublicGoMatch_Loading
    | PublicGoMatch_Loaded Evergreen.V273.Go.PublicGoMatchData Evergreen.V273.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V273.Route.Route
    , windowSize : Evergreen.V273.Coord.Coord Evergreen.V273.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V273.Ports.NotificationPermission
    , pwaStatus : Evergreen.V273.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V273.UserAgent.UserAgent
    , publicGoMatch : PublicGoMatch
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V273.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V273.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V273.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.FileStatus.FileId) Evergreen.V273.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V273.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V273.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.FileStatus.FileId) Evergreen.V273.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V273.Id.Id Evergreen.V273.Id.GuildId) Evergreen.V273.ChannelName.ChannelName Evergreen.V273.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V273.Id.Id Evergreen.V273.Id.GuildId) (Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelId) Evergreen.V273.ChannelName.ChannelName Evergreen.V273.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V273.Id.Id Evergreen.V273.Id.GuildId) (Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelId)
    | Local_DeleteGuild (Evergreen.V273.Id.Id Evergreen.V273.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V273.Id.Id Evergreen.V273.Id.GuildId) (Evergreen.V273.UserSession.ToBeFilledInByBackend (Evergreen.V273.SecretId.SecretId Evergreen.V273.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V273.Id.Id Evergreen.V273.Id.GuildId) (Evergreen.V273.SecretId.SecretId Evergreen.V273.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V273.GuildName.GuildName (Evergreen.V273.UserSession.ToBeFilledInByBackend (Evergreen.V273.Id.Id Evergreen.V273.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V273.Id.AnyGuildOrDmId, Evergreen.V273.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V273.Id.AnyGuildOrDmId Evergreen.V273.Id.ThreadRouteWithMessage Evergreen.V273.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V273.Id.AnyGuildOrDmId Evergreen.V273.Id.ThreadRouteWithMessage Evergreen.V273.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V273.Id.GuildOrDmId Evergreen.V273.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.FileStatus.FileId) Evergreen.V273.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId) (Evergreen.V273.Discord.Id Evergreen.V273.Discord.GuildId) (Evergreen.V273.Discord.Id Evergreen.V273.Discord.ChannelId) Evergreen.V273.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V273.Id.DiscordGuildOrDmId_DmData (Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V273.Id.AnyGuildOrDmId Evergreen.V273.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V273.Id.AnyGuildOrDmId Evergreen.V273.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V273.Id.AnyGuildOrDmId Evergreen.V273.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V273.UserSession.SetViewing
    | Local_SetName Evergreen.V273.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V273.Id.GuildOrDmId (Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelMessageId) (Evergreen.V273.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelMessageId) (Evergreen.V273.Message.Message Evergreen.V273.Id.ChannelMessageId (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V273.Id.GuildOrDmId (Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelMessageId) (Evergreen.V273.Id.Id Evergreen.V273.Id.ThreadMessageId) (Evergreen.V273.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.Id.ThreadMessageId) (Evergreen.V273.Message.Message Evergreen.V273.Id.ThreadMessageId (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V273.Id.DiscordGuildOrDmId (Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelMessageId) (Evergreen.V273.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelMessageId) (Evergreen.V273.Message.Message Evergreen.V273.Id.ChannelMessageId (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V273.Id.DiscordGuildOrDmId (Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelMessageId) (Evergreen.V273.Id.Id Evergreen.V273.Id.ThreadMessageId) (Evergreen.V273.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.Id.ThreadMessageId) (Evergreen.V273.Message.Message Evergreen.V273.Id.ThreadMessageId (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V273.Id.Id Evergreen.V273.Id.GuildId) Evergreen.V273.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId) (Evergreen.V273.Discord.Id Evergreen.V273.Discord.GuildId) Evergreen.V273.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V273.UserSession.NotificationMode
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V273.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V273.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V273.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V273.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V273.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V273.NonemptySet.NonemptySet (Evergreen.V273.Id.Id Evergreen.V273.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V273.Call.LocalChange
    | Local_Go
        { otherUserId : Evergreen.V273.Id.Id Evergreen.V273.Id.UserId
        }
        Evergreen.V273.Go.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId) Effect.Time.Posix Evergreen.V273.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V273.RichText.RichText (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId))) Evergreen.V273.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.FileStatus.FileId) Evergreen.V273.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.Id.StickerId) Evergreen.V273.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V273.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V273.RichText.RichText (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId))) Evergreen.V273.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.FileStatus.FileId) Evergreen.V273.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.Id.StickerId) Evergreen.V273.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V273.Id.Id Evergreen.V273.Id.GuildId) Evergreen.V273.ChannelName.ChannelName Evergreen.V273.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V273.Id.Id Evergreen.V273.Id.GuildId) (Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelId) Evergreen.V273.ChannelName.ChannelName Evergreen.V273.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V273.Id.Id Evergreen.V273.Id.GuildId) (Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelId)
    | Server_DeleteGuild (Evergreen.V273.Id.Id Evergreen.V273.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId) (Evergreen.V273.Id.Id Evergreen.V273.Id.GuildId) (Evergreen.V273.SecretId.SecretId Evergreen.V273.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V273.Id.Id Evergreen.V273.Id.GuildId) (Evergreen.V273.SecretId.SecretId Evergreen.V273.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId) (Evergreen.V273.Id.Id Evergreen.V273.Id.GuildId) Evergreen.V273.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V273.LocalState.JoinGuildError
            { guildId : Evergreen.V273.Id.Id Evergreen.V273.Id.GuildId
            , guild : Evergreen.V273.LocalState.FrontendGuild
            , owner : Evergreen.V273.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId) Evergreen.V273.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId) Evergreen.V273.Id.GuildOrDmId Evergreen.V273.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId) (Evergreen.V273.Discord.Id Evergreen.V273.Discord.GuildId) (Evergreen.V273.Discord.Id Evergreen.V273.Discord.ChannelId) Evergreen.V273.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId) (Evergreen.V273.Discord.Id Evergreen.V273.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId) Evergreen.V273.Id.GuildOrDmId Evergreen.V273.Id.ThreadRouteWithMessage Evergreen.V273.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId) Evergreen.V273.Id.GuildOrDmId Evergreen.V273.Id.ThreadRouteWithMessage Evergreen.V273.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId) (Evergreen.V273.Discord.Id Evergreen.V273.Discord.GuildId) (Evergreen.V273.Discord.Id Evergreen.V273.Discord.ChannelId) Evergreen.V273.Id.ThreadRouteWithMessage Evergreen.V273.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId) (Evergreen.V273.Discord.Id Evergreen.V273.Discord.PrivateChannelId) (Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelMessageId) Evergreen.V273.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId) (Evergreen.V273.Discord.Id Evergreen.V273.Discord.GuildId) (Evergreen.V273.Discord.Id Evergreen.V273.Discord.ChannelId) Evergreen.V273.Id.ThreadRouteWithMessage Evergreen.V273.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId) (Evergreen.V273.Discord.Id Evergreen.V273.Discord.PrivateChannelId) (Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelMessageId) Evergreen.V273.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId) Evergreen.V273.Id.GuildOrDmId Evergreen.V273.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V273.RichText.RichText (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId))) (SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.FileStatus.FileId) Evergreen.V273.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId) (Evergreen.V273.Discord.Id Evergreen.V273.Discord.GuildId) (Evergreen.V273.Discord.Id Evergreen.V273.Discord.ChannelId) Evergreen.V273.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V273.RichText.RichText (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V273.Id.DiscordGuildOrDmId_DmData (Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V273.RichText.RichText (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId) Evergreen.V273.Id.AnyGuildOrDmId Evergreen.V273.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V273.Id.AnyGuildOrDmId Evergreen.V273.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V273.Discord.Id Evergreen.V273.Discord.GuildId) (Evergreen.V273.Discord.Id Evergreen.V273.Discord.ChannelId) Evergreen.V273.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V273.Discord.Id Evergreen.V273.Discord.PrivateChannelId) (Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId) Evergreen.V273.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId) Evergreen.V273.FileStatus.FileHash
    | Server_SetGuildIcon (Evergreen.V273.Id.Id Evergreen.V273.Id.GuildId) Evergreen.V273.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V273.Id.Id Evergreen.V273.Id.GuildId) Evergreen.V273.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V273.Discord.Id Evergreen.V273.Discord.GuildId) Evergreen.V273.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V273.SessionIdHash.SessionIdHash Evergreen.V273.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V273.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V273.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V273.Id.AnyGuildOrDmId, Evergreen.V273.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V273.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId) Evergreen.V273.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V273.Discord.Id Evergreen.V273.Discord.GuildId) (Evergreen.V273.Discord.Id Evergreen.V273.Discord.ChannelId) Evergreen.V273.ChannelName.ChannelName (Evergreen.V273.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V273.Discord.Id Evergreen.V273.Discord.PrivateChannelId)
        (Evergreen.V273.NonemptyDict.NonemptyDict
            (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V273.Discord.Id Evergreen.V273.Discord.GuildId) Evergreen.V273.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V273.Discord.Id Evergreen.V273.Discord.PrivateChannelId) Evergreen.V273.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId) Evergreen.V273.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId) (Maybe (Evergreen.V273.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V273.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V273.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V273.Id.Id Evergreen.V273.Id.GuildId) (Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelId) Evergreen.V273.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V273.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId) Evergreen.V273.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V273.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V273.Discord.Id Evergreen.V273.Discord.GuildId) (Evergreen.V273.Discord.Id Evergreen.V273.Discord.ChannelId) Evergreen.V273.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V273.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V273.Discord.Id Evergreen.V273.Discord.PrivateChannelId) (Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V273.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V273.Discord.Id Evergreen.V273.Discord.GuildId) Evergreen.V273.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V273.Discord.Id Evergreen.V273.Discord.GuildId) (Evergreen.V273.Discord.Id Evergreen.V273.Discord.ChannelId) (Evergreen.V273.Discord.OptionalData String) (Evergreen.V273.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V273.Discord.Id Evergreen.V273.Discord.GuildId)
        (Evergreen.V273.MembersAndOwner.MembersAndOwner
            (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V273.Discord.Id Evergreen.V273.Discord.GuildId) (Evergreen.V273.Discord.Id Evergreen.V273.Discord.ChannelId) (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId) Evergreen.V273.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.Id.StickerId) Evergreen.V273.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.Id.CustomEmojiId) Evergreen.V273.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V273.Call.ServerChange
    | Server_Go
        (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId)
        { otherUserId : Evergreen.V273.Id.Id Evergreen.V273.Id.UserId
        }
        Evergreen.V273.Go.LocalChange


type LocalMsg
    = LocalChange (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V273.Id.Id Evergreen.V273.Id.GuildId) (Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelId) Evergreen.V273.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V273.Discord.Id Evergreen.V273.Discord.GuildId) (Evergreen.V273.Discord.Id Evergreen.V273.Discord.ChannelId) Evergreen.V273.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.FileStatus.FileId) Evergreen.V273.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V273.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V273.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V273.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V273.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V273.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V273.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V273.Coord.Coord Evergreen.V273.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V273.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V273.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V273.Id.AnyGuildOrDmId Evergreen.V273.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V273.Id.AnyGuildOrDmId Evergreen.V273.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V273.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V273.Coord.Coord Evergreen.V273.CssPixels.CssPixels) (Maybe Evergreen.V273.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V273.Id.AnyGuildOrDmId, Evergreen.V273.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelMessageId) (Evergreen.V273.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.Id.ThreadMessageId) (Evergreen.V273.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V273.Editable.Model
    , showLinkDiscordSetup : Bool
    , domainWhitelistInput : String
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V273.Local.Local LocalMsg Evergreen.V273.LocalState.LocalState
    , admin : Evergreen.V273.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V273.Id.AnyGuildOrDmId, Evergreen.V273.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V273.Id.Id Evergreen.V273.Id.GuildId, Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V273.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V273.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V273.Id.AnyGuildOrDmId, Evergreen.V273.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V273.Id.AnyGuildOrDmId, Evergreen.V273.Id.ThreadRoute ) (Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : Evergreen.V273.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V273.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V273.Id.AnyGuildOrDmId, Evergreen.V273.Id.ThreadRoute ) (Evergreen.V273.NonemptyDict.NonemptyDict (Evergreen.V273.Id.Id Evergreen.V273.FileStatus.FileId) Evergreen.V273.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V273.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V273.TextEditor.Model
    , profilePictureEditor : Evergreen.V273.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V273.Id.Id Evergreen.V273.Id.GuildId, Evergreen.V273.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V273.Emoji.Model
    , voiceChat : Evergreen.V273.Call.Model
    , currentDmGoMatch : SeqDict.SeqDict ( Evergreen.V273.Id.Id Evergreen.V273.Id.UserId, Maybe (Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelMessageId) ) Evergreen.V273.Go.Model
    , fileDragOverCount : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V273.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V273.SecretId.SecretId Evergreen.V273.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V273.Range.Range
                , direction : Evergreen.V273.Range.SelectionDirection
                }
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V273.NonemptyDict.NonemptyDict Int Evergreen.V273.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V273.NonemptyDict.NonemptyDict Int Evergreen.V273.Touch.Touch
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
    | AdminToFrontend Evergreen.V273.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V273.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V273.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V273.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V273.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V273.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V273.Go.PublicGoMatchResponse)


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V273.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V273.Coord.Coord Evergreen.V273.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V273.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V273.MyUi.LastCopy
    , notificationPermission : Evergreen.V273.Ports.NotificationPermission
    , pwaStatus : Evergreen.V273.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V273.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V273.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V273.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V273.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V273.Id.Id Evergreen.V273.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V273.Id.Id Evergreen.V273.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V273.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V273.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V273.Coord.Coord Evergreen.V273.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V273.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V273.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V273.Id.Id Evergreen.V273.Id.GuildId, Evergreen.V273.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V273.DmChannel.DmChannelId, Evergreen.V273.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V273.Discord.Id Evergreen.V273.Discord.GuildId, Evergreen.V273.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V273.Discord.Id Evergreen.V273.Discord.PrivateChannelId, Evergreen.V273.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V273.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V273.NonemptyDict.NonemptyDict (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId) Evergreen.V273.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V273.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V273.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V273.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V273.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId) Evergreen.V273.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId) Evergreen.V273.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V273.Id.Id Evergreen.V273.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.Id.GuildId) Evergreen.V273.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.Id.GuildId) Evergreen.V273.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V273.Discord.Id Evergreen.V273.Discord.GuildId) Evergreen.V273.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V273.DmChannel.DmChannelId Evergreen.V273.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V273.Discord.Id Evergreen.V273.Discord.PrivateChannelId) Evergreen.V273.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V273.OneToOne.OneToOne (Evergreen.V273.Slack.Id Evergreen.V273.Slack.ChannelId) Evergreen.V273.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V273.OneToOne.OneToOne String (Evergreen.V273.Id.Id Evergreen.V273.Id.GuildId)
    , slackUsers : Evergreen.V273.OneToOne.OneToOne (Evergreen.V273.Slack.Id Evergreen.V273.Slack.UserId) (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId)
    , slackServers : Evergreen.V273.OneToOne.OneToOne (Evergreen.V273.Slack.Id Evergreen.V273.Slack.TeamId) (Evergreen.V273.Id.Id Evergreen.V273.Id.GuildId)
    , slackToken : Maybe Evergreen.V273.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V273.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V273.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V273.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V273.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V273.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V273.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V273.Cloudflare.AnalyticsApiToken
    , textEditor : Evergreen.V273.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId) Evergreen.V273.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId, Evergreen.V273.Discord.Id Evergreen.V273.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V273.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V273.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V273.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V273.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId) (Evergreen.V273.LocalState.LoadingDiscordChannel (List Evergreen.V273.Discord.Message))
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V273.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.Id.StickerId) Evergreen.V273.Sticker.StickerData
    , discordStickers : Evergreen.V273.OneToOne.OneToOne (Evergreen.V273.Discord.Id Evergreen.V273.Discord.StickerId) (Evergreen.V273.Id.Id Evergreen.V273.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.Id.CustomEmojiId) Evergreen.V273.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V273.OneToOne.OneToOne Evergreen.V273.RichText.DiscordCustomEmojiIdAndName (Evergreen.V273.Id.Id Evergreen.V273.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V273.Postmark.ApiKey
    , serverSecret : Evergreen.V273.SecretId.SecretId Evergreen.V273.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V273.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V273.OneToOne.OneToOne (Evergreen.V273.SecretId.SecretId Evergreen.V273.Id.GoMatchPublicId) ( Evergreen.V273.DmChannel.DmChannelId, Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelMessageId )
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V273.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V273.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V273.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V273.Route.Route
    | SelectedFilesToAttach ( Evergreen.V273.Id.AnyGuildOrDmId, Evergreen.V273.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V273.Id.Id Evergreen.V273.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V273.Id.Id Evergreen.V273.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V273.Id.Id Evergreen.V273.Id.GuildId) (Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelId) Evergreen.V273.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V273.Id.Id Evergreen.V273.Id.GuildId) (Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelId) Evergreen.V273.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V273.Discord.Id Evergreen.V273.Discord.GuildId) (Evergreen.V273.Discord.Id Evergreen.V273.Discord.ChannelId) Evergreen.V273.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V273.Discord.Id Evergreen.V273.Discord.GuildId) (Evergreen.V273.Discord.Id Evergreen.V273.Discord.ChannelId) Evergreen.V273.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V273.Id.Id Evergreen.V273.Id.GuildId) (Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V273.Id.Id Evergreen.V273.Id.GuildId) (Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V273.Id.Id Evergreen.V273.Id.GuildId) (Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V273.Id.Id Evergreen.V273.Id.GuildId) (Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V273.Id.Id Evergreen.V273.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V273.Id.Id Evergreen.V273.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V273.Id.Id Evergreen.V273.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V273.Id.Id Evergreen.V273.Id.GuildId) (Evergreen.V273.SecretId.SecretId Evergreen.V273.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V273.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V273.Id.AnyGuildOrDmId Evergreen.V273.Id.ThreadRouteWithMessage (Evergreen.V273.Coord.Coord Evergreen.V273.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V273.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V273.Id.AnyGuildOrDmId Evergreen.V273.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V273.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V273.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V273.Id.AnyGuildOrDmId, Evergreen.V273.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V273.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V273.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V273.Id.AnyGuildOrDmId, Evergreen.V273.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V273.NonemptyDict.NonemptyDict Int Evergreen.V273.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V273.NonemptyDict.NonemptyDict Int Evergreen.V273.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V273.Id.AnyGuildOrDmId Evergreen.V273.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V273.Id.AnyGuildOrDmId Evergreen.V273.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V273.NonemptySet.NonemptySet (Evergreen.V273.Id.Id Evergreen.V273.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V273.Id.AnyGuildOrDmId, Evergreen.V273.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V273.Id.AnyGuildOrDmId Evergreen.V273.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V273.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V273.AiChat.Msg
    | GoMsg Evergreen.V273.Go.Msg
    | GoSpectatorMsg Evergreen.V273.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V273.Editable.Msg Evergreen.V273.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V273.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V273.Id.Id Evergreen.V273.Id.GuildId) Evergreen.V273.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V273.Id.AnyGuildOrDmId, Evergreen.V273.Id.ThreadRoute ) (Evergreen.V273.Id.Id Evergreen.V273.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V273.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V273.Id.AnyGuildOrDmId, Evergreen.V273.Id.ThreadRoute ) (Evergreen.V273.Id.Id Evergreen.V273.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V273.Id.AnyGuildOrDmId, Evergreen.V273.Id.ThreadRoute ) (Evergreen.V273.Id.Id Evergreen.V273.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V273.Id.AnyGuildOrDmId, Evergreen.V273.Id.ThreadRoute )
        { fileId : Evergreen.V273.Id.Id Evergreen.V273.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V273.Id.AnyGuildOrDmId, Evergreen.V273.Id.ThreadRoute ) (Evergreen.V273.Id.Id Evergreen.V273.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V273.Id.AnyGuildOrDmId, Evergreen.V273.Id.ThreadRoute ) (Evergreen.V273.Id.Id Evergreen.V273.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V273.Id.AnyGuildOrDmId, Evergreen.V273.Id.ThreadRoute )
        { fileId : Evergreen.V273.Id.Id Evergreen.V273.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V273.Id.AnyGuildOrDmId, Evergreen.V273.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V273.Id.AnyGuildOrDmId, Evergreen.V273.Id.ThreadRoute ) (Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelMessageId) (Evergreen.V273.Id.Id Evergreen.V273.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V273.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V273.Id.AnyGuildOrDmId, Evergreen.V273.Id.ThreadRoute ) (Evergreen.V273.Id.Id Evergreen.V273.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V273.Id.AnyGuildOrDmId Evergreen.V273.Id.ThreadRouteWithMessage Evergreen.V273.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V273.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V273.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V273.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V273.Id.Id Evergreen.V273.Id.GuildId) Evergreen.V273.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId) (Evergreen.V273.Discord.Id Evergreen.V273.Discord.GuildId) Evergreen.V273.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V273.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V273.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId
        , otherUserId : Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V273.Id.AnyGuildOrDmId Evergreen.V273.Id.ThreadRoute Evergreen.V273.MessageInput.Msg
    | MessageInputMsg Evergreen.V273.Id.AnyGuildOrDmId Evergreen.V273.Id.ThreadRoute Evergreen.V273.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V273.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V273.Range.Range, Evergreen.V273.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V273.Range.Range, Evergreen.V273.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V273.Call.FromJs)
    | VoiceChatMsg Evergreen.V273.Call.Msg
    | PressedChannelHeaderTab Evergreen.V273.Route.DmChannelHeaderTab
    | FileDragEnter
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V273.Id.Id Evergreen.V273.Id.GuildId) (Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelId) Evergreen.V273.Id.ThreadRoute
    | InitialLoadRequested_Dm Evergreen.V273.DmChannel.DmChannelId Evergreen.V273.Id.ThreadRoute
    | InitialLoadRequested_Discord Evergreen.V273.Id.DiscordGuildOrDmId Evergreen.V273.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V273.Id.Id Evergreen.V273.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V273.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V273.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V273.Untrusted.Untrusted Evergreen.V273.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V273.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V273.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V273.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V273.Id.Id Evergreen.V273.Id.GuildId) (Evergreen.V273.SecretId.SecretId Evergreen.V273.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V273.PersonName.PersonName Evergreen.V273.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V273.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V273.Slack.OAuthCode Evergreen.V273.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V273.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V273.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V273.Id.Id Evergreen.V273.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V273.SecretId.SecretId Evergreen.V273.Id.GoMatchPublicId)


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V273.Discord.Id Evergreen.V273.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V273.Discord.Id Evergreen.V273.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V273.EmailAddress.EmailAddress (Result Evergreen.V273.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V273.EmailAddress.EmailAddress (Result Evergreen.V273.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V273.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V273.Discord.Id Evergreen.V273.Discord.GuildId) (Evergreen.V273.Discord.Id Evergreen.V273.Discord.ChannelId) Evergreen.V273.Id.ThreadRouteWithMaybeMessage (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId) (Result Evergreen.V273.Discord.HttpError Evergreen.V273.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V273.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V273.Discord.Id Evergreen.V273.Discord.PrivateChannelId) (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId) (Result Evergreen.V273.Discord.HttpError Evergreen.V273.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V273.Discord.Id Evergreen.V273.Discord.GuildId) (Evergreen.V273.Discord.Id Evergreen.V273.Discord.ChannelId) Evergreen.V273.Id.ThreadRouteWithMessage (Evergreen.V273.Discord.Id Evergreen.V273.Discord.MessageId) (Result Evergreen.V273.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V273.Discord.Id Evergreen.V273.Discord.PrivateChannelId) (Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelMessageId) (Evergreen.V273.Discord.Id Evergreen.V273.Discord.MessageId) (Result Evergreen.V273.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V273.Discord.Id Evergreen.V273.Discord.GuildId) (Evergreen.V273.Discord.Id Evergreen.V273.Discord.ChannelId) Evergreen.V273.Id.ThreadRouteWithMessage (Evergreen.V273.Discord.Id Evergreen.V273.Discord.MessageId) (Result Evergreen.V273.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V273.Discord.Id Evergreen.V273.Discord.PrivateChannelId) (Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelMessageId) (Evergreen.V273.Discord.Id Evergreen.V273.Discord.MessageId) (Result Evergreen.V273.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V273.Discord.Id Evergreen.V273.Discord.GuildId) (Evergreen.V273.Discord.Id Evergreen.V273.Discord.ChannelId) Evergreen.V273.Id.ThreadRouteWithMessage (Evergreen.V273.Discord.Id Evergreen.V273.Discord.MessageId) Evergreen.V273.Emoji.EmojiOrCustomEmoji (Result Evergreen.V273.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V273.Discord.Id Evergreen.V273.Discord.PrivateChannelId) (Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelMessageId) (Evergreen.V273.Discord.Id Evergreen.V273.Discord.MessageId) Evergreen.V273.Emoji.EmojiOrCustomEmoji (Result Evergreen.V273.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V273.Discord.Id Evergreen.V273.Discord.GuildId) (Evergreen.V273.Discord.Id Evergreen.V273.Discord.ChannelId) Evergreen.V273.Id.ThreadRouteWithMessage (Evergreen.V273.Discord.Id Evergreen.V273.Discord.MessageId) Evergreen.V273.Emoji.EmojiOrCustomEmoji (Result Evergreen.V273.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V273.Discord.Id Evergreen.V273.Discord.PrivateChannelId) (Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelMessageId) (Evergreen.V273.Discord.Id Evergreen.V273.Discord.MessageId) Evergreen.V273.Emoji.EmojiOrCustomEmoji (Result Evergreen.V273.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V273.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V273.Discord.HttpError (List ( Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId, Maybe Evergreen.V273.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V273.Slack.CurrentUser
            , team : Evergreen.V273.Slack.Team
            , users : List Evergreen.V273.Slack.User
            , channels : List ( Evergreen.V273.Slack.Channel, List Evergreen.V273.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId) (Result Effect.Http.Error Evergreen.V273.Slack.TokenResponse)
    | GotCloudflareSessionCreated Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V273.Local.ChangeId Effect.Time.Posix Evergreen.V273.Call.CallId Evergreen.V273.Cloudflare.Sdp (List String) (Result Effect.Http.Error Evergreen.V273.Cloudflare.RealtimeSessionId)
    | GotCloudflareSession Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V273.Local.ChangeId Effect.Time.Posix Evergreen.V273.Call.CallId Evergreen.V273.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V273.Cloudflare.PushTracksResult)
    | GotCloudflarePullOffer Effect.Time.Posix Effect.Lamdera.ClientId Evergreen.V273.Local.ChangeId Evergreen.V273.Call.ConnectionId Evergreen.V273.Cloudflare.RealtimeSessionId (List Evergreen.V273.Cloudflare.TrackName) (Result Effect.Http.Error Evergreen.V273.Cloudflare.PullTracksResult)
    | GotCloudflareRenegotiateAck Effect.Lamdera.ClientId Evergreen.V273.Local.ChangeId Evergreen.V273.Cloudflare.Sdp (Result Effect.Http.Error ())
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId) Evergreen.V273.Discord.UserAuth (Result Evergreen.V273.Discord.HttpError Evergreen.V273.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId) (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId) (Result Evergreen.V273.Discord.HttpError Evergreen.V273.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId)
        (Result
            Evergreen.V273.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V273.Discord.Id Evergreen.V273.Discord.PrivateChannelId
                , members : List (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId)
                }
            , List
                ( Evergreen.V273.Discord.Id Evergreen.V273.Discord.GuildId
                , { guild : Evergreen.V273.Discord.GatewayGuild
                  , channels : List Evergreen.V273.Discord.Channel
                  , icon : Maybe Evergreen.V273.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId) Bool Evergreen.V273.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V273.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V273.Discord.Id Evergreen.V273.Discord.AttachmentId, Evergreen.V273.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V273.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V273.Discord.Id Evergreen.V273.Discord.AttachmentId, Evergreen.V273.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId) (Evergreen.V273.Discord.Id Evergreen.V273.Discord.GuildId) (Evergreen.V273.Discord.Id Evergreen.V273.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V273.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V273.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId) (Evergreen.V273.Discord.Id Evergreen.V273.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V273.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V273.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId) (Evergreen.V273.Discord.Id Evergreen.V273.Discord.GuildId) (Evergreen.V273.Discord.Id Evergreen.V273.Discord.ChannelId) (Result Evergreen.V273.Discord.HttpError (List Evergreen.V273.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId) (Evergreen.V273.Discord.Id Evergreen.V273.Discord.PrivateChannelId) (Result Evergreen.V273.Discord.HttpError (List Evergreen.V273.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V273.Id.Id Evergreen.V273.Id.GuildId) (Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelId) Evergreen.V273.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V273.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V273.DmChannel.DmChannelId Evergreen.V273.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V273.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V273.Discord.Id Evergreen.V273.Discord.GuildId) (Evergreen.V273.Discord.Id Evergreen.V273.Discord.ChannelId) Evergreen.V273.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V273.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V273.Discord.Id Evergreen.V273.Discord.PrivateChannelId) (Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V273.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId)
        (Evergreen.V273.Discord.Id Evergreen.V273.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V273.Discord.HttpError
            { guild : Evergreen.V273.Discord.GatewayGuild
            , channels : List Evergreen.V273.Discord.Channel
            , icon : Maybe Evergreen.V273.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V273.Discord.Id Evergreen.V273.Discord.GuildId) (Result Evergreen.V273.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V273.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId) (List ( Evergreen.V273.Id.Id Evergreen.V273.Id.StickerId, Result Effect.Http.Error Evergreen.V273.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V273.Id.Id Evergreen.V273.Id.StickerId, Result Effect.Http.Error Evergreen.V273.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId) (List ( Evergreen.V273.Id.Id Evergreen.V273.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V273.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V273.Id.Id Evergreen.V273.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V273.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V273.Discord.HttpError (List Evergreen.V273.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V273.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V273.SecretId.SecretId Evergreen.V273.SecretId.ServerSecret))
    | GotTimeForWebsocketListenClose (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | GotCloudflareUsage Effect.Time.Posix (Result Effect.Http.Error Int)
    | GotCloudflareEgressForAdmin Effect.Lamdera.ClientId (Result Effect.Http.Error Int)
