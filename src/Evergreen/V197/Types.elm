module Evergreen.V197.Types exposing (..)

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
import Evergreen.V197.AiChat
import Evergreen.V197.ChannelName
import Evergreen.V197.Coord
import Evergreen.V197.CssPixels
import Evergreen.V197.Discord
import Evergreen.V197.DiscordAttachmentId
import Evergreen.V197.DiscordUserData
import Evergreen.V197.DmChannel
import Evergreen.V197.Editable
import Evergreen.V197.EmailAddress
import Evergreen.V197.Embed
import Evergreen.V197.Emoji
import Evergreen.V197.FileStatus
import Evergreen.V197.GuildName
import Evergreen.V197.Id
import Evergreen.V197.ImageEditor
import Evergreen.V197.Local
import Evergreen.V197.LocalState
import Evergreen.V197.Log
import Evergreen.V197.LoginForm
import Evergreen.V197.MembersAndOwner
import Evergreen.V197.Message
import Evergreen.V197.MessageInput
import Evergreen.V197.MessageView
import Evergreen.V197.NonemptyDict
import Evergreen.V197.NonemptySet
import Evergreen.V197.OneToOne
import Evergreen.V197.Pages.Admin
import Evergreen.V197.Pagination
import Evergreen.V197.PersonName
import Evergreen.V197.Ports
import Evergreen.V197.Postmark
import Evergreen.V197.Range
import Evergreen.V197.RichText
import Evergreen.V197.Route
import Evergreen.V197.SecretId
import Evergreen.V197.SessionIdHash
import Evergreen.V197.Slack
import Evergreen.V197.Sticker
import Evergreen.V197.TextEditor
import Evergreen.V197.ToBackendLog
import Evergreen.V197.Touch
import Evergreen.V197.TwoFactorAuthentication
import Evergreen.V197.Ui.Anim
import Evergreen.V197.Untrusted
import Evergreen.V197.User
import Evergreen.V197.UserAgent
import Evergreen.V197.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V197.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V197.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V197.Id.Id Evergreen.V197.Id.GuildId) Evergreen.V197.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId) Evergreen.V197.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V197.Discord.Id Evergreen.V197.Discord.PrivateChannelId) Evergreen.V197.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V197.Discord.Id Evergreen.V197.Discord.GuildId) Evergreen.V197.LocalState.DiscordFrontendGuild
    , user : Evergreen.V197.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId) Evergreen.V197.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId) Evergreen.V197.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId) Evergreen.V197.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V197.SessionIdHash.SessionIdHash Evergreen.V197.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V197.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V197.Id.Id Evergreen.V197.Id.StickerId) Evergreen.V197.Sticker.StickerData
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V197.Route.Route
    , windowSize : Evergreen.V197.Coord.Coord Evergreen.V197.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V197.Ports.NotificationPermission
    , pwaStatus : Evergreen.V197.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V197.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V197.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V197.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V197.RichText.RichText (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId))) Evergreen.V197.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V197.Id.Id Evergreen.V197.FileStatus.FileId) Evergreen.V197.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V197.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V197.RichText.RichText (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId))) Evergreen.V197.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V197.Id.Id Evergreen.V197.FileStatus.FileId) Evergreen.V197.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V197.Id.Id Evergreen.V197.Id.GuildId) Evergreen.V197.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V197.Id.Id Evergreen.V197.Id.GuildId) (Evergreen.V197.Id.Id Evergreen.V197.Id.ChannelId) Evergreen.V197.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V197.Id.Id Evergreen.V197.Id.GuildId) (Evergreen.V197.Id.Id Evergreen.V197.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V197.Id.Id Evergreen.V197.Id.GuildId) (Evergreen.V197.UserSession.ToBeFilledInByBackend (Evergreen.V197.SecretId.SecretId Evergreen.V197.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V197.GuildName.GuildName (Evergreen.V197.UserSession.ToBeFilledInByBackend (Evergreen.V197.Id.Id Evergreen.V197.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V197.Id.AnyGuildOrDmId, Evergreen.V197.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V197.Id.AnyGuildOrDmId Evergreen.V197.Id.ThreadRouteWithMessage Evergreen.V197.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V197.Id.AnyGuildOrDmId Evergreen.V197.Id.ThreadRouteWithMessage Evergreen.V197.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V197.Id.GuildOrDmId Evergreen.V197.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V197.RichText.RichText (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId))) (SeqDict.SeqDict (Evergreen.V197.Id.Id Evergreen.V197.FileStatus.FileId) Evergreen.V197.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId) (Evergreen.V197.Discord.Id Evergreen.V197.Discord.GuildId) (Evergreen.V197.Discord.Id Evergreen.V197.Discord.ChannelId) Evergreen.V197.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V197.RichText.RichText (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId)))
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V197.Id.DiscordGuildOrDmId_DmData (Evergreen.V197.Id.Id Evergreen.V197.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V197.RichText.RichText (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId)))
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V197.Id.AnyGuildOrDmId Evergreen.V197.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V197.Id.AnyGuildOrDmId Evergreen.V197.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V197.Id.AnyGuildOrDmId Evergreen.V197.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V197.UserSession.SetViewing
    | Local_SetName Evergreen.V197.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V197.Id.GuildOrDmId (Evergreen.V197.Id.Id Evergreen.V197.Id.ChannelMessageId) (Evergreen.V197.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V197.Id.Id Evergreen.V197.Id.ChannelMessageId) (Evergreen.V197.Message.Message Evergreen.V197.Id.ChannelMessageId (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V197.Id.GuildOrDmId (Evergreen.V197.Id.Id Evergreen.V197.Id.ChannelMessageId) (Evergreen.V197.Id.Id Evergreen.V197.Id.ThreadMessageId) (Evergreen.V197.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V197.Id.Id Evergreen.V197.Id.ThreadMessageId) (Evergreen.V197.Message.Message Evergreen.V197.Id.ThreadMessageId (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V197.Id.DiscordGuildOrDmId (Evergreen.V197.Id.Id Evergreen.V197.Id.ChannelMessageId) (Evergreen.V197.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V197.Id.Id Evergreen.V197.Id.ChannelMessageId) (Evergreen.V197.Message.Message Evergreen.V197.Id.ChannelMessageId (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V197.Id.DiscordGuildOrDmId (Evergreen.V197.Id.Id Evergreen.V197.Id.ChannelMessageId) (Evergreen.V197.Id.Id Evergreen.V197.Id.ThreadMessageId) (Evergreen.V197.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V197.Id.Id Evergreen.V197.Id.ThreadMessageId) (Evergreen.V197.Message.Message Evergreen.V197.Id.ThreadMessageId (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V197.Id.Id Evergreen.V197.Id.GuildId) Evergreen.V197.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId) (Evergreen.V197.Discord.Id Evergreen.V197.Discord.GuildId) Evergreen.V197.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V197.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V197.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V197.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V197.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V197.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V197.Emoji.SkinTone)


type ServerChange
    = Server_SendMessage (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId) Effect.Time.Posix Evergreen.V197.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V197.RichText.RichText (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId))) Evergreen.V197.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V197.Id.Id Evergreen.V197.FileStatus.FileId) Evergreen.V197.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V197.Id.Id Evergreen.V197.Id.StickerId) Evergreen.V197.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V197.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V197.RichText.RichText (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId))) Evergreen.V197.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V197.Id.Id Evergreen.V197.FileStatus.FileId) Evergreen.V197.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V197.Id.Id Evergreen.V197.Id.StickerId) Evergreen.V197.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V197.Id.Id Evergreen.V197.Id.GuildId) Evergreen.V197.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V197.Id.Id Evergreen.V197.Id.GuildId) (Evergreen.V197.Id.Id Evergreen.V197.Id.ChannelId) Evergreen.V197.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V197.Id.Id Evergreen.V197.Id.GuildId) (Evergreen.V197.Id.Id Evergreen.V197.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId) (Evergreen.V197.Id.Id Evergreen.V197.Id.GuildId) (Evergreen.V197.SecretId.SecretId Evergreen.V197.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId) (Evergreen.V197.Id.Id Evergreen.V197.Id.GuildId) Evergreen.V197.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V197.LocalState.JoinGuildError
            { guildId : Evergreen.V197.Id.Id Evergreen.V197.Id.GuildId
            , guild : Evergreen.V197.LocalState.FrontendGuild
            , owner : Evergreen.V197.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId) Evergreen.V197.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId) Evergreen.V197.Id.GuildOrDmId Evergreen.V197.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId) (Evergreen.V197.Discord.Id Evergreen.V197.Discord.GuildId) (Evergreen.V197.Discord.Id Evergreen.V197.Discord.ChannelId) Evergreen.V197.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId) (Evergreen.V197.Discord.Id Evergreen.V197.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId) Evergreen.V197.Id.GuildOrDmId Evergreen.V197.Id.ThreadRouteWithMessage Evergreen.V197.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId) Evergreen.V197.Id.GuildOrDmId Evergreen.V197.Id.ThreadRouteWithMessage Evergreen.V197.Emoji.Emoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId) (Evergreen.V197.Discord.Id Evergreen.V197.Discord.GuildId) (Evergreen.V197.Discord.Id Evergreen.V197.Discord.ChannelId) Evergreen.V197.Id.ThreadRouteWithMessage Evergreen.V197.Emoji.Emoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId) (Evergreen.V197.Discord.Id Evergreen.V197.Discord.PrivateChannelId) (Evergreen.V197.Id.Id Evergreen.V197.Id.ChannelMessageId) Evergreen.V197.Emoji.Emoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId) (Evergreen.V197.Discord.Id Evergreen.V197.Discord.GuildId) (Evergreen.V197.Discord.Id Evergreen.V197.Discord.ChannelId) Evergreen.V197.Id.ThreadRouteWithMessage Evergreen.V197.Emoji.Emoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId) (Evergreen.V197.Discord.Id Evergreen.V197.Discord.PrivateChannelId) (Evergreen.V197.Id.Id Evergreen.V197.Id.ChannelMessageId) Evergreen.V197.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId) Evergreen.V197.Id.GuildOrDmId Evergreen.V197.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V197.RichText.RichText (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId))) (SeqDict.SeqDict (Evergreen.V197.Id.Id Evergreen.V197.FileStatus.FileId) Evergreen.V197.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId) (Evergreen.V197.Discord.Id Evergreen.V197.Discord.GuildId) (Evergreen.V197.Discord.Id Evergreen.V197.Discord.ChannelId) Evergreen.V197.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V197.RichText.RichText (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V197.Id.DiscordGuildOrDmId_DmData (Evergreen.V197.Id.Id Evergreen.V197.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V197.RichText.RichText (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId) Evergreen.V197.Id.AnyGuildOrDmId Evergreen.V197.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V197.Id.AnyGuildOrDmId Evergreen.V197.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V197.Discord.Id Evergreen.V197.Discord.GuildId) (Evergreen.V197.Discord.Id Evergreen.V197.Discord.ChannelId) Evergreen.V197.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V197.Discord.Id Evergreen.V197.Discord.PrivateChannelId) (Evergreen.V197.Id.Id Evergreen.V197.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId) Evergreen.V197.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId) Evergreen.V197.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V197.Id.Id Evergreen.V197.Id.GuildId) Evergreen.V197.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V197.Discord.Id Evergreen.V197.Discord.GuildId) Evergreen.V197.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V197.SessionIdHash.SessionIdHash Evergreen.V197.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V197.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V197.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V197.Id.AnyGuildOrDmId, Evergreen.V197.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V197.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId) Evergreen.V197.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V197.Discord.Id Evergreen.V197.Discord.GuildId) (Evergreen.V197.Discord.Id Evergreen.V197.Discord.ChannelId) Evergreen.V197.ChannelName.ChannelName (Evergreen.V197.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V197.Discord.Id Evergreen.V197.Discord.PrivateChannelId)
        (Evergreen.V197.NonemptyDict.NonemptyDict
            (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V197.Discord.Id Evergreen.V197.Discord.GuildId) Evergreen.V197.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V197.Discord.Id Evergreen.V197.Discord.PrivateChannelId) Evergreen.V197.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId) Evergreen.V197.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId) (Maybe (Evergreen.V197.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V197.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V197.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V197.Id.Id Evergreen.V197.Id.GuildId) (Evergreen.V197.Id.Id Evergreen.V197.Id.ChannelId) Evergreen.V197.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V197.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId) Evergreen.V197.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V197.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V197.Discord.Id Evergreen.V197.Discord.GuildId) (Evergreen.V197.Discord.Id Evergreen.V197.Discord.ChannelId) Evergreen.V197.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V197.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V197.Discord.Id Evergreen.V197.Discord.PrivateChannelId) (Evergreen.V197.Id.Id Evergreen.V197.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V197.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V197.Discord.Id Evergreen.V197.Discord.GuildId) Evergreen.V197.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V197.Discord.Id Evergreen.V197.Discord.GuildId) (Evergreen.V197.Discord.Id Evergreen.V197.Discord.ChannelId) (Evergreen.V197.Discord.OptionalData String) (Evergreen.V197.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V197.Discord.Id Evergreen.V197.Discord.GuildId)
        (Evergreen.V197.MembersAndOwner.MembersAndOwner
            (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V197.Discord.Id Evergreen.V197.Discord.GuildId) (Evergreen.V197.Discord.Id Evergreen.V197.Discord.ChannelId) (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId) Evergreen.V197.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V197.Id.Id Evergreen.V197.Id.StickerId) Evergreen.V197.Sticker.StickerData)


