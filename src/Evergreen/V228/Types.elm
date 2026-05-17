module Evergreen.V228.Types exposing (..)

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
import Evergreen.V228.AiChat
import Evergreen.V228.Call
import Evergreen.V228.ChannelDescription
import Evergreen.V228.ChannelName
import Evergreen.V228.Coord
import Evergreen.V228.CssPixels
import Evergreen.V228.CustomEmoji
import Evergreen.V228.Discord
import Evergreen.V228.DiscordAttachmentId
import Evergreen.V228.DiscordUserData
import Evergreen.V228.DmChannel
import Evergreen.V228.Editable
import Evergreen.V228.EmailAddress
import Evergreen.V228.Embed
import Evergreen.V228.Emoji
import Evergreen.V228.FileStatus
import Evergreen.V228.Go
import Evergreen.V228.GuildName
import Evergreen.V228.Id
import Evergreen.V228.ImageEditor
import Evergreen.V228.Local
import Evergreen.V228.LocalState
import Evergreen.V228.Log
import Evergreen.V228.LoginForm
import Evergreen.V228.MembersAndOwner
import Evergreen.V228.Message
import Evergreen.V228.MessageInput
import Evergreen.V228.MessageView
import Evergreen.V228.NonemptyDict
import Evergreen.V228.NonemptySet
import Evergreen.V228.OneToOne
import Evergreen.V228.Pages.Admin
import Evergreen.V228.Pagination
import Evergreen.V228.PersonName
import Evergreen.V228.Ports
import Evergreen.V228.Postmark
import Evergreen.V228.Range
import Evergreen.V228.RichText
import Evergreen.V228.Route
import Evergreen.V228.SecretId
import Evergreen.V228.SessionIdHash
import Evergreen.V228.Slack
import Evergreen.V228.Sticker
import Evergreen.V228.TextEditor
import Evergreen.V228.ToBackendLog
import Evergreen.V228.Touch
import Evergreen.V228.TwoFactorAuthentication
import Evergreen.V228.Ui.Anim
import Evergreen.V228.Untrusted
import Evergreen.V228.User
import Evergreen.V228.UserAgent
import Evergreen.V228.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V228.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V228.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.Id.GuildId) Evergreen.V228.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId) Evergreen.V228.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V228.Discord.Id Evergreen.V228.Discord.PrivateChannelId) Evergreen.V228.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V228.Discord.Id Evergreen.V228.Discord.GuildId) Evergreen.V228.LocalState.DiscordFrontendGuild
    , user : Evergreen.V228.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId) Evergreen.V228.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId) Evergreen.V228.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId) Evergreen.V228.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V228.SessionIdHash.SessionIdHash Evergreen.V228.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V228.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.Id.StickerId) Evergreen.V228.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.Id.CustomEmojiId) Evergreen.V228.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V228.Call.RoomId (Evergreen.V228.NonemptySet.NonemptySet ( Evergreen.V228.Id.Id Evergreen.V228.Id.UserId, Effect.Lamdera.ClientId ))
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V228.Route.Route
    , windowSize : Evergreen.V228.Coord.Coord Evergreen.V228.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V228.Ports.NotificationPermission
    , pwaStatus : Evergreen.V228.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V228.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V228.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V228.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V228.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.FileStatus.FileId) Evergreen.V228.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V228.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V228.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.FileStatus.FileId) Evergreen.V228.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V228.Id.Id Evergreen.V228.Id.GuildId) Evergreen.V228.ChannelName.ChannelName Evergreen.V228.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V228.Id.Id Evergreen.V228.Id.GuildId) (Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelId) Evergreen.V228.ChannelName.ChannelName Evergreen.V228.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V228.Id.Id Evergreen.V228.Id.GuildId) (Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V228.Id.Id Evergreen.V228.Id.GuildId) (Evergreen.V228.UserSession.ToBeFilledInByBackend (Evergreen.V228.SecretId.SecretId Evergreen.V228.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V228.GuildName.GuildName (Evergreen.V228.UserSession.ToBeFilledInByBackend (Evergreen.V228.Id.Id Evergreen.V228.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V228.Id.AnyGuildOrDmId, Evergreen.V228.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V228.Id.AnyGuildOrDmId Evergreen.V228.Id.ThreadRouteWithMessage Evergreen.V228.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V228.Id.AnyGuildOrDmId Evergreen.V228.Id.ThreadRouteWithMessage Evergreen.V228.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V228.Id.GuildOrDmId Evergreen.V228.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.FileStatus.FileId) Evergreen.V228.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId) (Evergreen.V228.Discord.Id Evergreen.V228.Discord.GuildId) (Evergreen.V228.Discord.Id Evergreen.V228.Discord.ChannelId) Evergreen.V228.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V228.Id.DiscordGuildOrDmId_DmData (Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V228.Id.AnyGuildOrDmId Evergreen.V228.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V228.Id.AnyGuildOrDmId Evergreen.V228.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V228.Id.AnyGuildOrDmId Evergreen.V228.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V228.UserSession.SetViewing
    | Local_SetName Evergreen.V228.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V228.Id.GuildOrDmId (Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelMessageId) (Evergreen.V228.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelMessageId) (Evergreen.V228.Message.Message Evergreen.V228.Id.ChannelMessageId (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V228.Id.GuildOrDmId (Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelMessageId) (Evergreen.V228.Id.Id Evergreen.V228.Id.ThreadMessageId) (Evergreen.V228.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.Id.ThreadMessageId) (Evergreen.V228.Message.Message Evergreen.V228.Id.ThreadMessageId (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V228.Id.DiscordGuildOrDmId (Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelMessageId) (Evergreen.V228.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelMessageId) (Evergreen.V228.Message.Message Evergreen.V228.Id.ChannelMessageId (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V228.Id.DiscordGuildOrDmId (Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelMessageId) (Evergreen.V228.Id.Id Evergreen.V228.Id.ThreadMessageId) (Evergreen.V228.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.Id.ThreadMessageId) (Evergreen.V228.Message.Message Evergreen.V228.Id.ThreadMessageId (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V228.Id.Id Evergreen.V228.Id.GuildId) Evergreen.V228.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId) (Evergreen.V228.Discord.Id Evergreen.V228.Discord.GuildId) Evergreen.V228.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V228.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V228.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V228.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V228.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V228.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V228.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V228.NonemptySet.NonemptySet (Evergreen.V228.Id.Id Evergreen.V228.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V228.Call.LocalChange
    | Local_Go
        { otherUserId : Evergreen.V228.Id.Id Evergreen.V228.Id.UserId
        }
        Evergreen.V228.Go.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId) Effect.Time.Posix Evergreen.V228.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V228.RichText.RichText (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId))) Evergreen.V228.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.FileStatus.FileId) Evergreen.V228.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.Id.StickerId) Evergreen.V228.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V228.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V228.RichText.RichText (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId))) Evergreen.V228.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.FileStatus.FileId) Evergreen.V228.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.Id.StickerId) Evergreen.V228.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V228.Id.Id Evergreen.V228.Id.GuildId) Evergreen.V228.ChannelName.ChannelName Evergreen.V228.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V228.Id.Id Evergreen.V228.Id.GuildId) (Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelId) Evergreen.V228.ChannelName.ChannelName Evergreen.V228.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V228.Id.Id Evergreen.V228.Id.GuildId) (Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId) (Evergreen.V228.Id.Id Evergreen.V228.Id.GuildId) (Evergreen.V228.SecretId.SecretId Evergreen.V228.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId) (Evergreen.V228.Id.Id Evergreen.V228.Id.GuildId) Evergreen.V228.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V228.LocalState.JoinGuildError
            { guildId : Evergreen.V228.Id.Id Evergreen.V228.Id.GuildId
            , guild : Evergreen.V228.LocalState.FrontendGuild
            , owner : Evergreen.V228.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId) Evergreen.V228.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId) Evergreen.V228.Id.GuildOrDmId Evergreen.V228.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId) (Evergreen.V228.Discord.Id Evergreen.V228.Discord.GuildId) (Evergreen.V228.Discord.Id Evergreen.V228.Discord.ChannelId) Evergreen.V228.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId) (Evergreen.V228.Discord.Id Evergreen.V228.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId) Evergreen.V228.Id.GuildOrDmId Evergreen.V228.Id.ThreadRouteWithMessage Evergreen.V228.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId) Evergreen.V228.Id.GuildOrDmId Evergreen.V228.Id.ThreadRouteWithMessage Evergreen.V228.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId) (Evergreen.V228.Discord.Id Evergreen.V228.Discord.GuildId) (Evergreen.V228.Discord.Id Evergreen.V228.Discord.ChannelId) Evergreen.V228.Id.ThreadRouteWithMessage Evergreen.V228.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId) (Evergreen.V228.Discord.Id Evergreen.V228.Discord.PrivateChannelId) (Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelMessageId) Evergreen.V228.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId) (Evergreen.V228.Discord.Id Evergreen.V228.Discord.GuildId) (Evergreen.V228.Discord.Id Evergreen.V228.Discord.ChannelId) Evergreen.V228.Id.ThreadRouteWithMessage Evergreen.V228.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId) (Evergreen.V228.Discord.Id Evergreen.V228.Discord.PrivateChannelId) (Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelMessageId) Evergreen.V228.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId) Evergreen.V228.Id.GuildOrDmId Evergreen.V228.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V228.RichText.RichText (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId))) (SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.FileStatus.FileId) Evergreen.V228.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId) (Evergreen.V228.Discord.Id Evergreen.V228.Discord.GuildId) (Evergreen.V228.Discord.Id Evergreen.V228.Discord.ChannelId) Evergreen.V228.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V228.RichText.RichText (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V228.Id.DiscordGuildOrDmId_DmData (Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V228.RichText.RichText (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId) Evergreen.V228.Id.AnyGuildOrDmId Evergreen.V228.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V228.Id.AnyGuildOrDmId Evergreen.V228.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V228.Discord.Id Evergreen.V228.Discord.GuildId) (Evergreen.V228.Discord.Id Evergreen.V228.Discord.ChannelId) Evergreen.V228.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V228.Discord.Id Evergreen.V228.Discord.PrivateChannelId) (Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId) Evergreen.V228.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId) Evergreen.V228.FileStatus.FileHash
    | Server_SetGuildIcon (Evergreen.V228.Id.Id Evergreen.V228.Id.GuildId) Evergreen.V228.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V228.Id.Id Evergreen.V228.Id.GuildId) Evergreen.V228.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V228.Discord.Id Evergreen.V228.Discord.GuildId) Evergreen.V228.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V228.SessionIdHash.SessionIdHash Evergreen.V228.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V228.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V228.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V228.Id.AnyGuildOrDmId, Evergreen.V228.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V228.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId) Evergreen.V228.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V228.Discord.Id Evergreen.V228.Discord.GuildId) (Evergreen.V228.Discord.Id Evergreen.V228.Discord.ChannelId) Evergreen.V228.ChannelName.ChannelName (Evergreen.V228.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V228.Discord.Id Evergreen.V228.Discord.PrivateChannelId)
        (Evergreen.V228.NonemptyDict.NonemptyDict
            (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V228.Discord.Id Evergreen.V228.Discord.GuildId) Evergreen.V228.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V228.Discord.Id Evergreen.V228.Discord.PrivateChannelId) Evergreen.V228.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId) Evergreen.V228.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId) (Maybe (Evergreen.V228.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V228.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V228.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V228.Id.Id Evergreen.V228.Id.GuildId) (Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelId) Evergreen.V228.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V228.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId) Evergreen.V228.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V228.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V228.Discord.Id Evergreen.V228.Discord.GuildId) (Evergreen.V228.Discord.Id Evergreen.V228.Discord.ChannelId) Evergreen.V228.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V228.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V228.Discord.Id Evergreen.V228.Discord.PrivateChannelId) (Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V228.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V228.Discord.Id Evergreen.V228.Discord.GuildId) Evergreen.V228.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V228.Discord.Id Evergreen.V228.Discord.GuildId) (Evergreen.V228.Discord.Id Evergreen.V228.Discord.ChannelId) (Evergreen.V228.Discord.OptionalData String) (Evergreen.V228.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V228.Discord.Id Evergreen.V228.Discord.GuildId)
        (Evergreen.V228.MembersAndOwner.MembersAndOwner
            (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V228.Discord.Id Evergreen.V228.Discord.GuildId) (Evergreen.V228.Discord.Id Evergreen.V228.Discord.ChannelId) (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId) Evergreen.V228.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.Id.StickerId) Evergreen.V228.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.Id.CustomEmojiId) Evergreen.V228.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V228.Call.ServerChange
    | Server_Go
        (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId)
        { otherUserId : Evergreen.V228.Id.Id Evergreen.V228.Id.UserId
        }
        Evergreen.V228.Go.LocalChange


