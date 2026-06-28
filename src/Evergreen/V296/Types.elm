module Evergreen.V296.Types exposing (..)

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
import Evergreen.V296.AiChat
import Evergreen.V296.Call
import Evergreen.V296.ChannelDescription
import Evergreen.V296.ChannelName
import Evergreen.V296.Cloudflare
import Evergreen.V296.Coord
import Evergreen.V296.CssPixels
import Evergreen.V296.CustomEmoji
import Evergreen.V296.Discord
import Evergreen.V296.DiscordAttachmentId
import Evergreen.V296.DiscordUserData
import Evergreen.V296.DmChannel
import Evergreen.V296.Drawing
import Evergreen.V296.Editable
import Evergreen.V296.EmailAddress
import Evergreen.V296.Embed
import Evergreen.V296.Emoji
import Evergreen.V296.FileStatus
import Evergreen.V296.Game
import Evergreen.V296.Go
import Evergreen.V296.GuildName
import Evergreen.V296.Id
import Evergreen.V296.ImageEditor
import Evergreen.V296.ImageViewer
import Evergreen.V296.LinkedAndOtherDiscordUsers
import Evergreen.V296.Local
import Evergreen.V296.LocalState
import Evergreen.V296.Log
import Evergreen.V296.LoginForm
import Evergreen.V296.MembersAndOwner
import Evergreen.V296.Message
import Evergreen.V296.MessageInput
import Evergreen.V296.MessageView
import Evergreen.V296.MyUi
import Evergreen.V296.NonemptyDict
import Evergreen.V296.NonemptySet
import Evergreen.V296.OneOrGreater
import Evergreen.V296.OneToOne
import Evergreen.V296.Pages.Admin
import Evergreen.V296.Pagination
import Evergreen.V296.PersonName
import Evergreen.V296.Ports
import Evergreen.V296.Postmark
import Evergreen.V296.Range
import Evergreen.V296.RichText
import Evergreen.V296.Route
import Evergreen.V296.SecretId
import Evergreen.V296.SessionIdHash
import Evergreen.V296.Slack
import Evergreen.V296.Sticker
import Evergreen.V296.TextEditor
import Evergreen.V296.ToBackendLog
import Evergreen.V296.Touch
import Evergreen.V296.TwoFactorAuthentication
import Evergreen.V296.Ui.Anim
import Evergreen.V296.Untrusted
import Evergreen.V296.User
import Evergreen.V296.UserAgent
import Evergreen.V296.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V296.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V296.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V296.Id.Id Evergreen.V296.Id.GuildId) Evergreen.V296.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId) Evergreen.V296.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V296.Discord.Id Evergreen.V296.Discord.PrivateChannelId) Evergreen.V296.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V296.Discord.Id Evergreen.V296.Discord.GuildId) Evergreen.V296.LocalState.DiscordFrontendGuild
    , user : Evergreen.V296.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId) Evergreen.V296.User.FrontendUser
    , discordUsers : Evergreen.V296.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V296.SessionIdHash.SessionIdHash Evergreen.V296.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V296.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V296.Id.Id Evergreen.V296.Id.StickerId) Evergreen.V296.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V296.Id.Id Evergreen.V296.Id.CustomEmojiId) Evergreen.V296.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V296.Call.CallId (Evergreen.V296.NonemptyDict.NonemptyDict ( Evergreen.V296.Id.Id Evergreen.V296.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V296.Call.RemoteCallData)
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type PublicGoMatch
    = PublicGoMatch_NotLoaded
    | PublicGoMatch_Loading
    | PublicGoMatch_Loaded Evergreen.V296.Go.PublicGoMatchData Evergreen.V296.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V296.Route.Route
    , windowSize : Evergreen.V296.Coord.Coord Evergreen.V296.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , timezone : Effect.Time.Zone
    , startupData : Maybe Evergreen.V296.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V296.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V296.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V296.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V296.Id.Id Evergreen.V296.FileStatus.FileId) Evergreen.V296.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V296.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V296.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V296.Id.Id Evergreen.V296.FileStatus.FileId) Evergreen.V296.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V296.Id.Id Evergreen.V296.Id.GuildId) Evergreen.V296.ChannelName.ChannelName Evergreen.V296.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V296.Id.Id Evergreen.V296.Id.GuildId) (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelId) Evergreen.V296.ChannelName.ChannelName Evergreen.V296.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V296.Id.Id Evergreen.V296.Id.GuildId) (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelId)
    | Local_DeleteGuild (Evergreen.V296.Id.Id Evergreen.V296.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V296.Id.Id Evergreen.V296.Id.GuildId) (Evergreen.V296.UserSession.ToBeFilledInByBackend (Evergreen.V296.SecretId.SecretId Evergreen.V296.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V296.Id.Id Evergreen.V296.Id.GuildId) (Evergreen.V296.SecretId.SecretId Evergreen.V296.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V296.GuildName.GuildName (Evergreen.V296.UserSession.ToBeFilledInByBackend (Evergreen.V296.Id.Id Evergreen.V296.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V296.Id.AnyGuildOrDmId, Evergreen.V296.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V296.Id.AnyGuildOrDmId Evergreen.V296.Id.ThreadRouteWithMessage Evergreen.V296.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V296.Id.AnyGuildOrDmId Evergreen.V296.Id.ThreadRouteWithMessage Evergreen.V296.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V296.Id.GuildOrDmId Evergreen.V296.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V296.Id.Id Evergreen.V296.FileStatus.FileId) Evergreen.V296.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId) (Evergreen.V296.Discord.Id Evergreen.V296.Discord.GuildId) (Evergreen.V296.Discord.Id Evergreen.V296.Discord.ChannelId) Evergreen.V296.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V296.Id.DiscordGuildOrDmId_DmData (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V296.Id.AnyGuildOrDmId Evergreen.V296.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V296.Id.AnyGuildOrDmId Evergreen.V296.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V296.Id.AnyGuildOrDmId Evergreen.V296.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V296.UserSession.SetViewing
    | Local_SetName Evergreen.V296.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V296.Id.GuildOrDmId (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelMessageId) (Evergreen.V296.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelMessageId) (Evergreen.V296.Message.Message Evergreen.V296.Id.ChannelMessageId (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V296.Id.GuildOrDmId (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelMessageId) (Evergreen.V296.Id.Id Evergreen.V296.Id.ThreadMessageId) (Evergreen.V296.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V296.Id.Id Evergreen.V296.Id.ThreadMessageId) (Evergreen.V296.Message.Message Evergreen.V296.Id.ThreadMessageId (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V296.Id.DiscordGuildOrDmId (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelMessageId) (Evergreen.V296.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelMessageId) (Evergreen.V296.Message.Message Evergreen.V296.Id.ChannelMessageId (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V296.Id.DiscordGuildOrDmId (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelMessageId) (Evergreen.V296.Id.Id Evergreen.V296.Id.ThreadMessageId) (Evergreen.V296.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V296.Id.Id Evergreen.V296.Id.ThreadMessageId) (Evergreen.V296.Message.Message Evergreen.V296.Id.ThreadMessageId (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V296.Id.Id Evergreen.V296.Id.GuildId) Evergreen.V296.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId) (Evergreen.V296.Discord.Id Evergreen.V296.Discord.GuildId) Evergreen.V296.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V296.UserSession.NotificationMode
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V296.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V296.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V296.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V296.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V296.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V296.NonemptySet.NonemptySet (Evergreen.V296.Id.Id Evergreen.V296.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V296.Call.LocalChange
    | Local_Game
        { otherUserId : Evergreen.V296.Id.Id Evergreen.V296.Id.UserId
        }
        Evergreen.V296.Game.LocalChange
    | Local_Drawing Evergreen.V296.Id.AnyGuildOrDmId Evergreen.V296.Drawing.AnchorType Evergreen.V296.Drawing.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId) Effect.Time.Posix Evergreen.V296.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V296.RichText.RichText (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId))) Evergreen.V296.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V296.Id.Id Evergreen.V296.FileStatus.FileId) Evergreen.V296.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V296.Id.Id Evergreen.V296.Id.StickerId) Evergreen.V296.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V296.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V296.RichText.RichText (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId))) Evergreen.V296.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V296.Id.Id Evergreen.V296.FileStatus.FileId) Evergreen.V296.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V296.Id.Id Evergreen.V296.Id.StickerId) Evergreen.V296.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V296.Id.Id Evergreen.V296.Id.GuildId) Evergreen.V296.ChannelName.ChannelName Evergreen.V296.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V296.Id.Id Evergreen.V296.Id.GuildId) (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelId) Evergreen.V296.ChannelName.ChannelName Evergreen.V296.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V296.Id.Id Evergreen.V296.Id.GuildId) (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelId)
    | Server_DeleteGuild (Evergreen.V296.Id.Id Evergreen.V296.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId) (Evergreen.V296.Id.Id Evergreen.V296.Id.GuildId) (Evergreen.V296.SecretId.SecretId Evergreen.V296.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V296.Id.Id Evergreen.V296.Id.GuildId) (Evergreen.V296.SecretId.SecretId Evergreen.V296.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId) (Evergreen.V296.Id.Id Evergreen.V296.Id.GuildId) Evergreen.V296.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V296.LocalState.JoinGuildError
            { guildId : Evergreen.V296.Id.Id Evergreen.V296.Id.GuildId
            , guild : Evergreen.V296.LocalState.FrontendGuild
            , owner : Evergreen.V296.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId) Evergreen.V296.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId) Evergreen.V296.Id.GuildOrDmId Evergreen.V296.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId) (Evergreen.V296.Discord.Id Evergreen.V296.Discord.GuildId) (Evergreen.V296.Discord.Id Evergreen.V296.Discord.ChannelId) Evergreen.V296.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId) (Evergreen.V296.Discord.Id Evergreen.V296.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId) Evergreen.V296.Id.GuildOrDmId Evergreen.V296.Id.ThreadRouteWithMessage Evergreen.V296.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId) Evergreen.V296.Id.GuildOrDmId Evergreen.V296.Id.ThreadRouteWithMessage Evergreen.V296.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId) (Evergreen.V296.Discord.Id Evergreen.V296.Discord.GuildId) (Evergreen.V296.Discord.Id Evergreen.V296.Discord.ChannelId) Evergreen.V296.Id.ThreadRouteWithMessage Evergreen.V296.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId) (Evergreen.V296.Discord.Id Evergreen.V296.Discord.PrivateChannelId) (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelMessageId) Evergreen.V296.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId) (Evergreen.V296.Discord.Id Evergreen.V296.Discord.GuildId) (Evergreen.V296.Discord.Id Evergreen.V296.Discord.ChannelId) Evergreen.V296.Id.ThreadRouteWithMessage Evergreen.V296.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId) (Evergreen.V296.Discord.Id Evergreen.V296.Discord.PrivateChannelId) (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelMessageId) Evergreen.V296.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId) Evergreen.V296.Id.GuildOrDmId Evergreen.V296.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V296.RichText.RichText (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId))) (SeqDict.SeqDict (Evergreen.V296.Id.Id Evergreen.V296.FileStatus.FileId) Evergreen.V296.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId) (Evergreen.V296.Discord.Id Evergreen.V296.Discord.GuildId) (Evergreen.V296.Discord.Id Evergreen.V296.Discord.ChannelId) Evergreen.V296.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V296.RichText.RichText (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V296.Id.DiscordGuildOrDmId_DmData (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V296.RichText.RichText (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId) Evergreen.V296.Id.AnyGuildOrDmId Evergreen.V296.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V296.Id.AnyGuildOrDmId Evergreen.V296.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V296.Discord.Id Evergreen.V296.Discord.GuildId) (Evergreen.V296.Discord.Id Evergreen.V296.Discord.ChannelId) Evergreen.V296.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V296.Discord.Id Evergreen.V296.Discord.PrivateChannelId) (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId) Evergreen.V296.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId) Evergreen.V296.FileStatus.FileHash
    | Server_SetGuildIcon (Evergreen.V296.Id.Id Evergreen.V296.Id.GuildId) Evergreen.V296.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V296.Id.Id Evergreen.V296.Id.GuildId) Evergreen.V296.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V296.Discord.Id Evergreen.V296.Discord.GuildId) Evergreen.V296.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V296.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V296.SessionIdHash.SessionIdHash Evergreen.V296.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V296.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V296.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V296.Id.AnyGuildOrDmId, Evergreen.V296.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V296.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId) Evergreen.V296.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V296.Discord.Id Evergreen.V296.Discord.GuildId) (Evergreen.V296.Discord.Id Evergreen.V296.Discord.ChannelId) Evergreen.V296.ChannelName.ChannelName (Evergreen.V296.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V296.Discord.Id Evergreen.V296.Discord.PrivateChannelId)
        (Evergreen.V296.NonemptyDict.NonemptyDict
            (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V296.Discord.Id Evergreen.V296.Discord.GuildId) Evergreen.V296.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V296.Discord.Id Evergreen.V296.Discord.PrivateChannelId) Evergreen.V296.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId) Evergreen.V296.UserSession.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId) (Maybe (Evergreen.V296.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V296.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V296.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V296.Id.Id Evergreen.V296.Id.GuildId) (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelId) Evergreen.V296.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V296.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId) Evergreen.V296.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V296.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V296.Discord.Id Evergreen.V296.Discord.GuildId) (Evergreen.V296.Discord.Id Evergreen.V296.Discord.ChannelId) Evergreen.V296.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V296.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V296.Discord.Id Evergreen.V296.Discord.PrivateChannelId) (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V296.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V296.Discord.Id Evergreen.V296.Discord.GuildId) Evergreen.V296.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V296.Discord.Id Evergreen.V296.Discord.GuildId) (Evergreen.V296.Discord.Id Evergreen.V296.Discord.ChannelId) (Evergreen.V296.Discord.OptionalData String) (Evergreen.V296.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V296.Discord.Id Evergreen.V296.Discord.GuildId)
        (Evergreen.V296.MembersAndOwner.MembersAndOwner
            (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V296.Discord.Id Evergreen.V296.Discord.GuildId) (Evergreen.V296.Discord.Id Evergreen.V296.Discord.ChannelId) (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId) Evergreen.V296.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V296.Id.Id Evergreen.V296.Id.StickerId) Evergreen.V296.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V296.Id.Id Evergreen.V296.Id.CustomEmojiId) Evergreen.V296.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V296.Call.ServerChange
    | Server_Game
        (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId)
        { otherUserId : Evergreen.V296.Id.Id Evergreen.V296.Id.UserId
        }
        Evergreen.V296.Game.LocalChange
    | Server_Drawing (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId) Evergreen.V296.Id.AnyGuildOrDmId Evergreen.V296.Drawing.AnchorType Evergreen.V296.Drawing.LocalChange


