module Evergreen.V229.Types exposing (..)

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
import Evergreen.V229.AiChat
import Evergreen.V229.Call
import Evergreen.V229.ChannelDescription
import Evergreen.V229.ChannelName
import Evergreen.V229.Coord
import Evergreen.V229.CssPixels
import Evergreen.V229.CustomEmoji
import Evergreen.V229.Discord
import Evergreen.V229.DiscordAttachmentId
import Evergreen.V229.DiscordUserData
import Evergreen.V229.DmChannel
import Evergreen.V229.Editable
import Evergreen.V229.EmailAddress
import Evergreen.V229.Embed
import Evergreen.V229.Emoji
import Evergreen.V229.FileStatus
import Evergreen.V229.Go
import Evergreen.V229.GuildName
import Evergreen.V229.Id
import Evergreen.V229.ImageEditor
import Evergreen.V229.Local
import Evergreen.V229.LocalState
import Evergreen.V229.Log
import Evergreen.V229.LoginForm
import Evergreen.V229.MembersAndOwner
import Evergreen.V229.Message
import Evergreen.V229.MessageInput
import Evergreen.V229.MessageView
import Evergreen.V229.NonemptyDict
import Evergreen.V229.NonemptySet
import Evergreen.V229.OneToOne
import Evergreen.V229.Pages.Admin
import Evergreen.V229.Pagination
import Evergreen.V229.PersonName
import Evergreen.V229.Ports
import Evergreen.V229.Postmark
import Evergreen.V229.Range
import Evergreen.V229.RichText
import Evergreen.V229.Route
import Evergreen.V229.SecretId
import Evergreen.V229.SessionIdHash
import Evergreen.V229.Slack
import Evergreen.V229.Sticker
import Evergreen.V229.TextEditor
import Evergreen.V229.ToBackendLog
import Evergreen.V229.Touch
import Evergreen.V229.TwoFactorAuthentication
import Evergreen.V229.Ui.Anim
import Evergreen.V229.Untrusted
import Evergreen.V229.User
import Evergreen.V229.UserAgent
import Evergreen.V229.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V229.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V229.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.Id.GuildId) Evergreen.V229.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId) Evergreen.V229.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V229.Discord.Id Evergreen.V229.Discord.PrivateChannelId) Evergreen.V229.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V229.Discord.Id Evergreen.V229.Discord.GuildId) Evergreen.V229.LocalState.DiscordFrontendGuild
    , user : Evergreen.V229.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId) Evergreen.V229.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId) Evergreen.V229.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId) Evergreen.V229.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V229.SessionIdHash.SessionIdHash Evergreen.V229.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V229.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.Id.StickerId) Evergreen.V229.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.Id.CustomEmojiId) Evergreen.V229.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V229.Call.RoomId (Evergreen.V229.NonemptySet.NonemptySet ( Evergreen.V229.Id.Id Evergreen.V229.Id.UserId, Effect.Lamdera.ClientId ))
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V229.Route.Route
    , windowSize : Evergreen.V229.Coord.Coord Evergreen.V229.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V229.Ports.NotificationPermission
    , pwaStatus : Evergreen.V229.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V229.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V229.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V229.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V229.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.FileStatus.FileId) Evergreen.V229.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V229.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V229.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.FileStatus.FileId) Evergreen.V229.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V229.Id.Id Evergreen.V229.Id.GuildId) Evergreen.V229.ChannelName.ChannelName Evergreen.V229.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V229.Id.Id Evergreen.V229.Id.GuildId) (Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelId) Evergreen.V229.ChannelName.ChannelName Evergreen.V229.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V229.Id.Id Evergreen.V229.Id.GuildId) (Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V229.Id.Id Evergreen.V229.Id.GuildId) (Evergreen.V229.UserSession.ToBeFilledInByBackend (Evergreen.V229.SecretId.SecretId Evergreen.V229.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V229.GuildName.GuildName (Evergreen.V229.UserSession.ToBeFilledInByBackend (Evergreen.V229.Id.Id Evergreen.V229.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V229.Id.AnyGuildOrDmId, Evergreen.V229.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V229.Id.AnyGuildOrDmId Evergreen.V229.Id.ThreadRouteWithMessage Evergreen.V229.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V229.Id.AnyGuildOrDmId Evergreen.V229.Id.ThreadRouteWithMessage Evergreen.V229.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V229.Id.GuildOrDmId Evergreen.V229.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.FileStatus.FileId) Evergreen.V229.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId) (Evergreen.V229.Discord.Id Evergreen.V229.Discord.GuildId) (Evergreen.V229.Discord.Id Evergreen.V229.Discord.ChannelId) Evergreen.V229.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V229.Id.DiscordGuildOrDmId_DmData (Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V229.Id.AnyGuildOrDmId Evergreen.V229.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V229.Id.AnyGuildOrDmId Evergreen.V229.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V229.Id.AnyGuildOrDmId Evergreen.V229.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V229.UserSession.SetViewing
    | Local_SetName Evergreen.V229.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V229.Id.GuildOrDmId (Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelMessageId) (Evergreen.V229.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelMessageId) (Evergreen.V229.Message.Message Evergreen.V229.Id.ChannelMessageId (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V229.Id.GuildOrDmId (Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelMessageId) (Evergreen.V229.Id.Id Evergreen.V229.Id.ThreadMessageId) (Evergreen.V229.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.Id.ThreadMessageId) (Evergreen.V229.Message.Message Evergreen.V229.Id.ThreadMessageId (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V229.Id.DiscordGuildOrDmId (Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelMessageId) (Evergreen.V229.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelMessageId) (Evergreen.V229.Message.Message Evergreen.V229.Id.ChannelMessageId (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V229.Id.DiscordGuildOrDmId (Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelMessageId) (Evergreen.V229.Id.Id Evergreen.V229.Id.ThreadMessageId) (Evergreen.V229.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.Id.ThreadMessageId) (Evergreen.V229.Message.Message Evergreen.V229.Id.ThreadMessageId (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V229.Id.Id Evergreen.V229.Id.GuildId) Evergreen.V229.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId) (Evergreen.V229.Discord.Id Evergreen.V229.Discord.GuildId) Evergreen.V229.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V229.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V229.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V229.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V229.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V229.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V229.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V229.NonemptySet.NonemptySet (Evergreen.V229.Id.Id Evergreen.V229.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V229.Call.LocalChange
    | Local_Go
        { otherUserId : Evergreen.V229.Id.Id Evergreen.V229.Id.UserId
        }
        Evergreen.V229.Go.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId) Effect.Time.Posix Evergreen.V229.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V229.RichText.RichText (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId))) Evergreen.V229.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.FileStatus.FileId) Evergreen.V229.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.Id.StickerId) Evergreen.V229.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V229.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V229.RichText.RichText (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId))) Evergreen.V229.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.FileStatus.FileId) Evergreen.V229.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.Id.StickerId) Evergreen.V229.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V229.Id.Id Evergreen.V229.Id.GuildId) Evergreen.V229.ChannelName.ChannelName Evergreen.V229.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V229.Id.Id Evergreen.V229.Id.GuildId) (Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelId) Evergreen.V229.ChannelName.ChannelName Evergreen.V229.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V229.Id.Id Evergreen.V229.Id.GuildId) (Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId) (Evergreen.V229.Id.Id Evergreen.V229.Id.GuildId) (Evergreen.V229.SecretId.SecretId Evergreen.V229.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId) (Evergreen.V229.Id.Id Evergreen.V229.Id.GuildId) Evergreen.V229.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V229.LocalState.JoinGuildError
            { guildId : Evergreen.V229.Id.Id Evergreen.V229.Id.GuildId
            , guild : Evergreen.V229.LocalState.FrontendGuild
            , owner : Evergreen.V229.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId) Evergreen.V229.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId) Evergreen.V229.Id.GuildOrDmId Evergreen.V229.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId) (Evergreen.V229.Discord.Id Evergreen.V229.Discord.GuildId) (Evergreen.V229.Discord.Id Evergreen.V229.Discord.ChannelId) Evergreen.V229.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId) (Evergreen.V229.Discord.Id Evergreen.V229.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId) Evergreen.V229.Id.GuildOrDmId Evergreen.V229.Id.ThreadRouteWithMessage Evergreen.V229.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId) Evergreen.V229.Id.GuildOrDmId Evergreen.V229.Id.ThreadRouteWithMessage Evergreen.V229.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId) (Evergreen.V229.Discord.Id Evergreen.V229.Discord.GuildId) (Evergreen.V229.Discord.Id Evergreen.V229.Discord.ChannelId) Evergreen.V229.Id.ThreadRouteWithMessage Evergreen.V229.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId) (Evergreen.V229.Discord.Id Evergreen.V229.Discord.PrivateChannelId) (Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelMessageId) Evergreen.V229.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId) (Evergreen.V229.Discord.Id Evergreen.V229.Discord.GuildId) (Evergreen.V229.Discord.Id Evergreen.V229.Discord.ChannelId) Evergreen.V229.Id.ThreadRouteWithMessage Evergreen.V229.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId) (Evergreen.V229.Discord.Id Evergreen.V229.Discord.PrivateChannelId) (Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelMessageId) Evergreen.V229.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId) Evergreen.V229.Id.GuildOrDmId Evergreen.V229.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V229.RichText.RichText (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId))) (SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.FileStatus.FileId) Evergreen.V229.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId) (Evergreen.V229.Discord.Id Evergreen.V229.Discord.GuildId) (Evergreen.V229.Discord.Id Evergreen.V229.Discord.ChannelId) Evergreen.V229.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V229.RichText.RichText (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V229.Id.DiscordGuildOrDmId_DmData (Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V229.RichText.RichText (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId) Evergreen.V229.Id.AnyGuildOrDmId Evergreen.V229.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V229.Id.AnyGuildOrDmId Evergreen.V229.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V229.Discord.Id Evergreen.V229.Discord.GuildId) (Evergreen.V229.Discord.Id Evergreen.V229.Discord.ChannelId) Evergreen.V229.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V229.Discord.Id Evergreen.V229.Discord.PrivateChannelId) (Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId) Evergreen.V229.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId) Evergreen.V229.FileStatus.FileHash
    | Server_SetGuildIcon (Evergreen.V229.Id.Id Evergreen.V229.Id.GuildId) Evergreen.V229.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V229.Id.Id Evergreen.V229.Id.GuildId) Evergreen.V229.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V229.Discord.Id Evergreen.V229.Discord.GuildId) Evergreen.V229.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V229.SessionIdHash.SessionIdHash Evergreen.V229.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V229.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V229.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V229.Id.AnyGuildOrDmId, Evergreen.V229.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V229.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId) Evergreen.V229.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V229.Discord.Id Evergreen.V229.Discord.GuildId) (Evergreen.V229.Discord.Id Evergreen.V229.Discord.ChannelId) Evergreen.V229.ChannelName.ChannelName (Evergreen.V229.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V229.Discord.Id Evergreen.V229.Discord.PrivateChannelId)
        (Evergreen.V229.NonemptyDict.NonemptyDict
            (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V229.Discord.Id Evergreen.V229.Discord.GuildId) Evergreen.V229.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V229.Discord.Id Evergreen.V229.Discord.PrivateChannelId) Evergreen.V229.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId) Evergreen.V229.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId) (Maybe (Evergreen.V229.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V229.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V229.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V229.Id.Id Evergreen.V229.Id.GuildId) (Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelId) Evergreen.V229.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V229.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId) Evergreen.V229.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V229.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V229.Discord.Id Evergreen.V229.Discord.GuildId) (Evergreen.V229.Discord.Id Evergreen.V229.Discord.ChannelId) Evergreen.V229.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V229.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V229.Discord.Id Evergreen.V229.Discord.PrivateChannelId) (Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V229.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V229.Discord.Id Evergreen.V229.Discord.GuildId) Evergreen.V229.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V229.Discord.Id Evergreen.V229.Discord.GuildId) (Evergreen.V229.Discord.Id Evergreen.V229.Discord.ChannelId) (Evergreen.V229.Discord.OptionalData String) (Evergreen.V229.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V229.Discord.Id Evergreen.V229.Discord.GuildId)
        (Evergreen.V229.MembersAndOwner.MembersAndOwner
            (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V229.Discord.Id Evergreen.V229.Discord.GuildId) (Evergreen.V229.Discord.Id Evergreen.V229.Discord.ChannelId) (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId) Evergreen.V229.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.Id.StickerId) Evergreen.V229.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.Id.CustomEmojiId) Evergreen.V229.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V229.Call.ServerChange
    | Server_Go
        (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId)
        { otherUserId : Evergreen.V229.Id.Id Evergreen.V229.Id.UserId
        }
        Evergreen.V229.Go.LocalChange


