module Evergreen.V263.Types exposing (..)

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
import Evergreen.V263.AiChat
import Evergreen.V263.Call
import Evergreen.V263.ChannelDescription
import Evergreen.V263.ChannelName
import Evergreen.V263.Cloudflare
import Evergreen.V263.Coord
import Evergreen.V263.CssPixels
import Evergreen.V263.CustomEmoji
import Evergreen.V263.Discord
import Evergreen.V263.DiscordAttachmentId
import Evergreen.V263.DiscordUserData
import Evergreen.V263.DmChannel
import Evergreen.V263.Editable
import Evergreen.V263.EmailAddress
import Evergreen.V263.Embed
import Evergreen.V263.Emoji
import Evergreen.V263.FileStatus
import Evergreen.V263.Go
import Evergreen.V263.GuildName
import Evergreen.V263.Id
import Evergreen.V263.ImageEditor
import Evergreen.V263.Local
import Evergreen.V263.LocalState
import Evergreen.V263.Log
import Evergreen.V263.LoginForm
import Evergreen.V263.MembersAndOwner
import Evergreen.V263.Message
import Evergreen.V263.MessageInput
import Evergreen.V263.MessageView
import Evergreen.V263.MyUi
import Evergreen.V263.NonemptyDict
import Evergreen.V263.NonemptySet
import Evergreen.V263.OneToOne
import Evergreen.V263.Pages.Admin
import Evergreen.V263.Pagination
import Evergreen.V263.PersonName
import Evergreen.V263.Ports
import Evergreen.V263.Postmark
import Evergreen.V263.Range
import Evergreen.V263.RichText
import Evergreen.V263.Route
import Evergreen.V263.SecretId
import Evergreen.V263.SessionIdHash
import Evergreen.V263.Slack
import Evergreen.V263.Sticker
import Evergreen.V263.TextEditor
import Evergreen.V263.ToBackendLog
import Evergreen.V263.Touch
import Evergreen.V263.TwoFactorAuthentication
import Evergreen.V263.Ui.Anim
import Evergreen.V263.Untrusted
import Evergreen.V263.User
import Evergreen.V263.UserAgent
import Evergreen.V263.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V263.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V263.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.Id.GuildId) Evergreen.V263.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId) Evergreen.V263.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V263.Discord.Id Evergreen.V263.Discord.PrivateChannelId) Evergreen.V263.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V263.Discord.Id Evergreen.V263.Discord.GuildId) Evergreen.V263.LocalState.DiscordFrontendGuild
    , user : Evergreen.V263.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId) Evergreen.V263.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId) Evergreen.V263.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId) Evergreen.V263.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V263.SessionIdHash.SessionIdHash Evergreen.V263.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V263.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.Id.StickerId) Evergreen.V263.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.Id.CustomEmojiId) Evergreen.V263.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V263.Call.CallId (Evergreen.V263.NonemptySet.NonemptySet ( Evergreen.V263.Id.Id Evergreen.V263.Id.UserId, Effect.Lamdera.ClientId ))
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type PublicGoMatch
    = PublicGoMatch_NotLoaded
    | PublicGoMatch_Loading
    | PublicGoMatch_Loaded Evergreen.V263.Go.PublicGoMatchData Evergreen.V263.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V263.Route.Route
    , windowSize : Evergreen.V263.Coord.Coord Evergreen.V263.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V263.Ports.NotificationPermission
    , pwaStatus : Evergreen.V263.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V263.UserAgent.UserAgent
    , publicGoMatch : PublicGoMatch
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V263.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V263.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V263.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.FileStatus.FileId) Evergreen.V263.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V263.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V263.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.FileStatus.FileId) Evergreen.V263.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V263.Id.Id Evergreen.V263.Id.GuildId) Evergreen.V263.ChannelName.ChannelName Evergreen.V263.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V263.Id.Id Evergreen.V263.Id.GuildId) (Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelId) Evergreen.V263.ChannelName.ChannelName Evergreen.V263.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V263.Id.Id Evergreen.V263.Id.GuildId) (Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelId)
    | Local_DeleteGuild (Evergreen.V263.Id.Id Evergreen.V263.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V263.Id.Id Evergreen.V263.Id.GuildId) (Evergreen.V263.UserSession.ToBeFilledInByBackend (Evergreen.V263.SecretId.SecretId Evergreen.V263.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V263.Id.Id Evergreen.V263.Id.GuildId) (Evergreen.V263.SecretId.SecretId Evergreen.V263.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V263.GuildName.GuildName (Evergreen.V263.UserSession.ToBeFilledInByBackend (Evergreen.V263.Id.Id Evergreen.V263.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V263.Id.AnyGuildOrDmId, Evergreen.V263.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V263.Id.AnyGuildOrDmId Evergreen.V263.Id.ThreadRouteWithMessage Evergreen.V263.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V263.Id.AnyGuildOrDmId Evergreen.V263.Id.ThreadRouteWithMessage Evergreen.V263.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V263.Id.GuildOrDmId Evergreen.V263.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.FileStatus.FileId) Evergreen.V263.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId) (Evergreen.V263.Discord.Id Evergreen.V263.Discord.GuildId) (Evergreen.V263.Discord.Id Evergreen.V263.Discord.ChannelId) Evergreen.V263.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V263.Id.DiscordGuildOrDmId_DmData (Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V263.Id.AnyGuildOrDmId Evergreen.V263.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V263.Id.AnyGuildOrDmId Evergreen.V263.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V263.Id.AnyGuildOrDmId Evergreen.V263.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V263.UserSession.SetViewing
    | Local_SetName Evergreen.V263.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V263.Id.GuildOrDmId (Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelMessageId) (Evergreen.V263.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelMessageId) (Evergreen.V263.Message.Message Evergreen.V263.Id.ChannelMessageId (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V263.Id.GuildOrDmId (Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelMessageId) (Evergreen.V263.Id.Id Evergreen.V263.Id.ThreadMessageId) (Evergreen.V263.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.Id.ThreadMessageId) (Evergreen.V263.Message.Message Evergreen.V263.Id.ThreadMessageId (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V263.Id.DiscordGuildOrDmId (Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelMessageId) (Evergreen.V263.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelMessageId) (Evergreen.V263.Message.Message Evergreen.V263.Id.ChannelMessageId (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V263.Id.DiscordGuildOrDmId (Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelMessageId) (Evergreen.V263.Id.Id Evergreen.V263.Id.ThreadMessageId) (Evergreen.V263.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.Id.ThreadMessageId) (Evergreen.V263.Message.Message Evergreen.V263.Id.ThreadMessageId (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V263.Id.Id Evergreen.V263.Id.GuildId) Evergreen.V263.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId) (Evergreen.V263.Discord.Id Evergreen.V263.Discord.GuildId) Evergreen.V263.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V263.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V263.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V263.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V263.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V263.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V263.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V263.NonemptySet.NonemptySet (Evergreen.V263.Id.Id Evergreen.V263.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V263.Call.LocalChange
    | Local_Go
        { otherUserId : Evergreen.V263.Id.Id Evergreen.V263.Id.UserId
        }
        Evergreen.V263.Go.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId) Effect.Time.Posix Evergreen.V263.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V263.RichText.RichText (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId))) Evergreen.V263.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.FileStatus.FileId) Evergreen.V263.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.Id.StickerId) Evergreen.V263.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V263.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V263.RichText.RichText (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId))) Evergreen.V263.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.FileStatus.FileId) Evergreen.V263.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.Id.StickerId) Evergreen.V263.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V263.Id.Id Evergreen.V263.Id.GuildId) Evergreen.V263.ChannelName.ChannelName Evergreen.V263.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V263.Id.Id Evergreen.V263.Id.GuildId) (Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelId) Evergreen.V263.ChannelName.ChannelName Evergreen.V263.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V263.Id.Id Evergreen.V263.Id.GuildId) (Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelId)
    | Server_DeleteGuild (Evergreen.V263.Id.Id Evergreen.V263.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId) (Evergreen.V263.Id.Id Evergreen.V263.Id.GuildId) (Evergreen.V263.SecretId.SecretId Evergreen.V263.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V263.Id.Id Evergreen.V263.Id.GuildId) (Evergreen.V263.SecretId.SecretId Evergreen.V263.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId) (Evergreen.V263.Id.Id Evergreen.V263.Id.GuildId) Evergreen.V263.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V263.LocalState.JoinGuildError
            { guildId : Evergreen.V263.Id.Id Evergreen.V263.Id.GuildId
            , guild : Evergreen.V263.LocalState.FrontendGuild
            , owner : Evergreen.V263.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId) Evergreen.V263.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId) Evergreen.V263.Id.GuildOrDmId Evergreen.V263.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId) (Evergreen.V263.Discord.Id Evergreen.V263.Discord.GuildId) (Evergreen.V263.Discord.Id Evergreen.V263.Discord.ChannelId) Evergreen.V263.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId) (Evergreen.V263.Discord.Id Evergreen.V263.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId) Evergreen.V263.Id.GuildOrDmId Evergreen.V263.Id.ThreadRouteWithMessage Evergreen.V263.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId) Evergreen.V263.Id.GuildOrDmId Evergreen.V263.Id.ThreadRouteWithMessage Evergreen.V263.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId) (Evergreen.V263.Discord.Id Evergreen.V263.Discord.GuildId) (Evergreen.V263.Discord.Id Evergreen.V263.Discord.ChannelId) Evergreen.V263.Id.ThreadRouteWithMessage Evergreen.V263.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId) (Evergreen.V263.Discord.Id Evergreen.V263.Discord.PrivateChannelId) (Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelMessageId) Evergreen.V263.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId) (Evergreen.V263.Discord.Id Evergreen.V263.Discord.GuildId) (Evergreen.V263.Discord.Id Evergreen.V263.Discord.ChannelId) Evergreen.V263.Id.ThreadRouteWithMessage Evergreen.V263.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId) (Evergreen.V263.Discord.Id Evergreen.V263.Discord.PrivateChannelId) (Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelMessageId) Evergreen.V263.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId) Evergreen.V263.Id.GuildOrDmId Evergreen.V263.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V263.RichText.RichText (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId))) (SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.FileStatus.FileId) Evergreen.V263.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId) (Evergreen.V263.Discord.Id Evergreen.V263.Discord.GuildId) (Evergreen.V263.Discord.Id Evergreen.V263.Discord.ChannelId) Evergreen.V263.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V263.RichText.RichText (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V263.Id.DiscordGuildOrDmId_DmData (Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V263.RichText.RichText (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId) Evergreen.V263.Id.AnyGuildOrDmId Evergreen.V263.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V263.Id.AnyGuildOrDmId Evergreen.V263.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V263.Discord.Id Evergreen.V263.Discord.GuildId) (Evergreen.V263.Discord.Id Evergreen.V263.Discord.ChannelId) Evergreen.V263.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V263.Discord.Id Evergreen.V263.Discord.PrivateChannelId) (Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId) Evergreen.V263.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId) Evergreen.V263.FileStatus.FileHash
    | Server_SetGuildIcon (Evergreen.V263.Id.Id Evergreen.V263.Id.GuildId) Evergreen.V263.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V263.Id.Id Evergreen.V263.Id.GuildId) Evergreen.V263.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V263.Discord.Id Evergreen.V263.Discord.GuildId) Evergreen.V263.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V263.SessionIdHash.SessionIdHash Evergreen.V263.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V263.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V263.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V263.Id.AnyGuildOrDmId, Evergreen.V263.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V263.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId) Evergreen.V263.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V263.Discord.Id Evergreen.V263.Discord.GuildId) (Evergreen.V263.Discord.Id Evergreen.V263.Discord.ChannelId) Evergreen.V263.ChannelName.ChannelName (Evergreen.V263.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V263.Discord.Id Evergreen.V263.Discord.PrivateChannelId)
        (Evergreen.V263.NonemptyDict.NonemptyDict
            (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V263.Discord.Id Evergreen.V263.Discord.GuildId) Evergreen.V263.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V263.Discord.Id Evergreen.V263.Discord.PrivateChannelId) Evergreen.V263.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId) Evergreen.V263.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId) (Maybe (Evergreen.V263.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V263.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V263.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V263.Id.Id Evergreen.V263.Id.GuildId) (Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelId) Evergreen.V263.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V263.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId) Evergreen.V263.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V263.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V263.Discord.Id Evergreen.V263.Discord.GuildId) (Evergreen.V263.Discord.Id Evergreen.V263.Discord.ChannelId) Evergreen.V263.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V263.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V263.Discord.Id Evergreen.V263.Discord.PrivateChannelId) (Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V263.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V263.Discord.Id Evergreen.V263.Discord.GuildId) Evergreen.V263.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V263.Discord.Id Evergreen.V263.Discord.GuildId) (Evergreen.V263.Discord.Id Evergreen.V263.Discord.ChannelId) (Evergreen.V263.Discord.OptionalData String) (Evergreen.V263.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V263.Discord.Id Evergreen.V263.Discord.GuildId)
        (Evergreen.V263.MembersAndOwner.MembersAndOwner
            (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V263.Discord.Id Evergreen.V263.Discord.GuildId) (Evergreen.V263.Discord.Id Evergreen.V263.Discord.ChannelId) (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId) Evergreen.V263.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.Id.StickerId) Evergreen.V263.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.Id.CustomEmojiId) Evergreen.V263.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V263.Call.ServerChange
    | Server_Go
        (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId)
        { otherUserId : Evergreen.V263.Id.Id Evergreen.V263.Id.UserId
        }
        Evergreen.V263.Go.LocalChange


