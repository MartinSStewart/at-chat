module Evergreen.V248.Types exposing (..)

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
import Evergreen.V248.AiChat
import Evergreen.V248.Call
import Evergreen.V248.ChannelDescription
import Evergreen.V248.ChannelName
import Evergreen.V248.Cloudflare
import Evergreen.V248.Coord
import Evergreen.V248.CssPixels
import Evergreen.V248.CustomEmoji
import Evergreen.V248.Discord
import Evergreen.V248.DiscordAttachmentId
import Evergreen.V248.DiscordUserData
import Evergreen.V248.DmChannel
import Evergreen.V248.Editable
import Evergreen.V248.EmailAddress
import Evergreen.V248.Embed
import Evergreen.V248.Emoji
import Evergreen.V248.FileStatus
import Evergreen.V248.Go
import Evergreen.V248.GuildName
import Evergreen.V248.Id
import Evergreen.V248.ImageEditor
import Evergreen.V248.Local
import Evergreen.V248.LocalState
import Evergreen.V248.Log
import Evergreen.V248.LoginForm
import Evergreen.V248.MembersAndOwner
import Evergreen.V248.Message
import Evergreen.V248.MessageInput
import Evergreen.V248.MessageView
import Evergreen.V248.MyUi
import Evergreen.V248.NonemptyDict
import Evergreen.V248.NonemptySet
import Evergreen.V248.OneToOne
import Evergreen.V248.Pages.Admin
import Evergreen.V248.Pagination
import Evergreen.V248.PersonName
import Evergreen.V248.Ports
import Evergreen.V248.Postmark
import Evergreen.V248.Range
import Evergreen.V248.RichText
import Evergreen.V248.Route
import Evergreen.V248.SecretId
import Evergreen.V248.SessionIdHash
import Evergreen.V248.Slack
import Evergreen.V248.Sticker
import Evergreen.V248.TextEditor
import Evergreen.V248.ToBackendLog
import Evergreen.V248.Touch
import Evergreen.V248.TwoFactorAuthentication
import Evergreen.V248.Ui.Anim
import Evergreen.V248.Untrusted
import Evergreen.V248.User
import Evergreen.V248.UserAgent
import Evergreen.V248.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V248.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V248.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.Id.GuildId) Evergreen.V248.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId) Evergreen.V248.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V248.Discord.Id Evergreen.V248.Discord.PrivateChannelId) Evergreen.V248.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V248.Discord.Id Evergreen.V248.Discord.GuildId) Evergreen.V248.LocalState.DiscordFrontendGuild
    , user : Evergreen.V248.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId) Evergreen.V248.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId) Evergreen.V248.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId) Evergreen.V248.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V248.SessionIdHash.SessionIdHash Evergreen.V248.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V248.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.Id.StickerId) Evergreen.V248.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.Id.CustomEmojiId) Evergreen.V248.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V248.Call.RoomId (Evergreen.V248.NonemptySet.NonemptySet ( Evergreen.V248.Id.Id Evergreen.V248.Id.UserId, Effect.Lamdera.ClientId ))
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type PublicGoMatch
    = PublicGoMatch_NotLoaded
    | PublicGoMatch_Loading
    | PublicGoMatch_Loaded Evergreen.V248.Go.PublicGoMatchData Evergreen.V248.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V248.Route.Route
    , windowSize : Evergreen.V248.Coord.Coord Evergreen.V248.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V248.Ports.NotificationPermission
    , pwaStatus : Evergreen.V248.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V248.UserAgent.UserAgent
    , publicGoMatch : PublicGoMatch
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V248.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V248.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V248.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.FileStatus.FileId) Evergreen.V248.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V248.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V248.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.FileStatus.FileId) Evergreen.V248.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V248.Id.Id Evergreen.V248.Id.GuildId) Evergreen.V248.ChannelName.ChannelName Evergreen.V248.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V248.Id.Id Evergreen.V248.Id.GuildId) (Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelId) Evergreen.V248.ChannelName.ChannelName Evergreen.V248.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V248.Id.Id Evergreen.V248.Id.GuildId) (Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelId)
    | Local_DeleteGuild (Evergreen.V248.Id.Id Evergreen.V248.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V248.Id.Id Evergreen.V248.Id.GuildId) (Evergreen.V248.UserSession.ToBeFilledInByBackend (Evergreen.V248.SecretId.SecretId Evergreen.V248.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V248.Id.Id Evergreen.V248.Id.GuildId) (Evergreen.V248.SecretId.SecretId Evergreen.V248.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V248.GuildName.GuildName (Evergreen.V248.UserSession.ToBeFilledInByBackend (Evergreen.V248.Id.Id Evergreen.V248.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V248.Id.AnyGuildOrDmId, Evergreen.V248.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V248.Id.AnyGuildOrDmId Evergreen.V248.Id.ThreadRouteWithMessage Evergreen.V248.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V248.Id.AnyGuildOrDmId Evergreen.V248.Id.ThreadRouteWithMessage Evergreen.V248.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V248.Id.GuildOrDmId Evergreen.V248.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.FileStatus.FileId) Evergreen.V248.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId) (Evergreen.V248.Discord.Id Evergreen.V248.Discord.GuildId) (Evergreen.V248.Discord.Id Evergreen.V248.Discord.ChannelId) Evergreen.V248.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V248.Id.DiscordGuildOrDmId_DmData (Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V248.Id.AnyGuildOrDmId Evergreen.V248.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V248.Id.AnyGuildOrDmId Evergreen.V248.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V248.Id.AnyGuildOrDmId Evergreen.V248.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V248.UserSession.SetViewing
    | Local_SetName Evergreen.V248.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V248.Id.GuildOrDmId (Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelMessageId) (Evergreen.V248.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelMessageId) (Evergreen.V248.Message.Message Evergreen.V248.Id.ChannelMessageId (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V248.Id.GuildOrDmId (Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelMessageId) (Evergreen.V248.Id.Id Evergreen.V248.Id.ThreadMessageId) (Evergreen.V248.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.Id.ThreadMessageId) (Evergreen.V248.Message.Message Evergreen.V248.Id.ThreadMessageId (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V248.Id.DiscordGuildOrDmId (Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelMessageId) (Evergreen.V248.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelMessageId) (Evergreen.V248.Message.Message Evergreen.V248.Id.ChannelMessageId (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V248.Id.DiscordGuildOrDmId (Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelMessageId) (Evergreen.V248.Id.Id Evergreen.V248.Id.ThreadMessageId) (Evergreen.V248.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.Id.ThreadMessageId) (Evergreen.V248.Message.Message Evergreen.V248.Id.ThreadMessageId (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V248.Id.Id Evergreen.V248.Id.GuildId) Evergreen.V248.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId) (Evergreen.V248.Discord.Id Evergreen.V248.Discord.GuildId) Evergreen.V248.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V248.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V248.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V248.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V248.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V248.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V248.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V248.NonemptySet.NonemptySet (Evergreen.V248.Id.Id Evergreen.V248.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V248.Call.LocalChange
    | Local_Go
        { otherUserId : Evergreen.V248.Id.Id Evergreen.V248.Id.UserId
        }
        Evergreen.V248.Go.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId) Effect.Time.Posix Evergreen.V248.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V248.RichText.RichText (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId))) Evergreen.V248.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.FileStatus.FileId) Evergreen.V248.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.Id.StickerId) Evergreen.V248.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V248.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V248.RichText.RichText (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId))) Evergreen.V248.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.FileStatus.FileId) Evergreen.V248.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.Id.StickerId) Evergreen.V248.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V248.Id.Id Evergreen.V248.Id.GuildId) Evergreen.V248.ChannelName.ChannelName Evergreen.V248.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V248.Id.Id Evergreen.V248.Id.GuildId) (Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelId) Evergreen.V248.ChannelName.ChannelName Evergreen.V248.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V248.Id.Id Evergreen.V248.Id.GuildId) (Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelId)
    | Server_DeleteGuild (Evergreen.V248.Id.Id Evergreen.V248.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId) (Evergreen.V248.Id.Id Evergreen.V248.Id.GuildId) (Evergreen.V248.SecretId.SecretId Evergreen.V248.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V248.Id.Id Evergreen.V248.Id.GuildId) (Evergreen.V248.SecretId.SecretId Evergreen.V248.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId) (Evergreen.V248.Id.Id Evergreen.V248.Id.GuildId) Evergreen.V248.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V248.LocalState.JoinGuildError
            { guildId : Evergreen.V248.Id.Id Evergreen.V248.Id.GuildId
            , guild : Evergreen.V248.LocalState.FrontendGuild
            , owner : Evergreen.V248.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId) Evergreen.V248.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId) Evergreen.V248.Id.GuildOrDmId Evergreen.V248.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId) (Evergreen.V248.Discord.Id Evergreen.V248.Discord.GuildId) (Evergreen.V248.Discord.Id Evergreen.V248.Discord.ChannelId) Evergreen.V248.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId) (Evergreen.V248.Discord.Id Evergreen.V248.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId) Evergreen.V248.Id.GuildOrDmId Evergreen.V248.Id.ThreadRouteWithMessage Evergreen.V248.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId) Evergreen.V248.Id.GuildOrDmId Evergreen.V248.Id.ThreadRouteWithMessage Evergreen.V248.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId) (Evergreen.V248.Discord.Id Evergreen.V248.Discord.GuildId) (Evergreen.V248.Discord.Id Evergreen.V248.Discord.ChannelId) Evergreen.V248.Id.ThreadRouteWithMessage Evergreen.V248.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId) (Evergreen.V248.Discord.Id Evergreen.V248.Discord.PrivateChannelId) (Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelMessageId) Evergreen.V248.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId) (Evergreen.V248.Discord.Id Evergreen.V248.Discord.GuildId) (Evergreen.V248.Discord.Id Evergreen.V248.Discord.ChannelId) Evergreen.V248.Id.ThreadRouteWithMessage Evergreen.V248.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId) (Evergreen.V248.Discord.Id Evergreen.V248.Discord.PrivateChannelId) (Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelMessageId) Evergreen.V248.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId) Evergreen.V248.Id.GuildOrDmId Evergreen.V248.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V248.RichText.RichText (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId))) (SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.FileStatus.FileId) Evergreen.V248.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId) (Evergreen.V248.Discord.Id Evergreen.V248.Discord.GuildId) (Evergreen.V248.Discord.Id Evergreen.V248.Discord.ChannelId) Evergreen.V248.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V248.RichText.RichText (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V248.Id.DiscordGuildOrDmId_DmData (Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V248.RichText.RichText (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId) Evergreen.V248.Id.AnyGuildOrDmId Evergreen.V248.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V248.Id.AnyGuildOrDmId Evergreen.V248.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V248.Discord.Id Evergreen.V248.Discord.GuildId) (Evergreen.V248.Discord.Id Evergreen.V248.Discord.ChannelId) Evergreen.V248.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V248.Discord.Id Evergreen.V248.Discord.PrivateChannelId) (Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId) Evergreen.V248.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId) Evergreen.V248.FileStatus.FileHash
    | Server_SetGuildIcon (Evergreen.V248.Id.Id Evergreen.V248.Id.GuildId) Evergreen.V248.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V248.Id.Id Evergreen.V248.Id.GuildId) Evergreen.V248.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V248.Discord.Id Evergreen.V248.Discord.GuildId) Evergreen.V248.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V248.SessionIdHash.SessionIdHash Evergreen.V248.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V248.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V248.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V248.Id.AnyGuildOrDmId, Evergreen.V248.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V248.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId) Evergreen.V248.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V248.Discord.Id Evergreen.V248.Discord.GuildId) (Evergreen.V248.Discord.Id Evergreen.V248.Discord.ChannelId) Evergreen.V248.ChannelName.ChannelName (Evergreen.V248.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V248.Discord.Id Evergreen.V248.Discord.PrivateChannelId)
        (Evergreen.V248.NonemptyDict.NonemptyDict
            (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V248.Discord.Id Evergreen.V248.Discord.GuildId) Evergreen.V248.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V248.Discord.Id Evergreen.V248.Discord.PrivateChannelId) Evergreen.V248.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId) Evergreen.V248.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId) (Maybe (Evergreen.V248.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V248.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V248.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V248.Id.Id Evergreen.V248.Id.GuildId) (Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelId) Evergreen.V248.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V248.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId) Evergreen.V248.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V248.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V248.Discord.Id Evergreen.V248.Discord.GuildId) (Evergreen.V248.Discord.Id Evergreen.V248.Discord.ChannelId) Evergreen.V248.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V248.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V248.Discord.Id Evergreen.V248.Discord.PrivateChannelId) (Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V248.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V248.Discord.Id Evergreen.V248.Discord.GuildId) Evergreen.V248.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V248.Discord.Id Evergreen.V248.Discord.GuildId) (Evergreen.V248.Discord.Id Evergreen.V248.Discord.ChannelId) (Evergreen.V248.Discord.OptionalData String) (Evergreen.V248.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V248.Discord.Id Evergreen.V248.Discord.GuildId)
        (Evergreen.V248.MembersAndOwner.MembersAndOwner
            (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V248.Discord.Id Evergreen.V248.Discord.GuildId) (Evergreen.V248.Discord.Id Evergreen.V248.Discord.ChannelId) (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId) Evergreen.V248.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.Id.StickerId) Evergreen.V248.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.Id.CustomEmojiId) Evergreen.V248.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V248.Call.ServerChange
    | Server_Go
        (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId)
        { otherUserId : Evergreen.V248.Id.Id Evergreen.V248.Id.UserId
        }
        Evergreen.V248.Go.LocalChange


