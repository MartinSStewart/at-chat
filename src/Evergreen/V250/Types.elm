module Evergreen.V250.Types exposing (..)

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
import Evergreen.V250.AiChat
import Evergreen.V250.Call
import Evergreen.V250.ChannelDescription
import Evergreen.V250.ChannelName
import Evergreen.V250.Cloudflare
import Evergreen.V250.Coord
import Evergreen.V250.CssPixels
import Evergreen.V250.CustomEmoji
import Evergreen.V250.Discord
import Evergreen.V250.DiscordAttachmentId
import Evergreen.V250.DiscordUserData
import Evergreen.V250.DmChannel
import Evergreen.V250.Editable
import Evergreen.V250.EmailAddress
import Evergreen.V250.Embed
import Evergreen.V250.Emoji
import Evergreen.V250.FileStatus
import Evergreen.V250.Go
import Evergreen.V250.GuildName
import Evergreen.V250.Id
import Evergreen.V250.ImageEditor
import Evergreen.V250.Local
import Evergreen.V250.LocalState
import Evergreen.V250.Log
import Evergreen.V250.LoginForm
import Evergreen.V250.MembersAndOwner
import Evergreen.V250.Message
import Evergreen.V250.MessageInput
import Evergreen.V250.MessageView
import Evergreen.V250.MyUi
import Evergreen.V250.NonemptyDict
import Evergreen.V250.NonemptySet
import Evergreen.V250.OneToOne
import Evergreen.V250.Pages.Admin
import Evergreen.V250.Pagination
import Evergreen.V250.PersonName
import Evergreen.V250.Ports
import Evergreen.V250.Postmark
import Evergreen.V250.Range
import Evergreen.V250.RichText
import Evergreen.V250.Route
import Evergreen.V250.SecretId
import Evergreen.V250.SessionIdHash
import Evergreen.V250.Slack
import Evergreen.V250.Sticker
import Evergreen.V250.TextEditor
import Evergreen.V250.ToBackendLog
import Evergreen.V250.Touch
import Evergreen.V250.TwoFactorAuthentication
import Evergreen.V250.Ui.Anim
import Evergreen.V250.Untrusted
import Evergreen.V250.User
import Evergreen.V250.UserAgent
import Evergreen.V250.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V250.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V250.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.Id.GuildId) Evergreen.V250.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId) Evergreen.V250.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V250.Discord.Id Evergreen.V250.Discord.PrivateChannelId) Evergreen.V250.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V250.Discord.Id Evergreen.V250.Discord.GuildId) Evergreen.V250.LocalState.DiscordFrontendGuild
    , user : Evergreen.V250.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId) Evergreen.V250.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId) Evergreen.V250.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId) Evergreen.V250.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V250.SessionIdHash.SessionIdHash Evergreen.V250.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V250.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.Id.StickerId) Evergreen.V250.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.Id.CustomEmojiId) Evergreen.V250.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V250.Call.RoomId (Evergreen.V250.NonemptySet.NonemptySet ( Evergreen.V250.Id.Id Evergreen.V250.Id.UserId, Effect.Lamdera.ClientId ))
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type PublicGoMatch
    = PublicGoMatch_NotLoaded
    | PublicGoMatch_Loading
    | PublicGoMatch_Loaded Evergreen.V250.Go.PublicGoMatchData Evergreen.V250.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V250.Route.Route
    , windowSize : Evergreen.V250.Coord.Coord Evergreen.V250.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V250.Ports.NotificationPermission
    , pwaStatus : Evergreen.V250.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V250.UserAgent.UserAgent
    , publicGoMatch : PublicGoMatch
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V250.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V250.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V250.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.FileStatus.FileId) Evergreen.V250.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V250.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V250.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.FileStatus.FileId) Evergreen.V250.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V250.Id.Id Evergreen.V250.Id.GuildId) Evergreen.V250.ChannelName.ChannelName Evergreen.V250.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V250.Id.Id Evergreen.V250.Id.GuildId) (Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelId) Evergreen.V250.ChannelName.ChannelName Evergreen.V250.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V250.Id.Id Evergreen.V250.Id.GuildId) (Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelId)
    | Local_DeleteGuild (Evergreen.V250.Id.Id Evergreen.V250.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V250.Id.Id Evergreen.V250.Id.GuildId) (Evergreen.V250.UserSession.ToBeFilledInByBackend (Evergreen.V250.SecretId.SecretId Evergreen.V250.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V250.Id.Id Evergreen.V250.Id.GuildId) (Evergreen.V250.SecretId.SecretId Evergreen.V250.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V250.GuildName.GuildName (Evergreen.V250.UserSession.ToBeFilledInByBackend (Evergreen.V250.Id.Id Evergreen.V250.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V250.Id.AnyGuildOrDmId, Evergreen.V250.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V250.Id.AnyGuildOrDmId Evergreen.V250.Id.ThreadRouteWithMessage Evergreen.V250.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V250.Id.AnyGuildOrDmId Evergreen.V250.Id.ThreadRouteWithMessage Evergreen.V250.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V250.Id.GuildOrDmId Evergreen.V250.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.FileStatus.FileId) Evergreen.V250.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId) (Evergreen.V250.Discord.Id Evergreen.V250.Discord.GuildId) (Evergreen.V250.Discord.Id Evergreen.V250.Discord.ChannelId) Evergreen.V250.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V250.Id.DiscordGuildOrDmId_DmData (Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V250.Id.AnyGuildOrDmId Evergreen.V250.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V250.Id.AnyGuildOrDmId Evergreen.V250.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V250.Id.AnyGuildOrDmId Evergreen.V250.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V250.UserSession.SetViewing
    | Local_SetName Evergreen.V250.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V250.Id.GuildOrDmId (Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelMessageId) (Evergreen.V250.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelMessageId) (Evergreen.V250.Message.Message Evergreen.V250.Id.ChannelMessageId (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V250.Id.GuildOrDmId (Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelMessageId) (Evergreen.V250.Id.Id Evergreen.V250.Id.ThreadMessageId) (Evergreen.V250.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.Id.ThreadMessageId) (Evergreen.V250.Message.Message Evergreen.V250.Id.ThreadMessageId (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V250.Id.DiscordGuildOrDmId (Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelMessageId) (Evergreen.V250.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelMessageId) (Evergreen.V250.Message.Message Evergreen.V250.Id.ChannelMessageId (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V250.Id.DiscordGuildOrDmId (Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelMessageId) (Evergreen.V250.Id.Id Evergreen.V250.Id.ThreadMessageId) (Evergreen.V250.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.Id.ThreadMessageId) (Evergreen.V250.Message.Message Evergreen.V250.Id.ThreadMessageId (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V250.Id.Id Evergreen.V250.Id.GuildId) Evergreen.V250.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId) (Evergreen.V250.Discord.Id Evergreen.V250.Discord.GuildId) Evergreen.V250.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V250.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V250.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V250.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V250.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V250.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V250.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V250.NonemptySet.NonemptySet (Evergreen.V250.Id.Id Evergreen.V250.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V250.Call.LocalChange
    | Local_Go
        { otherUserId : Evergreen.V250.Id.Id Evergreen.V250.Id.UserId
        }
        Evergreen.V250.Go.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId) Effect.Time.Posix Evergreen.V250.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V250.RichText.RichText (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId))) Evergreen.V250.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.FileStatus.FileId) Evergreen.V250.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.Id.StickerId) Evergreen.V250.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V250.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V250.RichText.RichText (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId))) Evergreen.V250.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.FileStatus.FileId) Evergreen.V250.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.Id.StickerId) Evergreen.V250.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V250.Id.Id Evergreen.V250.Id.GuildId) Evergreen.V250.ChannelName.ChannelName Evergreen.V250.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V250.Id.Id Evergreen.V250.Id.GuildId) (Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelId) Evergreen.V250.ChannelName.ChannelName Evergreen.V250.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V250.Id.Id Evergreen.V250.Id.GuildId) (Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelId)
    | Server_DeleteGuild (Evergreen.V250.Id.Id Evergreen.V250.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId) (Evergreen.V250.Id.Id Evergreen.V250.Id.GuildId) (Evergreen.V250.SecretId.SecretId Evergreen.V250.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V250.Id.Id Evergreen.V250.Id.GuildId) (Evergreen.V250.SecretId.SecretId Evergreen.V250.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId) (Evergreen.V250.Id.Id Evergreen.V250.Id.GuildId) Evergreen.V250.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V250.LocalState.JoinGuildError
            { guildId : Evergreen.V250.Id.Id Evergreen.V250.Id.GuildId
            , guild : Evergreen.V250.LocalState.FrontendGuild
            , owner : Evergreen.V250.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId) Evergreen.V250.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId) Evergreen.V250.Id.GuildOrDmId Evergreen.V250.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId) (Evergreen.V250.Discord.Id Evergreen.V250.Discord.GuildId) (Evergreen.V250.Discord.Id Evergreen.V250.Discord.ChannelId) Evergreen.V250.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId) (Evergreen.V250.Discord.Id Evergreen.V250.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId) Evergreen.V250.Id.GuildOrDmId Evergreen.V250.Id.ThreadRouteWithMessage Evergreen.V250.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId) Evergreen.V250.Id.GuildOrDmId Evergreen.V250.Id.ThreadRouteWithMessage Evergreen.V250.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId) (Evergreen.V250.Discord.Id Evergreen.V250.Discord.GuildId) (Evergreen.V250.Discord.Id Evergreen.V250.Discord.ChannelId) Evergreen.V250.Id.ThreadRouteWithMessage Evergreen.V250.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId) (Evergreen.V250.Discord.Id Evergreen.V250.Discord.PrivateChannelId) (Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelMessageId) Evergreen.V250.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId) (Evergreen.V250.Discord.Id Evergreen.V250.Discord.GuildId) (Evergreen.V250.Discord.Id Evergreen.V250.Discord.ChannelId) Evergreen.V250.Id.ThreadRouteWithMessage Evergreen.V250.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId) (Evergreen.V250.Discord.Id Evergreen.V250.Discord.PrivateChannelId) (Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelMessageId) Evergreen.V250.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId) Evergreen.V250.Id.GuildOrDmId Evergreen.V250.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V250.RichText.RichText (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId))) (SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.FileStatus.FileId) Evergreen.V250.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId) (Evergreen.V250.Discord.Id Evergreen.V250.Discord.GuildId) (Evergreen.V250.Discord.Id Evergreen.V250.Discord.ChannelId) Evergreen.V250.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V250.RichText.RichText (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V250.Id.DiscordGuildOrDmId_DmData (Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V250.RichText.RichText (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId) Evergreen.V250.Id.AnyGuildOrDmId Evergreen.V250.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V250.Id.AnyGuildOrDmId Evergreen.V250.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V250.Discord.Id Evergreen.V250.Discord.GuildId) (Evergreen.V250.Discord.Id Evergreen.V250.Discord.ChannelId) Evergreen.V250.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V250.Discord.Id Evergreen.V250.Discord.PrivateChannelId) (Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId) Evergreen.V250.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId) Evergreen.V250.FileStatus.FileHash
    | Server_SetGuildIcon (Evergreen.V250.Id.Id Evergreen.V250.Id.GuildId) Evergreen.V250.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V250.Id.Id Evergreen.V250.Id.GuildId) Evergreen.V250.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V250.Discord.Id Evergreen.V250.Discord.GuildId) Evergreen.V250.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V250.SessionIdHash.SessionIdHash Evergreen.V250.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V250.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V250.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V250.Id.AnyGuildOrDmId, Evergreen.V250.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V250.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId) Evergreen.V250.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V250.Discord.Id Evergreen.V250.Discord.GuildId) (Evergreen.V250.Discord.Id Evergreen.V250.Discord.ChannelId) Evergreen.V250.ChannelName.ChannelName (Evergreen.V250.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V250.Discord.Id Evergreen.V250.Discord.PrivateChannelId)
        (Evergreen.V250.NonemptyDict.NonemptyDict
            (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V250.Discord.Id Evergreen.V250.Discord.GuildId) Evergreen.V250.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V250.Discord.Id Evergreen.V250.Discord.PrivateChannelId) Evergreen.V250.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId) Evergreen.V250.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId) (Maybe (Evergreen.V250.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V250.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V250.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V250.Id.Id Evergreen.V250.Id.GuildId) (Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelId) Evergreen.V250.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V250.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId) Evergreen.V250.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V250.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V250.Discord.Id Evergreen.V250.Discord.GuildId) (Evergreen.V250.Discord.Id Evergreen.V250.Discord.ChannelId) Evergreen.V250.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V250.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V250.Discord.Id Evergreen.V250.Discord.PrivateChannelId) (Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V250.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V250.Discord.Id Evergreen.V250.Discord.GuildId) Evergreen.V250.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V250.Discord.Id Evergreen.V250.Discord.GuildId) (Evergreen.V250.Discord.Id Evergreen.V250.Discord.ChannelId) (Evergreen.V250.Discord.OptionalData String) (Evergreen.V250.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V250.Discord.Id Evergreen.V250.Discord.GuildId)
        (Evergreen.V250.MembersAndOwner.MembersAndOwner
            (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V250.Discord.Id Evergreen.V250.Discord.GuildId) (Evergreen.V250.Discord.Id Evergreen.V250.Discord.ChannelId) (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId) Evergreen.V250.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.Id.StickerId) Evergreen.V250.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.Id.CustomEmojiId) Evergreen.V250.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V250.Call.ServerChange
    | Server_Go
        (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId)
        { otherUserId : Evergreen.V250.Id.Id Evergreen.V250.Id.UserId
        }
        Evergreen.V250.Go.LocalChange


