module Evergreen.V243.Types exposing (..)

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
import Evergreen.V243.AiChat
import Evergreen.V243.Call
import Evergreen.V243.ChannelDescription
import Evergreen.V243.ChannelName
import Evergreen.V243.Cloudflare
import Evergreen.V243.Coord
import Evergreen.V243.CssPixels
import Evergreen.V243.CustomEmoji
import Evergreen.V243.Discord
import Evergreen.V243.DiscordAttachmentId
import Evergreen.V243.DiscordUserData
import Evergreen.V243.DmChannel
import Evergreen.V243.Editable
import Evergreen.V243.EmailAddress
import Evergreen.V243.Embed
import Evergreen.V243.Emoji
import Evergreen.V243.FileStatus
import Evergreen.V243.Go
import Evergreen.V243.GuildName
import Evergreen.V243.Id
import Evergreen.V243.ImageEditor
import Evergreen.V243.Local
import Evergreen.V243.LocalState
import Evergreen.V243.Log
import Evergreen.V243.LoginForm
import Evergreen.V243.MembersAndOwner
import Evergreen.V243.Message
import Evergreen.V243.MessageInput
import Evergreen.V243.MessageView
import Evergreen.V243.MyUi
import Evergreen.V243.NonemptyDict
import Evergreen.V243.NonemptySet
import Evergreen.V243.OneToOne
import Evergreen.V243.Pages.Admin
import Evergreen.V243.Pagination
import Evergreen.V243.PersonName
import Evergreen.V243.Ports
import Evergreen.V243.Postmark
import Evergreen.V243.Range
import Evergreen.V243.RichText
import Evergreen.V243.Route
import Evergreen.V243.SecretId
import Evergreen.V243.SessionIdHash
import Evergreen.V243.Slack
import Evergreen.V243.Sticker
import Evergreen.V243.TextEditor
import Evergreen.V243.ToBackendLog
import Evergreen.V243.Touch
import Evergreen.V243.TwoFactorAuthentication
import Evergreen.V243.Ui.Anim
import Evergreen.V243.Untrusted
import Evergreen.V243.User
import Evergreen.V243.UserAgent
import Evergreen.V243.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V243.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V243.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.Id.GuildId) Evergreen.V243.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId) Evergreen.V243.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V243.Discord.Id Evergreen.V243.Discord.PrivateChannelId) Evergreen.V243.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V243.Discord.Id Evergreen.V243.Discord.GuildId) Evergreen.V243.LocalState.DiscordFrontendGuild
    , user : Evergreen.V243.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId) Evergreen.V243.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId) Evergreen.V243.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId) Evergreen.V243.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V243.SessionIdHash.SessionIdHash Evergreen.V243.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V243.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.Id.StickerId) Evergreen.V243.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.Id.CustomEmojiId) Evergreen.V243.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V243.Call.RoomId (Evergreen.V243.NonemptySet.NonemptySet ( Evergreen.V243.Id.Id Evergreen.V243.Id.UserId, Effect.Lamdera.ClientId ))
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type PublicGoMatch
    = PublicGoMatch_NotLoaded
    | PublicGoMatch_Loading
    | PublicGoMatch_Loaded Evergreen.V243.Go.PublicGoMatchData Evergreen.V243.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V243.Route.Route
    , windowSize : Evergreen.V243.Coord.Coord Evergreen.V243.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V243.Ports.NotificationPermission
    , pwaStatus : Evergreen.V243.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V243.UserAgent.UserAgent
    , publicGoMatch : PublicGoMatch
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V243.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V243.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V243.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.FileStatus.FileId) Evergreen.V243.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V243.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V243.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.FileStatus.FileId) Evergreen.V243.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V243.Id.Id Evergreen.V243.Id.GuildId) Evergreen.V243.ChannelName.ChannelName Evergreen.V243.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V243.Id.Id Evergreen.V243.Id.GuildId) (Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelId) Evergreen.V243.ChannelName.ChannelName Evergreen.V243.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V243.Id.Id Evergreen.V243.Id.GuildId) (Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelId)
    | Local_DeleteGuild (Evergreen.V243.Id.Id Evergreen.V243.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V243.Id.Id Evergreen.V243.Id.GuildId) (Evergreen.V243.UserSession.ToBeFilledInByBackend (Evergreen.V243.SecretId.SecretId Evergreen.V243.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V243.Id.Id Evergreen.V243.Id.GuildId) (Evergreen.V243.SecretId.SecretId Evergreen.V243.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V243.GuildName.GuildName (Evergreen.V243.UserSession.ToBeFilledInByBackend (Evergreen.V243.Id.Id Evergreen.V243.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V243.Id.AnyGuildOrDmId, Evergreen.V243.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V243.Id.AnyGuildOrDmId Evergreen.V243.Id.ThreadRouteWithMessage Evergreen.V243.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V243.Id.AnyGuildOrDmId Evergreen.V243.Id.ThreadRouteWithMessage Evergreen.V243.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V243.Id.GuildOrDmId Evergreen.V243.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.FileStatus.FileId) Evergreen.V243.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId) (Evergreen.V243.Discord.Id Evergreen.V243.Discord.GuildId) (Evergreen.V243.Discord.Id Evergreen.V243.Discord.ChannelId) Evergreen.V243.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V243.Id.DiscordGuildOrDmId_DmData (Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V243.Id.AnyGuildOrDmId Evergreen.V243.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V243.Id.AnyGuildOrDmId Evergreen.V243.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V243.Id.AnyGuildOrDmId Evergreen.V243.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V243.UserSession.SetViewing
    | Local_SetName Evergreen.V243.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V243.Id.GuildOrDmId (Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelMessageId) (Evergreen.V243.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelMessageId) (Evergreen.V243.Message.Message Evergreen.V243.Id.ChannelMessageId (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V243.Id.GuildOrDmId (Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelMessageId) (Evergreen.V243.Id.Id Evergreen.V243.Id.ThreadMessageId) (Evergreen.V243.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.Id.ThreadMessageId) (Evergreen.V243.Message.Message Evergreen.V243.Id.ThreadMessageId (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V243.Id.DiscordGuildOrDmId (Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelMessageId) (Evergreen.V243.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelMessageId) (Evergreen.V243.Message.Message Evergreen.V243.Id.ChannelMessageId (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V243.Id.DiscordGuildOrDmId (Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelMessageId) (Evergreen.V243.Id.Id Evergreen.V243.Id.ThreadMessageId) (Evergreen.V243.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.Id.ThreadMessageId) (Evergreen.V243.Message.Message Evergreen.V243.Id.ThreadMessageId (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V243.Id.Id Evergreen.V243.Id.GuildId) Evergreen.V243.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId) (Evergreen.V243.Discord.Id Evergreen.V243.Discord.GuildId) Evergreen.V243.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V243.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V243.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V243.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V243.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V243.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V243.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V243.NonemptySet.NonemptySet (Evergreen.V243.Id.Id Evergreen.V243.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V243.Call.LocalChange
    | Local_Go
        { otherUserId : Evergreen.V243.Id.Id Evergreen.V243.Id.UserId
        }
        Evergreen.V243.Go.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId) Effect.Time.Posix Evergreen.V243.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V243.RichText.RichText (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId))) Evergreen.V243.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.FileStatus.FileId) Evergreen.V243.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.Id.StickerId) Evergreen.V243.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V243.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V243.RichText.RichText (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId))) Evergreen.V243.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.FileStatus.FileId) Evergreen.V243.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.Id.StickerId) Evergreen.V243.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V243.Id.Id Evergreen.V243.Id.GuildId) Evergreen.V243.ChannelName.ChannelName Evergreen.V243.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V243.Id.Id Evergreen.V243.Id.GuildId) (Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelId) Evergreen.V243.ChannelName.ChannelName Evergreen.V243.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V243.Id.Id Evergreen.V243.Id.GuildId) (Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelId)
    | Server_DeleteGuild (Evergreen.V243.Id.Id Evergreen.V243.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId) (Evergreen.V243.Id.Id Evergreen.V243.Id.GuildId) (Evergreen.V243.SecretId.SecretId Evergreen.V243.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V243.Id.Id Evergreen.V243.Id.GuildId) (Evergreen.V243.SecretId.SecretId Evergreen.V243.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId) (Evergreen.V243.Id.Id Evergreen.V243.Id.GuildId) Evergreen.V243.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V243.LocalState.JoinGuildError
            { guildId : Evergreen.V243.Id.Id Evergreen.V243.Id.GuildId
            , guild : Evergreen.V243.LocalState.FrontendGuild
            , owner : Evergreen.V243.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId) Evergreen.V243.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId) Evergreen.V243.Id.GuildOrDmId Evergreen.V243.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId) (Evergreen.V243.Discord.Id Evergreen.V243.Discord.GuildId) (Evergreen.V243.Discord.Id Evergreen.V243.Discord.ChannelId) Evergreen.V243.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId) (Evergreen.V243.Discord.Id Evergreen.V243.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId) Evergreen.V243.Id.GuildOrDmId Evergreen.V243.Id.ThreadRouteWithMessage Evergreen.V243.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId) Evergreen.V243.Id.GuildOrDmId Evergreen.V243.Id.ThreadRouteWithMessage Evergreen.V243.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId) (Evergreen.V243.Discord.Id Evergreen.V243.Discord.GuildId) (Evergreen.V243.Discord.Id Evergreen.V243.Discord.ChannelId) Evergreen.V243.Id.ThreadRouteWithMessage Evergreen.V243.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId) (Evergreen.V243.Discord.Id Evergreen.V243.Discord.PrivateChannelId) (Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelMessageId) Evergreen.V243.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId) (Evergreen.V243.Discord.Id Evergreen.V243.Discord.GuildId) (Evergreen.V243.Discord.Id Evergreen.V243.Discord.ChannelId) Evergreen.V243.Id.ThreadRouteWithMessage Evergreen.V243.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId) (Evergreen.V243.Discord.Id Evergreen.V243.Discord.PrivateChannelId) (Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelMessageId) Evergreen.V243.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId) Evergreen.V243.Id.GuildOrDmId Evergreen.V243.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V243.RichText.RichText (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId))) (SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.FileStatus.FileId) Evergreen.V243.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId) (Evergreen.V243.Discord.Id Evergreen.V243.Discord.GuildId) (Evergreen.V243.Discord.Id Evergreen.V243.Discord.ChannelId) Evergreen.V243.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V243.RichText.RichText (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V243.Id.DiscordGuildOrDmId_DmData (Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V243.RichText.RichText (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId) Evergreen.V243.Id.AnyGuildOrDmId Evergreen.V243.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V243.Id.AnyGuildOrDmId Evergreen.V243.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V243.Discord.Id Evergreen.V243.Discord.GuildId) (Evergreen.V243.Discord.Id Evergreen.V243.Discord.ChannelId) Evergreen.V243.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V243.Discord.Id Evergreen.V243.Discord.PrivateChannelId) (Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId) Evergreen.V243.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId) Evergreen.V243.FileStatus.FileHash
    | Server_SetGuildIcon (Evergreen.V243.Id.Id Evergreen.V243.Id.GuildId) Evergreen.V243.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V243.Id.Id Evergreen.V243.Id.GuildId) Evergreen.V243.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V243.Discord.Id Evergreen.V243.Discord.GuildId) Evergreen.V243.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V243.SessionIdHash.SessionIdHash Evergreen.V243.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V243.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V243.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V243.Id.AnyGuildOrDmId, Evergreen.V243.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V243.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId) Evergreen.V243.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V243.Discord.Id Evergreen.V243.Discord.GuildId) (Evergreen.V243.Discord.Id Evergreen.V243.Discord.ChannelId) Evergreen.V243.ChannelName.ChannelName (Evergreen.V243.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V243.Discord.Id Evergreen.V243.Discord.PrivateChannelId)
        (Evergreen.V243.NonemptyDict.NonemptyDict
            (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V243.Discord.Id Evergreen.V243.Discord.GuildId) Evergreen.V243.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V243.Discord.Id Evergreen.V243.Discord.PrivateChannelId) Evergreen.V243.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId) Evergreen.V243.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId) (Maybe (Evergreen.V243.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V243.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V243.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V243.Id.Id Evergreen.V243.Id.GuildId) (Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelId) Evergreen.V243.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V243.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId) Evergreen.V243.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V243.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V243.Discord.Id Evergreen.V243.Discord.GuildId) (Evergreen.V243.Discord.Id Evergreen.V243.Discord.ChannelId) Evergreen.V243.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V243.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V243.Discord.Id Evergreen.V243.Discord.PrivateChannelId) (Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V243.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V243.Discord.Id Evergreen.V243.Discord.GuildId) Evergreen.V243.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V243.Discord.Id Evergreen.V243.Discord.GuildId) (Evergreen.V243.Discord.Id Evergreen.V243.Discord.ChannelId) (Evergreen.V243.Discord.OptionalData String) (Evergreen.V243.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V243.Discord.Id Evergreen.V243.Discord.GuildId)
        (Evergreen.V243.MembersAndOwner.MembersAndOwner
            (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V243.Discord.Id Evergreen.V243.Discord.GuildId) (Evergreen.V243.Discord.Id Evergreen.V243.Discord.ChannelId) (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId) Evergreen.V243.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.Id.StickerId) Evergreen.V243.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.Id.CustomEmojiId) Evergreen.V243.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V243.Call.ServerChange
    | Server_Go
        (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId)
        { otherUserId : Evergreen.V243.Id.Id Evergreen.V243.Id.UserId
        }
        Evergreen.V243.Go.LocalChange


