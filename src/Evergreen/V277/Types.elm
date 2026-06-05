module Evergreen.V277.Types exposing (..)

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
import Evergreen.V277.AiChat
import Evergreen.V277.Call
import Evergreen.V277.ChannelDescription
import Evergreen.V277.ChannelName
import Evergreen.V277.Cloudflare
import Evergreen.V277.Coord
import Evergreen.V277.CssPixels
import Evergreen.V277.CustomEmoji
import Evergreen.V277.Discord
import Evergreen.V277.DiscordAttachmentId
import Evergreen.V277.DiscordUserData
import Evergreen.V277.DmChannel
import Evergreen.V277.Editable
import Evergreen.V277.EmailAddress
import Evergreen.V277.Embed
import Evergreen.V277.Emoji
import Evergreen.V277.FileStatus
import Evergreen.V277.Go
import Evergreen.V277.GuildName
import Evergreen.V277.Id
import Evergreen.V277.ImageEditor
import Evergreen.V277.ImageViewer
import Evergreen.V277.Local
import Evergreen.V277.LocalState
import Evergreen.V277.Log
import Evergreen.V277.LoginForm
import Evergreen.V277.MembersAndOwner
import Evergreen.V277.Message
import Evergreen.V277.MessageInput
import Evergreen.V277.MessageView
import Evergreen.V277.MyUi
import Evergreen.V277.NonemptyDict
import Evergreen.V277.NonemptySet
import Evergreen.V277.OneToOne
import Evergreen.V277.Pages.Admin
import Evergreen.V277.Pagination
import Evergreen.V277.PersonName
import Evergreen.V277.Ports
import Evergreen.V277.Postmark
import Evergreen.V277.Range
import Evergreen.V277.RichText
import Evergreen.V277.Route
import Evergreen.V277.SecretId
import Evergreen.V277.SessionIdHash
import Evergreen.V277.Slack
import Evergreen.V277.Sticker
import Evergreen.V277.TextEditor
import Evergreen.V277.ToBackendLog
import Evergreen.V277.Touch
import Evergreen.V277.TwoFactorAuthentication
import Evergreen.V277.Ui.Anim
import Evergreen.V277.Untrusted
import Evergreen.V277.User
import Evergreen.V277.UserAgent
import Evergreen.V277.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V277.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V277.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.Id.GuildId) Evergreen.V277.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId) Evergreen.V277.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V277.Discord.Id Evergreen.V277.Discord.PrivateChannelId) Evergreen.V277.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V277.Discord.Id Evergreen.V277.Discord.GuildId) Evergreen.V277.LocalState.DiscordFrontendGuild
    , user : Evergreen.V277.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId) Evergreen.V277.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId) Evergreen.V277.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId) Evergreen.V277.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V277.SessionIdHash.SessionIdHash Evergreen.V277.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V277.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.Id.StickerId) Evergreen.V277.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.Id.CustomEmojiId) Evergreen.V277.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V277.Call.CallId (Evergreen.V277.NonemptySet.NonemptySet ( Evergreen.V277.Id.Id Evergreen.V277.Id.UserId, Effect.Lamdera.ClientId ))
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type PublicGoMatch
    = PublicGoMatch_NotLoaded
    | PublicGoMatch_Loading
    | PublicGoMatch_Loaded Evergreen.V277.Go.PublicGoMatchData Evergreen.V277.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V277.Route.Route
    , windowSize : Evergreen.V277.Coord.Coord Evergreen.V277.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V277.Ports.NotificationPermission
    , pwaStatus : Evergreen.V277.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V277.UserAgent.UserAgent
    , publicGoMatch : PublicGoMatch
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V277.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V277.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V277.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.FileStatus.FileId) Evergreen.V277.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V277.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V277.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.FileStatus.FileId) Evergreen.V277.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V277.Id.Id Evergreen.V277.Id.GuildId) Evergreen.V277.ChannelName.ChannelName Evergreen.V277.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V277.Id.Id Evergreen.V277.Id.GuildId) (Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelId) Evergreen.V277.ChannelName.ChannelName Evergreen.V277.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V277.Id.Id Evergreen.V277.Id.GuildId) (Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelId)
    | Local_DeleteGuild (Evergreen.V277.Id.Id Evergreen.V277.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V277.Id.Id Evergreen.V277.Id.GuildId) (Evergreen.V277.UserSession.ToBeFilledInByBackend (Evergreen.V277.SecretId.SecretId Evergreen.V277.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V277.Id.Id Evergreen.V277.Id.GuildId) (Evergreen.V277.SecretId.SecretId Evergreen.V277.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V277.GuildName.GuildName (Evergreen.V277.UserSession.ToBeFilledInByBackend (Evergreen.V277.Id.Id Evergreen.V277.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V277.Id.AnyGuildOrDmId, Evergreen.V277.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V277.Id.AnyGuildOrDmId Evergreen.V277.Id.ThreadRouteWithMessage Evergreen.V277.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V277.Id.AnyGuildOrDmId Evergreen.V277.Id.ThreadRouteWithMessage Evergreen.V277.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V277.Id.GuildOrDmId Evergreen.V277.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.FileStatus.FileId) Evergreen.V277.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId) (Evergreen.V277.Discord.Id Evergreen.V277.Discord.GuildId) (Evergreen.V277.Discord.Id Evergreen.V277.Discord.ChannelId) Evergreen.V277.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V277.Id.DiscordGuildOrDmId_DmData (Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V277.Id.AnyGuildOrDmId Evergreen.V277.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V277.Id.AnyGuildOrDmId Evergreen.V277.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V277.Id.AnyGuildOrDmId Evergreen.V277.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V277.UserSession.SetViewing
    | Local_SetName Evergreen.V277.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V277.Id.GuildOrDmId (Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelMessageId) (Evergreen.V277.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelMessageId) (Evergreen.V277.Message.Message Evergreen.V277.Id.ChannelMessageId (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V277.Id.GuildOrDmId (Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelMessageId) (Evergreen.V277.Id.Id Evergreen.V277.Id.ThreadMessageId) (Evergreen.V277.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.Id.ThreadMessageId) (Evergreen.V277.Message.Message Evergreen.V277.Id.ThreadMessageId (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V277.Id.DiscordGuildOrDmId (Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelMessageId) (Evergreen.V277.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelMessageId) (Evergreen.V277.Message.Message Evergreen.V277.Id.ChannelMessageId (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V277.Id.DiscordGuildOrDmId (Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelMessageId) (Evergreen.V277.Id.Id Evergreen.V277.Id.ThreadMessageId) (Evergreen.V277.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.Id.ThreadMessageId) (Evergreen.V277.Message.Message Evergreen.V277.Id.ThreadMessageId (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V277.Id.Id Evergreen.V277.Id.GuildId) Evergreen.V277.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId) (Evergreen.V277.Discord.Id Evergreen.V277.Discord.GuildId) Evergreen.V277.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V277.UserSession.NotificationMode
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V277.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V277.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V277.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V277.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V277.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V277.NonemptySet.NonemptySet (Evergreen.V277.Id.Id Evergreen.V277.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V277.Call.LocalChange
    | Local_Go
        { otherUserId : Evergreen.V277.Id.Id Evergreen.V277.Id.UserId
        }
        Evergreen.V277.Go.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId) Effect.Time.Posix Evergreen.V277.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V277.RichText.RichText (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId))) Evergreen.V277.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.FileStatus.FileId) Evergreen.V277.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.Id.StickerId) Evergreen.V277.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V277.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V277.RichText.RichText (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId))) Evergreen.V277.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.FileStatus.FileId) Evergreen.V277.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.Id.StickerId) Evergreen.V277.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V277.Id.Id Evergreen.V277.Id.GuildId) Evergreen.V277.ChannelName.ChannelName Evergreen.V277.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V277.Id.Id Evergreen.V277.Id.GuildId) (Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelId) Evergreen.V277.ChannelName.ChannelName Evergreen.V277.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V277.Id.Id Evergreen.V277.Id.GuildId) (Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelId)
    | Server_DeleteGuild (Evergreen.V277.Id.Id Evergreen.V277.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId) (Evergreen.V277.Id.Id Evergreen.V277.Id.GuildId) (Evergreen.V277.SecretId.SecretId Evergreen.V277.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V277.Id.Id Evergreen.V277.Id.GuildId) (Evergreen.V277.SecretId.SecretId Evergreen.V277.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId) (Evergreen.V277.Id.Id Evergreen.V277.Id.GuildId) Evergreen.V277.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V277.LocalState.JoinGuildError
            { guildId : Evergreen.V277.Id.Id Evergreen.V277.Id.GuildId
            , guild : Evergreen.V277.LocalState.FrontendGuild
            , owner : Evergreen.V277.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId) Evergreen.V277.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId) Evergreen.V277.Id.GuildOrDmId Evergreen.V277.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId) (Evergreen.V277.Discord.Id Evergreen.V277.Discord.GuildId) (Evergreen.V277.Discord.Id Evergreen.V277.Discord.ChannelId) Evergreen.V277.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId) (Evergreen.V277.Discord.Id Evergreen.V277.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId) Evergreen.V277.Id.GuildOrDmId Evergreen.V277.Id.ThreadRouteWithMessage Evergreen.V277.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId) Evergreen.V277.Id.GuildOrDmId Evergreen.V277.Id.ThreadRouteWithMessage Evergreen.V277.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId) (Evergreen.V277.Discord.Id Evergreen.V277.Discord.GuildId) (Evergreen.V277.Discord.Id Evergreen.V277.Discord.ChannelId) Evergreen.V277.Id.ThreadRouteWithMessage Evergreen.V277.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId) (Evergreen.V277.Discord.Id Evergreen.V277.Discord.PrivateChannelId) (Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelMessageId) Evergreen.V277.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId) (Evergreen.V277.Discord.Id Evergreen.V277.Discord.GuildId) (Evergreen.V277.Discord.Id Evergreen.V277.Discord.ChannelId) Evergreen.V277.Id.ThreadRouteWithMessage Evergreen.V277.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId) (Evergreen.V277.Discord.Id Evergreen.V277.Discord.PrivateChannelId) (Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelMessageId) Evergreen.V277.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId) Evergreen.V277.Id.GuildOrDmId Evergreen.V277.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V277.RichText.RichText (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId))) (SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.FileStatus.FileId) Evergreen.V277.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId) (Evergreen.V277.Discord.Id Evergreen.V277.Discord.GuildId) (Evergreen.V277.Discord.Id Evergreen.V277.Discord.ChannelId) Evergreen.V277.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V277.RichText.RichText (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V277.Id.DiscordGuildOrDmId_DmData (Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V277.RichText.RichText (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId) Evergreen.V277.Id.AnyGuildOrDmId Evergreen.V277.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V277.Id.AnyGuildOrDmId Evergreen.V277.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V277.Discord.Id Evergreen.V277.Discord.GuildId) (Evergreen.V277.Discord.Id Evergreen.V277.Discord.ChannelId) Evergreen.V277.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V277.Discord.Id Evergreen.V277.Discord.PrivateChannelId) (Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId) Evergreen.V277.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId) Evergreen.V277.FileStatus.FileHash
    | Server_SetGuildIcon (Evergreen.V277.Id.Id Evergreen.V277.Id.GuildId) Evergreen.V277.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V277.Id.Id Evergreen.V277.Id.GuildId) Evergreen.V277.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V277.Discord.Id Evergreen.V277.Discord.GuildId) Evergreen.V277.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V277.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V277.SessionIdHash.SessionIdHash Evergreen.V277.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V277.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V277.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V277.Id.AnyGuildOrDmId, Evergreen.V277.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V277.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId) Evergreen.V277.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V277.Discord.Id Evergreen.V277.Discord.GuildId) (Evergreen.V277.Discord.Id Evergreen.V277.Discord.ChannelId) Evergreen.V277.ChannelName.ChannelName (Evergreen.V277.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V277.Discord.Id Evergreen.V277.Discord.PrivateChannelId)
        (Evergreen.V277.NonemptyDict.NonemptyDict
            (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V277.Discord.Id Evergreen.V277.Discord.GuildId) Evergreen.V277.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V277.Discord.Id Evergreen.V277.Discord.PrivateChannelId) Evergreen.V277.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId) Evergreen.V277.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId) (Maybe (Evergreen.V277.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V277.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V277.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V277.Id.Id Evergreen.V277.Id.GuildId) (Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelId) Evergreen.V277.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V277.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId) Evergreen.V277.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V277.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V277.Discord.Id Evergreen.V277.Discord.GuildId) (Evergreen.V277.Discord.Id Evergreen.V277.Discord.ChannelId) Evergreen.V277.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V277.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V277.Discord.Id Evergreen.V277.Discord.PrivateChannelId) (Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V277.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V277.Discord.Id Evergreen.V277.Discord.GuildId) Evergreen.V277.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V277.Discord.Id Evergreen.V277.Discord.GuildId) (Evergreen.V277.Discord.Id Evergreen.V277.Discord.ChannelId) (Evergreen.V277.Discord.OptionalData String) (Evergreen.V277.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V277.Discord.Id Evergreen.V277.Discord.GuildId)
        (Evergreen.V277.MembersAndOwner.MembersAndOwner
            (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V277.Discord.Id Evergreen.V277.Discord.GuildId) (Evergreen.V277.Discord.Id Evergreen.V277.Discord.ChannelId) (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId) Evergreen.V277.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.Id.StickerId) Evergreen.V277.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.Id.CustomEmojiId) Evergreen.V277.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V277.Call.ServerChange
    | Server_Go
        (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId)
        { otherUserId : Evergreen.V277.Id.Id Evergreen.V277.Id.UserId
        }
        Evergreen.V277.Go.LocalChange


