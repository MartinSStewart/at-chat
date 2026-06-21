module Evergreen.V293.Types exposing (..)

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
import Evergreen.V293.AiChat
import Evergreen.V293.Call
import Evergreen.V293.ChannelDescription
import Evergreen.V293.ChannelName
import Evergreen.V293.Cloudflare
import Evergreen.V293.Coord
import Evergreen.V293.CssPixels
import Evergreen.V293.CustomEmoji
import Evergreen.V293.Discord
import Evergreen.V293.DiscordAttachmentId
import Evergreen.V293.DiscordUserData
import Evergreen.V293.DmChannel
import Evergreen.V293.Drawing
import Evergreen.V293.Editable
import Evergreen.V293.EmailAddress
import Evergreen.V293.Embed
import Evergreen.V293.Emoji
import Evergreen.V293.FileStatus
import Evergreen.V293.Go
import Evergreen.V293.GuildName
import Evergreen.V293.Id
import Evergreen.V293.ImageEditor
import Evergreen.V293.ImageViewer
import Evergreen.V293.LinkedAndOtherDiscordUsers
import Evergreen.V293.Local
import Evergreen.V293.LocalState
import Evergreen.V293.Log
import Evergreen.V293.LoginForm
import Evergreen.V293.MembersAndOwner
import Evergreen.V293.Message
import Evergreen.V293.MessageInput
import Evergreen.V293.MessageView
import Evergreen.V293.MyUi
import Evergreen.V293.NonemptyDict
import Evergreen.V293.NonemptySet
import Evergreen.V293.OneOrGreater
import Evergreen.V293.OneToOne
import Evergreen.V293.Pages.Admin
import Evergreen.V293.Pagination
import Evergreen.V293.PersonName
import Evergreen.V293.Ports
import Evergreen.V293.Postmark
import Evergreen.V293.Range
import Evergreen.V293.RichText
import Evergreen.V293.Route
import Evergreen.V293.SecretId
import Evergreen.V293.SessionIdHash
import Evergreen.V293.Slack
import Evergreen.V293.Sticker
import Evergreen.V293.TextEditor
import Evergreen.V293.ToBackendLog
import Evergreen.V293.Touch
import Evergreen.V293.TwoFactorAuthentication
import Evergreen.V293.Ui.Anim
import Evergreen.V293.Untrusted
import Evergreen.V293.User
import Evergreen.V293.UserAgent
import Evergreen.V293.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V293.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V293.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.Id.GuildId) Evergreen.V293.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId) Evergreen.V293.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V293.Discord.Id Evergreen.V293.Discord.PrivateChannelId) Evergreen.V293.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V293.Discord.Id Evergreen.V293.Discord.GuildId) Evergreen.V293.LocalState.DiscordFrontendGuild
    , user : Evergreen.V293.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId) Evergreen.V293.User.FrontendUser
    , discordUsers : Evergreen.V293.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V293.SessionIdHash.SessionIdHash Evergreen.V293.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V293.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.Id.StickerId) Evergreen.V293.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.Id.CustomEmojiId) Evergreen.V293.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V293.Call.CallId (Evergreen.V293.NonemptyDict.NonemptyDict ( Evergreen.V293.Id.Id Evergreen.V293.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V293.Call.RemoteCallData)
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type PublicGoMatch
    = PublicGoMatch_NotLoaded
    | PublicGoMatch_Loading
    | PublicGoMatch_Loaded Evergreen.V293.Go.PublicGoMatchData Evergreen.V293.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V293.Route.Route
    , windowSize : Evergreen.V293.Coord.Coord Evergreen.V293.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , timezone : Effect.Time.Zone
    , startupData : Maybe Evergreen.V293.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V293.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V293.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V293.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.FileStatus.FileId) Evergreen.V293.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V293.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V293.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.FileStatus.FileId) Evergreen.V293.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V293.Id.Id Evergreen.V293.Id.GuildId) Evergreen.V293.ChannelName.ChannelName Evergreen.V293.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V293.Id.Id Evergreen.V293.Id.GuildId) (Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelId) Evergreen.V293.ChannelName.ChannelName Evergreen.V293.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V293.Id.Id Evergreen.V293.Id.GuildId) (Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelId)
    | Local_DeleteGuild (Evergreen.V293.Id.Id Evergreen.V293.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V293.Id.Id Evergreen.V293.Id.GuildId) (Evergreen.V293.UserSession.ToBeFilledInByBackend (Evergreen.V293.SecretId.SecretId Evergreen.V293.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V293.Id.Id Evergreen.V293.Id.GuildId) (Evergreen.V293.SecretId.SecretId Evergreen.V293.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V293.GuildName.GuildName (Evergreen.V293.UserSession.ToBeFilledInByBackend (Evergreen.V293.Id.Id Evergreen.V293.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V293.Id.AnyGuildOrDmId, Evergreen.V293.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V293.Id.AnyGuildOrDmId Evergreen.V293.Id.ThreadRouteWithMessage Evergreen.V293.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V293.Id.AnyGuildOrDmId Evergreen.V293.Id.ThreadRouteWithMessage Evergreen.V293.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V293.Id.GuildOrDmId Evergreen.V293.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.FileStatus.FileId) Evergreen.V293.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId) (Evergreen.V293.Discord.Id Evergreen.V293.Discord.GuildId) (Evergreen.V293.Discord.Id Evergreen.V293.Discord.ChannelId) Evergreen.V293.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V293.Id.DiscordGuildOrDmId_DmData (Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V293.Id.AnyGuildOrDmId Evergreen.V293.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V293.Id.AnyGuildOrDmId Evergreen.V293.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V293.Id.AnyGuildOrDmId Evergreen.V293.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V293.UserSession.SetViewing
    | Local_SetName Evergreen.V293.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V293.Id.GuildOrDmId (Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelMessageId) (Evergreen.V293.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelMessageId) (Evergreen.V293.Message.Message Evergreen.V293.Id.ChannelMessageId (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V293.Id.GuildOrDmId (Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelMessageId) (Evergreen.V293.Id.Id Evergreen.V293.Id.ThreadMessageId) (Evergreen.V293.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.Id.ThreadMessageId) (Evergreen.V293.Message.Message Evergreen.V293.Id.ThreadMessageId (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V293.Id.DiscordGuildOrDmId (Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelMessageId) (Evergreen.V293.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelMessageId) (Evergreen.V293.Message.Message Evergreen.V293.Id.ChannelMessageId (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V293.Id.DiscordGuildOrDmId (Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelMessageId) (Evergreen.V293.Id.Id Evergreen.V293.Id.ThreadMessageId) (Evergreen.V293.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.Id.ThreadMessageId) (Evergreen.V293.Message.Message Evergreen.V293.Id.ThreadMessageId (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V293.Id.Id Evergreen.V293.Id.GuildId) Evergreen.V293.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId) (Evergreen.V293.Discord.Id Evergreen.V293.Discord.GuildId) Evergreen.V293.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V293.UserSession.NotificationMode
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V293.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V293.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V293.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V293.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V293.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V293.NonemptySet.NonemptySet (Evergreen.V293.Id.Id Evergreen.V293.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V293.Call.LocalChange
    | Local_Go
        { otherUserId : Evergreen.V293.Id.Id Evergreen.V293.Id.UserId
        }
        Evergreen.V293.Go.LocalChange
    | Local_Drawing Evergreen.V293.Id.AnyGuildOrDmId Evergreen.V293.Drawing.AnchorType Evergreen.V293.Drawing.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId) Effect.Time.Posix Evergreen.V293.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V293.RichText.RichText (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId))) Evergreen.V293.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.FileStatus.FileId) Evergreen.V293.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.Id.StickerId) Evergreen.V293.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V293.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V293.RichText.RichText (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId))) Evergreen.V293.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.FileStatus.FileId) Evergreen.V293.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.Id.StickerId) Evergreen.V293.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V293.Id.Id Evergreen.V293.Id.GuildId) Evergreen.V293.ChannelName.ChannelName Evergreen.V293.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V293.Id.Id Evergreen.V293.Id.GuildId) (Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelId) Evergreen.V293.ChannelName.ChannelName Evergreen.V293.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V293.Id.Id Evergreen.V293.Id.GuildId) (Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelId)
    | Server_DeleteGuild (Evergreen.V293.Id.Id Evergreen.V293.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId) (Evergreen.V293.Id.Id Evergreen.V293.Id.GuildId) (Evergreen.V293.SecretId.SecretId Evergreen.V293.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V293.Id.Id Evergreen.V293.Id.GuildId) (Evergreen.V293.SecretId.SecretId Evergreen.V293.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId) (Evergreen.V293.Id.Id Evergreen.V293.Id.GuildId) Evergreen.V293.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V293.LocalState.JoinGuildError
            { guildId : Evergreen.V293.Id.Id Evergreen.V293.Id.GuildId
            , guild : Evergreen.V293.LocalState.FrontendGuild
            , owner : Evergreen.V293.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId) Evergreen.V293.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId) Evergreen.V293.Id.GuildOrDmId Evergreen.V293.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId) (Evergreen.V293.Discord.Id Evergreen.V293.Discord.GuildId) (Evergreen.V293.Discord.Id Evergreen.V293.Discord.ChannelId) Evergreen.V293.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId) (Evergreen.V293.Discord.Id Evergreen.V293.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId) Evergreen.V293.Id.GuildOrDmId Evergreen.V293.Id.ThreadRouteWithMessage Evergreen.V293.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId) Evergreen.V293.Id.GuildOrDmId Evergreen.V293.Id.ThreadRouteWithMessage Evergreen.V293.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId) (Evergreen.V293.Discord.Id Evergreen.V293.Discord.GuildId) (Evergreen.V293.Discord.Id Evergreen.V293.Discord.ChannelId) Evergreen.V293.Id.ThreadRouteWithMessage Evergreen.V293.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId) (Evergreen.V293.Discord.Id Evergreen.V293.Discord.PrivateChannelId) (Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelMessageId) Evergreen.V293.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId) (Evergreen.V293.Discord.Id Evergreen.V293.Discord.GuildId) (Evergreen.V293.Discord.Id Evergreen.V293.Discord.ChannelId) Evergreen.V293.Id.ThreadRouteWithMessage Evergreen.V293.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId) (Evergreen.V293.Discord.Id Evergreen.V293.Discord.PrivateChannelId) (Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelMessageId) Evergreen.V293.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId) Evergreen.V293.Id.GuildOrDmId Evergreen.V293.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V293.RichText.RichText (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId))) (SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.FileStatus.FileId) Evergreen.V293.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId) (Evergreen.V293.Discord.Id Evergreen.V293.Discord.GuildId) (Evergreen.V293.Discord.Id Evergreen.V293.Discord.ChannelId) Evergreen.V293.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V293.RichText.RichText (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V293.Id.DiscordGuildOrDmId_DmData (Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V293.RichText.RichText (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId) Evergreen.V293.Id.AnyGuildOrDmId Evergreen.V293.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V293.Id.AnyGuildOrDmId Evergreen.V293.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V293.Discord.Id Evergreen.V293.Discord.GuildId) (Evergreen.V293.Discord.Id Evergreen.V293.Discord.ChannelId) Evergreen.V293.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V293.Discord.Id Evergreen.V293.Discord.PrivateChannelId) (Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId) Evergreen.V293.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId) Evergreen.V293.FileStatus.FileHash
    | Server_SetGuildIcon (Evergreen.V293.Id.Id Evergreen.V293.Id.GuildId) Evergreen.V293.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V293.Id.Id Evergreen.V293.Id.GuildId) Evergreen.V293.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V293.Discord.Id Evergreen.V293.Discord.GuildId) Evergreen.V293.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V293.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V293.SessionIdHash.SessionIdHash Evergreen.V293.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V293.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V293.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V293.Id.AnyGuildOrDmId, Evergreen.V293.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V293.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId) Evergreen.V293.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V293.Discord.Id Evergreen.V293.Discord.GuildId) (Evergreen.V293.Discord.Id Evergreen.V293.Discord.ChannelId) Evergreen.V293.ChannelName.ChannelName (Evergreen.V293.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V293.Discord.Id Evergreen.V293.Discord.PrivateChannelId)
        (Evergreen.V293.NonemptyDict.NonemptyDict
            (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V293.Discord.Id Evergreen.V293.Discord.GuildId) Evergreen.V293.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V293.Discord.Id Evergreen.V293.Discord.PrivateChannelId) Evergreen.V293.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId) Evergreen.V293.UserSession.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId) (Maybe (Evergreen.V293.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V293.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V293.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V293.Id.Id Evergreen.V293.Id.GuildId) (Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelId) Evergreen.V293.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V293.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId) Evergreen.V293.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V293.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V293.Discord.Id Evergreen.V293.Discord.GuildId) (Evergreen.V293.Discord.Id Evergreen.V293.Discord.ChannelId) Evergreen.V293.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V293.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V293.Discord.Id Evergreen.V293.Discord.PrivateChannelId) (Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V293.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V293.Discord.Id Evergreen.V293.Discord.GuildId) Evergreen.V293.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V293.Discord.Id Evergreen.V293.Discord.GuildId) (Evergreen.V293.Discord.Id Evergreen.V293.Discord.ChannelId) (Evergreen.V293.Discord.OptionalData String) (Evergreen.V293.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V293.Discord.Id Evergreen.V293.Discord.GuildId)
        (Evergreen.V293.MembersAndOwner.MembersAndOwner
            (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V293.Discord.Id Evergreen.V293.Discord.GuildId) (Evergreen.V293.Discord.Id Evergreen.V293.Discord.ChannelId) (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId) Evergreen.V293.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.Id.StickerId) Evergreen.V293.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.Id.CustomEmojiId) Evergreen.V293.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V293.Call.ServerChange
    | Server_Go
        (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId)
        { otherUserId : Evergreen.V293.Id.Id Evergreen.V293.Id.UserId
        }
        Evergreen.V293.Go.LocalChange
    | Server_Drawing (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId) Evergreen.V293.Id.AnyGuildOrDmId Evergreen.V293.Drawing.AnchorType Evergreen.V293.Drawing.LocalChange


