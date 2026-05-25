module Evergreen.V253.Types exposing (..)

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
import Evergreen.V253.AiChat
import Evergreen.V253.Call
import Evergreen.V253.ChannelDescription
import Evergreen.V253.ChannelName
import Evergreen.V253.Cloudflare
import Evergreen.V253.Coord
import Evergreen.V253.CssPixels
import Evergreen.V253.CustomEmoji
import Evergreen.V253.Discord
import Evergreen.V253.DiscordAttachmentId
import Evergreen.V253.DiscordUserData
import Evergreen.V253.DmChannel
import Evergreen.V253.Editable
import Evergreen.V253.EmailAddress
import Evergreen.V253.Embed
import Evergreen.V253.Emoji
import Evergreen.V253.FileStatus
import Evergreen.V253.Go
import Evergreen.V253.GuildName
import Evergreen.V253.Id
import Evergreen.V253.ImageEditor
import Evergreen.V253.Local
import Evergreen.V253.LocalState
import Evergreen.V253.Log
import Evergreen.V253.LoginForm
import Evergreen.V253.MembersAndOwner
import Evergreen.V253.Message
import Evergreen.V253.MessageInput
import Evergreen.V253.MessageView
import Evergreen.V253.MyUi
import Evergreen.V253.NonemptyDict
import Evergreen.V253.NonemptySet
import Evergreen.V253.OneToOne
import Evergreen.V253.Pages.Admin
import Evergreen.V253.Pagination
import Evergreen.V253.PersonName
import Evergreen.V253.Ports
import Evergreen.V253.Postmark
import Evergreen.V253.Range
import Evergreen.V253.RichText
import Evergreen.V253.Route
import Evergreen.V253.SecretId
import Evergreen.V253.SessionIdHash
import Evergreen.V253.Slack
import Evergreen.V253.Sticker
import Evergreen.V253.TextEditor
import Evergreen.V253.ToBackendLog
import Evergreen.V253.Touch
import Evergreen.V253.TwoFactorAuthentication
import Evergreen.V253.Ui.Anim
import Evergreen.V253.Untrusted
import Evergreen.V253.User
import Evergreen.V253.UserAgent
import Evergreen.V253.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V253.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V253.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.Id.GuildId) Evergreen.V253.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId) Evergreen.V253.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V253.Discord.Id Evergreen.V253.Discord.PrivateChannelId) Evergreen.V253.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V253.Discord.Id Evergreen.V253.Discord.GuildId) Evergreen.V253.LocalState.DiscordFrontendGuild
    , user : Evergreen.V253.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId) Evergreen.V253.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId) Evergreen.V253.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId) Evergreen.V253.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V253.SessionIdHash.SessionIdHash Evergreen.V253.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V253.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.Id.StickerId) Evergreen.V253.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.Id.CustomEmojiId) Evergreen.V253.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V253.Call.RoomId (Evergreen.V253.NonemptySet.NonemptySet ( Evergreen.V253.Id.Id Evergreen.V253.Id.UserId, Effect.Lamdera.ClientId ))
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type PublicGoMatch
    = PublicGoMatch_NotLoaded
    | PublicGoMatch_Loading
    | PublicGoMatch_Loaded Evergreen.V253.Go.PublicGoMatchData Evergreen.V253.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V253.Route.Route
    , windowSize : Evergreen.V253.Coord.Coord Evergreen.V253.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V253.Ports.NotificationPermission
    , pwaStatus : Evergreen.V253.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V253.UserAgent.UserAgent
    , publicGoMatch : PublicGoMatch
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V253.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V253.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V253.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.FileStatus.FileId) Evergreen.V253.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V253.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V253.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.FileStatus.FileId) Evergreen.V253.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V253.Id.Id Evergreen.V253.Id.GuildId) Evergreen.V253.ChannelName.ChannelName Evergreen.V253.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V253.Id.Id Evergreen.V253.Id.GuildId) (Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelId) Evergreen.V253.ChannelName.ChannelName Evergreen.V253.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V253.Id.Id Evergreen.V253.Id.GuildId) (Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelId)
    | Local_DeleteGuild (Evergreen.V253.Id.Id Evergreen.V253.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V253.Id.Id Evergreen.V253.Id.GuildId) (Evergreen.V253.UserSession.ToBeFilledInByBackend (Evergreen.V253.SecretId.SecretId Evergreen.V253.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V253.Id.Id Evergreen.V253.Id.GuildId) (Evergreen.V253.SecretId.SecretId Evergreen.V253.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V253.GuildName.GuildName (Evergreen.V253.UserSession.ToBeFilledInByBackend (Evergreen.V253.Id.Id Evergreen.V253.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V253.Id.AnyGuildOrDmId, Evergreen.V253.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V253.Id.AnyGuildOrDmId Evergreen.V253.Id.ThreadRouteWithMessage Evergreen.V253.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V253.Id.AnyGuildOrDmId Evergreen.V253.Id.ThreadRouteWithMessage Evergreen.V253.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V253.Id.GuildOrDmId Evergreen.V253.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.FileStatus.FileId) Evergreen.V253.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId) (Evergreen.V253.Discord.Id Evergreen.V253.Discord.GuildId) (Evergreen.V253.Discord.Id Evergreen.V253.Discord.ChannelId) Evergreen.V253.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V253.Id.DiscordGuildOrDmId_DmData (Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V253.Id.AnyGuildOrDmId Evergreen.V253.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V253.Id.AnyGuildOrDmId Evergreen.V253.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V253.Id.AnyGuildOrDmId Evergreen.V253.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V253.UserSession.SetViewing
    | Local_SetName Evergreen.V253.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V253.Id.GuildOrDmId (Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelMessageId) (Evergreen.V253.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelMessageId) (Evergreen.V253.Message.Message Evergreen.V253.Id.ChannelMessageId (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V253.Id.GuildOrDmId (Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelMessageId) (Evergreen.V253.Id.Id Evergreen.V253.Id.ThreadMessageId) (Evergreen.V253.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.Id.ThreadMessageId) (Evergreen.V253.Message.Message Evergreen.V253.Id.ThreadMessageId (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V253.Id.DiscordGuildOrDmId (Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelMessageId) (Evergreen.V253.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelMessageId) (Evergreen.V253.Message.Message Evergreen.V253.Id.ChannelMessageId (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V253.Id.DiscordGuildOrDmId (Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelMessageId) (Evergreen.V253.Id.Id Evergreen.V253.Id.ThreadMessageId) (Evergreen.V253.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.Id.ThreadMessageId) (Evergreen.V253.Message.Message Evergreen.V253.Id.ThreadMessageId (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V253.Id.Id Evergreen.V253.Id.GuildId) Evergreen.V253.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId) (Evergreen.V253.Discord.Id Evergreen.V253.Discord.GuildId) Evergreen.V253.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V253.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V253.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V253.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V253.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V253.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V253.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V253.NonemptySet.NonemptySet (Evergreen.V253.Id.Id Evergreen.V253.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V253.Call.LocalChange
    | Local_Go
        { otherUserId : Evergreen.V253.Id.Id Evergreen.V253.Id.UserId
        }
        Evergreen.V253.Go.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId) Effect.Time.Posix Evergreen.V253.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V253.RichText.RichText (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId))) Evergreen.V253.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.FileStatus.FileId) Evergreen.V253.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.Id.StickerId) Evergreen.V253.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V253.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V253.RichText.RichText (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId))) Evergreen.V253.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.FileStatus.FileId) Evergreen.V253.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.Id.StickerId) Evergreen.V253.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V253.Id.Id Evergreen.V253.Id.GuildId) Evergreen.V253.ChannelName.ChannelName Evergreen.V253.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V253.Id.Id Evergreen.V253.Id.GuildId) (Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelId) Evergreen.V253.ChannelName.ChannelName Evergreen.V253.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V253.Id.Id Evergreen.V253.Id.GuildId) (Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelId)
    | Server_DeleteGuild (Evergreen.V253.Id.Id Evergreen.V253.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId) (Evergreen.V253.Id.Id Evergreen.V253.Id.GuildId) (Evergreen.V253.SecretId.SecretId Evergreen.V253.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V253.Id.Id Evergreen.V253.Id.GuildId) (Evergreen.V253.SecretId.SecretId Evergreen.V253.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId) (Evergreen.V253.Id.Id Evergreen.V253.Id.GuildId) Evergreen.V253.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V253.LocalState.JoinGuildError
            { guildId : Evergreen.V253.Id.Id Evergreen.V253.Id.GuildId
            , guild : Evergreen.V253.LocalState.FrontendGuild
            , owner : Evergreen.V253.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId) Evergreen.V253.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId) Evergreen.V253.Id.GuildOrDmId Evergreen.V253.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId) (Evergreen.V253.Discord.Id Evergreen.V253.Discord.GuildId) (Evergreen.V253.Discord.Id Evergreen.V253.Discord.ChannelId) Evergreen.V253.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId) (Evergreen.V253.Discord.Id Evergreen.V253.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId) Evergreen.V253.Id.GuildOrDmId Evergreen.V253.Id.ThreadRouteWithMessage Evergreen.V253.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId) Evergreen.V253.Id.GuildOrDmId Evergreen.V253.Id.ThreadRouteWithMessage Evergreen.V253.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId) (Evergreen.V253.Discord.Id Evergreen.V253.Discord.GuildId) (Evergreen.V253.Discord.Id Evergreen.V253.Discord.ChannelId) Evergreen.V253.Id.ThreadRouteWithMessage Evergreen.V253.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId) (Evergreen.V253.Discord.Id Evergreen.V253.Discord.PrivateChannelId) (Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelMessageId) Evergreen.V253.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId) (Evergreen.V253.Discord.Id Evergreen.V253.Discord.GuildId) (Evergreen.V253.Discord.Id Evergreen.V253.Discord.ChannelId) Evergreen.V253.Id.ThreadRouteWithMessage Evergreen.V253.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId) (Evergreen.V253.Discord.Id Evergreen.V253.Discord.PrivateChannelId) (Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelMessageId) Evergreen.V253.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId) Evergreen.V253.Id.GuildOrDmId Evergreen.V253.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V253.RichText.RichText (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId))) (SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.FileStatus.FileId) Evergreen.V253.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId) (Evergreen.V253.Discord.Id Evergreen.V253.Discord.GuildId) (Evergreen.V253.Discord.Id Evergreen.V253.Discord.ChannelId) Evergreen.V253.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V253.RichText.RichText (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V253.Id.DiscordGuildOrDmId_DmData (Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V253.RichText.RichText (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId) Evergreen.V253.Id.AnyGuildOrDmId Evergreen.V253.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V253.Id.AnyGuildOrDmId Evergreen.V253.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V253.Discord.Id Evergreen.V253.Discord.GuildId) (Evergreen.V253.Discord.Id Evergreen.V253.Discord.ChannelId) Evergreen.V253.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V253.Discord.Id Evergreen.V253.Discord.PrivateChannelId) (Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId) Evergreen.V253.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId) Evergreen.V253.FileStatus.FileHash
    | Server_SetGuildIcon (Evergreen.V253.Id.Id Evergreen.V253.Id.GuildId) Evergreen.V253.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V253.Id.Id Evergreen.V253.Id.GuildId) Evergreen.V253.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V253.Discord.Id Evergreen.V253.Discord.GuildId) Evergreen.V253.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V253.SessionIdHash.SessionIdHash Evergreen.V253.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V253.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V253.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V253.Id.AnyGuildOrDmId, Evergreen.V253.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V253.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId) Evergreen.V253.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V253.Discord.Id Evergreen.V253.Discord.GuildId) (Evergreen.V253.Discord.Id Evergreen.V253.Discord.ChannelId) Evergreen.V253.ChannelName.ChannelName (Evergreen.V253.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V253.Discord.Id Evergreen.V253.Discord.PrivateChannelId)
        (Evergreen.V253.NonemptyDict.NonemptyDict
            (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V253.Discord.Id Evergreen.V253.Discord.GuildId) Evergreen.V253.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V253.Discord.Id Evergreen.V253.Discord.PrivateChannelId) Evergreen.V253.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId) Evergreen.V253.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId) (Maybe (Evergreen.V253.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V253.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V253.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V253.Id.Id Evergreen.V253.Id.GuildId) (Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelId) Evergreen.V253.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V253.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId) Evergreen.V253.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V253.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V253.Discord.Id Evergreen.V253.Discord.GuildId) (Evergreen.V253.Discord.Id Evergreen.V253.Discord.ChannelId) Evergreen.V253.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V253.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V253.Discord.Id Evergreen.V253.Discord.PrivateChannelId) (Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V253.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V253.Discord.Id Evergreen.V253.Discord.GuildId) Evergreen.V253.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V253.Discord.Id Evergreen.V253.Discord.GuildId) (Evergreen.V253.Discord.Id Evergreen.V253.Discord.ChannelId) (Evergreen.V253.Discord.OptionalData String) (Evergreen.V253.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V253.Discord.Id Evergreen.V253.Discord.GuildId)
        (Evergreen.V253.MembersAndOwner.MembersAndOwner
            (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V253.Discord.Id Evergreen.V253.Discord.GuildId) (Evergreen.V253.Discord.Id Evergreen.V253.Discord.ChannelId) (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId) Evergreen.V253.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.Id.StickerId) Evergreen.V253.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.Id.CustomEmojiId) Evergreen.V253.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V253.Call.ServerChange
    | Server_Go
        (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId)
        { otherUserId : Evergreen.V253.Id.Id Evergreen.V253.Id.UserId
        }
        Evergreen.V253.Go.LocalChange


