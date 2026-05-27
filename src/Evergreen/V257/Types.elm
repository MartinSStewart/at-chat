module Evergreen.V257.Types exposing (..)

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
import Evergreen.V257.AiChat
import Evergreen.V257.Call
import Evergreen.V257.ChannelDescription
import Evergreen.V257.ChannelName
import Evergreen.V257.Cloudflare
import Evergreen.V257.Coord
import Evergreen.V257.CssPixels
import Evergreen.V257.CustomEmoji
import Evergreen.V257.Discord
import Evergreen.V257.DiscordAttachmentId
import Evergreen.V257.DiscordUserData
import Evergreen.V257.DmChannel
import Evergreen.V257.Editable
import Evergreen.V257.EmailAddress
import Evergreen.V257.Embed
import Evergreen.V257.Emoji
import Evergreen.V257.FileStatus
import Evergreen.V257.Go
import Evergreen.V257.GuildName
import Evergreen.V257.Id
import Evergreen.V257.ImageEditor
import Evergreen.V257.Local
import Evergreen.V257.LocalState
import Evergreen.V257.Log
import Evergreen.V257.LoginForm
import Evergreen.V257.MembersAndOwner
import Evergreen.V257.Message
import Evergreen.V257.MessageInput
import Evergreen.V257.MessageView
import Evergreen.V257.MyUi
import Evergreen.V257.NonemptyDict
import Evergreen.V257.NonemptySet
import Evergreen.V257.OneToOne
import Evergreen.V257.Pages.Admin
import Evergreen.V257.Pagination
import Evergreen.V257.PersonName
import Evergreen.V257.Ports
import Evergreen.V257.Postmark
import Evergreen.V257.Range
import Evergreen.V257.RichText
import Evergreen.V257.Route
import Evergreen.V257.SecretId
import Evergreen.V257.SessionIdHash
import Evergreen.V257.Slack
import Evergreen.V257.Sticker
import Evergreen.V257.TextEditor
import Evergreen.V257.ToBackendLog
import Evergreen.V257.Touch
import Evergreen.V257.TwoFactorAuthentication
import Evergreen.V257.Ui.Anim
import Evergreen.V257.Untrusted
import Evergreen.V257.User
import Evergreen.V257.UserAgent
import Evergreen.V257.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V257.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V257.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.Id.GuildId) Evergreen.V257.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId) Evergreen.V257.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V257.Discord.Id Evergreen.V257.Discord.PrivateChannelId) Evergreen.V257.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V257.Discord.Id Evergreen.V257.Discord.GuildId) Evergreen.V257.LocalState.DiscordFrontendGuild
    , user : Evergreen.V257.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId) Evergreen.V257.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId) Evergreen.V257.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId) Evergreen.V257.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V257.SessionIdHash.SessionIdHash Evergreen.V257.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V257.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.Id.StickerId) Evergreen.V257.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.Id.CustomEmojiId) Evergreen.V257.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V257.Call.CallId (Evergreen.V257.NonemptySet.NonemptySet ( Evergreen.V257.Id.Id Evergreen.V257.Id.UserId, Effect.Lamdera.ClientId ))
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type PublicGoMatch
    = PublicGoMatch_NotLoaded
    | PublicGoMatch_Loading
    | PublicGoMatch_Loaded Evergreen.V257.Go.PublicGoMatchData Evergreen.V257.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V257.Route.Route
    , windowSize : Evergreen.V257.Coord.Coord Evergreen.V257.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V257.Ports.NotificationPermission
    , pwaStatus : Evergreen.V257.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V257.UserAgent.UserAgent
    , publicGoMatch : PublicGoMatch
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V257.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V257.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V257.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.FileStatus.FileId) Evergreen.V257.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V257.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V257.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.FileStatus.FileId) Evergreen.V257.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V257.Id.Id Evergreen.V257.Id.GuildId) Evergreen.V257.ChannelName.ChannelName Evergreen.V257.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V257.Id.Id Evergreen.V257.Id.GuildId) (Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelId) Evergreen.V257.ChannelName.ChannelName Evergreen.V257.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V257.Id.Id Evergreen.V257.Id.GuildId) (Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelId)
    | Local_DeleteGuild (Evergreen.V257.Id.Id Evergreen.V257.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V257.Id.Id Evergreen.V257.Id.GuildId) (Evergreen.V257.UserSession.ToBeFilledInByBackend (Evergreen.V257.SecretId.SecretId Evergreen.V257.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V257.Id.Id Evergreen.V257.Id.GuildId) (Evergreen.V257.SecretId.SecretId Evergreen.V257.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V257.GuildName.GuildName (Evergreen.V257.UserSession.ToBeFilledInByBackend (Evergreen.V257.Id.Id Evergreen.V257.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V257.Id.AnyGuildOrDmId, Evergreen.V257.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V257.Id.AnyGuildOrDmId Evergreen.V257.Id.ThreadRouteWithMessage Evergreen.V257.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V257.Id.AnyGuildOrDmId Evergreen.V257.Id.ThreadRouteWithMessage Evergreen.V257.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V257.Id.GuildOrDmId Evergreen.V257.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.FileStatus.FileId) Evergreen.V257.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId) (Evergreen.V257.Discord.Id Evergreen.V257.Discord.GuildId) (Evergreen.V257.Discord.Id Evergreen.V257.Discord.ChannelId) Evergreen.V257.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V257.Id.DiscordGuildOrDmId_DmData (Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V257.Id.AnyGuildOrDmId Evergreen.V257.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V257.Id.AnyGuildOrDmId Evergreen.V257.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V257.Id.AnyGuildOrDmId Evergreen.V257.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V257.UserSession.SetViewing
    | Local_SetName Evergreen.V257.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V257.Id.GuildOrDmId (Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelMessageId) (Evergreen.V257.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelMessageId) (Evergreen.V257.Message.Message Evergreen.V257.Id.ChannelMessageId (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V257.Id.GuildOrDmId (Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelMessageId) (Evergreen.V257.Id.Id Evergreen.V257.Id.ThreadMessageId) (Evergreen.V257.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.Id.ThreadMessageId) (Evergreen.V257.Message.Message Evergreen.V257.Id.ThreadMessageId (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V257.Id.DiscordGuildOrDmId (Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelMessageId) (Evergreen.V257.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelMessageId) (Evergreen.V257.Message.Message Evergreen.V257.Id.ChannelMessageId (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V257.Id.DiscordGuildOrDmId (Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelMessageId) (Evergreen.V257.Id.Id Evergreen.V257.Id.ThreadMessageId) (Evergreen.V257.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.Id.ThreadMessageId) (Evergreen.V257.Message.Message Evergreen.V257.Id.ThreadMessageId (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V257.Id.Id Evergreen.V257.Id.GuildId) Evergreen.V257.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId) (Evergreen.V257.Discord.Id Evergreen.V257.Discord.GuildId) Evergreen.V257.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V257.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V257.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V257.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V257.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V257.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V257.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V257.NonemptySet.NonemptySet (Evergreen.V257.Id.Id Evergreen.V257.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V257.Call.LocalChange
    | Local_Go
        { otherUserId : Evergreen.V257.Id.Id Evergreen.V257.Id.UserId
        }
        Evergreen.V257.Go.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId) Effect.Time.Posix Evergreen.V257.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V257.RichText.RichText (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId))) Evergreen.V257.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.FileStatus.FileId) Evergreen.V257.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.Id.StickerId) Evergreen.V257.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V257.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V257.RichText.RichText (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId))) Evergreen.V257.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.FileStatus.FileId) Evergreen.V257.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.Id.StickerId) Evergreen.V257.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V257.Id.Id Evergreen.V257.Id.GuildId) Evergreen.V257.ChannelName.ChannelName Evergreen.V257.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V257.Id.Id Evergreen.V257.Id.GuildId) (Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelId) Evergreen.V257.ChannelName.ChannelName Evergreen.V257.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V257.Id.Id Evergreen.V257.Id.GuildId) (Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelId)
    | Server_DeleteGuild (Evergreen.V257.Id.Id Evergreen.V257.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId) (Evergreen.V257.Id.Id Evergreen.V257.Id.GuildId) (Evergreen.V257.SecretId.SecretId Evergreen.V257.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V257.Id.Id Evergreen.V257.Id.GuildId) (Evergreen.V257.SecretId.SecretId Evergreen.V257.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId) (Evergreen.V257.Id.Id Evergreen.V257.Id.GuildId) Evergreen.V257.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V257.LocalState.JoinGuildError
            { guildId : Evergreen.V257.Id.Id Evergreen.V257.Id.GuildId
            , guild : Evergreen.V257.LocalState.FrontendGuild
            , owner : Evergreen.V257.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId) Evergreen.V257.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId) Evergreen.V257.Id.GuildOrDmId Evergreen.V257.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId) (Evergreen.V257.Discord.Id Evergreen.V257.Discord.GuildId) (Evergreen.V257.Discord.Id Evergreen.V257.Discord.ChannelId) Evergreen.V257.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId) (Evergreen.V257.Discord.Id Evergreen.V257.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId) Evergreen.V257.Id.GuildOrDmId Evergreen.V257.Id.ThreadRouteWithMessage Evergreen.V257.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId) Evergreen.V257.Id.GuildOrDmId Evergreen.V257.Id.ThreadRouteWithMessage Evergreen.V257.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId) (Evergreen.V257.Discord.Id Evergreen.V257.Discord.GuildId) (Evergreen.V257.Discord.Id Evergreen.V257.Discord.ChannelId) Evergreen.V257.Id.ThreadRouteWithMessage Evergreen.V257.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId) (Evergreen.V257.Discord.Id Evergreen.V257.Discord.PrivateChannelId) (Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelMessageId) Evergreen.V257.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId) (Evergreen.V257.Discord.Id Evergreen.V257.Discord.GuildId) (Evergreen.V257.Discord.Id Evergreen.V257.Discord.ChannelId) Evergreen.V257.Id.ThreadRouteWithMessage Evergreen.V257.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId) (Evergreen.V257.Discord.Id Evergreen.V257.Discord.PrivateChannelId) (Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelMessageId) Evergreen.V257.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId) Evergreen.V257.Id.GuildOrDmId Evergreen.V257.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V257.RichText.RichText (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId))) (SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.FileStatus.FileId) Evergreen.V257.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId) (Evergreen.V257.Discord.Id Evergreen.V257.Discord.GuildId) (Evergreen.V257.Discord.Id Evergreen.V257.Discord.ChannelId) Evergreen.V257.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V257.RichText.RichText (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V257.Id.DiscordGuildOrDmId_DmData (Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V257.RichText.RichText (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId) Evergreen.V257.Id.AnyGuildOrDmId Evergreen.V257.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V257.Id.AnyGuildOrDmId Evergreen.V257.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V257.Discord.Id Evergreen.V257.Discord.GuildId) (Evergreen.V257.Discord.Id Evergreen.V257.Discord.ChannelId) Evergreen.V257.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V257.Discord.Id Evergreen.V257.Discord.PrivateChannelId) (Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId) Evergreen.V257.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId) Evergreen.V257.FileStatus.FileHash
    | Server_SetGuildIcon (Evergreen.V257.Id.Id Evergreen.V257.Id.GuildId) Evergreen.V257.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V257.Id.Id Evergreen.V257.Id.GuildId) Evergreen.V257.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V257.Discord.Id Evergreen.V257.Discord.GuildId) Evergreen.V257.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V257.SessionIdHash.SessionIdHash Evergreen.V257.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V257.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V257.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V257.Id.AnyGuildOrDmId, Evergreen.V257.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V257.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId) Evergreen.V257.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V257.Discord.Id Evergreen.V257.Discord.GuildId) (Evergreen.V257.Discord.Id Evergreen.V257.Discord.ChannelId) Evergreen.V257.ChannelName.ChannelName (Evergreen.V257.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V257.Discord.Id Evergreen.V257.Discord.PrivateChannelId)
        (Evergreen.V257.NonemptyDict.NonemptyDict
            (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V257.Discord.Id Evergreen.V257.Discord.GuildId) Evergreen.V257.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V257.Discord.Id Evergreen.V257.Discord.PrivateChannelId) Evergreen.V257.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId) Evergreen.V257.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId) (Maybe (Evergreen.V257.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V257.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V257.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V257.Id.Id Evergreen.V257.Id.GuildId) (Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelId) Evergreen.V257.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V257.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId) Evergreen.V257.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V257.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V257.Discord.Id Evergreen.V257.Discord.GuildId) (Evergreen.V257.Discord.Id Evergreen.V257.Discord.ChannelId) Evergreen.V257.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V257.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V257.Discord.Id Evergreen.V257.Discord.PrivateChannelId) (Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V257.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V257.Discord.Id Evergreen.V257.Discord.GuildId) Evergreen.V257.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V257.Discord.Id Evergreen.V257.Discord.GuildId) (Evergreen.V257.Discord.Id Evergreen.V257.Discord.ChannelId) (Evergreen.V257.Discord.OptionalData String) (Evergreen.V257.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V257.Discord.Id Evergreen.V257.Discord.GuildId)
        (Evergreen.V257.MembersAndOwner.MembersAndOwner
            (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V257.Discord.Id Evergreen.V257.Discord.GuildId) (Evergreen.V257.Discord.Id Evergreen.V257.Discord.ChannelId) (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId) Evergreen.V257.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.Id.StickerId) Evergreen.V257.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.Id.CustomEmojiId) Evergreen.V257.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V257.Call.ServerChange
    | Server_Go
        (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId)
        { otherUserId : Evergreen.V257.Id.Id Evergreen.V257.Id.UserId
        }
        Evergreen.V257.Go.LocalChange