type LocalMsg
    = LocalChange (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V229.Id.Id Evergreen.V229.Id.GuildId) (Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelId) Evergreen.V229.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V229.Discord.Id Evergreen.V229.Discord.GuildId) (Evergreen.V229.Discord.Id Evergreen.V229.Discord.ChannelId) Evergreen.V229.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.FileStatus.FileId) Evergreen.V229.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V229.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V229.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V229.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V229.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V229.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V229.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V229.Coord.Coord Evergreen.V229.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V229.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V229.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V229.Id.AnyGuildOrDmId Evergreen.V229.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V229.Id.AnyGuildOrDmId Evergreen.V229.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V229.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V229.Coord.Coord Evergreen.V229.CssPixels.CssPixels) (Maybe Evergreen.V229.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V229.Id.AnyGuildOrDmId, Evergreen.V229.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelMessageId) (Evergreen.V229.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.Id.ThreadMessageId) (Evergreen.V229.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V229.Editable.Model
    , showLinkDiscordSetup : Bool
    , domainWhitelistInput : String
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V229.Local.Local LocalMsg Evergreen.V229.LocalState.LocalState
    , admin : Evergreen.V229.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V229.Id.AnyGuildOrDmId, Evergreen.V229.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V229.Id.Id Evergreen.V229.Id.GuildId, Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelId ) EditChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V229.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V229.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V229.Id.AnyGuildOrDmId, Evergreen.V229.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V229.Id.AnyGuildOrDmId, Evergreen.V229.Id.ThreadRoute ) (Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : Evergreen.V229.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V229.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V229.Id.AnyGuildOrDmId, Evergreen.V229.Id.ThreadRoute ) (Evergreen.V229.NonemptyDict.NonemptyDict (Evergreen.V229.Id.Id Evergreen.V229.FileStatus.FileId) Evergreen.V229.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V229.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V229.TextEditor.Model
    , profilePictureEditor : Evergreen.V229.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V229.Id.Id Evergreen.V229.Id.GuildId, Evergreen.V229.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V229.Emoji.Model
    , voiceChat : Evergreen.V229.Call.Model
    , currentDmGoMatch : SeqDict.SeqDict ( Evergreen.V229.Id.Id Evergreen.V229.Id.UserId, Maybe (Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelMessageId) ) Evergreen.V229.Go.Model
    , fileDragOverCount : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V229.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V229.SecretId.SecretId Evergreen.V229.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V229.Range.Range
                , direction : Evergreen.V229.Range.SelectionDirection
                }
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V229.NonemptyDict.NonemptyDict Int Evergreen.V229.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V229.NonemptyDict.NonemptyDict Int Evergreen.V229.Touch.Touch
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
    | AdminToFrontend Evergreen.V229.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V229.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V229.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V229.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V229.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V229.ImageEditor.ToFrontend


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V229.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V229.Coord.Coord Evergreen.V229.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V229.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , notificationPermission : Evergreen.V229.Ports.NotificationPermission
    , pwaStatus : Evergreen.V229.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V229.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V229.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V229.Emoji.CachedEmojiData
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V229.Id.Id Evergreen.V229.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V229.Id.Id Evergreen.V229.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V229.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V229.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V229.Coord.Coord Evergreen.V229.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V229.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V229.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V229.Id.Id Evergreen.V229.Id.GuildId, Evergreen.V229.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V229.DmChannel.DmChannelId, Evergreen.V229.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V229.Discord.Id Evergreen.V229.Discord.GuildId, Evergreen.V229.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V229.Discord.Id Evergreen.V229.Discord.PrivateChannelId, Evergreen.V229.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V229.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V229.NonemptyDict.NonemptyDict (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId) Evergreen.V229.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V229.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V229.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V229.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V229.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId) Evergreen.V229.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId) Evergreen.V229.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.Id.GuildId) Evergreen.V229.LocalState.BackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V229.Discord.Id Evergreen.V229.Discord.GuildId) Evergreen.V229.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V229.DmChannel.DmChannelId Evergreen.V229.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V229.Discord.Id Evergreen.V229.Discord.PrivateChannelId) Evergreen.V229.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V229.OneToOne.OneToOne (Evergreen.V229.Slack.Id Evergreen.V229.Slack.ChannelId) Evergreen.V229.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V229.OneToOne.OneToOne String (Evergreen.V229.Id.Id Evergreen.V229.Id.GuildId)
    , slackUsers : Evergreen.V229.OneToOne.OneToOne (Evergreen.V229.Slack.Id Evergreen.V229.Slack.UserId) (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId)
    , slackServers : Evergreen.V229.OneToOne.OneToOne (Evergreen.V229.Slack.Id Evergreen.V229.Slack.TeamId) (Evergreen.V229.Id.Id Evergreen.V229.Id.GuildId)
    , slackToken : Maybe Evergreen.V229.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V229.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V229.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V229.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V229.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId) Evergreen.V229.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId, Evergreen.V229.Discord.Id Evergreen.V229.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V229.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V229.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V229.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V229.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId) (Evergreen.V229.LocalState.LoadingDiscordChannel (List Evergreen.V229.Discord.Message))
    , signupsEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V229.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.Id.StickerId) Evergreen.V229.Sticker.StickerData
    , discordStickers : Evergreen.V229.OneToOne.OneToOne (Evergreen.V229.Discord.Id Evergreen.V229.Discord.StickerId) (Evergreen.V229.Id.Id Evergreen.V229.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.Id.CustomEmojiId) Evergreen.V229.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V229.OneToOne.OneToOne Evergreen.V229.RichText.DiscordCustomEmojiIdAndName (Evergreen.V229.Id.Id Evergreen.V229.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V229.Postmark.ApiKey
    , serverSecret : Evergreen.V229.SecretId.SecretId Evergreen.V229.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V229.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V229.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V229.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V229.Route.Route
    | SelectedFilesToAttach ( Evergreen.V229.Id.AnyGuildOrDmId, Evergreen.V229.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V229.Id.Id Evergreen.V229.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V229.Id.Id Evergreen.V229.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V229.Id.Id Evergreen.V229.Id.GuildId) (Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelId) Evergreen.V229.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V229.Id.Id Evergreen.V229.Id.GuildId) (Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelId) Evergreen.V229.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V229.Discord.Id Evergreen.V229.Discord.GuildId) (Evergreen.V229.Discord.Id Evergreen.V229.Discord.ChannelId) Evergreen.V229.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V229.Discord.Id Evergreen.V229.Discord.GuildId) (Evergreen.V229.Discord.Id Evergreen.V229.Discord.ChannelId) Evergreen.V229.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V229.Id.Id Evergreen.V229.Id.GuildId) (Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V229.Id.Id Evergreen.V229.Id.GuildId) (Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V229.Id.Id Evergreen.V229.Id.GuildId) (Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V229.Id.Id Evergreen.V229.Id.GuildId) (Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V229.Id.Id Evergreen.V229.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V229.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V229.Id.AnyGuildOrDmId Evergreen.V229.Id.ThreadRouteWithMessage (Evergreen.V229.Coord.Coord Evergreen.V229.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V229.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V229.Id.AnyGuildOrDmId Evergreen.V229.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V229.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V229.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V229.Id.AnyGuildOrDmId, Evergreen.V229.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V229.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V229.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V229.Id.AnyGuildOrDmId, Evergreen.V229.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V229.NonemptyDict.NonemptyDict Int Evergreen.V229.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V229.NonemptyDict.NonemptyDict Int Evergreen.V229.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V229.Id.AnyGuildOrDmId Evergreen.V229.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V229.Id.AnyGuildOrDmId Evergreen.V229.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V229.NonemptySet.NonemptySet (Evergreen.V229.Id.Id Evergreen.V229.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V229.Id.AnyGuildOrDmId, Evergreen.V229.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V229.Id.AnyGuildOrDmId Evergreen.V229.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V229.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V229.AiChat.Msg
    | GoMsg Evergreen.V229.Go.Msg
    | UserNameEditableMsg (Evergreen.V229.Editable.Msg Evergreen.V229.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V229.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V229.Id.Id Evergreen.V229.Id.GuildId) Evergreen.V229.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V229.Id.AnyGuildOrDmId, Evergreen.V229.Id.ThreadRoute ) (Evergreen.V229.Id.Id Evergreen.V229.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V229.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V229.Id.AnyGuildOrDmId, Evergreen.V229.Id.ThreadRoute ) (Evergreen.V229.Id.Id Evergreen.V229.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V229.Id.AnyGuildOrDmId, Evergreen.V229.Id.ThreadRoute ) (Evergreen.V229.Id.Id Evergreen.V229.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V229.Id.AnyGuildOrDmId, Evergreen.V229.Id.ThreadRoute )
        { fileId : Evergreen.V229.Id.Id Evergreen.V229.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V229.Id.AnyGuildOrDmId, Evergreen.V229.Id.ThreadRoute ) (Evergreen.V229.Id.Id Evergreen.V229.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V229.Id.AnyGuildOrDmId, Evergreen.V229.Id.ThreadRoute ) (Evergreen.V229.Id.Id Evergreen.V229.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V229.Id.AnyGuildOrDmId, Evergreen.V229.Id.ThreadRoute )
        { fileId : Evergreen.V229.Id.Id Evergreen.V229.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V229.Id.AnyGuildOrDmId, Evergreen.V229.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V229.Id.AnyGuildOrDmId, Evergreen.V229.Id.ThreadRoute ) (Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelMessageId) (Evergreen.V229.Id.Id Evergreen.V229.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V229.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V229.Id.AnyGuildOrDmId, Evergreen.V229.Id.ThreadRoute ) (Evergreen.V229.Id.Id Evergreen.V229.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V229.Id.AnyGuildOrDmId Evergreen.V229.Id.ThreadRouteWithMessage Evergreen.V229.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V229.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V229.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V229.Id.Id Evergreen.V229.Id.GuildId) Evergreen.V229.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId) (Evergreen.V229.Discord.Id Evergreen.V229.Discord.GuildId) Evergreen.V229.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V229.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V229.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId
        , otherUserId : Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V229.Id.AnyGuildOrDmId Evergreen.V229.Id.ThreadRoute Evergreen.V229.MessageInput.Msg
    | MessageInputMsg Evergreen.V229.Id.AnyGuildOrDmId Evergreen.V229.Id.ThreadRoute Evergreen.V229.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V229.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V229.Range.Range, Evergreen.V229.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V229.Range.Range, Evergreen.V229.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V229.Call.FromJs)
    | VoiceChatMsg Evergreen.V229.Call.Msg
    | PressedChannelHeaderTab Evergreen.V229.Route.DmChannelHeaderTab
    | FileDragEnter
    | FileDragLeave
    | FileDropped (List Effect.File.File)


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V229.Id.Id Evergreen.V229.Id.GuildId) (Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelId) Evergreen.V229.Id.ThreadRoute
    | InitialLoadRequested_Dm Evergreen.V229.DmChannel.DmChannelId Evergreen.V229.Id.ThreadRoute
    | InitialLoadRequested_Discord Evergreen.V229.Id.DiscordGuildOrDmId Evergreen.V229.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V229.Id.Id Evergreen.V229.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V229.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V229.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V229.Untrusted.Untrusted Evergreen.V229.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V229.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V229.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V229.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V229.Id.Id Evergreen.V229.Id.GuildId) (Evergreen.V229.SecretId.SecretId Evergreen.V229.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V229.PersonName.PersonName Evergreen.V229.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V229.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V229.Slack.OAuthCode Evergreen.V229.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V229.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V229.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V229.Id.Id Evergreen.V229.Pagination.PageId))


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V229.Discord.Id Evergreen.V229.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V229.Discord.Id Evergreen.V229.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V229.EmailAddress.EmailAddress (Result Evergreen.V229.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V229.EmailAddress.EmailAddress (Result Evergreen.V229.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId) Evergreen.V229.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V229.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V229.Discord.Id Evergreen.V229.Discord.GuildId) (Evergreen.V229.Discord.Id Evergreen.V229.Discord.ChannelId) Evergreen.V229.Id.ThreadRouteWithMaybeMessage (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId) (Result Evergreen.V229.Discord.HttpError Evergreen.V229.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V229.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V229.Discord.Id Evergreen.V229.Discord.PrivateChannelId) (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId) (Result Evergreen.V229.Discord.HttpError Evergreen.V229.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V229.Discord.Id Evergreen.V229.Discord.GuildId) (Evergreen.V229.Discord.Id Evergreen.V229.Discord.ChannelId) Evergreen.V229.Id.ThreadRouteWithMessage (Evergreen.V229.Discord.Id Evergreen.V229.Discord.MessageId) (Result Evergreen.V229.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V229.Discord.Id Evergreen.V229.Discord.PrivateChannelId) (Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelMessageId) (Evergreen.V229.Discord.Id Evergreen.V229.Discord.MessageId) (Result Evergreen.V229.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V229.Discord.Id Evergreen.V229.Discord.GuildId) (Evergreen.V229.Discord.Id Evergreen.V229.Discord.ChannelId) Evergreen.V229.Id.ThreadRouteWithMessage (Evergreen.V229.Discord.Id Evergreen.V229.Discord.MessageId) (Result Evergreen.V229.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V229.Discord.Id Evergreen.V229.Discord.PrivateChannelId) (Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelMessageId) (Evergreen.V229.Discord.Id Evergreen.V229.Discord.MessageId) (Result Evergreen.V229.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V229.Discord.Id Evergreen.V229.Discord.GuildId) (Evergreen.V229.Discord.Id Evergreen.V229.Discord.ChannelId) Evergreen.V229.Id.ThreadRouteWithMessage (Evergreen.V229.Discord.Id Evergreen.V229.Discord.MessageId) Evergreen.V229.Emoji.EmojiOrCustomEmoji (Result Evergreen.V229.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V229.Discord.Id Evergreen.V229.Discord.PrivateChannelId) (Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelMessageId) (Evergreen.V229.Discord.Id Evergreen.V229.Discord.MessageId) Evergreen.V229.Emoji.EmojiOrCustomEmoji (Result Evergreen.V229.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V229.Discord.Id Evergreen.V229.Discord.GuildId) (Evergreen.V229.Discord.Id Evergreen.V229.Discord.ChannelId) Evergreen.V229.Id.ThreadRouteWithMessage (Evergreen.V229.Discord.Id Evergreen.V229.Discord.MessageId) Evergreen.V229.Emoji.EmojiOrCustomEmoji (Result Evergreen.V229.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V229.Discord.Id Evergreen.V229.Discord.PrivateChannelId) (Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelMessageId) (Evergreen.V229.Discord.Id Evergreen.V229.Discord.MessageId) Evergreen.V229.Emoji.EmojiOrCustomEmoji (Result Evergreen.V229.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V229.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V229.Discord.HttpError (List ( Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId, Maybe Evergreen.V229.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V229.Slack.CurrentUser
            , team : Evergreen.V229.Slack.Team
            , users : List Evergreen.V229.Slack.User
            , channels : List ( Evergreen.V229.Slack.Channel, List Evergreen.V229.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId) (Result Effect.Http.Error Evergreen.V229.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId) Evergreen.V229.Discord.UserAuth (Result Evergreen.V229.Discord.HttpError Evergreen.V229.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId) (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId) (Result Evergreen.V229.Discord.HttpError Evergreen.V229.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId)
        (Result
            Evergreen.V229.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V229.Discord.Id Evergreen.V229.Discord.PrivateChannelId
                , members : List (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId)
                }
            , List
                ( Evergreen.V229.Discord.Id Evergreen.V229.Discord.GuildId
                , { guild : Evergreen.V229.Discord.GatewayGuild
                  , channels : List Evergreen.V229.Discord.Channel
                  , icon : Maybe Evergreen.V229.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId) Bool
    | WebsocketSentDataForUser (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V229.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V229.Discord.Id Evergreen.V229.Discord.AttachmentId, Evergreen.V229.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V229.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V229.Discord.Id Evergreen.V229.Discord.AttachmentId, Evergreen.V229.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId) (Evergreen.V229.Discord.Id Evergreen.V229.Discord.GuildId) (Evergreen.V229.Discord.Id Evergreen.V229.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V229.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V229.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId) (Evergreen.V229.Discord.Id Evergreen.V229.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V229.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V229.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId) (Evergreen.V229.Discord.Id Evergreen.V229.Discord.GuildId) (Evergreen.V229.Discord.Id Evergreen.V229.Discord.ChannelId) (Result Evergreen.V229.Discord.HttpError (List Evergreen.V229.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId) (Evergreen.V229.Discord.Id Evergreen.V229.Discord.PrivateChannelId) (Result Evergreen.V229.Discord.HttpError (List Evergreen.V229.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V229.Id.Id Evergreen.V229.Id.GuildId) (Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelId) Evergreen.V229.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V229.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V229.DmChannel.DmChannelId Evergreen.V229.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V229.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V229.Discord.Id Evergreen.V229.Discord.GuildId) (Evergreen.V229.Discord.Id Evergreen.V229.Discord.ChannelId) Evergreen.V229.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V229.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V229.Discord.Id Evergreen.V229.Discord.PrivateChannelId) (Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V229.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId)
        (Evergreen.V229.Discord.Id Evergreen.V229.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V229.Discord.HttpError
            { guild : Evergreen.V229.Discord.GatewayGuild
            , channels : List Evergreen.V229.Discord.Channel
            , icon : Maybe Evergreen.V229.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V229.Discord.Id Evergreen.V229.Discord.GuildId) (Result Evergreen.V229.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V229.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId) (List ( Evergreen.V229.Id.Id Evergreen.V229.Id.StickerId, Result Effect.Http.Error Evergreen.V229.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V229.Id.Id Evergreen.V229.Id.StickerId, Result Effect.Http.Error Evergreen.V229.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId) (List ( Evergreen.V229.Id.Id Evergreen.V229.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V229.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V229.Id.Id Evergreen.V229.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V229.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V229.Discord.HttpError (List Evergreen.V229.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V229.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V229.SecretId.SecretId Evergreen.V229.SecretId.ServerSecret))