type LocalMsg
    = LocalChange (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V253.Id.Id Evergreen.V253.Id.GuildId) (Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelId) Evergreen.V253.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V253.Discord.Id Evergreen.V253.Discord.GuildId) (Evergreen.V253.Discord.Id Evergreen.V253.Discord.ChannelId) Evergreen.V253.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.FileStatus.FileId) Evergreen.V253.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V253.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V253.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V253.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V253.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V253.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V253.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V253.Coord.Coord Evergreen.V253.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V253.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V253.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V253.Id.AnyGuildOrDmId Evergreen.V253.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V253.Id.AnyGuildOrDmId Evergreen.V253.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V253.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V253.Coord.Coord Evergreen.V253.CssPixels.CssPixels) (Maybe Evergreen.V253.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V253.Id.AnyGuildOrDmId, Evergreen.V253.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelMessageId) (Evergreen.V253.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.Id.ThreadMessageId) (Evergreen.V253.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V253.Editable.Model
    , showLinkDiscordSetup : Bool
    , domainWhitelistInput : String
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V253.Local.Local LocalMsg Evergreen.V253.LocalState.LocalState
    , admin : Evergreen.V253.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V253.Id.AnyGuildOrDmId, Evergreen.V253.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V253.Id.Id Evergreen.V253.Id.GuildId, Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V253.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V253.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V253.Id.AnyGuildOrDmId, Evergreen.V253.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V253.Id.AnyGuildOrDmId, Evergreen.V253.Id.ThreadRoute ) (Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : Evergreen.V253.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V253.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V253.Id.AnyGuildOrDmId, Evergreen.V253.Id.ThreadRoute ) (Evergreen.V253.NonemptyDict.NonemptyDict (Evergreen.V253.Id.Id Evergreen.V253.FileStatus.FileId) Evergreen.V253.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V253.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V253.TextEditor.Model
    , profilePictureEditor : Evergreen.V253.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V253.Id.Id Evergreen.V253.Id.GuildId, Evergreen.V253.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V253.Emoji.Model
    , voiceChat : Evergreen.V253.Call.Model
    , currentDmGoMatch : SeqDict.SeqDict ( Evergreen.V253.Id.Id Evergreen.V253.Id.UserId, Maybe (Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelMessageId) ) Evergreen.V253.Go.Model
    , fileDragOverCount : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V253.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V253.SecretId.SecretId Evergreen.V253.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V253.Range.Range
                , direction : Evergreen.V253.Range.SelectionDirection
                }
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V253.NonemptyDict.NonemptyDict Int Evergreen.V253.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V253.NonemptyDict.NonemptyDict Int Evergreen.V253.Touch.Touch
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
    | AdminToFrontend Evergreen.V253.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V253.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V253.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V253.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V253.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V253.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V253.Go.PublicGoMatchData)


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V253.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V253.Coord.Coord Evergreen.V253.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V253.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V253.MyUi.LastCopy
    , notificationPermission : Evergreen.V253.Ports.NotificationPermission
    , pwaStatus : Evergreen.V253.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V253.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V253.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V253.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V253.Id.Id Evergreen.V253.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V253.Id.Id Evergreen.V253.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V253.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V253.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V253.Coord.Coord Evergreen.V253.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V253.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V253.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V253.Id.Id Evergreen.V253.Id.GuildId, Evergreen.V253.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V253.DmChannel.DmChannelId, Evergreen.V253.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V253.Discord.Id Evergreen.V253.Discord.GuildId, Evergreen.V253.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V253.Discord.Id Evergreen.V253.Discord.PrivateChannelId, Evergreen.V253.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V253.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V253.NonemptyDict.NonemptyDict (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId) Evergreen.V253.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V253.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V253.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V253.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V253.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId) Evergreen.V253.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId) Evergreen.V253.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V253.Id.Id Evergreen.V253.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.Id.GuildId) Evergreen.V253.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.Id.GuildId) Evergreen.V253.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V253.Discord.Id Evergreen.V253.Discord.GuildId) Evergreen.V253.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V253.DmChannel.DmChannelId Evergreen.V253.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V253.Discord.Id Evergreen.V253.Discord.PrivateChannelId) Evergreen.V253.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V253.OneToOne.OneToOne (Evergreen.V253.Slack.Id Evergreen.V253.Slack.ChannelId) Evergreen.V253.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V253.OneToOne.OneToOne String (Evergreen.V253.Id.Id Evergreen.V253.Id.GuildId)
    , slackUsers : Evergreen.V253.OneToOne.OneToOne (Evergreen.V253.Slack.Id Evergreen.V253.Slack.UserId) (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId)
    , slackServers : Evergreen.V253.OneToOne.OneToOne (Evergreen.V253.Slack.Id Evergreen.V253.Slack.TeamId) (Evergreen.V253.Id.Id Evergreen.V253.Id.GuildId)
    , slackToken : Maybe Evergreen.V253.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V253.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V253.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V253.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V253.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V253.Cloudflare.AppId
    , textEditor : Evergreen.V253.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId) Evergreen.V253.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId, Evergreen.V253.Discord.Id Evergreen.V253.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V253.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V253.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V253.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V253.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId) (Evergreen.V253.LocalState.LoadingDiscordChannel (List Evergreen.V253.Discord.Message))
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V253.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.Id.StickerId) Evergreen.V253.Sticker.StickerData
    , discordStickers : Evergreen.V253.OneToOne.OneToOne (Evergreen.V253.Discord.Id Evergreen.V253.Discord.StickerId) (Evergreen.V253.Id.Id Evergreen.V253.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.Id.CustomEmojiId) Evergreen.V253.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V253.OneToOne.OneToOne Evergreen.V253.RichText.DiscordCustomEmojiIdAndName (Evergreen.V253.Id.Id Evergreen.V253.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V253.Postmark.ApiKey
    , serverSecret : Evergreen.V253.SecretId.SecretId Evergreen.V253.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V253.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V253.OneToOne.OneToOne (Evergreen.V253.SecretId.SecretId Evergreen.V253.Id.GoMatchPublicId) ( Evergreen.V253.DmChannel.DmChannelId, Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelMessageId )
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V253.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V253.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V253.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V253.Route.Route
    | SelectedFilesToAttach ( Evergreen.V253.Id.AnyGuildOrDmId, Evergreen.V253.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V253.Id.Id Evergreen.V253.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V253.Id.Id Evergreen.V253.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V253.Id.Id Evergreen.V253.Id.GuildId) (Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelId) Evergreen.V253.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V253.Id.Id Evergreen.V253.Id.GuildId) (Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelId) Evergreen.V253.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V253.Discord.Id Evergreen.V253.Discord.GuildId) (Evergreen.V253.Discord.Id Evergreen.V253.Discord.ChannelId) Evergreen.V253.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V253.Discord.Id Evergreen.V253.Discord.GuildId) (Evergreen.V253.Discord.Id Evergreen.V253.Discord.ChannelId) Evergreen.V253.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V253.Id.Id Evergreen.V253.Id.GuildId) (Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V253.Id.Id Evergreen.V253.Id.GuildId) (Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V253.Id.Id Evergreen.V253.Id.GuildId) (Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V253.Id.Id Evergreen.V253.Id.GuildId) (Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V253.Id.Id Evergreen.V253.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V253.Id.Id Evergreen.V253.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V253.Id.Id Evergreen.V253.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V253.Id.Id Evergreen.V253.Id.GuildId) (Evergreen.V253.SecretId.SecretId Evergreen.V253.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V253.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V253.Id.AnyGuildOrDmId Evergreen.V253.Id.ThreadRouteWithMessage (Evergreen.V253.Coord.Coord Evergreen.V253.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V253.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V253.Id.AnyGuildOrDmId Evergreen.V253.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V253.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V253.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V253.Id.AnyGuildOrDmId, Evergreen.V253.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V253.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V253.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V253.Id.AnyGuildOrDmId, Evergreen.V253.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V253.NonemptyDict.NonemptyDict Int Evergreen.V253.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V253.NonemptyDict.NonemptyDict Int Evergreen.V253.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V253.Id.AnyGuildOrDmId Evergreen.V253.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V253.Id.AnyGuildOrDmId Evergreen.V253.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V253.NonemptySet.NonemptySet (Evergreen.V253.Id.Id Evergreen.V253.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V253.Id.AnyGuildOrDmId, Evergreen.V253.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V253.Id.AnyGuildOrDmId Evergreen.V253.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V253.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V253.AiChat.Msg
    | GoMsg Evergreen.V253.Go.Msg
    | GoSpectatorMsg Evergreen.V253.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V253.Editable.Msg Evergreen.V253.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V253.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V253.Id.Id Evergreen.V253.Id.GuildId) Evergreen.V253.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V253.Id.AnyGuildOrDmId, Evergreen.V253.Id.ThreadRoute ) (Evergreen.V253.Id.Id Evergreen.V253.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V253.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V253.Id.AnyGuildOrDmId, Evergreen.V253.Id.ThreadRoute ) (Evergreen.V253.Id.Id Evergreen.V253.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V253.Id.AnyGuildOrDmId, Evergreen.V253.Id.ThreadRoute ) (Evergreen.V253.Id.Id Evergreen.V253.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V253.Id.AnyGuildOrDmId, Evergreen.V253.Id.ThreadRoute )
        { fileId : Evergreen.V253.Id.Id Evergreen.V253.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V253.Id.AnyGuildOrDmId, Evergreen.V253.Id.ThreadRoute ) (Evergreen.V253.Id.Id Evergreen.V253.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V253.Id.AnyGuildOrDmId, Evergreen.V253.Id.ThreadRoute ) (Evergreen.V253.Id.Id Evergreen.V253.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V253.Id.AnyGuildOrDmId, Evergreen.V253.Id.ThreadRoute )
        { fileId : Evergreen.V253.Id.Id Evergreen.V253.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V253.Id.AnyGuildOrDmId, Evergreen.V253.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V253.Id.AnyGuildOrDmId, Evergreen.V253.Id.ThreadRoute ) (Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelMessageId) (Evergreen.V253.Id.Id Evergreen.V253.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V253.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V253.Id.AnyGuildOrDmId, Evergreen.V253.Id.ThreadRoute ) (Evergreen.V253.Id.Id Evergreen.V253.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V253.Id.AnyGuildOrDmId Evergreen.V253.Id.ThreadRouteWithMessage Evergreen.V253.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V253.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V253.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V253.Id.Id Evergreen.V253.Id.GuildId) Evergreen.V253.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId) (Evergreen.V253.Discord.Id Evergreen.V253.Discord.GuildId) Evergreen.V253.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V253.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V253.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId
        , otherUserId : Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V253.Id.AnyGuildOrDmId Evergreen.V253.Id.ThreadRoute Evergreen.V253.MessageInput.Msg
    | MessageInputMsg Evergreen.V253.Id.AnyGuildOrDmId Evergreen.V253.Id.ThreadRoute Evergreen.V253.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V253.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V253.Range.Range, Evergreen.V253.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V253.Range.Range, Evergreen.V253.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V253.Call.FromJs)
    | VoiceChatMsg Evergreen.V253.Call.Msg
    | PressedChannelHeaderTab Evergreen.V253.Route.DmChannelHeaderTab
    | FileDragEnter
    | FileDragLeave
    | FileDropped (List Effect.File.File)


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V253.Id.Id Evergreen.V253.Id.GuildId) (Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelId) Evergreen.V253.Id.ThreadRoute
    | InitialLoadRequested_Dm Evergreen.V253.DmChannel.DmChannelId Evergreen.V253.Id.ThreadRoute
    | InitialLoadRequested_Discord Evergreen.V253.Id.DiscordGuildOrDmId Evergreen.V253.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V253.Id.Id Evergreen.V253.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V253.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V253.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V253.Untrusted.Untrusted Evergreen.V253.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V253.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V253.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V253.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V253.Id.Id Evergreen.V253.Id.GuildId) (Evergreen.V253.SecretId.SecretId Evergreen.V253.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V253.PersonName.PersonName Evergreen.V253.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V253.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V253.Slack.OAuthCode Evergreen.V253.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V253.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V253.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V253.Id.Id Evergreen.V253.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V253.SecretId.SecretId Evergreen.V253.Id.GoMatchPublicId)


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V253.Discord.Id Evergreen.V253.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V253.Discord.Id Evergreen.V253.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V253.EmailAddress.EmailAddress (Result Evergreen.V253.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V253.EmailAddress.EmailAddress (Result Evergreen.V253.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V253.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V253.Discord.Id Evergreen.V253.Discord.GuildId) (Evergreen.V253.Discord.Id Evergreen.V253.Discord.ChannelId) Evergreen.V253.Id.ThreadRouteWithMaybeMessage (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId) (Result Evergreen.V253.Discord.HttpError Evergreen.V253.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V253.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V253.Discord.Id Evergreen.V253.Discord.PrivateChannelId) (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId) (Result Evergreen.V253.Discord.HttpError Evergreen.V253.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V253.Discord.Id Evergreen.V253.Discord.GuildId) (Evergreen.V253.Discord.Id Evergreen.V253.Discord.ChannelId) Evergreen.V253.Id.ThreadRouteWithMessage (Evergreen.V253.Discord.Id Evergreen.V253.Discord.MessageId) (Result Evergreen.V253.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V253.Discord.Id Evergreen.V253.Discord.PrivateChannelId) (Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelMessageId) (Evergreen.V253.Discord.Id Evergreen.V253.Discord.MessageId) (Result Evergreen.V253.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V253.Discord.Id Evergreen.V253.Discord.GuildId) (Evergreen.V253.Discord.Id Evergreen.V253.Discord.ChannelId) Evergreen.V253.Id.ThreadRouteWithMessage (Evergreen.V253.Discord.Id Evergreen.V253.Discord.MessageId) (Result Evergreen.V253.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V253.Discord.Id Evergreen.V253.Discord.PrivateChannelId) (Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelMessageId) (Evergreen.V253.Discord.Id Evergreen.V253.Discord.MessageId) (Result Evergreen.V253.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V253.Discord.Id Evergreen.V253.Discord.GuildId) (Evergreen.V253.Discord.Id Evergreen.V253.Discord.ChannelId) Evergreen.V253.Id.ThreadRouteWithMessage (Evergreen.V253.Discord.Id Evergreen.V253.Discord.MessageId) Evergreen.V253.Emoji.EmojiOrCustomEmoji (Result Evergreen.V253.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V253.Discord.Id Evergreen.V253.Discord.PrivateChannelId) (Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelMessageId) (Evergreen.V253.Discord.Id Evergreen.V253.Discord.MessageId) Evergreen.V253.Emoji.EmojiOrCustomEmoji (Result Evergreen.V253.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V253.Discord.Id Evergreen.V253.Discord.GuildId) (Evergreen.V253.Discord.Id Evergreen.V253.Discord.ChannelId) Evergreen.V253.Id.ThreadRouteWithMessage (Evergreen.V253.Discord.Id Evergreen.V253.Discord.MessageId) Evergreen.V253.Emoji.EmojiOrCustomEmoji (Result Evergreen.V253.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V253.Discord.Id Evergreen.V253.Discord.PrivateChannelId) (Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelMessageId) (Evergreen.V253.Discord.Id Evergreen.V253.Discord.MessageId) Evergreen.V253.Emoji.EmojiOrCustomEmoji (Result Evergreen.V253.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V253.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V253.Discord.HttpError (List ( Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId, Maybe Evergreen.V253.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V253.Slack.CurrentUser
            , team : Evergreen.V253.Slack.Team
            , users : List Evergreen.V253.Slack.User
            , channels : List ( Evergreen.V253.Slack.Channel, List Evergreen.V253.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId) (Result Effect.Http.Error Evergreen.V253.Slack.TokenResponse)
    | GotCloudflareSessionCreated Effect.Lamdera.ClientId Evergreen.V253.Local.ChangeId Effect.Time.Posix Evergreen.V253.Call.RoomId Evergreen.V253.Cloudflare.Sdp (List String) (Result Effect.Http.Error Evergreen.V253.Cloudflare.RealtimeSessionId)
    | GotCloudflareSession Effect.Lamdera.ClientId Evergreen.V253.Local.ChangeId Effect.Time.Posix Evergreen.V253.Call.RoomId Evergreen.V253.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V253.Cloudflare.PushTracksResult)
    | GotCloudflarePullOffer Effect.Time.Posix Effect.Lamdera.ClientId Evergreen.V253.Local.ChangeId Evergreen.V253.Call.ConnectionId Evergreen.V253.Cloudflare.RealtimeSessionId (List Evergreen.V253.Cloudflare.TrackName) (Result Effect.Http.Error Evergreen.V253.Cloudflare.PullTracksResult)
    | GotCloudflareRenegotiateAck Effect.Lamdera.ClientId Evergreen.V253.Local.ChangeId Evergreen.V253.Cloudflare.Sdp (Result Effect.Http.Error ())
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId) Evergreen.V253.Discord.UserAuth (Result Evergreen.V253.Discord.HttpError Evergreen.V253.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId) (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId) (Result Evergreen.V253.Discord.HttpError Evergreen.V253.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId)
        (Result
            Evergreen.V253.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V253.Discord.Id Evergreen.V253.Discord.PrivateChannelId
                , members : List (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId)
                }
            , List
                ( Evergreen.V253.Discord.Id Evergreen.V253.Discord.GuildId
                , { guild : Evergreen.V253.Discord.GatewayGuild
                  , channels : List Evergreen.V253.Discord.Channel
                  , icon : Maybe Evergreen.V253.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId) Bool Evergreen.V253.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V253.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V253.Discord.Id Evergreen.V253.Discord.AttachmentId, Evergreen.V253.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V253.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V253.Discord.Id Evergreen.V253.Discord.AttachmentId, Evergreen.V253.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId) (Evergreen.V253.Discord.Id Evergreen.V253.Discord.GuildId) (Evergreen.V253.Discord.Id Evergreen.V253.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V253.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V253.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId) (Evergreen.V253.Discord.Id Evergreen.V253.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V253.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V253.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId) (Evergreen.V253.Discord.Id Evergreen.V253.Discord.GuildId) (Evergreen.V253.Discord.Id Evergreen.V253.Discord.ChannelId) (Result Evergreen.V253.Discord.HttpError (List Evergreen.V253.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId) (Evergreen.V253.Discord.Id Evergreen.V253.Discord.PrivateChannelId) (Result Evergreen.V253.Discord.HttpError (List Evergreen.V253.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V253.Id.Id Evergreen.V253.Id.GuildId) (Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelId) Evergreen.V253.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V253.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V253.DmChannel.DmChannelId Evergreen.V253.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V253.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V253.Discord.Id Evergreen.V253.Discord.GuildId) (Evergreen.V253.Discord.Id Evergreen.V253.Discord.ChannelId) Evergreen.V253.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V253.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V253.Discord.Id Evergreen.V253.Discord.PrivateChannelId) (Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V253.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId)
        (Evergreen.V253.Discord.Id Evergreen.V253.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V253.Discord.HttpError
            { guild : Evergreen.V253.Discord.GatewayGuild
            , channels : List Evergreen.V253.Discord.Channel
            , icon : Maybe Evergreen.V253.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V253.Discord.Id Evergreen.V253.Discord.GuildId) (Result Evergreen.V253.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V253.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId) (List ( Evergreen.V253.Id.Id Evergreen.V253.Id.StickerId, Result Effect.Http.Error Evergreen.V253.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V253.Id.Id Evergreen.V253.Id.StickerId, Result Effect.Http.Error Evergreen.V253.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId) (List ( Evergreen.V253.Id.Id Evergreen.V253.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V253.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V253.Id.Id Evergreen.V253.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V253.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V253.Discord.HttpError (List Evergreen.V253.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V253.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V253.SecretId.SecretId Evergreen.V253.SecretId.ServerSecret))
    | GotTimeForWebsocketListenClose (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
