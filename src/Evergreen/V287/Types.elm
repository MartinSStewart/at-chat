module Evergreen.V287.Types exposing (..)

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
import Evergreen.V287.AiChat
import Evergreen.V287.Call
import Evergreen.V287.ChannelDescription
import Evergreen.V287.ChannelName
import Evergreen.V287.Cloudflare
import Evergreen.V287.Coord
import Evergreen.V287.CssPixels
import Evergreen.V287.CustomEmoji
import Evergreen.V287.Discord
import Evergreen.V287.DiscordAttachmentId
import Evergreen.V287.DiscordUserData
import Evergreen.V287.DmChannel
import Evergreen.V287.Drawing
import Evergreen.V287.Editable
import Evergreen.V287.EmailAddress
import Evergreen.V287.Embed
import Evergreen.V287.Emoji
import Evergreen.V287.FileStatus
import Evergreen.V287.Go
import Evergreen.V287.GuildName
import Evergreen.V287.Id
import Evergreen.V287.ImageEditor
import Evergreen.V287.ImageViewer
import Evergreen.V287.Local
import Evergreen.V287.LocalState
import Evergreen.V287.Log
import Evergreen.V287.LoginForm
import Evergreen.V287.MembersAndOwner
import Evergreen.V287.Message
import Evergreen.V287.MessageInput
import Evergreen.V287.MessageView
import Evergreen.V287.MyUi
import Evergreen.V287.NonemptyDict
import Evergreen.V287.NonemptySet
import Evergreen.V287.OneOrGreater
import Evergreen.V287.OneToOne
import Evergreen.V287.Pages.Admin
import Evergreen.V287.Pagination
import Evergreen.V287.PersonName
import Evergreen.V287.Ports
import Evergreen.V287.Postmark
import Evergreen.V287.Range
import Evergreen.V287.RichText
import Evergreen.V287.Route
import Evergreen.V287.SecretId
import Evergreen.V287.SessionIdHash
import Evergreen.V287.Slack
import Evergreen.V287.Sticker
import Evergreen.V287.TextEditor
import Evergreen.V287.ToBackendLog
import Evergreen.V287.Touch
import Evergreen.V287.TwoFactorAuthentication
import Evergreen.V287.Ui.Anim
import Evergreen.V287.Untrusted
import Evergreen.V287.User
import Evergreen.V287.UserAgent
import Evergreen.V287.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V287.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V287.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.Id.GuildId) Evergreen.V287.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId) Evergreen.V287.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V287.Discord.Id Evergreen.V287.Discord.PrivateChannelId) Evergreen.V287.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V287.Discord.Id Evergreen.V287.Discord.GuildId) Evergreen.V287.LocalState.DiscordFrontendGuild
    , user : Evergreen.V287.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId) Evergreen.V287.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId) Evergreen.V287.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId) Evergreen.V287.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V287.SessionIdHash.SessionIdHash Evergreen.V287.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V287.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.Id.StickerId) Evergreen.V287.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.Id.CustomEmojiId) Evergreen.V287.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V287.Call.CallId (Evergreen.V287.NonemptyDict.NonemptyDict ( Evergreen.V287.Id.Id Evergreen.V287.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V287.Call.RemoteCallData)
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type PublicGoMatch
    = PublicGoMatch_NotLoaded
    | PublicGoMatch_Loading
    | PublicGoMatch_Loaded Evergreen.V287.Go.PublicGoMatchData Evergreen.V287.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V287.Route.Route
    , windowSize : Evergreen.V287.Coord.Coord Evergreen.V287.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , timezone : Effect.Time.Zone
    , startupData : Maybe Evergreen.V287.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V287.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V287.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V287.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.FileStatus.FileId) Evergreen.V287.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V287.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V287.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.FileStatus.FileId) Evergreen.V287.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V287.Id.Id Evergreen.V287.Id.GuildId) Evergreen.V287.ChannelName.ChannelName Evergreen.V287.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V287.Id.Id Evergreen.V287.Id.GuildId) (Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelId) Evergreen.V287.ChannelName.ChannelName Evergreen.V287.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V287.Id.Id Evergreen.V287.Id.GuildId) (Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelId)
    | Local_DeleteGuild (Evergreen.V287.Id.Id Evergreen.V287.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V287.Id.Id Evergreen.V287.Id.GuildId) (Evergreen.V287.UserSession.ToBeFilledInByBackend (Evergreen.V287.SecretId.SecretId Evergreen.V287.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V287.Id.Id Evergreen.V287.Id.GuildId) (Evergreen.V287.SecretId.SecretId Evergreen.V287.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V287.GuildName.GuildName (Evergreen.V287.UserSession.ToBeFilledInByBackend (Evergreen.V287.Id.Id Evergreen.V287.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V287.Id.AnyGuildOrDmId, Evergreen.V287.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V287.Id.AnyGuildOrDmId Evergreen.V287.Id.ThreadRouteWithMessage Evergreen.V287.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V287.Id.AnyGuildOrDmId Evergreen.V287.Id.ThreadRouteWithMessage Evergreen.V287.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V287.Id.GuildOrDmId Evergreen.V287.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.FileStatus.FileId) Evergreen.V287.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId) (Evergreen.V287.Discord.Id Evergreen.V287.Discord.GuildId) (Evergreen.V287.Discord.Id Evergreen.V287.Discord.ChannelId) Evergreen.V287.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V287.Id.DiscordGuildOrDmId_DmData (Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V287.Id.AnyGuildOrDmId Evergreen.V287.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V287.Id.AnyGuildOrDmId Evergreen.V287.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V287.Id.AnyGuildOrDmId Evergreen.V287.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V287.UserSession.SetViewing
    | Local_SetName Evergreen.V287.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V287.Id.GuildOrDmId (Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelMessageId) (Evergreen.V287.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelMessageId) (Evergreen.V287.Message.Message Evergreen.V287.Id.ChannelMessageId (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V287.Id.GuildOrDmId (Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelMessageId) (Evergreen.V287.Id.Id Evergreen.V287.Id.ThreadMessageId) (Evergreen.V287.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.Id.ThreadMessageId) (Evergreen.V287.Message.Message Evergreen.V287.Id.ThreadMessageId (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V287.Id.DiscordGuildOrDmId (Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelMessageId) (Evergreen.V287.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelMessageId) (Evergreen.V287.Message.Message Evergreen.V287.Id.ChannelMessageId (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V287.Id.DiscordGuildOrDmId (Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelMessageId) (Evergreen.V287.Id.Id Evergreen.V287.Id.ThreadMessageId) (Evergreen.V287.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.Id.ThreadMessageId) (Evergreen.V287.Message.Message Evergreen.V287.Id.ThreadMessageId (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V287.Id.Id Evergreen.V287.Id.GuildId) Evergreen.V287.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId) (Evergreen.V287.Discord.Id Evergreen.V287.Discord.GuildId) Evergreen.V287.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V287.UserSession.NotificationMode
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V287.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V287.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V287.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V287.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V287.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V287.NonemptySet.NonemptySet (Evergreen.V287.Id.Id Evergreen.V287.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V287.Call.LocalChange
    | Local_Go
        { otherUserId : Evergreen.V287.Id.Id Evergreen.V287.Id.UserId
        }
        Evergreen.V287.Go.LocalChange
    | Local_Drawing Evergreen.V287.Id.AnyGuildOrDmId Evergreen.V287.Drawing.AnchorType Evergreen.V287.Drawing.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId) Effect.Time.Posix Evergreen.V287.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V287.RichText.RichText (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId))) Evergreen.V287.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.FileStatus.FileId) Evergreen.V287.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.Id.StickerId) Evergreen.V287.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V287.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V287.RichText.RichText (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId))) Evergreen.V287.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.FileStatus.FileId) Evergreen.V287.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.Id.StickerId) Evergreen.V287.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V287.Id.Id Evergreen.V287.Id.GuildId) Evergreen.V287.ChannelName.ChannelName Evergreen.V287.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V287.Id.Id Evergreen.V287.Id.GuildId) (Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelId) Evergreen.V287.ChannelName.ChannelName Evergreen.V287.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V287.Id.Id Evergreen.V287.Id.GuildId) (Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelId)
    | Server_DeleteGuild (Evergreen.V287.Id.Id Evergreen.V287.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId) (Evergreen.V287.Id.Id Evergreen.V287.Id.GuildId) (Evergreen.V287.SecretId.SecretId Evergreen.V287.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V287.Id.Id Evergreen.V287.Id.GuildId) (Evergreen.V287.SecretId.SecretId Evergreen.V287.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId) (Evergreen.V287.Id.Id Evergreen.V287.Id.GuildId) Evergreen.V287.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V287.LocalState.JoinGuildError
            { guildId : Evergreen.V287.Id.Id Evergreen.V287.Id.GuildId
            , guild : Evergreen.V287.LocalState.FrontendGuild
            , owner : Evergreen.V287.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId) Evergreen.V287.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId) Evergreen.V287.Id.GuildOrDmId Evergreen.V287.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId) (Evergreen.V287.Discord.Id Evergreen.V287.Discord.GuildId) (Evergreen.V287.Discord.Id Evergreen.V287.Discord.ChannelId) Evergreen.V287.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId) (Evergreen.V287.Discord.Id Evergreen.V287.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId) Evergreen.V287.Id.GuildOrDmId Evergreen.V287.Id.ThreadRouteWithMessage Evergreen.V287.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId) Evergreen.V287.Id.GuildOrDmId Evergreen.V287.Id.ThreadRouteWithMessage Evergreen.V287.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId) (Evergreen.V287.Discord.Id Evergreen.V287.Discord.GuildId) (Evergreen.V287.Discord.Id Evergreen.V287.Discord.ChannelId) Evergreen.V287.Id.ThreadRouteWithMessage Evergreen.V287.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId) (Evergreen.V287.Discord.Id Evergreen.V287.Discord.PrivateChannelId) (Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelMessageId) Evergreen.V287.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId) (Evergreen.V287.Discord.Id Evergreen.V287.Discord.GuildId) (Evergreen.V287.Discord.Id Evergreen.V287.Discord.ChannelId) Evergreen.V287.Id.ThreadRouteWithMessage Evergreen.V287.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId) (Evergreen.V287.Discord.Id Evergreen.V287.Discord.PrivateChannelId) (Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelMessageId) Evergreen.V287.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId) Evergreen.V287.Id.GuildOrDmId Evergreen.V287.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V287.RichText.RichText (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId))) (SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.FileStatus.FileId) Evergreen.V287.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId) (Evergreen.V287.Discord.Id Evergreen.V287.Discord.GuildId) (Evergreen.V287.Discord.Id Evergreen.V287.Discord.ChannelId) Evergreen.V287.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V287.RichText.RichText (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V287.Id.DiscordGuildOrDmId_DmData (Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V287.RichText.RichText (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId) Evergreen.V287.Id.AnyGuildOrDmId Evergreen.V287.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V287.Id.AnyGuildOrDmId Evergreen.V287.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V287.Discord.Id Evergreen.V287.Discord.GuildId) (Evergreen.V287.Discord.Id Evergreen.V287.Discord.ChannelId) Evergreen.V287.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V287.Discord.Id Evergreen.V287.Discord.PrivateChannelId) (Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId) Evergreen.V287.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId) Evergreen.V287.FileStatus.FileHash
    | Server_SetGuildIcon (Evergreen.V287.Id.Id Evergreen.V287.Id.GuildId) Evergreen.V287.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V287.Id.Id Evergreen.V287.Id.GuildId) Evergreen.V287.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V287.Discord.Id Evergreen.V287.Discord.GuildId) Evergreen.V287.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V287.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V287.SessionIdHash.SessionIdHash Evergreen.V287.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V287.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V287.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V287.Id.AnyGuildOrDmId, Evergreen.V287.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V287.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId) Evergreen.V287.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V287.Discord.Id Evergreen.V287.Discord.GuildId) (Evergreen.V287.Discord.Id Evergreen.V287.Discord.ChannelId) Evergreen.V287.ChannelName.ChannelName (Evergreen.V287.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V287.Discord.Id Evergreen.V287.Discord.PrivateChannelId)
        (Evergreen.V287.NonemptyDict.NonemptyDict
            (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V287.Discord.Id Evergreen.V287.Discord.GuildId) Evergreen.V287.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V287.Discord.Id Evergreen.V287.Discord.PrivateChannelId) Evergreen.V287.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId) Evergreen.V287.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId) (Maybe (Evergreen.V287.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V287.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V287.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V287.Id.Id Evergreen.V287.Id.GuildId) (Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelId) Evergreen.V287.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V287.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId) Evergreen.V287.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V287.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V287.Discord.Id Evergreen.V287.Discord.GuildId) (Evergreen.V287.Discord.Id Evergreen.V287.Discord.ChannelId) Evergreen.V287.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V287.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V287.Discord.Id Evergreen.V287.Discord.PrivateChannelId) (Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V287.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V287.Discord.Id Evergreen.V287.Discord.GuildId) Evergreen.V287.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V287.Discord.Id Evergreen.V287.Discord.GuildId) (Evergreen.V287.Discord.Id Evergreen.V287.Discord.ChannelId) (Evergreen.V287.Discord.OptionalData String) (Evergreen.V287.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V287.Discord.Id Evergreen.V287.Discord.GuildId)
        (Evergreen.V287.MembersAndOwner.MembersAndOwner
            (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V287.Discord.Id Evergreen.V287.Discord.GuildId) (Evergreen.V287.Discord.Id Evergreen.V287.Discord.ChannelId) (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId) Evergreen.V287.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.Id.StickerId) Evergreen.V287.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.Id.CustomEmojiId) Evergreen.V287.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V287.Call.ServerChange
    | Server_Go
        (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId)
        { otherUserId : Evergreen.V287.Id.Id Evergreen.V287.Id.UserId
        }
        Evergreen.V287.Go.LocalChange
    | Server_Drawing (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId) Evergreen.V287.Id.AnyGuildOrDmId Evergreen.V287.Drawing.AnchorType Evergreen.V287.Drawing.LocalChange