type LocalMsg
    = LocalChange (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V250.Id.Id Evergreen.V250.Id.GuildId) (Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelId) Evergreen.V250.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V250.Discord.Id Evergreen.V250.Discord.GuildId) (Evergreen.V250.Discord.Id Evergreen.V250.Discord.ChannelId) Evergreen.V250.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.FileStatus.FileId) Evergreen.V250.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V250.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V250.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V250.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V250.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V250.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V250.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V250.Coord.Coord Evergreen.V250.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V250.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V250.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V250.Id.AnyGuildOrDmId Evergreen.V250.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V250.Id.AnyGuildOrDmId Evergreen.V250.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V250.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V250.Coord.Coord Evergreen.V250.CssPixels.CssPixels) (Maybe Evergreen.V250.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V250.Id.AnyGuildOrDmId, Evergreen.V250.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelMessageId) (Evergreen.V250.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.Id.ThreadMessageId) (Evergreen.V250.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V250.Editable.Model
    , showLinkDiscordSetup : Bool
    , domainWhitelistInput : String
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V250.Local.Local LocalMsg Evergreen.V250.LocalState.LocalState
    , admin : Evergreen.V250.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V250.Id.AnyGuildOrDmId, Evergreen.V250.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V250.Id.Id Evergreen.V250.Id.GuildId, Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V250.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V250.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V250.Id.AnyGuildOrDmId, Evergreen.V250.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V250.Id.AnyGuildOrDmId, Evergreen.V250.Id.ThreadRoute ) (Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : Evergreen.V250.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V250.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V250.Id.AnyGuildOrDmId, Evergreen.V250.Id.ThreadRoute ) (Evergreen.V250.NonemptyDict.NonemptyDict (Evergreen.V250.Id.Id Evergreen.V250.FileStatus.FileId) Evergreen.V250.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V250.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V250.TextEditor.Model
    , profilePictureEditor : Evergreen.V250.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V250.Id.Id Evergreen.V250.Id.GuildId, Evergreen.V250.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V250.Emoji.Model
    , voiceChat : Evergreen.V250.Call.Model
    , currentDmGoMatch : SeqDict.SeqDict ( Evergreen.V250.Id.Id Evergreen.V250.Id.UserId, Maybe (Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelMessageId) ) Evergreen.V250.Go.Model
    , fileDragOverCount : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V250.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V250.SecretId.SecretId Evergreen.V250.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V250.Range.Range
                , direction : Evergreen.V250.Range.SelectionDirection
                }
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V250.NonemptyDict.NonemptyDict Int Evergreen.V250.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V250.NonemptyDict.NonemptyDict Int Evergreen.V250.Touch.Touch
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
    | AdminToFrontend Evergreen.V250.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V250.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V250.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V250.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V250.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V250.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V250.Go.PublicGoMatchData)


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V250.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V250.Coord.Coord Evergreen.V250.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V250.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V250.MyUi.LastCopy
    , notificationPermission : Evergreen.V250.Ports.NotificationPermission
    , pwaStatus : Evergreen.V250.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V250.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V250.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V250.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V250.Id.Id Evergreen.V250.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V250.Id.Id Evergreen.V250.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V250.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V250.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V250.Coord.Coord Evergreen.V250.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V250.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V250.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V250.Id.Id Evergreen.V250.Id.GuildId, Evergreen.V250.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V250.DmChannel.DmChannelId, Evergreen.V250.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V250.Discord.Id Evergreen.V250.Discord.GuildId, Evergreen.V250.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V250.Discord.Id Evergreen.V250.Discord.PrivateChannelId, Evergreen.V250.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V250.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V250.NonemptyDict.NonemptyDict (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId) Evergreen.V250.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V250.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V250.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V250.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V250.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId) Evergreen.V250.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId) Evergreen.V250.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V250.Id.Id Evergreen.V250.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.Id.GuildId) Evergreen.V250.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.Id.GuildId) Evergreen.V250.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V250.Discord.Id Evergreen.V250.Discord.GuildId) Evergreen.V250.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V250.DmChannel.DmChannelId Evergreen.V250.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V250.Discord.Id Evergreen.V250.Discord.PrivateChannelId) Evergreen.V250.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V250.OneToOne.OneToOne (Evergreen.V250.Slack.Id Evergreen.V250.Slack.ChannelId) Evergreen.V250.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V250.OneToOne.OneToOne String (Evergreen.V250.Id.Id Evergreen.V250.Id.GuildId)
    , slackUsers : Evergreen.V250.OneToOne.OneToOne (Evergreen.V250.Slack.Id Evergreen.V250.Slack.UserId) (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId)
    , slackServers : Evergreen.V250.OneToOne.OneToOne (Evergreen.V250.Slack.Id Evergreen.V250.Slack.TeamId) (Evergreen.V250.Id.Id Evergreen.V250.Id.GuildId)
    , slackToken : Maybe Evergreen.V250.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V250.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V250.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V250.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareTurnApiToken : Maybe String
    , textEditor : Evergreen.V250.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId) Evergreen.V250.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId, Evergreen.V250.Discord.Id Evergreen.V250.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V250.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V250.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V250.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V250.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId) (Evergreen.V250.LocalState.LoadingDiscordChannel (List Evergreen.V250.Discord.Message))
    , signupsEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V250.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.Id.StickerId) Evergreen.V250.Sticker.StickerData
    , discordStickers : Evergreen.V250.OneToOne.OneToOne (Evergreen.V250.Discord.Id Evergreen.V250.Discord.StickerId) (Evergreen.V250.Id.Id Evergreen.V250.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.Id.CustomEmojiId) Evergreen.V250.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V250.OneToOne.OneToOne Evergreen.V250.RichText.DiscordCustomEmojiIdAndName (Evergreen.V250.Id.Id Evergreen.V250.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V250.Postmark.ApiKey
    , serverSecret : Evergreen.V250.SecretId.SecretId Evergreen.V250.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V250.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V250.OneToOne.OneToOne (Evergreen.V250.SecretId.SecretId Evergreen.V250.Id.GoMatchPublicId) ( Evergreen.V250.DmChannel.DmChannelId, Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelMessageId )
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V250.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V250.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V250.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V250.Route.Route
    | SelectedFilesToAttach ( Evergreen.V250.Id.AnyGuildOrDmId, Evergreen.V250.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V250.Id.Id Evergreen.V250.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V250.Id.Id Evergreen.V250.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V250.Id.Id Evergreen.V250.Id.GuildId) (Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelId) Evergreen.V250.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V250.Id.Id Evergreen.V250.Id.GuildId) (Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelId) Evergreen.V250.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V250.Discord.Id Evergreen.V250.Discord.GuildId) (Evergreen.V250.Discord.Id Evergreen.V250.Discord.ChannelId) Evergreen.V250.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V250.Discord.Id Evergreen.V250.Discord.GuildId) (Evergreen.V250.Discord.Id Evergreen.V250.Discord.ChannelId) Evergreen.V250.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V250.Id.Id Evergreen.V250.Id.GuildId) (Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V250.Id.Id Evergreen.V250.Id.GuildId) (Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V250.Id.Id Evergreen.V250.Id.GuildId) (Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V250.Id.Id Evergreen.V250.Id.GuildId) (Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V250.Id.Id Evergreen.V250.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V250.Id.Id Evergreen.V250.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V250.Id.Id Evergreen.V250.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V250.Id.Id Evergreen.V250.Id.GuildId) (Evergreen.V250.SecretId.SecretId Evergreen.V250.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V250.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V250.Id.AnyGuildOrDmId Evergreen.V250.Id.ThreadRouteWithMessage (Evergreen.V250.Coord.Coord Evergreen.V250.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V250.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V250.Id.AnyGuildOrDmId Evergreen.V250.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V250.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V250.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V250.Id.AnyGuildOrDmId, Evergreen.V250.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V250.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V250.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V250.Id.AnyGuildOrDmId, Evergreen.V250.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V250.NonemptyDict.NonemptyDict Int Evergreen.V250.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V250.NonemptyDict.NonemptyDict Int Evergreen.V250.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V250.Id.AnyGuildOrDmId Evergreen.V250.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V250.Id.AnyGuildOrDmId Evergreen.V250.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V250.NonemptySet.NonemptySet (Evergreen.V250.Id.Id Evergreen.V250.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V250.Id.AnyGuildOrDmId, Evergreen.V250.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V250.Id.AnyGuildOrDmId Evergreen.V250.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V250.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V250.AiChat.Msg
    | GoMsg Evergreen.V250.Go.Msg
    | GoSpectatorMsg Evergreen.V250.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V250.Editable.Msg Evergreen.V250.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V250.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V250.Id.Id Evergreen.V250.Id.GuildId) Evergreen.V250.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V250.Id.AnyGuildOrDmId, Evergreen.V250.Id.ThreadRoute ) (Evergreen.V250.Id.Id Evergreen.V250.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V250.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V250.Id.AnyGuildOrDmId, Evergreen.V250.Id.ThreadRoute ) (Evergreen.V250.Id.Id Evergreen.V250.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V250.Id.AnyGuildOrDmId, Evergreen.V250.Id.ThreadRoute ) (Evergreen.V250.Id.Id Evergreen.V250.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V250.Id.AnyGuildOrDmId, Evergreen.V250.Id.ThreadRoute )
        { fileId : Evergreen.V250.Id.Id Evergreen.V250.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V250.Id.AnyGuildOrDmId, Evergreen.V250.Id.ThreadRoute ) (Evergreen.V250.Id.Id Evergreen.V250.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V250.Id.AnyGuildOrDmId, Evergreen.V250.Id.ThreadRoute ) (Evergreen.V250.Id.Id Evergreen.V250.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V250.Id.AnyGuildOrDmId, Evergreen.V250.Id.ThreadRoute )
        { fileId : Evergreen.V250.Id.Id Evergreen.V250.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V250.Id.AnyGuildOrDmId, Evergreen.V250.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V250.Id.AnyGuildOrDmId, Evergreen.V250.Id.ThreadRoute ) (Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelMessageId) (Evergreen.V250.Id.Id Evergreen.V250.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V250.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V250.Id.AnyGuildOrDmId, Evergreen.V250.Id.ThreadRoute ) (Evergreen.V250.Id.Id Evergreen.V250.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V250.Id.AnyGuildOrDmId Evergreen.V250.Id.ThreadRouteWithMessage Evergreen.V250.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V250.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V250.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V250.Id.Id Evergreen.V250.Id.GuildId) Evergreen.V250.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId) (Evergreen.V250.Discord.Id Evergreen.V250.Discord.GuildId) Evergreen.V250.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V250.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V250.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId
        , otherUserId : Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V250.Id.AnyGuildOrDmId Evergreen.V250.Id.ThreadRoute Evergreen.V250.MessageInput.Msg
    | MessageInputMsg Evergreen.V250.Id.AnyGuildOrDmId Evergreen.V250.Id.ThreadRoute Evergreen.V250.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V250.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V250.Range.Range, Evergreen.V250.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V250.Range.Range, Evergreen.V250.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V250.Call.FromJs)
    | VoiceChatMsg Evergreen.V250.Call.Msg
    | PressedChannelHeaderTab Evergreen.V250.Route.DmChannelHeaderTab
    | FileDragEnter
    | FileDragLeave
    | FileDropped (List Effect.File.File)


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V250.Id.Id Evergreen.V250.Id.GuildId) (Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelId) Evergreen.V250.Id.ThreadRoute
    | InitialLoadRequested_Dm Evergreen.V250.DmChannel.DmChannelId Evergreen.V250.Id.ThreadRoute
    | InitialLoadRequested_Discord Evergreen.V250.Id.DiscordGuildOrDmId Evergreen.V250.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V250.Id.Id Evergreen.V250.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V250.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V250.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V250.Untrusted.Untrusted Evergreen.V250.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V250.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V250.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V250.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V250.Id.Id Evergreen.V250.Id.GuildId) (Evergreen.V250.SecretId.SecretId Evergreen.V250.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V250.PersonName.PersonName Evergreen.V250.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V250.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V250.Slack.OAuthCode Evergreen.V250.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V250.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V250.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V250.Id.Id Evergreen.V250.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V250.SecretId.SecretId Evergreen.V250.Id.GoMatchPublicId)