type LocalMsg
    = LocalChange (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias NewChannelForm =
    { name : String
    , pressedSubmit : Bool
    }


type alias NewGuildForm =
    { name : String
    , pressedSubmit : Bool
    }


type GuildChannelNameHover
    = NoChannelNameHover
    | GuildChannelNameHover (Evergreen.V197.Id.Id Evergreen.V197.Id.GuildId) (Evergreen.V197.Id.Id Evergreen.V197.Id.ChannelId) Evergreen.V197.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V197.Discord.Id Evergreen.V197.Discord.GuildId) (Evergreen.V197.Discord.Id Evergreen.V197.Discord.ChannelId) Evergreen.V197.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V197.Id.Id Evergreen.V197.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V197.Id.Id Evergreen.V197.FileStatus.FileId) Evergreen.V197.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V197.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V197.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V197.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V197.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V197.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V197.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V197.Coord.Coord Evergreen.V197.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V197.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V197.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V197.Id.AnyGuildOrDmId Evergreen.V197.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V197.Id.AnyGuildOrDmId Evergreen.V197.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V197.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V197.Coord.Coord Evergreen.V197.CssPixels.CssPixels) (Maybe Evergreen.V197.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V197.Id.AnyGuildOrDmId, Evergreen.V197.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V197.Id.Id Evergreen.V197.Id.ChannelMessageId) (Evergreen.V197.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V197.Id.Id Evergreen.V197.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V197.Id.Id Evergreen.V197.Id.ThreadMessageId) (Evergreen.V197.NonemptySet.NonemptySet Int))
    }