type LocalMsg
    = LocalChange (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V296.Id.Id Evergreen.V296.Id.GuildId) (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelId) Evergreen.V296.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V296.Discord.Id Evergreen.V296.Discord.GuildId) (Evergreen.V296.Discord.Id Evergreen.V296.Discord.ChannelId) Evergreen.V296.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V296.Id.Id Evergreen.V296.FileStatus.FileId) Evergreen.V296.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V296.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V296.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V296.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V296.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V296.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V296.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V296.Coord.Coord Evergreen.V296.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V296.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V296.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V296.Id.AnyGuildOrDmId Evergreen.V296.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V296.Id.AnyGuildOrDmId Evergreen.V296.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V296.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V296.Coord.Coord Evergreen.V296.CssPixels.CssPixels) (Maybe Evergreen.V296.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V296.Id.AnyGuildOrDmId, Evergreen.V296.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelMessageId) (Evergreen.V296.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V296.Id.Id Evergreen.V296.Id.ThreadMessageId) (Evergreen.V296.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V296.Editable.Model
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
    | FileDragging Effect.Time.Posix Evergreen.V296.OneOrGreater.OneOrGreater


type alias LoggedIn2 =
    { localState : Evergreen.V296.Local.Local LocalMsg Evergreen.V296.LocalState.LocalState
    , admin : Evergreen.V296.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V296.Id.AnyGuildOrDmId, Evergreen.V296.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V296.Id.Id Evergreen.V296.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V296.Id.Id Evergreen.V296.Id.GuildId, Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V296.Id.Id Evergreen.V296.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V296.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V296.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V296.Id.AnyGuildOrDmId, Evergreen.V296.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V296.Id.AnyGuildOrDmId, Evergreen.V296.Id.ThreadRoute ) (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : Evergreen.V296.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V296.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V296.Id.AnyGuildOrDmId, Evergreen.V296.Id.ThreadRoute ) (Evergreen.V296.NonemptyDict.NonemptyDict (Evergreen.V296.Id.Id Evergreen.V296.FileStatus.FileId) Evergreen.V296.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V296.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V296.TextEditor.Model
    , profilePictureEditor : Evergreen.V296.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V296.Id.Id Evergreen.V296.Id.GuildId, Evergreen.V296.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V296.Emoji.Model
    , voiceChat : Evergreen.V296.Call.Model
    , currentDmGame : SeqDict.SeqDict ( Evergreen.V296.Id.Id Evergreen.V296.Id.UserId, Maybe (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelMessageId) ) Evergreen.V296.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V296.Drawing.Model
    , showInviteLinkQrCode : Maybe (Evergreen.V296.SecretId.SecretId Evergreen.V296.Id.InviteLinkId)
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V296.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V296.SecretId.SecretId Evergreen.V296.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V296.Range.Range
                , direction : Evergreen.V296.Range.SelectionDirection
                }
        }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_WordSpellingGameBoard


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V296.NonemptyDict.NonemptyDict Int Evergreen.V296.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V296.NonemptyDict.NonemptyDict Int Evergreen.V296.Touch.Touch
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
    | AdminToFrontend Evergreen.V296.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V296.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V296.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V296.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V296.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V296.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V296.Go.PublicGoMatchResponse)


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V296.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V296.Coord.Coord Evergreen.V296.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V296.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V296.MyUi.LastCopy
    , notificationPermission : Evergreen.V296.Ports.NotificationPermission
    , pwaStatus : Evergreen.V296.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V296.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V296.UserAgent.UserAgent
    , timeOrigin : Effect.Time.Posix
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V296.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V296.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V296.Id.Id Evergreen.V296.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V296.Id.Id Evergreen.V296.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V296.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V296.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V296.Coord.Coord Evergreen.V296.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V296.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V296.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V296.Id.Id Evergreen.V296.Id.GuildId, Evergreen.V296.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V296.DmChannel.DmChannelId, Evergreen.V296.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V296.Discord.Id Evergreen.V296.Discord.GuildId, Evergreen.V296.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V296.Discord.Id Evergreen.V296.Discord.PrivateChannelId, Evergreen.V296.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V296.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V296.NonemptyDict.NonemptyDict (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId) Evergreen.V296.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V296.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V296.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V296.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V296.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId) Evergreen.V296.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId) Evergreen.V296.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V296.Id.Id Evergreen.V296.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V296.Id.Id Evergreen.V296.Id.GuildId) Evergreen.V296.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V296.Id.Id Evergreen.V296.Id.GuildId) Evergreen.V296.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V296.Discord.Id Evergreen.V296.Discord.GuildId) Evergreen.V296.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V296.DmChannel.DmChannelId Evergreen.V296.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V296.Discord.Id Evergreen.V296.Discord.PrivateChannelId) Evergreen.V296.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V296.OneToOne.OneToOne (Evergreen.V296.Slack.Id Evergreen.V296.Slack.ChannelId) Evergreen.V296.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V296.OneToOne.OneToOne String (Evergreen.V296.Id.Id Evergreen.V296.Id.GuildId)
    , slackUsers : Evergreen.V296.OneToOne.OneToOne (Evergreen.V296.Slack.Id Evergreen.V296.Slack.UserId) (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId)
    , slackServers : Evergreen.V296.OneToOne.OneToOne (Evergreen.V296.Slack.Id Evergreen.V296.Slack.TeamId) (Evergreen.V296.Id.Id Evergreen.V296.Id.GuildId)
    , slackToken : Maybe Evergreen.V296.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V296.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V296.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V296.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V296.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V296.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V296.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V296.Cloudflare.AnalyticsApiToken
    , textEditor : Evergreen.V296.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId) Evergreen.V296.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId, Evergreen.V296.Discord.Id Evergreen.V296.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V296.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V296.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V296.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V296.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId) (Evergreen.V296.LocalState.LoadingDiscordChannel (List Evergreen.V296.Discord.Message))
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V296.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V296.Id.Id Evergreen.V296.Id.StickerId) Evergreen.V296.Sticker.StickerData
    , discordStickers : Evergreen.V296.OneToOne.OneToOne (Evergreen.V296.Discord.Id Evergreen.V296.Discord.StickerId) (Evergreen.V296.Id.Id Evergreen.V296.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V296.Id.Id Evergreen.V296.Id.CustomEmojiId) Evergreen.V296.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V296.OneToOne.OneToOne Evergreen.V296.RichText.DiscordCustomEmojiIdAndName (Evergreen.V296.Id.Id Evergreen.V296.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V296.Postmark.ApiKey
    , serverSecret : Evergreen.V296.SecretId.SecretId Evergreen.V296.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V296.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V296.OneToOne.OneToOne (Evergreen.V296.SecretId.SecretId Evergreen.V296.Id.GamePublicId) ( Evergreen.V296.DmChannel.DmChannelId, Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelMessageId )
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V296.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V296.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V296.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V296.Route.Route
    | SelectedFilesToAttach ( Evergreen.V296.Id.AnyGuildOrDmId, Evergreen.V296.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V296.Id.Id Evergreen.V296.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V296.Id.Id Evergreen.V296.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V296.Id.Id Evergreen.V296.Id.GuildId) (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelId) Evergreen.V296.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V296.Id.Id Evergreen.V296.Id.GuildId) (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelId) Evergreen.V296.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V296.Discord.Id Evergreen.V296.Discord.GuildId) (Evergreen.V296.Discord.Id Evergreen.V296.Discord.ChannelId) Evergreen.V296.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V296.Discord.Id Evergreen.V296.Discord.GuildId) (Evergreen.V296.Discord.Id Evergreen.V296.Discord.ChannelId) Evergreen.V296.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V296.Id.Id Evergreen.V296.Id.GuildId) (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V296.Id.Id Evergreen.V296.Id.GuildId) (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V296.Id.Id Evergreen.V296.Id.GuildId) (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V296.Id.Id Evergreen.V296.Id.GuildId) (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V296.Id.Id Evergreen.V296.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V296.Id.Id Evergreen.V296.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V296.Id.Id Evergreen.V296.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V296.Id.Id Evergreen.V296.Id.GuildId) (Evergreen.V296.SecretId.SecretId Evergreen.V296.Id.InviteLinkId)
    | PressedToggleInviteLinkQrCode (Evergreen.V296.SecretId.SecretId Evergreen.V296.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V296.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V296.Id.AnyGuildOrDmId Evergreen.V296.Id.ThreadRouteWithMessage (Evergreen.V296.Coord.Coord Evergreen.V296.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V296.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V296.Id.AnyGuildOrDmId Evergreen.V296.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V296.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V296.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V296.Id.AnyGuildOrDmId, Evergreen.V296.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V296.Ports.NotificationPermission
    | TouchStart (Maybe ( Evergreen.V296.Id.AnyGuildOrDmId, Evergreen.V296.Id.ThreadRouteWithMessage, Bool )) Duration.Duration (Evergreen.V296.NonemptyDict.NonemptyDict Int Evergreen.V296.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V296.NonemptyDict.NonemptyDict Int Evergreen.V296.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V296.Id.AnyGuildOrDmId Evergreen.V296.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V296.Id.AnyGuildOrDmId Evergreen.V296.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V296.NonemptySet.NonemptySet (Evergreen.V296.Id.Id Evergreen.V296.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V296.Id.AnyGuildOrDmId, Evergreen.V296.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V296.Id.AnyGuildOrDmId Evergreen.V296.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V296.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V296.AiChat.Msg
    | GameMsg Evergreen.V296.Game.Msg
    | GoSpectatorMsg Evergreen.V296.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V296.Editable.Msg Evergreen.V296.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V296.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V296.Id.Id Evergreen.V296.Id.GuildId) Evergreen.V296.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V296.Id.AnyGuildOrDmId, Evergreen.V296.Id.ThreadRoute ) (Evergreen.V296.Id.Id Evergreen.V296.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V296.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V296.Id.AnyGuildOrDmId, Evergreen.V296.Id.ThreadRoute ) (Evergreen.V296.Id.Id Evergreen.V296.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V296.Id.AnyGuildOrDmId, Evergreen.V296.Id.ThreadRoute ) (Evergreen.V296.Id.Id Evergreen.V296.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V296.Id.AnyGuildOrDmId, Evergreen.V296.Id.ThreadRoute )
        { fileId : Evergreen.V296.Id.Id Evergreen.V296.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V296.Id.AnyGuildOrDmId, Evergreen.V296.Id.ThreadRoute ) (Evergreen.V296.Id.Id Evergreen.V296.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V296.Id.AnyGuildOrDmId, Evergreen.V296.Id.ThreadRoute ) (Evergreen.V296.Id.Id Evergreen.V296.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V296.Id.AnyGuildOrDmId, Evergreen.V296.Id.ThreadRoute )
        { fileId : Evergreen.V296.Id.Id Evergreen.V296.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V296.Id.AnyGuildOrDmId, Evergreen.V296.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V296.Id.AnyGuildOrDmId, Evergreen.V296.Id.ThreadRoute ) (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelMessageId) (Evergreen.V296.Id.Id Evergreen.V296.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V296.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V296.Id.AnyGuildOrDmId, Evergreen.V296.Id.ThreadRoute ) (Evergreen.V296.Id.Id Evergreen.V296.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V296.Id.AnyGuildOrDmId Evergreen.V296.Id.ThreadRouteWithMessage Evergreen.V296.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V296.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V296.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V296.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V296.Id.Id Evergreen.V296.Id.GuildId) Evergreen.V296.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId) (Evergreen.V296.Discord.Id Evergreen.V296.Discord.GuildId) Evergreen.V296.User.NotificationLevel
    | GotStartupData Evergreen.V296.Ports.StartupData
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V296.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId
        , otherUserId : Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V296.Id.AnyGuildOrDmId Evergreen.V296.Id.ThreadRoute Evergreen.V296.MessageInput.Msg
    | MessageInputMsg Evergreen.V296.Id.AnyGuildOrDmId Evergreen.V296.Id.ThreadRoute Evergreen.V296.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V296.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V296.Range.Range, Evergreen.V296.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V296.Range.Range, Evergreen.V296.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V296.Call.FromJs)
    | VoiceChatMsg Evergreen.V296.Call.Msg
    | PressedChannelHeaderTab Evergreen.V296.Route.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadServiceWorkerData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V296.Drawing.Msg


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V296.Id.Id Evergreen.V296.Id.GuildId) (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelId) Evergreen.V296.Id.ThreadRoute
    | InitialLoadRequested_Dm Evergreen.V296.DmChannel.DmChannelId Evergreen.V296.Id.ThreadRoute
    | InitialLoadRequested_Discord Evergreen.V296.Id.DiscordGuildOrDmId Evergreen.V296.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V296.Id.Id Evergreen.V296.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V296.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V296.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V296.Untrusted.Untrusted Evergreen.V296.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V296.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V296.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V296.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V296.Id.Id Evergreen.V296.Id.GuildId) (Evergreen.V296.SecretId.SecretId Evergreen.V296.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V296.PersonName.PersonName Evergreen.V296.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V296.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V296.Slack.OAuthCode Evergreen.V296.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V296.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V296.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V296.Id.Id Evergreen.V296.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V296.SecretId.SecretId Evergreen.V296.Id.GamePublicId)


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V296.Discord.Id Evergreen.V296.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V296.Discord.Id Evergreen.V296.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V296.EmailAddress.EmailAddress (Result Evergreen.V296.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V296.EmailAddress.EmailAddress (Result Evergreen.V296.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V296.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V296.Discord.Id Evergreen.V296.Discord.GuildId) (Evergreen.V296.Discord.Id Evergreen.V296.Discord.ChannelId) Evergreen.V296.Id.ThreadRouteWithMaybeMessage (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId) (Result Evergreen.V296.Discord.HttpError Evergreen.V296.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V296.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V296.Discord.Id Evergreen.V296.Discord.PrivateChannelId) (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId) (Result Evergreen.V296.Discord.HttpError Evergreen.V296.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V296.Discord.Id Evergreen.V296.Discord.GuildId) (Evergreen.V296.Discord.Id Evergreen.V296.Discord.ChannelId) Evergreen.V296.Id.ThreadRouteWithMessage (Evergreen.V296.Discord.Id Evergreen.V296.Discord.MessageId) (Result Evergreen.V296.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V296.Discord.Id Evergreen.V296.Discord.PrivateChannelId) (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelMessageId) (Evergreen.V296.Discord.Id Evergreen.V296.Discord.MessageId) (Result Evergreen.V296.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V296.Discord.Id Evergreen.V296.Discord.GuildId) (Evergreen.V296.Discord.Id Evergreen.V296.Discord.ChannelId) Evergreen.V296.Id.ThreadRouteWithMessage (Evergreen.V296.Discord.Id Evergreen.V296.Discord.MessageId) (Result Evergreen.V296.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V296.Discord.Id Evergreen.V296.Discord.PrivateChannelId) (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelMessageId) (Evergreen.V296.Discord.Id Evergreen.V296.Discord.MessageId) (Result Evergreen.V296.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V296.Discord.Id Evergreen.V296.Discord.GuildId) (Evergreen.V296.Discord.Id Evergreen.V296.Discord.ChannelId) Evergreen.V296.Id.ThreadRouteWithMessage (Evergreen.V296.Discord.Id Evergreen.V296.Discord.MessageId) Evergreen.V296.Emoji.EmojiOrCustomEmoji (Result Evergreen.V296.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V296.Discord.Id Evergreen.V296.Discord.PrivateChannelId) (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelMessageId) (Evergreen.V296.Discord.Id Evergreen.V296.Discord.MessageId) Evergreen.V296.Emoji.EmojiOrCustomEmoji (Result Evergreen.V296.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V296.Discord.Id Evergreen.V296.Discord.GuildId) (Evergreen.V296.Discord.Id Evergreen.V296.Discord.ChannelId) Evergreen.V296.Id.ThreadRouteWithMessage (Evergreen.V296.Discord.Id Evergreen.V296.Discord.MessageId) Evergreen.V296.Emoji.EmojiOrCustomEmoji (Result Evergreen.V296.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V296.Discord.Id Evergreen.V296.Discord.PrivateChannelId) (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelMessageId) (Evergreen.V296.Discord.Id Evergreen.V296.Discord.MessageId) Evergreen.V296.Emoji.EmojiOrCustomEmoji (Result Evergreen.V296.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V296.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V296.Discord.HttpError (List ( Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId, Maybe Evergreen.V296.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId) Effect.Time.Posix Evergreen.V296.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V296.Slack.CurrentUser
            , team : Evergreen.V296.Slack.Team
            , users : List Evergreen.V296.Slack.User
            , channels : List ( Evergreen.V296.Slack.Channel, List Evergreen.V296.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId) (Result Effect.Http.Error Evergreen.V296.Slack.TokenResponse)
    | GotCloudflareSessionCreated Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V296.Local.ChangeId Effect.Time.Posix Evergreen.V296.Call.CallId Evergreen.V296.Cloudflare.Sdp (List String) (Result Effect.Http.Error Evergreen.V296.Cloudflare.RealtimeSessionId)
    | GotCloudflareSession Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V296.Local.ChangeId Effect.Time.Posix Evergreen.V296.Call.CallId Evergreen.V296.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V296.Cloudflare.PushTracksResult)
    | GotCloudflarePullOffer Effect.Time.Posix Effect.Lamdera.ClientId Evergreen.V296.Local.ChangeId Evergreen.V296.Call.ConnectionId Evergreen.V296.Cloudflare.RealtimeSessionId (List Evergreen.V296.Cloudflare.TrackName) (Result Effect.Http.Error Evergreen.V296.Cloudflare.PullTracksResult)
    | GotCloudflareRenegotiateAck Effect.Lamdera.ClientId Evergreen.V296.Local.ChangeId Evergreen.V296.Cloudflare.Sdp (Result Effect.Http.Error ())
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId) Evergreen.V296.Discord.UserAuth (Result Evergreen.V296.Discord.HttpError Evergreen.V296.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId) (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId) (Result Evergreen.V296.Discord.HttpError Evergreen.V296.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId)
        (Result
            Evergreen.V296.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V296.Discord.Id Evergreen.V296.Discord.PrivateChannelId
                , members : List (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId)
                }
            , List
                ( Evergreen.V296.Discord.Id Evergreen.V296.Discord.GuildId
                , { guild : Evergreen.V296.Discord.GatewayGuild
                  , channels : List Evergreen.V296.Discord.Channel
                  , icon : Maybe Evergreen.V296.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId) Bool Evergreen.V296.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V296.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V296.Discord.Id Evergreen.V296.Discord.AttachmentId, Evergreen.V296.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V296.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V296.Discord.Id Evergreen.V296.Discord.AttachmentId, Evergreen.V296.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId) (Evergreen.V296.Discord.Id Evergreen.V296.Discord.GuildId) (Evergreen.V296.Discord.Id Evergreen.V296.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V296.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V296.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId) (Evergreen.V296.Discord.Id Evergreen.V296.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V296.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V296.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId) (Evergreen.V296.Discord.Id Evergreen.V296.Discord.GuildId) (Evergreen.V296.Discord.Id Evergreen.V296.Discord.ChannelId) (Result Evergreen.V296.Discord.HttpError (List Evergreen.V296.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId) (Evergreen.V296.Discord.Id Evergreen.V296.Discord.PrivateChannelId) (Result Evergreen.V296.Discord.HttpError (List Evergreen.V296.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V296.Id.Id Evergreen.V296.Id.GuildId) (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelId) Evergreen.V296.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V296.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V296.DmChannel.DmChannelId Evergreen.V296.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V296.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V296.Discord.Id Evergreen.V296.Discord.GuildId) (Evergreen.V296.Discord.Id Evergreen.V296.Discord.ChannelId) Evergreen.V296.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V296.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V296.Discord.Id Evergreen.V296.Discord.PrivateChannelId) (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V296.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId)
        (Evergreen.V296.Discord.Id Evergreen.V296.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V296.Discord.HttpError
            { guild : Evergreen.V296.Discord.GatewayGuild
            , channels : List Evergreen.V296.Discord.Channel
            , icon : Maybe Evergreen.V296.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V296.Discord.Id Evergreen.V296.Discord.GuildId) (Result Evergreen.V296.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V296.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId) (List ( Evergreen.V296.Id.Id Evergreen.V296.Id.StickerId, Result Effect.Http.Error Evergreen.V296.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V296.Id.Id Evergreen.V296.Id.StickerId, Result Effect.Http.Error Evergreen.V296.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId) (List ( Evergreen.V296.Id.Id Evergreen.V296.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V296.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V296.Id.Id Evergreen.V296.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V296.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V296.Discord.HttpError (List Evergreen.V296.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V296.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V296.SecretId.SecretId Evergreen.V296.SecretId.ServerSecret))
    | GotTimeForWebsocketListenClose (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | GotCloudflareUsage Effect.Time.Posix (Result Effect.Http.Error Int)
    | GotCloudflareEgressForAdmin Effect.Lamdera.ClientId (Result Effect.Http.Error Int)
    | GotRustServerFileUpload Evergreen.V296.FileStatus.FileHash Int (Maybe (Evergreen.V296.Coord.Coord Evergreen.V296.CssPixels.CssPixels))