type LocalMsg
    = LocalChange (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V263.Id.Id Evergreen.V263.Id.GuildId) (Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelId) Evergreen.V263.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V263.Discord.Id Evergreen.V263.Discord.GuildId) (Evergreen.V263.Discord.Id Evergreen.V263.Discord.ChannelId) Evergreen.V263.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.FileStatus.FileId) Evergreen.V263.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V263.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V263.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V263.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V263.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V263.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V263.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V263.Coord.Coord Evergreen.V263.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V263.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V263.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V263.Id.AnyGuildOrDmId Evergreen.V263.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V263.Id.AnyGuildOrDmId Evergreen.V263.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V263.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V263.Coord.Coord Evergreen.V263.CssPixels.CssPixels) (Maybe Evergreen.V263.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V263.Id.AnyGuildOrDmId, Evergreen.V263.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelMessageId) (Evergreen.V263.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.Id.ThreadMessageId) (Evergreen.V263.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V263.Editable.Model
    , showLinkDiscordSetup : Bool
    , domainWhitelistInput : String
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V263.Local.Local LocalMsg Evergreen.V263.LocalState.LocalState
    , admin : Evergreen.V263.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V263.Id.AnyGuildOrDmId, Evergreen.V263.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V263.Id.Id Evergreen.V263.Id.GuildId, Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V263.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V263.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V263.Id.AnyGuildOrDmId, Evergreen.V263.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V263.Id.AnyGuildOrDmId, Evergreen.V263.Id.ThreadRoute ) (Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : Evergreen.V263.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V263.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V263.Id.AnyGuildOrDmId, Evergreen.V263.Id.ThreadRoute ) (Evergreen.V263.NonemptyDict.NonemptyDict (Evergreen.V263.Id.Id Evergreen.V263.FileStatus.FileId) Evergreen.V263.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V263.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V263.TextEditor.Model
    , profilePictureEditor : Evergreen.V263.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V263.Id.Id Evergreen.V263.Id.GuildId, Evergreen.V263.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V263.Emoji.Model
    , voiceChat : Evergreen.V263.Call.Model
    , currentDmGoMatch : SeqDict.SeqDict ( Evergreen.V263.Id.Id Evergreen.V263.Id.UserId, Maybe (Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelMessageId) ) Evergreen.V263.Go.Model
    , fileDragOverCount : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V263.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V263.SecretId.SecretId Evergreen.V263.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V263.Range.Range
                , direction : Evergreen.V263.Range.SelectionDirection
                }
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V263.NonemptyDict.NonemptyDict Int Evergreen.V263.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V263.NonemptyDict.NonemptyDict Int Evergreen.V263.Touch.Touch
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
    | AdminToFrontend Evergreen.V263.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V263.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V263.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V263.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V263.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V263.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V263.Go.PublicGoMatchResponse)


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V263.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V263.Coord.Coord Evergreen.V263.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V263.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V263.MyUi.LastCopy
    , notificationPermission : Evergreen.V263.Ports.NotificationPermission
    , pwaStatus : Evergreen.V263.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V263.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V263.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V263.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V263.Id.Id Evergreen.V263.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V263.Id.Id Evergreen.V263.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V263.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V263.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V263.Coord.Coord Evergreen.V263.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V263.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V263.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V263.Id.Id Evergreen.V263.Id.GuildId, Evergreen.V263.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V263.DmChannel.DmChannelId, Evergreen.V263.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V263.Discord.Id Evergreen.V263.Discord.GuildId, Evergreen.V263.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V263.Discord.Id Evergreen.V263.Discord.PrivateChannelId, Evergreen.V263.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V263.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V263.NonemptyDict.NonemptyDict (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId) Evergreen.V263.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V263.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V263.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V263.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V263.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId) Evergreen.V263.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId) Evergreen.V263.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V263.Id.Id Evergreen.V263.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.Id.GuildId) Evergreen.V263.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.Id.GuildId) Evergreen.V263.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V263.Discord.Id Evergreen.V263.Discord.GuildId) Evergreen.V263.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V263.DmChannel.DmChannelId Evergreen.V263.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V263.Discord.Id Evergreen.V263.Discord.PrivateChannelId) Evergreen.V263.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V263.OneToOne.OneToOne (Evergreen.V263.Slack.Id Evergreen.V263.Slack.ChannelId) Evergreen.V263.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V263.OneToOne.OneToOne String (Evergreen.V263.Id.Id Evergreen.V263.Id.GuildId)
    , slackUsers : Evergreen.V263.OneToOne.OneToOne (Evergreen.V263.Slack.Id Evergreen.V263.Slack.UserId) (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId)
    , slackServers : Evergreen.V263.OneToOne.OneToOne (Evergreen.V263.Slack.Id Evergreen.V263.Slack.TeamId) (Evergreen.V263.Id.Id Evergreen.V263.Id.GuildId)
    , slackToken : Maybe Evergreen.V263.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V263.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V263.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V263.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V263.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V263.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V263.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V263.Cloudflare.AnalyticsApiToken
    , textEditor : Evergreen.V263.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId) Evergreen.V263.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId, Evergreen.V263.Discord.Id Evergreen.V263.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V263.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V263.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V263.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V263.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId) (Evergreen.V263.LocalState.LoadingDiscordChannel (List Evergreen.V263.Discord.Message))
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V263.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.Id.StickerId) Evergreen.V263.Sticker.StickerData
    , discordStickers : Evergreen.V263.OneToOne.OneToOne (Evergreen.V263.Discord.Id Evergreen.V263.Discord.StickerId) (Evergreen.V263.Id.Id Evergreen.V263.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.Id.CustomEmojiId) Evergreen.V263.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V263.OneToOne.OneToOne Evergreen.V263.RichText.DiscordCustomEmojiIdAndName (Evergreen.V263.Id.Id Evergreen.V263.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V263.Postmark.ApiKey
    , serverSecret : Evergreen.V263.SecretId.SecretId Evergreen.V263.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V263.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V263.OneToOne.OneToOne (Evergreen.V263.SecretId.SecretId Evergreen.V263.Id.GoMatchPublicId) ( Evergreen.V263.DmChannel.DmChannelId, Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelMessageId )
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V263.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V263.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V263.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V263.Route.Route
    | SelectedFilesToAttach ( Evergreen.V263.Id.AnyGuildOrDmId, Evergreen.V263.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V263.Id.Id Evergreen.V263.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V263.Id.Id Evergreen.V263.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V263.Id.Id Evergreen.V263.Id.GuildId) (Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelId) Evergreen.V263.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V263.Id.Id Evergreen.V263.Id.GuildId) (Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelId) Evergreen.V263.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V263.Discord.Id Evergreen.V263.Discord.GuildId) (Evergreen.V263.Discord.Id Evergreen.V263.Discord.ChannelId) Evergreen.V263.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V263.Discord.Id Evergreen.V263.Discord.GuildId) (Evergreen.V263.Discord.Id Evergreen.V263.Discord.ChannelId) Evergreen.V263.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V263.Id.Id Evergreen.V263.Id.GuildId) (Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V263.Id.Id Evergreen.V263.Id.GuildId) (Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V263.Id.Id Evergreen.V263.Id.GuildId) (Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V263.Id.Id Evergreen.V263.Id.GuildId) (Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V263.Id.Id Evergreen.V263.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V263.Id.Id Evergreen.V263.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V263.Id.Id Evergreen.V263.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V263.Id.Id Evergreen.V263.Id.GuildId) (Evergreen.V263.SecretId.SecretId Evergreen.V263.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V263.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V263.Id.AnyGuildOrDmId Evergreen.V263.Id.ThreadRouteWithMessage (Evergreen.V263.Coord.Coord Evergreen.V263.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V263.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V263.Id.AnyGuildOrDmId Evergreen.V263.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V263.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V263.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V263.Id.AnyGuildOrDmId, Evergreen.V263.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V263.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V263.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V263.Id.AnyGuildOrDmId, Evergreen.V263.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V263.NonemptyDict.NonemptyDict Int Evergreen.V263.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V263.NonemptyDict.NonemptyDict Int Evergreen.V263.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V263.Id.AnyGuildOrDmId Evergreen.V263.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V263.Id.AnyGuildOrDmId Evergreen.V263.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V263.NonemptySet.NonemptySet (Evergreen.V263.Id.Id Evergreen.V263.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V263.Id.AnyGuildOrDmId, Evergreen.V263.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V263.Id.AnyGuildOrDmId Evergreen.V263.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V263.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V263.AiChat.Msg
    | GoMsg Evergreen.V263.Go.Msg
    | GoSpectatorMsg Evergreen.V263.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V263.Editable.Msg Evergreen.V263.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V263.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V263.Id.Id Evergreen.V263.Id.GuildId) Evergreen.V263.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V263.Id.AnyGuildOrDmId, Evergreen.V263.Id.ThreadRoute ) (Evergreen.V263.Id.Id Evergreen.V263.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V263.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V263.Id.AnyGuildOrDmId, Evergreen.V263.Id.ThreadRoute ) (Evergreen.V263.Id.Id Evergreen.V263.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V263.Id.AnyGuildOrDmId, Evergreen.V263.Id.ThreadRoute ) (Evergreen.V263.Id.Id Evergreen.V263.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V263.Id.AnyGuildOrDmId, Evergreen.V263.Id.ThreadRoute )
        { fileId : Evergreen.V263.Id.Id Evergreen.V263.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V263.Id.AnyGuildOrDmId, Evergreen.V263.Id.ThreadRoute ) (Evergreen.V263.Id.Id Evergreen.V263.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V263.Id.AnyGuildOrDmId, Evergreen.V263.Id.ThreadRoute ) (Evergreen.V263.Id.Id Evergreen.V263.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V263.Id.AnyGuildOrDmId, Evergreen.V263.Id.ThreadRoute )
        { fileId : Evergreen.V263.Id.Id Evergreen.V263.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V263.Id.AnyGuildOrDmId, Evergreen.V263.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V263.Id.AnyGuildOrDmId, Evergreen.V263.Id.ThreadRoute ) (Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelMessageId) (Evergreen.V263.Id.Id Evergreen.V263.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V263.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V263.Id.AnyGuildOrDmId, Evergreen.V263.Id.ThreadRoute ) (Evergreen.V263.Id.Id Evergreen.V263.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V263.Id.AnyGuildOrDmId Evergreen.V263.Id.ThreadRouteWithMessage Evergreen.V263.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V263.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V263.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V263.Id.Id Evergreen.V263.Id.GuildId) Evergreen.V263.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId) (Evergreen.V263.Discord.Id Evergreen.V263.Discord.GuildId) Evergreen.V263.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V263.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V263.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId
        , otherUserId : Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V263.Id.AnyGuildOrDmId Evergreen.V263.Id.ThreadRoute Evergreen.V263.MessageInput.Msg
    | MessageInputMsg Evergreen.V263.Id.AnyGuildOrDmId Evergreen.V263.Id.ThreadRoute Evergreen.V263.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V263.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V263.Range.Range, Evergreen.V263.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V263.Range.Range, Evergreen.V263.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V263.Call.FromJs)
    | VoiceChatMsg Evergreen.V263.Call.Msg
    | PressedChannelHeaderTab Evergreen.V263.Route.DmChannelHeaderTab
    | FileDragEnter
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V263.Id.Id Evergreen.V263.Id.GuildId) (Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelId) Evergreen.V263.Id.ThreadRoute
    | InitialLoadRequested_Dm Evergreen.V263.DmChannel.DmChannelId Evergreen.V263.Id.ThreadRoute
    | InitialLoadRequested_Discord Evergreen.V263.Id.DiscordGuildOrDmId Evergreen.V263.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V263.Id.Id Evergreen.V263.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V263.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V263.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V263.Untrusted.Untrusted Evergreen.V263.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V263.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V263.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V263.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V263.Id.Id Evergreen.V263.Id.GuildId) (Evergreen.V263.SecretId.SecretId Evergreen.V263.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V263.PersonName.PersonName Evergreen.V263.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V263.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V263.Slack.OAuthCode Evergreen.V263.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V263.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V263.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V263.Id.Id Evergreen.V263.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V263.SecretId.SecretId Evergreen.V263.Id.GoMatchPublicId)


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V263.Discord.Id Evergreen.V263.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V263.Discord.Id Evergreen.V263.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V263.EmailAddress.EmailAddress (Result Evergreen.V263.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V263.EmailAddress.EmailAddress (Result Evergreen.V263.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V263.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V263.Discord.Id Evergreen.V263.Discord.GuildId) (Evergreen.V263.Discord.Id Evergreen.V263.Discord.ChannelId) Evergreen.V263.Id.ThreadRouteWithMaybeMessage (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId) (Result Evergreen.V263.Discord.HttpError Evergreen.V263.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V263.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V263.Discord.Id Evergreen.V263.Discord.PrivateChannelId) (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId) (Result Evergreen.V263.Discord.HttpError Evergreen.V263.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V263.Discord.Id Evergreen.V263.Discord.GuildId) (Evergreen.V263.Discord.Id Evergreen.V263.Discord.ChannelId) Evergreen.V263.Id.ThreadRouteWithMessage (Evergreen.V263.Discord.Id Evergreen.V263.Discord.MessageId) (Result Evergreen.V263.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V263.Discord.Id Evergreen.V263.Discord.PrivateChannelId) (Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelMessageId) (Evergreen.V263.Discord.Id Evergreen.V263.Discord.MessageId) (Result Evergreen.V263.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V263.Discord.Id Evergreen.V263.Discord.GuildId) (Evergreen.V263.Discord.Id Evergreen.V263.Discord.ChannelId) Evergreen.V263.Id.ThreadRouteWithMessage (Evergreen.V263.Discord.Id Evergreen.V263.Discord.MessageId) (Result Evergreen.V263.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V263.Discord.Id Evergreen.V263.Discord.PrivateChannelId) (Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelMessageId) (Evergreen.V263.Discord.Id Evergreen.V263.Discord.MessageId) (Result Evergreen.V263.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V263.Discord.Id Evergreen.V263.Discord.GuildId) (Evergreen.V263.Discord.Id Evergreen.V263.Discord.ChannelId) Evergreen.V263.Id.ThreadRouteWithMessage (Evergreen.V263.Discord.Id Evergreen.V263.Discord.MessageId) Evergreen.V263.Emoji.EmojiOrCustomEmoji (Result Evergreen.V263.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V263.Discord.Id Evergreen.V263.Discord.PrivateChannelId) (Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelMessageId) (Evergreen.V263.Discord.Id Evergreen.V263.Discord.MessageId) Evergreen.V263.Emoji.EmojiOrCustomEmoji (Result Evergreen.V263.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V263.Discord.Id Evergreen.V263.Discord.GuildId) (Evergreen.V263.Discord.Id Evergreen.V263.Discord.ChannelId) Evergreen.V263.Id.ThreadRouteWithMessage (Evergreen.V263.Discord.Id Evergreen.V263.Discord.MessageId) Evergreen.V263.Emoji.EmojiOrCustomEmoji (Result Evergreen.V263.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V263.Discord.Id Evergreen.V263.Discord.PrivateChannelId) (Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelMessageId) (Evergreen.V263.Discord.Id Evergreen.V263.Discord.MessageId) Evergreen.V263.Emoji.EmojiOrCustomEmoji (Result Evergreen.V263.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V263.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V263.Discord.HttpError (List ( Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId, Maybe Evergreen.V263.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V263.Slack.CurrentUser
            , team : Evergreen.V263.Slack.Team
            , users : List Evergreen.V263.Slack.User
            , channels : List ( Evergreen.V263.Slack.Channel, List Evergreen.V263.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId) (Result Effect.Http.Error Evergreen.V263.Slack.TokenResponse)
    | GotCloudflareSessionCreated Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V263.Local.ChangeId Effect.Time.Posix Evergreen.V263.Call.CallId Evergreen.V263.Cloudflare.Sdp (List String) (Result Effect.Http.Error Evergreen.V263.Cloudflare.RealtimeSessionId)
    | GotCloudflareSession Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V263.Local.ChangeId Effect.Time.Posix Evergreen.V263.Call.CallId Evergreen.V263.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V263.Cloudflare.PushTracksResult)
    | GotCloudflarePullOffer Effect.Time.Posix Effect.Lamdera.ClientId Evergreen.V263.Local.ChangeId Evergreen.V263.Call.ConnectionId Evergreen.V263.Cloudflare.RealtimeSessionId (List Evergreen.V263.Cloudflare.TrackName) (Result Effect.Http.Error Evergreen.V263.Cloudflare.PullTracksResult)
    | GotCloudflareRenegotiateAck Effect.Lamdera.ClientId Evergreen.V263.Local.ChangeId Evergreen.V263.Cloudflare.Sdp (Result Effect.Http.Error ())
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId) Evergreen.V263.Discord.UserAuth (Result Evergreen.V263.Discord.HttpError Evergreen.V263.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId) (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId) (Result Evergreen.V263.Discord.HttpError Evergreen.V263.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId)
        (Result
            Evergreen.V263.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V263.Discord.Id Evergreen.V263.Discord.PrivateChannelId
                , members : List (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId)
                }
            , List
                ( Evergreen.V263.Discord.Id Evergreen.V263.Discord.GuildId
                , { guild : Evergreen.V263.Discord.GatewayGuild
                  , channels : List Evergreen.V263.Discord.Channel
                  , icon : Maybe Evergreen.V263.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId) Bool Evergreen.V263.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V263.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V263.Discord.Id Evergreen.V263.Discord.AttachmentId, Evergreen.V263.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V263.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V263.Discord.Id Evergreen.V263.Discord.AttachmentId, Evergreen.V263.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId) (Evergreen.V263.Discord.Id Evergreen.V263.Discord.GuildId) (Evergreen.V263.Discord.Id Evergreen.V263.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V263.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V263.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId) (Evergreen.V263.Discord.Id Evergreen.V263.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V263.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V263.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId) (Evergreen.V263.Discord.Id Evergreen.V263.Discord.GuildId) (Evergreen.V263.Discord.Id Evergreen.V263.Discord.ChannelId) (Result Evergreen.V263.Discord.HttpError (List Evergreen.V263.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId) (Evergreen.V263.Discord.Id Evergreen.V263.Discord.PrivateChannelId) (Result Evergreen.V263.Discord.HttpError (List Evergreen.V263.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V263.Id.Id Evergreen.V263.Id.GuildId) (Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelId) Evergreen.V263.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V263.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V263.DmChannel.DmChannelId Evergreen.V263.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V263.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V263.Discord.Id Evergreen.V263.Discord.GuildId) (Evergreen.V263.Discord.Id Evergreen.V263.Discord.ChannelId) Evergreen.V263.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V263.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V263.Discord.Id Evergreen.V263.Discord.PrivateChannelId) (Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V263.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId)
        (Evergreen.V263.Discord.Id Evergreen.V263.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V263.Discord.HttpError
            { guild : Evergreen.V263.Discord.GatewayGuild
            , channels : List Evergreen.V263.Discord.Channel
            , icon : Maybe Evergreen.V263.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V263.Discord.Id Evergreen.V263.Discord.GuildId) (Result Evergreen.V263.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V263.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId) (List ( Evergreen.V263.Id.Id Evergreen.V263.Id.StickerId, Result Effect.Http.Error Evergreen.V263.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V263.Id.Id Evergreen.V263.Id.StickerId, Result Effect.Http.Error Evergreen.V263.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId) (List ( Evergreen.V263.Id.Id Evergreen.V263.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V263.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V263.Id.Id Evergreen.V263.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V263.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V263.Discord.HttpError (List Evergreen.V263.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V263.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V263.SecretId.SecretId Evergreen.V263.SecretId.ServerSecret))
    | GotTimeForWebsocketListenClose (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | GotCloudflareUsage Effect.Time.Posix (Result Effect.Http.Error Int)
    | GotCloudflareEgressForAdmin Effect.Lamdera.ClientId (Result Effect.Http.Error Int)
