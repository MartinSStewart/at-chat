module Evergreen.V187.Types exposing (..)

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
import Evergreen.V187.AiChat
import Evergreen.V187.ChannelName
import Evergreen.V187.Coord
import Evergreen.V187.CssPixels
import Evergreen.V187.Discord
import Evergreen.V187.DiscordAttachmentId
import Evergreen.V187.DiscordUserData
import Evergreen.V187.DmChannel
import Evergreen.V187.Editable
import Evergreen.V187.EmailAddress
import Evergreen.V187.Embed
import Evergreen.V187.Emoji
import Evergreen.V187.FileStatus
import Evergreen.V187.GuildName
import Evergreen.V187.Id
import Evergreen.V187.ImageEditor
import Evergreen.V187.Local
import Evergreen.V187.LocalState
import Evergreen.V187.Log
import Evergreen.V187.LoginForm
import Evergreen.V187.MembersAndOwner
import Evergreen.V187.Message
import Evergreen.V187.MessageInput
import Evergreen.V187.MessageView
import Evergreen.V187.MyUi
import Evergreen.V187.NonemptyDict
import Evergreen.V187.NonemptySet
import Evergreen.V187.OneToOne
import Evergreen.V187.Pages.Admin
import Evergreen.V187.Pagination
import Evergreen.V187.PersonName
import Evergreen.V187.Ports
import Evergreen.V187.Postmark
import Evergreen.V187.RichText
import Evergreen.V187.Route
import Evergreen.V187.SecretId
import Evergreen.V187.SessionIdHash
import Evergreen.V187.Slack
import Evergreen.V187.TextEditor
import Evergreen.V187.ToBackendLog
import Evergreen.V187.Touch
import Evergreen.V187.TwoFactorAuthentication
import Evergreen.V187.Ui.Anim
import Evergreen.V187.Untrusted
import Evergreen.V187.User
import Evergreen.V187.UserAgent
import Evergreen.V187.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V187.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V187.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V187.Id.Id Evergreen.V187.Id.GuildId) Evergreen.V187.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId) Evergreen.V187.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V187.Discord.Id Evergreen.V187.Discord.PrivateChannelId) Evergreen.V187.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V187.Discord.Id Evergreen.V187.Discord.GuildId) Evergreen.V187.LocalState.DiscordFrontendGuild
    , user : Evergreen.V187.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId) Evergreen.V187.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId) Evergreen.V187.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId) Evergreen.V187.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V187.SessionIdHash.SessionIdHash Evergreen.V187.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V187.TextEditor.LocalState
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V187.Route.Route
    , windowSize : Evergreen.V187.Coord.Coord Evergreen.V187.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V187.Ports.NotificationPermission
    , pwaStatus : Evergreen.V187.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V187.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V187.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V187.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V187.RichText.RichText (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId))) Evergreen.V187.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V187.Id.Id Evergreen.V187.FileStatus.FileId) Evergreen.V187.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V187.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V187.RichText.RichText (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId))) Evergreen.V187.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V187.Id.Id Evergreen.V187.FileStatus.FileId) Evergreen.V187.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V187.Id.Id Evergreen.V187.Id.GuildId) Evergreen.V187.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V187.Id.Id Evergreen.V187.Id.GuildId) (Evergreen.V187.Id.Id Evergreen.V187.Id.ChannelId) Evergreen.V187.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V187.Id.Id Evergreen.V187.Id.GuildId) (Evergreen.V187.Id.Id Evergreen.V187.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V187.Id.Id Evergreen.V187.Id.GuildId) (Evergreen.V187.UserSession.ToBeFilledInByBackend (Evergreen.V187.SecretId.SecretId Evergreen.V187.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V187.GuildName.GuildName (Evergreen.V187.UserSession.ToBeFilledInByBackend (Evergreen.V187.Id.Id Evergreen.V187.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V187.Id.AnyGuildOrDmId, Evergreen.V187.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V187.Id.AnyGuildOrDmId Evergreen.V187.Id.ThreadRouteWithMessage Evergreen.V187.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V187.Id.AnyGuildOrDmId Evergreen.V187.Id.ThreadRouteWithMessage Evergreen.V187.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V187.Id.GuildOrDmId Evergreen.V187.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V187.RichText.RichText (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId))) (SeqDict.SeqDict (Evergreen.V187.Id.Id Evergreen.V187.FileStatus.FileId) Evergreen.V187.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId) (Evergreen.V187.Discord.Id Evergreen.V187.Discord.GuildId) (Evergreen.V187.Discord.Id Evergreen.V187.Discord.ChannelId) Evergreen.V187.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V187.RichText.RichText (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId)))
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V187.Id.DiscordGuildOrDmId_DmData (Evergreen.V187.Id.Id Evergreen.V187.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V187.RichText.RichText (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId)))
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V187.Id.AnyGuildOrDmId Evergreen.V187.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V187.Id.AnyGuildOrDmId Evergreen.V187.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V187.Id.AnyGuildOrDmId Evergreen.V187.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V187.UserSession.SetViewing
    | Local_SetName Evergreen.V187.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V187.Id.GuildOrDmId (Evergreen.V187.Id.Id Evergreen.V187.Id.ChannelMessageId) (Evergreen.V187.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V187.Id.Id Evergreen.V187.Id.ChannelMessageId) (Evergreen.V187.Message.Message Evergreen.V187.Id.ChannelMessageId (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V187.Id.GuildOrDmId (Evergreen.V187.Id.Id Evergreen.V187.Id.ChannelMessageId) (Evergreen.V187.Id.Id Evergreen.V187.Id.ThreadMessageId) (Evergreen.V187.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V187.Id.Id Evergreen.V187.Id.ThreadMessageId) (Evergreen.V187.Message.Message Evergreen.V187.Id.ThreadMessageId (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V187.Id.DiscordGuildOrDmId (Evergreen.V187.Id.Id Evergreen.V187.Id.ChannelMessageId) (Evergreen.V187.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V187.Id.Id Evergreen.V187.Id.ChannelMessageId) (Evergreen.V187.Message.Message Evergreen.V187.Id.ChannelMessageId (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V187.Id.DiscordGuildOrDmId (Evergreen.V187.Id.Id Evergreen.V187.Id.ChannelMessageId) (Evergreen.V187.Id.Id Evergreen.V187.Id.ThreadMessageId) (Evergreen.V187.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V187.Id.Id Evergreen.V187.Id.ThreadMessageId) (Evergreen.V187.Message.Message Evergreen.V187.Id.ThreadMessageId (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V187.Id.Id Evergreen.V187.Id.GuildId) Evergreen.V187.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V187.Discord.Id Evergreen.V187.Discord.GuildId) Evergreen.V187.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V187.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V187.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V187.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V187.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V187.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V187.Emoji.SkinTone)


type ServerChange
    = Server_SendMessage (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId) Effect.Time.Posix Evergreen.V187.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V187.RichText.RichText (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId))) Evergreen.V187.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V187.Id.Id Evergreen.V187.FileStatus.FileId) Evergreen.V187.FileStatus.FileData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V187.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V187.RichText.RichText (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId))) Evergreen.V187.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V187.Id.Id Evergreen.V187.FileStatus.FileId) Evergreen.V187.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V187.Id.Id Evergreen.V187.Id.GuildId) Evergreen.V187.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V187.Id.Id Evergreen.V187.Id.GuildId) (Evergreen.V187.Id.Id Evergreen.V187.Id.ChannelId) Evergreen.V187.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V187.Id.Id Evergreen.V187.Id.GuildId) (Evergreen.V187.Id.Id Evergreen.V187.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId) (Evergreen.V187.Id.Id Evergreen.V187.Id.GuildId) (Evergreen.V187.SecretId.SecretId Evergreen.V187.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId) (Evergreen.V187.Id.Id Evergreen.V187.Id.GuildId) Evergreen.V187.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V187.LocalState.JoinGuildError
            { guildId : Evergreen.V187.Id.Id Evergreen.V187.Id.GuildId
            , guild : Evergreen.V187.LocalState.FrontendGuild
            , owner : Evergreen.V187.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId) Evergreen.V187.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId) Evergreen.V187.Id.GuildOrDmId Evergreen.V187.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId) (Evergreen.V187.Discord.Id Evergreen.V187.Discord.GuildId) (Evergreen.V187.Discord.Id Evergreen.V187.Discord.ChannelId) Evergreen.V187.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId) (Evergreen.V187.Discord.Id Evergreen.V187.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId) Evergreen.V187.Id.GuildOrDmId Evergreen.V187.Id.ThreadRouteWithMessage Evergreen.V187.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId) Evergreen.V187.Id.GuildOrDmId Evergreen.V187.Id.ThreadRouteWithMessage Evergreen.V187.Emoji.Emoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId) (Evergreen.V187.Discord.Id Evergreen.V187.Discord.GuildId) (Evergreen.V187.Discord.Id Evergreen.V187.Discord.ChannelId) Evergreen.V187.Id.ThreadRouteWithMessage Evergreen.V187.Emoji.Emoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId) (Evergreen.V187.Discord.Id Evergreen.V187.Discord.PrivateChannelId) (Evergreen.V187.Id.Id Evergreen.V187.Id.ChannelMessageId) Evergreen.V187.Emoji.Emoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId) (Evergreen.V187.Discord.Id Evergreen.V187.Discord.GuildId) (Evergreen.V187.Discord.Id Evergreen.V187.Discord.ChannelId) Evergreen.V187.Id.ThreadRouteWithMessage Evergreen.V187.Emoji.Emoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId) (Evergreen.V187.Discord.Id Evergreen.V187.Discord.PrivateChannelId) (Evergreen.V187.Id.Id Evergreen.V187.Id.ChannelMessageId) Evergreen.V187.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId) Evergreen.V187.Id.GuildOrDmId Evergreen.V187.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V187.RichText.RichText (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId))) (SeqDict.SeqDict (Evergreen.V187.Id.Id Evergreen.V187.FileStatus.FileId) Evergreen.V187.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId) (Evergreen.V187.Discord.Id Evergreen.V187.Discord.GuildId) (Evergreen.V187.Discord.Id Evergreen.V187.Discord.ChannelId) Evergreen.V187.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V187.RichText.RichText (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V187.Id.DiscordGuildOrDmId_DmData (Evergreen.V187.Id.Id Evergreen.V187.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V187.RichText.RichText (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId) Evergreen.V187.Id.AnyGuildOrDmId Evergreen.V187.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V187.Id.AnyGuildOrDmId Evergreen.V187.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V187.Discord.Id Evergreen.V187.Discord.GuildId) (Evergreen.V187.Discord.Id Evergreen.V187.Discord.ChannelId) Evergreen.V187.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V187.Discord.Id Evergreen.V187.Discord.PrivateChannelId) (Evergreen.V187.Id.Id Evergreen.V187.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId) Evergreen.V187.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId) Evergreen.V187.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V187.Id.Id Evergreen.V187.Id.GuildId) Evergreen.V187.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V187.Discord.Id Evergreen.V187.Discord.GuildId) Evergreen.V187.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V187.SessionIdHash.SessionIdHash Evergreen.V187.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V187.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V187.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V187.Id.AnyGuildOrDmId, Evergreen.V187.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V187.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId) Evergreen.V187.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V187.Discord.Id Evergreen.V187.Discord.GuildId) (Evergreen.V187.Discord.Id Evergreen.V187.Discord.ChannelId) Evergreen.V187.ChannelName.ChannelName (Evergreen.V187.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V187.Discord.Id Evergreen.V187.Discord.PrivateChannelId)
        (Evergreen.V187.NonemptyDict.NonemptyDict
            (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V187.Discord.Id Evergreen.V187.Discord.GuildId) Evergreen.V187.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V187.Discord.Id Evergreen.V187.Discord.PrivateChannelId) Evergreen.V187.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId) Evergreen.V187.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId) (Maybe (Evergreen.V187.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V187.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V187.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V187.Id.Id Evergreen.V187.Id.GuildId) (Evergreen.V187.Id.Id Evergreen.V187.Id.ChannelId) Evergreen.V187.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V187.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId) Evergreen.V187.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V187.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V187.Discord.Id Evergreen.V187.Discord.GuildId) (Evergreen.V187.Discord.Id Evergreen.V187.Discord.ChannelId) Evergreen.V187.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V187.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V187.Discord.Id Evergreen.V187.Discord.PrivateChannelId) (Evergreen.V187.Id.Id Evergreen.V187.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V187.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V187.Discord.Id Evergreen.V187.Discord.GuildId) Evergreen.V187.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V187.Discord.Id Evergreen.V187.Discord.GuildId) (Evergreen.V187.Discord.Id Evergreen.V187.Discord.ChannelId) (Evergreen.V187.Discord.OptionalData String) (Evergreen.V187.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V187.Discord.Id Evergreen.V187.Discord.GuildId)
        (Evergreen.V187.MembersAndOwner.MembersAndOwner
            (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V187.Discord.Id Evergreen.V187.Discord.GuildId) (Evergreen.V187.Discord.Id Evergreen.V187.Discord.ChannelId) (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId) Evergreen.V187.PersonName.PersonName


type LocalMsg
    = LocalChange (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V187.Id.Id Evergreen.V187.Id.GuildId) (Evergreen.V187.Id.Id Evergreen.V187.Id.ChannelId) Evergreen.V187.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V187.Discord.Id Evergreen.V187.Discord.GuildId) (Evergreen.V187.Discord.Id Evergreen.V187.Discord.ChannelId) Evergreen.V187.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V187.Id.Id Evergreen.V187.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V187.Id.Id Evergreen.V187.FileStatus.FileId) Evergreen.V187.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V187.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V187.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V187.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V187.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V187.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V187.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V187.Coord.Coord Evergreen.V187.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V187.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V187.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V187.Id.AnyGuildOrDmId Evergreen.V187.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V187.Id.AnyGuildOrDmId Evergreen.V187.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V187.MyUi.Range)
    | EmojiSelectorForEditMessage (Evergreen.V187.Coord.Coord Evergreen.V187.CssPixels.CssPixels) (Maybe Evergreen.V187.MyUi.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V187.Id.AnyGuildOrDmId, Evergreen.V187.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V187.Id.Id Evergreen.V187.Id.ChannelMessageId) (Evergreen.V187.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V187.Id.Id Evergreen.V187.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V187.Id.Id Evergreen.V187.Id.ThreadMessageId) (Evergreen.V187.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V187.Editable.Model
    , showLinkDiscordSetup : Bool
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V187.Local.Local LocalMsg Evergreen.V187.LocalState.LocalState
    , admin : Evergreen.V187.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V187.Id.AnyGuildOrDmId, Evergreen.V187.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V187.Id.Id Evergreen.V187.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V187.Id.Id Evergreen.V187.Id.GuildId, Evergreen.V187.Id.Id Evergreen.V187.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V187.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V187.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V187.Id.AnyGuildOrDmId, Evergreen.V187.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V187.Id.AnyGuildOrDmId, Evergreen.V187.Id.ThreadRoute ) (Evergreen.V187.Id.Id Evergreen.V187.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V187.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V187.Id.AnyGuildOrDmId, Evergreen.V187.Id.ThreadRoute ) (Evergreen.V187.NonemptyDict.NonemptyDict (Evergreen.V187.Id.Id Evergreen.V187.FileStatus.FileId) Evergreen.V187.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V187.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V187.TextEditor.Model
    , profilePictureEditor : Evergreen.V187.ImageEditor.Model
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V187.Emoji.Model
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V187.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V187.SecretId.SecretId Evergreen.V187.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V187.MyUi.Range
                , direction : Evergreen.V187.MyUi.SelectionDirection
                }
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V187.NonemptyDict.NonemptyDict Int Evergreen.V187.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V187.NonemptyDict.NonemptyDict Int Evergreen.V187.Touch.Touch
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
    | AdminToFrontend Evergreen.V187.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V187.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V187.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V187.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V187.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V187.ImageEditor.ToFrontend


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V187.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V187.Coord.Coord Evergreen.V187.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V187.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , notificationPermission : Evergreen.V187.Ports.NotificationPermission
    , pwaStatus : Evergreen.V187.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V187.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V187.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V187.Emoji.CachedEmojiData
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V187.Id.Id Evergreen.V187.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V187.Id.Id Evergreen.V187.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V187.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V187.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V187.Coord.Coord Evergreen.V187.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V187.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V187.FileStatus.ImageMetadata
    }


