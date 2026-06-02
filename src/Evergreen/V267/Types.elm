module Evergreen.V267.Types exposing (..)

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
import Evergreen.V267.AiChat
import Evergreen.V267.Call
import Evergreen.V267.ChannelDescription
import Evergreen.V267.ChannelName
import Evergreen.V267.Cloudflare
import Evergreen.V267.Coord
import Evergreen.V267.CssPixels
import Evergreen.V267.CustomEmoji
import Evergreen.V267.Discord
import Evergreen.V267.DiscordAttachmentId
import Evergreen.V267.DiscordUserData
import Evergreen.V267.DmChannel
import Evergreen.V267.Editable
import Evergreen.V267.EmailAddress
import Evergreen.V267.Embed
import Evergreen.V267.Emoji
import Evergreen.V267.FileStatus
import Evergreen.V267.Go
import Evergreen.V267.GuildName
import Evergreen.V267.Id
import Evergreen.V267.ImageEditor
import Evergreen.V267.Local
import Evergreen.V267.LocalState
import Evergreen.V267.Log
import Evergreen.V267.LoginForm
import Evergreen.V267.MembersAndOwner
import Evergreen.V267.Message
import Evergreen.V267.MessageInput
import Evergreen.V267.MessageView
import Evergreen.V267.MyUi
import Evergreen.V267.NonemptyDict
import Evergreen.V267.NonemptySet
import Evergreen.V267.OneToOne
import Evergreen.V267.Pages.Admin
import Evergreen.V267.Pagination
import Evergreen.V267.PersonName
import Evergreen.V267.Ports
import Evergreen.V267.Postmark
import Evergreen.V267.Range
import Evergreen.V267.RichText
import Evergreen.V267.Route
import Evergreen.V267.SecretId
import Evergreen.V267.SessionIdHash
import Evergreen.V267.Slack
import Evergreen.V267.Sticker
import Evergreen.V267.TextEditor
import Evergreen.V267.ToBackendLog
import Evergreen.V267.Touch
import Evergreen.V267.TwoFactorAuthentication
import Evergreen.V267.Ui.Anim
import Evergreen.V267.Untrusted
import Evergreen.V267.User
import Evergreen.V267.UserAgent
import Evergreen.V267.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V267.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V267.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V267.Id.Id Evergreen.V267.Id.GuildId) Evergreen.V267.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V267.Id.Id Evergreen.V267.Id.UserId) Evergreen.V267.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V267.Discord.Id Evergreen.V267.Discord.PrivateChannelId) Evergreen.V267.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V267.Discord.Id Evergreen.V267.Discord.GuildId) Evergreen.V267.LocalState.DiscordFrontendGuild
    , user : Evergreen.V267.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V267.Id.Id Evergreen.V267.Id.UserId) Evergreen.V267.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId) Evergreen.V267.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId) Evergreen.V267.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V267.SessionIdHash.SessionIdHash Evergreen.V267.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V267.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V267.Id.Id Evergreen.V267.Id.StickerId) Evergreen.V267.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V267.Id.Id Evergreen.V267.Id.CustomEmojiId) Evergreen.V267.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V267.Call.CallId (Evergreen.V267.NonemptySet.NonemptySet ( Evergreen.V267.Id.Id Evergreen.V267.Id.UserId, Effect.Lamdera.ClientId ))
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type PublicGoMatch
    = PublicGoMatch_NotLoaded
    | PublicGoMatch_Loading
    | PublicGoMatch_Loaded Evergreen.V267.Go.PublicGoMatchData Evergreen.V267.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V267.Route.Route
    , windowSize : Evergreen.V267.Coord.Coord Evergreen.V267.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V267.Ports.NotificationPermission
    , pwaStatus : Evergreen.V267.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V267.UserAgent.UserAgent
    , publicGoMatch : PublicGoMatch
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V267.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V267.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V267.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V267.Id.Id Evergreen.V267.FileStatus.FileId) Evergreen.V267.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V267.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V267.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V267.Id.Id Evergreen.V267.FileStatus.FileId) Evergreen.V267.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V267.Id.Id Evergreen.V267.Id.GuildId) Evergreen.V267.ChannelName.ChannelName Evergreen.V267.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V267.Id.Id Evergreen.V267.Id.GuildId) (Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelId) Evergreen.V267.ChannelName.ChannelName Evergreen.V267.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V267.Id.Id Evergreen.V267.Id.GuildId) (Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelId)
    | Local_DeleteGuild (Evergreen.V267.Id.Id Evergreen.V267.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V267.Id.Id Evergreen.V267.Id.GuildId) (Evergreen.V267.UserSession.ToBeFilledInByBackend (Evergreen.V267.SecretId.SecretId Evergreen.V267.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V267.Id.Id Evergreen.V267.Id.GuildId) (Evergreen.V267.SecretId.SecretId Evergreen.V267.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V267.GuildName.GuildName (Evergreen.V267.UserSession.ToBeFilledInByBackend (Evergreen.V267.Id.Id Evergreen.V267.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V267.Id.AnyGuildOrDmId, Evergreen.V267.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V267.Id.AnyGuildOrDmId Evergreen.V267.Id.ThreadRouteWithMessage Evergreen.V267.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V267.Id.AnyGuildOrDmId Evergreen.V267.Id.ThreadRouteWithMessage Evergreen.V267.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V267.Id.GuildOrDmId Evergreen.V267.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V267.Id.Id Evergreen.V267.FileStatus.FileId) Evergreen.V267.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId) (Evergreen.V267.Discord.Id Evergreen.V267.Discord.GuildId) (Evergreen.V267.Discord.Id Evergreen.V267.Discord.ChannelId) Evergreen.V267.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V267.Id.DiscordGuildOrDmId_DmData (Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V267.Id.AnyGuildOrDmId Evergreen.V267.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V267.Id.AnyGuildOrDmId Evergreen.V267.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V267.Id.AnyGuildOrDmId Evergreen.V267.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V267.UserSession.SetViewing
    | Local_SetName Evergreen.V267.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V267.Id.GuildOrDmId (Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelMessageId) (Evergreen.V267.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelMessageId) (Evergreen.V267.Message.Message Evergreen.V267.Id.ChannelMessageId (Evergreen.V267.Id.Id Evergreen.V267.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V267.Id.GuildOrDmId (Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelMessageId) (Evergreen.V267.Id.Id Evergreen.V267.Id.ThreadMessageId) (Evergreen.V267.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V267.Id.Id Evergreen.V267.Id.ThreadMessageId) (Evergreen.V267.Message.Message Evergreen.V267.Id.ThreadMessageId (Evergreen.V267.Id.Id Evergreen.V267.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V267.Id.DiscordGuildOrDmId (Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelMessageId) (Evergreen.V267.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelMessageId) (Evergreen.V267.Message.Message Evergreen.V267.Id.ChannelMessageId (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V267.Id.DiscordGuildOrDmId (Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelMessageId) (Evergreen.V267.Id.Id Evergreen.V267.Id.ThreadMessageId) (Evergreen.V267.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V267.Id.Id Evergreen.V267.Id.ThreadMessageId) (Evergreen.V267.Message.Message Evergreen.V267.Id.ThreadMessageId (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V267.Id.Id Evergreen.V267.Id.GuildId) Evergreen.V267.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId) (Evergreen.V267.Discord.Id Evergreen.V267.Discord.GuildId) Evergreen.V267.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V267.UserSession.NotificationMode
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V267.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V267.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V267.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V267.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V267.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V267.NonemptySet.NonemptySet (Evergreen.V267.Id.Id Evergreen.V267.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V267.Call.LocalChange
    | Local_Go
        { otherUserId : Evergreen.V267.Id.Id Evergreen.V267.Id.UserId
        }
        Evergreen.V267.Go.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V267.Id.Id Evergreen.V267.Id.UserId) Effect.Time.Posix Evergreen.V267.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V267.RichText.RichText (Evergreen.V267.Id.Id Evergreen.V267.Id.UserId))) Evergreen.V267.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V267.Id.Id Evergreen.V267.FileStatus.FileId) Evergreen.V267.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V267.Id.Id Evergreen.V267.Id.StickerId) Evergreen.V267.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V267.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V267.RichText.RichText (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId))) Evergreen.V267.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V267.Id.Id Evergreen.V267.FileStatus.FileId) Evergreen.V267.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V267.Id.Id Evergreen.V267.Id.StickerId) Evergreen.V267.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V267.Id.Id Evergreen.V267.Id.GuildId) Evergreen.V267.ChannelName.ChannelName Evergreen.V267.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V267.Id.Id Evergreen.V267.Id.GuildId) (Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelId) Evergreen.V267.ChannelName.ChannelName Evergreen.V267.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V267.Id.Id Evergreen.V267.Id.GuildId) (Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelId)
    | Server_DeleteGuild (Evergreen.V267.Id.Id Evergreen.V267.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V267.Id.Id Evergreen.V267.Id.UserId) (Evergreen.V267.Id.Id Evergreen.V267.Id.GuildId) (Evergreen.V267.SecretId.SecretId Evergreen.V267.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V267.Id.Id Evergreen.V267.Id.GuildId) (Evergreen.V267.SecretId.SecretId Evergreen.V267.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V267.Id.Id Evergreen.V267.Id.UserId) (Evergreen.V267.Id.Id Evergreen.V267.Id.GuildId) Evergreen.V267.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V267.LocalState.JoinGuildError
            { guildId : Evergreen.V267.Id.Id Evergreen.V267.Id.GuildId
            , guild : Evergreen.V267.LocalState.FrontendGuild
            , owner : Evergreen.V267.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V267.Id.Id Evergreen.V267.Id.UserId) Evergreen.V267.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V267.Id.Id Evergreen.V267.Id.UserId) Evergreen.V267.Id.GuildOrDmId Evergreen.V267.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId) (Evergreen.V267.Discord.Id Evergreen.V267.Discord.GuildId) (Evergreen.V267.Discord.Id Evergreen.V267.Discord.ChannelId) Evergreen.V267.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId) (Evergreen.V267.Discord.Id Evergreen.V267.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V267.Id.Id Evergreen.V267.Id.UserId) Evergreen.V267.Id.GuildOrDmId Evergreen.V267.Id.ThreadRouteWithMessage Evergreen.V267.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V267.Id.Id Evergreen.V267.Id.UserId) Evergreen.V267.Id.GuildOrDmId Evergreen.V267.Id.ThreadRouteWithMessage Evergreen.V267.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId) (Evergreen.V267.Discord.Id Evergreen.V267.Discord.GuildId) (Evergreen.V267.Discord.Id Evergreen.V267.Discord.ChannelId) Evergreen.V267.Id.ThreadRouteWithMessage Evergreen.V267.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId) (Evergreen.V267.Discord.Id Evergreen.V267.Discord.PrivateChannelId) (Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelMessageId) Evergreen.V267.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId) (Evergreen.V267.Discord.Id Evergreen.V267.Discord.GuildId) (Evergreen.V267.Discord.Id Evergreen.V267.Discord.ChannelId) Evergreen.V267.Id.ThreadRouteWithMessage Evergreen.V267.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId) (Evergreen.V267.Discord.Id Evergreen.V267.Discord.PrivateChannelId) (Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelMessageId) Evergreen.V267.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V267.Id.Id Evergreen.V267.Id.UserId) Evergreen.V267.Id.GuildOrDmId Evergreen.V267.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V267.RichText.RichText (Evergreen.V267.Id.Id Evergreen.V267.Id.UserId))) (SeqDict.SeqDict (Evergreen.V267.Id.Id Evergreen.V267.FileStatus.FileId) Evergreen.V267.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId) (Evergreen.V267.Discord.Id Evergreen.V267.Discord.GuildId) (Evergreen.V267.Discord.Id Evergreen.V267.Discord.ChannelId) Evergreen.V267.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V267.RichText.RichText (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V267.Id.DiscordGuildOrDmId_DmData (Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V267.RichText.RichText (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V267.Id.Id Evergreen.V267.Id.UserId) Evergreen.V267.Id.AnyGuildOrDmId Evergreen.V267.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V267.Id.AnyGuildOrDmId Evergreen.V267.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V267.Discord.Id Evergreen.V267.Discord.GuildId) (Evergreen.V267.Discord.Id Evergreen.V267.Discord.ChannelId) Evergreen.V267.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V267.Discord.Id Evergreen.V267.Discord.PrivateChannelId) (Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V267.Id.Id Evergreen.V267.Id.UserId) Evergreen.V267.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V267.Id.Id Evergreen.V267.Id.UserId) Evergreen.V267.FileStatus.FileHash
    | Server_SetGuildIcon (Evergreen.V267.Id.Id Evergreen.V267.Id.GuildId) Evergreen.V267.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V267.Id.Id Evergreen.V267.Id.GuildId) Evergreen.V267.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V267.Discord.Id Evergreen.V267.Discord.GuildId) Evergreen.V267.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V267.SessionIdHash.SessionIdHash Evergreen.V267.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V267.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V267.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V267.Id.AnyGuildOrDmId, Evergreen.V267.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V267.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId) Evergreen.V267.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V267.Discord.Id Evergreen.V267.Discord.GuildId) (Evergreen.V267.Discord.Id Evergreen.V267.Discord.ChannelId) Evergreen.V267.ChannelName.ChannelName (Evergreen.V267.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V267.Discord.Id Evergreen.V267.Discord.PrivateChannelId)
        (Evergreen.V267.NonemptyDict.NonemptyDict
            (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V267.Discord.Id Evergreen.V267.Discord.GuildId) Evergreen.V267.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V267.Discord.Id Evergreen.V267.Discord.PrivateChannelId) Evergreen.V267.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId) Evergreen.V267.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId) (Maybe (Evergreen.V267.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V267.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V267.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V267.Id.Id Evergreen.V267.Id.GuildId) (Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelId) Evergreen.V267.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V267.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V267.Id.Id Evergreen.V267.Id.UserId) Evergreen.V267.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V267.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V267.Discord.Id Evergreen.V267.Discord.GuildId) (Evergreen.V267.Discord.Id Evergreen.V267.Discord.ChannelId) Evergreen.V267.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V267.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V267.Discord.Id Evergreen.V267.Discord.PrivateChannelId) (Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V267.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V267.Discord.Id Evergreen.V267.Discord.GuildId) Evergreen.V267.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V267.Discord.Id Evergreen.V267.Discord.GuildId) (Evergreen.V267.Discord.Id Evergreen.V267.Discord.ChannelId) (Evergreen.V267.Discord.OptionalData String) (Evergreen.V267.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V267.Discord.Id Evergreen.V267.Discord.GuildId)
        (Evergreen.V267.MembersAndOwner.MembersAndOwner
            (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V267.Discord.Id Evergreen.V267.Discord.GuildId) (Evergreen.V267.Discord.Id Evergreen.V267.Discord.ChannelId) (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId) Evergreen.V267.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V267.Id.Id Evergreen.V267.Id.StickerId) Evergreen.V267.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V267.Id.Id Evergreen.V267.Id.CustomEmojiId) Evergreen.V267.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V267.Call.ServerChange
    | Server_Go
        (Evergreen.V267.Id.Id Evergreen.V267.Id.UserId)
        { otherUserId : Evergreen.V267.Id.Id Evergreen.V267.Id.UserId
        }
        Evergreen.V267.Go.LocalChange