type LocalMsg
    = LocalChange (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V277.Id.Id Evergreen.V277.Id.GuildId) (Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelId) Evergreen.V277.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V277.Discord.Id Evergreen.V277.Discord.GuildId) (Evergreen.V277.Discord.Id Evergreen.V277.Discord.ChannelId) Evergreen.V277.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.FileStatus.FileId) Evergreen.V277.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V277.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V277.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V277.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V277.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V277.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V277.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V277.Coord.Coord Evergreen.V277.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V277.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V277.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V277.Id.AnyGuildOrDmId Evergreen.V277.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V277.Id.AnyGuildOrDmId Evergreen.V277.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V277.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V277.Coord.Coord Evergreen.V277.CssPixels.CssPixels) (Maybe Evergreen.V277.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V277.Id.AnyGuildOrDmId, Evergreen.V277.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelMessageId) (Evergreen.V277.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.Id.ThreadMessageId) (Evergreen.V277.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V277.Editable.Model
    , showLinkDiscordSetup : Bool
    , domainWhitelistInput : String
    , serviceWorkerData : Maybe String
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V277.Local.Local LocalMsg Evergreen.V277.LocalState.LocalState
    , admin : Evergreen.V277.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V277.Id.AnyGuildOrDmId, Evergreen.V277.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V277.Id.Id Evergreen.V277.Id.GuildId, Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V277.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V277.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V277.Id.AnyGuildOrDmId, Evergreen.V277.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V277.Id.AnyGuildOrDmId, Evergreen.V277.Id.ThreadRoute ) (Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : Evergreen.V277.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V277.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V277.Id.AnyGuildOrDmId, Evergreen.V277.Id.ThreadRoute ) (Evergreen.V277.NonemptyDict.NonemptyDict (Evergreen.V277.Id.Id Evergreen.V277.FileStatus.FileId) Evergreen.V277.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V277.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V277.TextEditor.Model
    , profilePictureEditor : Evergreen.V277.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V277.Id.Id Evergreen.V277.Id.GuildId, Evergreen.V277.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V277.Emoji.Model
    , voiceChat : Evergreen.V277.Call.Model
    , currentDmGoMatch : SeqDict.SeqDict ( Evergreen.V277.Id.Id Evergreen.V277.Id.UserId, Maybe (Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelMessageId) ) Evergreen.V277.Go.Model
    , fileDragOverCount : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V277.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V277.SecretId.SecretId Evergreen.V277.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V277.Range.Range
                , direction : Evergreen.V277.Range.SelectionDirection
                }
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V277.NonemptyDict.NonemptyDict Int Evergreen.V277.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V277.NonemptyDict.NonemptyDict Int Evergreen.V277.Touch.Touch
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
    | AdminToFrontend Evergreen.V277.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V277.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V277.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V277.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V277.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V277.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V277.Go.PublicGoMatchResponse)


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V277.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V277.Coord.Coord Evergreen.V277.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V277.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V277.MyUi.LastCopy
    , notificationPermission : Evergreen.V277.Ports.NotificationPermission
    , pwaStatus : Evergreen.V277.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V277.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V277.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V277.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V277.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V277.Id.Id Evergreen.V277.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V277.Id.Id Evergreen.V277.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V277.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V277.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V277.Coord.Coord Evergreen.V277.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V277.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V277.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V277.Id.Id Evergreen.V277.Id.GuildId, Evergreen.V277.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V277.DmChannel.DmChannelId, Evergreen.V277.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V277.Discord.Id Evergreen.V277.Discord.GuildId, Evergreen.V277.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V277.Discord.Id Evergreen.V277.Discord.PrivateChannelId, Evergreen.V277.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V277.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V277.NonemptyDict.NonemptyDict (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId) Evergreen.V277.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V277.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V277.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V277.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V277.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId) Evergreen.V277.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId) Evergreen.V277.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V277.Id.Id Evergreen.V277.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.Id.GuildId) Evergreen.V277.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.Id.GuildId) Evergreen.V277.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V277.Discord.Id Evergreen.V277.Discord.GuildId) Evergreen.V277.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V277.DmChannel.DmChannelId Evergreen.V277.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V277.Discord.Id Evergreen.V277.Discord.PrivateChannelId) Evergreen.V277.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V277.OneToOne.OneToOne (Evergreen.V277.Slack.Id Evergreen.V277.Slack.ChannelId) Evergreen.V277.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V277.OneToOne.OneToOne String (Evergreen.V277.Id.Id Evergreen.V277.Id.GuildId)
    , slackUsers : Evergreen.V277.OneToOne.OneToOne (Evergreen.V277.Slack.Id Evergreen.V277.Slack.UserId) (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId)
    , slackServers : Evergreen.V277.OneToOne.OneToOne (Evergreen.V277.Slack.Id Evergreen.V277.Slack.TeamId) (Evergreen.V277.Id.Id Evergreen.V277.Id.GuildId)
    , slackToken : Maybe Evergreen.V277.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V277.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V277.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V277.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V277.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V277.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V277.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V277.Cloudflare.AnalyticsApiToken
    , textEditor : Evergreen.V277.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId) Evergreen.V277.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId, Evergreen.V277.Discord.Id Evergreen.V277.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V277.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V277.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V277.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V277.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId) (Evergreen.V277.LocalState.LoadingDiscordChannel (List Evergreen.V277.Discord.Message))
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V277.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.Id.StickerId) Evergreen.V277.Sticker.StickerData
    , discordStickers : Evergreen.V277.OneToOne.OneToOne (Evergreen.V277.Discord.Id Evergreen.V277.Discord.StickerId) (Evergreen.V277.Id.Id Evergreen.V277.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.Id.CustomEmojiId) Evergreen.V277.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V277.OneToOne.OneToOne Evergreen.V277.RichText.DiscordCustomEmojiIdAndName (Evergreen.V277.Id.Id Evergreen.V277.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V277.Postmark.ApiKey
    , serverSecret : Evergreen.V277.SecretId.SecretId Evergreen.V277.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V277.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V277.OneToOne.OneToOne (Evergreen.V277.SecretId.SecretId Evergreen.V277.Id.GoMatchPublicId) ( Evergreen.V277.DmChannel.DmChannelId, Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelMessageId )
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V277.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V277.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V277.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V277.Route.Route
    | SelectedFilesToAttach ( Evergreen.V277.Id.AnyGuildOrDmId, Evergreen.V277.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V277.Id.Id Evergreen.V277.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V277.Id.Id Evergreen.V277.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V277.Id.Id Evergreen.V277.Id.GuildId) (Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelId) Evergreen.V277.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V277.Id.Id Evergreen.V277.Id.GuildId) (Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelId) Evergreen.V277.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V277.Discord.Id Evergreen.V277.Discord.GuildId) (Evergreen.V277.Discord.Id Evergreen.V277.Discord.ChannelId) Evergreen.V277.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V277.Discord.Id Evergreen.V277.Discord.GuildId) (Evergreen.V277.Discord.Id Evergreen.V277.Discord.ChannelId) Evergreen.V277.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V277.Id.Id Evergreen.V277.Id.GuildId) (Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V277.Id.Id Evergreen.V277.Id.GuildId) (Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V277.Id.Id Evergreen.V277.Id.GuildId) (Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V277.Id.Id Evergreen.V277.Id.GuildId) (Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V277.Id.Id Evergreen.V277.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V277.Id.Id Evergreen.V277.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V277.Id.Id Evergreen.V277.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V277.Id.Id Evergreen.V277.Id.GuildId) (Evergreen.V277.SecretId.SecretId Evergreen.V277.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V277.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V277.Id.AnyGuildOrDmId Evergreen.V277.Id.ThreadRouteWithMessage (Evergreen.V277.Coord.Coord Evergreen.V277.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V277.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V277.Id.AnyGuildOrDmId Evergreen.V277.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V277.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V277.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V277.Id.AnyGuildOrDmId, Evergreen.V277.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V277.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V277.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V277.Id.AnyGuildOrDmId, Evergreen.V277.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V277.NonemptyDict.NonemptyDict Int Evergreen.V277.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V277.NonemptyDict.NonemptyDict Int Evergreen.V277.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V277.Id.AnyGuildOrDmId Evergreen.V277.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V277.Id.AnyGuildOrDmId Evergreen.V277.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V277.NonemptySet.NonemptySet (Evergreen.V277.Id.Id Evergreen.V277.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V277.Id.AnyGuildOrDmId, Evergreen.V277.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V277.Id.AnyGuildOrDmId Evergreen.V277.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V277.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V277.AiChat.Msg
    | GoMsg Evergreen.V277.Go.Msg
    | GoSpectatorMsg Evergreen.V277.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V277.Editable.Msg Evergreen.V277.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V277.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V277.Id.Id Evergreen.V277.Id.GuildId) Evergreen.V277.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V277.Id.AnyGuildOrDmId, Evergreen.V277.Id.ThreadRoute ) (Evergreen.V277.Id.Id Evergreen.V277.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V277.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V277.Id.AnyGuildOrDmId, Evergreen.V277.Id.ThreadRoute ) (Evergreen.V277.Id.Id Evergreen.V277.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V277.Id.AnyGuildOrDmId, Evergreen.V277.Id.ThreadRoute ) (Evergreen.V277.Id.Id Evergreen.V277.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V277.Id.AnyGuildOrDmId, Evergreen.V277.Id.ThreadRoute )
        { fileId : Evergreen.V277.Id.Id Evergreen.V277.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V277.Id.AnyGuildOrDmId, Evergreen.V277.Id.ThreadRoute ) (Evergreen.V277.Id.Id Evergreen.V277.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V277.Id.AnyGuildOrDmId, Evergreen.V277.Id.ThreadRoute ) (Evergreen.V277.Id.Id Evergreen.V277.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V277.Id.AnyGuildOrDmId, Evergreen.V277.Id.ThreadRoute )
        { fileId : Evergreen.V277.Id.Id Evergreen.V277.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V277.Id.AnyGuildOrDmId, Evergreen.V277.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V277.Id.AnyGuildOrDmId, Evergreen.V277.Id.ThreadRoute ) (Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelMessageId) (Evergreen.V277.Id.Id Evergreen.V277.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V277.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V277.Id.AnyGuildOrDmId, Evergreen.V277.Id.ThreadRoute ) (Evergreen.V277.Id.Id Evergreen.V277.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V277.Id.AnyGuildOrDmId Evergreen.V277.Id.ThreadRouteWithMessage Evergreen.V277.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V277.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V277.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V277.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V277.Id.Id Evergreen.V277.Id.GuildId) Evergreen.V277.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId) (Evergreen.V277.Discord.Id Evergreen.V277.Discord.GuildId) Evergreen.V277.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V277.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V277.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId
        , otherUserId : Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V277.Id.AnyGuildOrDmId Evergreen.V277.Id.ThreadRoute Evergreen.V277.MessageInput.Msg
    | MessageInputMsg Evergreen.V277.Id.AnyGuildOrDmId Evergreen.V277.Id.ThreadRoute Evergreen.V277.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V277.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V277.Range.Range, Evergreen.V277.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V277.Range.Range, Evergreen.V277.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V277.Call.FromJs)
    | VoiceChatMsg Evergreen.V277.Call.Msg
    | PressedChannelHeaderTab Evergreen.V277.Route.DmChannelHeaderTab
    | FileDragEnter
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadServiceWorkerData
    | GotServiceWorkerData String


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V277.Id.Id Evergreen.V277.Id.GuildId) (Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelId) Evergreen.V277.Id.ThreadRoute
    | InitialLoadRequested_Dm Evergreen.V277.DmChannel.DmChannelId Evergreen.V277.Id.ThreadRoute
    | InitialLoadRequested_Discord Evergreen.V277.Id.DiscordGuildOrDmId Evergreen.V277.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V277.Id.Id Evergreen.V277.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V277.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V277.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V277.Untrusted.Untrusted Evergreen.V277.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V277.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V277.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V277.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V277.Id.Id Evergreen.V277.Id.GuildId) (Evergreen.V277.SecretId.SecretId Evergreen.V277.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V277.PersonName.PersonName Evergreen.V277.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V277.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V277.Slack.OAuthCode Evergreen.V277.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V277.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V277.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V277.Id.Id Evergreen.V277.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V277.SecretId.SecretId Evergreen.V277.Id.GoMatchPublicId)


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V277.Discord.Id Evergreen.V277.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V277.Discord.Id Evergreen.V277.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V277.EmailAddress.EmailAddress (Result Evergreen.V277.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V277.EmailAddress.EmailAddress (Result Evergreen.V277.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V277.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V277.Discord.Id Evergreen.V277.Discord.GuildId) (Evergreen.V277.Discord.Id Evergreen.V277.Discord.ChannelId) Evergreen.V277.Id.ThreadRouteWithMaybeMessage (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId) (Result Evergreen.V277.Discord.HttpError Evergreen.V277.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V277.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V277.Discord.Id Evergreen.V277.Discord.PrivateChannelId) (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId) (Result Evergreen.V277.Discord.HttpError Evergreen.V277.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V277.Discord.Id Evergreen.V277.Discord.GuildId) (Evergreen.V277.Discord.Id Evergreen.V277.Discord.ChannelId) Evergreen.V277.Id.ThreadRouteWithMessage (Evergreen.V277.Discord.Id Evergreen.V277.Discord.MessageId) (Result Evergreen.V277.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V277.Discord.Id Evergreen.V277.Discord.PrivateChannelId) (Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelMessageId) (Evergreen.V277.Discord.Id Evergreen.V277.Discord.MessageId) (Result Evergreen.V277.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V277.Discord.Id Evergreen.V277.Discord.GuildId) (Evergreen.V277.Discord.Id Evergreen.V277.Discord.ChannelId) Evergreen.V277.Id.ThreadRouteWithMessage (Evergreen.V277.Discord.Id Evergreen.V277.Discord.MessageId) (Result Evergreen.V277.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V277.Discord.Id Evergreen.V277.Discord.PrivateChannelId) (Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelMessageId) (Evergreen.V277.Discord.Id Evergreen.V277.Discord.MessageId) (Result Evergreen.V277.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V277.Discord.Id Evergreen.V277.Discord.GuildId) (Evergreen.V277.Discord.Id Evergreen.V277.Discord.ChannelId) Evergreen.V277.Id.ThreadRouteWithMessage (Evergreen.V277.Discord.Id Evergreen.V277.Discord.MessageId) Evergreen.V277.Emoji.EmojiOrCustomEmoji (Result Evergreen.V277.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V277.Discord.Id Evergreen.V277.Discord.PrivateChannelId) (Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelMessageId) (Evergreen.V277.Discord.Id Evergreen.V277.Discord.MessageId) Evergreen.V277.Emoji.EmojiOrCustomEmoji (Result Evergreen.V277.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V277.Discord.Id Evergreen.V277.Discord.GuildId) (Evergreen.V277.Discord.Id Evergreen.V277.Discord.ChannelId) Evergreen.V277.Id.ThreadRouteWithMessage (Evergreen.V277.Discord.Id Evergreen.V277.Discord.MessageId) Evergreen.V277.Emoji.EmojiOrCustomEmoji (Result Evergreen.V277.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V277.Discord.Id Evergreen.V277.Discord.PrivateChannelId) (Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelMessageId) (Evergreen.V277.Discord.Id Evergreen.V277.Discord.MessageId) Evergreen.V277.Emoji.EmojiOrCustomEmoji (Result Evergreen.V277.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V277.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V277.Discord.HttpError (List ( Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId, Maybe Evergreen.V277.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId) Effect.Time.Posix Evergreen.V277.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V277.Slack.CurrentUser
            , team : Evergreen.V277.Slack.Team
            , users : List Evergreen.V277.Slack.User
            , channels : List ( Evergreen.V277.Slack.Channel, List Evergreen.V277.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId) (Result Effect.Http.Error Evergreen.V277.Slack.TokenResponse)
    | GotCloudflareSessionCreated Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V277.Local.ChangeId Effect.Time.Posix Evergreen.V277.Call.CallId Evergreen.V277.Cloudflare.Sdp (List String) (Result Effect.Http.Error Evergreen.V277.Cloudflare.RealtimeSessionId)
    | GotCloudflareSession Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V277.Local.ChangeId Effect.Time.Posix Evergreen.V277.Call.CallId Evergreen.V277.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V277.Cloudflare.PushTracksResult)
    | GotCloudflarePullOffer Effect.Time.Posix Effect.Lamdera.ClientId Evergreen.V277.Local.ChangeId Evergreen.V277.Call.ConnectionId Evergreen.V277.Cloudflare.RealtimeSessionId (List Evergreen.V277.Cloudflare.TrackName) (Result Effect.Http.Error Evergreen.V277.Cloudflare.PullTracksResult)
    | GotCloudflareRenegotiateAck Effect.Lamdera.ClientId Evergreen.V277.Local.ChangeId Evergreen.V277.Cloudflare.Sdp (Result Effect.Http.Error ())
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId) Evergreen.V277.Discord.UserAuth (Result Evergreen.V277.Discord.HttpError Evergreen.V277.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId) (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId) (Result Evergreen.V277.Discord.HttpError Evergreen.V277.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId)
        (Result
            Evergreen.V277.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V277.Discord.Id Evergreen.V277.Discord.PrivateChannelId
                , members : List (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId)
                }
            , List
                ( Evergreen.V277.Discord.Id Evergreen.V277.Discord.GuildId
                , { guild : Evergreen.V277.Discord.GatewayGuild
                  , channels : List Evergreen.V277.Discord.Channel
                  , icon : Maybe Evergreen.V277.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId) Bool Evergreen.V277.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V277.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V277.Discord.Id Evergreen.V277.Discord.AttachmentId, Evergreen.V277.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V277.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V277.Discord.Id Evergreen.V277.Discord.AttachmentId, Evergreen.V277.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId) (Evergreen.V277.Discord.Id Evergreen.V277.Discord.GuildId) (Evergreen.V277.Discord.Id Evergreen.V277.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V277.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V277.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId) (Evergreen.V277.Discord.Id Evergreen.V277.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V277.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V277.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId) (Evergreen.V277.Discord.Id Evergreen.V277.Discord.GuildId) (Evergreen.V277.Discord.Id Evergreen.V277.Discord.ChannelId) (Result Evergreen.V277.Discord.HttpError (List Evergreen.V277.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId) (Evergreen.V277.Discord.Id Evergreen.V277.Discord.PrivateChannelId) (Result Evergreen.V277.Discord.HttpError (List Evergreen.V277.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V277.Id.Id Evergreen.V277.Id.GuildId) (Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelId) Evergreen.V277.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V277.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V277.DmChannel.DmChannelId Evergreen.V277.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V277.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V277.Discord.Id Evergreen.V277.Discord.GuildId) (Evergreen.V277.Discord.Id Evergreen.V277.Discord.ChannelId) Evergreen.V277.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V277.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V277.Discord.Id Evergreen.V277.Discord.PrivateChannelId) (Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V277.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId)
        (Evergreen.V277.Discord.Id Evergreen.V277.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V277.Discord.HttpError
            { guild : Evergreen.V277.Discord.GatewayGuild
            , channels : List Evergreen.V277.Discord.Channel
            , icon : Maybe Evergreen.V277.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V277.Discord.Id Evergreen.V277.Discord.GuildId) (Result Evergreen.V277.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V277.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId) (List ( Evergreen.V277.Id.Id Evergreen.V277.Id.StickerId, Result Effect.Http.Error Evergreen.V277.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V277.Id.Id Evergreen.V277.Id.StickerId, Result Effect.Http.Error Evergreen.V277.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId) (List ( Evergreen.V277.Id.Id Evergreen.V277.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V277.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V277.Id.Id Evergreen.V277.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V277.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V277.Discord.HttpError (List Evergreen.V277.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V277.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V277.SecretId.SecretId Evergreen.V277.SecretId.ServerSecret))
    | GotTimeForWebsocketListenClose (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | GotCloudflareUsage Effect.Time.Posix (Result Effect.Http.Error Int)
    | GotCloudflareEgressForAdmin Effect.Lamdera.ClientId (Result Effect.Http.Error Int)
