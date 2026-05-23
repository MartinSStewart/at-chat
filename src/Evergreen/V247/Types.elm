module Evergreen.V247.Types exposing (..)

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
import Evergreen.V247.AiChat
import Evergreen.V247.Call
import Evergreen.V247.ChannelDescription
import Evergreen.V247.ChannelName
import Evergreen.V247.Cloudflare
import Evergreen.V247.Coord
import Evergreen.V247.CssPixels
import Evergreen.V247.CustomEmoji
import Evergreen.V247.Discord
import Evergreen.V247.DiscordAttachmentId
import Evergreen.V247.DiscordUserData
import Evergreen.V247.DmChannel
import Evergreen.V247.Editable
import Evergreen.V247.EmailAddress
import Evergreen.V247.Embed
import Evergreen.V247.Emoji
import Evergreen.V247.FileStatus
import Evergreen.V247.Go
import Evergreen.V247.GuildName
import Evergreen.V247.Id
import Evergreen.V247.ImageEditor
import Evergreen.V247.Local
import Evergreen.V247.LocalState
import Evergreen.V247.Log
import Evergreen.V247.LoginForm
import Evergreen.V247.MembersAndOwner
import Evergreen.V247.Message
import Evergreen.V247.MessageInput
import Evergreen.V247.MessageView
import Evergreen.V247.MyUi
import Evergreen.V247.NonemptyDict
import Evergreen.V247.NonemptySet
import Evergreen.V247.OneToOne
import Evergreen.V247.Pages.Admin
import Evergreen.V247.Pagination
import Evergreen.V247.PersonName
import Evergreen.V247.Ports
import Evergreen.V247.Postmark
import Evergreen.V247.Range
import Evergreen.V247.RichText
import Evergreen.V247.Route
import Evergreen.V247.SecretId
import Evergreen.V247.SessionIdHash
import Evergreen.V247.Slack
import Evergreen.V247.Sticker
import Evergreen.V247.TextEditor
import Evergreen.V247.ToBackendLog
import Evergreen.V247.Touch
import Evergreen.V247.TwoFactorAuthentication
import Evergreen.V247.Ui.Anim
import Evergreen.V247.Untrusted
import Evergreen.V247.User
import Evergreen.V247.UserAgent
import Evergreen.V247.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V247.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V247.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.Id.GuildId) Evergreen.V247.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId) Evergreen.V247.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V247.Discord.Id Evergreen.V247.Discord.PrivateChannelId) Evergreen.V247.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V247.Discord.Id Evergreen.V247.Discord.GuildId) Evergreen.V247.LocalState.DiscordFrontendGuild
    , user : Evergreen.V247.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId) Evergreen.V247.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId) Evergreen.V247.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId) Evergreen.V247.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V247.SessionIdHash.SessionIdHash Evergreen.V247.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V247.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.Id.StickerId) Evergreen.V247.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.Id.CustomEmojiId) Evergreen.V247.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V247.Call.RoomId (Evergreen.V247.NonemptySet.NonemptySet ( Evergreen.V247.Id.Id Evergreen.V247.Id.UserId, Effect.Lamdera.ClientId ))
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type PublicGoMatch
    = PublicGoMatch_NotLoaded
    | PublicGoMatch_Loading
    | PublicGoMatch_Loaded Evergreen.V247.Go.PublicGoMatchData Evergreen.V247.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V247.Route.Route
    , windowSize : Evergreen.V247.Coord.Coord Evergreen.V247.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V247.Ports.NotificationPermission
    , pwaStatus : Evergreen.V247.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V247.UserAgent.UserAgent
    , publicGoMatch : PublicGoMatch
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V247.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V247.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V247.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.FileStatus.FileId) Evergreen.V247.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V247.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V247.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.FileStatus.FileId) Evergreen.V247.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V247.Id.Id Evergreen.V247.Id.GuildId) Evergreen.V247.ChannelName.ChannelName Evergreen.V247.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V247.Id.Id Evergreen.V247.Id.GuildId) (Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelId) Evergreen.V247.ChannelName.ChannelName Evergreen.V247.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V247.Id.Id Evergreen.V247.Id.GuildId) (Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelId)
    | Local_DeleteGuild (Evergreen.V247.Id.Id Evergreen.V247.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V247.Id.Id Evergreen.V247.Id.GuildId) (Evergreen.V247.UserSession.ToBeFilledInByBackend (Evergreen.V247.SecretId.SecretId Evergreen.V247.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V247.Id.Id Evergreen.V247.Id.GuildId) (Evergreen.V247.SecretId.SecretId Evergreen.V247.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V247.GuildName.GuildName (Evergreen.V247.UserSession.ToBeFilledInByBackend (Evergreen.V247.Id.Id Evergreen.V247.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V247.Id.AnyGuildOrDmId, Evergreen.V247.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V247.Id.AnyGuildOrDmId Evergreen.V247.Id.ThreadRouteWithMessage Evergreen.V247.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V247.Id.AnyGuildOrDmId Evergreen.V247.Id.ThreadRouteWithMessage Evergreen.V247.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V247.Id.GuildOrDmId Evergreen.V247.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.FileStatus.FileId) Evergreen.V247.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId) (Evergreen.V247.Discord.Id Evergreen.V247.Discord.GuildId) (Evergreen.V247.Discord.Id Evergreen.V247.Discord.ChannelId) Evergreen.V247.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V247.Id.DiscordGuildOrDmId_DmData (Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V247.Id.AnyGuildOrDmId Evergreen.V247.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V247.Id.AnyGuildOrDmId Evergreen.V247.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V247.Id.AnyGuildOrDmId Evergreen.V247.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V247.UserSession.SetViewing
    | Local_SetName Evergreen.V247.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V247.Id.GuildOrDmId (Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelMessageId) (Evergreen.V247.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelMessageId) (Evergreen.V247.Message.Message Evergreen.V247.Id.ChannelMessageId (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V247.Id.GuildOrDmId (Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelMessageId) (Evergreen.V247.Id.Id Evergreen.V247.Id.ThreadMessageId) (Evergreen.V247.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.Id.ThreadMessageId) (Evergreen.V247.Message.Message Evergreen.V247.Id.ThreadMessageId (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V247.Id.DiscordGuildOrDmId (Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelMessageId) (Evergreen.V247.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelMessageId) (Evergreen.V247.Message.Message Evergreen.V247.Id.ChannelMessageId (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V247.Id.DiscordGuildOrDmId (Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelMessageId) (Evergreen.V247.Id.Id Evergreen.V247.Id.ThreadMessageId) (Evergreen.V247.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.Id.ThreadMessageId) (Evergreen.V247.Message.Message Evergreen.V247.Id.ThreadMessageId (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V247.Id.Id Evergreen.V247.Id.GuildId) Evergreen.V247.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId) (Evergreen.V247.Discord.Id Evergreen.V247.Discord.GuildId) Evergreen.V247.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V247.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V247.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V247.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V247.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V247.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V247.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V247.NonemptySet.NonemptySet (Evergreen.V247.Id.Id Evergreen.V247.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V247.Call.LocalChange
    | Local_Go
        { otherUserId : Evergreen.V247.Id.Id Evergreen.V247.Id.UserId
        }
        Evergreen.V247.Go.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId) Effect.Time.Posix Evergreen.V247.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V247.RichText.RichText (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId))) Evergreen.V247.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.FileStatus.FileId) Evergreen.V247.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.Id.StickerId) Evergreen.V247.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V247.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V247.RichText.RichText (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId))) Evergreen.V247.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.FileStatus.FileId) Evergreen.V247.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.Id.StickerId) Evergreen.V247.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V247.Id.Id Evergreen.V247.Id.GuildId) Evergreen.V247.ChannelName.ChannelName Evergreen.V247.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V247.Id.Id Evergreen.V247.Id.GuildId) (Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelId) Evergreen.V247.ChannelName.ChannelName Evergreen.V247.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V247.Id.Id Evergreen.V247.Id.GuildId) (Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelId)
    | Server_DeleteGuild (Evergreen.V247.Id.Id Evergreen.V247.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId) (Evergreen.V247.Id.Id Evergreen.V247.Id.GuildId) (Evergreen.V247.SecretId.SecretId Evergreen.V247.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V247.Id.Id Evergreen.V247.Id.GuildId) (Evergreen.V247.SecretId.SecretId Evergreen.V247.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId) (Evergreen.V247.Id.Id Evergreen.V247.Id.GuildId) Evergreen.V247.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V247.LocalState.JoinGuildError
            { guildId : Evergreen.V247.Id.Id Evergreen.V247.Id.GuildId
            , guild : Evergreen.V247.LocalState.FrontendGuild
            , owner : Evergreen.V247.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId) Evergreen.V247.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId) Evergreen.V247.Id.GuildOrDmId Evergreen.V247.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId) (Evergreen.V247.Discord.Id Evergreen.V247.Discord.GuildId) (Evergreen.V247.Discord.Id Evergreen.V247.Discord.ChannelId) Evergreen.V247.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId) (Evergreen.V247.Discord.Id Evergreen.V247.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId) Evergreen.V247.Id.GuildOrDmId Evergreen.V247.Id.ThreadRouteWithMessage Evergreen.V247.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId) Evergreen.V247.Id.GuildOrDmId Evergreen.V247.Id.ThreadRouteWithMessage Evergreen.V247.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId) (Evergreen.V247.Discord.Id Evergreen.V247.Discord.GuildId) (Evergreen.V247.Discord.Id Evergreen.V247.Discord.ChannelId) Evergreen.V247.Id.ThreadRouteWithMessage Evergreen.V247.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId) (Evergreen.V247.Discord.Id Evergreen.V247.Discord.PrivateChannelId) (Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelMessageId) Evergreen.V247.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId) (Evergreen.V247.Discord.Id Evergreen.V247.Discord.GuildId) (Evergreen.V247.Discord.Id Evergreen.V247.Discord.ChannelId) Evergreen.V247.Id.ThreadRouteWithMessage Evergreen.V247.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId) (Evergreen.V247.Discord.Id Evergreen.V247.Discord.PrivateChannelId) (Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelMessageId) Evergreen.V247.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId) Evergreen.V247.Id.GuildOrDmId Evergreen.V247.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V247.RichText.RichText (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId))) (SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.FileStatus.FileId) Evergreen.V247.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId) (Evergreen.V247.Discord.Id Evergreen.V247.Discord.GuildId) (Evergreen.V247.Discord.Id Evergreen.V247.Discord.ChannelId) Evergreen.V247.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V247.RichText.RichText (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V247.Id.DiscordGuildOrDmId_DmData (Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V247.RichText.RichText (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId) Evergreen.V247.Id.AnyGuildOrDmId Evergreen.V247.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V247.Id.AnyGuildOrDmId Evergreen.V247.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V247.Discord.Id Evergreen.V247.Discord.GuildId) (Evergreen.V247.Discord.Id Evergreen.V247.Discord.ChannelId) Evergreen.V247.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V247.Discord.Id Evergreen.V247.Discord.PrivateChannelId) (Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId) Evergreen.V247.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId) Evergreen.V247.FileStatus.FileHash
    | Server_SetGuildIcon (Evergreen.V247.Id.Id Evergreen.V247.Id.GuildId) Evergreen.V247.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V247.Id.Id Evergreen.V247.Id.GuildId) Evergreen.V247.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V247.Discord.Id Evergreen.V247.Discord.GuildId) Evergreen.V247.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V247.SessionIdHash.SessionIdHash Evergreen.V247.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V247.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V247.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V247.Id.AnyGuildOrDmId, Evergreen.V247.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V247.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId) Evergreen.V247.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V247.Discord.Id Evergreen.V247.Discord.GuildId) (Evergreen.V247.Discord.Id Evergreen.V247.Discord.ChannelId) Evergreen.V247.ChannelName.ChannelName (Evergreen.V247.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V247.Discord.Id Evergreen.V247.Discord.PrivateChannelId)
        (Evergreen.V247.NonemptyDict.NonemptyDict
            (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V247.Discord.Id Evergreen.V247.Discord.GuildId) Evergreen.V247.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V247.Discord.Id Evergreen.V247.Discord.PrivateChannelId) Evergreen.V247.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId) Evergreen.V247.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId) (Maybe (Evergreen.V247.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V247.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V247.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V247.Id.Id Evergreen.V247.Id.GuildId) (Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelId) Evergreen.V247.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V247.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId) Evergreen.V247.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V247.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V247.Discord.Id Evergreen.V247.Discord.GuildId) (Evergreen.V247.Discord.Id Evergreen.V247.Discord.ChannelId) Evergreen.V247.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V247.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V247.Discord.Id Evergreen.V247.Discord.PrivateChannelId) (Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V247.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V247.Discord.Id Evergreen.V247.Discord.GuildId) Evergreen.V247.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V247.Discord.Id Evergreen.V247.Discord.GuildId) (Evergreen.V247.Discord.Id Evergreen.V247.Discord.ChannelId) (Evergreen.V247.Discord.OptionalData String) (Evergreen.V247.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V247.Discord.Id Evergreen.V247.Discord.GuildId)
        (Evergreen.V247.MembersAndOwner.MembersAndOwner
            (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V247.Discord.Id Evergreen.V247.Discord.GuildId) (Evergreen.V247.Discord.Id Evergreen.V247.Discord.ChannelId) (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId) Evergreen.V247.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.Id.StickerId) Evergreen.V247.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.Id.CustomEmojiId) Evergreen.V247.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V247.Call.ServerChange
    | Server_Go
        (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId)
        { otherUserId : Evergreen.V247.Id.Id Evergreen.V247.Id.UserId
        }
        Evergreen.V247.Go.LocalChange