type LocalMsg
    = LocalChange (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V228.Id.Id Evergreen.V228.Id.GuildId) (Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelId) Evergreen.V228.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V228.Discord.Id Evergreen.V228.Discord.GuildId) (Evergreen.V228.Discord.Id Evergreen.V228.Discord.ChannelId) Evergreen.V228.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.FileStatus.FileId) Evergreen.V228.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V228.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V228.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V228.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V228.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V228.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V228.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V228.Coord.Coord Evergreen.V228.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V228.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V228.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V228.Id.AnyGuildOrDmId Evergreen.V228.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V228.Id.AnyGuildOrDmId Evergreen.V228.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V228.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V228.Coord.Coord Evergreen.V228.CssPixels.CssPixels) (Maybe Evergreen.V228.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V228.Id.AnyGuildOrDmId, Evergreen.V228.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelMessageId) (Evergreen.V228.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.Id.ThreadMessageId) (Evergreen.V228.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V228.Editable.Model
    , showLinkDiscordSetup : Bool
    , domainWhitelistInput : String
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V228.Local.Local LocalMsg Evergreen.V228.LocalState.LocalState
    , admin : Evergreen.V228.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V228.Id.AnyGuildOrDmId, Evergreen.V228.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V228.Id.Id Evergreen.V228.Id.GuildId, Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelId ) EditChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V228.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V228.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V228.Id.AnyGuildOrDmId, Evergreen.V228.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V228.Id.AnyGuildOrDmId, Evergreen.V228.Id.ThreadRoute ) (Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : Evergreen.V228.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V228.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V228.Id.AnyGuildOrDmId, Evergreen.V228.Id.ThreadRoute ) (Evergreen.V228.NonemptyDict.NonemptyDict (Evergreen.V228.Id.Id Evergreen.V228.FileStatus.FileId) Evergreen.V228.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V228.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V228.TextEditor.Model
    , profilePictureEditor : Evergreen.V228.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V228.Id.Id Evergreen.V228.Id.GuildId, Evergreen.V228.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V228.Emoji.Model
    , voiceChat : Evergreen.V228.Call.Model
    , currentDmGoMatch : SeqDict.SeqDict ( Evergreen.V228.Id.Id Evergreen.V228.Id.UserId, Maybe (Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelMessageId) ) Evergreen.V228.Go.Model
    , fileDragOverCount : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V228.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V228.SecretId.SecretId Evergreen.V228.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V228.Range.Range
                , direction : Evergreen.V228.Range.SelectionDirection
                }
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V228.NonemptyDict.NonemptyDict Int Evergreen.V228.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V228.NonemptyDict.NonemptyDict Int Evergreen.V228.Touch.Touch
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
    | AdminToFrontend Evergreen.V228.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V228.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V228.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V228.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V228.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V228.ImageEditor.ToFrontend


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V228.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V228.Coord.Coord Evergreen.V228.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V228.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , notificationPermission : Evergreen.V228.Ports.NotificationPermission
    , pwaStatus : Evergreen.V228.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V228.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V228.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V228.Emoji.CachedEmojiData
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V228.Id.Id Evergreen.V228.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V228.Id.Id Evergreen.V228.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V228.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V228.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V228.Coord.Coord Evergreen.V228.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V228.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V228.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V228.Id.Id Evergreen.V228.Id.GuildId, Evergreen.V228.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V228.DmChannel.DmChannelId, Evergreen.V228.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V228.Discord.Id Evergreen.V228.Discord.GuildId, Evergreen.V228.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V228.Discord.Id Evergreen.V228.Discord.PrivateChannelId, Evergreen.V228.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V228.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V228.NonemptyDict.NonemptyDict (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId) Evergreen.V228.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V228.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V228.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V228.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V228.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId) Evergreen.V228.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId) Evergreen.V228.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.Id.GuildId) Evergreen.V228.LocalState.BackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V228.Discord.Id Evergreen.V228.Discord.GuildId) Evergreen.V228.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V228.DmChannel.DmChannelId Evergreen.V228.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V228.Discord.Id Evergreen.V228.Discord.PrivateChannelId) Evergreen.V228.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V228.OneToOne.OneToOne (Evergreen.V228.Slack.Id Evergreen.V228.Slack.ChannelId) Evergreen.V228.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V228.OneToOne.OneToOne String (Evergreen.V228.Id.Id Evergreen.V228.Id.GuildId)
    , slackUsers : Evergreen.V228.OneToOne.OneToOne (Evergreen.V228.Slack.Id Evergreen.V228.Slack.UserId) (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId)
    , slackServers : Evergreen.V228.OneToOne.OneToOne (Evergreen.V228.Slack.Id Evergreen.V228.Slack.TeamId) (Evergreen.V228.Id.Id Evergreen.V228.Id.GuildId)
    , slackToken : Maybe Evergreen.V228.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V228.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V228.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V228.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V228.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId) Evergreen.V228.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId, Evergreen.V228.Discord.Id Evergreen.V228.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V228.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V228.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V228.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V228.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId) (Evergreen.V228.LocalState.LoadingDiscordChannel (List Evergreen.V228.Discord.Message))
    , signupsEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V228.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.Id.StickerId) Evergreen.V228.Sticker.StickerData
    , discordStickers : Evergreen.V228.OneToOne.OneToOne (Evergreen.V228.Discord.Id Evergreen.V228.Discord.StickerId) (Evergreen.V228.Id.Id Evergreen.V228.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.Id.CustomEmojiId) Evergreen.V228.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V228.OneToOne.OneToOne Evergreen.V228.RichText.DiscordCustomEmojiIdAndName (Evergreen.V228.Id.Id Evergreen.V228.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V228.Postmark.ApiKey
    , serverSecret : Evergreen.V228.SecretId.SecretId Evergreen.V228.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V228.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V228.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V228.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V228.Route.Route
    | SelectedFilesToAttach ( Evergreen.V228.Id.AnyGuildOrDmId, Evergreen.V228.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V228.Id.Id Evergreen.V228.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V228.Id.Id Evergreen.V228.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V228.Id.Id Evergreen.V228.Id.GuildId) (Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelId) Evergreen.V228.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V228.Id.Id Evergreen.V228.Id.GuildId) (Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelId) Evergreen.V228.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V228.Discord.Id Evergreen.V228.Discord.GuildId) (Evergreen.V228.Discord.Id Evergreen.V228.Discord.ChannelId) Evergreen.V228.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V228.Discord.Id Evergreen.V228.Discord.GuildId) (Evergreen.V228.Discord.Id Evergreen.V228.Discord.ChannelId) Evergreen.V228.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V228.Id.Id Evergreen.V228.Id.GuildId) (Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V228.Id.Id Evergreen.V228.Id.GuildId) (Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V228.Id.Id Evergreen.V228.Id.GuildId) (Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V228.Id.Id Evergreen.V228.Id.GuildId) (Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V228.Id.Id Evergreen.V228.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V228.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V228.Id.AnyGuildOrDmId Evergreen.V228.Id.ThreadRouteWithMessage (Evergreen.V228.Coord.Coord Evergreen.V228.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V228.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V228.Id.AnyGuildOrDmId Evergreen.V228.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V228.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V228.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V228.Id.AnyGuildOrDmId, Evergreen.V228.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V228.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V228.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V228.Id.AnyGuildOrDmId, Evergreen.V228.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V228.NonemptyDict.NonemptyDict Int Evergreen.V228.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V228.NonemptyDict.NonemptyDict Int Evergreen.V228.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V228.Id.AnyGuildOrDmId Evergreen.V228.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V228.Id.AnyGuildOrDmId Evergreen.V228.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V228.NonemptySet.NonemptySet (Evergreen.V228.Id.Id Evergreen.V228.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V228.Id.AnyGuildOrDmId, Evergreen.V228.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V228.Id.AnyGuildOrDmId Evergreen.V228.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V228.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V228.AiChat.Msg
    | GoMsg Evergreen.V228.Go.Msg
    | UserNameEditableMsg (Evergreen.V228.Editable.Msg Evergreen.V228.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V228.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V228.Id.Id Evergreen.V228.Id.GuildId) Evergreen.V228.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V228.Id.AnyGuildOrDmId, Evergreen.V228.Id.ThreadRoute ) (Evergreen.V228.Id.Id Evergreen.V228.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V228.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V228.Id.AnyGuildOrDmId, Evergreen.V228.Id.ThreadRoute ) (Evergreen.V228.Id.Id Evergreen.V228.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V228.Id.AnyGuildOrDmId, Evergreen.V228.Id.ThreadRoute ) (Evergreen.V228.Id.Id Evergreen.V228.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V228.Id.AnyGuildOrDmId, Evergreen.V228.Id.ThreadRoute )
        { fileId : Evergreen.V228.Id.Id Evergreen.V228.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V228.Id.AnyGuildOrDmId, Evergreen.V228.Id.ThreadRoute ) (Evergreen.V228.Id.Id Evergreen.V228.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V228.Id.AnyGuildOrDmId, Evergreen.V228.Id.ThreadRoute ) (Evergreen.V228.Id.Id Evergreen.V228.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V228.Id.AnyGuildOrDmId, Evergreen.V228.Id.ThreadRoute )
        { fileId : Evergreen.V228.Id.Id Evergreen.V228.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V228.Id.AnyGuildOrDmId, Evergreen.V228.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V228.Id.AnyGuildOrDmId, Evergreen.V228.Id.ThreadRoute ) (Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelMessageId) (Evergreen.V228.Id.Id Evergreen.V228.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V228.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V228.Id.AnyGuildOrDmId, Evergreen.V228.Id.ThreadRoute ) (Evergreen.V228.Id.Id Evergreen.V228.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V228.Id.AnyGuildOrDmId Evergreen.V228.Id.ThreadRouteWithMessage Evergreen.V228.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V228.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V228.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V228.Id.Id Evergreen.V228.Id.GuildId) Evergreen.V228.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId) (Evergreen.V228.Discord.Id Evergreen.V228.Discord.GuildId) Evergreen.V228.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V228.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V228.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId
        , otherUserId : Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V228.Id.AnyGuildOrDmId Evergreen.V228.Id.ThreadRoute Evergreen.V228.MessageInput.Msg
    | MessageInputMsg Evergreen.V228.Id.AnyGuildOrDmId Evergreen.V228.Id.ThreadRoute Evergreen.V228.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V228.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V228.Range.Range, Evergreen.V228.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V228.Range.Range, Evergreen.V228.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V228.Call.FromJs)
    | VoiceChatMsg Evergreen.V228.Call.Msg
    | PressedChannelHeaderTab Evergreen.V228.Route.DmChannelHeaderTab
    | FileDragEnter
    | FileDragLeave
    | FileDropped (List Effect.File.File)


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V228.Id.Id Evergreen.V228.Id.GuildId) (Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelId) Evergreen.V228.Id.ThreadRoute
    | InitialLoadRequested_Dm Evergreen.V228.DmChannel.DmChannelId Evergreen.V228.Id.ThreadRoute
    | InitialLoadRequested_Discord Evergreen.V228.Id.DiscordGuildOrDmId Evergreen.V228.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V228.Id.Id Evergreen.V228.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V228.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V228.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V228.Untrusted.Untrusted Evergreen.V228.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V228.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V228.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V228.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V228.Id.Id Evergreen.V228.Id.GuildId) (Evergreen.V228.SecretId.SecretId Evergreen.V228.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V228.PersonName.PersonName Evergreen.V228.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V228.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V228.Slack.OAuthCode Evergreen.V228.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V228.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V228.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V228.Id.Id Evergreen.V228.Pagination.PageId))


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V228.Discord.Id Evergreen.V228.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V228.Discord.Id Evergreen.V228.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V228.EmailAddress.EmailAddress (Result Evergreen.V228.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V228.EmailAddress.EmailAddress (Result Evergreen.V228.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId) Evergreen.V228.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V228.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V228.Discord.Id Evergreen.V228.Discord.GuildId) (Evergreen.V228.Discord.Id Evergreen.V228.Discord.ChannelId) Evergreen.V228.Id.ThreadRouteWithMaybeMessage (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId) (Result Evergreen.V228.Discord.HttpError Evergreen.V228.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V228.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V228.Discord.Id Evergreen.V228.Discord.PrivateChannelId) (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId) (Result Evergreen.V228.Discord.HttpError Evergreen.V228.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V228.Discord.Id Evergreen.V228.Discord.GuildId) (Evergreen.V228.Discord.Id Evergreen.V228.Discord.ChannelId) Evergreen.V228.Id.ThreadRouteWithMessage (Evergreen.V228.Discord.Id Evergreen.V228.Discord.MessageId) (Result Evergreen.V228.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V228.Discord.Id Evergreen.V228.Discord.PrivateChannelId) (Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelMessageId) (Evergreen.V228.Discord.Id Evergreen.V228.Discord.MessageId) (Result Evergreen.V228.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V228.Discord.Id Evergreen.V228.Discord.GuildId) (Evergreen.V228.Discord.Id Evergreen.V228.Discord.ChannelId) Evergreen.V228.Id.ThreadRouteWithMessage (Evergreen.V228.Discord.Id Evergreen.V228.Discord.MessageId) (Result Evergreen.V228.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V228.Discord.Id Evergreen.V228.Discord.PrivateChannelId) (Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelMessageId) (Evergreen.V228.Discord.Id Evergreen.V228.Discord.MessageId) (Result Evergreen.V228.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V228.Discord.Id Evergreen.V228.Discord.GuildId) (Evergreen.V228.Discord.Id Evergreen.V228.Discord.ChannelId) Evergreen.V228.Id.ThreadRouteWithMessage (Evergreen.V228.Discord.Id Evergreen.V228.Discord.MessageId) Evergreen.V228.Emoji.EmojiOrCustomEmoji (Result Evergreen.V228.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V228.Discord.Id Evergreen.V228.Discord.PrivateChannelId) (Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelMessageId) (Evergreen.V228.Discord.Id Evergreen.V228.Discord.MessageId) Evergreen.V228.Emoji.EmojiOrCustomEmoji (Result Evergreen.V228.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V228.Discord.Id Evergreen.V228.Discord.GuildId) (Evergreen.V228.Discord.Id Evergreen.V228.Discord.ChannelId) Evergreen.V228.Id.ThreadRouteWithMessage (Evergreen.V228.Discord.Id Evergreen.V228.Discord.MessageId) Evergreen.V228.Emoji.EmojiOrCustomEmoji (Result Evergreen.V228.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V228.Discord.Id Evergreen.V228.Discord.PrivateChannelId) (Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelMessageId) (Evergreen.V228.Discord.Id Evergreen.V228.Discord.MessageId) Evergreen.V228.Emoji.EmojiOrCustomEmoji (Result Evergreen.V228.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V228.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V228.Discord.HttpError (List ( Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId, Maybe Evergreen.V228.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V228.Slack.CurrentUser
            , team : Evergreen.V228.Slack.Team
            , users : List Evergreen.V228.Slack.User
            , channels : List ( Evergreen.V228.Slack.Channel, List Evergreen.V228.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId) (Result Effect.Http.Error Evergreen.V228.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId) Evergreen.V228.Discord.UserAuth (Result Evergreen.V228.Discord.HttpError Evergreen.V228.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId) (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId) (Result Evergreen.V228.Discord.HttpError Evergreen.V228.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId)
        (Result
            Evergreen.V228.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V228.Discord.Id Evergreen.V228.Discord.PrivateChannelId
                , members : List (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId)
                }
            , List
                ( Evergreen.V228.Discord.Id Evergreen.V228.Discord.GuildId
                , { guild : Evergreen.V228.Discord.GatewayGuild
                  , channels : List Evergreen.V228.Discord.Channel
                  , icon : Maybe Evergreen.V228.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId) Bool
    | WebsocketSentDataForUser (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V228.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V228.Discord.Id Evergreen.V228.Discord.AttachmentId, Evergreen.V228.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V228.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V228.Discord.Id Evergreen.V228.Discord.AttachmentId, Evergreen.V228.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId) (Evergreen.V228.Discord.Id Evergreen.V228.Discord.GuildId) (Evergreen.V228.Discord.Id Evergreen.V228.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V228.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V228.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId) (Evergreen.V228.Discord.Id Evergreen.V228.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V228.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V228.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId) (Evergreen.V228.Discord.Id Evergreen.V228.Discord.GuildId) (Evergreen.V228.Discord.Id Evergreen.V228.Discord.ChannelId) (Result Evergreen.V228.Discord.HttpError (List Evergreen.V228.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId) (Evergreen.V228.Discord.Id Evergreen.V228.Discord.PrivateChannelId) (Result Evergreen.V228.Discord.HttpError (List Evergreen.V228.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V228.Id.Id Evergreen.V228.Id.GuildId) (Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelId) Evergreen.V228.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V228.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V228.DmChannel.DmChannelId Evergreen.V228.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V228.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V228.Discord.Id Evergreen.V228.Discord.GuildId) (Evergreen.V228.Discord.Id Evergreen.V228.Discord.ChannelId) Evergreen.V228.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V228.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V228.Discord.Id Evergreen.V228.Discord.PrivateChannelId) (Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V228.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId)
        (Evergreen.V228.Discord.Id Evergreen.V228.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V228.Discord.HttpError
            { guild : Evergreen.V228.Discord.GatewayGuild
            , channels : List Evergreen.V228.Discord.Channel
            , icon : Maybe Evergreen.V228.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V228.Discord.Id Evergreen.V228.Discord.GuildId) (Result Evergreen.V228.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V228.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId) (List ( Evergreen.V228.Id.Id Evergreen.V228.Id.StickerId, Result Effect.Http.Error Evergreen.V228.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V228.Id.Id Evergreen.V228.Id.StickerId, Result Effect.Http.Error Evergreen.V228.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId) (List ( Evergreen.V228.Id.Id Evergreen.V228.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V228.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V228.Id.Id Evergreen.V228.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V228.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V228.Discord.HttpError (List Evergreen.V228.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V228.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V228.SecretId.SecretId Evergreen.V228.SecretId.ServerSecret))
