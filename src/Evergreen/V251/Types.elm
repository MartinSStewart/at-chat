module Evergreen.V251.Types exposing (..)

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
import Evergreen.V251.AiChat
import Evergreen.V251.Call
import Evergreen.V251.ChannelDescription
import Evergreen.V251.ChannelName
import Evergreen.V251.Cloudflare
import Evergreen.V251.Coord
import Evergreen.V251.CssPixels
import Evergreen.V251.CustomEmoji
import Evergreen.V251.Discord
import Evergreen.V251.DiscordAttachmentId
import Evergreen.V251.DiscordUserData
import Evergreen.V251.DmChannel
import Evergreen.V251.Editable
import Evergreen.V251.EmailAddress
import Evergreen.V251.Embed
import Evergreen.V251.Emoji
import Evergreen.V251.FileStatus
import Evergreen.V251.Go
import Evergreen.V251.GuildName
import Evergreen.V251.Id
import Evergreen.V251.ImageEditor
import Evergreen.V251.Local
import Evergreen.V251.LocalState
import Evergreen.V251.Log
import Evergreen.V251.LoginForm
import Evergreen.V251.MembersAndOwner
import Evergreen.V251.Message
import Evergreen.V251.MessageInput
import Evergreen.V251.MessageView
import Evergreen.V251.MyUi
import Evergreen.V251.NonemptyDict
import Evergreen.V251.NonemptySet
import Evergreen.V251.OneToOne
import Evergreen.V251.Pages.Admin
import Evergreen.V251.Pagination
import Evergreen.V251.PersonName
import Evergreen.V251.Ports
import Evergreen.V251.Postmark
import Evergreen.V251.Range
import Evergreen.V251.RichText
import Evergreen.V251.Route
import Evergreen.V251.SecretId
import Evergreen.V251.SessionIdHash
import Evergreen.V251.Slack
import Evergreen.V251.Sticker
import Evergreen.V251.TextEditor
import Evergreen.V251.ToBackendLog
import Evergreen.V251.Touch
import Evergreen.V251.TwoFactorAuthentication
import Evergreen.V251.Ui.Anim
import Evergreen.V251.Untrusted
import Evergreen.V251.User
import Evergreen.V251.UserAgent
import Evergreen.V251.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V251.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V251.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.Id.GuildId) Evergreen.V251.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId) Evergreen.V251.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V251.Discord.Id Evergreen.V251.Discord.PrivateChannelId) Evergreen.V251.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V251.Discord.Id Evergreen.V251.Discord.GuildId) Evergreen.V251.LocalState.DiscordFrontendGuild
    , user : Evergreen.V251.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId) Evergreen.V251.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId) Evergreen.V251.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId) Evergreen.V251.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V251.SessionIdHash.SessionIdHash Evergreen.V251.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V251.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.Id.StickerId) Evergreen.V251.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.Id.CustomEmojiId) Evergreen.V251.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V251.Call.RoomId (Evergreen.V251.NonemptySet.NonemptySet ( Evergreen.V251.Id.Id Evergreen.V251.Id.UserId, Effect.Lamdera.ClientId ))
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type PublicGoMatch
    = PublicGoMatch_NotLoaded
    | PublicGoMatch_Loading
    | PublicGoMatch_Loaded Evergreen.V251.Go.PublicGoMatchData Evergreen.V251.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V251.Route.Route
    , windowSize : Evergreen.V251.Coord.Coord Evergreen.V251.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V251.Ports.NotificationPermission
    , pwaStatus : Evergreen.V251.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V251.UserAgent.UserAgent
    , publicGoMatch : PublicGoMatch
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V251.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V251.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V251.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.FileStatus.FileId) Evergreen.V251.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V251.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V251.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.FileStatus.FileId) Evergreen.V251.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V251.Id.Id Evergreen.V251.Id.GuildId) Evergreen.V251.ChannelName.ChannelName Evergreen.V251.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V251.Id.Id Evergreen.V251.Id.GuildId) (Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelId) Evergreen.V251.ChannelName.ChannelName Evergreen.V251.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V251.Id.Id Evergreen.V251.Id.GuildId) (Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelId)
    | Local_DeleteGuild (Evergreen.V251.Id.Id Evergreen.V251.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V251.Id.Id Evergreen.V251.Id.GuildId) (Evergreen.V251.UserSession.ToBeFilledInByBackend (Evergreen.V251.SecretId.SecretId Evergreen.V251.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V251.Id.Id Evergreen.V251.Id.GuildId) (Evergreen.V251.SecretId.SecretId Evergreen.V251.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V251.GuildName.GuildName (Evergreen.V251.UserSession.ToBeFilledInByBackend (Evergreen.V251.Id.Id Evergreen.V251.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V251.Id.AnyGuildOrDmId, Evergreen.V251.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V251.Id.AnyGuildOrDmId Evergreen.V251.Id.ThreadRouteWithMessage Evergreen.V251.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V251.Id.AnyGuildOrDmId Evergreen.V251.Id.ThreadRouteWithMessage Evergreen.V251.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V251.Id.GuildOrDmId Evergreen.V251.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.FileStatus.FileId) Evergreen.V251.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId) (Evergreen.V251.Discord.Id Evergreen.V251.Discord.GuildId) (Evergreen.V251.Discord.Id Evergreen.V251.Discord.ChannelId) Evergreen.V251.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V251.Id.DiscordGuildOrDmId_DmData (Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V251.Id.AnyGuildOrDmId Evergreen.V251.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V251.Id.AnyGuildOrDmId Evergreen.V251.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V251.Id.AnyGuildOrDmId Evergreen.V251.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V251.UserSession.SetViewing
    | Local_SetName Evergreen.V251.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V251.Id.GuildOrDmId (Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelMessageId) (Evergreen.V251.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelMessageId) (Evergreen.V251.Message.Message Evergreen.V251.Id.ChannelMessageId (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V251.Id.GuildOrDmId (Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelMessageId) (Evergreen.V251.Id.Id Evergreen.V251.Id.ThreadMessageId) (Evergreen.V251.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.Id.ThreadMessageId) (Evergreen.V251.Message.Message Evergreen.V251.Id.ThreadMessageId (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V251.Id.DiscordGuildOrDmId (Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelMessageId) (Evergreen.V251.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelMessageId) (Evergreen.V251.Message.Message Evergreen.V251.Id.ChannelMessageId (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V251.Id.DiscordGuildOrDmId (Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelMessageId) (Evergreen.V251.Id.Id Evergreen.V251.Id.ThreadMessageId) (Evergreen.V251.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.Id.ThreadMessageId) (Evergreen.V251.Message.Message Evergreen.V251.Id.ThreadMessageId (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V251.Id.Id Evergreen.V251.Id.GuildId) Evergreen.V251.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId) (Evergreen.V251.Discord.Id Evergreen.V251.Discord.GuildId) Evergreen.V251.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V251.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V251.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V251.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V251.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V251.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V251.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V251.NonemptySet.NonemptySet (Evergreen.V251.Id.Id Evergreen.V251.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V251.Call.LocalChange
    | Local_Go
        { otherUserId : Evergreen.V251.Id.Id Evergreen.V251.Id.UserId
        }
        Evergreen.V251.Go.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId) Effect.Time.Posix Evergreen.V251.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V251.RichText.RichText (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId))) Evergreen.V251.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.FileStatus.FileId) Evergreen.V251.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.Id.StickerId) Evergreen.V251.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V251.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V251.RichText.RichText (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId))) Evergreen.V251.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.FileStatus.FileId) Evergreen.V251.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.Id.StickerId) Evergreen.V251.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V251.Id.Id Evergreen.V251.Id.GuildId) Evergreen.V251.ChannelName.ChannelName Evergreen.V251.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V251.Id.Id Evergreen.V251.Id.GuildId) (Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelId) Evergreen.V251.ChannelName.ChannelName Evergreen.V251.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V251.Id.Id Evergreen.V251.Id.GuildId) (Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelId)
    | Server_DeleteGuild (Evergreen.V251.Id.Id Evergreen.V251.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId) (Evergreen.V251.Id.Id Evergreen.V251.Id.GuildId) (Evergreen.V251.SecretId.SecretId Evergreen.V251.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V251.Id.Id Evergreen.V251.Id.GuildId) (Evergreen.V251.SecretId.SecretId Evergreen.V251.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId) (Evergreen.V251.Id.Id Evergreen.V251.Id.GuildId) Evergreen.V251.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V251.LocalState.JoinGuildError
            { guildId : Evergreen.V251.Id.Id Evergreen.V251.Id.GuildId
            , guild : Evergreen.V251.LocalState.FrontendGuild
            , owner : Evergreen.V251.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId) Evergreen.V251.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId) Evergreen.V251.Id.GuildOrDmId Evergreen.V251.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId) (Evergreen.V251.Discord.Id Evergreen.V251.Discord.GuildId) (Evergreen.V251.Discord.Id Evergreen.V251.Discord.ChannelId) Evergreen.V251.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId) (Evergreen.V251.Discord.Id Evergreen.V251.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId) Evergreen.V251.Id.GuildOrDmId Evergreen.V251.Id.ThreadRouteWithMessage Evergreen.V251.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId) Evergreen.V251.Id.GuildOrDmId Evergreen.V251.Id.ThreadRouteWithMessage Evergreen.V251.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId) (Evergreen.V251.Discord.Id Evergreen.V251.Discord.GuildId) (Evergreen.V251.Discord.Id Evergreen.V251.Discord.ChannelId) Evergreen.V251.Id.ThreadRouteWithMessage Evergreen.V251.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId) (Evergreen.V251.Discord.Id Evergreen.V251.Discord.PrivateChannelId) (Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelMessageId) Evergreen.V251.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId) (Evergreen.V251.Discord.Id Evergreen.V251.Discord.GuildId) (Evergreen.V251.Discord.Id Evergreen.V251.Discord.ChannelId) Evergreen.V251.Id.ThreadRouteWithMessage Evergreen.V251.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId) (Evergreen.V251.Discord.Id Evergreen.V251.Discord.PrivateChannelId) (Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelMessageId) Evergreen.V251.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId) Evergreen.V251.Id.GuildOrDmId Evergreen.V251.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V251.RichText.RichText (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId))) (SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.FileStatus.FileId) Evergreen.V251.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId) (Evergreen.V251.Discord.Id Evergreen.V251.Discord.GuildId) (Evergreen.V251.Discord.Id Evergreen.V251.Discord.ChannelId) Evergreen.V251.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V251.RichText.RichText (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V251.Id.DiscordGuildOrDmId_DmData (Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V251.RichText.RichText (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId) Evergreen.V251.Id.AnyGuildOrDmId Evergreen.V251.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V251.Id.AnyGuildOrDmId Evergreen.V251.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V251.Discord.Id Evergreen.V251.Discord.GuildId) (Evergreen.V251.Discord.Id Evergreen.V251.Discord.ChannelId) Evergreen.V251.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V251.Discord.Id Evergreen.V251.Discord.PrivateChannelId) (Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId) Evergreen.V251.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId) Evergreen.V251.FileStatus.FileHash
    | Server_SetGuildIcon (Evergreen.V251.Id.Id Evergreen.V251.Id.GuildId) Evergreen.V251.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V251.Id.Id Evergreen.V251.Id.GuildId) Evergreen.V251.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V251.Discord.Id Evergreen.V251.Discord.GuildId) Evergreen.V251.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V251.SessionIdHash.SessionIdHash Evergreen.V251.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V251.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V251.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V251.Id.AnyGuildOrDmId, Evergreen.V251.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V251.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId) Evergreen.V251.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V251.Discord.Id Evergreen.V251.Discord.GuildId) (Evergreen.V251.Discord.Id Evergreen.V251.Discord.ChannelId) Evergreen.V251.ChannelName.ChannelName (Evergreen.V251.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V251.Discord.Id Evergreen.V251.Discord.PrivateChannelId)
        (Evergreen.V251.NonemptyDict.NonemptyDict
            (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V251.Discord.Id Evergreen.V251.Discord.GuildId) Evergreen.V251.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V251.Discord.Id Evergreen.V251.Discord.PrivateChannelId) Evergreen.V251.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId) Evergreen.V251.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId) (Maybe (Evergreen.V251.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V251.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V251.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V251.Id.Id Evergreen.V251.Id.GuildId) (Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelId) Evergreen.V251.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V251.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId) Evergreen.V251.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V251.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V251.Discord.Id Evergreen.V251.Discord.GuildId) (Evergreen.V251.Discord.Id Evergreen.V251.Discord.ChannelId) Evergreen.V251.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V251.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V251.Discord.Id Evergreen.V251.Discord.PrivateChannelId) (Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V251.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V251.Discord.Id Evergreen.V251.Discord.GuildId) Evergreen.V251.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V251.Discord.Id Evergreen.V251.Discord.GuildId) (Evergreen.V251.Discord.Id Evergreen.V251.Discord.ChannelId) (Evergreen.V251.Discord.OptionalData String) (Evergreen.V251.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V251.Discord.Id Evergreen.V251.Discord.GuildId)
        (Evergreen.V251.MembersAndOwner.MembersAndOwner
            (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V251.Discord.Id Evergreen.V251.Discord.GuildId) (Evergreen.V251.Discord.Id Evergreen.V251.Discord.ChannelId) (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId) Evergreen.V251.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.Id.StickerId) Evergreen.V251.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.Id.CustomEmojiId) Evergreen.V251.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V251.Call.ServerChange
    | Server_Go
        (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId)
        { otherUserId : Evergreen.V251.Id.Id Evergreen.V251.Id.UserId
        }
        Evergreen.V251.Go.LocalChange


