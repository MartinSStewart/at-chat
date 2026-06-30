module Evergreen.V297.Types exposing (..)

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
import Evergreen.V297.AiChat
import Evergreen.V297.Call
import Evergreen.V297.ChannelDescription
import Evergreen.V297.ChannelName
import Evergreen.V297.Cloudflare
import Evergreen.V297.Coord
import Evergreen.V297.CssPixels
import Evergreen.V297.CustomEmoji
import Evergreen.V297.Discord
import Evergreen.V297.DiscordAttachmentId
import Evergreen.V297.DiscordUserData
import Evergreen.V297.DmChannel
import Evergreen.V297.Drawing
import Evergreen.V297.Editable
import Evergreen.V297.EmailAddress
import Evergreen.V297.Embed
import Evergreen.V297.Emoji
import Evergreen.V297.FileStatus
import Evergreen.V297.Game
import Evergreen.V297.Go
import Evergreen.V297.GuildName
import Evergreen.V297.Id
import Evergreen.V297.ImageEditor
import Evergreen.V297.ImageViewer
import Evergreen.V297.LinkedAndOtherDiscordUsers
import Evergreen.V297.Local
import Evergreen.V297.LocalState
import Evergreen.V297.Log
import Evergreen.V297.LoginForm
import Evergreen.V297.MembersAndOwner
import Evergreen.V297.Message
import Evergreen.V297.MessageInput
import Evergreen.V297.MessageView
import Evergreen.V297.MyUi
import Evergreen.V297.NonemptyDict
import Evergreen.V297.NonemptySet
import Evergreen.V297.OneOrGreater
import Evergreen.V297.OneToOne
import Evergreen.V297.Pages.Admin
import Evergreen.V297.Pagination
import Evergreen.V297.PersonName
import Evergreen.V297.Ports
import Evergreen.V297.Postmark
import Evergreen.V297.Range
import Evergreen.V297.RichText
import Evergreen.V297.Route
import Evergreen.V297.SecretId
import Evergreen.V297.SessionIdHash
import Evergreen.V297.Slack
import Evergreen.V297.Sticker
import Evergreen.V297.TextEditor
import Evergreen.V297.ToBackendLog
import Evergreen.V297.Touch
import Evergreen.V297.TwoFactorAuthentication
import Evergreen.V297.Ui.Anim
import Evergreen.V297.Untrusted
import Evergreen.V297.User
import Evergreen.V297.UserAgent
import Evergreen.V297.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V297.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V297.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.Id.GuildId) Evergreen.V297.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId) Evergreen.V297.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V297.Discord.Id Evergreen.V297.Discord.PrivateChannelId) Evergreen.V297.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V297.Discord.Id Evergreen.V297.Discord.GuildId) Evergreen.V297.LocalState.DiscordFrontendGuild
    , user : Evergreen.V297.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId) Evergreen.V297.User.FrontendUser
    , discordUsers : Evergreen.V297.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V297.SessionIdHash.SessionIdHash Evergreen.V297.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V297.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.Id.StickerId) Evergreen.V297.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.Id.CustomEmojiId) Evergreen.V297.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V297.Call.CallId (Evergreen.V297.NonemptyDict.NonemptyDict ( Evergreen.V297.Id.Id Evergreen.V297.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V297.Call.RemoteCallData)
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type PublicGoMatch
    = PublicGoMatch_NotLoaded
    | PublicGoMatch_Loading
    | PublicGoMatch_Loaded Evergreen.V297.Go.PublicGoMatchData Evergreen.V297.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V297.Route.Route
    , windowSize : Evergreen.V297.Coord.Coord Evergreen.V297.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , timezone : Effect.Time.Zone
    , startupData : Maybe Evergreen.V297.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V297.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V297.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V297.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.FileStatus.FileId) Evergreen.V297.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V297.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V297.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.FileStatus.FileId) Evergreen.V297.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V297.Id.Id Evergreen.V297.Id.GuildId) Evergreen.V297.ChannelName.ChannelName Evergreen.V297.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V297.Id.Id Evergreen.V297.Id.GuildId) (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelId) Evergreen.V297.ChannelName.ChannelName Evergreen.V297.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V297.Id.Id Evergreen.V297.Id.GuildId) (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelId)
    | Local_DeleteGuild (Evergreen.V297.Id.Id Evergreen.V297.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V297.Id.Id Evergreen.V297.Id.GuildId) (Evergreen.V297.UserSession.ToBeFilledInByBackend (Evergreen.V297.SecretId.SecretId Evergreen.V297.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V297.Id.Id Evergreen.V297.Id.GuildId) (Evergreen.V297.SecretId.SecretId Evergreen.V297.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V297.GuildName.GuildName (Evergreen.V297.UserSession.ToBeFilledInByBackend (Evergreen.V297.Id.Id Evergreen.V297.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V297.Id.AnyGuildOrDmId, Evergreen.V297.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V297.Id.AnyGuildOrDmId Evergreen.V297.Id.ThreadRouteWithMessage Evergreen.V297.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V297.Id.AnyGuildOrDmId Evergreen.V297.Id.ThreadRouteWithMessage Evergreen.V297.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V297.Id.GuildOrDmId Evergreen.V297.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.FileStatus.FileId) Evergreen.V297.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId) (Evergreen.V297.Discord.Id Evergreen.V297.Discord.GuildId) (Evergreen.V297.Discord.Id Evergreen.V297.Discord.ChannelId) Evergreen.V297.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V297.Id.DiscordGuildOrDmId_DmData (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V297.Id.AnyGuildOrDmId Evergreen.V297.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V297.Id.AnyGuildOrDmId Evergreen.V297.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V297.Id.AnyGuildOrDmId Evergreen.V297.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V297.UserSession.SetViewing
    | Local_SetName Evergreen.V297.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V297.Id.GuildOrDmId (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelMessageId) (Evergreen.V297.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelMessageId) (Evergreen.V297.Message.Message Evergreen.V297.Id.ChannelMessageId (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V297.Id.GuildOrDmId (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelMessageId) (Evergreen.V297.Id.Id Evergreen.V297.Id.ThreadMessageId) (Evergreen.V297.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.Id.ThreadMessageId) (Evergreen.V297.Message.Message Evergreen.V297.Id.ThreadMessageId (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V297.Id.DiscordGuildOrDmId (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelMessageId) (Evergreen.V297.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelMessageId) (Evergreen.V297.Message.Message Evergreen.V297.Id.ChannelMessageId (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V297.Id.DiscordGuildOrDmId (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelMessageId) (Evergreen.V297.Id.Id Evergreen.V297.Id.ThreadMessageId) (Evergreen.V297.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.Id.ThreadMessageId) (Evergreen.V297.Message.Message Evergreen.V297.Id.ThreadMessageId (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V297.Id.Id Evergreen.V297.Id.GuildId) Evergreen.V297.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId) (Evergreen.V297.Discord.Id Evergreen.V297.Discord.GuildId) Evergreen.V297.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V297.UserSession.NotificationMode
    | Local_SetEmailNotifications Evergreen.V297.User.EmailNotifications
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V297.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V297.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V297.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V297.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V297.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V297.NonemptySet.NonemptySet (Evergreen.V297.Id.Id Evergreen.V297.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V297.Call.LocalChange
    | Local_Game
        { otherUserId : Evergreen.V297.Id.Id Evergreen.V297.Id.UserId
        }
        Evergreen.V297.Game.LocalChange
    | Local_Drawing Evergreen.V297.Id.AnyGuildOrDmId Evergreen.V297.Drawing.AnchorType Evergreen.V297.Drawing.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId) Effect.Time.Posix Evergreen.V297.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V297.RichText.RichText (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId))) Evergreen.V297.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.FileStatus.FileId) Evergreen.V297.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.Id.StickerId) Evergreen.V297.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V297.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V297.RichText.RichText (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId))) Evergreen.V297.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.FileStatus.FileId) Evergreen.V297.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.Id.StickerId) Evergreen.V297.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V297.Id.Id Evergreen.V297.Id.GuildId) Evergreen.V297.ChannelName.ChannelName Evergreen.V297.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V297.Id.Id Evergreen.V297.Id.GuildId) (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelId) Evergreen.V297.ChannelName.ChannelName Evergreen.V297.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V297.Id.Id Evergreen.V297.Id.GuildId) (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelId)
    | Server_DeleteGuild (Evergreen.V297.Id.Id Evergreen.V297.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId) (Evergreen.V297.Id.Id Evergreen.V297.Id.GuildId) (Evergreen.V297.SecretId.SecretId Evergreen.V297.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V297.Id.Id Evergreen.V297.Id.GuildId) (Evergreen.V297.SecretId.SecretId Evergreen.V297.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId) (Evergreen.V297.Id.Id Evergreen.V297.Id.GuildId) Evergreen.V297.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V297.LocalState.JoinGuildError
            { guildId : Evergreen.V297.Id.Id Evergreen.V297.Id.GuildId
            , guild : Evergreen.V297.LocalState.FrontendGuild
            , owner : Evergreen.V297.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId) Evergreen.V297.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId) Evergreen.V297.Id.GuildOrDmId Evergreen.V297.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId) (Evergreen.V297.Discord.Id Evergreen.V297.Discord.GuildId) (Evergreen.V297.Discord.Id Evergreen.V297.Discord.ChannelId) Evergreen.V297.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId) (Evergreen.V297.Discord.Id Evergreen.V297.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId) Evergreen.V297.Id.GuildOrDmId Evergreen.V297.Id.ThreadRouteWithMessage Evergreen.V297.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId) Evergreen.V297.Id.GuildOrDmId Evergreen.V297.Id.ThreadRouteWithMessage Evergreen.V297.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId) (Evergreen.V297.Discord.Id Evergreen.V297.Discord.GuildId) (Evergreen.V297.Discord.Id Evergreen.V297.Discord.ChannelId) Evergreen.V297.Id.ThreadRouteWithMessage Evergreen.V297.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId) (Evergreen.V297.Discord.Id Evergreen.V297.Discord.PrivateChannelId) (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelMessageId) Evergreen.V297.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId) (Evergreen.V297.Discord.Id Evergreen.V297.Discord.GuildId) (Evergreen.V297.Discord.Id Evergreen.V297.Discord.ChannelId) Evergreen.V297.Id.ThreadRouteWithMessage Evergreen.V297.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId) (Evergreen.V297.Discord.Id Evergreen.V297.Discord.PrivateChannelId) (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelMessageId) Evergreen.V297.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId) Evergreen.V297.Id.GuildOrDmId Evergreen.V297.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V297.RichText.RichText (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId))) (SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.FileStatus.FileId) Evergreen.V297.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId) (Evergreen.V297.Discord.Id Evergreen.V297.Discord.GuildId) (Evergreen.V297.Discord.Id Evergreen.V297.Discord.ChannelId) Evergreen.V297.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V297.RichText.RichText (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V297.Id.DiscordGuildOrDmId_DmData (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V297.RichText.RichText (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId) Evergreen.V297.Id.AnyGuildOrDmId Evergreen.V297.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V297.Id.AnyGuildOrDmId Evergreen.V297.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V297.Discord.Id Evergreen.V297.Discord.GuildId) (Evergreen.V297.Discord.Id Evergreen.V297.Discord.ChannelId) Evergreen.V297.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V297.Discord.Id Evergreen.V297.Discord.PrivateChannelId) (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId) Evergreen.V297.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId) Evergreen.V297.FileStatus.FileHash
    | Server_SetGuildIcon (Evergreen.V297.Id.Id Evergreen.V297.Id.GuildId) Evergreen.V297.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V297.Id.Id Evergreen.V297.Id.GuildId) Evergreen.V297.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V297.Discord.Id Evergreen.V297.Discord.GuildId) Evergreen.V297.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V297.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V297.SessionIdHash.SessionIdHash Evergreen.V297.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V297.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V297.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V297.Id.AnyGuildOrDmId, Evergreen.V297.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V297.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId) Evergreen.V297.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V297.Discord.Id Evergreen.V297.Discord.GuildId) (Evergreen.V297.Discord.Id Evergreen.V297.Discord.ChannelId) Evergreen.V297.ChannelName.ChannelName (Evergreen.V297.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V297.Discord.Id Evergreen.V297.Discord.PrivateChannelId)
        (Evergreen.V297.NonemptyDict.NonemptyDict
            (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V297.Discord.Id Evergreen.V297.Discord.GuildId) Evergreen.V297.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V297.Discord.Id Evergreen.V297.Discord.PrivateChannelId) Evergreen.V297.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId) Evergreen.V297.UserSession.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId) (Maybe (Evergreen.V297.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V297.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V297.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V297.Id.Id Evergreen.V297.Id.GuildId) (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelId) Evergreen.V297.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V297.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId) Evergreen.V297.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V297.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V297.Discord.Id Evergreen.V297.Discord.GuildId) (Evergreen.V297.Discord.Id Evergreen.V297.Discord.ChannelId) Evergreen.V297.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V297.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V297.Discord.Id Evergreen.V297.Discord.PrivateChannelId) (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V297.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V297.Discord.Id Evergreen.V297.Discord.GuildId) Evergreen.V297.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V297.Discord.Id Evergreen.V297.Discord.GuildId) (Evergreen.V297.Discord.Id Evergreen.V297.Discord.ChannelId) (Evergreen.V297.Discord.OptionalData String) (Evergreen.V297.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V297.Discord.Id Evergreen.V297.Discord.GuildId)
        (Evergreen.V297.MembersAndOwner.MembersAndOwner
            (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V297.Discord.Id Evergreen.V297.Discord.GuildId) (Evergreen.V297.Discord.Id Evergreen.V297.Discord.ChannelId) (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId) Evergreen.V297.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.Id.StickerId) Evergreen.V297.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.Id.CustomEmojiId) Evergreen.V297.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V297.Call.ServerChange
    | Server_Game
        (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId)
        { otherUserId : Evergreen.V297.Id.Id Evergreen.V297.Id.UserId
        }
        Evergreen.V297.Game.LocalChange
    | Server_Drawing (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId) Evergreen.V297.Id.AnyGuildOrDmId Evergreen.V297.Drawing.AnchorType Evergreen.V297.Drawing.LocalChange


