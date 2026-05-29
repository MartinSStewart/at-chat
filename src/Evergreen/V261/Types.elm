module Evergreen.V261.Types exposing (..)

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
import Evergreen.V261.AiChat
import Evergreen.V261.Call
import Evergreen.V261.ChannelDescription
import Evergreen.V261.ChannelName
import Evergreen.V261.Cloudflare
import Evergreen.V261.Coord
import Evergreen.V261.CssPixels
import Evergreen.V261.CustomEmoji
import Evergreen.V261.Discord
import Evergreen.V261.DiscordAttachmentId
import Evergreen.V261.DiscordUserData
import Evergreen.V261.DmChannel
import Evergreen.V261.Editable
import Evergreen.V261.EmailAddress
import Evergreen.V261.Embed
import Evergreen.V261.Emoji
import Evergreen.V261.FileStatus
import Evergreen.V261.Go
import Evergreen.V261.GuildName
import Evergreen.V261.Id
import Evergreen.V261.ImageEditor
import Evergreen.V261.Local
import Evergreen.V261.LocalState
import Evergreen.V261.Log
import Evergreen.V261.LoginForm
import Evergreen.V261.MembersAndOwner
import Evergreen.V261.Message
import Evergreen.V261.MessageInput
import Evergreen.V261.MessageView
import Evergreen.V261.MyUi
import Evergreen.V261.NonemptyDict
import Evergreen.V261.NonemptySet
import Evergreen.V261.OneToOne
import Evergreen.V261.Pages.Admin
import Evergreen.V261.Pagination
import Evergreen.V261.PersonName
import Evergreen.V261.Ports
import Evergreen.V261.Postmark
import Evergreen.V261.Range
import Evergreen.V261.RichText
import Evergreen.V261.Route
import Evergreen.V261.SecretId
import Evergreen.V261.SessionIdHash
import Evergreen.V261.Slack
import Evergreen.V261.Sticker
import Evergreen.V261.TextEditor
import Evergreen.V261.ToBackendLog
import Evergreen.V261.Touch
import Evergreen.V261.TwoFactorAuthentication
import Evergreen.V261.Ui.Anim
import Evergreen.V261.Untrusted
import Evergreen.V261.User
import Evergreen.V261.UserAgent
import Evergreen.V261.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V261.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V261.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.Id.GuildId) Evergreen.V261.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId) Evergreen.V261.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V261.Discord.Id Evergreen.V261.Discord.PrivateChannelId) Evergreen.V261.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V261.Discord.Id Evergreen.V261.Discord.GuildId) Evergreen.V261.LocalState.DiscordFrontendGuild
    , user : Evergreen.V261.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId) Evergreen.V261.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId) Evergreen.V261.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId) Evergreen.V261.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V261.SessionIdHash.SessionIdHash Evergreen.V261.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V261.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.Id.StickerId) Evergreen.V261.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.Id.CustomEmojiId) Evergreen.V261.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V261.Call.CallId (Evergreen.V261.NonemptySet.NonemptySet ( Evergreen.V261.Id.Id Evergreen.V261.Id.UserId, Effect.Lamdera.ClientId ))
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type PublicGoMatch
    = PublicGoMatch_NotLoaded
    | PublicGoMatch_Loading
    | PublicGoMatch_Loaded Evergreen.V261.Go.PublicGoMatchData Evergreen.V261.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V261.Route.Route
    , windowSize : Evergreen.V261.Coord.Coord Evergreen.V261.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V261.Ports.NotificationPermission
    , pwaStatus : Evergreen.V261.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V261.UserAgent.UserAgent
    , publicGoMatch : PublicGoMatch
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V261.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V261.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V261.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.FileStatus.FileId) Evergreen.V261.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V261.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V261.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.FileStatus.FileId) Evergreen.V261.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V261.Id.Id Evergreen.V261.Id.GuildId) Evergreen.V261.ChannelName.ChannelName Evergreen.V261.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V261.Id.Id Evergreen.V261.Id.GuildId) (Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelId) Evergreen.V261.ChannelName.ChannelName Evergreen.V261.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V261.Id.Id Evergreen.V261.Id.GuildId) (Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelId)
    | Local_DeleteGuild (Evergreen.V261.Id.Id Evergreen.V261.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V261.Id.Id Evergreen.V261.Id.GuildId) (Evergreen.V261.UserSession.ToBeFilledInByBackend (Evergreen.V261.SecretId.SecretId Evergreen.V261.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V261.Id.Id Evergreen.V261.Id.GuildId) (Evergreen.V261.SecretId.SecretId Evergreen.V261.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V261.GuildName.GuildName (Evergreen.V261.UserSession.ToBeFilledInByBackend (Evergreen.V261.Id.Id Evergreen.V261.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V261.Id.AnyGuildOrDmId, Evergreen.V261.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V261.Id.AnyGuildOrDmId Evergreen.V261.Id.ThreadRouteWithMessage Evergreen.V261.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V261.Id.AnyGuildOrDmId Evergreen.V261.Id.ThreadRouteWithMessage Evergreen.V261.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V261.Id.GuildOrDmId Evergreen.V261.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.FileStatus.FileId) Evergreen.V261.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId) (Evergreen.V261.Discord.Id Evergreen.V261.Discord.GuildId) (Evergreen.V261.Discord.Id Evergreen.V261.Discord.ChannelId) Evergreen.V261.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V261.Id.DiscordGuildOrDmId_DmData (Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V261.Id.AnyGuildOrDmId Evergreen.V261.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V261.Id.AnyGuildOrDmId Evergreen.V261.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V261.Id.AnyGuildOrDmId Evergreen.V261.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V261.UserSession.SetViewing
    | Local_SetName Evergreen.V261.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V261.Id.GuildOrDmId (Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelMessageId) (Evergreen.V261.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelMessageId) (Evergreen.V261.Message.Message Evergreen.V261.Id.ChannelMessageId (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V261.Id.GuildOrDmId (Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelMessageId) (Evergreen.V261.Id.Id Evergreen.V261.Id.ThreadMessageId) (Evergreen.V261.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.Id.ThreadMessageId) (Evergreen.V261.Message.Message Evergreen.V261.Id.ThreadMessageId (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V261.Id.DiscordGuildOrDmId (Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelMessageId) (Evergreen.V261.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelMessageId) (Evergreen.V261.Message.Message Evergreen.V261.Id.ChannelMessageId (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V261.Id.DiscordGuildOrDmId (Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelMessageId) (Evergreen.V261.Id.Id Evergreen.V261.Id.ThreadMessageId) (Evergreen.V261.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.Id.ThreadMessageId) (Evergreen.V261.Message.Message Evergreen.V261.Id.ThreadMessageId (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V261.Id.Id Evergreen.V261.Id.GuildId) Evergreen.V261.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId) (Evergreen.V261.Discord.Id Evergreen.V261.Discord.GuildId) Evergreen.V261.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V261.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V261.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V261.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V261.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V261.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V261.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V261.NonemptySet.NonemptySet (Evergreen.V261.Id.Id Evergreen.V261.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V261.Call.LocalChange
    | Local_Go
        { otherUserId : Evergreen.V261.Id.Id Evergreen.V261.Id.UserId
        }
        Evergreen.V261.Go.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId) Effect.Time.Posix Evergreen.V261.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V261.RichText.RichText (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId))) Evergreen.V261.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.FileStatus.FileId) Evergreen.V261.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.Id.StickerId) Evergreen.V261.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V261.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V261.RichText.RichText (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId))) Evergreen.V261.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.FileStatus.FileId) Evergreen.V261.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.Id.StickerId) Evergreen.V261.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V261.Id.Id Evergreen.V261.Id.GuildId) Evergreen.V261.ChannelName.ChannelName Evergreen.V261.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V261.Id.Id Evergreen.V261.Id.GuildId) (Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelId) Evergreen.V261.ChannelName.ChannelName Evergreen.V261.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V261.Id.Id Evergreen.V261.Id.GuildId) (Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelId)
    | Server_DeleteGuild (Evergreen.V261.Id.Id Evergreen.V261.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId) (Evergreen.V261.Id.Id Evergreen.V261.Id.GuildId) (Evergreen.V261.SecretId.SecretId Evergreen.V261.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V261.Id.Id Evergreen.V261.Id.GuildId) (Evergreen.V261.SecretId.SecretId Evergreen.V261.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId) (Evergreen.V261.Id.Id Evergreen.V261.Id.GuildId) Evergreen.V261.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V261.LocalState.JoinGuildError
            { guildId : Evergreen.V261.Id.Id Evergreen.V261.Id.GuildId
            , guild : Evergreen.V261.LocalState.FrontendGuild
            , owner : Evergreen.V261.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId) Evergreen.V261.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId) Evergreen.V261.Id.GuildOrDmId Evergreen.V261.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId) (Evergreen.V261.Discord.Id Evergreen.V261.Discord.GuildId) (Evergreen.V261.Discord.Id Evergreen.V261.Discord.ChannelId) Evergreen.V261.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId) (Evergreen.V261.Discord.Id Evergreen.V261.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId) Evergreen.V261.Id.GuildOrDmId Evergreen.V261.Id.ThreadRouteWithMessage Evergreen.V261.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId) Evergreen.V261.Id.GuildOrDmId Evergreen.V261.Id.ThreadRouteWithMessage Evergreen.V261.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId) (Evergreen.V261.Discord.Id Evergreen.V261.Discord.GuildId) (Evergreen.V261.Discord.Id Evergreen.V261.Discord.ChannelId) Evergreen.V261.Id.ThreadRouteWithMessage Evergreen.V261.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId) (Evergreen.V261.Discord.Id Evergreen.V261.Discord.PrivateChannelId) (Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelMessageId) Evergreen.V261.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId) (Evergreen.V261.Discord.Id Evergreen.V261.Discord.GuildId) (Evergreen.V261.Discord.Id Evergreen.V261.Discord.ChannelId) Evergreen.V261.Id.ThreadRouteWithMessage Evergreen.V261.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId) (Evergreen.V261.Discord.Id Evergreen.V261.Discord.PrivateChannelId) (Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelMessageId) Evergreen.V261.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId) Evergreen.V261.Id.GuildOrDmId Evergreen.V261.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V261.RichText.RichText (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId))) (SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.FileStatus.FileId) Evergreen.V261.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId) (Evergreen.V261.Discord.Id Evergreen.V261.Discord.GuildId) (Evergreen.V261.Discord.Id Evergreen.V261.Discord.ChannelId) Evergreen.V261.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V261.RichText.RichText (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V261.Id.DiscordGuildOrDmId_DmData (Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V261.RichText.RichText (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId) Evergreen.V261.Id.AnyGuildOrDmId Evergreen.V261.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V261.Id.AnyGuildOrDmId Evergreen.V261.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V261.Discord.Id Evergreen.V261.Discord.GuildId) (Evergreen.V261.Discord.Id Evergreen.V261.Discord.ChannelId) Evergreen.V261.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V261.Discord.Id Evergreen.V261.Discord.PrivateChannelId) (Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId) Evergreen.V261.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId) Evergreen.V261.FileStatus.FileHash
    | Server_SetGuildIcon (Evergreen.V261.Id.Id Evergreen.V261.Id.GuildId) Evergreen.V261.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V261.Id.Id Evergreen.V261.Id.GuildId) Evergreen.V261.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V261.Discord.Id Evergreen.V261.Discord.GuildId) Evergreen.V261.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V261.SessionIdHash.SessionIdHash Evergreen.V261.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V261.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V261.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V261.Id.AnyGuildOrDmId, Evergreen.V261.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V261.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId) Evergreen.V261.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V261.Discord.Id Evergreen.V261.Discord.GuildId) (Evergreen.V261.Discord.Id Evergreen.V261.Discord.ChannelId) Evergreen.V261.ChannelName.ChannelName (Evergreen.V261.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V261.Discord.Id Evergreen.V261.Discord.PrivateChannelId)
        (Evergreen.V261.NonemptyDict.NonemptyDict
            (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V261.Discord.Id Evergreen.V261.Discord.GuildId) Evergreen.V261.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V261.Discord.Id Evergreen.V261.Discord.PrivateChannelId) Evergreen.V261.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId) Evergreen.V261.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId) (Maybe (Evergreen.V261.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V261.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V261.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V261.Id.Id Evergreen.V261.Id.GuildId) (Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelId) Evergreen.V261.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V261.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId) Evergreen.V261.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V261.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V261.Discord.Id Evergreen.V261.Discord.GuildId) (Evergreen.V261.Discord.Id Evergreen.V261.Discord.ChannelId) Evergreen.V261.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V261.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V261.Discord.Id Evergreen.V261.Discord.PrivateChannelId) (Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V261.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V261.Discord.Id Evergreen.V261.Discord.GuildId) Evergreen.V261.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V261.Discord.Id Evergreen.V261.Discord.GuildId) (Evergreen.V261.Discord.Id Evergreen.V261.Discord.ChannelId) (Evergreen.V261.Discord.OptionalData String) (Evergreen.V261.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V261.Discord.Id Evergreen.V261.Discord.GuildId)
        (Evergreen.V261.MembersAndOwner.MembersAndOwner
            (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V261.Discord.Id Evergreen.V261.Discord.GuildId) (Evergreen.V261.Discord.Id Evergreen.V261.Discord.ChannelId) (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId) Evergreen.V261.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.Id.StickerId) Evergreen.V261.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.Id.CustomEmojiId) Evergreen.V261.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V261.Call.ServerChange
    | Server_Go
        (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId)
        { otherUserId : Evergreen.V261.Id.Id Evergreen.V261.Id.UserId
        }
        Evergreen.V261.Go.LocalChange


