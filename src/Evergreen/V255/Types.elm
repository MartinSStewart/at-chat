module Evergreen.V255.Types exposing (..)

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
import Evergreen.V255.AiChat
import Evergreen.V255.Call
import Evergreen.V255.ChannelDescription
import Evergreen.V255.ChannelName
import Evergreen.V255.Cloudflare
import Evergreen.V255.Coord
import Evergreen.V255.CssPixels
import Evergreen.V255.CustomEmoji
import Evergreen.V255.Discord
import Evergreen.V255.DiscordAttachmentId
import Evergreen.V255.DiscordUserData
import Evergreen.V255.DmChannel
import Evergreen.V255.Editable
import Evergreen.V255.EmailAddress
import Evergreen.V255.Embed
import Evergreen.V255.Emoji
import Evergreen.V255.FileStatus
import Evergreen.V255.Go
import Evergreen.V255.GuildName
import Evergreen.V255.Id
import Evergreen.V255.ImageEditor
import Evergreen.V255.Local
import Evergreen.V255.LocalState
import Evergreen.V255.Log
import Evergreen.V255.LoginForm
import Evergreen.V255.MembersAndOwner
import Evergreen.V255.Message
import Evergreen.V255.MessageInput
import Evergreen.V255.MessageView
import Evergreen.V255.MyUi
import Evergreen.V255.NonemptyDict
import Evergreen.V255.NonemptySet
import Evergreen.V255.OneToOne
import Evergreen.V255.Pages.Admin
import Evergreen.V255.Pagination
import Evergreen.V255.PersonName
import Evergreen.V255.Ports
import Evergreen.V255.Postmark
import Evergreen.V255.Range
import Evergreen.V255.RichText
import Evergreen.V255.Route
import Evergreen.V255.SecretId
import Evergreen.V255.SessionIdHash
import Evergreen.V255.Slack
import Evergreen.V255.Sticker
import Evergreen.V255.TextEditor
import Evergreen.V255.ToBackendLog
import Evergreen.V255.Touch
import Evergreen.V255.TwoFactorAuthentication
import Evergreen.V255.Ui.Anim
import Evergreen.V255.Untrusted
import Evergreen.V255.User
import Evergreen.V255.UserAgent
import Evergreen.V255.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V255.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V255.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.Id.GuildId) Evergreen.V255.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId) Evergreen.V255.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V255.Discord.Id Evergreen.V255.Discord.PrivateChannelId) Evergreen.V255.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V255.Discord.Id Evergreen.V255.Discord.GuildId) Evergreen.V255.LocalState.DiscordFrontendGuild
    , user : Evergreen.V255.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId) Evergreen.V255.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId) Evergreen.V255.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId) Evergreen.V255.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V255.SessionIdHash.SessionIdHash Evergreen.V255.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V255.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.Id.StickerId) Evergreen.V255.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.Id.CustomEmojiId) Evergreen.V255.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V255.Call.CallId (Evergreen.V255.NonemptySet.NonemptySet ( Evergreen.V255.Id.Id Evergreen.V255.Id.UserId, Effect.Lamdera.ClientId ))
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type PublicGoMatch
    = PublicGoMatch_NotLoaded
    | PublicGoMatch_Loading
    | PublicGoMatch_Loaded Evergreen.V255.Go.PublicGoMatchData Evergreen.V255.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V255.Route.Route
    , windowSize : Evergreen.V255.Coord.Coord Evergreen.V255.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V255.Ports.NotificationPermission
    , pwaStatus : Evergreen.V255.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V255.UserAgent.UserAgent
    , publicGoMatch : PublicGoMatch
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V255.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V255.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V255.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.FileStatus.FileId) Evergreen.V255.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V255.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V255.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.FileStatus.FileId) Evergreen.V255.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V255.Id.Id Evergreen.V255.Id.GuildId) Evergreen.V255.ChannelName.ChannelName Evergreen.V255.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V255.Id.Id Evergreen.V255.Id.GuildId) (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelId) Evergreen.V255.ChannelName.ChannelName Evergreen.V255.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V255.Id.Id Evergreen.V255.Id.GuildId) (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelId)
    | Local_DeleteGuild (Evergreen.V255.Id.Id Evergreen.V255.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V255.Id.Id Evergreen.V255.Id.GuildId) (Evergreen.V255.UserSession.ToBeFilledInByBackend (Evergreen.V255.SecretId.SecretId Evergreen.V255.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V255.Id.Id Evergreen.V255.Id.GuildId) (Evergreen.V255.SecretId.SecretId Evergreen.V255.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V255.GuildName.GuildName (Evergreen.V255.UserSession.ToBeFilledInByBackend (Evergreen.V255.Id.Id Evergreen.V255.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V255.Id.AnyGuildOrDmId, Evergreen.V255.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V255.Id.AnyGuildOrDmId Evergreen.V255.Id.ThreadRouteWithMessage Evergreen.V255.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V255.Id.AnyGuildOrDmId Evergreen.V255.Id.ThreadRouteWithMessage Evergreen.V255.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V255.Id.GuildOrDmId Evergreen.V255.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.FileStatus.FileId) Evergreen.V255.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId) (Evergreen.V255.Discord.Id Evergreen.V255.Discord.GuildId) (Evergreen.V255.Discord.Id Evergreen.V255.Discord.ChannelId) Evergreen.V255.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V255.Id.DiscordGuildOrDmId_DmData (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V255.Id.AnyGuildOrDmId Evergreen.V255.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V255.Id.AnyGuildOrDmId Evergreen.V255.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V255.Id.AnyGuildOrDmId Evergreen.V255.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V255.UserSession.SetViewing
    | Local_SetName Evergreen.V255.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V255.Id.GuildOrDmId (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelMessageId) (Evergreen.V255.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelMessageId) (Evergreen.V255.Message.Message Evergreen.V255.Id.ChannelMessageId (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V255.Id.GuildOrDmId (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelMessageId) (Evergreen.V255.Id.Id Evergreen.V255.Id.ThreadMessageId) (Evergreen.V255.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.Id.ThreadMessageId) (Evergreen.V255.Message.Message Evergreen.V255.Id.ThreadMessageId (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V255.Id.DiscordGuildOrDmId (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelMessageId) (Evergreen.V255.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelMessageId) (Evergreen.V255.Message.Message Evergreen.V255.Id.ChannelMessageId (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V255.Id.DiscordGuildOrDmId (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelMessageId) (Evergreen.V255.Id.Id Evergreen.V255.Id.ThreadMessageId) (Evergreen.V255.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.Id.ThreadMessageId) (Evergreen.V255.Message.Message Evergreen.V255.Id.ThreadMessageId (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V255.Id.Id Evergreen.V255.Id.GuildId) Evergreen.V255.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId) (Evergreen.V255.Discord.Id Evergreen.V255.Discord.GuildId) Evergreen.V255.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V255.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V255.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V255.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V255.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V255.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V255.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V255.NonemptySet.NonemptySet (Evergreen.V255.Id.Id Evergreen.V255.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V255.Call.LocalChange
    | Local_Go
        { otherUserId : Evergreen.V255.Id.Id Evergreen.V255.Id.UserId
        }
        Evergreen.V255.Go.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId) Effect.Time.Posix Evergreen.V255.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V255.RichText.RichText (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId))) Evergreen.V255.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.FileStatus.FileId) Evergreen.V255.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.Id.StickerId) Evergreen.V255.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V255.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V255.RichText.RichText (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId))) Evergreen.V255.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.FileStatus.FileId) Evergreen.V255.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.Id.StickerId) Evergreen.V255.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V255.Id.Id Evergreen.V255.Id.GuildId) Evergreen.V255.ChannelName.ChannelName Evergreen.V255.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V255.Id.Id Evergreen.V255.Id.GuildId) (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelId) Evergreen.V255.ChannelName.ChannelName Evergreen.V255.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V255.Id.Id Evergreen.V255.Id.GuildId) (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelId)
    | Server_DeleteGuild (Evergreen.V255.Id.Id Evergreen.V255.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId) (Evergreen.V255.Id.Id Evergreen.V255.Id.GuildId) (Evergreen.V255.SecretId.SecretId Evergreen.V255.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V255.Id.Id Evergreen.V255.Id.GuildId) (Evergreen.V255.SecretId.SecretId Evergreen.V255.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId) (Evergreen.V255.Id.Id Evergreen.V255.Id.GuildId) Evergreen.V255.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V255.LocalState.JoinGuildError
            { guildId : Evergreen.V255.Id.Id Evergreen.V255.Id.GuildId
            , guild : Evergreen.V255.LocalState.FrontendGuild
            , owner : Evergreen.V255.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId) Evergreen.V255.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId) Evergreen.V255.Id.GuildOrDmId Evergreen.V255.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId) (Evergreen.V255.Discord.Id Evergreen.V255.Discord.GuildId) (Evergreen.V255.Discord.Id Evergreen.V255.Discord.ChannelId) Evergreen.V255.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId) (Evergreen.V255.Discord.Id Evergreen.V255.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId) Evergreen.V255.Id.GuildOrDmId Evergreen.V255.Id.ThreadRouteWithMessage Evergreen.V255.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId) Evergreen.V255.Id.GuildOrDmId Evergreen.V255.Id.ThreadRouteWithMessage Evergreen.V255.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId) (Evergreen.V255.Discord.Id Evergreen.V255.Discord.GuildId) (Evergreen.V255.Discord.Id Evergreen.V255.Discord.ChannelId) Evergreen.V255.Id.ThreadRouteWithMessage Evergreen.V255.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId) (Evergreen.V255.Discord.Id Evergreen.V255.Discord.PrivateChannelId) (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelMessageId) Evergreen.V255.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId) (Evergreen.V255.Discord.Id Evergreen.V255.Discord.GuildId) (Evergreen.V255.Discord.Id Evergreen.V255.Discord.ChannelId) Evergreen.V255.Id.ThreadRouteWithMessage Evergreen.V255.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId) (Evergreen.V255.Discord.Id Evergreen.V255.Discord.PrivateChannelId) (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelMessageId) Evergreen.V255.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId) Evergreen.V255.Id.GuildOrDmId Evergreen.V255.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V255.RichText.RichText (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId))) (SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.FileStatus.FileId) Evergreen.V255.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId) (Evergreen.V255.Discord.Id Evergreen.V255.Discord.GuildId) (Evergreen.V255.Discord.Id Evergreen.V255.Discord.ChannelId) Evergreen.V255.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V255.RichText.RichText (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V255.Id.DiscordGuildOrDmId_DmData (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V255.RichText.RichText (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId) Evergreen.V255.Id.AnyGuildOrDmId Evergreen.V255.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V255.Id.AnyGuildOrDmId Evergreen.V255.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V255.Discord.Id Evergreen.V255.Discord.GuildId) (Evergreen.V255.Discord.Id Evergreen.V255.Discord.ChannelId) Evergreen.V255.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V255.Discord.Id Evergreen.V255.Discord.PrivateChannelId) (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId) Evergreen.V255.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId) Evergreen.V255.FileStatus.FileHash
    | Server_SetGuildIcon (Evergreen.V255.Id.Id Evergreen.V255.Id.GuildId) Evergreen.V255.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V255.Id.Id Evergreen.V255.Id.GuildId) Evergreen.V255.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V255.Discord.Id Evergreen.V255.Discord.GuildId) Evergreen.V255.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V255.SessionIdHash.SessionIdHash Evergreen.V255.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V255.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V255.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V255.Id.AnyGuildOrDmId, Evergreen.V255.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V255.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId) Evergreen.V255.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V255.Discord.Id Evergreen.V255.Discord.GuildId) (Evergreen.V255.Discord.Id Evergreen.V255.Discord.ChannelId) Evergreen.V255.ChannelName.ChannelName (Evergreen.V255.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V255.Discord.Id Evergreen.V255.Discord.PrivateChannelId)
        (Evergreen.V255.NonemptyDict.NonemptyDict
            (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V255.Discord.Id Evergreen.V255.Discord.GuildId) Evergreen.V255.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V255.Discord.Id Evergreen.V255.Discord.PrivateChannelId) Evergreen.V255.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId) Evergreen.V255.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId) (Maybe (Evergreen.V255.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V255.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V255.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V255.Id.Id Evergreen.V255.Id.GuildId) (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelId) Evergreen.V255.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V255.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId) Evergreen.V255.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V255.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V255.Discord.Id Evergreen.V255.Discord.GuildId) (Evergreen.V255.Discord.Id Evergreen.V255.Discord.ChannelId) Evergreen.V255.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V255.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V255.Discord.Id Evergreen.V255.Discord.PrivateChannelId) (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V255.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V255.Discord.Id Evergreen.V255.Discord.GuildId) Evergreen.V255.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V255.Discord.Id Evergreen.V255.Discord.GuildId) (Evergreen.V255.Discord.Id Evergreen.V255.Discord.ChannelId) (Evergreen.V255.Discord.OptionalData String) (Evergreen.V255.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V255.Discord.Id Evergreen.V255.Discord.GuildId)
        (Evergreen.V255.MembersAndOwner.MembersAndOwner
            (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V255.Discord.Id Evergreen.V255.Discord.GuildId) (Evergreen.V255.Discord.Id Evergreen.V255.Discord.ChannelId) (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId) Evergreen.V255.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.Id.StickerId) Evergreen.V255.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.Id.CustomEmojiId) Evergreen.V255.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V255.Call.ServerChange
    | Server_Go
        (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId)
        { otherUserId : Evergreen.V255.Id.Id Evergreen.V255.Id.UserId
        }
        Evergreen.V255.Go.LocalChange