type LocalMsg
    = LocalChange (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V247.Id.Id Evergreen.V247.Id.GuildId) (Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelId) Evergreen.V247.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V247.Discord.Id Evergreen.V247.Discord.GuildId) (Evergreen.V247.Discord.Id Evergreen.V247.Discord.ChannelId) Evergreen.V247.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.FileStatus.FileId) Evergreen.V247.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V247.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V247.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V247.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V247.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V247.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V247.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V247.Coord.Coord Evergreen.V247.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V247.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V247.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V247.Id.AnyGuildOrDmId Evergreen.V247.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V247.Id.AnyGuildOrDmId Evergreen.V247.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V247.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V247.Coord.Coord Evergreen.V247.CssPixels.CssPixels) (Maybe Evergreen.V247.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V247.Id.AnyGuildOrDmId, Evergreen.V247.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelMessageId) (Evergreen.V247.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.Id.ThreadMessageId) (Evergreen.V247.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V247.Editable.Model
    , showLinkDiscordSetup : Bool
    , domainWhitelistInput : String
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V247.Local.Local LocalMsg Evergreen.V247.LocalState.LocalState
    , admin : Evergreen.V247.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V247.Id.AnyGuildOrDmId, Evergreen.V247.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V247.Id.Id Evergreen.V247.Id.GuildId, Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V247.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V247.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V247.Id.AnyGuildOrDmId, Evergreen.V247.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V247.Id.AnyGuildOrDmId, Evergreen.V247.Id.ThreadRoute ) (Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : Evergreen.V247.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V247.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V247.Id.AnyGuildOrDmId, Evergreen.V247.Id.ThreadRoute ) (Evergreen.V247.NonemptyDict.NonemptyDict (Evergreen.V247.Id.Id Evergreen.V247.FileStatus.FileId) Evergreen.V247.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V247.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V247.TextEditor.Model
    , profilePictureEditor : Evergreen.V247.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V247.Id.Id Evergreen.V247.Id.GuildId, Evergreen.V247.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V247.Emoji.Model
    , voiceChat : Evergreen.V247.Call.Model
    , currentDmGoMatch : SeqDict.SeqDict ( Evergreen.V247.Id.Id Evergreen.V247.Id.UserId, Maybe (Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelMessageId) ) Evergreen.V247.Go.Model
    , fileDragOverCount : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V247.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V247.SecretId.SecretId Evergreen.V247.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V247.Range.Range
                , direction : Evergreen.V247.Range.SelectionDirection
                }
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V247.NonemptyDict.NonemptyDict Int Evergreen.V247.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V247.NonemptyDict.NonemptyDict Int Evergreen.V247.Touch.Touch
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
    | AdminToFrontend Evergreen.V247.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V247.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V247.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V247.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V247.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V247.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V247.Go.PublicGoMatchData)


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V247.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V247.Coord.Coord Evergreen.V247.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V247.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V247.MyUi.LastCopy
    , notificationPermission : Evergreen.V247.Ports.NotificationPermission
    , pwaStatus : Evergreen.V247.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V247.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V247.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V247.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V247.Id.Id Evergreen.V247.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V247.Id.Id Evergreen.V247.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V247.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V247.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V247.Coord.Coord Evergreen.V247.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V247.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V247.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V247.Id.Id Evergreen.V247.Id.GuildId, Evergreen.V247.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V247.DmChannel.DmChannelId, Evergreen.V247.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V247.Discord.Id Evergreen.V247.Discord.GuildId, Evergreen.V247.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V247.Discord.Id Evergreen.V247.Discord.PrivateChannelId, Evergreen.V247.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V247.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V247.NonemptyDict.NonemptyDict (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId) Evergreen.V247.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V247.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V247.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V247.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V247.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId) Evergreen.V247.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId) Evergreen.V247.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V247.Id.Id Evergreen.V247.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.Id.GuildId) Evergreen.V247.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.Id.GuildId) Evergreen.V247.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V247.Discord.Id Evergreen.V247.Discord.GuildId) Evergreen.V247.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V247.DmChannel.DmChannelId Evergreen.V247.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V247.Discord.Id Evergreen.V247.Discord.PrivateChannelId) Evergreen.V247.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V247.OneToOne.OneToOne (Evergreen.V247.Slack.Id Evergreen.V247.Slack.ChannelId) Evergreen.V247.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V247.OneToOne.OneToOne String (Evergreen.V247.Id.Id Evergreen.V247.Id.GuildId)
    , slackUsers : Evergreen.V247.OneToOne.OneToOne (Evergreen.V247.Slack.Id Evergreen.V247.Slack.UserId) (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId)
    , slackServers : Evergreen.V247.OneToOne.OneToOne (Evergreen.V247.Slack.Id Evergreen.V247.Slack.TeamId) (Evergreen.V247.Id.Id Evergreen.V247.Id.GuildId)
    , slackToken : Maybe Evergreen.V247.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V247.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V247.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V247.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareTurnApiToken : Maybe String
    , textEditor : Evergreen.V247.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId) Evergreen.V247.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId, Evergreen.V247.Discord.Id Evergreen.V247.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V247.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V247.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V247.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V247.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId) (Evergreen.V247.LocalState.LoadingDiscordChannel (List Evergreen.V247.Discord.Message))
    , signupsEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V247.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.Id.StickerId) Evergreen.V247.Sticker.StickerData
    , discordStickers : Evergreen.V247.OneToOne.OneToOne (Evergreen.V247.Discord.Id Evergreen.V247.Discord.StickerId) (Evergreen.V247.Id.Id Evergreen.V247.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.Id.CustomEmojiId) Evergreen.V247.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V247.OneToOne.OneToOne Evergreen.V247.RichText.DiscordCustomEmojiIdAndName (Evergreen.V247.Id.Id Evergreen.V247.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V247.Postmark.ApiKey
    , serverSecret : Evergreen.V247.SecretId.SecretId Evergreen.V247.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V247.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V247.OneToOne.OneToOne (Evergreen.V247.SecretId.SecretId Evergreen.V247.Id.GoMatchPublicId) ( Evergreen.V247.DmChannel.DmChannelId, Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelMessageId )
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V247.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V247.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V247.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V247.Route.Route
    | SelectedFilesToAttach ( Evergreen.V247.Id.AnyGuildOrDmId, Evergreen.V247.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V247.Id.Id Evergreen.V247.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V247.Id.Id Evergreen.V247.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V247.Id.Id Evergreen.V247.Id.GuildId) (Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelId) Evergreen.V247.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V247.Id.Id Evergreen.V247.Id.GuildId) (Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelId) Evergreen.V247.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V247.Discord.Id Evergreen.V247.Discord.GuildId) (Evergreen.V247.Discord.Id Evergreen.V247.Discord.ChannelId) Evergreen.V247.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V247.Discord.Id Evergreen.V247.Discord.GuildId) (Evergreen.V247.Discord.Id Evergreen.V247.Discord.ChannelId) Evergreen.V247.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V247.Id.Id Evergreen.V247.Id.GuildId) (Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V247.Id.Id Evergreen.V247.Id.GuildId) (Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V247.Id.Id Evergreen.V247.Id.GuildId) (Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V247.Id.Id Evergreen.V247.Id.GuildId) (Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V247.Id.Id Evergreen.V247.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V247.Id.Id Evergreen.V247.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V247.Id.Id Evergreen.V247.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V247.Id.Id Evergreen.V247.Id.GuildId) (Evergreen.V247.SecretId.SecretId Evergreen.V247.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V247.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V247.Id.AnyGuildOrDmId Evergreen.V247.Id.ThreadRouteWithMessage (Evergreen.V247.Coord.Coord Evergreen.V247.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V247.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V247.Id.AnyGuildOrDmId Evergreen.V247.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V247.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V247.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V247.Id.AnyGuildOrDmId, Evergreen.V247.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V247.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V247.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V247.Id.AnyGuildOrDmId, Evergreen.V247.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V247.NonemptyDict.NonemptyDict Int Evergreen.V247.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V247.NonemptyDict.NonemptyDict Int Evergreen.V247.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V247.Id.AnyGuildOrDmId Evergreen.V247.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V247.Id.AnyGuildOrDmId Evergreen.V247.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V247.NonemptySet.NonemptySet (Evergreen.V247.Id.Id Evergreen.V247.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V247.Id.AnyGuildOrDmId, Evergreen.V247.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V247.Id.AnyGuildOrDmId Evergreen.V247.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V247.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V247.AiChat.Msg
    | GoMsg Evergreen.V247.Go.Msg
    | GoSpectatorMsg Evergreen.V247.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V247.Editable.Msg Evergreen.V247.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V247.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V247.Id.Id Evergreen.V247.Id.GuildId) Evergreen.V247.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V247.Id.AnyGuildOrDmId, Evergreen.V247.Id.ThreadRoute ) (Evergreen.V247.Id.Id Evergreen.V247.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V247.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V247.Id.AnyGuildOrDmId, Evergreen.V247.Id.ThreadRoute ) (Evergreen.V247.Id.Id Evergreen.V247.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V247.Id.AnyGuildOrDmId, Evergreen.V247.Id.ThreadRoute ) (Evergreen.V247.Id.Id Evergreen.V247.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V247.Id.AnyGuildOrDmId, Evergreen.V247.Id.ThreadRoute )
        { fileId : Evergreen.V247.Id.Id Evergreen.V247.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V247.Id.AnyGuildOrDmId, Evergreen.V247.Id.ThreadRoute ) (Evergreen.V247.Id.Id Evergreen.V247.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V247.Id.AnyGuildOrDmId, Evergreen.V247.Id.ThreadRoute ) (Evergreen.V247.Id.Id Evergreen.V247.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V247.Id.AnyGuildOrDmId, Evergreen.V247.Id.ThreadRoute )
        { fileId : Evergreen.V247.Id.Id Evergreen.V247.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V247.Id.AnyGuildOrDmId, Evergreen.V247.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V247.Id.AnyGuildOrDmId, Evergreen.V247.Id.ThreadRoute ) (Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelMessageId) (Evergreen.V247.Id.Id Evergreen.V247.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V247.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V247.Id.AnyGuildOrDmId, Evergreen.V247.Id.ThreadRoute ) (Evergreen.V247.Id.Id Evergreen.V247.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V247.Id.AnyGuildOrDmId Evergreen.V247.Id.ThreadRouteWithMessage Evergreen.V247.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V247.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V247.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V247.Id.Id Evergreen.V247.Id.GuildId) Evergreen.V247.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId) (Evergreen.V247.Discord.Id Evergreen.V247.Discord.GuildId) Evergreen.V247.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V247.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V247.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId
        , otherUserId : Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V247.Id.AnyGuildOrDmId Evergreen.V247.Id.ThreadRoute Evergreen.V247.MessageInput.Msg
    | MessageInputMsg Evergreen.V247.Id.AnyGuildOrDmId Evergreen.V247.Id.ThreadRoute Evergreen.V247.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V247.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V247.Range.Range, Evergreen.V247.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V247.Range.Range, Evergreen.V247.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V247.Call.FromJs)
    | VoiceChatMsg Evergreen.V247.Call.Msg
    | PressedChannelHeaderTab Evergreen.V247.Route.DmChannelHeaderTab
    | FileDragEnter
    | FileDragLeave
    | FileDropped (List Effect.File.File)


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V247.Id.Id Evergreen.V247.Id.GuildId) (Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelId) Evergreen.V247.Id.ThreadRoute
    | InitialLoadRequested_Dm Evergreen.V247.DmChannel.DmChannelId Evergreen.V247.Id.ThreadRoute
    | InitialLoadRequested_Discord Evergreen.V247.Id.DiscordGuildOrDmId Evergreen.V247.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V247.Id.Id Evergreen.V247.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V247.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V247.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V247.Untrusted.Untrusted Evergreen.V247.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V247.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V247.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V247.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V247.Id.Id Evergreen.V247.Id.GuildId) (Evergreen.V247.SecretId.SecretId Evergreen.V247.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V247.PersonName.PersonName Evergreen.V247.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V247.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V247.Slack.OAuthCode Evergreen.V247.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V247.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V247.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V247.Id.Id Evergreen.V247.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V247.SecretId.SecretId Evergreen.V247.Id.GoMatchPublicId)


