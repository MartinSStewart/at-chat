module Evergreen.V289.Types exposing (..)

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
import Evergreen.V289.AiChat
import Evergreen.V289.Call
import Evergreen.V289.ChannelDescription
import Evergreen.V289.ChannelName
import Evergreen.V289.Cloudflare
import Evergreen.V289.Coord
import Evergreen.V289.CssPixels
import Evergreen.V289.CustomEmoji
import Evergreen.V289.Discord
import Evergreen.V289.DiscordAttachmentId
import Evergreen.V289.DiscordUserData
import Evergreen.V289.DmChannel
import Evergreen.V289.Drawing
import Evergreen.V289.Editable
import Evergreen.V289.EmailAddress
import Evergreen.V289.Embed
import Evergreen.V289.Emoji
import Evergreen.V289.FileStatus
import Evergreen.V289.Go
import Evergreen.V289.GuildName
import Evergreen.V289.Id
import Evergreen.V289.ImageEditor
import Evergreen.V289.ImageViewer
import Evergreen.V289.Local
import Evergreen.V289.LocalState
import Evergreen.V289.Log
import Evergreen.V289.LoginForm
import Evergreen.V289.MembersAndOwner
import Evergreen.V289.Message
import Evergreen.V289.MessageInput
import Evergreen.V289.MessageView
import Evergreen.V289.MyUi
import Evergreen.V289.NonemptyDict
import Evergreen.V289.NonemptySet
import Evergreen.V289.OneOrGreater
import Evergreen.V289.OneToOne
import Evergreen.V289.Pages.Admin
import Evergreen.V289.Pagination
import Evergreen.V289.PersonName
import Evergreen.V289.Ports
import Evergreen.V289.Postmark
import Evergreen.V289.Range
import Evergreen.V289.RichText
import Evergreen.V289.Route
import Evergreen.V289.SecretId
import Evergreen.V289.SessionIdHash
import Evergreen.V289.Slack
import Evergreen.V289.Sticker
import Evergreen.V289.TextEditor
import Evergreen.V289.ToBackendLog
import Evergreen.V289.Touch
import Evergreen.V289.TwoFactorAuthentication
import Evergreen.V289.Ui.Anim
import Evergreen.V289.Untrusted
import Evergreen.V289.User
import Evergreen.V289.UserAgent
import Evergreen.V289.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V289.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V289.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.Id.GuildId) Evergreen.V289.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId) Evergreen.V289.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V289.Discord.Id Evergreen.V289.Discord.PrivateChannelId) Evergreen.V289.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V289.Discord.Id Evergreen.V289.Discord.GuildId) Evergreen.V289.LocalState.DiscordFrontendGuild
    , user : Evergreen.V289.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId) Evergreen.V289.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId) Evergreen.V289.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId) Evergreen.V289.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V289.SessionIdHash.SessionIdHash Evergreen.V289.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V289.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.Id.StickerId) Evergreen.V289.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.Id.CustomEmojiId) Evergreen.V289.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V289.Call.CallId (Evergreen.V289.NonemptyDict.NonemptyDict ( Evergreen.V289.Id.Id Evergreen.V289.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V289.Call.RemoteCallData)
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type PublicGoMatch
    = PublicGoMatch_NotLoaded
    | PublicGoMatch_Loading
    | PublicGoMatch_Loaded Evergreen.V289.Go.PublicGoMatchData Evergreen.V289.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V289.Route.Route
    , windowSize : Evergreen.V289.Coord.Coord Evergreen.V289.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , timezone : Effect.Time.Zone
    , startupData : Maybe Evergreen.V289.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V289.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V289.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V289.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.FileStatus.FileId) Evergreen.V289.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V289.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V289.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.FileStatus.FileId) Evergreen.V289.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V289.Id.Id Evergreen.V289.Id.GuildId) Evergreen.V289.ChannelName.ChannelName Evergreen.V289.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V289.Id.Id Evergreen.V289.Id.GuildId) (Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelId) Evergreen.V289.ChannelName.ChannelName Evergreen.V289.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V289.Id.Id Evergreen.V289.Id.GuildId) (Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelId)
    | Local_DeleteGuild (Evergreen.V289.Id.Id Evergreen.V289.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V289.Id.Id Evergreen.V289.Id.GuildId) (Evergreen.V289.UserSession.ToBeFilledInByBackend (Evergreen.V289.SecretId.SecretId Evergreen.V289.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V289.Id.Id Evergreen.V289.Id.GuildId) (Evergreen.V289.SecretId.SecretId Evergreen.V289.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V289.GuildName.GuildName (Evergreen.V289.UserSession.ToBeFilledInByBackend (Evergreen.V289.Id.Id Evergreen.V289.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V289.Id.AnyGuildOrDmId, Evergreen.V289.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V289.Id.AnyGuildOrDmId Evergreen.V289.Id.ThreadRouteWithMessage Evergreen.V289.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V289.Id.AnyGuildOrDmId Evergreen.V289.Id.ThreadRouteWithMessage Evergreen.V289.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V289.Id.GuildOrDmId Evergreen.V289.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.FileStatus.FileId) Evergreen.V289.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId) (Evergreen.V289.Discord.Id Evergreen.V289.Discord.GuildId) (Evergreen.V289.Discord.Id Evergreen.V289.Discord.ChannelId) Evergreen.V289.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V289.Id.DiscordGuildOrDmId_DmData (Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V289.Id.AnyGuildOrDmId Evergreen.V289.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V289.Id.AnyGuildOrDmId Evergreen.V289.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V289.Id.AnyGuildOrDmId Evergreen.V289.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V289.UserSession.SetViewing
    | Local_SetName Evergreen.V289.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V289.Id.GuildOrDmId (Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelMessageId) (Evergreen.V289.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelMessageId) (Evergreen.V289.Message.Message Evergreen.V289.Id.ChannelMessageId (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V289.Id.GuildOrDmId (Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelMessageId) (Evergreen.V289.Id.Id Evergreen.V289.Id.ThreadMessageId) (Evergreen.V289.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.Id.ThreadMessageId) (Evergreen.V289.Message.Message Evergreen.V289.Id.ThreadMessageId (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V289.Id.DiscordGuildOrDmId (Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelMessageId) (Evergreen.V289.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelMessageId) (Evergreen.V289.Message.Message Evergreen.V289.Id.ChannelMessageId (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V289.Id.DiscordGuildOrDmId (Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelMessageId) (Evergreen.V289.Id.Id Evergreen.V289.Id.ThreadMessageId) (Evergreen.V289.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.Id.ThreadMessageId) (Evergreen.V289.Message.Message Evergreen.V289.Id.ThreadMessageId (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V289.Id.Id Evergreen.V289.Id.GuildId) Evergreen.V289.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId) (Evergreen.V289.Discord.Id Evergreen.V289.Discord.GuildId) Evergreen.V289.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V289.UserSession.NotificationMode
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V289.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V289.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V289.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V289.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V289.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V289.NonemptySet.NonemptySet (Evergreen.V289.Id.Id Evergreen.V289.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V289.Call.LocalChange
    | Local_Go
        { otherUserId : Evergreen.V289.Id.Id Evergreen.V289.Id.UserId
        }
        Evergreen.V289.Go.LocalChange
    | Local_Drawing Evergreen.V289.Id.AnyGuildOrDmId Evergreen.V289.Drawing.AnchorType Evergreen.V289.Drawing.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId) Effect.Time.Posix Evergreen.V289.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V289.RichText.RichText (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId))) Evergreen.V289.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.FileStatus.FileId) Evergreen.V289.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.Id.StickerId) Evergreen.V289.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V289.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V289.RichText.RichText (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId))) Evergreen.V289.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.FileStatus.FileId) Evergreen.V289.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.Id.StickerId) Evergreen.V289.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V289.Id.Id Evergreen.V289.Id.GuildId) Evergreen.V289.ChannelName.ChannelName Evergreen.V289.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V289.Id.Id Evergreen.V289.Id.GuildId) (Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelId) Evergreen.V289.ChannelName.ChannelName Evergreen.V289.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V289.Id.Id Evergreen.V289.Id.GuildId) (Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelId)
    | Server_DeleteGuild (Evergreen.V289.Id.Id Evergreen.V289.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId) (Evergreen.V289.Id.Id Evergreen.V289.Id.GuildId) (Evergreen.V289.SecretId.SecretId Evergreen.V289.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V289.Id.Id Evergreen.V289.Id.GuildId) (Evergreen.V289.SecretId.SecretId Evergreen.V289.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId) (Evergreen.V289.Id.Id Evergreen.V289.Id.GuildId) Evergreen.V289.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V289.LocalState.JoinGuildError
            { guildId : Evergreen.V289.Id.Id Evergreen.V289.Id.GuildId
            , guild : Evergreen.V289.LocalState.FrontendGuild
            , owner : Evergreen.V289.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId) Evergreen.V289.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId) Evergreen.V289.Id.GuildOrDmId Evergreen.V289.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId) (Evergreen.V289.Discord.Id Evergreen.V289.Discord.GuildId) (Evergreen.V289.Discord.Id Evergreen.V289.Discord.ChannelId) Evergreen.V289.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId) (Evergreen.V289.Discord.Id Evergreen.V289.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId) Evergreen.V289.Id.GuildOrDmId Evergreen.V289.Id.ThreadRouteWithMessage Evergreen.V289.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId) Evergreen.V289.Id.GuildOrDmId Evergreen.V289.Id.ThreadRouteWithMessage Evergreen.V289.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId) (Evergreen.V289.Discord.Id Evergreen.V289.Discord.GuildId) (Evergreen.V289.Discord.Id Evergreen.V289.Discord.ChannelId) Evergreen.V289.Id.ThreadRouteWithMessage Evergreen.V289.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId) (Evergreen.V289.Discord.Id Evergreen.V289.Discord.PrivateChannelId) (Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelMessageId) Evergreen.V289.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId) (Evergreen.V289.Discord.Id Evergreen.V289.Discord.GuildId) (Evergreen.V289.Discord.Id Evergreen.V289.Discord.ChannelId) Evergreen.V289.Id.ThreadRouteWithMessage Evergreen.V289.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId) (Evergreen.V289.Discord.Id Evergreen.V289.Discord.PrivateChannelId) (Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelMessageId) Evergreen.V289.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId) Evergreen.V289.Id.GuildOrDmId Evergreen.V289.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V289.RichText.RichText (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId))) (SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.FileStatus.FileId) Evergreen.V289.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId) (Evergreen.V289.Discord.Id Evergreen.V289.Discord.GuildId) (Evergreen.V289.Discord.Id Evergreen.V289.Discord.ChannelId) Evergreen.V289.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V289.RichText.RichText (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V289.Id.DiscordGuildOrDmId_DmData (Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V289.RichText.RichText (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId) Evergreen.V289.Id.AnyGuildOrDmId Evergreen.V289.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V289.Id.AnyGuildOrDmId Evergreen.V289.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V289.Discord.Id Evergreen.V289.Discord.GuildId) (Evergreen.V289.Discord.Id Evergreen.V289.Discord.ChannelId) Evergreen.V289.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V289.Discord.Id Evergreen.V289.Discord.PrivateChannelId) (Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId) Evergreen.V289.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId) Evergreen.V289.FileStatus.FileHash
    | Server_SetGuildIcon (Evergreen.V289.Id.Id Evergreen.V289.Id.GuildId) Evergreen.V289.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V289.Id.Id Evergreen.V289.Id.GuildId) Evergreen.V289.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V289.Discord.Id Evergreen.V289.Discord.GuildId) Evergreen.V289.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V289.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V289.SessionIdHash.SessionIdHash Evergreen.V289.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V289.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V289.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V289.Id.AnyGuildOrDmId, Evergreen.V289.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V289.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId) Evergreen.V289.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V289.Discord.Id Evergreen.V289.Discord.GuildId) (Evergreen.V289.Discord.Id Evergreen.V289.Discord.ChannelId) Evergreen.V289.ChannelName.ChannelName (Evergreen.V289.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V289.Discord.Id Evergreen.V289.Discord.PrivateChannelId)
        (Evergreen.V289.NonemptyDict.NonemptyDict
            (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V289.Discord.Id Evergreen.V289.Discord.GuildId) Evergreen.V289.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V289.Discord.Id Evergreen.V289.Discord.PrivateChannelId) Evergreen.V289.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId) Evergreen.V289.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId) (Maybe (Evergreen.V289.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V289.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V289.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V289.Id.Id Evergreen.V289.Id.GuildId) (Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelId) Evergreen.V289.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V289.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId) Evergreen.V289.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V289.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V289.Discord.Id Evergreen.V289.Discord.GuildId) (Evergreen.V289.Discord.Id Evergreen.V289.Discord.ChannelId) Evergreen.V289.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V289.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V289.Discord.Id Evergreen.V289.Discord.PrivateChannelId) (Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V289.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V289.Discord.Id Evergreen.V289.Discord.GuildId) Evergreen.V289.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V289.Discord.Id Evergreen.V289.Discord.GuildId) (Evergreen.V289.Discord.Id Evergreen.V289.Discord.ChannelId) (Evergreen.V289.Discord.OptionalData String) (Evergreen.V289.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V289.Discord.Id Evergreen.V289.Discord.GuildId)
        (Evergreen.V289.MembersAndOwner.MembersAndOwner
            (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V289.Discord.Id Evergreen.V289.Discord.GuildId) (Evergreen.V289.Discord.Id Evergreen.V289.Discord.ChannelId) (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId) Evergreen.V289.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.Id.StickerId) Evergreen.V289.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.Id.CustomEmojiId) Evergreen.V289.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V289.Call.ServerChange
    | Server_Go
        (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId)
        { otherUserId : Evergreen.V289.Id.Id Evergreen.V289.Id.UserId
        }
        Evergreen.V289.Go.LocalChange
    | Server_Drawing (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId) Evergreen.V289.Id.AnyGuildOrDmId Evergreen.V289.Drawing.AnchorType Evergreen.V289.Drawing.LocalChange