type LocalMsg
    = LocalChange (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V243.Id.Id Evergreen.V243.Id.GuildId) (Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelId) Evergreen.V243.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V243.Discord.Id Evergreen.V243.Discord.GuildId) (Evergreen.V243.Discord.Id Evergreen.V243.Discord.ChannelId) Evergreen.V243.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.FileStatus.FileId) Evergreen.V243.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V243.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V243.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V243.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V243.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V243.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V243.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V243.Coord.Coord Evergreen.V243.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V243.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V243.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V243.Id.AnyGuildOrDmId Evergreen.V243.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V243.Id.AnyGuildOrDmId Evergreen.V243.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V243.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V243.Coord.Coord Evergreen.V243.CssPixels.CssPixels) (Maybe Evergreen.V243.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V243.Id.AnyGuildOrDmId, Evergreen.V243.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelMessageId) (Evergreen.V243.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.Id.ThreadMessageId) (Evergreen.V243.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V243.Editable.Model
    , showLinkDiscordSetup : Bool
    , domainWhitelistInput : String
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V243.Local.Local LocalMsg Evergreen.V243.LocalState.LocalState
    , admin : Evergreen.V243.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V243.Id.AnyGuildOrDmId, Evergreen.V243.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V243.Id.Id Evergreen.V243.Id.GuildId, Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V243.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V243.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V243.Id.AnyGuildOrDmId, Evergreen.V243.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V243.Id.AnyGuildOrDmId, Evergreen.V243.Id.ThreadRoute ) (Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : Evergreen.V243.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V243.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V243.Id.AnyGuildOrDmId, Evergreen.V243.Id.ThreadRoute ) (Evergreen.V243.NonemptyDict.NonemptyDict (Evergreen.V243.Id.Id Evergreen.V243.FileStatus.FileId) Evergreen.V243.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V243.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V243.TextEditor.Model
    , profilePictureEditor : Evergreen.V243.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V243.Id.Id Evergreen.V243.Id.GuildId, Evergreen.V243.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V243.Emoji.Model
    , voiceChat : Evergreen.V243.Call.Model
    , currentDmGoMatch : SeqDict.SeqDict ( Evergreen.V243.Id.Id Evergreen.V243.Id.UserId, Maybe (Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelMessageId) ) Evergreen.V243.Go.Model
    , fileDragOverCount : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V243.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V243.SecretId.SecretId Evergreen.V243.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V243.Range.Range
                , direction : Evergreen.V243.Range.SelectionDirection
                }
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V243.NonemptyDict.NonemptyDict Int Evergreen.V243.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V243.NonemptyDict.NonemptyDict Int Evergreen.V243.Touch.Touch
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
    | AdminToFrontend Evergreen.V243.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V243.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V243.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V243.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V243.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V243.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V243.Go.PublicGoMatchData)


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V243.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V243.Coord.Coord Evergreen.V243.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V243.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V243.MyUi.LastCopy
    , notificationPermission : Evergreen.V243.Ports.NotificationPermission
    , pwaStatus : Evergreen.V243.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V243.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V243.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V243.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V243.Id.Id Evergreen.V243.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V243.Id.Id Evergreen.V243.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V243.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V243.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V243.Coord.Coord Evergreen.V243.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V243.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V243.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V243.Id.Id Evergreen.V243.Id.GuildId, Evergreen.V243.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V243.DmChannel.DmChannelId, Evergreen.V243.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V243.Discord.Id Evergreen.V243.Discord.GuildId, Evergreen.V243.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V243.Discord.Id Evergreen.V243.Discord.PrivateChannelId, Evergreen.V243.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V243.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V243.NonemptyDict.NonemptyDict (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId) Evergreen.V243.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V243.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V243.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V243.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V243.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId) Evergreen.V243.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId) Evergreen.V243.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V243.Id.Id Evergreen.V243.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.Id.GuildId) Evergreen.V243.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.Id.GuildId) Evergreen.V243.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V243.Discord.Id Evergreen.V243.Discord.GuildId) Evergreen.V243.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V243.DmChannel.DmChannelId Evergreen.V243.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V243.Discord.Id Evergreen.V243.Discord.PrivateChannelId) Evergreen.V243.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V243.OneToOne.OneToOne (Evergreen.V243.Slack.Id Evergreen.V243.Slack.ChannelId) Evergreen.V243.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V243.OneToOne.OneToOne String (Evergreen.V243.Id.Id Evergreen.V243.Id.GuildId)
    , slackUsers : Evergreen.V243.OneToOne.OneToOne (Evergreen.V243.Slack.Id Evergreen.V243.Slack.UserId) (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId)
    , slackServers : Evergreen.V243.OneToOne.OneToOne (Evergreen.V243.Slack.Id Evergreen.V243.Slack.TeamId) (Evergreen.V243.Id.Id Evergreen.V243.Id.GuildId)
    , slackToken : Maybe Evergreen.V243.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V243.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V243.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V243.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareTurnApiToken : Maybe String
    , textEditor : Evergreen.V243.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId) Evergreen.V243.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId, Evergreen.V243.Discord.Id Evergreen.V243.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V243.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V243.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V243.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V243.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId) (Evergreen.V243.LocalState.LoadingDiscordChannel (List Evergreen.V243.Discord.Message))
    , signupsEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V243.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.Id.StickerId) Evergreen.V243.Sticker.StickerData
    , discordStickers : Evergreen.V243.OneToOne.OneToOne (Evergreen.V243.Discord.Id Evergreen.V243.Discord.StickerId) (Evergreen.V243.Id.Id Evergreen.V243.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.Id.CustomEmojiId) Evergreen.V243.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V243.OneToOne.OneToOne Evergreen.V243.RichText.DiscordCustomEmojiIdAndName (Evergreen.V243.Id.Id Evergreen.V243.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V243.Postmark.ApiKey
    , serverSecret : Evergreen.V243.SecretId.SecretId Evergreen.V243.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketDisconnects : Array.Array Effect.Time.Posix
    , goMatchPublicIds : Evergreen.V243.OneToOne.OneToOne (Evergreen.V243.SecretId.SecretId Evergreen.V243.Id.GoMatchPublicId) ( Evergreen.V243.DmChannel.DmChannelId, Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelMessageId )
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V243.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V243.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V243.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V243.Route.Route
    | SelectedFilesToAttach ( Evergreen.V243.Id.AnyGuildOrDmId, Evergreen.V243.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V243.Id.Id Evergreen.V243.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V243.Id.Id Evergreen.V243.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V243.Id.Id Evergreen.V243.Id.GuildId) (Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelId) Evergreen.V243.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V243.Id.Id Evergreen.V243.Id.GuildId) (Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelId) Evergreen.V243.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V243.Discord.Id Evergreen.V243.Discord.GuildId) (Evergreen.V243.Discord.Id Evergreen.V243.Discord.ChannelId) Evergreen.V243.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V243.Discord.Id Evergreen.V243.Discord.GuildId) (Evergreen.V243.Discord.Id Evergreen.V243.Discord.ChannelId) Evergreen.V243.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V243.Id.Id Evergreen.V243.Id.GuildId) (Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V243.Id.Id Evergreen.V243.Id.GuildId) (Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V243.Id.Id Evergreen.V243.Id.GuildId) (Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V243.Id.Id Evergreen.V243.Id.GuildId) (Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V243.Id.Id Evergreen.V243.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V243.Id.Id Evergreen.V243.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V243.Id.Id Evergreen.V243.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V243.Id.Id Evergreen.V243.Id.GuildId) (Evergreen.V243.SecretId.SecretId Evergreen.V243.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V243.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V243.Id.AnyGuildOrDmId Evergreen.V243.Id.ThreadRouteWithMessage (Evergreen.V243.Coord.Coord Evergreen.V243.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V243.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V243.Id.AnyGuildOrDmId Evergreen.V243.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V243.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V243.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V243.Id.AnyGuildOrDmId, Evergreen.V243.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V243.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V243.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V243.Id.AnyGuildOrDmId, Evergreen.V243.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V243.NonemptyDict.NonemptyDict Int Evergreen.V243.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V243.NonemptyDict.NonemptyDict Int Evergreen.V243.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V243.Id.AnyGuildOrDmId Evergreen.V243.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V243.Id.AnyGuildOrDmId Evergreen.V243.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V243.NonemptySet.NonemptySet (Evergreen.V243.Id.Id Evergreen.V243.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V243.Id.AnyGuildOrDmId, Evergreen.V243.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V243.Id.AnyGuildOrDmId Evergreen.V243.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V243.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V243.AiChat.Msg
    | GoMsg Evergreen.V243.Go.Msg
    | GoSpectatorMsg Evergreen.V243.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V243.Editable.Msg Evergreen.V243.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V243.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V243.Id.Id Evergreen.V243.Id.GuildId) Evergreen.V243.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V243.Id.AnyGuildOrDmId, Evergreen.V243.Id.ThreadRoute ) (Evergreen.V243.Id.Id Evergreen.V243.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V243.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V243.Id.AnyGuildOrDmId, Evergreen.V243.Id.ThreadRoute ) (Evergreen.V243.Id.Id Evergreen.V243.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V243.Id.AnyGuildOrDmId, Evergreen.V243.Id.ThreadRoute ) (Evergreen.V243.Id.Id Evergreen.V243.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V243.Id.AnyGuildOrDmId, Evergreen.V243.Id.ThreadRoute )
        { fileId : Evergreen.V243.Id.Id Evergreen.V243.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V243.Id.AnyGuildOrDmId, Evergreen.V243.Id.ThreadRoute ) (Evergreen.V243.Id.Id Evergreen.V243.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V243.Id.AnyGuildOrDmId, Evergreen.V243.Id.ThreadRoute ) (Evergreen.V243.Id.Id Evergreen.V243.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V243.Id.AnyGuildOrDmId, Evergreen.V243.Id.ThreadRoute )
        { fileId : Evergreen.V243.Id.Id Evergreen.V243.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V243.Id.AnyGuildOrDmId, Evergreen.V243.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V243.Id.AnyGuildOrDmId, Evergreen.V243.Id.ThreadRoute ) (Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelMessageId) (Evergreen.V243.Id.Id Evergreen.V243.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V243.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V243.Id.AnyGuildOrDmId, Evergreen.V243.Id.ThreadRoute ) (Evergreen.V243.Id.Id Evergreen.V243.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V243.Id.AnyGuildOrDmId Evergreen.V243.Id.ThreadRouteWithMessage Evergreen.V243.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V243.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V243.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V243.Id.Id Evergreen.V243.Id.GuildId) Evergreen.V243.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId) (Evergreen.V243.Discord.Id Evergreen.V243.Discord.GuildId) Evergreen.V243.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V243.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V243.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId
        , otherUserId : Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V243.Id.AnyGuildOrDmId Evergreen.V243.Id.ThreadRoute Evergreen.V243.MessageInput.Msg
    | MessageInputMsg Evergreen.V243.Id.AnyGuildOrDmId Evergreen.V243.Id.ThreadRoute Evergreen.V243.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V243.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V243.Range.Range, Evergreen.V243.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V243.Range.Range, Evergreen.V243.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V243.Call.FromJs)
    | VoiceChatMsg Evergreen.V243.Call.Msg
    | PressedChannelHeaderTab Evergreen.V243.Route.DmChannelHeaderTab
    | FileDragEnter
    | FileDragLeave
    | FileDropped (List Effect.File.File)


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V243.Id.Id Evergreen.V243.Id.GuildId) (Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelId) Evergreen.V243.Id.ThreadRoute
    | InitialLoadRequested_Dm Evergreen.V243.DmChannel.DmChannelId Evergreen.V243.Id.ThreadRoute
    | InitialLoadRequested_Discord Evergreen.V243.Id.DiscordGuildOrDmId Evergreen.V243.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V243.Id.Id Evergreen.V243.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V243.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V243.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V243.Untrusted.Untrusted Evergreen.V243.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V243.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V243.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V243.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V243.Id.Id Evergreen.V243.Id.GuildId) (Evergreen.V243.SecretId.SecretId Evergreen.V243.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V243.PersonName.PersonName Evergreen.V243.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V243.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V243.Slack.OAuthCode Evergreen.V243.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V243.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V243.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V243.Id.Id Evergreen.V243.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V243.SecretId.SecretId Evergreen.V243.Id.GoMatchPublicId)