type LocalMsg
    = LocalChange (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V251.Id.Id Evergreen.V251.Id.GuildId) (Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelId) Evergreen.V251.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V251.Discord.Id Evergreen.V251.Discord.GuildId) (Evergreen.V251.Discord.Id Evergreen.V251.Discord.ChannelId) Evergreen.V251.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.FileStatus.FileId) Evergreen.V251.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V251.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V251.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V251.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V251.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V251.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V251.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V251.Coord.Coord Evergreen.V251.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V251.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V251.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V251.Id.AnyGuildOrDmId Evergreen.V251.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V251.Id.AnyGuildOrDmId Evergreen.V251.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V251.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V251.Coord.Coord Evergreen.V251.CssPixels.CssPixels) (Maybe Evergreen.V251.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V251.Id.AnyGuildOrDmId, Evergreen.V251.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelMessageId) (Evergreen.V251.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.Id.ThreadMessageId) (Evergreen.V251.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V251.Editable.Model
    , showLinkDiscordSetup : Bool
    , domainWhitelistInput : String
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V251.Local.Local LocalMsg Evergreen.V251.LocalState.LocalState
    , admin : Evergreen.V251.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V251.Id.AnyGuildOrDmId, Evergreen.V251.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V251.Id.Id Evergreen.V251.Id.GuildId, Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V251.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V251.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V251.Id.AnyGuildOrDmId, Evergreen.V251.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V251.Id.AnyGuildOrDmId, Evergreen.V251.Id.ThreadRoute ) (Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : Evergreen.V251.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V251.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V251.Id.AnyGuildOrDmId, Evergreen.V251.Id.ThreadRoute ) (Evergreen.V251.NonemptyDict.NonemptyDict (Evergreen.V251.Id.Id Evergreen.V251.FileStatus.FileId) Evergreen.V251.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V251.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V251.TextEditor.Model
    , profilePictureEditor : Evergreen.V251.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V251.Id.Id Evergreen.V251.Id.GuildId, Evergreen.V251.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V251.Emoji.Model
    , voiceChat : Evergreen.V251.Call.Model
    , currentDmGoMatch : SeqDict.SeqDict ( Evergreen.V251.Id.Id Evergreen.V251.Id.UserId, Maybe (Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelMessageId) ) Evergreen.V251.Go.Model
    , fileDragOverCount : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V251.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V251.SecretId.SecretId Evergreen.V251.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V251.Range.Range
                , direction : Evergreen.V251.Range.SelectionDirection
                }
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V251.NonemptyDict.NonemptyDict Int Evergreen.V251.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V251.NonemptyDict.NonemptyDict Int Evergreen.V251.Touch.Touch
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
    | AdminToFrontend Evergreen.V251.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V251.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V251.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V251.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V251.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V251.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V251.Go.PublicGoMatchData)


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V251.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V251.Coord.Coord Evergreen.V251.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V251.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V251.MyUi.LastCopy
    , notificationPermission : Evergreen.V251.Ports.NotificationPermission
    , pwaStatus : Evergreen.V251.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V251.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V251.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V251.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V251.Id.Id Evergreen.V251.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V251.Id.Id Evergreen.V251.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V251.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V251.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V251.Coord.Coord Evergreen.V251.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V251.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V251.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V251.Id.Id Evergreen.V251.Id.GuildId, Evergreen.V251.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V251.DmChannel.DmChannelId, Evergreen.V251.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V251.Discord.Id Evergreen.V251.Discord.GuildId, Evergreen.V251.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V251.Discord.Id Evergreen.V251.Discord.PrivateChannelId, Evergreen.V251.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V251.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V251.NonemptyDict.NonemptyDict (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId) Evergreen.V251.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V251.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V251.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V251.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V251.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId) Evergreen.V251.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId) Evergreen.V251.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V251.Id.Id Evergreen.V251.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.Id.GuildId) Evergreen.V251.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.Id.GuildId) Evergreen.V251.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V251.Discord.Id Evergreen.V251.Discord.GuildId) Evergreen.V251.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V251.DmChannel.DmChannelId Evergreen.V251.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V251.Discord.Id Evergreen.V251.Discord.PrivateChannelId) Evergreen.V251.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V251.OneToOne.OneToOne (Evergreen.V251.Slack.Id Evergreen.V251.Slack.ChannelId) Evergreen.V251.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V251.OneToOne.OneToOne String (Evergreen.V251.Id.Id Evergreen.V251.Id.GuildId)
    , slackUsers : Evergreen.V251.OneToOne.OneToOne (Evergreen.V251.Slack.Id Evergreen.V251.Slack.UserId) (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId)
    , slackServers : Evergreen.V251.OneToOne.OneToOne (Evergreen.V251.Slack.Id Evergreen.V251.Slack.TeamId) (Evergreen.V251.Id.Id Evergreen.V251.Id.GuildId)
    , slackToken : Maybe Evergreen.V251.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V251.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V251.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V251.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V251.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V251.Cloudflare.AppId
    , textEditor : Evergreen.V251.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId) Evergreen.V251.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId, Evergreen.V251.Discord.Id Evergreen.V251.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V251.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V251.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V251.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V251.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId) (Evergreen.V251.LocalState.LoadingDiscordChannel (List Evergreen.V251.Discord.Message))
    , signupsEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V251.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.Id.StickerId) Evergreen.V251.Sticker.StickerData
    , discordStickers : Evergreen.V251.OneToOne.OneToOne (Evergreen.V251.Discord.Id Evergreen.V251.Discord.StickerId) (Evergreen.V251.Id.Id Evergreen.V251.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.Id.CustomEmojiId) Evergreen.V251.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V251.OneToOne.OneToOne Evergreen.V251.RichText.DiscordCustomEmojiIdAndName (Evergreen.V251.Id.Id Evergreen.V251.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V251.Postmark.ApiKey
    , serverSecret : Evergreen.V251.SecretId.SecretId Evergreen.V251.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V251.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V251.OneToOne.OneToOne (Evergreen.V251.SecretId.SecretId Evergreen.V251.Id.GoMatchPublicId) ( Evergreen.V251.DmChannel.DmChannelId, Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelMessageId )
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V251.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V251.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V251.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V251.Route.Route
    | SelectedFilesToAttach ( Evergreen.V251.Id.AnyGuildOrDmId, Evergreen.V251.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V251.Id.Id Evergreen.V251.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V251.Id.Id Evergreen.V251.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V251.Id.Id Evergreen.V251.Id.GuildId) (Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelId) Evergreen.V251.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V251.Id.Id Evergreen.V251.Id.GuildId) (Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelId) Evergreen.V251.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V251.Discord.Id Evergreen.V251.Discord.GuildId) (Evergreen.V251.Discord.Id Evergreen.V251.Discord.ChannelId) Evergreen.V251.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V251.Discord.Id Evergreen.V251.Discord.GuildId) (Evergreen.V251.Discord.Id Evergreen.V251.Discord.ChannelId) Evergreen.V251.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V251.Id.Id Evergreen.V251.Id.GuildId) (Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V251.Id.Id Evergreen.V251.Id.GuildId) (Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V251.Id.Id Evergreen.V251.Id.GuildId) (Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V251.Id.Id Evergreen.V251.Id.GuildId) (Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V251.Id.Id Evergreen.V251.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V251.Id.Id Evergreen.V251.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V251.Id.Id Evergreen.V251.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V251.Id.Id Evergreen.V251.Id.GuildId) (Evergreen.V251.SecretId.SecretId Evergreen.V251.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V251.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V251.Id.AnyGuildOrDmId Evergreen.V251.Id.ThreadRouteWithMessage (Evergreen.V251.Coord.Coord Evergreen.V251.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V251.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V251.Id.AnyGuildOrDmId Evergreen.V251.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V251.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V251.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V251.Id.AnyGuildOrDmId, Evergreen.V251.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V251.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V251.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V251.Id.AnyGuildOrDmId, Evergreen.V251.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V251.NonemptyDict.NonemptyDict Int Evergreen.V251.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V251.NonemptyDict.NonemptyDict Int Evergreen.V251.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V251.Id.AnyGuildOrDmId Evergreen.V251.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V251.Id.AnyGuildOrDmId Evergreen.V251.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V251.NonemptySet.NonemptySet (Evergreen.V251.Id.Id Evergreen.V251.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V251.Id.AnyGuildOrDmId, Evergreen.V251.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V251.Id.AnyGuildOrDmId Evergreen.V251.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V251.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V251.AiChat.Msg
    | GoMsg Evergreen.V251.Go.Msg
    | GoSpectatorMsg Evergreen.V251.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V251.Editable.Msg Evergreen.V251.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V251.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V251.Id.Id Evergreen.V251.Id.GuildId) Evergreen.V251.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V251.Id.AnyGuildOrDmId, Evergreen.V251.Id.ThreadRoute ) (Evergreen.V251.Id.Id Evergreen.V251.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V251.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V251.Id.AnyGuildOrDmId, Evergreen.V251.Id.ThreadRoute ) (Evergreen.V251.Id.Id Evergreen.V251.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V251.Id.AnyGuildOrDmId, Evergreen.V251.Id.ThreadRoute ) (Evergreen.V251.Id.Id Evergreen.V251.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V251.Id.AnyGuildOrDmId, Evergreen.V251.Id.ThreadRoute )
        { fileId : Evergreen.V251.Id.Id Evergreen.V251.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V251.Id.AnyGuildOrDmId, Evergreen.V251.Id.ThreadRoute ) (Evergreen.V251.Id.Id Evergreen.V251.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V251.Id.AnyGuildOrDmId, Evergreen.V251.Id.ThreadRoute ) (Evergreen.V251.Id.Id Evergreen.V251.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V251.Id.AnyGuildOrDmId, Evergreen.V251.Id.ThreadRoute )
        { fileId : Evergreen.V251.Id.Id Evergreen.V251.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V251.Id.AnyGuildOrDmId, Evergreen.V251.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V251.Id.AnyGuildOrDmId, Evergreen.V251.Id.ThreadRoute ) (Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelMessageId) (Evergreen.V251.Id.Id Evergreen.V251.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V251.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V251.Id.AnyGuildOrDmId, Evergreen.V251.Id.ThreadRoute ) (Evergreen.V251.Id.Id Evergreen.V251.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V251.Id.AnyGuildOrDmId Evergreen.V251.Id.ThreadRouteWithMessage Evergreen.V251.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V251.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V251.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V251.Id.Id Evergreen.V251.Id.GuildId) Evergreen.V251.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId) (Evergreen.V251.Discord.Id Evergreen.V251.Discord.GuildId) Evergreen.V251.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V251.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V251.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId
        , otherUserId : Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V251.Id.AnyGuildOrDmId Evergreen.V251.Id.ThreadRoute Evergreen.V251.MessageInput.Msg
    | MessageInputMsg Evergreen.V251.Id.AnyGuildOrDmId Evergreen.V251.Id.ThreadRoute Evergreen.V251.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V251.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V251.Range.Range, Evergreen.V251.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V251.Range.Range, Evergreen.V251.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V251.Call.FromJs)
    | VoiceChatMsg Evergreen.V251.Call.Msg
    | PressedChannelHeaderTab Evergreen.V251.Route.DmChannelHeaderTab
    | FileDragEnter
    | FileDragLeave
    | FileDropped (List Effect.File.File)


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V251.Id.Id Evergreen.V251.Id.GuildId) (Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelId) Evergreen.V251.Id.ThreadRoute
    | InitialLoadRequested_Dm Evergreen.V251.DmChannel.DmChannelId Evergreen.V251.Id.ThreadRoute
    | InitialLoadRequested_Discord Evergreen.V251.Id.DiscordGuildOrDmId Evergreen.V251.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V251.Id.Id Evergreen.V251.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V251.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V251.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V251.Untrusted.Untrusted Evergreen.V251.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V251.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V251.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V251.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V251.Id.Id Evergreen.V251.Id.GuildId) (Evergreen.V251.SecretId.SecretId Evergreen.V251.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V251.PersonName.PersonName Evergreen.V251.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V251.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V251.Slack.OAuthCode Evergreen.V251.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V251.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V251.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V251.Id.Id Evergreen.V251.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V251.SecretId.SecretId Evergreen.V251.Id.GoMatchPublicId)


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V251.Discord.Id Evergreen.V251.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V251.Discord.Id Evergreen.V251.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V251.EmailAddress.EmailAddress (Result Evergreen.V251.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V251.EmailAddress.EmailAddress (Result Evergreen.V251.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId) Evergreen.V251.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V251.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V251.Discord.Id Evergreen.V251.Discord.GuildId) (Evergreen.V251.Discord.Id Evergreen.V251.Discord.ChannelId) Evergreen.V251.Id.ThreadRouteWithMaybeMessage (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId) (Result Evergreen.V251.Discord.HttpError Evergreen.V251.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V251.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V251.Discord.Id Evergreen.V251.Discord.PrivateChannelId) (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId) (Result Evergreen.V251.Discord.HttpError Evergreen.V251.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V251.Discord.Id Evergreen.V251.Discord.GuildId) (Evergreen.V251.Discord.Id Evergreen.V251.Discord.ChannelId) Evergreen.V251.Id.ThreadRouteWithMessage (Evergreen.V251.Discord.Id Evergreen.V251.Discord.MessageId) (Result Evergreen.V251.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V251.Discord.Id Evergreen.V251.Discord.PrivateChannelId) (Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelMessageId) (Evergreen.V251.Discord.Id Evergreen.V251.Discord.MessageId) (Result Evergreen.V251.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V251.Discord.Id Evergreen.V251.Discord.GuildId) (Evergreen.V251.Discord.Id Evergreen.V251.Discord.ChannelId) Evergreen.V251.Id.ThreadRouteWithMessage (Evergreen.V251.Discord.Id Evergreen.V251.Discord.MessageId) (Result Evergreen.V251.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V251.Discord.Id Evergreen.V251.Discord.PrivateChannelId) (Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelMessageId) (Evergreen.V251.Discord.Id Evergreen.V251.Discord.MessageId) (Result Evergreen.V251.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V251.Discord.Id Evergreen.V251.Discord.GuildId) (Evergreen.V251.Discord.Id Evergreen.V251.Discord.ChannelId) Evergreen.V251.Id.ThreadRouteWithMessage (Evergreen.V251.Discord.Id Evergreen.V251.Discord.MessageId) Evergreen.V251.Emoji.EmojiOrCustomEmoji (Result Evergreen.V251.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V251.Discord.Id Evergreen.V251.Discord.PrivateChannelId) (Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelMessageId) (Evergreen.V251.Discord.Id Evergreen.V251.Discord.MessageId) Evergreen.V251.Emoji.EmojiOrCustomEmoji (Result Evergreen.V251.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V251.Discord.Id Evergreen.V251.Discord.GuildId) (Evergreen.V251.Discord.Id Evergreen.V251.Discord.ChannelId) Evergreen.V251.Id.ThreadRouteWithMessage (Evergreen.V251.Discord.Id Evergreen.V251.Discord.MessageId) Evergreen.V251.Emoji.EmojiOrCustomEmoji (Result Evergreen.V251.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V251.Discord.Id Evergreen.V251.Discord.PrivateChannelId) (Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelMessageId) (Evergreen.V251.Discord.Id Evergreen.V251.Discord.MessageId) Evergreen.V251.Emoji.EmojiOrCustomEmoji (Result Evergreen.V251.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V251.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V251.Discord.HttpError (List ( Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId, Maybe Evergreen.V251.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V251.Slack.CurrentUser
            , team : Evergreen.V251.Slack.Team
            , users : List Evergreen.V251.Slack.User
            , channels : List ( Evergreen.V251.Slack.Channel, List Evergreen.V251.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId) (Result Effect.Http.Error Evergreen.V251.Slack.TokenResponse)
    | GotCloudflareSessionCreated Effect.Lamdera.ClientId Evergreen.V251.Local.ChangeId Effect.Time.Posix Evergreen.V251.Call.RoomId Evergreen.V251.Cloudflare.Sdp (List String) (Result Effect.Http.Error Evergreen.V251.Cloudflare.RealtimeSessionId)
    | GotCloudflareSession Effect.Lamdera.ClientId Evergreen.V251.Local.ChangeId Effect.Time.Posix Evergreen.V251.Call.RoomId Evergreen.V251.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V251.Cloudflare.PushTracksResult)
    | GotCloudflarePullOffer Effect.Time.Posix Effect.Lamdera.ClientId Evergreen.V251.Local.ChangeId Evergreen.V251.Call.ConnectionId Evergreen.V251.Cloudflare.RealtimeSessionId (List Evergreen.V251.Cloudflare.TrackName) (Result Effect.Http.Error Evergreen.V251.Cloudflare.PullTracksResult)
    | GotCloudflareRenegotiateAck Effect.Lamdera.ClientId Evergreen.V251.Local.ChangeId Evergreen.V251.Cloudflare.Sdp (Result Effect.Http.Error ())
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId) Evergreen.V251.Discord.UserAuth (Result Evergreen.V251.Discord.HttpError Evergreen.V251.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId) (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId) (Result Evergreen.V251.Discord.HttpError Evergreen.V251.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId)
        (Result
            Evergreen.V251.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V251.Discord.Id Evergreen.V251.Discord.PrivateChannelId
                , members : List (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId)
                }
            , List
                ( Evergreen.V251.Discord.Id Evergreen.V251.Discord.GuildId
                , { guild : Evergreen.V251.Discord.GatewayGuild
                  , channels : List Evergreen.V251.Discord.Channel
                  , icon : Maybe Evergreen.V251.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId) Bool Evergreen.V251.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V251.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V251.Discord.Id Evergreen.V251.Discord.AttachmentId, Evergreen.V251.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V251.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V251.Discord.Id Evergreen.V251.Discord.AttachmentId, Evergreen.V251.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId) (Evergreen.V251.Discord.Id Evergreen.V251.Discord.GuildId) (Evergreen.V251.Discord.Id Evergreen.V251.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V251.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V251.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId) (Evergreen.V251.Discord.Id Evergreen.V251.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V251.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V251.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId) (Evergreen.V251.Discord.Id Evergreen.V251.Discord.GuildId) (Evergreen.V251.Discord.Id Evergreen.V251.Discord.ChannelId) (Result Evergreen.V251.Discord.HttpError (List Evergreen.V251.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId) (Evergreen.V251.Discord.Id Evergreen.V251.Discord.PrivateChannelId) (Result Evergreen.V251.Discord.HttpError (List Evergreen.V251.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V251.Id.Id Evergreen.V251.Id.GuildId) (Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelId) Evergreen.V251.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V251.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V251.DmChannel.DmChannelId Evergreen.V251.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V251.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V251.Discord.Id Evergreen.V251.Discord.GuildId) (Evergreen.V251.Discord.Id Evergreen.V251.Discord.ChannelId) Evergreen.V251.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V251.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V251.Discord.Id Evergreen.V251.Discord.PrivateChannelId) (Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V251.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId)
        (Evergreen.V251.Discord.Id Evergreen.V251.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V251.Discord.HttpError
            { guild : Evergreen.V251.Discord.GatewayGuild
            , channels : List Evergreen.V251.Discord.Channel
            , icon : Maybe Evergreen.V251.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V251.Discord.Id Evergreen.V251.Discord.GuildId) (Result Evergreen.V251.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V251.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId) (List ( Evergreen.V251.Id.Id Evergreen.V251.Id.StickerId, Result Effect.Http.Error Evergreen.V251.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V251.Id.Id Evergreen.V251.Id.StickerId, Result Effect.Http.Error Evergreen.V251.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId) (List ( Evergreen.V251.Id.Id Evergreen.V251.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V251.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V251.Id.Id Evergreen.V251.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V251.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V251.Discord.HttpError (List Evergreen.V251.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V251.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V251.SecretId.SecretId Evergreen.V251.SecretId.ServerSecret))
    | GotTimeForWebsocketListenClose (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId) String Effect.Time.Posix
