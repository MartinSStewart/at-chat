module Evergreen.V266.Types exposing (..)

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
import Evergreen.V266.AiChat
import Evergreen.V266.Call
import Evergreen.V266.ChannelDescription
import Evergreen.V266.ChannelName
import Evergreen.V266.Cloudflare
import Evergreen.V266.Coord
import Evergreen.V266.CssPixels
import Evergreen.V266.CustomEmoji
import Evergreen.V266.Discord
import Evergreen.V266.DiscordAttachmentId
import Evergreen.V266.DiscordUserData
import Evergreen.V266.DmChannel
import Evergreen.V266.Editable
import Evergreen.V266.EmailAddress
import Evergreen.V266.Embed
import Evergreen.V266.Emoji
import Evergreen.V266.FileStatus
import Evergreen.V266.Go
import Evergreen.V266.GuildName
import Evergreen.V266.Id
import Evergreen.V266.ImageEditor
import Evergreen.V266.Local
import Evergreen.V266.LocalState
import Evergreen.V266.Log
import Evergreen.V266.LoginForm
import Evergreen.V266.MembersAndOwner
import Evergreen.V266.Message
import Evergreen.V266.MessageInput
import Evergreen.V266.MessageView
import Evergreen.V266.MyUi
import Evergreen.V266.NonemptyDict
import Evergreen.V266.NonemptySet
import Evergreen.V266.OneToOne
import Evergreen.V266.Pages.Admin
import Evergreen.V266.Pagination
import Evergreen.V266.PersonName
import Evergreen.V266.Ports
import Evergreen.V266.Postmark
import Evergreen.V266.Range
import Evergreen.V266.RichText
import Evergreen.V266.Route
import Evergreen.V266.SecretId
import Evergreen.V266.SessionIdHash
import Evergreen.V266.Slack
import Evergreen.V266.Sticker
import Evergreen.V266.TextEditor
import Evergreen.V266.ToBackendLog
import Evergreen.V266.Touch
import Evergreen.V266.TwoFactorAuthentication
import Evergreen.V266.Ui.Anim
import Evergreen.V266.Untrusted
import Evergreen.V266.User
import Evergreen.V266.UserAgent
import Evergreen.V266.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V266.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V266.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.Id.GuildId) Evergreen.V266.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId) Evergreen.V266.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V266.Discord.Id Evergreen.V266.Discord.PrivateChannelId) Evergreen.V266.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V266.Discord.Id Evergreen.V266.Discord.GuildId) Evergreen.V266.LocalState.DiscordFrontendGuild
    , user : Evergreen.V266.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId) Evergreen.V266.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId) Evergreen.V266.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId) Evergreen.V266.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V266.SessionIdHash.SessionIdHash Evergreen.V266.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V266.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.Id.StickerId) Evergreen.V266.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.Id.CustomEmojiId) Evergreen.V266.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V266.Call.CallId (Evergreen.V266.NonemptySet.NonemptySet ( Evergreen.V266.Id.Id Evergreen.V266.Id.UserId, Effect.Lamdera.ClientId ))
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type PublicGoMatch
    = PublicGoMatch_NotLoaded
    | PublicGoMatch_Loading
    | PublicGoMatch_Loaded Evergreen.V266.Go.PublicGoMatchData Evergreen.V266.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V266.Route.Route
    , windowSize : Evergreen.V266.Coord.Coord Evergreen.V266.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V266.Ports.NotificationPermission
    , pwaStatus : Evergreen.V266.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V266.UserAgent.UserAgent
    , publicGoMatch : PublicGoMatch
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V266.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V266.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V266.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.FileStatus.FileId) Evergreen.V266.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V266.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V266.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.FileStatus.FileId) Evergreen.V266.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V266.Id.Id Evergreen.V266.Id.GuildId) Evergreen.V266.ChannelName.ChannelName Evergreen.V266.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V266.Id.Id Evergreen.V266.Id.GuildId) (Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelId) Evergreen.V266.ChannelName.ChannelName Evergreen.V266.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V266.Id.Id Evergreen.V266.Id.GuildId) (Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelId)
    | Local_DeleteGuild (Evergreen.V266.Id.Id Evergreen.V266.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V266.Id.Id Evergreen.V266.Id.GuildId) (Evergreen.V266.UserSession.ToBeFilledInByBackend (Evergreen.V266.SecretId.SecretId Evergreen.V266.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V266.Id.Id Evergreen.V266.Id.GuildId) (Evergreen.V266.SecretId.SecretId Evergreen.V266.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V266.GuildName.GuildName (Evergreen.V266.UserSession.ToBeFilledInByBackend (Evergreen.V266.Id.Id Evergreen.V266.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V266.Id.AnyGuildOrDmId, Evergreen.V266.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V266.Id.AnyGuildOrDmId Evergreen.V266.Id.ThreadRouteWithMessage Evergreen.V266.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V266.Id.AnyGuildOrDmId Evergreen.V266.Id.ThreadRouteWithMessage Evergreen.V266.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V266.Id.GuildOrDmId Evergreen.V266.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.FileStatus.FileId) Evergreen.V266.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId) (Evergreen.V266.Discord.Id Evergreen.V266.Discord.GuildId) (Evergreen.V266.Discord.Id Evergreen.V266.Discord.ChannelId) Evergreen.V266.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V266.Id.DiscordGuildOrDmId_DmData (Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V266.Id.AnyGuildOrDmId Evergreen.V266.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V266.Id.AnyGuildOrDmId Evergreen.V266.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V266.Id.AnyGuildOrDmId Evergreen.V266.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V266.UserSession.SetViewing
    | Local_SetName Evergreen.V266.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V266.Id.GuildOrDmId (Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelMessageId) (Evergreen.V266.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelMessageId) (Evergreen.V266.Message.Message Evergreen.V266.Id.ChannelMessageId (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V266.Id.GuildOrDmId (Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelMessageId) (Evergreen.V266.Id.Id Evergreen.V266.Id.ThreadMessageId) (Evergreen.V266.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.Id.ThreadMessageId) (Evergreen.V266.Message.Message Evergreen.V266.Id.ThreadMessageId (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V266.Id.DiscordGuildOrDmId (Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelMessageId) (Evergreen.V266.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelMessageId) (Evergreen.V266.Message.Message Evergreen.V266.Id.ChannelMessageId (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V266.Id.DiscordGuildOrDmId (Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelMessageId) (Evergreen.V266.Id.Id Evergreen.V266.Id.ThreadMessageId) (Evergreen.V266.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.Id.ThreadMessageId) (Evergreen.V266.Message.Message Evergreen.V266.Id.ThreadMessageId (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V266.Id.Id Evergreen.V266.Id.GuildId) Evergreen.V266.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId) (Evergreen.V266.Discord.Id Evergreen.V266.Discord.GuildId) Evergreen.V266.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V266.UserSession.NotificationMode
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V266.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V266.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V266.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V266.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V266.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V266.NonemptySet.NonemptySet (Evergreen.V266.Id.Id Evergreen.V266.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V266.Call.LocalChange
    | Local_Go
        { otherUserId : Evergreen.V266.Id.Id Evergreen.V266.Id.UserId
        }
        Evergreen.V266.Go.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId) Effect.Time.Posix Evergreen.V266.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V266.RichText.RichText (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId))) Evergreen.V266.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.FileStatus.FileId) Evergreen.V266.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.Id.StickerId) Evergreen.V266.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V266.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V266.RichText.RichText (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId))) Evergreen.V266.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.FileStatus.FileId) Evergreen.V266.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.Id.StickerId) Evergreen.V266.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V266.Id.Id Evergreen.V266.Id.GuildId) Evergreen.V266.ChannelName.ChannelName Evergreen.V266.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V266.Id.Id Evergreen.V266.Id.GuildId) (Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelId) Evergreen.V266.ChannelName.ChannelName Evergreen.V266.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V266.Id.Id Evergreen.V266.Id.GuildId) (Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelId)
    | Server_DeleteGuild (Evergreen.V266.Id.Id Evergreen.V266.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId) (Evergreen.V266.Id.Id Evergreen.V266.Id.GuildId) (Evergreen.V266.SecretId.SecretId Evergreen.V266.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V266.Id.Id Evergreen.V266.Id.GuildId) (Evergreen.V266.SecretId.SecretId Evergreen.V266.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId) (Evergreen.V266.Id.Id Evergreen.V266.Id.GuildId) Evergreen.V266.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V266.LocalState.JoinGuildError
            { guildId : Evergreen.V266.Id.Id Evergreen.V266.Id.GuildId
            , guild : Evergreen.V266.LocalState.FrontendGuild
            , owner : Evergreen.V266.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId) Evergreen.V266.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId) Evergreen.V266.Id.GuildOrDmId Evergreen.V266.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId) (Evergreen.V266.Discord.Id Evergreen.V266.Discord.GuildId) (Evergreen.V266.Discord.Id Evergreen.V266.Discord.ChannelId) Evergreen.V266.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId) (Evergreen.V266.Discord.Id Evergreen.V266.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId) Evergreen.V266.Id.GuildOrDmId Evergreen.V266.Id.ThreadRouteWithMessage Evergreen.V266.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId) Evergreen.V266.Id.GuildOrDmId Evergreen.V266.Id.ThreadRouteWithMessage Evergreen.V266.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId) (Evergreen.V266.Discord.Id Evergreen.V266.Discord.GuildId) (Evergreen.V266.Discord.Id Evergreen.V266.Discord.ChannelId) Evergreen.V266.Id.ThreadRouteWithMessage Evergreen.V266.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId) (Evergreen.V266.Discord.Id Evergreen.V266.Discord.PrivateChannelId) (Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelMessageId) Evergreen.V266.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId) (Evergreen.V266.Discord.Id Evergreen.V266.Discord.GuildId) (Evergreen.V266.Discord.Id Evergreen.V266.Discord.ChannelId) Evergreen.V266.Id.ThreadRouteWithMessage Evergreen.V266.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId) (Evergreen.V266.Discord.Id Evergreen.V266.Discord.PrivateChannelId) (Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelMessageId) Evergreen.V266.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId) Evergreen.V266.Id.GuildOrDmId Evergreen.V266.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V266.RichText.RichText (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId))) (SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.FileStatus.FileId) Evergreen.V266.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId) (Evergreen.V266.Discord.Id Evergreen.V266.Discord.GuildId) (Evergreen.V266.Discord.Id Evergreen.V266.Discord.ChannelId) Evergreen.V266.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V266.RichText.RichText (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V266.Id.DiscordGuildOrDmId_DmData (Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V266.RichText.RichText (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId) Evergreen.V266.Id.AnyGuildOrDmId Evergreen.V266.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V266.Id.AnyGuildOrDmId Evergreen.V266.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V266.Discord.Id Evergreen.V266.Discord.GuildId) (Evergreen.V266.Discord.Id Evergreen.V266.Discord.ChannelId) Evergreen.V266.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V266.Discord.Id Evergreen.V266.Discord.PrivateChannelId) (Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId) Evergreen.V266.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId) Evergreen.V266.FileStatus.FileHash
    | Server_SetGuildIcon (Evergreen.V266.Id.Id Evergreen.V266.Id.GuildId) Evergreen.V266.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V266.Id.Id Evergreen.V266.Id.GuildId) Evergreen.V266.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V266.Discord.Id Evergreen.V266.Discord.GuildId) Evergreen.V266.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V266.SessionIdHash.SessionIdHash Evergreen.V266.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V266.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V266.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V266.Id.AnyGuildOrDmId, Evergreen.V266.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V266.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId) Evergreen.V266.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V266.Discord.Id Evergreen.V266.Discord.GuildId) (Evergreen.V266.Discord.Id Evergreen.V266.Discord.ChannelId) Evergreen.V266.ChannelName.ChannelName (Evergreen.V266.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V266.Discord.Id Evergreen.V266.Discord.PrivateChannelId)
        (Evergreen.V266.NonemptyDict.NonemptyDict
            (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V266.Discord.Id Evergreen.V266.Discord.GuildId) Evergreen.V266.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V266.Discord.Id Evergreen.V266.Discord.PrivateChannelId) Evergreen.V266.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId) Evergreen.V266.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId) (Maybe (Evergreen.V266.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V266.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V266.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V266.Id.Id Evergreen.V266.Id.GuildId) (Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelId) Evergreen.V266.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V266.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId) Evergreen.V266.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V266.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V266.Discord.Id Evergreen.V266.Discord.GuildId) (Evergreen.V266.Discord.Id Evergreen.V266.Discord.ChannelId) Evergreen.V266.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V266.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V266.Discord.Id Evergreen.V266.Discord.PrivateChannelId) (Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V266.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V266.Discord.Id Evergreen.V266.Discord.GuildId) Evergreen.V266.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V266.Discord.Id Evergreen.V266.Discord.GuildId) (Evergreen.V266.Discord.Id Evergreen.V266.Discord.ChannelId) (Evergreen.V266.Discord.OptionalData String) (Evergreen.V266.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V266.Discord.Id Evergreen.V266.Discord.GuildId)
        (Evergreen.V266.MembersAndOwner.MembersAndOwner
            (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V266.Discord.Id Evergreen.V266.Discord.GuildId) (Evergreen.V266.Discord.Id Evergreen.V266.Discord.ChannelId) (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId) Evergreen.V266.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.Id.StickerId) Evergreen.V266.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.Id.CustomEmojiId) Evergreen.V266.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V266.Call.ServerChange
    | Server_Go
        (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId)
        { otherUserId : Evergreen.V266.Id.Id Evergreen.V266.Id.UserId
        }
        Evergreen.V266.Go.LocalChange