type alias ExportState =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V187.Id.Id Evergreen.V187.Id.GuildId, Evergreen.V187.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V187.DmChannel.DmChannelId, Evergreen.V187.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V187.Discord.Id Evergreen.V187.Discord.GuildId, Evergreen.V187.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V187.Discord.Id Evergreen.V187.Discord.PrivateChannelId, Evergreen.V187.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    , exportSubset : Evergreen.V187.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V187.NonemptyDict.NonemptyDict (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId) Evergreen.V187.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V187.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V187.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V187.LocalState.LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V187.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId) Evergreen.V187.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId) Evergreen.V187.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V187.Id.Id Evergreen.V187.Id.GuildId) Evergreen.V187.LocalState.BackendGuild
    , backendInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V187.Discord.Id Evergreen.V187.Discord.GuildId) Evergreen.V187.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V187.DmChannel.DmChannelId Evergreen.V187.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V187.Discord.Id Evergreen.V187.Discord.PrivateChannelId) Evergreen.V187.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V187.OneToOne.OneToOne (Evergreen.V187.Slack.Id Evergreen.V187.Slack.ChannelId) Evergreen.V187.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V187.OneToOne.OneToOne String (Evergreen.V187.Id.Id Evergreen.V187.Id.GuildId)
    , slackUsers : Evergreen.V187.OneToOne.OneToOne (Evergreen.V187.Slack.Id Evergreen.V187.Slack.UserId) (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId)
    , slackServers : Evergreen.V187.OneToOne.OneToOne (Evergreen.V187.Slack.Id Evergreen.V187.Slack.TeamId) (Evergreen.V187.Id.Id Evergreen.V187.Id.GuildId)
    , slackToken : Maybe Evergreen.V187.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V187.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V187.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V187.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V187.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId) Evergreen.V187.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId, Evergreen.V187.Discord.Id Evergreen.V187.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V187.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V187.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V187.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V187.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId) (Evergreen.V187.LocalState.LoadingDiscordChannel (List Evergreen.V187.Discord.Message))
    , signupsEnabled : Bool
    , exportState : Maybe ExportState
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V187.ToBackendLog.ToBackendLogData
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V187.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V187.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V187.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V187.Route.Route
    | SelectedFilesToAttach ( Evergreen.V187.Id.AnyGuildOrDmId, Evergreen.V187.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V187.Id.Id Evergreen.V187.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V187.Id.Id Evergreen.V187.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V187.Id.Id Evergreen.V187.Id.GuildId) (Evergreen.V187.Id.Id Evergreen.V187.Id.ChannelId) Evergreen.V187.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V187.Id.Id Evergreen.V187.Id.GuildId) (Evergreen.V187.Id.Id Evergreen.V187.Id.ChannelId) Evergreen.V187.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V187.Discord.Id Evergreen.V187.Discord.GuildId) (Evergreen.V187.Discord.Id Evergreen.V187.Discord.ChannelId) Evergreen.V187.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V187.Discord.Id Evergreen.V187.Discord.GuildId) (Evergreen.V187.Discord.Id Evergreen.V187.Discord.ChannelId) Evergreen.V187.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V187.Id.Id Evergreen.V187.Id.GuildId) (Evergreen.V187.Id.Id Evergreen.V187.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V187.Id.Id Evergreen.V187.Id.GuildId) (Evergreen.V187.Id.Id Evergreen.V187.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V187.Id.Id Evergreen.V187.Id.GuildId) (Evergreen.V187.Id.Id Evergreen.V187.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V187.Id.Id Evergreen.V187.Id.GuildId) (Evergreen.V187.Id.Id Evergreen.V187.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V187.Id.Id Evergreen.V187.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V187.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V187.Id.AnyGuildOrDmId Evergreen.V187.Id.ThreadRouteWithMessage (Evergreen.V187.Coord.Coord Evergreen.V187.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V187.Emoji.Emoji
    | MessageMenu_PressedEditMessage Evergreen.V187.Id.AnyGuildOrDmId Evergreen.V187.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V187.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V187.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V187.Id.Id Evergreen.V187.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V187.Id.AnyGuildOrDmId, Evergreen.V187.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V187.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V187.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V187.Id.AnyGuildOrDmId, Evergreen.V187.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V187.NonemptyDict.NonemptyDict Int Evergreen.V187.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V187.NonemptyDict.NonemptyDict Int Evergreen.V187.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V187.Id.AnyGuildOrDmId Evergreen.V187.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V187.Id.AnyGuildOrDmId Evergreen.V187.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V187.Id.AnyGuildOrDmId, Evergreen.V187.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V187.Id.AnyGuildOrDmId Evergreen.V187.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V187.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V187.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V187.Editable.Msg Evergreen.V187.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V187.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V187.Id.AnyGuildOrDmId, Evergreen.V187.Id.ThreadRoute ) (Evergreen.V187.Id.Id Evergreen.V187.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V187.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V187.Id.AnyGuildOrDmId, Evergreen.V187.Id.ThreadRoute ) (Evergreen.V187.Id.Id Evergreen.V187.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V187.Id.AnyGuildOrDmId, Evergreen.V187.Id.ThreadRoute ) (Evergreen.V187.Id.Id Evergreen.V187.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V187.Id.AnyGuildOrDmId, Evergreen.V187.Id.ThreadRoute ) (Evergreen.V187.Id.Id Evergreen.V187.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V187.Id.AnyGuildOrDmId, Evergreen.V187.Id.ThreadRoute ) (Evergreen.V187.Id.Id Evergreen.V187.FileStatus.FileId)
    | EditMessage_SelectedFilesToAttach ( Evergreen.V187.Id.AnyGuildOrDmId, Evergreen.V187.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V187.Id.AnyGuildOrDmId, Evergreen.V187.Id.ThreadRoute ) (Evergreen.V187.Id.Id Evergreen.V187.Id.ChannelMessageId) (Evergreen.V187.Id.Id Evergreen.V187.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V187.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V187.Id.AnyGuildOrDmId, Evergreen.V187.Id.ThreadRoute ) (Evergreen.V187.Id.Id Evergreen.V187.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V187.Id.AnyGuildOrDmId Evergreen.V187.Id.ThreadRouteWithMessage Evergreen.V187.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V187.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V187.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V187.Id.Id Evergreen.V187.Id.GuildId) Evergreen.V187.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V187.Discord.Id Evergreen.V187.Discord.GuildId) Evergreen.V187.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V187.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V187.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId
        , otherUserId : Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | PressedRemoveDomainFromWhitelist Evergreen.V187.RichText.Domain
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V187.Id.AnyGuildOrDmId Evergreen.V187.Id.ThreadRoute Evergreen.V187.MessageInput.Msg
    | MessageInputMsg Evergreen.V187.Id.AnyGuildOrDmId Evergreen.V187.Id.ThreadRoute Evergreen.V187.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V187.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V187.MyUi.Range, Evergreen.V187.MyUi.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V187.MyUi.Range, Evergreen.V187.MyUi.SelectionDirection ) )