type LocalMsg
    = LocalChange (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V248.Id.Id Evergreen.V248.Id.GuildId) (Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelId) Evergreen.V248.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V248.Discord.Id Evergreen.V248.Discord.GuildId) (Evergreen.V248.Discord.Id Evergreen.V248.Discord.ChannelId) Evergreen.V248.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.FileStatus.FileId) Evergreen.V248.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V248.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V248.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V248.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V248.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V248.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V248.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V248.Coord.Coord Evergreen.V248.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V248.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V248.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V248.Id.AnyGuildOrDmId Evergreen.V248.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V248.Id.AnyGuildOrDmId Evergreen.V248.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V248.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V248.Coord.Coord Evergreen.V248.CssPixels.CssPixels) (Maybe Evergreen.V248.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V248.Id.AnyGuildOrDmId, Evergreen.V248.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelMessageId) (Evergreen.V248.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.Id.ThreadMessageId) (Evergreen.V248.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V248.Editable.Model
    , showLinkDiscordSetup : Bool
    , domainWhitelistInput : String
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V248.Local.Local LocalMsg Evergreen.V248.LocalState.LocalState
    , admin : Evergreen.V248.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V248.Id.AnyGuildOrDmId, Evergreen.V248.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V248.Id.Id Evergreen.V248.Id.GuildId, Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V248.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V248.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V248.Id.AnyGuildOrDmId, Evergreen.V248.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V248.Id.AnyGuildOrDmId, Evergreen.V248.Id.ThreadRoute ) (Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : Evergreen.V248.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V248.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V248.Id.AnyGuildOrDmId, Evergreen.V248.Id.ThreadRoute ) (Evergreen.V248.NonemptyDict.NonemptyDict (Evergreen.V248.Id.Id Evergreen.V248.FileStatus.FileId) Evergreen.V248.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V248.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V248.TextEditor.Model
    , profilePictureEditor : Evergreen.V248.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V248.Id.Id Evergreen.V248.Id.GuildId, Evergreen.V248.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V248.Emoji.Model
    , voiceChat : Evergreen.V248.Call.Model
    , currentDmGoMatch : SeqDict.SeqDict ( Evergreen.V248.Id.Id Evergreen.V248.Id.UserId, Maybe (Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelMessageId) ) Evergreen.V248.Go.Model
    , fileDragOverCount : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V248.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V248.SecretId.SecretId Evergreen.V248.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V248.Range.Range
                , direction : Evergreen.V248.Range.SelectionDirection
                }
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V248.NonemptyDict.NonemptyDict Int Evergreen.V248.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V248.NonemptyDict.NonemptyDict Int Evergreen.V248.Touch.Touch
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
    | AdminToFrontend Evergreen.V248.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V248.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V248.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V248.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V248.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V248.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V248.Go.PublicGoMatchData)


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V248.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V248.Coord.Coord Evergreen.V248.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V248.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V248.MyUi.LastCopy
    , notificationPermission : Evergreen.V248.Ports.NotificationPermission
    , pwaStatus : Evergreen.V248.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V248.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V248.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V248.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V248.Id.Id Evergreen.V248.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V248.Id.Id Evergreen.V248.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V248.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V248.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V248.Coord.Coord Evergreen.V248.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V248.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V248.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V248.Id.Id Evergreen.V248.Id.GuildId, Evergreen.V248.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V248.DmChannel.DmChannelId, Evergreen.V248.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V248.Discord.Id Evergreen.V248.Discord.GuildId, Evergreen.V248.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V248.Discord.Id Evergreen.V248.Discord.PrivateChannelId, Evergreen.V248.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V248.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V248.NonemptyDict.NonemptyDict (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId) Evergreen.V248.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V248.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V248.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V248.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V248.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId) Evergreen.V248.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId) Evergreen.V248.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V248.Id.Id Evergreen.V248.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.Id.GuildId) Evergreen.V248.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.Id.GuildId) Evergreen.V248.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V248.Discord.Id Evergreen.V248.Discord.GuildId) Evergreen.V248.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V248.DmChannel.DmChannelId Evergreen.V248.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V248.Discord.Id Evergreen.V248.Discord.PrivateChannelId) Evergreen.V248.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V248.OneToOne.OneToOne (Evergreen.V248.Slack.Id Evergreen.V248.Slack.ChannelId) Evergreen.V248.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V248.OneToOne.OneToOne String (Evergreen.V248.Id.Id Evergreen.V248.Id.GuildId)
    , slackUsers : Evergreen.V248.OneToOne.OneToOne (Evergreen.V248.Slack.Id Evergreen.V248.Slack.UserId) (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId)
    , slackServers : Evergreen.V248.OneToOne.OneToOne (Evergreen.V248.Slack.Id Evergreen.V248.Slack.TeamId) (Evergreen.V248.Id.Id Evergreen.V248.Id.GuildId)
    , slackToken : Maybe Evergreen.V248.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V248.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V248.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V248.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareTurnApiToken : Maybe String
    , textEditor : Evergreen.V248.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId) Evergreen.V248.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId, Evergreen.V248.Discord.Id Evergreen.V248.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V248.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V248.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V248.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V248.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId) (Evergreen.V248.LocalState.LoadingDiscordChannel (List Evergreen.V248.Discord.Message))
    , signupsEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V248.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.Id.StickerId) Evergreen.V248.Sticker.StickerData
    , discordStickers : Evergreen.V248.OneToOne.OneToOne (Evergreen.V248.Discord.Id Evergreen.V248.Discord.StickerId) (Evergreen.V248.Id.Id Evergreen.V248.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.Id.CustomEmojiId) Evergreen.V248.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V248.OneToOne.OneToOne Evergreen.V248.RichText.DiscordCustomEmojiIdAndName (Evergreen.V248.Id.Id Evergreen.V248.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V248.Postmark.ApiKey
    , serverSecret : Evergreen.V248.SecretId.SecretId Evergreen.V248.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V248.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V248.OneToOne.OneToOne (Evergreen.V248.SecretId.SecretId Evergreen.V248.Id.GoMatchPublicId) ( Evergreen.V248.DmChannel.DmChannelId, Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelMessageId )
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V248.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V248.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V248.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V248.Route.Route
    | SelectedFilesToAttach ( Evergreen.V248.Id.AnyGuildOrDmId, Evergreen.V248.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V248.Id.Id Evergreen.V248.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V248.Id.Id Evergreen.V248.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V248.Id.Id Evergreen.V248.Id.GuildId) (Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelId) Evergreen.V248.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V248.Id.Id Evergreen.V248.Id.GuildId) (Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelId) Evergreen.V248.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V248.Discord.Id Evergreen.V248.Discord.GuildId) (Evergreen.V248.Discord.Id Evergreen.V248.Discord.ChannelId) Evergreen.V248.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V248.Discord.Id Evergreen.V248.Discord.GuildId) (Evergreen.V248.Discord.Id Evergreen.V248.Discord.ChannelId) Evergreen.V248.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V248.Id.Id Evergreen.V248.Id.GuildId) (Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V248.Id.Id Evergreen.V248.Id.GuildId) (Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V248.Id.Id Evergreen.V248.Id.GuildId) (Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V248.Id.Id Evergreen.V248.Id.GuildId) (Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V248.Id.Id Evergreen.V248.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V248.Id.Id Evergreen.V248.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V248.Id.Id Evergreen.V248.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V248.Id.Id Evergreen.V248.Id.GuildId) (Evergreen.V248.SecretId.SecretId Evergreen.V248.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V248.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V248.Id.AnyGuildOrDmId Evergreen.V248.Id.ThreadRouteWithMessage (Evergreen.V248.Coord.Coord Evergreen.V248.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V248.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V248.Id.AnyGuildOrDmId Evergreen.V248.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V248.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V248.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V248.Id.AnyGuildOrDmId, Evergreen.V248.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V248.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V248.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V248.Id.AnyGuildOrDmId, Evergreen.V248.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V248.NonemptyDict.NonemptyDict Int Evergreen.V248.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V248.NonemptyDict.NonemptyDict Int Evergreen.V248.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V248.Id.AnyGuildOrDmId Evergreen.V248.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V248.Id.AnyGuildOrDmId Evergreen.V248.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V248.NonemptySet.NonemptySet (Evergreen.V248.Id.Id Evergreen.V248.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V248.Id.AnyGuildOrDmId, Evergreen.V248.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V248.Id.AnyGuildOrDmId Evergreen.V248.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V248.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V248.AiChat.Msg
    | GoMsg Evergreen.V248.Go.Msg
    | GoSpectatorMsg Evergreen.V248.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V248.Editable.Msg Evergreen.V248.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V248.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V248.Id.Id Evergreen.V248.Id.GuildId) Evergreen.V248.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V248.Id.AnyGuildOrDmId, Evergreen.V248.Id.ThreadRoute ) (Evergreen.V248.Id.Id Evergreen.V248.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V248.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V248.Id.AnyGuildOrDmId, Evergreen.V248.Id.ThreadRoute ) (Evergreen.V248.Id.Id Evergreen.V248.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V248.Id.AnyGuildOrDmId, Evergreen.V248.Id.ThreadRoute ) (Evergreen.V248.Id.Id Evergreen.V248.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V248.Id.AnyGuildOrDmId, Evergreen.V248.Id.ThreadRoute )
        { fileId : Evergreen.V248.Id.Id Evergreen.V248.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V248.Id.AnyGuildOrDmId, Evergreen.V248.Id.ThreadRoute ) (Evergreen.V248.Id.Id Evergreen.V248.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V248.Id.AnyGuildOrDmId, Evergreen.V248.Id.ThreadRoute ) (Evergreen.V248.Id.Id Evergreen.V248.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V248.Id.AnyGuildOrDmId, Evergreen.V248.Id.ThreadRoute )
        { fileId : Evergreen.V248.Id.Id Evergreen.V248.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V248.Id.AnyGuildOrDmId, Evergreen.V248.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V248.Id.AnyGuildOrDmId, Evergreen.V248.Id.ThreadRoute ) (Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelMessageId) (Evergreen.V248.Id.Id Evergreen.V248.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V248.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V248.Id.AnyGuildOrDmId, Evergreen.V248.Id.ThreadRoute ) (Evergreen.V248.Id.Id Evergreen.V248.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V248.Id.AnyGuildOrDmId Evergreen.V248.Id.ThreadRouteWithMessage Evergreen.V248.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V248.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V248.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V248.Id.Id Evergreen.V248.Id.GuildId) Evergreen.V248.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId) (Evergreen.V248.Discord.Id Evergreen.V248.Discord.GuildId) Evergreen.V248.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V248.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V248.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId
        , otherUserId : Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V248.Id.AnyGuildOrDmId Evergreen.V248.Id.ThreadRoute Evergreen.V248.MessageInput.Msg
    | MessageInputMsg Evergreen.V248.Id.AnyGuildOrDmId Evergreen.V248.Id.ThreadRoute Evergreen.V248.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V248.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V248.Range.Range, Evergreen.V248.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V248.Range.Range, Evergreen.V248.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V248.Call.FromJs)
    | VoiceChatMsg Evergreen.V248.Call.Msg
    | PressedChannelHeaderTab Evergreen.V248.Route.DmChannelHeaderTab
    | FileDragEnter
    | FileDragLeave
    | FileDropped (List Effect.File.File)


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V248.Id.Id Evergreen.V248.Id.GuildId) (Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelId) Evergreen.V248.Id.ThreadRoute
    | InitialLoadRequested_Dm Evergreen.V248.DmChannel.DmChannelId Evergreen.V248.Id.ThreadRoute
    | InitialLoadRequested_Discord Evergreen.V248.Id.DiscordGuildOrDmId Evergreen.V248.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V248.Id.Id Evergreen.V248.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V248.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V248.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V248.Untrusted.Untrusted Evergreen.V248.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V248.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V248.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V248.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V248.Id.Id Evergreen.V248.Id.GuildId) (Evergreen.V248.SecretId.SecretId Evergreen.V248.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V248.PersonName.PersonName Evergreen.V248.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V248.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V248.Slack.OAuthCode Evergreen.V248.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V248.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V248.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V248.Id.Id Evergreen.V248.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V248.SecretId.SecretId Evergreen.V248.Id.GoMatchPublicId)


