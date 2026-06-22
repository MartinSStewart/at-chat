module Evergreen.V294.Types exposing (..)

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
import Evergreen.V294.AiChat
import Evergreen.V294.Call
import Evergreen.V294.ChannelDescription
import Evergreen.V294.ChannelName
import Evergreen.V294.Cloudflare
import Evergreen.V294.Coord
import Evergreen.V294.CssPixels
import Evergreen.V294.CustomEmoji
import Evergreen.V294.Discord
import Evergreen.V294.DiscordAttachmentId
import Evergreen.V294.DiscordUserData
import Evergreen.V294.DmChannel
import Evergreen.V294.Drawing
import Evergreen.V294.Editable
import Evergreen.V294.EmailAddress
import Evergreen.V294.Embed
import Evergreen.V294.Emoji
import Evergreen.V294.FileStatus
import Evergreen.V294.Go
import Evergreen.V294.GuildName
import Evergreen.V294.Id
import Evergreen.V294.ImageEditor
import Evergreen.V294.ImageViewer
import Evergreen.V294.LinkedAndOtherDiscordUsers
import Evergreen.V294.Local
import Evergreen.V294.LocalState
import Evergreen.V294.Log
import Evergreen.V294.LoginForm
import Evergreen.V294.MembersAndOwner
import Evergreen.V294.Message
import Evergreen.V294.MessageInput
import Evergreen.V294.MessageView
import Evergreen.V294.MyUi
import Evergreen.V294.NonemptyDict
import Evergreen.V294.NonemptySet
import Evergreen.V294.OneOrGreater
import Evergreen.V294.OneToOne
import Evergreen.V294.Pages.Admin
import Evergreen.V294.Pagination
import Evergreen.V294.PersonName
import Evergreen.V294.Ports
import Evergreen.V294.Postmark
import Evergreen.V294.Range
import Evergreen.V294.RichText
import Evergreen.V294.Route
import Evergreen.V294.SecretId
import Evergreen.V294.SessionIdHash
import Evergreen.V294.Slack
import Evergreen.V294.Sticker
import Evergreen.V294.TextEditor
import Evergreen.V294.ToBackendLog
import Evergreen.V294.Touch
import Evergreen.V294.TwoFactorAuthentication
import Evergreen.V294.Ui.Anim
import Evergreen.V294.Untrusted
import Evergreen.V294.User
import Evergreen.V294.UserAgent
import Evergreen.V294.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V294.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V294.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.Id.GuildId) Evergreen.V294.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId) Evergreen.V294.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V294.Discord.Id Evergreen.V294.Discord.PrivateChannelId) Evergreen.V294.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V294.Discord.Id Evergreen.V294.Discord.GuildId) Evergreen.V294.LocalState.DiscordFrontendGuild
    , user : Evergreen.V294.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId) Evergreen.V294.User.FrontendUser
    , discordUsers : Evergreen.V294.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V294.SessionIdHash.SessionIdHash Evergreen.V294.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V294.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.Id.StickerId) Evergreen.V294.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.Id.CustomEmojiId) Evergreen.V294.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V294.Call.CallId (Evergreen.V294.NonemptyDict.NonemptyDict ( Evergreen.V294.Id.Id Evergreen.V294.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V294.Call.RemoteCallData)
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type PublicGoMatch
    = PublicGoMatch_NotLoaded
    | PublicGoMatch_Loading
    | PublicGoMatch_Loaded Evergreen.V294.Go.PublicGoMatchData Evergreen.V294.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V294.Route.Route
    , windowSize : Evergreen.V294.Coord.Coord Evergreen.V294.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , timezone : Effect.Time.Zone
    , startupData : Maybe Evergreen.V294.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V294.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V294.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V294.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.FileStatus.FileId) Evergreen.V294.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V294.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V294.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.FileStatus.FileId) Evergreen.V294.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V294.Id.Id Evergreen.V294.Id.GuildId) Evergreen.V294.ChannelName.ChannelName Evergreen.V294.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V294.Id.Id Evergreen.V294.Id.GuildId) (Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelId) Evergreen.V294.ChannelName.ChannelName Evergreen.V294.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V294.Id.Id Evergreen.V294.Id.GuildId) (Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelId)
    | Local_DeleteGuild (Evergreen.V294.Id.Id Evergreen.V294.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V294.Id.Id Evergreen.V294.Id.GuildId) (Evergreen.V294.UserSession.ToBeFilledInByBackend (Evergreen.V294.SecretId.SecretId Evergreen.V294.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V294.Id.Id Evergreen.V294.Id.GuildId) (Evergreen.V294.SecretId.SecretId Evergreen.V294.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V294.GuildName.GuildName (Evergreen.V294.UserSession.ToBeFilledInByBackend (Evergreen.V294.Id.Id Evergreen.V294.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V294.Id.AnyGuildOrDmId, Evergreen.V294.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V294.Id.AnyGuildOrDmId Evergreen.V294.Id.ThreadRouteWithMessage Evergreen.V294.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V294.Id.AnyGuildOrDmId Evergreen.V294.Id.ThreadRouteWithMessage Evergreen.V294.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V294.Id.GuildOrDmId Evergreen.V294.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.FileStatus.FileId) Evergreen.V294.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId) (Evergreen.V294.Discord.Id Evergreen.V294.Discord.GuildId) (Evergreen.V294.Discord.Id Evergreen.V294.Discord.ChannelId) Evergreen.V294.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V294.Id.DiscordGuildOrDmId_DmData (Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V294.Id.AnyGuildOrDmId Evergreen.V294.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V294.Id.AnyGuildOrDmId Evergreen.V294.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V294.Id.AnyGuildOrDmId Evergreen.V294.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V294.UserSession.SetViewing
    | Local_SetName Evergreen.V294.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V294.Id.GuildOrDmId (Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelMessageId) (Evergreen.V294.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelMessageId) (Evergreen.V294.Message.Message Evergreen.V294.Id.ChannelMessageId (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V294.Id.GuildOrDmId (Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelMessageId) (Evergreen.V294.Id.Id Evergreen.V294.Id.ThreadMessageId) (Evergreen.V294.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.Id.ThreadMessageId) (Evergreen.V294.Message.Message Evergreen.V294.Id.ThreadMessageId (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V294.Id.DiscordGuildOrDmId (Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelMessageId) (Evergreen.V294.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelMessageId) (Evergreen.V294.Message.Message Evergreen.V294.Id.ChannelMessageId (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V294.Id.DiscordGuildOrDmId (Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelMessageId) (Evergreen.V294.Id.Id Evergreen.V294.Id.ThreadMessageId) (Evergreen.V294.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.Id.ThreadMessageId) (Evergreen.V294.Message.Message Evergreen.V294.Id.ThreadMessageId (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V294.Id.Id Evergreen.V294.Id.GuildId) Evergreen.V294.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId) (Evergreen.V294.Discord.Id Evergreen.V294.Discord.GuildId) Evergreen.V294.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V294.UserSession.NotificationMode
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V294.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V294.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V294.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V294.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V294.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V294.NonemptySet.NonemptySet (Evergreen.V294.Id.Id Evergreen.V294.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V294.Call.LocalChange
    | Local_Go
        { otherUserId : Evergreen.V294.Id.Id Evergreen.V294.Id.UserId
        }
        Evergreen.V294.Go.LocalChange
    | Local_Drawing Evergreen.V294.Id.AnyGuildOrDmId Evergreen.V294.Drawing.AnchorType Evergreen.V294.Drawing.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId) Effect.Time.Posix Evergreen.V294.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V294.RichText.RichText (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId))) Evergreen.V294.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.FileStatus.FileId) Evergreen.V294.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.Id.StickerId) Evergreen.V294.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V294.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V294.RichText.RichText (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId))) Evergreen.V294.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.FileStatus.FileId) Evergreen.V294.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.Id.StickerId) Evergreen.V294.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V294.Id.Id Evergreen.V294.Id.GuildId) Evergreen.V294.ChannelName.ChannelName Evergreen.V294.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V294.Id.Id Evergreen.V294.Id.GuildId) (Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelId) Evergreen.V294.ChannelName.ChannelName Evergreen.V294.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V294.Id.Id Evergreen.V294.Id.GuildId) (Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelId)
    | Server_DeleteGuild (Evergreen.V294.Id.Id Evergreen.V294.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId) (Evergreen.V294.Id.Id Evergreen.V294.Id.GuildId) (Evergreen.V294.SecretId.SecretId Evergreen.V294.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V294.Id.Id Evergreen.V294.Id.GuildId) (Evergreen.V294.SecretId.SecretId Evergreen.V294.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId) (Evergreen.V294.Id.Id Evergreen.V294.Id.GuildId) Evergreen.V294.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V294.LocalState.JoinGuildError
            { guildId : Evergreen.V294.Id.Id Evergreen.V294.Id.GuildId
            , guild : Evergreen.V294.LocalState.FrontendGuild
            , owner : Evergreen.V294.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId) Evergreen.V294.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId) Evergreen.V294.Id.GuildOrDmId Evergreen.V294.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId) (Evergreen.V294.Discord.Id Evergreen.V294.Discord.GuildId) (Evergreen.V294.Discord.Id Evergreen.V294.Discord.ChannelId) Evergreen.V294.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId) (Evergreen.V294.Discord.Id Evergreen.V294.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId) Evergreen.V294.Id.GuildOrDmId Evergreen.V294.Id.ThreadRouteWithMessage Evergreen.V294.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId) Evergreen.V294.Id.GuildOrDmId Evergreen.V294.Id.ThreadRouteWithMessage Evergreen.V294.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId) (Evergreen.V294.Discord.Id Evergreen.V294.Discord.GuildId) (Evergreen.V294.Discord.Id Evergreen.V294.Discord.ChannelId) Evergreen.V294.Id.ThreadRouteWithMessage Evergreen.V294.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId) (Evergreen.V294.Discord.Id Evergreen.V294.Discord.PrivateChannelId) (Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelMessageId) Evergreen.V294.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId) (Evergreen.V294.Discord.Id Evergreen.V294.Discord.GuildId) (Evergreen.V294.Discord.Id Evergreen.V294.Discord.ChannelId) Evergreen.V294.Id.ThreadRouteWithMessage Evergreen.V294.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId) (Evergreen.V294.Discord.Id Evergreen.V294.Discord.PrivateChannelId) (Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelMessageId) Evergreen.V294.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId) Evergreen.V294.Id.GuildOrDmId Evergreen.V294.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V294.RichText.RichText (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId))) (SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.FileStatus.FileId) Evergreen.V294.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId) (Evergreen.V294.Discord.Id Evergreen.V294.Discord.GuildId) (Evergreen.V294.Discord.Id Evergreen.V294.Discord.ChannelId) Evergreen.V294.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V294.RichText.RichText (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V294.Id.DiscordGuildOrDmId_DmData (Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V294.RichText.RichText (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId) Evergreen.V294.Id.AnyGuildOrDmId Evergreen.V294.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V294.Id.AnyGuildOrDmId Evergreen.V294.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V294.Discord.Id Evergreen.V294.Discord.GuildId) (Evergreen.V294.Discord.Id Evergreen.V294.Discord.ChannelId) Evergreen.V294.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V294.Discord.Id Evergreen.V294.Discord.PrivateChannelId) (Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId) Evergreen.V294.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId) Evergreen.V294.FileStatus.FileHash
    | Server_SetGuildIcon (Evergreen.V294.Id.Id Evergreen.V294.Id.GuildId) Evergreen.V294.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V294.Id.Id Evergreen.V294.Id.GuildId) Evergreen.V294.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V294.Discord.Id Evergreen.V294.Discord.GuildId) Evergreen.V294.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V294.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V294.SessionIdHash.SessionIdHash Evergreen.V294.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V294.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V294.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V294.Id.AnyGuildOrDmId, Evergreen.V294.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V294.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId) Evergreen.V294.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V294.Discord.Id Evergreen.V294.Discord.GuildId) (Evergreen.V294.Discord.Id Evergreen.V294.Discord.ChannelId) Evergreen.V294.ChannelName.ChannelName (Evergreen.V294.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V294.Discord.Id Evergreen.V294.Discord.PrivateChannelId)
        (Evergreen.V294.NonemptyDict.NonemptyDict
            (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V294.Discord.Id Evergreen.V294.Discord.GuildId) Evergreen.V294.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V294.Discord.Id Evergreen.V294.Discord.PrivateChannelId) Evergreen.V294.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId) Evergreen.V294.UserSession.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId) (Maybe (Evergreen.V294.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V294.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V294.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V294.Id.Id Evergreen.V294.Id.GuildId) (Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelId) Evergreen.V294.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V294.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId) Evergreen.V294.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V294.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V294.Discord.Id Evergreen.V294.Discord.GuildId) (Evergreen.V294.Discord.Id Evergreen.V294.Discord.ChannelId) Evergreen.V294.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V294.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V294.Discord.Id Evergreen.V294.Discord.PrivateChannelId) (Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V294.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V294.Discord.Id Evergreen.V294.Discord.GuildId) Evergreen.V294.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V294.Discord.Id Evergreen.V294.Discord.GuildId) (Evergreen.V294.Discord.Id Evergreen.V294.Discord.ChannelId) (Evergreen.V294.Discord.OptionalData String) (Evergreen.V294.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V294.Discord.Id Evergreen.V294.Discord.GuildId)
        (Evergreen.V294.MembersAndOwner.MembersAndOwner
            (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V294.Discord.Id Evergreen.V294.Discord.GuildId) (Evergreen.V294.Discord.Id Evergreen.V294.Discord.ChannelId) (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId) Evergreen.V294.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.Id.StickerId) Evergreen.V294.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.Id.CustomEmojiId) Evergreen.V294.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V294.Call.ServerChange
    | Server_Go
        (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId)
        { otherUserId : Evergreen.V294.Id.Id Evergreen.V294.Id.UserId
        }
        Evergreen.V294.Go.LocalChange
    | Server_Drawing (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId) Evergreen.V294.Id.AnyGuildOrDmId Evergreen.V294.Drawing.AnchorType Evergreen.V294.Drawing.LocalChange


