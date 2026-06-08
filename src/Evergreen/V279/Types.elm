module Evergreen.V279.Types exposing (..)

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
import Evergreen.V279.AiChat
import Evergreen.V279.Call
import Evergreen.V279.ChannelDescription
import Evergreen.V279.ChannelName
import Evergreen.V279.Cloudflare
import Evergreen.V279.Coord
import Evergreen.V279.CssPixels
import Evergreen.V279.CustomEmoji
import Evergreen.V279.Discord
import Evergreen.V279.DiscordAttachmentId
import Evergreen.V279.DiscordUserData
import Evergreen.V279.DmChannel
import Evergreen.V279.Editable
import Evergreen.V279.EmailAddress
import Evergreen.V279.Embed
import Evergreen.V279.Emoji
import Evergreen.V279.FileStatus
import Evergreen.V279.Go
import Evergreen.V279.GuildName
import Evergreen.V279.Id
import Evergreen.V279.ImageEditor
import Evergreen.V279.ImageViewer
import Evergreen.V279.Local
import Evergreen.V279.LocalState
import Evergreen.V279.Log
import Evergreen.V279.LoginForm
import Evergreen.V279.MembersAndOwner
import Evergreen.V279.Message
import Evergreen.V279.MessageInput
import Evergreen.V279.MessageView
import Evergreen.V279.MyUi
import Evergreen.V279.NonemptyDict
import Evergreen.V279.NonemptySet
import Evergreen.V279.OneToOne
import Evergreen.V279.Pages.Admin
import Evergreen.V279.Pagination
import Evergreen.V279.PersonName
import Evergreen.V279.Ports
import Evergreen.V279.Postmark
import Evergreen.V279.Range
import Evergreen.V279.RichText
import Evergreen.V279.Route
import Evergreen.V279.SecretId
import Evergreen.V279.SessionIdHash
import Evergreen.V279.Slack
import Evergreen.V279.Sticker
import Evergreen.V279.TextEditor
import Evergreen.V279.ToBackendLog
import Evergreen.V279.Touch
import Evergreen.V279.TwoFactorAuthentication
import Evergreen.V279.Ui.Anim
import Evergreen.V279.Untrusted
import Evergreen.V279.User
import Evergreen.V279.UserAgent
import Evergreen.V279.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V279.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V279.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.Id.GuildId) Evergreen.V279.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId) Evergreen.V279.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V279.Discord.Id Evergreen.V279.Discord.PrivateChannelId) Evergreen.V279.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V279.Discord.Id Evergreen.V279.Discord.GuildId) Evergreen.V279.LocalState.DiscordFrontendGuild
    , user : Evergreen.V279.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId) Evergreen.V279.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId) Evergreen.V279.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId) Evergreen.V279.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V279.SessionIdHash.SessionIdHash Evergreen.V279.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V279.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.Id.StickerId) Evergreen.V279.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.Id.CustomEmojiId) Evergreen.V279.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V279.Call.CallId (Evergreen.V279.NonemptySet.NonemptySet ( Evergreen.V279.Id.Id Evergreen.V279.Id.UserId, Effect.Lamdera.ClientId ))
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type PublicGoMatch
    = PublicGoMatch_NotLoaded
    | PublicGoMatch_Loading
    | PublicGoMatch_Loaded Evergreen.V279.Go.PublicGoMatchData Evergreen.V279.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V279.Route.Route
    , windowSize : Evergreen.V279.Coord.Coord Evergreen.V279.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V279.Ports.NotificationPermission
    , pwaStatus : Evergreen.V279.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V279.UserAgent.UserAgent
    , publicGoMatch : PublicGoMatch
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V279.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V279.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V279.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.FileStatus.FileId) Evergreen.V279.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V279.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V279.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.FileStatus.FileId) Evergreen.V279.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V279.Id.Id Evergreen.V279.Id.GuildId) Evergreen.V279.ChannelName.ChannelName Evergreen.V279.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V279.Id.Id Evergreen.V279.Id.GuildId) (Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelId) Evergreen.V279.ChannelName.ChannelName Evergreen.V279.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V279.Id.Id Evergreen.V279.Id.GuildId) (Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelId)
    | Local_DeleteGuild (Evergreen.V279.Id.Id Evergreen.V279.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V279.Id.Id Evergreen.V279.Id.GuildId) (Evergreen.V279.UserSession.ToBeFilledInByBackend (Evergreen.V279.SecretId.SecretId Evergreen.V279.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V279.Id.Id Evergreen.V279.Id.GuildId) (Evergreen.V279.SecretId.SecretId Evergreen.V279.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V279.GuildName.GuildName (Evergreen.V279.UserSession.ToBeFilledInByBackend (Evergreen.V279.Id.Id Evergreen.V279.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V279.Id.AnyGuildOrDmId, Evergreen.V279.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V279.Id.AnyGuildOrDmId Evergreen.V279.Id.ThreadRouteWithMessage Evergreen.V279.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V279.Id.AnyGuildOrDmId Evergreen.V279.Id.ThreadRouteWithMessage Evergreen.V279.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V279.Id.GuildOrDmId Evergreen.V279.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.FileStatus.FileId) Evergreen.V279.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId) (Evergreen.V279.Discord.Id Evergreen.V279.Discord.GuildId) (Evergreen.V279.Discord.Id Evergreen.V279.Discord.ChannelId) Evergreen.V279.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V279.Id.DiscordGuildOrDmId_DmData (Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V279.Id.AnyGuildOrDmId Evergreen.V279.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V279.Id.AnyGuildOrDmId Evergreen.V279.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V279.Id.AnyGuildOrDmId Evergreen.V279.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V279.UserSession.SetViewing
    | Local_SetName Evergreen.V279.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V279.Id.GuildOrDmId (Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelMessageId) (Evergreen.V279.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelMessageId) (Evergreen.V279.Message.Message Evergreen.V279.Id.ChannelMessageId (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V279.Id.GuildOrDmId (Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelMessageId) (Evergreen.V279.Id.Id Evergreen.V279.Id.ThreadMessageId) (Evergreen.V279.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.Id.ThreadMessageId) (Evergreen.V279.Message.Message Evergreen.V279.Id.ThreadMessageId (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V279.Id.DiscordGuildOrDmId (Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelMessageId) (Evergreen.V279.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelMessageId) (Evergreen.V279.Message.Message Evergreen.V279.Id.ChannelMessageId (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V279.Id.DiscordGuildOrDmId (Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelMessageId) (Evergreen.V279.Id.Id Evergreen.V279.Id.ThreadMessageId) (Evergreen.V279.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.Id.ThreadMessageId) (Evergreen.V279.Message.Message Evergreen.V279.Id.ThreadMessageId (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V279.Id.Id Evergreen.V279.Id.GuildId) Evergreen.V279.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId) (Evergreen.V279.Discord.Id Evergreen.V279.Discord.GuildId) Evergreen.V279.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V279.UserSession.NotificationMode
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V279.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V279.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V279.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V279.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V279.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V279.NonemptySet.NonemptySet (Evergreen.V279.Id.Id Evergreen.V279.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V279.Call.LocalChange
    | Local_Go
        { otherUserId : Evergreen.V279.Id.Id Evergreen.V279.Id.UserId
        }
        Evergreen.V279.Go.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId) Effect.Time.Posix Evergreen.V279.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V279.RichText.RichText (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId))) Evergreen.V279.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.FileStatus.FileId) Evergreen.V279.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.Id.StickerId) Evergreen.V279.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V279.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V279.RichText.RichText (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId))) Evergreen.V279.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.FileStatus.FileId) Evergreen.V279.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.Id.StickerId) Evergreen.V279.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V279.Id.Id Evergreen.V279.Id.GuildId) Evergreen.V279.ChannelName.ChannelName Evergreen.V279.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V279.Id.Id Evergreen.V279.Id.GuildId) (Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelId) Evergreen.V279.ChannelName.ChannelName Evergreen.V279.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V279.Id.Id Evergreen.V279.Id.GuildId) (Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelId)
    | Server_DeleteGuild (Evergreen.V279.Id.Id Evergreen.V279.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId) (Evergreen.V279.Id.Id Evergreen.V279.Id.GuildId) (Evergreen.V279.SecretId.SecretId Evergreen.V279.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V279.Id.Id Evergreen.V279.Id.GuildId) (Evergreen.V279.SecretId.SecretId Evergreen.V279.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId) (Evergreen.V279.Id.Id Evergreen.V279.Id.GuildId) Evergreen.V279.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V279.LocalState.JoinGuildError
            { guildId : Evergreen.V279.Id.Id Evergreen.V279.Id.GuildId
            , guild : Evergreen.V279.LocalState.FrontendGuild
            , owner : Evergreen.V279.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId) Evergreen.V279.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId) Evergreen.V279.Id.GuildOrDmId Evergreen.V279.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId) (Evergreen.V279.Discord.Id Evergreen.V279.Discord.GuildId) (Evergreen.V279.Discord.Id Evergreen.V279.Discord.ChannelId) Evergreen.V279.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId) (Evergreen.V279.Discord.Id Evergreen.V279.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId) Evergreen.V279.Id.GuildOrDmId Evergreen.V279.Id.ThreadRouteWithMessage Evergreen.V279.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId) Evergreen.V279.Id.GuildOrDmId Evergreen.V279.Id.ThreadRouteWithMessage Evergreen.V279.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId) (Evergreen.V279.Discord.Id Evergreen.V279.Discord.GuildId) (Evergreen.V279.Discord.Id Evergreen.V279.Discord.ChannelId) Evergreen.V279.Id.ThreadRouteWithMessage Evergreen.V279.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId) (Evergreen.V279.Discord.Id Evergreen.V279.Discord.PrivateChannelId) (Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelMessageId) Evergreen.V279.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId) (Evergreen.V279.Discord.Id Evergreen.V279.Discord.GuildId) (Evergreen.V279.Discord.Id Evergreen.V279.Discord.ChannelId) Evergreen.V279.Id.ThreadRouteWithMessage Evergreen.V279.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId) (Evergreen.V279.Discord.Id Evergreen.V279.Discord.PrivateChannelId) (Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelMessageId) Evergreen.V279.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId) Evergreen.V279.Id.GuildOrDmId Evergreen.V279.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V279.RichText.RichText (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId))) (SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.FileStatus.FileId) Evergreen.V279.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId) (Evergreen.V279.Discord.Id Evergreen.V279.Discord.GuildId) (Evergreen.V279.Discord.Id Evergreen.V279.Discord.ChannelId) Evergreen.V279.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V279.RichText.RichText (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V279.Id.DiscordGuildOrDmId_DmData (Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V279.RichText.RichText (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId) Evergreen.V279.Id.AnyGuildOrDmId Evergreen.V279.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V279.Id.AnyGuildOrDmId Evergreen.V279.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V279.Discord.Id Evergreen.V279.Discord.GuildId) (Evergreen.V279.Discord.Id Evergreen.V279.Discord.ChannelId) Evergreen.V279.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V279.Discord.Id Evergreen.V279.Discord.PrivateChannelId) (Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId) Evergreen.V279.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId) Evergreen.V279.FileStatus.FileHash
    | Server_SetGuildIcon (Evergreen.V279.Id.Id Evergreen.V279.Id.GuildId) Evergreen.V279.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V279.Id.Id Evergreen.V279.Id.GuildId) Evergreen.V279.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V279.Discord.Id Evergreen.V279.Discord.GuildId) Evergreen.V279.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V279.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V279.SessionIdHash.SessionIdHash Evergreen.V279.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V279.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V279.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V279.Id.AnyGuildOrDmId, Evergreen.V279.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V279.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId) Evergreen.V279.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V279.Discord.Id Evergreen.V279.Discord.GuildId) (Evergreen.V279.Discord.Id Evergreen.V279.Discord.ChannelId) Evergreen.V279.ChannelName.ChannelName (Evergreen.V279.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V279.Discord.Id Evergreen.V279.Discord.PrivateChannelId)
        (Evergreen.V279.NonemptyDict.NonemptyDict
            (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V279.Discord.Id Evergreen.V279.Discord.GuildId) Evergreen.V279.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V279.Discord.Id Evergreen.V279.Discord.PrivateChannelId) Evergreen.V279.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId) Evergreen.V279.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId) (Maybe (Evergreen.V279.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V279.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V279.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V279.Id.Id Evergreen.V279.Id.GuildId) (Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelId) Evergreen.V279.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V279.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId) Evergreen.V279.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V279.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V279.Discord.Id Evergreen.V279.Discord.GuildId) (Evergreen.V279.Discord.Id Evergreen.V279.Discord.ChannelId) Evergreen.V279.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V279.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V279.Discord.Id Evergreen.V279.Discord.PrivateChannelId) (Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V279.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V279.Discord.Id Evergreen.V279.Discord.GuildId) Evergreen.V279.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V279.Discord.Id Evergreen.V279.Discord.GuildId) (Evergreen.V279.Discord.Id Evergreen.V279.Discord.ChannelId) (Evergreen.V279.Discord.OptionalData String) (Evergreen.V279.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V279.Discord.Id Evergreen.V279.Discord.GuildId)
        (Evergreen.V279.MembersAndOwner.MembersAndOwner
            (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V279.Discord.Id Evergreen.V279.Discord.GuildId) (Evergreen.V279.Discord.Id Evergreen.V279.Discord.ChannelId) (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId) Evergreen.V279.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.Id.StickerId) Evergreen.V279.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.Id.CustomEmojiId) Evergreen.V279.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V279.Call.ServerChange
    | Server_Go
        (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId)
        { otherUserId : Evergreen.V279.Id.Id Evergreen.V279.Id.UserId
        }
        Evergreen.V279.Go.LocalChange


