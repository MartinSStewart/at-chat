module Evergreen.V264.Types exposing (..)

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
import Evergreen.V264.AiChat
import Evergreen.V264.Call
import Evergreen.V264.ChannelDescription
import Evergreen.V264.ChannelName
import Evergreen.V264.Cloudflare
import Evergreen.V264.Coord
import Evergreen.V264.CssPixels
import Evergreen.V264.CustomEmoji
import Evergreen.V264.Discord
import Evergreen.V264.DiscordAttachmentId
import Evergreen.V264.DiscordUserData
import Evergreen.V264.DmChannel
import Evergreen.V264.Editable
import Evergreen.V264.EmailAddress
import Evergreen.V264.Embed
import Evergreen.V264.Emoji
import Evergreen.V264.FileStatus
import Evergreen.V264.Go
import Evergreen.V264.GuildName
import Evergreen.V264.Id
import Evergreen.V264.ImageEditor
import Evergreen.V264.Local
import Evergreen.V264.LocalState
import Evergreen.V264.Log
import Evergreen.V264.LoginForm
import Evergreen.V264.MembersAndOwner
import Evergreen.V264.Message
import Evergreen.V264.MessageInput
import Evergreen.V264.MessageView
import Evergreen.V264.MyUi
import Evergreen.V264.NonemptyDict
import Evergreen.V264.NonemptySet
import Evergreen.V264.OneToOne
import Evergreen.V264.Pages.Admin
import Evergreen.V264.Pagination
import Evergreen.V264.PersonName
import Evergreen.V264.Ports
import Evergreen.V264.Postmark
import Evergreen.V264.Range
import Evergreen.V264.RichText
import Evergreen.V264.Route
import Evergreen.V264.SecretId
import Evergreen.V264.SessionIdHash
import Evergreen.V264.Slack
import Evergreen.V264.Sticker
import Evergreen.V264.TextEditor
import Evergreen.V264.ToBackendLog
import Evergreen.V264.Touch
import Evergreen.V264.TwoFactorAuthentication
import Evergreen.V264.Ui.Anim
import Evergreen.V264.Untrusted
import Evergreen.V264.User
import Evergreen.V264.UserAgent
import Evergreen.V264.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V264.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V264.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.Id.GuildId) Evergreen.V264.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId) Evergreen.V264.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V264.Discord.Id Evergreen.V264.Discord.PrivateChannelId) Evergreen.V264.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V264.Discord.Id Evergreen.V264.Discord.GuildId) Evergreen.V264.LocalState.DiscordFrontendGuild
    , user : Evergreen.V264.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId) Evergreen.V264.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId) Evergreen.V264.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId) Evergreen.V264.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V264.SessionIdHash.SessionIdHash Evergreen.V264.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V264.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.Id.StickerId) Evergreen.V264.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.Id.CustomEmojiId) Evergreen.V264.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V264.Call.CallId (Evergreen.V264.NonemptySet.NonemptySet ( Evergreen.V264.Id.Id Evergreen.V264.Id.UserId, Effect.Lamdera.ClientId ))
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type PublicGoMatch
    = PublicGoMatch_NotLoaded
    | PublicGoMatch_Loading
    | PublicGoMatch_Loaded Evergreen.V264.Go.PublicGoMatchData Evergreen.V264.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V264.Route.Route
    , windowSize : Evergreen.V264.Coord.Coord Evergreen.V264.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V264.Ports.NotificationPermission
    , pwaStatus : Evergreen.V264.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V264.UserAgent.UserAgent
    , publicGoMatch : PublicGoMatch
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V264.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V264.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V264.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.FileStatus.FileId) Evergreen.V264.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V264.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V264.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.FileStatus.FileId) Evergreen.V264.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V264.Id.Id Evergreen.V264.Id.GuildId) Evergreen.V264.ChannelName.ChannelName Evergreen.V264.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V264.Id.Id Evergreen.V264.Id.GuildId) (Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelId) Evergreen.V264.ChannelName.ChannelName Evergreen.V264.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V264.Id.Id Evergreen.V264.Id.GuildId) (Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelId)
    | Local_DeleteGuild (Evergreen.V264.Id.Id Evergreen.V264.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V264.Id.Id Evergreen.V264.Id.GuildId) (Evergreen.V264.UserSession.ToBeFilledInByBackend (Evergreen.V264.SecretId.SecretId Evergreen.V264.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V264.Id.Id Evergreen.V264.Id.GuildId) (Evergreen.V264.SecretId.SecretId Evergreen.V264.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V264.GuildName.GuildName (Evergreen.V264.UserSession.ToBeFilledInByBackend (Evergreen.V264.Id.Id Evergreen.V264.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V264.Id.AnyGuildOrDmId, Evergreen.V264.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V264.Id.AnyGuildOrDmId Evergreen.V264.Id.ThreadRouteWithMessage Evergreen.V264.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V264.Id.AnyGuildOrDmId Evergreen.V264.Id.ThreadRouteWithMessage Evergreen.V264.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V264.Id.GuildOrDmId Evergreen.V264.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.FileStatus.FileId) Evergreen.V264.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId) (Evergreen.V264.Discord.Id Evergreen.V264.Discord.GuildId) (Evergreen.V264.Discord.Id Evergreen.V264.Discord.ChannelId) Evergreen.V264.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V264.Id.DiscordGuildOrDmId_DmData (Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V264.Id.AnyGuildOrDmId Evergreen.V264.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V264.Id.AnyGuildOrDmId Evergreen.V264.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V264.Id.AnyGuildOrDmId Evergreen.V264.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V264.UserSession.SetViewing
    | Local_SetName Evergreen.V264.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V264.Id.GuildOrDmId (Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelMessageId) (Evergreen.V264.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelMessageId) (Evergreen.V264.Message.Message Evergreen.V264.Id.ChannelMessageId (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V264.Id.GuildOrDmId (Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelMessageId) (Evergreen.V264.Id.Id Evergreen.V264.Id.ThreadMessageId) (Evergreen.V264.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.Id.ThreadMessageId) (Evergreen.V264.Message.Message Evergreen.V264.Id.ThreadMessageId (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V264.Id.DiscordGuildOrDmId (Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelMessageId) (Evergreen.V264.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelMessageId) (Evergreen.V264.Message.Message Evergreen.V264.Id.ChannelMessageId (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V264.Id.DiscordGuildOrDmId (Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelMessageId) (Evergreen.V264.Id.Id Evergreen.V264.Id.ThreadMessageId) (Evergreen.V264.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.Id.ThreadMessageId) (Evergreen.V264.Message.Message Evergreen.V264.Id.ThreadMessageId (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V264.Id.Id Evergreen.V264.Id.GuildId) Evergreen.V264.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId) (Evergreen.V264.Discord.Id Evergreen.V264.Discord.GuildId) Evergreen.V264.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V264.UserSession.NotificationMode
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V264.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V264.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V264.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V264.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V264.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V264.NonemptySet.NonemptySet (Evergreen.V264.Id.Id Evergreen.V264.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V264.Call.LocalChange
    | Local_Go
        { otherUserId : Evergreen.V264.Id.Id Evergreen.V264.Id.UserId
        }
        Evergreen.V264.Go.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId) Effect.Time.Posix Evergreen.V264.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V264.RichText.RichText (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId))) Evergreen.V264.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.FileStatus.FileId) Evergreen.V264.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.Id.StickerId) Evergreen.V264.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V264.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V264.RichText.RichText (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId))) Evergreen.V264.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.FileStatus.FileId) Evergreen.V264.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.Id.StickerId) Evergreen.V264.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V264.Id.Id Evergreen.V264.Id.GuildId) Evergreen.V264.ChannelName.ChannelName Evergreen.V264.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V264.Id.Id Evergreen.V264.Id.GuildId) (Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelId) Evergreen.V264.ChannelName.ChannelName Evergreen.V264.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V264.Id.Id Evergreen.V264.Id.GuildId) (Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelId)
    | Server_DeleteGuild (Evergreen.V264.Id.Id Evergreen.V264.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId) (Evergreen.V264.Id.Id Evergreen.V264.Id.GuildId) (Evergreen.V264.SecretId.SecretId Evergreen.V264.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V264.Id.Id Evergreen.V264.Id.GuildId) (Evergreen.V264.SecretId.SecretId Evergreen.V264.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId) (Evergreen.V264.Id.Id Evergreen.V264.Id.GuildId) Evergreen.V264.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V264.LocalState.JoinGuildError
            { guildId : Evergreen.V264.Id.Id Evergreen.V264.Id.GuildId
            , guild : Evergreen.V264.LocalState.FrontendGuild
            , owner : Evergreen.V264.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId) Evergreen.V264.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId) Evergreen.V264.Id.GuildOrDmId Evergreen.V264.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId) (Evergreen.V264.Discord.Id Evergreen.V264.Discord.GuildId) (Evergreen.V264.Discord.Id Evergreen.V264.Discord.ChannelId) Evergreen.V264.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId) (Evergreen.V264.Discord.Id Evergreen.V264.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId) Evergreen.V264.Id.GuildOrDmId Evergreen.V264.Id.ThreadRouteWithMessage Evergreen.V264.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId) Evergreen.V264.Id.GuildOrDmId Evergreen.V264.Id.ThreadRouteWithMessage Evergreen.V264.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId) (Evergreen.V264.Discord.Id Evergreen.V264.Discord.GuildId) (Evergreen.V264.Discord.Id Evergreen.V264.Discord.ChannelId) Evergreen.V264.Id.ThreadRouteWithMessage Evergreen.V264.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId) (Evergreen.V264.Discord.Id Evergreen.V264.Discord.PrivateChannelId) (Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelMessageId) Evergreen.V264.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId) (Evergreen.V264.Discord.Id Evergreen.V264.Discord.GuildId) (Evergreen.V264.Discord.Id Evergreen.V264.Discord.ChannelId) Evergreen.V264.Id.ThreadRouteWithMessage Evergreen.V264.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId) (Evergreen.V264.Discord.Id Evergreen.V264.Discord.PrivateChannelId) (Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelMessageId) Evergreen.V264.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId) Evergreen.V264.Id.GuildOrDmId Evergreen.V264.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V264.RichText.RichText (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId))) (SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.FileStatus.FileId) Evergreen.V264.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId) (Evergreen.V264.Discord.Id Evergreen.V264.Discord.GuildId) (Evergreen.V264.Discord.Id Evergreen.V264.Discord.ChannelId) Evergreen.V264.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V264.RichText.RichText (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V264.Id.DiscordGuildOrDmId_DmData (Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V264.RichText.RichText (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId) Evergreen.V264.Id.AnyGuildOrDmId Evergreen.V264.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V264.Id.AnyGuildOrDmId Evergreen.V264.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V264.Discord.Id Evergreen.V264.Discord.GuildId) (Evergreen.V264.Discord.Id Evergreen.V264.Discord.ChannelId) Evergreen.V264.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V264.Discord.Id Evergreen.V264.Discord.PrivateChannelId) (Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId) Evergreen.V264.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId) Evergreen.V264.FileStatus.FileHash
    | Server_SetGuildIcon (Evergreen.V264.Id.Id Evergreen.V264.Id.GuildId) Evergreen.V264.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V264.Id.Id Evergreen.V264.Id.GuildId) Evergreen.V264.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V264.Discord.Id Evergreen.V264.Discord.GuildId) Evergreen.V264.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V264.SessionIdHash.SessionIdHash Evergreen.V264.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V264.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V264.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V264.Id.AnyGuildOrDmId, Evergreen.V264.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V264.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId) Evergreen.V264.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V264.Discord.Id Evergreen.V264.Discord.GuildId) (Evergreen.V264.Discord.Id Evergreen.V264.Discord.ChannelId) Evergreen.V264.ChannelName.ChannelName (Evergreen.V264.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V264.Discord.Id Evergreen.V264.Discord.PrivateChannelId)
        (Evergreen.V264.NonemptyDict.NonemptyDict
            (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V264.Discord.Id Evergreen.V264.Discord.GuildId) Evergreen.V264.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V264.Discord.Id Evergreen.V264.Discord.PrivateChannelId) Evergreen.V264.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId) Evergreen.V264.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId) (Maybe (Evergreen.V264.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V264.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V264.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V264.Id.Id Evergreen.V264.Id.GuildId) (Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelId) Evergreen.V264.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V264.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId) Evergreen.V264.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V264.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V264.Discord.Id Evergreen.V264.Discord.GuildId) (Evergreen.V264.Discord.Id Evergreen.V264.Discord.ChannelId) Evergreen.V264.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V264.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V264.Discord.Id Evergreen.V264.Discord.PrivateChannelId) (Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V264.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V264.Discord.Id Evergreen.V264.Discord.GuildId) Evergreen.V264.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V264.Discord.Id Evergreen.V264.Discord.GuildId) (Evergreen.V264.Discord.Id Evergreen.V264.Discord.ChannelId) (Evergreen.V264.Discord.OptionalData String) (Evergreen.V264.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V264.Discord.Id Evergreen.V264.Discord.GuildId)
        (Evergreen.V264.MembersAndOwner.MembersAndOwner
            (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V264.Discord.Id Evergreen.V264.Discord.GuildId) (Evergreen.V264.Discord.Id Evergreen.V264.Discord.ChannelId) (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId) Evergreen.V264.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.Id.StickerId) Evergreen.V264.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.Id.CustomEmojiId) Evergreen.V264.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V264.Call.ServerChange
    | Server_Go
        (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId)
        { otherUserId : Evergreen.V264.Id.Id Evergreen.V264.Id.UserId
        }
        Evergreen.V264.Go.LocalChange