type LocalMsg
    = LocalChange (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V257.Id.Id Evergreen.V257.Id.GuildId) (Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelId) Evergreen.V257.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V257.Discord.Id Evergreen.V257.Discord.GuildId) (Evergreen.V257.Discord.Id Evergreen.V257.Discord.ChannelId) Evergreen.V257.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.FileStatus.FileId) Evergreen.V257.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V257.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V257.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V257.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V257.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V257.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V257.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V257.Coord.Coord Evergreen.V257.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V257.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V257.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V257.Id.AnyGuildOrDmId Evergreen.V257.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V257.Id.AnyGuildOrDmId Evergreen.V257.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V257.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V257.Coord.Coord Evergreen.V257.CssPixels.CssPixels) (Maybe Evergreen.V257.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V257.Id.AnyGuildOrDmId, Evergreen.V257.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelMessageId) (Evergreen.V257.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.Id.ThreadMessageId) (Evergreen.V257.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V257.Editable.Model
    , showLinkDiscordSetup : Bool
    , domainWhitelistInput : String
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V257.Local.Local LocalMsg Evergreen.V257.LocalState.LocalState
    , admin : Evergreen.V257.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V257.Id.AnyGuildOrDmId, Evergreen.V257.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V257.Id.Id Evergreen.V257.Id.GuildId, Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V257.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V257.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V257.Id.AnyGuildOrDmId, Evergreen.V257.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V257.Id.AnyGuildOrDmId, Evergreen.V257.Id.ThreadRoute ) (Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : Evergreen.V257.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V257.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V257.Id.AnyGuildOrDmId, Evergreen.V257.Id.ThreadRoute ) (Evergreen.V257.NonemptyDict.NonemptyDict (Evergreen.V257.Id.Id Evergreen.V257.FileStatus.FileId) Evergreen.V257.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V257.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V257.TextEditor.Model
    , profilePictureEditor : Evergreen.V257.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V257.Id.Id Evergreen.V257.Id.GuildId, Evergreen.V257.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V257.Emoji.Model
    , voiceChat : Evergreen.V257.Call.Model
    , currentDmGoMatch : SeqDict.SeqDict ( Evergreen.V257.Id.Id Evergreen.V257.Id.UserId, Maybe (Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelMessageId) ) Evergreen.V257.Go.Model
    , fileDragOverCount : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V257.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V257.SecretId.SecretId Evergreen.V257.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V257.Range.Range
                , direction : Evergreen.V257.Range.SelectionDirection
                }
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V257.NonemptyDict.NonemptyDict Int Evergreen.V257.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V257.NonemptyDict.NonemptyDict Int Evergreen.V257.Touch.Touch
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
    | AdminToFrontend Evergreen.V257.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V257.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V257.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V257.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V257.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V257.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V257.Go.PublicGoMatchData)


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V257.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V257.Coord.Coord Evergreen.V257.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V257.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V257.MyUi.LastCopy
    , notificationPermission : Evergreen.V257.Ports.NotificationPermission
    , pwaStatus : Evergreen.V257.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V257.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V257.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V257.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V257.Id.Id Evergreen.V257.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V257.Id.Id Evergreen.V257.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V257.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V257.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V257.Coord.Coord Evergreen.V257.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V257.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V257.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V257.Id.Id Evergreen.V257.Id.GuildId, Evergreen.V257.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V257.DmChannel.DmChannelId, Evergreen.V257.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V257.Discord.Id Evergreen.V257.Discord.GuildId, Evergreen.V257.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V257.Discord.Id Evergreen.V257.Discord.PrivateChannelId, Evergreen.V257.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V257.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V257.NonemptyDict.NonemptyDict (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId) Evergreen.V257.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V257.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V257.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V257.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V257.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId) Evergreen.V257.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId) Evergreen.V257.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V257.Id.Id Evergreen.V257.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.Id.GuildId) Evergreen.V257.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.Id.GuildId) Evergreen.V257.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V257.Discord.Id Evergreen.V257.Discord.GuildId) Evergreen.V257.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V257.DmChannel.DmChannelId Evergreen.V257.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V257.Discord.Id Evergreen.V257.Discord.PrivateChannelId) Evergreen.V257.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V257.OneToOne.OneToOne (Evergreen.V257.Slack.Id Evergreen.V257.Slack.ChannelId) Evergreen.V257.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V257.OneToOne.OneToOne String (Evergreen.V257.Id.Id Evergreen.V257.Id.GuildId)
    , slackUsers : Evergreen.V257.OneToOne.OneToOne (Evergreen.V257.Slack.Id Evergreen.V257.Slack.UserId) (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId)
    , slackServers : Evergreen.V257.OneToOne.OneToOne (Evergreen.V257.Slack.Id Evergreen.V257.Slack.TeamId) (Evergreen.V257.Id.Id Evergreen.V257.Id.GuildId)
    , slackToken : Maybe Evergreen.V257.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V257.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V257.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V257.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V257.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V257.Cloudflare.AppId
    , textEditor : Evergreen.V257.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId) Evergreen.V257.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId, Evergreen.V257.Discord.Id Evergreen.V257.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V257.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V257.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V257.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V257.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId) (Evergreen.V257.LocalState.LoadingDiscordChannel (List Evergreen.V257.Discord.Message))
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V257.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.Id.StickerId) Evergreen.V257.Sticker.StickerData
    , discordStickers : Evergreen.V257.OneToOne.OneToOne (Evergreen.V257.Discord.Id Evergreen.V257.Discord.StickerId) (Evergreen.V257.Id.Id Evergreen.V257.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.Id.CustomEmojiId) Evergreen.V257.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V257.OneToOne.OneToOne Evergreen.V257.RichText.DiscordCustomEmojiIdAndName (Evergreen.V257.Id.Id Evergreen.V257.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V257.Postmark.ApiKey
    , serverSecret : Evergreen.V257.SecretId.SecretId Evergreen.V257.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V257.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V257.OneToOne.OneToOne (Evergreen.V257.SecretId.SecretId Evergreen.V257.Id.GoMatchPublicId) ( Evergreen.V257.DmChannel.DmChannelId, Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelMessageId )
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V257.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V257.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V257.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V257.Route.Route
    | SelectedFilesToAttach ( Evergreen.V257.Id.AnyGuildOrDmId, Evergreen.V257.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V257.Id.Id Evergreen.V257.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V257.Id.Id Evergreen.V257.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V257.Id.Id Evergreen.V257.Id.GuildId) (Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelId) Evergreen.V257.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V257.Id.Id Evergreen.V257.Id.GuildId) (Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelId) Evergreen.V257.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V257.Discord.Id Evergreen.V257.Discord.GuildId) (Evergreen.V257.Discord.Id Evergreen.V257.Discord.ChannelId) Evergreen.V257.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V257.Discord.Id Evergreen.V257.Discord.GuildId) (Evergreen.V257.Discord.Id Evergreen.V257.Discord.ChannelId) Evergreen.V257.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V257.Id.Id Evergreen.V257.Id.GuildId) (Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V257.Id.Id Evergreen.V257.Id.GuildId) (Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V257.Id.Id Evergreen.V257.Id.GuildId) (Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V257.Id.Id Evergreen.V257.Id.GuildId) (Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V257.Id.Id Evergreen.V257.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V257.Id.Id Evergreen.V257.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V257.Id.Id Evergreen.V257.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V257.Id.Id Evergreen.V257.Id.GuildId) (Evergreen.V257.SecretId.SecretId Evergreen.V257.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V257.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V257.Id.AnyGuildOrDmId Evergreen.V257.Id.ThreadRouteWithMessage (Evergreen.V257.Coord.Coord Evergreen.V257.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V257.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V257.Id.AnyGuildOrDmId Evergreen.V257.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V257.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V257.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V257.Id.AnyGuildOrDmId, Evergreen.V257.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V257.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V257.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V257.Id.AnyGuildOrDmId, Evergreen.V257.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V257.NonemptyDict.NonemptyDict Int Evergreen.V257.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V257.NonemptyDict.NonemptyDict Int Evergreen.V257.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V257.Id.AnyGuildOrDmId Evergreen.V257.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V257.Id.AnyGuildOrDmId Evergreen.V257.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V257.NonemptySet.NonemptySet (Evergreen.V257.Id.Id Evergreen.V257.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V257.Id.AnyGuildOrDmId, Evergreen.V257.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V257.Id.AnyGuildOrDmId Evergreen.V257.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V257.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V257.AiChat.Msg
    | GoMsg Evergreen.V257.Go.Msg
    | GoSpectatorMsg Evergreen.V257.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V257.Editable.Msg Evergreen.V257.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V257.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V257.Id.Id Evergreen.V257.Id.GuildId) Evergreen.V257.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V257.Id.AnyGuildOrDmId, Evergreen.V257.Id.ThreadRoute ) (Evergreen.V257.Id.Id Evergreen.V257.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V257.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V257.Id.AnyGuildOrDmId, Evergreen.V257.Id.ThreadRoute ) (Evergreen.V257.Id.Id Evergreen.V257.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V257.Id.AnyGuildOrDmId, Evergreen.V257.Id.ThreadRoute ) (Evergreen.V257.Id.Id Evergreen.V257.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V257.Id.AnyGuildOrDmId, Evergreen.V257.Id.ThreadRoute )
        { fileId : Evergreen.V257.Id.Id Evergreen.V257.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V257.Id.AnyGuildOrDmId, Evergreen.V257.Id.ThreadRoute ) (Evergreen.V257.Id.Id Evergreen.V257.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V257.Id.AnyGuildOrDmId, Evergreen.V257.Id.ThreadRoute ) (Evergreen.V257.Id.Id Evergreen.V257.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V257.Id.AnyGuildOrDmId, Evergreen.V257.Id.ThreadRoute )
        { fileId : Evergreen.V257.Id.Id Evergreen.V257.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V257.Id.AnyGuildOrDmId, Evergreen.V257.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V257.Id.AnyGuildOrDmId, Evergreen.V257.Id.ThreadRoute ) (Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelMessageId) (Evergreen.V257.Id.Id Evergreen.V257.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V257.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V257.Id.AnyGuildOrDmId, Evergreen.V257.Id.ThreadRoute ) (Evergreen.V257.Id.Id Evergreen.V257.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V257.Id.AnyGuildOrDmId Evergreen.V257.Id.ThreadRouteWithMessage Evergreen.V257.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V257.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V257.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V257.Id.Id Evergreen.V257.Id.GuildId) Evergreen.V257.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId) (Evergreen.V257.Discord.Id Evergreen.V257.Discord.GuildId) Evergreen.V257.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V257.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V257.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId
        , otherUserId : Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V257.Id.AnyGuildOrDmId Evergreen.V257.Id.ThreadRoute Evergreen.V257.MessageInput.Msg
    | MessageInputMsg Evergreen.V257.Id.AnyGuildOrDmId Evergreen.V257.Id.ThreadRoute Evergreen.V257.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V257.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V257.Range.Range, Evergreen.V257.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V257.Range.Range, Evergreen.V257.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V257.Call.FromJs)
    | VoiceChatMsg Evergreen.V257.Call.Msg
    | PressedChannelHeaderTab Evergreen.V257.Route.DmChannelHeaderTab
    | FileDragEnter
    | FileDragLeave
    | FileDropped (List Effect.File.File)


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V257.Id.Id Evergreen.V257.Id.GuildId) (Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelId) Evergreen.V257.Id.ThreadRoute
    | InitialLoadRequested_Dm Evergreen.V257.DmChannel.DmChannelId Evergreen.V257.Id.ThreadRoute
    | InitialLoadRequested_Discord Evergreen.V257.Id.DiscordGuildOrDmId Evergreen.V257.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V257.Id.Id Evergreen.V257.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V257.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V257.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V257.Untrusted.Untrusted Evergreen.V257.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V257.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V257.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V257.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V257.Id.Id Evergreen.V257.Id.GuildId) (Evergreen.V257.SecretId.SecretId Evergreen.V257.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V257.PersonName.PersonName Evergreen.V257.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V257.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V257.Slack.OAuthCode Evergreen.V257.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V257.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V257.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V257.Id.Id Evergreen.V257.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V257.SecretId.SecretId Evergreen.V257.Id.GoMatchPublicId)


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V257.Discord.Id Evergreen.V257.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V257.Discord.Id Evergreen.V257.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V257.EmailAddress.EmailAddress (Result Evergreen.V257.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V257.EmailAddress.EmailAddress (Result Evergreen.V257.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V257.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V257.Discord.Id Evergreen.V257.Discord.GuildId) (Evergreen.V257.Discord.Id Evergreen.V257.Discord.ChannelId) Evergreen.V257.Id.ThreadRouteWithMaybeMessage (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId) (Result Evergreen.V257.Discord.HttpError Evergreen.V257.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V257.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V257.Discord.Id Evergreen.V257.Discord.PrivateChannelId) (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId) (Result Evergreen.V257.Discord.HttpError Evergreen.V257.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V257.Discord.Id Evergreen.V257.Discord.GuildId) (Evergreen.V257.Discord.Id Evergreen.V257.Discord.ChannelId) Evergreen.V257.Id.ThreadRouteWithMessage (Evergreen.V257.Discord.Id Evergreen.V257.Discord.MessageId) (Result Evergreen.V257.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V257.Discord.Id Evergreen.V257.Discord.PrivateChannelId) (Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelMessageId) (Evergreen.V257.Discord.Id Evergreen.V257.Discord.MessageId) (Result Evergreen.V257.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V257.Discord.Id Evergreen.V257.Discord.GuildId) (Evergreen.V257.Discord.Id Evergreen.V257.Discord.ChannelId) Evergreen.V257.Id.ThreadRouteWithMessage (Evergreen.V257.Discord.Id Evergreen.V257.Discord.MessageId) (Result Evergreen.V257.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V257.Discord.Id Evergreen.V257.Discord.PrivateChannelId) (Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelMessageId) (Evergreen.V257.Discord.Id Evergreen.V257.Discord.MessageId) (Result Evergreen.V257.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V257.Discord.Id Evergreen.V257.Discord.GuildId) (Evergreen.V257.Discord.Id Evergreen.V257.Discord.ChannelId) Evergreen.V257.Id.ThreadRouteWithMessage (Evergreen.V257.Discord.Id Evergreen.V257.Discord.MessageId) Evergreen.V257.Emoji.EmojiOrCustomEmoji (Result Evergreen.V257.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V257.Discord.Id Evergreen.V257.Discord.PrivateChannelId) (Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelMessageId) (Evergreen.V257.Discord.Id Evergreen.V257.Discord.MessageId) Evergreen.V257.Emoji.EmojiOrCustomEmoji (Result Evergreen.V257.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V257.Discord.Id Evergreen.V257.Discord.GuildId) (Evergreen.V257.Discord.Id Evergreen.V257.Discord.ChannelId) Evergreen.V257.Id.ThreadRouteWithMessage (Evergreen.V257.Discord.Id Evergreen.V257.Discord.MessageId) Evergreen.V257.Emoji.EmojiOrCustomEmoji (Result Evergreen.V257.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V257.Discord.Id Evergreen.V257.Discord.PrivateChannelId) (Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelMessageId) (Evergreen.V257.Discord.Id Evergreen.V257.Discord.MessageId) Evergreen.V257.Emoji.EmojiOrCustomEmoji (Result Evergreen.V257.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V257.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V257.Discord.HttpError (List ( Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId, Maybe Evergreen.V257.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V257.Slack.CurrentUser
            , team : Evergreen.V257.Slack.Team
            , users : List Evergreen.V257.Slack.User
            , channels : List ( Evergreen.V257.Slack.Channel, List Evergreen.V257.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId) (Result Effect.Http.Error Evergreen.V257.Slack.TokenResponse)
    | GotCloudflareSessionCreated Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V257.Local.ChangeId Effect.Time.Posix Evergreen.V257.Call.CallId Evergreen.V257.Cloudflare.Sdp (List String) (Result Effect.Http.Error Evergreen.V257.Cloudflare.RealtimeSessionId)
    | GotCloudflareSession Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V257.Local.ChangeId Effect.Time.Posix Evergreen.V257.Call.CallId Evergreen.V257.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V257.Cloudflare.PushTracksResult)
    | GotCloudflarePullOffer Effect.Time.Posix Effect.Lamdera.ClientId Evergreen.V257.Local.ChangeId Evergreen.V257.Call.ConnectionId Evergreen.V257.Cloudflare.RealtimeSessionId (List Evergreen.V257.Cloudflare.TrackName) (Result Effect.Http.Error Evergreen.V257.Cloudflare.PullTracksResult)
    | GotCloudflareRenegotiateAck Effect.Lamdera.ClientId Evergreen.V257.Local.ChangeId Evergreen.V257.Cloudflare.Sdp (Result Effect.Http.Error ())
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId) Evergreen.V257.Discord.UserAuth (Result Evergreen.V257.Discord.HttpError Evergreen.V257.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId) (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId) (Result Evergreen.V257.Discord.HttpError Evergreen.V257.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId)
        (Result
            Evergreen.V257.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V257.Discord.Id Evergreen.V257.Discord.PrivateChannelId
                , members : List (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId)
                }
            , List
                ( Evergreen.V257.Discord.Id Evergreen.V257.Discord.GuildId
                , { guild : Evergreen.V257.Discord.GatewayGuild
                  , channels : List Evergreen.V257.Discord.Channel
                  , icon : Maybe Evergreen.V257.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId) Bool Evergreen.V257.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V257.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V257.Discord.Id Evergreen.V257.Discord.AttachmentId, Evergreen.V257.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V257.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V257.Discord.Id Evergreen.V257.Discord.AttachmentId, Evergreen.V257.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId) (Evergreen.V257.Discord.Id Evergreen.V257.Discord.GuildId) (Evergreen.V257.Discord.Id Evergreen.V257.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V257.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V257.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId) (Evergreen.V257.Discord.Id Evergreen.V257.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V257.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V257.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId) (Evergreen.V257.Discord.Id Evergreen.V257.Discord.GuildId) (Evergreen.V257.Discord.Id Evergreen.V257.Discord.ChannelId) (Result Evergreen.V257.Discord.HttpError (List Evergreen.V257.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId) (Evergreen.V257.Discord.Id Evergreen.V257.Discord.PrivateChannelId) (Result Evergreen.V257.Discord.HttpError (List Evergreen.V257.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V257.Id.Id Evergreen.V257.Id.GuildId) (Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelId) Evergreen.V257.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V257.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V257.DmChannel.DmChannelId Evergreen.V257.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V257.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V257.Discord.Id Evergreen.V257.Discord.GuildId) (Evergreen.V257.Discord.Id Evergreen.V257.Discord.ChannelId) Evergreen.V257.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V257.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V257.Discord.Id Evergreen.V257.Discord.PrivateChannelId) (Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V257.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId)
        (Evergreen.V257.Discord.Id Evergreen.V257.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V257.Discord.HttpError
            { guild : Evergreen.V257.Discord.GatewayGuild
            , channels : List Evergreen.V257.Discord.Channel
            , icon : Maybe Evergreen.V257.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V257.Discord.Id Evergreen.V257.Discord.GuildId) (Result Evergreen.V257.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V257.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId) (List ( Evergreen.V257.Id.Id Evergreen.V257.Id.StickerId, Result Effect.Http.Error Evergreen.V257.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V257.Id.Id Evergreen.V257.Id.StickerId, Result Effect.Http.Error Evergreen.V257.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId) (List ( Evergreen.V257.Id.Id Evergreen.V257.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V257.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V257.Id.Id Evergreen.V257.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V257.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V257.Discord.HttpError (List Evergreen.V257.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V257.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V257.SecretId.SecretId Evergreen.V257.SecretId.ServerSecret))
    | GotTimeForWebsocketListenClose (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