type LocalMsg
    = LocalChange (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V289.Id.Id Evergreen.V289.Id.GuildId) (Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelId) Evergreen.V289.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V289.Discord.Id Evergreen.V289.Discord.GuildId) (Evergreen.V289.Discord.Id Evergreen.V289.Discord.ChannelId) Evergreen.V289.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.FileStatus.FileId) Evergreen.V289.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V289.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V289.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V289.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V289.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V289.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V289.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V289.Coord.Coord Evergreen.V289.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V289.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V289.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V289.Id.AnyGuildOrDmId Evergreen.V289.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V289.Id.AnyGuildOrDmId Evergreen.V289.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V289.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V289.Coord.Coord Evergreen.V289.CssPixels.CssPixels) (Maybe Evergreen.V289.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V289.Id.AnyGuildOrDmId, Evergreen.V289.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelMessageId) (Evergreen.V289.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.Id.ThreadMessageId) (Evergreen.V289.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V289.Editable.Model
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
    | FileDragging Effect.Time.Posix Evergreen.V289.OneOrGreater.OneOrGreater


type alias LoggedIn2 =
    { localState : Evergreen.V289.Local.Local LocalMsg Evergreen.V289.LocalState.LocalState
    , admin : Evergreen.V289.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V289.Id.AnyGuildOrDmId, Evergreen.V289.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V289.Id.Id Evergreen.V289.Id.GuildId, Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V289.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V289.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V289.Id.AnyGuildOrDmId, Evergreen.V289.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V289.Id.AnyGuildOrDmId, Evergreen.V289.Id.ThreadRoute ) (Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : Evergreen.V289.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V289.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V289.Id.AnyGuildOrDmId, Evergreen.V289.Id.ThreadRoute ) (Evergreen.V289.NonemptyDict.NonemptyDict (Evergreen.V289.Id.Id Evergreen.V289.FileStatus.FileId) Evergreen.V289.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V289.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V289.TextEditor.Model
    , profilePictureEditor : Evergreen.V289.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V289.Id.Id Evergreen.V289.Id.GuildId, Evergreen.V289.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V289.Emoji.Model
    , voiceChat : Evergreen.V289.Call.Model
    , currentDmGoMatch : SeqDict.SeqDict ( Evergreen.V289.Id.Id Evergreen.V289.Id.UserId, Maybe (Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelMessageId) ) Evergreen.V289.Go.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V289.Drawing.Model
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V289.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V289.SecretId.SecretId Evergreen.V289.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V289.Range.Range
                , direction : Evergreen.V289.Range.SelectionDirection
                }
        }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V289.NonemptyDict.NonemptyDict Int Evergreen.V289.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V289.NonemptyDict.NonemptyDict Int Evergreen.V289.Touch.Touch
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
    | AdminToFrontend Evergreen.V289.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V289.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V289.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V289.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V289.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V289.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V289.Go.PublicGoMatchResponse)


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V289.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V289.Coord.Coord Evergreen.V289.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V289.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V289.MyUi.LastCopy
    , notificationPermission : Evergreen.V289.Ports.NotificationPermission
    , pwaStatus : Evergreen.V289.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V289.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V289.UserAgent.UserAgent
    , timeOrigin : Effect.Time.Posix
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V289.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V289.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V289.Id.Id Evergreen.V289.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V289.Id.Id Evergreen.V289.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V289.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V289.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V289.Coord.Coord Evergreen.V289.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V289.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V289.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V289.Id.Id Evergreen.V289.Id.GuildId, Evergreen.V289.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V289.DmChannel.DmChannelId, Evergreen.V289.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V289.Discord.Id Evergreen.V289.Discord.GuildId, Evergreen.V289.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V289.Discord.Id Evergreen.V289.Discord.PrivateChannelId, Evergreen.V289.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V289.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V289.NonemptyDict.NonemptyDict (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId) Evergreen.V289.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V289.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V289.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V289.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V289.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId) Evergreen.V289.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId) Evergreen.V289.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V289.Id.Id Evergreen.V289.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.Id.GuildId) Evergreen.V289.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.Id.GuildId) Evergreen.V289.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V289.Discord.Id Evergreen.V289.Discord.GuildId) Evergreen.V289.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V289.DmChannel.DmChannelId Evergreen.V289.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V289.Discord.Id Evergreen.V289.Discord.PrivateChannelId) Evergreen.V289.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V289.OneToOne.OneToOne (Evergreen.V289.Slack.Id Evergreen.V289.Slack.ChannelId) Evergreen.V289.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V289.OneToOne.OneToOne String (Evergreen.V289.Id.Id Evergreen.V289.Id.GuildId)
    , slackUsers : Evergreen.V289.OneToOne.OneToOne (Evergreen.V289.Slack.Id Evergreen.V289.Slack.UserId) (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId)
    , slackServers : Evergreen.V289.OneToOne.OneToOne (Evergreen.V289.Slack.Id Evergreen.V289.Slack.TeamId) (Evergreen.V289.Id.Id Evergreen.V289.Id.GuildId)
    , slackToken : Maybe Evergreen.V289.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V289.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V289.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V289.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V289.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V289.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V289.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V289.Cloudflare.AnalyticsApiToken
    , textEditor : Evergreen.V289.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId) Evergreen.V289.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId, Evergreen.V289.Discord.Id Evergreen.V289.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V289.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V289.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V289.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V289.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId) (Evergreen.V289.LocalState.LoadingDiscordChannel (List Evergreen.V289.Discord.Message))
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V289.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.Id.StickerId) Evergreen.V289.Sticker.StickerData
    , discordStickers : Evergreen.V289.OneToOne.OneToOne (Evergreen.V289.Discord.Id Evergreen.V289.Discord.StickerId) (Evergreen.V289.Id.Id Evergreen.V289.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.Id.CustomEmojiId) Evergreen.V289.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V289.OneToOne.OneToOne Evergreen.V289.RichText.DiscordCustomEmojiIdAndName (Evergreen.V289.Id.Id Evergreen.V289.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V289.Postmark.ApiKey
    , serverSecret : Evergreen.V289.SecretId.SecretId Evergreen.V289.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V289.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V289.OneToOne.OneToOne (Evergreen.V289.SecretId.SecretId Evergreen.V289.Id.GoMatchPublicId) ( Evergreen.V289.DmChannel.DmChannelId, Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelMessageId )
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V289.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V289.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V289.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V289.Route.Route
    | SelectedFilesToAttach ( Evergreen.V289.Id.AnyGuildOrDmId, Evergreen.V289.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V289.Id.Id Evergreen.V289.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V289.Id.Id Evergreen.V289.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V289.Id.Id Evergreen.V289.Id.GuildId) (Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelId) Evergreen.V289.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V289.Id.Id Evergreen.V289.Id.GuildId) (Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelId) Evergreen.V289.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V289.Discord.Id Evergreen.V289.Discord.GuildId) (Evergreen.V289.Discord.Id Evergreen.V289.Discord.ChannelId) Evergreen.V289.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V289.Discord.Id Evergreen.V289.Discord.GuildId) (Evergreen.V289.Discord.Id Evergreen.V289.Discord.ChannelId) Evergreen.V289.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V289.Id.Id Evergreen.V289.Id.GuildId) (Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V289.Id.Id Evergreen.V289.Id.GuildId) (Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V289.Id.Id Evergreen.V289.Id.GuildId) (Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V289.Id.Id Evergreen.V289.Id.GuildId) (Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V289.Id.Id Evergreen.V289.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V289.Id.Id Evergreen.V289.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V289.Id.Id Evergreen.V289.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V289.Id.Id Evergreen.V289.Id.GuildId) (Evergreen.V289.SecretId.SecretId Evergreen.V289.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V289.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V289.Id.AnyGuildOrDmId Evergreen.V289.Id.ThreadRouteWithMessage (Evergreen.V289.Coord.Coord Evergreen.V289.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V289.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V289.Id.AnyGuildOrDmId Evergreen.V289.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V289.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V289.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V289.Id.AnyGuildOrDmId, Evergreen.V289.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V289.Ports.NotificationPermission
    | TouchStart (Maybe ( Evergreen.V289.Id.AnyGuildOrDmId, Evergreen.V289.Id.ThreadRouteWithMessage, Bool )) Duration.Duration (Evergreen.V289.NonemptyDict.NonemptyDict Int Evergreen.V289.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V289.NonemptyDict.NonemptyDict Int Evergreen.V289.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V289.Id.AnyGuildOrDmId Evergreen.V289.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V289.Id.AnyGuildOrDmId Evergreen.V289.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V289.NonemptySet.NonemptySet (Evergreen.V289.Id.Id Evergreen.V289.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V289.Id.AnyGuildOrDmId, Evergreen.V289.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V289.Id.AnyGuildOrDmId Evergreen.V289.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V289.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V289.AiChat.Msg
    | GoMsg Evergreen.V289.Go.Msg
    | GoSpectatorMsg Evergreen.V289.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V289.Editable.Msg Evergreen.V289.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V289.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V289.Id.Id Evergreen.V289.Id.GuildId) Evergreen.V289.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V289.Id.AnyGuildOrDmId, Evergreen.V289.Id.ThreadRoute ) (Evergreen.V289.Id.Id Evergreen.V289.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V289.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V289.Id.AnyGuildOrDmId, Evergreen.V289.Id.ThreadRoute ) (Evergreen.V289.Id.Id Evergreen.V289.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V289.Id.AnyGuildOrDmId, Evergreen.V289.Id.ThreadRoute ) (Evergreen.V289.Id.Id Evergreen.V289.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V289.Id.AnyGuildOrDmId, Evergreen.V289.Id.ThreadRoute )
        { fileId : Evergreen.V289.Id.Id Evergreen.V289.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V289.Id.AnyGuildOrDmId, Evergreen.V289.Id.ThreadRoute ) (Evergreen.V289.Id.Id Evergreen.V289.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V289.Id.AnyGuildOrDmId, Evergreen.V289.Id.ThreadRoute ) (Evergreen.V289.Id.Id Evergreen.V289.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V289.Id.AnyGuildOrDmId, Evergreen.V289.Id.ThreadRoute )
        { fileId : Evergreen.V289.Id.Id Evergreen.V289.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V289.Id.AnyGuildOrDmId, Evergreen.V289.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V289.Id.AnyGuildOrDmId, Evergreen.V289.Id.ThreadRoute ) (Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelMessageId) (Evergreen.V289.Id.Id Evergreen.V289.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V289.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V289.Id.AnyGuildOrDmId, Evergreen.V289.Id.ThreadRoute ) (Evergreen.V289.Id.Id Evergreen.V289.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V289.Id.AnyGuildOrDmId Evergreen.V289.Id.ThreadRouteWithMessage Evergreen.V289.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V289.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V289.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V289.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V289.Id.Id Evergreen.V289.Id.GuildId) Evergreen.V289.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId) (Evergreen.V289.Discord.Id Evergreen.V289.Discord.GuildId) Evergreen.V289.User.NotificationLevel
    | GotStartupData Evergreen.V289.Ports.StartupData
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V289.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId
        , otherUserId : Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V289.Id.AnyGuildOrDmId Evergreen.V289.Id.ThreadRoute Evergreen.V289.MessageInput.Msg
    | MessageInputMsg Evergreen.V289.Id.AnyGuildOrDmId Evergreen.V289.Id.ThreadRoute Evergreen.V289.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V289.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V289.Range.Range, Evergreen.V289.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V289.Range.Range, Evergreen.V289.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V289.Call.FromJs)
    | VoiceChatMsg Evergreen.V289.Call.Msg
    | PressedChannelHeaderTab Evergreen.V289.Route.DmChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadServiceWorkerData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V289.Drawing.Msg


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V289.Id.Id Evergreen.V289.Id.GuildId) (Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelId) Evergreen.V289.Id.ThreadRoute
    | InitialLoadRequested_Dm Evergreen.V289.DmChannel.DmChannelId Evergreen.V289.Id.ThreadRoute
    | InitialLoadRequested_Discord Evergreen.V289.Id.DiscordGuildOrDmId Evergreen.V289.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V289.Id.Id Evergreen.V289.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V289.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V289.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V289.Untrusted.Untrusted Evergreen.V289.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V289.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V289.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V289.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V289.Id.Id Evergreen.V289.Id.GuildId) (Evergreen.V289.SecretId.SecretId Evergreen.V289.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V289.PersonName.PersonName Evergreen.V289.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V289.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V289.Slack.OAuthCode Evergreen.V289.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V289.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V289.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V289.Id.Id Evergreen.V289.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V289.SecretId.SecretId Evergreen.V289.Id.GoMatchPublicId)


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V289.Discord.Id Evergreen.V289.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V289.Discord.Id Evergreen.V289.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V289.EmailAddress.EmailAddress (Result Evergreen.V289.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V289.EmailAddress.EmailAddress (Result Evergreen.V289.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V289.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V289.Discord.Id Evergreen.V289.Discord.GuildId) (Evergreen.V289.Discord.Id Evergreen.V289.Discord.ChannelId) Evergreen.V289.Id.ThreadRouteWithMaybeMessage (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId) (Result Evergreen.V289.Discord.HttpError Evergreen.V289.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V289.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V289.Discord.Id Evergreen.V289.Discord.PrivateChannelId) (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId) (Result Evergreen.V289.Discord.HttpError Evergreen.V289.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V289.Discord.Id Evergreen.V289.Discord.GuildId) (Evergreen.V289.Discord.Id Evergreen.V289.Discord.ChannelId) Evergreen.V289.Id.ThreadRouteWithMessage (Evergreen.V289.Discord.Id Evergreen.V289.Discord.MessageId) (Result Evergreen.V289.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V289.Discord.Id Evergreen.V289.Discord.PrivateChannelId) (Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelMessageId) (Evergreen.V289.Discord.Id Evergreen.V289.Discord.MessageId) (Result Evergreen.V289.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V289.Discord.Id Evergreen.V289.Discord.GuildId) (Evergreen.V289.Discord.Id Evergreen.V289.Discord.ChannelId) Evergreen.V289.Id.ThreadRouteWithMessage (Evergreen.V289.Discord.Id Evergreen.V289.Discord.MessageId) (Result Evergreen.V289.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V289.Discord.Id Evergreen.V289.Discord.PrivateChannelId) (Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelMessageId) (Evergreen.V289.Discord.Id Evergreen.V289.Discord.MessageId) (Result Evergreen.V289.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V289.Discord.Id Evergreen.V289.Discord.GuildId) (Evergreen.V289.Discord.Id Evergreen.V289.Discord.ChannelId) Evergreen.V289.Id.ThreadRouteWithMessage (Evergreen.V289.Discord.Id Evergreen.V289.Discord.MessageId) Evergreen.V289.Emoji.EmojiOrCustomEmoji (Result Evergreen.V289.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V289.Discord.Id Evergreen.V289.Discord.PrivateChannelId) (Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelMessageId) (Evergreen.V289.Discord.Id Evergreen.V289.Discord.MessageId) Evergreen.V289.Emoji.EmojiOrCustomEmoji (Result Evergreen.V289.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V289.Discord.Id Evergreen.V289.Discord.GuildId) (Evergreen.V289.Discord.Id Evergreen.V289.Discord.ChannelId) Evergreen.V289.Id.ThreadRouteWithMessage (Evergreen.V289.Discord.Id Evergreen.V289.Discord.MessageId) Evergreen.V289.Emoji.EmojiOrCustomEmoji (Result Evergreen.V289.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V289.Discord.Id Evergreen.V289.Discord.PrivateChannelId) (Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelMessageId) (Evergreen.V289.Discord.Id Evergreen.V289.Discord.MessageId) Evergreen.V289.Emoji.EmojiOrCustomEmoji (Result Evergreen.V289.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V289.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V289.Discord.HttpError (List ( Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId, Maybe Evergreen.V289.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId) Effect.Time.Posix Evergreen.V289.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V289.Slack.CurrentUser
            , team : Evergreen.V289.Slack.Team
            , users : List Evergreen.V289.Slack.User
            , channels : List ( Evergreen.V289.Slack.Channel, List Evergreen.V289.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId) (Result Effect.Http.Error Evergreen.V289.Slack.TokenResponse)
    | GotCloudflareSessionCreated Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V289.Local.ChangeId Effect.Time.Posix Evergreen.V289.Call.CallId Evergreen.V289.Cloudflare.Sdp (List String) (Result Effect.Http.Error Evergreen.V289.Cloudflare.RealtimeSessionId)
    | GotCloudflareSession Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V289.Local.ChangeId Effect.Time.Posix Evergreen.V289.Call.CallId Evergreen.V289.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V289.Cloudflare.PushTracksResult)
    | GotCloudflarePullOffer Effect.Time.Posix Effect.Lamdera.ClientId Evergreen.V289.Local.ChangeId Evergreen.V289.Call.ConnectionId Evergreen.V289.Cloudflare.RealtimeSessionId (List Evergreen.V289.Cloudflare.TrackName) (Result Effect.Http.Error Evergreen.V289.Cloudflare.PullTracksResult)
    | GotCloudflareRenegotiateAck Effect.Lamdera.ClientId Evergreen.V289.Local.ChangeId Evergreen.V289.Cloudflare.Sdp (Result Effect.Http.Error ())
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId) Evergreen.V289.Discord.UserAuth (Result Evergreen.V289.Discord.HttpError Evergreen.V289.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId) (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId) (Result Evergreen.V289.Discord.HttpError Evergreen.V289.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId)
        (Result
            Evergreen.V289.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V289.Discord.Id Evergreen.V289.Discord.PrivateChannelId
                , members : List (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId)
                }
            , List
                ( Evergreen.V289.Discord.Id Evergreen.V289.Discord.GuildId
                , { guild : Evergreen.V289.Discord.GatewayGuild
                  , channels : List Evergreen.V289.Discord.Channel
                  , icon : Maybe Evergreen.V289.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId) Bool Evergreen.V289.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V289.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V289.Discord.Id Evergreen.V289.Discord.AttachmentId, Evergreen.V289.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V289.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V289.Discord.Id Evergreen.V289.Discord.AttachmentId, Evergreen.V289.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId) (Evergreen.V289.Discord.Id Evergreen.V289.Discord.GuildId) (Evergreen.V289.Discord.Id Evergreen.V289.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V289.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V289.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId) (Evergreen.V289.Discord.Id Evergreen.V289.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V289.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V289.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId) (Evergreen.V289.Discord.Id Evergreen.V289.Discord.GuildId) (Evergreen.V289.Discord.Id Evergreen.V289.Discord.ChannelId) (Result Evergreen.V289.Discord.HttpError (List Evergreen.V289.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId) (Evergreen.V289.Discord.Id Evergreen.V289.Discord.PrivateChannelId) (Result Evergreen.V289.Discord.HttpError (List Evergreen.V289.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V289.Id.Id Evergreen.V289.Id.GuildId) (Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelId) Evergreen.V289.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V289.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V289.DmChannel.DmChannelId Evergreen.V289.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V289.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V289.Discord.Id Evergreen.V289.Discord.GuildId) (Evergreen.V289.Discord.Id Evergreen.V289.Discord.ChannelId) Evergreen.V289.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V289.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V289.Discord.Id Evergreen.V289.Discord.PrivateChannelId) (Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V289.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId)
        (Evergreen.V289.Discord.Id Evergreen.V289.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V289.Discord.HttpError
            { guild : Evergreen.V289.Discord.GatewayGuild
            , channels : List Evergreen.V289.Discord.Channel
            , icon : Maybe Evergreen.V289.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V289.Discord.Id Evergreen.V289.Discord.GuildId) (Result Evergreen.V289.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V289.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId) (List ( Evergreen.V289.Id.Id Evergreen.V289.Id.StickerId, Result Effect.Http.Error Evergreen.V289.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V289.Id.Id Evergreen.V289.Id.StickerId, Result Effect.Http.Error Evergreen.V289.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId) (List ( Evergreen.V289.Id.Id Evergreen.V289.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V289.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V289.Id.Id Evergreen.V289.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V289.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V289.Discord.HttpError (List Evergreen.V289.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V289.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V289.SecretId.SecretId Evergreen.V289.SecretId.ServerSecret))
    | GotTimeForWebsocketListenClose (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | GotCloudflareUsage Effect.Time.Posix (Result Effect.Http.Error Int)
    | GotCloudflareEgressForAdmin Effect.Lamdera.ClientId (Result Effect.Http.Error Int)
    | GotRustServerFileUpload Evergreen.V289.FileStatus.FileHash Int (Maybe (Evergreen.V289.Coord.Coord Evergreen.V289.CssPixels.CssPixels))