type alias PendingVoiceChatJoin =
    { sessionId : Effect.Lamdera.SessionId
    , clientId : Effect.Lamdera.ClientId
    , changeId : Evergreen.V248.Local.ChangeId
    , time : Effect.Time.Posix
    , userId : Evergreen.V248.Id.Id Evergreen.V248.Id.UserId
    , otherUserId : Evergreen.V248.Id.Id Evergreen.V248.Id.UserId
    , dmChannelId : Evergreen.V248.DmChannel.DmChannelId
    , roomId : Evergreen.V248.Call.RoomId
    }


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V248.Discord.Id Evergreen.V248.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V248.Discord.Id Evergreen.V248.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V248.EmailAddress.EmailAddress (Result Evergreen.V248.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V248.EmailAddress.EmailAddress (Result Evergreen.V248.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId) Evergreen.V248.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V248.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V248.Discord.Id Evergreen.V248.Discord.GuildId) (Evergreen.V248.Discord.Id Evergreen.V248.Discord.ChannelId) Evergreen.V248.Id.ThreadRouteWithMaybeMessage (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId) (Result Evergreen.V248.Discord.HttpError Evergreen.V248.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V248.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V248.Discord.Id Evergreen.V248.Discord.PrivateChannelId) (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId) (Result Evergreen.V248.Discord.HttpError Evergreen.V248.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V248.Discord.Id Evergreen.V248.Discord.GuildId) (Evergreen.V248.Discord.Id Evergreen.V248.Discord.ChannelId) Evergreen.V248.Id.ThreadRouteWithMessage (Evergreen.V248.Discord.Id Evergreen.V248.Discord.MessageId) (Result Evergreen.V248.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V248.Discord.Id Evergreen.V248.Discord.PrivateChannelId) (Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelMessageId) (Evergreen.V248.Discord.Id Evergreen.V248.Discord.MessageId) (Result Evergreen.V248.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V248.Discord.Id Evergreen.V248.Discord.GuildId) (Evergreen.V248.Discord.Id Evergreen.V248.Discord.ChannelId) Evergreen.V248.Id.ThreadRouteWithMessage (Evergreen.V248.Discord.Id Evergreen.V248.Discord.MessageId) (Result Evergreen.V248.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V248.Discord.Id Evergreen.V248.Discord.PrivateChannelId) (Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelMessageId) (Evergreen.V248.Discord.Id Evergreen.V248.Discord.MessageId) (Result Evergreen.V248.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V248.Discord.Id Evergreen.V248.Discord.GuildId) (Evergreen.V248.Discord.Id Evergreen.V248.Discord.ChannelId) Evergreen.V248.Id.ThreadRouteWithMessage (Evergreen.V248.Discord.Id Evergreen.V248.Discord.MessageId) Evergreen.V248.Emoji.EmojiOrCustomEmoji (Result Evergreen.V248.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V248.Discord.Id Evergreen.V248.Discord.PrivateChannelId) (Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelMessageId) (Evergreen.V248.Discord.Id Evergreen.V248.Discord.MessageId) Evergreen.V248.Emoji.EmojiOrCustomEmoji (Result Evergreen.V248.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V248.Discord.Id Evergreen.V248.Discord.GuildId) (Evergreen.V248.Discord.Id Evergreen.V248.Discord.ChannelId) Evergreen.V248.Id.ThreadRouteWithMessage (Evergreen.V248.Discord.Id Evergreen.V248.Discord.MessageId) Evergreen.V248.Emoji.EmojiOrCustomEmoji (Result Evergreen.V248.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V248.Discord.Id Evergreen.V248.Discord.PrivateChannelId) (Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelMessageId) (Evergreen.V248.Discord.Id Evergreen.V248.Discord.MessageId) Evergreen.V248.Emoji.EmojiOrCustomEmoji (Result Evergreen.V248.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V248.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V248.Discord.HttpError (List ( Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId, Maybe Evergreen.V248.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V248.Slack.CurrentUser
            , team : Evergreen.V248.Slack.Team
            , users : List Evergreen.V248.Slack.User
            , channels : List ( Evergreen.V248.Slack.Channel, List Evergreen.V248.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId) (Result Effect.Http.Error Evergreen.V248.Slack.TokenResponse)
    | GotCloudflareTurnCredentials PendingVoiceChatJoin (Result Effect.Http.Error (List Evergreen.V248.Cloudflare.TurnConfig))
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId) Evergreen.V248.Discord.UserAuth (Result Evergreen.V248.Discord.HttpError Evergreen.V248.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId) (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId) (Result Evergreen.V248.Discord.HttpError Evergreen.V248.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId)
        (Result
            Evergreen.V248.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V248.Discord.Id Evergreen.V248.Discord.PrivateChannelId
                , members : List (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId)
                }
            , List
                ( Evergreen.V248.Discord.Id Evergreen.V248.Discord.GuildId
                , { guild : Evergreen.V248.Discord.GatewayGuild
                  , channels : List Evergreen.V248.Discord.Channel
                  , icon : Maybe Evergreen.V248.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId) Bool Evergreen.V248.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V248.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V248.Discord.Id Evergreen.V248.Discord.AttachmentId, Evergreen.V248.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V248.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V248.Discord.Id Evergreen.V248.Discord.AttachmentId, Evergreen.V248.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId) (Evergreen.V248.Discord.Id Evergreen.V248.Discord.GuildId) (Evergreen.V248.Discord.Id Evergreen.V248.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V248.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V248.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId) (Evergreen.V248.Discord.Id Evergreen.V248.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V248.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V248.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId) (Evergreen.V248.Discord.Id Evergreen.V248.Discord.GuildId) (Evergreen.V248.Discord.Id Evergreen.V248.Discord.ChannelId) (Result Evergreen.V248.Discord.HttpError (List Evergreen.V248.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId) (Evergreen.V248.Discord.Id Evergreen.V248.Discord.PrivateChannelId) (Result Evergreen.V248.Discord.HttpError (List Evergreen.V248.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V248.Id.Id Evergreen.V248.Id.GuildId) (Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelId) Evergreen.V248.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V248.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V248.DmChannel.DmChannelId Evergreen.V248.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V248.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V248.Discord.Id Evergreen.V248.Discord.GuildId) (Evergreen.V248.Discord.Id Evergreen.V248.Discord.ChannelId) Evergreen.V248.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V248.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V248.Discord.Id Evergreen.V248.Discord.PrivateChannelId) (Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V248.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId)
        (Evergreen.V248.Discord.Id Evergreen.V248.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V248.Discord.HttpError
            { guild : Evergreen.V248.Discord.GatewayGuild
            , channels : List Evergreen.V248.Discord.Channel
            , icon : Maybe Evergreen.V248.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V248.Discord.Id Evergreen.V248.Discord.GuildId) (Result Evergreen.V248.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V248.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId) (List ( Evergreen.V248.Id.Id Evergreen.V248.Id.StickerId, Result Effect.Http.Error Evergreen.V248.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V248.Id.Id Evergreen.V248.Id.StickerId, Result Effect.Http.Error Evergreen.V248.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId) (List ( Evergreen.V248.Id.Id Evergreen.V248.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V248.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V248.Id.Id Evergreen.V248.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V248.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V248.Discord.HttpError (List Evergreen.V248.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V248.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V248.SecretId.SecretId Evergreen.V248.SecretId.ServerSecret))
    | GotTimeForWebsocketListenClose (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId) String Effect.Time.Posix
