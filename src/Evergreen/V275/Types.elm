module Evergreen.V275.Types exposing (..)

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
import Evergreen.V275.AiChat
import Evergreen.V275.Call
import Evergreen.V275.ChannelDescription
import Evergreen.V275.ChannelName
import Evergreen.V275.Cloudflare
import Evergreen.V275.Coord
import Evergreen.V275.CssPixels
import Evergreen.V275.CustomEmoji
import Evergreen.V275.Discord
import Evergreen.V275.DiscordAttachmentId
import Evergreen.V275.DiscordUserData
import Evergreen.V275.DmChannel
import Evergreen.V275.Editable
import Evergreen.V275.EmailAddress
import Evergreen.V275.Embed
import Evergreen.V275.Emoji
import Evergreen.V275.FileStatus
import Evergreen.V275.Go
import Evergreen.V275.GuildName
import Evergreen.V275.Id
import Evergreen.V275.ImageEditor
import Evergreen.V275.ImageViewer
import Evergreen.V275.Local
import Evergreen.V275.LocalState
import Evergreen.V275.Log
import Evergreen.V275.LoginForm
import Evergreen.V275.MembersAndOwner
import Evergreen.V275.Message
import Evergreen.V275.MessageInput
import Evergreen.V275.MessageView
import Evergreen.V275.MyUi
import Evergreen.V275.NonemptyDict
import Evergreen.V275.NonemptySet
import Evergreen.V275.OneToOne
import Evergreen.V275.Pages.Admin
import Evergreen.V275.Pagination
import Evergreen.V275.PersonName
import Evergreen.V275.Ports
import Evergreen.V275.Postmark
import Evergreen.V275.Range
import Evergreen.V275.RichText
import Evergreen.V275.Route
import Evergreen.V275.SecretId
import Evergreen.V275.SessionIdHash
import Evergreen.V275.Slack
import Evergreen.V275.Sticker
import Evergreen.V275.TextEditor
import Evergreen.V275.ToBackendLog
import Evergreen.V275.Touch
import Evergreen.V275.TwoFactorAuthentication
import Evergreen.V275.Ui.Anim
import Evergreen.V275.Untrusted
import Evergreen.V275.User
import Evergreen.V275.UserAgent
import Evergreen.V275.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V275.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V275.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.Id.GuildId) Evergreen.V275.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId) Evergreen.V275.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V275.Discord.Id Evergreen.V275.Discord.PrivateChannelId) Evergreen.V275.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V275.Discord.Id Evergreen.V275.Discord.GuildId) Evergreen.V275.LocalState.DiscordFrontendGuild
    , user : Evergreen.V275.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId) Evergreen.V275.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId) Evergreen.V275.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId) Evergreen.V275.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V275.SessionIdHash.SessionIdHash Evergreen.V275.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V275.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.Id.StickerId) Evergreen.V275.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.Id.CustomEmojiId) Evergreen.V275.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V275.Call.CallId (Evergreen.V275.NonemptySet.NonemptySet ( Evergreen.V275.Id.Id Evergreen.V275.Id.UserId, Effect.Lamdera.ClientId ))
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type PublicGoMatch
    = PublicGoMatch_NotLoaded
    | PublicGoMatch_Loading
    | PublicGoMatch_Loaded Evergreen.V275.Go.PublicGoMatchData Evergreen.V275.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V275.Route.Route
    , windowSize : Evergreen.V275.Coord.Coord Evergreen.V275.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V275.Ports.NotificationPermission
    , pwaStatus : Evergreen.V275.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V275.UserAgent.UserAgent
    , publicGoMatch : PublicGoMatch
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V275.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V275.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V275.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.FileStatus.FileId) Evergreen.V275.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V275.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V275.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.FileStatus.FileId) Evergreen.V275.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V275.Id.Id Evergreen.V275.Id.GuildId) Evergreen.V275.ChannelName.ChannelName Evergreen.V275.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V275.Id.Id Evergreen.V275.Id.GuildId) (Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelId) Evergreen.V275.ChannelName.ChannelName Evergreen.V275.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V275.Id.Id Evergreen.V275.Id.GuildId) (Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelId)
    | Local_DeleteGuild (Evergreen.V275.Id.Id Evergreen.V275.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V275.Id.Id Evergreen.V275.Id.GuildId) (Evergreen.V275.UserSession.ToBeFilledInByBackend (Evergreen.V275.SecretId.SecretId Evergreen.V275.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V275.Id.Id Evergreen.V275.Id.GuildId) (Evergreen.V275.SecretId.SecretId Evergreen.V275.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V275.GuildName.GuildName (Evergreen.V275.UserSession.ToBeFilledInByBackend (Evergreen.V275.Id.Id Evergreen.V275.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V275.Id.AnyGuildOrDmId, Evergreen.V275.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V275.Id.AnyGuildOrDmId Evergreen.V275.Id.ThreadRouteWithMessage Evergreen.V275.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V275.Id.AnyGuildOrDmId Evergreen.V275.Id.ThreadRouteWithMessage Evergreen.V275.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V275.Id.GuildOrDmId Evergreen.V275.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.FileStatus.FileId) Evergreen.V275.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId) (Evergreen.V275.Discord.Id Evergreen.V275.Discord.GuildId) (Evergreen.V275.Discord.Id Evergreen.V275.Discord.ChannelId) Evergreen.V275.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V275.Id.DiscordGuildOrDmId_DmData (Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V275.Id.AnyGuildOrDmId Evergreen.V275.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V275.Id.AnyGuildOrDmId Evergreen.V275.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V275.Id.AnyGuildOrDmId Evergreen.V275.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V275.UserSession.SetViewing
    | Local_SetName Evergreen.V275.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V275.Id.GuildOrDmId (Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelMessageId) (Evergreen.V275.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelMessageId) (Evergreen.V275.Message.Message Evergreen.V275.Id.ChannelMessageId (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V275.Id.GuildOrDmId (Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelMessageId) (Evergreen.V275.Id.Id Evergreen.V275.Id.ThreadMessageId) (Evergreen.V275.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.Id.ThreadMessageId) (Evergreen.V275.Message.Message Evergreen.V275.Id.ThreadMessageId (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V275.Id.DiscordGuildOrDmId (Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelMessageId) (Evergreen.V275.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelMessageId) (Evergreen.V275.Message.Message Evergreen.V275.Id.ChannelMessageId (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V275.Id.DiscordGuildOrDmId (Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelMessageId) (Evergreen.V275.Id.Id Evergreen.V275.Id.ThreadMessageId) (Evergreen.V275.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.Id.ThreadMessageId) (Evergreen.V275.Message.Message Evergreen.V275.Id.ThreadMessageId (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V275.Id.Id Evergreen.V275.Id.GuildId) Evergreen.V275.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId) (Evergreen.V275.Discord.Id Evergreen.V275.Discord.GuildId) Evergreen.V275.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V275.UserSession.NotificationMode
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V275.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V275.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V275.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V275.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V275.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V275.NonemptySet.NonemptySet (Evergreen.V275.Id.Id Evergreen.V275.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V275.Call.LocalChange
    | Local_Go
        { otherUserId : Evergreen.V275.Id.Id Evergreen.V275.Id.UserId
        }
        Evergreen.V275.Go.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId) Effect.Time.Posix Evergreen.V275.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V275.RichText.RichText (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId))) Evergreen.V275.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.FileStatus.FileId) Evergreen.V275.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.Id.StickerId) Evergreen.V275.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V275.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V275.RichText.RichText (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId))) Evergreen.V275.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.FileStatus.FileId) Evergreen.V275.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.Id.StickerId) Evergreen.V275.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V275.Id.Id Evergreen.V275.Id.GuildId) Evergreen.V275.ChannelName.ChannelName Evergreen.V275.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V275.Id.Id Evergreen.V275.Id.GuildId) (Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelId) Evergreen.V275.ChannelName.ChannelName Evergreen.V275.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V275.Id.Id Evergreen.V275.Id.GuildId) (Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelId)
    | Server_DeleteGuild (Evergreen.V275.Id.Id Evergreen.V275.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId) (Evergreen.V275.Id.Id Evergreen.V275.Id.GuildId) (Evergreen.V275.SecretId.SecretId Evergreen.V275.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V275.Id.Id Evergreen.V275.Id.GuildId) (Evergreen.V275.SecretId.SecretId Evergreen.V275.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId) (Evergreen.V275.Id.Id Evergreen.V275.Id.GuildId) Evergreen.V275.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V275.LocalState.JoinGuildError
            { guildId : Evergreen.V275.Id.Id Evergreen.V275.Id.GuildId
            , guild : Evergreen.V275.LocalState.FrontendGuild
            , owner : Evergreen.V275.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId) Evergreen.V275.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId) Evergreen.V275.Id.GuildOrDmId Evergreen.V275.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId) (Evergreen.V275.Discord.Id Evergreen.V275.Discord.GuildId) (Evergreen.V275.Discord.Id Evergreen.V275.Discord.ChannelId) Evergreen.V275.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId) (Evergreen.V275.Discord.Id Evergreen.V275.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId) Evergreen.V275.Id.GuildOrDmId Evergreen.V275.Id.ThreadRouteWithMessage Evergreen.V275.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId) Evergreen.V275.Id.GuildOrDmId Evergreen.V275.Id.ThreadRouteWithMessage Evergreen.V275.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId) (Evergreen.V275.Discord.Id Evergreen.V275.Discord.GuildId) (Evergreen.V275.Discord.Id Evergreen.V275.Discord.ChannelId) Evergreen.V275.Id.ThreadRouteWithMessage Evergreen.V275.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId) (Evergreen.V275.Discord.Id Evergreen.V275.Discord.PrivateChannelId) (Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelMessageId) Evergreen.V275.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId) (Evergreen.V275.Discord.Id Evergreen.V275.Discord.GuildId) (Evergreen.V275.Discord.Id Evergreen.V275.Discord.ChannelId) Evergreen.V275.Id.ThreadRouteWithMessage Evergreen.V275.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId) (Evergreen.V275.Discord.Id Evergreen.V275.Discord.PrivateChannelId) (Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelMessageId) Evergreen.V275.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId) Evergreen.V275.Id.GuildOrDmId Evergreen.V275.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V275.RichText.RichText (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId))) (SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.FileStatus.FileId) Evergreen.V275.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId) (Evergreen.V275.Discord.Id Evergreen.V275.Discord.GuildId) (Evergreen.V275.Discord.Id Evergreen.V275.Discord.ChannelId) Evergreen.V275.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V275.RichText.RichText (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V275.Id.DiscordGuildOrDmId_DmData (Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V275.RichText.RichText (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId) Evergreen.V275.Id.AnyGuildOrDmId Evergreen.V275.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V275.Id.AnyGuildOrDmId Evergreen.V275.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V275.Discord.Id Evergreen.V275.Discord.GuildId) (Evergreen.V275.Discord.Id Evergreen.V275.Discord.ChannelId) Evergreen.V275.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V275.Discord.Id Evergreen.V275.Discord.PrivateChannelId) (Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId) Evergreen.V275.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId) Evergreen.V275.FileStatus.FileHash
    | Server_SetGuildIcon (Evergreen.V275.Id.Id Evergreen.V275.Id.GuildId) Evergreen.V275.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V275.Id.Id Evergreen.V275.Id.GuildId) Evergreen.V275.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V275.Discord.Id Evergreen.V275.Discord.GuildId) Evergreen.V275.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V275.SessionIdHash.SessionIdHash Evergreen.V275.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V275.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V275.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V275.Id.AnyGuildOrDmId, Evergreen.V275.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V275.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId) Evergreen.V275.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V275.Discord.Id Evergreen.V275.Discord.GuildId) (Evergreen.V275.Discord.Id Evergreen.V275.Discord.ChannelId) Evergreen.V275.ChannelName.ChannelName (Evergreen.V275.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V275.Discord.Id Evergreen.V275.Discord.PrivateChannelId)
        (Evergreen.V275.NonemptyDict.NonemptyDict
            (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V275.Discord.Id Evergreen.V275.Discord.GuildId) Evergreen.V275.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V275.Discord.Id Evergreen.V275.Discord.PrivateChannelId) Evergreen.V275.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId) Evergreen.V275.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId) (Maybe (Evergreen.V275.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V275.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V275.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V275.Id.Id Evergreen.V275.Id.GuildId) (Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelId) Evergreen.V275.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V275.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId) Evergreen.V275.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V275.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V275.Discord.Id Evergreen.V275.Discord.GuildId) (Evergreen.V275.Discord.Id Evergreen.V275.Discord.ChannelId) Evergreen.V275.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V275.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V275.Discord.Id Evergreen.V275.Discord.PrivateChannelId) (Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V275.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V275.Discord.Id Evergreen.V275.Discord.GuildId) Evergreen.V275.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V275.Discord.Id Evergreen.V275.Discord.GuildId) (Evergreen.V275.Discord.Id Evergreen.V275.Discord.ChannelId) (Evergreen.V275.Discord.OptionalData String) (Evergreen.V275.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V275.Discord.Id Evergreen.V275.Discord.GuildId)
        (Evergreen.V275.MembersAndOwner.MembersAndOwner
            (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V275.Discord.Id Evergreen.V275.Discord.GuildId) (Evergreen.V275.Discord.Id Evergreen.V275.Discord.ChannelId) (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId) Evergreen.V275.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.Id.StickerId) Evergreen.V275.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.Id.CustomEmojiId) Evergreen.V275.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V275.Call.ServerChange
    | Server_Go
        (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId)
        { otherUserId : Evergreen.V275.Id.Id Evergreen.V275.Id.UserId
        }
        Evergreen.V275.Go.LocalChange


