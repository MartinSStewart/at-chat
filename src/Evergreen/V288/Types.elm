module Evergreen.V288.Types exposing (..)

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
import Evergreen.V288.AiChat
import Evergreen.V288.Call
import Evergreen.V288.ChannelDescription
import Evergreen.V288.ChannelName
import Evergreen.V288.Cloudflare
import Evergreen.V288.Coord
import Evergreen.V288.CssPixels
import Evergreen.V288.CustomEmoji
import Evergreen.V288.Discord
import Evergreen.V288.DiscordAttachmentId
import Evergreen.V288.DiscordUserData
import Evergreen.V288.DmChannel
import Evergreen.V288.Drawing
import Evergreen.V288.Editable
import Evergreen.V288.EmailAddress
import Evergreen.V288.Embed
import Evergreen.V288.Emoji
import Evergreen.V288.FileStatus
import Evergreen.V288.Go
import Evergreen.V288.GuildName
import Evergreen.V288.Id
import Evergreen.V288.ImageEditor
import Evergreen.V288.ImageViewer
import Evergreen.V288.Local
import Evergreen.V288.LocalState
import Evergreen.V288.Log
import Evergreen.V288.LoginForm
import Evergreen.V288.MembersAndOwner
import Evergreen.V288.Message
import Evergreen.V288.MessageInput
import Evergreen.V288.MessageView
import Evergreen.V288.MyUi
import Evergreen.V288.NonemptyDict
import Evergreen.V288.NonemptySet
import Evergreen.V288.OneOrGreater
import Evergreen.V288.OneToOne
import Evergreen.V288.Pages.Admin
import Evergreen.V288.Pagination
import Evergreen.V288.PersonName
import Evergreen.V288.Ports
import Evergreen.V288.Postmark
import Evergreen.V288.Range
import Evergreen.V288.RichText
import Evergreen.V288.Route
import Evergreen.V288.SecretId
import Evergreen.V288.SessionIdHash
import Evergreen.V288.Slack
import Evergreen.V288.Sticker
import Evergreen.V288.TextEditor
import Evergreen.V288.ToBackendLog
import Evergreen.V288.Touch
import Evergreen.V288.TwoFactorAuthentication
import Evergreen.V288.Ui.Anim
import Evergreen.V288.Untrusted
import Evergreen.V288.User
import Evergreen.V288.UserAgent
import Evergreen.V288.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V288.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V288.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.Id.GuildId) Evergreen.V288.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId) Evergreen.V288.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V288.Discord.Id Evergreen.V288.Discord.PrivateChannelId) Evergreen.V288.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V288.Discord.Id Evergreen.V288.Discord.GuildId) Evergreen.V288.LocalState.DiscordFrontendGuild
    , user : Evergreen.V288.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId) Evergreen.V288.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId) Evergreen.V288.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId) Evergreen.V288.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V288.SessionIdHash.SessionIdHash Evergreen.V288.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V288.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.Id.StickerId) Evergreen.V288.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.Id.CustomEmojiId) Evergreen.V288.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V288.Call.CallId (Evergreen.V288.NonemptyDict.NonemptyDict ( Evergreen.V288.Id.Id Evergreen.V288.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V288.Call.RemoteCallData)
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type PublicGoMatch
    = PublicGoMatch_NotLoaded
    | PublicGoMatch_Loading
    | PublicGoMatch_Loaded Evergreen.V288.Go.PublicGoMatchData Evergreen.V288.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V288.Route.Route
    , windowSize : Evergreen.V288.Coord.Coord Evergreen.V288.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , timezone : Effect.Time.Zone
    , startupData : Maybe Evergreen.V288.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V288.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V288.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V288.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.FileStatus.FileId) Evergreen.V288.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V288.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V288.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.FileStatus.FileId) Evergreen.V288.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V288.Id.Id Evergreen.V288.Id.GuildId) Evergreen.V288.ChannelName.ChannelName Evergreen.V288.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V288.Id.Id Evergreen.V288.Id.GuildId) (Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelId) Evergreen.V288.ChannelName.ChannelName Evergreen.V288.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V288.Id.Id Evergreen.V288.Id.GuildId) (Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelId)
    | Local_DeleteGuild (Evergreen.V288.Id.Id Evergreen.V288.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V288.Id.Id Evergreen.V288.Id.GuildId) (Evergreen.V288.UserSession.ToBeFilledInByBackend (Evergreen.V288.SecretId.SecretId Evergreen.V288.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V288.Id.Id Evergreen.V288.Id.GuildId) (Evergreen.V288.SecretId.SecretId Evergreen.V288.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V288.GuildName.GuildName (Evergreen.V288.UserSession.ToBeFilledInByBackend (Evergreen.V288.Id.Id Evergreen.V288.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V288.Id.AnyGuildOrDmId, Evergreen.V288.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V288.Id.AnyGuildOrDmId Evergreen.V288.Id.ThreadRouteWithMessage Evergreen.V288.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V288.Id.AnyGuildOrDmId Evergreen.V288.Id.ThreadRouteWithMessage Evergreen.V288.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V288.Id.GuildOrDmId Evergreen.V288.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.FileStatus.FileId) Evergreen.V288.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId) (Evergreen.V288.Discord.Id Evergreen.V288.Discord.GuildId) (Evergreen.V288.Discord.Id Evergreen.V288.Discord.ChannelId) Evergreen.V288.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V288.Id.DiscordGuildOrDmId_DmData (Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V288.Id.AnyGuildOrDmId Evergreen.V288.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V288.Id.AnyGuildOrDmId Evergreen.V288.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V288.Id.AnyGuildOrDmId Evergreen.V288.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V288.UserSession.SetViewing
    | Local_SetName Evergreen.V288.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V288.Id.GuildOrDmId (Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelMessageId) (Evergreen.V288.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelMessageId) (Evergreen.V288.Message.Message Evergreen.V288.Id.ChannelMessageId (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V288.Id.GuildOrDmId (Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelMessageId) (Evergreen.V288.Id.Id Evergreen.V288.Id.ThreadMessageId) (Evergreen.V288.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.Id.ThreadMessageId) (Evergreen.V288.Message.Message Evergreen.V288.Id.ThreadMessageId (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V288.Id.DiscordGuildOrDmId (Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelMessageId) (Evergreen.V288.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelMessageId) (Evergreen.V288.Message.Message Evergreen.V288.Id.ChannelMessageId (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V288.Id.DiscordGuildOrDmId (Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelMessageId) (Evergreen.V288.Id.Id Evergreen.V288.Id.ThreadMessageId) (Evergreen.V288.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.Id.ThreadMessageId) (Evergreen.V288.Message.Message Evergreen.V288.Id.ThreadMessageId (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V288.Id.Id Evergreen.V288.Id.GuildId) Evergreen.V288.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId) (Evergreen.V288.Discord.Id Evergreen.V288.Discord.GuildId) Evergreen.V288.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V288.UserSession.NotificationMode
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V288.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V288.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V288.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V288.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V288.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V288.NonemptySet.NonemptySet (Evergreen.V288.Id.Id Evergreen.V288.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V288.Call.LocalChange
    | Local_Go
        { otherUserId : Evergreen.V288.Id.Id Evergreen.V288.Id.UserId
        }
        Evergreen.V288.Go.LocalChange
    | Local_Drawing Evergreen.V288.Id.AnyGuildOrDmId Evergreen.V288.Drawing.AnchorType Evergreen.V288.Drawing.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId) Effect.Time.Posix Evergreen.V288.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V288.RichText.RichText (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId))) Evergreen.V288.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.FileStatus.FileId) Evergreen.V288.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.Id.StickerId) Evergreen.V288.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V288.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V288.RichText.RichText (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId))) Evergreen.V288.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.FileStatus.FileId) Evergreen.V288.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.Id.StickerId) Evergreen.V288.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V288.Id.Id Evergreen.V288.Id.GuildId) Evergreen.V288.ChannelName.ChannelName Evergreen.V288.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V288.Id.Id Evergreen.V288.Id.GuildId) (Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelId) Evergreen.V288.ChannelName.ChannelName Evergreen.V288.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V288.Id.Id Evergreen.V288.Id.GuildId) (Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelId)
    | Server_DeleteGuild (Evergreen.V288.Id.Id Evergreen.V288.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId) (Evergreen.V288.Id.Id Evergreen.V288.Id.GuildId) (Evergreen.V288.SecretId.SecretId Evergreen.V288.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V288.Id.Id Evergreen.V288.Id.GuildId) (Evergreen.V288.SecretId.SecretId Evergreen.V288.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId) (Evergreen.V288.Id.Id Evergreen.V288.Id.GuildId) Evergreen.V288.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V288.LocalState.JoinGuildError
            { guildId : Evergreen.V288.Id.Id Evergreen.V288.Id.GuildId
            , guild : Evergreen.V288.LocalState.FrontendGuild
            , owner : Evergreen.V288.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId) Evergreen.V288.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId) Evergreen.V288.Id.GuildOrDmId Evergreen.V288.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId) (Evergreen.V288.Discord.Id Evergreen.V288.Discord.GuildId) (Evergreen.V288.Discord.Id Evergreen.V288.Discord.ChannelId) Evergreen.V288.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId) (Evergreen.V288.Discord.Id Evergreen.V288.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId) Evergreen.V288.Id.GuildOrDmId Evergreen.V288.Id.ThreadRouteWithMessage Evergreen.V288.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId) Evergreen.V288.Id.GuildOrDmId Evergreen.V288.Id.ThreadRouteWithMessage Evergreen.V288.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId) (Evergreen.V288.Discord.Id Evergreen.V288.Discord.GuildId) (Evergreen.V288.Discord.Id Evergreen.V288.Discord.ChannelId) Evergreen.V288.Id.ThreadRouteWithMessage Evergreen.V288.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId) (Evergreen.V288.Discord.Id Evergreen.V288.Discord.PrivateChannelId) (Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelMessageId) Evergreen.V288.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId) (Evergreen.V288.Discord.Id Evergreen.V288.Discord.GuildId) (Evergreen.V288.Discord.Id Evergreen.V288.Discord.ChannelId) Evergreen.V288.Id.ThreadRouteWithMessage Evergreen.V288.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId) (Evergreen.V288.Discord.Id Evergreen.V288.Discord.PrivateChannelId) (Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelMessageId) Evergreen.V288.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId) Evergreen.V288.Id.GuildOrDmId Evergreen.V288.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V288.RichText.RichText (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId))) (SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.FileStatus.FileId) Evergreen.V288.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId) (Evergreen.V288.Discord.Id Evergreen.V288.Discord.GuildId) (Evergreen.V288.Discord.Id Evergreen.V288.Discord.ChannelId) Evergreen.V288.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V288.RichText.RichText (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V288.Id.DiscordGuildOrDmId_DmData (Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V288.RichText.RichText (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId) Evergreen.V288.Id.AnyGuildOrDmId Evergreen.V288.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V288.Id.AnyGuildOrDmId Evergreen.V288.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V288.Discord.Id Evergreen.V288.Discord.GuildId) (Evergreen.V288.Discord.Id Evergreen.V288.Discord.ChannelId) Evergreen.V288.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V288.Discord.Id Evergreen.V288.Discord.PrivateChannelId) (Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId) Evergreen.V288.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId) Evergreen.V288.FileStatus.FileHash
    | Server_SetGuildIcon (Evergreen.V288.Id.Id Evergreen.V288.Id.GuildId) Evergreen.V288.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V288.Id.Id Evergreen.V288.Id.GuildId) Evergreen.V288.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V288.Discord.Id Evergreen.V288.Discord.GuildId) Evergreen.V288.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V288.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V288.SessionIdHash.SessionIdHash Evergreen.V288.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V288.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V288.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V288.Id.AnyGuildOrDmId, Evergreen.V288.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V288.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId) Evergreen.V288.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V288.Discord.Id Evergreen.V288.Discord.GuildId) (Evergreen.V288.Discord.Id Evergreen.V288.Discord.ChannelId) Evergreen.V288.ChannelName.ChannelName (Evergreen.V288.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V288.Discord.Id Evergreen.V288.Discord.PrivateChannelId)
        (Evergreen.V288.NonemptyDict.NonemptyDict
            (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V288.Discord.Id Evergreen.V288.Discord.GuildId) Evergreen.V288.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V288.Discord.Id Evergreen.V288.Discord.PrivateChannelId) Evergreen.V288.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId) Evergreen.V288.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId) (Maybe (Evergreen.V288.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V288.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V288.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V288.Id.Id Evergreen.V288.Id.GuildId) (Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelId) Evergreen.V288.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V288.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId) Evergreen.V288.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V288.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V288.Discord.Id Evergreen.V288.Discord.GuildId) (Evergreen.V288.Discord.Id Evergreen.V288.Discord.ChannelId) Evergreen.V288.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V288.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V288.Discord.Id Evergreen.V288.Discord.PrivateChannelId) (Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V288.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V288.Discord.Id Evergreen.V288.Discord.GuildId) Evergreen.V288.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V288.Discord.Id Evergreen.V288.Discord.GuildId) (Evergreen.V288.Discord.Id Evergreen.V288.Discord.ChannelId) (Evergreen.V288.Discord.OptionalData String) (Evergreen.V288.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V288.Discord.Id Evergreen.V288.Discord.GuildId)
        (Evergreen.V288.MembersAndOwner.MembersAndOwner
            (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V288.Discord.Id Evergreen.V288.Discord.GuildId) (Evergreen.V288.Discord.Id Evergreen.V288.Discord.ChannelId) (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId) Evergreen.V288.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.Id.StickerId) Evergreen.V288.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.Id.CustomEmojiId) Evergreen.V288.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V288.Call.ServerChange
    | Server_Go
        (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId)
        { otherUserId : Evergreen.V288.Id.Id Evergreen.V288.Id.UserId
        }
        Evergreen.V288.Go.LocalChange
    | Server_Drawing (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId) Evergreen.V288.Id.AnyGuildOrDmId Evergreen.V288.Drawing.AnchorType Evergreen.V288.Drawing.LocalChange


