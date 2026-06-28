module Evergreen.V295.Types exposing (..)

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
import Evergreen.V295.AiChat
import Evergreen.V295.Call
import Evergreen.V295.ChannelDescription
import Evergreen.V295.ChannelName
import Evergreen.V295.Cloudflare
import Evergreen.V295.Coord
import Evergreen.V295.CssPixels
import Evergreen.V295.CustomEmoji
import Evergreen.V295.Discord
import Evergreen.V295.DiscordAttachmentId
import Evergreen.V295.DiscordUserData
import Evergreen.V295.DmChannel
import Evergreen.V295.Drawing
import Evergreen.V295.Editable
import Evergreen.V295.EmailAddress
import Evergreen.V295.Embed
import Evergreen.V295.Emoji
import Evergreen.V295.FileStatus
import Evergreen.V295.Game
import Evergreen.V295.Go
import Evergreen.V295.GuildName
import Evergreen.V295.Id
import Evergreen.V295.ImageEditor
import Evergreen.V295.ImageViewer
import Evergreen.V295.LinkedAndOtherDiscordUsers
import Evergreen.V295.Local
import Evergreen.V295.LocalState
import Evergreen.V295.Log
import Evergreen.V295.LoginForm
import Evergreen.V295.MembersAndOwner
import Evergreen.V295.Message
import Evergreen.V295.MessageInput
import Evergreen.V295.MessageView
import Evergreen.V295.MyUi
import Evergreen.V295.NonemptyDict
import Evergreen.V295.NonemptySet
import Evergreen.V295.OneOrGreater
import Evergreen.V295.OneToOne
import Evergreen.V295.Pages.Admin
import Evergreen.V295.Pagination
import Evergreen.V295.PersonName
import Evergreen.V295.Ports
import Evergreen.V295.Postmark
import Evergreen.V295.Range
import Evergreen.V295.RichText
import Evergreen.V295.Route
import Evergreen.V295.SecretId
import Evergreen.V295.SessionIdHash
import Evergreen.V295.Slack
import Evergreen.V295.Sticker
import Evergreen.V295.TextEditor
import Evergreen.V295.ToBackendLog
import Evergreen.V295.Touch
import Evergreen.V295.TwoFactorAuthentication
import Evergreen.V295.Ui.Anim
import Evergreen.V295.Untrusted
import Evergreen.V295.User
import Evergreen.V295.UserAgent
import Evergreen.V295.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V295.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V295.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.Id.GuildId) Evergreen.V295.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId) Evergreen.V295.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V295.Discord.Id Evergreen.V295.Discord.PrivateChannelId) Evergreen.V295.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V295.Discord.Id Evergreen.V295.Discord.GuildId) Evergreen.V295.LocalState.DiscordFrontendGuild
    , user : Evergreen.V295.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId) Evergreen.V295.User.FrontendUser
    , discordUsers : Evergreen.V295.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V295.SessionIdHash.SessionIdHash Evergreen.V295.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V295.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.Id.StickerId) Evergreen.V295.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.Id.CustomEmojiId) Evergreen.V295.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V295.Call.CallId (Evergreen.V295.NonemptyDict.NonemptyDict ( Evergreen.V295.Id.Id Evergreen.V295.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V295.Call.RemoteCallData)
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type PublicGoMatch
    = PublicGoMatch_NotLoaded
    | PublicGoMatch_Loading
    | PublicGoMatch_Loaded Evergreen.V295.Go.PublicGoMatchData Evergreen.V295.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V295.Route.Route
    , windowSize : Evergreen.V295.Coord.Coord Evergreen.V295.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , timezone : Effect.Time.Zone
    , startupData : Maybe Evergreen.V295.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V295.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V295.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V295.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.FileStatus.FileId) Evergreen.V295.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V295.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V295.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.FileStatus.FileId) Evergreen.V295.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V295.Id.Id Evergreen.V295.Id.GuildId) Evergreen.V295.ChannelName.ChannelName Evergreen.V295.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V295.Id.Id Evergreen.V295.Id.GuildId) (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelId) Evergreen.V295.ChannelName.ChannelName Evergreen.V295.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V295.Id.Id Evergreen.V295.Id.GuildId) (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelId)
    | Local_DeleteGuild (Evergreen.V295.Id.Id Evergreen.V295.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V295.Id.Id Evergreen.V295.Id.GuildId) (Evergreen.V295.UserSession.ToBeFilledInByBackend (Evergreen.V295.SecretId.SecretId Evergreen.V295.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V295.Id.Id Evergreen.V295.Id.GuildId) (Evergreen.V295.SecretId.SecretId Evergreen.V295.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V295.GuildName.GuildName (Evergreen.V295.UserSession.ToBeFilledInByBackend (Evergreen.V295.Id.Id Evergreen.V295.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V295.Id.AnyGuildOrDmId, Evergreen.V295.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V295.Id.AnyGuildOrDmId Evergreen.V295.Id.ThreadRouteWithMessage Evergreen.V295.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V295.Id.AnyGuildOrDmId Evergreen.V295.Id.ThreadRouteWithMessage Evergreen.V295.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V295.Id.GuildOrDmId Evergreen.V295.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.FileStatus.FileId) Evergreen.V295.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId) (Evergreen.V295.Discord.Id Evergreen.V295.Discord.GuildId) (Evergreen.V295.Discord.Id Evergreen.V295.Discord.ChannelId) Evergreen.V295.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V295.Id.DiscordGuildOrDmId_DmData (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V295.Id.AnyGuildOrDmId Evergreen.V295.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V295.Id.AnyGuildOrDmId Evergreen.V295.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V295.Id.AnyGuildOrDmId Evergreen.V295.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V295.UserSession.SetViewing
    | Local_SetName Evergreen.V295.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V295.Id.GuildOrDmId (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelMessageId) (Evergreen.V295.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelMessageId) (Evergreen.V295.Message.Message Evergreen.V295.Id.ChannelMessageId (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V295.Id.GuildOrDmId (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelMessageId) (Evergreen.V295.Id.Id Evergreen.V295.Id.ThreadMessageId) (Evergreen.V295.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.Id.ThreadMessageId) (Evergreen.V295.Message.Message Evergreen.V295.Id.ThreadMessageId (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V295.Id.DiscordGuildOrDmId (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelMessageId) (Evergreen.V295.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelMessageId) (Evergreen.V295.Message.Message Evergreen.V295.Id.ChannelMessageId (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V295.Id.DiscordGuildOrDmId (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelMessageId) (Evergreen.V295.Id.Id Evergreen.V295.Id.ThreadMessageId) (Evergreen.V295.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.Id.ThreadMessageId) (Evergreen.V295.Message.Message Evergreen.V295.Id.ThreadMessageId (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V295.Id.Id Evergreen.V295.Id.GuildId) Evergreen.V295.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId) (Evergreen.V295.Discord.Id Evergreen.V295.Discord.GuildId) Evergreen.V295.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V295.UserSession.NotificationMode
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V295.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V295.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V295.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V295.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V295.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V295.NonemptySet.NonemptySet (Evergreen.V295.Id.Id Evergreen.V295.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V295.Call.LocalChange
    | Local_Game
        { otherUserId : Evergreen.V295.Id.Id Evergreen.V295.Id.UserId
        }
        Evergreen.V295.Game.LocalChange
    | Local_Drawing Evergreen.V295.Id.AnyGuildOrDmId Evergreen.V295.Drawing.AnchorType Evergreen.V295.Drawing.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId) Effect.Time.Posix Evergreen.V295.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V295.RichText.RichText (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId))) Evergreen.V295.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.FileStatus.FileId) Evergreen.V295.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.Id.StickerId) Evergreen.V295.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V295.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V295.RichText.RichText (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId))) Evergreen.V295.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.FileStatus.FileId) Evergreen.V295.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.Id.StickerId) Evergreen.V295.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V295.Id.Id Evergreen.V295.Id.GuildId) Evergreen.V295.ChannelName.ChannelName Evergreen.V295.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V295.Id.Id Evergreen.V295.Id.GuildId) (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelId) Evergreen.V295.ChannelName.ChannelName Evergreen.V295.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V295.Id.Id Evergreen.V295.Id.GuildId) (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelId)
    | Server_DeleteGuild (Evergreen.V295.Id.Id Evergreen.V295.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId) (Evergreen.V295.Id.Id Evergreen.V295.Id.GuildId) (Evergreen.V295.SecretId.SecretId Evergreen.V295.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V295.Id.Id Evergreen.V295.Id.GuildId) (Evergreen.V295.SecretId.SecretId Evergreen.V295.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId) (Evergreen.V295.Id.Id Evergreen.V295.Id.GuildId) Evergreen.V295.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V295.LocalState.JoinGuildError
            { guildId : Evergreen.V295.Id.Id Evergreen.V295.Id.GuildId
            , guild : Evergreen.V295.LocalState.FrontendGuild
            , owner : Evergreen.V295.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId) Evergreen.V295.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId) Evergreen.V295.Id.GuildOrDmId Evergreen.V295.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId) (Evergreen.V295.Discord.Id Evergreen.V295.Discord.GuildId) (Evergreen.V295.Discord.Id Evergreen.V295.Discord.ChannelId) Evergreen.V295.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId) (Evergreen.V295.Discord.Id Evergreen.V295.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId) Evergreen.V295.Id.GuildOrDmId Evergreen.V295.Id.ThreadRouteWithMessage Evergreen.V295.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId) Evergreen.V295.Id.GuildOrDmId Evergreen.V295.Id.ThreadRouteWithMessage Evergreen.V295.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId) (Evergreen.V295.Discord.Id Evergreen.V295.Discord.GuildId) (Evergreen.V295.Discord.Id Evergreen.V295.Discord.ChannelId) Evergreen.V295.Id.ThreadRouteWithMessage Evergreen.V295.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId) (Evergreen.V295.Discord.Id Evergreen.V295.Discord.PrivateChannelId) (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelMessageId) Evergreen.V295.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId) (Evergreen.V295.Discord.Id Evergreen.V295.Discord.GuildId) (Evergreen.V295.Discord.Id Evergreen.V295.Discord.ChannelId) Evergreen.V295.Id.ThreadRouteWithMessage Evergreen.V295.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId) (Evergreen.V295.Discord.Id Evergreen.V295.Discord.PrivateChannelId) (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelMessageId) Evergreen.V295.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId) Evergreen.V295.Id.GuildOrDmId Evergreen.V295.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V295.RichText.RichText (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId))) (SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.FileStatus.FileId) Evergreen.V295.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId) (Evergreen.V295.Discord.Id Evergreen.V295.Discord.GuildId) (Evergreen.V295.Discord.Id Evergreen.V295.Discord.ChannelId) Evergreen.V295.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V295.RichText.RichText (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V295.Id.DiscordGuildOrDmId_DmData (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V295.RichText.RichText (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId) Evergreen.V295.Id.AnyGuildOrDmId Evergreen.V295.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V295.Id.AnyGuildOrDmId Evergreen.V295.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V295.Discord.Id Evergreen.V295.Discord.GuildId) (Evergreen.V295.Discord.Id Evergreen.V295.Discord.ChannelId) Evergreen.V295.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V295.Discord.Id Evergreen.V295.Discord.PrivateChannelId) (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId) Evergreen.V295.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId) Evergreen.V295.FileStatus.FileHash
    | Server_SetGuildIcon (Evergreen.V295.Id.Id Evergreen.V295.Id.GuildId) Evergreen.V295.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V295.Id.Id Evergreen.V295.Id.GuildId) Evergreen.V295.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V295.Discord.Id Evergreen.V295.Discord.GuildId) Evergreen.V295.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V295.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V295.SessionIdHash.SessionIdHash Evergreen.V295.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V295.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V295.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V295.Id.AnyGuildOrDmId, Evergreen.V295.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V295.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId) Evergreen.V295.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V295.Discord.Id Evergreen.V295.Discord.GuildId) (Evergreen.V295.Discord.Id Evergreen.V295.Discord.ChannelId) Evergreen.V295.ChannelName.ChannelName (Evergreen.V295.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V295.Discord.Id Evergreen.V295.Discord.PrivateChannelId)
        (Evergreen.V295.NonemptyDict.NonemptyDict
            (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V295.Discord.Id Evergreen.V295.Discord.GuildId) Evergreen.V295.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V295.Discord.Id Evergreen.V295.Discord.PrivateChannelId) Evergreen.V295.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId) Evergreen.V295.UserSession.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId) (Maybe (Evergreen.V295.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V295.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V295.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V295.Id.Id Evergreen.V295.Id.GuildId) (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelId) Evergreen.V295.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V295.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId) Evergreen.V295.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V295.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V295.Discord.Id Evergreen.V295.Discord.GuildId) (Evergreen.V295.Discord.Id Evergreen.V295.Discord.ChannelId) Evergreen.V295.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V295.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V295.Discord.Id Evergreen.V295.Discord.PrivateChannelId) (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V295.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V295.Discord.Id Evergreen.V295.Discord.GuildId) Evergreen.V295.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V295.Discord.Id Evergreen.V295.Discord.GuildId) (Evergreen.V295.Discord.Id Evergreen.V295.Discord.ChannelId) (Evergreen.V295.Discord.OptionalData String) (Evergreen.V295.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V295.Discord.Id Evergreen.V295.Discord.GuildId)
        (Evergreen.V295.MembersAndOwner.MembersAndOwner
            (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V295.Discord.Id Evergreen.V295.Discord.GuildId) (Evergreen.V295.Discord.Id Evergreen.V295.Discord.ChannelId) (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId) Evergreen.V295.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.Id.StickerId) Evergreen.V295.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.Id.CustomEmojiId) Evergreen.V295.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V295.Call.ServerChange
    | Server_Game
        (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId)
        { otherUserId : Evergreen.V295.Id.Id Evergreen.V295.Id.UserId
        }
        Evergreen.V295.Game.LocalChange
    | Server_Drawing (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId) Evergreen.V295.Id.AnyGuildOrDmId Evergreen.V295.Drawing.AnchorType Evergreen.V295.Drawing.LocalChange