type LocalMsg
    = LocalChange (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V293.Id.Id Evergreen.V293.Id.GuildId) (Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelId) Evergreen.V293.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V293.Discord.Id Evergreen.V293.Discord.GuildId) (Evergreen.V293.Discord.Id Evergreen.V293.Discord.ChannelId) Evergreen.V293.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.FileStatus.FileId) Evergreen.V293.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V293.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V293.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V293.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V293.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V293.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V293.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V293.Coord.Coord Evergreen.V293.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V293.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V293.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V293.Id.AnyGuildOrDmId Evergreen.V293.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V293.Id.AnyGuildOrDmId Evergreen.V293.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V293.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V293.Coord.Coord Evergreen.V293.CssPixels.CssPixels) (Maybe Evergreen.V293.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V293.Id.AnyGuildOrDmId, Evergreen.V293.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelMessageId) (Evergreen.V293.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.Id.ThreadMessageId) (Evergreen.V293.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V293.Editable.Model
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
    | FileDragging Effect.Time.Posix Evergreen.V293.OneOrGreater.OneOrGreater


type alias LoggedIn2 =
    { localState : Evergreen.V293.Local.Local LocalMsg Evergreen.V293.LocalState.LocalState
    , admin : Evergreen.V293.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V293.Id.AnyGuildOrDmId, Evergreen.V293.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V293.Id.Id Evergreen.V293.Id.GuildId, Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V293.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V293.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V293.Id.AnyGuildOrDmId, Evergreen.V293.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V293.Id.AnyGuildOrDmId, Evergreen.V293.Id.ThreadRoute ) (Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : Evergreen.V293.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V293.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V293.Id.AnyGuildOrDmId, Evergreen.V293.Id.ThreadRoute ) (Evergreen.V293.NonemptyDict.NonemptyDict (Evergreen.V293.Id.Id Evergreen.V293.FileStatus.FileId) Evergreen.V293.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V293.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V293.TextEditor.Model
    , profilePictureEditor : Evergreen.V293.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V293.Id.Id Evergreen.V293.Id.GuildId, Evergreen.V293.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V293.Emoji.Model
    , voiceChat : Evergreen.V293.Call.Model
    , currentDmGoMatch : SeqDict.SeqDict ( Evergreen.V293.Id.Id Evergreen.V293.Id.UserId, Maybe (Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelMessageId) ) Evergreen.V293.Go.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V293.Drawing.Model
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V293.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V293.SecretId.SecretId Evergreen.V293.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V293.Range.Range
                , direction : Evergreen.V293.Range.SelectionDirection
                }
        }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V293.NonemptyDict.NonemptyDict Int Evergreen.V293.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V293.NonemptyDict.NonemptyDict Int Evergreen.V293.Touch.Touch
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
    | AdminToFrontend Evergreen.V293.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V293.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V293.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V293.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V293.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V293.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V293.Go.PublicGoMatchResponse)


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V293.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V293.Coord.Coord Evergreen.V293.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V293.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V293.MyUi.LastCopy
    , notificationPermission : Evergreen.V293.Ports.NotificationPermission
    , pwaStatus : Evergreen.V293.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V293.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V293.UserAgent.UserAgent
    , timeOrigin : Effect.Time.Posix
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V293.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V293.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V293.Id.Id Evergreen.V293.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V293.Id.Id Evergreen.V293.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V293.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V293.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V293.Coord.Coord Evergreen.V293.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V293.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V293.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V293.Id.Id Evergreen.V293.Id.GuildId, Evergreen.V293.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V293.DmChannel.DmChannelId, Evergreen.V293.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V293.Discord.Id Evergreen.V293.Discord.GuildId, Evergreen.V293.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V293.Discord.Id Evergreen.V293.Discord.PrivateChannelId, Evergreen.V293.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V293.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V293.NonemptyDict.NonemptyDict (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId) Evergreen.V293.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V293.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V293.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V293.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V293.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId) Evergreen.V293.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId) Evergreen.V293.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V293.Id.Id Evergreen.V293.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.Id.GuildId) Evergreen.V293.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.Id.GuildId) Evergreen.V293.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V293.Discord.Id Evergreen.V293.Discord.GuildId) Evergreen.V293.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V293.DmChannel.DmChannelId Evergreen.V293.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V293.Discord.Id Evergreen.V293.Discord.PrivateChannelId) Evergreen.V293.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V293.OneToOne.OneToOne (Evergreen.V293.Slack.Id Evergreen.V293.Slack.ChannelId) Evergreen.V293.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V293.OneToOne.OneToOne String (Evergreen.V293.Id.Id Evergreen.V293.Id.GuildId)
    , slackUsers : Evergreen.V293.OneToOne.OneToOne (Evergreen.V293.Slack.Id Evergreen.V293.Slack.UserId) (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId)
    , slackServers : Evergreen.V293.OneToOne.OneToOne (Evergreen.V293.Slack.Id Evergreen.V293.Slack.TeamId) (Evergreen.V293.Id.Id Evergreen.V293.Id.GuildId)
    , slackToken : Maybe Evergreen.V293.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V293.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V293.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V293.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V293.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V293.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V293.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V293.Cloudflare.AnalyticsApiToken
    , textEditor : Evergreen.V293.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId) Evergreen.V293.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId, Evergreen.V293.Discord.Id Evergreen.V293.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V293.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V293.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V293.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V293.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId) (Evergreen.V293.LocalState.LoadingDiscordChannel (List Evergreen.V293.Discord.Message))
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V293.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.Id.StickerId) Evergreen.V293.Sticker.StickerData
    , discordStickers : Evergreen.V293.OneToOne.OneToOne (Evergreen.V293.Discord.Id Evergreen.V293.Discord.StickerId) (Evergreen.V293.Id.Id Evergreen.V293.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.Id.CustomEmojiId) Evergreen.V293.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V293.OneToOne.OneToOne Evergreen.V293.RichText.DiscordCustomEmojiIdAndName (Evergreen.V293.Id.Id Evergreen.V293.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V293.Postmark.ApiKey
    , serverSecret : Evergreen.V293.SecretId.SecretId Evergreen.V293.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V293.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V293.OneToOne.OneToOne (Evergreen.V293.SecretId.SecretId Evergreen.V293.Id.GoMatchPublicId) ( Evergreen.V293.DmChannel.DmChannelId, Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelMessageId )
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V293.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V293.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V293.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V293.Route.Route
    | SelectedFilesToAttach ( Evergreen.V293.Id.AnyGuildOrDmId, Evergreen.V293.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V293.Id.Id Evergreen.V293.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V293.Id.Id Evergreen.V293.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V293.Id.Id Evergreen.V293.Id.GuildId) (Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelId) Evergreen.V293.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V293.Id.Id Evergreen.V293.Id.GuildId) (Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelId) Evergreen.V293.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V293.Discord.Id Evergreen.V293.Discord.GuildId) (Evergreen.V293.Discord.Id Evergreen.V293.Discord.ChannelId) Evergreen.V293.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V293.Discord.Id Evergreen.V293.Discord.GuildId) (Evergreen.V293.Discord.Id Evergreen.V293.Discord.ChannelId) Evergreen.V293.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V293.Id.Id Evergreen.V293.Id.GuildId) (Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V293.Id.Id Evergreen.V293.Id.GuildId) (Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V293.Id.Id Evergreen.V293.Id.GuildId) (Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V293.Id.Id Evergreen.V293.Id.GuildId) (Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V293.Id.Id Evergreen.V293.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V293.Id.Id Evergreen.V293.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V293.Id.Id Evergreen.V293.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V293.Id.Id Evergreen.V293.Id.GuildId) (Evergreen.V293.SecretId.SecretId Evergreen.V293.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V293.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V293.Id.AnyGuildOrDmId Evergreen.V293.Id.ThreadRouteWithMessage (Evergreen.V293.Coord.Coord Evergreen.V293.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V293.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V293.Id.AnyGuildOrDmId Evergreen.V293.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V293.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V293.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V293.Id.AnyGuildOrDmId, Evergreen.V293.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V293.Ports.NotificationPermission
    | TouchStart (Maybe ( Evergreen.V293.Id.AnyGuildOrDmId, Evergreen.V293.Id.ThreadRouteWithMessage, Bool )) Duration.Duration (Evergreen.V293.NonemptyDict.NonemptyDict Int Evergreen.V293.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V293.NonemptyDict.NonemptyDict Int Evergreen.V293.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V293.Id.AnyGuildOrDmId Evergreen.V293.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V293.Id.AnyGuildOrDmId Evergreen.V293.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V293.NonemptySet.NonemptySet (Evergreen.V293.Id.Id Evergreen.V293.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V293.Id.AnyGuildOrDmId, Evergreen.V293.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V293.Id.AnyGuildOrDmId Evergreen.V293.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V293.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V293.AiChat.Msg
    | GoMsg Evergreen.V293.Go.Msg
    | GoSpectatorMsg Evergreen.V293.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V293.Editable.Msg Evergreen.V293.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V293.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V293.Id.Id Evergreen.V293.Id.GuildId) Evergreen.V293.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V293.Id.AnyGuildOrDmId, Evergreen.V293.Id.ThreadRoute ) (Evergreen.V293.Id.Id Evergreen.V293.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V293.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V293.Id.AnyGuildOrDmId, Evergreen.V293.Id.ThreadRoute ) (Evergreen.V293.Id.Id Evergreen.V293.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V293.Id.AnyGuildOrDmId, Evergreen.V293.Id.ThreadRoute ) (Evergreen.V293.Id.Id Evergreen.V293.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V293.Id.AnyGuildOrDmId, Evergreen.V293.Id.ThreadRoute )
        { fileId : Evergreen.V293.Id.Id Evergreen.V293.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V293.Id.AnyGuildOrDmId, Evergreen.V293.Id.ThreadRoute ) (Evergreen.V293.Id.Id Evergreen.V293.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V293.Id.AnyGuildOrDmId, Evergreen.V293.Id.ThreadRoute ) (Evergreen.V293.Id.Id Evergreen.V293.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V293.Id.AnyGuildOrDmId, Evergreen.V293.Id.ThreadRoute )
        { fileId : Evergreen.V293.Id.Id Evergreen.V293.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V293.Id.AnyGuildOrDmId, Evergreen.V293.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V293.Id.AnyGuildOrDmId, Evergreen.V293.Id.ThreadRoute ) (Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelMessageId) (Evergreen.V293.Id.Id Evergreen.V293.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V293.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V293.Id.AnyGuildOrDmId, Evergreen.V293.Id.ThreadRoute ) (Evergreen.V293.Id.Id Evergreen.V293.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V293.Id.AnyGuildOrDmId Evergreen.V293.Id.ThreadRouteWithMessage Evergreen.V293.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V293.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V293.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V293.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V293.Id.Id Evergreen.V293.Id.GuildId) Evergreen.V293.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId) (Evergreen.V293.Discord.Id Evergreen.V293.Discord.GuildId) Evergreen.V293.User.NotificationLevel
    | GotStartupData Evergreen.V293.Ports.StartupData
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V293.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId
        , otherUserId : Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V293.Id.AnyGuildOrDmId Evergreen.V293.Id.ThreadRoute Evergreen.V293.MessageInput.Msg
    | MessageInputMsg Evergreen.V293.Id.AnyGuildOrDmId Evergreen.V293.Id.ThreadRoute Evergreen.V293.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V293.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V293.Range.Range, Evergreen.V293.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V293.Range.Range, Evergreen.V293.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V293.Call.FromJs)
    | VoiceChatMsg Evergreen.V293.Call.Msg
    | PressedChannelHeaderTab Evergreen.V293.Route.DmChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadServiceWorkerData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V293.Drawing.Msg


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V293.Id.Id Evergreen.V293.Id.GuildId) (Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelId) Evergreen.V293.Id.ThreadRoute
    | InitialLoadRequested_Dm Evergreen.V293.DmChannel.DmChannelId Evergreen.V293.Id.ThreadRoute
    | InitialLoadRequested_Discord Evergreen.V293.Id.DiscordGuildOrDmId Evergreen.V293.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V293.Id.Id Evergreen.V293.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V293.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V293.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V293.Untrusted.Untrusted Evergreen.V293.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V293.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V293.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V293.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V293.Id.Id Evergreen.V293.Id.GuildId) (Evergreen.V293.SecretId.SecretId Evergreen.V293.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V293.PersonName.PersonName Evergreen.V293.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V293.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V293.Slack.OAuthCode Evergreen.V293.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V293.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V293.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V293.Id.Id Evergreen.V293.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V293.SecretId.SecretId Evergreen.V293.Id.GoMatchPublicId)


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V293.Discord.Id Evergreen.V293.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V293.Discord.Id Evergreen.V293.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V293.EmailAddress.EmailAddress (Result Evergreen.V293.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V293.EmailAddress.EmailAddress (Result Evergreen.V293.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V293.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V293.Discord.Id Evergreen.V293.Discord.GuildId) (Evergreen.V293.Discord.Id Evergreen.V293.Discord.ChannelId) Evergreen.V293.Id.ThreadRouteWithMaybeMessage (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId) (Result Evergreen.V293.Discord.HttpError Evergreen.V293.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V293.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V293.Discord.Id Evergreen.V293.Discord.PrivateChannelId) (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId) (Result Evergreen.V293.Discord.HttpError Evergreen.V293.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V293.Discord.Id Evergreen.V293.Discord.GuildId) (Evergreen.V293.Discord.Id Evergreen.V293.Discord.ChannelId) Evergreen.V293.Id.ThreadRouteWithMessage (Evergreen.V293.Discord.Id Evergreen.V293.Discord.MessageId) (Result Evergreen.V293.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V293.Discord.Id Evergreen.V293.Discord.PrivateChannelId) (Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelMessageId) (Evergreen.V293.Discord.Id Evergreen.V293.Discord.MessageId) (Result Evergreen.V293.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V293.Discord.Id Evergreen.V293.Discord.GuildId) (Evergreen.V293.Discord.Id Evergreen.V293.Discord.ChannelId) Evergreen.V293.Id.ThreadRouteWithMessage (Evergreen.V293.Discord.Id Evergreen.V293.Discord.MessageId) (Result Evergreen.V293.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V293.Discord.Id Evergreen.V293.Discord.PrivateChannelId) (Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelMessageId) (Evergreen.V293.Discord.Id Evergreen.V293.Discord.MessageId) (Result Evergreen.V293.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V293.Discord.Id Evergreen.V293.Discord.GuildId) (Evergreen.V293.Discord.Id Evergreen.V293.Discord.ChannelId) Evergreen.V293.Id.ThreadRouteWithMessage (Evergreen.V293.Discord.Id Evergreen.V293.Discord.MessageId) Evergreen.V293.Emoji.EmojiOrCustomEmoji (Result Evergreen.V293.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V293.Discord.Id Evergreen.V293.Discord.PrivateChannelId) (Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelMessageId) (Evergreen.V293.Discord.Id Evergreen.V293.Discord.MessageId) Evergreen.V293.Emoji.EmojiOrCustomEmoji (Result Evergreen.V293.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V293.Discord.Id Evergreen.V293.Discord.GuildId) (Evergreen.V293.Discord.Id Evergreen.V293.Discord.ChannelId) Evergreen.V293.Id.ThreadRouteWithMessage (Evergreen.V293.Discord.Id Evergreen.V293.Discord.MessageId) Evergreen.V293.Emoji.EmojiOrCustomEmoji (Result Evergreen.V293.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V293.Discord.Id Evergreen.V293.Discord.PrivateChannelId) (Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelMessageId) (Evergreen.V293.Discord.Id Evergreen.V293.Discord.MessageId) Evergreen.V293.Emoji.EmojiOrCustomEmoji (Result Evergreen.V293.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V293.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V293.Discord.HttpError (List ( Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId, Maybe Evergreen.V293.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId) Effect.Time.Posix Evergreen.V293.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V293.Slack.CurrentUser
            , team : Evergreen.V293.Slack.Team
            , users : List Evergreen.V293.Slack.User
            , channels : List ( Evergreen.V293.Slack.Channel, List Evergreen.V293.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId) (Result Effect.Http.Error Evergreen.V293.Slack.TokenResponse)
    | GotCloudflareSessionCreated Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V293.Local.ChangeId Effect.Time.Posix Evergreen.V293.Call.CallId Evergreen.V293.Cloudflare.Sdp (List String) (Result Effect.Http.Error Evergreen.V293.Cloudflare.RealtimeSessionId)
    | GotCloudflareSession Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V293.Local.ChangeId Effect.Time.Posix Evergreen.V293.Call.CallId Evergreen.V293.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V293.Cloudflare.PushTracksResult)
    | GotCloudflarePullOffer Effect.Time.Posix Effect.Lamdera.ClientId Evergreen.V293.Local.ChangeId Evergreen.V293.Call.ConnectionId Evergreen.V293.Cloudflare.RealtimeSessionId (List Evergreen.V293.Cloudflare.TrackName) (Result Effect.Http.Error Evergreen.V293.Cloudflare.PullTracksResult)
    | GotCloudflareRenegotiateAck Effect.Lamdera.ClientId Evergreen.V293.Local.ChangeId Evergreen.V293.Cloudflare.Sdp (Result Effect.Http.Error ())
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId) Evergreen.V293.Discord.UserAuth (Result Evergreen.V293.Discord.HttpError Evergreen.V293.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId) (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId) (Result Evergreen.V293.Discord.HttpError Evergreen.V293.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId)
        (Result
            Evergreen.V293.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V293.Discord.Id Evergreen.V293.Discord.PrivateChannelId
                , members : List (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId)
                }
            , List
                ( Evergreen.V293.Discord.Id Evergreen.V293.Discord.GuildId
                , { guild : Evergreen.V293.Discord.GatewayGuild
                  , channels : List Evergreen.V293.Discord.Channel
                  , icon : Maybe Evergreen.V293.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId) Bool Evergreen.V293.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V293.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V293.Discord.Id Evergreen.V293.Discord.AttachmentId, Evergreen.V293.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V293.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V293.Discord.Id Evergreen.V293.Discord.AttachmentId, Evergreen.V293.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId) (Evergreen.V293.Discord.Id Evergreen.V293.Discord.GuildId) (Evergreen.V293.Discord.Id Evergreen.V293.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V293.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V293.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId) (Evergreen.V293.Discord.Id Evergreen.V293.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V293.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V293.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId) (Evergreen.V293.Discord.Id Evergreen.V293.Discord.GuildId) (Evergreen.V293.Discord.Id Evergreen.V293.Discord.ChannelId) (Result Evergreen.V293.Discord.HttpError (List Evergreen.V293.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId) (Evergreen.V293.Discord.Id Evergreen.V293.Discord.PrivateChannelId) (Result Evergreen.V293.Discord.HttpError (List Evergreen.V293.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V293.Id.Id Evergreen.V293.Id.GuildId) (Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelId) Evergreen.V293.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V293.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V293.DmChannel.DmChannelId Evergreen.V293.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V293.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V293.Discord.Id Evergreen.V293.Discord.GuildId) (Evergreen.V293.Discord.Id Evergreen.V293.Discord.ChannelId) Evergreen.V293.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V293.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V293.Discord.Id Evergreen.V293.Discord.PrivateChannelId) (Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V293.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId)
        (Evergreen.V293.Discord.Id Evergreen.V293.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V293.Discord.HttpError
            { guild : Evergreen.V293.Discord.GatewayGuild
            , channels : List Evergreen.V293.Discord.Channel
            , icon : Maybe Evergreen.V293.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V293.Discord.Id Evergreen.V293.Discord.GuildId) (Result Evergreen.V293.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V293.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId) (List ( Evergreen.V293.Id.Id Evergreen.V293.Id.StickerId, Result Effect.Http.Error Evergreen.V293.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V293.Id.Id Evergreen.V293.Id.StickerId, Result Effect.Http.Error Evergreen.V293.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId) (List ( Evergreen.V293.Id.Id Evergreen.V293.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V293.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V293.Id.Id Evergreen.V293.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V293.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V293.Discord.HttpError (List Evergreen.V293.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V293.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V293.SecretId.SecretId Evergreen.V293.SecretId.ServerSecret))
    | GotTimeForWebsocketListenClose (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | GotCloudflareUsage Effect.Time.Posix (Result Effect.Http.Error Int)
    | GotCloudflareEgressForAdmin Effect.Lamdera.ClientId (Result Effect.Http.Error Int)
    | GotRustServerFileUpload Evergreen.V293.FileStatus.FileHash Int (Maybe (Evergreen.V293.Coord.Coord Evergreen.V293.CssPixels.CssPixels))