type ChannelSidebarMode
    = ChannelSidebarClosed
    | ChannelSidebarOpened
    | ChannelSidebarClosing
        { offset : Float
        }
    | ChannelSidebarOpening
        { offset : Float
        }
    | ChannelSidebarDragging
        { offset : Float
        , previousOffset : Float
        , time : Effect.Time.Posix
        }


type alias UserOptionsModel =
    { name : Evergreen.V197.Editable.Model
    , showLinkDiscordSetup : Bool
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V197.Local.Local LocalMsg Evergreen.V197.LocalState.LocalState
    , admin : Evergreen.V197.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V197.Id.AnyGuildOrDmId, Evergreen.V197.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V197.Id.Id Evergreen.V197.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V197.Id.Id Evergreen.V197.Id.GuildId, Evergreen.V197.Id.Id Evergreen.V197.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V197.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V197.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V197.Id.AnyGuildOrDmId, Evergreen.V197.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V197.Id.AnyGuildOrDmId, Evergreen.V197.Id.ThreadRoute ) (Evergreen.V197.Id.Id Evergreen.V197.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V197.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V197.Id.AnyGuildOrDmId, Evergreen.V197.Id.ThreadRoute ) (Evergreen.V197.NonemptyDict.NonemptyDict (Evergreen.V197.Id.Id Evergreen.V197.FileStatus.FileId) Evergreen.V197.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V197.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V197.TextEditor.Model
    , profilePictureEditor : Evergreen.V197.ImageEditor.Model
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V197.Emoji.Model
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V197.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V197.SecretId.SecretId Evergreen.V197.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V197.Range.Range
                , direction : Evergreen.V197.Range.SelectionDirection
                }
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V197.NonemptyDict.NonemptyDict Int Evergreen.V197.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V197.NonemptyDict.NonemptyDict Int Evergreen.V197.Touch.Touch
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
    | AdminToFrontend Evergreen.V197.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V197.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V197.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V197.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V197.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V197.ImageEditor.ToFrontend


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V197.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V197.Coord.Coord Evergreen.V197.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V197.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , notificationPermission : Evergreen.V197.Ports.NotificationPermission
    , pwaStatus : Evergreen.V197.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V197.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V197.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V197.Emoji.CachedEmojiData
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V197.Id.Id Evergreen.V197.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V197.Id.Id Evergreen.V197.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V197.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V197.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V197.Coord.Coord Evergreen.V197.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V197.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V197.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V197.Id.Id Evergreen.V197.Id.GuildId, Evergreen.V197.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V197.DmChannel.DmChannelId, Evergreen.V197.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V197.Discord.Id Evergreen.V197.Discord.GuildId, Evergreen.V197.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V197.Discord.Id Evergreen.V197.Discord.PrivateChannelId, Evergreen.V197.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V197.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V197.NonemptyDict.NonemptyDict (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId) Evergreen.V197.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V197.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V197.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V197.LocalState.LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V197.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId) Evergreen.V197.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId) Evergreen.V197.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V197.Id.Id Evergreen.V197.Id.GuildId) Evergreen.V197.LocalState.BackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V197.Discord.Id Evergreen.V197.Discord.GuildId) Evergreen.V197.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V197.DmChannel.DmChannelId Evergreen.V197.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V197.Discord.Id Evergreen.V197.Discord.PrivateChannelId) Evergreen.V197.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V197.OneToOne.OneToOne (Evergreen.V197.Slack.Id Evergreen.V197.Slack.ChannelId) Evergreen.V197.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V197.OneToOne.OneToOne String (Evergreen.V197.Id.Id Evergreen.V197.Id.GuildId)
    , slackUsers : Evergreen.V197.OneToOne.OneToOne (Evergreen.V197.Slack.Id Evergreen.V197.Slack.UserId) (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId)
    , slackServers : Evergreen.V197.OneToOne.OneToOne (Evergreen.V197.Slack.Id Evergreen.V197.Slack.TeamId) (Evergreen.V197.Id.Id Evergreen.V197.Id.GuildId)
    , slackToken : Maybe Evergreen.V197.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V197.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V197.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V197.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V197.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId) Evergreen.V197.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId, Evergreen.V197.Discord.Id Evergreen.V197.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V197.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V197.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V197.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V197.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId) (Evergreen.V197.LocalState.LoadingDiscordChannel (List Evergreen.V197.Discord.Message))
    , signupsEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V197.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V197.Id.Id Evergreen.V197.Id.StickerId) Evergreen.V197.Sticker.StickerData
    , discordStickers : Evergreen.V197.OneToOne.OneToOne (Evergreen.V197.Discord.Id Evergreen.V197.Discord.StickerId) (Evergreen.V197.Id.Id Evergreen.V197.Id.StickerId)
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V197.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V197.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V197.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V197.Route.Route
    | SelectedFilesToAttach ( Evergreen.V197.Id.AnyGuildOrDmId, Evergreen.V197.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V197.Id.Id Evergreen.V197.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V197.Id.Id Evergreen.V197.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V197.Id.Id Evergreen.V197.Id.GuildId) (Evergreen.V197.Id.Id Evergreen.V197.Id.ChannelId) Evergreen.V197.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V197.Id.Id Evergreen.V197.Id.GuildId) (Evergreen.V197.Id.Id Evergreen.V197.Id.ChannelId) Evergreen.V197.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V197.Discord.Id Evergreen.V197.Discord.GuildId) (Evergreen.V197.Discord.Id Evergreen.V197.Discord.ChannelId) Evergreen.V197.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V197.Discord.Id Evergreen.V197.Discord.GuildId) (Evergreen.V197.Discord.Id Evergreen.V197.Discord.ChannelId) Evergreen.V197.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V197.Id.Id Evergreen.V197.Id.GuildId) (Evergreen.V197.Id.Id Evergreen.V197.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V197.Id.Id Evergreen.V197.Id.GuildId) (Evergreen.V197.Id.Id Evergreen.V197.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V197.Id.Id Evergreen.V197.Id.GuildId) (Evergreen.V197.Id.Id Evergreen.V197.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V197.Id.Id Evergreen.V197.Id.GuildId) (Evergreen.V197.Id.Id Evergreen.V197.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V197.Id.Id Evergreen.V197.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V197.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V197.Id.AnyGuildOrDmId Evergreen.V197.Id.ThreadRouteWithMessage (Evergreen.V197.Coord.Coord Evergreen.V197.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V197.Emoji.Emoji
    | MessageMenu_PressedEditMessage Evergreen.V197.Id.AnyGuildOrDmId Evergreen.V197.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V197.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V197.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V197.Id.Id Evergreen.V197.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V197.Id.AnyGuildOrDmId, Evergreen.V197.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V197.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V197.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V197.Id.AnyGuildOrDmId, Evergreen.V197.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V197.NonemptyDict.NonemptyDict Int Evergreen.V197.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V197.NonemptyDict.NonemptyDict Int Evergreen.V197.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V197.Id.AnyGuildOrDmId Evergreen.V197.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V197.Id.AnyGuildOrDmId Evergreen.V197.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V197.Id.AnyGuildOrDmId, Evergreen.V197.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V197.Id.AnyGuildOrDmId Evergreen.V197.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V197.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V197.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V197.Editable.Msg Evergreen.V197.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V197.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V197.Id.AnyGuildOrDmId, Evergreen.V197.Id.ThreadRoute ) (Evergreen.V197.Id.Id Evergreen.V197.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V197.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V197.Id.AnyGuildOrDmId, Evergreen.V197.Id.ThreadRoute ) (Evergreen.V197.Id.Id Evergreen.V197.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V197.Id.AnyGuildOrDmId, Evergreen.V197.Id.ThreadRoute ) (Evergreen.V197.Id.Id Evergreen.V197.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V197.Id.AnyGuildOrDmId, Evergreen.V197.Id.ThreadRoute )
        { fileId : Evergreen.V197.Id.Id Evergreen.V197.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V197.Id.AnyGuildOrDmId, Evergreen.V197.Id.ThreadRoute ) (Evergreen.V197.Id.Id Evergreen.V197.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V197.Id.AnyGuildOrDmId, Evergreen.V197.Id.ThreadRoute ) (Evergreen.V197.Id.Id Evergreen.V197.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V197.Id.AnyGuildOrDmId, Evergreen.V197.Id.ThreadRoute )
        { fileId : Evergreen.V197.Id.Id Evergreen.V197.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V197.Id.AnyGuildOrDmId, Evergreen.V197.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V197.Id.AnyGuildOrDmId, Evergreen.V197.Id.ThreadRoute ) (Evergreen.V197.Id.Id Evergreen.V197.Id.ChannelMessageId) (Evergreen.V197.Id.Id Evergreen.V197.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V197.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V197.Id.AnyGuildOrDmId, Evergreen.V197.Id.ThreadRoute ) (Evergreen.V197.Id.Id Evergreen.V197.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V197.Id.AnyGuildOrDmId Evergreen.V197.Id.ThreadRouteWithMessage Evergreen.V197.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V197.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V197.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V197.Id.Id Evergreen.V197.Id.GuildId) Evergreen.V197.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId) (Evergreen.V197.Discord.Id Evergreen.V197.Discord.GuildId) Evergreen.V197.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V197.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V197.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId
        , otherUserId : Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | PressedRemoveDomainFromWhitelist Evergreen.V197.RichText.Domain
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V197.Id.AnyGuildOrDmId Evergreen.V197.Id.ThreadRoute Evergreen.V197.MessageInput.Msg
    | MessageInputMsg Evergreen.V197.Id.AnyGuildOrDmId Evergreen.V197.Id.ThreadRoute Evergreen.V197.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V197.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V197.Range.Range, Evergreen.V197.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V197.Range.Range, Evergreen.V197.Range.SelectionDirection ) )


