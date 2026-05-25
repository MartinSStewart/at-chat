module Evergreen.V252.Types exposing (..)

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
import Evergreen.V252.AiChat
import Evergreen.V252.Call
import Evergreen.V252.ChannelDescription
import Evergreen.V252.ChannelName
import Evergreen.V252.Cloudflare
import Evergreen.V252.Coord
import Evergreen.V252.CssPixels
import Evergreen.V252.CustomEmoji
import Evergreen.V252.Discord
import Evergreen.V252.DiscordAttachmentId
import Evergreen.V252.DiscordUserData
import Evergreen.V252.DmChannel
import Evergreen.V252.Editable
import Evergreen.V252.EmailAddress
import Evergreen.V252.Embed
import Evergreen.V252.Emoji
import Evergreen.V252.FileStatus
import Evergreen.V252.Go
import Evergreen.V252.GuildName
import Evergreen.V252.Id
import Evergreen.V252.ImageEditor
import Evergreen.V252.Local
import Evergreen.V252.LocalState
import Evergreen.V252.Log
import Evergreen.V252.LoginForm
import Evergreen.V252.MembersAndOwner
import Evergreen.V252.Message
import Evergreen.V252.MessageInput
import Evergreen.V252.MessageView
import Evergreen.V252.MyUi
import Evergreen.V252.NonemptyDict
import Evergreen.V252.NonemptySet
import Evergreen.V252.OneToOne
import Evergreen.V252.Pages.Admin
import Evergreen.V252.Pagination
import Evergreen.V252.PersonName
import Evergreen.V252.Ports
import Evergreen.V252.Postmark
import Evergreen.V252.Range
import Evergreen.V252.RichText
import Evergreen.V252.Route
import Evergreen.V252.SecretId
import Evergreen.V252.SessionIdHash
import Evergreen.V252.Slack
import Evergreen.V252.Sticker
import Evergreen.V252.TextEditor
import Evergreen.V252.ToBackendLog
import Evergreen.V252.Touch
import Evergreen.V252.TwoFactorAuthentication
import Evergreen.V252.Ui.Anim
import Evergreen.V252.Untrusted
import Evergreen.V252.User
import Evergreen.V252.UserAgent
import Evergreen.V252.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V252.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V252.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.Id.GuildId) Evergreen.V252.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId) Evergreen.V252.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V252.Discord.Id Evergreen.V252.Discord.PrivateChannelId) Evergreen.V252.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V252.Discord.Id Evergreen.V252.Discord.GuildId) Evergreen.V252.LocalState.DiscordFrontendGuild
    , user : Evergreen.V252.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId) Evergreen.V252.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId) Evergreen.V252.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId) Evergreen.V252.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V252.SessionIdHash.SessionIdHash Evergreen.V252.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V252.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.Id.StickerId) Evergreen.V252.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.Id.CustomEmojiId) Evergreen.V252.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V252.Call.RoomId (Evergreen.V252.NonemptySet.NonemptySet ( Evergreen.V252.Id.Id Evergreen.V252.Id.UserId, Effect.Lamdera.ClientId ))
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type PublicGoMatch
    = PublicGoMatch_NotLoaded
    | PublicGoMatch_Loading
    | PublicGoMatch_Loaded Evergreen.V252.Go.PublicGoMatchData Evergreen.V252.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V252.Route.Route
    , windowSize : Evergreen.V252.Coord.Coord Evergreen.V252.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V252.Ports.NotificationPermission
    , pwaStatus : Evergreen.V252.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V252.UserAgent.UserAgent
    , publicGoMatch : PublicGoMatch
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V252.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V252.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V252.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.FileStatus.FileId) Evergreen.V252.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V252.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V252.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.FileStatus.FileId) Evergreen.V252.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V252.Id.Id Evergreen.V252.Id.GuildId) Evergreen.V252.ChannelName.ChannelName Evergreen.V252.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V252.Id.Id Evergreen.V252.Id.GuildId) (Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelId) Evergreen.V252.ChannelName.ChannelName Evergreen.V252.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V252.Id.Id Evergreen.V252.Id.GuildId) (Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelId)
    | Local_DeleteGuild (Evergreen.V252.Id.Id Evergreen.V252.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V252.Id.Id Evergreen.V252.Id.GuildId) (Evergreen.V252.UserSession.ToBeFilledInByBackend (Evergreen.V252.SecretId.SecretId Evergreen.V252.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V252.Id.Id Evergreen.V252.Id.GuildId) (Evergreen.V252.SecretId.SecretId Evergreen.V252.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V252.GuildName.GuildName (Evergreen.V252.UserSession.ToBeFilledInByBackend (Evergreen.V252.Id.Id Evergreen.V252.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V252.Id.AnyGuildOrDmId, Evergreen.V252.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V252.Id.AnyGuildOrDmId Evergreen.V252.Id.ThreadRouteWithMessage Evergreen.V252.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V252.Id.AnyGuildOrDmId Evergreen.V252.Id.ThreadRouteWithMessage Evergreen.V252.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V252.Id.GuildOrDmId Evergreen.V252.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.FileStatus.FileId) Evergreen.V252.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId) (Evergreen.V252.Discord.Id Evergreen.V252.Discord.GuildId) (Evergreen.V252.Discord.Id Evergreen.V252.Discord.ChannelId) Evergreen.V252.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V252.Id.DiscordGuildOrDmId_DmData (Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V252.Id.AnyGuildOrDmId Evergreen.V252.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V252.Id.AnyGuildOrDmId Evergreen.V252.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V252.Id.AnyGuildOrDmId Evergreen.V252.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V252.UserSession.SetViewing
    | Local_SetName Evergreen.V252.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V252.Id.GuildOrDmId (Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelMessageId) (Evergreen.V252.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelMessageId) (Evergreen.V252.Message.Message Evergreen.V252.Id.ChannelMessageId (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V252.Id.GuildOrDmId (Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelMessageId) (Evergreen.V252.Id.Id Evergreen.V252.Id.ThreadMessageId) (Evergreen.V252.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.Id.ThreadMessageId) (Evergreen.V252.Message.Message Evergreen.V252.Id.ThreadMessageId (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V252.Id.DiscordGuildOrDmId (Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelMessageId) (Evergreen.V252.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelMessageId) (Evergreen.V252.Message.Message Evergreen.V252.Id.ChannelMessageId (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V252.Id.DiscordGuildOrDmId (Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelMessageId) (Evergreen.V252.Id.Id Evergreen.V252.Id.ThreadMessageId) (Evergreen.V252.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.Id.ThreadMessageId) (Evergreen.V252.Message.Message Evergreen.V252.Id.ThreadMessageId (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V252.Id.Id Evergreen.V252.Id.GuildId) Evergreen.V252.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId) (Evergreen.V252.Discord.Id Evergreen.V252.Discord.GuildId) Evergreen.V252.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V252.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V252.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V252.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V252.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V252.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V252.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V252.NonemptySet.NonemptySet (Evergreen.V252.Id.Id Evergreen.V252.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V252.Call.LocalChange
    | Local_Go
        { otherUserId : Evergreen.V252.Id.Id Evergreen.V252.Id.UserId
        }
        Evergreen.V252.Go.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId) Effect.Time.Posix Evergreen.V252.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V252.RichText.RichText (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId))) Evergreen.V252.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.FileStatus.FileId) Evergreen.V252.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.Id.StickerId) Evergreen.V252.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V252.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V252.RichText.RichText (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId))) Evergreen.V252.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.FileStatus.FileId) Evergreen.V252.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.Id.StickerId) Evergreen.V252.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V252.Id.Id Evergreen.V252.Id.GuildId) Evergreen.V252.ChannelName.ChannelName Evergreen.V252.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V252.Id.Id Evergreen.V252.Id.GuildId) (Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelId) Evergreen.V252.ChannelName.ChannelName Evergreen.V252.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V252.Id.Id Evergreen.V252.Id.GuildId) (Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelId)
    | Server_DeleteGuild (Evergreen.V252.Id.Id Evergreen.V252.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId) (Evergreen.V252.Id.Id Evergreen.V252.Id.GuildId) (Evergreen.V252.SecretId.SecretId Evergreen.V252.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V252.Id.Id Evergreen.V252.Id.GuildId) (Evergreen.V252.SecretId.SecretId Evergreen.V252.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId) (Evergreen.V252.Id.Id Evergreen.V252.Id.GuildId) Evergreen.V252.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V252.LocalState.JoinGuildError
            { guildId : Evergreen.V252.Id.Id Evergreen.V252.Id.GuildId
            , guild : Evergreen.V252.LocalState.FrontendGuild
            , owner : Evergreen.V252.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId) Evergreen.V252.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId) Evergreen.V252.Id.GuildOrDmId Evergreen.V252.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId) (Evergreen.V252.Discord.Id Evergreen.V252.Discord.GuildId) (Evergreen.V252.Discord.Id Evergreen.V252.Discord.ChannelId) Evergreen.V252.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId) (Evergreen.V252.Discord.Id Evergreen.V252.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId) Evergreen.V252.Id.GuildOrDmId Evergreen.V252.Id.ThreadRouteWithMessage Evergreen.V252.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId) Evergreen.V252.Id.GuildOrDmId Evergreen.V252.Id.ThreadRouteWithMessage Evergreen.V252.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId) (Evergreen.V252.Discord.Id Evergreen.V252.Discord.GuildId) (Evergreen.V252.Discord.Id Evergreen.V252.Discord.ChannelId) Evergreen.V252.Id.ThreadRouteWithMessage Evergreen.V252.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId) (Evergreen.V252.Discord.Id Evergreen.V252.Discord.PrivateChannelId) (Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelMessageId) Evergreen.V252.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId) (Evergreen.V252.Discord.Id Evergreen.V252.Discord.GuildId) (Evergreen.V252.Discord.Id Evergreen.V252.Discord.ChannelId) Evergreen.V252.Id.ThreadRouteWithMessage Evergreen.V252.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId) (Evergreen.V252.Discord.Id Evergreen.V252.Discord.PrivateChannelId) (Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelMessageId) Evergreen.V252.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId) Evergreen.V252.Id.GuildOrDmId Evergreen.V252.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V252.RichText.RichText (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId))) (SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.FileStatus.FileId) Evergreen.V252.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId) (Evergreen.V252.Discord.Id Evergreen.V252.Discord.GuildId) (Evergreen.V252.Discord.Id Evergreen.V252.Discord.ChannelId) Evergreen.V252.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V252.RichText.RichText (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V252.Id.DiscordGuildOrDmId_DmData (Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V252.RichText.RichText (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId) Evergreen.V252.Id.AnyGuildOrDmId Evergreen.V252.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V252.Id.AnyGuildOrDmId Evergreen.V252.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V252.Discord.Id Evergreen.V252.Discord.GuildId) (Evergreen.V252.Discord.Id Evergreen.V252.Discord.ChannelId) Evergreen.V252.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V252.Discord.Id Evergreen.V252.Discord.PrivateChannelId) (Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId) Evergreen.V252.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId) Evergreen.V252.FileStatus.FileHash
    | Server_SetGuildIcon (Evergreen.V252.Id.Id Evergreen.V252.Id.GuildId) Evergreen.V252.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V252.Id.Id Evergreen.V252.Id.GuildId) Evergreen.V252.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V252.Discord.Id Evergreen.V252.Discord.GuildId) Evergreen.V252.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V252.SessionIdHash.SessionIdHash Evergreen.V252.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V252.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V252.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V252.Id.AnyGuildOrDmId, Evergreen.V252.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V252.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId) Evergreen.V252.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V252.Discord.Id Evergreen.V252.Discord.GuildId) (Evergreen.V252.Discord.Id Evergreen.V252.Discord.ChannelId) Evergreen.V252.ChannelName.ChannelName (Evergreen.V252.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V252.Discord.Id Evergreen.V252.Discord.PrivateChannelId)
        (Evergreen.V252.NonemptyDict.NonemptyDict
            (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V252.Discord.Id Evergreen.V252.Discord.GuildId) Evergreen.V252.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V252.Discord.Id Evergreen.V252.Discord.PrivateChannelId) Evergreen.V252.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId) Evergreen.V252.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId) (Maybe (Evergreen.V252.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V252.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V252.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V252.Id.Id Evergreen.V252.Id.GuildId) (Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelId) Evergreen.V252.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V252.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId) Evergreen.V252.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V252.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V252.Discord.Id Evergreen.V252.Discord.GuildId) (Evergreen.V252.Discord.Id Evergreen.V252.Discord.ChannelId) Evergreen.V252.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V252.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V252.Discord.Id Evergreen.V252.Discord.PrivateChannelId) (Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V252.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V252.Discord.Id Evergreen.V252.Discord.GuildId) Evergreen.V252.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V252.Discord.Id Evergreen.V252.Discord.GuildId) (Evergreen.V252.Discord.Id Evergreen.V252.Discord.ChannelId) (Evergreen.V252.Discord.OptionalData String) (Evergreen.V252.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V252.Discord.Id Evergreen.V252.Discord.GuildId)
        (Evergreen.V252.MembersAndOwner.MembersAndOwner
            (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V252.Discord.Id Evergreen.V252.Discord.GuildId) (Evergreen.V252.Discord.Id Evergreen.V252.Discord.ChannelId) (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId) Evergreen.V252.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.Id.StickerId) Evergreen.V252.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.Id.CustomEmojiId) Evergreen.V252.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V252.Call.ServerChange
    | Server_Go
        (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId)
        { otherUserId : Evergreen.V252.Id.Id Evergreen.V252.Id.UserId
        }
        Evergreen.V252.Go.LocalChange


