module Evergreen.V290.Types exposing (..)

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
import Evergreen.V290.AiChat
import Evergreen.V290.Call
import Evergreen.V290.ChannelDescription
import Evergreen.V290.ChannelName
import Evergreen.V290.Cloudflare
import Evergreen.V290.Coord
import Evergreen.V290.CssPixels
import Evergreen.V290.CustomEmoji
import Evergreen.V290.Discord
import Evergreen.V290.DiscordAttachmentId
import Evergreen.V290.DiscordUserData
import Evergreen.V290.DmChannel
import Evergreen.V290.Drawing
import Evergreen.V290.Editable
import Evergreen.V290.EmailAddress
import Evergreen.V290.Embed
import Evergreen.V290.Emoji
import Evergreen.V290.FileStatus
import Evergreen.V290.Go
import Evergreen.V290.GuildName
import Evergreen.V290.Id
import Evergreen.V290.ImageEditor
import Evergreen.V290.ImageViewer
import Evergreen.V290.LinkedAndOtherDiscordUsers
import Evergreen.V290.Local
import Evergreen.V290.LocalState
import Evergreen.V290.Log
import Evergreen.V290.LoginForm
import Evergreen.V290.MembersAndOwner
import Evergreen.V290.Message
import Evergreen.V290.MessageInput
import Evergreen.V290.MessageView
import Evergreen.V290.MyUi
import Evergreen.V290.NonemptyDict
import Evergreen.V290.NonemptySet
import Evergreen.V290.OneOrGreater
import Evergreen.V290.OneToOne
import Evergreen.V290.Pages.Admin
import Evergreen.V290.Pagination
import Evergreen.V290.PersonName
import Evergreen.V290.Ports
import Evergreen.V290.Postmark
import Evergreen.V290.Range
import Evergreen.V290.RichText
import Evergreen.V290.Route
import Evergreen.V290.SecretId
import Evergreen.V290.SessionIdHash
import Evergreen.V290.Slack
import Evergreen.V290.Sticker
import Evergreen.V290.TextEditor
import Evergreen.V290.ToBackendLog
import Evergreen.V290.Touch
import Evergreen.V290.TwoFactorAuthentication
import Evergreen.V290.Ui.Anim
import Evergreen.V290.Untrusted
import Evergreen.V290.User
import Evergreen.V290.UserAgent
import Evergreen.V290.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V290.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V290.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.Id.GuildId) Evergreen.V290.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId) Evergreen.V290.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V290.Discord.Id Evergreen.V290.Discord.PrivateChannelId) Evergreen.V290.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V290.Discord.Id Evergreen.V290.Discord.GuildId) Evergreen.V290.LocalState.DiscordFrontendGuild
    , user : Evergreen.V290.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId) Evergreen.V290.User.FrontendUser
    , discordUsers : Evergreen.V290.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V290.SessionIdHash.SessionIdHash Evergreen.V290.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V290.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.Id.StickerId) Evergreen.V290.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.Id.CustomEmojiId) Evergreen.V290.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V290.Call.CallId (Evergreen.V290.NonemptyDict.NonemptyDict ( Evergreen.V290.Id.Id Evergreen.V290.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V290.Call.RemoteCallData)
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type PublicGoMatch
    = PublicGoMatch_NotLoaded
    | PublicGoMatch_Loading
    | PublicGoMatch_Loaded Evergreen.V290.Go.PublicGoMatchData Evergreen.V290.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V290.Route.Route
    , windowSize : Evergreen.V290.Coord.Coord Evergreen.V290.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , timezone : Effect.Time.Zone
    , startupData : Maybe Evergreen.V290.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V290.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V290.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V290.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.FileStatus.FileId) Evergreen.V290.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V290.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V290.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.FileStatus.FileId) Evergreen.V290.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V290.Id.Id Evergreen.V290.Id.GuildId) Evergreen.V290.ChannelName.ChannelName Evergreen.V290.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V290.Id.Id Evergreen.V290.Id.GuildId) (Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelId) Evergreen.V290.ChannelName.ChannelName Evergreen.V290.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V290.Id.Id Evergreen.V290.Id.GuildId) (Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelId)
    | Local_DeleteGuild (Evergreen.V290.Id.Id Evergreen.V290.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V290.Id.Id Evergreen.V290.Id.GuildId) (Evergreen.V290.UserSession.ToBeFilledInByBackend (Evergreen.V290.SecretId.SecretId Evergreen.V290.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V290.Id.Id Evergreen.V290.Id.GuildId) (Evergreen.V290.SecretId.SecretId Evergreen.V290.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V290.GuildName.GuildName (Evergreen.V290.UserSession.ToBeFilledInByBackend (Evergreen.V290.Id.Id Evergreen.V290.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V290.Id.AnyGuildOrDmId, Evergreen.V290.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V290.Id.AnyGuildOrDmId Evergreen.V290.Id.ThreadRouteWithMessage Evergreen.V290.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V290.Id.AnyGuildOrDmId Evergreen.V290.Id.ThreadRouteWithMessage Evergreen.V290.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V290.Id.GuildOrDmId Evergreen.V290.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.FileStatus.FileId) Evergreen.V290.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId) (Evergreen.V290.Discord.Id Evergreen.V290.Discord.GuildId) (Evergreen.V290.Discord.Id Evergreen.V290.Discord.ChannelId) Evergreen.V290.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V290.Id.DiscordGuildOrDmId_DmData (Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V290.Id.AnyGuildOrDmId Evergreen.V290.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V290.Id.AnyGuildOrDmId Evergreen.V290.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V290.Id.AnyGuildOrDmId Evergreen.V290.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V290.UserSession.SetViewing
    | Local_SetName Evergreen.V290.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V290.Id.GuildOrDmId (Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelMessageId) (Evergreen.V290.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelMessageId) (Evergreen.V290.Message.Message Evergreen.V290.Id.ChannelMessageId (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V290.Id.GuildOrDmId (Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelMessageId) (Evergreen.V290.Id.Id Evergreen.V290.Id.ThreadMessageId) (Evergreen.V290.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.Id.ThreadMessageId) (Evergreen.V290.Message.Message Evergreen.V290.Id.ThreadMessageId (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V290.Id.DiscordGuildOrDmId (Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelMessageId) (Evergreen.V290.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelMessageId) (Evergreen.V290.Message.Message Evergreen.V290.Id.ChannelMessageId (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V290.Id.DiscordGuildOrDmId (Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelMessageId) (Evergreen.V290.Id.Id Evergreen.V290.Id.ThreadMessageId) (Evergreen.V290.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.Id.ThreadMessageId) (Evergreen.V290.Message.Message Evergreen.V290.Id.ThreadMessageId (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V290.Id.Id Evergreen.V290.Id.GuildId) Evergreen.V290.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId) (Evergreen.V290.Discord.Id Evergreen.V290.Discord.GuildId) Evergreen.V290.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V290.UserSession.NotificationMode
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V290.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V290.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V290.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V290.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V290.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V290.NonemptySet.NonemptySet (Evergreen.V290.Id.Id Evergreen.V290.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V290.Call.LocalChange
    | Local_Go
        { otherUserId : Evergreen.V290.Id.Id Evergreen.V290.Id.UserId
        }
        Evergreen.V290.Go.LocalChange
    | Local_Drawing Evergreen.V290.Id.AnyGuildOrDmId Evergreen.V290.Drawing.AnchorType Evergreen.V290.Drawing.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId) Effect.Time.Posix Evergreen.V290.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V290.RichText.RichText (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId))) Evergreen.V290.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.FileStatus.FileId) Evergreen.V290.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.Id.StickerId) Evergreen.V290.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V290.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V290.RichText.RichText (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId))) Evergreen.V290.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.FileStatus.FileId) Evergreen.V290.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.Id.StickerId) Evergreen.V290.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V290.Id.Id Evergreen.V290.Id.GuildId) Evergreen.V290.ChannelName.ChannelName Evergreen.V290.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V290.Id.Id Evergreen.V290.Id.GuildId) (Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelId) Evergreen.V290.ChannelName.ChannelName Evergreen.V290.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V290.Id.Id Evergreen.V290.Id.GuildId) (Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelId)
    | Server_DeleteGuild (Evergreen.V290.Id.Id Evergreen.V290.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId) (Evergreen.V290.Id.Id Evergreen.V290.Id.GuildId) (Evergreen.V290.SecretId.SecretId Evergreen.V290.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V290.Id.Id Evergreen.V290.Id.GuildId) (Evergreen.V290.SecretId.SecretId Evergreen.V290.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId) (Evergreen.V290.Id.Id Evergreen.V290.Id.GuildId) Evergreen.V290.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V290.LocalState.JoinGuildError
            { guildId : Evergreen.V290.Id.Id Evergreen.V290.Id.GuildId
            , guild : Evergreen.V290.LocalState.FrontendGuild
            , owner : Evergreen.V290.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId) Evergreen.V290.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId) Evergreen.V290.Id.GuildOrDmId Evergreen.V290.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId) (Evergreen.V290.Discord.Id Evergreen.V290.Discord.GuildId) (Evergreen.V290.Discord.Id Evergreen.V290.Discord.ChannelId) Evergreen.V290.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId) (Evergreen.V290.Discord.Id Evergreen.V290.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId) Evergreen.V290.Id.GuildOrDmId Evergreen.V290.Id.ThreadRouteWithMessage Evergreen.V290.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId) Evergreen.V290.Id.GuildOrDmId Evergreen.V290.Id.ThreadRouteWithMessage Evergreen.V290.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId) (Evergreen.V290.Discord.Id Evergreen.V290.Discord.GuildId) (Evergreen.V290.Discord.Id Evergreen.V290.Discord.ChannelId) Evergreen.V290.Id.ThreadRouteWithMessage Evergreen.V290.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId) (Evergreen.V290.Discord.Id Evergreen.V290.Discord.PrivateChannelId) (Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelMessageId) Evergreen.V290.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId) (Evergreen.V290.Discord.Id Evergreen.V290.Discord.GuildId) (Evergreen.V290.Discord.Id Evergreen.V290.Discord.ChannelId) Evergreen.V290.Id.ThreadRouteWithMessage Evergreen.V290.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId) (Evergreen.V290.Discord.Id Evergreen.V290.Discord.PrivateChannelId) (Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelMessageId) Evergreen.V290.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId) Evergreen.V290.Id.GuildOrDmId Evergreen.V290.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V290.RichText.RichText (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId))) (SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.FileStatus.FileId) Evergreen.V290.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId) (Evergreen.V290.Discord.Id Evergreen.V290.Discord.GuildId) (Evergreen.V290.Discord.Id Evergreen.V290.Discord.ChannelId) Evergreen.V290.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V290.RichText.RichText (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V290.Id.DiscordGuildOrDmId_DmData (Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V290.RichText.RichText (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId) Evergreen.V290.Id.AnyGuildOrDmId Evergreen.V290.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V290.Id.AnyGuildOrDmId Evergreen.V290.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V290.Discord.Id Evergreen.V290.Discord.GuildId) (Evergreen.V290.Discord.Id Evergreen.V290.Discord.ChannelId) Evergreen.V290.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V290.Discord.Id Evergreen.V290.Discord.PrivateChannelId) (Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId) Evergreen.V290.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId) Evergreen.V290.FileStatus.FileHash
    | Server_SetGuildIcon (Evergreen.V290.Id.Id Evergreen.V290.Id.GuildId) Evergreen.V290.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V290.Id.Id Evergreen.V290.Id.GuildId) Evergreen.V290.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V290.Discord.Id Evergreen.V290.Discord.GuildId) Evergreen.V290.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V290.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V290.SessionIdHash.SessionIdHash Evergreen.V290.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V290.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V290.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V290.Id.AnyGuildOrDmId, Evergreen.V290.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V290.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId) Evergreen.V290.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V290.Discord.Id Evergreen.V290.Discord.GuildId) (Evergreen.V290.Discord.Id Evergreen.V290.Discord.ChannelId) Evergreen.V290.ChannelName.ChannelName (Evergreen.V290.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V290.Discord.Id Evergreen.V290.Discord.PrivateChannelId)
        (Evergreen.V290.NonemptyDict.NonemptyDict
            (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V290.Discord.Id Evergreen.V290.Discord.GuildId) Evergreen.V290.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V290.Discord.Id Evergreen.V290.Discord.PrivateChannelId) Evergreen.V290.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId) Evergreen.V290.UserSession.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId) (Maybe (Evergreen.V290.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V290.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V290.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V290.Id.Id Evergreen.V290.Id.GuildId) (Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelId) Evergreen.V290.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V290.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId) Evergreen.V290.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V290.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V290.Discord.Id Evergreen.V290.Discord.GuildId) (Evergreen.V290.Discord.Id Evergreen.V290.Discord.ChannelId) Evergreen.V290.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V290.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V290.Discord.Id Evergreen.V290.Discord.PrivateChannelId) (Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V290.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V290.Discord.Id Evergreen.V290.Discord.GuildId) Evergreen.V290.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V290.Discord.Id Evergreen.V290.Discord.GuildId) (Evergreen.V290.Discord.Id Evergreen.V290.Discord.ChannelId) (Evergreen.V290.Discord.OptionalData String) (Evergreen.V290.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V290.Discord.Id Evergreen.V290.Discord.GuildId)
        (Evergreen.V290.MembersAndOwner.MembersAndOwner
            (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V290.Discord.Id Evergreen.V290.Discord.GuildId) (Evergreen.V290.Discord.Id Evergreen.V290.Discord.ChannelId) (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId) Evergreen.V290.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.Id.StickerId) Evergreen.V290.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.Id.CustomEmojiId) Evergreen.V290.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V290.Call.ServerChange
    | Server_Go
        (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId)
        { otherUserId : Evergreen.V290.Id.Id Evergreen.V290.Id.UserId
        }
        Evergreen.V290.Go.LocalChange
    | Server_Drawing (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId) Evergreen.V290.Id.AnyGuildOrDmId Evergreen.V290.Drawing.AnchorType Evergreen.V290.Drawing.LocalChange


