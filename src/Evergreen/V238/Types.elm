module Evergreen.V238.Types exposing (..)

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
import Evergreen.V238.AiChat
import Evergreen.V238.Call
import Evergreen.V238.ChannelDescription
import Evergreen.V238.ChannelName
import Evergreen.V238.Coord
import Evergreen.V238.CssPixels
import Evergreen.V238.CustomEmoji
import Evergreen.V238.Discord
import Evergreen.V238.DiscordAttachmentId
import Evergreen.V238.DiscordUserData
import Evergreen.V238.DmChannel
import Evergreen.V238.Editable
import Evergreen.V238.EmailAddress
import Evergreen.V238.Embed
import Evergreen.V238.Emoji
import Evergreen.V238.FileStatus
import Evergreen.V238.Go
import Evergreen.V238.GuildName
import Evergreen.V238.Id
import Evergreen.V238.ImageEditor
import Evergreen.V238.Local
import Evergreen.V238.LocalState
import Evergreen.V238.Log
import Evergreen.V238.LoginForm
import Evergreen.V238.MembersAndOwner
import Evergreen.V238.Message
import Evergreen.V238.MessageInput
import Evergreen.V238.MessageView
import Evergreen.V238.NonemptyDict
import Evergreen.V238.NonemptySet
import Evergreen.V238.OneToOne
import Evergreen.V238.Pages.Admin
import Evergreen.V238.Pagination
import Evergreen.V238.PersonName
import Evergreen.V238.Ports
import Evergreen.V238.Postmark
import Evergreen.V238.Range
import Evergreen.V238.RichText
import Evergreen.V238.Route
import Evergreen.V238.SecretId
import Evergreen.V238.SessionIdHash
import Evergreen.V238.Slack
import Evergreen.V238.Sticker
import Evergreen.V238.TextEditor
import Evergreen.V238.ToBackendLog
import Evergreen.V238.Touch
import Evergreen.V238.TwoFactorAuthentication
import Evergreen.V238.Ui.Anim
import Evergreen.V238.Untrusted
import Evergreen.V238.User
import Evergreen.V238.UserAgent
import Evergreen.V238.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V238.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V238.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.Id.GuildId) Evergreen.V238.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId) Evergreen.V238.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V238.Discord.Id Evergreen.V238.Discord.PrivateChannelId) Evergreen.V238.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V238.Discord.Id Evergreen.V238.Discord.GuildId) Evergreen.V238.LocalState.DiscordFrontendGuild
    , user : Evergreen.V238.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId) Evergreen.V238.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId) Evergreen.V238.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId) Evergreen.V238.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V238.SessionIdHash.SessionIdHash Evergreen.V238.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V238.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.Id.StickerId) Evergreen.V238.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.Id.CustomEmojiId) Evergreen.V238.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V238.Call.RoomId (Evergreen.V238.NonemptySet.NonemptySet ( Evergreen.V238.Id.Id Evergreen.V238.Id.UserId, Effect.Lamdera.ClientId ))
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V238.Route.Route
    , windowSize : Evergreen.V238.Coord.Coord Evergreen.V238.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V238.Ports.NotificationPermission
    , pwaStatus : Evergreen.V238.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V238.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V238.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V238.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V238.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.FileStatus.FileId) Evergreen.V238.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V238.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V238.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.FileStatus.FileId) Evergreen.V238.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V238.Id.Id Evergreen.V238.Id.GuildId) Evergreen.V238.ChannelName.ChannelName Evergreen.V238.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V238.Id.Id Evergreen.V238.Id.GuildId) (Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelId) Evergreen.V238.ChannelName.ChannelName Evergreen.V238.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V238.Id.Id Evergreen.V238.Id.GuildId) (Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelId)
    | Local_DeleteGuild (Evergreen.V238.Id.Id Evergreen.V238.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V238.Id.Id Evergreen.V238.Id.GuildId) (Evergreen.V238.UserSession.ToBeFilledInByBackend (Evergreen.V238.SecretId.SecretId Evergreen.V238.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V238.GuildName.GuildName (Evergreen.V238.UserSession.ToBeFilledInByBackend (Evergreen.V238.Id.Id Evergreen.V238.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V238.Id.AnyGuildOrDmId, Evergreen.V238.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V238.Id.AnyGuildOrDmId Evergreen.V238.Id.ThreadRouteWithMessage Evergreen.V238.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V238.Id.AnyGuildOrDmId Evergreen.V238.Id.ThreadRouteWithMessage Evergreen.V238.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V238.Id.GuildOrDmId Evergreen.V238.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.FileStatus.FileId) Evergreen.V238.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId) (Evergreen.V238.Discord.Id Evergreen.V238.Discord.GuildId) (Evergreen.V238.Discord.Id Evergreen.V238.Discord.ChannelId) Evergreen.V238.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V238.Id.DiscordGuildOrDmId_DmData (Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V238.Id.AnyGuildOrDmId Evergreen.V238.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V238.Id.AnyGuildOrDmId Evergreen.V238.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V238.Id.AnyGuildOrDmId Evergreen.V238.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V238.UserSession.SetViewing
    | Local_SetName Evergreen.V238.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V238.Id.GuildOrDmId (Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelMessageId) (Evergreen.V238.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelMessageId) (Evergreen.V238.Message.Message Evergreen.V238.Id.ChannelMessageId (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V238.Id.GuildOrDmId (Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelMessageId) (Evergreen.V238.Id.Id Evergreen.V238.Id.ThreadMessageId) (Evergreen.V238.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.Id.ThreadMessageId) (Evergreen.V238.Message.Message Evergreen.V238.Id.ThreadMessageId (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V238.Id.DiscordGuildOrDmId (Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelMessageId) (Evergreen.V238.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelMessageId) (Evergreen.V238.Message.Message Evergreen.V238.Id.ChannelMessageId (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V238.Id.DiscordGuildOrDmId (Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelMessageId) (Evergreen.V238.Id.Id Evergreen.V238.Id.ThreadMessageId) (Evergreen.V238.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.Id.ThreadMessageId) (Evergreen.V238.Message.Message Evergreen.V238.Id.ThreadMessageId (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V238.Id.Id Evergreen.V238.Id.GuildId) Evergreen.V238.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId) (Evergreen.V238.Discord.Id Evergreen.V238.Discord.GuildId) Evergreen.V238.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V238.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V238.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V238.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V238.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V238.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V238.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V238.NonemptySet.NonemptySet (Evergreen.V238.Id.Id Evergreen.V238.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V238.Call.LocalChange
    | Local_Go
        { otherUserId : Evergreen.V238.Id.Id Evergreen.V238.Id.UserId
        }
        Evergreen.V238.Go.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId) Effect.Time.Posix Evergreen.V238.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V238.RichText.RichText (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId))) Evergreen.V238.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.FileStatus.FileId) Evergreen.V238.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.Id.StickerId) Evergreen.V238.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V238.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V238.RichText.RichText (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId))) Evergreen.V238.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.FileStatus.FileId) Evergreen.V238.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.Id.StickerId) Evergreen.V238.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V238.Id.Id Evergreen.V238.Id.GuildId) Evergreen.V238.ChannelName.ChannelName Evergreen.V238.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V238.Id.Id Evergreen.V238.Id.GuildId) (Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelId) Evergreen.V238.ChannelName.ChannelName Evergreen.V238.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V238.Id.Id Evergreen.V238.Id.GuildId) (Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelId)
    | Server_DeleteGuild (Evergreen.V238.Id.Id Evergreen.V238.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId) (Evergreen.V238.Id.Id Evergreen.V238.Id.GuildId) (Evergreen.V238.SecretId.SecretId Evergreen.V238.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId) (Evergreen.V238.Id.Id Evergreen.V238.Id.GuildId) Evergreen.V238.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V238.LocalState.JoinGuildError
            { guildId : Evergreen.V238.Id.Id Evergreen.V238.Id.GuildId
            , guild : Evergreen.V238.LocalState.FrontendGuild
            , owner : Evergreen.V238.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId) Evergreen.V238.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId) Evergreen.V238.Id.GuildOrDmId Evergreen.V238.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId) (Evergreen.V238.Discord.Id Evergreen.V238.Discord.GuildId) (Evergreen.V238.Discord.Id Evergreen.V238.Discord.ChannelId) Evergreen.V238.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId) (Evergreen.V238.Discord.Id Evergreen.V238.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId) Evergreen.V238.Id.GuildOrDmId Evergreen.V238.Id.ThreadRouteWithMessage Evergreen.V238.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId) Evergreen.V238.Id.GuildOrDmId Evergreen.V238.Id.ThreadRouteWithMessage Evergreen.V238.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId) (Evergreen.V238.Discord.Id Evergreen.V238.Discord.GuildId) (Evergreen.V238.Discord.Id Evergreen.V238.Discord.ChannelId) Evergreen.V238.Id.ThreadRouteWithMessage Evergreen.V238.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId) (Evergreen.V238.Discord.Id Evergreen.V238.Discord.PrivateChannelId) (Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelMessageId) Evergreen.V238.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId) (Evergreen.V238.Discord.Id Evergreen.V238.Discord.GuildId) (Evergreen.V238.Discord.Id Evergreen.V238.Discord.ChannelId) Evergreen.V238.Id.ThreadRouteWithMessage Evergreen.V238.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId) (Evergreen.V238.Discord.Id Evergreen.V238.Discord.PrivateChannelId) (Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelMessageId) Evergreen.V238.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId) Evergreen.V238.Id.GuildOrDmId Evergreen.V238.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V238.RichText.RichText (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId))) (SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.FileStatus.FileId) Evergreen.V238.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId) (Evergreen.V238.Discord.Id Evergreen.V238.Discord.GuildId) (Evergreen.V238.Discord.Id Evergreen.V238.Discord.ChannelId) Evergreen.V238.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V238.RichText.RichText (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V238.Id.DiscordGuildOrDmId_DmData (Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V238.RichText.RichText (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId) Evergreen.V238.Id.AnyGuildOrDmId Evergreen.V238.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V238.Id.AnyGuildOrDmId Evergreen.V238.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V238.Discord.Id Evergreen.V238.Discord.GuildId) (Evergreen.V238.Discord.Id Evergreen.V238.Discord.ChannelId) Evergreen.V238.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V238.Discord.Id Evergreen.V238.Discord.PrivateChannelId) (Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId) Evergreen.V238.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId) Evergreen.V238.FileStatus.FileHash
    | Server_SetGuildIcon (Evergreen.V238.Id.Id Evergreen.V238.Id.GuildId) Evergreen.V238.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V238.Id.Id Evergreen.V238.Id.GuildId) Evergreen.V238.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V238.Discord.Id Evergreen.V238.Discord.GuildId) Evergreen.V238.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V238.SessionIdHash.SessionIdHash Evergreen.V238.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V238.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V238.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V238.Id.AnyGuildOrDmId, Evergreen.V238.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V238.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId) Evergreen.V238.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V238.Discord.Id Evergreen.V238.Discord.GuildId) (Evergreen.V238.Discord.Id Evergreen.V238.Discord.ChannelId) Evergreen.V238.ChannelName.ChannelName (Evergreen.V238.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V238.Discord.Id Evergreen.V238.Discord.PrivateChannelId)
        (Evergreen.V238.NonemptyDict.NonemptyDict
            (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V238.Discord.Id Evergreen.V238.Discord.GuildId) Evergreen.V238.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V238.Discord.Id Evergreen.V238.Discord.PrivateChannelId) Evergreen.V238.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId) Evergreen.V238.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId) (Maybe (Evergreen.V238.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V238.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V238.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V238.Id.Id Evergreen.V238.Id.GuildId) (Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelId) Evergreen.V238.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V238.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId) Evergreen.V238.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V238.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V238.Discord.Id Evergreen.V238.Discord.GuildId) (Evergreen.V238.Discord.Id Evergreen.V238.Discord.ChannelId) Evergreen.V238.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V238.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V238.Discord.Id Evergreen.V238.Discord.PrivateChannelId) (Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V238.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V238.Discord.Id Evergreen.V238.Discord.GuildId) Evergreen.V238.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V238.Discord.Id Evergreen.V238.Discord.GuildId) (Evergreen.V238.Discord.Id Evergreen.V238.Discord.ChannelId) (Evergreen.V238.Discord.OptionalData String) (Evergreen.V238.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V238.Discord.Id Evergreen.V238.Discord.GuildId)
        (Evergreen.V238.MembersAndOwner.MembersAndOwner
            (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V238.Discord.Id Evergreen.V238.Discord.GuildId) (Evergreen.V238.Discord.Id Evergreen.V238.Discord.ChannelId) (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId) Evergreen.V238.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.Id.StickerId) Evergreen.V238.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.Id.CustomEmojiId) Evergreen.V238.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V238.Call.ServerChange
    | Server_Go
        (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId)
        { otherUserId : Evergreen.V238.Id.Id Evergreen.V238.Id.UserId
        }
        Evergreen.V238.Go.LocalChange