type LocalMsg
    = LocalChange (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V297.Id.Id Evergreen.V297.Id.GuildId) (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelId) Evergreen.V297.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V297.Discord.Id Evergreen.V297.Discord.GuildId) (Evergreen.V297.Discord.Id Evergreen.V297.Discord.ChannelId) Evergreen.V297.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.FileStatus.FileId) Evergreen.V297.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V297.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V297.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V297.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V297.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V297.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V297.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V297.Coord.Coord Evergreen.V297.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V297.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V297.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V297.Id.AnyGuildOrDmId Evergreen.V297.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V297.Id.AnyGuildOrDmId Evergreen.V297.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V297.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V297.Coord.Coord Evergreen.V297.CssPixels.CssPixels) (Maybe Evergreen.V297.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V297.Id.AnyGuildOrDmId, Evergreen.V297.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelMessageId) (Evergreen.V297.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.Id.ThreadMessageId) (Evergreen.V297.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V297.Editable.Model
    , showLinkDiscordSetup : Bool
    , domainWhitelistInput : String
    , serviceWorkerData : Maybe String
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V297.OneOrGreater.OneOrGreater


type alias LoggedIn2 =
    { localState : Evergreen.V297.Local.Local LocalMsg Evergreen.V297.LocalState.LocalState
    , admin : Evergreen.V297.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V297.Id.AnyGuildOrDmId, Evergreen.V297.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V297.Id.Id Evergreen.V297.Id.GuildId, Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V297.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V297.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V297.Id.AnyGuildOrDmId, Evergreen.V297.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V297.Id.AnyGuildOrDmId, Evergreen.V297.Id.ThreadRoute ) (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : Evergreen.V297.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V297.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V297.Id.AnyGuildOrDmId, Evergreen.V297.Id.ThreadRoute ) (Evergreen.V297.NonemptyDict.NonemptyDict (Evergreen.V297.Id.Id Evergreen.V297.FileStatus.FileId) Evergreen.V297.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V297.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V297.TextEditor.Model
    , profilePictureEditor : Evergreen.V297.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V297.Id.Id Evergreen.V297.Id.GuildId, Evergreen.V297.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V297.Emoji.Model
    , voiceChat : Evergreen.V297.Call.Model
    , currentDmGame : SeqDict.SeqDict ( Evergreen.V297.Id.Id Evergreen.V297.Id.UserId, Maybe (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelMessageId) ) Evergreen.V297.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V297.Drawing.Model
    , showInviteLinkQrCode : Maybe (Evergreen.V297.SecretId.SecretId Evergreen.V297.Id.InviteLinkId)
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V297.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V297.SecretId.SecretId Evergreen.V297.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V297.Range.Range
                , direction : Evergreen.V297.Range.SelectionDirection
                }
        }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_WordSpellingGameBoard


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V297.NonemptyDict.NonemptyDict Int Evergreen.V297.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V297.NonemptyDict.NonemptyDict Int Evergreen.V297.Touch.Touch
        , target : DragTarget
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
    | AdminToFrontend Evergreen.V297.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V297.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V297.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V297.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V297.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V297.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V297.Go.PublicGoMatchResponse)


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V297.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V297.Coord.Coord Evergreen.V297.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V297.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V297.MyUi.LastCopy
    , notificationPermission : Evergreen.V297.Ports.NotificationPermission
    , pwaStatus : Evergreen.V297.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V297.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V297.UserAgent.UserAgent
    , timeOrigin : Effect.Time.Posix
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V297.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V297.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V297.Id.Id Evergreen.V297.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V297.Id.Id Evergreen.V297.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V297.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V297.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V297.Coord.Coord Evergreen.V297.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V297.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V297.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V297.Id.Id Evergreen.V297.Id.GuildId, Evergreen.V297.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V297.DmChannel.DmChannelId, Evergreen.V297.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V297.Discord.Id Evergreen.V297.Discord.GuildId, Evergreen.V297.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V297.Discord.Id Evergreen.V297.Discord.PrivateChannelId, Evergreen.V297.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V297.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V297.NonemptyDict.NonemptyDict (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId) Evergreen.V297.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V297.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V297.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V297.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V297.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId) Evergreen.V297.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId) Evergreen.V297.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V297.Id.Id Evergreen.V297.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.Id.GuildId) Evergreen.V297.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.Id.GuildId) Evergreen.V297.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V297.Discord.Id Evergreen.V297.Discord.GuildId) Evergreen.V297.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V297.DmChannel.DmChannelId Evergreen.V297.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V297.Discord.Id Evergreen.V297.Discord.PrivateChannelId) Evergreen.V297.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V297.OneToOne.OneToOne (Evergreen.V297.Slack.Id Evergreen.V297.Slack.ChannelId) Evergreen.V297.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V297.OneToOne.OneToOne String (Evergreen.V297.Id.Id Evergreen.V297.Id.GuildId)
    , slackUsers : Evergreen.V297.OneToOne.OneToOne (Evergreen.V297.Slack.Id Evergreen.V297.Slack.UserId) (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId)
    , slackServers : Evergreen.V297.OneToOne.OneToOne (Evergreen.V297.Slack.Id Evergreen.V297.Slack.TeamId) (Evergreen.V297.Id.Id Evergreen.V297.Id.GuildId)
    , slackToken : Maybe Evergreen.V297.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V297.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V297.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V297.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V297.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V297.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V297.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V297.Cloudflare.AnalyticsApiToken
    , textEditor : Evergreen.V297.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId) Evergreen.V297.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId, Evergreen.V297.Discord.Id Evergreen.V297.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V297.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V297.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V297.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V297.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId) (Evergreen.V297.LocalState.LoadingDiscordChannel (List Evergreen.V297.Discord.Message))
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V297.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.Id.StickerId) Evergreen.V297.Sticker.StickerData
    , discordStickers : Evergreen.V297.OneToOne.OneToOne (Evergreen.V297.Discord.Id Evergreen.V297.Discord.StickerId) (Evergreen.V297.Id.Id Evergreen.V297.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.Id.CustomEmojiId) Evergreen.V297.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V297.OneToOne.OneToOne Evergreen.V297.RichText.DiscordCustomEmojiIdAndName (Evergreen.V297.Id.Id Evergreen.V297.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V297.Postmark.ApiKey
    , serverSecret : Evergreen.V297.SecretId.SecretId Evergreen.V297.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V297.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V297.OneToOne.OneToOne (Evergreen.V297.SecretId.SecretId Evergreen.V297.Id.GamePublicId) ( Evergreen.V297.DmChannel.DmChannelId, Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelMessageId )
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V297.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V297.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V297.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V297.Route.Route
    | SelectedFilesToAttach ( Evergreen.V297.Id.AnyGuildOrDmId, Evergreen.V297.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V297.Id.Id Evergreen.V297.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V297.Id.Id Evergreen.V297.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V297.Id.Id Evergreen.V297.Id.GuildId) (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelId) Evergreen.V297.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V297.Id.Id Evergreen.V297.Id.GuildId) (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelId) Evergreen.V297.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V297.Discord.Id Evergreen.V297.Discord.GuildId) (Evergreen.V297.Discord.Id Evergreen.V297.Discord.ChannelId) Evergreen.V297.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V297.Discord.Id Evergreen.V297.Discord.GuildId) (Evergreen.V297.Discord.Id Evergreen.V297.Discord.ChannelId) Evergreen.V297.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V297.Id.Id Evergreen.V297.Id.GuildId) (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V297.Id.Id Evergreen.V297.Id.GuildId) (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V297.Id.Id Evergreen.V297.Id.GuildId) (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V297.Id.Id Evergreen.V297.Id.GuildId) (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V297.Id.Id Evergreen.V297.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V297.Id.Id Evergreen.V297.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V297.Id.Id Evergreen.V297.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V297.Id.Id Evergreen.V297.Id.GuildId) (Evergreen.V297.SecretId.SecretId Evergreen.V297.Id.InviteLinkId)
    | PressedToggleInviteLinkQrCode (Evergreen.V297.SecretId.SecretId Evergreen.V297.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V297.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V297.Id.AnyGuildOrDmId Evergreen.V297.Id.ThreadRouteWithMessage (Evergreen.V297.Coord.Coord Evergreen.V297.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V297.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V297.Id.AnyGuildOrDmId Evergreen.V297.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V297.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V297.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V297.Id.AnyGuildOrDmId, Evergreen.V297.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V297.Ports.NotificationPermission
    | TouchStart (Maybe ( Evergreen.V297.Id.AnyGuildOrDmId, Evergreen.V297.Id.ThreadRouteWithMessage, Bool )) Duration.Duration (Evergreen.V297.NonemptyDict.NonemptyDict Int Evergreen.V297.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V297.NonemptyDict.NonemptyDict Int Evergreen.V297.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V297.Id.AnyGuildOrDmId Evergreen.V297.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V297.Id.AnyGuildOrDmId Evergreen.V297.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V297.NonemptySet.NonemptySet (Evergreen.V297.Id.Id Evergreen.V297.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V297.Id.AnyGuildOrDmId, Evergreen.V297.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V297.Id.AnyGuildOrDmId Evergreen.V297.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V297.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V297.AiChat.Msg
    | GameMsg Evergreen.V297.Game.Msg
    | GoSpectatorMsg Evergreen.V297.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V297.Editable.Msg Evergreen.V297.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V297.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V297.Id.Id Evergreen.V297.Id.GuildId) Evergreen.V297.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V297.Id.AnyGuildOrDmId, Evergreen.V297.Id.ThreadRoute ) (Evergreen.V297.Id.Id Evergreen.V297.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V297.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V297.Id.AnyGuildOrDmId, Evergreen.V297.Id.ThreadRoute ) (Evergreen.V297.Id.Id Evergreen.V297.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V297.Id.AnyGuildOrDmId, Evergreen.V297.Id.ThreadRoute ) (Evergreen.V297.Id.Id Evergreen.V297.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V297.Id.AnyGuildOrDmId, Evergreen.V297.Id.ThreadRoute )
        { fileId : Evergreen.V297.Id.Id Evergreen.V297.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V297.Id.AnyGuildOrDmId, Evergreen.V297.Id.ThreadRoute ) (Evergreen.V297.Id.Id Evergreen.V297.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V297.Id.AnyGuildOrDmId, Evergreen.V297.Id.ThreadRoute ) (Evergreen.V297.Id.Id Evergreen.V297.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V297.Id.AnyGuildOrDmId, Evergreen.V297.Id.ThreadRoute )
        { fileId : Evergreen.V297.Id.Id Evergreen.V297.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V297.Id.AnyGuildOrDmId, Evergreen.V297.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V297.Id.AnyGuildOrDmId, Evergreen.V297.Id.ThreadRoute ) (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelMessageId) (Evergreen.V297.Id.Id Evergreen.V297.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V297.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V297.Id.AnyGuildOrDmId, Evergreen.V297.Id.ThreadRoute ) (Evergreen.V297.Id.Id Evergreen.V297.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V297.Id.AnyGuildOrDmId Evergreen.V297.Id.ThreadRouteWithMessage Evergreen.V297.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V297.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V297.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V297.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V297.User.EmailNotifications
    | PressedGuildNotificationLevel (Evergreen.V297.Id.Id Evergreen.V297.Id.GuildId) Evergreen.V297.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId) (Evergreen.V297.Discord.Id Evergreen.V297.Discord.GuildId) Evergreen.V297.User.NotificationLevel
    | GotStartupData Evergreen.V297.Ports.StartupData
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V297.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId
        , otherUserId : Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V297.Id.AnyGuildOrDmId Evergreen.V297.Id.ThreadRoute Evergreen.V297.MessageInput.Msg
    | MessageInputMsg Evergreen.V297.Id.AnyGuildOrDmId Evergreen.V297.Id.ThreadRoute Evergreen.V297.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V297.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V297.Range.Range, Evergreen.V297.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V297.Range.Range, Evergreen.V297.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V297.Call.FromJs)
    | VoiceChatMsg Evergreen.V297.Call.Msg
    | PressedChannelHeaderTab Evergreen.V297.Route.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadServiceWorkerData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V297.Drawing.Msg


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V297.Id.Id Evergreen.V297.Id.GuildId) (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelId) Evergreen.V297.Id.ThreadRoute
    | InitialLoadRequested_Dm Evergreen.V297.DmChannel.DmChannelId Evergreen.V297.Id.ThreadRoute
    | InitialLoadRequested_Discord Evergreen.V297.Id.DiscordGuildOrDmId Evergreen.V297.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V297.Id.Id Evergreen.V297.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V297.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V297.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V297.Untrusted.Untrusted Evergreen.V297.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V297.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V297.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V297.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V297.Id.Id Evergreen.V297.Id.GuildId) (Evergreen.V297.SecretId.SecretId Evergreen.V297.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V297.PersonName.PersonName Evergreen.V297.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V297.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V297.Slack.OAuthCode Evergreen.V297.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V297.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V297.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V297.Id.Id Evergreen.V297.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V297.SecretId.SecretId Evergreen.V297.Id.GamePublicId)


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V297.Discord.Id Evergreen.V297.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V297.Discord.Id Evergreen.V297.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V297.EmailAddress.EmailAddress (Result Evergreen.V297.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V297.EmailAddress.EmailAddress (Result Evergreen.V297.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V297.EmailAddress.EmailAddress (Result Evergreen.V297.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V297.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V297.Discord.Id Evergreen.V297.Discord.GuildId) (Evergreen.V297.Discord.Id Evergreen.V297.Discord.ChannelId) Evergreen.V297.Id.ThreadRouteWithMaybeMessage (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId) (Result Evergreen.V297.Discord.HttpError Evergreen.V297.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V297.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V297.Discord.Id Evergreen.V297.Discord.PrivateChannelId) (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId) (Result Evergreen.V297.Discord.HttpError Evergreen.V297.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V297.Discord.Id Evergreen.V297.Discord.GuildId) (Evergreen.V297.Discord.Id Evergreen.V297.Discord.ChannelId) Evergreen.V297.Id.ThreadRouteWithMessage (Evergreen.V297.Discord.Id Evergreen.V297.Discord.MessageId) (Result Evergreen.V297.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V297.Discord.Id Evergreen.V297.Discord.PrivateChannelId) (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelMessageId) (Evergreen.V297.Discord.Id Evergreen.V297.Discord.MessageId) (Result Evergreen.V297.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V297.Discord.Id Evergreen.V297.Discord.GuildId) (Evergreen.V297.Discord.Id Evergreen.V297.Discord.ChannelId) Evergreen.V297.Id.ThreadRouteWithMessage (Evergreen.V297.Discord.Id Evergreen.V297.Discord.MessageId) (Result Evergreen.V297.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V297.Discord.Id Evergreen.V297.Discord.PrivateChannelId) (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelMessageId) (Evergreen.V297.Discord.Id Evergreen.V297.Discord.MessageId) (Result Evergreen.V297.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V297.Discord.Id Evergreen.V297.Discord.GuildId) (Evergreen.V297.Discord.Id Evergreen.V297.Discord.ChannelId) Evergreen.V297.Id.ThreadRouteWithMessage (Evergreen.V297.Discord.Id Evergreen.V297.Discord.MessageId) Evergreen.V297.Emoji.EmojiOrCustomEmoji (Result Evergreen.V297.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V297.Discord.Id Evergreen.V297.Discord.PrivateChannelId) (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelMessageId) (Evergreen.V297.Discord.Id Evergreen.V297.Discord.MessageId) Evergreen.V297.Emoji.EmojiOrCustomEmoji (Result Evergreen.V297.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V297.Discord.Id Evergreen.V297.Discord.GuildId) (Evergreen.V297.Discord.Id Evergreen.V297.Discord.ChannelId) Evergreen.V297.Id.ThreadRouteWithMessage (Evergreen.V297.Discord.Id Evergreen.V297.Discord.MessageId) Evergreen.V297.Emoji.EmojiOrCustomEmoji (Result Evergreen.V297.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V297.Discord.Id Evergreen.V297.Discord.PrivateChannelId) (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelMessageId) (Evergreen.V297.Discord.Id Evergreen.V297.Discord.MessageId) Evergreen.V297.Emoji.EmojiOrCustomEmoji (Result Evergreen.V297.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V297.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V297.Discord.HttpError (List ( Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId, Maybe Evergreen.V297.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId) Effect.Time.Posix Evergreen.V297.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V297.Slack.CurrentUser
            , team : Evergreen.V297.Slack.Team
            , users : List Evergreen.V297.Slack.User
            , channels : List ( Evergreen.V297.Slack.Channel, List Evergreen.V297.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId) (Result Effect.Http.Error Evergreen.V297.Slack.TokenResponse)
    | GotCloudflareSessionCreated Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V297.Local.ChangeId Effect.Time.Posix Evergreen.V297.Call.CallId Evergreen.V297.Cloudflare.Sdp (List String) (Result Effect.Http.Error Evergreen.V297.Cloudflare.RealtimeSessionId)
    | GotCloudflareSession Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V297.Local.ChangeId Effect.Time.Posix Evergreen.V297.Call.CallId Evergreen.V297.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V297.Cloudflare.PushTracksResult)
    | GotCloudflarePullOffer Effect.Time.Posix Effect.Lamdera.ClientId Evergreen.V297.Local.ChangeId Evergreen.V297.Call.ConnectionId Evergreen.V297.Cloudflare.RealtimeSessionId (List Evergreen.V297.Cloudflare.TrackName) (Result Effect.Http.Error Evergreen.V297.Cloudflare.PullTracksResult)
    | GotCloudflareRenegotiateAck Effect.Lamdera.ClientId Evergreen.V297.Local.ChangeId Evergreen.V297.Cloudflare.Sdp (Result Effect.Http.Error ())
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId) Evergreen.V297.Discord.UserAuth (Result Evergreen.V297.Discord.HttpError Evergreen.V297.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId) (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId) (Result Evergreen.V297.Discord.HttpError Evergreen.V297.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId)
        (Result
            Evergreen.V297.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V297.Discord.Id Evergreen.V297.Discord.PrivateChannelId
                , members : List (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId)
                }
            , List
                ( Evergreen.V297.Discord.Id Evergreen.V297.Discord.GuildId
                , { guild : Evergreen.V297.Discord.GatewayGuild
                  , channels : List Evergreen.V297.Discord.Channel
                  , icon : Maybe Evergreen.V297.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId) Bool Evergreen.V297.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V297.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V297.Discord.Id Evergreen.V297.Discord.AttachmentId, Evergreen.V297.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V297.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V297.Discord.Id Evergreen.V297.Discord.AttachmentId, Evergreen.V297.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId) (Evergreen.V297.Discord.Id Evergreen.V297.Discord.GuildId) (Evergreen.V297.Discord.Id Evergreen.V297.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V297.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V297.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId) (Evergreen.V297.Discord.Id Evergreen.V297.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V297.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V297.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId) (Evergreen.V297.Discord.Id Evergreen.V297.Discord.GuildId) (Evergreen.V297.Discord.Id Evergreen.V297.Discord.ChannelId) (Result Evergreen.V297.Discord.HttpError (List Evergreen.V297.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId) (Evergreen.V297.Discord.Id Evergreen.V297.Discord.PrivateChannelId) (Result Evergreen.V297.Discord.HttpError (List Evergreen.V297.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V297.Id.Id Evergreen.V297.Id.GuildId) (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelId) Evergreen.V297.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V297.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V297.DmChannel.DmChannelId Evergreen.V297.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V297.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V297.Discord.Id Evergreen.V297.Discord.GuildId) (Evergreen.V297.Discord.Id Evergreen.V297.Discord.ChannelId) Evergreen.V297.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V297.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V297.Discord.Id Evergreen.V297.Discord.PrivateChannelId) (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V297.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId)
        (Evergreen.V297.Discord.Id Evergreen.V297.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V297.Discord.HttpError
            { guild : Evergreen.V297.Discord.GatewayGuild
            , channels : List Evergreen.V297.Discord.Channel
            , icon : Maybe Evergreen.V297.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V297.Discord.Id Evergreen.V297.Discord.GuildId) (Result Evergreen.V297.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V297.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId) (List ( Evergreen.V297.Id.Id Evergreen.V297.Id.StickerId, Result Effect.Http.Error Evergreen.V297.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V297.Id.Id Evergreen.V297.Id.StickerId, Result Effect.Http.Error Evergreen.V297.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId) (List ( Evergreen.V297.Id.Id Evergreen.V297.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V297.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V297.Id.Id Evergreen.V297.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V297.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V297.Discord.HttpError (List Evergreen.V297.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V297.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V297.SecretId.SecretId Evergreen.V297.SecretId.ServerSecret))
    | GotTimeForWebsocketListenClose (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | GotCloudflareUsage Effect.Time.Posix (Result Effect.Http.Error Int)
    | GotCloudflareEgressForAdmin Effect.Lamdera.ClientId (Result Effect.Http.Error Int)
    | GotRustServerFileUpload Evergreen.V297.FileStatus.FileHash Int (Maybe (Evergreen.V297.Coord.Coord Evergreen.V297.CssPixels.CssPixels))
