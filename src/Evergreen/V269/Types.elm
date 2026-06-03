module Evergreen.V269.Types exposing (..)

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
import Evergreen.V269.AiChat
import Evergreen.V269.Call
import Evergreen.V269.ChannelDescription
import Evergreen.V269.ChannelName
import Evergreen.V269.Cloudflare
import Evergreen.V269.Coord
import Evergreen.V269.CssPixels
import Evergreen.V269.CustomEmoji
import Evergreen.V269.Discord
import Evergreen.V269.DiscordAttachmentId
import Evergreen.V269.DiscordUserData
import Evergreen.V269.DmChannel
import Evergreen.V269.Editable
import Evergreen.V269.EmailAddress
import Evergreen.V269.Embed
import Evergreen.V269.Emoji
import Evergreen.V269.FileStatus
import Evergreen.V269.Go
import Evergreen.V269.GuildName
import Evergreen.V269.Id
import Evergreen.V269.ImageEditor
import Evergreen.V269.ImageViewer
import Evergreen.V269.Local
import Evergreen.V269.LocalState
import Evergreen.V269.Log
import Evergreen.V269.LoginForm
import Evergreen.V269.MembersAndOwner
import Evergreen.V269.Message
import Evergreen.V269.MessageInput
import Evergreen.V269.MessageView
import Evergreen.V269.MyUi
import Evergreen.V269.NonemptyDict
import Evergreen.V269.NonemptySet
import Evergreen.V269.OneToOne
import Evergreen.V269.Pages.Admin
import Evergreen.V269.Pagination
import Evergreen.V269.PersonName
import Evergreen.V269.Ports
import Evergreen.V269.Postmark
import Evergreen.V269.Range
import Evergreen.V269.RichText
import Evergreen.V269.Route
import Evergreen.V269.SecretId
import Evergreen.V269.SessionIdHash
import Evergreen.V269.Slack
import Evergreen.V269.Sticker
import Evergreen.V269.TextEditor
import Evergreen.V269.ToBackendLog
import Evergreen.V269.Touch
import Evergreen.V269.TwoFactorAuthentication
import Evergreen.V269.Ui.Anim
import Evergreen.V269.Untrusted
import Evergreen.V269.User
import Evergreen.V269.UserAgent
import Evergreen.V269.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V269.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V269.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.Id.GuildId) Evergreen.V269.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId) Evergreen.V269.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V269.Discord.Id Evergreen.V269.Discord.PrivateChannelId) Evergreen.V269.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V269.Discord.Id Evergreen.V269.Discord.GuildId) Evergreen.V269.LocalState.DiscordFrontendGuild
    , user : Evergreen.V269.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId) Evergreen.V269.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId) Evergreen.V269.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId) Evergreen.V269.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V269.SessionIdHash.SessionIdHash Evergreen.V269.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V269.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.Id.StickerId) Evergreen.V269.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.Id.CustomEmojiId) Evergreen.V269.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V269.Call.CallId (Evergreen.V269.NonemptySet.NonemptySet ( Evergreen.V269.Id.Id Evergreen.V269.Id.UserId, Effect.Lamdera.ClientId ))
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type PublicGoMatch
    = PublicGoMatch_NotLoaded
    | PublicGoMatch_Loading
    | PublicGoMatch_Loaded Evergreen.V269.Go.PublicGoMatchData Evergreen.V269.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V269.Route.Route
    , windowSize : Evergreen.V269.Coord.Coord Evergreen.V269.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V269.Ports.NotificationPermission
    , pwaStatus : Evergreen.V269.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V269.UserAgent.UserAgent
    , publicGoMatch : PublicGoMatch
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V269.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V269.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V269.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.FileStatus.FileId) Evergreen.V269.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V269.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V269.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.FileStatus.FileId) Evergreen.V269.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V269.Id.Id Evergreen.V269.Id.GuildId) Evergreen.V269.ChannelName.ChannelName Evergreen.V269.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V269.Id.Id Evergreen.V269.Id.GuildId) (Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelId) Evergreen.V269.ChannelName.ChannelName Evergreen.V269.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V269.Id.Id Evergreen.V269.Id.GuildId) (Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelId)
    | Local_DeleteGuild (Evergreen.V269.Id.Id Evergreen.V269.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V269.Id.Id Evergreen.V269.Id.GuildId) (Evergreen.V269.UserSession.ToBeFilledInByBackend (Evergreen.V269.SecretId.SecretId Evergreen.V269.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V269.Id.Id Evergreen.V269.Id.GuildId) (Evergreen.V269.SecretId.SecretId Evergreen.V269.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V269.GuildName.GuildName (Evergreen.V269.UserSession.ToBeFilledInByBackend (Evergreen.V269.Id.Id Evergreen.V269.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V269.Id.AnyGuildOrDmId, Evergreen.V269.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V269.Id.AnyGuildOrDmId Evergreen.V269.Id.ThreadRouteWithMessage Evergreen.V269.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V269.Id.AnyGuildOrDmId Evergreen.V269.Id.ThreadRouteWithMessage Evergreen.V269.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V269.Id.GuildOrDmId Evergreen.V269.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.FileStatus.FileId) Evergreen.V269.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId) (Evergreen.V269.Discord.Id Evergreen.V269.Discord.GuildId) (Evergreen.V269.Discord.Id Evergreen.V269.Discord.ChannelId) Evergreen.V269.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V269.Id.DiscordGuildOrDmId_DmData (Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V269.Id.AnyGuildOrDmId Evergreen.V269.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V269.Id.AnyGuildOrDmId Evergreen.V269.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V269.Id.AnyGuildOrDmId Evergreen.V269.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V269.UserSession.SetViewing
    | Local_SetName Evergreen.V269.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V269.Id.GuildOrDmId (Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelMessageId) (Evergreen.V269.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelMessageId) (Evergreen.V269.Message.Message Evergreen.V269.Id.ChannelMessageId (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V269.Id.GuildOrDmId (Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelMessageId) (Evergreen.V269.Id.Id Evergreen.V269.Id.ThreadMessageId) (Evergreen.V269.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.Id.ThreadMessageId) (Evergreen.V269.Message.Message Evergreen.V269.Id.ThreadMessageId (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V269.Id.DiscordGuildOrDmId (Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelMessageId) (Evergreen.V269.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelMessageId) (Evergreen.V269.Message.Message Evergreen.V269.Id.ChannelMessageId (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V269.Id.DiscordGuildOrDmId (Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelMessageId) (Evergreen.V269.Id.Id Evergreen.V269.Id.ThreadMessageId) (Evergreen.V269.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.Id.ThreadMessageId) (Evergreen.V269.Message.Message Evergreen.V269.Id.ThreadMessageId (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V269.Id.Id Evergreen.V269.Id.GuildId) Evergreen.V269.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId) (Evergreen.V269.Discord.Id Evergreen.V269.Discord.GuildId) Evergreen.V269.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V269.UserSession.NotificationMode
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V269.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V269.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V269.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V269.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V269.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V269.NonemptySet.NonemptySet (Evergreen.V269.Id.Id Evergreen.V269.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V269.Call.LocalChange
    | Local_Go
        { otherUserId : Evergreen.V269.Id.Id Evergreen.V269.Id.UserId
        }
        Evergreen.V269.Go.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId) Effect.Time.Posix Evergreen.V269.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V269.RichText.RichText (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId))) Evergreen.V269.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.FileStatus.FileId) Evergreen.V269.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.Id.StickerId) Evergreen.V269.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V269.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V269.RichText.RichText (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId))) Evergreen.V269.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.FileStatus.FileId) Evergreen.V269.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.Id.StickerId) Evergreen.V269.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V269.Id.Id Evergreen.V269.Id.GuildId) Evergreen.V269.ChannelName.ChannelName Evergreen.V269.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V269.Id.Id Evergreen.V269.Id.GuildId) (Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelId) Evergreen.V269.ChannelName.ChannelName Evergreen.V269.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V269.Id.Id Evergreen.V269.Id.GuildId) (Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelId)
    | Server_DeleteGuild (Evergreen.V269.Id.Id Evergreen.V269.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId) (Evergreen.V269.Id.Id Evergreen.V269.Id.GuildId) (Evergreen.V269.SecretId.SecretId Evergreen.V269.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V269.Id.Id Evergreen.V269.Id.GuildId) (Evergreen.V269.SecretId.SecretId Evergreen.V269.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId) (Evergreen.V269.Id.Id Evergreen.V269.Id.GuildId) Evergreen.V269.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V269.LocalState.JoinGuildError
            { guildId : Evergreen.V269.Id.Id Evergreen.V269.Id.GuildId
            , guild : Evergreen.V269.LocalState.FrontendGuild
            , owner : Evergreen.V269.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId) Evergreen.V269.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId) Evergreen.V269.Id.GuildOrDmId Evergreen.V269.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId) (Evergreen.V269.Discord.Id Evergreen.V269.Discord.GuildId) (Evergreen.V269.Discord.Id Evergreen.V269.Discord.ChannelId) Evergreen.V269.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId) (Evergreen.V269.Discord.Id Evergreen.V269.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId) Evergreen.V269.Id.GuildOrDmId Evergreen.V269.Id.ThreadRouteWithMessage Evergreen.V269.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId) Evergreen.V269.Id.GuildOrDmId Evergreen.V269.Id.ThreadRouteWithMessage Evergreen.V269.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId) (Evergreen.V269.Discord.Id Evergreen.V269.Discord.GuildId) (Evergreen.V269.Discord.Id Evergreen.V269.Discord.ChannelId) Evergreen.V269.Id.ThreadRouteWithMessage Evergreen.V269.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId) (Evergreen.V269.Discord.Id Evergreen.V269.Discord.PrivateChannelId) (Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelMessageId) Evergreen.V269.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId) (Evergreen.V269.Discord.Id Evergreen.V269.Discord.GuildId) (Evergreen.V269.Discord.Id Evergreen.V269.Discord.ChannelId) Evergreen.V269.Id.ThreadRouteWithMessage Evergreen.V269.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId) (Evergreen.V269.Discord.Id Evergreen.V269.Discord.PrivateChannelId) (Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelMessageId) Evergreen.V269.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId) Evergreen.V269.Id.GuildOrDmId Evergreen.V269.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V269.RichText.RichText (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId))) (SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.FileStatus.FileId) Evergreen.V269.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId) (Evergreen.V269.Discord.Id Evergreen.V269.Discord.GuildId) (Evergreen.V269.Discord.Id Evergreen.V269.Discord.ChannelId) Evergreen.V269.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V269.RichText.RichText (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V269.Id.DiscordGuildOrDmId_DmData (Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V269.RichText.RichText (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId) Evergreen.V269.Id.AnyGuildOrDmId Evergreen.V269.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V269.Id.AnyGuildOrDmId Evergreen.V269.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V269.Discord.Id Evergreen.V269.Discord.GuildId) (Evergreen.V269.Discord.Id Evergreen.V269.Discord.ChannelId) Evergreen.V269.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V269.Discord.Id Evergreen.V269.Discord.PrivateChannelId) (Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId) Evergreen.V269.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId) Evergreen.V269.FileStatus.FileHash
    | Server_SetGuildIcon (Evergreen.V269.Id.Id Evergreen.V269.Id.GuildId) Evergreen.V269.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V269.Id.Id Evergreen.V269.Id.GuildId) Evergreen.V269.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V269.Discord.Id Evergreen.V269.Discord.GuildId) Evergreen.V269.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V269.SessionIdHash.SessionIdHash Evergreen.V269.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V269.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V269.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V269.Id.AnyGuildOrDmId, Evergreen.V269.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V269.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId) Evergreen.V269.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V269.Discord.Id Evergreen.V269.Discord.GuildId) (Evergreen.V269.Discord.Id Evergreen.V269.Discord.ChannelId) Evergreen.V269.ChannelName.ChannelName (Evergreen.V269.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V269.Discord.Id Evergreen.V269.Discord.PrivateChannelId)
        (Evergreen.V269.NonemptyDict.NonemptyDict
            (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V269.Discord.Id Evergreen.V269.Discord.GuildId) Evergreen.V269.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V269.Discord.Id Evergreen.V269.Discord.PrivateChannelId) Evergreen.V269.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId) Evergreen.V269.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId) (Maybe (Evergreen.V269.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V269.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V269.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V269.Id.Id Evergreen.V269.Id.GuildId) (Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelId) Evergreen.V269.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V269.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId) Evergreen.V269.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V269.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V269.Discord.Id Evergreen.V269.Discord.GuildId) (Evergreen.V269.Discord.Id Evergreen.V269.Discord.ChannelId) Evergreen.V269.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V269.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V269.Discord.Id Evergreen.V269.Discord.PrivateChannelId) (Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V269.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V269.Discord.Id Evergreen.V269.Discord.GuildId) Evergreen.V269.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V269.Discord.Id Evergreen.V269.Discord.GuildId) (Evergreen.V269.Discord.Id Evergreen.V269.Discord.ChannelId) (Evergreen.V269.Discord.OptionalData String) (Evergreen.V269.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V269.Discord.Id Evergreen.V269.Discord.GuildId)
        (Evergreen.V269.MembersAndOwner.MembersAndOwner
            (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V269.Discord.Id Evergreen.V269.Discord.GuildId) (Evergreen.V269.Discord.Id Evergreen.V269.Discord.ChannelId) (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId) Evergreen.V269.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.Id.StickerId) Evergreen.V269.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.Id.CustomEmojiId) Evergreen.V269.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V269.Call.ServerChange
    | Server_Go
        (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId)
        { otherUserId : Evergreen.V269.Id.Id Evergreen.V269.Id.UserId
        }
        Evergreen.V269.Go.LocalChange