type InitialLoadRequest
    = InitialLoadRequested_Channel Evergreen.V197.Id.AnyGuildOrDmId Evergreen.V197.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V197.Id.Id Evergreen.V197.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V197.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V197.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V197.Untrusted.Untrusted Evergreen.V197.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V197.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V197.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V197.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V197.Id.Id Evergreen.V197.Id.GuildId) (Evergreen.V197.SecretId.SecretId Evergreen.V197.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V197.PersonName.PersonName Evergreen.V197.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V197.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V197.Slack.OAuthCode Evergreen.V197.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V197.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V197.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V197.Id.Id Evergreen.V197.Pagination.PageId))


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V197.EmailAddress.EmailAddress (Result Evergreen.V197.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V197.EmailAddress.EmailAddress (Result Evergreen.V197.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId) Evergreen.V197.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V197.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V197.Discord.Id Evergreen.V197.Discord.GuildId) (Evergreen.V197.Discord.Id Evergreen.V197.Discord.ChannelId) Evergreen.V197.Id.ThreadRouteWithMaybeMessage (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId) (Result Evergreen.V197.Discord.HttpError Evergreen.V197.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V197.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V197.Discord.Id Evergreen.V197.Discord.PrivateChannelId) (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId) (Result Evergreen.V197.Discord.HttpError Evergreen.V197.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V197.Discord.Id Evergreen.V197.Discord.GuildId) (Evergreen.V197.Discord.Id Evergreen.V197.Discord.ChannelId) Evergreen.V197.Id.ThreadRouteWithMessage (Evergreen.V197.Discord.Id Evergreen.V197.Discord.MessageId) (Result Evergreen.V197.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V197.Discord.Id Evergreen.V197.Discord.PrivateChannelId) (Evergreen.V197.Id.Id Evergreen.V197.Id.ChannelMessageId) (Evergreen.V197.Discord.Id Evergreen.V197.Discord.MessageId) (Result Evergreen.V197.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V197.Discord.Id Evergreen.V197.Discord.GuildId) (Evergreen.V197.Discord.Id Evergreen.V197.Discord.ChannelId) Evergreen.V197.Id.ThreadRouteWithMessage (Evergreen.V197.Discord.Id Evergreen.V197.Discord.MessageId) (Result Evergreen.V197.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V197.Discord.Id Evergreen.V197.Discord.PrivateChannelId) (Evergreen.V197.Id.Id Evergreen.V197.Id.ChannelMessageId) (Evergreen.V197.Discord.Id Evergreen.V197.Discord.MessageId) (Result Evergreen.V197.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V197.Discord.Id Evergreen.V197.Discord.GuildId) (Evergreen.V197.Discord.Id Evergreen.V197.Discord.ChannelId) Evergreen.V197.Id.ThreadRouteWithMessage (Evergreen.V197.Discord.Id Evergreen.V197.Discord.MessageId) Evergreen.V197.Emoji.Emoji (Result Evergreen.V197.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V197.Discord.Id Evergreen.V197.Discord.PrivateChannelId) (Evergreen.V197.Id.Id Evergreen.V197.Id.ChannelMessageId) (Evergreen.V197.Discord.Id Evergreen.V197.Discord.MessageId) Evergreen.V197.Emoji.Emoji (Result Evergreen.V197.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V197.Discord.Id Evergreen.V197.Discord.GuildId) (Evergreen.V197.Discord.Id Evergreen.V197.Discord.ChannelId) Evergreen.V197.Id.ThreadRouteWithMessage (Evergreen.V197.Discord.Id Evergreen.V197.Discord.MessageId) Evergreen.V197.Emoji.Emoji (Result Evergreen.V197.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V197.Discord.Id Evergreen.V197.Discord.PrivateChannelId) (Evergreen.V197.Id.Id Evergreen.V197.Id.ChannelMessageId) (Evergreen.V197.Discord.Id Evergreen.V197.Discord.MessageId) Evergreen.V197.Emoji.Emoji (Result Evergreen.V197.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V197.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V197.Discord.HttpError (List ( Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId, Maybe Evergreen.V197.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V197.Slack.CurrentUser
            , team : Evergreen.V197.Slack.Team
            , users : List Evergreen.V197.Slack.User
            , channels : List ( Evergreen.V197.Slack.Channel, List Evergreen.V197.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId) (Result Effect.Http.Error Evergreen.V197.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId) Evergreen.V197.Discord.UserAuth (Result Evergreen.V197.Discord.HttpError Evergreen.V197.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId) (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId) (Result Evergreen.V197.Discord.HttpError Evergreen.V197.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId)
        (Result
            Evergreen.V197.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V197.Discord.Id Evergreen.V197.Discord.PrivateChannelId
                , members : List (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId)
                }
            , List
                ( Evergreen.V197.Discord.Id Evergreen.V197.Discord.GuildId
                , { guild : Evergreen.V197.Discord.GatewayGuild
                  , channels : List Evergreen.V197.Discord.Channel
                  , icon : Maybe Evergreen.V197.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId) Bool
    | WebsocketSentDataForUser (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V197.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V197.Discord.Id Evergreen.V197.Discord.AttachmentId, Evergreen.V197.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V197.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V197.Discord.Id Evergreen.V197.Discord.AttachmentId, Evergreen.V197.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId) (Evergreen.V197.Discord.Id Evergreen.V197.Discord.GuildId) (Evergreen.V197.Discord.Id Evergreen.V197.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V197.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V197.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId) (Evergreen.V197.Discord.Id Evergreen.V197.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V197.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V197.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId) (Evergreen.V197.Discord.Id Evergreen.V197.Discord.GuildId) (Evergreen.V197.Discord.Id Evergreen.V197.Discord.ChannelId) (Result Evergreen.V197.Discord.HttpError (List Evergreen.V197.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId) (Evergreen.V197.Discord.Id Evergreen.V197.Discord.PrivateChannelId) (Result Evergreen.V197.Discord.HttpError (List Evergreen.V197.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V197.Id.Id Evergreen.V197.Id.GuildId) (Evergreen.V197.Id.Id Evergreen.V197.Id.ChannelId) Evergreen.V197.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V197.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V197.DmChannel.DmChannelId Evergreen.V197.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V197.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V197.Discord.Id Evergreen.V197.Discord.GuildId) (Evergreen.V197.Discord.Id Evergreen.V197.Discord.ChannelId) Evergreen.V197.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V197.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V197.Discord.Id Evergreen.V197.Discord.PrivateChannelId) (Evergreen.V197.Id.Id Evergreen.V197.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V197.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId)
        (Evergreen.V197.Discord.Id Evergreen.V197.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V197.Discord.HttpError
            { guild : Evergreen.V197.Discord.GatewayGuild
            , channels : List Evergreen.V197.Discord.Channel
            , icon : Maybe Evergreen.V197.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V197.Discord.Id Evergreen.V197.Discord.GuildId) (Result Evergreen.V197.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V197.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordGuildStickers (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId) (List ( Evergreen.V197.Id.Id Evergreen.V197.Id.StickerId, Result Effect.Http.Error Evergreen.V197.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V197.Discord.HttpError (List Evergreen.V197.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