type LocalMsg
    = LocalChange (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V295.Id.Id Evergreen.V295.Id.GuildId) (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelId) Evergreen.V295.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V295.Discord.Id Evergreen.V295.Discord.GuildId) (Evergreen.V295.Discord.Id Evergreen.V295.Discord.ChannelId) Evergreen.V295.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.FileStatus.FileId) Evergreen.V295.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V295.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V295.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V295.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V295.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V295.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V295.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V295.Coord.Coord Evergreen.V295.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V295.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V295.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V295.Id.AnyGuildOrDmId Evergreen.V295.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V295.Id.AnyGuildOrDmId Evergreen.V295.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V295.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V295.Coord.Coord Evergreen.V295.CssPixels.CssPixels) (Maybe Evergreen.V295.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V295.Id.AnyGuildOrDmId, Evergreen.V295.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelMessageId) (Evergreen.V295.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.Id.ThreadMessageId) (Evergreen.V295.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V295.Editable.Model
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
    | FileDragging Effect.Time.Posix Evergreen.V295.OneOrGreater.OneOrGreater


type alias LoggedIn2 =
    { localState : Evergreen.V295.Local.Local LocalMsg Evergreen.V295.LocalState.LocalState
    , admin : Evergreen.V295.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V295.Id.AnyGuildOrDmId, Evergreen.V295.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V295.Id.Id Evergreen.V295.Id.GuildId, Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V295.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V295.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V295.Id.AnyGuildOrDmId, Evergreen.V295.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V295.Id.AnyGuildOrDmId, Evergreen.V295.Id.ThreadRoute ) (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : Evergreen.V295.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V295.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V295.Id.AnyGuildOrDmId, Evergreen.V295.Id.ThreadRoute ) (Evergreen.V295.NonemptyDict.NonemptyDict (Evergreen.V295.Id.Id Evergreen.V295.FileStatus.FileId) Evergreen.V295.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V295.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V295.TextEditor.Model
    , profilePictureEditor : Evergreen.V295.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V295.Id.Id Evergreen.V295.Id.GuildId, Evergreen.V295.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V295.Emoji.Model
    , voiceChat : Evergreen.V295.Call.Model
    , currentDmGame : SeqDict.SeqDict ( Evergreen.V295.Id.Id Evergreen.V295.Id.UserId, Maybe (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelMessageId) ) Evergreen.V295.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V295.Drawing.Model
    , showInviteLinkQrCode : Maybe (Evergreen.V295.SecretId.SecretId Evergreen.V295.Id.InviteLinkId)
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V295.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V295.SecretId.SecretId Evergreen.V295.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V295.Range.Range
                , direction : Evergreen.V295.Range.SelectionDirection
                }
        }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_WordSpellingGameBoard


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V295.NonemptyDict.NonemptyDict Int Evergreen.V295.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V295.NonemptyDict.NonemptyDict Int Evergreen.V295.Touch.Touch
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
    | AdminToFrontend Evergreen.V295.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V295.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V295.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V295.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V295.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V295.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V295.Go.PublicGoMatchResponse)


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V295.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V295.Coord.Coord Evergreen.V295.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V295.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V295.MyUi.LastCopy
    , notificationPermission : Evergreen.V295.Ports.NotificationPermission
    , pwaStatus : Evergreen.V295.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V295.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V295.UserAgent.UserAgent
    , timeOrigin : Effect.Time.Posix
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V295.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V295.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V295.Id.Id Evergreen.V295.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V295.Id.Id Evergreen.V295.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V295.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V295.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V295.Coord.Coord Evergreen.V295.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V295.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V295.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V295.Id.Id Evergreen.V295.Id.GuildId, Evergreen.V295.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V295.DmChannel.DmChannelId, Evergreen.V295.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V295.Discord.Id Evergreen.V295.Discord.GuildId, Evergreen.V295.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V295.Discord.Id Evergreen.V295.Discord.PrivateChannelId, Evergreen.V295.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V295.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V295.NonemptyDict.NonemptyDict (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId) Evergreen.V295.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V295.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V295.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V295.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V295.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId) Evergreen.V295.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId) Evergreen.V295.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V295.Id.Id Evergreen.V295.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.Id.GuildId) Evergreen.V295.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.Id.GuildId) Evergreen.V295.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V295.Discord.Id Evergreen.V295.Discord.GuildId) Evergreen.V295.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V295.DmChannel.DmChannelId Evergreen.V295.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V295.Discord.Id Evergreen.V295.Discord.PrivateChannelId) Evergreen.V295.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V295.OneToOne.OneToOne (Evergreen.V295.Slack.Id Evergreen.V295.Slack.ChannelId) Evergreen.V295.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V295.OneToOne.OneToOne String (Evergreen.V295.Id.Id Evergreen.V295.Id.GuildId)
    , slackUsers : Evergreen.V295.OneToOne.OneToOne (Evergreen.V295.Slack.Id Evergreen.V295.Slack.UserId) (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId)
    , slackServers : Evergreen.V295.OneToOne.OneToOne (Evergreen.V295.Slack.Id Evergreen.V295.Slack.TeamId) (Evergreen.V295.Id.Id Evergreen.V295.Id.GuildId)
    , slackToken : Maybe Evergreen.V295.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V295.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V295.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V295.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V295.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V295.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V295.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V295.Cloudflare.AnalyticsApiToken
    , textEditor : Evergreen.V295.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId) Evergreen.V295.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId, Evergreen.V295.Discord.Id Evergreen.V295.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V295.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V295.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V295.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V295.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId) (Evergreen.V295.LocalState.LoadingDiscordChannel (List Evergreen.V295.Discord.Message))
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V295.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.Id.StickerId) Evergreen.V295.Sticker.StickerData
    , discordStickers : Evergreen.V295.OneToOne.OneToOne (Evergreen.V295.Discord.Id Evergreen.V295.Discord.StickerId) (Evergreen.V295.Id.Id Evergreen.V295.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.Id.CustomEmojiId) Evergreen.V295.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V295.OneToOne.OneToOne Evergreen.V295.RichText.DiscordCustomEmojiIdAndName (Evergreen.V295.Id.Id Evergreen.V295.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V295.Postmark.ApiKey
    , serverSecret : Evergreen.V295.SecretId.SecretId Evergreen.V295.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V295.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V295.OneToOne.OneToOne (Evergreen.V295.SecretId.SecretId Evergreen.V295.Id.GamePublicId) ( Evergreen.V295.DmChannel.DmChannelId, Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelMessageId )
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V295.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V295.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V295.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V295.Route.Route
    | SelectedFilesToAttach ( Evergreen.V295.Id.AnyGuildOrDmId, Evergreen.V295.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V295.Id.Id Evergreen.V295.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V295.Id.Id Evergreen.V295.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V295.Id.Id Evergreen.V295.Id.GuildId) (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelId) Evergreen.V295.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V295.Id.Id Evergreen.V295.Id.GuildId) (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelId) Evergreen.V295.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V295.Discord.Id Evergreen.V295.Discord.GuildId) (Evergreen.V295.Discord.Id Evergreen.V295.Discord.ChannelId) Evergreen.V295.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V295.Discord.Id Evergreen.V295.Discord.GuildId) (Evergreen.V295.Discord.Id Evergreen.V295.Discord.ChannelId) Evergreen.V295.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V295.Id.Id Evergreen.V295.Id.GuildId) (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V295.Id.Id Evergreen.V295.Id.GuildId) (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V295.Id.Id Evergreen.V295.Id.GuildId) (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V295.Id.Id Evergreen.V295.Id.GuildId) (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V295.Id.Id Evergreen.V295.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V295.Id.Id Evergreen.V295.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V295.Id.Id Evergreen.V295.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V295.Id.Id Evergreen.V295.Id.GuildId) (Evergreen.V295.SecretId.SecretId Evergreen.V295.Id.InviteLinkId)
    | PressedToggleInviteLinkQrCode (Evergreen.V295.SecretId.SecretId Evergreen.V295.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V295.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V295.Id.AnyGuildOrDmId Evergreen.V295.Id.ThreadRouteWithMessage (Evergreen.V295.Coord.Coord Evergreen.V295.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V295.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V295.Id.AnyGuildOrDmId Evergreen.V295.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V295.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V295.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V295.Id.AnyGuildOrDmId, Evergreen.V295.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V295.Ports.NotificationPermission
    | TouchStart (Maybe ( Evergreen.V295.Id.AnyGuildOrDmId, Evergreen.V295.Id.ThreadRouteWithMessage, Bool )) Duration.Duration (Evergreen.V295.NonemptyDict.NonemptyDict Int Evergreen.V295.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V295.NonemptyDict.NonemptyDict Int Evergreen.V295.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V295.Id.AnyGuildOrDmId Evergreen.V295.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V295.Id.AnyGuildOrDmId Evergreen.V295.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V295.NonemptySet.NonemptySet (Evergreen.V295.Id.Id Evergreen.V295.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V295.Id.AnyGuildOrDmId, Evergreen.V295.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V295.Id.AnyGuildOrDmId Evergreen.V295.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V295.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V295.AiChat.Msg
    | GameMsg Evergreen.V295.Game.Msg
    | GoSpectatorMsg Evergreen.V295.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V295.Editable.Msg Evergreen.V295.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V295.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V295.Id.Id Evergreen.V295.Id.GuildId) Evergreen.V295.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V295.Id.AnyGuildOrDmId, Evergreen.V295.Id.ThreadRoute ) (Evergreen.V295.Id.Id Evergreen.V295.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V295.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V295.Id.AnyGuildOrDmId, Evergreen.V295.Id.ThreadRoute ) (Evergreen.V295.Id.Id Evergreen.V295.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V295.Id.AnyGuildOrDmId, Evergreen.V295.Id.ThreadRoute ) (Evergreen.V295.Id.Id Evergreen.V295.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V295.Id.AnyGuildOrDmId, Evergreen.V295.Id.ThreadRoute )
        { fileId : Evergreen.V295.Id.Id Evergreen.V295.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V295.Id.AnyGuildOrDmId, Evergreen.V295.Id.ThreadRoute ) (Evergreen.V295.Id.Id Evergreen.V295.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V295.Id.AnyGuildOrDmId, Evergreen.V295.Id.ThreadRoute ) (Evergreen.V295.Id.Id Evergreen.V295.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V295.Id.AnyGuildOrDmId, Evergreen.V295.Id.ThreadRoute )
        { fileId : Evergreen.V295.Id.Id Evergreen.V295.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V295.Id.AnyGuildOrDmId, Evergreen.V295.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V295.Id.AnyGuildOrDmId, Evergreen.V295.Id.ThreadRoute ) (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelMessageId) (Evergreen.V295.Id.Id Evergreen.V295.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V295.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V295.Id.AnyGuildOrDmId, Evergreen.V295.Id.ThreadRoute ) (Evergreen.V295.Id.Id Evergreen.V295.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V295.Id.AnyGuildOrDmId Evergreen.V295.Id.ThreadRouteWithMessage Evergreen.V295.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V295.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V295.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V295.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V295.Id.Id Evergreen.V295.Id.GuildId) Evergreen.V295.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId) (Evergreen.V295.Discord.Id Evergreen.V295.Discord.GuildId) Evergreen.V295.User.NotificationLevel
    | GotStartupData Evergreen.V295.Ports.StartupData
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V295.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId
        , otherUserId : Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V295.Id.AnyGuildOrDmId Evergreen.V295.Id.ThreadRoute Evergreen.V295.MessageInput.Msg
    | MessageInputMsg Evergreen.V295.Id.AnyGuildOrDmId Evergreen.V295.Id.ThreadRoute Evergreen.V295.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V295.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V295.Range.Range, Evergreen.V295.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V295.Range.Range, Evergreen.V295.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V295.Call.FromJs)
    | VoiceChatMsg Evergreen.V295.Call.Msg
    | PressedChannelHeaderTab Evergreen.V295.Route.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadServiceWorkerData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V295.Drawing.Msg


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V295.Id.Id Evergreen.V295.Id.GuildId) (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelId) Evergreen.V295.Id.ThreadRoute
    | InitialLoadRequested_Dm Evergreen.V295.DmChannel.DmChannelId Evergreen.V295.Id.ThreadRoute
    | InitialLoadRequested_Discord Evergreen.V295.Id.DiscordGuildOrDmId Evergreen.V295.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V295.Id.Id Evergreen.V295.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V295.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V295.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V295.Untrusted.Untrusted Evergreen.V295.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V295.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V295.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V295.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V295.Id.Id Evergreen.V295.Id.GuildId) (Evergreen.V295.SecretId.SecretId Evergreen.V295.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V295.PersonName.PersonName Evergreen.V295.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V295.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V295.Slack.OAuthCode Evergreen.V295.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V295.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V295.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V295.Id.Id Evergreen.V295.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V295.SecretId.SecretId Evergreen.V295.Id.GamePublicId)


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V295.Discord.Id Evergreen.V295.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V295.Discord.Id Evergreen.V295.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V295.EmailAddress.EmailAddress (Result Evergreen.V295.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V295.EmailAddress.EmailAddress (Result Evergreen.V295.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V295.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V295.Discord.Id Evergreen.V295.Discord.GuildId) (Evergreen.V295.Discord.Id Evergreen.V295.Discord.ChannelId) Evergreen.V295.Id.ThreadRouteWithMaybeMessage (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId) (Result Evergreen.V295.Discord.HttpError Evergreen.V295.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V295.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V295.Discord.Id Evergreen.V295.Discord.PrivateChannelId) (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId) (Result Evergreen.V295.Discord.HttpError Evergreen.V295.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V295.Discord.Id Evergreen.V295.Discord.GuildId) (Evergreen.V295.Discord.Id Evergreen.V295.Discord.ChannelId) Evergreen.V295.Id.ThreadRouteWithMessage (Evergreen.V295.Discord.Id Evergreen.V295.Discord.MessageId) (Result Evergreen.V295.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V295.Discord.Id Evergreen.V295.Discord.PrivateChannelId) (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelMessageId) (Evergreen.V295.Discord.Id Evergreen.V295.Discord.MessageId) (Result Evergreen.V295.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V295.Discord.Id Evergreen.V295.Discord.GuildId) (Evergreen.V295.Discord.Id Evergreen.V295.Discord.ChannelId) Evergreen.V295.Id.ThreadRouteWithMessage (Evergreen.V295.Discord.Id Evergreen.V295.Discord.MessageId) (Result Evergreen.V295.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V295.Discord.Id Evergreen.V295.Discord.PrivateChannelId) (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelMessageId) (Evergreen.V295.Discord.Id Evergreen.V295.Discord.MessageId) (Result Evergreen.V295.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V295.Discord.Id Evergreen.V295.Discord.GuildId) (Evergreen.V295.Discord.Id Evergreen.V295.Discord.ChannelId) Evergreen.V295.Id.ThreadRouteWithMessage (Evergreen.V295.Discord.Id Evergreen.V295.Discord.MessageId) Evergreen.V295.Emoji.EmojiOrCustomEmoji (Result Evergreen.V295.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V295.Discord.Id Evergreen.V295.Discord.PrivateChannelId) (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelMessageId) (Evergreen.V295.Discord.Id Evergreen.V295.Discord.MessageId) Evergreen.V295.Emoji.EmojiOrCustomEmoji (Result Evergreen.V295.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V295.Discord.Id Evergreen.V295.Discord.GuildId) (Evergreen.V295.Discord.Id Evergreen.V295.Discord.ChannelId) Evergreen.V295.Id.ThreadRouteWithMessage (Evergreen.V295.Discord.Id Evergreen.V295.Discord.MessageId) Evergreen.V295.Emoji.EmojiOrCustomEmoji (Result Evergreen.V295.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V295.Discord.Id Evergreen.V295.Discord.PrivateChannelId) (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelMessageId) (Evergreen.V295.Discord.Id Evergreen.V295.Discord.MessageId) Evergreen.V295.Emoji.EmojiOrCustomEmoji (Result Evergreen.V295.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V295.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V295.Discord.HttpError (List ( Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId, Maybe Evergreen.V295.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId) Effect.Time.Posix Evergreen.V295.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V295.Slack.CurrentUser
            , team : Evergreen.V295.Slack.Team
            , users : List Evergreen.V295.Slack.User
            , channels : List ( Evergreen.V295.Slack.Channel, List Evergreen.V295.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId) (Result Effect.Http.Error Evergreen.V295.Slack.TokenResponse)
    | GotCloudflareSessionCreated Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V295.Local.ChangeId Effect.Time.Posix Evergreen.V295.Call.CallId Evergreen.V295.Cloudflare.Sdp (List String) (Result Effect.Http.Error Evergreen.V295.Cloudflare.RealtimeSessionId)
    | GotCloudflareSession Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V295.Local.ChangeId Effect.Time.Posix Evergreen.V295.Call.CallId Evergreen.V295.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V295.Cloudflare.PushTracksResult)
    | GotCloudflarePullOffer Effect.Time.Posix Effect.Lamdera.ClientId Evergreen.V295.Local.ChangeId Evergreen.V295.Call.ConnectionId Evergreen.V295.Cloudflare.RealtimeSessionId (List Evergreen.V295.Cloudflare.TrackName) (Result Effect.Http.Error Evergreen.V295.Cloudflare.PullTracksResult)
    | GotCloudflareRenegotiateAck Effect.Lamdera.ClientId Evergreen.V295.Local.ChangeId Evergreen.V295.Cloudflare.Sdp (Result Effect.Http.Error ())
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId) Evergreen.V295.Discord.UserAuth (Result Evergreen.V295.Discord.HttpError Evergreen.V295.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId) (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId) (Result Evergreen.V295.Discord.HttpError Evergreen.V295.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId)
        (Result
            Evergreen.V295.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V295.Discord.Id Evergreen.V295.Discord.PrivateChannelId
                , members : List (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId)
                }
            , List
                ( Evergreen.V295.Discord.Id Evergreen.V295.Discord.GuildId
                , { guild : Evergreen.V295.Discord.GatewayGuild
                  , channels : List Evergreen.V295.Discord.Channel
                  , icon : Maybe Evergreen.V295.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId) Bool Evergreen.V295.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V295.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V295.Discord.Id Evergreen.V295.Discord.AttachmentId, Evergreen.V295.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V295.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V295.Discord.Id Evergreen.V295.Discord.AttachmentId, Evergreen.V295.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId) (Evergreen.V295.Discord.Id Evergreen.V295.Discord.GuildId) (Evergreen.V295.Discord.Id Evergreen.V295.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V295.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V295.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId) (Evergreen.V295.Discord.Id Evergreen.V295.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V295.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V295.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId) (Evergreen.V295.Discord.Id Evergreen.V295.Discord.GuildId) (Evergreen.V295.Discord.Id Evergreen.V295.Discord.ChannelId) (Result Evergreen.V295.Discord.HttpError (List Evergreen.V295.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId) (Evergreen.V295.Discord.Id Evergreen.V295.Discord.PrivateChannelId) (Result Evergreen.V295.Discord.HttpError (List Evergreen.V295.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V295.Id.Id Evergreen.V295.Id.GuildId) (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelId) Evergreen.V295.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V295.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V295.DmChannel.DmChannelId Evergreen.V295.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V295.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V295.Discord.Id Evergreen.V295.Discord.GuildId) (Evergreen.V295.Discord.Id Evergreen.V295.Discord.ChannelId) Evergreen.V295.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V295.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V295.Discord.Id Evergreen.V295.Discord.PrivateChannelId) (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V295.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId)
        (Evergreen.V295.Discord.Id Evergreen.V295.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V295.Discord.HttpError
            { guild : Evergreen.V295.Discord.GatewayGuild
            , channels : List Evergreen.V295.Discord.Channel
            , icon : Maybe Evergreen.V295.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V295.Discord.Id Evergreen.V295.Discord.GuildId) (Result Evergreen.V295.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V295.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId) (List ( Evergreen.V295.Id.Id Evergreen.V295.Id.StickerId, Result Effect.Http.Error Evergreen.V295.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V295.Id.Id Evergreen.V295.Id.StickerId, Result Effect.Http.Error Evergreen.V295.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId) (List ( Evergreen.V295.Id.Id Evergreen.V295.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V295.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V295.Id.Id Evergreen.V295.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V295.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V295.Discord.HttpError (List Evergreen.V295.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V295.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V295.SecretId.SecretId Evergreen.V295.SecretId.ServerSecret))
    | GotTimeForWebsocketListenClose (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | GotCloudflareUsage Effect.Time.Posix (Result Effect.Http.Error Int)
    | GotCloudflareEgressForAdmin Effect.Lamdera.ClientId (Result Effect.Http.Error Int)
    | GotRustServerFileUpload Evergreen.V295.FileStatus.FileHash Int (Maybe (Evergreen.V295.Coord.Coord Evergreen.V295.CssPixels.CssPixels))