type LocalMsg
    = LocalChange (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V238.Id.Id Evergreen.V238.Id.GuildId) (Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelId) Evergreen.V238.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V238.Discord.Id Evergreen.V238.Discord.GuildId) (Evergreen.V238.Discord.Id Evergreen.V238.Discord.ChannelId) Evergreen.V238.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.FileStatus.FileId) Evergreen.V238.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V238.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V238.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V238.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V238.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V238.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V238.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V238.Coord.Coord Evergreen.V238.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V238.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V238.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V238.Id.AnyGuildOrDmId Evergreen.V238.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V238.Id.AnyGuildOrDmId Evergreen.V238.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V238.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V238.Coord.Coord Evergreen.V238.CssPixels.CssPixels) (Maybe Evergreen.V238.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V238.Id.AnyGuildOrDmId, Evergreen.V238.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelMessageId) (Evergreen.V238.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.Id.ThreadMessageId) (Evergreen.V238.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V238.Editable.Model
    , showLinkDiscordSetup : Bool
    , domainWhitelistInput : String
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V238.Local.Local LocalMsg Evergreen.V238.LocalState.LocalState
    , admin : Evergreen.V238.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V238.Id.AnyGuildOrDmId, Evergreen.V238.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V238.Id.Id Evergreen.V238.Id.GuildId, Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V238.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V238.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V238.Id.AnyGuildOrDmId, Evergreen.V238.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V238.Id.AnyGuildOrDmId, Evergreen.V238.Id.ThreadRoute ) (Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : Evergreen.V238.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V238.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V238.Id.AnyGuildOrDmId, Evergreen.V238.Id.ThreadRoute ) (Evergreen.V238.NonemptyDict.NonemptyDict (Evergreen.V238.Id.Id Evergreen.V238.FileStatus.FileId) Evergreen.V238.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V238.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V238.TextEditor.Model
    , profilePictureEditor : Evergreen.V238.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V238.Id.Id Evergreen.V238.Id.GuildId, Evergreen.V238.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V238.Emoji.Model
    , voiceChat : Evergreen.V238.Call.Model
    , currentDmGoMatch : SeqDict.SeqDict ( Evergreen.V238.Id.Id Evergreen.V238.Id.UserId, Maybe (Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelMessageId) ) Evergreen.V238.Go.Model
    , fileDragOverCount : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V238.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V238.SecretId.SecretId Evergreen.V238.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V238.Range.Range
                , direction : Evergreen.V238.Range.SelectionDirection
                }
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V238.NonemptyDict.NonemptyDict Int Evergreen.V238.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V238.NonemptyDict.NonemptyDict Int Evergreen.V238.Touch.Touch
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
    | AdminToFrontend Evergreen.V238.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V238.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V238.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V238.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V238.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V238.ImageEditor.ToFrontend


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V238.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V238.Coord.Coord Evergreen.V238.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V238.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , notificationPermission : Evergreen.V238.Ports.NotificationPermission
    , pwaStatus : Evergreen.V238.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V238.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V238.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V238.Emoji.CachedEmojiData
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V238.Id.Id Evergreen.V238.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V238.Id.Id Evergreen.V238.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V238.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V238.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V238.Coord.Coord Evergreen.V238.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V238.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V238.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V238.Id.Id Evergreen.V238.Id.GuildId, Evergreen.V238.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V238.DmChannel.DmChannelId, Evergreen.V238.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V238.Discord.Id Evergreen.V238.Discord.GuildId, Evergreen.V238.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V238.Discord.Id Evergreen.V238.Discord.PrivateChannelId, Evergreen.V238.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V238.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V238.NonemptyDict.NonemptyDict (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId) Evergreen.V238.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V238.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V238.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V238.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V238.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId) Evergreen.V238.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId) Evergreen.V238.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V238.Id.Id Evergreen.V238.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.Id.GuildId) Evergreen.V238.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.Id.GuildId) Evergreen.V238.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V238.Discord.Id Evergreen.V238.Discord.GuildId) Evergreen.V238.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V238.DmChannel.DmChannelId Evergreen.V238.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V238.Discord.Id Evergreen.V238.Discord.PrivateChannelId) Evergreen.V238.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V238.OneToOne.OneToOne (Evergreen.V238.Slack.Id Evergreen.V238.Slack.ChannelId) Evergreen.V238.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V238.OneToOne.OneToOne String (Evergreen.V238.Id.Id Evergreen.V238.Id.GuildId)
    , slackUsers : Evergreen.V238.OneToOne.OneToOne (Evergreen.V238.Slack.Id Evergreen.V238.Slack.UserId) (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId)
    , slackServers : Evergreen.V238.OneToOne.OneToOne (Evergreen.V238.Slack.Id Evergreen.V238.Slack.TeamId) (Evergreen.V238.Id.Id Evergreen.V238.Id.GuildId)
    , slackToken : Maybe Evergreen.V238.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V238.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V238.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V238.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V238.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId) Evergreen.V238.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId, Evergreen.V238.Discord.Id Evergreen.V238.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V238.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V238.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V238.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V238.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId) (Evergreen.V238.LocalState.LoadingDiscordChannel (List Evergreen.V238.Discord.Message))
    , signupsEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V238.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.Id.StickerId) Evergreen.V238.Sticker.StickerData
    , discordStickers : Evergreen.V238.OneToOne.OneToOne (Evergreen.V238.Discord.Id Evergreen.V238.Discord.StickerId) (Evergreen.V238.Id.Id Evergreen.V238.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.Id.CustomEmojiId) Evergreen.V238.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V238.OneToOne.OneToOne Evergreen.V238.RichText.DiscordCustomEmojiIdAndName (Evergreen.V238.Id.Id Evergreen.V238.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V238.Postmark.ApiKey
    , serverSecret : Evergreen.V238.SecretId.SecretId Evergreen.V238.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V238.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V238.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V238.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V238.Route.Route
    | SelectedFilesToAttach ( Evergreen.V238.Id.AnyGuildOrDmId, Evergreen.V238.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V238.Id.Id Evergreen.V238.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V238.Id.Id Evergreen.V238.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V238.Id.Id Evergreen.V238.Id.GuildId) (Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelId) Evergreen.V238.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V238.Id.Id Evergreen.V238.Id.GuildId) (Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelId) Evergreen.V238.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V238.Discord.Id Evergreen.V238.Discord.GuildId) (Evergreen.V238.Discord.Id Evergreen.V238.Discord.ChannelId) Evergreen.V238.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V238.Discord.Id Evergreen.V238.Discord.GuildId) (Evergreen.V238.Discord.Id Evergreen.V238.Discord.ChannelId) Evergreen.V238.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V238.Id.Id Evergreen.V238.Id.GuildId) (Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V238.Id.Id Evergreen.V238.Id.GuildId) (Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V238.Id.Id Evergreen.V238.Id.GuildId) (Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V238.Id.Id Evergreen.V238.Id.GuildId) (Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V238.Id.Id Evergreen.V238.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V238.Id.Id Evergreen.V238.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V238.Id.Id Evergreen.V238.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V238.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V238.Id.AnyGuildOrDmId Evergreen.V238.Id.ThreadRouteWithMessage (Evergreen.V238.Coord.Coord Evergreen.V238.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V238.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V238.Id.AnyGuildOrDmId Evergreen.V238.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V238.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V238.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V238.Id.AnyGuildOrDmId, Evergreen.V238.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V238.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V238.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V238.Id.AnyGuildOrDmId, Evergreen.V238.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V238.NonemptyDict.NonemptyDict Int Evergreen.V238.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V238.NonemptyDict.NonemptyDict Int Evergreen.V238.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V238.Id.AnyGuildOrDmId Evergreen.V238.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V238.Id.AnyGuildOrDmId Evergreen.V238.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V238.NonemptySet.NonemptySet (Evergreen.V238.Id.Id Evergreen.V238.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V238.Id.AnyGuildOrDmId, Evergreen.V238.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V238.Id.AnyGuildOrDmId Evergreen.V238.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V238.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V238.AiChat.Msg
    | GoMsg Evergreen.V238.Go.Msg
    | UserNameEditableMsg (Evergreen.V238.Editable.Msg Evergreen.V238.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V238.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V238.Id.Id Evergreen.V238.Id.GuildId) Evergreen.V238.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V238.Id.AnyGuildOrDmId, Evergreen.V238.Id.ThreadRoute ) (Evergreen.V238.Id.Id Evergreen.V238.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V238.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V238.Id.AnyGuildOrDmId, Evergreen.V238.Id.ThreadRoute ) (Evergreen.V238.Id.Id Evergreen.V238.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V238.Id.AnyGuildOrDmId, Evergreen.V238.Id.ThreadRoute ) (Evergreen.V238.Id.Id Evergreen.V238.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V238.Id.AnyGuildOrDmId, Evergreen.V238.Id.ThreadRoute )
        { fileId : Evergreen.V238.Id.Id Evergreen.V238.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V238.Id.AnyGuildOrDmId, Evergreen.V238.Id.ThreadRoute ) (Evergreen.V238.Id.Id Evergreen.V238.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V238.Id.AnyGuildOrDmId, Evergreen.V238.Id.ThreadRoute ) (Evergreen.V238.Id.Id Evergreen.V238.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V238.Id.AnyGuildOrDmId, Evergreen.V238.Id.ThreadRoute )
        { fileId : Evergreen.V238.Id.Id Evergreen.V238.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V238.Id.AnyGuildOrDmId, Evergreen.V238.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V238.Id.AnyGuildOrDmId, Evergreen.V238.Id.ThreadRoute ) (Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelMessageId) (Evergreen.V238.Id.Id Evergreen.V238.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V238.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V238.Id.AnyGuildOrDmId, Evergreen.V238.Id.ThreadRoute ) (Evergreen.V238.Id.Id Evergreen.V238.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V238.Id.AnyGuildOrDmId Evergreen.V238.Id.ThreadRouteWithMessage Evergreen.V238.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V238.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V238.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V238.Id.Id Evergreen.V238.Id.GuildId) Evergreen.V238.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId) (Evergreen.V238.Discord.Id Evergreen.V238.Discord.GuildId) Evergreen.V238.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V238.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V238.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId
        , otherUserId : Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V238.Id.AnyGuildOrDmId Evergreen.V238.Id.ThreadRoute Evergreen.V238.MessageInput.Msg
    | MessageInputMsg Evergreen.V238.Id.AnyGuildOrDmId Evergreen.V238.Id.ThreadRoute Evergreen.V238.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V238.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V238.Range.Range, Evergreen.V238.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V238.Range.Range, Evergreen.V238.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V238.Call.FromJs)
    | VoiceChatMsg Evergreen.V238.Call.Msg
    | PressedChannelHeaderTab Evergreen.V238.Route.DmChannelHeaderTab
    | FileDragEnter
    | FileDragLeave
    | FileDropped (List Effect.File.File)


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V238.Id.Id Evergreen.V238.Id.GuildId) (Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelId) Evergreen.V238.Id.ThreadRoute
    | InitialLoadRequested_Dm Evergreen.V238.DmChannel.DmChannelId Evergreen.V238.Id.ThreadRoute
    | InitialLoadRequested_Discord Evergreen.V238.Id.DiscordGuildOrDmId Evergreen.V238.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V238.Id.Id Evergreen.V238.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V238.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V238.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V238.Untrusted.Untrusted Evergreen.V238.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V238.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V238.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V238.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V238.Id.Id Evergreen.V238.Id.GuildId) (Evergreen.V238.SecretId.SecretId Evergreen.V238.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V238.PersonName.PersonName Evergreen.V238.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V238.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V238.Slack.OAuthCode Evergreen.V238.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V238.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V238.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V238.Id.Id Evergreen.V238.Pagination.PageId))


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V238.Discord.Id Evergreen.V238.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V238.Discord.Id Evergreen.V238.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V238.EmailAddress.EmailAddress (Result Evergreen.V238.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V238.EmailAddress.EmailAddress (Result Evergreen.V238.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId) Evergreen.V238.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V238.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V238.Discord.Id Evergreen.V238.Discord.GuildId) (Evergreen.V238.Discord.Id Evergreen.V238.Discord.ChannelId) Evergreen.V238.Id.ThreadRouteWithMaybeMessage (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId) (Result Evergreen.V238.Discord.HttpError Evergreen.V238.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V238.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V238.Discord.Id Evergreen.V238.Discord.PrivateChannelId) (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId) (Result Evergreen.V238.Discord.HttpError Evergreen.V238.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V238.Discord.Id Evergreen.V238.Discord.GuildId) (Evergreen.V238.Discord.Id Evergreen.V238.Discord.ChannelId) Evergreen.V238.Id.ThreadRouteWithMessage (Evergreen.V238.Discord.Id Evergreen.V238.Discord.MessageId) (Result Evergreen.V238.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V238.Discord.Id Evergreen.V238.Discord.PrivateChannelId) (Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelMessageId) (Evergreen.V238.Discord.Id Evergreen.V238.Discord.MessageId) (Result Evergreen.V238.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V238.Discord.Id Evergreen.V238.Discord.GuildId) (Evergreen.V238.Discord.Id Evergreen.V238.Discord.ChannelId) Evergreen.V238.Id.ThreadRouteWithMessage (Evergreen.V238.Discord.Id Evergreen.V238.Discord.MessageId) (Result Evergreen.V238.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V238.Discord.Id Evergreen.V238.Discord.PrivateChannelId) (Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelMessageId) (Evergreen.V238.Discord.Id Evergreen.V238.Discord.MessageId) (Result Evergreen.V238.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V238.Discord.Id Evergreen.V238.Discord.GuildId) (Evergreen.V238.Discord.Id Evergreen.V238.Discord.ChannelId) Evergreen.V238.Id.ThreadRouteWithMessage (Evergreen.V238.Discord.Id Evergreen.V238.Discord.MessageId) Evergreen.V238.Emoji.EmojiOrCustomEmoji (Result Evergreen.V238.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V238.Discord.Id Evergreen.V238.Discord.PrivateChannelId) (Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelMessageId) (Evergreen.V238.Discord.Id Evergreen.V238.Discord.MessageId) Evergreen.V238.Emoji.EmojiOrCustomEmoji (Result Evergreen.V238.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V238.Discord.Id Evergreen.V238.Discord.GuildId) (Evergreen.V238.Discord.Id Evergreen.V238.Discord.ChannelId) Evergreen.V238.Id.ThreadRouteWithMessage (Evergreen.V238.Discord.Id Evergreen.V238.Discord.MessageId) Evergreen.V238.Emoji.EmojiOrCustomEmoji (Result Evergreen.V238.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V238.Discord.Id Evergreen.V238.Discord.PrivateChannelId) (Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelMessageId) (Evergreen.V238.Discord.Id Evergreen.V238.Discord.MessageId) Evergreen.V238.Emoji.EmojiOrCustomEmoji (Result Evergreen.V238.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V238.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V238.Discord.HttpError (List ( Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId, Maybe Evergreen.V238.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V238.Slack.CurrentUser
            , team : Evergreen.V238.Slack.Team
            , users : List Evergreen.V238.Slack.User
            , channels : List ( Evergreen.V238.Slack.Channel, List Evergreen.V238.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId) (Result Effect.Http.Error Evergreen.V238.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId) Evergreen.V238.Discord.UserAuth (Result Evergreen.V238.Discord.HttpError Evergreen.V238.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId) (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId) (Result Evergreen.V238.Discord.HttpError Evergreen.V238.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId)
        (Result
            Evergreen.V238.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V238.Discord.Id Evergreen.V238.Discord.PrivateChannelId
                , members : List (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId)
                }
            , List
                ( Evergreen.V238.Discord.Id Evergreen.V238.Discord.GuildId
                , { guild : Evergreen.V238.Discord.GatewayGuild
                  , channels : List Evergreen.V238.Discord.Channel
                  , icon : Maybe Evergreen.V238.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId) Bool
    | WebsocketSentDataForUser (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V238.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V238.Discord.Id Evergreen.V238.Discord.AttachmentId, Evergreen.V238.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V238.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V238.Discord.Id Evergreen.V238.Discord.AttachmentId, Evergreen.V238.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId) (Evergreen.V238.Discord.Id Evergreen.V238.Discord.GuildId) (Evergreen.V238.Discord.Id Evergreen.V238.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V238.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V238.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId) (Evergreen.V238.Discord.Id Evergreen.V238.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V238.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V238.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId) (Evergreen.V238.Discord.Id Evergreen.V238.Discord.GuildId) (Evergreen.V238.Discord.Id Evergreen.V238.Discord.ChannelId) (Result Evergreen.V238.Discord.HttpError (List Evergreen.V238.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId) (Evergreen.V238.Discord.Id Evergreen.V238.Discord.PrivateChannelId) (Result Evergreen.V238.Discord.HttpError (List Evergreen.V238.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V238.Id.Id Evergreen.V238.Id.GuildId) (Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelId) Evergreen.V238.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V238.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V238.DmChannel.DmChannelId Evergreen.V238.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V238.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V238.Discord.Id Evergreen.V238.Discord.GuildId) (Evergreen.V238.Discord.Id Evergreen.V238.Discord.ChannelId) Evergreen.V238.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V238.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V238.Discord.Id Evergreen.V238.Discord.PrivateChannelId) (Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V238.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId)
        (Evergreen.V238.Discord.Id Evergreen.V238.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V238.Discord.HttpError
            { guild : Evergreen.V238.Discord.GatewayGuild
            , channels : List Evergreen.V238.Discord.Channel
            , icon : Maybe Evergreen.V238.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V238.Discord.Id Evergreen.V238.Discord.GuildId) (Result Evergreen.V238.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V238.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId) (List ( Evergreen.V238.Id.Id Evergreen.V238.Id.StickerId, Result Effect.Http.Error Evergreen.V238.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V238.Id.Id Evergreen.V238.Id.StickerId, Result Effect.Http.Error Evergreen.V238.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId) (List ( Evergreen.V238.Id.Id Evergreen.V238.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V238.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V238.Id.Id Evergreen.V238.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V238.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V238.Discord.HttpError (List Evergreen.V238.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V238.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V238.SecretId.SecretId Evergreen.V238.SecretId.ServerSecret))