type LocalMsg
    = LocalChange (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V252.Id.Id Evergreen.V252.Id.GuildId) (Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelId) Evergreen.V252.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V252.Discord.Id Evergreen.V252.Discord.GuildId) (Evergreen.V252.Discord.Id Evergreen.V252.Discord.ChannelId) Evergreen.V252.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.FileStatus.FileId) Evergreen.V252.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V252.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V252.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V252.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V252.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V252.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V252.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V252.Coord.Coord Evergreen.V252.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V252.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V252.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V252.Id.AnyGuildOrDmId Evergreen.V252.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V252.Id.AnyGuildOrDmId Evergreen.V252.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V252.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V252.Coord.Coord Evergreen.V252.CssPixels.CssPixels) (Maybe Evergreen.V252.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V252.Id.AnyGuildOrDmId, Evergreen.V252.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelMessageId) (Evergreen.V252.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.Id.ThreadMessageId) (Evergreen.V252.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V252.Editable.Model
    , showLinkDiscordSetup : Bool
    , domainWhitelistInput : String
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V252.Local.Local LocalMsg Evergreen.V252.LocalState.LocalState
    , admin : Evergreen.V252.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V252.Id.AnyGuildOrDmId, Evergreen.V252.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V252.Id.Id Evergreen.V252.Id.GuildId, Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V252.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V252.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V252.Id.AnyGuildOrDmId, Evergreen.V252.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V252.Id.AnyGuildOrDmId, Evergreen.V252.Id.ThreadRoute ) (Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : Evergreen.V252.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V252.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V252.Id.AnyGuildOrDmId, Evergreen.V252.Id.ThreadRoute ) (Evergreen.V252.NonemptyDict.NonemptyDict (Evergreen.V252.Id.Id Evergreen.V252.FileStatus.FileId) Evergreen.V252.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V252.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V252.TextEditor.Model
    , profilePictureEditor : Evergreen.V252.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V252.Id.Id Evergreen.V252.Id.GuildId, Evergreen.V252.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V252.Emoji.Model
    , voiceChat : Evergreen.V252.Call.Model
    , currentDmGoMatch : SeqDict.SeqDict ( Evergreen.V252.Id.Id Evergreen.V252.Id.UserId, Maybe (Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelMessageId) ) Evergreen.V252.Go.Model
    , fileDragOverCount : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V252.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V252.SecretId.SecretId Evergreen.V252.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V252.Range.Range
                , direction : Evergreen.V252.Range.SelectionDirection
                }
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V252.NonemptyDict.NonemptyDict Int Evergreen.V252.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V252.NonemptyDict.NonemptyDict Int Evergreen.V252.Touch.Touch
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
    | AdminToFrontend Evergreen.V252.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V252.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V252.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V252.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V252.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V252.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V252.Go.PublicGoMatchData)


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V252.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V252.Coord.Coord Evergreen.V252.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V252.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V252.MyUi.LastCopy
    , notificationPermission : Evergreen.V252.Ports.NotificationPermission
    , pwaStatus : Evergreen.V252.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V252.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V252.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V252.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V252.Id.Id Evergreen.V252.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V252.Id.Id Evergreen.V252.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V252.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V252.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V252.Coord.Coord Evergreen.V252.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V252.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V252.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V252.Id.Id Evergreen.V252.Id.GuildId, Evergreen.V252.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V252.DmChannel.DmChannelId, Evergreen.V252.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V252.Discord.Id Evergreen.V252.Discord.GuildId, Evergreen.V252.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V252.Discord.Id Evergreen.V252.Discord.PrivateChannelId, Evergreen.V252.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V252.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V252.NonemptyDict.NonemptyDict (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId) Evergreen.V252.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V252.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V252.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V252.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V252.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId) Evergreen.V252.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId) Evergreen.V252.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V252.Id.Id Evergreen.V252.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.Id.GuildId) Evergreen.V252.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.Id.GuildId) Evergreen.V252.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V252.Discord.Id Evergreen.V252.Discord.GuildId) Evergreen.V252.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V252.DmChannel.DmChannelId Evergreen.V252.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V252.Discord.Id Evergreen.V252.Discord.PrivateChannelId) Evergreen.V252.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V252.OneToOne.OneToOne (Evergreen.V252.Slack.Id Evergreen.V252.Slack.ChannelId) Evergreen.V252.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V252.OneToOne.OneToOne String (Evergreen.V252.Id.Id Evergreen.V252.Id.GuildId)
    , slackUsers : Evergreen.V252.OneToOne.OneToOne (Evergreen.V252.Slack.Id Evergreen.V252.Slack.UserId) (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId)
    , slackServers : Evergreen.V252.OneToOne.OneToOne (Evergreen.V252.Slack.Id Evergreen.V252.Slack.TeamId) (Evergreen.V252.Id.Id Evergreen.V252.Id.GuildId)
    , slackToken : Maybe Evergreen.V252.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V252.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V252.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V252.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V252.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V252.Cloudflare.AppId
    , textEditor : Evergreen.V252.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId) Evergreen.V252.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId, Evergreen.V252.Discord.Id Evergreen.V252.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V252.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V252.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V252.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V252.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId) (Evergreen.V252.LocalState.LoadingDiscordChannel (List Evergreen.V252.Discord.Message))
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V252.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.Id.StickerId) Evergreen.V252.Sticker.StickerData
    , discordStickers : Evergreen.V252.OneToOne.OneToOne (Evergreen.V252.Discord.Id Evergreen.V252.Discord.StickerId) (Evergreen.V252.Id.Id Evergreen.V252.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.Id.CustomEmojiId) Evergreen.V252.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V252.OneToOne.OneToOne Evergreen.V252.RichText.DiscordCustomEmojiIdAndName (Evergreen.V252.Id.Id Evergreen.V252.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V252.Postmark.ApiKey
    , serverSecret : Evergreen.V252.SecretId.SecretId Evergreen.V252.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V252.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V252.OneToOne.OneToOne (Evergreen.V252.SecretId.SecretId Evergreen.V252.Id.GoMatchPublicId) ( Evergreen.V252.DmChannel.DmChannelId, Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelMessageId )
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V252.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V252.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V252.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V252.Route.Route
    | SelectedFilesToAttach ( Evergreen.V252.Id.AnyGuildOrDmId, Evergreen.V252.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V252.Id.Id Evergreen.V252.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V252.Id.Id Evergreen.V252.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V252.Id.Id Evergreen.V252.Id.GuildId) (Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelId) Evergreen.V252.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V252.Id.Id Evergreen.V252.Id.GuildId) (Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelId) Evergreen.V252.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V252.Discord.Id Evergreen.V252.Discord.GuildId) (Evergreen.V252.Discord.Id Evergreen.V252.Discord.ChannelId) Evergreen.V252.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V252.Discord.Id Evergreen.V252.Discord.GuildId) (Evergreen.V252.Discord.Id Evergreen.V252.Discord.ChannelId) Evergreen.V252.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V252.Id.Id Evergreen.V252.Id.GuildId) (Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V252.Id.Id Evergreen.V252.Id.GuildId) (Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V252.Id.Id Evergreen.V252.Id.GuildId) (Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V252.Id.Id Evergreen.V252.Id.GuildId) (Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V252.Id.Id Evergreen.V252.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V252.Id.Id Evergreen.V252.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V252.Id.Id Evergreen.V252.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V252.Id.Id Evergreen.V252.Id.GuildId) (Evergreen.V252.SecretId.SecretId Evergreen.V252.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V252.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V252.Id.AnyGuildOrDmId Evergreen.V252.Id.ThreadRouteWithMessage (Evergreen.V252.Coord.Coord Evergreen.V252.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V252.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V252.Id.AnyGuildOrDmId Evergreen.V252.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V252.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V252.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V252.Id.AnyGuildOrDmId, Evergreen.V252.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V252.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V252.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V252.Id.AnyGuildOrDmId, Evergreen.V252.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V252.NonemptyDict.NonemptyDict Int Evergreen.V252.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V252.NonemptyDict.NonemptyDict Int Evergreen.V252.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V252.Id.AnyGuildOrDmId Evergreen.V252.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V252.Id.AnyGuildOrDmId Evergreen.V252.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V252.NonemptySet.NonemptySet (Evergreen.V252.Id.Id Evergreen.V252.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V252.Id.AnyGuildOrDmId, Evergreen.V252.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V252.Id.AnyGuildOrDmId Evergreen.V252.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V252.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V252.AiChat.Msg
    | GoMsg Evergreen.V252.Go.Msg
    | GoSpectatorMsg Evergreen.V252.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V252.Editable.Msg Evergreen.V252.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V252.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V252.Id.Id Evergreen.V252.Id.GuildId) Evergreen.V252.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V252.Id.AnyGuildOrDmId, Evergreen.V252.Id.ThreadRoute ) (Evergreen.V252.Id.Id Evergreen.V252.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V252.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V252.Id.AnyGuildOrDmId, Evergreen.V252.Id.ThreadRoute ) (Evergreen.V252.Id.Id Evergreen.V252.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V252.Id.AnyGuildOrDmId, Evergreen.V252.Id.ThreadRoute ) (Evergreen.V252.Id.Id Evergreen.V252.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V252.Id.AnyGuildOrDmId, Evergreen.V252.Id.ThreadRoute )
        { fileId : Evergreen.V252.Id.Id Evergreen.V252.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V252.Id.AnyGuildOrDmId, Evergreen.V252.Id.ThreadRoute ) (Evergreen.V252.Id.Id Evergreen.V252.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V252.Id.AnyGuildOrDmId, Evergreen.V252.Id.ThreadRoute ) (Evergreen.V252.Id.Id Evergreen.V252.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V252.Id.AnyGuildOrDmId, Evergreen.V252.Id.ThreadRoute )
        { fileId : Evergreen.V252.Id.Id Evergreen.V252.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V252.Id.AnyGuildOrDmId, Evergreen.V252.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V252.Id.AnyGuildOrDmId, Evergreen.V252.Id.ThreadRoute ) (Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelMessageId) (Evergreen.V252.Id.Id Evergreen.V252.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V252.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V252.Id.AnyGuildOrDmId, Evergreen.V252.Id.ThreadRoute ) (Evergreen.V252.Id.Id Evergreen.V252.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V252.Id.AnyGuildOrDmId Evergreen.V252.Id.ThreadRouteWithMessage Evergreen.V252.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V252.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V252.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V252.Id.Id Evergreen.V252.Id.GuildId) Evergreen.V252.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId) (Evergreen.V252.Discord.Id Evergreen.V252.Discord.GuildId) Evergreen.V252.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V252.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V252.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId
        , otherUserId : Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V252.Id.AnyGuildOrDmId Evergreen.V252.Id.ThreadRoute Evergreen.V252.MessageInput.Msg
    | MessageInputMsg Evergreen.V252.Id.AnyGuildOrDmId Evergreen.V252.Id.ThreadRoute Evergreen.V252.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V252.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V252.Range.Range, Evergreen.V252.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V252.Range.Range, Evergreen.V252.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V252.Call.FromJs)
    | VoiceChatMsg Evergreen.V252.Call.Msg
    | PressedChannelHeaderTab Evergreen.V252.Route.DmChannelHeaderTab
    | FileDragEnter
    | FileDragLeave
    | FileDropped (List Effect.File.File)


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V252.Id.Id Evergreen.V252.Id.GuildId) (Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelId) Evergreen.V252.Id.ThreadRoute
    | InitialLoadRequested_Dm Evergreen.V252.DmChannel.DmChannelId Evergreen.V252.Id.ThreadRoute
    | InitialLoadRequested_Discord Evergreen.V252.Id.DiscordGuildOrDmId Evergreen.V252.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V252.Id.Id Evergreen.V252.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V252.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V252.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V252.Untrusted.Untrusted Evergreen.V252.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V252.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V252.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V252.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V252.Id.Id Evergreen.V252.Id.GuildId) (Evergreen.V252.SecretId.SecretId Evergreen.V252.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V252.PersonName.PersonName Evergreen.V252.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V252.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V252.Slack.OAuthCode Evergreen.V252.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V252.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V252.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V252.Id.Id Evergreen.V252.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V252.SecretId.SecretId Evergreen.V252.Id.GoMatchPublicId)


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V252.Discord.Id Evergreen.V252.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V252.Discord.Id Evergreen.V252.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V252.EmailAddress.EmailAddress (Result Evergreen.V252.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V252.EmailAddress.EmailAddress (Result Evergreen.V252.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V252.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V252.Discord.Id Evergreen.V252.Discord.GuildId) (Evergreen.V252.Discord.Id Evergreen.V252.Discord.ChannelId) Evergreen.V252.Id.ThreadRouteWithMaybeMessage (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId) (Result Evergreen.V252.Discord.HttpError Evergreen.V252.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V252.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V252.Discord.Id Evergreen.V252.Discord.PrivateChannelId) (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId) (Result Evergreen.V252.Discord.HttpError Evergreen.V252.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V252.Discord.Id Evergreen.V252.Discord.GuildId) (Evergreen.V252.Discord.Id Evergreen.V252.Discord.ChannelId) Evergreen.V252.Id.ThreadRouteWithMessage (Evergreen.V252.Discord.Id Evergreen.V252.Discord.MessageId) (Result Evergreen.V252.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V252.Discord.Id Evergreen.V252.Discord.PrivateChannelId) (Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelMessageId) (Evergreen.V252.Discord.Id Evergreen.V252.Discord.MessageId) (Result Evergreen.V252.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V252.Discord.Id Evergreen.V252.Discord.GuildId) (Evergreen.V252.Discord.Id Evergreen.V252.Discord.ChannelId) Evergreen.V252.Id.ThreadRouteWithMessage (Evergreen.V252.Discord.Id Evergreen.V252.Discord.MessageId) (Result Evergreen.V252.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V252.Discord.Id Evergreen.V252.Discord.PrivateChannelId) (Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelMessageId) (Evergreen.V252.Discord.Id Evergreen.V252.Discord.MessageId) (Result Evergreen.V252.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V252.Discord.Id Evergreen.V252.Discord.GuildId) (Evergreen.V252.Discord.Id Evergreen.V252.Discord.ChannelId) Evergreen.V252.Id.ThreadRouteWithMessage (Evergreen.V252.Discord.Id Evergreen.V252.Discord.MessageId) Evergreen.V252.Emoji.EmojiOrCustomEmoji (Result Evergreen.V252.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V252.Discord.Id Evergreen.V252.Discord.PrivateChannelId) (Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelMessageId) (Evergreen.V252.Discord.Id Evergreen.V252.Discord.MessageId) Evergreen.V252.Emoji.EmojiOrCustomEmoji (Result Evergreen.V252.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V252.Discord.Id Evergreen.V252.Discord.GuildId) (Evergreen.V252.Discord.Id Evergreen.V252.Discord.ChannelId) Evergreen.V252.Id.ThreadRouteWithMessage (Evergreen.V252.Discord.Id Evergreen.V252.Discord.MessageId) Evergreen.V252.Emoji.EmojiOrCustomEmoji (Result Evergreen.V252.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V252.Discord.Id Evergreen.V252.Discord.PrivateChannelId) (Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelMessageId) (Evergreen.V252.Discord.Id Evergreen.V252.Discord.MessageId) Evergreen.V252.Emoji.EmojiOrCustomEmoji (Result Evergreen.V252.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V252.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V252.Discord.HttpError (List ( Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId, Maybe Evergreen.V252.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V252.Slack.CurrentUser
            , team : Evergreen.V252.Slack.Team
            , users : List Evergreen.V252.Slack.User
            , channels : List ( Evergreen.V252.Slack.Channel, List Evergreen.V252.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId) (Result Effect.Http.Error Evergreen.V252.Slack.TokenResponse)
    | GotCloudflareSessionCreated Effect.Lamdera.ClientId Evergreen.V252.Local.ChangeId Effect.Time.Posix Evergreen.V252.Call.RoomId Evergreen.V252.Cloudflare.Sdp (List String) (Result Effect.Http.Error Evergreen.V252.Cloudflare.RealtimeSessionId)
    | GotCloudflareSession Effect.Lamdera.ClientId Evergreen.V252.Local.ChangeId Effect.Time.Posix Evergreen.V252.Call.RoomId Evergreen.V252.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V252.Cloudflare.PushTracksResult)
    | GotCloudflarePullOffer Effect.Time.Posix Effect.Lamdera.ClientId Evergreen.V252.Local.ChangeId Evergreen.V252.Call.ConnectionId Evergreen.V252.Cloudflare.RealtimeSessionId (List Evergreen.V252.Cloudflare.TrackName) (Result Effect.Http.Error Evergreen.V252.Cloudflare.PullTracksResult)
    | GotCloudflareRenegotiateAck Effect.Lamdera.ClientId Evergreen.V252.Local.ChangeId Evergreen.V252.Cloudflare.Sdp (Result Effect.Http.Error ())
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId) Evergreen.V252.Discord.UserAuth (Result Evergreen.V252.Discord.HttpError Evergreen.V252.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId) (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId) (Result Evergreen.V252.Discord.HttpError Evergreen.V252.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId)
        (Result
            Evergreen.V252.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V252.Discord.Id Evergreen.V252.Discord.PrivateChannelId
                , members : List (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId)
                }
            , List
                ( Evergreen.V252.Discord.Id Evergreen.V252.Discord.GuildId
                , { guild : Evergreen.V252.Discord.GatewayGuild
                  , channels : List Evergreen.V252.Discord.Channel
                  , icon : Maybe Evergreen.V252.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId) Bool Evergreen.V252.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V252.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V252.Discord.Id Evergreen.V252.Discord.AttachmentId, Evergreen.V252.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V252.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V252.Discord.Id Evergreen.V252.Discord.AttachmentId, Evergreen.V252.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId) (Evergreen.V252.Discord.Id Evergreen.V252.Discord.GuildId) (Evergreen.V252.Discord.Id Evergreen.V252.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V252.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V252.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId) (Evergreen.V252.Discord.Id Evergreen.V252.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V252.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V252.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId) (Evergreen.V252.Discord.Id Evergreen.V252.Discord.GuildId) (Evergreen.V252.Discord.Id Evergreen.V252.Discord.ChannelId) (Result Evergreen.V252.Discord.HttpError (List Evergreen.V252.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId) (Evergreen.V252.Discord.Id Evergreen.V252.Discord.PrivateChannelId) (Result Evergreen.V252.Discord.HttpError (List Evergreen.V252.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V252.Id.Id Evergreen.V252.Id.GuildId) (Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelId) Evergreen.V252.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V252.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V252.DmChannel.DmChannelId Evergreen.V252.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V252.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V252.Discord.Id Evergreen.V252.Discord.GuildId) (Evergreen.V252.Discord.Id Evergreen.V252.Discord.ChannelId) Evergreen.V252.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V252.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V252.Discord.Id Evergreen.V252.Discord.PrivateChannelId) (Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V252.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId)
        (Evergreen.V252.Discord.Id Evergreen.V252.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V252.Discord.HttpError
            { guild : Evergreen.V252.Discord.GatewayGuild
            , channels : List Evergreen.V252.Discord.Channel
            , icon : Maybe Evergreen.V252.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V252.Discord.Id Evergreen.V252.Discord.GuildId) (Result Evergreen.V252.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V252.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId) (List ( Evergreen.V252.Id.Id Evergreen.V252.Id.StickerId, Result Effect.Http.Error Evergreen.V252.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V252.Id.Id Evergreen.V252.Id.StickerId, Result Effect.Http.Error Evergreen.V252.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId) (List ( Evergreen.V252.Id.Id Evergreen.V252.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V252.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V252.Id.Id Evergreen.V252.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V252.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V252.Discord.HttpError (List Evergreen.V252.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V252.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V252.SecretId.SecretId Evergreen.V252.SecretId.ServerSecret))
    | GotTimeForWebsocketListenClose (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
