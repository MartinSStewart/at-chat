module Evergreen.V190.Types exposing (..)

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
import Evergreen.V190.AiChat
import Evergreen.V190.ChannelName
import Evergreen.V190.Coord
import Evergreen.V190.CssPixels
import Evergreen.V190.Discord
import Evergreen.V190.DiscordAttachmentId
import Evergreen.V190.DiscordUserData
import Evergreen.V190.DmChannel
import Evergreen.V190.Editable
import Evergreen.V190.EmailAddress
import Evergreen.V190.Embed
import Evergreen.V190.Emoji
import Evergreen.V190.FileStatus
import Evergreen.V190.GuildName
import Evergreen.V190.Id
import Evergreen.V190.ImageEditor
import Evergreen.V190.Local
import Evergreen.V190.LocalState
import Evergreen.V190.Log
import Evergreen.V190.LoginForm
import Evergreen.V190.MembersAndOwner
import Evergreen.V190.Message
import Evergreen.V190.MessageInput
import Evergreen.V190.MessageView
import Evergreen.V190.MyUi
import Evergreen.V190.NonemptyDict
import Evergreen.V190.NonemptySet
import Evergreen.V190.OneToOne
import Evergreen.V190.Pages.Admin
import Evergreen.V190.Pagination
import Evergreen.V190.PersonName
import Evergreen.V190.Ports
import Evergreen.V190.Postmark
import Evergreen.V190.RichText
import Evergreen.V190.Route
import Evergreen.V190.SecretId
import Evergreen.V190.SessionIdHash
import Evergreen.V190.Slack
import Evergreen.V190.TextEditor
import Evergreen.V190.ToBackendLog
import Evergreen.V190.Touch
import Evergreen.V190.TwoFactorAuthentication
import Evergreen.V190.Ui.Anim
import Evergreen.V190.Untrusted
import Evergreen.V190.User
import Evergreen.V190.UserAgent
import Evergreen.V190.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V190.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V190.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V190.Id.Id Evergreen.V190.Id.GuildId) Evergreen.V190.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId) Evergreen.V190.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V190.Discord.Id Evergreen.V190.Discord.PrivateChannelId) Evergreen.V190.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V190.Discord.Id Evergreen.V190.Discord.GuildId) Evergreen.V190.LocalState.DiscordFrontendGuild
    , user : Evergreen.V190.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId) Evergreen.V190.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId) Evergreen.V190.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId) Evergreen.V190.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V190.SessionIdHash.SessionIdHash Evergreen.V190.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V190.TextEditor.LocalState
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V190.Route.Route
    , windowSize : Evergreen.V190.Coord.Coord Evergreen.V190.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V190.Ports.NotificationPermission
    , pwaStatus : Evergreen.V190.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V190.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V190.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V190.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V190.RichText.RichText (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId))) Evergreen.V190.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V190.Id.Id Evergreen.V190.FileStatus.FileId) Evergreen.V190.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V190.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V190.RichText.RichText (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId))) Evergreen.V190.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V190.Id.Id Evergreen.V190.FileStatus.FileId) Evergreen.V190.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V190.Id.Id Evergreen.V190.Id.GuildId) Evergreen.V190.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V190.Id.Id Evergreen.V190.Id.GuildId) (Evergreen.V190.Id.Id Evergreen.V190.Id.ChannelId) Evergreen.V190.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V190.Id.Id Evergreen.V190.Id.GuildId) (Evergreen.V190.Id.Id Evergreen.V190.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V190.Id.Id Evergreen.V190.Id.GuildId) (Evergreen.V190.UserSession.ToBeFilledInByBackend (Evergreen.V190.SecretId.SecretId Evergreen.V190.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V190.GuildName.GuildName (Evergreen.V190.UserSession.ToBeFilledInByBackend (Evergreen.V190.Id.Id Evergreen.V190.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V190.Id.AnyGuildOrDmId, Evergreen.V190.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V190.Id.AnyGuildOrDmId Evergreen.V190.Id.ThreadRouteWithMessage Evergreen.V190.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V190.Id.AnyGuildOrDmId Evergreen.V190.Id.ThreadRouteWithMessage Evergreen.V190.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V190.Id.GuildOrDmId Evergreen.V190.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V190.RichText.RichText (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId))) (SeqDict.SeqDict (Evergreen.V190.Id.Id Evergreen.V190.FileStatus.FileId) Evergreen.V190.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId) (Evergreen.V190.Discord.Id Evergreen.V190.Discord.GuildId) (Evergreen.V190.Discord.Id Evergreen.V190.Discord.ChannelId) Evergreen.V190.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V190.RichText.RichText (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId)))
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V190.Id.DiscordGuildOrDmId_DmData (Evergreen.V190.Id.Id Evergreen.V190.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V190.RichText.RichText (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId)))
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V190.Id.AnyGuildOrDmId Evergreen.V190.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V190.Id.AnyGuildOrDmId Evergreen.V190.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V190.Id.AnyGuildOrDmId Evergreen.V190.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V190.UserSession.SetViewing
    | Local_SetName Evergreen.V190.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V190.Id.GuildOrDmId (Evergreen.V190.Id.Id Evergreen.V190.Id.ChannelMessageId) (Evergreen.V190.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V190.Id.Id Evergreen.V190.Id.ChannelMessageId) (Evergreen.V190.Message.Message Evergreen.V190.Id.ChannelMessageId (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V190.Id.GuildOrDmId (Evergreen.V190.Id.Id Evergreen.V190.Id.ChannelMessageId) (Evergreen.V190.Id.Id Evergreen.V190.Id.ThreadMessageId) (Evergreen.V190.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V190.Id.Id Evergreen.V190.Id.ThreadMessageId) (Evergreen.V190.Message.Message Evergreen.V190.Id.ThreadMessageId (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V190.Id.DiscordGuildOrDmId (Evergreen.V190.Id.Id Evergreen.V190.Id.ChannelMessageId) (Evergreen.V190.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V190.Id.Id Evergreen.V190.Id.ChannelMessageId) (Evergreen.V190.Message.Message Evergreen.V190.Id.ChannelMessageId (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V190.Id.DiscordGuildOrDmId (Evergreen.V190.Id.Id Evergreen.V190.Id.ChannelMessageId) (Evergreen.V190.Id.Id Evergreen.V190.Id.ThreadMessageId) (Evergreen.V190.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V190.Id.Id Evergreen.V190.Id.ThreadMessageId) (Evergreen.V190.Message.Message Evergreen.V190.Id.ThreadMessageId (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V190.Id.Id Evergreen.V190.Id.GuildId) Evergreen.V190.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId) (Evergreen.V190.Discord.Id Evergreen.V190.Discord.GuildId) Evergreen.V190.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V190.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V190.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V190.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V190.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V190.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V190.Emoji.SkinTone)


type ServerChange
    = Server_SendMessage (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId) Effect.Time.Posix Evergreen.V190.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V190.RichText.RichText (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId))) Evergreen.V190.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V190.Id.Id Evergreen.V190.FileStatus.FileId) Evergreen.V190.FileStatus.FileData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V190.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V190.RichText.RichText (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId))) Evergreen.V190.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V190.Id.Id Evergreen.V190.FileStatus.FileId) Evergreen.V190.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V190.Id.Id Evergreen.V190.Id.GuildId) Evergreen.V190.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V190.Id.Id Evergreen.V190.Id.GuildId) (Evergreen.V190.Id.Id Evergreen.V190.Id.ChannelId) Evergreen.V190.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V190.Id.Id Evergreen.V190.Id.GuildId) (Evergreen.V190.Id.Id Evergreen.V190.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId) (Evergreen.V190.Id.Id Evergreen.V190.Id.GuildId) (Evergreen.V190.SecretId.SecretId Evergreen.V190.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId) (Evergreen.V190.Id.Id Evergreen.V190.Id.GuildId) Evergreen.V190.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V190.LocalState.JoinGuildError
            { guildId : Evergreen.V190.Id.Id Evergreen.V190.Id.GuildId
            , guild : Evergreen.V190.LocalState.FrontendGuild
            , owner : Evergreen.V190.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId) Evergreen.V190.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId) Evergreen.V190.Id.GuildOrDmId Evergreen.V190.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId) (Evergreen.V190.Discord.Id Evergreen.V190.Discord.GuildId) (Evergreen.V190.Discord.Id Evergreen.V190.Discord.ChannelId) Evergreen.V190.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId) (Evergreen.V190.Discord.Id Evergreen.V190.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId) Evergreen.V190.Id.GuildOrDmId Evergreen.V190.Id.ThreadRouteWithMessage Evergreen.V190.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId) Evergreen.V190.Id.GuildOrDmId Evergreen.V190.Id.ThreadRouteWithMessage Evergreen.V190.Emoji.Emoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId) (Evergreen.V190.Discord.Id Evergreen.V190.Discord.GuildId) (Evergreen.V190.Discord.Id Evergreen.V190.Discord.ChannelId) Evergreen.V190.Id.ThreadRouteWithMessage Evergreen.V190.Emoji.Emoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId) (Evergreen.V190.Discord.Id Evergreen.V190.Discord.PrivateChannelId) (Evergreen.V190.Id.Id Evergreen.V190.Id.ChannelMessageId) Evergreen.V190.Emoji.Emoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId) (Evergreen.V190.Discord.Id Evergreen.V190.Discord.GuildId) (Evergreen.V190.Discord.Id Evergreen.V190.Discord.ChannelId) Evergreen.V190.Id.ThreadRouteWithMessage Evergreen.V190.Emoji.Emoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId) (Evergreen.V190.Discord.Id Evergreen.V190.Discord.PrivateChannelId) (Evergreen.V190.Id.Id Evergreen.V190.Id.ChannelMessageId) Evergreen.V190.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId) Evergreen.V190.Id.GuildOrDmId Evergreen.V190.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V190.RichText.RichText (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId))) (SeqDict.SeqDict (Evergreen.V190.Id.Id Evergreen.V190.FileStatus.FileId) Evergreen.V190.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId) (Evergreen.V190.Discord.Id Evergreen.V190.Discord.GuildId) (Evergreen.V190.Discord.Id Evergreen.V190.Discord.ChannelId) Evergreen.V190.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V190.RichText.RichText (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V190.Id.DiscordGuildOrDmId_DmData (Evergreen.V190.Id.Id Evergreen.V190.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V190.RichText.RichText (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId) Evergreen.V190.Id.AnyGuildOrDmId Evergreen.V190.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V190.Id.AnyGuildOrDmId Evergreen.V190.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V190.Discord.Id Evergreen.V190.Discord.GuildId) (Evergreen.V190.Discord.Id Evergreen.V190.Discord.ChannelId) Evergreen.V190.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V190.Discord.Id Evergreen.V190.Discord.PrivateChannelId) (Evergreen.V190.Id.Id Evergreen.V190.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId) Evergreen.V190.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId) Evergreen.V190.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V190.Id.Id Evergreen.V190.Id.GuildId) Evergreen.V190.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V190.Discord.Id Evergreen.V190.Discord.GuildId) Evergreen.V190.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V190.SessionIdHash.SessionIdHash Evergreen.V190.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V190.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V190.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V190.Id.AnyGuildOrDmId, Evergreen.V190.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V190.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId) Evergreen.V190.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V190.Discord.Id Evergreen.V190.Discord.GuildId) (Evergreen.V190.Discord.Id Evergreen.V190.Discord.ChannelId) Evergreen.V190.ChannelName.ChannelName (Evergreen.V190.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V190.Discord.Id Evergreen.V190.Discord.PrivateChannelId)
        (Evergreen.V190.NonemptyDict.NonemptyDict
            (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V190.Discord.Id Evergreen.V190.Discord.GuildId) Evergreen.V190.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V190.Discord.Id Evergreen.V190.Discord.PrivateChannelId) Evergreen.V190.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId) Evergreen.V190.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId) (Maybe (Evergreen.V190.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V190.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V190.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V190.Id.Id Evergreen.V190.Id.GuildId) (Evergreen.V190.Id.Id Evergreen.V190.Id.ChannelId) Evergreen.V190.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V190.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId) Evergreen.V190.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V190.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V190.Discord.Id Evergreen.V190.Discord.GuildId) (Evergreen.V190.Discord.Id Evergreen.V190.Discord.ChannelId) Evergreen.V190.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V190.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V190.Discord.Id Evergreen.V190.Discord.PrivateChannelId) (Evergreen.V190.Id.Id Evergreen.V190.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V190.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V190.Discord.Id Evergreen.V190.Discord.GuildId) Evergreen.V190.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V190.Discord.Id Evergreen.V190.Discord.GuildId) (Evergreen.V190.Discord.Id Evergreen.V190.Discord.ChannelId) (Evergreen.V190.Discord.OptionalData String) (Evergreen.V190.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V190.Discord.Id Evergreen.V190.Discord.GuildId)
        (Evergreen.V190.MembersAndOwner.MembersAndOwner
            (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V190.Discord.Id Evergreen.V190.Discord.GuildId) (Evergreen.V190.Discord.Id Evergreen.V190.Discord.ChannelId) (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId) Evergreen.V190.PersonName.PersonName


type LocalMsg
    = LocalChange (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V190.Id.Id Evergreen.V190.Id.GuildId) (Evergreen.V190.Id.Id Evergreen.V190.Id.ChannelId) Evergreen.V190.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V190.Discord.Id Evergreen.V190.Discord.GuildId) (Evergreen.V190.Discord.Id Evergreen.V190.Discord.ChannelId) Evergreen.V190.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V190.Id.Id Evergreen.V190.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V190.Id.Id Evergreen.V190.FileStatus.FileId) Evergreen.V190.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V190.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V190.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V190.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V190.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V190.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V190.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V190.Coord.Coord Evergreen.V190.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V190.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V190.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V190.Id.AnyGuildOrDmId Evergreen.V190.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V190.Id.AnyGuildOrDmId Evergreen.V190.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V190.MyUi.Range)
    | EmojiSelectorForEditMessage (Evergreen.V190.Coord.Coord Evergreen.V190.CssPixels.CssPixels) (Maybe Evergreen.V190.MyUi.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V190.Id.AnyGuildOrDmId, Evergreen.V190.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V190.Id.Id Evergreen.V190.Id.ChannelMessageId) (Evergreen.V190.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V190.Id.Id Evergreen.V190.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V190.Id.Id Evergreen.V190.Id.ThreadMessageId) (Evergreen.V190.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V190.Editable.Model
    , showLinkDiscordSetup : Bool
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V190.Local.Local LocalMsg Evergreen.V190.LocalState.LocalState
    , admin : Evergreen.V190.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V190.Id.AnyGuildOrDmId, Evergreen.V190.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V190.Id.Id Evergreen.V190.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V190.Id.Id Evergreen.V190.Id.GuildId, Evergreen.V190.Id.Id Evergreen.V190.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V190.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V190.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V190.Id.AnyGuildOrDmId, Evergreen.V190.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V190.Id.AnyGuildOrDmId, Evergreen.V190.Id.ThreadRoute ) (Evergreen.V190.Id.Id Evergreen.V190.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V190.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V190.Id.AnyGuildOrDmId, Evergreen.V190.Id.ThreadRoute ) (Evergreen.V190.NonemptyDict.NonemptyDict (Evergreen.V190.Id.Id Evergreen.V190.FileStatus.FileId) Evergreen.V190.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V190.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V190.TextEditor.Model
    , profilePictureEditor : Evergreen.V190.ImageEditor.Model
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V190.Emoji.Model
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V190.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V190.SecretId.SecretId Evergreen.V190.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V190.MyUi.Range
                , direction : Evergreen.V190.MyUi.SelectionDirection
                }
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V190.NonemptyDict.NonemptyDict Int Evergreen.V190.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V190.NonemptyDict.NonemptyDict Int Evergreen.V190.Touch.Touch
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
    | AdminToFrontend Evergreen.V190.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V190.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V190.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V190.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V190.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V190.ImageEditor.ToFrontend


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V190.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V190.Coord.Coord Evergreen.V190.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V190.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , notificationPermission : Evergreen.V190.Ports.NotificationPermission
    , pwaStatus : Evergreen.V190.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V190.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V190.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V190.Emoji.CachedEmojiData
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V190.Id.Id Evergreen.V190.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V190.Id.Id Evergreen.V190.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V190.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V190.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V190.Coord.Coord Evergreen.V190.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V190.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V190.FileStatus.ImageMetadata
    }


