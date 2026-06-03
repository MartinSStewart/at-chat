module Evergreen.V270.Types exposing (..)

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
import Evergreen.V270.AiChat
import Evergreen.V270.Call
import Evergreen.V270.ChannelDescription
import Evergreen.V270.ChannelName
import Evergreen.V270.Cloudflare
import Evergreen.V270.Coord
import Evergreen.V270.CssPixels
import Evergreen.V270.CustomEmoji
import Evergreen.V270.Discord
import Evergreen.V270.DiscordAttachmentId
import Evergreen.V270.DiscordUserData
import Evergreen.V270.DmChannel
import Evergreen.V270.Editable
import Evergreen.V270.EmailAddress
import Evergreen.V270.Embed
import Evergreen.V270.Emoji
import Evergreen.V270.FileStatus
import Evergreen.V270.Go
import Evergreen.V270.GuildName
import Evergreen.V270.Id
import Evergreen.V270.ImageEditor
import Evergreen.V270.ImageViewer
import Evergreen.V270.Local
import Evergreen.V270.LocalState
import Evergreen.V270.Log
import Evergreen.V270.LoginForm
import Evergreen.V270.MembersAndOwner
import Evergreen.V270.Message
import Evergreen.V270.MessageInput
import Evergreen.V270.MessageView
import Evergreen.V270.MyUi
import Evergreen.V270.NonemptyDict
import Evergreen.V270.NonemptySet
import Evergreen.V270.OneToOne
import Evergreen.V270.Pages.Admin
import Evergreen.V270.Pagination
import Evergreen.V270.PersonName
import Evergreen.V270.Ports
import Evergreen.V270.Postmark
import Evergreen.V270.Range
import Evergreen.V270.RichText
import Evergreen.V270.Route
import Evergreen.V270.SecretId
import Evergreen.V270.SessionIdHash
import Evergreen.V270.Slack
import Evergreen.V270.Sticker
import Evergreen.V270.TextEditor
import Evergreen.V270.ToBackendLog
import Evergreen.V270.Touch
import Evergreen.V270.TwoFactorAuthentication
import Evergreen.V270.Ui.Anim
import Evergreen.V270.Untrusted
import Evergreen.V270.User
import Evergreen.V270.UserAgent
import Evergreen.V270.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V270.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V270.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.Id.GuildId) Evergreen.V270.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId) Evergreen.V270.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V270.Discord.Id Evergreen.V270.Discord.PrivateChannelId) Evergreen.V270.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V270.Discord.Id Evergreen.V270.Discord.GuildId) Evergreen.V270.LocalState.DiscordFrontendGuild
    , user : Evergreen.V270.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId) Evergreen.V270.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId) Evergreen.V270.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId) Evergreen.V270.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V270.SessionIdHash.SessionIdHash Evergreen.V270.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V270.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.Id.StickerId) Evergreen.V270.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.Id.CustomEmojiId) Evergreen.V270.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V270.Call.CallId (Evergreen.V270.NonemptySet.NonemptySet ( Evergreen.V270.Id.Id Evergreen.V270.Id.UserId, Effect.Lamdera.ClientId ))
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type PublicGoMatch
    = PublicGoMatch_NotLoaded
    | PublicGoMatch_Loading
    | PublicGoMatch_Loaded Evergreen.V270.Go.PublicGoMatchData Evergreen.V270.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V270.Route.Route
    , windowSize : Evergreen.V270.Coord.Coord Evergreen.V270.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V270.Ports.NotificationPermission
    , pwaStatus : Evergreen.V270.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V270.UserAgent.UserAgent
    , publicGoMatch : PublicGoMatch
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V270.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V270.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V270.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.FileStatus.FileId) Evergreen.V270.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V270.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V270.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.FileStatus.FileId) Evergreen.V270.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V270.Id.Id Evergreen.V270.Id.GuildId) Evergreen.V270.ChannelName.ChannelName Evergreen.V270.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V270.Id.Id Evergreen.V270.Id.GuildId) (Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelId) Evergreen.V270.ChannelName.ChannelName Evergreen.V270.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V270.Id.Id Evergreen.V270.Id.GuildId) (Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelId)
    | Local_DeleteGuild (Evergreen.V270.Id.Id Evergreen.V270.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V270.Id.Id Evergreen.V270.Id.GuildId) (Evergreen.V270.UserSession.ToBeFilledInByBackend (Evergreen.V270.SecretId.SecretId Evergreen.V270.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V270.Id.Id Evergreen.V270.Id.GuildId) (Evergreen.V270.SecretId.SecretId Evergreen.V270.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V270.GuildName.GuildName (Evergreen.V270.UserSession.ToBeFilledInByBackend (Evergreen.V270.Id.Id Evergreen.V270.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V270.Id.AnyGuildOrDmId, Evergreen.V270.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V270.Id.AnyGuildOrDmId Evergreen.V270.Id.ThreadRouteWithMessage Evergreen.V270.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V270.Id.AnyGuildOrDmId Evergreen.V270.Id.ThreadRouteWithMessage Evergreen.V270.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V270.Id.GuildOrDmId Evergreen.V270.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.FileStatus.FileId) Evergreen.V270.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId) (Evergreen.V270.Discord.Id Evergreen.V270.Discord.GuildId) (Evergreen.V270.Discord.Id Evergreen.V270.Discord.ChannelId) Evergreen.V270.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V270.Id.DiscordGuildOrDmId_DmData (Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V270.Id.AnyGuildOrDmId Evergreen.V270.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V270.Id.AnyGuildOrDmId Evergreen.V270.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V270.Id.AnyGuildOrDmId Evergreen.V270.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V270.UserSession.SetViewing
    | Local_SetName Evergreen.V270.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V270.Id.GuildOrDmId (Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelMessageId) (Evergreen.V270.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelMessageId) (Evergreen.V270.Message.Message Evergreen.V270.Id.ChannelMessageId (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V270.Id.GuildOrDmId (Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelMessageId) (Evergreen.V270.Id.Id Evergreen.V270.Id.ThreadMessageId) (Evergreen.V270.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.Id.ThreadMessageId) (Evergreen.V270.Message.Message Evergreen.V270.Id.ThreadMessageId (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V270.Id.DiscordGuildOrDmId (Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelMessageId) (Evergreen.V270.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelMessageId) (Evergreen.V270.Message.Message Evergreen.V270.Id.ChannelMessageId (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V270.Id.DiscordGuildOrDmId (Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelMessageId) (Evergreen.V270.Id.Id Evergreen.V270.Id.ThreadMessageId) (Evergreen.V270.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.Id.ThreadMessageId) (Evergreen.V270.Message.Message Evergreen.V270.Id.ThreadMessageId (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V270.Id.Id Evergreen.V270.Id.GuildId) Evergreen.V270.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId) (Evergreen.V270.Discord.Id Evergreen.V270.Discord.GuildId) Evergreen.V270.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V270.UserSession.NotificationMode
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V270.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V270.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V270.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V270.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V270.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V270.NonemptySet.NonemptySet (Evergreen.V270.Id.Id Evergreen.V270.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V270.Call.LocalChange
    | Local_Go
        { otherUserId : Evergreen.V270.Id.Id Evergreen.V270.Id.UserId
        }
        Evergreen.V270.Go.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId) Effect.Time.Posix Evergreen.V270.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V270.RichText.RichText (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId))) Evergreen.V270.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.FileStatus.FileId) Evergreen.V270.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.Id.StickerId) Evergreen.V270.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V270.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V270.RichText.RichText (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId))) Evergreen.V270.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.FileStatus.FileId) Evergreen.V270.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.Id.StickerId) Evergreen.V270.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V270.Id.Id Evergreen.V270.Id.GuildId) Evergreen.V270.ChannelName.ChannelName Evergreen.V270.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V270.Id.Id Evergreen.V270.Id.GuildId) (Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelId) Evergreen.V270.ChannelName.ChannelName Evergreen.V270.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V270.Id.Id Evergreen.V270.Id.GuildId) (Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelId)
    | Server_DeleteGuild (Evergreen.V270.Id.Id Evergreen.V270.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId) (Evergreen.V270.Id.Id Evergreen.V270.Id.GuildId) (Evergreen.V270.SecretId.SecretId Evergreen.V270.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V270.Id.Id Evergreen.V270.Id.GuildId) (Evergreen.V270.SecretId.SecretId Evergreen.V270.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId) (Evergreen.V270.Id.Id Evergreen.V270.Id.GuildId) Evergreen.V270.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V270.LocalState.JoinGuildError
            { guildId : Evergreen.V270.Id.Id Evergreen.V270.Id.GuildId
            , guild : Evergreen.V270.LocalState.FrontendGuild
            , owner : Evergreen.V270.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId) Evergreen.V270.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId) Evergreen.V270.Id.GuildOrDmId Evergreen.V270.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId) (Evergreen.V270.Discord.Id Evergreen.V270.Discord.GuildId) (Evergreen.V270.Discord.Id Evergreen.V270.Discord.ChannelId) Evergreen.V270.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId) (Evergreen.V270.Discord.Id Evergreen.V270.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId) Evergreen.V270.Id.GuildOrDmId Evergreen.V270.Id.ThreadRouteWithMessage Evergreen.V270.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId) Evergreen.V270.Id.GuildOrDmId Evergreen.V270.Id.ThreadRouteWithMessage Evergreen.V270.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId) (Evergreen.V270.Discord.Id Evergreen.V270.Discord.GuildId) (Evergreen.V270.Discord.Id Evergreen.V270.Discord.ChannelId) Evergreen.V270.Id.ThreadRouteWithMessage Evergreen.V270.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId) (Evergreen.V270.Discord.Id Evergreen.V270.Discord.PrivateChannelId) (Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelMessageId) Evergreen.V270.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId) (Evergreen.V270.Discord.Id Evergreen.V270.Discord.GuildId) (Evergreen.V270.Discord.Id Evergreen.V270.Discord.ChannelId) Evergreen.V270.Id.ThreadRouteWithMessage Evergreen.V270.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId) (Evergreen.V270.Discord.Id Evergreen.V270.Discord.PrivateChannelId) (Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelMessageId) Evergreen.V270.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId) Evergreen.V270.Id.GuildOrDmId Evergreen.V270.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V270.RichText.RichText (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId))) (SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.FileStatus.FileId) Evergreen.V270.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId) (Evergreen.V270.Discord.Id Evergreen.V270.Discord.GuildId) (Evergreen.V270.Discord.Id Evergreen.V270.Discord.ChannelId) Evergreen.V270.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V270.RichText.RichText (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V270.Id.DiscordGuildOrDmId_DmData (Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V270.RichText.RichText (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId) Evergreen.V270.Id.AnyGuildOrDmId Evergreen.V270.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V270.Id.AnyGuildOrDmId Evergreen.V270.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V270.Discord.Id Evergreen.V270.Discord.GuildId) (Evergreen.V270.Discord.Id Evergreen.V270.Discord.ChannelId) Evergreen.V270.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V270.Discord.Id Evergreen.V270.Discord.PrivateChannelId) (Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId) Evergreen.V270.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId) Evergreen.V270.FileStatus.FileHash
    | Server_SetGuildIcon (Evergreen.V270.Id.Id Evergreen.V270.Id.GuildId) Evergreen.V270.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V270.Id.Id Evergreen.V270.Id.GuildId) Evergreen.V270.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V270.Discord.Id Evergreen.V270.Discord.GuildId) Evergreen.V270.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V270.SessionIdHash.SessionIdHash Evergreen.V270.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V270.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V270.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V270.Id.AnyGuildOrDmId, Evergreen.V270.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V270.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId) Evergreen.V270.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V270.Discord.Id Evergreen.V270.Discord.GuildId) (Evergreen.V270.Discord.Id Evergreen.V270.Discord.ChannelId) Evergreen.V270.ChannelName.ChannelName (Evergreen.V270.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V270.Discord.Id Evergreen.V270.Discord.PrivateChannelId)
        (Evergreen.V270.NonemptyDict.NonemptyDict
            (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V270.Discord.Id Evergreen.V270.Discord.GuildId) Evergreen.V270.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V270.Discord.Id Evergreen.V270.Discord.PrivateChannelId) Evergreen.V270.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId) Evergreen.V270.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId) (Maybe (Evergreen.V270.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V270.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V270.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V270.Id.Id Evergreen.V270.Id.GuildId) (Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelId) Evergreen.V270.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V270.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId) Evergreen.V270.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V270.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V270.Discord.Id Evergreen.V270.Discord.GuildId) (Evergreen.V270.Discord.Id Evergreen.V270.Discord.ChannelId) Evergreen.V270.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V270.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V270.Discord.Id Evergreen.V270.Discord.PrivateChannelId) (Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V270.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V270.Discord.Id Evergreen.V270.Discord.GuildId) Evergreen.V270.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V270.Discord.Id Evergreen.V270.Discord.GuildId) (Evergreen.V270.Discord.Id Evergreen.V270.Discord.ChannelId) (Evergreen.V270.Discord.OptionalData String) (Evergreen.V270.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V270.Discord.Id Evergreen.V270.Discord.GuildId)
        (Evergreen.V270.MembersAndOwner.MembersAndOwner
            (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V270.Discord.Id Evergreen.V270.Discord.GuildId) (Evergreen.V270.Discord.Id Evergreen.V270.Discord.ChannelId) (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId) Evergreen.V270.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.Id.StickerId) Evergreen.V270.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.Id.CustomEmojiId) Evergreen.V270.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V270.Call.ServerChange
    | Server_Go
        (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId)
        { otherUserId : Evergreen.V270.Id.Id Evergreen.V270.Id.UserId
        }
        Evergreen.V270.Go.LocalChange


