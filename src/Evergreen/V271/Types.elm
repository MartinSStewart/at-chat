module Evergreen.V271.Types exposing (..)

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
import Evergreen.V271.AiChat
import Evergreen.V271.Call
import Evergreen.V271.ChannelDescription
import Evergreen.V271.ChannelName
import Evergreen.V271.Cloudflare
import Evergreen.V271.Coord
import Evergreen.V271.CssPixels
import Evergreen.V271.CustomEmoji
import Evergreen.V271.Discord
import Evergreen.V271.DiscordAttachmentId
import Evergreen.V271.DiscordUserData
import Evergreen.V271.DmChannel
import Evergreen.V271.Editable
import Evergreen.V271.EmailAddress
import Evergreen.V271.Embed
import Evergreen.V271.Emoji
import Evergreen.V271.FileStatus
import Evergreen.V271.Go
import Evergreen.V271.GuildName
import Evergreen.V271.Id
import Evergreen.V271.ImageEditor
import Evergreen.V271.ImageViewer
import Evergreen.V271.Local
import Evergreen.V271.LocalState
import Evergreen.V271.Log
import Evergreen.V271.LoginForm
import Evergreen.V271.MembersAndOwner
import Evergreen.V271.Message
import Evergreen.V271.MessageInput
import Evergreen.V271.MessageView
import Evergreen.V271.MyUi
import Evergreen.V271.NonemptyDict
import Evergreen.V271.NonemptySet
import Evergreen.V271.OneToOne
import Evergreen.V271.Pages.Admin
import Evergreen.V271.Pagination
import Evergreen.V271.PersonName
import Evergreen.V271.Ports
import Evergreen.V271.Postmark
import Evergreen.V271.Range
import Evergreen.V271.RichText
import Evergreen.V271.Route
import Evergreen.V271.SecretId
import Evergreen.V271.SessionIdHash
import Evergreen.V271.Slack
import Evergreen.V271.Sticker
import Evergreen.V271.TextEditor
import Evergreen.V271.ToBackendLog
import Evergreen.V271.Touch
import Evergreen.V271.TwoFactorAuthentication
import Evergreen.V271.Ui.Anim
import Evergreen.V271.Untrusted
import Evergreen.V271.User
import Evergreen.V271.UserAgent
import Evergreen.V271.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V271.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V271.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.Id.GuildId) Evergreen.V271.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId) Evergreen.V271.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V271.Discord.Id Evergreen.V271.Discord.PrivateChannelId) Evergreen.V271.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V271.Discord.Id Evergreen.V271.Discord.GuildId) Evergreen.V271.LocalState.DiscordFrontendGuild
    , user : Evergreen.V271.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId) Evergreen.V271.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId) Evergreen.V271.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId) Evergreen.V271.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V271.SessionIdHash.SessionIdHash Evergreen.V271.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V271.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.Id.StickerId) Evergreen.V271.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.Id.CustomEmojiId) Evergreen.V271.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V271.Call.CallId (Evergreen.V271.NonemptySet.NonemptySet ( Evergreen.V271.Id.Id Evergreen.V271.Id.UserId, Effect.Lamdera.ClientId ))
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type PublicGoMatch
    = PublicGoMatch_NotLoaded
    | PublicGoMatch_Loading
    | PublicGoMatch_Loaded Evergreen.V271.Go.PublicGoMatchData Evergreen.V271.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V271.Route.Route
    , windowSize : Evergreen.V271.Coord.Coord Evergreen.V271.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V271.Ports.NotificationPermission
    , pwaStatus : Evergreen.V271.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V271.UserAgent.UserAgent
    , publicGoMatch : PublicGoMatch
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V271.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V271.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V271.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.FileStatus.FileId) Evergreen.V271.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V271.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V271.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.FileStatus.FileId) Evergreen.V271.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V271.Id.Id Evergreen.V271.Id.GuildId) Evergreen.V271.ChannelName.ChannelName Evergreen.V271.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V271.Id.Id Evergreen.V271.Id.GuildId) (Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelId) Evergreen.V271.ChannelName.ChannelName Evergreen.V271.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V271.Id.Id Evergreen.V271.Id.GuildId) (Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelId)
    | Local_DeleteGuild (Evergreen.V271.Id.Id Evergreen.V271.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V271.Id.Id Evergreen.V271.Id.GuildId) (Evergreen.V271.UserSession.ToBeFilledInByBackend (Evergreen.V271.SecretId.SecretId Evergreen.V271.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V271.Id.Id Evergreen.V271.Id.GuildId) (Evergreen.V271.SecretId.SecretId Evergreen.V271.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V271.GuildName.GuildName (Evergreen.V271.UserSession.ToBeFilledInByBackend (Evergreen.V271.Id.Id Evergreen.V271.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V271.Id.AnyGuildOrDmId, Evergreen.V271.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V271.Id.AnyGuildOrDmId Evergreen.V271.Id.ThreadRouteWithMessage Evergreen.V271.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V271.Id.AnyGuildOrDmId Evergreen.V271.Id.ThreadRouteWithMessage Evergreen.V271.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V271.Id.GuildOrDmId Evergreen.V271.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.FileStatus.FileId) Evergreen.V271.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId) (Evergreen.V271.Discord.Id Evergreen.V271.Discord.GuildId) (Evergreen.V271.Discord.Id Evergreen.V271.Discord.ChannelId) Evergreen.V271.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V271.Id.DiscordGuildOrDmId_DmData (Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V271.Id.AnyGuildOrDmId Evergreen.V271.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V271.Id.AnyGuildOrDmId Evergreen.V271.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V271.Id.AnyGuildOrDmId Evergreen.V271.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V271.UserSession.SetViewing
    | Local_SetName Evergreen.V271.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V271.Id.GuildOrDmId (Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelMessageId) (Evergreen.V271.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelMessageId) (Evergreen.V271.Message.Message Evergreen.V271.Id.ChannelMessageId (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V271.Id.GuildOrDmId (Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelMessageId) (Evergreen.V271.Id.Id Evergreen.V271.Id.ThreadMessageId) (Evergreen.V271.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.Id.ThreadMessageId) (Evergreen.V271.Message.Message Evergreen.V271.Id.ThreadMessageId (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V271.Id.DiscordGuildOrDmId (Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelMessageId) (Evergreen.V271.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelMessageId) (Evergreen.V271.Message.Message Evergreen.V271.Id.ChannelMessageId (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V271.Id.DiscordGuildOrDmId (Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelMessageId) (Evergreen.V271.Id.Id Evergreen.V271.Id.ThreadMessageId) (Evergreen.V271.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.Id.ThreadMessageId) (Evergreen.V271.Message.Message Evergreen.V271.Id.ThreadMessageId (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V271.Id.Id Evergreen.V271.Id.GuildId) Evergreen.V271.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId) (Evergreen.V271.Discord.Id Evergreen.V271.Discord.GuildId) Evergreen.V271.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V271.UserSession.NotificationMode
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V271.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V271.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V271.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V271.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V271.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V271.NonemptySet.NonemptySet (Evergreen.V271.Id.Id Evergreen.V271.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V271.Call.LocalChange
    | Local_Go
        { otherUserId : Evergreen.V271.Id.Id Evergreen.V271.Id.UserId
        }
        Evergreen.V271.Go.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId) Effect.Time.Posix Evergreen.V271.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V271.RichText.RichText (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId))) Evergreen.V271.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.FileStatus.FileId) Evergreen.V271.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.Id.StickerId) Evergreen.V271.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V271.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V271.RichText.RichText (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId))) Evergreen.V271.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.FileStatus.FileId) Evergreen.V271.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.Id.StickerId) Evergreen.V271.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V271.Id.Id Evergreen.V271.Id.GuildId) Evergreen.V271.ChannelName.ChannelName Evergreen.V271.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V271.Id.Id Evergreen.V271.Id.GuildId) (Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelId) Evergreen.V271.ChannelName.ChannelName Evergreen.V271.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V271.Id.Id Evergreen.V271.Id.GuildId) (Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelId)
    | Server_DeleteGuild (Evergreen.V271.Id.Id Evergreen.V271.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId) (Evergreen.V271.Id.Id Evergreen.V271.Id.GuildId) (Evergreen.V271.SecretId.SecretId Evergreen.V271.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V271.Id.Id Evergreen.V271.Id.GuildId) (Evergreen.V271.SecretId.SecretId Evergreen.V271.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId) (Evergreen.V271.Id.Id Evergreen.V271.Id.GuildId) Evergreen.V271.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V271.LocalState.JoinGuildError
            { guildId : Evergreen.V271.Id.Id Evergreen.V271.Id.GuildId
            , guild : Evergreen.V271.LocalState.FrontendGuild
            , owner : Evergreen.V271.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId) Evergreen.V271.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId) Evergreen.V271.Id.GuildOrDmId Evergreen.V271.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId) (Evergreen.V271.Discord.Id Evergreen.V271.Discord.GuildId) (Evergreen.V271.Discord.Id Evergreen.V271.Discord.ChannelId) Evergreen.V271.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId) (Evergreen.V271.Discord.Id Evergreen.V271.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId) Evergreen.V271.Id.GuildOrDmId Evergreen.V271.Id.ThreadRouteWithMessage Evergreen.V271.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId) Evergreen.V271.Id.GuildOrDmId Evergreen.V271.Id.ThreadRouteWithMessage Evergreen.V271.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId) (Evergreen.V271.Discord.Id Evergreen.V271.Discord.GuildId) (Evergreen.V271.Discord.Id Evergreen.V271.Discord.ChannelId) Evergreen.V271.Id.ThreadRouteWithMessage Evergreen.V271.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId) (Evergreen.V271.Discord.Id Evergreen.V271.Discord.PrivateChannelId) (Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelMessageId) Evergreen.V271.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId) (Evergreen.V271.Discord.Id Evergreen.V271.Discord.GuildId) (Evergreen.V271.Discord.Id Evergreen.V271.Discord.ChannelId) Evergreen.V271.Id.ThreadRouteWithMessage Evergreen.V271.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId) (Evergreen.V271.Discord.Id Evergreen.V271.Discord.PrivateChannelId) (Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelMessageId) Evergreen.V271.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId) Evergreen.V271.Id.GuildOrDmId Evergreen.V271.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V271.RichText.RichText (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId))) (SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.FileStatus.FileId) Evergreen.V271.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId) (Evergreen.V271.Discord.Id Evergreen.V271.Discord.GuildId) (Evergreen.V271.Discord.Id Evergreen.V271.Discord.ChannelId) Evergreen.V271.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V271.RichText.RichText (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V271.Id.DiscordGuildOrDmId_DmData (Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V271.RichText.RichText (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId) Evergreen.V271.Id.AnyGuildOrDmId Evergreen.V271.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V271.Id.AnyGuildOrDmId Evergreen.V271.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V271.Discord.Id Evergreen.V271.Discord.GuildId) (Evergreen.V271.Discord.Id Evergreen.V271.Discord.ChannelId) Evergreen.V271.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V271.Discord.Id Evergreen.V271.Discord.PrivateChannelId) (Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId) Evergreen.V271.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId) Evergreen.V271.FileStatus.FileHash
    | Server_SetGuildIcon (Evergreen.V271.Id.Id Evergreen.V271.Id.GuildId) Evergreen.V271.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V271.Id.Id Evergreen.V271.Id.GuildId) Evergreen.V271.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V271.Discord.Id Evergreen.V271.Discord.GuildId) Evergreen.V271.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V271.SessionIdHash.SessionIdHash Evergreen.V271.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V271.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V271.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V271.Id.AnyGuildOrDmId, Evergreen.V271.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V271.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId) Evergreen.V271.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V271.Discord.Id Evergreen.V271.Discord.GuildId) (Evergreen.V271.Discord.Id Evergreen.V271.Discord.ChannelId) Evergreen.V271.ChannelName.ChannelName (Evergreen.V271.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V271.Discord.Id Evergreen.V271.Discord.PrivateChannelId)
        (Evergreen.V271.NonemptyDict.NonemptyDict
            (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V271.Discord.Id Evergreen.V271.Discord.GuildId) Evergreen.V271.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V271.Discord.Id Evergreen.V271.Discord.PrivateChannelId) Evergreen.V271.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId) Evergreen.V271.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId) (Maybe (Evergreen.V271.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V271.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V271.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V271.Id.Id Evergreen.V271.Id.GuildId) (Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelId) Evergreen.V271.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V271.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId) Evergreen.V271.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V271.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V271.Discord.Id Evergreen.V271.Discord.GuildId) (Evergreen.V271.Discord.Id Evergreen.V271.Discord.ChannelId) Evergreen.V271.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V271.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V271.Discord.Id Evergreen.V271.Discord.PrivateChannelId) (Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V271.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V271.Discord.Id Evergreen.V271.Discord.GuildId) Evergreen.V271.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V271.Discord.Id Evergreen.V271.Discord.GuildId) (Evergreen.V271.Discord.Id Evergreen.V271.Discord.ChannelId) (Evergreen.V271.Discord.OptionalData String) (Evergreen.V271.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V271.Discord.Id Evergreen.V271.Discord.GuildId)
        (Evergreen.V271.MembersAndOwner.MembersAndOwner
            (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V271.Discord.Id Evergreen.V271.Discord.GuildId) (Evergreen.V271.Discord.Id Evergreen.V271.Discord.ChannelId) (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId) Evergreen.V271.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.Id.StickerId) Evergreen.V271.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.Id.CustomEmojiId) Evergreen.V271.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V271.Call.ServerChange
    | Server_Go
        (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId)
        { otherUserId : Evergreen.V271.Id.Id Evergreen.V271.Id.UserId
        }
        Evergreen.V271.Go.LocalChange