type LocalMsg
    = LocalChange (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V279.Id.Id Evergreen.V279.Id.GuildId) (Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelId) Evergreen.V279.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V279.Discord.Id Evergreen.V279.Discord.GuildId) (Evergreen.V279.Discord.Id Evergreen.V279.Discord.ChannelId) Evergreen.V279.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.FileStatus.FileId) Evergreen.V279.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V279.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V279.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V279.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V279.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V279.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V279.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V279.Coord.Coord Evergreen.V279.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V279.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V279.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V279.Id.AnyGuildOrDmId Evergreen.V279.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V279.Id.AnyGuildOrDmId Evergreen.V279.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V279.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V279.Coord.Coord Evergreen.V279.CssPixels.CssPixels) (Maybe Evergreen.V279.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V279.Id.AnyGuildOrDmId, Evergreen.V279.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelMessageId) (Evergreen.V279.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.Id.ThreadMessageId) (Evergreen.V279.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V279.Editable.Model
    , showLinkDiscordSetup : Bool
    , domainWhitelistInput : String
    , serviceWorkerData : Maybe String
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V279.Local.Local LocalMsg Evergreen.V279.LocalState.LocalState
    , admin : Evergreen.V279.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V279.Id.AnyGuildOrDmId, Evergreen.V279.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V279.Id.Id Evergreen.V279.Id.GuildId, Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V279.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V279.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V279.Id.AnyGuildOrDmId, Evergreen.V279.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V279.Id.AnyGuildOrDmId, Evergreen.V279.Id.ThreadRoute ) (Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : Evergreen.V279.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V279.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V279.Id.AnyGuildOrDmId, Evergreen.V279.Id.ThreadRoute ) (Evergreen.V279.NonemptyDict.NonemptyDict (Evergreen.V279.Id.Id Evergreen.V279.FileStatus.FileId) Evergreen.V279.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V279.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V279.TextEditor.Model
    , profilePictureEditor : Evergreen.V279.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V279.Id.Id Evergreen.V279.Id.GuildId, Evergreen.V279.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V279.Emoji.Model
    , voiceChat : Evergreen.V279.Call.Model
    , currentDmGoMatch : SeqDict.SeqDict ( Evergreen.V279.Id.Id Evergreen.V279.Id.UserId, Maybe (Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelMessageId) ) Evergreen.V279.Go.Model
    , fileDragOverCount : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V279.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V279.SecretId.SecretId Evergreen.V279.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V279.Range.Range
                , direction : Evergreen.V279.Range.SelectionDirection
                }
        }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V279.NonemptyDict.NonemptyDict Int Evergreen.V279.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V279.NonemptyDict.NonemptyDict Int Evergreen.V279.Touch.Touch
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
    | AdminToFrontend Evergreen.V279.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V279.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V279.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V279.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V279.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V279.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V279.Go.PublicGoMatchResponse)


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V279.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V279.Coord.Coord Evergreen.V279.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V279.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V279.MyUi.LastCopy
    , notificationPermission : Evergreen.V279.Ports.NotificationPermission
    , pwaStatus : Evergreen.V279.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V279.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V279.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V279.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V279.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V279.Id.Id Evergreen.V279.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V279.Id.Id Evergreen.V279.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V279.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V279.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V279.Coord.Coord Evergreen.V279.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V279.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V279.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V279.Id.Id Evergreen.V279.Id.GuildId, Evergreen.V279.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V279.DmChannel.DmChannelId, Evergreen.V279.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V279.Discord.Id Evergreen.V279.Discord.GuildId, Evergreen.V279.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V279.Discord.Id Evergreen.V279.Discord.PrivateChannelId, Evergreen.V279.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V279.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V279.NonemptyDict.NonemptyDict (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId) Evergreen.V279.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V279.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V279.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V279.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V279.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId) Evergreen.V279.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId) Evergreen.V279.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V279.Id.Id Evergreen.V279.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.Id.GuildId) Evergreen.V279.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.Id.GuildId) Evergreen.V279.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V279.Discord.Id Evergreen.V279.Discord.GuildId) Evergreen.V279.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V279.DmChannel.DmChannelId Evergreen.V279.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V279.Discord.Id Evergreen.V279.Discord.PrivateChannelId) Evergreen.V279.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V279.OneToOne.OneToOne (Evergreen.V279.Slack.Id Evergreen.V279.Slack.ChannelId) Evergreen.V279.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V279.OneToOne.OneToOne String (Evergreen.V279.Id.Id Evergreen.V279.Id.GuildId)
    , slackUsers : Evergreen.V279.OneToOne.OneToOne (Evergreen.V279.Slack.Id Evergreen.V279.Slack.UserId) (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId)
    , slackServers : Evergreen.V279.OneToOne.OneToOne (Evergreen.V279.Slack.Id Evergreen.V279.Slack.TeamId) (Evergreen.V279.Id.Id Evergreen.V279.Id.GuildId)
    , slackToken : Maybe Evergreen.V279.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V279.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V279.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V279.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V279.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V279.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V279.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V279.Cloudflare.AnalyticsApiToken
    , textEditor : Evergreen.V279.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId) Evergreen.V279.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId, Evergreen.V279.Discord.Id Evergreen.V279.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V279.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V279.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V279.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V279.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId) (Evergreen.V279.LocalState.LoadingDiscordChannel (List Evergreen.V279.Discord.Message))
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V279.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.Id.StickerId) Evergreen.V279.Sticker.StickerData
    , discordStickers : Evergreen.V279.OneToOne.OneToOne (Evergreen.V279.Discord.Id Evergreen.V279.Discord.StickerId) (Evergreen.V279.Id.Id Evergreen.V279.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.Id.CustomEmojiId) Evergreen.V279.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V279.OneToOne.OneToOne Evergreen.V279.RichText.DiscordCustomEmojiIdAndName (Evergreen.V279.Id.Id Evergreen.V279.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V279.Postmark.ApiKey
    , serverSecret : Evergreen.V279.SecretId.SecretId Evergreen.V279.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V279.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V279.OneToOne.OneToOne (Evergreen.V279.SecretId.SecretId Evergreen.V279.Id.GoMatchPublicId) ( Evergreen.V279.DmChannel.DmChannelId, Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelMessageId )
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V279.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V279.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V279.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V279.Route.Route
    | SelectedFilesToAttach ( Evergreen.V279.Id.AnyGuildOrDmId, Evergreen.V279.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V279.Id.Id Evergreen.V279.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V279.Id.Id Evergreen.V279.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V279.Id.Id Evergreen.V279.Id.GuildId) (Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelId) Evergreen.V279.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V279.Id.Id Evergreen.V279.Id.GuildId) (Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelId) Evergreen.V279.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V279.Discord.Id Evergreen.V279.Discord.GuildId) (Evergreen.V279.Discord.Id Evergreen.V279.Discord.ChannelId) Evergreen.V279.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V279.Discord.Id Evergreen.V279.Discord.GuildId) (Evergreen.V279.Discord.Id Evergreen.V279.Discord.ChannelId) Evergreen.V279.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V279.Id.Id Evergreen.V279.Id.GuildId) (Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V279.Id.Id Evergreen.V279.Id.GuildId) (Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V279.Id.Id Evergreen.V279.Id.GuildId) (Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V279.Id.Id Evergreen.V279.Id.GuildId) (Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V279.Id.Id Evergreen.V279.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V279.Id.Id Evergreen.V279.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V279.Id.Id Evergreen.V279.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V279.Id.Id Evergreen.V279.Id.GuildId) (Evergreen.V279.SecretId.SecretId Evergreen.V279.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V279.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V279.Id.AnyGuildOrDmId Evergreen.V279.Id.ThreadRouteWithMessage (Evergreen.V279.Coord.Coord Evergreen.V279.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V279.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V279.Id.AnyGuildOrDmId Evergreen.V279.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V279.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V279.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V279.Id.AnyGuildOrDmId, Evergreen.V279.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V279.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V279.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V279.Id.AnyGuildOrDmId, Evergreen.V279.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V279.NonemptyDict.NonemptyDict Int Evergreen.V279.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V279.NonemptyDict.NonemptyDict Int Evergreen.V279.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V279.Id.AnyGuildOrDmId Evergreen.V279.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V279.Id.AnyGuildOrDmId Evergreen.V279.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V279.NonemptySet.NonemptySet (Evergreen.V279.Id.Id Evergreen.V279.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V279.Id.AnyGuildOrDmId, Evergreen.V279.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V279.Id.AnyGuildOrDmId Evergreen.V279.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V279.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V279.AiChat.Msg
    | GoMsg Evergreen.V279.Go.Msg
    | GoSpectatorMsg Evergreen.V279.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V279.Editable.Msg Evergreen.V279.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V279.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V279.Id.Id Evergreen.V279.Id.GuildId) Evergreen.V279.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V279.Id.AnyGuildOrDmId, Evergreen.V279.Id.ThreadRoute ) (Evergreen.V279.Id.Id Evergreen.V279.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V279.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V279.Id.AnyGuildOrDmId, Evergreen.V279.Id.ThreadRoute ) (Evergreen.V279.Id.Id Evergreen.V279.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V279.Id.AnyGuildOrDmId, Evergreen.V279.Id.ThreadRoute ) (Evergreen.V279.Id.Id Evergreen.V279.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V279.Id.AnyGuildOrDmId, Evergreen.V279.Id.ThreadRoute )
        { fileId : Evergreen.V279.Id.Id Evergreen.V279.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V279.Id.AnyGuildOrDmId, Evergreen.V279.Id.ThreadRoute ) (Evergreen.V279.Id.Id Evergreen.V279.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V279.Id.AnyGuildOrDmId, Evergreen.V279.Id.ThreadRoute ) (Evergreen.V279.Id.Id Evergreen.V279.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V279.Id.AnyGuildOrDmId, Evergreen.V279.Id.ThreadRoute )
        { fileId : Evergreen.V279.Id.Id Evergreen.V279.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V279.Id.AnyGuildOrDmId, Evergreen.V279.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V279.Id.AnyGuildOrDmId, Evergreen.V279.Id.ThreadRoute ) (Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelMessageId) (Evergreen.V279.Id.Id Evergreen.V279.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V279.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V279.Id.AnyGuildOrDmId, Evergreen.V279.Id.ThreadRoute ) (Evergreen.V279.Id.Id Evergreen.V279.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V279.Id.AnyGuildOrDmId Evergreen.V279.Id.ThreadRouteWithMessage Evergreen.V279.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V279.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V279.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V279.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V279.Id.Id Evergreen.V279.Id.GuildId) Evergreen.V279.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId) (Evergreen.V279.Discord.Id Evergreen.V279.Discord.GuildId) Evergreen.V279.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V279.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V279.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId
        , otherUserId : Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V279.Id.AnyGuildOrDmId Evergreen.V279.Id.ThreadRoute Evergreen.V279.MessageInput.Msg
    | MessageInputMsg Evergreen.V279.Id.AnyGuildOrDmId Evergreen.V279.Id.ThreadRoute Evergreen.V279.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V279.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V279.Range.Range, Evergreen.V279.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V279.Range.Range, Evergreen.V279.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V279.Call.FromJs)
    | VoiceChatMsg Evergreen.V279.Call.Msg
    | PressedChannelHeaderTab Evergreen.V279.Route.DmChannelHeaderTab
    | FileDragEnter
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadServiceWorkerData
    | GotServiceWorkerData String


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V279.Id.Id Evergreen.V279.Id.GuildId) (Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelId) Evergreen.V279.Id.ThreadRoute
    | InitialLoadRequested_Dm Evergreen.V279.DmChannel.DmChannelId Evergreen.V279.Id.ThreadRoute
    | InitialLoadRequested_Discord Evergreen.V279.Id.DiscordGuildOrDmId Evergreen.V279.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V279.Id.Id Evergreen.V279.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V279.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V279.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V279.Untrusted.Untrusted Evergreen.V279.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V279.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V279.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V279.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V279.Id.Id Evergreen.V279.Id.GuildId) (Evergreen.V279.SecretId.SecretId Evergreen.V279.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V279.PersonName.PersonName Evergreen.V279.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V279.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V279.Slack.OAuthCode Evergreen.V279.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V279.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V279.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V279.Id.Id Evergreen.V279.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V279.SecretId.SecretId Evergreen.V279.Id.GoMatchPublicId)


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V279.Discord.Id Evergreen.V279.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V279.Discord.Id Evergreen.V279.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V279.EmailAddress.EmailAddress (Result Evergreen.V279.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V279.EmailAddress.EmailAddress (Result Evergreen.V279.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V279.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V279.Discord.Id Evergreen.V279.Discord.GuildId) (Evergreen.V279.Discord.Id Evergreen.V279.Discord.ChannelId) Evergreen.V279.Id.ThreadRouteWithMaybeMessage (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId) (Result Evergreen.V279.Discord.HttpError Evergreen.V279.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V279.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V279.Discord.Id Evergreen.V279.Discord.PrivateChannelId) (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId) (Result Evergreen.V279.Discord.HttpError Evergreen.V279.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V279.Discord.Id Evergreen.V279.Discord.GuildId) (Evergreen.V279.Discord.Id Evergreen.V279.Discord.ChannelId) Evergreen.V279.Id.ThreadRouteWithMessage (Evergreen.V279.Discord.Id Evergreen.V279.Discord.MessageId) (Result Evergreen.V279.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V279.Discord.Id Evergreen.V279.Discord.PrivateChannelId) (Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelMessageId) (Evergreen.V279.Discord.Id Evergreen.V279.Discord.MessageId) (Result Evergreen.V279.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V279.Discord.Id Evergreen.V279.Discord.GuildId) (Evergreen.V279.Discord.Id Evergreen.V279.Discord.ChannelId) Evergreen.V279.Id.ThreadRouteWithMessage (Evergreen.V279.Discord.Id Evergreen.V279.Discord.MessageId) (Result Evergreen.V279.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V279.Discord.Id Evergreen.V279.Discord.PrivateChannelId) (Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelMessageId) (Evergreen.V279.Discord.Id Evergreen.V279.Discord.MessageId) (Result Evergreen.V279.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V279.Discord.Id Evergreen.V279.Discord.GuildId) (Evergreen.V279.Discord.Id Evergreen.V279.Discord.ChannelId) Evergreen.V279.Id.ThreadRouteWithMessage (Evergreen.V279.Discord.Id Evergreen.V279.Discord.MessageId) Evergreen.V279.Emoji.EmojiOrCustomEmoji (Result Evergreen.V279.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V279.Discord.Id Evergreen.V279.Discord.PrivateChannelId) (Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelMessageId) (Evergreen.V279.Discord.Id Evergreen.V279.Discord.MessageId) Evergreen.V279.Emoji.EmojiOrCustomEmoji (Result Evergreen.V279.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V279.Discord.Id Evergreen.V279.Discord.GuildId) (Evergreen.V279.Discord.Id Evergreen.V279.Discord.ChannelId) Evergreen.V279.Id.ThreadRouteWithMessage (Evergreen.V279.Discord.Id Evergreen.V279.Discord.MessageId) Evergreen.V279.Emoji.EmojiOrCustomEmoji (Result Evergreen.V279.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V279.Discord.Id Evergreen.V279.Discord.PrivateChannelId) (Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelMessageId) (Evergreen.V279.Discord.Id Evergreen.V279.Discord.MessageId) Evergreen.V279.Emoji.EmojiOrCustomEmoji (Result Evergreen.V279.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V279.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V279.Discord.HttpError (List ( Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId, Maybe Evergreen.V279.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId) Effect.Time.Posix Evergreen.V279.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V279.Slack.CurrentUser
            , team : Evergreen.V279.Slack.Team
            , users : List Evergreen.V279.Slack.User
            , channels : List ( Evergreen.V279.Slack.Channel, List Evergreen.V279.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId) (Result Effect.Http.Error Evergreen.V279.Slack.TokenResponse)
    | GotCloudflareSessionCreated Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V279.Local.ChangeId Effect.Time.Posix Evergreen.V279.Call.CallId Evergreen.V279.Cloudflare.Sdp (List String) (Result Effect.Http.Error Evergreen.V279.Cloudflare.RealtimeSessionId)
    | GotCloudflareSession Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V279.Local.ChangeId Effect.Time.Posix Evergreen.V279.Call.CallId Evergreen.V279.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V279.Cloudflare.PushTracksResult)
    | GotCloudflarePullOffer Effect.Time.Posix Effect.Lamdera.ClientId Evergreen.V279.Local.ChangeId Evergreen.V279.Call.ConnectionId Evergreen.V279.Cloudflare.RealtimeSessionId (List Evergreen.V279.Cloudflare.TrackName) (Result Effect.Http.Error Evergreen.V279.Cloudflare.PullTracksResult)
    | GotCloudflareRenegotiateAck Effect.Lamdera.ClientId Evergreen.V279.Local.ChangeId Evergreen.V279.Cloudflare.Sdp (Result Effect.Http.Error ())
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId) Evergreen.V279.Discord.UserAuth (Result Evergreen.V279.Discord.HttpError Evergreen.V279.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId) (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId) (Result Evergreen.V279.Discord.HttpError Evergreen.V279.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId)
        (Result
            Evergreen.V279.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V279.Discord.Id Evergreen.V279.Discord.PrivateChannelId
                , members : List (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId)
                }
            , List
                ( Evergreen.V279.Discord.Id Evergreen.V279.Discord.GuildId
                , { guild : Evergreen.V279.Discord.GatewayGuild
                  , channels : List Evergreen.V279.Discord.Channel
                  , icon : Maybe Evergreen.V279.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId) Bool Evergreen.V279.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V279.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V279.Discord.Id Evergreen.V279.Discord.AttachmentId, Evergreen.V279.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V279.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V279.Discord.Id Evergreen.V279.Discord.AttachmentId, Evergreen.V279.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId) (Evergreen.V279.Discord.Id Evergreen.V279.Discord.GuildId) (Evergreen.V279.Discord.Id Evergreen.V279.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V279.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V279.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId) (Evergreen.V279.Discord.Id Evergreen.V279.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V279.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V279.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId) (Evergreen.V279.Discord.Id Evergreen.V279.Discord.GuildId) (Evergreen.V279.Discord.Id Evergreen.V279.Discord.ChannelId) (Result Evergreen.V279.Discord.HttpError (List Evergreen.V279.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId) (Evergreen.V279.Discord.Id Evergreen.V279.Discord.PrivateChannelId) (Result Evergreen.V279.Discord.HttpError (List Evergreen.V279.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V279.Id.Id Evergreen.V279.Id.GuildId) (Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelId) Evergreen.V279.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V279.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V279.DmChannel.DmChannelId Evergreen.V279.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V279.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V279.Discord.Id Evergreen.V279.Discord.GuildId) (Evergreen.V279.Discord.Id Evergreen.V279.Discord.ChannelId) Evergreen.V279.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V279.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V279.Discord.Id Evergreen.V279.Discord.PrivateChannelId) (Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V279.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId)
        (Evergreen.V279.Discord.Id Evergreen.V279.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V279.Discord.HttpError
            { guild : Evergreen.V279.Discord.GatewayGuild
            , channels : List Evergreen.V279.Discord.Channel
            , icon : Maybe Evergreen.V279.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V279.Discord.Id Evergreen.V279.Discord.GuildId) (Result Evergreen.V279.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V279.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId) (List ( Evergreen.V279.Id.Id Evergreen.V279.Id.StickerId, Result Effect.Http.Error Evergreen.V279.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V279.Id.Id Evergreen.V279.Id.StickerId, Result Effect.Http.Error Evergreen.V279.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId) (List ( Evergreen.V279.Id.Id Evergreen.V279.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V279.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V279.Id.Id Evergreen.V279.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V279.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V279.Discord.HttpError (List Evergreen.V279.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V279.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V279.SecretId.SecretId Evergreen.V279.SecretId.ServerSecret))
    | GotTimeForWebsocketListenClose (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | GotCloudflareUsage Effect.Time.Posix (Result Effect.Http.Error Int)
    | GotCloudflareEgressForAdmin Effect.Lamdera.ClientId (Result Effect.Http.Error Int)
