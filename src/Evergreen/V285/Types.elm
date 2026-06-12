module Evergreen.V285.Types exposing (..)

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
import Evergreen.V285.AiChat
import Evergreen.V285.Call
import Evergreen.V285.ChannelDescription
import Evergreen.V285.ChannelName
import Evergreen.V285.Cloudflare
import Evergreen.V285.Coord
import Evergreen.V285.CssPixels
import Evergreen.V285.CustomEmoji
import Evergreen.V285.Discord
import Evergreen.V285.DiscordAttachmentId
import Evergreen.V285.DiscordUserData
import Evergreen.V285.DmChannel
import Evergreen.V285.Drawing
import Evergreen.V285.Editable
import Evergreen.V285.EmailAddress
import Evergreen.V285.Embed
import Evergreen.V285.Emoji
import Evergreen.V285.FileStatus
import Evergreen.V285.Go
import Evergreen.V285.GuildName
import Evergreen.V285.Id
import Evergreen.V285.ImageEditor
import Evergreen.V285.ImageViewer
import Evergreen.V285.Local
import Evergreen.V285.LocalState
import Evergreen.V285.Log
import Evergreen.V285.LoginForm
import Evergreen.V285.MembersAndOwner
import Evergreen.V285.Message
import Evergreen.V285.MessageInput
import Evergreen.V285.MessageView
import Evergreen.V285.MyUi
import Evergreen.V285.NonemptyDict
import Evergreen.V285.NonemptySet
import Evergreen.V285.OneOrGreater
import Evergreen.V285.OneToOne
import Evergreen.V285.Pages.Admin
import Evergreen.V285.Pagination
import Evergreen.V285.PersonName
import Evergreen.V285.Ports
import Evergreen.V285.Postmark
import Evergreen.V285.Range
import Evergreen.V285.RichText
import Evergreen.V285.Route
import Evergreen.V285.SecretId
import Evergreen.V285.SessionIdHash
import Evergreen.V285.Slack
import Evergreen.V285.Sticker
import Evergreen.V285.TextEditor
import Evergreen.V285.ToBackendLog
import Evergreen.V285.Touch
import Evergreen.V285.TwoFactorAuthentication
import Evergreen.V285.Ui.Anim
import Evergreen.V285.Untrusted
import Evergreen.V285.User
import Evergreen.V285.UserAgent
import Evergreen.V285.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V285.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V285.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.Id.GuildId) Evergreen.V285.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId) Evergreen.V285.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V285.Discord.Id Evergreen.V285.Discord.PrivateChannelId) Evergreen.V285.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V285.Discord.Id Evergreen.V285.Discord.GuildId) Evergreen.V285.LocalState.DiscordFrontendGuild
    , user : Evergreen.V285.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId) Evergreen.V285.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId) Evergreen.V285.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId) Evergreen.V285.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V285.SessionIdHash.SessionIdHash Evergreen.V285.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V285.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.Id.StickerId) Evergreen.V285.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.Id.CustomEmojiId) Evergreen.V285.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V285.Call.CallId (Evergreen.V285.NonemptyDict.NonemptyDict ( Evergreen.V285.Id.Id Evergreen.V285.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V285.Call.RemoteCallData)
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type PublicGoMatch
    = PublicGoMatch_NotLoaded
    | PublicGoMatch_Loading
    | PublicGoMatch_Loaded Evergreen.V285.Go.PublicGoMatchData Evergreen.V285.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V285.Route.Route
    , windowSize : Evergreen.V285.Coord.Coord Evergreen.V285.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , timezone : Effect.Time.Zone
    , startupData : Maybe Evergreen.V285.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V285.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V285.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V285.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.FileStatus.FileId) Evergreen.V285.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V285.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V285.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.FileStatus.FileId) Evergreen.V285.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V285.Id.Id Evergreen.V285.Id.GuildId) Evergreen.V285.ChannelName.ChannelName Evergreen.V285.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V285.Id.Id Evergreen.V285.Id.GuildId) (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelId) Evergreen.V285.ChannelName.ChannelName Evergreen.V285.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V285.Id.Id Evergreen.V285.Id.GuildId) (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelId)
    | Local_DeleteGuild (Evergreen.V285.Id.Id Evergreen.V285.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V285.Id.Id Evergreen.V285.Id.GuildId) (Evergreen.V285.UserSession.ToBeFilledInByBackend (Evergreen.V285.SecretId.SecretId Evergreen.V285.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V285.Id.Id Evergreen.V285.Id.GuildId) (Evergreen.V285.SecretId.SecretId Evergreen.V285.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V285.GuildName.GuildName (Evergreen.V285.UserSession.ToBeFilledInByBackend (Evergreen.V285.Id.Id Evergreen.V285.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V285.Id.AnyGuildOrDmId, Evergreen.V285.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V285.Id.AnyGuildOrDmId Evergreen.V285.Id.ThreadRouteWithMessage Evergreen.V285.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V285.Id.AnyGuildOrDmId Evergreen.V285.Id.ThreadRouteWithMessage Evergreen.V285.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V285.Id.GuildOrDmId Evergreen.V285.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.FileStatus.FileId) Evergreen.V285.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId) (Evergreen.V285.Discord.Id Evergreen.V285.Discord.GuildId) (Evergreen.V285.Discord.Id Evergreen.V285.Discord.ChannelId) Evergreen.V285.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V285.Id.DiscordGuildOrDmId_DmData (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V285.Id.AnyGuildOrDmId Evergreen.V285.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V285.Id.AnyGuildOrDmId Evergreen.V285.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V285.Id.AnyGuildOrDmId Evergreen.V285.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V285.UserSession.SetViewing
    | Local_SetName Evergreen.V285.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V285.Id.GuildOrDmId (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelMessageId) (Evergreen.V285.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelMessageId) (Evergreen.V285.Message.Message Evergreen.V285.Id.ChannelMessageId (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V285.Id.GuildOrDmId (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelMessageId) (Evergreen.V285.Id.Id Evergreen.V285.Id.ThreadMessageId) (Evergreen.V285.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.Id.ThreadMessageId) (Evergreen.V285.Message.Message Evergreen.V285.Id.ThreadMessageId (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V285.Id.DiscordGuildOrDmId (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelMessageId) (Evergreen.V285.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelMessageId) (Evergreen.V285.Message.Message Evergreen.V285.Id.ChannelMessageId (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V285.Id.DiscordGuildOrDmId (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelMessageId) (Evergreen.V285.Id.Id Evergreen.V285.Id.ThreadMessageId) (Evergreen.V285.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.Id.ThreadMessageId) (Evergreen.V285.Message.Message Evergreen.V285.Id.ThreadMessageId (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V285.Id.Id Evergreen.V285.Id.GuildId) Evergreen.V285.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId) (Evergreen.V285.Discord.Id Evergreen.V285.Discord.GuildId) Evergreen.V285.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V285.UserSession.NotificationMode
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V285.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V285.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V285.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V285.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V285.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V285.NonemptySet.NonemptySet (Evergreen.V285.Id.Id Evergreen.V285.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V285.Call.LocalChange
    | Local_Go
        { otherUserId : Evergreen.V285.Id.Id Evergreen.V285.Id.UserId
        }
        Evergreen.V285.Go.LocalChange
    | Local_Drawing Evergreen.V285.Id.AnyGuildOrDmId Evergreen.V285.Drawing.AnchorType Evergreen.V285.Drawing.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId) Effect.Time.Posix Evergreen.V285.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V285.RichText.RichText (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId))) Evergreen.V285.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.FileStatus.FileId) Evergreen.V285.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.Id.StickerId) Evergreen.V285.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V285.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V285.RichText.RichText (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId))) Evergreen.V285.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.FileStatus.FileId) Evergreen.V285.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.Id.StickerId) Evergreen.V285.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V285.Id.Id Evergreen.V285.Id.GuildId) Evergreen.V285.ChannelName.ChannelName Evergreen.V285.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V285.Id.Id Evergreen.V285.Id.GuildId) (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelId) Evergreen.V285.ChannelName.ChannelName Evergreen.V285.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V285.Id.Id Evergreen.V285.Id.GuildId) (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelId)
    | Server_DeleteGuild (Evergreen.V285.Id.Id Evergreen.V285.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId) (Evergreen.V285.Id.Id Evergreen.V285.Id.GuildId) (Evergreen.V285.SecretId.SecretId Evergreen.V285.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V285.Id.Id Evergreen.V285.Id.GuildId) (Evergreen.V285.SecretId.SecretId Evergreen.V285.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId) (Evergreen.V285.Id.Id Evergreen.V285.Id.GuildId) Evergreen.V285.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V285.LocalState.JoinGuildError
            { guildId : Evergreen.V285.Id.Id Evergreen.V285.Id.GuildId
            , guild : Evergreen.V285.LocalState.FrontendGuild
            , owner : Evergreen.V285.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId) Evergreen.V285.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId) Evergreen.V285.Id.GuildOrDmId Evergreen.V285.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId) (Evergreen.V285.Discord.Id Evergreen.V285.Discord.GuildId) (Evergreen.V285.Discord.Id Evergreen.V285.Discord.ChannelId) Evergreen.V285.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId) (Evergreen.V285.Discord.Id Evergreen.V285.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId) Evergreen.V285.Id.GuildOrDmId Evergreen.V285.Id.ThreadRouteWithMessage Evergreen.V285.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId) Evergreen.V285.Id.GuildOrDmId Evergreen.V285.Id.ThreadRouteWithMessage Evergreen.V285.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId) (Evergreen.V285.Discord.Id Evergreen.V285.Discord.GuildId) (Evergreen.V285.Discord.Id Evergreen.V285.Discord.ChannelId) Evergreen.V285.Id.ThreadRouteWithMessage Evergreen.V285.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId) (Evergreen.V285.Discord.Id Evergreen.V285.Discord.PrivateChannelId) (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelMessageId) Evergreen.V285.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId) (Evergreen.V285.Discord.Id Evergreen.V285.Discord.GuildId) (Evergreen.V285.Discord.Id Evergreen.V285.Discord.ChannelId) Evergreen.V285.Id.ThreadRouteWithMessage Evergreen.V285.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId) (Evergreen.V285.Discord.Id Evergreen.V285.Discord.PrivateChannelId) (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelMessageId) Evergreen.V285.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId) Evergreen.V285.Id.GuildOrDmId Evergreen.V285.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V285.RichText.RichText (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId))) (SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.FileStatus.FileId) Evergreen.V285.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId) (Evergreen.V285.Discord.Id Evergreen.V285.Discord.GuildId) (Evergreen.V285.Discord.Id Evergreen.V285.Discord.ChannelId) Evergreen.V285.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V285.RichText.RichText (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V285.Id.DiscordGuildOrDmId_DmData (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V285.RichText.RichText (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId) Evergreen.V285.Id.AnyGuildOrDmId Evergreen.V285.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V285.Id.AnyGuildOrDmId Evergreen.V285.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V285.Discord.Id Evergreen.V285.Discord.GuildId) (Evergreen.V285.Discord.Id Evergreen.V285.Discord.ChannelId) Evergreen.V285.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V285.Discord.Id Evergreen.V285.Discord.PrivateChannelId) (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId) Evergreen.V285.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId) Evergreen.V285.FileStatus.FileHash
    | Server_SetGuildIcon (Evergreen.V285.Id.Id Evergreen.V285.Id.GuildId) Evergreen.V285.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V285.Id.Id Evergreen.V285.Id.GuildId) Evergreen.V285.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V285.Discord.Id Evergreen.V285.Discord.GuildId) Evergreen.V285.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V285.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V285.SessionIdHash.SessionIdHash Evergreen.V285.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V285.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V285.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V285.Id.AnyGuildOrDmId, Evergreen.V285.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V285.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId) Evergreen.V285.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V285.Discord.Id Evergreen.V285.Discord.GuildId) (Evergreen.V285.Discord.Id Evergreen.V285.Discord.ChannelId) Evergreen.V285.ChannelName.ChannelName (Evergreen.V285.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V285.Discord.Id Evergreen.V285.Discord.PrivateChannelId)
        (Evergreen.V285.NonemptyDict.NonemptyDict
            (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V285.Discord.Id Evergreen.V285.Discord.GuildId) Evergreen.V285.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V285.Discord.Id Evergreen.V285.Discord.PrivateChannelId) Evergreen.V285.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId) Evergreen.V285.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId) (Maybe (Evergreen.V285.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V285.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V285.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V285.Id.Id Evergreen.V285.Id.GuildId) (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelId) Evergreen.V285.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V285.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId) Evergreen.V285.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V285.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V285.Discord.Id Evergreen.V285.Discord.GuildId) (Evergreen.V285.Discord.Id Evergreen.V285.Discord.ChannelId) Evergreen.V285.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V285.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V285.Discord.Id Evergreen.V285.Discord.PrivateChannelId) (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V285.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V285.Discord.Id Evergreen.V285.Discord.GuildId) Evergreen.V285.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V285.Discord.Id Evergreen.V285.Discord.GuildId) (Evergreen.V285.Discord.Id Evergreen.V285.Discord.ChannelId) (Evergreen.V285.Discord.OptionalData String) (Evergreen.V285.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V285.Discord.Id Evergreen.V285.Discord.GuildId)
        (Evergreen.V285.MembersAndOwner.MembersAndOwner
            (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V285.Discord.Id Evergreen.V285.Discord.GuildId) (Evergreen.V285.Discord.Id Evergreen.V285.Discord.ChannelId) (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId) Evergreen.V285.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.Id.StickerId) Evergreen.V285.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.Id.CustomEmojiId) Evergreen.V285.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V285.Call.ServerChange
    | Server_Go
        (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId)
        { otherUserId : Evergreen.V285.Id.Id Evergreen.V285.Id.UserId
        }
        Evergreen.V285.Go.LocalChange
    | Server_Drawing (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId) Evergreen.V285.Id.AnyGuildOrDmId Evergreen.V285.Drawing.AnchorType Evergreen.V285.Drawing.LocalChange