type LocalMsg
    = LocalChange (Evergreen.V267.Id.Id Evergreen.V267.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V267.Id.Id Evergreen.V267.Id.GuildId) (Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelId) Evergreen.V267.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V267.Discord.Id Evergreen.V267.Discord.GuildId) (Evergreen.V267.Discord.Id Evergreen.V267.Discord.ChannelId) Evergreen.V267.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V267.Id.Id Evergreen.V267.FileStatus.FileId) Evergreen.V267.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V267.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V267.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V267.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V267.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V267.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V267.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V267.Coord.Coord Evergreen.V267.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V267.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V267.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V267.Id.AnyGuildOrDmId Evergreen.V267.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V267.Id.AnyGuildOrDmId Evergreen.V267.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V267.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V267.Coord.Coord Evergreen.V267.CssPixels.CssPixels) (Maybe Evergreen.V267.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V267.Id.AnyGuildOrDmId, Evergreen.V267.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelMessageId) (Evergreen.V267.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V267.Id.Id Evergreen.V267.Id.ThreadMessageId) (Evergreen.V267.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V267.Editable.Model
    , showLinkDiscordSetup : Bool
    , domainWhitelistInput : String
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V267.Local.Local LocalMsg Evergreen.V267.LocalState.LocalState
    , admin : Evergreen.V267.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V267.Id.AnyGuildOrDmId, Evergreen.V267.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V267.Id.Id Evergreen.V267.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V267.Id.Id Evergreen.V267.Id.GuildId, Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V267.Id.Id Evergreen.V267.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V267.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V267.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V267.Id.AnyGuildOrDmId, Evergreen.V267.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V267.Id.AnyGuildOrDmId, Evergreen.V267.Id.ThreadRoute ) (Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : Evergreen.V267.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V267.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V267.Id.AnyGuildOrDmId, Evergreen.V267.Id.ThreadRoute ) (Evergreen.V267.NonemptyDict.NonemptyDict (Evergreen.V267.Id.Id Evergreen.V267.FileStatus.FileId) Evergreen.V267.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V267.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V267.TextEditor.Model
    , profilePictureEditor : Evergreen.V267.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V267.Id.Id Evergreen.V267.Id.GuildId, Evergreen.V267.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V267.Emoji.Model
    , voiceChat : Evergreen.V267.Call.Model
    , currentDmGoMatch : SeqDict.SeqDict ( Evergreen.V267.Id.Id Evergreen.V267.Id.UserId, Maybe (Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelMessageId) ) Evergreen.V267.Go.Model
    , fileDragOverCount : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V267.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V267.SecretId.SecretId Evergreen.V267.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V267.Range.Range
                , direction : Evergreen.V267.Range.SelectionDirection
                }
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V267.NonemptyDict.NonemptyDict Int Evergreen.V267.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V267.NonemptyDict.NonemptyDict Int Evergreen.V267.Touch.Touch
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
    | AdminToFrontend Evergreen.V267.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V267.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V267.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V267.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V267.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V267.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V267.Go.PublicGoMatchResponse)


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V267.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V267.Coord.Coord Evergreen.V267.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V267.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V267.MyUi.LastCopy
    , notificationPermission : Evergreen.V267.Ports.NotificationPermission
    , pwaStatus : Evergreen.V267.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V267.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V267.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V267.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V267.Id.Id Evergreen.V267.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V267.Id.Id Evergreen.V267.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V267.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V267.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V267.Coord.Coord Evergreen.V267.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V267.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V267.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V267.Id.Id Evergreen.V267.Id.GuildId, Evergreen.V267.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V267.DmChannel.DmChannelId, Evergreen.V267.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V267.Discord.Id Evergreen.V267.Discord.GuildId, Evergreen.V267.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V267.Discord.Id Evergreen.V267.Discord.PrivateChannelId, Evergreen.V267.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V267.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V267.NonemptyDict.NonemptyDict (Evergreen.V267.Id.Id Evergreen.V267.Id.UserId) Evergreen.V267.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V267.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V267.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V267.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V267.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V267.Id.Id Evergreen.V267.Id.UserId) Evergreen.V267.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V267.Id.Id Evergreen.V267.Id.UserId) Evergreen.V267.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V267.Id.Id Evergreen.V267.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V267.Id.Id Evergreen.V267.Id.GuildId) Evergreen.V267.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V267.Id.Id Evergreen.V267.Id.GuildId) Evergreen.V267.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V267.Discord.Id Evergreen.V267.Discord.GuildId) Evergreen.V267.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V267.DmChannel.DmChannelId Evergreen.V267.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V267.Discord.Id Evergreen.V267.Discord.PrivateChannelId) Evergreen.V267.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V267.OneToOne.OneToOne (Evergreen.V267.Slack.Id Evergreen.V267.Slack.ChannelId) Evergreen.V267.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V267.OneToOne.OneToOne String (Evergreen.V267.Id.Id Evergreen.V267.Id.GuildId)
    , slackUsers : Evergreen.V267.OneToOne.OneToOne (Evergreen.V267.Slack.Id Evergreen.V267.Slack.UserId) (Evergreen.V267.Id.Id Evergreen.V267.Id.UserId)
    , slackServers : Evergreen.V267.OneToOne.OneToOne (Evergreen.V267.Slack.Id Evergreen.V267.Slack.TeamId) (Evergreen.V267.Id.Id Evergreen.V267.Id.GuildId)
    , slackToken : Maybe Evergreen.V267.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V267.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V267.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V267.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V267.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V267.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V267.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V267.Cloudflare.AnalyticsApiToken
    , textEditor : Evergreen.V267.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId) Evergreen.V267.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId, Evergreen.V267.Discord.Id Evergreen.V267.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V267.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V267.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V267.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V267.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId) (Evergreen.V267.LocalState.LoadingDiscordChannel (List Evergreen.V267.Discord.Message))
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V267.Id.Id Evergreen.V267.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V267.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V267.Id.Id Evergreen.V267.Id.StickerId) Evergreen.V267.Sticker.StickerData
    , discordStickers : Evergreen.V267.OneToOne.OneToOne (Evergreen.V267.Discord.Id Evergreen.V267.Discord.StickerId) (Evergreen.V267.Id.Id Evergreen.V267.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V267.Id.Id Evergreen.V267.Id.CustomEmojiId) Evergreen.V267.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V267.OneToOne.OneToOne Evergreen.V267.RichText.DiscordCustomEmojiIdAndName (Evergreen.V267.Id.Id Evergreen.V267.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V267.Postmark.ApiKey
    , serverSecret : Evergreen.V267.SecretId.SecretId Evergreen.V267.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V267.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V267.OneToOne.OneToOne (Evergreen.V267.SecretId.SecretId Evergreen.V267.Id.GoMatchPublicId) ( Evergreen.V267.DmChannel.DmChannelId, Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelMessageId )
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V267.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V267.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V267.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V267.Route.Route
    | SelectedFilesToAttach ( Evergreen.V267.Id.AnyGuildOrDmId, Evergreen.V267.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V267.Id.Id Evergreen.V267.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V267.Id.Id Evergreen.V267.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V267.Id.Id Evergreen.V267.Id.GuildId) (Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelId) Evergreen.V267.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V267.Id.Id Evergreen.V267.Id.GuildId) (Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelId) Evergreen.V267.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V267.Discord.Id Evergreen.V267.Discord.GuildId) (Evergreen.V267.Discord.Id Evergreen.V267.Discord.ChannelId) Evergreen.V267.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V267.Discord.Id Evergreen.V267.Discord.GuildId) (Evergreen.V267.Discord.Id Evergreen.V267.Discord.ChannelId) Evergreen.V267.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V267.Id.Id Evergreen.V267.Id.GuildId) (Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V267.Id.Id Evergreen.V267.Id.GuildId) (Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V267.Id.Id Evergreen.V267.Id.GuildId) (Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V267.Id.Id Evergreen.V267.Id.GuildId) (Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V267.Id.Id Evergreen.V267.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V267.Id.Id Evergreen.V267.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V267.Id.Id Evergreen.V267.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V267.Id.Id Evergreen.V267.Id.GuildId) (Evergreen.V267.SecretId.SecretId Evergreen.V267.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V267.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V267.Id.AnyGuildOrDmId Evergreen.V267.Id.ThreadRouteWithMessage (Evergreen.V267.Coord.Coord Evergreen.V267.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V267.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V267.Id.AnyGuildOrDmId Evergreen.V267.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V267.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V267.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V267.Id.AnyGuildOrDmId, Evergreen.V267.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V267.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V267.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V267.Id.AnyGuildOrDmId, Evergreen.V267.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V267.NonemptyDict.NonemptyDict Int Evergreen.V267.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V267.NonemptyDict.NonemptyDict Int Evergreen.V267.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V267.Id.AnyGuildOrDmId Evergreen.V267.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V267.Id.AnyGuildOrDmId Evergreen.V267.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V267.NonemptySet.NonemptySet (Evergreen.V267.Id.Id Evergreen.V267.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V267.Id.AnyGuildOrDmId, Evergreen.V267.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V267.Id.AnyGuildOrDmId Evergreen.V267.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V267.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V267.AiChat.Msg
    | GoMsg Evergreen.V267.Go.Msg
    | GoSpectatorMsg Evergreen.V267.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V267.Editable.Msg Evergreen.V267.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V267.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V267.Id.Id Evergreen.V267.Id.GuildId) Evergreen.V267.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V267.Id.AnyGuildOrDmId, Evergreen.V267.Id.ThreadRoute ) (Evergreen.V267.Id.Id Evergreen.V267.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V267.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V267.Id.AnyGuildOrDmId, Evergreen.V267.Id.ThreadRoute ) (Evergreen.V267.Id.Id Evergreen.V267.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V267.Id.AnyGuildOrDmId, Evergreen.V267.Id.ThreadRoute ) (Evergreen.V267.Id.Id Evergreen.V267.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V267.Id.AnyGuildOrDmId, Evergreen.V267.Id.ThreadRoute )
        { fileId : Evergreen.V267.Id.Id Evergreen.V267.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V267.Id.AnyGuildOrDmId, Evergreen.V267.Id.ThreadRoute ) (Evergreen.V267.Id.Id Evergreen.V267.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V267.Id.AnyGuildOrDmId, Evergreen.V267.Id.ThreadRoute ) (Evergreen.V267.Id.Id Evergreen.V267.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V267.Id.AnyGuildOrDmId, Evergreen.V267.Id.ThreadRoute )
        { fileId : Evergreen.V267.Id.Id Evergreen.V267.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V267.Id.AnyGuildOrDmId, Evergreen.V267.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V267.Id.AnyGuildOrDmId, Evergreen.V267.Id.ThreadRoute ) (Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelMessageId) (Evergreen.V267.Id.Id Evergreen.V267.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V267.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V267.Id.AnyGuildOrDmId, Evergreen.V267.Id.ThreadRoute ) (Evergreen.V267.Id.Id Evergreen.V267.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V267.Id.AnyGuildOrDmId Evergreen.V267.Id.ThreadRouteWithMessage Evergreen.V267.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V267.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V267.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V267.Id.Id Evergreen.V267.Id.GuildId) Evergreen.V267.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId) (Evergreen.V267.Discord.Id Evergreen.V267.Discord.GuildId) Evergreen.V267.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V267.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V267.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId
        , otherUserId : Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V267.Id.AnyGuildOrDmId Evergreen.V267.Id.ThreadRoute Evergreen.V267.MessageInput.Msg
    | MessageInputMsg Evergreen.V267.Id.AnyGuildOrDmId Evergreen.V267.Id.ThreadRoute Evergreen.V267.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V267.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V267.Range.Range, Evergreen.V267.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V267.Range.Range, Evergreen.V267.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V267.Call.FromJs)
    | VoiceChatMsg Evergreen.V267.Call.Msg
    | PressedChannelHeaderTab Evergreen.V267.Route.DmChannelHeaderTab
    | FileDragEnter
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V267.Id.Id Evergreen.V267.Id.GuildId) (Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelId) Evergreen.V267.Id.ThreadRoute
    | InitialLoadRequested_Dm Evergreen.V267.DmChannel.DmChannelId Evergreen.V267.Id.ThreadRoute
    | InitialLoadRequested_Discord Evergreen.V267.Id.DiscordGuildOrDmId Evergreen.V267.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V267.Id.Id Evergreen.V267.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V267.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V267.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V267.Untrusted.Untrusted Evergreen.V267.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V267.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V267.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V267.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V267.Id.Id Evergreen.V267.Id.GuildId) (Evergreen.V267.SecretId.SecretId Evergreen.V267.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V267.PersonName.PersonName Evergreen.V267.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V267.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V267.Slack.OAuthCode Evergreen.V267.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V267.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V267.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V267.Id.Id Evergreen.V267.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V267.SecretId.SecretId Evergreen.V267.Id.GoMatchPublicId)


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V267.Discord.Id Evergreen.V267.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V267.Discord.Id Evergreen.V267.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V267.EmailAddress.EmailAddress (Result Evergreen.V267.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V267.EmailAddress.EmailAddress (Result Evergreen.V267.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V267.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V267.Discord.Id Evergreen.V267.Discord.GuildId) (Evergreen.V267.Discord.Id Evergreen.V267.Discord.ChannelId) Evergreen.V267.Id.ThreadRouteWithMaybeMessage (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId) (Result Evergreen.V267.Discord.HttpError Evergreen.V267.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V267.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V267.Discord.Id Evergreen.V267.Discord.PrivateChannelId) (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId) (Result Evergreen.V267.Discord.HttpError Evergreen.V267.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V267.Discord.Id Evergreen.V267.Discord.GuildId) (Evergreen.V267.Discord.Id Evergreen.V267.Discord.ChannelId) Evergreen.V267.Id.ThreadRouteWithMessage (Evergreen.V267.Discord.Id Evergreen.V267.Discord.MessageId) (Result Evergreen.V267.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V267.Discord.Id Evergreen.V267.Discord.PrivateChannelId) (Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelMessageId) (Evergreen.V267.Discord.Id Evergreen.V267.Discord.MessageId) (Result Evergreen.V267.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V267.Discord.Id Evergreen.V267.Discord.GuildId) (Evergreen.V267.Discord.Id Evergreen.V267.Discord.ChannelId) Evergreen.V267.Id.ThreadRouteWithMessage (Evergreen.V267.Discord.Id Evergreen.V267.Discord.MessageId) (Result Evergreen.V267.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V267.Discord.Id Evergreen.V267.Discord.PrivateChannelId) (Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelMessageId) (Evergreen.V267.Discord.Id Evergreen.V267.Discord.MessageId) (Result Evergreen.V267.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V267.Discord.Id Evergreen.V267.Discord.GuildId) (Evergreen.V267.Discord.Id Evergreen.V267.Discord.ChannelId) Evergreen.V267.Id.ThreadRouteWithMessage (Evergreen.V267.Discord.Id Evergreen.V267.Discord.MessageId) Evergreen.V267.Emoji.EmojiOrCustomEmoji (Result Evergreen.V267.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V267.Discord.Id Evergreen.V267.Discord.PrivateChannelId) (Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelMessageId) (Evergreen.V267.Discord.Id Evergreen.V267.Discord.MessageId) Evergreen.V267.Emoji.EmojiOrCustomEmoji (Result Evergreen.V267.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V267.Discord.Id Evergreen.V267.Discord.GuildId) (Evergreen.V267.Discord.Id Evergreen.V267.Discord.ChannelId) Evergreen.V267.Id.ThreadRouteWithMessage (Evergreen.V267.Discord.Id Evergreen.V267.Discord.MessageId) Evergreen.V267.Emoji.EmojiOrCustomEmoji (Result Evergreen.V267.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V267.Discord.Id Evergreen.V267.Discord.PrivateChannelId) (Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelMessageId) (Evergreen.V267.Discord.Id Evergreen.V267.Discord.MessageId) Evergreen.V267.Emoji.EmojiOrCustomEmoji (Result Evergreen.V267.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V267.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V267.Discord.HttpError (List ( Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId, Maybe Evergreen.V267.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V267.Id.Id Evergreen.V267.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V267.Id.Id Evergreen.V267.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V267.Slack.CurrentUser
            , team : Evergreen.V267.Slack.Team
            , users : List Evergreen.V267.Slack.User
            , channels : List ( Evergreen.V267.Slack.Channel, List Evergreen.V267.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V267.Id.Id Evergreen.V267.Id.UserId) (Result Effect.Http.Error Evergreen.V267.Slack.TokenResponse)
    | GotCloudflareSessionCreated Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V267.Local.ChangeId Effect.Time.Posix Evergreen.V267.Call.CallId Evergreen.V267.Cloudflare.Sdp (List String) (Result Effect.Http.Error Evergreen.V267.Cloudflare.RealtimeSessionId)
    | GotCloudflareSession Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V267.Local.ChangeId Effect.Time.Posix Evergreen.V267.Call.CallId Evergreen.V267.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V267.Cloudflare.PushTracksResult)
    | GotCloudflarePullOffer Effect.Time.Posix Effect.Lamdera.ClientId Evergreen.V267.Local.ChangeId Evergreen.V267.Call.ConnectionId Evergreen.V267.Cloudflare.RealtimeSessionId (List Evergreen.V267.Cloudflare.TrackName) (Result Effect.Http.Error Evergreen.V267.Cloudflare.PullTracksResult)
    | GotCloudflareRenegotiateAck Effect.Lamdera.ClientId Evergreen.V267.Local.ChangeId Evergreen.V267.Cloudflare.Sdp (Result Effect.Http.Error ())
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V267.Id.Id Evergreen.V267.Id.UserId) Evergreen.V267.Discord.UserAuth (Result Evergreen.V267.Discord.HttpError Evergreen.V267.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V267.Id.Id Evergreen.V267.Id.UserId) (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId) (Result Evergreen.V267.Discord.HttpError Evergreen.V267.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId)
        (Result
            Evergreen.V267.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V267.Discord.Id Evergreen.V267.Discord.PrivateChannelId
                , members : List (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId)
                }
            , List
                ( Evergreen.V267.Discord.Id Evergreen.V267.Discord.GuildId
                , { guild : Evergreen.V267.Discord.GatewayGuild
                  , channels : List Evergreen.V267.Discord.Channel
                  , icon : Maybe Evergreen.V267.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId) Bool Evergreen.V267.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V267.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V267.Discord.Id Evergreen.V267.Discord.AttachmentId, Evergreen.V267.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V267.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V267.Discord.Id Evergreen.V267.Discord.AttachmentId, Evergreen.V267.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId) (Evergreen.V267.Discord.Id Evergreen.V267.Discord.GuildId) (Evergreen.V267.Discord.Id Evergreen.V267.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V267.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V267.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId) (Evergreen.V267.Discord.Id Evergreen.V267.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V267.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V267.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId) (Evergreen.V267.Discord.Id Evergreen.V267.Discord.GuildId) (Evergreen.V267.Discord.Id Evergreen.V267.Discord.ChannelId) (Result Evergreen.V267.Discord.HttpError (List Evergreen.V267.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId) (Evergreen.V267.Discord.Id Evergreen.V267.Discord.PrivateChannelId) (Result Evergreen.V267.Discord.HttpError (List Evergreen.V267.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V267.Id.Id Evergreen.V267.Id.GuildId) (Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelId) Evergreen.V267.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V267.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V267.DmChannel.DmChannelId Evergreen.V267.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V267.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V267.Discord.Id Evergreen.V267.Discord.GuildId) (Evergreen.V267.Discord.Id Evergreen.V267.Discord.ChannelId) Evergreen.V267.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V267.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V267.Discord.Id Evergreen.V267.Discord.PrivateChannelId) (Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V267.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId)
        (Evergreen.V267.Discord.Id Evergreen.V267.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V267.Discord.HttpError
            { guild : Evergreen.V267.Discord.GatewayGuild
            , channels : List Evergreen.V267.Discord.Channel
            , icon : Maybe Evergreen.V267.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V267.Discord.Id Evergreen.V267.Discord.GuildId) (Result Evergreen.V267.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V267.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V267.Id.Id Evergreen.V267.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V267.Id.Id Evergreen.V267.Id.UserId) (List ( Evergreen.V267.Id.Id Evergreen.V267.Id.StickerId, Result Effect.Http.Error Evergreen.V267.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V267.Id.Id Evergreen.V267.Id.StickerId, Result Effect.Http.Error Evergreen.V267.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V267.Id.Id Evergreen.V267.Id.UserId) (List ( Evergreen.V267.Id.Id Evergreen.V267.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V267.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V267.Id.Id Evergreen.V267.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V267.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V267.Discord.HttpError (List Evergreen.V267.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V267.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V267.SecretId.SecretId Evergreen.V267.SecretId.ServerSecret))
    | GotTimeForWebsocketListenClose (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | GotCloudflareUsage Effect.Time.Posix (Result Effect.Http.Error Int)
    | GotCloudflareEgressForAdmin Effect.Lamdera.ClientId (Result Effect.Http.Error Int)