type LocalMsg
    = LocalChange (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V294.Id.Id Evergreen.V294.Id.GuildId) (Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelId) Evergreen.V294.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V294.Discord.Id Evergreen.V294.Discord.GuildId) (Evergreen.V294.Discord.Id Evergreen.V294.Discord.ChannelId) Evergreen.V294.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.FileStatus.FileId) Evergreen.V294.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V294.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V294.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V294.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V294.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V294.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V294.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V294.Coord.Coord Evergreen.V294.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V294.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V294.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V294.Id.AnyGuildOrDmId Evergreen.V294.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V294.Id.AnyGuildOrDmId Evergreen.V294.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V294.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V294.Coord.Coord Evergreen.V294.CssPixels.CssPixels) (Maybe Evergreen.V294.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V294.Id.AnyGuildOrDmId, Evergreen.V294.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelMessageId) (Evergreen.V294.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.Id.ThreadMessageId) (Evergreen.V294.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V294.Editable.Model
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
    | FileDragging Effect.Time.Posix Evergreen.V294.OneOrGreater.OneOrGreater


type alias LoggedIn2 =
    { localState : Evergreen.V294.Local.Local LocalMsg Evergreen.V294.LocalState.LocalState
    , admin : Evergreen.V294.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V294.Id.AnyGuildOrDmId, Evergreen.V294.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V294.Id.Id Evergreen.V294.Id.GuildId, Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V294.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V294.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V294.Id.AnyGuildOrDmId, Evergreen.V294.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V294.Id.AnyGuildOrDmId, Evergreen.V294.Id.ThreadRoute ) (Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : Evergreen.V294.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V294.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V294.Id.AnyGuildOrDmId, Evergreen.V294.Id.ThreadRoute ) (Evergreen.V294.NonemptyDict.NonemptyDict (Evergreen.V294.Id.Id Evergreen.V294.FileStatus.FileId) Evergreen.V294.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V294.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V294.TextEditor.Model
    , profilePictureEditor : Evergreen.V294.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V294.Id.Id Evergreen.V294.Id.GuildId, Evergreen.V294.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V294.Emoji.Model
    , voiceChat : Evergreen.V294.Call.Model
    , currentDmGoMatch : SeqDict.SeqDict ( Evergreen.V294.Id.Id Evergreen.V294.Id.UserId, Maybe (Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelMessageId) ) Evergreen.V294.Go.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V294.Drawing.Model
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V294.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V294.SecretId.SecretId Evergreen.V294.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V294.Range.Range
                , direction : Evergreen.V294.Range.SelectionDirection
                }
        }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V294.NonemptyDict.NonemptyDict Int Evergreen.V294.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V294.NonemptyDict.NonemptyDict Int Evergreen.V294.Touch.Touch
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
    | AdminToFrontend Evergreen.V294.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V294.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V294.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V294.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V294.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V294.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V294.Go.PublicGoMatchResponse)


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V294.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V294.Coord.Coord Evergreen.V294.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V294.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V294.MyUi.LastCopy
    , notificationPermission : Evergreen.V294.Ports.NotificationPermission
    , pwaStatus : Evergreen.V294.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V294.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V294.UserAgent.UserAgent
    , timeOrigin : Effect.Time.Posix
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V294.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V294.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V294.Id.Id Evergreen.V294.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V294.Id.Id Evergreen.V294.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V294.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V294.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V294.Coord.Coord Evergreen.V294.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V294.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V294.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V294.Id.Id Evergreen.V294.Id.GuildId, Evergreen.V294.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V294.DmChannel.DmChannelId, Evergreen.V294.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V294.Discord.Id Evergreen.V294.Discord.GuildId, Evergreen.V294.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V294.Discord.Id Evergreen.V294.Discord.PrivateChannelId, Evergreen.V294.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V294.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V294.NonemptyDict.NonemptyDict (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId) Evergreen.V294.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V294.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V294.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V294.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V294.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId) Evergreen.V294.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId) Evergreen.V294.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V294.Id.Id Evergreen.V294.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.Id.GuildId) Evergreen.V294.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.Id.GuildId) Evergreen.V294.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V294.Discord.Id Evergreen.V294.Discord.GuildId) Evergreen.V294.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V294.DmChannel.DmChannelId Evergreen.V294.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V294.Discord.Id Evergreen.V294.Discord.PrivateChannelId) Evergreen.V294.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V294.OneToOne.OneToOne (Evergreen.V294.Slack.Id Evergreen.V294.Slack.ChannelId) Evergreen.V294.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V294.OneToOne.OneToOne String (Evergreen.V294.Id.Id Evergreen.V294.Id.GuildId)
    , slackUsers : Evergreen.V294.OneToOne.OneToOne (Evergreen.V294.Slack.Id Evergreen.V294.Slack.UserId) (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId)
    , slackServers : Evergreen.V294.OneToOne.OneToOne (Evergreen.V294.Slack.Id Evergreen.V294.Slack.TeamId) (Evergreen.V294.Id.Id Evergreen.V294.Id.GuildId)
    , slackToken : Maybe Evergreen.V294.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V294.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V294.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V294.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V294.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V294.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V294.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V294.Cloudflare.AnalyticsApiToken
    , textEditor : Evergreen.V294.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId) Evergreen.V294.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId, Evergreen.V294.Discord.Id Evergreen.V294.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V294.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V294.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V294.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V294.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId) (Evergreen.V294.LocalState.LoadingDiscordChannel (List Evergreen.V294.Discord.Message))
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V294.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.Id.StickerId) Evergreen.V294.Sticker.StickerData
    , discordStickers : Evergreen.V294.OneToOne.OneToOne (Evergreen.V294.Discord.Id Evergreen.V294.Discord.StickerId) (Evergreen.V294.Id.Id Evergreen.V294.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.Id.CustomEmojiId) Evergreen.V294.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V294.OneToOne.OneToOne Evergreen.V294.RichText.DiscordCustomEmojiIdAndName (Evergreen.V294.Id.Id Evergreen.V294.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V294.Postmark.ApiKey
    , serverSecret : Evergreen.V294.SecretId.SecretId Evergreen.V294.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V294.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V294.OneToOne.OneToOne (Evergreen.V294.SecretId.SecretId Evergreen.V294.Id.GoMatchPublicId) ( Evergreen.V294.DmChannel.DmChannelId, Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelMessageId )
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V294.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V294.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V294.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V294.Route.Route
    | SelectedFilesToAttach ( Evergreen.V294.Id.AnyGuildOrDmId, Evergreen.V294.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V294.Id.Id Evergreen.V294.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V294.Id.Id Evergreen.V294.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V294.Id.Id Evergreen.V294.Id.GuildId) (Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelId) Evergreen.V294.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V294.Id.Id Evergreen.V294.Id.GuildId) (Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelId) Evergreen.V294.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V294.Discord.Id Evergreen.V294.Discord.GuildId) (Evergreen.V294.Discord.Id Evergreen.V294.Discord.ChannelId) Evergreen.V294.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V294.Discord.Id Evergreen.V294.Discord.GuildId) (Evergreen.V294.Discord.Id Evergreen.V294.Discord.ChannelId) Evergreen.V294.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V294.Id.Id Evergreen.V294.Id.GuildId) (Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V294.Id.Id Evergreen.V294.Id.GuildId) (Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V294.Id.Id Evergreen.V294.Id.GuildId) (Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V294.Id.Id Evergreen.V294.Id.GuildId) (Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V294.Id.Id Evergreen.V294.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V294.Id.Id Evergreen.V294.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V294.Id.Id Evergreen.V294.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V294.Id.Id Evergreen.V294.Id.GuildId) (Evergreen.V294.SecretId.SecretId Evergreen.V294.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V294.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V294.Id.AnyGuildOrDmId Evergreen.V294.Id.ThreadRouteWithMessage (Evergreen.V294.Coord.Coord Evergreen.V294.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V294.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V294.Id.AnyGuildOrDmId Evergreen.V294.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V294.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V294.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V294.Id.AnyGuildOrDmId, Evergreen.V294.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V294.Ports.NotificationPermission
    | TouchStart (Maybe ( Evergreen.V294.Id.AnyGuildOrDmId, Evergreen.V294.Id.ThreadRouteWithMessage, Bool )) Duration.Duration (Evergreen.V294.NonemptyDict.NonemptyDict Int Evergreen.V294.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V294.NonemptyDict.NonemptyDict Int Evergreen.V294.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V294.Id.AnyGuildOrDmId Evergreen.V294.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V294.Id.AnyGuildOrDmId Evergreen.V294.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V294.NonemptySet.NonemptySet (Evergreen.V294.Id.Id Evergreen.V294.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V294.Id.AnyGuildOrDmId, Evergreen.V294.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V294.Id.AnyGuildOrDmId Evergreen.V294.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V294.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V294.AiChat.Msg
    | GoMsg Evergreen.V294.Go.Msg
    | GoSpectatorMsg Evergreen.V294.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V294.Editable.Msg Evergreen.V294.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V294.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V294.Id.Id Evergreen.V294.Id.GuildId) Evergreen.V294.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V294.Id.AnyGuildOrDmId, Evergreen.V294.Id.ThreadRoute ) (Evergreen.V294.Id.Id Evergreen.V294.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V294.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V294.Id.AnyGuildOrDmId, Evergreen.V294.Id.ThreadRoute ) (Evergreen.V294.Id.Id Evergreen.V294.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V294.Id.AnyGuildOrDmId, Evergreen.V294.Id.ThreadRoute ) (Evergreen.V294.Id.Id Evergreen.V294.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V294.Id.AnyGuildOrDmId, Evergreen.V294.Id.ThreadRoute )
        { fileId : Evergreen.V294.Id.Id Evergreen.V294.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V294.Id.AnyGuildOrDmId, Evergreen.V294.Id.ThreadRoute ) (Evergreen.V294.Id.Id Evergreen.V294.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V294.Id.AnyGuildOrDmId, Evergreen.V294.Id.ThreadRoute ) (Evergreen.V294.Id.Id Evergreen.V294.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V294.Id.AnyGuildOrDmId, Evergreen.V294.Id.ThreadRoute )
        { fileId : Evergreen.V294.Id.Id Evergreen.V294.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V294.Id.AnyGuildOrDmId, Evergreen.V294.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V294.Id.AnyGuildOrDmId, Evergreen.V294.Id.ThreadRoute ) (Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelMessageId) (Evergreen.V294.Id.Id Evergreen.V294.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V294.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V294.Id.AnyGuildOrDmId, Evergreen.V294.Id.ThreadRoute ) (Evergreen.V294.Id.Id Evergreen.V294.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V294.Id.AnyGuildOrDmId Evergreen.V294.Id.ThreadRouteWithMessage Evergreen.V294.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V294.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V294.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V294.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V294.Id.Id Evergreen.V294.Id.GuildId) Evergreen.V294.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId) (Evergreen.V294.Discord.Id Evergreen.V294.Discord.GuildId) Evergreen.V294.User.NotificationLevel
    | GotStartupData Evergreen.V294.Ports.StartupData
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V294.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId
        , otherUserId : Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V294.Id.AnyGuildOrDmId Evergreen.V294.Id.ThreadRoute Evergreen.V294.MessageInput.Msg
    | MessageInputMsg Evergreen.V294.Id.AnyGuildOrDmId Evergreen.V294.Id.ThreadRoute Evergreen.V294.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V294.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V294.Range.Range, Evergreen.V294.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V294.Range.Range, Evergreen.V294.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V294.Call.FromJs)
    | VoiceChatMsg Evergreen.V294.Call.Msg
    | PressedChannelHeaderTab Evergreen.V294.Route.DmChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadServiceWorkerData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V294.Drawing.Msg


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V294.Id.Id Evergreen.V294.Id.GuildId) (Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelId) Evergreen.V294.Id.ThreadRoute
    | InitialLoadRequested_Dm Evergreen.V294.DmChannel.DmChannelId Evergreen.V294.Id.ThreadRoute
    | InitialLoadRequested_Discord Evergreen.V294.Id.DiscordGuildOrDmId Evergreen.V294.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V294.Id.Id Evergreen.V294.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V294.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V294.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V294.Untrusted.Untrusted Evergreen.V294.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V294.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V294.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V294.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V294.Id.Id Evergreen.V294.Id.GuildId) (Evergreen.V294.SecretId.SecretId Evergreen.V294.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V294.PersonName.PersonName Evergreen.V294.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V294.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V294.Slack.OAuthCode Evergreen.V294.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V294.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V294.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V294.Id.Id Evergreen.V294.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V294.SecretId.SecretId Evergreen.V294.Id.GoMatchPublicId)


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V294.Discord.Id Evergreen.V294.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V294.Discord.Id Evergreen.V294.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V294.EmailAddress.EmailAddress (Result Evergreen.V294.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V294.EmailAddress.EmailAddress (Result Evergreen.V294.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V294.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V294.Discord.Id Evergreen.V294.Discord.GuildId) (Evergreen.V294.Discord.Id Evergreen.V294.Discord.ChannelId) Evergreen.V294.Id.ThreadRouteWithMaybeMessage (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId) (Result Evergreen.V294.Discord.HttpError Evergreen.V294.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V294.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V294.Discord.Id Evergreen.V294.Discord.PrivateChannelId) (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId) (Result Evergreen.V294.Discord.HttpError Evergreen.V294.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V294.Discord.Id Evergreen.V294.Discord.GuildId) (Evergreen.V294.Discord.Id Evergreen.V294.Discord.ChannelId) Evergreen.V294.Id.ThreadRouteWithMessage (Evergreen.V294.Discord.Id Evergreen.V294.Discord.MessageId) (Result Evergreen.V294.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V294.Discord.Id Evergreen.V294.Discord.PrivateChannelId) (Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelMessageId) (Evergreen.V294.Discord.Id Evergreen.V294.Discord.MessageId) (Result Evergreen.V294.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V294.Discord.Id Evergreen.V294.Discord.GuildId) (Evergreen.V294.Discord.Id Evergreen.V294.Discord.ChannelId) Evergreen.V294.Id.ThreadRouteWithMessage (Evergreen.V294.Discord.Id Evergreen.V294.Discord.MessageId) (Result Evergreen.V294.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V294.Discord.Id Evergreen.V294.Discord.PrivateChannelId) (Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelMessageId) (Evergreen.V294.Discord.Id Evergreen.V294.Discord.MessageId) (Result Evergreen.V294.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V294.Discord.Id Evergreen.V294.Discord.GuildId) (Evergreen.V294.Discord.Id Evergreen.V294.Discord.ChannelId) Evergreen.V294.Id.ThreadRouteWithMessage (Evergreen.V294.Discord.Id Evergreen.V294.Discord.MessageId) Evergreen.V294.Emoji.EmojiOrCustomEmoji (Result Evergreen.V294.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V294.Discord.Id Evergreen.V294.Discord.PrivateChannelId) (Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelMessageId) (Evergreen.V294.Discord.Id Evergreen.V294.Discord.MessageId) Evergreen.V294.Emoji.EmojiOrCustomEmoji (Result Evergreen.V294.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V294.Discord.Id Evergreen.V294.Discord.GuildId) (Evergreen.V294.Discord.Id Evergreen.V294.Discord.ChannelId) Evergreen.V294.Id.ThreadRouteWithMessage (Evergreen.V294.Discord.Id Evergreen.V294.Discord.MessageId) Evergreen.V294.Emoji.EmojiOrCustomEmoji (Result Evergreen.V294.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V294.Discord.Id Evergreen.V294.Discord.PrivateChannelId) (Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelMessageId) (Evergreen.V294.Discord.Id Evergreen.V294.Discord.MessageId) Evergreen.V294.Emoji.EmojiOrCustomEmoji (Result Evergreen.V294.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V294.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V294.Discord.HttpError (List ( Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId, Maybe Evergreen.V294.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId) Effect.Time.Posix Evergreen.V294.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V294.Slack.CurrentUser
            , team : Evergreen.V294.Slack.Team
            , users : List Evergreen.V294.Slack.User
            , channels : List ( Evergreen.V294.Slack.Channel, List Evergreen.V294.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId) (Result Effect.Http.Error Evergreen.V294.Slack.TokenResponse)
    | GotCloudflareSessionCreated Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V294.Local.ChangeId Effect.Time.Posix Evergreen.V294.Call.CallId Evergreen.V294.Cloudflare.Sdp (List String) (Result Effect.Http.Error Evergreen.V294.Cloudflare.RealtimeSessionId)
    | GotCloudflareSession Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V294.Local.ChangeId Effect.Time.Posix Evergreen.V294.Call.CallId Evergreen.V294.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V294.Cloudflare.PushTracksResult)
    | GotCloudflarePullOffer Effect.Time.Posix Effect.Lamdera.ClientId Evergreen.V294.Local.ChangeId Evergreen.V294.Call.ConnectionId Evergreen.V294.Cloudflare.RealtimeSessionId (List Evergreen.V294.Cloudflare.TrackName) (Result Effect.Http.Error Evergreen.V294.Cloudflare.PullTracksResult)
    | GotCloudflareRenegotiateAck Effect.Lamdera.ClientId Evergreen.V294.Local.ChangeId Evergreen.V294.Cloudflare.Sdp (Result Effect.Http.Error ())
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId) Evergreen.V294.Discord.UserAuth (Result Evergreen.V294.Discord.HttpError Evergreen.V294.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId) (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId) (Result Evergreen.V294.Discord.HttpError Evergreen.V294.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId)
        (Result
            Evergreen.V294.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V294.Discord.Id Evergreen.V294.Discord.PrivateChannelId
                , members : List (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId)
                }
            , List
                ( Evergreen.V294.Discord.Id Evergreen.V294.Discord.GuildId
                , { guild : Evergreen.V294.Discord.GatewayGuild
                  , channels : List Evergreen.V294.Discord.Channel
                  , icon : Maybe Evergreen.V294.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId) Bool Evergreen.V294.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V294.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V294.Discord.Id Evergreen.V294.Discord.AttachmentId, Evergreen.V294.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V294.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V294.Discord.Id Evergreen.V294.Discord.AttachmentId, Evergreen.V294.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId) (Evergreen.V294.Discord.Id Evergreen.V294.Discord.GuildId) (Evergreen.V294.Discord.Id Evergreen.V294.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V294.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V294.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId) (Evergreen.V294.Discord.Id Evergreen.V294.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V294.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V294.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId) (Evergreen.V294.Discord.Id Evergreen.V294.Discord.GuildId) (Evergreen.V294.Discord.Id Evergreen.V294.Discord.ChannelId) (Result Evergreen.V294.Discord.HttpError (List Evergreen.V294.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId) (Evergreen.V294.Discord.Id Evergreen.V294.Discord.PrivateChannelId) (Result Evergreen.V294.Discord.HttpError (List Evergreen.V294.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V294.Id.Id Evergreen.V294.Id.GuildId) (Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelId) Evergreen.V294.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V294.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V294.DmChannel.DmChannelId Evergreen.V294.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V294.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V294.Discord.Id Evergreen.V294.Discord.GuildId) (Evergreen.V294.Discord.Id Evergreen.V294.Discord.ChannelId) Evergreen.V294.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V294.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V294.Discord.Id Evergreen.V294.Discord.PrivateChannelId) (Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V294.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId)
        (Evergreen.V294.Discord.Id Evergreen.V294.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V294.Discord.HttpError
            { guild : Evergreen.V294.Discord.GatewayGuild
            , channels : List Evergreen.V294.Discord.Channel
            , icon : Maybe Evergreen.V294.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V294.Discord.Id Evergreen.V294.Discord.GuildId) (Result Evergreen.V294.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V294.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId) (List ( Evergreen.V294.Id.Id Evergreen.V294.Id.StickerId, Result Effect.Http.Error Evergreen.V294.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V294.Id.Id Evergreen.V294.Id.StickerId, Result Effect.Http.Error Evergreen.V294.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId) (List ( Evergreen.V294.Id.Id Evergreen.V294.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V294.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V294.Id.Id Evergreen.V294.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V294.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V294.Discord.HttpError (List Evergreen.V294.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V294.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V294.SecretId.SecretId Evergreen.V294.SecretId.ServerSecret))
    | GotTimeForWebsocketListenClose (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | GotCloudflareUsage Effect.Time.Posix (Result Effect.Http.Error Int)
    | GotCloudflareEgressForAdmin Effect.Lamdera.ClientId (Result Effect.Http.Error Int)
    | GotRustServerFileUpload Evergreen.V294.FileStatus.FileHash Int (Maybe (Evergreen.V294.Coord.Coord Evergreen.V294.CssPixels.CssPixels))