type LocalMsg
    = LocalChange (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V270.Id.Id Evergreen.V270.Id.GuildId) (Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelId) Evergreen.V270.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V270.Discord.Id Evergreen.V270.Discord.GuildId) (Evergreen.V270.Discord.Id Evergreen.V270.Discord.ChannelId) Evergreen.V270.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.FileStatus.FileId) Evergreen.V270.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V270.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V270.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V270.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V270.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V270.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V270.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V270.Coord.Coord Evergreen.V270.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V270.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V270.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V270.Id.AnyGuildOrDmId Evergreen.V270.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V270.Id.AnyGuildOrDmId Evergreen.V270.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V270.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V270.Coord.Coord Evergreen.V270.CssPixels.CssPixels) (Maybe Evergreen.V270.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V270.Id.AnyGuildOrDmId, Evergreen.V270.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelMessageId) (Evergreen.V270.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.Id.ThreadMessageId) (Evergreen.V270.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V270.Editable.Model
    , showLinkDiscordSetup : Bool
    , domainWhitelistInput : String
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V270.Local.Local LocalMsg Evergreen.V270.LocalState.LocalState
    , admin : Evergreen.V270.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V270.Id.AnyGuildOrDmId, Evergreen.V270.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V270.Id.Id Evergreen.V270.Id.GuildId, Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V270.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V270.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V270.Id.AnyGuildOrDmId, Evergreen.V270.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V270.Id.AnyGuildOrDmId, Evergreen.V270.Id.ThreadRoute ) (Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : Evergreen.V270.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V270.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V270.Id.AnyGuildOrDmId, Evergreen.V270.Id.ThreadRoute ) (Evergreen.V270.NonemptyDict.NonemptyDict (Evergreen.V270.Id.Id Evergreen.V270.FileStatus.FileId) Evergreen.V270.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V270.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V270.TextEditor.Model
    , profilePictureEditor : Evergreen.V270.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V270.Id.Id Evergreen.V270.Id.GuildId, Evergreen.V270.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V270.Emoji.Model
    , voiceChat : Evergreen.V270.Call.Model
    , currentDmGoMatch : SeqDict.SeqDict ( Evergreen.V270.Id.Id Evergreen.V270.Id.UserId, Maybe (Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelMessageId) ) Evergreen.V270.Go.Model
    , fileDragOverCount : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V270.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V270.SecretId.SecretId Evergreen.V270.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V270.Range.Range
                , direction : Evergreen.V270.Range.SelectionDirection
                }
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V270.NonemptyDict.NonemptyDict Int Evergreen.V270.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V270.NonemptyDict.NonemptyDict Int Evergreen.V270.Touch.Touch
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
    | AdminToFrontend Evergreen.V270.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V270.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V270.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V270.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V270.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V270.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V270.Go.PublicGoMatchResponse)


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V270.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V270.Coord.Coord Evergreen.V270.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V270.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V270.MyUi.LastCopy
    , notificationPermission : Evergreen.V270.Ports.NotificationPermission
    , pwaStatus : Evergreen.V270.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V270.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V270.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V270.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V270.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V270.Id.Id Evergreen.V270.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V270.Id.Id Evergreen.V270.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V270.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V270.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V270.Coord.Coord Evergreen.V270.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V270.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V270.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V270.Id.Id Evergreen.V270.Id.GuildId, Evergreen.V270.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V270.DmChannel.DmChannelId, Evergreen.V270.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V270.Discord.Id Evergreen.V270.Discord.GuildId, Evergreen.V270.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V270.Discord.Id Evergreen.V270.Discord.PrivateChannelId, Evergreen.V270.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V270.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V270.NonemptyDict.NonemptyDict (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId) Evergreen.V270.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V270.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V270.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V270.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V270.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId) Evergreen.V270.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId) Evergreen.V270.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V270.Id.Id Evergreen.V270.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.Id.GuildId) Evergreen.V270.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.Id.GuildId) Evergreen.V270.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V270.Discord.Id Evergreen.V270.Discord.GuildId) Evergreen.V270.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V270.DmChannel.DmChannelId Evergreen.V270.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V270.Discord.Id Evergreen.V270.Discord.PrivateChannelId) Evergreen.V270.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V270.OneToOne.OneToOne (Evergreen.V270.Slack.Id Evergreen.V270.Slack.ChannelId) Evergreen.V270.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V270.OneToOne.OneToOne String (Evergreen.V270.Id.Id Evergreen.V270.Id.GuildId)
    , slackUsers : Evergreen.V270.OneToOne.OneToOne (Evergreen.V270.Slack.Id Evergreen.V270.Slack.UserId) (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId)
    , slackServers : Evergreen.V270.OneToOne.OneToOne (Evergreen.V270.Slack.Id Evergreen.V270.Slack.TeamId) (Evergreen.V270.Id.Id Evergreen.V270.Id.GuildId)
    , slackToken : Maybe Evergreen.V270.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V270.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V270.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V270.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V270.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V270.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V270.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V270.Cloudflare.AnalyticsApiToken
    , textEditor : Evergreen.V270.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId) Evergreen.V270.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId, Evergreen.V270.Discord.Id Evergreen.V270.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V270.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V270.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V270.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V270.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId) (Evergreen.V270.LocalState.LoadingDiscordChannel (List Evergreen.V270.Discord.Message))
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V270.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.Id.StickerId) Evergreen.V270.Sticker.StickerData
    , discordStickers : Evergreen.V270.OneToOne.OneToOne (Evergreen.V270.Discord.Id Evergreen.V270.Discord.StickerId) (Evergreen.V270.Id.Id Evergreen.V270.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.Id.CustomEmojiId) Evergreen.V270.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V270.OneToOne.OneToOne Evergreen.V270.RichText.DiscordCustomEmojiIdAndName (Evergreen.V270.Id.Id Evergreen.V270.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V270.Postmark.ApiKey
    , serverSecret : Evergreen.V270.SecretId.SecretId Evergreen.V270.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V270.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V270.OneToOne.OneToOne (Evergreen.V270.SecretId.SecretId Evergreen.V270.Id.GoMatchPublicId) ( Evergreen.V270.DmChannel.DmChannelId, Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelMessageId )
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V270.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V270.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V270.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V270.Route.Route
    | SelectedFilesToAttach ( Evergreen.V270.Id.AnyGuildOrDmId, Evergreen.V270.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V270.Id.Id Evergreen.V270.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V270.Id.Id Evergreen.V270.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V270.Id.Id Evergreen.V270.Id.GuildId) (Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelId) Evergreen.V270.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V270.Id.Id Evergreen.V270.Id.GuildId) (Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelId) Evergreen.V270.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V270.Discord.Id Evergreen.V270.Discord.GuildId) (Evergreen.V270.Discord.Id Evergreen.V270.Discord.ChannelId) Evergreen.V270.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V270.Discord.Id Evergreen.V270.Discord.GuildId) (Evergreen.V270.Discord.Id Evergreen.V270.Discord.ChannelId) Evergreen.V270.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V270.Id.Id Evergreen.V270.Id.GuildId) (Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V270.Id.Id Evergreen.V270.Id.GuildId) (Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V270.Id.Id Evergreen.V270.Id.GuildId) (Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V270.Id.Id Evergreen.V270.Id.GuildId) (Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V270.Id.Id Evergreen.V270.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V270.Id.Id Evergreen.V270.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V270.Id.Id Evergreen.V270.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V270.Id.Id Evergreen.V270.Id.GuildId) (Evergreen.V270.SecretId.SecretId Evergreen.V270.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V270.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V270.Id.AnyGuildOrDmId Evergreen.V270.Id.ThreadRouteWithMessage (Evergreen.V270.Coord.Coord Evergreen.V270.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V270.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V270.Id.AnyGuildOrDmId Evergreen.V270.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V270.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V270.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V270.Id.AnyGuildOrDmId, Evergreen.V270.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V270.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V270.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V270.Id.AnyGuildOrDmId, Evergreen.V270.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V270.NonemptyDict.NonemptyDict Int Evergreen.V270.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V270.NonemptyDict.NonemptyDict Int Evergreen.V270.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V270.Id.AnyGuildOrDmId Evergreen.V270.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V270.Id.AnyGuildOrDmId Evergreen.V270.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V270.NonemptySet.NonemptySet (Evergreen.V270.Id.Id Evergreen.V270.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V270.Id.AnyGuildOrDmId, Evergreen.V270.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V270.Id.AnyGuildOrDmId Evergreen.V270.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V270.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V270.AiChat.Msg
    | GoMsg Evergreen.V270.Go.Msg
    | GoSpectatorMsg Evergreen.V270.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V270.Editable.Msg Evergreen.V270.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V270.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V270.Id.Id Evergreen.V270.Id.GuildId) Evergreen.V270.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V270.Id.AnyGuildOrDmId, Evergreen.V270.Id.ThreadRoute ) (Evergreen.V270.Id.Id Evergreen.V270.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V270.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V270.Id.AnyGuildOrDmId, Evergreen.V270.Id.ThreadRoute ) (Evergreen.V270.Id.Id Evergreen.V270.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V270.Id.AnyGuildOrDmId, Evergreen.V270.Id.ThreadRoute ) (Evergreen.V270.Id.Id Evergreen.V270.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V270.Id.AnyGuildOrDmId, Evergreen.V270.Id.ThreadRoute )
        { fileId : Evergreen.V270.Id.Id Evergreen.V270.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V270.Id.AnyGuildOrDmId, Evergreen.V270.Id.ThreadRoute ) (Evergreen.V270.Id.Id Evergreen.V270.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V270.Id.AnyGuildOrDmId, Evergreen.V270.Id.ThreadRoute ) (Evergreen.V270.Id.Id Evergreen.V270.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V270.Id.AnyGuildOrDmId, Evergreen.V270.Id.ThreadRoute )
        { fileId : Evergreen.V270.Id.Id Evergreen.V270.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V270.Id.AnyGuildOrDmId, Evergreen.V270.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V270.Id.AnyGuildOrDmId, Evergreen.V270.Id.ThreadRoute ) (Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelMessageId) (Evergreen.V270.Id.Id Evergreen.V270.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V270.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V270.Id.AnyGuildOrDmId, Evergreen.V270.Id.ThreadRoute ) (Evergreen.V270.Id.Id Evergreen.V270.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V270.Id.AnyGuildOrDmId Evergreen.V270.Id.ThreadRouteWithMessage Evergreen.V270.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V270.ImageViewer.Msg
    | GotRegisterPushSubscription (Result String Evergreen.V270.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V270.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V270.Id.Id Evergreen.V270.Id.GuildId) Evergreen.V270.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId) (Evergreen.V270.Discord.Id Evergreen.V270.Discord.GuildId) Evergreen.V270.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V270.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V270.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId
        , otherUserId : Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V270.Id.AnyGuildOrDmId Evergreen.V270.Id.ThreadRoute Evergreen.V270.MessageInput.Msg
    | MessageInputMsg Evergreen.V270.Id.AnyGuildOrDmId Evergreen.V270.Id.ThreadRoute Evergreen.V270.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V270.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V270.Range.Range, Evergreen.V270.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V270.Range.Range, Evergreen.V270.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V270.Call.FromJs)
    | VoiceChatMsg Evergreen.V270.Call.Msg
    | PressedChannelHeaderTab Evergreen.V270.Route.DmChannelHeaderTab
    | FileDragEnter
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V270.Id.Id Evergreen.V270.Id.GuildId) (Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelId) Evergreen.V270.Id.ThreadRoute
    | InitialLoadRequested_Dm Evergreen.V270.DmChannel.DmChannelId Evergreen.V270.Id.ThreadRoute
    | InitialLoadRequested_Discord Evergreen.V270.Id.DiscordGuildOrDmId Evergreen.V270.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V270.Id.Id Evergreen.V270.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V270.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V270.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V270.Untrusted.Untrusted Evergreen.V270.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V270.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V270.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V270.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V270.Id.Id Evergreen.V270.Id.GuildId) (Evergreen.V270.SecretId.SecretId Evergreen.V270.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V270.PersonName.PersonName Evergreen.V270.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V270.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V270.Slack.OAuthCode Evergreen.V270.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V270.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V270.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V270.Id.Id Evergreen.V270.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V270.SecretId.SecretId Evergreen.V270.Id.GoMatchPublicId)


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V270.Discord.Id Evergreen.V270.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V270.Discord.Id Evergreen.V270.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V270.EmailAddress.EmailAddress (Result Evergreen.V270.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V270.EmailAddress.EmailAddress (Result Evergreen.V270.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V270.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V270.Discord.Id Evergreen.V270.Discord.GuildId) (Evergreen.V270.Discord.Id Evergreen.V270.Discord.ChannelId) Evergreen.V270.Id.ThreadRouteWithMaybeMessage (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId) (Result Evergreen.V270.Discord.HttpError Evergreen.V270.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V270.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V270.Discord.Id Evergreen.V270.Discord.PrivateChannelId) (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId) (Result Evergreen.V270.Discord.HttpError Evergreen.V270.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V270.Discord.Id Evergreen.V270.Discord.GuildId) (Evergreen.V270.Discord.Id Evergreen.V270.Discord.ChannelId) Evergreen.V270.Id.ThreadRouteWithMessage (Evergreen.V270.Discord.Id Evergreen.V270.Discord.MessageId) (Result Evergreen.V270.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V270.Discord.Id Evergreen.V270.Discord.PrivateChannelId) (Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelMessageId) (Evergreen.V270.Discord.Id Evergreen.V270.Discord.MessageId) (Result Evergreen.V270.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V270.Discord.Id Evergreen.V270.Discord.GuildId) (Evergreen.V270.Discord.Id Evergreen.V270.Discord.ChannelId) Evergreen.V270.Id.ThreadRouteWithMessage (Evergreen.V270.Discord.Id Evergreen.V270.Discord.MessageId) (Result Evergreen.V270.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V270.Discord.Id Evergreen.V270.Discord.PrivateChannelId) (Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelMessageId) (Evergreen.V270.Discord.Id Evergreen.V270.Discord.MessageId) (Result Evergreen.V270.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V270.Discord.Id Evergreen.V270.Discord.GuildId) (Evergreen.V270.Discord.Id Evergreen.V270.Discord.ChannelId) Evergreen.V270.Id.ThreadRouteWithMessage (Evergreen.V270.Discord.Id Evergreen.V270.Discord.MessageId) Evergreen.V270.Emoji.EmojiOrCustomEmoji (Result Evergreen.V270.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V270.Discord.Id Evergreen.V270.Discord.PrivateChannelId) (Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelMessageId) (Evergreen.V270.Discord.Id Evergreen.V270.Discord.MessageId) Evergreen.V270.Emoji.EmojiOrCustomEmoji (Result Evergreen.V270.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V270.Discord.Id Evergreen.V270.Discord.GuildId) (Evergreen.V270.Discord.Id Evergreen.V270.Discord.ChannelId) Evergreen.V270.Id.ThreadRouteWithMessage (Evergreen.V270.Discord.Id Evergreen.V270.Discord.MessageId) Evergreen.V270.Emoji.EmojiOrCustomEmoji (Result Evergreen.V270.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V270.Discord.Id Evergreen.V270.Discord.PrivateChannelId) (Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelMessageId) (Evergreen.V270.Discord.Id Evergreen.V270.Discord.MessageId) Evergreen.V270.Emoji.EmojiOrCustomEmoji (Result Evergreen.V270.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V270.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V270.Discord.HttpError (List ( Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId, Maybe Evergreen.V270.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V270.Slack.CurrentUser
            , team : Evergreen.V270.Slack.Team
            , users : List Evergreen.V270.Slack.User
            , channels : List ( Evergreen.V270.Slack.Channel, List Evergreen.V270.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId) (Result Effect.Http.Error Evergreen.V270.Slack.TokenResponse)
    | GotCloudflareSessionCreated Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V270.Local.ChangeId Effect.Time.Posix Evergreen.V270.Call.CallId Evergreen.V270.Cloudflare.Sdp (List String) (Result Effect.Http.Error Evergreen.V270.Cloudflare.RealtimeSessionId)
    | GotCloudflareSession Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V270.Local.ChangeId Effect.Time.Posix Evergreen.V270.Call.CallId Evergreen.V270.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V270.Cloudflare.PushTracksResult)
    | GotCloudflarePullOffer Effect.Time.Posix Effect.Lamdera.ClientId Evergreen.V270.Local.ChangeId Evergreen.V270.Call.ConnectionId Evergreen.V270.Cloudflare.RealtimeSessionId (List Evergreen.V270.Cloudflare.TrackName) (Result Effect.Http.Error Evergreen.V270.Cloudflare.PullTracksResult)
    | GotCloudflareRenegotiateAck Effect.Lamdera.ClientId Evergreen.V270.Local.ChangeId Evergreen.V270.Cloudflare.Sdp (Result Effect.Http.Error ())
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId) Evergreen.V270.Discord.UserAuth (Result Evergreen.V270.Discord.HttpError Evergreen.V270.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId) (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId) (Result Evergreen.V270.Discord.HttpError Evergreen.V270.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId)
        (Result
            Evergreen.V270.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V270.Discord.Id Evergreen.V270.Discord.PrivateChannelId
                , members : List (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId)
                }
            , List
                ( Evergreen.V270.Discord.Id Evergreen.V270.Discord.GuildId
                , { guild : Evergreen.V270.Discord.GatewayGuild
                  , channels : List Evergreen.V270.Discord.Channel
                  , icon : Maybe Evergreen.V270.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId) Bool Evergreen.V270.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V270.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V270.Discord.Id Evergreen.V270.Discord.AttachmentId, Evergreen.V270.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V270.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V270.Discord.Id Evergreen.V270.Discord.AttachmentId, Evergreen.V270.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId) (Evergreen.V270.Discord.Id Evergreen.V270.Discord.GuildId) (Evergreen.V270.Discord.Id Evergreen.V270.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V270.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V270.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId) (Evergreen.V270.Discord.Id Evergreen.V270.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V270.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V270.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId) (Evergreen.V270.Discord.Id Evergreen.V270.Discord.GuildId) (Evergreen.V270.Discord.Id Evergreen.V270.Discord.ChannelId) (Result Evergreen.V270.Discord.HttpError (List Evergreen.V270.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId) (Evergreen.V270.Discord.Id Evergreen.V270.Discord.PrivateChannelId) (Result Evergreen.V270.Discord.HttpError (List Evergreen.V270.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V270.Id.Id Evergreen.V270.Id.GuildId) (Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelId) Evergreen.V270.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V270.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V270.DmChannel.DmChannelId Evergreen.V270.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V270.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V270.Discord.Id Evergreen.V270.Discord.GuildId) (Evergreen.V270.Discord.Id Evergreen.V270.Discord.ChannelId) Evergreen.V270.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V270.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V270.Discord.Id Evergreen.V270.Discord.PrivateChannelId) (Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V270.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId)
        (Evergreen.V270.Discord.Id Evergreen.V270.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V270.Discord.HttpError
            { guild : Evergreen.V270.Discord.GatewayGuild
            , channels : List Evergreen.V270.Discord.Channel
            , icon : Maybe Evergreen.V270.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V270.Discord.Id Evergreen.V270.Discord.GuildId) (Result Evergreen.V270.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V270.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId) (List ( Evergreen.V270.Id.Id Evergreen.V270.Id.StickerId, Result Effect.Http.Error Evergreen.V270.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V270.Id.Id Evergreen.V270.Id.StickerId, Result Effect.Http.Error Evergreen.V270.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId) (List ( Evergreen.V270.Id.Id Evergreen.V270.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V270.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V270.Id.Id Evergreen.V270.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V270.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V270.Discord.HttpError (List Evergreen.V270.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V270.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V270.SecretId.SecretId Evergreen.V270.SecretId.ServerSecret))
    | GotTimeForWebsocketListenClose (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | GotCloudflareUsage Effect.Time.Posix (Result Effect.Http.Error Int)
    | GotCloudflareEgressForAdmin Effect.Lamdera.ClientId (Result Effect.Http.Error Int)