type alias PendingVoiceChatJoin =
    { sessionId : Effect.Lamdera.SessionId
    , clientId : Effect.Lamdera.ClientId
    , changeId : Evergreen.V243.Local.ChangeId
    , time : Effect.Time.Posix
    , userId : Evergreen.V243.Id.Id Evergreen.V243.Id.UserId
    , otherUserId : Evergreen.V243.Id.Id Evergreen.V243.Id.UserId
    , dmChannelId : Evergreen.V243.DmChannel.DmChannelId
    , roomId : Evergreen.V243.Call.RoomId
    }


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V243.Discord.Id Evergreen.V243.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V243.Discord.Id Evergreen.V243.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V243.EmailAddress.EmailAddress (Result Evergreen.V243.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V243.EmailAddress.EmailAddress (Result Evergreen.V243.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId) Evergreen.V243.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V243.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V243.Discord.Id Evergreen.V243.Discord.GuildId) (Evergreen.V243.Discord.Id Evergreen.V243.Discord.ChannelId) Evergreen.V243.Id.ThreadRouteWithMaybeMessage (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId) (Result Evergreen.V243.Discord.HttpError Evergreen.V243.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V243.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V243.Discord.Id Evergreen.V243.Discord.PrivateChannelId) (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId) (Result Evergreen.V243.Discord.HttpError Evergreen.V243.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V243.Discord.Id Evergreen.V243.Discord.GuildId) (Evergreen.V243.Discord.Id Evergreen.V243.Discord.ChannelId) Evergreen.V243.Id.ThreadRouteWithMessage (Evergreen.V243.Discord.Id Evergreen.V243.Discord.MessageId) (Result Evergreen.V243.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V243.Discord.Id Evergreen.V243.Discord.PrivateChannelId) (Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelMessageId) (Evergreen.V243.Discord.Id Evergreen.V243.Discord.MessageId) (Result Evergreen.V243.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V243.Discord.Id Evergreen.V243.Discord.GuildId) (Evergreen.V243.Discord.Id Evergreen.V243.Discord.ChannelId) Evergreen.V243.Id.ThreadRouteWithMessage (Evergreen.V243.Discord.Id Evergreen.V243.Discord.MessageId) (Result Evergreen.V243.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V243.Discord.Id Evergreen.V243.Discord.PrivateChannelId) (Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelMessageId) (Evergreen.V243.Discord.Id Evergreen.V243.Discord.MessageId) (Result Evergreen.V243.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V243.Discord.Id Evergreen.V243.Discord.GuildId) (Evergreen.V243.Discord.Id Evergreen.V243.Discord.ChannelId) Evergreen.V243.Id.ThreadRouteWithMessage (Evergreen.V243.Discord.Id Evergreen.V243.Discord.MessageId) Evergreen.V243.Emoji.EmojiOrCustomEmoji (Result Evergreen.V243.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V243.Discord.Id Evergreen.V243.Discord.PrivateChannelId) (Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelMessageId) (Evergreen.V243.Discord.Id Evergreen.V243.Discord.MessageId) Evergreen.V243.Emoji.EmojiOrCustomEmoji (Result Evergreen.V243.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V243.Discord.Id Evergreen.V243.Discord.GuildId) (Evergreen.V243.Discord.Id Evergreen.V243.Discord.ChannelId) Evergreen.V243.Id.ThreadRouteWithMessage (Evergreen.V243.Discord.Id Evergreen.V243.Discord.MessageId) Evergreen.V243.Emoji.EmojiOrCustomEmoji (Result Evergreen.V243.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V243.Discord.Id Evergreen.V243.Discord.PrivateChannelId) (Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelMessageId) (Evergreen.V243.Discord.Id Evergreen.V243.Discord.MessageId) Evergreen.V243.Emoji.EmojiOrCustomEmoji (Result Evergreen.V243.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V243.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V243.Discord.HttpError (List ( Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId, Maybe Evergreen.V243.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V243.Slack.CurrentUser
            , team : Evergreen.V243.Slack.Team
            , users : List Evergreen.V243.Slack.User
            , channels : List ( Evergreen.V243.Slack.Channel, List Evergreen.V243.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId) (Result Effect.Http.Error Evergreen.V243.Slack.TokenResponse)
    | GotCloudflareTurnCredentials PendingVoiceChatJoin (Result Effect.Http.Error (List Evergreen.V243.Cloudflare.TurnConfig))
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId) Evergreen.V243.Discord.UserAuth (Result Evergreen.V243.Discord.HttpError Evergreen.V243.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId) (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId) (Result Evergreen.V243.Discord.HttpError Evergreen.V243.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId)
        (Result
            Evergreen.V243.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V243.Discord.Id Evergreen.V243.Discord.PrivateChannelId
                , members : List (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId)
                }
            , List
                ( Evergreen.V243.Discord.Id Evergreen.V243.Discord.GuildId
                , { guild : Evergreen.V243.Discord.GatewayGuild
                  , channels : List Evergreen.V243.Discord.Channel
                  , icon : Maybe Evergreen.V243.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId) Bool
    | WebsocketSentDataForUser (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V243.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V243.Discord.Id Evergreen.V243.Discord.AttachmentId, Evergreen.V243.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V243.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V243.Discord.Id Evergreen.V243.Discord.AttachmentId, Evergreen.V243.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId) (Evergreen.V243.Discord.Id Evergreen.V243.Discord.GuildId) (Evergreen.V243.Discord.Id Evergreen.V243.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V243.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V243.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId) (Evergreen.V243.Discord.Id Evergreen.V243.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V243.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V243.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId) (Evergreen.V243.Discord.Id Evergreen.V243.Discord.GuildId) (Evergreen.V243.Discord.Id Evergreen.V243.Discord.ChannelId) (Result Evergreen.V243.Discord.HttpError (List Evergreen.V243.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId) (Evergreen.V243.Discord.Id Evergreen.V243.Discord.PrivateChannelId) (Result Evergreen.V243.Discord.HttpError (List Evergreen.V243.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V243.Id.Id Evergreen.V243.Id.GuildId) (Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelId) Evergreen.V243.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V243.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V243.DmChannel.DmChannelId Evergreen.V243.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V243.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V243.Discord.Id Evergreen.V243.Discord.GuildId) (Evergreen.V243.Discord.Id Evergreen.V243.Discord.ChannelId) Evergreen.V243.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V243.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V243.Discord.Id Evergreen.V243.Discord.PrivateChannelId) (Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V243.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId)
        (Evergreen.V243.Discord.Id Evergreen.V243.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V243.Discord.HttpError
            { guild : Evergreen.V243.Discord.GatewayGuild
            , channels : List Evergreen.V243.Discord.Channel
            , icon : Maybe Evergreen.V243.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V243.Discord.Id Evergreen.V243.Discord.GuildId) (Result Evergreen.V243.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V243.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId) (List ( Evergreen.V243.Id.Id Evergreen.V243.Id.StickerId, Result Effect.Http.Error Evergreen.V243.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V243.Id.Id Evergreen.V243.Id.StickerId, Result Effect.Http.Error Evergreen.V243.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId) (List ( Evergreen.V243.Id.Id Evergreen.V243.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V243.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V243.Id.Id Evergreen.V243.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V243.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V243.Discord.HttpError (List Evergreen.V243.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V243.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V243.SecretId.SecretId Evergreen.V243.SecretId.ServerSecret))
