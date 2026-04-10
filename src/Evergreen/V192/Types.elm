module Evergreen.V192.Types exposing (..)

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
import Evergreen.V192.AiChat
import Evergreen.V192.ChannelName
import Evergreen.V192.Coord
import Evergreen.V192.CssPixels
import Evergreen.V192.Discord
import Evergreen.V192.DiscordAttachmentId
import Evergreen.V192.DiscordUserData
import Evergreen.V192.DmChannel
import Evergreen.V192.Editable
import Evergreen.V192.EmailAddress
import Evergreen.V192.Embed
import Evergreen.V192.Emoji
import Evergreen.V192.FileStatus
import Evergreen.V192.GuildName
import Evergreen.V192.Id
import Evergreen.V192.ImageEditor
import Evergreen.V192.Local
import Evergreen.V192.LocalState
import Evergreen.V192.Log
import Evergreen.V192.LoginForm
import Evergreen.V192.MembersAndOwner
import Evergreen.V192.Message
import Evergreen.V192.MessageInput
import Evergreen.V192.MessageView
import Evergreen.V192.NonemptyDict
import Evergreen.V192.NonemptySet
import Evergreen.V192.OneToOne
import Evergreen.V192.Pages.Admin
import Evergreen.V192.Pagination
import Evergreen.V192.PersonName
import Evergreen.V192.Ports
import Evergreen.V192.Postmark
import Evergreen.V192.Range
import Evergreen.V192.RichText
import Evergreen.V192.Route
import Evergreen.V192.SecretId
import Evergreen.V192.SessionIdHash
import Evergreen.V192.Slack
import Evergreen.V192.Sticker
import Evergreen.V192.TextEditor
import Evergreen.V192.ToBackendLog
import Evergreen.V192.Touch
import Evergreen.V192.TwoFactorAuthentication
import Evergreen.V192.Ui.Anim
import Evergreen.V192.Untrusted
import Evergreen.V192.User
import Evergreen.V192.UserAgent
import Evergreen.V192.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V192.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V192.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V192.Id.Id Evergreen.V192.Id.GuildId) Evergreen.V192.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId) Evergreen.V192.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V192.Discord.Id Evergreen.V192.Discord.PrivateChannelId) Evergreen.V192.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V192.Discord.Id Evergreen.V192.Discord.GuildId) Evergreen.V192.LocalState.DiscordFrontendGuild
    , user : Evergreen.V192.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId) Evergreen.V192.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId) Evergreen.V192.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId) Evergreen.V192.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V192.SessionIdHash.SessionIdHash Evergreen.V192.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V192.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V192.Id.Id Evergreen.V192.Id.StickerId) Evergreen.V192.Sticker.StickerData
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V192.Route.Route
    , windowSize : Evergreen.V192.Coord.Coord Evergreen.V192.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V192.Ports.NotificationPermission
    , pwaStatus : Evergreen.V192.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V192.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V192.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V192.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V192.RichText.RichText (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId))) Evergreen.V192.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V192.Id.Id Evergreen.V192.FileStatus.FileId) Evergreen.V192.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V192.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V192.RichText.RichText (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId))) Evergreen.V192.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V192.Id.Id Evergreen.V192.FileStatus.FileId) Evergreen.V192.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V192.Id.Id Evergreen.V192.Id.GuildId) Evergreen.V192.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V192.Id.Id Evergreen.V192.Id.GuildId) (Evergreen.V192.Id.Id Evergreen.V192.Id.ChannelId) Evergreen.V192.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V192.Id.Id Evergreen.V192.Id.GuildId) (Evergreen.V192.Id.Id Evergreen.V192.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V192.Id.Id Evergreen.V192.Id.GuildId) (Evergreen.V192.UserSession.ToBeFilledInByBackend (Evergreen.V192.SecretId.SecretId Evergreen.V192.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V192.GuildName.GuildName (Evergreen.V192.UserSession.ToBeFilledInByBackend (Evergreen.V192.Id.Id Evergreen.V192.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V192.Id.AnyGuildOrDmId, Evergreen.V192.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V192.Id.AnyGuildOrDmId Evergreen.V192.Id.ThreadRouteWithMessage Evergreen.V192.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V192.Id.AnyGuildOrDmId Evergreen.V192.Id.ThreadRouteWithMessage Evergreen.V192.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V192.Id.GuildOrDmId Evergreen.V192.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V192.RichText.RichText (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId))) (SeqDict.SeqDict (Evergreen.V192.Id.Id Evergreen.V192.FileStatus.FileId) Evergreen.V192.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId) (Evergreen.V192.Discord.Id Evergreen.V192.Discord.GuildId) (Evergreen.V192.Discord.Id Evergreen.V192.Discord.ChannelId) Evergreen.V192.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V192.RichText.RichText (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId)))
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V192.Id.DiscordGuildOrDmId_DmData (Evergreen.V192.Id.Id Evergreen.V192.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V192.RichText.RichText (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId)))
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V192.Id.AnyGuildOrDmId Evergreen.V192.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V192.Id.AnyGuildOrDmId Evergreen.V192.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V192.Id.AnyGuildOrDmId Evergreen.V192.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V192.UserSession.SetViewing
    | Local_SetName Evergreen.V192.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V192.Id.GuildOrDmId (Evergreen.V192.Id.Id Evergreen.V192.Id.ChannelMessageId) (Evergreen.V192.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V192.Id.Id Evergreen.V192.Id.ChannelMessageId) (Evergreen.V192.Message.Message Evergreen.V192.Id.ChannelMessageId (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V192.Id.GuildOrDmId (Evergreen.V192.Id.Id Evergreen.V192.Id.ChannelMessageId) (Evergreen.V192.Id.Id Evergreen.V192.Id.ThreadMessageId) (Evergreen.V192.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V192.Id.Id Evergreen.V192.Id.ThreadMessageId) (Evergreen.V192.Message.Message Evergreen.V192.Id.ThreadMessageId (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V192.Id.DiscordGuildOrDmId (Evergreen.V192.Id.Id Evergreen.V192.Id.ChannelMessageId) (Evergreen.V192.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V192.Id.Id Evergreen.V192.Id.ChannelMessageId) (Evergreen.V192.Message.Message Evergreen.V192.Id.ChannelMessageId (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V192.Id.DiscordGuildOrDmId (Evergreen.V192.Id.Id Evergreen.V192.Id.ChannelMessageId) (Evergreen.V192.Id.Id Evergreen.V192.Id.ThreadMessageId) (Evergreen.V192.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V192.Id.Id Evergreen.V192.Id.ThreadMessageId) (Evergreen.V192.Message.Message Evergreen.V192.Id.ThreadMessageId (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V192.Id.Id Evergreen.V192.Id.GuildId) Evergreen.V192.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId) (Evergreen.V192.Discord.Id Evergreen.V192.Discord.GuildId) Evergreen.V192.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V192.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V192.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V192.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V192.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V192.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V192.Emoji.SkinTone)


type ServerChange
    = Server_SendMessage (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId) Effect.Time.Posix Evergreen.V192.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V192.RichText.RichText (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId))) Evergreen.V192.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V192.Id.Id Evergreen.V192.FileStatus.FileId) Evergreen.V192.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V192.Id.Id Evergreen.V192.Id.StickerId) Evergreen.V192.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V192.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V192.RichText.RichText (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId))) Evergreen.V192.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V192.Id.Id Evergreen.V192.FileStatus.FileId) Evergreen.V192.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V192.Id.Id Evergreen.V192.Id.StickerId) Evergreen.V192.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V192.Id.Id Evergreen.V192.Id.GuildId) Evergreen.V192.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V192.Id.Id Evergreen.V192.Id.GuildId) (Evergreen.V192.Id.Id Evergreen.V192.Id.ChannelId) Evergreen.V192.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V192.Id.Id Evergreen.V192.Id.GuildId) (Evergreen.V192.Id.Id Evergreen.V192.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId) (Evergreen.V192.Id.Id Evergreen.V192.Id.GuildId) (Evergreen.V192.SecretId.SecretId Evergreen.V192.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId) (Evergreen.V192.Id.Id Evergreen.V192.Id.GuildId) Evergreen.V192.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V192.LocalState.JoinGuildError
            { guildId : Evergreen.V192.Id.Id Evergreen.V192.Id.GuildId
            , guild : Evergreen.V192.LocalState.FrontendGuild
            , owner : Evergreen.V192.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId) Evergreen.V192.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId) Evergreen.V192.Id.GuildOrDmId Evergreen.V192.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId) (Evergreen.V192.Discord.Id Evergreen.V192.Discord.GuildId) (Evergreen.V192.Discord.Id Evergreen.V192.Discord.ChannelId) Evergreen.V192.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId) (Evergreen.V192.Discord.Id Evergreen.V192.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId) Evergreen.V192.Id.GuildOrDmId Evergreen.V192.Id.ThreadRouteWithMessage Evergreen.V192.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId) Evergreen.V192.Id.GuildOrDmId Evergreen.V192.Id.ThreadRouteWithMessage Evergreen.V192.Emoji.Emoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId) (Evergreen.V192.Discord.Id Evergreen.V192.Discord.GuildId) (Evergreen.V192.Discord.Id Evergreen.V192.Discord.ChannelId) Evergreen.V192.Id.ThreadRouteWithMessage Evergreen.V192.Emoji.Emoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId) (Evergreen.V192.Discord.Id Evergreen.V192.Discord.PrivateChannelId) (Evergreen.V192.Id.Id Evergreen.V192.Id.ChannelMessageId) Evergreen.V192.Emoji.Emoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId) (Evergreen.V192.Discord.Id Evergreen.V192.Discord.GuildId) (Evergreen.V192.Discord.Id Evergreen.V192.Discord.ChannelId) Evergreen.V192.Id.ThreadRouteWithMessage Evergreen.V192.Emoji.Emoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId) (Evergreen.V192.Discord.Id Evergreen.V192.Discord.PrivateChannelId) (Evergreen.V192.Id.Id Evergreen.V192.Id.ChannelMessageId) Evergreen.V192.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId) Evergreen.V192.Id.GuildOrDmId Evergreen.V192.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V192.RichText.RichText (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId))) (SeqDict.SeqDict (Evergreen.V192.Id.Id Evergreen.V192.FileStatus.FileId) Evergreen.V192.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId) (Evergreen.V192.Discord.Id Evergreen.V192.Discord.GuildId) (Evergreen.V192.Discord.Id Evergreen.V192.Discord.ChannelId) Evergreen.V192.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V192.RichText.RichText (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V192.Id.DiscordGuildOrDmId_DmData (Evergreen.V192.Id.Id Evergreen.V192.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V192.RichText.RichText (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId) Evergreen.V192.Id.AnyGuildOrDmId Evergreen.V192.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V192.Id.AnyGuildOrDmId Evergreen.V192.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V192.Discord.Id Evergreen.V192.Discord.GuildId) (Evergreen.V192.Discord.Id Evergreen.V192.Discord.ChannelId) Evergreen.V192.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V192.Discord.Id Evergreen.V192.Discord.PrivateChannelId) (Evergreen.V192.Id.Id Evergreen.V192.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId) Evergreen.V192.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId) Evergreen.V192.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V192.Id.Id Evergreen.V192.Id.GuildId) Evergreen.V192.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V192.Discord.Id Evergreen.V192.Discord.GuildId) Evergreen.V192.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V192.SessionIdHash.SessionIdHash Evergreen.V192.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V192.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V192.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V192.Id.AnyGuildOrDmId, Evergreen.V192.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V192.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId) Evergreen.V192.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V192.Discord.Id Evergreen.V192.Discord.GuildId) (Evergreen.V192.Discord.Id Evergreen.V192.Discord.ChannelId) Evergreen.V192.ChannelName.ChannelName (Evergreen.V192.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V192.Discord.Id Evergreen.V192.Discord.PrivateChannelId)
        (Evergreen.V192.NonemptyDict.NonemptyDict
            (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V192.Discord.Id Evergreen.V192.Discord.GuildId) Evergreen.V192.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V192.Discord.Id Evergreen.V192.Discord.PrivateChannelId) Evergreen.V192.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId) Evergreen.V192.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId) (Maybe (Evergreen.V192.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V192.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V192.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V192.Id.Id Evergreen.V192.Id.GuildId) (Evergreen.V192.Id.Id Evergreen.V192.Id.ChannelId) Evergreen.V192.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V192.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId) Evergreen.V192.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V192.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V192.Discord.Id Evergreen.V192.Discord.GuildId) (Evergreen.V192.Discord.Id Evergreen.V192.Discord.ChannelId) Evergreen.V192.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V192.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V192.Discord.Id Evergreen.V192.Discord.PrivateChannelId) (Evergreen.V192.Id.Id Evergreen.V192.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V192.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V192.Discord.Id Evergreen.V192.Discord.GuildId) Evergreen.V192.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V192.Discord.Id Evergreen.V192.Discord.GuildId) (Evergreen.V192.Discord.Id Evergreen.V192.Discord.ChannelId) (Evergreen.V192.Discord.OptionalData String) (Evergreen.V192.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V192.Discord.Id Evergreen.V192.Discord.GuildId)
        (Evergreen.V192.MembersAndOwner.MembersAndOwner
            (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V192.Discord.Id Evergreen.V192.Discord.GuildId) (Evergreen.V192.Discord.Id Evergreen.V192.Discord.ChannelId) (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId) Evergreen.V192.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V192.Id.Id Evergreen.V192.Id.StickerId) Evergreen.V192.Sticker.StickerData)