type LocalMsg
    = LocalChange (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V290.Id.Id Evergreen.V290.Id.GuildId) (Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelId) Evergreen.V290.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V290.Discord.Id Evergreen.V290.Discord.GuildId) (Evergreen.V290.Discord.Id Evergreen.V290.Discord.ChannelId) Evergreen.V290.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.FileStatus.FileId) Evergreen.V290.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V290.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V290.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V290.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V290.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V290.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V290.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V290.Coord.Coord Evergreen.V290.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V290.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V290.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V290.Id.AnyGuildOrDmId Evergreen.V290.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V290.Id.AnyGuildOrDmId Evergreen.V290.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V290.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V290.Coord.Coord Evergreen.V290.CssPixels.CssPixels) (Maybe Evergreen.V290.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V290.Id.AnyGuildOrDmId, Evergreen.V290.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelMessageId) (Evergreen.V290.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.Id.ThreadMessageId) (Evergreen.V290.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V290.Editable.Model
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
    | FileDragging Effect.Time.Posix Evergreen.V290.OneOrGreater.OneOrGreater


type alias LoggedIn2 =
    { localState : Evergreen.V290.Local.Local LocalMsg Evergreen.V290.LocalState.LocalState
    , admin : Evergreen.V290.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V290.Id.AnyGuildOrDmId, Evergreen.V290.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V290.Id.Id Evergreen.V290.Id.GuildId, Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V290.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V290.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V290.Id.AnyGuildOrDmId, Evergreen.V290.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V290.Id.AnyGuildOrDmId, Evergreen.V290.Id.ThreadRoute ) (Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : Evergreen.V290.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V290.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V290.Id.AnyGuildOrDmId, Evergreen.V290.Id.ThreadRoute ) (Evergreen.V290.NonemptyDict.NonemptyDict (Evergreen.V290.Id.Id Evergreen.V290.FileStatus.FileId) Evergreen.V290.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V290.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V290.TextEditor.Model
    , profilePictureEditor : Evergreen.V290.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V290.Id.Id Evergreen.V290.Id.GuildId, Evergreen.V290.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V290.Emoji.Model
    , voiceChat : Evergreen.V290.Call.Model
    , currentDmGoMatch : SeqDict.SeqDict ( Evergreen.V290.Id.Id Evergreen.V290.Id.UserId, Maybe (Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelMessageId) ) Evergreen.V290.Go.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V290.Drawing.Model
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V290.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V290.SecretId.SecretId Evergreen.V290.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V290.Range.Range
                , direction : Evergreen.V290.Range.SelectionDirection
                }
        }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V290.NonemptyDict.NonemptyDict Int Evergreen.V290.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V290.NonemptyDict.NonemptyDict Int Evergreen.V290.Touch.Touch
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
    | AdminToFrontend Evergreen.V290.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V290.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V290.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V290.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V290.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V290.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V290.Go.PublicGoMatchResponse)


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V290.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V290.Coord.Coord Evergreen.V290.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V290.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V290.MyUi.LastCopy
    , notificationPermission : Evergreen.V290.Ports.NotificationPermission
    , pwaStatus : Evergreen.V290.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V290.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V290.UserAgent.UserAgent
    , timeOrigin : Effect.Time.Posix
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V290.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V290.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V290.Id.Id Evergreen.V290.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V290.Id.Id Evergreen.V290.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V290.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V290.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V290.Coord.Coord Evergreen.V290.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V290.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V290.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V290.Id.Id Evergreen.V290.Id.GuildId, Evergreen.V290.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V290.DmChannel.DmChannelId, Evergreen.V290.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V290.Discord.Id Evergreen.V290.Discord.GuildId, Evergreen.V290.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V290.Discord.Id Evergreen.V290.Discord.PrivateChannelId, Evergreen.V290.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V290.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V290.NonemptyDict.NonemptyDict (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId) Evergreen.V290.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V290.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V290.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V290.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V290.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId) Evergreen.V290.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId) Evergreen.V290.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V290.Id.Id Evergreen.V290.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.Id.GuildId) Evergreen.V290.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.Id.GuildId) Evergreen.V290.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V290.Discord.Id Evergreen.V290.Discord.GuildId) Evergreen.V290.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V290.DmChannel.DmChannelId Evergreen.V290.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V290.Discord.Id Evergreen.V290.Discord.PrivateChannelId) Evergreen.V290.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V290.OneToOne.OneToOne (Evergreen.V290.Slack.Id Evergreen.V290.Slack.ChannelId) Evergreen.V290.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V290.OneToOne.OneToOne String (Evergreen.V290.Id.Id Evergreen.V290.Id.GuildId)
    , slackUsers : Evergreen.V290.OneToOne.OneToOne (Evergreen.V290.Slack.Id Evergreen.V290.Slack.UserId) (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId)
    , slackServers : Evergreen.V290.OneToOne.OneToOne (Evergreen.V290.Slack.Id Evergreen.V290.Slack.TeamId) (Evergreen.V290.Id.Id Evergreen.V290.Id.GuildId)
    , slackToken : Maybe Evergreen.V290.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V290.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V290.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V290.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V290.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V290.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V290.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V290.Cloudflare.AnalyticsApiToken
    , textEditor : Evergreen.V290.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId) Evergreen.V290.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId, Evergreen.V290.Discord.Id Evergreen.V290.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V290.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V290.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V290.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V290.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId) (Evergreen.V290.LocalState.LoadingDiscordChannel (List Evergreen.V290.Discord.Message))
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V290.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.Id.StickerId) Evergreen.V290.Sticker.StickerData
    , discordStickers : Evergreen.V290.OneToOne.OneToOne (Evergreen.V290.Discord.Id Evergreen.V290.Discord.StickerId) (Evergreen.V290.Id.Id Evergreen.V290.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.Id.CustomEmojiId) Evergreen.V290.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V290.OneToOne.OneToOne Evergreen.V290.RichText.DiscordCustomEmojiIdAndName (Evergreen.V290.Id.Id Evergreen.V290.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V290.Postmark.ApiKey
    , serverSecret : Evergreen.V290.SecretId.SecretId Evergreen.V290.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V290.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V290.OneToOne.OneToOne (Evergreen.V290.SecretId.SecretId Evergreen.V290.Id.GoMatchPublicId) ( Evergreen.V290.DmChannel.DmChannelId, Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelMessageId )
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V290.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V290.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V290.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V290.Route.Route
    | SelectedFilesToAttach ( Evergreen.V290.Id.AnyGuildOrDmId, Evergreen.V290.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V290.Id.Id Evergreen.V290.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V290.Id.Id Evergreen.V290.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V290.Id.Id Evergreen.V290.Id.GuildId) (Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelId) Evergreen.V290.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V290.Id.Id Evergreen.V290.Id.GuildId) (Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelId) Evergreen.V290.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V290.Discord.Id Evergreen.V290.Discord.GuildId) (Evergreen.V290.Discord.Id Evergreen.V290.Discord.ChannelId) Evergreen.V290.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V290.Discord.Id Evergreen.V290.Discord.GuildId) (Evergreen.V290.Discord.Id Evergreen.V290.Discord.ChannelId) Evergreen.V290.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V290.Id.Id Evergreen.V290.Id.GuildId) (Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V290.Id.Id Evergreen.V290.Id.GuildId) (Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V290.Id.Id Evergreen.V290.Id.GuildId) (Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V290.Id.Id Evergreen.V290.Id.GuildId) (Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V290.Id.Id Evergreen.V290.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V290.Id.Id Evergreen.V290.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V290.Id.Id Evergreen.V290.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V290.Id.Id Evergreen.V290.Id.GuildId) (Evergreen.V290.SecretId.SecretId Evergreen.V290.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V290.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V290.Id.AnyGuildOrDmId Evergreen.V290.Id.ThreadRouteWithMessage (Evergreen.V290.Coord.Coord Evergreen.V290.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V290.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V290.Id.AnyGuildOrDmId Evergreen.V290.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V290.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V290.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V290.Id.AnyGuildOrDmId, Evergreen.V290.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V290.Ports.NotificationPermission
    | TouchStart (Maybe ( Evergreen.V290.Id.AnyGuildOrDmId, Evergreen.V290.Id.ThreadRouteWithMessage, Bool )) Duration.Duration (Evergreen.V290.NonemptyDict.NonemptyDict Int Evergreen.V290.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V290.NonemptyDict.NonemptyDict Int Evergreen.V290.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V290.Id.AnyGuildOrDmId Evergreen.V290.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V290.Id.AnyGuildOrDmId Evergreen.V290.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V290.NonemptySet.NonemptySet (Evergreen.V290.Id.Id Evergreen.V290.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V290.Id.AnyGuildOrDmId, Evergreen.V290.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V290.Id.AnyGuildOrDmId Evergreen.V290.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V290.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V290.AiChat.Msg
    | GoMsg Evergreen.V290.Go.Msg
    | GoSpectatorMsg Evergreen.V290.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V290.Editable.Msg Evergreen.V290.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V290.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V290.Id.Id Evergreen.V290.Id.GuildId) Evergreen.V290.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V290.Id.AnyGuildOrDmId, Evergreen.V290.Id.ThreadRoute ) (Evergreen.V290.Id.Id Evergreen.V290.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V290.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V290.Id.AnyGuildOrDmId, Evergreen.V290.Id.ThreadRoute ) (Evergreen.V290.Id.Id Evergreen.V290.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V290.Id.AnyGuildOrDmId, Evergreen.V290.Id.ThreadRoute ) (Evergreen.V290.Id.Id Evergreen.V290.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V290.Id.AnyGuildOrDmId, Evergreen.V290.Id.ThreadRoute )
        { fileId : Evergreen.V290.Id.Id Evergreen.V290.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V290.Id.AnyGuildOrDmId, Evergreen.V290.Id.ThreadRoute ) (Evergreen.V290.Id.Id Evergreen.V290.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V290.Id.AnyGuildOrDmId, Evergreen.V290.Id.ThreadRoute ) (Evergreen.V290.Id.Id Evergreen.V290.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V290.Id.AnyGuildOrDmId, Evergreen.V290.Id.ThreadRoute )
        { fileId : Evergreen.V290.Id.Id Evergreen.V290.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V290.Id.AnyGuildOrDmId, Evergreen.V290.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V290.Id.AnyGuildOrDmId, Evergreen.V290.Id.ThreadRoute ) (Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelMessageId) (Evergreen.V290.Id.Id Evergreen.V290.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V290.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V290.Id.AnyGuildOrDmId, Evergreen.V290.Id.ThreadRoute ) (Evergreen.V290.Id.Id Evergreen.V290.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V290.Id.AnyGuildOrDmId Evergreen.V290.Id.ThreadRouteWithMessage Evergreen.V290.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V290.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V290.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V290.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V290.Id.Id Evergreen.V290.Id.GuildId) Evergreen.V290.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId) (Evergreen.V290.Discord.Id Evergreen.V290.Discord.GuildId) Evergreen.V290.User.NotificationLevel
    | GotStartupData Evergreen.V290.Ports.StartupData
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V290.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId
        , otherUserId : Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V290.Id.AnyGuildOrDmId Evergreen.V290.Id.ThreadRoute Evergreen.V290.MessageInput.Msg
    | MessageInputMsg Evergreen.V290.Id.AnyGuildOrDmId Evergreen.V290.Id.ThreadRoute Evergreen.V290.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V290.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V290.Range.Range, Evergreen.V290.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V290.Range.Range, Evergreen.V290.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V290.Call.FromJs)
    | VoiceChatMsg Evergreen.V290.Call.Msg
    | PressedChannelHeaderTab Evergreen.V290.Route.DmChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadServiceWorkerData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V290.Drawing.Msg


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V290.Id.Id Evergreen.V290.Id.GuildId) (Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelId) Evergreen.V290.Id.ThreadRoute
    | InitialLoadRequested_Dm Evergreen.V290.DmChannel.DmChannelId Evergreen.V290.Id.ThreadRoute
    | InitialLoadRequested_Discord Evergreen.V290.Id.DiscordGuildOrDmId Evergreen.V290.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V290.Id.Id Evergreen.V290.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V290.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V290.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V290.Untrusted.Untrusted Evergreen.V290.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V290.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V290.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V290.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V290.Id.Id Evergreen.V290.Id.GuildId) (Evergreen.V290.SecretId.SecretId Evergreen.V290.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V290.PersonName.PersonName Evergreen.V290.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V290.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V290.Slack.OAuthCode Evergreen.V290.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V290.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V290.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V290.Id.Id Evergreen.V290.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V290.SecretId.SecretId Evergreen.V290.Id.GoMatchPublicId)


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V290.Discord.Id Evergreen.V290.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V290.Discord.Id Evergreen.V290.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V290.EmailAddress.EmailAddress (Result Evergreen.V290.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V290.EmailAddress.EmailAddress (Result Evergreen.V290.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V290.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V290.Discord.Id Evergreen.V290.Discord.GuildId) (Evergreen.V290.Discord.Id Evergreen.V290.Discord.ChannelId) Evergreen.V290.Id.ThreadRouteWithMaybeMessage (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId) (Result Evergreen.V290.Discord.HttpError Evergreen.V290.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V290.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V290.Discord.Id Evergreen.V290.Discord.PrivateChannelId) (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId) (Result Evergreen.V290.Discord.HttpError Evergreen.V290.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V290.Discord.Id Evergreen.V290.Discord.GuildId) (Evergreen.V290.Discord.Id Evergreen.V290.Discord.ChannelId) Evergreen.V290.Id.ThreadRouteWithMessage (Evergreen.V290.Discord.Id Evergreen.V290.Discord.MessageId) (Result Evergreen.V290.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V290.Discord.Id Evergreen.V290.Discord.PrivateChannelId) (Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelMessageId) (Evergreen.V290.Discord.Id Evergreen.V290.Discord.MessageId) (Result Evergreen.V290.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V290.Discord.Id Evergreen.V290.Discord.GuildId) (Evergreen.V290.Discord.Id Evergreen.V290.Discord.ChannelId) Evergreen.V290.Id.ThreadRouteWithMessage (Evergreen.V290.Discord.Id Evergreen.V290.Discord.MessageId) (Result Evergreen.V290.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V290.Discord.Id Evergreen.V290.Discord.PrivateChannelId) (Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelMessageId) (Evergreen.V290.Discord.Id Evergreen.V290.Discord.MessageId) (Result Evergreen.V290.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V290.Discord.Id Evergreen.V290.Discord.GuildId) (Evergreen.V290.Discord.Id Evergreen.V290.Discord.ChannelId) Evergreen.V290.Id.ThreadRouteWithMessage (Evergreen.V290.Discord.Id Evergreen.V290.Discord.MessageId) Evergreen.V290.Emoji.EmojiOrCustomEmoji (Result Evergreen.V290.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V290.Discord.Id Evergreen.V290.Discord.PrivateChannelId) (Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelMessageId) (Evergreen.V290.Discord.Id Evergreen.V290.Discord.MessageId) Evergreen.V290.Emoji.EmojiOrCustomEmoji (Result Evergreen.V290.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V290.Discord.Id Evergreen.V290.Discord.GuildId) (Evergreen.V290.Discord.Id Evergreen.V290.Discord.ChannelId) Evergreen.V290.Id.ThreadRouteWithMessage (Evergreen.V290.Discord.Id Evergreen.V290.Discord.MessageId) Evergreen.V290.Emoji.EmojiOrCustomEmoji (Result Evergreen.V290.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V290.Discord.Id Evergreen.V290.Discord.PrivateChannelId) (Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelMessageId) (Evergreen.V290.Discord.Id Evergreen.V290.Discord.MessageId) Evergreen.V290.Emoji.EmojiOrCustomEmoji (Result Evergreen.V290.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V290.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V290.Discord.HttpError (List ( Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId, Maybe Evergreen.V290.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId) Effect.Time.Posix Evergreen.V290.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V290.Slack.CurrentUser
            , team : Evergreen.V290.Slack.Team
            , users : List Evergreen.V290.Slack.User
            , channels : List ( Evergreen.V290.Slack.Channel, List Evergreen.V290.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId) (Result Effect.Http.Error Evergreen.V290.Slack.TokenResponse)
    | GotCloudflareSessionCreated Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V290.Local.ChangeId Effect.Time.Posix Evergreen.V290.Call.CallId Evergreen.V290.Cloudflare.Sdp (List String) (Result Effect.Http.Error Evergreen.V290.Cloudflare.RealtimeSessionId)
    | GotCloudflareSession Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V290.Local.ChangeId Effect.Time.Posix Evergreen.V290.Call.CallId Evergreen.V290.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V290.Cloudflare.PushTracksResult)
    | GotCloudflarePullOffer Effect.Time.Posix Effect.Lamdera.ClientId Evergreen.V290.Local.ChangeId Evergreen.V290.Call.ConnectionId Evergreen.V290.Cloudflare.RealtimeSessionId (List Evergreen.V290.Cloudflare.TrackName) (Result Effect.Http.Error Evergreen.V290.Cloudflare.PullTracksResult)
    | GotCloudflareRenegotiateAck Effect.Lamdera.ClientId Evergreen.V290.Local.ChangeId Evergreen.V290.Cloudflare.Sdp (Result Effect.Http.Error ())
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId) Evergreen.V290.Discord.UserAuth (Result Evergreen.V290.Discord.HttpError Evergreen.V290.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId) (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId) (Result Evergreen.V290.Discord.HttpError Evergreen.V290.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId)
        (Result
            Evergreen.V290.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V290.Discord.Id Evergreen.V290.Discord.PrivateChannelId
                , members : List (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId)
                }
            , List
                ( Evergreen.V290.Discord.Id Evergreen.V290.Discord.GuildId
                , { guild : Evergreen.V290.Discord.GatewayGuild
                  , channels : List Evergreen.V290.Discord.Channel
                  , icon : Maybe Evergreen.V290.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId) Bool Evergreen.V290.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V290.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V290.Discord.Id Evergreen.V290.Discord.AttachmentId, Evergreen.V290.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V290.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V290.Discord.Id Evergreen.V290.Discord.AttachmentId, Evergreen.V290.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId) (Evergreen.V290.Discord.Id Evergreen.V290.Discord.GuildId) (Evergreen.V290.Discord.Id Evergreen.V290.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V290.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V290.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId) (Evergreen.V290.Discord.Id Evergreen.V290.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V290.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V290.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId) (Evergreen.V290.Discord.Id Evergreen.V290.Discord.GuildId) (Evergreen.V290.Discord.Id Evergreen.V290.Discord.ChannelId) (Result Evergreen.V290.Discord.HttpError (List Evergreen.V290.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId) (Evergreen.V290.Discord.Id Evergreen.V290.Discord.PrivateChannelId) (Result Evergreen.V290.Discord.HttpError (List Evergreen.V290.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V290.Id.Id Evergreen.V290.Id.GuildId) (Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelId) Evergreen.V290.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V290.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V290.DmChannel.DmChannelId Evergreen.V290.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V290.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V290.Discord.Id Evergreen.V290.Discord.GuildId) (Evergreen.V290.Discord.Id Evergreen.V290.Discord.ChannelId) Evergreen.V290.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V290.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V290.Discord.Id Evergreen.V290.Discord.PrivateChannelId) (Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V290.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId)
        (Evergreen.V290.Discord.Id Evergreen.V290.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V290.Discord.HttpError
            { guild : Evergreen.V290.Discord.GatewayGuild
            , channels : List Evergreen.V290.Discord.Channel
            , icon : Maybe Evergreen.V290.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V290.Discord.Id Evergreen.V290.Discord.GuildId) (Result Evergreen.V290.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V290.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId) (List ( Evergreen.V290.Id.Id Evergreen.V290.Id.StickerId, Result Effect.Http.Error Evergreen.V290.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V290.Id.Id Evergreen.V290.Id.StickerId, Result Effect.Http.Error Evergreen.V290.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId) (List ( Evergreen.V290.Id.Id Evergreen.V290.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V290.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V290.Id.Id Evergreen.V290.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V290.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V290.Discord.HttpError (List Evergreen.V290.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V290.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V290.SecretId.SecretId Evergreen.V290.SecretId.ServerSecret))
    | GotTimeForWebsocketListenClose (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | GotCloudflareUsage Effect.Time.Posix (Result Effect.Http.Error Int)
    | GotCloudflareEgressForAdmin Effect.Lamdera.ClientId (Result Effect.Http.Error Int)
    | GotRustServerFileUpload Evergreen.V290.FileStatus.FileHash Int (Maybe (Evergreen.V290.Coord.Coord Evergreen.V290.CssPixels.CssPixels))