type LocalMsg
    = LocalChange (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V261.Id.Id Evergreen.V261.Id.GuildId) (Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelId) Evergreen.V261.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V261.Discord.Id Evergreen.V261.Discord.GuildId) (Evergreen.V261.Discord.Id Evergreen.V261.Discord.ChannelId) Evergreen.V261.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.FileStatus.FileId) Evergreen.V261.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V261.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V261.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V261.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V261.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V261.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V261.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V261.Coord.Coord Evergreen.V261.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V261.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V261.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V261.Id.AnyGuildOrDmId Evergreen.V261.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V261.Id.AnyGuildOrDmId Evergreen.V261.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V261.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V261.Coord.Coord Evergreen.V261.CssPixels.CssPixels) (Maybe Evergreen.V261.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V261.Id.AnyGuildOrDmId, Evergreen.V261.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelMessageId) (Evergreen.V261.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.Id.ThreadMessageId) (Evergreen.V261.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V261.Editable.Model
    , showLinkDiscordSetup : Bool
    , domainWhitelistInput : String
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V261.Local.Local LocalMsg Evergreen.V261.LocalState.LocalState
    , admin : Evergreen.V261.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V261.Id.AnyGuildOrDmId, Evergreen.V261.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V261.Id.Id Evergreen.V261.Id.GuildId, Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V261.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V261.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V261.Id.AnyGuildOrDmId, Evergreen.V261.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V261.Id.AnyGuildOrDmId, Evergreen.V261.Id.ThreadRoute ) (Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : Evergreen.V261.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V261.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V261.Id.AnyGuildOrDmId, Evergreen.V261.Id.ThreadRoute ) (Evergreen.V261.NonemptyDict.NonemptyDict (Evergreen.V261.Id.Id Evergreen.V261.FileStatus.FileId) Evergreen.V261.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V261.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V261.TextEditor.Model
    , profilePictureEditor : Evergreen.V261.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V261.Id.Id Evergreen.V261.Id.GuildId, Evergreen.V261.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V261.Emoji.Model
    , voiceChat : Evergreen.V261.Call.Model
    , currentDmGoMatch : SeqDict.SeqDict ( Evergreen.V261.Id.Id Evergreen.V261.Id.UserId, Maybe (Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelMessageId) ) Evergreen.V261.Go.Model
    , fileDragOverCount : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V261.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V261.SecretId.SecretId Evergreen.V261.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V261.Range.Range
                , direction : Evergreen.V261.Range.SelectionDirection
                }
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V261.NonemptyDict.NonemptyDict Int Evergreen.V261.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V261.NonemptyDict.NonemptyDict Int Evergreen.V261.Touch.Touch
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
    | AdminToFrontend Evergreen.V261.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V261.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V261.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V261.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V261.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V261.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V261.Go.PublicGoMatchData)


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V261.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V261.Coord.Coord Evergreen.V261.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V261.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V261.MyUi.LastCopy
    , notificationPermission : Evergreen.V261.Ports.NotificationPermission
    , pwaStatus : Evergreen.V261.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V261.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V261.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V261.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V261.Id.Id Evergreen.V261.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V261.Id.Id Evergreen.V261.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V261.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V261.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V261.Coord.Coord Evergreen.V261.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V261.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V261.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V261.Id.Id Evergreen.V261.Id.GuildId, Evergreen.V261.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V261.DmChannel.DmChannelId, Evergreen.V261.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V261.Discord.Id Evergreen.V261.Discord.GuildId, Evergreen.V261.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V261.Discord.Id Evergreen.V261.Discord.PrivateChannelId, Evergreen.V261.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V261.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V261.NonemptyDict.NonemptyDict (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId) Evergreen.V261.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V261.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V261.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V261.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V261.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId) Evergreen.V261.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId) Evergreen.V261.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V261.Id.Id Evergreen.V261.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.Id.GuildId) Evergreen.V261.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.Id.GuildId) Evergreen.V261.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V261.Discord.Id Evergreen.V261.Discord.GuildId) Evergreen.V261.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V261.DmChannel.DmChannelId Evergreen.V261.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V261.Discord.Id Evergreen.V261.Discord.PrivateChannelId) Evergreen.V261.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V261.OneToOne.OneToOne (Evergreen.V261.Slack.Id Evergreen.V261.Slack.ChannelId) Evergreen.V261.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V261.OneToOne.OneToOne String (Evergreen.V261.Id.Id Evergreen.V261.Id.GuildId)
    , slackUsers : Evergreen.V261.OneToOne.OneToOne (Evergreen.V261.Slack.Id Evergreen.V261.Slack.UserId) (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId)
    , slackServers : Evergreen.V261.OneToOne.OneToOne (Evergreen.V261.Slack.Id Evergreen.V261.Slack.TeamId) (Evergreen.V261.Id.Id Evergreen.V261.Id.GuildId)
    , slackToken : Maybe Evergreen.V261.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V261.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V261.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V261.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V261.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V261.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V261.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V261.Cloudflare.AnalyticsApiToken
    , textEditor : Evergreen.V261.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId) Evergreen.V261.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId, Evergreen.V261.Discord.Id Evergreen.V261.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V261.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V261.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V261.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V261.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId) (Evergreen.V261.LocalState.LoadingDiscordChannel (List Evergreen.V261.Discord.Message))
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V261.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.Id.StickerId) Evergreen.V261.Sticker.StickerData
    , discordStickers : Evergreen.V261.OneToOne.OneToOne (Evergreen.V261.Discord.Id Evergreen.V261.Discord.StickerId) (Evergreen.V261.Id.Id Evergreen.V261.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.Id.CustomEmojiId) Evergreen.V261.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V261.OneToOne.OneToOne Evergreen.V261.RichText.DiscordCustomEmojiIdAndName (Evergreen.V261.Id.Id Evergreen.V261.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V261.Postmark.ApiKey
    , serverSecret : Evergreen.V261.SecretId.SecretId Evergreen.V261.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V261.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V261.OneToOne.OneToOne (Evergreen.V261.SecretId.SecretId Evergreen.V261.Id.GoMatchPublicId) ( Evergreen.V261.DmChannel.DmChannelId, Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelMessageId )
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V261.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V261.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V261.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V261.Route.Route
    | SelectedFilesToAttach ( Evergreen.V261.Id.AnyGuildOrDmId, Evergreen.V261.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V261.Id.Id Evergreen.V261.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V261.Id.Id Evergreen.V261.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V261.Id.Id Evergreen.V261.Id.GuildId) (Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelId) Evergreen.V261.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V261.Id.Id Evergreen.V261.Id.GuildId) (Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelId) Evergreen.V261.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V261.Discord.Id Evergreen.V261.Discord.GuildId) (Evergreen.V261.Discord.Id Evergreen.V261.Discord.ChannelId) Evergreen.V261.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V261.Discord.Id Evergreen.V261.Discord.GuildId) (Evergreen.V261.Discord.Id Evergreen.V261.Discord.ChannelId) Evergreen.V261.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V261.Id.Id Evergreen.V261.Id.GuildId) (Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V261.Id.Id Evergreen.V261.Id.GuildId) (Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V261.Id.Id Evergreen.V261.Id.GuildId) (Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V261.Id.Id Evergreen.V261.Id.GuildId) (Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V261.Id.Id Evergreen.V261.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V261.Id.Id Evergreen.V261.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V261.Id.Id Evergreen.V261.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V261.Id.Id Evergreen.V261.Id.GuildId) (Evergreen.V261.SecretId.SecretId Evergreen.V261.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V261.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V261.Id.AnyGuildOrDmId Evergreen.V261.Id.ThreadRouteWithMessage (Evergreen.V261.Coord.Coord Evergreen.V261.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V261.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V261.Id.AnyGuildOrDmId Evergreen.V261.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V261.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V261.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V261.Id.AnyGuildOrDmId, Evergreen.V261.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V261.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V261.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V261.Id.AnyGuildOrDmId, Evergreen.V261.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V261.NonemptyDict.NonemptyDict Int Evergreen.V261.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V261.NonemptyDict.NonemptyDict Int Evergreen.V261.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V261.Id.AnyGuildOrDmId Evergreen.V261.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V261.Id.AnyGuildOrDmId Evergreen.V261.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V261.NonemptySet.NonemptySet (Evergreen.V261.Id.Id Evergreen.V261.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V261.Id.AnyGuildOrDmId, Evergreen.V261.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V261.Id.AnyGuildOrDmId Evergreen.V261.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V261.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V261.AiChat.Msg
    | GoMsg Evergreen.V261.Go.Msg
    | GoSpectatorMsg Evergreen.V261.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V261.Editable.Msg Evergreen.V261.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V261.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V261.Id.Id Evergreen.V261.Id.GuildId) Evergreen.V261.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V261.Id.AnyGuildOrDmId, Evergreen.V261.Id.ThreadRoute ) (Evergreen.V261.Id.Id Evergreen.V261.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V261.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V261.Id.AnyGuildOrDmId, Evergreen.V261.Id.ThreadRoute ) (Evergreen.V261.Id.Id Evergreen.V261.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V261.Id.AnyGuildOrDmId, Evergreen.V261.Id.ThreadRoute ) (Evergreen.V261.Id.Id Evergreen.V261.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V261.Id.AnyGuildOrDmId, Evergreen.V261.Id.ThreadRoute )
        { fileId : Evergreen.V261.Id.Id Evergreen.V261.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V261.Id.AnyGuildOrDmId, Evergreen.V261.Id.ThreadRoute ) (Evergreen.V261.Id.Id Evergreen.V261.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V261.Id.AnyGuildOrDmId, Evergreen.V261.Id.ThreadRoute ) (Evergreen.V261.Id.Id Evergreen.V261.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V261.Id.AnyGuildOrDmId, Evergreen.V261.Id.ThreadRoute )
        { fileId : Evergreen.V261.Id.Id Evergreen.V261.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V261.Id.AnyGuildOrDmId, Evergreen.V261.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V261.Id.AnyGuildOrDmId, Evergreen.V261.Id.ThreadRoute ) (Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelMessageId) (Evergreen.V261.Id.Id Evergreen.V261.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V261.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V261.Id.AnyGuildOrDmId, Evergreen.V261.Id.ThreadRoute ) (Evergreen.V261.Id.Id Evergreen.V261.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V261.Id.AnyGuildOrDmId Evergreen.V261.Id.ThreadRouteWithMessage Evergreen.V261.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V261.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V261.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V261.Id.Id Evergreen.V261.Id.GuildId) Evergreen.V261.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId) (Evergreen.V261.Discord.Id Evergreen.V261.Discord.GuildId) Evergreen.V261.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V261.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V261.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId
        , otherUserId : Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V261.Id.AnyGuildOrDmId Evergreen.V261.Id.ThreadRoute Evergreen.V261.MessageInput.Msg
    | MessageInputMsg Evergreen.V261.Id.AnyGuildOrDmId Evergreen.V261.Id.ThreadRoute Evergreen.V261.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V261.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V261.Range.Range, Evergreen.V261.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V261.Range.Range, Evergreen.V261.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V261.Call.FromJs)
    | VoiceChatMsg Evergreen.V261.Call.Msg
    | PressedChannelHeaderTab Evergreen.V261.Route.DmChannelHeaderTab
    | FileDragEnter
    | FileDragLeave
    | FileDropped (List Effect.File.File)


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V261.Id.Id Evergreen.V261.Id.GuildId) (Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelId) Evergreen.V261.Id.ThreadRoute
    | InitialLoadRequested_Dm Evergreen.V261.DmChannel.DmChannelId Evergreen.V261.Id.ThreadRoute
    | InitialLoadRequested_Discord Evergreen.V261.Id.DiscordGuildOrDmId Evergreen.V261.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V261.Id.Id Evergreen.V261.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V261.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V261.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V261.Untrusted.Untrusted Evergreen.V261.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V261.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V261.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V261.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V261.Id.Id Evergreen.V261.Id.GuildId) (Evergreen.V261.SecretId.SecretId Evergreen.V261.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V261.PersonName.PersonName Evergreen.V261.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V261.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V261.Slack.OAuthCode Evergreen.V261.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V261.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V261.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V261.Id.Id Evergreen.V261.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V261.SecretId.SecretId Evergreen.V261.Id.GoMatchPublicId)


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V261.Discord.Id Evergreen.V261.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V261.Discord.Id Evergreen.V261.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V261.EmailAddress.EmailAddress (Result Evergreen.V261.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V261.EmailAddress.EmailAddress (Result Evergreen.V261.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V261.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V261.Discord.Id Evergreen.V261.Discord.GuildId) (Evergreen.V261.Discord.Id Evergreen.V261.Discord.ChannelId) Evergreen.V261.Id.ThreadRouteWithMaybeMessage (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId) (Result Evergreen.V261.Discord.HttpError Evergreen.V261.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V261.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V261.Discord.Id Evergreen.V261.Discord.PrivateChannelId) (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId) (Result Evergreen.V261.Discord.HttpError Evergreen.V261.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V261.Discord.Id Evergreen.V261.Discord.GuildId) (Evergreen.V261.Discord.Id Evergreen.V261.Discord.ChannelId) Evergreen.V261.Id.ThreadRouteWithMessage (Evergreen.V261.Discord.Id Evergreen.V261.Discord.MessageId) (Result Evergreen.V261.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V261.Discord.Id Evergreen.V261.Discord.PrivateChannelId) (Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelMessageId) (Evergreen.V261.Discord.Id Evergreen.V261.Discord.MessageId) (Result Evergreen.V261.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V261.Discord.Id Evergreen.V261.Discord.GuildId) (Evergreen.V261.Discord.Id Evergreen.V261.Discord.ChannelId) Evergreen.V261.Id.ThreadRouteWithMessage (Evergreen.V261.Discord.Id Evergreen.V261.Discord.MessageId) (Result Evergreen.V261.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V261.Discord.Id Evergreen.V261.Discord.PrivateChannelId) (Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelMessageId) (Evergreen.V261.Discord.Id Evergreen.V261.Discord.MessageId) (Result Evergreen.V261.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V261.Discord.Id Evergreen.V261.Discord.GuildId) (Evergreen.V261.Discord.Id Evergreen.V261.Discord.ChannelId) Evergreen.V261.Id.ThreadRouteWithMessage (Evergreen.V261.Discord.Id Evergreen.V261.Discord.MessageId) Evergreen.V261.Emoji.EmojiOrCustomEmoji (Result Evergreen.V261.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V261.Discord.Id Evergreen.V261.Discord.PrivateChannelId) (Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelMessageId) (Evergreen.V261.Discord.Id Evergreen.V261.Discord.MessageId) Evergreen.V261.Emoji.EmojiOrCustomEmoji (Result Evergreen.V261.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V261.Discord.Id Evergreen.V261.Discord.GuildId) (Evergreen.V261.Discord.Id Evergreen.V261.Discord.ChannelId) Evergreen.V261.Id.ThreadRouteWithMessage (Evergreen.V261.Discord.Id Evergreen.V261.Discord.MessageId) Evergreen.V261.Emoji.EmojiOrCustomEmoji (Result Evergreen.V261.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V261.Discord.Id Evergreen.V261.Discord.PrivateChannelId) (Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelMessageId) (Evergreen.V261.Discord.Id Evergreen.V261.Discord.MessageId) Evergreen.V261.Emoji.EmojiOrCustomEmoji (Result Evergreen.V261.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V261.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V261.Discord.HttpError (List ( Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId, Maybe Evergreen.V261.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V261.Slack.CurrentUser
            , team : Evergreen.V261.Slack.Team
            , users : List Evergreen.V261.Slack.User
            , channels : List ( Evergreen.V261.Slack.Channel, List Evergreen.V261.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId) (Result Effect.Http.Error Evergreen.V261.Slack.TokenResponse)
    | GotCloudflareSessionCreated Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V261.Local.ChangeId Effect.Time.Posix Evergreen.V261.Call.CallId Evergreen.V261.Cloudflare.Sdp (List String) (Result Effect.Http.Error Evergreen.V261.Cloudflare.RealtimeSessionId)
    | GotCloudflareSession Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V261.Local.ChangeId Effect.Time.Posix Evergreen.V261.Call.CallId Evergreen.V261.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V261.Cloudflare.PushTracksResult)
    | GotCloudflarePullOffer Effect.Time.Posix Effect.Lamdera.ClientId Evergreen.V261.Local.ChangeId Evergreen.V261.Call.ConnectionId Evergreen.V261.Cloudflare.RealtimeSessionId (List Evergreen.V261.Cloudflare.TrackName) (Result Effect.Http.Error Evergreen.V261.Cloudflare.PullTracksResult)
    | GotCloudflareRenegotiateAck Effect.Lamdera.ClientId Evergreen.V261.Local.ChangeId Evergreen.V261.Cloudflare.Sdp (Result Effect.Http.Error ())
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId) Evergreen.V261.Discord.UserAuth (Result Evergreen.V261.Discord.HttpError Evergreen.V261.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId) (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId) (Result Evergreen.V261.Discord.HttpError Evergreen.V261.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId)
        (Result
            Evergreen.V261.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V261.Discord.Id Evergreen.V261.Discord.PrivateChannelId
                , members : List (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId)
                }
            , List
                ( Evergreen.V261.Discord.Id Evergreen.V261.Discord.GuildId
                , { guild : Evergreen.V261.Discord.GatewayGuild
                  , channels : List Evergreen.V261.Discord.Channel
                  , icon : Maybe Evergreen.V261.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId) Bool Evergreen.V261.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V261.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V261.Discord.Id Evergreen.V261.Discord.AttachmentId, Evergreen.V261.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V261.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V261.Discord.Id Evergreen.V261.Discord.AttachmentId, Evergreen.V261.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId) (Evergreen.V261.Discord.Id Evergreen.V261.Discord.GuildId) (Evergreen.V261.Discord.Id Evergreen.V261.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V261.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V261.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId) (Evergreen.V261.Discord.Id Evergreen.V261.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V261.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V261.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId) (Evergreen.V261.Discord.Id Evergreen.V261.Discord.GuildId) (Evergreen.V261.Discord.Id Evergreen.V261.Discord.ChannelId) (Result Evergreen.V261.Discord.HttpError (List Evergreen.V261.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId) (Evergreen.V261.Discord.Id Evergreen.V261.Discord.PrivateChannelId) (Result Evergreen.V261.Discord.HttpError (List Evergreen.V261.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V261.Id.Id Evergreen.V261.Id.GuildId) (Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelId) Evergreen.V261.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V261.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V261.DmChannel.DmChannelId Evergreen.V261.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V261.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V261.Discord.Id Evergreen.V261.Discord.GuildId) (Evergreen.V261.Discord.Id Evergreen.V261.Discord.ChannelId) Evergreen.V261.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V261.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V261.Discord.Id Evergreen.V261.Discord.PrivateChannelId) (Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V261.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId)
        (Evergreen.V261.Discord.Id Evergreen.V261.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V261.Discord.HttpError
            { guild : Evergreen.V261.Discord.GatewayGuild
            , channels : List Evergreen.V261.Discord.Channel
            , icon : Maybe Evergreen.V261.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V261.Discord.Id Evergreen.V261.Discord.GuildId) (Result Evergreen.V261.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V261.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId) (List ( Evergreen.V261.Id.Id Evergreen.V261.Id.StickerId, Result Effect.Http.Error Evergreen.V261.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V261.Id.Id Evergreen.V261.Id.StickerId, Result Effect.Http.Error Evergreen.V261.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId) (List ( Evergreen.V261.Id.Id Evergreen.V261.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V261.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V261.Id.Id Evergreen.V261.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V261.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V261.Discord.HttpError (List Evergreen.V261.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V261.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V261.SecretId.SecretId Evergreen.V261.SecretId.ServerSecret))
    | GotTimeForWebsocketListenClose (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | GotCloudflareUsage Effect.Time.Posix (Result Effect.Http.Error Int)
    | GotCloudflareEgressForAdmin Effect.Lamdera.ClientId (Result Effect.Http.Error Int)