type LocalMsg
    = LocalChange (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V192.Id.Id Evergreen.V192.Id.GuildId) (Evergreen.V192.Id.Id Evergreen.V192.Id.ChannelId) Evergreen.V192.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V192.Discord.Id Evergreen.V192.Discord.GuildId) (Evergreen.V192.Discord.Id Evergreen.V192.Discord.ChannelId) Evergreen.V192.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V192.Id.Id Evergreen.V192.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V192.Id.Id Evergreen.V192.FileStatus.FileId) Evergreen.V192.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V192.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V192.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V192.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V192.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V192.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V192.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V192.Coord.Coord Evergreen.V192.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V192.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V192.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V192.Id.AnyGuildOrDmId Evergreen.V192.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V192.Id.AnyGuildOrDmId Evergreen.V192.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V192.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V192.Coord.Coord Evergreen.V192.CssPixels.CssPixels) (Maybe Evergreen.V192.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V192.Id.AnyGuildOrDmId, Evergreen.V192.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V192.Id.Id Evergreen.V192.Id.ChannelMessageId) (Evergreen.V192.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V192.Id.Id Evergreen.V192.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V192.Id.Id Evergreen.V192.Id.ThreadMessageId) (Evergreen.V192.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V192.Editable.Model
    , showLinkDiscordSetup : Bool
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V192.Local.Local LocalMsg Evergreen.V192.LocalState.LocalState
    , admin : Evergreen.V192.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V192.Id.AnyGuildOrDmId, Evergreen.V192.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V192.Id.Id Evergreen.V192.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V192.Id.Id Evergreen.V192.Id.GuildId, Evergreen.V192.Id.Id Evergreen.V192.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V192.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V192.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V192.Id.AnyGuildOrDmId, Evergreen.V192.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V192.Id.AnyGuildOrDmId, Evergreen.V192.Id.ThreadRoute ) (Evergreen.V192.Id.Id Evergreen.V192.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V192.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V192.Id.AnyGuildOrDmId, Evergreen.V192.Id.ThreadRoute ) (Evergreen.V192.NonemptyDict.NonemptyDict (Evergreen.V192.Id.Id Evergreen.V192.FileStatus.FileId) Evergreen.V192.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V192.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V192.TextEditor.Model
    , profilePictureEditor : Evergreen.V192.ImageEditor.Model
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V192.Emoji.Model
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V192.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V192.SecretId.SecretId Evergreen.V192.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V192.Range.Range
                , direction : Evergreen.V192.Range.SelectionDirection
                }
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V192.NonemptyDict.NonemptyDict Int Evergreen.V192.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V192.NonemptyDict.NonemptyDict Int Evergreen.V192.Touch.Touch
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
    | AdminToFrontend Evergreen.V192.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V192.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V192.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V192.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V192.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V192.ImageEditor.ToFrontend


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V192.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V192.Coord.Coord Evergreen.V192.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V192.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , notificationPermission : Evergreen.V192.Ports.NotificationPermission
    , pwaStatus : Evergreen.V192.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V192.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V192.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V192.Emoji.CachedEmojiData
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V192.Id.Id Evergreen.V192.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V192.Id.Id Evergreen.V192.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V192.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V192.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V192.Coord.Coord Evergreen.V192.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V192.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V192.FileStatus.ImageMetadata
    }