type InitialLoadRequest
    = InitialLoadRequested_Channel Evergreen.V187.Id.AnyGuildOrDmId Evergreen.V187.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V187.Id.Id Evergreen.V187.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V187.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V187.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V187.Untrusted.Untrusted Evergreen.V187.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V187.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V187.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V187.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V187.Id.Id Evergreen.V187.Id.GuildId) (Evergreen.V187.SecretId.SecretId Evergreen.V187.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V187.PersonName.PersonName Evergreen.V187.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V187.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V187.Slack.OAuthCode Evergreen.V187.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V187.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V187.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V187.Id.Id Evergreen.V187.Pagination.PageId))


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V187.EmailAddress.EmailAddress (Result Evergreen.V187.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V187.EmailAddress.EmailAddress (Result Evergreen.V187.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId) Evergreen.V187.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V187.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V187.Discord.Id Evergreen.V187.Discord.GuildId) (Evergreen.V187.Discord.Id Evergreen.V187.Discord.ChannelId) Evergreen.V187.Id.ThreadRouteWithMaybeMessage (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId) (Result Evergreen.V187.Discord.HttpError Evergreen.V187.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V187.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V187.Discord.Id Evergreen.V187.Discord.PrivateChannelId) (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId) (Result Evergreen.V187.Discord.HttpError Evergreen.V187.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V187.Discord.Id Evergreen.V187.Discord.GuildId) (Evergreen.V187.Discord.Id Evergreen.V187.Discord.ChannelId) Evergreen.V187.Id.ThreadRouteWithMessage (Evergreen.V187.Discord.Id Evergreen.V187.Discord.MessageId) (Result Evergreen.V187.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V187.Discord.Id Evergreen.V187.Discord.PrivateChannelId) (Evergreen.V187.Id.Id Evergreen.V187.Id.ChannelMessageId) (Evergreen.V187.Discord.Id Evergreen.V187.Discord.MessageId) (Result Evergreen.V187.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V187.Discord.Id Evergreen.V187.Discord.GuildId) (Evergreen.V187.Discord.Id Evergreen.V187.Discord.ChannelId) Evergreen.V187.Id.ThreadRouteWithMessage (Evergreen.V187.Discord.Id Evergreen.V187.Discord.MessageId) (Result Evergreen.V187.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V187.Discord.Id Evergreen.V187.Discord.PrivateChannelId) (Evergreen.V187.Id.Id Evergreen.V187.Id.ChannelMessageId) (Evergreen.V187.Discord.Id Evergreen.V187.Discord.MessageId) (Result Evergreen.V187.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V187.Discord.Id Evergreen.V187.Discord.GuildId) (Evergreen.V187.Discord.Id Evergreen.V187.Discord.ChannelId) Evergreen.V187.Id.ThreadRouteWithMessage (Evergreen.V187.Discord.Id Evergreen.V187.Discord.MessageId) Evergreen.V187.Emoji.Emoji (Result Evergreen.V187.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V187.Discord.Id Evergreen.V187.Discord.PrivateChannelId) (Evergreen.V187.Id.Id Evergreen.V187.Id.ChannelMessageId) (Evergreen.V187.Discord.Id Evergreen.V187.Discord.MessageId) Evergreen.V187.Emoji.Emoji (Result Evergreen.V187.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V187.Discord.Id Evergreen.V187.Discord.GuildId) (Evergreen.V187.Discord.Id Evergreen.V187.Discord.ChannelId) Evergreen.V187.Id.ThreadRouteWithMessage (Evergreen.V187.Discord.Id Evergreen.V187.Discord.MessageId) Evergreen.V187.Emoji.Emoji (Result Evergreen.V187.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V187.Discord.Id Evergreen.V187.Discord.PrivateChannelId) (Evergreen.V187.Id.Id Evergreen.V187.Id.ChannelMessageId) (Evergreen.V187.Discord.Id Evergreen.V187.Discord.MessageId) Evergreen.V187.Emoji.Emoji (Result Evergreen.V187.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V187.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V187.Discord.HttpError (List ( Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId, Maybe Evergreen.V187.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V187.Slack.CurrentUser
            , team : Evergreen.V187.Slack.Team
            , users : List Evergreen.V187.Slack.User
            , channels : List ( Evergreen.V187.Slack.Channel, List Evergreen.V187.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId) (Result Effect.Http.Error Evergreen.V187.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId) Evergreen.V187.Discord.UserAuth (Result Evergreen.V187.Discord.HttpError Evergreen.V187.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId) (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId) (Result Evergreen.V187.Discord.HttpError Evergreen.V187.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId)
        (Result
            Evergreen.V187.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V187.Discord.Id Evergreen.V187.Discord.PrivateChannelId
                , members : List (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId)
                }
            , List
                ( Evergreen.V187.Discord.Id Evergreen.V187.Discord.GuildId
                , { guild : Evergreen.V187.Discord.GatewayGuild
                  , channels : List Evergreen.V187.Discord.Channel
                  , icon : Maybe Evergreen.V187.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId) Bool
    | WebsocketSentDataForUser (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V187.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V187.Discord.Id Evergreen.V187.Discord.AttachmentId, Evergreen.V187.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V187.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V187.Discord.Id Evergreen.V187.Discord.AttachmentId, Evergreen.V187.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId) (Evergreen.V187.Discord.Id Evergreen.V187.Discord.GuildId) (Evergreen.V187.Discord.Id Evergreen.V187.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V187.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V187.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId) (Evergreen.V187.Discord.Id Evergreen.V187.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V187.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V187.FileStatus.UploadResponse )))
    | ExportBackendStep
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId) (Evergreen.V187.Discord.Id Evergreen.V187.Discord.GuildId) (Evergreen.V187.Discord.Id Evergreen.V187.Discord.ChannelId) (Result Evergreen.V187.Discord.HttpError (List Evergreen.V187.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId) (Evergreen.V187.Discord.Id Evergreen.V187.Discord.PrivateChannelId) (Result Evergreen.V187.Discord.HttpError (List Evergreen.V187.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V187.Id.Id Evergreen.V187.Id.GuildId) (Evergreen.V187.Id.Id Evergreen.V187.Id.ChannelId) Evergreen.V187.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V187.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V187.DmChannel.DmChannelId Evergreen.V187.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V187.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V187.Discord.Id Evergreen.V187.Discord.GuildId) (Evergreen.V187.Discord.Id Evergreen.V187.Discord.ChannelId) Evergreen.V187.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V187.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V187.Discord.Id Evergreen.V187.Discord.PrivateChannelId) (Evergreen.V187.Id.Id Evergreen.V187.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V187.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId)
        (Evergreen.V187.Discord.Id Evergreen.V187.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V187.Discord.HttpError
            { guild : Evergreen.V187.Discord.GatewayGuild
            , channels : List Evergreen.V187.Discord.Channel
            , icon : Maybe Evergreen.V187.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V187.Discord.Id Evergreen.V187.Discord.GuildId) (Result Evergreen.V187.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V187.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
