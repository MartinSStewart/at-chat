module Evergreen.V236.Types exposing (..)

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
import Evergreen.V236.AiChat
import Evergreen.V236.Call
import Evergreen.V236.ChannelDescription
import Evergreen.V236.ChannelName
import Evergreen.V236.Coord
import Evergreen.V236.CssPixels
import Evergreen.V236.CustomEmoji
import Evergreen.V236.Discord
import Evergreen.V236.DiscordAttachmentId
import Evergreen.V236.DiscordUserData
import Evergreen.V236.DmChannel
import Evergreen.V236.Editable
import Evergreen.V236.EmailAddress
import Evergreen.V236.Embed
import Evergreen.V236.Emoji
import Evergreen.V236.FileStatus
import Evergreen.V236.Go
import Evergreen.V236.GuildName
import Evergreen.V236.Id
import Evergreen.V236.ImageEditor
import Evergreen.V236.Local
import Evergreen.V236.LocalState
import Evergreen.V236.Log
import Evergreen.V236.LoginForm
import Evergreen.V236.MembersAndOwner
import Evergreen.V236.Message
import Evergreen.V236.MessageInput
import Evergreen.V236.MessageView
import Evergreen.V236.NonemptyDict
import Evergreen.V236.NonemptySet
import Evergreen.V236.OneToOne
import Evergreen.V236.Pages.Admin
import Evergreen.V236.Pagination
import Evergreen.V236.PersonName
import Evergreen.V236.Ports
import Evergreen.V236.Postmark
import Evergreen.V236.Range
import Evergreen.V236.RichText
import Evergreen.V236.Route
import Evergreen.V236.SecretId
import Evergreen.V236.SessionIdHash
import Evergreen.V236.Slack
import Evergreen.V236.Sticker
import Evergreen.V236.TextEditor
import Evergreen.V236.ToBackendLog
import Evergreen.V236.Touch
import Evergreen.V236.TwoFactorAuthentication
import Evergreen.V236.Ui.Anim
import Evergreen.V236.Untrusted
import Evergreen.V236.User
import Evergreen.V236.UserAgent
import Evergreen.V236.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V236.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V236.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.Id.GuildId) Evergreen.V236.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId) Evergreen.V236.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V236.Discord.Id Evergreen.V236.Discord.PrivateChannelId) Evergreen.V236.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V236.Discord.Id Evergreen.V236.Discord.GuildId) Evergreen.V236.LocalState.DiscordFrontendGuild
    , user : Evergreen.V236.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId) Evergreen.V236.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId) Evergreen.V236.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId) Evergreen.V236.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V236.SessionIdHash.SessionIdHash Evergreen.V236.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V236.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.Id.StickerId) Evergreen.V236.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.Id.CustomEmojiId) Evergreen.V236.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V236.Call.RoomId (Evergreen.V236.NonemptySet.NonemptySet ( Evergreen.V236.Id.Id Evergreen.V236.Id.UserId, Effect.Lamdera.ClientId ))
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V236.Route.Route
    , windowSize : Evergreen.V236.Coord.Coord Evergreen.V236.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V236.Ports.NotificationPermission
    , pwaStatus : Evergreen.V236.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V236.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V236.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V236.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V236.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.FileStatus.FileId) Evergreen.V236.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V236.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V236.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.FileStatus.FileId) Evergreen.V236.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V236.Id.Id Evergreen.V236.Id.GuildId) Evergreen.V236.ChannelName.ChannelName Evergreen.V236.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V236.Id.Id Evergreen.V236.Id.GuildId) (Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelId) Evergreen.V236.ChannelName.ChannelName Evergreen.V236.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V236.Id.Id Evergreen.V236.Id.GuildId) (Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V236.Id.Id Evergreen.V236.Id.GuildId) (Evergreen.V236.UserSession.ToBeFilledInByBackend (Evergreen.V236.SecretId.SecretId Evergreen.V236.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V236.GuildName.GuildName (Evergreen.V236.UserSession.ToBeFilledInByBackend (Evergreen.V236.Id.Id Evergreen.V236.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V236.Id.AnyGuildOrDmId, Evergreen.V236.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V236.Id.AnyGuildOrDmId Evergreen.V236.Id.ThreadRouteWithMessage Evergreen.V236.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V236.Id.AnyGuildOrDmId Evergreen.V236.Id.ThreadRouteWithMessage Evergreen.V236.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V236.Id.GuildOrDmId Evergreen.V236.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.FileStatus.FileId) Evergreen.V236.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId) (Evergreen.V236.Discord.Id Evergreen.V236.Discord.GuildId) (Evergreen.V236.Discord.Id Evergreen.V236.Discord.ChannelId) Evergreen.V236.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V236.Id.DiscordGuildOrDmId_DmData (Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V236.Id.AnyGuildOrDmId Evergreen.V236.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V236.Id.AnyGuildOrDmId Evergreen.V236.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V236.Id.AnyGuildOrDmId Evergreen.V236.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V236.UserSession.SetViewing
    | Local_SetName Evergreen.V236.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V236.Id.GuildOrDmId (Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelMessageId) (Evergreen.V236.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelMessageId) (Evergreen.V236.Message.Message Evergreen.V236.Id.ChannelMessageId (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V236.Id.GuildOrDmId (Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelMessageId) (Evergreen.V236.Id.Id Evergreen.V236.Id.ThreadMessageId) (Evergreen.V236.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.Id.ThreadMessageId) (Evergreen.V236.Message.Message Evergreen.V236.Id.ThreadMessageId (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V236.Id.DiscordGuildOrDmId (Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelMessageId) (Evergreen.V236.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelMessageId) (Evergreen.V236.Message.Message Evergreen.V236.Id.ChannelMessageId (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V236.Id.DiscordGuildOrDmId (Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelMessageId) (Evergreen.V236.Id.Id Evergreen.V236.Id.ThreadMessageId) (Evergreen.V236.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.Id.ThreadMessageId) (Evergreen.V236.Message.Message Evergreen.V236.Id.ThreadMessageId (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V236.Id.Id Evergreen.V236.Id.GuildId) Evergreen.V236.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId) (Evergreen.V236.Discord.Id Evergreen.V236.Discord.GuildId) Evergreen.V236.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V236.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V236.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V236.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V236.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V236.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V236.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V236.NonemptySet.NonemptySet (Evergreen.V236.Id.Id Evergreen.V236.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V236.Call.LocalChange
    | Local_Go
        { otherUserId : Evergreen.V236.Id.Id Evergreen.V236.Id.UserId
        }
        Evergreen.V236.Go.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId) Effect.Time.Posix Evergreen.V236.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V236.RichText.RichText (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId))) Evergreen.V236.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.FileStatus.FileId) Evergreen.V236.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.Id.StickerId) Evergreen.V236.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V236.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V236.RichText.RichText (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId))) Evergreen.V236.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.FileStatus.FileId) Evergreen.V236.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.Id.StickerId) Evergreen.V236.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V236.Id.Id Evergreen.V236.Id.GuildId) Evergreen.V236.ChannelName.ChannelName Evergreen.V236.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V236.Id.Id Evergreen.V236.Id.GuildId) (Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelId) Evergreen.V236.ChannelName.ChannelName Evergreen.V236.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V236.Id.Id Evergreen.V236.Id.GuildId) (Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId) (Evergreen.V236.Id.Id Evergreen.V236.Id.GuildId) (Evergreen.V236.SecretId.SecretId Evergreen.V236.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId) (Evergreen.V236.Id.Id Evergreen.V236.Id.GuildId) Evergreen.V236.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V236.LocalState.JoinGuildError
            { guildId : Evergreen.V236.Id.Id Evergreen.V236.Id.GuildId
            , guild : Evergreen.V236.LocalState.FrontendGuild
            , owner : Evergreen.V236.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId) Evergreen.V236.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId) Evergreen.V236.Id.GuildOrDmId Evergreen.V236.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId) (Evergreen.V236.Discord.Id Evergreen.V236.Discord.GuildId) (Evergreen.V236.Discord.Id Evergreen.V236.Discord.ChannelId) Evergreen.V236.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId) (Evergreen.V236.Discord.Id Evergreen.V236.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId) Evergreen.V236.Id.GuildOrDmId Evergreen.V236.Id.ThreadRouteWithMessage Evergreen.V236.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId) Evergreen.V236.Id.GuildOrDmId Evergreen.V236.Id.ThreadRouteWithMessage Evergreen.V236.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId) (Evergreen.V236.Discord.Id Evergreen.V236.Discord.GuildId) (Evergreen.V236.Discord.Id Evergreen.V236.Discord.ChannelId) Evergreen.V236.Id.ThreadRouteWithMessage Evergreen.V236.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId) (Evergreen.V236.Discord.Id Evergreen.V236.Discord.PrivateChannelId) (Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelMessageId) Evergreen.V236.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId) (Evergreen.V236.Discord.Id Evergreen.V236.Discord.GuildId) (Evergreen.V236.Discord.Id Evergreen.V236.Discord.ChannelId) Evergreen.V236.Id.ThreadRouteWithMessage Evergreen.V236.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId) (Evergreen.V236.Discord.Id Evergreen.V236.Discord.PrivateChannelId) (Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelMessageId) Evergreen.V236.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId) Evergreen.V236.Id.GuildOrDmId Evergreen.V236.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V236.RichText.RichText (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId))) (SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.FileStatus.FileId) Evergreen.V236.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId) (Evergreen.V236.Discord.Id Evergreen.V236.Discord.GuildId) (Evergreen.V236.Discord.Id Evergreen.V236.Discord.ChannelId) Evergreen.V236.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V236.RichText.RichText (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V236.Id.DiscordGuildOrDmId_DmData (Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V236.RichText.RichText (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId) Evergreen.V236.Id.AnyGuildOrDmId Evergreen.V236.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V236.Id.AnyGuildOrDmId Evergreen.V236.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V236.Discord.Id Evergreen.V236.Discord.GuildId) (Evergreen.V236.Discord.Id Evergreen.V236.Discord.ChannelId) Evergreen.V236.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V236.Discord.Id Evergreen.V236.Discord.PrivateChannelId) (Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId) Evergreen.V236.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId) Evergreen.V236.FileStatus.FileHash
    | Server_SetGuildIcon (Evergreen.V236.Id.Id Evergreen.V236.Id.GuildId) Evergreen.V236.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V236.Id.Id Evergreen.V236.Id.GuildId) Evergreen.V236.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V236.Discord.Id Evergreen.V236.Discord.GuildId) Evergreen.V236.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V236.SessionIdHash.SessionIdHash Evergreen.V236.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V236.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V236.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V236.Id.AnyGuildOrDmId, Evergreen.V236.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V236.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId) Evergreen.V236.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V236.Discord.Id Evergreen.V236.Discord.GuildId) (Evergreen.V236.Discord.Id Evergreen.V236.Discord.ChannelId) Evergreen.V236.ChannelName.ChannelName (Evergreen.V236.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V236.Discord.Id Evergreen.V236.Discord.PrivateChannelId)
        (Evergreen.V236.NonemptyDict.NonemptyDict
            (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V236.Discord.Id Evergreen.V236.Discord.GuildId) Evergreen.V236.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V236.Discord.Id Evergreen.V236.Discord.PrivateChannelId) Evergreen.V236.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId) Evergreen.V236.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId) (Maybe (Evergreen.V236.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V236.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V236.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V236.Id.Id Evergreen.V236.Id.GuildId) (Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelId) Evergreen.V236.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V236.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId) Evergreen.V236.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V236.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V236.Discord.Id Evergreen.V236.Discord.GuildId) (Evergreen.V236.Discord.Id Evergreen.V236.Discord.ChannelId) Evergreen.V236.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V236.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V236.Discord.Id Evergreen.V236.Discord.PrivateChannelId) (Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V236.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V236.Discord.Id Evergreen.V236.Discord.GuildId) Evergreen.V236.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V236.Discord.Id Evergreen.V236.Discord.GuildId) (Evergreen.V236.Discord.Id Evergreen.V236.Discord.ChannelId) (Evergreen.V236.Discord.OptionalData String) (Evergreen.V236.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V236.Discord.Id Evergreen.V236.Discord.GuildId)
        (Evergreen.V236.MembersAndOwner.MembersAndOwner
            (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V236.Discord.Id Evergreen.V236.Discord.GuildId) (Evergreen.V236.Discord.Id Evergreen.V236.Discord.ChannelId) (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId) Evergreen.V236.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.Id.StickerId) Evergreen.V236.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.Id.CustomEmojiId) Evergreen.V236.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V236.Call.ServerChange
    | Server_Go
        (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId)
        { otherUserId : Evergreen.V236.Id.Id Evergreen.V236.Id.UserId
        }
        Evergreen.V236.Go.LocalChange