type alias ExportState =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V190.Id.Id Evergreen.V190.Id.GuildId, Evergreen.V190.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V190.DmChannel.DmChannelId, Evergreen.V190.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V190.Discord.Id Evergreen.V190.Discord.GuildId, Evergreen.V190.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V190.Discord.Id Evergreen.V190.Discord.PrivateChannelId, Evergreen.V190.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    , exportSubset : Evergreen.V190.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V190.NonemptyDict.NonemptyDict (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId) Evergreen.V190.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V190.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V190.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V190.LocalState.LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V190.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId) Evergreen.V190.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId) Evergreen.V190.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V190.Id.Id Evergreen.V190.Id.GuildId) Evergreen.V190.LocalState.BackendGuild
    , backendInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V190.Discord.Id Evergreen.V190.Discord.GuildId) Evergreen.V190.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V190.DmChannel.DmChannelId Evergreen.V190.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V190.Discord.Id Evergreen.V190.Discord.PrivateChannelId) Evergreen.V190.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V190.OneToOne.OneToOne (Evergreen.V190.Slack.Id Evergreen.V190.Slack.ChannelId) Evergreen.V190.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V190.OneToOne.OneToOne String (Evergreen.V190.Id.Id Evergreen.V190.Id.GuildId)
    , slackUsers : Evergreen.V190.OneToOne.OneToOne (Evergreen.V190.Slack.Id Evergreen.V190.Slack.UserId) (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId)
    , slackServers : Evergreen.V190.OneToOne.OneToOne (Evergreen.V190.Slack.Id Evergreen.V190.Slack.TeamId) (Evergreen.V190.Id.Id Evergreen.V190.Id.GuildId)
    , slackToken : Maybe Evergreen.V190.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V190.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V190.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V190.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V190.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId) Evergreen.V190.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId, Evergreen.V190.Discord.Id Evergreen.V190.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V190.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V190.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V190.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V190.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId) (Evergreen.V190.LocalState.LoadingDiscordChannel (List Evergreen.V190.Discord.Message))
    , signupsEnabled : Bool
    , exportState : Maybe ExportState
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V190.ToBackendLog.ToBackendLogData
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V190.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V190.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V190.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V190.Route.Route
    | SelectedFilesToAttach ( Evergreen.V190.Id.AnyGuildOrDmId, Evergreen.V190.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V190.Id.Id Evergreen.V190.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V190.Id.Id Evergreen.V190.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V190.Id.Id Evergreen.V190.Id.GuildId) (Evergreen.V190.Id.Id Evergreen.V190.Id.ChannelId) Evergreen.V190.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V190.Id.Id Evergreen.V190.Id.GuildId) (Evergreen.V190.Id.Id Evergreen.V190.Id.ChannelId) Evergreen.V190.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V190.Discord.Id Evergreen.V190.Discord.GuildId) (Evergreen.V190.Discord.Id Evergreen.V190.Discord.ChannelId) Evergreen.V190.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V190.Discord.Id Evergreen.V190.Discord.GuildId) (Evergreen.V190.Discord.Id Evergreen.V190.Discord.ChannelId) Evergreen.V190.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V190.Id.Id Evergreen.V190.Id.GuildId) (Evergreen.V190.Id.Id Evergreen.V190.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V190.Id.Id Evergreen.V190.Id.GuildId) (Evergreen.V190.Id.Id Evergreen.V190.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V190.Id.Id Evergreen.V190.Id.GuildId) (Evergreen.V190.Id.Id Evergreen.V190.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V190.Id.Id Evergreen.V190.Id.GuildId) (Evergreen.V190.Id.Id Evergreen.V190.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V190.Id.Id Evergreen.V190.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V190.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V190.Id.AnyGuildOrDmId Evergreen.V190.Id.ThreadRouteWithMessage (Evergreen.V190.Coord.Coord Evergreen.V190.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V190.Emoji.Emoji
    | MessageMenu_PressedEditMessage Evergreen.V190.Id.AnyGuildOrDmId Evergreen.V190.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V190.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V190.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V190.Id.Id Evergreen.V190.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V190.Id.AnyGuildOrDmId, Evergreen.V190.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V190.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V190.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V190.Id.AnyGuildOrDmId, Evergreen.V190.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V190.NonemptyDict.NonemptyDict Int Evergreen.V190.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V190.NonemptyDict.NonemptyDict Int Evergreen.V190.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V190.Id.AnyGuildOrDmId Evergreen.V190.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V190.Id.AnyGuildOrDmId Evergreen.V190.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V190.Id.AnyGuildOrDmId, Evergreen.V190.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V190.Id.AnyGuildOrDmId Evergreen.V190.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V190.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V190.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V190.Editable.Msg Evergreen.V190.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V190.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V190.Id.AnyGuildOrDmId, Evergreen.V190.Id.ThreadRoute ) (Evergreen.V190.Id.Id Evergreen.V190.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V190.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V190.Id.AnyGuildOrDmId, Evergreen.V190.Id.ThreadRoute ) (Evergreen.V190.Id.Id Evergreen.V190.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V190.Id.AnyGuildOrDmId, Evergreen.V190.Id.ThreadRoute ) (Evergreen.V190.Id.Id Evergreen.V190.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V190.Id.AnyGuildOrDmId, Evergreen.V190.Id.ThreadRoute ) (Evergreen.V190.Id.Id Evergreen.V190.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V190.Id.AnyGuildOrDmId, Evergreen.V190.Id.ThreadRoute ) (Evergreen.V190.Id.Id Evergreen.V190.FileStatus.FileId)
    | EditMessage_SelectedFilesToAttach ( Evergreen.V190.Id.AnyGuildOrDmId, Evergreen.V190.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V190.Id.AnyGuildOrDmId, Evergreen.V190.Id.ThreadRoute ) (Evergreen.V190.Id.Id Evergreen.V190.Id.ChannelMessageId) (Evergreen.V190.Id.Id Evergreen.V190.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V190.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V190.Id.AnyGuildOrDmId, Evergreen.V190.Id.ThreadRoute ) (Evergreen.V190.Id.Id Evergreen.V190.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V190.Id.AnyGuildOrDmId Evergreen.V190.Id.ThreadRouteWithMessage Evergreen.V190.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V190.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V190.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V190.Id.Id Evergreen.V190.Id.GuildId) Evergreen.V190.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId) (Evergreen.V190.Discord.Id Evergreen.V190.Discord.GuildId) Evergreen.V190.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V190.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V190.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId
        , otherUserId : Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | PressedRemoveDomainFromWhitelist Evergreen.V190.RichText.Domain
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V190.Id.AnyGuildOrDmId Evergreen.V190.Id.ThreadRoute Evergreen.V190.MessageInput.Msg
    | MessageInputMsg Evergreen.V190.Id.AnyGuildOrDmId Evergreen.V190.Id.ThreadRoute Evergreen.V190.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V190.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V190.MyUi.Range, Evergreen.V190.MyUi.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V190.MyUi.Range, Evergreen.V190.MyUi.SelectionDirection ) )