type LocalMsg
    = LocalChange (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V266.Id.Id Evergreen.V266.Id.GuildId) (Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelId) Evergreen.V266.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V266.Discord.Id Evergreen.V266.Discord.GuildId) (Evergreen.V266.Discord.Id Evergreen.V266.Discord.ChannelId) Evergreen.V266.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.FileStatus.FileId) Evergreen.V266.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V266.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V266.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V266.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V266.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V266.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V266.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V266.Coord.Coord Evergreen.V266.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V266.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V266.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V266.Id.AnyGuildOrDmId Evergreen.V266.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V266.Id.AnyGuildOrDmId Evergreen.V266.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V266.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V266.Coord.Coord Evergreen.V266.CssPixels.CssPixels) (Maybe Evergreen.V266.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V266.Id.AnyGuildOrDmId, Evergreen.V266.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelMessageId) (Evergreen.V266.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.Id.ThreadMessageId) (Evergreen.V266.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V266.Editable.Model
    , showLinkDiscordSetup : Bool
    , domainWhitelistInput : String
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V266.Local.Local LocalMsg Evergreen.V266.LocalState.LocalState
    , admin : Evergreen.V266.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V266.Id.AnyGuildOrDmId, Evergreen.V266.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V266.Id.Id Evergreen.V266.Id.GuildId, Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V266.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V266.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V266.Id.AnyGuildOrDmId, Evergreen.V266.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V266.Id.AnyGuildOrDmId, Evergreen.V266.Id.ThreadRoute ) (Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : Evergreen.V266.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V266.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V266.Id.AnyGuildOrDmId, Evergreen.V266.Id.ThreadRoute ) (Evergreen.V266.NonemptyDict.NonemptyDict (Evergreen.V266.Id.Id Evergreen.V266.FileStatus.FileId) Evergreen.V266.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V266.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V266.TextEditor.Model
    , profilePictureEditor : Evergreen.V266.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V266.Id.Id Evergreen.V266.Id.GuildId, Evergreen.V266.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V266.Emoji.Model
    , voiceChat : Evergreen.V266.Call.Model
    , currentDmGoMatch : SeqDict.SeqDict ( Evergreen.V266.Id.Id Evergreen.V266.Id.UserId, Maybe (Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelMessageId) ) Evergreen.V266.Go.Model
    , fileDragOverCount : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V266.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V266.SecretId.SecretId Evergreen.V266.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V266.Range.Range
                , direction : Evergreen.V266.Range.SelectionDirection
                }
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V266.NonemptyDict.NonemptyDict Int Evergreen.V266.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V266.NonemptyDict.NonemptyDict Int Evergreen.V266.Touch.Touch
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
    | AdminToFrontend Evergreen.V266.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V266.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V266.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V266.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V266.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V266.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V266.Go.PublicGoMatchResponse)


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V266.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V266.Coord.Coord Evergreen.V266.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V266.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V266.MyUi.LastCopy
    , notificationPermission : Evergreen.V266.Ports.NotificationPermission
    , pwaStatus : Evergreen.V266.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V266.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V266.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V266.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V266.Id.Id Evergreen.V266.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V266.Id.Id Evergreen.V266.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V266.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V266.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V266.Coord.Coord Evergreen.V266.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V266.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V266.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V266.Id.Id Evergreen.V266.Id.GuildId, Evergreen.V266.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V266.DmChannel.DmChannelId, Evergreen.V266.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V266.Discord.Id Evergreen.V266.Discord.GuildId, Evergreen.V266.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V266.Discord.Id Evergreen.V266.Discord.PrivateChannelId, Evergreen.V266.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V266.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V266.NonemptyDict.NonemptyDict (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId) Evergreen.V266.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V266.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V266.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V266.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V266.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId) Evergreen.V266.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId) Evergreen.V266.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V266.Id.Id Evergreen.V266.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.Id.GuildId) Evergreen.V266.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.Id.GuildId) Evergreen.V266.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V266.Discord.Id Evergreen.V266.Discord.GuildId) Evergreen.V266.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V266.DmChannel.DmChannelId Evergreen.V266.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V266.Discord.Id Evergreen.V266.Discord.PrivateChannelId) Evergreen.V266.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V266.OneToOne.OneToOne (Evergreen.V266.Slack.Id Evergreen.V266.Slack.ChannelId) Evergreen.V266.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V266.OneToOne.OneToOne String (Evergreen.V266.Id.Id Evergreen.V266.Id.GuildId)
    , slackUsers : Evergreen.V266.OneToOne.OneToOne (Evergreen.V266.Slack.Id Evergreen.V266.Slack.UserId) (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId)
    , slackServers : Evergreen.V266.OneToOne.OneToOne (Evergreen.V266.Slack.Id Evergreen.V266.Slack.TeamId) (Evergreen.V266.Id.Id Evergreen.V266.Id.GuildId)
    , slackToken : Maybe Evergreen.V266.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V266.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V266.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V266.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V266.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V266.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V266.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V266.Cloudflare.AnalyticsApiToken
    , textEditor : Evergreen.V266.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId) Evergreen.V266.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId, Evergreen.V266.Discord.Id Evergreen.V266.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V266.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V266.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V266.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V266.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId) (Evergreen.V266.LocalState.LoadingDiscordChannel (List Evergreen.V266.Discord.Message))
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V266.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.Id.StickerId) Evergreen.V266.Sticker.StickerData
    , discordStickers : Evergreen.V266.OneToOne.OneToOne (Evergreen.V266.Discord.Id Evergreen.V266.Discord.StickerId) (Evergreen.V266.Id.Id Evergreen.V266.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.Id.CustomEmojiId) Evergreen.V266.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V266.OneToOne.OneToOne Evergreen.V266.RichText.DiscordCustomEmojiIdAndName (Evergreen.V266.Id.Id Evergreen.V266.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V266.Postmark.ApiKey
    , serverSecret : Evergreen.V266.SecretId.SecretId Evergreen.V266.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V266.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V266.OneToOne.OneToOne (Evergreen.V266.SecretId.SecretId Evergreen.V266.Id.GoMatchPublicId) ( Evergreen.V266.DmChannel.DmChannelId, Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelMessageId )
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V266.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V266.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V266.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V266.Route.Route
    | SelectedFilesToAttach ( Evergreen.V266.Id.AnyGuildOrDmId, Evergreen.V266.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V266.Id.Id Evergreen.V266.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V266.Id.Id Evergreen.V266.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V266.Id.Id Evergreen.V266.Id.GuildId) (Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelId) Evergreen.V266.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V266.Id.Id Evergreen.V266.Id.GuildId) (Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelId) Evergreen.V266.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V266.Discord.Id Evergreen.V266.Discord.GuildId) (Evergreen.V266.Discord.Id Evergreen.V266.Discord.ChannelId) Evergreen.V266.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V266.Discord.Id Evergreen.V266.Discord.GuildId) (Evergreen.V266.Discord.Id Evergreen.V266.Discord.ChannelId) Evergreen.V266.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V266.Id.Id Evergreen.V266.Id.GuildId) (Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V266.Id.Id Evergreen.V266.Id.GuildId) (Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V266.Id.Id Evergreen.V266.Id.GuildId) (Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V266.Id.Id Evergreen.V266.Id.GuildId) (Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V266.Id.Id Evergreen.V266.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V266.Id.Id Evergreen.V266.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V266.Id.Id Evergreen.V266.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V266.Id.Id Evergreen.V266.Id.GuildId) (Evergreen.V266.SecretId.SecretId Evergreen.V266.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V266.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V266.Id.AnyGuildOrDmId Evergreen.V266.Id.ThreadRouteWithMessage (Evergreen.V266.Coord.Coord Evergreen.V266.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V266.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V266.Id.AnyGuildOrDmId Evergreen.V266.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V266.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V266.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V266.Id.AnyGuildOrDmId, Evergreen.V266.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V266.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V266.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V266.Id.AnyGuildOrDmId, Evergreen.V266.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V266.NonemptyDict.NonemptyDict Int Evergreen.V266.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V266.NonemptyDict.NonemptyDict Int Evergreen.V266.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V266.Id.AnyGuildOrDmId Evergreen.V266.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V266.Id.AnyGuildOrDmId Evergreen.V266.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V266.NonemptySet.NonemptySet (Evergreen.V266.Id.Id Evergreen.V266.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V266.Id.AnyGuildOrDmId, Evergreen.V266.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V266.Id.AnyGuildOrDmId Evergreen.V266.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V266.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V266.AiChat.Msg
    | GoMsg Evergreen.V266.Go.Msg
    | GoSpectatorMsg Evergreen.V266.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V266.Editable.Msg Evergreen.V266.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V266.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V266.Id.Id Evergreen.V266.Id.GuildId) Evergreen.V266.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V266.Id.AnyGuildOrDmId, Evergreen.V266.Id.ThreadRoute ) (Evergreen.V266.Id.Id Evergreen.V266.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V266.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V266.Id.AnyGuildOrDmId, Evergreen.V266.Id.ThreadRoute ) (Evergreen.V266.Id.Id Evergreen.V266.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V266.Id.AnyGuildOrDmId, Evergreen.V266.Id.ThreadRoute ) (Evergreen.V266.Id.Id Evergreen.V266.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V266.Id.AnyGuildOrDmId, Evergreen.V266.Id.ThreadRoute )
        { fileId : Evergreen.V266.Id.Id Evergreen.V266.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V266.Id.AnyGuildOrDmId, Evergreen.V266.Id.ThreadRoute ) (Evergreen.V266.Id.Id Evergreen.V266.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V266.Id.AnyGuildOrDmId, Evergreen.V266.Id.ThreadRoute ) (Evergreen.V266.Id.Id Evergreen.V266.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V266.Id.AnyGuildOrDmId, Evergreen.V266.Id.ThreadRoute )
        { fileId : Evergreen.V266.Id.Id Evergreen.V266.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V266.Id.AnyGuildOrDmId, Evergreen.V266.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V266.Id.AnyGuildOrDmId, Evergreen.V266.Id.ThreadRoute ) (Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelMessageId) (Evergreen.V266.Id.Id Evergreen.V266.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V266.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V266.Id.AnyGuildOrDmId, Evergreen.V266.Id.ThreadRoute ) (Evergreen.V266.Id.Id Evergreen.V266.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V266.Id.AnyGuildOrDmId Evergreen.V266.Id.ThreadRouteWithMessage Evergreen.V266.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V266.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V266.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V266.Id.Id Evergreen.V266.Id.GuildId) Evergreen.V266.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId) (Evergreen.V266.Discord.Id Evergreen.V266.Discord.GuildId) Evergreen.V266.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V266.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V266.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId
        , otherUserId : Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V266.Id.AnyGuildOrDmId Evergreen.V266.Id.ThreadRoute Evergreen.V266.MessageInput.Msg
    | MessageInputMsg Evergreen.V266.Id.AnyGuildOrDmId Evergreen.V266.Id.ThreadRoute Evergreen.V266.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V266.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V266.Range.Range, Evergreen.V266.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V266.Range.Range, Evergreen.V266.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V266.Call.FromJs)
    | VoiceChatMsg Evergreen.V266.Call.Msg
    | PressedChannelHeaderTab Evergreen.V266.Route.DmChannelHeaderTab
    | FileDragEnter
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V266.Id.Id Evergreen.V266.Id.GuildId) (Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelId) Evergreen.V266.Id.ThreadRoute
    | InitialLoadRequested_Dm Evergreen.V266.DmChannel.DmChannelId Evergreen.V266.Id.ThreadRoute
    | InitialLoadRequested_Discord Evergreen.V266.Id.DiscordGuildOrDmId Evergreen.V266.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V266.Id.Id Evergreen.V266.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V266.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V266.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V266.Untrusted.Untrusted Evergreen.V266.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V266.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V266.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V266.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V266.Id.Id Evergreen.V266.Id.GuildId) (Evergreen.V266.SecretId.SecretId Evergreen.V266.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V266.PersonName.PersonName Evergreen.V266.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V266.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V266.Slack.OAuthCode Evergreen.V266.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V266.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V266.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V266.Id.Id Evergreen.V266.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V266.SecretId.SecretId Evergreen.V266.Id.GoMatchPublicId)


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V266.Discord.Id Evergreen.V266.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V266.Discord.Id Evergreen.V266.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V266.EmailAddress.EmailAddress (Result Evergreen.V266.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V266.EmailAddress.EmailAddress (Result Evergreen.V266.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V266.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V266.Discord.Id Evergreen.V266.Discord.GuildId) (Evergreen.V266.Discord.Id Evergreen.V266.Discord.ChannelId) Evergreen.V266.Id.ThreadRouteWithMaybeMessage (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId) (Result Evergreen.V266.Discord.HttpError Evergreen.V266.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V266.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V266.Discord.Id Evergreen.V266.Discord.PrivateChannelId) (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId) (Result Evergreen.V266.Discord.HttpError Evergreen.V266.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V266.Discord.Id Evergreen.V266.Discord.GuildId) (Evergreen.V266.Discord.Id Evergreen.V266.Discord.ChannelId) Evergreen.V266.Id.ThreadRouteWithMessage (Evergreen.V266.Discord.Id Evergreen.V266.Discord.MessageId) (Result Evergreen.V266.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V266.Discord.Id Evergreen.V266.Discord.PrivateChannelId) (Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelMessageId) (Evergreen.V266.Discord.Id Evergreen.V266.Discord.MessageId) (Result Evergreen.V266.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V266.Discord.Id Evergreen.V266.Discord.GuildId) (Evergreen.V266.Discord.Id Evergreen.V266.Discord.ChannelId) Evergreen.V266.Id.ThreadRouteWithMessage (Evergreen.V266.Discord.Id Evergreen.V266.Discord.MessageId) (Result Evergreen.V266.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V266.Discord.Id Evergreen.V266.Discord.PrivateChannelId) (Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelMessageId) (Evergreen.V266.Discord.Id Evergreen.V266.Discord.MessageId) (Result Evergreen.V266.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V266.Discord.Id Evergreen.V266.Discord.GuildId) (Evergreen.V266.Discord.Id Evergreen.V266.Discord.ChannelId) Evergreen.V266.Id.ThreadRouteWithMessage (Evergreen.V266.Discord.Id Evergreen.V266.Discord.MessageId) Evergreen.V266.Emoji.EmojiOrCustomEmoji (Result Evergreen.V266.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V266.Discord.Id Evergreen.V266.Discord.PrivateChannelId) (Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelMessageId) (Evergreen.V266.Discord.Id Evergreen.V266.Discord.MessageId) Evergreen.V266.Emoji.EmojiOrCustomEmoji (Result Evergreen.V266.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V266.Discord.Id Evergreen.V266.Discord.GuildId) (Evergreen.V266.Discord.Id Evergreen.V266.Discord.ChannelId) Evergreen.V266.Id.ThreadRouteWithMessage (Evergreen.V266.Discord.Id Evergreen.V266.Discord.MessageId) Evergreen.V266.Emoji.EmojiOrCustomEmoji (Result Evergreen.V266.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V266.Discord.Id Evergreen.V266.Discord.PrivateChannelId) (Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelMessageId) (Evergreen.V266.Discord.Id Evergreen.V266.Discord.MessageId) Evergreen.V266.Emoji.EmojiOrCustomEmoji (Result Evergreen.V266.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V266.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V266.Discord.HttpError (List ( Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId, Maybe Evergreen.V266.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V266.Slack.CurrentUser
            , team : Evergreen.V266.Slack.Team
            , users : List Evergreen.V266.Slack.User
            , channels : List ( Evergreen.V266.Slack.Channel, List Evergreen.V266.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId) (Result Effect.Http.Error Evergreen.V266.Slack.TokenResponse)
    | GotCloudflareSessionCreated Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V266.Local.ChangeId Effect.Time.Posix Evergreen.V266.Call.CallId Evergreen.V266.Cloudflare.Sdp (List String) (Result Effect.Http.Error Evergreen.V266.Cloudflare.RealtimeSessionId)
    | GotCloudflareSession Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V266.Local.ChangeId Effect.Time.Posix Evergreen.V266.Call.CallId Evergreen.V266.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V266.Cloudflare.PushTracksResult)
    | GotCloudflarePullOffer Effect.Time.Posix Effect.Lamdera.ClientId Evergreen.V266.Local.ChangeId Evergreen.V266.Call.ConnectionId Evergreen.V266.Cloudflare.RealtimeSessionId (List Evergreen.V266.Cloudflare.TrackName) (Result Effect.Http.Error Evergreen.V266.Cloudflare.PullTracksResult)
    | GotCloudflareRenegotiateAck Effect.Lamdera.ClientId Evergreen.V266.Local.ChangeId Evergreen.V266.Cloudflare.Sdp (Result Effect.Http.Error ())
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId) Evergreen.V266.Discord.UserAuth (Result Evergreen.V266.Discord.HttpError Evergreen.V266.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId) (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId) (Result Evergreen.V266.Discord.HttpError Evergreen.V266.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId)
        (Result
            Evergreen.V266.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V266.Discord.Id Evergreen.V266.Discord.PrivateChannelId
                , members : List (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId)
                }
            , List
                ( Evergreen.V266.Discord.Id Evergreen.V266.Discord.GuildId
                , { guild : Evergreen.V266.Discord.GatewayGuild
                  , channels : List Evergreen.V266.Discord.Channel
                  , icon : Maybe Evergreen.V266.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId) Bool Evergreen.V266.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V266.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V266.Discord.Id Evergreen.V266.Discord.AttachmentId, Evergreen.V266.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V266.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V266.Discord.Id Evergreen.V266.Discord.AttachmentId, Evergreen.V266.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId) (Evergreen.V266.Discord.Id Evergreen.V266.Discord.GuildId) (Evergreen.V266.Discord.Id Evergreen.V266.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V266.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V266.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId) (Evergreen.V266.Discord.Id Evergreen.V266.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V266.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V266.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId) (Evergreen.V266.Discord.Id Evergreen.V266.Discord.GuildId) (Evergreen.V266.Discord.Id Evergreen.V266.Discord.ChannelId) (Result Evergreen.V266.Discord.HttpError (List Evergreen.V266.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId) (Evergreen.V266.Discord.Id Evergreen.V266.Discord.PrivateChannelId) (Result Evergreen.V266.Discord.HttpError (List Evergreen.V266.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V266.Id.Id Evergreen.V266.Id.GuildId) (Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelId) Evergreen.V266.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V266.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V266.DmChannel.DmChannelId Evergreen.V266.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V266.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V266.Discord.Id Evergreen.V266.Discord.GuildId) (Evergreen.V266.Discord.Id Evergreen.V266.Discord.ChannelId) Evergreen.V266.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V266.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V266.Discord.Id Evergreen.V266.Discord.PrivateChannelId) (Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V266.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId)
        (Evergreen.V266.Discord.Id Evergreen.V266.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V266.Discord.HttpError
            { guild : Evergreen.V266.Discord.GatewayGuild
            , channels : List Evergreen.V266.Discord.Channel
            , icon : Maybe Evergreen.V266.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V266.Discord.Id Evergreen.V266.Discord.GuildId) (Result Evergreen.V266.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V266.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId) (List ( Evergreen.V266.Id.Id Evergreen.V266.Id.StickerId, Result Effect.Http.Error Evergreen.V266.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V266.Id.Id Evergreen.V266.Id.StickerId, Result Effect.Http.Error Evergreen.V266.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId) (List ( Evergreen.V266.Id.Id Evergreen.V266.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V266.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V266.Id.Id Evergreen.V266.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V266.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V266.Discord.HttpError (List Evergreen.V266.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V266.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V266.SecretId.SecretId Evergreen.V266.SecretId.ServerSecret))
    | GotTimeForWebsocketListenClose (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | GotCloudflareUsage Effect.Time.Posix (Result Effect.Http.Error Int)
    | GotCloudflareEgressForAdmin Effect.Lamdera.ClientId (Result Effect.Http.Error Int)