type alias ExportState =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V192.Id.Id Evergreen.V192.Id.GuildId, Evergreen.V192.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V192.DmChannel.DmChannelId, Evergreen.V192.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V192.Discord.Id Evergreen.V192.Discord.GuildId, Evergreen.V192.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V192.Discord.Id Evergreen.V192.Discord.PrivateChannelId, Evergreen.V192.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    , exportSubset : Evergreen.V192.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V192.NonemptyDict.NonemptyDict (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId) Evergreen.V192.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V192.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V192.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V192.LocalState.LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V192.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId) Evergreen.V192.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId) Evergreen.V192.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V192.Id.Id Evergreen.V192.Id.GuildId) Evergreen.V192.LocalState.BackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V192.Discord.Id Evergreen.V192.Discord.GuildId) Evergreen.V192.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V192.DmChannel.DmChannelId Evergreen.V192.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V192.Discord.Id Evergreen.V192.Discord.PrivateChannelId) Evergreen.V192.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V192.OneToOne.OneToOne (Evergreen.V192.Slack.Id Evergreen.V192.Slack.ChannelId) Evergreen.V192.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V192.OneToOne.OneToOne String (Evergreen.V192.Id.Id Evergreen.V192.Id.GuildId)
    , slackUsers : Evergreen.V192.OneToOne.OneToOne (Evergreen.V192.Slack.Id Evergreen.V192.Slack.UserId) (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId)
    , slackServers : Evergreen.V192.OneToOne.OneToOne (Evergreen.V192.Slack.Id Evergreen.V192.Slack.TeamId) (Evergreen.V192.Id.Id Evergreen.V192.Id.GuildId)
    , slackToken : Maybe Evergreen.V192.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V192.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V192.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V192.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V192.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId) Evergreen.V192.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId, Evergreen.V192.Discord.Id Evergreen.V192.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V192.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V192.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V192.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V192.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId) (Evergreen.V192.LocalState.LoadingDiscordChannel (List Evergreen.V192.Discord.Message))
    , signupsEnabled : Bool
    , exportState : Maybe ExportState
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V192.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V192.Id.Id Evergreen.V192.Id.StickerId) Evergreen.V192.Sticker.StickerData
    , discordStickers : Evergreen.V192.OneToOne.OneToOne (Evergreen.V192.Discord.Id Evergreen.V192.Discord.StickerId) (Evergreen.V192.Id.Id Evergreen.V192.Id.StickerId)
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V192.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V192.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V192.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V192.Route.Route
    | SelectedFilesToAttach ( Evergreen.V192.Id.AnyGuildOrDmId, Evergreen.V192.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V192.Id.Id Evergreen.V192.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V192.Id.Id Evergreen.V192.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V192.Id.Id Evergreen.V192.Id.GuildId) (Evergreen.V192.Id.Id Evergreen.V192.Id.ChannelId) Evergreen.V192.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V192.Id.Id Evergreen.V192.Id.GuildId) (Evergreen.V192.Id.Id Evergreen.V192.Id.ChannelId) Evergreen.V192.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V192.Discord.Id Evergreen.V192.Discord.GuildId) (Evergreen.V192.Discord.Id Evergreen.V192.Discord.ChannelId) Evergreen.V192.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V192.Discord.Id Evergreen.V192.Discord.GuildId) (Evergreen.V192.Discord.Id Evergreen.V192.Discord.ChannelId) Evergreen.V192.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V192.Id.Id Evergreen.V192.Id.GuildId) (Evergreen.V192.Id.Id Evergreen.V192.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V192.Id.Id Evergreen.V192.Id.GuildId) (Evergreen.V192.Id.Id Evergreen.V192.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V192.Id.Id Evergreen.V192.Id.GuildId) (Evergreen.V192.Id.Id Evergreen.V192.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V192.Id.Id Evergreen.V192.Id.GuildId) (Evergreen.V192.Id.Id Evergreen.V192.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V192.Id.Id Evergreen.V192.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V192.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V192.Id.AnyGuildOrDmId Evergreen.V192.Id.ThreadRouteWithMessage (Evergreen.V192.Coord.Coord Evergreen.V192.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V192.Emoji.Emoji
    | MessageMenu_PressedEditMessage Evergreen.V192.Id.AnyGuildOrDmId Evergreen.V192.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V192.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V192.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V192.Id.Id Evergreen.V192.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V192.Id.AnyGuildOrDmId, Evergreen.V192.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V192.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V192.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V192.Id.AnyGuildOrDmId, Evergreen.V192.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V192.NonemptyDict.NonemptyDict Int Evergreen.V192.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V192.NonemptyDict.NonemptyDict Int Evergreen.V192.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V192.Id.AnyGuildOrDmId Evergreen.V192.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V192.Id.AnyGuildOrDmId Evergreen.V192.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V192.Id.AnyGuildOrDmId, Evergreen.V192.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V192.Id.AnyGuildOrDmId Evergreen.V192.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V192.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V192.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V192.Editable.Msg Evergreen.V192.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V192.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V192.Id.AnyGuildOrDmId, Evergreen.V192.Id.ThreadRoute ) (Evergreen.V192.Id.Id Evergreen.V192.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V192.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V192.Id.AnyGuildOrDmId, Evergreen.V192.Id.ThreadRoute ) (Evergreen.V192.Id.Id Evergreen.V192.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V192.Id.AnyGuildOrDmId, Evergreen.V192.Id.ThreadRoute ) (Evergreen.V192.Id.Id Evergreen.V192.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V192.Id.AnyGuildOrDmId, Evergreen.V192.Id.ThreadRoute ) (Evergreen.V192.Id.Id Evergreen.V192.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V192.Id.AnyGuildOrDmId, Evergreen.V192.Id.ThreadRoute ) (Evergreen.V192.Id.Id Evergreen.V192.FileStatus.FileId)
    | EditMessage_SelectedFilesToAttach ( Evergreen.V192.Id.AnyGuildOrDmId, Evergreen.V192.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V192.Id.AnyGuildOrDmId, Evergreen.V192.Id.ThreadRoute ) (Evergreen.V192.Id.Id Evergreen.V192.Id.ChannelMessageId) (Evergreen.V192.Id.Id Evergreen.V192.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V192.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V192.Id.AnyGuildOrDmId, Evergreen.V192.Id.ThreadRoute ) (Evergreen.V192.Id.Id Evergreen.V192.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V192.Id.AnyGuildOrDmId Evergreen.V192.Id.ThreadRouteWithMessage Evergreen.V192.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V192.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V192.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V192.Id.Id Evergreen.V192.Id.GuildId) Evergreen.V192.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId) (Evergreen.V192.Discord.Id Evergreen.V192.Discord.GuildId) Evergreen.V192.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V192.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V192.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId
        , otherUserId : Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | PressedRemoveDomainFromWhitelist Evergreen.V192.RichText.Domain
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V192.Id.AnyGuildOrDmId Evergreen.V192.Id.ThreadRoute Evergreen.V192.MessageInput.Msg
    | MessageInputMsg Evergreen.V192.Id.AnyGuildOrDmId Evergreen.V192.Id.ThreadRoute Evergreen.V192.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V192.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V192.Range.Range, Evergreen.V192.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V192.Range.Range, Evergreen.V192.Range.SelectionDirection ) )