type LocalMsg
    = LocalChange (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V275.Id.Id Evergreen.V275.Id.GuildId) (Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelId) Evergreen.V275.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V275.Discord.Id Evergreen.V275.Discord.GuildId) (Evergreen.V275.Discord.Id Evergreen.V275.Discord.ChannelId) Evergreen.V275.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.FileStatus.FileId) Evergreen.V275.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V275.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V275.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V275.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V275.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V275.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V275.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V275.Coord.Coord Evergreen.V275.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V275.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V275.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V275.Id.AnyGuildOrDmId Evergreen.V275.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V275.Id.AnyGuildOrDmId Evergreen.V275.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V275.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V275.Coord.Coord Evergreen.V275.CssPixels.CssPixels) (Maybe Evergreen.V275.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V275.Id.AnyGuildOrDmId, Evergreen.V275.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelMessageId) (Evergreen.V275.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.Id.ThreadMessageId) (Evergreen.V275.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V275.Editable.Model
    , showLinkDiscordSetup : Bool
    , domainWhitelistInput : String
    , serviceWorkerData : Maybe String
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V275.Local.Local LocalMsg Evergreen.V275.LocalState.LocalState
    , admin : Evergreen.V275.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V275.Id.AnyGuildOrDmId, Evergreen.V275.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V275.Id.Id Evergreen.V275.Id.GuildId, Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V275.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V275.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V275.Id.AnyGuildOrDmId, Evergreen.V275.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V275.Id.AnyGuildOrDmId, Evergreen.V275.Id.ThreadRoute ) (Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : Evergreen.V275.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V275.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V275.Id.AnyGuildOrDmId, Evergreen.V275.Id.ThreadRoute ) (Evergreen.V275.NonemptyDict.NonemptyDict (Evergreen.V275.Id.Id Evergreen.V275.FileStatus.FileId) Evergreen.V275.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V275.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V275.TextEditor.Model
    , profilePictureEditor : Evergreen.V275.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V275.Id.Id Evergreen.V275.Id.GuildId, Evergreen.V275.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V275.Emoji.Model
    , voiceChat : Evergreen.V275.Call.Model
    , currentDmGoMatch : SeqDict.SeqDict ( Evergreen.V275.Id.Id Evergreen.V275.Id.UserId, Maybe (Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelMessageId) ) Evergreen.V275.Go.Model
    , fileDragOverCount : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V275.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V275.SecretId.SecretId Evergreen.V275.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V275.Range.Range
                , direction : Evergreen.V275.Range.SelectionDirection
                }
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V275.NonemptyDict.NonemptyDict Int Evergreen.V275.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V275.NonemptyDict.NonemptyDict Int Evergreen.V275.Touch.Touch
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
    | AdminToFrontend Evergreen.V275.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V275.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V275.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V275.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V275.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V275.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V275.Go.PublicGoMatchResponse)


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V275.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V275.Coord.Coord Evergreen.V275.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V275.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V275.MyUi.LastCopy
    , notificationPermission : Evergreen.V275.Ports.NotificationPermission
    , pwaStatus : Evergreen.V275.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V275.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V275.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V275.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V275.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V275.Id.Id Evergreen.V275.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V275.Id.Id Evergreen.V275.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V275.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V275.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V275.Coord.Coord Evergreen.V275.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V275.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V275.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V275.Id.Id Evergreen.V275.Id.GuildId, Evergreen.V275.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V275.DmChannel.DmChannelId, Evergreen.V275.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V275.Discord.Id Evergreen.V275.Discord.GuildId, Evergreen.V275.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V275.Discord.Id Evergreen.V275.Discord.PrivateChannelId, Evergreen.V275.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V275.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V275.NonemptyDict.NonemptyDict (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId) Evergreen.V275.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V275.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V275.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V275.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V275.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId) Evergreen.V275.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId) Evergreen.V275.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V275.Id.Id Evergreen.V275.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.Id.GuildId) Evergreen.V275.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.Id.GuildId) Evergreen.V275.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V275.Discord.Id Evergreen.V275.Discord.GuildId) Evergreen.V275.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V275.DmChannel.DmChannelId Evergreen.V275.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V275.Discord.Id Evergreen.V275.Discord.PrivateChannelId) Evergreen.V275.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V275.OneToOne.OneToOne (Evergreen.V275.Slack.Id Evergreen.V275.Slack.ChannelId) Evergreen.V275.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V275.OneToOne.OneToOne String (Evergreen.V275.Id.Id Evergreen.V275.Id.GuildId)
    , slackUsers : Evergreen.V275.OneToOne.OneToOne (Evergreen.V275.Slack.Id Evergreen.V275.Slack.UserId) (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId)
    , slackServers : Evergreen.V275.OneToOne.OneToOne (Evergreen.V275.Slack.Id Evergreen.V275.Slack.TeamId) (Evergreen.V275.Id.Id Evergreen.V275.Id.GuildId)
    , slackToken : Maybe Evergreen.V275.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V275.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V275.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V275.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V275.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V275.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V275.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V275.Cloudflare.AnalyticsApiToken
    , textEditor : Evergreen.V275.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId) Evergreen.V275.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId, Evergreen.V275.Discord.Id Evergreen.V275.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V275.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V275.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V275.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V275.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId) (Evergreen.V275.LocalState.LoadingDiscordChannel (List Evergreen.V275.Discord.Message))
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V275.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.Id.StickerId) Evergreen.V275.Sticker.StickerData
    , discordStickers : Evergreen.V275.OneToOne.OneToOne (Evergreen.V275.Discord.Id Evergreen.V275.Discord.StickerId) (Evergreen.V275.Id.Id Evergreen.V275.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.Id.CustomEmojiId) Evergreen.V275.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V275.OneToOne.OneToOne Evergreen.V275.RichText.DiscordCustomEmojiIdAndName (Evergreen.V275.Id.Id Evergreen.V275.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V275.Postmark.ApiKey
    , serverSecret : Evergreen.V275.SecretId.SecretId Evergreen.V275.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V275.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V275.OneToOne.OneToOne (Evergreen.V275.SecretId.SecretId Evergreen.V275.Id.GoMatchPublicId) ( Evergreen.V275.DmChannel.DmChannelId, Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelMessageId )
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V275.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V275.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V275.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V275.Route.Route
    | SelectedFilesToAttach ( Evergreen.V275.Id.AnyGuildOrDmId, Evergreen.V275.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V275.Id.Id Evergreen.V275.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V275.Id.Id Evergreen.V275.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V275.Id.Id Evergreen.V275.Id.GuildId) (Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelId) Evergreen.V275.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V275.Id.Id Evergreen.V275.Id.GuildId) (Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelId) Evergreen.V275.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V275.Discord.Id Evergreen.V275.Discord.GuildId) (Evergreen.V275.Discord.Id Evergreen.V275.Discord.ChannelId) Evergreen.V275.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V275.Discord.Id Evergreen.V275.Discord.GuildId) (Evergreen.V275.Discord.Id Evergreen.V275.Discord.ChannelId) Evergreen.V275.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V275.Id.Id Evergreen.V275.Id.GuildId) (Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V275.Id.Id Evergreen.V275.Id.GuildId) (Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V275.Id.Id Evergreen.V275.Id.GuildId) (Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V275.Id.Id Evergreen.V275.Id.GuildId) (Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V275.Id.Id Evergreen.V275.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V275.Id.Id Evergreen.V275.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V275.Id.Id Evergreen.V275.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V275.Id.Id Evergreen.V275.Id.GuildId) (Evergreen.V275.SecretId.SecretId Evergreen.V275.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V275.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V275.Id.AnyGuildOrDmId Evergreen.V275.Id.ThreadRouteWithMessage (Evergreen.V275.Coord.Coord Evergreen.V275.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V275.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V275.Id.AnyGuildOrDmId Evergreen.V275.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V275.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V275.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V275.Id.AnyGuildOrDmId, Evergreen.V275.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V275.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V275.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V275.Id.AnyGuildOrDmId, Evergreen.V275.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V275.NonemptyDict.NonemptyDict Int Evergreen.V275.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V275.NonemptyDict.NonemptyDict Int Evergreen.V275.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V275.Id.AnyGuildOrDmId Evergreen.V275.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V275.Id.AnyGuildOrDmId Evergreen.V275.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V275.NonemptySet.NonemptySet (Evergreen.V275.Id.Id Evergreen.V275.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V275.Id.AnyGuildOrDmId, Evergreen.V275.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V275.Id.AnyGuildOrDmId Evergreen.V275.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V275.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V275.AiChat.Msg
    | GoMsg Evergreen.V275.Go.Msg
    | GoSpectatorMsg Evergreen.V275.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V275.Editable.Msg Evergreen.V275.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V275.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V275.Id.Id Evergreen.V275.Id.GuildId) Evergreen.V275.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V275.Id.AnyGuildOrDmId, Evergreen.V275.Id.ThreadRoute ) (Evergreen.V275.Id.Id Evergreen.V275.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V275.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V275.Id.AnyGuildOrDmId, Evergreen.V275.Id.ThreadRoute ) (Evergreen.V275.Id.Id Evergreen.V275.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V275.Id.AnyGuildOrDmId, Evergreen.V275.Id.ThreadRoute ) (Evergreen.V275.Id.Id Evergreen.V275.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V275.Id.AnyGuildOrDmId, Evergreen.V275.Id.ThreadRoute )
        { fileId : Evergreen.V275.Id.Id Evergreen.V275.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V275.Id.AnyGuildOrDmId, Evergreen.V275.Id.ThreadRoute ) (Evergreen.V275.Id.Id Evergreen.V275.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V275.Id.AnyGuildOrDmId, Evergreen.V275.Id.ThreadRoute ) (Evergreen.V275.Id.Id Evergreen.V275.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V275.Id.AnyGuildOrDmId, Evergreen.V275.Id.ThreadRoute )
        { fileId : Evergreen.V275.Id.Id Evergreen.V275.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V275.Id.AnyGuildOrDmId, Evergreen.V275.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V275.Id.AnyGuildOrDmId, Evergreen.V275.Id.ThreadRoute ) (Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelMessageId) (Evergreen.V275.Id.Id Evergreen.V275.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V275.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V275.Id.AnyGuildOrDmId, Evergreen.V275.Id.ThreadRoute ) (Evergreen.V275.Id.Id Evergreen.V275.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V275.Id.AnyGuildOrDmId Evergreen.V275.Id.ThreadRouteWithMessage Evergreen.V275.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V275.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V275.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V275.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V275.Id.Id Evergreen.V275.Id.GuildId) Evergreen.V275.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId) (Evergreen.V275.Discord.Id Evergreen.V275.Discord.GuildId) Evergreen.V275.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V275.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V275.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId
        , otherUserId : Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V275.Id.AnyGuildOrDmId Evergreen.V275.Id.ThreadRoute Evergreen.V275.MessageInput.Msg
    | MessageInputMsg Evergreen.V275.Id.AnyGuildOrDmId Evergreen.V275.Id.ThreadRoute Evergreen.V275.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V275.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V275.Range.Range, Evergreen.V275.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V275.Range.Range, Evergreen.V275.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V275.Call.FromJs)
    | VoiceChatMsg Evergreen.V275.Call.Msg
    | PressedChannelHeaderTab Evergreen.V275.Route.DmChannelHeaderTab
    | FileDragEnter
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadServiceWorkerData
    | GotServiceWorkerData String


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V275.Id.Id Evergreen.V275.Id.GuildId) (Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelId) Evergreen.V275.Id.ThreadRoute
    | InitialLoadRequested_Dm Evergreen.V275.DmChannel.DmChannelId Evergreen.V275.Id.ThreadRoute
    | InitialLoadRequested_Discord Evergreen.V275.Id.DiscordGuildOrDmId Evergreen.V275.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V275.Id.Id Evergreen.V275.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V275.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V275.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V275.Untrusted.Untrusted Evergreen.V275.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V275.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V275.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V275.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V275.Id.Id Evergreen.V275.Id.GuildId) (Evergreen.V275.SecretId.SecretId Evergreen.V275.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V275.PersonName.PersonName Evergreen.V275.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V275.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V275.Slack.OAuthCode Evergreen.V275.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V275.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V275.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V275.Id.Id Evergreen.V275.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V275.SecretId.SecretId Evergreen.V275.Id.GoMatchPublicId)


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V275.Discord.Id Evergreen.V275.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V275.Discord.Id Evergreen.V275.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V275.EmailAddress.EmailAddress (Result Evergreen.V275.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V275.EmailAddress.EmailAddress (Result Evergreen.V275.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V275.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V275.Discord.Id Evergreen.V275.Discord.GuildId) (Evergreen.V275.Discord.Id Evergreen.V275.Discord.ChannelId) Evergreen.V275.Id.ThreadRouteWithMaybeMessage (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId) (Result Evergreen.V275.Discord.HttpError Evergreen.V275.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V275.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V275.Discord.Id Evergreen.V275.Discord.PrivateChannelId) (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId) (Result Evergreen.V275.Discord.HttpError Evergreen.V275.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V275.Discord.Id Evergreen.V275.Discord.GuildId) (Evergreen.V275.Discord.Id Evergreen.V275.Discord.ChannelId) Evergreen.V275.Id.ThreadRouteWithMessage (Evergreen.V275.Discord.Id Evergreen.V275.Discord.MessageId) (Result Evergreen.V275.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V275.Discord.Id Evergreen.V275.Discord.PrivateChannelId) (Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelMessageId) (Evergreen.V275.Discord.Id Evergreen.V275.Discord.MessageId) (Result Evergreen.V275.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V275.Discord.Id Evergreen.V275.Discord.GuildId) (Evergreen.V275.Discord.Id Evergreen.V275.Discord.ChannelId) Evergreen.V275.Id.ThreadRouteWithMessage (Evergreen.V275.Discord.Id Evergreen.V275.Discord.MessageId) (Result Evergreen.V275.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V275.Discord.Id Evergreen.V275.Discord.PrivateChannelId) (Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelMessageId) (Evergreen.V275.Discord.Id Evergreen.V275.Discord.MessageId) (Result Evergreen.V275.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V275.Discord.Id Evergreen.V275.Discord.GuildId) (Evergreen.V275.Discord.Id Evergreen.V275.Discord.ChannelId) Evergreen.V275.Id.ThreadRouteWithMessage (Evergreen.V275.Discord.Id Evergreen.V275.Discord.MessageId) Evergreen.V275.Emoji.EmojiOrCustomEmoji (Result Evergreen.V275.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V275.Discord.Id Evergreen.V275.Discord.PrivateChannelId) (Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelMessageId) (Evergreen.V275.Discord.Id Evergreen.V275.Discord.MessageId) Evergreen.V275.Emoji.EmojiOrCustomEmoji (Result Evergreen.V275.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V275.Discord.Id Evergreen.V275.Discord.GuildId) (Evergreen.V275.Discord.Id Evergreen.V275.Discord.ChannelId) Evergreen.V275.Id.ThreadRouteWithMessage (Evergreen.V275.Discord.Id Evergreen.V275.Discord.MessageId) Evergreen.V275.Emoji.EmojiOrCustomEmoji (Result Evergreen.V275.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V275.Discord.Id Evergreen.V275.Discord.PrivateChannelId) (Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelMessageId) (Evergreen.V275.Discord.Id Evergreen.V275.Discord.MessageId) Evergreen.V275.Emoji.EmojiOrCustomEmoji (Result Evergreen.V275.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V275.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V275.Discord.HttpError (List ( Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId, Maybe Evergreen.V275.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V275.Slack.CurrentUser
            , team : Evergreen.V275.Slack.Team
            , users : List Evergreen.V275.Slack.User
            , channels : List ( Evergreen.V275.Slack.Channel, List Evergreen.V275.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId) (Result Effect.Http.Error Evergreen.V275.Slack.TokenResponse)
    | GotCloudflareSessionCreated Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V275.Local.ChangeId Effect.Time.Posix Evergreen.V275.Call.CallId Evergreen.V275.Cloudflare.Sdp (List String) (Result Effect.Http.Error Evergreen.V275.Cloudflare.RealtimeSessionId)
    | GotCloudflareSession Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V275.Local.ChangeId Effect.Time.Posix Evergreen.V275.Call.CallId Evergreen.V275.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V275.Cloudflare.PushTracksResult)
    | GotCloudflarePullOffer Effect.Time.Posix Effect.Lamdera.ClientId Evergreen.V275.Local.ChangeId Evergreen.V275.Call.ConnectionId Evergreen.V275.Cloudflare.RealtimeSessionId (List Evergreen.V275.Cloudflare.TrackName) (Result Effect.Http.Error Evergreen.V275.Cloudflare.PullTracksResult)
    | GotCloudflareRenegotiateAck Effect.Lamdera.ClientId Evergreen.V275.Local.ChangeId Evergreen.V275.Cloudflare.Sdp (Result Effect.Http.Error ())
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId) Evergreen.V275.Discord.UserAuth (Result Evergreen.V275.Discord.HttpError Evergreen.V275.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId) (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId) (Result Evergreen.V275.Discord.HttpError Evergreen.V275.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId)
        (Result
            Evergreen.V275.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V275.Discord.Id Evergreen.V275.Discord.PrivateChannelId
                , members : List (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId)
                }
            , List
                ( Evergreen.V275.Discord.Id Evergreen.V275.Discord.GuildId
                , { guild : Evergreen.V275.Discord.GatewayGuild
                  , channels : List Evergreen.V275.Discord.Channel
                  , icon : Maybe Evergreen.V275.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId) Bool Evergreen.V275.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V275.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V275.Discord.Id Evergreen.V275.Discord.AttachmentId, Evergreen.V275.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V275.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V275.Discord.Id Evergreen.V275.Discord.AttachmentId, Evergreen.V275.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId) (Evergreen.V275.Discord.Id Evergreen.V275.Discord.GuildId) (Evergreen.V275.Discord.Id Evergreen.V275.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V275.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V275.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId) (Evergreen.V275.Discord.Id Evergreen.V275.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V275.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V275.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId) (Evergreen.V275.Discord.Id Evergreen.V275.Discord.GuildId) (Evergreen.V275.Discord.Id Evergreen.V275.Discord.ChannelId) (Result Evergreen.V275.Discord.HttpError (List Evergreen.V275.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId) (Evergreen.V275.Discord.Id Evergreen.V275.Discord.PrivateChannelId) (Result Evergreen.V275.Discord.HttpError (List Evergreen.V275.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V275.Id.Id Evergreen.V275.Id.GuildId) (Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelId) Evergreen.V275.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V275.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V275.DmChannel.DmChannelId Evergreen.V275.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V275.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V275.Discord.Id Evergreen.V275.Discord.GuildId) (Evergreen.V275.Discord.Id Evergreen.V275.Discord.ChannelId) Evergreen.V275.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V275.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V275.Discord.Id Evergreen.V275.Discord.PrivateChannelId) (Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V275.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId)
        (Evergreen.V275.Discord.Id Evergreen.V275.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V275.Discord.HttpError
            { guild : Evergreen.V275.Discord.GatewayGuild
            , channels : List Evergreen.V275.Discord.Channel
            , icon : Maybe Evergreen.V275.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V275.Discord.Id Evergreen.V275.Discord.GuildId) (Result Evergreen.V275.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V275.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId) (List ( Evergreen.V275.Id.Id Evergreen.V275.Id.StickerId, Result Effect.Http.Error Evergreen.V275.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V275.Id.Id Evergreen.V275.Id.StickerId, Result Effect.Http.Error Evergreen.V275.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId) (List ( Evergreen.V275.Id.Id Evergreen.V275.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V275.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V275.Id.Id Evergreen.V275.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V275.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V275.Discord.HttpError (List Evergreen.V275.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V275.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V275.SecretId.SecretId Evergreen.V275.SecretId.ServerSecret))
    | GotTimeForWebsocketListenClose (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | GotCloudflareUsage Effect.Time.Posix (Result Effect.Http.Error Int)
    | GotCloudflareEgressForAdmin Effect.Lamdera.ClientId (Result Effect.Http.Error Int)