type LocalMsg
    = LocalChange (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V264.Id.Id Evergreen.V264.Id.GuildId) (Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelId) Evergreen.V264.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V264.Discord.Id Evergreen.V264.Discord.GuildId) (Evergreen.V264.Discord.Id Evergreen.V264.Discord.ChannelId) Evergreen.V264.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.FileStatus.FileId) Evergreen.V264.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V264.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V264.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V264.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V264.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V264.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V264.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V264.Coord.Coord Evergreen.V264.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V264.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V264.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V264.Id.AnyGuildOrDmId Evergreen.V264.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V264.Id.AnyGuildOrDmId Evergreen.V264.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V264.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V264.Coord.Coord Evergreen.V264.CssPixels.CssPixels) (Maybe Evergreen.V264.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V264.Id.AnyGuildOrDmId, Evergreen.V264.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelMessageId) (Evergreen.V264.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.Id.ThreadMessageId) (Evergreen.V264.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V264.Editable.Model
    , showLinkDiscordSetup : Bool
    , domainWhitelistInput : String
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V264.Local.Local LocalMsg Evergreen.V264.LocalState.LocalState
    , admin : Evergreen.V264.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V264.Id.AnyGuildOrDmId, Evergreen.V264.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V264.Id.Id Evergreen.V264.Id.GuildId, Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V264.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V264.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V264.Id.AnyGuildOrDmId, Evergreen.V264.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V264.Id.AnyGuildOrDmId, Evergreen.V264.Id.ThreadRoute ) (Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : Evergreen.V264.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V264.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V264.Id.AnyGuildOrDmId, Evergreen.V264.Id.ThreadRoute ) (Evergreen.V264.NonemptyDict.NonemptyDict (Evergreen.V264.Id.Id Evergreen.V264.FileStatus.FileId) Evergreen.V264.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V264.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V264.TextEditor.Model
    , profilePictureEditor : Evergreen.V264.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V264.Id.Id Evergreen.V264.Id.GuildId, Evergreen.V264.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V264.Emoji.Model
    , voiceChat : Evergreen.V264.Call.Model
    , currentDmGoMatch : SeqDict.SeqDict ( Evergreen.V264.Id.Id Evergreen.V264.Id.UserId, Maybe (Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelMessageId) ) Evergreen.V264.Go.Model
    , fileDragOverCount : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V264.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V264.SecretId.SecretId Evergreen.V264.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V264.Range.Range
                , direction : Evergreen.V264.Range.SelectionDirection
                }
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V264.NonemptyDict.NonemptyDict Int Evergreen.V264.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V264.NonemptyDict.NonemptyDict Int Evergreen.V264.Touch.Touch
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
    | AdminToFrontend Evergreen.V264.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V264.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V264.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V264.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V264.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V264.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V264.Go.PublicGoMatchResponse)


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V264.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V264.Coord.Coord Evergreen.V264.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V264.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V264.MyUi.LastCopy
    , notificationPermission : Evergreen.V264.Ports.NotificationPermission
    , pwaStatus : Evergreen.V264.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V264.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V264.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V264.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V264.Id.Id Evergreen.V264.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V264.Id.Id Evergreen.V264.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V264.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V264.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V264.Coord.Coord Evergreen.V264.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V264.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V264.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V264.Id.Id Evergreen.V264.Id.GuildId, Evergreen.V264.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V264.DmChannel.DmChannelId, Evergreen.V264.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V264.Discord.Id Evergreen.V264.Discord.GuildId, Evergreen.V264.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V264.Discord.Id Evergreen.V264.Discord.PrivateChannelId, Evergreen.V264.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V264.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V264.NonemptyDict.NonemptyDict (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId) Evergreen.V264.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V264.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V264.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V264.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V264.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId) Evergreen.V264.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId) Evergreen.V264.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V264.Id.Id Evergreen.V264.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.Id.GuildId) Evergreen.V264.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.Id.GuildId) Evergreen.V264.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V264.Discord.Id Evergreen.V264.Discord.GuildId) Evergreen.V264.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V264.DmChannel.DmChannelId Evergreen.V264.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V264.Discord.Id Evergreen.V264.Discord.PrivateChannelId) Evergreen.V264.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V264.OneToOne.OneToOne (Evergreen.V264.Slack.Id Evergreen.V264.Slack.ChannelId) Evergreen.V264.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V264.OneToOne.OneToOne String (Evergreen.V264.Id.Id Evergreen.V264.Id.GuildId)
    , slackUsers : Evergreen.V264.OneToOne.OneToOne (Evergreen.V264.Slack.Id Evergreen.V264.Slack.UserId) (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId)
    , slackServers : Evergreen.V264.OneToOne.OneToOne (Evergreen.V264.Slack.Id Evergreen.V264.Slack.TeamId) (Evergreen.V264.Id.Id Evergreen.V264.Id.GuildId)
    , slackToken : Maybe Evergreen.V264.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V264.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V264.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V264.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V264.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V264.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V264.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V264.Cloudflare.AnalyticsApiToken
    , textEditor : Evergreen.V264.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId) Evergreen.V264.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId, Evergreen.V264.Discord.Id Evergreen.V264.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V264.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V264.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V264.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V264.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId) (Evergreen.V264.LocalState.LoadingDiscordChannel (List Evergreen.V264.Discord.Message))
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V264.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.Id.StickerId) Evergreen.V264.Sticker.StickerData
    , discordStickers : Evergreen.V264.OneToOne.OneToOne (Evergreen.V264.Discord.Id Evergreen.V264.Discord.StickerId) (Evergreen.V264.Id.Id Evergreen.V264.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.Id.CustomEmojiId) Evergreen.V264.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V264.OneToOne.OneToOne Evergreen.V264.RichText.DiscordCustomEmojiIdAndName (Evergreen.V264.Id.Id Evergreen.V264.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V264.Postmark.ApiKey
    , serverSecret : Evergreen.V264.SecretId.SecretId Evergreen.V264.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V264.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V264.OneToOne.OneToOne (Evergreen.V264.SecretId.SecretId Evergreen.V264.Id.GoMatchPublicId) ( Evergreen.V264.DmChannel.DmChannelId, Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelMessageId )
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V264.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V264.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V264.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V264.Route.Route
    | SelectedFilesToAttach ( Evergreen.V264.Id.AnyGuildOrDmId, Evergreen.V264.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V264.Id.Id Evergreen.V264.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V264.Id.Id Evergreen.V264.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V264.Id.Id Evergreen.V264.Id.GuildId) (Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelId) Evergreen.V264.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V264.Id.Id Evergreen.V264.Id.GuildId) (Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelId) Evergreen.V264.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V264.Discord.Id Evergreen.V264.Discord.GuildId) (Evergreen.V264.Discord.Id Evergreen.V264.Discord.ChannelId) Evergreen.V264.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V264.Discord.Id Evergreen.V264.Discord.GuildId) (Evergreen.V264.Discord.Id Evergreen.V264.Discord.ChannelId) Evergreen.V264.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V264.Id.Id Evergreen.V264.Id.GuildId) (Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V264.Id.Id Evergreen.V264.Id.GuildId) (Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V264.Id.Id Evergreen.V264.Id.GuildId) (Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V264.Id.Id Evergreen.V264.Id.GuildId) (Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V264.Id.Id Evergreen.V264.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V264.Id.Id Evergreen.V264.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V264.Id.Id Evergreen.V264.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V264.Id.Id Evergreen.V264.Id.GuildId) (Evergreen.V264.SecretId.SecretId Evergreen.V264.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V264.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V264.Id.AnyGuildOrDmId Evergreen.V264.Id.ThreadRouteWithMessage (Evergreen.V264.Coord.Coord Evergreen.V264.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V264.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V264.Id.AnyGuildOrDmId Evergreen.V264.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V264.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V264.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V264.Id.AnyGuildOrDmId, Evergreen.V264.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V264.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V264.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V264.Id.AnyGuildOrDmId, Evergreen.V264.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V264.NonemptyDict.NonemptyDict Int Evergreen.V264.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V264.NonemptyDict.NonemptyDict Int Evergreen.V264.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V264.Id.AnyGuildOrDmId Evergreen.V264.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V264.Id.AnyGuildOrDmId Evergreen.V264.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V264.NonemptySet.NonemptySet (Evergreen.V264.Id.Id Evergreen.V264.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V264.Id.AnyGuildOrDmId, Evergreen.V264.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V264.Id.AnyGuildOrDmId Evergreen.V264.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V264.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V264.AiChat.Msg
    | GoMsg Evergreen.V264.Go.Msg
    | GoSpectatorMsg Evergreen.V264.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V264.Editable.Msg Evergreen.V264.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V264.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V264.Id.Id Evergreen.V264.Id.GuildId) Evergreen.V264.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V264.Id.AnyGuildOrDmId, Evergreen.V264.Id.ThreadRoute ) (Evergreen.V264.Id.Id Evergreen.V264.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V264.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V264.Id.AnyGuildOrDmId, Evergreen.V264.Id.ThreadRoute ) (Evergreen.V264.Id.Id Evergreen.V264.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V264.Id.AnyGuildOrDmId, Evergreen.V264.Id.ThreadRoute ) (Evergreen.V264.Id.Id Evergreen.V264.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V264.Id.AnyGuildOrDmId, Evergreen.V264.Id.ThreadRoute )
        { fileId : Evergreen.V264.Id.Id Evergreen.V264.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V264.Id.AnyGuildOrDmId, Evergreen.V264.Id.ThreadRoute ) (Evergreen.V264.Id.Id Evergreen.V264.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V264.Id.AnyGuildOrDmId, Evergreen.V264.Id.ThreadRoute ) (Evergreen.V264.Id.Id Evergreen.V264.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V264.Id.AnyGuildOrDmId, Evergreen.V264.Id.ThreadRoute )
        { fileId : Evergreen.V264.Id.Id Evergreen.V264.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V264.Id.AnyGuildOrDmId, Evergreen.V264.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V264.Id.AnyGuildOrDmId, Evergreen.V264.Id.ThreadRoute ) (Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelMessageId) (Evergreen.V264.Id.Id Evergreen.V264.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V264.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V264.Id.AnyGuildOrDmId, Evergreen.V264.Id.ThreadRoute ) (Evergreen.V264.Id.Id Evergreen.V264.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V264.Id.AnyGuildOrDmId Evergreen.V264.Id.ThreadRouteWithMessage Evergreen.V264.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V264.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V264.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V264.Id.Id Evergreen.V264.Id.GuildId) Evergreen.V264.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId) (Evergreen.V264.Discord.Id Evergreen.V264.Discord.GuildId) Evergreen.V264.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V264.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V264.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId
        , otherUserId : Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V264.Id.AnyGuildOrDmId Evergreen.V264.Id.ThreadRoute Evergreen.V264.MessageInput.Msg
    | MessageInputMsg Evergreen.V264.Id.AnyGuildOrDmId Evergreen.V264.Id.ThreadRoute Evergreen.V264.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V264.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V264.Range.Range, Evergreen.V264.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V264.Range.Range, Evergreen.V264.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V264.Call.FromJs)
    | VoiceChatMsg Evergreen.V264.Call.Msg
    | PressedChannelHeaderTab Evergreen.V264.Route.DmChannelHeaderTab
    | FileDragEnter
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V264.Id.Id Evergreen.V264.Id.GuildId) (Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelId) Evergreen.V264.Id.ThreadRoute
    | InitialLoadRequested_Dm Evergreen.V264.DmChannel.DmChannelId Evergreen.V264.Id.ThreadRoute
    | InitialLoadRequested_Discord Evergreen.V264.Id.DiscordGuildOrDmId Evergreen.V264.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V264.Id.Id Evergreen.V264.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V264.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V264.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V264.Untrusted.Untrusted Evergreen.V264.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V264.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V264.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V264.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V264.Id.Id Evergreen.V264.Id.GuildId) (Evergreen.V264.SecretId.SecretId Evergreen.V264.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V264.PersonName.PersonName Evergreen.V264.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V264.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V264.Slack.OAuthCode Evergreen.V264.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V264.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V264.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V264.Id.Id Evergreen.V264.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V264.SecretId.SecretId Evergreen.V264.Id.GoMatchPublicId)


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V264.Discord.Id Evergreen.V264.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V264.Discord.Id Evergreen.V264.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V264.EmailAddress.EmailAddress (Result Evergreen.V264.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V264.EmailAddress.EmailAddress (Result Evergreen.V264.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V264.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V264.Discord.Id Evergreen.V264.Discord.GuildId) (Evergreen.V264.Discord.Id Evergreen.V264.Discord.ChannelId) Evergreen.V264.Id.ThreadRouteWithMaybeMessage (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId) (Result Evergreen.V264.Discord.HttpError Evergreen.V264.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V264.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V264.Discord.Id Evergreen.V264.Discord.PrivateChannelId) (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId) (Result Evergreen.V264.Discord.HttpError Evergreen.V264.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V264.Discord.Id Evergreen.V264.Discord.GuildId) (Evergreen.V264.Discord.Id Evergreen.V264.Discord.ChannelId) Evergreen.V264.Id.ThreadRouteWithMessage (Evergreen.V264.Discord.Id Evergreen.V264.Discord.MessageId) (Result Evergreen.V264.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V264.Discord.Id Evergreen.V264.Discord.PrivateChannelId) (Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelMessageId) (Evergreen.V264.Discord.Id Evergreen.V264.Discord.MessageId) (Result Evergreen.V264.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V264.Discord.Id Evergreen.V264.Discord.GuildId) (Evergreen.V264.Discord.Id Evergreen.V264.Discord.ChannelId) Evergreen.V264.Id.ThreadRouteWithMessage (Evergreen.V264.Discord.Id Evergreen.V264.Discord.MessageId) (Result Evergreen.V264.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V264.Discord.Id Evergreen.V264.Discord.PrivateChannelId) (Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelMessageId) (Evergreen.V264.Discord.Id Evergreen.V264.Discord.MessageId) (Result Evergreen.V264.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V264.Discord.Id Evergreen.V264.Discord.GuildId) (Evergreen.V264.Discord.Id Evergreen.V264.Discord.ChannelId) Evergreen.V264.Id.ThreadRouteWithMessage (Evergreen.V264.Discord.Id Evergreen.V264.Discord.MessageId) Evergreen.V264.Emoji.EmojiOrCustomEmoji (Result Evergreen.V264.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V264.Discord.Id Evergreen.V264.Discord.PrivateChannelId) (Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelMessageId) (Evergreen.V264.Discord.Id Evergreen.V264.Discord.MessageId) Evergreen.V264.Emoji.EmojiOrCustomEmoji (Result Evergreen.V264.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V264.Discord.Id Evergreen.V264.Discord.GuildId) (Evergreen.V264.Discord.Id Evergreen.V264.Discord.ChannelId) Evergreen.V264.Id.ThreadRouteWithMessage (Evergreen.V264.Discord.Id Evergreen.V264.Discord.MessageId) Evergreen.V264.Emoji.EmojiOrCustomEmoji (Result Evergreen.V264.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V264.Discord.Id Evergreen.V264.Discord.PrivateChannelId) (Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelMessageId) (Evergreen.V264.Discord.Id Evergreen.V264.Discord.MessageId) Evergreen.V264.Emoji.EmojiOrCustomEmoji (Result Evergreen.V264.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V264.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V264.Discord.HttpError (List ( Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId, Maybe Evergreen.V264.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V264.Slack.CurrentUser
            , team : Evergreen.V264.Slack.Team
            , users : List Evergreen.V264.Slack.User
            , channels : List ( Evergreen.V264.Slack.Channel, List Evergreen.V264.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId) (Result Effect.Http.Error Evergreen.V264.Slack.TokenResponse)
    | GotCloudflareSessionCreated Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V264.Local.ChangeId Effect.Time.Posix Evergreen.V264.Call.CallId Evergreen.V264.Cloudflare.Sdp (List String) (Result Effect.Http.Error Evergreen.V264.Cloudflare.RealtimeSessionId)
    | GotCloudflareSession Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V264.Local.ChangeId Effect.Time.Posix Evergreen.V264.Call.CallId Evergreen.V264.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V264.Cloudflare.PushTracksResult)
    | GotCloudflarePullOffer Effect.Time.Posix Effect.Lamdera.ClientId Evergreen.V264.Local.ChangeId Evergreen.V264.Call.ConnectionId Evergreen.V264.Cloudflare.RealtimeSessionId (List Evergreen.V264.Cloudflare.TrackName) (Result Effect.Http.Error Evergreen.V264.Cloudflare.PullTracksResult)
    | GotCloudflareRenegotiateAck Effect.Lamdera.ClientId Evergreen.V264.Local.ChangeId Evergreen.V264.Cloudflare.Sdp (Result Effect.Http.Error ())
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId) Evergreen.V264.Discord.UserAuth (Result Evergreen.V264.Discord.HttpError Evergreen.V264.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId) (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId) (Result Evergreen.V264.Discord.HttpError Evergreen.V264.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId)
        (Result
            Evergreen.V264.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V264.Discord.Id Evergreen.V264.Discord.PrivateChannelId
                , members : List (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId)
                }
            , List
                ( Evergreen.V264.Discord.Id Evergreen.V264.Discord.GuildId
                , { guild : Evergreen.V264.Discord.GatewayGuild
                  , channels : List Evergreen.V264.Discord.Channel
                  , icon : Maybe Evergreen.V264.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId) Bool Evergreen.V264.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V264.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V264.Discord.Id Evergreen.V264.Discord.AttachmentId, Evergreen.V264.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V264.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V264.Discord.Id Evergreen.V264.Discord.AttachmentId, Evergreen.V264.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId) (Evergreen.V264.Discord.Id Evergreen.V264.Discord.GuildId) (Evergreen.V264.Discord.Id Evergreen.V264.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V264.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V264.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId) (Evergreen.V264.Discord.Id Evergreen.V264.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V264.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V264.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId) (Evergreen.V264.Discord.Id Evergreen.V264.Discord.GuildId) (Evergreen.V264.Discord.Id Evergreen.V264.Discord.ChannelId) (Result Evergreen.V264.Discord.HttpError (List Evergreen.V264.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId) (Evergreen.V264.Discord.Id Evergreen.V264.Discord.PrivateChannelId) (Result Evergreen.V264.Discord.HttpError (List Evergreen.V264.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V264.Id.Id Evergreen.V264.Id.GuildId) (Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelId) Evergreen.V264.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V264.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V264.DmChannel.DmChannelId Evergreen.V264.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V264.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V264.Discord.Id Evergreen.V264.Discord.GuildId) (Evergreen.V264.Discord.Id Evergreen.V264.Discord.ChannelId) Evergreen.V264.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V264.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V264.Discord.Id Evergreen.V264.Discord.PrivateChannelId) (Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V264.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId)
        (Evergreen.V264.Discord.Id Evergreen.V264.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V264.Discord.HttpError
            { guild : Evergreen.V264.Discord.GatewayGuild
            , channels : List Evergreen.V264.Discord.Channel
            , icon : Maybe Evergreen.V264.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V264.Discord.Id Evergreen.V264.Discord.GuildId) (Result Evergreen.V264.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V264.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId) (List ( Evergreen.V264.Id.Id Evergreen.V264.Id.StickerId, Result Effect.Http.Error Evergreen.V264.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V264.Id.Id Evergreen.V264.Id.StickerId, Result Effect.Http.Error Evergreen.V264.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId) (List ( Evergreen.V264.Id.Id Evergreen.V264.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V264.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V264.Id.Id Evergreen.V264.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V264.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V264.Discord.HttpError (List Evergreen.V264.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V264.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V264.SecretId.SecretId Evergreen.V264.SecretId.ServerSecret))
    | GotTimeForWebsocketListenClose (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | GotCloudflareUsage Effect.Time.Posix (Result Effect.Http.Error Int)
    | GotCloudflareEgressForAdmin Effect.Lamdera.ClientId (Result Effect.Http.Error Int)