type LocalMsg
    = LocalChange (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V255.Id.Id Evergreen.V255.Id.GuildId) (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelId) Evergreen.V255.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V255.Discord.Id Evergreen.V255.Discord.GuildId) (Evergreen.V255.Discord.Id Evergreen.V255.Discord.ChannelId) Evergreen.V255.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.FileStatus.FileId) Evergreen.V255.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V255.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V255.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V255.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V255.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V255.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V255.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V255.Coord.Coord Evergreen.V255.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V255.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V255.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V255.Id.AnyGuildOrDmId Evergreen.V255.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V255.Id.AnyGuildOrDmId Evergreen.V255.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V255.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V255.Coord.Coord Evergreen.V255.CssPixels.CssPixels) (Maybe Evergreen.V255.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V255.Id.AnyGuildOrDmId, Evergreen.V255.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelMessageId) (Evergreen.V255.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.Id.ThreadMessageId) (Evergreen.V255.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V255.Editable.Model
    , showLinkDiscordSetup : Bool
    , domainWhitelistInput : String
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V255.Local.Local LocalMsg Evergreen.V255.LocalState.LocalState
    , admin : Evergreen.V255.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V255.Id.AnyGuildOrDmId, Evergreen.V255.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V255.Id.Id Evergreen.V255.Id.GuildId, Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V255.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V255.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V255.Id.AnyGuildOrDmId, Evergreen.V255.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V255.Id.AnyGuildOrDmId, Evergreen.V255.Id.ThreadRoute ) (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : Evergreen.V255.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V255.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V255.Id.AnyGuildOrDmId, Evergreen.V255.Id.ThreadRoute ) (Evergreen.V255.NonemptyDict.NonemptyDict (Evergreen.V255.Id.Id Evergreen.V255.FileStatus.FileId) Evergreen.V255.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V255.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V255.TextEditor.Model
    , profilePictureEditor : Evergreen.V255.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V255.Id.Id Evergreen.V255.Id.GuildId, Evergreen.V255.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V255.Emoji.Model
    , voiceChat : Evergreen.V255.Call.Model
    , currentDmGoMatch : SeqDict.SeqDict ( Evergreen.V255.Id.Id Evergreen.V255.Id.UserId, Maybe (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelMessageId) ) Evergreen.V255.Go.Model
    , fileDragOverCount : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V255.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V255.SecretId.SecretId Evergreen.V255.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V255.Range.Range
                , direction : Evergreen.V255.Range.SelectionDirection
                }
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V255.NonemptyDict.NonemptyDict Int Evergreen.V255.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V255.NonemptyDict.NonemptyDict Int Evergreen.V255.Touch.Touch
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
    | AdminToFrontend Evergreen.V255.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V255.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V255.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V255.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V255.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V255.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V255.Go.PublicGoMatchData)


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V255.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V255.Coord.Coord Evergreen.V255.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V255.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V255.MyUi.LastCopy
    , notificationPermission : Evergreen.V255.Ports.NotificationPermission
    , pwaStatus : Evergreen.V255.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V255.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V255.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V255.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V255.Id.Id Evergreen.V255.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V255.Id.Id Evergreen.V255.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V255.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V255.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V255.Coord.Coord Evergreen.V255.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V255.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V255.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V255.Id.Id Evergreen.V255.Id.GuildId, Evergreen.V255.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V255.DmChannel.DmChannelId, Evergreen.V255.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V255.Discord.Id Evergreen.V255.Discord.GuildId, Evergreen.V255.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V255.Discord.Id Evergreen.V255.Discord.PrivateChannelId, Evergreen.V255.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V255.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V255.NonemptyDict.NonemptyDict (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId) Evergreen.V255.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V255.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V255.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V255.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V255.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId) Evergreen.V255.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId) Evergreen.V255.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V255.Id.Id Evergreen.V255.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.Id.GuildId) Evergreen.V255.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.Id.GuildId) Evergreen.V255.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V255.Discord.Id Evergreen.V255.Discord.GuildId) Evergreen.V255.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V255.DmChannel.DmChannelId Evergreen.V255.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V255.Discord.Id Evergreen.V255.Discord.PrivateChannelId) Evergreen.V255.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V255.OneToOne.OneToOne (Evergreen.V255.Slack.Id Evergreen.V255.Slack.ChannelId) Evergreen.V255.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V255.OneToOne.OneToOne String (Evergreen.V255.Id.Id Evergreen.V255.Id.GuildId)
    , slackUsers : Evergreen.V255.OneToOne.OneToOne (Evergreen.V255.Slack.Id Evergreen.V255.Slack.UserId) (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId)
    , slackServers : Evergreen.V255.OneToOne.OneToOne (Evergreen.V255.Slack.Id Evergreen.V255.Slack.TeamId) (Evergreen.V255.Id.Id Evergreen.V255.Id.GuildId)
    , slackToken : Maybe Evergreen.V255.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V255.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V255.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V255.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V255.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V255.Cloudflare.AppId
    , textEditor : Evergreen.V255.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId) Evergreen.V255.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId, Evergreen.V255.Discord.Id Evergreen.V255.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V255.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V255.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V255.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V255.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId) (Evergreen.V255.LocalState.LoadingDiscordChannel (List Evergreen.V255.Discord.Message))
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V255.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.Id.StickerId) Evergreen.V255.Sticker.StickerData
    , discordStickers : Evergreen.V255.OneToOne.OneToOne (Evergreen.V255.Discord.Id Evergreen.V255.Discord.StickerId) (Evergreen.V255.Id.Id Evergreen.V255.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.Id.CustomEmojiId) Evergreen.V255.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V255.OneToOne.OneToOne Evergreen.V255.RichText.DiscordCustomEmojiIdAndName (Evergreen.V255.Id.Id Evergreen.V255.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V255.Postmark.ApiKey
    , serverSecret : Evergreen.V255.SecretId.SecretId Evergreen.V255.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V255.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V255.OneToOne.OneToOne (Evergreen.V255.SecretId.SecretId Evergreen.V255.Id.GoMatchPublicId) ( Evergreen.V255.DmChannel.DmChannelId, Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelMessageId )
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V255.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V255.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V255.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V255.Route.Route
    | SelectedFilesToAttach ( Evergreen.V255.Id.AnyGuildOrDmId, Evergreen.V255.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V255.Id.Id Evergreen.V255.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V255.Id.Id Evergreen.V255.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V255.Id.Id Evergreen.V255.Id.GuildId) (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelId) Evergreen.V255.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V255.Id.Id Evergreen.V255.Id.GuildId) (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelId) Evergreen.V255.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V255.Discord.Id Evergreen.V255.Discord.GuildId) (Evergreen.V255.Discord.Id Evergreen.V255.Discord.ChannelId) Evergreen.V255.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V255.Discord.Id Evergreen.V255.Discord.GuildId) (Evergreen.V255.Discord.Id Evergreen.V255.Discord.ChannelId) Evergreen.V255.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V255.Id.Id Evergreen.V255.Id.GuildId) (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V255.Id.Id Evergreen.V255.Id.GuildId) (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V255.Id.Id Evergreen.V255.Id.GuildId) (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V255.Id.Id Evergreen.V255.Id.GuildId) (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V255.Id.Id Evergreen.V255.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V255.Id.Id Evergreen.V255.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V255.Id.Id Evergreen.V255.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V255.Id.Id Evergreen.V255.Id.GuildId) (Evergreen.V255.SecretId.SecretId Evergreen.V255.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V255.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V255.Id.AnyGuildOrDmId Evergreen.V255.Id.ThreadRouteWithMessage (Evergreen.V255.Coord.Coord Evergreen.V255.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V255.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V255.Id.AnyGuildOrDmId Evergreen.V255.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V255.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V255.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V255.Id.AnyGuildOrDmId, Evergreen.V255.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V255.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V255.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V255.Id.AnyGuildOrDmId, Evergreen.V255.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V255.NonemptyDict.NonemptyDict Int Evergreen.V255.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V255.NonemptyDict.NonemptyDict Int Evergreen.V255.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V255.Id.AnyGuildOrDmId Evergreen.V255.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V255.Id.AnyGuildOrDmId Evergreen.V255.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V255.NonemptySet.NonemptySet (Evergreen.V255.Id.Id Evergreen.V255.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V255.Id.AnyGuildOrDmId, Evergreen.V255.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V255.Id.AnyGuildOrDmId Evergreen.V255.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V255.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V255.AiChat.Msg
    | GoMsg Evergreen.V255.Go.Msg
    | GoSpectatorMsg Evergreen.V255.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V255.Editable.Msg Evergreen.V255.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V255.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V255.Id.Id Evergreen.V255.Id.GuildId) Evergreen.V255.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V255.Id.AnyGuildOrDmId, Evergreen.V255.Id.ThreadRoute ) (Evergreen.V255.Id.Id Evergreen.V255.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V255.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V255.Id.AnyGuildOrDmId, Evergreen.V255.Id.ThreadRoute ) (Evergreen.V255.Id.Id Evergreen.V255.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V255.Id.AnyGuildOrDmId, Evergreen.V255.Id.ThreadRoute ) (Evergreen.V255.Id.Id Evergreen.V255.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V255.Id.AnyGuildOrDmId, Evergreen.V255.Id.ThreadRoute )
        { fileId : Evergreen.V255.Id.Id Evergreen.V255.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V255.Id.AnyGuildOrDmId, Evergreen.V255.Id.ThreadRoute ) (Evergreen.V255.Id.Id Evergreen.V255.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V255.Id.AnyGuildOrDmId, Evergreen.V255.Id.ThreadRoute ) (Evergreen.V255.Id.Id Evergreen.V255.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V255.Id.AnyGuildOrDmId, Evergreen.V255.Id.ThreadRoute )
        { fileId : Evergreen.V255.Id.Id Evergreen.V255.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V255.Id.AnyGuildOrDmId, Evergreen.V255.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V255.Id.AnyGuildOrDmId, Evergreen.V255.Id.ThreadRoute ) (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelMessageId) (Evergreen.V255.Id.Id Evergreen.V255.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V255.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V255.Id.AnyGuildOrDmId, Evergreen.V255.Id.ThreadRoute ) (Evergreen.V255.Id.Id Evergreen.V255.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V255.Id.AnyGuildOrDmId Evergreen.V255.Id.ThreadRouteWithMessage Evergreen.V255.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V255.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V255.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V255.Id.Id Evergreen.V255.Id.GuildId) Evergreen.V255.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId) (Evergreen.V255.Discord.Id Evergreen.V255.Discord.GuildId) Evergreen.V255.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V255.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V255.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId
        , otherUserId : Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V255.Id.AnyGuildOrDmId Evergreen.V255.Id.ThreadRoute Evergreen.V255.MessageInput.Msg
    | MessageInputMsg Evergreen.V255.Id.AnyGuildOrDmId Evergreen.V255.Id.ThreadRoute Evergreen.V255.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V255.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V255.Range.Range, Evergreen.V255.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V255.Range.Range, Evergreen.V255.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V255.Call.FromJs)
    | VoiceChatMsg Evergreen.V255.Call.Msg
    | PressedChannelHeaderTab Evergreen.V255.Route.DmChannelHeaderTab
    | FileDragEnter
    | FileDragLeave
    | FileDropped (List Effect.File.File)


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V255.Id.Id Evergreen.V255.Id.GuildId) (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelId) Evergreen.V255.Id.ThreadRoute
    | InitialLoadRequested_Dm Evergreen.V255.DmChannel.DmChannelId Evergreen.V255.Id.ThreadRoute
    | InitialLoadRequested_Discord Evergreen.V255.Id.DiscordGuildOrDmId Evergreen.V255.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V255.Id.Id Evergreen.V255.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V255.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V255.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V255.Untrusted.Untrusted Evergreen.V255.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V255.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V255.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V255.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V255.Id.Id Evergreen.V255.Id.GuildId) (Evergreen.V255.SecretId.SecretId Evergreen.V255.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V255.PersonName.PersonName Evergreen.V255.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V255.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V255.Slack.OAuthCode Evergreen.V255.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V255.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V255.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V255.Id.Id Evergreen.V255.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V255.SecretId.SecretId Evergreen.V255.Id.GoMatchPublicId)


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V255.Discord.Id Evergreen.V255.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V255.Discord.Id Evergreen.V255.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V255.EmailAddress.EmailAddress (Result Evergreen.V255.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V255.EmailAddress.EmailAddress (Result Evergreen.V255.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V255.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V255.Discord.Id Evergreen.V255.Discord.GuildId) (Evergreen.V255.Discord.Id Evergreen.V255.Discord.ChannelId) Evergreen.V255.Id.ThreadRouteWithMaybeMessage (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId) (Result Evergreen.V255.Discord.HttpError Evergreen.V255.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V255.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V255.Discord.Id Evergreen.V255.Discord.PrivateChannelId) (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId) (Result Evergreen.V255.Discord.HttpError Evergreen.V255.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V255.Discord.Id Evergreen.V255.Discord.GuildId) (Evergreen.V255.Discord.Id Evergreen.V255.Discord.ChannelId) Evergreen.V255.Id.ThreadRouteWithMessage (Evergreen.V255.Discord.Id Evergreen.V255.Discord.MessageId) (Result Evergreen.V255.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V255.Discord.Id Evergreen.V255.Discord.PrivateChannelId) (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelMessageId) (Evergreen.V255.Discord.Id Evergreen.V255.Discord.MessageId) (Result Evergreen.V255.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V255.Discord.Id Evergreen.V255.Discord.GuildId) (Evergreen.V255.Discord.Id Evergreen.V255.Discord.ChannelId) Evergreen.V255.Id.ThreadRouteWithMessage (Evergreen.V255.Discord.Id Evergreen.V255.Discord.MessageId) (Result Evergreen.V255.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V255.Discord.Id Evergreen.V255.Discord.PrivateChannelId) (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelMessageId) (Evergreen.V255.Discord.Id Evergreen.V255.Discord.MessageId) (Result Evergreen.V255.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V255.Discord.Id Evergreen.V255.Discord.GuildId) (Evergreen.V255.Discord.Id Evergreen.V255.Discord.ChannelId) Evergreen.V255.Id.ThreadRouteWithMessage (Evergreen.V255.Discord.Id Evergreen.V255.Discord.MessageId) Evergreen.V255.Emoji.EmojiOrCustomEmoji (Result Evergreen.V255.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V255.Discord.Id Evergreen.V255.Discord.PrivateChannelId) (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelMessageId) (Evergreen.V255.Discord.Id Evergreen.V255.Discord.MessageId) Evergreen.V255.Emoji.EmojiOrCustomEmoji (Result Evergreen.V255.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V255.Discord.Id Evergreen.V255.Discord.GuildId) (Evergreen.V255.Discord.Id Evergreen.V255.Discord.ChannelId) Evergreen.V255.Id.ThreadRouteWithMessage (Evergreen.V255.Discord.Id Evergreen.V255.Discord.MessageId) Evergreen.V255.Emoji.EmojiOrCustomEmoji (Result Evergreen.V255.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V255.Discord.Id Evergreen.V255.Discord.PrivateChannelId) (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelMessageId) (Evergreen.V255.Discord.Id Evergreen.V255.Discord.MessageId) Evergreen.V255.Emoji.EmojiOrCustomEmoji (Result Evergreen.V255.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V255.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V255.Discord.HttpError (List ( Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId, Maybe Evergreen.V255.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V255.Slack.CurrentUser
            , team : Evergreen.V255.Slack.Team
            , users : List Evergreen.V255.Slack.User
            , channels : List ( Evergreen.V255.Slack.Channel, List Evergreen.V255.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId) (Result Effect.Http.Error Evergreen.V255.Slack.TokenResponse)
    | GotCloudflareSessionCreated Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V255.Local.ChangeId Effect.Time.Posix Evergreen.V255.Call.CallId Evergreen.V255.Cloudflare.Sdp (List String) (Result Effect.Http.Error Evergreen.V255.Cloudflare.RealtimeSessionId)
    | GotCloudflareSession Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V255.Local.ChangeId Effect.Time.Posix Evergreen.V255.Call.CallId Evergreen.V255.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V255.Cloudflare.PushTracksResult)
    | GotCloudflarePullOffer Effect.Time.Posix Effect.Lamdera.ClientId Evergreen.V255.Local.ChangeId Evergreen.V255.Call.ConnectionId Evergreen.V255.Cloudflare.RealtimeSessionId (List Evergreen.V255.Cloudflare.TrackName) (Result Effect.Http.Error Evergreen.V255.Cloudflare.PullTracksResult)
    | GotCloudflareRenegotiateAck Effect.Lamdera.ClientId Evergreen.V255.Local.ChangeId Evergreen.V255.Cloudflare.Sdp (Result Effect.Http.Error ())
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId) Evergreen.V255.Discord.UserAuth (Result Evergreen.V255.Discord.HttpError Evergreen.V255.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId) (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId) (Result Evergreen.V255.Discord.HttpError Evergreen.V255.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId)
        (Result
            Evergreen.V255.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V255.Discord.Id Evergreen.V255.Discord.PrivateChannelId
                , members : List (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId)
                }
            , List
                ( Evergreen.V255.Discord.Id Evergreen.V255.Discord.GuildId
                , { guild : Evergreen.V255.Discord.GatewayGuild
                  , channels : List Evergreen.V255.Discord.Channel
                  , icon : Maybe Evergreen.V255.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId) Bool Evergreen.V255.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V255.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V255.Discord.Id Evergreen.V255.Discord.AttachmentId, Evergreen.V255.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V255.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V255.Discord.Id Evergreen.V255.Discord.AttachmentId, Evergreen.V255.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId) (Evergreen.V255.Discord.Id Evergreen.V255.Discord.GuildId) (Evergreen.V255.Discord.Id Evergreen.V255.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V255.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V255.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId) (Evergreen.V255.Discord.Id Evergreen.V255.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V255.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V255.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId) (Evergreen.V255.Discord.Id Evergreen.V255.Discord.GuildId) (Evergreen.V255.Discord.Id Evergreen.V255.Discord.ChannelId) (Result Evergreen.V255.Discord.HttpError (List Evergreen.V255.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId) (Evergreen.V255.Discord.Id Evergreen.V255.Discord.PrivateChannelId) (Result Evergreen.V255.Discord.HttpError (List Evergreen.V255.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V255.Id.Id Evergreen.V255.Id.GuildId) (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelId) Evergreen.V255.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V255.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V255.DmChannel.DmChannelId Evergreen.V255.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V255.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V255.Discord.Id Evergreen.V255.Discord.GuildId) (Evergreen.V255.Discord.Id Evergreen.V255.Discord.ChannelId) Evergreen.V255.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V255.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V255.Discord.Id Evergreen.V255.Discord.PrivateChannelId) (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V255.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId)
        (Evergreen.V255.Discord.Id Evergreen.V255.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V255.Discord.HttpError
            { guild : Evergreen.V255.Discord.GatewayGuild
            , channels : List Evergreen.V255.Discord.Channel
            , icon : Maybe Evergreen.V255.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V255.Discord.Id Evergreen.V255.Discord.GuildId) (Result Evergreen.V255.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V255.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId) (List ( Evergreen.V255.Id.Id Evergreen.V255.Id.StickerId, Result Effect.Http.Error Evergreen.V255.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V255.Id.Id Evergreen.V255.Id.StickerId, Result Effect.Http.Error Evergreen.V255.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId) (List ( Evergreen.V255.Id.Id Evergreen.V255.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V255.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V255.Id.Id Evergreen.V255.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V255.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V255.Discord.HttpError (List Evergreen.V255.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V255.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V255.SecretId.SecretId Evergreen.V255.SecretId.ServerSecret))
    | GotTimeForWebsocketListenClose (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