type InitialLoadRequest
    = InitialLoadRequested_Channel Evergreen.V192.Id.AnyGuildOrDmId Evergreen.V192.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V192.Id.Id Evergreen.V192.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V192.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V192.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V192.Untrusted.Untrusted Evergreen.V192.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V192.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V192.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V192.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V192.Id.Id Evergreen.V192.Id.GuildId) (Evergreen.V192.SecretId.SecretId Evergreen.V192.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V192.PersonName.PersonName Evergreen.V192.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V192.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V192.Slack.OAuthCode Evergreen.V192.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V192.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V192.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V192.Id.Id Evergreen.V192.Pagination.PageId))


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V192.EmailAddress.EmailAddress (Result Evergreen.V192.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V192.EmailAddress.EmailAddress (Result Evergreen.V192.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId) Evergreen.V192.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V192.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V192.Discord.Id Evergreen.V192.Discord.GuildId) (Evergreen.V192.Discord.Id Evergreen.V192.Discord.ChannelId) Evergreen.V192.Id.ThreadRouteWithMaybeMessage (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId) (Result Evergreen.V192.Discord.HttpError Evergreen.V192.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V192.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V192.Discord.Id Evergreen.V192.Discord.PrivateChannelId) (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId) (Result Evergreen.V192.Discord.HttpError Evergreen.V192.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V192.Discord.Id Evergreen.V192.Discord.GuildId) (Evergreen.V192.Discord.Id Evergreen.V192.Discord.ChannelId) Evergreen.V192.Id.ThreadRouteWithMessage (Evergreen.V192.Discord.Id Evergreen.V192.Discord.MessageId) (Result Evergreen.V192.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V192.Discord.Id Evergreen.V192.Discord.PrivateChannelId) (Evergreen.V192.Id.Id Evergreen.V192.Id.ChannelMessageId) (Evergreen.V192.Discord.Id Evergreen.V192.Discord.MessageId) (Result Evergreen.V192.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V192.Discord.Id Evergreen.V192.Discord.GuildId) (Evergreen.V192.Discord.Id Evergreen.V192.Discord.ChannelId) Evergreen.V192.Id.ThreadRouteWithMessage (Evergreen.V192.Discord.Id Evergreen.V192.Discord.MessageId) (Result Evergreen.V192.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V192.Discord.Id Evergreen.V192.Discord.PrivateChannelId) (Evergreen.V192.Id.Id Evergreen.V192.Id.ChannelMessageId) (Evergreen.V192.Discord.Id Evergreen.V192.Discord.MessageId) (Result Evergreen.V192.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V192.Discord.Id Evergreen.V192.Discord.GuildId) (Evergreen.V192.Discord.Id Evergreen.V192.Discord.ChannelId) Evergreen.V192.Id.ThreadRouteWithMessage (Evergreen.V192.Discord.Id Evergreen.V192.Discord.MessageId) Evergreen.V192.Emoji.Emoji (Result Evergreen.V192.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V192.Discord.Id Evergreen.V192.Discord.PrivateChannelId) (Evergreen.V192.Id.Id Evergreen.V192.Id.ChannelMessageId) (Evergreen.V192.Discord.Id Evergreen.V192.Discord.MessageId) Evergreen.V192.Emoji.Emoji (Result Evergreen.V192.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V192.Discord.Id Evergreen.V192.Discord.GuildId) (Evergreen.V192.Discord.Id Evergreen.V192.Discord.ChannelId) Evergreen.V192.Id.ThreadRouteWithMessage (Evergreen.V192.Discord.Id Evergreen.V192.Discord.MessageId) Evergreen.V192.Emoji.Emoji (Result Evergreen.V192.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V192.Discord.Id Evergreen.V192.Discord.PrivateChannelId) (Evergreen.V192.Id.Id Evergreen.V192.Id.ChannelMessageId) (Evergreen.V192.Discord.Id Evergreen.V192.Discord.MessageId) Evergreen.V192.Emoji.Emoji (Result Evergreen.V192.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V192.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V192.Discord.HttpError (List ( Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId, Maybe Evergreen.V192.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V192.Slack.CurrentUser
            , team : Evergreen.V192.Slack.Team
            , users : List Evergreen.V192.Slack.User
            , channels : List ( Evergreen.V192.Slack.Channel, List Evergreen.V192.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId) (Result Effect.Http.Error Evergreen.V192.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId) Evergreen.V192.Discord.UserAuth (Result Evergreen.V192.Discord.HttpError Evergreen.V192.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId) (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId) (Result Evergreen.V192.Discord.HttpError Evergreen.V192.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId)
        (Result
            Evergreen.V192.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V192.Discord.Id Evergreen.V192.Discord.PrivateChannelId
                , members : List (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId)
                }
            , List
                ( Evergreen.V192.Discord.Id Evergreen.V192.Discord.GuildId
                , { guild : Evergreen.V192.Discord.GatewayGuild
                  , channels : List Evergreen.V192.Discord.Channel
                  , icon : Maybe Evergreen.V192.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId) Bool
    | WebsocketSentDataForUser (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V192.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V192.Discord.Id Evergreen.V192.Discord.AttachmentId, Evergreen.V192.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V192.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V192.Discord.Id Evergreen.V192.Discord.AttachmentId, Evergreen.V192.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId) (Evergreen.V192.Discord.Id Evergreen.V192.Discord.GuildId) (Evergreen.V192.Discord.Id Evergreen.V192.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V192.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V192.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId) (Evergreen.V192.Discord.Id Evergreen.V192.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V192.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V192.FileStatus.UploadResponse )))
    | ExportBackendStep
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId) (Evergreen.V192.Discord.Id Evergreen.V192.Discord.GuildId) (Evergreen.V192.Discord.Id Evergreen.V192.Discord.ChannelId) (Result Evergreen.V192.Discord.HttpError (List Evergreen.V192.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId) (Evergreen.V192.Discord.Id Evergreen.V192.Discord.PrivateChannelId) (Result Evergreen.V192.Discord.HttpError (List Evergreen.V192.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V192.Id.Id Evergreen.V192.Id.GuildId) (Evergreen.V192.Id.Id Evergreen.V192.Id.ChannelId) Evergreen.V192.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V192.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V192.DmChannel.DmChannelId Evergreen.V192.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V192.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V192.Discord.Id Evergreen.V192.Discord.GuildId) (Evergreen.V192.Discord.Id Evergreen.V192.Discord.ChannelId) Evergreen.V192.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V192.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V192.Discord.Id Evergreen.V192.Discord.PrivateChannelId) (Evergreen.V192.Id.Id Evergreen.V192.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V192.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId)
        (Evergreen.V192.Discord.Id Evergreen.V192.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V192.Discord.HttpError
            { guild : Evergreen.V192.Discord.GatewayGuild
            , channels : List Evergreen.V192.Discord.Channel
            , icon : Maybe Evergreen.V192.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V192.Discord.Id Evergreen.V192.Discord.GuildId) (Result Evergreen.V192.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V192.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordGuildStickers (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId) (List ( Evergreen.V192.Id.Id Evergreen.V192.Id.StickerId, Result Effect.Http.Error Evergreen.V192.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V192.Discord.HttpError (List Evergreen.V192.Discord.StickerPack))