type alias PendingVoiceChatJoin =
    { sessionId : Effect.Lamdera.SessionId
    , clientId : Effect.Lamdera.ClientId
    , changeId : Evergreen.V247.Local.ChangeId
    , time : Effect.Time.Posix
    , userId : Evergreen.V247.Id.Id Evergreen.V247.Id.UserId
    , otherUserId : Evergreen.V247.Id.Id Evergreen.V247.Id.UserId
    , dmChannelId : Evergreen.V247.DmChannel.DmChannelId
    , roomId : Evergreen.V247.Call.RoomId
    }


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V247.Discord.Id Evergreen.V247.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V247.Discord.Id Evergreen.V247.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V247.EmailAddress.EmailAddress (Result Evergreen.V247.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V247.EmailAddress.EmailAddress (Result Evergreen.V247.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId) Evergreen.V247.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V247.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V247.Discord.Id Evergreen.V247.Discord.GuildId) (Evergreen.V247.Discord.Id Evergreen.V247.Discord.ChannelId) Evergreen.V247.Id.ThreadRouteWithMaybeMessage (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId) (Result Evergreen.V247.Discord.HttpError Evergreen.V247.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V247.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V247.Discord.Id Evergreen.V247.Discord.PrivateChannelId) (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId) (Result Evergreen.V247.Discord.HttpError Evergreen.V247.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V247.Discord.Id Evergreen.V247.Discord.GuildId) (Evergreen.V247.Discord.Id Evergreen.V247.Discord.ChannelId) Evergreen.V247.Id.ThreadRouteWithMessage (Evergreen.V247.Discord.Id Evergreen.V247.Discord.MessageId) (Result Evergreen.V247.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V247.Discord.Id Evergreen.V247.Discord.PrivateChannelId) (Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelMessageId) (Evergreen.V247.Discord.Id Evergreen.V247.Discord.MessageId) (Result Evergreen.V247.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V247.Discord.Id Evergreen.V247.Discord.GuildId) (Evergreen.V247.Discord.Id Evergreen.V247.Discord.ChannelId) Evergreen.V247.Id.ThreadRouteWithMessage (Evergreen.V247.Discord.Id Evergreen.V247.Discord.MessageId) (Result Evergreen.V247.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V247.Discord.Id Evergreen.V247.Discord.PrivateChannelId) (Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelMessageId) (Evergreen.V247.Discord.Id Evergreen.V247.Discord.MessageId) (Result Evergreen.V247.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V247.Discord.Id Evergreen.V247.Discord.GuildId) (Evergreen.V247.Discord.Id Evergreen.V247.Discord.ChannelId) Evergreen.V247.Id.ThreadRouteWithMessage (Evergreen.V247.Discord.Id Evergreen.V247.Discord.MessageId) Evergreen.V247.Emoji.EmojiOrCustomEmoji (Result Evergreen.V247.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V247.Discord.Id Evergreen.V247.Discord.PrivateChannelId) (Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelMessageId) (Evergreen.V247.Discord.Id Evergreen.V247.Discord.MessageId) Evergreen.V247.Emoji.EmojiOrCustomEmoji (Result Evergreen.V247.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V247.Discord.Id Evergreen.V247.Discord.GuildId) (Evergreen.V247.Discord.Id Evergreen.V247.Discord.ChannelId) Evergreen.V247.Id.ThreadRouteWithMessage (Evergreen.V247.Discord.Id Evergreen.V247.Discord.MessageId) Evergreen.V247.Emoji.EmojiOrCustomEmoji (Result Evergreen.V247.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V247.Discord.Id Evergreen.V247.Discord.PrivateChannelId) (Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelMessageId) (Evergreen.V247.Discord.Id Evergreen.V247.Discord.MessageId) Evergreen.V247.Emoji.EmojiOrCustomEmoji (Result Evergreen.V247.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V247.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V247.Discord.HttpError (List ( Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId, Maybe Evergreen.V247.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V247.Slack.CurrentUser
            , team : Evergreen.V247.Slack.Team
            , users : List Evergreen.V247.Slack.User
            , channels : List ( Evergreen.V247.Slack.Channel, List Evergreen.V247.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId) (Result Effect.Http.Error Evergreen.V247.Slack.TokenResponse)
    | GotCloudflareTurnCredentials PendingVoiceChatJoin (Result Effect.Http.Error (List Evergreen.V247.Cloudflare.TurnConfig))
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId) Evergreen.V247.Discord.UserAuth (Result Evergreen.V247.Discord.HttpError Evergreen.V247.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId) (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId) (Result Evergreen.V247.Discord.HttpError Evergreen.V247.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId)
        (Result
            Evergreen.V247.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V247.Discord.Id Evergreen.V247.Discord.PrivateChannelId
                , members : List (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId)
                }
            , List
                ( Evergreen.V247.Discord.Id Evergreen.V247.Discord.GuildId
                , { guild : Evergreen.V247.Discord.GatewayGuild
                  , channels : List Evergreen.V247.Discord.Channel
                  , icon : Maybe Evergreen.V247.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId) Bool Evergreen.V247.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V247.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V247.Discord.Id Evergreen.V247.Discord.AttachmentId, Evergreen.V247.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V247.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V247.Discord.Id Evergreen.V247.Discord.AttachmentId, Evergreen.V247.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId) (Evergreen.V247.Discord.Id Evergreen.V247.Discord.GuildId) (Evergreen.V247.Discord.Id Evergreen.V247.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V247.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V247.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId) (Evergreen.V247.Discord.Id Evergreen.V247.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V247.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V247.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId) (Evergreen.V247.Discord.Id Evergreen.V247.Discord.GuildId) (Evergreen.V247.Discord.Id Evergreen.V247.Discord.ChannelId) (Result Evergreen.V247.Discord.HttpError (List Evergreen.V247.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId) (Evergreen.V247.Discord.Id Evergreen.V247.Discord.PrivateChannelId) (Result Evergreen.V247.Discord.HttpError (List Evergreen.V247.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V247.Id.Id Evergreen.V247.Id.GuildId) (Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelId) Evergreen.V247.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V247.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V247.DmChannel.DmChannelId Evergreen.V247.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V247.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V247.Discord.Id Evergreen.V247.Discord.GuildId) (Evergreen.V247.Discord.Id Evergreen.V247.Discord.ChannelId) Evergreen.V247.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V247.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V247.Discord.Id Evergreen.V247.Discord.PrivateChannelId) (Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V247.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId)
        (Evergreen.V247.Discord.Id Evergreen.V247.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V247.Discord.HttpError
            { guild : Evergreen.V247.Discord.GatewayGuild
            , channels : List Evergreen.V247.Discord.Channel
            , icon : Maybe Evergreen.V247.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V247.Discord.Id Evergreen.V247.Discord.GuildId) (Result Evergreen.V247.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V247.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId) (List ( Evergreen.V247.Id.Id Evergreen.V247.Id.StickerId, Result Effect.Http.Error Evergreen.V247.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V247.Id.Id Evergreen.V247.Id.StickerId, Result Effect.Http.Error Evergreen.V247.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId) (List ( Evergreen.V247.Id.Id Evergreen.V247.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V247.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V247.Id.Id Evergreen.V247.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V247.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V247.Discord.HttpError (List Evergreen.V247.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V247.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V247.SecretId.SecretId Evergreen.V247.SecretId.ServerSecret))
    | GotTimeForWebsocketListenClose (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId) String Effect.Time.Posix
