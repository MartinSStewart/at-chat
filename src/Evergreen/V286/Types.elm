module Evergreen.V286.Types exposing (..)

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
import Evergreen.V286.AiChat
import Evergreen.V286.Call
import Evergreen.V286.ChannelDescription
import Evergreen.V286.ChannelName
import Evergreen.V286.Cloudflare
import Evergreen.V286.Coord
import Evergreen.V286.CssPixels
import Evergreen.V286.CustomEmoji
import Evergreen.V286.Discord
import Evergreen.V286.DiscordAttachmentId
import Evergreen.V286.DiscordUserData
import Evergreen.V286.DmChannel
import Evergreen.V286.Drawing
import Evergreen.V286.Editable
import Evergreen.V286.EmailAddress
import Evergreen.V286.Embed
import Evergreen.V286.Emoji
import Evergreen.V286.FileStatus
import Evergreen.V286.Go
import Evergreen.V286.GuildName
import Evergreen.V286.Id
import Evergreen.V286.ImageEditor
import Evergreen.V286.ImageViewer
import Evergreen.V286.Local
import Evergreen.V286.LocalState
import Evergreen.V286.Log
import Evergreen.V286.LoginForm
import Evergreen.V286.MembersAndOwner
import Evergreen.V286.Message
import Evergreen.V286.MessageInput
import Evergreen.V286.MessageView
import Evergreen.V286.MyUi
import Evergreen.V286.NonemptyDict
import Evergreen.V286.NonemptySet
import Evergreen.V286.OneOrGreater
import Evergreen.V286.OneToOne
import Evergreen.V286.Pages.Admin
import Evergreen.V286.Pagination
import Evergreen.V286.PersonName
import Evergreen.V286.Ports
import Evergreen.V286.Postmark
import Evergreen.V286.Range
import Evergreen.V286.RichText
import Evergreen.V286.Route
import Evergreen.V286.SecretId
import Evergreen.V286.SessionIdHash
import Evergreen.V286.Slack
import Evergreen.V286.Sticker
import Evergreen.V286.TextEditor
import Evergreen.V286.ToBackendLog
import Evergreen.V286.Touch
import Evergreen.V286.TwoFactorAuthentication
import Evergreen.V286.Ui.Anim
import Evergreen.V286.Untrusted
import Evergreen.V286.User
import Evergreen.V286.UserAgent
import Evergreen.V286.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V286.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V286.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.Id.GuildId) Evergreen.V286.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId) Evergreen.V286.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V286.Discord.Id Evergreen.V286.Discord.PrivateChannelId) Evergreen.V286.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V286.Discord.Id Evergreen.V286.Discord.GuildId) Evergreen.V286.LocalState.DiscordFrontendGuild
    , user : Evergreen.V286.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId) Evergreen.V286.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId) Evergreen.V286.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId) Evergreen.V286.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V286.SessionIdHash.SessionIdHash Evergreen.V286.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V286.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.Id.StickerId) Evergreen.V286.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.Id.CustomEmojiId) Evergreen.V286.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V286.Call.CallId (Evergreen.V286.NonemptyDict.NonemptyDict ( Evergreen.V286.Id.Id Evergreen.V286.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V286.Call.RemoteCallData)
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type PublicGoMatch
    = PublicGoMatch_NotLoaded
    | PublicGoMatch_Loading
    | PublicGoMatch_Loaded Evergreen.V286.Go.PublicGoMatchData Evergreen.V286.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V286.Route.Route
    , windowSize : Evergreen.V286.Coord.Coord Evergreen.V286.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , timezone : Effect.Time.Zone
    , startupData : Maybe Evergreen.V286.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V286.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V286.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V286.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.FileStatus.FileId) Evergreen.V286.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V286.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V286.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.FileStatus.FileId) Evergreen.V286.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V286.Id.Id Evergreen.V286.Id.GuildId) Evergreen.V286.ChannelName.ChannelName Evergreen.V286.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V286.Id.Id Evergreen.V286.Id.GuildId) (Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelId) Evergreen.V286.ChannelName.ChannelName Evergreen.V286.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V286.Id.Id Evergreen.V286.Id.GuildId) (Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelId)
    | Local_DeleteGuild (Evergreen.V286.Id.Id Evergreen.V286.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V286.Id.Id Evergreen.V286.Id.GuildId) (Evergreen.V286.UserSession.ToBeFilledInByBackend (Evergreen.V286.SecretId.SecretId Evergreen.V286.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V286.Id.Id Evergreen.V286.Id.GuildId) (Evergreen.V286.SecretId.SecretId Evergreen.V286.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V286.GuildName.GuildName (Evergreen.V286.UserSession.ToBeFilledInByBackend (Evergreen.V286.Id.Id Evergreen.V286.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V286.Id.AnyGuildOrDmId, Evergreen.V286.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V286.Id.AnyGuildOrDmId Evergreen.V286.Id.ThreadRouteWithMessage Evergreen.V286.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V286.Id.AnyGuildOrDmId Evergreen.V286.Id.ThreadRouteWithMessage Evergreen.V286.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V286.Id.GuildOrDmId Evergreen.V286.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.FileStatus.FileId) Evergreen.V286.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId) (Evergreen.V286.Discord.Id Evergreen.V286.Discord.GuildId) (Evergreen.V286.Discord.Id Evergreen.V286.Discord.ChannelId) Evergreen.V286.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V286.Id.DiscordGuildOrDmId_DmData (Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V286.Id.AnyGuildOrDmId Evergreen.V286.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V286.Id.AnyGuildOrDmId Evergreen.V286.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V286.Id.AnyGuildOrDmId Evergreen.V286.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V286.UserSession.SetViewing
    | Local_SetName Evergreen.V286.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V286.Id.GuildOrDmId (Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelMessageId) (Evergreen.V286.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelMessageId) (Evergreen.V286.Message.Message Evergreen.V286.Id.ChannelMessageId (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V286.Id.GuildOrDmId (Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelMessageId) (Evergreen.V286.Id.Id Evergreen.V286.Id.ThreadMessageId) (Evergreen.V286.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.Id.ThreadMessageId) (Evergreen.V286.Message.Message Evergreen.V286.Id.ThreadMessageId (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V286.Id.DiscordGuildOrDmId (Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelMessageId) (Evergreen.V286.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelMessageId) (Evergreen.V286.Message.Message Evergreen.V286.Id.ChannelMessageId (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V286.Id.DiscordGuildOrDmId (Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelMessageId) (Evergreen.V286.Id.Id Evergreen.V286.Id.ThreadMessageId) (Evergreen.V286.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.Id.ThreadMessageId) (Evergreen.V286.Message.Message Evergreen.V286.Id.ThreadMessageId (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V286.Id.Id Evergreen.V286.Id.GuildId) Evergreen.V286.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId) (Evergreen.V286.Discord.Id Evergreen.V286.Discord.GuildId) Evergreen.V286.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V286.UserSession.NotificationMode
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V286.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V286.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V286.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V286.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V286.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V286.NonemptySet.NonemptySet (Evergreen.V286.Id.Id Evergreen.V286.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V286.Call.LocalChange
    | Local_Go
        { otherUserId : Evergreen.V286.Id.Id Evergreen.V286.Id.UserId
        }
        Evergreen.V286.Go.LocalChange
    | Local_Drawing Evergreen.V286.Id.AnyGuildOrDmId Evergreen.V286.Drawing.AnchorType Evergreen.V286.Drawing.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId) Effect.Time.Posix Evergreen.V286.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V286.RichText.RichText (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId))) Evergreen.V286.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.FileStatus.FileId) Evergreen.V286.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.Id.StickerId) Evergreen.V286.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V286.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V286.RichText.RichText (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId))) Evergreen.V286.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.FileStatus.FileId) Evergreen.V286.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.Id.StickerId) Evergreen.V286.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V286.Id.Id Evergreen.V286.Id.GuildId) Evergreen.V286.ChannelName.ChannelName Evergreen.V286.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V286.Id.Id Evergreen.V286.Id.GuildId) (Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelId) Evergreen.V286.ChannelName.ChannelName Evergreen.V286.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V286.Id.Id Evergreen.V286.Id.GuildId) (Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelId)
    | Server_DeleteGuild (Evergreen.V286.Id.Id Evergreen.V286.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId) (Evergreen.V286.Id.Id Evergreen.V286.Id.GuildId) (Evergreen.V286.SecretId.SecretId Evergreen.V286.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V286.Id.Id Evergreen.V286.Id.GuildId) (Evergreen.V286.SecretId.SecretId Evergreen.V286.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId) (Evergreen.V286.Id.Id Evergreen.V286.Id.GuildId) Evergreen.V286.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V286.LocalState.JoinGuildError
            { guildId : Evergreen.V286.Id.Id Evergreen.V286.Id.GuildId
            , guild : Evergreen.V286.LocalState.FrontendGuild
            , owner : Evergreen.V286.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId) Evergreen.V286.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId) Evergreen.V286.Id.GuildOrDmId Evergreen.V286.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId) (Evergreen.V286.Discord.Id Evergreen.V286.Discord.GuildId) (Evergreen.V286.Discord.Id Evergreen.V286.Discord.ChannelId) Evergreen.V286.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId) (Evergreen.V286.Discord.Id Evergreen.V286.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId) Evergreen.V286.Id.GuildOrDmId Evergreen.V286.Id.ThreadRouteWithMessage Evergreen.V286.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId) Evergreen.V286.Id.GuildOrDmId Evergreen.V286.Id.ThreadRouteWithMessage Evergreen.V286.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId) (Evergreen.V286.Discord.Id Evergreen.V286.Discord.GuildId) (Evergreen.V286.Discord.Id Evergreen.V286.Discord.ChannelId) Evergreen.V286.Id.ThreadRouteWithMessage Evergreen.V286.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId) (Evergreen.V286.Discord.Id Evergreen.V286.Discord.PrivateChannelId) (Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelMessageId) Evergreen.V286.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId) (Evergreen.V286.Discord.Id Evergreen.V286.Discord.GuildId) (Evergreen.V286.Discord.Id Evergreen.V286.Discord.ChannelId) Evergreen.V286.Id.ThreadRouteWithMessage Evergreen.V286.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId) (Evergreen.V286.Discord.Id Evergreen.V286.Discord.PrivateChannelId) (Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelMessageId) Evergreen.V286.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId) Evergreen.V286.Id.GuildOrDmId Evergreen.V286.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V286.RichText.RichText (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId))) (SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.FileStatus.FileId) Evergreen.V286.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId) (Evergreen.V286.Discord.Id Evergreen.V286.Discord.GuildId) (Evergreen.V286.Discord.Id Evergreen.V286.Discord.ChannelId) Evergreen.V286.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V286.RichText.RichText (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V286.Id.DiscordGuildOrDmId_DmData (Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V286.RichText.RichText (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId) Evergreen.V286.Id.AnyGuildOrDmId Evergreen.V286.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V286.Id.AnyGuildOrDmId Evergreen.V286.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V286.Discord.Id Evergreen.V286.Discord.GuildId) (Evergreen.V286.Discord.Id Evergreen.V286.Discord.ChannelId) Evergreen.V286.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V286.Discord.Id Evergreen.V286.Discord.PrivateChannelId) (Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId) Evergreen.V286.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId) Evergreen.V286.FileStatus.FileHash
    | Server_SetGuildIcon (Evergreen.V286.Id.Id Evergreen.V286.Id.GuildId) Evergreen.V286.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V286.Id.Id Evergreen.V286.Id.GuildId) Evergreen.V286.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V286.Discord.Id Evergreen.V286.Discord.GuildId) Evergreen.V286.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V286.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V286.SessionIdHash.SessionIdHash Evergreen.V286.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V286.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V286.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V286.Id.AnyGuildOrDmId, Evergreen.V286.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V286.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId) Evergreen.V286.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V286.Discord.Id Evergreen.V286.Discord.GuildId) (Evergreen.V286.Discord.Id Evergreen.V286.Discord.ChannelId) Evergreen.V286.ChannelName.ChannelName (Evergreen.V286.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V286.Discord.Id Evergreen.V286.Discord.PrivateChannelId)
        (Evergreen.V286.NonemptyDict.NonemptyDict
            (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V286.Discord.Id Evergreen.V286.Discord.GuildId) Evergreen.V286.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V286.Discord.Id Evergreen.V286.Discord.PrivateChannelId) Evergreen.V286.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId) Evergreen.V286.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId) (Maybe (Evergreen.V286.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V286.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V286.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V286.Id.Id Evergreen.V286.Id.GuildId) (Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelId) Evergreen.V286.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V286.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId) Evergreen.V286.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V286.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V286.Discord.Id Evergreen.V286.Discord.GuildId) (Evergreen.V286.Discord.Id Evergreen.V286.Discord.ChannelId) Evergreen.V286.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V286.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V286.Discord.Id Evergreen.V286.Discord.PrivateChannelId) (Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V286.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V286.Discord.Id Evergreen.V286.Discord.GuildId) Evergreen.V286.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V286.Discord.Id Evergreen.V286.Discord.GuildId) (Evergreen.V286.Discord.Id Evergreen.V286.Discord.ChannelId) (Evergreen.V286.Discord.OptionalData String) (Evergreen.V286.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V286.Discord.Id Evergreen.V286.Discord.GuildId)
        (Evergreen.V286.MembersAndOwner.MembersAndOwner
            (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V286.Discord.Id Evergreen.V286.Discord.GuildId) (Evergreen.V286.Discord.Id Evergreen.V286.Discord.ChannelId) (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId) Evergreen.V286.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.Id.StickerId) Evergreen.V286.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.Id.CustomEmojiId) Evergreen.V286.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V286.Call.ServerChange
    | Server_Go
        (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId)
        { otherUserId : Evergreen.V286.Id.Id Evergreen.V286.Id.UserId
        }
        Evergreen.V286.Go.LocalChange
    | Server_Drawing (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId) Evergreen.V286.Id.AnyGuildOrDmId Evergreen.V286.Drawing.AnchorType Evergreen.V286.Drawing.LocalChange