type LocalMsg
    = LocalChange (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V288.Id.Id Evergreen.V288.Id.GuildId) (Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelId) Evergreen.V288.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V288.Discord.Id Evergreen.V288.Discord.GuildId) (Evergreen.V288.Discord.Id Evergreen.V288.Discord.ChannelId) Evergreen.V288.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.FileStatus.FileId) Evergreen.V288.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V288.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V288.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V288.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V288.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V288.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V288.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V288.Coord.Coord Evergreen.V288.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V288.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V288.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V288.Id.AnyGuildOrDmId Evergreen.V288.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V288.Id.AnyGuildOrDmId Evergreen.V288.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V288.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V288.Coord.Coord Evergreen.V288.CssPixels.CssPixels) (Maybe Evergreen.V288.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V288.Id.AnyGuildOrDmId, Evergreen.V288.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelMessageId) (Evergreen.V288.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.Id.ThreadMessageId) (Evergreen.V288.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V288.Editable.Model
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
    | FileDragging Effect.Time.Posix Evergreen.V288.OneOrGreater.OneOrGreater


type alias LoggedIn2 =
    { localState : Evergreen.V288.Local.Local LocalMsg Evergreen.V288.LocalState.LocalState
    , admin : Evergreen.V288.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V288.Id.AnyGuildOrDmId, Evergreen.V288.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V288.Id.Id Evergreen.V288.Id.GuildId, Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V288.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V288.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V288.Id.AnyGuildOrDmId, Evergreen.V288.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V288.Id.AnyGuildOrDmId, Evergreen.V288.Id.ThreadRoute ) (Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : Evergreen.V288.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V288.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V288.Id.AnyGuildOrDmId, Evergreen.V288.Id.ThreadRoute ) (Evergreen.V288.NonemptyDict.NonemptyDict (Evergreen.V288.Id.Id Evergreen.V288.FileStatus.FileId) Evergreen.V288.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V288.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V288.TextEditor.Model
    , profilePictureEditor : Evergreen.V288.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V288.Id.Id Evergreen.V288.Id.GuildId, Evergreen.V288.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V288.Emoji.Model
    , voiceChat : Evergreen.V288.Call.Model
    , currentDmGoMatch : SeqDict.SeqDict ( Evergreen.V288.Id.Id Evergreen.V288.Id.UserId, Maybe (Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelMessageId) ) Evergreen.V288.Go.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V288.Drawing.Model
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V288.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V288.SecretId.SecretId Evergreen.V288.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V288.Range.Range
                , direction : Evergreen.V288.Range.SelectionDirection
                }
        }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V288.NonemptyDict.NonemptyDict Int Evergreen.V288.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V288.NonemptyDict.NonemptyDict Int Evergreen.V288.Touch.Touch
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
    | AdminToFrontend Evergreen.V288.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V288.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V288.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V288.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V288.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V288.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V288.Go.PublicGoMatchResponse)


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V288.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V288.Coord.Coord Evergreen.V288.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V288.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V288.MyUi.LastCopy
    , notificationPermission : Evergreen.V288.Ports.NotificationPermission
    , pwaStatus : Evergreen.V288.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V288.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V288.UserAgent.UserAgent
    , timeOrigin : Effect.Time.Posix
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V288.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V288.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V288.Id.Id Evergreen.V288.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V288.Id.Id Evergreen.V288.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V288.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V288.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V288.Coord.Coord Evergreen.V288.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V288.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V288.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V288.Id.Id Evergreen.V288.Id.GuildId, Evergreen.V288.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V288.DmChannel.DmChannelId, Evergreen.V288.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V288.Discord.Id Evergreen.V288.Discord.GuildId, Evergreen.V288.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V288.Discord.Id Evergreen.V288.Discord.PrivateChannelId, Evergreen.V288.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V288.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V288.NonemptyDict.NonemptyDict (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId) Evergreen.V288.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V288.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V288.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V288.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V288.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId) Evergreen.V288.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId) Evergreen.V288.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V288.Id.Id Evergreen.V288.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.Id.GuildId) Evergreen.V288.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.Id.GuildId) Evergreen.V288.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V288.Discord.Id Evergreen.V288.Discord.GuildId) Evergreen.V288.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V288.DmChannel.DmChannelId Evergreen.V288.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V288.Discord.Id Evergreen.V288.Discord.PrivateChannelId) Evergreen.V288.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V288.OneToOne.OneToOne (Evergreen.V288.Slack.Id Evergreen.V288.Slack.ChannelId) Evergreen.V288.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V288.OneToOne.OneToOne String (Evergreen.V288.Id.Id Evergreen.V288.Id.GuildId)
    , slackUsers : Evergreen.V288.OneToOne.OneToOne (Evergreen.V288.Slack.Id Evergreen.V288.Slack.UserId) (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId)
    , slackServers : Evergreen.V288.OneToOne.OneToOne (Evergreen.V288.Slack.Id Evergreen.V288.Slack.TeamId) (Evergreen.V288.Id.Id Evergreen.V288.Id.GuildId)
    , slackToken : Maybe Evergreen.V288.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V288.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V288.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V288.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V288.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V288.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V288.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V288.Cloudflare.AnalyticsApiToken
    , textEditor : Evergreen.V288.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId) Evergreen.V288.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId, Evergreen.V288.Discord.Id Evergreen.V288.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V288.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V288.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V288.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V288.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId) (Evergreen.V288.LocalState.LoadingDiscordChannel (List Evergreen.V288.Discord.Message))
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V288.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.Id.StickerId) Evergreen.V288.Sticker.StickerData
    , discordStickers : Evergreen.V288.OneToOne.OneToOne (Evergreen.V288.Discord.Id Evergreen.V288.Discord.StickerId) (Evergreen.V288.Id.Id Evergreen.V288.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.Id.CustomEmojiId) Evergreen.V288.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V288.OneToOne.OneToOne Evergreen.V288.RichText.DiscordCustomEmojiIdAndName (Evergreen.V288.Id.Id Evergreen.V288.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V288.Postmark.ApiKey
    , serverSecret : Evergreen.V288.SecretId.SecretId Evergreen.V288.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V288.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V288.OneToOne.OneToOne (Evergreen.V288.SecretId.SecretId Evergreen.V288.Id.GoMatchPublicId) ( Evergreen.V288.DmChannel.DmChannelId, Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelMessageId )
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V288.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V288.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V288.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V288.Route.Route
    | SelectedFilesToAttach ( Evergreen.V288.Id.AnyGuildOrDmId, Evergreen.V288.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V288.Id.Id Evergreen.V288.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V288.Id.Id Evergreen.V288.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V288.Id.Id Evergreen.V288.Id.GuildId) (Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelId) Evergreen.V288.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V288.Id.Id Evergreen.V288.Id.GuildId) (Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelId) Evergreen.V288.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V288.Discord.Id Evergreen.V288.Discord.GuildId) (Evergreen.V288.Discord.Id Evergreen.V288.Discord.ChannelId) Evergreen.V288.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V288.Discord.Id Evergreen.V288.Discord.GuildId) (Evergreen.V288.Discord.Id Evergreen.V288.Discord.ChannelId) Evergreen.V288.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V288.Id.Id Evergreen.V288.Id.GuildId) (Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V288.Id.Id Evergreen.V288.Id.GuildId) (Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V288.Id.Id Evergreen.V288.Id.GuildId) (Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V288.Id.Id Evergreen.V288.Id.GuildId) (Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V288.Id.Id Evergreen.V288.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V288.Id.Id Evergreen.V288.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V288.Id.Id Evergreen.V288.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V288.Id.Id Evergreen.V288.Id.GuildId) (Evergreen.V288.SecretId.SecretId Evergreen.V288.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V288.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V288.Id.AnyGuildOrDmId Evergreen.V288.Id.ThreadRouteWithMessage (Evergreen.V288.Coord.Coord Evergreen.V288.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V288.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V288.Id.AnyGuildOrDmId Evergreen.V288.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V288.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V288.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V288.Id.AnyGuildOrDmId, Evergreen.V288.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V288.Ports.NotificationPermission
    | TouchStart (Maybe ( Evergreen.V288.Id.AnyGuildOrDmId, Evergreen.V288.Id.ThreadRouteWithMessage, Bool )) Duration.Duration (Evergreen.V288.NonemptyDict.NonemptyDict Int Evergreen.V288.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V288.NonemptyDict.NonemptyDict Int Evergreen.V288.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V288.Id.AnyGuildOrDmId Evergreen.V288.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V288.Id.AnyGuildOrDmId Evergreen.V288.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V288.NonemptySet.NonemptySet (Evergreen.V288.Id.Id Evergreen.V288.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V288.Id.AnyGuildOrDmId, Evergreen.V288.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V288.Id.AnyGuildOrDmId Evergreen.V288.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V288.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V288.AiChat.Msg
    | GoMsg Evergreen.V288.Go.Msg
    | GoSpectatorMsg Evergreen.V288.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V288.Editable.Msg Evergreen.V288.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V288.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V288.Id.Id Evergreen.V288.Id.GuildId) Evergreen.V288.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V288.Id.AnyGuildOrDmId, Evergreen.V288.Id.ThreadRoute ) (Evergreen.V288.Id.Id Evergreen.V288.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V288.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V288.Id.AnyGuildOrDmId, Evergreen.V288.Id.ThreadRoute ) (Evergreen.V288.Id.Id Evergreen.V288.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V288.Id.AnyGuildOrDmId, Evergreen.V288.Id.ThreadRoute ) (Evergreen.V288.Id.Id Evergreen.V288.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V288.Id.AnyGuildOrDmId, Evergreen.V288.Id.ThreadRoute )
        { fileId : Evergreen.V288.Id.Id Evergreen.V288.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V288.Id.AnyGuildOrDmId, Evergreen.V288.Id.ThreadRoute ) (Evergreen.V288.Id.Id Evergreen.V288.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V288.Id.AnyGuildOrDmId, Evergreen.V288.Id.ThreadRoute ) (Evergreen.V288.Id.Id Evergreen.V288.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V288.Id.AnyGuildOrDmId, Evergreen.V288.Id.ThreadRoute )
        { fileId : Evergreen.V288.Id.Id Evergreen.V288.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V288.Id.AnyGuildOrDmId, Evergreen.V288.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V288.Id.AnyGuildOrDmId, Evergreen.V288.Id.ThreadRoute ) (Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelMessageId) (Evergreen.V288.Id.Id Evergreen.V288.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V288.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V288.Id.AnyGuildOrDmId, Evergreen.V288.Id.ThreadRoute ) (Evergreen.V288.Id.Id Evergreen.V288.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V288.Id.AnyGuildOrDmId Evergreen.V288.Id.ThreadRouteWithMessage Evergreen.V288.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V288.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V288.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V288.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V288.Id.Id Evergreen.V288.Id.GuildId) Evergreen.V288.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId) (Evergreen.V288.Discord.Id Evergreen.V288.Discord.GuildId) Evergreen.V288.User.NotificationLevel
    | GotStartupData Evergreen.V288.Ports.StartupData
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V288.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId
        , otherUserId : Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V288.Id.AnyGuildOrDmId Evergreen.V288.Id.ThreadRoute Evergreen.V288.MessageInput.Msg
    | MessageInputMsg Evergreen.V288.Id.AnyGuildOrDmId Evergreen.V288.Id.ThreadRoute Evergreen.V288.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V288.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V288.Range.Range, Evergreen.V288.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V288.Range.Range, Evergreen.V288.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V288.Call.FromJs)
    | VoiceChatMsg Evergreen.V288.Call.Msg
    | PressedChannelHeaderTab Evergreen.V288.Route.DmChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadServiceWorkerData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V288.Drawing.Msg


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V288.Id.Id Evergreen.V288.Id.GuildId) (Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelId) Evergreen.V288.Id.ThreadRoute
    | InitialLoadRequested_Dm Evergreen.V288.DmChannel.DmChannelId Evergreen.V288.Id.ThreadRoute
    | InitialLoadRequested_Discord Evergreen.V288.Id.DiscordGuildOrDmId Evergreen.V288.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V288.Id.Id Evergreen.V288.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V288.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V288.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V288.Untrusted.Untrusted Evergreen.V288.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V288.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V288.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V288.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V288.Id.Id Evergreen.V288.Id.GuildId) (Evergreen.V288.SecretId.SecretId Evergreen.V288.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V288.PersonName.PersonName Evergreen.V288.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V288.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V288.Slack.OAuthCode Evergreen.V288.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V288.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V288.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V288.Id.Id Evergreen.V288.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V288.SecretId.SecretId Evergreen.V288.Id.GoMatchPublicId)


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V288.Discord.Id Evergreen.V288.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V288.Discord.Id Evergreen.V288.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V288.EmailAddress.EmailAddress (Result Evergreen.V288.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V288.EmailAddress.EmailAddress (Result Evergreen.V288.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V288.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V288.Discord.Id Evergreen.V288.Discord.GuildId) (Evergreen.V288.Discord.Id Evergreen.V288.Discord.ChannelId) Evergreen.V288.Id.ThreadRouteWithMaybeMessage (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId) (Result Evergreen.V288.Discord.HttpError Evergreen.V288.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V288.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V288.Discord.Id Evergreen.V288.Discord.PrivateChannelId) (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId) (Result Evergreen.V288.Discord.HttpError Evergreen.V288.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V288.Discord.Id Evergreen.V288.Discord.GuildId) (Evergreen.V288.Discord.Id Evergreen.V288.Discord.ChannelId) Evergreen.V288.Id.ThreadRouteWithMessage (Evergreen.V288.Discord.Id Evergreen.V288.Discord.MessageId) (Result Evergreen.V288.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V288.Discord.Id Evergreen.V288.Discord.PrivateChannelId) (Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelMessageId) (Evergreen.V288.Discord.Id Evergreen.V288.Discord.MessageId) (Result Evergreen.V288.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V288.Discord.Id Evergreen.V288.Discord.GuildId) (Evergreen.V288.Discord.Id Evergreen.V288.Discord.ChannelId) Evergreen.V288.Id.ThreadRouteWithMessage (Evergreen.V288.Discord.Id Evergreen.V288.Discord.MessageId) (Result Evergreen.V288.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V288.Discord.Id Evergreen.V288.Discord.PrivateChannelId) (Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelMessageId) (Evergreen.V288.Discord.Id Evergreen.V288.Discord.MessageId) (Result Evergreen.V288.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V288.Discord.Id Evergreen.V288.Discord.GuildId) (Evergreen.V288.Discord.Id Evergreen.V288.Discord.ChannelId) Evergreen.V288.Id.ThreadRouteWithMessage (Evergreen.V288.Discord.Id Evergreen.V288.Discord.MessageId) Evergreen.V288.Emoji.EmojiOrCustomEmoji (Result Evergreen.V288.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V288.Discord.Id Evergreen.V288.Discord.PrivateChannelId) (Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelMessageId) (Evergreen.V288.Discord.Id Evergreen.V288.Discord.MessageId) Evergreen.V288.Emoji.EmojiOrCustomEmoji (Result Evergreen.V288.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V288.Discord.Id Evergreen.V288.Discord.GuildId) (Evergreen.V288.Discord.Id Evergreen.V288.Discord.ChannelId) Evergreen.V288.Id.ThreadRouteWithMessage (Evergreen.V288.Discord.Id Evergreen.V288.Discord.MessageId) Evergreen.V288.Emoji.EmojiOrCustomEmoji (Result Evergreen.V288.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V288.Discord.Id Evergreen.V288.Discord.PrivateChannelId) (Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelMessageId) (Evergreen.V288.Discord.Id Evergreen.V288.Discord.MessageId) Evergreen.V288.Emoji.EmojiOrCustomEmoji (Result Evergreen.V288.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V288.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V288.Discord.HttpError (List ( Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId, Maybe Evergreen.V288.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId) Effect.Time.Posix Evergreen.V288.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V288.Slack.CurrentUser
            , team : Evergreen.V288.Slack.Team
            , users : List Evergreen.V288.Slack.User
            , channels : List ( Evergreen.V288.Slack.Channel, List Evergreen.V288.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId) (Result Effect.Http.Error Evergreen.V288.Slack.TokenResponse)
    | GotCloudflareSessionCreated Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V288.Local.ChangeId Effect.Time.Posix Evergreen.V288.Call.CallId Evergreen.V288.Cloudflare.Sdp (List String) (Result Effect.Http.Error Evergreen.V288.Cloudflare.RealtimeSessionId)
    | GotCloudflareSession Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V288.Local.ChangeId Effect.Time.Posix Evergreen.V288.Call.CallId Evergreen.V288.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V288.Cloudflare.PushTracksResult)
    | GotCloudflarePullOffer Effect.Time.Posix Effect.Lamdera.ClientId Evergreen.V288.Local.ChangeId Evergreen.V288.Call.ConnectionId Evergreen.V288.Cloudflare.RealtimeSessionId (List Evergreen.V288.Cloudflare.TrackName) (Result Effect.Http.Error Evergreen.V288.Cloudflare.PullTracksResult)
    | GotCloudflareRenegotiateAck Effect.Lamdera.ClientId Evergreen.V288.Local.ChangeId Evergreen.V288.Cloudflare.Sdp (Result Effect.Http.Error ())
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId) Evergreen.V288.Discord.UserAuth (Result Evergreen.V288.Discord.HttpError Evergreen.V288.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId) (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId) (Result Evergreen.V288.Discord.HttpError Evergreen.V288.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId)
        (Result
            Evergreen.V288.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V288.Discord.Id Evergreen.V288.Discord.PrivateChannelId
                , members : List (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId)
                }
            , List
                ( Evergreen.V288.Discord.Id Evergreen.V288.Discord.GuildId
                , { guild : Evergreen.V288.Discord.GatewayGuild
                  , channels : List Evergreen.V288.Discord.Channel
                  , icon : Maybe Evergreen.V288.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId) Bool Evergreen.V288.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V288.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V288.Discord.Id Evergreen.V288.Discord.AttachmentId, Evergreen.V288.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V288.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V288.Discord.Id Evergreen.V288.Discord.AttachmentId, Evergreen.V288.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId) (Evergreen.V288.Discord.Id Evergreen.V288.Discord.GuildId) (Evergreen.V288.Discord.Id Evergreen.V288.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V288.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V288.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId) (Evergreen.V288.Discord.Id Evergreen.V288.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V288.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V288.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId) (Evergreen.V288.Discord.Id Evergreen.V288.Discord.GuildId) (Evergreen.V288.Discord.Id Evergreen.V288.Discord.ChannelId) (Result Evergreen.V288.Discord.HttpError (List Evergreen.V288.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId) (Evergreen.V288.Discord.Id Evergreen.V288.Discord.PrivateChannelId) (Result Evergreen.V288.Discord.HttpError (List Evergreen.V288.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V288.Id.Id Evergreen.V288.Id.GuildId) (Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelId) Evergreen.V288.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V288.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V288.DmChannel.DmChannelId Evergreen.V288.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V288.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V288.Discord.Id Evergreen.V288.Discord.GuildId) (Evergreen.V288.Discord.Id Evergreen.V288.Discord.ChannelId) Evergreen.V288.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V288.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V288.Discord.Id Evergreen.V288.Discord.PrivateChannelId) (Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V288.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId)
        (Evergreen.V288.Discord.Id Evergreen.V288.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V288.Discord.HttpError
            { guild : Evergreen.V288.Discord.GatewayGuild
            , channels : List Evergreen.V288.Discord.Channel
            , icon : Maybe Evergreen.V288.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V288.Discord.Id Evergreen.V288.Discord.GuildId) (Result Evergreen.V288.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V288.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId) (List ( Evergreen.V288.Id.Id Evergreen.V288.Id.StickerId, Result Effect.Http.Error Evergreen.V288.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V288.Id.Id Evergreen.V288.Id.StickerId, Result Effect.Http.Error Evergreen.V288.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId) (List ( Evergreen.V288.Id.Id Evergreen.V288.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V288.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V288.Id.Id Evergreen.V288.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V288.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V288.Discord.HttpError (List Evergreen.V288.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V288.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V288.SecretId.SecretId Evergreen.V288.SecretId.ServerSecret))
    | GotTimeForWebsocketListenClose (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | GotCloudflareUsage Effect.Time.Posix (Result Effect.Http.Error Int)
    | GotCloudflareEgressForAdmin Effect.Lamdera.ClientId (Result Effect.Http.Error Int)
    | GotRustServerFileUpload Evergreen.V288.FileStatus.FileHash Int (Maybe (Evergreen.V288.Coord.Coord Evergreen.V288.CssPixels.CssPixels))
