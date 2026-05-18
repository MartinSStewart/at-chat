module Evergreen.V232.Types exposing (..)

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
import Evergreen.V232.AiChat
import Evergreen.V232.Call
import Evergreen.V232.ChannelDescription
import Evergreen.V232.ChannelName
import Evergreen.V232.Coord
import Evergreen.V232.CssPixels
import Evergreen.V232.CustomEmoji
import Evergreen.V232.Discord
import Evergreen.V232.DiscordAttachmentId
import Evergreen.V232.DiscordUserData
import Evergreen.V232.DmChannel
import Evergreen.V232.Editable
import Evergreen.V232.EmailAddress
import Evergreen.V232.Embed
import Evergreen.V232.Emoji
import Evergreen.V232.FileStatus
import Evergreen.V232.Go
import Evergreen.V232.GuildName
import Evergreen.V232.Id
import Evergreen.V232.ImageEditor
import Evergreen.V232.Local
import Evergreen.V232.LocalState
import Evergreen.V232.Log
import Evergreen.V232.LoginForm
import Evergreen.V232.MembersAndOwner
import Evergreen.V232.Message
import Evergreen.V232.MessageInput
import Evergreen.V232.MessageView
import Evergreen.V232.NonemptyDict
import Evergreen.V232.NonemptySet
import Evergreen.V232.OneToOne
import Evergreen.V232.Pages.Admin
import Evergreen.V232.Pagination
import Evergreen.V232.PersonName
import Evergreen.V232.Ports
import Evergreen.V232.Postmark
import Evergreen.V232.Range
import Evergreen.V232.RichText
import Evergreen.V232.Route
import Evergreen.V232.SecretId
import Evergreen.V232.SessionIdHash
import Evergreen.V232.Slack
import Evergreen.V232.Sticker
import Evergreen.V232.TextEditor
import Evergreen.V232.ToBackendLog
import Evergreen.V232.Touch
import Evergreen.V232.TwoFactorAuthentication
import Evergreen.V232.Ui.Anim
import Evergreen.V232.Untrusted
import Evergreen.V232.User
import Evergreen.V232.UserAgent
import Evergreen.V232.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V232.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V232.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.Id.GuildId) Evergreen.V232.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId) Evergreen.V232.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V232.Discord.Id Evergreen.V232.Discord.PrivateChannelId) Evergreen.V232.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V232.Discord.Id Evergreen.V232.Discord.GuildId) Evergreen.V232.LocalState.DiscordFrontendGuild
    , user : Evergreen.V232.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId) Evergreen.V232.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId) Evergreen.V232.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId) Evergreen.V232.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V232.SessionIdHash.SessionIdHash Evergreen.V232.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V232.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.Id.StickerId) Evergreen.V232.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.Id.CustomEmojiId) Evergreen.V232.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V232.Call.RoomId (Evergreen.V232.NonemptySet.NonemptySet ( Evergreen.V232.Id.Id Evergreen.V232.Id.UserId, Effect.Lamdera.ClientId ))
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V232.Route.Route
    , windowSize : Evergreen.V232.Coord.Coord Evergreen.V232.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V232.Ports.NotificationPermission
    , pwaStatus : Evergreen.V232.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V232.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V232.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V232.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V232.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.FileStatus.FileId) Evergreen.V232.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V232.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V232.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.FileStatus.FileId) Evergreen.V232.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V232.Id.Id Evergreen.V232.Id.GuildId) Evergreen.V232.ChannelName.ChannelName Evergreen.V232.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V232.Id.Id Evergreen.V232.Id.GuildId) (Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelId) Evergreen.V232.ChannelName.ChannelName Evergreen.V232.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V232.Id.Id Evergreen.V232.Id.GuildId) (Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V232.Id.Id Evergreen.V232.Id.GuildId) (Evergreen.V232.UserSession.ToBeFilledInByBackend (Evergreen.V232.SecretId.SecretId Evergreen.V232.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V232.GuildName.GuildName (Evergreen.V232.UserSession.ToBeFilledInByBackend (Evergreen.V232.Id.Id Evergreen.V232.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V232.Id.AnyGuildOrDmId, Evergreen.V232.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V232.Id.AnyGuildOrDmId Evergreen.V232.Id.ThreadRouteWithMessage Evergreen.V232.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V232.Id.AnyGuildOrDmId Evergreen.V232.Id.ThreadRouteWithMessage Evergreen.V232.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V232.Id.GuildOrDmId Evergreen.V232.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.FileStatus.FileId) Evergreen.V232.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId) (Evergreen.V232.Discord.Id Evergreen.V232.Discord.GuildId) (Evergreen.V232.Discord.Id Evergreen.V232.Discord.ChannelId) Evergreen.V232.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V232.Id.DiscordGuildOrDmId_DmData (Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V232.Id.AnyGuildOrDmId Evergreen.V232.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V232.Id.AnyGuildOrDmId Evergreen.V232.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V232.Id.AnyGuildOrDmId Evergreen.V232.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V232.UserSession.SetViewing
    | Local_SetName Evergreen.V232.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V232.Id.GuildOrDmId (Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelMessageId) (Evergreen.V232.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelMessageId) (Evergreen.V232.Message.Message Evergreen.V232.Id.ChannelMessageId (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V232.Id.GuildOrDmId (Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelMessageId) (Evergreen.V232.Id.Id Evergreen.V232.Id.ThreadMessageId) (Evergreen.V232.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.Id.ThreadMessageId) (Evergreen.V232.Message.Message Evergreen.V232.Id.ThreadMessageId (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V232.Id.DiscordGuildOrDmId (Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelMessageId) (Evergreen.V232.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelMessageId) (Evergreen.V232.Message.Message Evergreen.V232.Id.ChannelMessageId (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V232.Id.DiscordGuildOrDmId (Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelMessageId) (Evergreen.V232.Id.Id Evergreen.V232.Id.ThreadMessageId) (Evergreen.V232.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.Id.ThreadMessageId) (Evergreen.V232.Message.Message Evergreen.V232.Id.ThreadMessageId (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V232.Id.Id Evergreen.V232.Id.GuildId) Evergreen.V232.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId) (Evergreen.V232.Discord.Id Evergreen.V232.Discord.GuildId) Evergreen.V232.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V232.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V232.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V232.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V232.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V232.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V232.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V232.NonemptySet.NonemptySet (Evergreen.V232.Id.Id Evergreen.V232.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V232.Call.LocalChange
    | Local_Go
        { otherUserId : Evergreen.V232.Id.Id Evergreen.V232.Id.UserId
        }
        Evergreen.V232.Go.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId) Effect.Time.Posix Evergreen.V232.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V232.RichText.RichText (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId))) Evergreen.V232.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.FileStatus.FileId) Evergreen.V232.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.Id.StickerId) Evergreen.V232.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V232.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V232.RichText.RichText (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId))) Evergreen.V232.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.FileStatus.FileId) Evergreen.V232.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.Id.StickerId) Evergreen.V232.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V232.Id.Id Evergreen.V232.Id.GuildId) Evergreen.V232.ChannelName.ChannelName Evergreen.V232.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V232.Id.Id Evergreen.V232.Id.GuildId) (Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelId) Evergreen.V232.ChannelName.ChannelName Evergreen.V232.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V232.Id.Id Evergreen.V232.Id.GuildId) (Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId) (Evergreen.V232.Id.Id Evergreen.V232.Id.GuildId) (Evergreen.V232.SecretId.SecretId Evergreen.V232.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId) (Evergreen.V232.Id.Id Evergreen.V232.Id.GuildId) Evergreen.V232.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V232.LocalState.JoinGuildError
            { guildId : Evergreen.V232.Id.Id Evergreen.V232.Id.GuildId
            , guild : Evergreen.V232.LocalState.FrontendGuild
            , owner : Evergreen.V232.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId) Evergreen.V232.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId) Evergreen.V232.Id.GuildOrDmId Evergreen.V232.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId) (Evergreen.V232.Discord.Id Evergreen.V232.Discord.GuildId) (Evergreen.V232.Discord.Id Evergreen.V232.Discord.ChannelId) Evergreen.V232.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId) (Evergreen.V232.Discord.Id Evergreen.V232.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId) Evergreen.V232.Id.GuildOrDmId Evergreen.V232.Id.ThreadRouteWithMessage Evergreen.V232.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId) Evergreen.V232.Id.GuildOrDmId Evergreen.V232.Id.ThreadRouteWithMessage Evergreen.V232.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId) (Evergreen.V232.Discord.Id Evergreen.V232.Discord.GuildId) (Evergreen.V232.Discord.Id Evergreen.V232.Discord.ChannelId) Evergreen.V232.Id.ThreadRouteWithMessage Evergreen.V232.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId) (Evergreen.V232.Discord.Id Evergreen.V232.Discord.PrivateChannelId) (Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelMessageId) Evergreen.V232.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId) (Evergreen.V232.Discord.Id Evergreen.V232.Discord.GuildId) (Evergreen.V232.Discord.Id Evergreen.V232.Discord.ChannelId) Evergreen.V232.Id.ThreadRouteWithMessage Evergreen.V232.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId) (Evergreen.V232.Discord.Id Evergreen.V232.Discord.PrivateChannelId) (Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelMessageId) Evergreen.V232.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId) Evergreen.V232.Id.GuildOrDmId Evergreen.V232.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V232.RichText.RichText (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId))) (SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.FileStatus.FileId) Evergreen.V232.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId) (Evergreen.V232.Discord.Id Evergreen.V232.Discord.GuildId) (Evergreen.V232.Discord.Id Evergreen.V232.Discord.ChannelId) Evergreen.V232.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V232.RichText.RichText (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V232.Id.DiscordGuildOrDmId_DmData (Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V232.RichText.RichText (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId) Evergreen.V232.Id.AnyGuildOrDmId Evergreen.V232.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V232.Id.AnyGuildOrDmId Evergreen.V232.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V232.Discord.Id Evergreen.V232.Discord.GuildId) (Evergreen.V232.Discord.Id Evergreen.V232.Discord.ChannelId) Evergreen.V232.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V232.Discord.Id Evergreen.V232.Discord.PrivateChannelId) (Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId) Evergreen.V232.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId) Evergreen.V232.FileStatus.FileHash
    | Server_SetGuildIcon (Evergreen.V232.Id.Id Evergreen.V232.Id.GuildId) Evergreen.V232.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V232.Id.Id Evergreen.V232.Id.GuildId) Evergreen.V232.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V232.Discord.Id Evergreen.V232.Discord.GuildId) Evergreen.V232.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V232.SessionIdHash.SessionIdHash Evergreen.V232.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V232.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V232.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V232.Id.AnyGuildOrDmId, Evergreen.V232.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V232.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId) Evergreen.V232.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V232.Discord.Id Evergreen.V232.Discord.GuildId) (Evergreen.V232.Discord.Id Evergreen.V232.Discord.ChannelId) Evergreen.V232.ChannelName.ChannelName (Evergreen.V232.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V232.Discord.Id Evergreen.V232.Discord.PrivateChannelId)
        (Evergreen.V232.NonemptyDict.NonemptyDict
            (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V232.Discord.Id Evergreen.V232.Discord.GuildId) Evergreen.V232.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V232.Discord.Id Evergreen.V232.Discord.PrivateChannelId) Evergreen.V232.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId) Evergreen.V232.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId) (Maybe (Evergreen.V232.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V232.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V232.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V232.Id.Id Evergreen.V232.Id.GuildId) (Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelId) Evergreen.V232.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V232.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId) Evergreen.V232.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V232.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V232.Discord.Id Evergreen.V232.Discord.GuildId) (Evergreen.V232.Discord.Id Evergreen.V232.Discord.ChannelId) Evergreen.V232.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V232.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V232.Discord.Id Evergreen.V232.Discord.PrivateChannelId) (Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V232.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V232.Discord.Id Evergreen.V232.Discord.GuildId) Evergreen.V232.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V232.Discord.Id Evergreen.V232.Discord.GuildId) (Evergreen.V232.Discord.Id Evergreen.V232.Discord.ChannelId) (Evergreen.V232.Discord.OptionalData String) (Evergreen.V232.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V232.Discord.Id Evergreen.V232.Discord.GuildId)
        (Evergreen.V232.MembersAndOwner.MembersAndOwner
            (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V232.Discord.Id Evergreen.V232.Discord.GuildId) (Evergreen.V232.Discord.Id Evergreen.V232.Discord.ChannelId) (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId) Evergreen.V232.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.Id.StickerId) Evergreen.V232.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.Id.CustomEmojiId) Evergreen.V232.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V232.Call.ServerChange
    | Server_Go
        (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId)
        { otherUserId : Evergreen.V232.Id.Id Evergreen.V232.Id.UserId
        }
        Evergreen.V232.Go.LocalChange