type LocalMsg
    = LocalChange (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V287.Id.Id Evergreen.V287.Id.GuildId) (Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelId) Evergreen.V287.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V287.Discord.Id Evergreen.V287.Discord.GuildId) (Evergreen.V287.Discord.Id Evergreen.V287.Discord.ChannelId) Evergreen.V287.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.FileStatus.FileId) Evergreen.V287.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V287.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V287.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V287.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V287.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V287.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V287.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V287.Coord.Coord Evergreen.V287.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V287.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V287.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V287.Id.AnyGuildOrDmId Evergreen.V287.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V287.Id.AnyGuildOrDmId Evergreen.V287.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V287.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V287.Coord.Coord Evergreen.V287.CssPixels.CssPixels) (Maybe Evergreen.V287.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V287.Id.AnyGuildOrDmId, Evergreen.V287.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelMessageId) (Evergreen.V287.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.Id.ThreadMessageId) (Evergreen.V287.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V287.Editable.Model
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
    | FileDragging Effect.Time.Posix Evergreen.V287.OneOrGreater.OneOrGreater


type alias LoggedIn2 =
    { localState : Evergreen.V287.Local.Local LocalMsg Evergreen.V287.LocalState.LocalState
    , admin : Evergreen.V287.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V287.Id.AnyGuildOrDmId, Evergreen.V287.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V287.Id.Id Evergreen.V287.Id.GuildId, Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V287.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V287.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V287.Id.AnyGuildOrDmId, Evergreen.V287.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V287.Id.AnyGuildOrDmId, Evergreen.V287.Id.ThreadRoute ) (Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : Evergreen.V287.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V287.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V287.Id.AnyGuildOrDmId, Evergreen.V287.Id.ThreadRoute ) (Evergreen.V287.NonemptyDict.NonemptyDict (Evergreen.V287.Id.Id Evergreen.V287.FileStatus.FileId) Evergreen.V287.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V287.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V287.TextEditor.Model
    , profilePictureEditor : Evergreen.V287.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V287.Id.Id Evergreen.V287.Id.GuildId, Evergreen.V287.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V287.Emoji.Model
    , voiceChat : Evergreen.V287.Call.Model
    , currentDmGoMatch : SeqDict.SeqDict ( Evergreen.V287.Id.Id Evergreen.V287.Id.UserId, Maybe (Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelMessageId) ) Evergreen.V287.Go.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V287.Drawing.Model
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V287.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V287.SecretId.SecretId Evergreen.V287.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V287.Range.Range
                , direction : Evergreen.V287.Range.SelectionDirection
                }
        }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V287.NonemptyDict.NonemptyDict Int Evergreen.V287.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V287.NonemptyDict.NonemptyDict Int Evergreen.V287.Touch.Touch
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
    | AdminToFrontend Evergreen.V287.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V287.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V287.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V287.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V287.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V287.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V287.Go.PublicGoMatchResponse)


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V287.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V287.Coord.Coord Evergreen.V287.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V287.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V287.MyUi.LastCopy
    , notificationPermission : Evergreen.V287.Ports.NotificationPermission
    , pwaStatus : Evergreen.V287.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V287.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V287.UserAgent.UserAgent
    , timeOrigin : Effect.Time.Posix
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V287.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V287.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V287.Id.Id Evergreen.V287.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V287.Id.Id Evergreen.V287.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V287.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V287.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V287.Coord.Coord Evergreen.V287.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V287.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V287.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V287.Id.Id Evergreen.V287.Id.GuildId, Evergreen.V287.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V287.DmChannel.DmChannelId, Evergreen.V287.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V287.Discord.Id Evergreen.V287.Discord.GuildId, Evergreen.V287.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V287.Discord.Id Evergreen.V287.Discord.PrivateChannelId, Evergreen.V287.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V287.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V287.NonemptyDict.NonemptyDict (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId) Evergreen.V287.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V287.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V287.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V287.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V287.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId) Evergreen.V287.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId) Evergreen.V287.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V287.Id.Id Evergreen.V287.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.Id.GuildId) Evergreen.V287.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.Id.GuildId) Evergreen.V287.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V287.Discord.Id Evergreen.V287.Discord.GuildId) Evergreen.V287.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V287.DmChannel.DmChannelId Evergreen.V287.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V287.Discord.Id Evergreen.V287.Discord.PrivateChannelId) Evergreen.V287.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V287.OneToOne.OneToOne (Evergreen.V287.Slack.Id Evergreen.V287.Slack.ChannelId) Evergreen.V287.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V287.OneToOne.OneToOne String (Evergreen.V287.Id.Id Evergreen.V287.Id.GuildId)
    , slackUsers : Evergreen.V287.OneToOne.OneToOne (Evergreen.V287.Slack.Id Evergreen.V287.Slack.UserId) (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId)
    , slackServers : Evergreen.V287.OneToOne.OneToOne (Evergreen.V287.Slack.Id Evergreen.V287.Slack.TeamId) (Evergreen.V287.Id.Id Evergreen.V287.Id.GuildId)
    , slackToken : Maybe Evergreen.V287.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V287.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V287.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V287.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V287.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V287.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V287.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V287.Cloudflare.AnalyticsApiToken
    , textEditor : Evergreen.V287.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId) Evergreen.V287.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId, Evergreen.V287.Discord.Id Evergreen.V287.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V287.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V287.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V287.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V287.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId) (Evergreen.V287.LocalState.LoadingDiscordChannel (List Evergreen.V287.Discord.Message))
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V287.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.Id.StickerId) Evergreen.V287.Sticker.StickerData
    , discordStickers : Evergreen.V287.OneToOne.OneToOne (Evergreen.V287.Discord.Id Evergreen.V287.Discord.StickerId) (Evergreen.V287.Id.Id Evergreen.V287.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.Id.CustomEmojiId) Evergreen.V287.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V287.OneToOne.OneToOne Evergreen.V287.RichText.DiscordCustomEmojiIdAndName (Evergreen.V287.Id.Id Evergreen.V287.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V287.Postmark.ApiKey
    , serverSecret : Evergreen.V287.SecretId.SecretId Evergreen.V287.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V287.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V287.OneToOne.OneToOne (Evergreen.V287.SecretId.SecretId Evergreen.V287.Id.GoMatchPublicId) ( Evergreen.V287.DmChannel.DmChannelId, Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelMessageId )
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V287.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V287.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V287.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V287.Route.Route
    | SelectedFilesToAttach ( Evergreen.V287.Id.AnyGuildOrDmId, Evergreen.V287.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V287.Id.Id Evergreen.V287.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V287.Id.Id Evergreen.V287.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V287.Id.Id Evergreen.V287.Id.GuildId) (Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelId) Evergreen.V287.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V287.Id.Id Evergreen.V287.Id.GuildId) (Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelId) Evergreen.V287.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V287.Discord.Id Evergreen.V287.Discord.GuildId) (Evergreen.V287.Discord.Id Evergreen.V287.Discord.ChannelId) Evergreen.V287.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V287.Discord.Id Evergreen.V287.Discord.GuildId) (Evergreen.V287.Discord.Id Evergreen.V287.Discord.ChannelId) Evergreen.V287.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V287.Id.Id Evergreen.V287.Id.GuildId) (Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V287.Id.Id Evergreen.V287.Id.GuildId) (Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V287.Id.Id Evergreen.V287.Id.GuildId) (Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V287.Id.Id Evergreen.V287.Id.GuildId) (Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V287.Id.Id Evergreen.V287.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V287.Id.Id Evergreen.V287.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V287.Id.Id Evergreen.V287.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V287.Id.Id Evergreen.V287.Id.GuildId) (Evergreen.V287.SecretId.SecretId Evergreen.V287.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V287.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V287.Id.AnyGuildOrDmId Evergreen.V287.Id.ThreadRouteWithMessage (Evergreen.V287.Coord.Coord Evergreen.V287.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V287.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V287.Id.AnyGuildOrDmId Evergreen.V287.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V287.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V287.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V287.Id.AnyGuildOrDmId, Evergreen.V287.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V287.Ports.NotificationPermission
    | TouchStart (Maybe ( Evergreen.V287.Id.AnyGuildOrDmId, Evergreen.V287.Id.ThreadRouteWithMessage, Bool )) Duration.Duration (Evergreen.V287.NonemptyDict.NonemptyDict Int Evergreen.V287.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V287.NonemptyDict.NonemptyDict Int Evergreen.V287.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V287.Id.AnyGuildOrDmId Evergreen.V287.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V287.Id.AnyGuildOrDmId Evergreen.V287.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V287.NonemptySet.NonemptySet (Evergreen.V287.Id.Id Evergreen.V287.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V287.Id.AnyGuildOrDmId, Evergreen.V287.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V287.Id.AnyGuildOrDmId Evergreen.V287.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V287.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V287.AiChat.Msg
    | GoMsg Evergreen.V287.Go.Msg
    | GoSpectatorMsg Evergreen.V287.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V287.Editable.Msg Evergreen.V287.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V287.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V287.Id.Id Evergreen.V287.Id.GuildId) Evergreen.V287.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V287.Id.AnyGuildOrDmId, Evergreen.V287.Id.ThreadRoute ) (Evergreen.V287.Id.Id Evergreen.V287.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V287.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V287.Id.AnyGuildOrDmId, Evergreen.V287.Id.ThreadRoute ) (Evergreen.V287.Id.Id Evergreen.V287.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V287.Id.AnyGuildOrDmId, Evergreen.V287.Id.ThreadRoute ) (Evergreen.V287.Id.Id Evergreen.V287.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V287.Id.AnyGuildOrDmId, Evergreen.V287.Id.ThreadRoute )
        { fileId : Evergreen.V287.Id.Id Evergreen.V287.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V287.Id.AnyGuildOrDmId, Evergreen.V287.Id.ThreadRoute ) (Evergreen.V287.Id.Id Evergreen.V287.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V287.Id.AnyGuildOrDmId, Evergreen.V287.Id.ThreadRoute ) (Evergreen.V287.Id.Id Evergreen.V287.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V287.Id.AnyGuildOrDmId, Evergreen.V287.Id.ThreadRoute )
        { fileId : Evergreen.V287.Id.Id Evergreen.V287.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V287.Id.AnyGuildOrDmId, Evergreen.V287.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V287.Id.AnyGuildOrDmId, Evergreen.V287.Id.ThreadRoute ) (Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelMessageId) (Evergreen.V287.Id.Id Evergreen.V287.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V287.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V287.Id.AnyGuildOrDmId, Evergreen.V287.Id.ThreadRoute ) (Evergreen.V287.Id.Id Evergreen.V287.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V287.Id.AnyGuildOrDmId Evergreen.V287.Id.ThreadRouteWithMessage Evergreen.V287.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V287.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V287.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V287.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V287.Id.Id Evergreen.V287.Id.GuildId) Evergreen.V287.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId) (Evergreen.V287.Discord.Id Evergreen.V287.Discord.GuildId) Evergreen.V287.User.NotificationLevel
    | GotStartupData Evergreen.V287.Ports.StartupData
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V287.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId
        , otherUserId : Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V287.Id.AnyGuildOrDmId Evergreen.V287.Id.ThreadRoute Evergreen.V287.MessageInput.Msg
    | MessageInputMsg Evergreen.V287.Id.AnyGuildOrDmId Evergreen.V287.Id.ThreadRoute Evergreen.V287.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V287.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V287.Range.Range, Evergreen.V287.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V287.Range.Range, Evergreen.V287.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V287.Call.FromJs)
    | VoiceChatMsg Evergreen.V287.Call.Msg
    | PressedChannelHeaderTab Evergreen.V287.Route.DmChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadServiceWorkerData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V287.Drawing.Msg


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V287.Id.Id Evergreen.V287.Id.GuildId) (Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelId) Evergreen.V287.Id.ThreadRoute
    | InitialLoadRequested_Dm Evergreen.V287.DmChannel.DmChannelId Evergreen.V287.Id.ThreadRoute
    | InitialLoadRequested_Discord Evergreen.V287.Id.DiscordGuildOrDmId Evergreen.V287.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V287.Id.Id Evergreen.V287.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V287.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V287.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V287.Untrusted.Untrusted Evergreen.V287.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V287.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V287.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V287.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V287.Id.Id Evergreen.V287.Id.GuildId) (Evergreen.V287.SecretId.SecretId Evergreen.V287.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V287.PersonName.PersonName Evergreen.V287.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V287.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V287.Slack.OAuthCode Evergreen.V287.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V287.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V287.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V287.Id.Id Evergreen.V287.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V287.SecretId.SecretId Evergreen.V287.Id.GoMatchPublicId)


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V287.Discord.Id Evergreen.V287.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V287.Discord.Id Evergreen.V287.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V287.EmailAddress.EmailAddress (Result Evergreen.V287.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V287.EmailAddress.EmailAddress (Result Evergreen.V287.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V287.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V287.Discord.Id Evergreen.V287.Discord.GuildId) (Evergreen.V287.Discord.Id Evergreen.V287.Discord.ChannelId) Evergreen.V287.Id.ThreadRouteWithMaybeMessage (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId) (Result Evergreen.V287.Discord.HttpError Evergreen.V287.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V287.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V287.Discord.Id Evergreen.V287.Discord.PrivateChannelId) (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId) (Result Evergreen.V287.Discord.HttpError Evergreen.V287.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V287.Discord.Id Evergreen.V287.Discord.GuildId) (Evergreen.V287.Discord.Id Evergreen.V287.Discord.ChannelId) Evergreen.V287.Id.ThreadRouteWithMessage (Evergreen.V287.Discord.Id Evergreen.V287.Discord.MessageId) (Result Evergreen.V287.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V287.Discord.Id Evergreen.V287.Discord.PrivateChannelId) (Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelMessageId) (Evergreen.V287.Discord.Id Evergreen.V287.Discord.MessageId) (Result Evergreen.V287.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V287.Discord.Id Evergreen.V287.Discord.GuildId) (Evergreen.V287.Discord.Id Evergreen.V287.Discord.ChannelId) Evergreen.V287.Id.ThreadRouteWithMessage (Evergreen.V287.Discord.Id Evergreen.V287.Discord.MessageId) (Result Evergreen.V287.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V287.Discord.Id Evergreen.V287.Discord.PrivateChannelId) (Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelMessageId) (Evergreen.V287.Discord.Id Evergreen.V287.Discord.MessageId) (Result Evergreen.V287.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V287.Discord.Id Evergreen.V287.Discord.GuildId) (Evergreen.V287.Discord.Id Evergreen.V287.Discord.ChannelId) Evergreen.V287.Id.ThreadRouteWithMessage (Evergreen.V287.Discord.Id Evergreen.V287.Discord.MessageId) Evergreen.V287.Emoji.EmojiOrCustomEmoji (Result Evergreen.V287.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V287.Discord.Id Evergreen.V287.Discord.PrivateChannelId) (Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelMessageId) (Evergreen.V287.Discord.Id Evergreen.V287.Discord.MessageId) Evergreen.V287.Emoji.EmojiOrCustomEmoji (Result Evergreen.V287.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V287.Discord.Id Evergreen.V287.Discord.GuildId) (Evergreen.V287.Discord.Id Evergreen.V287.Discord.ChannelId) Evergreen.V287.Id.ThreadRouteWithMessage (Evergreen.V287.Discord.Id Evergreen.V287.Discord.MessageId) Evergreen.V287.Emoji.EmojiOrCustomEmoji (Result Evergreen.V287.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V287.Discord.Id Evergreen.V287.Discord.PrivateChannelId) (Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelMessageId) (Evergreen.V287.Discord.Id Evergreen.V287.Discord.MessageId) Evergreen.V287.Emoji.EmojiOrCustomEmoji (Result Evergreen.V287.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V287.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V287.Discord.HttpError (List ( Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId, Maybe Evergreen.V287.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId) Effect.Time.Posix Evergreen.V287.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V287.Slack.CurrentUser
            , team : Evergreen.V287.Slack.Team
            , users : List Evergreen.V287.Slack.User
            , channels : List ( Evergreen.V287.Slack.Channel, List Evergreen.V287.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId) (Result Effect.Http.Error Evergreen.V287.Slack.TokenResponse)
    | GotCloudflareSessionCreated Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V287.Local.ChangeId Effect.Time.Posix Evergreen.V287.Call.CallId Evergreen.V287.Cloudflare.Sdp (List String) (Result Effect.Http.Error Evergreen.V287.Cloudflare.RealtimeSessionId)
    | GotCloudflareSession Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V287.Local.ChangeId Effect.Time.Posix Evergreen.V287.Call.CallId Evergreen.V287.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V287.Cloudflare.PushTracksResult)
    | GotCloudflarePullOffer Effect.Time.Posix Effect.Lamdera.ClientId Evergreen.V287.Local.ChangeId Evergreen.V287.Call.ConnectionId Evergreen.V287.Cloudflare.RealtimeSessionId (List Evergreen.V287.Cloudflare.TrackName) (Result Effect.Http.Error Evergreen.V287.Cloudflare.PullTracksResult)
    | GotCloudflareRenegotiateAck Effect.Lamdera.ClientId Evergreen.V287.Local.ChangeId Evergreen.V287.Cloudflare.Sdp (Result Effect.Http.Error ())
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId) Evergreen.V287.Discord.UserAuth (Result Evergreen.V287.Discord.HttpError Evergreen.V287.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId) (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId) (Result Evergreen.V287.Discord.HttpError Evergreen.V287.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId)
        (Result
            Evergreen.V287.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V287.Discord.Id Evergreen.V287.Discord.PrivateChannelId
                , members : List (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId)
                }
            , List
                ( Evergreen.V287.Discord.Id Evergreen.V287.Discord.GuildId
                , { guild : Evergreen.V287.Discord.GatewayGuild
                  , channels : List Evergreen.V287.Discord.Channel
                  , icon : Maybe Evergreen.V287.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId) Bool Evergreen.V287.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V287.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V287.Discord.Id Evergreen.V287.Discord.AttachmentId, Evergreen.V287.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V287.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V287.Discord.Id Evergreen.V287.Discord.AttachmentId, Evergreen.V287.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId) (Evergreen.V287.Discord.Id Evergreen.V287.Discord.GuildId) (Evergreen.V287.Discord.Id Evergreen.V287.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V287.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V287.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId) (Evergreen.V287.Discord.Id Evergreen.V287.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V287.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V287.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId) (Evergreen.V287.Discord.Id Evergreen.V287.Discord.GuildId) (Evergreen.V287.Discord.Id Evergreen.V287.Discord.ChannelId) (Result Evergreen.V287.Discord.HttpError (List Evergreen.V287.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId) (Evergreen.V287.Discord.Id Evergreen.V287.Discord.PrivateChannelId) (Result Evergreen.V287.Discord.HttpError (List Evergreen.V287.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V287.Id.Id Evergreen.V287.Id.GuildId) (Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelId) Evergreen.V287.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V287.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V287.DmChannel.DmChannelId Evergreen.V287.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V287.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V287.Discord.Id Evergreen.V287.Discord.GuildId) (Evergreen.V287.Discord.Id Evergreen.V287.Discord.ChannelId) Evergreen.V287.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V287.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V287.Discord.Id Evergreen.V287.Discord.PrivateChannelId) (Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V287.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId)
        (Evergreen.V287.Discord.Id Evergreen.V287.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V287.Discord.HttpError
            { guild : Evergreen.V287.Discord.GatewayGuild
            , channels : List Evergreen.V287.Discord.Channel
            , icon : Maybe Evergreen.V287.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V287.Discord.Id Evergreen.V287.Discord.GuildId) (Result Evergreen.V287.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V287.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId) (List ( Evergreen.V287.Id.Id Evergreen.V287.Id.StickerId, Result Effect.Http.Error Evergreen.V287.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V287.Id.Id Evergreen.V287.Id.StickerId, Result Effect.Http.Error Evergreen.V287.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId) (List ( Evergreen.V287.Id.Id Evergreen.V287.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V287.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V287.Id.Id Evergreen.V287.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V287.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V287.Discord.HttpError (List Evergreen.V287.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V287.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V287.SecretId.SecretId Evergreen.V287.SecretId.ServerSecret))
    | GotTimeForWebsocketListenClose (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | GotCloudflareUsage Effect.Time.Posix (Result Effect.Http.Error Int)
    | GotCloudflareEgressForAdmin Effect.Lamdera.ClientId (Result Effect.Http.Error Int)
    | GotRustServerFileUpload Evergreen.V287.FileStatus.FileHash Int (Maybe (Evergreen.V287.Coord.Coord Evergreen.V287.CssPixels.CssPixels))