type LocalMsg
    = LocalChange (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V286.Id.Id Evergreen.V286.Id.GuildId) (Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelId) Evergreen.V286.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V286.Discord.Id Evergreen.V286.Discord.GuildId) (Evergreen.V286.Discord.Id Evergreen.V286.Discord.ChannelId) Evergreen.V286.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.FileStatus.FileId) Evergreen.V286.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V286.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V286.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V286.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V286.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V286.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V286.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V286.Coord.Coord Evergreen.V286.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V286.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V286.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V286.Id.AnyGuildOrDmId Evergreen.V286.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V286.Id.AnyGuildOrDmId Evergreen.V286.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V286.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V286.Coord.Coord Evergreen.V286.CssPixels.CssPixels) (Maybe Evergreen.V286.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V286.Id.AnyGuildOrDmId, Evergreen.V286.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelMessageId) (Evergreen.V286.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.Id.ThreadMessageId) (Evergreen.V286.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V286.Editable.Model
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
    | FileDragging Effect.Time.Posix Evergreen.V286.OneOrGreater.OneOrGreater


type alias LoggedIn2 =
    { localState : Evergreen.V286.Local.Local LocalMsg Evergreen.V286.LocalState.LocalState
    , admin : Evergreen.V286.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V286.Id.AnyGuildOrDmId, Evergreen.V286.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V286.Id.Id Evergreen.V286.Id.GuildId, Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V286.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V286.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V286.Id.AnyGuildOrDmId, Evergreen.V286.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V286.Id.AnyGuildOrDmId, Evergreen.V286.Id.ThreadRoute ) (Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : Evergreen.V286.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V286.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V286.Id.AnyGuildOrDmId, Evergreen.V286.Id.ThreadRoute ) (Evergreen.V286.NonemptyDict.NonemptyDict (Evergreen.V286.Id.Id Evergreen.V286.FileStatus.FileId) Evergreen.V286.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V286.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V286.TextEditor.Model
    , profilePictureEditor : Evergreen.V286.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V286.Id.Id Evergreen.V286.Id.GuildId, Evergreen.V286.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V286.Emoji.Model
    , voiceChat : Evergreen.V286.Call.Model
    , currentDmGoMatch : SeqDict.SeqDict ( Evergreen.V286.Id.Id Evergreen.V286.Id.UserId, Maybe (Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelMessageId) ) Evergreen.V286.Go.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V286.Drawing.Model
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V286.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V286.SecretId.SecretId Evergreen.V286.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V286.Range.Range
                , direction : Evergreen.V286.Range.SelectionDirection
                }
        }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V286.NonemptyDict.NonemptyDict Int Evergreen.V286.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V286.NonemptyDict.NonemptyDict Int Evergreen.V286.Touch.Touch
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
    | AdminToFrontend Evergreen.V286.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V286.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V286.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V286.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V286.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V286.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V286.Go.PublicGoMatchResponse)


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V286.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V286.Coord.Coord Evergreen.V286.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V286.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V286.MyUi.LastCopy
    , notificationPermission : Evergreen.V286.Ports.NotificationPermission
    , pwaStatus : Evergreen.V286.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V286.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V286.UserAgent.UserAgent
    , timeOrigin : Effect.Time.Posix
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V286.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V286.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V286.Id.Id Evergreen.V286.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V286.Id.Id Evergreen.V286.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V286.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V286.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V286.Coord.Coord Evergreen.V286.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V286.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V286.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V286.Id.Id Evergreen.V286.Id.GuildId, Evergreen.V286.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V286.DmChannel.DmChannelId, Evergreen.V286.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V286.Discord.Id Evergreen.V286.Discord.GuildId, Evergreen.V286.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V286.Discord.Id Evergreen.V286.Discord.PrivateChannelId, Evergreen.V286.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V286.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V286.NonemptyDict.NonemptyDict (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId) Evergreen.V286.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V286.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V286.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V286.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V286.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId) Evergreen.V286.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId) Evergreen.V286.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V286.Id.Id Evergreen.V286.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.Id.GuildId) Evergreen.V286.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.Id.GuildId) Evergreen.V286.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V286.Discord.Id Evergreen.V286.Discord.GuildId) Evergreen.V286.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V286.DmChannel.DmChannelId Evergreen.V286.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V286.Discord.Id Evergreen.V286.Discord.PrivateChannelId) Evergreen.V286.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V286.OneToOne.OneToOne (Evergreen.V286.Slack.Id Evergreen.V286.Slack.ChannelId) Evergreen.V286.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V286.OneToOne.OneToOne String (Evergreen.V286.Id.Id Evergreen.V286.Id.GuildId)
    , slackUsers : Evergreen.V286.OneToOne.OneToOne (Evergreen.V286.Slack.Id Evergreen.V286.Slack.UserId) (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId)
    , slackServers : Evergreen.V286.OneToOne.OneToOne (Evergreen.V286.Slack.Id Evergreen.V286.Slack.TeamId) (Evergreen.V286.Id.Id Evergreen.V286.Id.GuildId)
    , slackToken : Maybe Evergreen.V286.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V286.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V286.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V286.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V286.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V286.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V286.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V286.Cloudflare.AnalyticsApiToken
    , textEditor : Evergreen.V286.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId) Evergreen.V286.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId, Evergreen.V286.Discord.Id Evergreen.V286.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V286.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V286.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V286.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V286.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId) (Evergreen.V286.LocalState.LoadingDiscordChannel (List Evergreen.V286.Discord.Message))
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V286.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.Id.StickerId) Evergreen.V286.Sticker.StickerData
    , discordStickers : Evergreen.V286.OneToOne.OneToOne (Evergreen.V286.Discord.Id Evergreen.V286.Discord.StickerId) (Evergreen.V286.Id.Id Evergreen.V286.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.Id.CustomEmojiId) Evergreen.V286.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V286.OneToOne.OneToOne Evergreen.V286.RichText.DiscordCustomEmojiIdAndName (Evergreen.V286.Id.Id Evergreen.V286.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V286.Postmark.ApiKey
    , serverSecret : Evergreen.V286.SecretId.SecretId Evergreen.V286.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V286.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V286.OneToOne.OneToOne (Evergreen.V286.SecretId.SecretId Evergreen.V286.Id.GoMatchPublicId) ( Evergreen.V286.DmChannel.DmChannelId, Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelMessageId )
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V286.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V286.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V286.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V286.Route.Route
    | SelectedFilesToAttach ( Evergreen.V286.Id.AnyGuildOrDmId, Evergreen.V286.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V286.Id.Id Evergreen.V286.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V286.Id.Id Evergreen.V286.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V286.Id.Id Evergreen.V286.Id.GuildId) (Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelId) Evergreen.V286.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V286.Id.Id Evergreen.V286.Id.GuildId) (Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelId) Evergreen.V286.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V286.Discord.Id Evergreen.V286.Discord.GuildId) (Evergreen.V286.Discord.Id Evergreen.V286.Discord.ChannelId) Evergreen.V286.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V286.Discord.Id Evergreen.V286.Discord.GuildId) (Evergreen.V286.Discord.Id Evergreen.V286.Discord.ChannelId) Evergreen.V286.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V286.Id.Id Evergreen.V286.Id.GuildId) (Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V286.Id.Id Evergreen.V286.Id.GuildId) (Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V286.Id.Id Evergreen.V286.Id.GuildId) (Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V286.Id.Id Evergreen.V286.Id.GuildId) (Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V286.Id.Id Evergreen.V286.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V286.Id.Id Evergreen.V286.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V286.Id.Id Evergreen.V286.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V286.Id.Id Evergreen.V286.Id.GuildId) (Evergreen.V286.SecretId.SecretId Evergreen.V286.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V286.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V286.Id.AnyGuildOrDmId Evergreen.V286.Id.ThreadRouteWithMessage (Evergreen.V286.Coord.Coord Evergreen.V286.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V286.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V286.Id.AnyGuildOrDmId Evergreen.V286.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V286.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V286.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V286.Id.AnyGuildOrDmId, Evergreen.V286.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V286.Ports.NotificationPermission
    | TouchStart (Maybe ( Evergreen.V286.Id.AnyGuildOrDmId, Evergreen.V286.Id.ThreadRouteWithMessage, Bool )) Duration.Duration (Evergreen.V286.NonemptyDict.NonemptyDict Int Evergreen.V286.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V286.NonemptyDict.NonemptyDict Int Evergreen.V286.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V286.Id.AnyGuildOrDmId Evergreen.V286.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V286.Id.AnyGuildOrDmId Evergreen.V286.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V286.NonemptySet.NonemptySet (Evergreen.V286.Id.Id Evergreen.V286.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V286.Id.AnyGuildOrDmId, Evergreen.V286.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V286.Id.AnyGuildOrDmId Evergreen.V286.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V286.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V286.AiChat.Msg
    | GoMsg Evergreen.V286.Go.Msg
    | GoSpectatorMsg Evergreen.V286.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V286.Editable.Msg Evergreen.V286.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V286.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V286.Id.Id Evergreen.V286.Id.GuildId) Evergreen.V286.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V286.Id.AnyGuildOrDmId, Evergreen.V286.Id.ThreadRoute ) (Evergreen.V286.Id.Id Evergreen.V286.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V286.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V286.Id.AnyGuildOrDmId, Evergreen.V286.Id.ThreadRoute ) (Evergreen.V286.Id.Id Evergreen.V286.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V286.Id.AnyGuildOrDmId, Evergreen.V286.Id.ThreadRoute ) (Evergreen.V286.Id.Id Evergreen.V286.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V286.Id.AnyGuildOrDmId, Evergreen.V286.Id.ThreadRoute )
        { fileId : Evergreen.V286.Id.Id Evergreen.V286.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V286.Id.AnyGuildOrDmId, Evergreen.V286.Id.ThreadRoute ) (Evergreen.V286.Id.Id Evergreen.V286.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V286.Id.AnyGuildOrDmId, Evergreen.V286.Id.ThreadRoute ) (Evergreen.V286.Id.Id Evergreen.V286.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V286.Id.AnyGuildOrDmId, Evergreen.V286.Id.ThreadRoute )
        { fileId : Evergreen.V286.Id.Id Evergreen.V286.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V286.Id.AnyGuildOrDmId, Evergreen.V286.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V286.Id.AnyGuildOrDmId, Evergreen.V286.Id.ThreadRoute ) (Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelMessageId) (Evergreen.V286.Id.Id Evergreen.V286.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V286.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V286.Id.AnyGuildOrDmId, Evergreen.V286.Id.ThreadRoute ) (Evergreen.V286.Id.Id Evergreen.V286.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V286.Id.AnyGuildOrDmId Evergreen.V286.Id.ThreadRouteWithMessage Evergreen.V286.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V286.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V286.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V286.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V286.Id.Id Evergreen.V286.Id.GuildId) Evergreen.V286.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId) (Evergreen.V286.Discord.Id Evergreen.V286.Discord.GuildId) Evergreen.V286.User.NotificationLevel
    | GotStartupData Evergreen.V286.Ports.StartupData
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V286.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId
        , otherUserId : Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V286.Id.AnyGuildOrDmId Evergreen.V286.Id.ThreadRoute Evergreen.V286.MessageInput.Msg
    | MessageInputMsg Evergreen.V286.Id.AnyGuildOrDmId Evergreen.V286.Id.ThreadRoute Evergreen.V286.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V286.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V286.Range.Range, Evergreen.V286.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V286.Range.Range, Evergreen.V286.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V286.Call.FromJs)
    | VoiceChatMsg Evergreen.V286.Call.Msg
    | PressedChannelHeaderTab Evergreen.V286.Route.DmChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadServiceWorkerData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V286.Drawing.Msg


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V286.Id.Id Evergreen.V286.Id.GuildId) (Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelId) Evergreen.V286.Id.ThreadRoute
    | InitialLoadRequested_Dm Evergreen.V286.DmChannel.DmChannelId Evergreen.V286.Id.ThreadRoute
    | InitialLoadRequested_Discord Evergreen.V286.Id.DiscordGuildOrDmId Evergreen.V286.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V286.Id.Id Evergreen.V286.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V286.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V286.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V286.Untrusted.Untrusted Evergreen.V286.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V286.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V286.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V286.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V286.Id.Id Evergreen.V286.Id.GuildId) (Evergreen.V286.SecretId.SecretId Evergreen.V286.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V286.PersonName.PersonName Evergreen.V286.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V286.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V286.Slack.OAuthCode Evergreen.V286.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V286.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V286.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V286.Id.Id Evergreen.V286.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V286.SecretId.SecretId Evergreen.V286.Id.GoMatchPublicId)


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V286.Discord.Id Evergreen.V286.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V286.Discord.Id Evergreen.V286.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V286.EmailAddress.EmailAddress (Result Evergreen.V286.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V286.EmailAddress.EmailAddress (Result Evergreen.V286.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V286.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V286.Discord.Id Evergreen.V286.Discord.GuildId) (Evergreen.V286.Discord.Id Evergreen.V286.Discord.ChannelId) Evergreen.V286.Id.ThreadRouteWithMaybeMessage (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId) (Result Evergreen.V286.Discord.HttpError Evergreen.V286.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V286.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V286.Discord.Id Evergreen.V286.Discord.PrivateChannelId) (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId) (Result Evergreen.V286.Discord.HttpError Evergreen.V286.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V286.Discord.Id Evergreen.V286.Discord.GuildId) (Evergreen.V286.Discord.Id Evergreen.V286.Discord.ChannelId) Evergreen.V286.Id.ThreadRouteWithMessage (Evergreen.V286.Discord.Id Evergreen.V286.Discord.MessageId) (Result Evergreen.V286.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V286.Discord.Id Evergreen.V286.Discord.PrivateChannelId) (Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelMessageId) (Evergreen.V286.Discord.Id Evergreen.V286.Discord.MessageId) (Result Evergreen.V286.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V286.Discord.Id Evergreen.V286.Discord.GuildId) (Evergreen.V286.Discord.Id Evergreen.V286.Discord.ChannelId) Evergreen.V286.Id.ThreadRouteWithMessage (Evergreen.V286.Discord.Id Evergreen.V286.Discord.MessageId) (Result Evergreen.V286.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V286.Discord.Id Evergreen.V286.Discord.PrivateChannelId) (Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelMessageId) (Evergreen.V286.Discord.Id Evergreen.V286.Discord.MessageId) (Result Evergreen.V286.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V286.Discord.Id Evergreen.V286.Discord.GuildId) (Evergreen.V286.Discord.Id Evergreen.V286.Discord.ChannelId) Evergreen.V286.Id.ThreadRouteWithMessage (Evergreen.V286.Discord.Id Evergreen.V286.Discord.MessageId) Evergreen.V286.Emoji.EmojiOrCustomEmoji (Result Evergreen.V286.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V286.Discord.Id Evergreen.V286.Discord.PrivateChannelId) (Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelMessageId) (Evergreen.V286.Discord.Id Evergreen.V286.Discord.MessageId) Evergreen.V286.Emoji.EmojiOrCustomEmoji (Result Evergreen.V286.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V286.Discord.Id Evergreen.V286.Discord.GuildId) (Evergreen.V286.Discord.Id Evergreen.V286.Discord.ChannelId) Evergreen.V286.Id.ThreadRouteWithMessage (Evergreen.V286.Discord.Id Evergreen.V286.Discord.MessageId) Evergreen.V286.Emoji.EmojiOrCustomEmoji (Result Evergreen.V286.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V286.Discord.Id Evergreen.V286.Discord.PrivateChannelId) (Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelMessageId) (Evergreen.V286.Discord.Id Evergreen.V286.Discord.MessageId) Evergreen.V286.Emoji.EmojiOrCustomEmoji (Result Evergreen.V286.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V286.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V286.Discord.HttpError (List ( Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId, Maybe Evergreen.V286.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId) Effect.Time.Posix Evergreen.V286.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V286.Slack.CurrentUser
            , team : Evergreen.V286.Slack.Team
            , users : List Evergreen.V286.Slack.User
            , channels : List ( Evergreen.V286.Slack.Channel, List Evergreen.V286.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId) (Result Effect.Http.Error Evergreen.V286.Slack.TokenResponse)
    | GotCloudflareSessionCreated Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V286.Local.ChangeId Effect.Time.Posix Evergreen.V286.Call.CallId Evergreen.V286.Cloudflare.Sdp (List String) (Result Effect.Http.Error Evergreen.V286.Cloudflare.RealtimeSessionId)
    | GotCloudflareSession Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V286.Local.ChangeId Effect.Time.Posix Evergreen.V286.Call.CallId Evergreen.V286.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V286.Cloudflare.PushTracksResult)
    | GotCloudflarePullOffer Effect.Time.Posix Effect.Lamdera.ClientId Evergreen.V286.Local.ChangeId Evergreen.V286.Call.ConnectionId Evergreen.V286.Cloudflare.RealtimeSessionId (List Evergreen.V286.Cloudflare.TrackName) (Result Effect.Http.Error Evergreen.V286.Cloudflare.PullTracksResult)
    | GotCloudflareRenegotiateAck Effect.Lamdera.ClientId Evergreen.V286.Local.ChangeId Evergreen.V286.Cloudflare.Sdp (Result Effect.Http.Error ())
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId) Evergreen.V286.Discord.UserAuth (Result Evergreen.V286.Discord.HttpError Evergreen.V286.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId) (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId) (Result Evergreen.V286.Discord.HttpError Evergreen.V286.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId)
        (Result
            Evergreen.V286.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V286.Discord.Id Evergreen.V286.Discord.PrivateChannelId
                , members : List (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId)
                }
            , List
                ( Evergreen.V286.Discord.Id Evergreen.V286.Discord.GuildId
                , { guild : Evergreen.V286.Discord.GatewayGuild
                  , channels : List Evergreen.V286.Discord.Channel
                  , icon : Maybe Evergreen.V286.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId) Bool Evergreen.V286.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V286.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V286.Discord.Id Evergreen.V286.Discord.AttachmentId, Evergreen.V286.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V286.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V286.Discord.Id Evergreen.V286.Discord.AttachmentId, Evergreen.V286.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId) (Evergreen.V286.Discord.Id Evergreen.V286.Discord.GuildId) (Evergreen.V286.Discord.Id Evergreen.V286.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V286.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V286.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId) (Evergreen.V286.Discord.Id Evergreen.V286.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V286.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V286.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId) (Evergreen.V286.Discord.Id Evergreen.V286.Discord.GuildId) (Evergreen.V286.Discord.Id Evergreen.V286.Discord.ChannelId) (Result Evergreen.V286.Discord.HttpError (List Evergreen.V286.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId) (Evergreen.V286.Discord.Id Evergreen.V286.Discord.PrivateChannelId) (Result Evergreen.V286.Discord.HttpError (List Evergreen.V286.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V286.Id.Id Evergreen.V286.Id.GuildId) (Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelId) Evergreen.V286.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V286.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V286.DmChannel.DmChannelId Evergreen.V286.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V286.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V286.Discord.Id Evergreen.V286.Discord.GuildId) (Evergreen.V286.Discord.Id Evergreen.V286.Discord.ChannelId) Evergreen.V286.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V286.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V286.Discord.Id Evergreen.V286.Discord.PrivateChannelId) (Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V286.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId)
        (Evergreen.V286.Discord.Id Evergreen.V286.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V286.Discord.HttpError
            { guild : Evergreen.V286.Discord.GatewayGuild
            , channels : List Evergreen.V286.Discord.Channel
            , icon : Maybe Evergreen.V286.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V286.Discord.Id Evergreen.V286.Discord.GuildId) (Result Evergreen.V286.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V286.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId) (List ( Evergreen.V286.Id.Id Evergreen.V286.Id.StickerId, Result Effect.Http.Error Evergreen.V286.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V286.Id.Id Evergreen.V286.Id.StickerId, Result Effect.Http.Error Evergreen.V286.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId) (List ( Evergreen.V286.Id.Id Evergreen.V286.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V286.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V286.Id.Id Evergreen.V286.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V286.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V286.Discord.HttpError (List Evergreen.V286.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V286.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V286.SecretId.SecretId Evergreen.V286.SecretId.ServerSecret))
    | GotTimeForWebsocketListenClose (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | GotCloudflareUsage Effect.Time.Posix (Result Effect.Http.Error Int)
    | GotCloudflareEgressForAdmin Effect.Lamdera.ClientId (Result Effect.Http.Error Int)
    | GotRustServerFileUpload Evergreen.V286.FileStatus.FileHash Int (Maybe (Evergreen.V286.Coord.Coord Evergreen.V286.CssPixels.CssPixels))