type LocalMsg
    = LocalChange (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V236.Id.Id Evergreen.V236.Id.GuildId) (Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelId) Evergreen.V236.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V236.Discord.Id Evergreen.V236.Discord.GuildId) (Evergreen.V236.Discord.Id Evergreen.V236.Discord.ChannelId) Evergreen.V236.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.FileStatus.FileId) Evergreen.V236.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V236.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V236.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V236.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V236.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V236.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V236.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V236.Coord.Coord Evergreen.V236.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V236.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V236.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V236.Id.AnyGuildOrDmId Evergreen.V236.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V236.Id.AnyGuildOrDmId Evergreen.V236.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V236.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V236.Coord.Coord Evergreen.V236.CssPixels.CssPixels) (Maybe Evergreen.V236.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V236.Id.AnyGuildOrDmId, Evergreen.V236.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelMessageId) (Evergreen.V236.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.Id.ThreadMessageId) (Evergreen.V236.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V236.Editable.Model
    , showLinkDiscordSetup : Bool
    , domainWhitelistInput : String
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V236.Local.Local LocalMsg Evergreen.V236.LocalState.LocalState
    , admin : Evergreen.V236.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V236.Id.AnyGuildOrDmId, Evergreen.V236.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V236.Id.Id Evergreen.V236.Id.GuildId, Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelId ) EditChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V236.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V236.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V236.Id.AnyGuildOrDmId, Evergreen.V236.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V236.Id.AnyGuildOrDmId, Evergreen.V236.Id.ThreadRoute ) (Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : Evergreen.V236.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V236.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V236.Id.AnyGuildOrDmId, Evergreen.V236.Id.ThreadRoute ) (Evergreen.V236.NonemptyDict.NonemptyDict (Evergreen.V236.Id.Id Evergreen.V236.FileStatus.FileId) Evergreen.V236.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V236.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V236.TextEditor.Model
    , profilePictureEditor : Evergreen.V236.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V236.Id.Id Evergreen.V236.Id.GuildId, Evergreen.V236.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V236.Emoji.Model
    , voiceChat : Evergreen.V236.Call.Model
    , currentDmGoMatch : SeqDict.SeqDict ( Evergreen.V236.Id.Id Evergreen.V236.Id.UserId, Maybe (Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelMessageId) ) Evergreen.V236.Go.Model
    , fileDragOverCount : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V236.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V236.SecretId.SecretId Evergreen.V236.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V236.Range.Range
                , direction : Evergreen.V236.Range.SelectionDirection
                }
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V236.NonemptyDict.NonemptyDict Int Evergreen.V236.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V236.NonemptyDict.NonemptyDict Int Evergreen.V236.Touch.Touch
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
    | AdminToFrontend Evergreen.V236.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V236.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V236.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V236.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V236.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V236.ImageEditor.ToFrontend


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V236.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V236.Coord.Coord Evergreen.V236.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V236.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , notificationPermission : Evergreen.V236.Ports.NotificationPermission
    , pwaStatus : Evergreen.V236.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V236.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V236.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V236.Emoji.CachedEmojiData
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V236.Id.Id Evergreen.V236.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V236.Id.Id Evergreen.V236.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V236.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V236.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V236.Coord.Coord Evergreen.V236.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V236.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V236.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V236.Id.Id Evergreen.V236.Id.GuildId, Evergreen.V236.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V236.DmChannel.DmChannelId, Evergreen.V236.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V236.Discord.Id Evergreen.V236.Discord.GuildId, Evergreen.V236.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V236.Discord.Id Evergreen.V236.Discord.PrivateChannelId, Evergreen.V236.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V236.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V236.NonemptyDict.NonemptyDict (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId) Evergreen.V236.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V236.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V236.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V236.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V236.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId) Evergreen.V236.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId) Evergreen.V236.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.Id.GuildId) Evergreen.V236.LocalState.BackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V236.Discord.Id Evergreen.V236.Discord.GuildId) Evergreen.V236.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V236.DmChannel.DmChannelId Evergreen.V236.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V236.Discord.Id Evergreen.V236.Discord.PrivateChannelId) Evergreen.V236.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V236.OneToOne.OneToOne (Evergreen.V236.Slack.Id Evergreen.V236.Slack.ChannelId) Evergreen.V236.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V236.OneToOne.OneToOne String (Evergreen.V236.Id.Id Evergreen.V236.Id.GuildId)
    , slackUsers : Evergreen.V236.OneToOne.OneToOne (Evergreen.V236.Slack.Id Evergreen.V236.Slack.UserId) (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId)
    , slackServers : Evergreen.V236.OneToOne.OneToOne (Evergreen.V236.Slack.Id Evergreen.V236.Slack.TeamId) (Evergreen.V236.Id.Id Evergreen.V236.Id.GuildId)
    , slackToken : Maybe Evergreen.V236.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V236.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V236.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V236.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V236.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId) Evergreen.V236.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId, Evergreen.V236.Discord.Id Evergreen.V236.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V236.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V236.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V236.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V236.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId) (Evergreen.V236.LocalState.LoadingDiscordChannel (List Evergreen.V236.Discord.Message))
    , signupsEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V236.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.Id.StickerId) Evergreen.V236.Sticker.StickerData
    , discordStickers : Evergreen.V236.OneToOne.OneToOne (Evergreen.V236.Discord.Id Evergreen.V236.Discord.StickerId) (Evergreen.V236.Id.Id Evergreen.V236.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.Id.CustomEmojiId) Evergreen.V236.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V236.OneToOne.OneToOne Evergreen.V236.RichText.DiscordCustomEmojiIdAndName (Evergreen.V236.Id.Id Evergreen.V236.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V236.Postmark.ApiKey
    , serverSecret : Evergreen.V236.SecretId.SecretId Evergreen.V236.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V236.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V236.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V236.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V236.Route.Route
    | SelectedFilesToAttach ( Evergreen.V236.Id.AnyGuildOrDmId, Evergreen.V236.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V236.Id.Id Evergreen.V236.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V236.Id.Id Evergreen.V236.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V236.Id.Id Evergreen.V236.Id.GuildId) (Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelId) Evergreen.V236.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V236.Id.Id Evergreen.V236.Id.GuildId) (Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelId) Evergreen.V236.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V236.Discord.Id Evergreen.V236.Discord.GuildId) (Evergreen.V236.Discord.Id Evergreen.V236.Discord.ChannelId) Evergreen.V236.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V236.Discord.Id Evergreen.V236.Discord.GuildId) (Evergreen.V236.Discord.Id Evergreen.V236.Discord.ChannelId) Evergreen.V236.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V236.Id.Id Evergreen.V236.Id.GuildId) (Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V236.Id.Id Evergreen.V236.Id.GuildId) (Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V236.Id.Id Evergreen.V236.Id.GuildId) (Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V236.Id.Id Evergreen.V236.Id.GuildId) (Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V236.Id.Id Evergreen.V236.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V236.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V236.Id.AnyGuildOrDmId Evergreen.V236.Id.ThreadRouteWithMessage (Evergreen.V236.Coord.Coord Evergreen.V236.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V236.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V236.Id.AnyGuildOrDmId Evergreen.V236.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V236.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V236.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V236.Id.AnyGuildOrDmId, Evergreen.V236.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V236.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V236.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V236.Id.AnyGuildOrDmId, Evergreen.V236.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V236.NonemptyDict.NonemptyDict Int Evergreen.V236.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V236.NonemptyDict.NonemptyDict Int Evergreen.V236.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V236.Id.AnyGuildOrDmId Evergreen.V236.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V236.Id.AnyGuildOrDmId Evergreen.V236.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V236.NonemptySet.NonemptySet (Evergreen.V236.Id.Id Evergreen.V236.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V236.Id.AnyGuildOrDmId, Evergreen.V236.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V236.Id.AnyGuildOrDmId Evergreen.V236.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V236.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V236.AiChat.Msg
    | GoMsg Evergreen.V236.Go.Msg
    | UserNameEditableMsg (Evergreen.V236.Editable.Msg Evergreen.V236.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V236.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V236.Id.Id Evergreen.V236.Id.GuildId) Evergreen.V236.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V236.Id.AnyGuildOrDmId, Evergreen.V236.Id.ThreadRoute ) (Evergreen.V236.Id.Id Evergreen.V236.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V236.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V236.Id.AnyGuildOrDmId, Evergreen.V236.Id.ThreadRoute ) (Evergreen.V236.Id.Id Evergreen.V236.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V236.Id.AnyGuildOrDmId, Evergreen.V236.Id.ThreadRoute ) (Evergreen.V236.Id.Id Evergreen.V236.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V236.Id.AnyGuildOrDmId, Evergreen.V236.Id.ThreadRoute )
        { fileId : Evergreen.V236.Id.Id Evergreen.V236.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V236.Id.AnyGuildOrDmId, Evergreen.V236.Id.ThreadRoute ) (Evergreen.V236.Id.Id Evergreen.V236.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V236.Id.AnyGuildOrDmId, Evergreen.V236.Id.ThreadRoute ) (Evergreen.V236.Id.Id Evergreen.V236.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V236.Id.AnyGuildOrDmId, Evergreen.V236.Id.ThreadRoute )
        { fileId : Evergreen.V236.Id.Id Evergreen.V236.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V236.Id.AnyGuildOrDmId, Evergreen.V236.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V236.Id.AnyGuildOrDmId, Evergreen.V236.Id.ThreadRoute ) (Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelMessageId) (Evergreen.V236.Id.Id Evergreen.V236.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V236.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V236.Id.AnyGuildOrDmId, Evergreen.V236.Id.ThreadRoute ) (Evergreen.V236.Id.Id Evergreen.V236.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V236.Id.AnyGuildOrDmId Evergreen.V236.Id.ThreadRouteWithMessage Evergreen.V236.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V236.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V236.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V236.Id.Id Evergreen.V236.Id.GuildId) Evergreen.V236.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId) (Evergreen.V236.Discord.Id Evergreen.V236.Discord.GuildId) Evergreen.V236.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V236.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V236.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId
        , otherUserId : Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V236.Id.AnyGuildOrDmId Evergreen.V236.Id.ThreadRoute Evergreen.V236.MessageInput.Msg
    | MessageInputMsg Evergreen.V236.Id.AnyGuildOrDmId Evergreen.V236.Id.ThreadRoute Evergreen.V236.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V236.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V236.Range.Range, Evergreen.V236.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V236.Range.Range, Evergreen.V236.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V236.Call.FromJs)
    | VoiceChatMsg Evergreen.V236.Call.Msg
    | PressedChannelHeaderTab Evergreen.V236.Route.DmChannelHeaderTab
    | FileDragEnter
    | FileDragLeave
    | FileDropped (List Effect.File.File)


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V236.Id.Id Evergreen.V236.Id.GuildId) (Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelId) Evergreen.V236.Id.ThreadRoute
    | InitialLoadRequested_Dm Evergreen.V236.DmChannel.DmChannelId Evergreen.V236.Id.ThreadRoute
    | InitialLoadRequested_Discord Evergreen.V236.Id.DiscordGuildOrDmId Evergreen.V236.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V236.Id.Id Evergreen.V236.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V236.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V236.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V236.Untrusted.Untrusted Evergreen.V236.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V236.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V236.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V236.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V236.Id.Id Evergreen.V236.Id.GuildId) (Evergreen.V236.SecretId.SecretId Evergreen.V236.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V236.PersonName.PersonName Evergreen.V236.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V236.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V236.Slack.OAuthCode Evergreen.V236.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V236.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V236.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V236.Id.Id Evergreen.V236.Pagination.PageId))


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V236.Discord.Id Evergreen.V236.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V236.Discord.Id Evergreen.V236.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V236.EmailAddress.EmailAddress (Result Evergreen.V236.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V236.EmailAddress.EmailAddress (Result Evergreen.V236.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId) Evergreen.V236.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V236.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V236.Discord.Id Evergreen.V236.Discord.GuildId) (Evergreen.V236.Discord.Id Evergreen.V236.Discord.ChannelId) Evergreen.V236.Id.ThreadRouteWithMaybeMessage (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId) (Result Evergreen.V236.Discord.HttpError Evergreen.V236.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V236.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V236.Discord.Id Evergreen.V236.Discord.PrivateChannelId) (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId) (Result Evergreen.V236.Discord.HttpError Evergreen.V236.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V236.Discord.Id Evergreen.V236.Discord.GuildId) (Evergreen.V236.Discord.Id Evergreen.V236.Discord.ChannelId) Evergreen.V236.Id.ThreadRouteWithMessage (Evergreen.V236.Discord.Id Evergreen.V236.Discord.MessageId) (Result Evergreen.V236.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V236.Discord.Id Evergreen.V236.Discord.PrivateChannelId) (Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelMessageId) (Evergreen.V236.Discord.Id Evergreen.V236.Discord.MessageId) (Result Evergreen.V236.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V236.Discord.Id Evergreen.V236.Discord.GuildId) (Evergreen.V236.Discord.Id Evergreen.V236.Discord.ChannelId) Evergreen.V236.Id.ThreadRouteWithMessage (Evergreen.V236.Discord.Id Evergreen.V236.Discord.MessageId) (Result Evergreen.V236.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V236.Discord.Id Evergreen.V236.Discord.PrivateChannelId) (Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelMessageId) (Evergreen.V236.Discord.Id Evergreen.V236.Discord.MessageId) (Result Evergreen.V236.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V236.Discord.Id Evergreen.V236.Discord.GuildId) (Evergreen.V236.Discord.Id Evergreen.V236.Discord.ChannelId) Evergreen.V236.Id.ThreadRouteWithMessage (Evergreen.V236.Discord.Id Evergreen.V236.Discord.MessageId) Evergreen.V236.Emoji.EmojiOrCustomEmoji (Result Evergreen.V236.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V236.Discord.Id Evergreen.V236.Discord.PrivateChannelId) (Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelMessageId) (Evergreen.V236.Discord.Id Evergreen.V236.Discord.MessageId) Evergreen.V236.Emoji.EmojiOrCustomEmoji (Result Evergreen.V236.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V236.Discord.Id Evergreen.V236.Discord.GuildId) (Evergreen.V236.Discord.Id Evergreen.V236.Discord.ChannelId) Evergreen.V236.Id.ThreadRouteWithMessage (Evergreen.V236.Discord.Id Evergreen.V236.Discord.MessageId) Evergreen.V236.Emoji.EmojiOrCustomEmoji (Result Evergreen.V236.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V236.Discord.Id Evergreen.V236.Discord.PrivateChannelId) (Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelMessageId) (Evergreen.V236.Discord.Id Evergreen.V236.Discord.MessageId) Evergreen.V236.Emoji.EmojiOrCustomEmoji (Result Evergreen.V236.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V236.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V236.Discord.HttpError (List ( Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId, Maybe Evergreen.V236.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V236.Slack.CurrentUser
            , team : Evergreen.V236.Slack.Team
            , users : List Evergreen.V236.Slack.User
            , channels : List ( Evergreen.V236.Slack.Channel, List Evergreen.V236.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId) (Result Effect.Http.Error Evergreen.V236.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId) Evergreen.V236.Discord.UserAuth (Result Evergreen.V236.Discord.HttpError Evergreen.V236.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId) (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId) (Result Evergreen.V236.Discord.HttpError Evergreen.V236.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId)
        (Result
            Evergreen.V236.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V236.Discord.Id Evergreen.V236.Discord.PrivateChannelId
                , members : List (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId)
                }
            , List
                ( Evergreen.V236.Discord.Id Evergreen.V236.Discord.GuildId
                , { guild : Evergreen.V236.Discord.GatewayGuild
                  , channels : List Evergreen.V236.Discord.Channel
                  , icon : Maybe Evergreen.V236.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId) Bool
    | WebsocketSentDataForUser (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V236.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V236.Discord.Id Evergreen.V236.Discord.AttachmentId, Evergreen.V236.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V236.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V236.Discord.Id Evergreen.V236.Discord.AttachmentId, Evergreen.V236.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId) (Evergreen.V236.Discord.Id Evergreen.V236.Discord.GuildId) (Evergreen.V236.Discord.Id Evergreen.V236.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V236.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V236.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId) (Evergreen.V236.Discord.Id Evergreen.V236.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V236.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V236.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId) (Evergreen.V236.Discord.Id Evergreen.V236.Discord.GuildId) (Evergreen.V236.Discord.Id Evergreen.V236.Discord.ChannelId) (Result Evergreen.V236.Discord.HttpError (List Evergreen.V236.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId) (Evergreen.V236.Discord.Id Evergreen.V236.Discord.PrivateChannelId) (Result Evergreen.V236.Discord.HttpError (List Evergreen.V236.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V236.Id.Id Evergreen.V236.Id.GuildId) (Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelId) Evergreen.V236.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V236.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V236.DmChannel.DmChannelId Evergreen.V236.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V236.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V236.Discord.Id Evergreen.V236.Discord.GuildId) (Evergreen.V236.Discord.Id Evergreen.V236.Discord.ChannelId) Evergreen.V236.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V236.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V236.Discord.Id Evergreen.V236.Discord.PrivateChannelId) (Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V236.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId)
        (Evergreen.V236.Discord.Id Evergreen.V236.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V236.Discord.HttpError
            { guild : Evergreen.V236.Discord.GatewayGuild
            , channels : List Evergreen.V236.Discord.Channel
            , icon : Maybe Evergreen.V236.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V236.Discord.Id Evergreen.V236.Discord.GuildId) (Result Evergreen.V236.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V236.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId) (List ( Evergreen.V236.Id.Id Evergreen.V236.Id.StickerId, Result Effect.Http.Error Evergreen.V236.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V236.Id.Id Evergreen.V236.Id.StickerId, Result Effect.Http.Error Evergreen.V236.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId) (List ( Evergreen.V236.Id.Id Evergreen.V236.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V236.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V236.Id.Id Evergreen.V236.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V236.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V236.Discord.HttpError (List Evergreen.V236.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V236.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V236.SecretId.SecretId Evergreen.V236.SecretId.ServerSecret))