type InitialLoadRequest
    = InitialLoadRequested_Channel Evergreen.V190.Id.AnyGuildOrDmId Evergreen.V190.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V190.Id.Id Evergreen.V190.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V190.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V190.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V190.Untrusted.Untrusted Evergreen.V190.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V190.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V190.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V190.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V190.Id.Id Evergreen.V190.Id.GuildId) (Evergreen.V190.SecretId.SecretId Evergreen.V190.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V190.PersonName.PersonName Evergreen.V190.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V190.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V190.Slack.OAuthCode Evergreen.V190.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V190.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V190.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V190.Id.Id Evergreen.V190.Pagination.PageId))


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V190.EmailAddress.EmailAddress (Result Evergreen.V190.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V190.EmailAddress.EmailAddress (Result Evergreen.V190.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId) Evergreen.V190.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V190.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V190.Discord.Id Evergreen.V190.Discord.GuildId) (Evergreen.V190.Discord.Id Evergreen.V190.Discord.ChannelId) Evergreen.V190.Id.ThreadRouteWithMaybeMessage (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId) (Result Evergreen.V190.Discord.HttpError Evergreen.V190.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V190.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V190.Discord.Id Evergreen.V190.Discord.PrivateChannelId) (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId) (Result Evergreen.V190.Discord.HttpError Evergreen.V190.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V190.Discord.Id Evergreen.V190.Discord.GuildId) (Evergreen.V190.Discord.Id Evergreen.V190.Discord.ChannelId) Evergreen.V190.Id.ThreadRouteWithMessage (Evergreen.V190.Discord.Id Evergreen.V190.Discord.MessageId) (Result Evergreen.V190.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V190.Discord.Id Evergreen.V190.Discord.PrivateChannelId) (Evergreen.V190.Id.Id Evergreen.V190.Id.ChannelMessageId) (Evergreen.V190.Discord.Id Evergreen.V190.Discord.MessageId) (Result Evergreen.V190.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V190.Discord.Id Evergreen.V190.Discord.GuildId) (Evergreen.V190.Discord.Id Evergreen.V190.Discord.ChannelId) Evergreen.V190.Id.ThreadRouteWithMessage (Evergreen.V190.Discord.Id Evergreen.V190.Discord.MessageId) (Result Evergreen.V190.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V190.Discord.Id Evergreen.V190.Discord.PrivateChannelId) (Evergreen.V190.Id.Id Evergreen.V190.Id.ChannelMessageId) (Evergreen.V190.Discord.Id Evergreen.V190.Discord.MessageId) (Result Evergreen.V190.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V190.Discord.Id Evergreen.V190.Discord.GuildId) (Evergreen.V190.Discord.Id Evergreen.V190.Discord.ChannelId) Evergreen.V190.Id.ThreadRouteWithMessage (Evergreen.V190.Discord.Id Evergreen.V190.Discord.MessageId) Evergreen.V190.Emoji.Emoji (Result Evergreen.V190.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V190.Discord.Id Evergreen.V190.Discord.PrivateChannelId) (Evergreen.V190.Id.Id Evergreen.V190.Id.ChannelMessageId) (Evergreen.V190.Discord.Id Evergreen.V190.Discord.MessageId) Evergreen.V190.Emoji.Emoji (Result Evergreen.V190.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V190.Discord.Id Evergreen.V190.Discord.GuildId) (Evergreen.V190.Discord.Id Evergreen.V190.Discord.ChannelId) Evergreen.V190.Id.ThreadRouteWithMessage (Evergreen.V190.Discord.Id Evergreen.V190.Discord.MessageId) Evergreen.V190.Emoji.Emoji (Result Evergreen.V190.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V190.Discord.Id Evergreen.V190.Discord.PrivateChannelId) (Evergreen.V190.Id.Id Evergreen.V190.Id.ChannelMessageId) (Evergreen.V190.Discord.Id Evergreen.V190.Discord.MessageId) Evergreen.V190.Emoji.Emoji (Result Evergreen.V190.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V190.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V190.Discord.HttpError (List ( Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId, Maybe Evergreen.V190.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V190.Slack.CurrentUser
            , team : Evergreen.V190.Slack.Team
            , users : List Evergreen.V190.Slack.User
            , channels : List ( Evergreen.V190.Slack.Channel, List Evergreen.V190.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId) (Result Effect.Http.Error Evergreen.V190.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId) Evergreen.V190.Discord.UserAuth (Result Evergreen.V190.Discord.HttpError Evergreen.V190.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId) (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId) (Result Evergreen.V190.Discord.HttpError Evergreen.V190.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId)
        (Result
            Evergreen.V190.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V190.Discord.Id Evergreen.V190.Discord.PrivateChannelId
                , members : List (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId)
                }
            , List
                ( Evergreen.V190.Discord.Id Evergreen.V190.Discord.GuildId
                , { guild : Evergreen.V190.Discord.GatewayGuild
                  , channels : List Evergreen.V190.Discord.Channel
                  , icon : Maybe Evergreen.V190.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId) Bool
    | WebsocketSentDataForUser (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V190.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V190.Discord.Id Evergreen.V190.Discord.AttachmentId, Evergreen.V190.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V190.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V190.Discord.Id Evergreen.V190.Discord.AttachmentId, Evergreen.V190.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId) (Evergreen.V190.Discord.Id Evergreen.V190.Discord.GuildId) (Evergreen.V190.Discord.Id Evergreen.V190.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V190.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V190.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId) (Evergreen.V190.Discord.Id Evergreen.V190.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V190.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V190.FileStatus.UploadResponse )))
    | ExportBackendStep
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId) (Evergreen.V190.Discord.Id Evergreen.V190.Discord.GuildId) (Evergreen.V190.Discord.Id Evergreen.V190.Discord.ChannelId) (Result Evergreen.V190.Discord.HttpError (List Evergreen.V190.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId) (Evergreen.V190.Discord.Id Evergreen.V190.Discord.PrivateChannelId) (Result Evergreen.V190.Discord.HttpError (List Evergreen.V190.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V190.Id.Id Evergreen.V190.Id.GuildId) (Evergreen.V190.Id.Id Evergreen.V190.Id.ChannelId) Evergreen.V190.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V190.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V190.DmChannel.DmChannelId Evergreen.V190.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V190.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V190.Discord.Id Evergreen.V190.Discord.GuildId) (Evergreen.V190.Discord.Id Evergreen.V190.Discord.ChannelId) Evergreen.V190.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V190.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V190.Discord.Id Evergreen.V190.Discord.PrivateChannelId) (Evergreen.V190.Id.Id Evergreen.V190.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V190.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId)
        (Evergreen.V190.Discord.Id Evergreen.V190.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V190.Discord.HttpError
            { guild : Evergreen.V190.Discord.GatewayGuild
            , channels : List Evergreen.V190.Discord.Channel
            , icon : Maybe Evergreen.V190.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V190.Discord.Id Evergreen.V190.Discord.GuildId) (Result Evergreen.V190.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V190.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