type LocalMsg
    = LocalChange (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V271.Id.Id Evergreen.V271.Id.GuildId) (Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelId) Evergreen.V271.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V271.Discord.Id Evergreen.V271.Discord.GuildId) (Evergreen.V271.Discord.Id Evergreen.V271.Discord.ChannelId) Evergreen.V271.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.FileStatus.FileId) Evergreen.V271.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V271.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V271.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V271.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V271.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V271.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V271.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V271.Coord.Coord Evergreen.V271.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V271.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V271.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V271.Id.AnyGuildOrDmId Evergreen.V271.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V271.Id.AnyGuildOrDmId Evergreen.V271.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V271.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V271.Coord.Coord Evergreen.V271.CssPixels.CssPixels) (Maybe Evergreen.V271.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V271.Id.AnyGuildOrDmId, Evergreen.V271.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelMessageId) (Evergreen.V271.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.Id.ThreadMessageId) (Evergreen.V271.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V271.Editable.Model
    , showLinkDiscordSetup : Bool
    , domainWhitelistInput : String
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V271.Local.Local LocalMsg Evergreen.V271.LocalState.LocalState
    , admin : Evergreen.V271.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V271.Id.AnyGuildOrDmId, Evergreen.V271.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V271.Id.Id Evergreen.V271.Id.GuildId, Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V271.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V271.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V271.Id.AnyGuildOrDmId, Evergreen.V271.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V271.Id.AnyGuildOrDmId, Evergreen.V271.Id.ThreadRoute ) (Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : Evergreen.V271.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V271.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V271.Id.AnyGuildOrDmId, Evergreen.V271.Id.ThreadRoute ) (Evergreen.V271.NonemptyDict.NonemptyDict (Evergreen.V271.Id.Id Evergreen.V271.FileStatus.FileId) Evergreen.V271.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V271.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V271.TextEditor.Model
    , profilePictureEditor : Evergreen.V271.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V271.Id.Id Evergreen.V271.Id.GuildId, Evergreen.V271.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V271.Emoji.Model
    , voiceChat : Evergreen.V271.Call.Model
    , currentDmGoMatch : SeqDict.SeqDict ( Evergreen.V271.Id.Id Evergreen.V271.Id.UserId, Maybe (Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelMessageId) ) Evergreen.V271.Go.Model
    , fileDragOverCount : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V271.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V271.SecretId.SecretId Evergreen.V271.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V271.Range.Range
                , direction : Evergreen.V271.Range.SelectionDirection
                }
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V271.NonemptyDict.NonemptyDict Int Evergreen.V271.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V271.NonemptyDict.NonemptyDict Int Evergreen.V271.Touch.Touch
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
    | AdminToFrontend Evergreen.V271.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V271.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V271.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V271.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V271.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V271.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V271.Go.PublicGoMatchResponse)


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V271.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V271.Coord.Coord Evergreen.V271.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V271.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V271.MyUi.LastCopy
    , notificationPermission : Evergreen.V271.Ports.NotificationPermission
    , pwaStatus : Evergreen.V271.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V271.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V271.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V271.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V271.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V271.Id.Id Evergreen.V271.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V271.Id.Id Evergreen.V271.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V271.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V271.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V271.Coord.Coord Evergreen.V271.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V271.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V271.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V271.Id.Id Evergreen.V271.Id.GuildId, Evergreen.V271.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V271.DmChannel.DmChannelId, Evergreen.V271.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V271.Discord.Id Evergreen.V271.Discord.GuildId, Evergreen.V271.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V271.Discord.Id Evergreen.V271.Discord.PrivateChannelId, Evergreen.V271.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V271.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V271.NonemptyDict.NonemptyDict (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId) Evergreen.V271.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V271.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V271.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V271.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V271.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId) Evergreen.V271.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId) Evergreen.V271.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V271.Id.Id Evergreen.V271.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.Id.GuildId) Evergreen.V271.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.Id.GuildId) Evergreen.V271.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V271.Discord.Id Evergreen.V271.Discord.GuildId) Evergreen.V271.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V271.DmChannel.DmChannelId Evergreen.V271.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V271.Discord.Id Evergreen.V271.Discord.PrivateChannelId) Evergreen.V271.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V271.OneToOne.OneToOne (Evergreen.V271.Slack.Id Evergreen.V271.Slack.ChannelId) Evergreen.V271.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V271.OneToOne.OneToOne String (Evergreen.V271.Id.Id Evergreen.V271.Id.GuildId)
    , slackUsers : Evergreen.V271.OneToOne.OneToOne (Evergreen.V271.Slack.Id Evergreen.V271.Slack.UserId) (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId)
    , slackServers : Evergreen.V271.OneToOne.OneToOne (Evergreen.V271.Slack.Id Evergreen.V271.Slack.TeamId) (Evergreen.V271.Id.Id Evergreen.V271.Id.GuildId)
    , slackToken : Maybe Evergreen.V271.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V271.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V271.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V271.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V271.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V271.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V271.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V271.Cloudflare.AnalyticsApiToken
    , textEditor : Evergreen.V271.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId) Evergreen.V271.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId, Evergreen.V271.Discord.Id Evergreen.V271.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V271.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V271.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V271.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V271.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId) (Evergreen.V271.LocalState.LoadingDiscordChannel (List Evergreen.V271.Discord.Message))
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V271.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.Id.StickerId) Evergreen.V271.Sticker.StickerData
    , discordStickers : Evergreen.V271.OneToOne.OneToOne (Evergreen.V271.Discord.Id Evergreen.V271.Discord.StickerId) (Evergreen.V271.Id.Id Evergreen.V271.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.Id.CustomEmojiId) Evergreen.V271.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V271.OneToOne.OneToOne Evergreen.V271.RichText.DiscordCustomEmojiIdAndName (Evergreen.V271.Id.Id Evergreen.V271.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V271.Postmark.ApiKey
    , serverSecret : Evergreen.V271.SecretId.SecretId Evergreen.V271.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V271.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V271.OneToOne.OneToOne (Evergreen.V271.SecretId.SecretId Evergreen.V271.Id.GoMatchPublicId) ( Evergreen.V271.DmChannel.DmChannelId, Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelMessageId )
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V271.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V271.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V271.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V271.Route.Route
    | SelectedFilesToAttach ( Evergreen.V271.Id.AnyGuildOrDmId, Evergreen.V271.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V271.Id.Id Evergreen.V271.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V271.Id.Id Evergreen.V271.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V271.Id.Id Evergreen.V271.Id.GuildId) (Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelId) Evergreen.V271.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V271.Id.Id Evergreen.V271.Id.GuildId) (Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelId) Evergreen.V271.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V271.Discord.Id Evergreen.V271.Discord.GuildId) (Evergreen.V271.Discord.Id Evergreen.V271.Discord.ChannelId) Evergreen.V271.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V271.Discord.Id Evergreen.V271.Discord.GuildId) (Evergreen.V271.Discord.Id Evergreen.V271.Discord.ChannelId) Evergreen.V271.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V271.Id.Id Evergreen.V271.Id.GuildId) (Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V271.Id.Id Evergreen.V271.Id.GuildId) (Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V271.Id.Id Evergreen.V271.Id.GuildId) (Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V271.Id.Id Evergreen.V271.Id.GuildId) (Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V271.Id.Id Evergreen.V271.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V271.Id.Id Evergreen.V271.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V271.Id.Id Evergreen.V271.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V271.Id.Id Evergreen.V271.Id.GuildId) (Evergreen.V271.SecretId.SecretId Evergreen.V271.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V271.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V271.Id.AnyGuildOrDmId Evergreen.V271.Id.ThreadRouteWithMessage (Evergreen.V271.Coord.Coord Evergreen.V271.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V271.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V271.Id.AnyGuildOrDmId Evergreen.V271.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V271.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V271.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V271.Id.AnyGuildOrDmId, Evergreen.V271.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V271.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V271.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V271.Id.AnyGuildOrDmId, Evergreen.V271.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V271.NonemptyDict.NonemptyDict Int Evergreen.V271.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V271.NonemptyDict.NonemptyDict Int Evergreen.V271.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V271.Id.AnyGuildOrDmId Evergreen.V271.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V271.Id.AnyGuildOrDmId Evergreen.V271.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V271.NonemptySet.NonemptySet (Evergreen.V271.Id.Id Evergreen.V271.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V271.Id.AnyGuildOrDmId, Evergreen.V271.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V271.Id.AnyGuildOrDmId Evergreen.V271.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V271.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V271.AiChat.Msg
    | GoMsg Evergreen.V271.Go.Msg
    | GoSpectatorMsg Evergreen.V271.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V271.Editable.Msg Evergreen.V271.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V271.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V271.Id.Id Evergreen.V271.Id.GuildId) Evergreen.V271.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V271.Id.AnyGuildOrDmId, Evergreen.V271.Id.ThreadRoute ) (Evergreen.V271.Id.Id Evergreen.V271.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V271.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V271.Id.AnyGuildOrDmId, Evergreen.V271.Id.ThreadRoute ) (Evergreen.V271.Id.Id Evergreen.V271.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V271.Id.AnyGuildOrDmId, Evergreen.V271.Id.ThreadRoute ) (Evergreen.V271.Id.Id Evergreen.V271.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V271.Id.AnyGuildOrDmId, Evergreen.V271.Id.ThreadRoute )
        { fileId : Evergreen.V271.Id.Id Evergreen.V271.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V271.Id.AnyGuildOrDmId, Evergreen.V271.Id.ThreadRoute ) (Evergreen.V271.Id.Id Evergreen.V271.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V271.Id.AnyGuildOrDmId, Evergreen.V271.Id.ThreadRoute ) (Evergreen.V271.Id.Id Evergreen.V271.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V271.Id.AnyGuildOrDmId, Evergreen.V271.Id.ThreadRoute )
        { fileId : Evergreen.V271.Id.Id Evergreen.V271.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V271.Id.AnyGuildOrDmId, Evergreen.V271.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V271.Id.AnyGuildOrDmId, Evergreen.V271.Id.ThreadRoute ) (Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelMessageId) (Evergreen.V271.Id.Id Evergreen.V271.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V271.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V271.Id.AnyGuildOrDmId, Evergreen.V271.Id.ThreadRoute ) (Evergreen.V271.Id.Id Evergreen.V271.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V271.Id.AnyGuildOrDmId Evergreen.V271.Id.ThreadRouteWithMessage Evergreen.V271.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V271.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V271.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V271.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V271.Id.Id Evergreen.V271.Id.GuildId) Evergreen.V271.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId) (Evergreen.V271.Discord.Id Evergreen.V271.Discord.GuildId) Evergreen.V271.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V271.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V271.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId
        , otherUserId : Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V271.Id.AnyGuildOrDmId Evergreen.V271.Id.ThreadRoute Evergreen.V271.MessageInput.Msg
    | MessageInputMsg Evergreen.V271.Id.AnyGuildOrDmId Evergreen.V271.Id.ThreadRoute Evergreen.V271.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V271.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V271.Range.Range, Evergreen.V271.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V271.Range.Range, Evergreen.V271.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V271.Call.FromJs)
    | VoiceChatMsg Evergreen.V271.Call.Msg
    | PressedChannelHeaderTab Evergreen.V271.Route.DmChannelHeaderTab
    | FileDragEnter
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V271.Id.Id Evergreen.V271.Id.GuildId) (Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelId) Evergreen.V271.Id.ThreadRoute
    | InitialLoadRequested_Dm Evergreen.V271.DmChannel.DmChannelId Evergreen.V271.Id.ThreadRoute
    | InitialLoadRequested_Discord Evergreen.V271.Id.DiscordGuildOrDmId Evergreen.V271.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V271.Id.Id Evergreen.V271.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V271.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V271.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V271.Untrusted.Untrusted Evergreen.V271.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V271.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V271.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V271.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V271.Id.Id Evergreen.V271.Id.GuildId) (Evergreen.V271.SecretId.SecretId Evergreen.V271.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V271.PersonName.PersonName Evergreen.V271.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V271.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V271.Slack.OAuthCode Evergreen.V271.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V271.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V271.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V271.Id.Id Evergreen.V271.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V271.SecretId.SecretId Evergreen.V271.Id.GoMatchPublicId)


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V271.Discord.Id Evergreen.V271.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V271.Discord.Id Evergreen.V271.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V271.EmailAddress.EmailAddress (Result Evergreen.V271.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V271.EmailAddress.EmailAddress (Result Evergreen.V271.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V271.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V271.Discord.Id Evergreen.V271.Discord.GuildId) (Evergreen.V271.Discord.Id Evergreen.V271.Discord.ChannelId) Evergreen.V271.Id.ThreadRouteWithMaybeMessage (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId) (Result Evergreen.V271.Discord.HttpError Evergreen.V271.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V271.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V271.Discord.Id Evergreen.V271.Discord.PrivateChannelId) (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId) (Result Evergreen.V271.Discord.HttpError Evergreen.V271.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V271.Discord.Id Evergreen.V271.Discord.GuildId) (Evergreen.V271.Discord.Id Evergreen.V271.Discord.ChannelId) Evergreen.V271.Id.ThreadRouteWithMessage (Evergreen.V271.Discord.Id Evergreen.V271.Discord.MessageId) (Result Evergreen.V271.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V271.Discord.Id Evergreen.V271.Discord.PrivateChannelId) (Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelMessageId) (Evergreen.V271.Discord.Id Evergreen.V271.Discord.MessageId) (Result Evergreen.V271.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V271.Discord.Id Evergreen.V271.Discord.GuildId) (Evergreen.V271.Discord.Id Evergreen.V271.Discord.ChannelId) Evergreen.V271.Id.ThreadRouteWithMessage (Evergreen.V271.Discord.Id Evergreen.V271.Discord.MessageId) (Result Evergreen.V271.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V271.Discord.Id Evergreen.V271.Discord.PrivateChannelId) (Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelMessageId) (Evergreen.V271.Discord.Id Evergreen.V271.Discord.MessageId) (Result Evergreen.V271.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V271.Discord.Id Evergreen.V271.Discord.GuildId) (Evergreen.V271.Discord.Id Evergreen.V271.Discord.ChannelId) Evergreen.V271.Id.ThreadRouteWithMessage (Evergreen.V271.Discord.Id Evergreen.V271.Discord.MessageId) Evergreen.V271.Emoji.EmojiOrCustomEmoji (Result Evergreen.V271.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V271.Discord.Id Evergreen.V271.Discord.PrivateChannelId) (Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelMessageId) (Evergreen.V271.Discord.Id Evergreen.V271.Discord.MessageId) Evergreen.V271.Emoji.EmojiOrCustomEmoji (Result Evergreen.V271.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V271.Discord.Id Evergreen.V271.Discord.GuildId) (Evergreen.V271.Discord.Id Evergreen.V271.Discord.ChannelId) Evergreen.V271.Id.ThreadRouteWithMessage (Evergreen.V271.Discord.Id Evergreen.V271.Discord.MessageId) Evergreen.V271.Emoji.EmojiOrCustomEmoji (Result Evergreen.V271.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V271.Discord.Id Evergreen.V271.Discord.PrivateChannelId) (Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelMessageId) (Evergreen.V271.Discord.Id Evergreen.V271.Discord.MessageId) Evergreen.V271.Emoji.EmojiOrCustomEmoji (Result Evergreen.V271.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V271.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V271.Discord.HttpError (List ( Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId, Maybe Evergreen.V271.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V271.Slack.CurrentUser
            , team : Evergreen.V271.Slack.Team
            , users : List Evergreen.V271.Slack.User
            , channels : List ( Evergreen.V271.Slack.Channel, List Evergreen.V271.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId) (Result Effect.Http.Error Evergreen.V271.Slack.TokenResponse)
    | GotCloudflareSessionCreated Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V271.Local.ChangeId Effect.Time.Posix Evergreen.V271.Call.CallId Evergreen.V271.Cloudflare.Sdp (List String) (Result Effect.Http.Error Evergreen.V271.Cloudflare.RealtimeSessionId)
    | GotCloudflareSession Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V271.Local.ChangeId Effect.Time.Posix Evergreen.V271.Call.CallId Evergreen.V271.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V271.Cloudflare.PushTracksResult)
    | GotCloudflarePullOffer Effect.Time.Posix Effect.Lamdera.ClientId Evergreen.V271.Local.ChangeId Evergreen.V271.Call.ConnectionId Evergreen.V271.Cloudflare.RealtimeSessionId (List Evergreen.V271.Cloudflare.TrackName) (Result Effect.Http.Error Evergreen.V271.Cloudflare.PullTracksResult)
    | GotCloudflareRenegotiateAck Effect.Lamdera.ClientId Evergreen.V271.Local.ChangeId Evergreen.V271.Cloudflare.Sdp (Result Effect.Http.Error ())
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId) Evergreen.V271.Discord.UserAuth (Result Evergreen.V271.Discord.HttpError Evergreen.V271.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId) (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId) (Result Evergreen.V271.Discord.HttpError Evergreen.V271.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId)
        (Result
            Evergreen.V271.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V271.Discord.Id Evergreen.V271.Discord.PrivateChannelId
                , members : List (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId)
                }
            , List
                ( Evergreen.V271.Discord.Id Evergreen.V271.Discord.GuildId
                , { guild : Evergreen.V271.Discord.GatewayGuild
                  , channels : List Evergreen.V271.Discord.Channel
                  , icon : Maybe Evergreen.V271.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId) Bool Evergreen.V271.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V271.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V271.Discord.Id Evergreen.V271.Discord.AttachmentId, Evergreen.V271.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V271.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V271.Discord.Id Evergreen.V271.Discord.AttachmentId, Evergreen.V271.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId) (Evergreen.V271.Discord.Id Evergreen.V271.Discord.GuildId) (Evergreen.V271.Discord.Id Evergreen.V271.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V271.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V271.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId) (Evergreen.V271.Discord.Id Evergreen.V271.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V271.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V271.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId) (Evergreen.V271.Discord.Id Evergreen.V271.Discord.GuildId) (Evergreen.V271.Discord.Id Evergreen.V271.Discord.ChannelId) (Result Evergreen.V271.Discord.HttpError (List Evergreen.V271.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId) (Evergreen.V271.Discord.Id Evergreen.V271.Discord.PrivateChannelId) (Result Evergreen.V271.Discord.HttpError (List Evergreen.V271.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V271.Id.Id Evergreen.V271.Id.GuildId) (Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelId) Evergreen.V271.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V271.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V271.DmChannel.DmChannelId Evergreen.V271.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V271.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V271.Discord.Id Evergreen.V271.Discord.GuildId) (Evergreen.V271.Discord.Id Evergreen.V271.Discord.ChannelId) Evergreen.V271.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V271.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V271.Discord.Id Evergreen.V271.Discord.PrivateChannelId) (Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V271.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId)
        (Evergreen.V271.Discord.Id Evergreen.V271.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V271.Discord.HttpError
            { guild : Evergreen.V271.Discord.GatewayGuild
            , channels : List Evergreen.V271.Discord.Channel
            , icon : Maybe Evergreen.V271.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V271.Discord.Id Evergreen.V271.Discord.GuildId) (Result Evergreen.V271.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V271.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId) (List ( Evergreen.V271.Id.Id Evergreen.V271.Id.StickerId, Result Effect.Http.Error Evergreen.V271.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V271.Id.Id Evergreen.V271.Id.StickerId, Result Effect.Http.Error Evergreen.V271.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId) (List ( Evergreen.V271.Id.Id Evergreen.V271.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V271.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V271.Id.Id Evergreen.V271.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V271.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V271.Discord.HttpError (List Evergreen.V271.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V271.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V271.SecretId.SecretId Evergreen.V271.SecretId.ServerSecret))
    | GotTimeForWebsocketListenClose (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | GotCloudflareUsage Effect.Time.Posix (Result Effect.Http.Error Int)
    | GotCloudflareEgressForAdmin Effect.Lamdera.ClientId (Result Effect.Http.Error Int)