type alias PendingVoiceChatJoin =
    { sessionId : Effect.Lamdera.SessionId
    , clientId : Effect.Lamdera.ClientId
    , changeId : Evergreen.V250.Local.ChangeId
    , time : Effect.Time.Posix
    , userId : Evergreen.V250.Id.Id Evergreen.V250.Id.UserId
    , otherUserId : Evergreen.V250.Id.Id Evergreen.V250.Id.UserId
    , dmChannelId : Evergreen.V250.DmChannel.DmChannelId
    , roomId : Evergreen.V250.Call.RoomId
    }


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V250.Discord.Id Evergreen.V250.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V250.Discord.Id Evergreen.V250.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V250.EmailAddress.EmailAddress (Result Evergreen.V250.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V250.EmailAddress.EmailAddress (Result Evergreen.V250.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId) Evergreen.V250.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V250.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V250.Discord.Id Evergreen.V250.Discord.GuildId) (Evergreen.V250.Discord.Id Evergreen.V250.Discord.ChannelId) Evergreen.V250.Id.ThreadRouteWithMaybeMessage (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId) (Result Evergreen.V250.Discord.HttpError Evergreen.V250.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V250.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V250.Discord.Id Evergreen.V250.Discord.PrivateChannelId) (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId) (Result Evergreen.V250.Discord.HttpError Evergreen.V250.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V250.Discord.Id Evergreen.V250.Discord.GuildId) (Evergreen.V250.Discord.Id Evergreen.V250.Discord.ChannelId) Evergreen.V250.Id.ThreadRouteWithMessage (Evergreen.V250.Discord.Id Evergreen.V250.Discord.MessageId) (Result Evergreen.V250.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V250.Discord.Id Evergreen.V250.Discord.PrivateChannelId) (Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelMessageId) (Evergreen.V250.Discord.Id Evergreen.V250.Discord.MessageId) (Result Evergreen.V250.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V250.Discord.Id Evergreen.V250.Discord.GuildId) (Evergreen.V250.Discord.Id Evergreen.V250.Discord.ChannelId) Evergreen.V250.Id.ThreadRouteWithMessage (Evergreen.V250.Discord.Id Evergreen.V250.Discord.MessageId) (Result Evergreen.V250.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V250.Discord.Id Evergreen.V250.Discord.PrivateChannelId) (Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelMessageId) (Evergreen.V250.Discord.Id Evergreen.V250.Discord.MessageId) (Result Evergreen.V250.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V250.Discord.Id Evergreen.V250.Discord.GuildId) (Evergreen.V250.Discord.Id Evergreen.V250.Discord.ChannelId) Evergreen.V250.Id.ThreadRouteWithMessage (Evergreen.V250.Discord.Id Evergreen.V250.Discord.MessageId) Evergreen.V250.Emoji.EmojiOrCustomEmoji (Result Evergreen.V250.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V250.Discord.Id Evergreen.V250.Discord.PrivateChannelId) (Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelMessageId) (Evergreen.V250.Discord.Id Evergreen.V250.Discord.MessageId) Evergreen.V250.Emoji.EmojiOrCustomEmoji (Result Evergreen.V250.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V250.Discord.Id Evergreen.V250.Discord.GuildId) (Evergreen.V250.Discord.Id Evergreen.V250.Discord.ChannelId) Evergreen.V250.Id.ThreadRouteWithMessage (Evergreen.V250.Discord.Id Evergreen.V250.Discord.MessageId) Evergreen.V250.Emoji.EmojiOrCustomEmoji (Result Evergreen.V250.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V250.Discord.Id Evergreen.V250.Discord.PrivateChannelId) (Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelMessageId) (Evergreen.V250.Discord.Id Evergreen.V250.Discord.MessageId) Evergreen.V250.Emoji.EmojiOrCustomEmoji (Result Evergreen.V250.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V250.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V250.Discord.HttpError (List ( Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId, Maybe Evergreen.V250.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V250.Slack.CurrentUser
            , team : Evergreen.V250.Slack.Team
            , users : List Evergreen.V250.Slack.User
            , channels : List ( Evergreen.V250.Slack.Channel, List Evergreen.V250.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId) (Result Effect.Http.Error Evergreen.V250.Slack.TokenResponse)
    | GotCloudflareTurnCredentials PendingVoiceChatJoin (Result Effect.Http.Error (List Evergreen.V250.Cloudflare.TurnConfig))
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId) Evergreen.V250.Discord.UserAuth (Result Evergreen.V250.Discord.HttpError Evergreen.V250.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId) (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId) (Result Evergreen.V250.Discord.HttpError Evergreen.V250.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId)
        (Result
            Evergreen.V250.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V250.Discord.Id Evergreen.V250.Discord.PrivateChannelId
                , members : List (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId)
                }
            , List
                ( Evergreen.V250.Discord.Id Evergreen.V250.Discord.GuildId
                , { guild : Evergreen.V250.Discord.GatewayGuild
                  , channels : List Evergreen.V250.Discord.Channel
                  , icon : Maybe Evergreen.V250.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId) Bool Evergreen.V250.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V250.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V250.Discord.Id Evergreen.V250.Discord.AttachmentId, Evergreen.V250.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V250.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V250.Discord.Id Evergreen.V250.Discord.AttachmentId, Evergreen.V250.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId) (Evergreen.V250.Discord.Id Evergreen.V250.Discord.GuildId) (Evergreen.V250.Discord.Id Evergreen.V250.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V250.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V250.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId) (Evergreen.V250.Discord.Id Evergreen.V250.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V250.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V250.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId) (Evergreen.V250.Discord.Id Evergreen.V250.Discord.GuildId) (Evergreen.V250.Discord.Id Evergreen.V250.Discord.ChannelId) (Result Evergreen.V250.Discord.HttpError (List Evergreen.V250.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId) (Evergreen.V250.Discord.Id Evergreen.V250.Discord.PrivateChannelId) (Result Evergreen.V250.Discord.HttpError (List Evergreen.V250.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V250.Id.Id Evergreen.V250.Id.GuildId) (Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelId) Evergreen.V250.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V250.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V250.DmChannel.DmChannelId Evergreen.V250.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V250.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V250.Discord.Id Evergreen.V250.Discord.GuildId) (Evergreen.V250.Discord.Id Evergreen.V250.Discord.ChannelId) Evergreen.V250.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V250.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V250.Discord.Id Evergreen.V250.Discord.PrivateChannelId) (Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V250.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId)
        (Evergreen.V250.Discord.Id Evergreen.V250.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V250.Discord.HttpError
            { guild : Evergreen.V250.Discord.GatewayGuild
            , channels : List Evergreen.V250.Discord.Channel
            , icon : Maybe Evergreen.V250.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V250.Discord.Id Evergreen.V250.Discord.GuildId) (Result Evergreen.V250.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V250.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId) (List ( Evergreen.V250.Id.Id Evergreen.V250.Id.StickerId, Result Effect.Http.Error Evergreen.V250.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V250.Id.Id Evergreen.V250.Id.StickerId, Result Effect.Http.Error Evergreen.V250.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId) (List ( Evergreen.V250.Id.Id Evergreen.V250.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V250.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V250.Id.Id Evergreen.V250.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V250.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V250.Discord.HttpError (List Evergreen.V250.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V250.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V250.SecretId.SecretId Evergreen.V250.SecretId.ServerSecret))
    | GotTimeForWebsocketListenClose (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId) String Effect.Time.Posix