type LocalMsg
    = LocalChange (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V285.Id.Id Evergreen.V285.Id.GuildId) (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelId) Evergreen.V285.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V285.Discord.Id Evergreen.V285.Discord.GuildId) (Evergreen.V285.Discord.Id Evergreen.V285.Discord.ChannelId) Evergreen.V285.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.FileStatus.FileId) Evergreen.V285.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V285.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V285.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V285.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V285.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V285.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V285.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V285.Coord.Coord Evergreen.V285.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V285.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V285.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V285.Id.AnyGuildOrDmId Evergreen.V285.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V285.Id.AnyGuildOrDmId Evergreen.V285.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V285.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V285.Coord.Coord Evergreen.V285.CssPixels.CssPixels) (Maybe Evergreen.V285.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V285.Id.AnyGuildOrDmId, Evergreen.V285.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelMessageId) (Evergreen.V285.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.Id.ThreadMessageId) (Evergreen.V285.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V285.Editable.Model
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
    | FileDragging Effect.Time.Posix Evergreen.V285.OneOrGreater.OneOrGreater


type alias LoggedIn2 =
    { localState : Evergreen.V285.Local.Local LocalMsg Evergreen.V285.LocalState.LocalState
    , admin : Evergreen.V285.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V285.Id.AnyGuildOrDmId, Evergreen.V285.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V285.Id.Id Evergreen.V285.Id.GuildId, Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V285.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V285.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V285.Id.AnyGuildOrDmId, Evergreen.V285.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V285.Id.AnyGuildOrDmId, Evergreen.V285.Id.ThreadRoute ) (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : Evergreen.V285.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V285.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V285.Id.AnyGuildOrDmId, Evergreen.V285.Id.ThreadRoute ) (Evergreen.V285.NonemptyDict.NonemptyDict (Evergreen.V285.Id.Id Evergreen.V285.FileStatus.FileId) Evergreen.V285.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V285.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V285.TextEditor.Model
    , profilePictureEditor : Evergreen.V285.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V285.Id.Id Evergreen.V285.Id.GuildId, Evergreen.V285.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V285.Emoji.Model
    , voiceChat : Evergreen.V285.Call.Model
    , currentDmGoMatch : SeqDict.SeqDict ( Evergreen.V285.Id.Id Evergreen.V285.Id.UserId, Maybe (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelMessageId) ) Evergreen.V285.Go.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V285.Drawing.Model
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V285.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V285.SecretId.SecretId Evergreen.V285.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V285.Range.Range
                , direction : Evergreen.V285.Range.SelectionDirection
                }
        }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V285.NonemptyDict.NonemptyDict Int Evergreen.V285.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V285.NonemptyDict.NonemptyDict Int Evergreen.V285.Touch.Touch
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
    | AdminToFrontend Evergreen.V285.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V285.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V285.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V285.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V285.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V285.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V285.Go.PublicGoMatchResponse)


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V285.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V285.Coord.Coord Evergreen.V285.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V285.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V285.MyUi.LastCopy
    , notificationPermission : Evergreen.V285.Ports.NotificationPermission
    , pwaStatus : Evergreen.V285.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V285.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V285.UserAgent.UserAgent
    , timeOrigin : Effect.Time.Posix
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V285.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V285.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V285.Id.Id Evergreen.V285.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V285.Id.Id Evergreen.V285.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V285.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V285.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V285.Coord.Coord Evergreen.V285.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V285.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V285.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V285.Id.Id Evergreen.V285.Id.GuildId, Evergreen.V285.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V285.DmChannel.DmChannelId, Evergreen.V285.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V285.Discord.Id Evergreen.V285.Discord.GuildId, Evergreen.V285.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V285.Discord.Id Evergreen.V285.Discord.PrivateChannelId, Evergreen.V285.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V285.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V285.NonemptyDict.NonemptyDict (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId) Evergreen.V285.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V285.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V285.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V285.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V285.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId) Evergreen.V285.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId) Evergreen.V285.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V285.Id.Id Evergreen.V285.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.Id.GuildId) Evergreen.V285.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.Id.GuildId) Evergreen.V285.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V285.Discord.Id Evergreen.V285.Discord.GuildId) Evergreen.V285.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V285.DmChannel.DmChannelId Evergreen.V285.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V285.Discord.Id Evergreen.V285.Discord.PrivateChannelId) Evergreen.V285.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V285.OneToOne.OneToOne (Evergreen.V285.Slack.Id Evergreen.V285.Slack.ChannelId) Evergreen.V285.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V285.OneToOne.OneToOne String (Evergreen.V285.Id.Id Evergreen.V285.Id.GuildId)
    , slackUsers : Evergreen.V285.OneToOne.OneToOne (Evergreen.V285.Slack.Id Evergreen.V285.Slack.UserId) (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId)
    , slackServers : Evergreen.V285.OneToOne.OneToOne (Evergreen.V285.Slack.Id Evergreen.V285.Slack.TeamId) (Evergreen.V285.Id.Id Evergreen.V285.Id.GuildId)
    , slackToken : Maybe Evergreen.V285.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V285.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V285.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V285.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V285.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V285.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V285.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V285.Cloudflare.AnalyticsApiToken
    , textEditor : Evergreen.V285.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId) Evergreen.V285.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId, Evergreen.V285.Discord.Id Evergreen.V285.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V285.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V285.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V285.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V285.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId) (Evergreen.V285.LocalState.LoadingDiscordChannel (List Evergreen.V285.Discord.Message))
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V285.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.Id.StickerId) Evergreen.V285.Sticker.StickerData
    , discordStickers : Evergreen.V285.OneToOne.OneToOne (Evergreen.V285.Discord.Id Evergreen.V285.Discord.StickerId) (Evergreen.V285.Id.Id Evergreen.V285.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.Id.CustomEmojiId) Evergreen.V285.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V285.OneToOne.OneToOne Evergreen.V285.RichText.DiscordCustomEmojiIdAndName (Evergreen.V285.Id.Id Evergreen.V285.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V285.Postmark.ApiKey
    , serverSecret : Evergreen.V285.SecretId.SecretId Evergreen.V285.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V285.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V285.OneToOne.OneToOne (Evergreen.V285.SecretId.SecretId Evergreen.V285.Id.GoMatchPublicId) ( Evergreen.V285.DmChannel.DmChannelId, Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelMessageId )
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V285.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V285.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V285.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V285.Route.Route
    | SelectedFilesToAttach ( Evergreen.V285.Id.AnyGuildOrDmId, Evergreen.V285.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V285.Id.Id Evergreen.V285.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V285.Id.Id Evergreen.V285.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V285.Id.Id Evergreen.V285.Id.GuildId) (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelId) Evergreen.V285.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V285.Id.Id Evergreen.V285.Id.GuildId) (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelId) Evergreen.V285.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V285.Discord.Id Evergreen.V285.Discord.GuildId) (Evergreen.V285.Discord.Id Evergreen.V285.Discord.ChannelId) Evergreen.V285.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V285.Discord.Id Evergreen.V285.Discord.GuildId) (Evergreen.V285.Discord.Id Evergreen.V285.Discord.ChannelId) Evergreen.V285.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V285.Id.Id Evergreen.V285.Id.GuildId) (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V285.Id.Id Evergreen.V285.Id.GuildId) (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V285.Id.Id Evergreen.V285.Id.GuildId) (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V285.Id.Id Evergreen.V285.Id.GuildId) (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V285.Id.Id Evergreen.V285.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V285.Id.Id Evergreen.V285.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V285.Id.Id Evergreen.V285.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V285.Id.Id Evergreen.V285.Id.GuildId) (Evergreen.V285.SecretId.SecretId Evergreen.V285.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V285.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V285.Id.AnyGuildOrDmId Evergreen.V285.Id.ThreadRouteWithMessage (Evergreen.V285.Coord.Coord Evergreen.V285.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V285.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V285.Id.AnyGuildOrDmId Evergreen.V285.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V285.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V285.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V285.Id.AnyGuildOrDmId, Evergreen.V285.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V285.Ports.NotificationPermission
    | TouchStart (Maybe ( Evergreen.V285.Id.AnyGuildOrDmId, Evergreen.V285.Id.ThreadRouteWithMessage, Bool )) Duration.Duration (Evergreen.V285.NonemptyDict.NonemptyDict Int Evergreen.V285.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V285.NonemptyDict.NonemptyDict Int Evergreen.V285.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V285.Id.AnyGuildOrDmId Evergreen.V285.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V285.Id.AnyGuildOrDmId Evergreen.V285.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V285.NonemptySet.NonemptySet (Evergreen.V285.Id.Id Evergreen.V285.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V285.Id.AnyGuildOrDmId, Evergreen.V285.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V285.Id.AnyGuildOrDmId Evergreen.V285.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V285.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V285.AiChat.Msg
    | GoMsg Evergreen.V285.Go.Msg
    | GoSpectatorMsg Evergreen.V285.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V285.Editable.Msg Evergreen.V285.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V285.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V285.Id.Id Evergreen.V285.Id.GuildId) Evergreen.V285.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V285.Id.AnyGuildOrDmId, Evergreen.V285.Id.ThreadRoute ) (Evergreen.V285.Id.Id Evergreen.V285.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V285.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V285.Id.AnyGuildOrDmId, Evergreen.V285.Id.ThreadRoute ) (Evergreen.V285.Id.Id Evergreen.V285.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V285.Id.AnyGuildOrDmId, Evergreen.V285.Id.ThreadRoute ) (Evergreen.V285.Id.Id Evergreen.V285.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V285.Id.AnyGuildOrDmId, Evergreen.V285.Id.ThreadRoute )
        { fileId : Evergreen.V285.Id.Id Evergreen.V285.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V285.Id.AnyGuildOrDmId, Evergreen.V285.Id.ThreadRoute ) (Evergreen.V285.Id.Id Evergreen.V285.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V285.Id.AnyGuildOrDmId, Evergreen.V285.Id.ThreadRoute ) (Evergreen.V285.Id.Id Evergreen.V285.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V285.Id.AnyGuildOrDmId, Evergreen.V285.Id.ThreadRoute )
        { fileId : Evergreen.V285.Id.Id Evergreen.V285.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V285.Id.AnyGuildOrDmId, Evergreen.V285.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V285.Id.AnyGuildOrDmId, Evergreen.V285.Id.ThreadRoute ) (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelMessageId) (Evergreen.V285.Id.Id Evergreen.V285.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V285.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V285.Id.AnyGuildOrDmId, Evergreen.V285.Id.ThreadRoute ) (Evergreen.V285.Id.Id Evergreen.V285.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V285.Id.AnyGuildOrDmId Evergreen.V285.Id.ThreadRouteWithMessage Evergreen.V285.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V285.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V285.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V285.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V285.Id.Id Evergreen.V285.Id.GuildId) Evergreen.V285.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId) (Evergreen.V285.Discord.Id Evergreen.V285.Discord.GuildId) Evergreen.V285.User.NotificationLevel
    | GotStartupData Evergreen.V285.Ports.StartupData
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V285.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId
        , otherUserId : Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V285.Id.AnyGuildOrDmId Evergreen.V285.Id.ThreadRoute Evergreen.V285.MessageInput.Msg
    | MessageInputMsg Evergreen.V285.Id.AnyGuildOrDmId Evergreen.V285.Id.ThreadRoute Evergreen.V285.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V285.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V285.Range.Range, Evergreen.V285.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V285.Range.Range, Evergreen.V285.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V285.Call.FromJs)
    | VoiceChatMsg Evergreen.V285.Call.Msg
    | PressedChannelHeaderTab Evergreen.V285.Route.DmChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadServiceWorkerData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V285.Drawing.Msg


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V285.Id.Id Evergreen.V285.Id.GuildId) (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelId) Evergreen.V285.Id.ThreadRoute
    | InitialLoadRequested_Dm Evergreen.V285.DmChannel.DmChannelId Evergreen.V285.Id.ThreadRoute
    | InitialLoadRequested_Discord Evergreen.V285.Id.DiscordGuildOrDmId Evergreen.V285.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V285.Id.Id Evergreen.V285.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V285.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V285.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V285.Untrusted.Untrusted Evergreen.V285.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V285.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V285.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V285.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V285.Id.Id Evergreen.V285.Id.GuildId) (Evergreen.V285.SecretId.SecretId Evergreen.V285.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V285.PersonName.PersonName Evergreen.V285.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V285.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V285.Slack.OAuthCode Evergreen.V285.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V285.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V285.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V285.Id.Id Evergreen.V285.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V285.SecretId.SecretId Evergreen.V285.Id.GoMatchPublicId)


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V285.Discord.Id Evergreen.V285.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V285.Discord.Id Evergreen.V285.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V285.EmailAddress.EmailAddress (Result Evergreen.V285.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V285.EmailAddress.EmailAddress (Result Evergreen.V285.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V285.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V285.Discord.Id Evergreen.V285.Discord.GuildId) (Evergreen.V285.Discord.Id Evergreen.V285.Discord.ChannelId) Evergreen.V285.Id.ThreadRouteWithMaybeMessage (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId) (Result Evergreen.V285.Discord.HttpError Evergreen.V285.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V285.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V285.Discord.Id Evergreen.V285.Discord.PrivateChannelId) (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId) (Result Evergreen.V285.Discord.HttpError Evergreen.V285.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V285.Discord.Id Evergreen.V285.Discord.GuildId) (Evergreen.V285.Discord.Id Evergreen.V285.Discord.ChannelId) Evergreen.V285.Id.ThreadRouteWithMessage (Evergreen.V285.Discord.Id Evergreen.V285.Discord.MessageId) (Result Evergreen.V285.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V285.Discord.Id Evergreen.V285.Discord.PrivateChannelId) (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelMessageId) (Evergreen.V285.Discord.Id Evergreen.V285.Discord.MessageId) (Result Evergreen.V285.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V285.Discord.Id Evergreen.V285.Discord.GuildId) (Evergreen.V285.Discord.Id Evergreen.V285.Discord.ChannelId) Evergreen.V285.Id.ThreadRouteWithMessage (Evergreen.V285.Discord.Id Evergreen.V285.Discord.MessageId) (Result Evergreen.V285.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V285.Discord.Id Evergreen.V285.Discord.PrivateChannelId) (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelMessageId) (Evergreen.V285.Discord.Id Evergreen.V285.Discord.MessageId) (Result Evergreen.V285.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V285.Discord.Id Evergreen.V285.Discord.GuildId) (Evergreen.V285.Discord.Id Evergreen.V285.Discord.ChannelId) Evergreen.V285.Id.ThreadRouteWithMessage (Evergreen.V285.Discord.Id Evergreen.V285.Discord.MessageId) Evergreen.V285.Emoji.EmojiOrCustomEmoji (Result Evergreen.V285.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V285.Discord.Id Evergreen.V285.Discord.PrivateChannelId) (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelMessageId) (Evergreen.V285.Discord.Id Evergreen.V285.Discord.MessageId) Evergreen.V285.Emoji.EmojiOrCustomEmoji (Result Evergreen.V285.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V285.Discord.Id Evergreen.V285.Discord.GuildId) (Evergreen.V285.Discord.Id Evergreen.V285.Discord.ChannelId) Evergreen.V285.Id.ThreadRouteWithMessage (Evergreen.V285.Discord.Id Evergreen.V285.Discord.MessageId) Evergreen.V285.Emoji.EmojiOrCustomEmoji (Result Evergreen.V285.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V285.Discord.Id Evergreen.V285.Discord.PrivateChannelId) (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelMessageId) (Evergreen.V285.Discord.Id Evergreen.V285.Discord.MessageId) Evergreen.V285.Emoji.EmojiOrCustomEmoji (Result Evergreen.V285.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V285.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V285.Discord.HttpError (List ( Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId, Maybe Evergreen.V285.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId) Effect.Time.Posix Evergreen.V285.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V285.Slack.CurrentUser
            , team : Evergreen.V285.Slack.Team
            , users : List Evergreen.V285.Slack.User
            , channels : List ( Evergreen.V285.Slack.Channel, List Evergreen.V285.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId) (Result Effect.Http.Error Evergreen.V285.Slack.TokenResponse)
    | GotCloudflareSessionCreated Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V285.Local.ChangeId Effect.Time.Posix Evergreen.V285.Call.CallId Evergreen.V285.Cloudflare.Sdp (List String) (Result Effect.Http.Error Evergreen.V285.Cloudflare.RealtimeSessionId)
    | GotCloudflareSession Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V285.Local.ChangeId Effect.Time.Posix Evergreen.V285.Call.CallId Evergreen.V285.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V285.Cloudflare.PushTracksResult)
    | GotCloudflarePullOffer Effect.Time.Posix Effect.Lamdera.ClientId Evergreen.V285.Local.ChangeId Evergreen.V285.Call.ConnectionId Evergreen.V285.Cloudflare.RealtimeSessionId (List Evergreen.V285.Cloudflare.TrackName) (Result Effect.Http.Error Evergreen.V285.Cloudflare.PullTracksResult)
    | GotCloudflareRenegotiateAck Effect.Lamdera.ClientId Evergreen.V285.Local.ChangeId Evergreen.V285.Cloudflare.Sdp (Result Effect.Http.Error ())
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId) Evergreen.V285.Discord.UserAuth (Result Evergreen.V285.Discord.HttpError Evergreen.V285.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId) (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId) (Result Evergreen.V285.Discord.HttpError Evergreen.V285.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId)
        (Result
            Evergreen.V285.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V285.Discord.Id Evergreen.V285.Discord.PrivateChannelId
                , members : List (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId)
                }
            , List
                ( Evergreen.V285.Discord.Id Evergreen.V285.Discord.GuildId
                , { guild : Evergreen.V285.Discord.GatewayGuild
                  , channels : List Evergreen.V285.Discord.Channel
                  , icon : Maybe Evergreen.V285.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId) Bool Evergreen.V285.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V285.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V285.Discord.Id Evergreen.V285.Discord.AttachmentId, Evergreen.V285.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V285.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V285.Discord.Id Evergreen.V285.Discord.AttachmentId, Evergreen.V285.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId) (Evergreen.V285.Discord.Id Evergreen.V285.Discord.GuildId) (Evergreen.V285.Discord.Id Evergreen.V285.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V285.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V285.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId) (Evergreen.V285.Discord.Id Evergreen.V285.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V285.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V285.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId) (Evergreen.V285.Discord.Id Evergreen.V285.Discord.GuildId) (Evergreen.V285.Discord.Id Evergreen.V285.Discord.ChannelId) (Result Evergreen.V285.Discord.HttpError (List Evergreen.V285.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId) (Evergreen.V285.Discord.Id Evergreen.V285.Discord.PrivateChannelId) (Result Evergreen.V285.Discord.HttpError (List Evergreen.V285.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V285.Id.Id Evergreen.V285.Id.GuildId) (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelId) Evergreen.V285.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V285.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V285.DmChannel.DmChannelId Evergreen.V285.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V285.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V285.Discord.Id Evergreen.V285.Discord.GuildId) (Evergreen.V285.Discord.Id Evergreen.V285.Discord.ChannelId) Evergreen.V285.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V285.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V285.Discord.Id Evergreen.V285.Discord.PrivateChannelId) (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V285.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId)
        (Evergreen.V285.Discord.Id Evergreen.V285.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V285.Discord.HttpError
            { guild : Evergreen.V285.Discord.GatewayGuild
            , channels : List Evergreen.V285.Discord.Channel
            , icon : Maybe Evergreen.V285.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V285.Discord.Id Evergreen.V285.Discord.GuildId) (Result Evergreen.V285.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V285.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId) (List ( Evergreen.V285.Id.Id Evergreen.V285.Id.StickerId, Result Effect.Http.Error Evergreen.V285.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V285.Id.Id Evergreen.V285.Id.StickerId, Result Effect.Http.Error Evergreen.V285.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId) (List ( Evergreen.V285.Id.Id Evergreen.V285.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V285.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V285.Id.Id Evergreen.V285.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V285.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V285.Discord.HttpError (List Evergreen.V285.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V285.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V285.SecretId.SecretId Evergreen.V285.SecretId.ServerSecret))
    | GotTimeForWebsocketListenClose (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | GotCloudflareUsage Effect.Time.Posix (Result Effect.Http.Error Int)
    | GotCloudflareEgressForAdmin Effect.Lamdera.ClientId (Result Effect.Http.Error Int)
    | GotRustServerFileUpload Evergreen.V285.FileStatus.FileHash Int (Maybe (Evergreen.V285.Coord.Coord Evergreen.V285.CssPixels.CssPixels))