type LocalMsg
    = LocalChange (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V269.Id.Id Evergreen.V269.Id.GuildId) (Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelId) Evergreen.V269.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V269.Discord.Id Evergreen.V269.Discord.GuildId) (Evergreen.V269.Discord.Id Evergreen.V269.Discord.ChannelId) Evergreen.V269.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.FileStatus.FileId) Evergreen.V269.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V269.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V269.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V269.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V269.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V269.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V269.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V269.Coord.Coord Evergreen.V269.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V269.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V269.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V269.Id.AnyGuildOrDmId Evergreen.V269.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V269.Id.AnyGuildOrDmId Evergreen.V269.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V269.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V269.Coord.Coord Evergreen.V269.CssPixels.CssPixels) (Maybe Evergreen.V269.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V269.Id.AnyGuildOrDmId, Evergreen.V269.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelMessageId) (Evergreen.V269.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.Id.ThreadMessageId) (Evergreen.V269.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V269.Editable.Model
    , showLinkDiscordSetup : Bool
    , domainWhitelistInput : String
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V269.Local.Local LocalMsg Evergreen.V269.LocalState.LocalState
    , admin : Evergreen.V269.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V269.Id.AnyGuildOrDmId, Evergreen.V269.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V269.Id.Id Evergreen.V269.Id.GuildId, Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V269.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V269.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V269.Id.AnyGuildOrDmId, Evergreen.V269.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V269.Id.AnyGuildOrDmId, Evergreen.V269.Id.ThreadRoute ) (Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : Evergreen.V269.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V269.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V269.Id.AnyGuildOrDmId, Evergreen.V269.Id.ThreadRoute ) (Evergreen.V269.NonemptyDict.NonemptyDict (Evergreen.V269.Id.Id Evergreen.V269.FileStatus.FileId) Evergreen.V269.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V269.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V269.TextEditor.Model
    , profilePictureEditor : Evergreen.V269.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V269.Id.Id Evergreen.V269.Id.GuildId, Evergreen.V269.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V269.Emoji.Model
    , voiceChat : Evergreen.V269.Call.Model
    , currentDmGoMatch : SeqDict.SeqDict ( Evergreen.V269.Id.Id Evergreen.V269.Id.UserId, Maybe (Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelMessageId) ) Evergreen.V269.Go.Model
    , fileDragOverCount : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V269.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V269.SecretId.SecretId Evergreen.V269.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V269.Range.Range
                , direction : Evergreen.V269.Range.SelectionDirection
                }
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V269.NonemptyDict.NonemptyDict Int Evergreen.V269.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V269.NonemptyDict.NonemptyDict Int Evergreen.V269.Touch.Touch
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
    | AdminToFrontend Evergreen.V269.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V269.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V269.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V269.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V269.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V269.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V269.Go.PublicGoMatchResponse)


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V269.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V269.Coord.Coord Evergreen.V269.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V269.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V269.MyUi.LastCopy
    , notificationPermission : Evergreen.V269.Ports.NotificationPermission
    , pwaStatus : Evergreen.V269.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V269.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V269.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V269.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V269.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V269.Id.Id Evergreen.V269.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V269.Id.Id Evergreen.V269.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V269.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V269.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V269.Coord.Coord Evergreen.V269.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V269.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V269.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V269.Id.Id Evergreen.V269.Id.GuildId, Evergreen.V269.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V269.DmChannel.DmChannelId, Evergreen.V269.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V269.Discord.Id Evergreen.V269.Discord.GuildId, Evergreen.V269.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V269.Discord.Id Evergreen.V269.Discord.PrivateChannelId, Evergreen.V269.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V269.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V269.NonemptyDict.NonemptyDict (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId) Evergreen.V269.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V269.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V269.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V269.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V269.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId) Evergreen.V269.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId) Evergreen.V269.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V269.Id.Id Evergreen.V269.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.Id.GuildId) Evergreen.V269.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.Id.GuildId) Evergreen.V269.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V269.Discord.Id Evergreen.V269.Discord.GuildId) Evergreen.V269.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V269.DmChannel.DmChannelId Evergreen.V269.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V269.Discord.Id Evergreen.V269.Discord.PrivateChannelId) Evergreen.V269.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V269.OneToOne.OneToOne (Evergreen.V269.Slack.Id Evergreen.V269.Slack.ChannelId) Evergreen.V269.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V269.OneToOne.OneToOne String (Evergreen.V269.Id.Id Evergreen.V269.Id.GuildId)
    , slackUsers : Evergreen.V269.OneToOne.OneToOne (Evergreen.V269.Slack.Id Evergreen.V269.Slack.UserId) (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId)
    , slackServers : Evergreen.V269.OneToOne.OneToOne (Evergreen.V269.Slack.Id Evergreen.V269.Slack.TeamId) (Evergreen.V269.Id.Id Evergreen.V269.Id.GuildId)
    , slackToken : Maybe Evergreen.V269.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V269.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V269.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V269.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V269.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V269.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V269.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V269.Cloudflare.AnalyticsApiToken
    , textEditor : Evergreen.V269.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId) Evergreen.V269.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId, Evergreen.V269.Discord.Id Evergreen.V269.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V269.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V269.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V269.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V269.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId) (Evergreen.V269.LocalState.LoadingDiscordChannel (List Evergreen.V269.Discord.Message))
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V269.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.Id.StickerId) Evergreen.V269.Sticker.StickerData
    , discordStickers : Evergreen.V269.OneToOne.OneToOne (Evergreen.V269.Discord.Id Evergreen.V269.Discord.StickerId) (Evergreen.V269.Id.Id Evergreen.V269.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.Id.CustomEmojiId) Evergreen.V269.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V269.OneToOne.OneToOne Evergreen.V269.RichText.DiscordCustomEmojiIdAndName (Evergreen.V269.Id.Id Evergreen.V269.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V269.Postmark.ApiKey
    , serverSecret : Evergreen.V269.SecretId.SecretId Evergreen.V269.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V269.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V269.OneToOne.OneToOne (Evergreen.V269.SecretId.SecretId Evergreen.V269.Id.GoMatchPublicId) ( Evergreen.V269.DmChannel.DmChannelId, Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelMessageId )
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V269.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V269.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V269.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V269.Route.Route
    | SelectedFilesToAttach ( Evergreen.V269.Id.AnyGuildOrDmId, Evergreen.V269.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V269.Id.Id Evergreen.V269.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V269.Id.Id Evergreen.V269.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V269.Id.Id Evergreen.V269.Id.GuildId) (Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelId) Evergreen.V269.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V269.Id.Id Evergreen.V269.Id.GuildId) (Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelId) Evergreen.V269.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V269.Discord.Id Evergreen.V269.Discord.GuildId) (Evergreen.V269.Discord.Id Evergreen.V269.Discord.ChannelId) Evergreen.V269.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V269.Discord.Id Evergreen.V269.Discord.GuildId) (Evergreen.V269.Discord.Id Evergreen.V269.Discord.ChannelId) Evergreen.V269.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V269.Id.Id Evergreen.V269.Id.GuildId) (Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V269.Id.Id Evergreen.V269.Id.GuildId) (Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V269.Id.Id Evergreen.V269.Id.GuildId) (Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V269.Id.Id Evergreen.V269.Id.GuildId) (Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V269.Id.Id Evergreen.V269.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V269.Id.Id Evergreen.V269.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V269.Id.Id Evergreen.V269.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V269.Id.Id Evergreen.V269.Id.GuildId) (Evergreen.V269.SecretId.SecretId Evergreen.V269.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V269.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V269.Id.AnyGuildOrDmId Evergreen.V269.Id.ThreadRouteWithMessage (Evergreen.V269.Coord.Coord Evergreen.V269.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V269.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V269.Id.AnyGuildOrDmId Evergreen.V269.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V269.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V269.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V269.Id.AnyGuildOrDmId, Evergreen.V269.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V269.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V269.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V269.Id.AnyGuildOrDmId, Evergreen.V269.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V269.NonemptyDict.NonemptyDict Int Evergreen.V269.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V269.NonemptyDict.NonemptyDict Int Evergreen.V269.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V269.Id.AnyGuildOrDmId Evergreen.V269.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V269.Id.AnyGuildOrDmId Evergreen.V269.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V269.NonemptySet.NonemptySet (Evergreen.V269.Id.Id Evergreen.V269.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V269.Id.AnyGuildOrDmId, Evergreen.V269.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V269.Id.AnyGuildOrDmId Evergreen.V269.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V269.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V269.AiChat.Msg
    | GoMsg Evergreen.V269.Go.Msg
    | GoSpectatorMsg Evergreen.V269.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V269.Editable.Msg Evergreen.V269.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V269.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V269.Id.Id Evergreen.V269.Id.GuildId) Evergreen.V269.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V269.Id.AnyGuildOrDmId, Evergreen.V269.Id.ThreadRoute ) (Evergreen.V269.Id.Id Evergreen.V269.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V269.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V269.Id.AnyGuildOrDmId, Evergreen.V269.Id.ThreadRoute ) (Evergreen.V269.Id.Id Evergreen.V269.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V269.Id.AnyGuildOrDmId, Evergreen.V269.Id.ThreadRoute ) (Evergreen.V269.Id.Id Evergreen.V269.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V269.Id.AnyGuildOrDmId, Evergreen.V269.Id.ThreadRoute )
        { fileId : Evergreen.V269.Id.Id Evergreen.V269.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V269.Id.AnyGuildOrDmId, Evergreen.V269.Id.ThreadRoute ) (Evergreen.V269.Id.Id Evergreen.V269.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V269.Id.AnyGuildOrDmId, Evergreen.V269.Id.ThreadRoute ) (Evergreen.V269.Id.Id Evergreen.V269.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V269.Id.AnyGuildOrDmId, Evergreen.V269.Id.ThreadRoute )
        { fileId : Evergreen.V269.Id.Id Evergreen.V269.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V269.Id.AnyGuildOrDmId, Evergreen.V269.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V269.Id.AnyGuildOrDmId, Evergreen.V269.Id.ThreadRoute ) (Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelMessageId) (Evergreen.V269.Id.Id Evergreen.V269.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V269.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V269.Id.AnyGuildOrDmId, Evergreen.V269.Id.ThreadRoute ) (Evergreen.V269.Id.Id Evergreen.V269.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V269.Id.AnyGuildOrDmId Evergreen.V269.Id.ThreadRouteWithMessage Evergreen.V269.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V269.ImageViewer.Msg
    | GotRegisterPushSubscription (Result String Evergreen.V269.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V269.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V269.Id.Id Evergreen.V269.Id.GuildId) Evergreen.V269.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId) (Evergreen.V269.Discord.Id Evergreen.V269.Discord.GuildId) Evergreen.V269.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V269.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V269.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId
        , otherUserId : Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V269.Id.AnyGuildOrDmId Evergreen.V269.Id.ThreadRoute Evergreen.V269.MessageInput.Msg
    | MessageInputMsg Evergreen.V269.Id.AnyGuildOrDmId Evergreen.V269.Id.ThreadRoute Evergreen.V269.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V269.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V269.Range.Range, Evergreen.V269.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V269.Range.Range, Evergreen.V269.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V269.Call.FromJs)
    | VoiceChatMsg Evergreen.V269.Call.Msg
    | PressedChannelHeaderTab Evergreen.V269.Route.DmChannelHeaderTab
    | FileDragEnter
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V269.Id.Id Evergreen.V269.Id.GuildId) (Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelId) Evergreen.V269.Id.ThreadRoute
    | InitialLoadRequested_Dm Evergreen.V269.DmChannel.DmChannelId Evergreen.V269.Id.ThreadRoute
    | InitialLoadRequested_Discord Evergreen.V269.Id.DiscordGuildOrDmId Evergreen.V269.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V269.Id.Id Evergreen.V269.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V269.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V269.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V269.Untrusted.Untrusted Evergreen.V269.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V269.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V269.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V269.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V269.Id.Id Evergreen.V269.Id.GuildId) (Evergreen.V269.SecretId.SecretId Evergreen.V269.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V269.PersonName.PersonName Evergreen.V269.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V269.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V269.Slack.OAuthCode Evergreen.V269.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V269.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V269.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V269.Id.Id Evergreen.V269.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V269.SecretId.SecretId Evergreen.V269.Id.GoMatchPublicId)


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V269.Discord.Id Evergreen.V269.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V269.Discord.Id Evergreen.V269.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V269.EmailAddress.EmailAddress (Result Evergreen.V269.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V269.EmailAddress.EmailAddress (Result Evergreen.V269.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V269.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V269.Discord.Id Evergreen.V269.Discord.GuildId) (Evergreen.V269.Discord.Id Evergreen.V269.Discord.ChannelId) Evergreen.V269.Id.ThreadRouteWithMaybeMessage (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId) (Result Evergreen.V269.Discord.HttpError Evergreen.V269.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V269.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V269.Discord.Id Evergreen.V269.Discord.PrivateChannelId) (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId) (Result Evergreen.V269.Discord.HttpError Evergreen.V269.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V269.Discord.Id Evergreen.V269.Discord.GuildId) (Evergreen.V269.Discord.Id Evergreen.V269.Discord.ChannelId) Evergreen.V269.Id.ThreadRouteWithMessage (Evergreen.V269.Discord.Id Evergreen.V269.Discord.MessageId) (Result Evergreen.V269.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V269.Discord.Id Evergreen.V269.Discord.PrivateChannelId) (Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelMessageId) (Evergreen.V269.Discord.Id Evergreen.V269.Discord.MessageId) (Result Evergreen.V269.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V269.Discord.Id Evergreen.V269.Discord.GuildId) (Evergreen.V269.Discord.Id Evergreen.V269.Discord.ChannelId) Evergreen.V269.Id.ThreadRouteWithMessage (Evergreen.V269.Discord.Id Evergreen.V269.Discord.MessageId) (Result Evergreen.V269.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V269.Discord.Id Evergreen.V269.Discord.PrivateChannelId) (Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelMessageId) (Evergreen.V269.Discord.Id Evergreen.V269.Discord.MessageId) (Result Evergreen.V269.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V269.Discord.Id Evergreen.V269.Discord.GuildId) (Evergreen.V269.Discord.Id Evergreen.V269.Discord.ChannelId) Evergreen.V269.Id.ThreadRouteWithMessage (Evergreen.V269.Discord.Id Evergreen.V269.Discord.MessageId) Evergreen.V269.Emoji.EmojiOrCustomEmoji (Result Evergreen.V269.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V269.Discord.Id Evergreen.V269.Discord.PrivateChannelId) (Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelMessageId) (Evergreen.V269.Discord.Id Evergreen.V269.Discord.MessageId) Evergreen.V269.Emoji.EmojiOrCustomEmoji (Result Evergreen.V269.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V269.Discord.Id Evergreen.V269.Discord.GuildId) (Evergreen.V269.Discord.Id Evergreen.V269.Discord.ChannelId) Evergreen.V269.Id.ThreadRouteWithMessage (Evergreen.V269.Discord.Id Evergreen.V269.Discord.MessageId) Evergreen.V269.Emoji.EmojiOrCustomEmoji (Result Evergreen.V269.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V269.Discord.Id Evergreen.V269.Discord.PrivateChannelId) (Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelMessageId) (Evergreen.V269.Discord.Id Evergreen.V269.Discord.MessageId) Evergreen.V269.Emoji.EmojiOrCustomEmoji (Result Evergreen.V269.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V269.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V269.Discord.HttpError (List ( Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId, Maybe Evergreen.V269.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V269.Slack.CurrentUser
            , team : Evergreen.V269.Slack.Team
            , users : List Evergreen.V269.Slack.User
            , channels : List ( Evergreen.V269.Slack.Channel, List Evergreen.V269.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId) (Result Effect.Http.Error Evergreen.V269.Slack.TokenResponse)
    | GotCloudflareSessionCreated Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V269.Local.ChangeId Effect.Time.Posix Evergreen.V269.Call.CallId Evergreen.V269.Cloudflare.Sdp (List String) (Result Effect.Http.Error Evergreen.V269.Cloudflare.RealtimeSessionId)
    | GotCloudflareSession Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V269.Local.ChangeId Effect.Time.Posix Evergreen.V269.Call.CallId Evergreen.V269.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V269.Cloudflare.PushTracksResult)
    | GotCloudflarePullOffer Effect.Time.Posix Effect.Lamdera.ClientId Evergreen.V269.Local.ChangeId Evergreen.V269.Call.ConnectionId Evergreen.V269.Cloudflare.RealtimeSessionId (List Evergreen.V269.Cloudflare.TrackName) (Result Effect.Http.Error Evergreen.V269.Cloudflare.PullTracksResult)
    | GotCloudflareRenegotiateAck Effect.Lamdera.ClientId Evergreen.V269.Local.ChangeId Evergreen.V269.Cloudflare.Sdp (Result Effect.Http.Error ())
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId) Evergreen.V269.Discord.UserAuth (Result Evergreen.V269.Discord.HttpError Evergreen.V269.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId) (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId) (Result Evergreen.V269.Discord.HttpError Evergreen.V269.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId)
        (Result
            Evergreen.V269.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V269.Discord.Id Evergreen.V269.Discord.PrivateChannelId
                , members : List (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId)
                }
            , List
                ( Evergreen.V269.Discord.Id Evergreen.V269.Discord.GuildId
                , { guild : Evergreen.V269.Discord.GatewayGuild
                  , channels : List Evergreen.V269.Discord.Channel
                  , icon : Maybe Evergreen.V269.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId) Bool Evergreen.V269.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V269.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V269.Discord.Id Evergreen.V269.Discord.AttachmentId, Evergreen.V269.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V269.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V269.Discord.Id Evergreen.V269.Discord.AttachmentId, Evergreen.V269.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId) (Evergreen.V269.Discord.Id Evergreen.V269.Discord.GuildId) (Evergreen.V269.Discord.Id Evergreen.V269.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V269.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V269.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId) (Evergreen.V269.Discord.Id Evergreen.V269.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V269.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V269.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId) (Evergreen.V269.Discord.Id Evergreen.V269.Discord.GuildId) (Evergreen.V269.Discord.Id Evergreen.V269.Discord.ChannelId) (Result Evergreen.V269.Discord.HttpError (List Evergreen.V269.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId) (Evergreen.V269.Discord.Id Evergreen.V269.Discord.PrivateChannelId) (Result Evergreen.V269.Discord.HttpError (List Evergreen.V269.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V269.Id.Id Evergreen.V269.Id.GuildId) (Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelId) Evergreen.V269.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V269.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V269.DmChannel.DmChannelId Evergreen.V269.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V269.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V269.Discord.Id Evergreen.V269.Discord.GuildId) (Evergreen.V269.Discord.Id Evergreen.V269.Discord.ChannelId) Evergreen.V269.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V269.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V269.Discord.Id Evergreen.V269.Discord.PrivateChannelId) (Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V269.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId)
        (Evergreen.V269.Discord.Id Evergreen.V269.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V269.Discord.HttpError
            { guild : Evergreen.V269.Discord.GatewayGuild
            , channels : List Evergreen.V269.Discord.Channel
            , icon : Maybe Evergreen.V269.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V269.Discord.Id Evergreen.V269.Discord.GuildId) (Result Evergreen.V269.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V269.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId) (List ( Evergreen.V269.Id.Id Evergreen.V269.Id.StickerId, Result Effect.Http.Error Evergreen.V269.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V269.Id.Id Evergreen.V269.Id.StickerId, Result Effect.Http.Error Evergreen.V269.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId) (List ( Evergreen.V269.Id.Id Evergreen.V269.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V269.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V269.Id.Id Evergreen.V269.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V269.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V269.Discord.HttpError (List Evergreen.V269.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V269.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V269.SecretId.SecretId Evergreen.V269.SecretId.ServerSecret))
    | GotTimeForWebsocketListenClose (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | GotCloudflareUsage Effect.Time.Posix (Result Effect.Http.Error Int)
    | GotCloudflareEgressForAdmin Effect.Lamdera.ClientId (Result Effect.Http.Error Int)