type LocalMsg
    = LocalChange (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId) LocalChange
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


type alias NewGuildForm =
    { name : String
    , pressedSubmit : Bool
    }


type GuildChannelNameHover
    = NoChannelNameHover
    | GuildChannelNameHover (Evergreen.V232.Id.Id Evergreen.V232.Id.GuildId) (Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelId) Evergreen.V232.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V232.Discord.Id Evergreen.V232.Discord.GuildId) (Evergreen.V232.Discord.Id Evergreen.V232.Discord.ChannelId) Evergreen.V232.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.FileStatus.FileId) Evergreen.V232.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V232.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V232.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V232.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V232.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V232.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V232.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V232.Coord.Coord Evergreen.V232.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V232.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V232.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V232.Id.AnyGuildOrDmId Evergreen.V232.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V232.Id.AnyGuildOrDmId Evergreen.V232.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V232.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V232.Coord.Coord Evergreen.V232.CssPixels.CssPixels) (Maybe Evergreen.V232.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V232.Id.AnyGuildOrDmId, Evergreen.V232.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelMessageId) (Evergreen.V232.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.Id.ThreadMessageId) (Evergreen.V232.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V232.Editable.Model
    , showLinkDiscordSetup : Bool
    , domainWhitelistInput : String
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V232.Local.Local LocalMsg Evergreen.V232.LocalState.LocalState
    , admin : Evergreen.V232.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V232.Id.AnyGuildOrDmId, Evergreen.V232.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V232.Id.Id Evergreen.V232.Id.GuildId, Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelId ) EditChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V232.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V232.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V232.Id.AnyGuildOrDmId, Evergreen.V232.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V232.Id.AnyGuildOrDmId, Evergreen.V232.Id.ThreadRoute ) (Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : Evergreen.V232.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V232.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V232.Id.AnyGuildOrDmId, Evergreen.V232.Id.ThreadRoute ) (Evergreen.V232.NonemptyDict.NonemptyDict (Evergreen.V232.Id.Id Evergreen.V232.FileStatus.FileId) Evergreen.V232.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V232.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V232.TextEditor.Model
    , profilePictureEditor : Evergreen.V232.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V232.Id.Id Evergreen.V232.Id.GuildId, Evergreen.V232.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V232.Emoji.Model
    , voiceChat : Evergreen.V232.Call.Model
    , currentDmGoMatch : SeqDict.SeqDict ( Evergreen.V232.Id.Id Evergreen.V232.Id.UserId, Maybe (Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelMessageId) ) Evergreen.V232.Go.Model
    , fileDragOverCount : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V232.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V232.SecretId.SecretId Evergreen.V232.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V232.Range.Range
                , direction : Evergreen.V232.Range.SelectionDirection
                }
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V232.NonemptyDict.NonemptyDict Int Evergreen.V232.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V232.NonemptyDict.NonemptyDict Int Evergreen.V232.Touch.Touch
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
    | AdminToFrontend Evergreen.V232.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V232.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V232.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V232.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V232.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V232.ImageEditor.ToFrontend


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V232.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V232.Coord.Coord Evergreen.V232.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V232.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , notificationPermission : Evergreen.V232.Ports.NotificationPermission
    , pwaStatus : Evergreen.V232.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V232.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V232.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V232.Emoji.CachedEmojiData
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V232.Id.Id Evergreen.V232.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V232.Id.Id Evergreen.V232.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V232.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V232.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V232.Coord.Coord Evergreen.V232.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V232.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V232.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V232.Id.Id Evergreen.V232.Id.GuildId, Evergreen.V232.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V232.DmChannel.DmChannelId, Evergreen.V232.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V232.Discord.Id Evergreen.V232.Discord.GuildId, Evergreen.V232.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V232.Discord.Id Evergreen.V232.Discord.PrivateChannelId, Evergreen.V232.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V232.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V232.NonemptyDict.NonemptyDict (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId) Evergreen.V232.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V232.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V232.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V232.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V232.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId) Evergreen.V232.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId) Evergreen.V232.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.Id.GuildId) Evergreen.V232.LocalState.BackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V232.Discord.Id Evergreen.V232.Discord.GuildId) Evergreen.V232.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V232.DmChannel.DmChannelId Evergreen.V232.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V232.Discord.Id Evergreen.V232.Discord.PrivateChannelId) Evergreen.V232.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V232.OneToOne.OneToOne (Evergreen.V232.Slack.Id Evergreen.V232.Slack.ChannelId) Evergreen.V232.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V232.OneToOne.OneToOne String (Evergreen.V232.Id.Id Evergreen.V232.Id.GuildId)
    , slackUsers : Evergreen.V232.OneToOne.OneToOne (Evergreen.V232.Slack.Id Evergreen.V232.Slack.UserId) (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId)
    , slackServers : Evergreen.V232.OneToOne.OneToOne (Evergreen.V232.Slack.Id Evergreen.V232.Slack.TeamId) (Evergreen.V232.Id.Id Evergreen.V232.Id.GuildId)
    , slackToken : Maybe Evergreen.V232.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V232.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V232.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V232.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V232.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId) Evergreen.V232.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId, Evergreen.V232.Discord.Id Evergreen.V232.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V232.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V232.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V232.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V232.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId) (Evergreen.V232.LocalState.LoadingDiscordChannel (List Evergreen.V232.Discord.Message))
    , signupsEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V232.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.Id.StickerId) Evergreen.V232.Sticker.StickerData
    , discordStickers : Evergreen.V232.OneToOne.OneToOne (Evergreen.V232.Discord.Id Evergreen.V232.Discord.StickerId) (Evergreen.V232.Id.Id Evergreen.V232.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.Id.CustomEmojiId) Evergreen.V232.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V232.OneToOne.OneToOne Evergreen.V232.RichText.DiscordCustomEmojiIdAndName (Evergreen.V232.Id.Id Evergreen.V232.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V232.Postmark.ApiKey
    , serverSecret : Evergreen.V232.SecretId.SecretId Evergreen.V232.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V232.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V232.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V232.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V232.Route.Route
    | SelectedFilesToAttach ( Evergreen.V232.Id.AnyGuildOrDmId, Evergreen.V232.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V232.Id.Id Evergreen.V232.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V232.Id.Id Evergreen.V232.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V232.Id.Id Evergreen.V232.Id.GuildId) (Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelId) Evergreen.V232.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V232.Id.Id Evergreen.V232.Id.GuildId) (Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelId) Evergreen.V232.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V232.Discord.Id Evergreen.V232.Discord.GuildId) (Evergreen.V232.Discord.Id Evergreen.V232.Discord.ChannelId) Evergreen.V232.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V232.Discord.Id Evergreen.V232.Discord.GuildId) (Evergreen.V232.Discord.Id Evergreen.V232.Discord.ChannelId) Evergreen.V232.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V232.Id.Id Evergreen.V232.Id.GuildId) (Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V232.Id.Id Evergreen.V232.Id.GuildId) (Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V232.Id.Id Evergreen.V232.Id.GuildId) (Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V232.Id.Id Evergreen.V232.Id.GuildId) (Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V232.Id.Id Evergreen.V232.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V232.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V232.Id.AnyGuildOrDmId Evergreen.V232.Id.ThreadRouteWithMessage (Evergreen.V232.Coord.Coord Evergreen.V232.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V232.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V232.Id.AnyGuildOrDmId Evergreen.V232.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V232.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V232.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V232.Id.AnyGuildOrDmId, Evergreen.V232.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V232.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V232.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V232.Id.AnyGuildOrDmId, Evergreen.V232.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V232.NonemptyDict.NonemptyDict Int Evergreen.V232.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V232.NonemptyDict.NonemptyDict Int Evergreen.V232.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V232.Id.AnyGuildOrDmId Evergreen.V232.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V232.Id.AnyGuildOrDmId Evergreen.V232.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V232.NonemptySet.NonemptySet (Evergreen.V232.Id.Id Evergreen.V232.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V232.Id.AnyGuildOrDmId, Evergreen.V232.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V232.Id.AnyGuildOrDmId Evergreen.V232.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V232.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V232.AiChat.Msg
    | GoMsg Evergreen.V232.Go.Msg
    | UserNameEditableMsg (Evergreen.V232.Editable.Msg Evergreen.V232.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V232.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V232.Id.Id Evergreen.V232.Id.GuildId) Evergreen.V232.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V232.Id.AnyGuildOrDmId, Evergreen.V232.Id.ThreadRoute ) (Evergreen.V232.Id.Id Evergreen.V232.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V232.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V232.Id.AnyGuildOrDmId, Evergreen.V232.Id.ThreadRoute ) (Evergreen.V232.Id.Id Evergreen.V232.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V232.Id.AnyGuildOrDmId, Evergreen.V232.Id.ThreadRoute ) (Evergreen.V232.Id.Id Evergreen.V232.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V232.Id.AnyGuildOrDmId, Evergreen.V232.Id.ThreadRoute )
        { fileId : Evergreen.V232.Id.Id Evergreen.V232.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V232.Id.AnyGuildOrDmId, Evergreen.V232.Id.ThreadRoute ) (Evergreen.V232.Id.Id Evergreen.V232.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V232.Id.AnyGuildOrDmId, Evergreen.V232.Id.ThreadRoute ) (Evergreen.V232.Id.Id Evergreen.V232.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V232.Id.AnyGuildOrDmId, Evergreen.V232.Id.ThreadRoute )
        { fileId : Evergreen.V232.Id.Id Evergreen.V232.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V232.Id.AnyGuildOrDmId, Evergreen.V232.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V232.Id.AnyGuildOrDmId, Evergreen.V232.Id.ThreadRoute ) (Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelMessageId) (Evergreen.V232.Id.Id Evergreen.V232.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V232.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V232.Id.AnyGuildOrDmId, Evergreen.V232.Id.ThreadRoute ) (Evergreen.V232.Id.Id Evergreen.V232.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V232.Id.AnyGuildOrDmId Evergreen.V232.Id.ThreadRouteWithMessage Evergreen.V232.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V232.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V232.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V232.Id.Id Evergreen.V232.Id.GuildId) Evergreen.V232.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId) (Evergreen.V232.Discord.Id Evergreen.V232.Discord.GuildId) Evergreen.V232.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V232.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V232.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId
        , otherUserId : Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V232.Id.AnyGuildOrDmId Evergreen.V232.Id.ThreadRoute Evergreen.V232.MessageInput.Msg
    | MessageInputMsg Evergreen.V232.Id.AnyGuildOrDmId Evergreen.V232.Id.ThreadRoute Evergreen.V232.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V232.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V232.Range.Range, Evergreen.V232.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V232.Range.Range, Evergreen.V232.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V232.Call.FromJs)
    | VoiceChatMsg Evergreen.V232.Call.Msg
    | PressedChannelHeaderTab Evergreen.V232.Route.DmChannelHeaderTab
    | FileDragEnter
    | FileDragLeave
    | FileDropped (List Effect.File.File)


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V232.Id.Id Evergreen.V232.Id.GuildId) (Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelId) Evergreen.V232.Id.ThreadRoute
    | InitialLoadRequested_Dm Evergreen.V232.DmChannel.DmChannelId Evergreen.V232.Id.ThreadRoute
    | InitialLoadRequested_Discord Evergreen.V232.Id.DiscordGuildOrDmId Evergreen.V232.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V232.Id.Id Evergreen.V232.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V232.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V232.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V232.Untrusted.Untrusted Evergreen.V232.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V232.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V232.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V232.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V232.Id.Id Evergreen.V232.Id.GuildId) (Evergreen.V232.SecretId.SecretId Evergreen.V232.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V232.PersonName.PersonName Evergreen.V232.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V232.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V232.Slack.OAuthCode Evergreen.V232.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V232.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V232.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V232.Id.Id Evergreen.V232.Pagination.PageId))


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V232.Discord.Id Evergreen.V232.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V232.Discord.Id Evergreen.V232.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V232.EmailAddress.EmailAddress (Result Evergreen.V232.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V232.EmailAddress.EmailAddress (Result Evergreen.V232.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId) Evergreen.V232.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V232.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V232.Discord.Id Evergreen.V232.Discord.GuildId) (Evergreen.V232.Discord.Id Evergreen.V232.Discord.ChannelId) Evergreen.V232.Id.ThreadRouteWithMaybeMessage (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId) (Result Evergreen.V232.Discord.HttpError Evergreen.V232.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V232.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V232.Discord.Id Evergreen.V232.Discord.PrivateChannelId) (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId) (Result Evergreen.V232.Discord.HttpError Evergreen.V232.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V232.Discord.Id Evergreen.V232.Discord.GuildId) (Evergreen.V232.Discord.Id Evergreen.V232.Discord.ChannelId) Evergreen.V232.Id.ThreadRouteWithMessage (Evergreen.V232.Discord.Id Evergreen.V232.Discord.MessageId) (Result Evergreen.V232.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V232.Discord.Id Evergreen.V232.Discord.PrivateChannelId) (Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelMessageId) (Evergreen.V232.Discord.Id Evergreen.V232.Discord.MessageId) (Result Evergreen.V232.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V232.Discord.Id Evergreen.V232.Discord.GuildId) (Evergreen.V232.Discord.Id Evergreen.V232.Discord.ChannelId) Evergreen.V232.Id.ThreadRouteWithMessage (Evergreen.V232.Discord.Id Evergreen.V232.Discord.MessageId) (Result Evergreen.V232.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V232.Discord.Id Evergreen.V232.Discord.PrivateChannelId) (Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelMessageId) (Evergreen.V232.Discord.Id Evergreen.V232.Discord.MessageId) (Result Evergreen.V232.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V232.Discord.Id Evergreen.V232.Discord.GuildId) (Evergreen.V232.Discord.Id Evergreen.V232.Discord.ChannelId) Evergreen.V232.Id.ThreadRouteWithMessage (Evergreen.V232.Discord.Id Evergreen.V232.Discord.MessageId) Evergreen.V232.Emoji.EmojiOrCustomEmoji (Result Evergreen.V232.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V232.Discord.Id Evergreen.V232.Discord.PrivateChannelId) (Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelMessageId) (Evergreen.V232.Discord.Id Evergreen.V232.Discord.MessageId) Evergreen.V232.Emoji.EmojiOrCustomEmoji (Result Evergreen.V232.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V232.Discord.Id Evergreen.V232.Discord.GuildId) (Evergreen.V232.Discord.Id Evergreen.V232.Discord.ChannelId) Evergreen.V232.Id.ThreadRouteWithMessage (Evergreen.V232.Discord.Id Evergreen.V232.Discord.MessageId) Evergreen.V232.Emoji.EmojiOrCustomEmoji (Result Evergreen.V232.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V232.Discord.Id Evergreen.V232.Discord.PrivateChannelId) (Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelMessageId) (Evergreen.V232.Discord.Id Evergreen.V232.Discord.MessageId) Evergreen.V232.Emoji.EmojiOrCustomEmoji (Result Evergreen.V232.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V232.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V232.Discord.HttpError (List ( Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId, Maybe Evergreen.V232.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V232.Slack.CurrentUser
            , team : Evergreen.V232.Slack.Team
            , users : List Evergreen.V232.Slack.User
            , channels : List ( Evergreen.V232.Slack.Channel, List Evergreen.V232.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId) (Result Effect.Http.Error Evergreen.V232.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId) Evergreen.V232.Discord.UserAuth (Result Evergreen.V232.Discord.HttpError Evergreen.V232.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId) (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId) (Result Evergreen.V232.Discord.HttpError Evergreen.V232.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId)
        (Result
            Evergreen.V232.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V232.Discord.Id Evergreen.V232.Discord.PrivateChannelId
                , members : List (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId)
                }
            , List
                ( Evergreen.V232.Discord.Id Evergreen.V232.Discord.GuildId
                , { guild : Evergreen.V232.Discord.GatewayGuild
                  , channels : List Evergreen.V232.Discord.Channel
                  , icon : Maybe Evergreen.V232.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId) Bool
    | WebsocketSentDataForUser (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V232.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V232.Discord.Id Evergreen.V232.Discord.AttachmentId, Evergreen.V232.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V232.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V232.Discord.Id Evergreen.V232.Discord.AttachmentId, Evergreen.V232.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId) (Evergreen.V232.Discord.Id Evergreen.V232.Discord.GuildId) (Evergreen.V232.Discord.Id Evergreen.V232.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V232.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V232.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId) (Evergreen.V232.Discord.Id Evergreen.V232.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V232.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V232.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId) (Evergreen.V232.Discord.Id Evergreen.V232.Discord.GuildId) (Evergreen.V232.Discord.Id Evergreen.V232.Discord.ChannelId) (Result Evergreen.V232.Discord.HttpError (List Evergreen.V232.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId) (Evergreen.V232.Discord.Id Evergreen.V232.Discord.PrivateChannelId) (Result Evergreen.V232.Discord.HttpError (List Evergreen.V232.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V232.Id.Id Evergreen.V232.Id.GuildId) (Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelId) Evergreen.V232.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V232.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V232.DmChannel.DmChannelId Evergreen.V232.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V232.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V232.Discord.Id Evergreen.V232.Discord.GuildId) (Evergreen.V232.Discord.Id Evergreen.V232.Discord.ChannelId) Evergreen.V232.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V232.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V232.Discord.Id Evergreen.V232.Discord.PrivateChannelId) (Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V232.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId)
        (Evergreen.V232.Discord.Id Evergreen.V232.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V232.Discord.HttpError
            { guild : Evergreen.V232.Discord.GatewayGuild
            , channels : List Evergreen.V232.Discord.Channel
            , icon : Maybe Evergreen.V232.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V232.Discord.Id Evergreen.V232.Discord.GuildId) (Result Evergreen.V232.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V232.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId) (List ( Evergreen.V232.Id.Id Evergreen.V232.Id.StickerId, Result Effect.Http.Error Evergreen.V232.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V232.Id.Id Evergreen.V232.Id.StickerId, Result Effect.Http.Error Evergreen.V232.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId) (List ( Evergreen.V232.Id.Id Evergreen.V232.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V232.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V232.Id.Id Evergreen.V232.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V232.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V232.Discord.HttpError (List Evergreen.V232.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V232.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V232.SecretId.SecretId Evergreen.V232.SecretId.ServerSecret))
